//
//  VoiceCommandModels.swift
//  Lyra
//
//  Data models for natural language processing and voice commands
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import SwiftData

// MARK: - Command Intent

/// Intent classification for voice commands
enum CommandIntent: String, Codable {
    // Search intents
    case findSongs
    case findByKey
    case findByTempo
    case findByMood
    case findByArtist
    case findByLyrics

    // Navigation intents
    case goToSong
    case goToSet
    case showNext
    case showPrevious
    case goHome

    // Edit intents
    case transpose
    case setCapo
    case editSong
    case deleteSong

    // Performance intents
    case startAutoscroll
    case stopAutoscroll
    case adjustScrollSpeed
    case startMetronome
    case stopMetronome
    case adjustTempo
    case enablePerformanceMode
    case disablePerformanceMode

    // Set management intents
    case addToSet
    case removeFromSet
    case createSet
    case deleteSet
    case reorderSet

    // Query intents
    case whatSong
    case whatSet
    case whatsNext
    case howMany
    case listSets

    // System intents
    case help
    case `repeat`
    case cancel
    case unknown

    var category: IntentCategory {
        switch self {
        case .findSongs, .findByKey, .findByTempo, .findByMood, .findByArtist, .findByLyrics:
            return .search
        case .goToSong, .goToSet, .showNext, .showPrevious, .goHome:
            return .navigate
        case .transpose, .setCapo, .editSong, .deleteSong:
            return .edit
        case .startAutoscroll, .stopAutoscroll, .adjustScrollSpeed, .startMetronome,
             .stopMetronome, .adjustTempo, .enablePerformanceMode, .disablePerformanceMode:
            return .perform
        case .addToSet, .removeFromSet, .createSet, .deleteSet, .reorderSet:
            return .manage
        case .whatSong, .whatSet, .whatsNext, .howMany, .listSets:
            return .query
        case .help, .repeat, .cancel, .unknown:
            return .system
        }
    }
}

/// High-level intent categories
enum IntentCategory: String, Codable {
    case search
    case navigate
    case edit
    case perform
    case manage
    case query
    case system
}

// MARK: - Command Entity

/// Extracted entities from voice commands
struct CommandEntity: Codable, Identifiable {
    let id: UUID
    let type: EntityType
    let value: String
    let confidence: Float
    let range: Range<String.Index>?  // Not included in Codable

    enum EntityType: String, Codable {
        case songTitle
        case artistName
        case musicalKey
        case tempo
        case mood
        case action
        case number
        case setName
        case direction
        case attribute
        case timeSignature
        case capoPosition
    }

    // Exclude range from Codable since Range<String.Index> is not serializable
    enum CodingKeys: String, CodingKey {
        case id, type, value, confidence
    }

    init(id: UUID = UUID(), type: EntityType, value: String, confidence: Float, range: Range<String.Index>? = nil) {
        self.id = id
        self.type = type
        self.value = value
        self.confidence = confidence
        self.range = range
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(EntityType.self, forKey: .type)
        value = try container.decode(String.self, forKey: .value)
        confidence = try container.decode(Float.self, forKey: .confidence)
        range = nil  // Cannot be decoded
    }
}

// MARK: - Voice Command

/// Represents a processed voice command
@Model
class VoiceCommand {
    var id: UUID
    var rawText: String
    var processedText: String
    var intent: String  // CommandIntent as String for SwiftData
    var entities: Data  // [CommandEntity] encoded
    var confidence: Float
    var timestamp: Date
    var executionResult: String?  // CommandResult as String
    var userID: String?

    // Context
    var contextID: UUID?
    var isFollowUp: Bool
    var referencesSong: UUID?
    var referencesSet: UUID?

    init(
        rawText: String,
        processedText: String,
        intent: CommandIntent,
        entities: [CommandEntity],
        confidence: Float,
        contextID: UUID? = nil,
        isFollowUp: Bool = false
    ) {
        self.id = UUID()
        self.rawText = rawText
        self.processedText = processedText
        self.intent = intent.rawValue
        self.confidence = confidence
        self.timestamp = Date()
        self.contextID = contextID
        self.isFollowUp = isFollowUp

        // Encode entities
        if let encoded = try? JSONEncoder().encode(entities) {
            self.entities = encoded
        } else {
            self.entities = Data()
        }
    }

