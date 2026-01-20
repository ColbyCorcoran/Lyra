//
//  ImportQueueManager.swift
//  Lyra
//
//  Manages batch import queue for efficient library building
//

import Foundation
import SwiftData
import SwiftUI
import Combine

/// Represents a file in the import queue
struct ImportQueueItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let fileName: String
    var status: ImportStatus = .pending
    var error: String?
    var song: Song?

    enum ImportStatus {
        case pending
        case processing
        case completed
        case failed
        case skipped
        case duplicate
    }

    static func == (lhs: ImportQueueItem, rhs: ImportQueueItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Result of a bulk import operation
struct BulkImportResult {
    let totalFiles: Int
    let successCount: Int
    let failedCount: Int
    let skippedCount: Int
    let duplicateCount: Int
    let importedSongs: [Song]
    let failedItems: [ImportQueueItem]
    let duplicateItems: [ImportQueueItem]

    var hasFailures: Bool {
        failedCount > 0
    }

    var hasDuplicates: Bool {
        duplicateCount > 0
    }
}

@MainActor
class ImportQueueManager: ObservableObject {
    static let shared = ImportQueueManager()

    private init() {}

    // MARK: - Published Properties

    @Published var isImporting: Bool = false
    @Published var isCancelled: Bool = false
    @Published var queue: [ImportQueueItem] = []
    @Published var currentItem: ImportQueueItem?
    @Published var progress: Double = 0.0
    @Published var currentFileIndex: Int = 0
    @Published var totalFiles: Int = 0

    // Results
    @Published var importedSongs: [Song] = []
    @Published var failedItems: [ImportQueueItem] = []
    @Published var skippedItems: [ImportQueueItem] = []
    @Published var duplicateItems: [ImportQueueItem] = []

    // Configuration
    var checkDuplicates: Bool = true
    var duplicateSimilarityThreshold: Double = 0.90 // 90% similarity

    // Import tracking
    var importSource: String = "Files"
    var importMethod: String = "Bulk Import"
    var cloudFolderPath: String?
    private var importStartTime: Date?

    // MARK: - Constants

    static let maxBatchSize: Int = 100

    // MARK: - Queue Management

    /// Add files to the import queue
    func addToQueue(urls: [URL]) {
        let items = urls.prefix(Self.maxBatchSize).map { url in
            ImportQueueItem(
                url: url,
                fileName: url.lastPathComponent
            )
        }
        queue.append(contentsOf: items)
        totalFiles = queue.count
    }

    /// Clear the queue and reset state
    func clearQueue() {
        queue.removeAll()
        currentItem = nil
        progress = 0.0
        currentFileIndex = 0
        totalFiles = 0
        importedSongs.removeAll()
        failedItems.removeAll()
        skippedItems.removeAll()
        duplicateItems.removeAll()
        isCancelled = false
    }

    /// Cancel the current import operation
    func cancelImport() {
        isCancelled = true
        HapticManager.shared.warning()
    }

    // MARK: - Batch Import

    /// Start processing the import queue
    func startImport(modelContext: ModelContext) async {
        guard !queue.isEmpty else { return }
        guard !isImporting else { return }

        isImporting = true
        isCancelled = false
        currentFileIndex = 0
        importStartTime = Date()

        // Get all existing songs for duplicate detection
        let existingSongs = checkDuplicates ? fetchExistingSongs(from: modelContext) : []

        for (index, var item) in queue.enumerated() {
            // Check if cancelled
            if isCancelled {
                // Mark remaining items as skipped
                for i in index..<queue.count {
                    queue[i].status = .skipped
                }
                break
            }

            currentFileIndex = index + 1
            currentItem = item
            item.status = .processing
            queue[index] = item

            // Check for duplicates
            if checkDuplicates {
                if let duplicate = detectDuplicate(for: item.url, in: existingSongs, modelContext: modelContext) {
                    item.status = .duplicate
                    item.error = "Similar song already exists: \"\(duplicate.title)\""
                    item.song = duplicate
                    queue[index] = item
                    duplicateItems.append(item)

                    progress = Double(currentFileIndex) / Double(totalFiles)
                    continue
                }
            }

            // Import the file
            do {
                let result = try ImportManager.shared.importFile(
                    from: item.url,
                    to: modelContext,
                    progress: { _ in }
                )

                item.status = .completed
                item.song = result.song
                queue[index] = item
                importedSongs.append(result.song)

                HapticManager.shared.light()

            } catch {
                item.status = .failed
                item.error = error.localizedDescription
                queue[index] = item
                failedItems.append(item)

                HapticManager.shared.light()
            }

            progress = Double(currentFileIndex) / Double(totalFiles)

            // Small delay to allow UI updates
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        isImporting = false

        // Create import record
        createImportRecord(modelContext: modelContext)

        // Final haptic feedback
        if isCancelled {
            HapticManager.shared.warning()
        } else if failedItems.isEmpty && duplicateItems.isEmpty {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.warning()
        }
    }

    // MARK: - Import Record Creation

    private func createImportRecord(modelContext: ModelContext) {
        let duration = importStartTime.map { Date().timeIntervalSince($0) }

        // Create import record
        let record = ImportRecord(
            importSource: importSource,
            importMethod: importMethod,
            totalFileCount: totalFiles,
            successCount: importedSongs.count,
            failedCount: failedItems.count,
            duplicateCount: duplicateItems.count,
            skippedCount: queue.filter { $0.status == .skipped }.count,
            originalFilePaths: queue.map { $0.url.path },
            fileTypes: Array(Set(queue.map { $0.url.pathExtension })),
            cloudFolderPath: cloudFolderPath,
            cloudSyncEnabled: cloudFolderPath != nil
        )

        record.importDuration = duration

        // Add error messages
        for item in failedItems {
            if let error = item.error {
                record.addError("\(item.fileName): \(error)")
            }
        }

        // Link imported songs to record
        for song in importedSongs {
            record.addImportedSong(song)
        }

        // Save to database
        modelContext.insert(record)
        try? modelContext.save()
    }

    // MARK: - Duplicate Detection

    /// Fetch all existing songs from the database
    private func fetchExistingSongs(from modelContext: ModelContext) -> [Song] {
        let descriptor = FetchDescriptor<Song>()
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Error fetching songs for duplicate detection: \(error)")
            return []
        }
    }

    /// Detect if a file is a duplicate of an existing song
    private func detectDuplicate(for url: URL, in existingSongs: [Song], modelContext: ModelContext) -> Song? {
        // First, try to read the file content
        guard let fileContent = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        // Extract potential title and artist from content
        let (potentialTitle, potentialArtist) = extractMetadata(from: fileContent)

        // Check for exact title + artist match
        for song in existingSongs {
            // Exact title match
            if !potentialTitle.isEmpty && song.title.lowercased() == potentialTitle.lowercased() {
                // If both have artists, check artist match
                if let songArtist = song.artist,
                   !potentialArtist.isEmpty,
                   songArtist.lowercased() == potentialArtist.lowercased() {
                    return song
                }

                // If no artist info, just title match is strong signal
                if song.artist == nil && potentialArtist.isEmpty {
                    return song
                }
            }
        }

        // Check for content similarity
        for song in existingSongs {
            let similarity = calculateSimilarity(between: fileContent, and: song.content)
            if similarity >= duplicateSimilarityThreshold {
                return song
            }
        }

        return nil
    }

    /// Extract title and artist from file content
    private func extractMetadata(from content: String) -> (title: String, artist: String) {
        var title = ""
        var artist = ""

        let lines = content.components(separatedBy: .newlines)
        for line in lines.prefix(20) { // Only check first 20 lines
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // ChordPro format
            if trimmed.hasPrefix("{title:") || trimmed.hasPrefix("{t:") {
                title = trimmed
                    .replacingOccurrences(of: "{title:", with: "")
                    .replacingOccurrences(of: "{t:", with: "")
                    .replacingOccurrences(of: "}", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }

            if trimmed.hasPrefix("{artist:") || trimmed.hasPrefix("{a:") {
                artist = trimmed
                    .replacingOccurrences(of: "{artist:", with: "")
                    .replacingOccurrences(of: "{a:", with: "")
                    .replacingOccurrences(of: "}", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }

            // Plain text format (first non-empty line is often the title)
            if title.isEmpty && !trimmed.isEmpty && !trimmed.hasPrefix("#") && !trimmed.hasPrefix("{") {
                title = trimmed
            }
        }

        return (title, artist)
    }

    /// Calculate similarity between two strings (0.0 to 1.0)
    private func calculateSimilarity(between text1: String, and text2: String) -> Double {
        // Normalize texts
        let normalized1 = normalizeForComparison(text1)
        let normalized2 = normalizeForComparison(text2)

        // Use Levenshtein distance
        let distance = levenshteinDistance(normalized1, normalized2)
        let maxLength = max(normalized1.count, normalized2.count)

        guard maxLength > 0 else { return 1.0 }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    /// Normalize text for comparison (remove chords, whitespace, etc.)
    private func normalizeForComparison(_ text: String) -> String {
        var result = text.lowercased()

        // Remove ChordPro directives
        result = result.replacingOccurrences(of: #"\{[^}]+\}"#, with: "", options: .regularExpression)

        // Remove chord notation [C], [Am], etc.
        result = result.replacingOccurrences(of: #"\[[^\]]+\]"#, with: "", options: .regularExpression)

        // Remove extra whitespace
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        // Remove punctuation
        result = result.components(separatedBy: CharacterSet.punctuationCharacters).joined()

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)

        for i in 0...s1Array.count {
            matrix[i][0] = i
        }

        for j in 0...s2Array.count {
            matrix[0][j] = j
        }

        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                if s1Array[i - 1] == s2Array[j - 1] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,      // deletion
                        matrix[i][j - 1] + 1,      // insertion
                        matrix[i - 1][j - 1] + 1   // substitution
                    )
                }
            }
        }

        return matrix[s1Array.count][s2Array.count]
    }

    // MARK: - Results

    /// Get the final import result
    func getResult() -> BulkImportResult {
        BulkImportResult(
            totalFiles: totalFiles,
            successCount: importedSongs.count,
            failedCount: failedItems.count,
            skippedCount: queue.filter { $0.status == .skipped }.count,
            duplicateCount: duplicateItems.count,
            importedSongs: importedSongs,
            failedItems: failedItems,
            duplicateItems: duplicateItems
        )
    }

    /// Retry failed imports
    func retryFailedImports(modelContext: ModelContext) async {
        let failed = failedItems

        // Reset failed items in queue
        for item in failed {
            if let index = queue.firstIndex(where: { $0.id == item.id }) {
                queue[index].status = .pending
                queue[index].error = nil
            }
        }

        failedItems.removeAll()

        await startImport(modelContext: modelContext)
    }

    /// Export error log as text
    func exportErrorLog() -> String {
        var log = "Bulk Import Error Log\n"
        log += "Generated: \(Date().formatted())\n"
        log += "Total Files: \(totalFiles)\n"
        log += "Successful: \(importedSongs.count)\n"
        log += "Failed: \(failedItems.count)\n"
        log += "Duplicates: \(duplicateItems.count)\n"
        log += "Skipped: \(queue.filter { $0.status == .skipped }.count)\n\n"

        if !failedItems.isEmpty {
            log += "FAILED IMPORTS:\n"
            log += "================\n"
            for item in failedItems {
                log += "\nFile: \(item.fileName)\n"
                log += "Error: \(item.error ?? "Unknown error")\n"
            }
        }

        if !duplicateItems.isEmpty {
            log += "\n\nDUPLICATE DETECTIONS:\n"
            log += "======================\n"
            for item in duplicateItems {
                log += "\nFile: \(item.fileName)\n"
                log += "Reason: \(item.error ?? "Duplicate detected")\n"
            }
        }

        return log
    }
}
