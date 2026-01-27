//
//  SongwritingModels.swift
//  Lyra
//
//  Phase 7.14: AI Songwriting Assistance - Data Models
//  SwiftData models for songwriting intelligence persistence
//

import Foundation
import SwiftData

// MARK: - SwiftData Models

/// Stores user's songwriting sessions
@Model
final class SongwritingSession {
    @Attribute(.unique) var id: UUID
    var songID: UUID
    var startedAt: Date
    var endedAt: Date?
    var goal: String
    var genre: String
    var generatedContent: String
    var acceptedSuggestions: Int
    var rejectedSuggestions: Int

    init(
        id: UUID = UUID(),
        songID: UUID,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        goal: String,
        genre: String,
        generatedContent: String = "",
        acceptedSuggestions: Int = 0,
        rejectedSuggestions: Int = 0
    ) {
        self.id = id
        self.songID = songID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.goal = goal
        self.genre = genre
        self.generatedContent = generatedContent
        self.acceptedSuggestions = acceptedSuggestions
        self.rejectedSuggestions = rejectedSuggestions
    }
}

/// Stores generated chord progressions for reuse
@Model
final class SavedProgression {
    @Attribute(.unique) var id: UUID
    var name: String
    var chords: [String]
    var key: String
    var genre: String
    var isMinor: Bool
    var usageCount: Int
    var rating: Int // 1-5
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        chords: [String],
        key: String,
        genre: String,
        isMinor: Bool = false,
        usageCount: Int = 0,
        rating: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.chords = chords
        self.key = key
        self.genre = genre
        self.isMinor = isMinor
        self.usageCount = usageCount
        self.rating = rating
        self.createdAt = createdAt
    }
}

/// Stores user feedback on AI suggestions
@Model
final class SuggestionFeedback {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var suggestionType: String
    var suggestionContent: String
    var accepted: Bool
    var rating: Int
    var userNotes: String?
    var timestamp: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        suggestionType: String,
        suggestionContent: String,
        accepted: Bool,
        rating: Int,
        userNotes: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.suggestionType = suggestionType
        self.suggestionContent = suggestionContent
        self.accepted = accepted
        self.rating = rating
        self.userNotes = userNotes
        self.timestamp = timestamp
    }
}

/// Stores user's writing patterns for learning
@Model
final class WritingPatternRecord {
    @Attribute(.unique) var id: UUID
    var userID: String
    var chords: [String]
    var key: String
    var tempo: Int
    var genre: String
    var structure: [String]
    var usageCount: Int
    var lastUsed: Date

    init(
        id: UUID = UUID(),
        userID: String,
        chords: [String],
        key: String,
        tempo: Int,
        genre: String,
        structure: [String],
        usageCount: Int = 1,
        lastUsed: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.chords = chords
        self.key = key
        self.tempo = tempo
        self.genre = genre
        self.structure = structure
        self.usageCount = usageCount
        self.lastUsed = lastUsed
    }
}

/// Stores saved song starters
@Model
final class SavedSongStarter {
    @Attribute(.unique) var id: UUID
    var name: String
    var genre: String
    var key: String
    var tempo: Int
    var mood: String
    var theme: String
    var chordProgressionData: Data // Encoded GeneratedProgression
    var structureData: Data // Encoded SongStructureTemplate
    var createdAt: Date
    var lastModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        genre: String,
        key: String,
        tempo: Int,
        mood: String,
        theme: String,
        chordProgressionData: Data,
        structureData: Data,
        createdAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.genre = genre
        self.key = key
        self.tempo = tempo
        self.mood = mood
        self.theme = theme
        self.chordProgressionData = chordProgressionData
        self.structureData = structureData
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
}

/// Stores collaboration session history
@Model
final class CollaborationHistory {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var versionNumber: Int
    var content: String
    var changes: [String]
    var aiContributed: Bool
    var timestamp: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        versionNumber: Int,
        content: String,
        changes: [String],
        aiContributed: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.versionNumber = versionNumber
        self.content = content
        self.changes = changes
        self.aiContributed = aiContributed
        self.timestamp = timestamp
    }
}

/// Stores user's songwriting preferences
@Model
final class SongwritingPreferences {
    @Attribute(.unique) var id: UUID
    var userID: String
    var preferredGenres: [String]
    var favoriteKeys: [String: Int]
    var typicalTempo: Int
    var enabledFeatures: [String]
    var assistantMode: String
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        userID: String,
        preferredGenres: [String] = [],
        favoriteKeys: [String: Int] = [:],
        typicalTempo: Int = 120,
        enabledFeatures: [String] = [],
        assistantMode: String = "suggest",
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.preferredGenres = preferredGenres
        self.favoriteKeys = favoriteKeys
        self.typicalTempo = typicalTempo
        self.enabledFeatures = enabledFeatures
        self.assistantMode = assistantMode
        self.lastUpdated = lastUpdated
    }
}

/// Stores style transformations
@Model
final class SavedStyleTransform {
    @Attribute(.unique) var id: UUID
    var name: String
    var originalChords: [String]
    var transformedChords: [String]
    var sourceGenre: String
    var targetGenre: String
    var intensity: String
    var rating: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        originalChords: [String],
        transformedChords: [String],
        sourceGenre: String,
        targetGenre: String,
        intensity: String,
        rating: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.originalChords = originalChords
        self.transformedChords = transformedChords
        self.sourceGenre = sourceGenre
        self.targetGenre = targetGenre
        self.intensity = intensity
        self.rating = rating
        self.createdAt = createdAt
    }
}

// MARK: - Helper Extensions

extension SongwritingSession {
    var duration: TimeInterval? {
        guard let endedAt = endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }

    var acceptanceRate: Double {
        let total = acceptedSuggestions + rejectedSuggestions
        guard total > 0 else { return 0 }
        return Double(acceptedSuggestions) / Double(total)
    }
}

extension SavedProgression {
    func incrementUsage() {
        usageCount += 1
    }

    var chordString: String {
        chords.joined(separator: " - ")
    }
}

extension WritingPatternRecord {
    func recordUsage() {
        usageCount += 1
        lastUsed = Date()
    }

    var isRecent: Bool {
        Date().timeIntervalSince(lastUsed) < 30 * 24 * 60 * 60 // 30 days
    }
}

extension SavedSongStarter {
    func updateModifiedDate() {
        lastModified = Date()
    }
}

// MARK: - Model Container Configuration

/// Helper to configure SwiftData model container with songwriting models
extension ModelContainer {
    static func songwritingContainer() throws -> ModelContainer {
        let schema = Schema([
            SongwritingSession.self,
            SavedProgression.self,
            SuggestionFeedback.self,
            WritingPatternRecord.self,
            SavedSongStarter.self,
            CollaborationHistory.self,
            SongwritingPreferences.self,
            SavedStyleTransform.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