    func getIntent() -> CommandIntent {
        return CommandIntent(rawValue: intent) ?? .unknown
    }

    func getEntities() -> [CommandEntity] {
        guard let decoded = try? JSONDecoder().decode([CommandEntity].self, from: entities) else {
            return []
        }
        return decoded
    }
}

// MARK: - Command Result

/// Result of command execution
enum CommandResult {
    case success(CommandAction)
    case needsConfirmation(CommandAction, reason: String)
    case needsClarification([CommandOption])
    case error(String)
    case notImplemented
}

/// Action to be executed
struct CommandAction: Identifiable {
    let id = UUID()
    let intent: CommandIntent
    let target: ActionTarget
    let parameters: [String: Any]
    let description: String
    let requiresConfirmation: Bool

    enum ActionTarget {
        case song(UUID)
        case set(UUID)
        case songs([UUID])
        case currentView
        case application
        case none
    }
}

/// Option for clarification
struct CommandOption: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let action: CommandAction
}

// MARK: - Conversation Context

/// Maintains conversation state
@Model
class ConversationContext {
    var id: UUID
    var sessionStart: Date
    var lastActivity: Date
    var commands: [UUID]  // VoiceCommand IDs

    // Current context
    var currentSong: UUID?
    var currentSet: UUID?
    var lastSearchResults: [UUID]
    var recentTopics: [String]

    // Pronoun resolution
    var itRefers: UUID?
    var thisRefers: UUID?
    var thatRefers: UUID?
    var themRefers: [UUID]

    init() {
        self.id = UUID()
        self.sessionStart = Date()
        self.lastActivity = Date()
        self.commands = []
        self.lastSearchResults = []
        self.recentTopics = []
        self.themRefers = []
    }

    func updateActivity() {
        lastActivity = Date()
    }

    func isStale() -> Bool {
        let interval = Date().timeIntervalSince(lastActivity)
        return interval > 300 // 5 minutes
    }
}

// MARK: - Command Pattern

/// Learned command pattern
@Model
class CommandPattern {
    var id: UUID
    var patternText: String
    var intent: String
    var entityMappings: Data  // [String: CommandEntity.EntityType] encoded
    var usageCount: Int
    var successRate: Float
    var lastUsed: Date
    var userID: String?

    init(
        patternText: String,
        intent: CommandIntent,
        entityMappings: [String: CommandEntity.EntityType]
    ) {
        self.id = UUID()
        self.patternText = patternText
        self.intent = intent.rawValue
        self.usageCount = 0
        self.successRate = 1.0
        self.lastUsed = Date()

        // Encode mappings
        if let encoded = try? JSONEncoder().encode(entityMappings) {
            self.entityMappings = encoded
        } else {
            self.entityMappings = Data()
        }
    }

    func recordUsage(success: Bool) {
        usageCount += 1
        lastUsed = Date()

        // Update success rate with exponential moving average
        let alpha: Float = 0.2
        let newValue: Float = success ? 1.0 : 0.0
        successRate = alpha * newValue + (1 - alpha) * successRate
    }
}

// MARK: - User Command Vocabulary

/// User's custom vocabulary and shortcuts
@Model
class UserCommandVocabulary {
    var id: UUID
    var userID: String
    var customTerms: Data  // [String: String] encoded (custom term -> standard term)
    var shortcuts: Data  // [String: CommandIntent] encoded
    var preferredPhrasing: Data  // [CommandIntent: [String]] encoded
    var lastUpdated: Date

    init(userID: String) {
        self.id = UUID()
        self.userID = userID
        self.customTerms = Data()
        self.shortcuts = Data()
        self.preferredPhrasing = Data()
        self.lastUpdated = Date()
    }

    func getCustomTerms() -> [String: String] {
        guard let decoded = try? JSONDecoder().decode([String: String].self, from: customTerms) else {
            return [:]
        }
        return decoded
    }

    func addCustomTerm(from: String, to: String) {
        var terms = getCustomTerms()
        terms[from.lowercased()] = to

        if let encoded = try? JSONEncoder().encode(terms) {
            customTerms = encoded
            lastUpdated = Date()
        }
    }
}

