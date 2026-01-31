//
//  BulkExportView.swift
//  Lyra
//
//  UI for bulk exporting the entire library
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BulkExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedFormat: ExportFormat = .chordPro
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var exportedCount: Int = 0
    @State private var totalSongs: Int = 0
    @State private var showError = false
    @State private var errorMessage: String = ""
    @State private var showExportPicker = false
    @State private var exportURL: URL?
    @State private var includeBooks = true
    @State private var includeSets = true

    var body: some View {
        NavigationStack {
            Form {
                // Library Info
                Section {
                    HStack {
                        Label("Total Songs", systemImage: "music.note")
                        Spacer()
                        Text("\(getSongCount())")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Books", systemImage: "book.fill")
                        Spacer()
                        Text("\(getBookCount())")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Sets", systemImage: "list.bullet.rectangle")
                        Spacer()
                        Text("\(getSetCount())")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Library Overview")
                } footer: {
                    Text("Export your entire library to a single archive")
                }

                // Export Options
                Section {
                    Picker("Export Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            HStack {
                                Image(systemName: format.icon)
                                Text(format.displayName)
                            }
                            .tag(format)
                        }
                    }

                    Toggle("Include Books", isOn: $includeBooks)
                    Toggle("Include Sets", isOn: $includeSets)
                } header: {
                    Text("Export Options")
                } footer: {
                    Text(selectedFormat.description)
                }

                // Export Progress
                if isExporting {
                    Section {
                        VStack(spacing: 16) {
                            ProgressView(value: exportProgress, total: 1.0)
                                .progressViewStyle(.linear)

                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)

                                Text("Exporting \(exportedCount) of \(totalSongs) songs...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Export Progress")
                    }
                }

                // Export Button
                Section {
                    Button {
                        startExport()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                            } else {
                                Label("Export Library", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isExporting || getSongCount() == 0)
                }
            }
            .navigationTitle("Export Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isExporting)
                }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .fileExporter(
                isPresented: $showExportPicker,
                document: BulkExportDocument(url: exportURL),
                contentType: .zip,
                defaultFilename: "Lyra-Library-Export-\(Date().formatted(date: .abbreviated, time: .omitted)).zip"
            ) { result in
                handleExport(result)
            }
        }
    }

    // MARK: - Helper Methods

    private func getSongCount() -> Int {
        let descriptor = FetchDescriptor<Song>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func getBookCount() -> Int {
        let descriptor = FetchDescriptor<Book>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func getSetCount() -> Int {
        let descriptor = FetchDescriptor<PerformanceSet>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Export Logic

    private func startExport() {
        Task {
            do {
                isExporting = true
                exportedCount = 0

                // Fetch all data
                let songs = try modelContext.fetch(FetchDescriptor<Song>())
                totalSongs = songs.count

                let books = includeBooks ? try modelContext.fetch(FetchDescriptor<Book>()) : []
                let sets = includeSets ? try modelContext.fetch(FetchDescriptor<PerformanceSet>()) : []

                // Create temporary directory
                let tempDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("LyraExport-\(UUID().uuidString)")
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                // Create songs directory
                let songsDir = tempDir.appendingPathComponent("Songs")
                try FileManager.default.createDirectory(at: songsDir, withIntermediateDirectories: true)

                // Export all songs
                for (index, song) in songs.enumerated() {
                    try exportSong(song, to: songsDir)
                    exportedCount = index + 1
                    exportProgress = Double(index + 1) / Double(totalSongs)
                }

                // Export library metadata (books and sets)
                if includeBooks || includeSets {
                    try exportMetadata(songs: songs, books: books, sets: sets, to: tempDir)
                }

                // Create README
                try createReadme(to: tempDir, songCount: songs.count, bookCount: books.count, setCount: sets.count)

                // Zip the directory
                let zipURL = try zipDirectory(tempDir)

                // Clean up temp directory
                try? FileManager.default.removeItem(at: tempDir)

                // Show export picker
                exportURL = zipURL
                isExporting = false
                showExportPicker = true

            } catch {
                isExporting = false
                errorMessage = "Export failed: \(error.localizedDescription)"
                showError = true
                HapticManager.shared.error()
            }
        }
    }

    private func exportSong(_ song: Song, to directory: URL) throws {
        let exporter = SongExporter()
        let filename = sanitizeFilename(song.title) + selectedFormat.fileExtension
        let fileURL = directory.appendingPathComponent(filename)

        let content: String
        switch selectedFormat {
        case .chordPro:
            content = try exporter.exportToChordPro(song: song)
        case .plainText:
            content = try exporter.exportToPlainText(song: song)
        case .pdf:
            // For PDF, we need to save as data
            let pdfData = try exporter.exportToPDF(song: song)
            try pdfData.write(to: fileURL)
            return
        case .json:
            let jsonData = try exporter.exportToJSONData(song: song)
            try jsonData.write(to: fileURL)
            return
        }

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func exportMetadata(songs: [Song], books: [Book], sets: [PerformanceSet], to directory: URL) throws {
        var metadata: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "version": "1.0",
            "songCount": songs.count
        ]

        // Export books
        if includeBooks && !books.isEmpty {
            let booksData = books.map { book in
                [
                    "name": book.name,
                    "description": book.bookDescription ?? "",
                    "songs": book.songs?.map { $0.title } ?? []
                ]
            }
            metadata["books"] = booksData
        }

        // Export sets
        if includeSets && !sets.isEmpty {
            let setsData = sets.map { set in
                [
                    "name": set.name,
                    "description": set.setDescription ?? "",
                    "songs": set.songs?.map { $0.title } ?? []
                ]
            }
            metadata["sets"] = setsData
        }

        let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        let metadataURL = directory.appendingPathComponent("library-metadata.json")
        try jsonData.write(to: metadataURL)
    }

    private func createReadme(to directory: URL, songCount: Int, bookCount: Int, setCount: Int) throws {
        let readme = """
        # Lyra Library Export

        Export Date: \(Date().formatted(date: .long, time: .shortened))
        Format: \(selectedFormat.displayName)

        ## Contents

        - **Songs**: \(songCount) files in /Songs directory
        - **Books**: \(bookCount) collections
        - **Sets**: \(setCount) performance sets

        ## File Format

        \(selectedFormat.description)

        ## Importing

        To import this library back into Lyra:
        1. Open Lyra
        2. Go to Settings → Data Management → Backup & Restore
        3. Choose "Import Backup"
        4. Select this archive

        For more information, visit: https://github.com/yourusername/lyra
        """

        let readmeURL = directory.appendingPathComponent("README.txt")
        try readme.write(to: readmeURL, atomically: true, encoding: .utf8)
    }

    private func zipDirectory(_ directory: URL) throws -> URL {
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Lyra-Export-\(UUID().uuidString).zip")

        // Use macOS/iOS built-in zip (this is a simplified version - in production you'd use a proper ZIP library)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-q", zipURL.path, "."]
        process.currentDirectoryURL = directory

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "BulkExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create ZIP archive"])
        }

        return zipURL
    }

    private func sanitizeFilename(_ filename: String) -> String {
        let invalid = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return filename
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            HapticManager.shared.success()
            dismiss()
        case .failure(let error):
            errorMessage = "Failed to save export: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.error()
        }
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case chordPro = "ChordPro"
    case plainText = "Plain Text"
    case pdf = "PDF"
    case json = "JSON"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .chordPro: return "text.badge.checkmark"
        case .plainText: return "doc.text"
        case .pdf: return "doc.richtext"
        case .json: return "curlybraces"
        }
    }

    var fileExtension: String {
        switch self {
        case .chordPro: return ".cho"
        case .plainText: return ".txt"
        case .pdf: return ".pdf"
        case .json: return ".json"
        }
    }

    var description: String {
        switch self {
        case .chordPro:
            return "ChordPro format with metadata and formatting. Compatible with most chord chart apps."
        case .plainText:
            return "Plain text format. Simple and universal, but loses some formatting."
        case .pdf:
            return "PDF documents. Perfect for printing or sharing. Cannot be re-imported."
        case .json:
            return "JSON format with all metadata. Best for programmatic access or backup."
        }
    }
}

// MARK: - Bulk Export Document

struct BulkExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }

    let url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url else {
            throw NSError(domain: "BulkExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Export file not found"])
        }

        let data = try Data(contentsOf: url)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview {
    BulkExportView()
        .modelContainer(for: Song.self, inMemory: true)
}
