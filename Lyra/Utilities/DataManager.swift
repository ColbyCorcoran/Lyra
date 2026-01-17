//
//  DataManager.swift
//  Lyra
//
//  Singleton data manager for SwiftData operations
//

import SwiftData
import Foundation

@MainActor
class DataManager {
    static let shared = DataManager()

    private var modelContext: ModelContext?

    private init() {}

    // MARK: - Initialization

    func initialize(with context: ModelContext) {
        self.modelContext = context
    }

    private func getContext() throws -> ModelContext {
        guard let context = modelContext else {
            throw DataError.contextNotInitialized
        }
        return context
    }

    // MARK: - Song Operations

    func createSong(
        title: String,
        artist: String? = nil,
        content: String = "",
        contentFormat: ContentFormat = .chordPro,
        originalKey: String? = nil
    ) throws -> Song {
        let context = try getContext()
        let song = Song(
            title: title,
            artist: artist,
            content: content,
            contentFormat: contentFormat,
            originalKey: originalKey
        )
        context.insert(song)
        try context.save()
        return song
    }

    func updateSong(_ song: Song) throws {
        let context = try getContext()
        song.modifiedAt = Date()
        try context.save()
    }

    func deleteSong(_ song: Song) throws {
        let context = try getContext()
        context.delete(song)
        try context.save()
    }

    // MARK: - Book Operations

    func createBook(name: String, description: String? = nil) throws -> Book {
        let context = try getContext()
        let book = Book(name: name, description: description)
        context.insert(book)
        try context.save()
        return book
    }

    func addSongToBook(_ song: Song, book: Book) throws {
        if book.songs == nil {
            book.songs = []
        }
        if !book.songs!.contains(where: { $0.id == song.id }) {
            book.songs?.append(song)
            book.modifiedAt = Date()
            try getContext().save()
        }
    }

    func removeSongFromBook(_ song: Song, book: Book) throws {
        guard let songs = book.songs else { return }
        book.songs = songs.filter { $0.id != song.id }
        book.modifiedAt = Date()
        try getContext().save()
    }

    func deleteBook(_ book: Book) throws {
        let context = try getContext()
        context.delete(book)
        try context.save()
    }

    // MARK: - Set Operations

    func createPerformanceSet(
        name: String,
        scheduledDate: Date? = nil,
        venue: String? = nil
    ) throws -> PerformanceSet {
        let context = try getContext()
        let set = PerformanceSet(name: name, scheduledDate: scheduledDate)
        set.venue = venue
        context.insert(set)
        try context.save()
        return set
    }

    func addSongToPerformanceSet(
        _ song: Song,
        set: PerformanceSet,
        at index: Int? = nil,
        keyOverride: String? = nil,
        capoOverride: Int? = nil,
        tempoOverride: Int? = nil,
        notes: String? = nil
    ) throws -> SetEntry {
        let context = try getContext()

        // Determine order index
        let orderIndex = index ?? (set.songEntries?.count ?? 0)

        // Create set entry
        let entry = SetEntry(song: song, orderIndex: orderIndex)
        entry.performanceSet = set
        entry.keyOverride = keyOverride
        entry.capoOverride = capoOverride
        entry.tempoOverride = tempoOverride
        entry.notes = notes

        context.insert(entry)

        // Add to set
        if set.songEntries == nil {
            set.songEntries = []
        }
        set.songEntries?.append(entry)

        // Reorder if needed
        if let index = index {
            reorderSetEntries(in: set, moving: entry, to: index)
        }

        set.modifiedAt = Date()
        try context.save()

        return entry
    }

    func removeSongFromPerformanceSet(_ entry: SetEntry, set: PerformanceSet) throws {
        let context = try getContext()
        guard let entries = set.songEntries else { return }

        set.songEntries = entries.filter { $0.id != entry.id }
        context.delete(entry)

        // Reindex remaining entries
        set.songEntries?.enumerated().forEach { index, entry in
            entry.orderIndex = index
        }

        set.modifiedAt = Date()
        try context.save()
    }

    func reorderSetEntries(in set: PerformanceSet, moving entry: SetEntry, to newIndex: Int) {
        guard var entries = set.songEntries else { return }

        // Remove from current position
        entries.removeAll { $0.id == entry.id }

        // Insert at new position
        entries.insert(entry, at: min(newIndex, entries.count))

        // Update all order indices
        entries.enumerated().forEach { index, entry in
            entry.orderIndex = index
        }

        set.songEntries = entries
    }

    func deletePerformanceSet(_ set: PerformanceSet) throws {
        let context = try getContext()
        context.delete(set)
        try context.save()
    }

    // MARK: - Attachment Operations