// MARK: - Command Feedback

/// User feedback on command execution
@Model
class CommandFeedback {
    var id: UUID
    var commandID: UUID
    var wasCorrect: Bool
    var correctedIntent: String?
    var correctedEntities: Data?
    var timestamp: Date
    var feedbackType: String  // FeedbackType as String

    enum FeedbackType: String, Codable {
        case correct
        case wrongIntent
        case wrongEntity
        case misunderstood
        case partiallyCorrect
    }

    init(
        commandID: UUID,
        wasCorrect: Bool,
        feedbackType: FeedbackType,
        correctedIntent: CommandIntent? = nil
    ) {
        self.id = UUID()
        self.commandID = commandID
        self.wasCorrect = wasCorrect
        self.feedbackType = feedbackType.rawValue
        self.timestamp = Date()

        if let corrected = correctedIntent {
            self.correctedIntent = corrected.rawValue
        }
    }
}

// MARK: - Voice Settings

/// User preferences for voice commands
struct VoiceSettings: Codable {
    var isEnabled: Bool = true
    var language: String = "en-US"
    var wakeWordEnabled: Bool = false
    var wakeWord: String = "Hey Lyra"
    var continuousListening: Bool = false
    var confirmationLevel: ConfirmationLevel = .destructive
    var feedbackVerbosity: FeedbackVerbosity = .normal
    var learningEnabled: Bool = true
    var audioFeedbackEnabled: Bool = true
    var hapticFeedbackEnabled: Bool = true

    enum ConfirmationLevel: String, Codable {
        case none
        case destructive
        case all
    }

    enum FeedbackVerbosity: String, Codable {
        case minimal
        case normal
        case detailed
    }
}

// MARK: - Speech Recognition State

/// Current state of speech recognition
enum RecognitionState {
    case idle
    case listening
    case processing
    case speaking
    case error(String)
}

// MARK: - Command Execution Context

/// Context for command execution
struct ExecutionContext {
    let modelContext: Any  // ModelContext
    let currentSong: UUID?
    let currentSet: UUID?
    let navigationState: NavigationState
    let performanceMode: Bool

    enum NavigationState {
        case songList
        case songDetail
        case setList
        case setDetail
        case search
        case settings
    }
}

// MARK: - Natural Language Query

/// Extended search query with NLP context
struct NaturalLanguageQuery: Codable {
    let rawText: String
    let intent: CommandIntent
    let entities: [CommandEntity]
    let filters: [String: String]
    let sortPreference: String?
    let limit: Int?
    let followUpContext: UUID?
    let timestamp: Date
}

// MARK: - Command Statistics

/// Statistics for command usage
@Model
class CommandStatistics {
    var id: UUID
    var intentCounts: Data  // [String: Int] encoded
    var entityCounts: Data  // [String: Int] encoded
    var averageConfidence: Float
    var totalCommands: Int
    var successfulCommands: Int
    var lastReset: Date

    init() {
        self.id = UUID()
        self.intentCounts = Data()
        self.entityCounts = Data()
        self.averageConfidence = 0.0
        self.totalCommands = 0
        self.successfulCommands = 0
        self.lastReset = Date()
    }

    func recordCommand(intent: CommandIntent, success: Bool, confidence: Float) {
        totalCommands += 1
        if success {
            successfulCommands += 1
        }

        // Update average confidence
        let alpha: Float = 1.0 / Float(totalCommands)
        averageConfidence = alpha * confidence + (1 - alpha) * averageConfidence

        // Update intent counts
        var counts = getIntentCounts()
        counts[intent.rawValue, default: 0] += 1

        if let encoded = try? JSONEncoder().encode(counts) {
            intentCounts = encoded
        }
    }

    func getIntentCounts() -> [String: Int] {
        guard let decoded = try? JSONDecoder().decode([String: Int].self, from: intentCounts) else {
            return [:]
        }
        return decoded
    }

    var successRate: Float {
        guard totalCommands > 0 else { return 0 }
        return Float(successfulCommands) / Float(totalCommands)
    }
}
