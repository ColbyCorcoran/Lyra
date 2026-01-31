//
//  BackupManager.swift
//  Lyra
//
//  Manages local backups of the SwiftData database
//

import Foundation
import SwiftData

@MainActor
class BackupManager: ObservableObject {
    static let shared = BackupManager()

    @Published var availableBackups: [Backup] = []
    @Published var isCreatingBackup: Bool = false
    @Published var isRestoringBackup: Bool = false
    @Published var lastBackupDate: Date?
    @Published var autoBackupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoBackupEnabled, forKey: "backup.autoBackupEnabled")
        }
    }
    @Published var backupFrequency: BackupFrequency {
        didSet {
            UserDefaults.standard.set(backupFrequency.rawValue, forKey: "backup.frequency")
            scheduleNextAutoBackup()
        }
    }

    private let maxBackupCount = 5
    private let backupDirectory: URL
    private var modelContext: ModelContext?

    private init() {
        // Setup backup directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.backupDirectory = documentsPath.appendingPathComponent("Backups", isDirectory: true)

        // Create backup directory if needed
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        // Load settings
        self.autoBackupEnabled = UserDefaults.standard.bool(forKey: "backup.autoBackupEnabled")
        let frequencyRaw = UserDefaults.standard.string(forKey: "backup.frequency") ?? BackupFrequency.daily.rawValue
        self.backupFrequency = BackupFrequency(rawValue: frequencyRaw) ?? .daily

        if let lastBackupTimestamp = UserDefaults.standard.object(forKey: "backup.lastBackupDate") as? Date {
            self.lastBackupDate = lastBackupTimestamp
        }

        // Load available backups
        loadAvailableBackups()
    }

    func initialize(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Manual Backup

    func createBackup(name: String? = nil) async throws {
        guard let context = modelContext else {
            throw BackupError.contextNotInitialized
        }

        isCreatingBackup = true
        defer { isCreatingBackup = false }

        // Create backup filename
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())
        let backupName = name ?? "Backup-\(timestamp)"
        let backupFile = backupDirectory.appendingPathComponent("\(backupName).lyrabackup")

        // Get all data from SwiftData
        let songs = try context.fetch(FetchDescriptor<Song>())
        let books = try context.fetch(FetchDescriptor<Book>())
        let sets = try context.fetch(FetchDescriptor<PerformanceSet>())

        // Create backup data structure
        let backupData = BackupData(
            version: "1.0",
            createdAt: Date(),
            songs: songs.map { SongBackup(from: $0) },
            books: books.map { BookBackup(from: $0) },
            sets: sets.map { SetBackup(from: $0) }
        )

        // Encode and write to file
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(backupData)
        try jsonData.write(to: backupFile)

        // Update last backup date
        lastBackupDate = Date()
        UserDefaults.standard.set(lastBackupDate, forKey: "backup.lastBackupDate")

        // Clean up old backups
        try cleanupOldBackups()

        // Reload available backups
        loadAvailableBackups()
    }

    // MARK: - Restore Backup

    func restoreBackup(_ backup: Backup) async throws {
        guard let context = modelContext else {
            throw BackupError.contextNotInitialized
        }

        isRestoringBackup = true
        defer { isRestoringBackup = false }

        // Read backup file
        let backupFile = backupDirectory.appendingPathComponent(backup.filename)
        let jsonData = try Data(contentsOf: backupFile)

        // Decode backup data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: jsonData)

        // Clear existing data
        let existingSongs = try context.fetch(FetchDescriptor<Song>())
        let existingBooks = try context.fetch(FetchDescriptor<Book>())
        let existingSets = try context.fetch(FetchDescriptor<PerformanceSet>())

        for song in existingSongs {
            context.delete(song)
        }
        for book in existingBooks {
            context.delete(book)
        }
        for set in existingSets {
            context.delete(set)
        }

        try context.save()

        // Restore songs
        var songMap: [UUID: Song] = [:]
        for songBackup in backupData.songs {
            let song = songBackup.toSong()
            context.insert(song)
            songMap[songBackup.id] = song
        }

        // Restore books with song relationships
        var bookMap: [UUID: Book] = [:]
        for bookBackup in backupData.books {
            let book = bookBackup.toBook(songMap: songMap)
            context.insert(book)
            bookMap[bookBackup.id] = book
        }

        // Restore sets with song relationships
        for setBackup in backupData.sets {
            let set = setBackup.toSet(songMap: songMap)
            context.insert(set)
        }

        try context.save()
    }

    // MARK: - Export Backup

    func exportBackup(_ backup: Backup) -> URL {
        return backupDirectory.appendingPathComponent(backup.filename)
    }

    // MARK: - Import Backup

    func importBackup(from url: URL) async throws {
        // Copy file to backup directory
        let filename = url.lastPathComponent
        let destination = backupDirectory.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.copyItem(at: url, to: destination)

        // Reload available backups
        loadAvailableBackups()
    }

    // MARK: - Delete Backup

    func deleteBackup(_ backup: Backup) throws {
        let backupFile = backupDirectory.appendingPathComponent(backup.filename)
        try FileManager.default.removeItem(at: backupFile)
        loadAvailableBackups()
    }

    // MARK: - Auto Backup

    func checkAutoBackup() async {
        guard autoBackupEnabled else { return }
        guard shouldCreateAutoBackup() else { return }

        do {
            try await createBackup(name: "Auto-Backup")
        } catch {
            print("❌ Auto backup failed: \(error)")
        }
    }

    private func shouldCreateAutoBackup() -> Bool {
        guard let lastBackup = lastBackupDate else { return true }

        let now = Date()
        let calendar = Calendar.current

        switch backupFrequency {
        case .daily:
            return !calendar.isDateInToday(lastBackup)
        case .weekly:
            guard let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return false }
            return lastBackup < weekAgo
        case .manual:
            return false
        }
    }

    private func scheduleNextAutoBackup() {
        // This would integrate with background tasks in a production app
        // For now, we check on app launch and when the app becomes active
    }

    // MARK: - Cleanup

    private func cleanupOldBackups() throws {
        loadAvailableBackups()

        // Keep only the most recent backups
        if availableBackups.count > maxBackupCount {
            let backupsToDelete = availableBackups
                .sorted { $0.createdAt < $1.createdAt }
                .prefix(availableBackups.count - maxBackupCount)

            for backup in backupsToDelete {
                try? deleteBackup(backup)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadAvailableBackups() {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            availableBackups = files
                .filter { $0.pathExtension == "lyrabackup" }
                .compactMap { url in
                    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                          let createdAt = attributes[.creationDate] as? Date,
                          let fileSize = attributes[.size] as? Int64 else {
                        return nil
                    }

                    return Backup(
                        filename: url.lastPathComponent,
                        createdAt: createdAt,
                        fileSize: fileSize
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("❌ Error loading backups: \(error)")
            availableBackups = []
        }
    }
}

// MARK: - Models

struct Backup: Identifiable {
    let id = UUID()
    let filename: String
    let createdAt: Date
    let fileSize: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var displayName: String {
        filename.replacingOccurrences(of: ".lyrabackup", with: "")
    }
}

enum BackupFrequency: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case manual = "Manual Only"

    var displayName: String { rawValue }
}

enum BackupError: LocalizedError {
    case contextNotInitialized
    case backupFileNotFound
    case invalidBackupData
    case restorationFailed

    var errorDescription: String? {
        switch self {
        case .contextNotInitialized:
            return "Database context not initialized"
        case .backupFileNotFound:
            return "Backup file not found"
        case .invalidBackupData:
            return "Invalid backup data format"
        case .restorationFailed:
            return "Failed to restore backup"
        }
    }
}

// MARK: - Backup Data Structures

struct BackupData: Codable {
    let version: String
    let createdAt: Date
    let songs: [SongBackup]
    let books: [BookBackup]
    let sets: [SetBackup]
}

struct SongBackup: Codable {
    let id: UUID
    let title: String
    let artist: String?
    let content: String
    let contentFormat: String
    let originalKey: String?
    let currentKey: String?
    let transposeAmount: Int
    let capoPosition: Int?
    let tempo: Int?
    let timeSignature: String?
    let notes: String?
    let tags: [String]?
    let createdAt: Date
    let modifiedAt: Date

    init(from song: Song) {
        self.id = song.id
        self.title = song.title
        self.artist = song.artist
        self.content = song.content
        self.contentFormat = song.contentFormat.rawValue
        self.originalKey = song.originalKey
        self.currentKey = song.currentKey
        self.transposeAmount = song.transposeAmount
        self.capoPosition = song.capoPosition
        self.tempo = song.tempo
        self.timeSignature = song.timeSignature
        self.notes = song.notes
        self.tags = song.tags
        self.createdAt = song.createdAt
        self.modifiedAt = song.modifiedAt
    }

    func toSong() -> Song {
        let song = Song(
            title: title,
            artist: artist,
            content: content,
            contentFormat: ContentFormat(rawValue: contentFormat) ?? .chordPro,
            originalKey: originalKey
        )
        song.id = id
        song.currentKey = currentKey
        song.transposeAmount = transposeAmount
        song.capoPosition = capoPosition
        song.tempo = tempo
        song.timeSignature = timeSignature
        song.notes = notes
        song.tags = tags
        song.createdAt = createdAt
        song.modifiedAt = modifiedAt
        return song
    }
}

struct BookBackup: Codable {
    let id: UUID
    let name: String
    let description: String?
    let songIds: [UUID]
    let createdAt: Date
    let modifiedAt: Date

    init(from book: Book) {
        self.id = book.id
        self.name = book.name
        self.description = book.bookDescription
        self.songIds = book.songs?.map { $0.id } ?? []
        self.createdAt = book.createdAt
        self.modifiedAt = book.modifiedAt
    }

    func toBook(songMap: [UUID: Song]) -> Book {
        let book = Book(name: name, description: description)
        book.id = id
        book.songs = songIds.compactMap { songMap[$0] }
        book.createdAt = createdAt
        book.modifiedAt = modifiedAt
        return book
    }
}

struct SetBackup: Codable {
    let id: UUID
    let name: String
    let setDescription: String?
    let songIds: [UUID]
    let createdAt: Date
    let modifiedAt: Date

    init(from set: PerformanceSet) {
        self.id = set.id
        self.name = set.name
        self.setDescription = set.setDescription
        self.songIds = set.songs?.map { $0.id } ?? []
        self.createdAt = set.createdAt
        self.modifiedAt = set.modifiedAt
    }

    func toSet(songMap: [UUID: Song]) -> PerformanceSet {
        let set = PerformanceSet(name: name, description: setDescription)
        set.id = id
        set.songs = songIds.compactMap { songMap[$0] }
        set.createdAt = createdAt
        set.modifiedAt = modifiedAt
        return set
    }
}