    func addAttachment(
        to song: Song,
        filename: String,
        fileType: String,
        fileData: Data?,
        filePath: String?
    ) throws -> Attachment {
        let context = try getContext()

        let attachment = Attachment(
            filename: filename,
            fileType: fileType,
            fileSize: fileData?.count ?? 0
        )
        attachment.song = song
        attachment.fileData = fileData
        attachment.filePath = filePath

        context.insert(attachment)

        if song.attachments == nil {
            song.attachments = []
        }
        song.attachments?.append(attachment)

        song.modifiedAt = Date()
        try context.save()

        return attachment
    }

    func deleteAttachment(_ attachment: Attachment) throws {
        let context = try getContext()
        if let song = attachment.song {
            song.modifiedAt = Date()
        }
        context.delete(attachment)
        try context.save()
    }

    // MARK: - Annotation Operations

    func addAnnotation(
        to song: Song,
        type: AnnotationType,
        x: Double,
        y: Double,
        text: String? = nil
    ) throws -> Annotation {
        let context = try getContext()

        let annotation = Annotation(song: song, type: type, x: x, y: y)
        annotation.text = text

        context.insert(annotation)

        if song.annotations == nil {
            song.annotations = []
        }
        song.annotations?.append(annotation)

        song.modifiedAt = Date()
        try context.save()

        return annotation
    }

    func updateAnnotation(_ annotation: Annotation) throws {
        annotation.modifiedAt = Date()
        if let song = annotation.song {
            song.modifiedAt = Date()
        }
        try getContext().save()
    }

    func deleteAnnotation(_ annotation: Annotation) throws {
        let context = try getContext()
        if let song = annotation.song {
            song.modifiedAt = Date()
        }
        context.delete(annotation)
        try context.save()
    }

    // MARK: - Query Operations

    func fetchAllSongs(sortedBy keyPath: KeyPath<Song, String> = \Song.title) throws -> [Song] {
        let context = try getContext()
        let descriptor = FetchDescriptor<Song>(
            sortBy: [SortDescriptor(keyPath)]
        )
        return try context.fetch(descriptor)
    }

    func fetchSongs(in book: Book) throws -> [Song] {
        return book.songs ?? []
    }

    func fetchSongs(in set: PerformanceSet) throws -> [Song] {
        guard let entries = set.songEntries else { return [] }
        return entries
            .sorted { $0.orderIndex < $1.orderIndex }
            .compactMap { $0.song }
    }

    func fetchAllBooks(sortedBy keyPath: KeyPath<Book, String> = \Book.name) throws -> [Book] {
        let context = try getContext()
        let descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(keyPath)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAllSets(
        includeArchived: Bool = false,
        sortedBy keyPath: KeyPath<PerformanceSet, String> = \PerformanceSet.name
    ) throws -> [PerformanceSet] {
        let context = try getContext()
        var descriptor = FetchDescriptor<PerformanceSet>(
            sortBy: [SortDescriptor(keyPath)]
        )

        if !includeArchived {
            descriptor.predicate = #Predicate<PerformanceSet> { set in
                set.isArchived == false
            }
        }

        return try context.fetch(descriptor)
    }

    func searchSongs(query: String) throws -> [Song] {
        let context = try getContext()
        let lowercaseQuery = query.lowercased()

        // Fetch all songs and filter in-memory since predicates don't support lowercased()
        let descriptor = FetchDescriptor<Song>(
            sortBy: [SortDescriptor(\Song.title)]
        )

        let allSongs = try context.fetch(descriptor)

        return allSongs.filter { song in
            song.title.lowercased().contains(lowercaseQuery) ||
            (song.artist?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }

    func fetchUserSettings() throws -> UserSettings? {
        let context = try getContext()
        let descriptor = FetchDescriptor<UserSettings>()
        return try context.fetch(descriptor).first
    }

    func getOrCreateUserSettings() throws -> UserSettings {
        if let existing = try fetchUserSettings() {
            return existing
        }

        let context = try getContext()
        let settings = UserSettings()
        context.insert(settings)
        try context.save()
        return settings
    }
}

// MARK: - Error Handling

enum DataError: LocalizedError {
    case contextNotInitialized
    case songNotFound
    case bookNotFound
    case setNotFound
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .contextNotInitialized:
            return "Model context has not been initialized. Please restart the app."
        case .songNotFound:
            return "The requested song could not be found."
        case .bookNotFound:
            return "The requested book could not be found."
        case .setNotFound:
            return "The requested set could not be found."
        case .saveFailed:
            return "Failed to save changes to the database."
        case .deleteFailed:
            return "Failed to delete the item from the database."
        }
    }
}
