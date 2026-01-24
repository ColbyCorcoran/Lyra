//
//  RecommendationModels.swift
//  Lyra
//
//  Phase 7.5: Recommendation Intelligence
//  Created on January 24, 2026
//

import Foundation
import SwiftData

// MARK: - Song Recommendation

/// Represents a song recommendation with similarity scoring and reasoning
@Model
final class SongRecommendation {
    var id: UUID
    var songID: UUID
    var recommendedSongID: UUID
    var similarityScore: Float
    var recommendationType: String // RecommendationType raw value
    var reasons: [String]
    var timestamp: Date
    var context: String?

    init(
        id: UUID = UUID(),
        songID: UUID,
        recommendedSongID: UUID,
        similarityScore: Float,
        recommendationType: RecommendationType,
        reasons: [RecommendationReason],
        timestamp: Date = Date(),
        context: String? = nil
    ) {
        self.id = id
        self.songID = songID
        self.recommendedSongID = recommendedSongID
        self.similarityScore = similarityScore
        self.recommendationType = recommendationType.rawValue
        self.reasons = reasons.map { $0.rawValue }
        self.timestamp = timestamp
        self.context = context
    }
}

// MARK: - User Taste Profile

/// User's musical preferences and behavioral patterns
@Model
final class UserTasteProfile {
    var id: UUID
    var userID: String
    var preferredKeys: [String]
    var preferredTempos: [String] // TempoRange raw values
    var preferredMoods: [String] // Mood raw values
    var preferredArtists: [String]
    var preferredGenres: [String]
    var chordComplexityPreference: Float // 0.0 = simple, 1.0 = complex
    var capoPreference: String // CapoPreference raw value
    var playPatterns: [String: Int] // time-of-day -> frequency
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        userID: String,
        preferredKeys: [String] = [],
        preferredTempos: [String] = [],
        preferredMoods: [String] = [],
        preferredArtists: [String] = [],
        preferredGenres: [String] = [],
        chordComplexityPreference: Float = 0.5,
        capoPreference: String = CapoPreference.neutral.rawValue,
        playPatterns: [String: Int] = [:],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.preferredKeys = preferredKeys
        self.preferredTempos = preferredTempos
        self.preferredMoods = preferredMoods
        self.preferredArtists = preferredArtists
        self.preferredGenres = preferredGenres
        self.chordComplexityPreference = chordComplexityPreference
        self.capoPreference = capoPreference
        self.playPatterns = playPatterns
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Recommendation Feedback

/// User feedback on recommendations for learning
@Model
final class RecommendationFeedback {
    var id: UUID
    var recommendationID: UUID
    var feedback: String // FeedbackType raw value
    var timestamp: Date
    var context: String?

    init(
        id: UUID = UUID(),
        recommendationID: UUID,
        feedback: FeedbackType,
        timestamp: Date = Date(),
        context: String? = nil
    ) {
        self.id = id
        self.recommendationID = recommendationID
        self.feedback = feedback.rawValue
        self.timestamp = timestamp
        self.context = context
    }
}

// MARK: - Smart Playlist

/// Auto-generated playlist based on criteria
@Model
final class SmartPlaylist {
    var id: UUID
    var name: String
    var criteriaData: Data // Encoded PlaylistCriteria
    var songIDs: [UUID]
    var autoRefresh: Bool
    var refreshInterval: TimeInterval
    var lastRefreshed: Date
    var flowOptimized: Bool
    var targetDuration: TimeInterval?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        criteria: PlaylistCriteria,
        songIDs: [UUID] = [],
        autoRefresh: Bool = false,
        refreshInterval: TimeInterval = 86400, // 1 day
        lastRefreshed: Date = Date(),
        flowOptimized: Bool = true,
        targetDuration: TimeInterval? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.criteriaData = (try? JSONEncoder().encode(criteria)) ?? Data()
        self.songIDs = songIDs
        self.autoRefresh = autoRefresh
        self.refreshInterval = refreshInterval
        self.lastRefreshed = lastRefreshed
        self.flowOptimized = flowOptimized
        self.targetDuration = targetDuration
        self.createdAt = createdAt
    }

    var criteria: PlaylistCriteria? {
        try? JSONDecoder().decode(PlaylistCriteria.self, from: criteriaData)
    }
}

// MARK: - Play History Entry

/// Records when and how a song was played
@Model
final class PlayHistoryEntry {
    var id: UUID
    var songID: UUID
    var playedAt: Date
    var context: String // PlayContext raw value
    var duration: TimeInterval
    var completedPercentage: Float

    init(
        id: UUID = UUID(),
        songID: UUID,
        playedAt: Date = Date(),
        context: PlayContext,
        duration: TimeInterval,
        completedPercentage: Float
    ) {
        self.id = id
        self.songID = songID
        self.playedAt = playedAt
        self.context = context.rawValue
        self.duration = duration
        self.completedPercentage = completedPercentage
    }
}

// MARK: - Song Characteristics

/// Analyzed characteristics of a song (not persisted, computed on demand)
struct SongCharacteristics: Codable {
    var songID: UUID
    var key: String
    var tempo: Int
    var timeSignature: String
    var chordComplexity: Float
    var chordCount: Int
    var uniqueChords: Int
    var lyricThemes: [String]
    var estimatedGenre: String?
    var harmonicComplexity: Float
    var songStructure: SongStructure?
    var estimatedDuration: TimeInterval?

    init(
        songID: UUID,
        key: String,
        tempo: Int = 120,
        timeSignature: String = "4/4",
        chordComplexity: Float = 0.5,
        chordCount: Int = 0,
        uniqueChords: Int = 0,
        lyricThemes: [String] = [],
        estimatedGenre: String? = nil,
        harmonicComplexity: Float = 0.5,
        songStructure: SongStructure? = nil,
        estimatedDuration: TimeInterval? = nil
    ) {
        self.songID = songID
        self.key = key
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.chordComplexity = chordComplexity
        self.chordCount = chordCount
        self.uniqueChords = uniqueChords
        self.lyricThemes = lyricThemes
        self.estimatedGenre = estimatedGenre
        self.harmonicComplexity = harmonicComplexity
        self.songStructure = songStructure
        self.estimatedDuration = estimatedDuration
    }
}

// MARK: - Song Structure

struct SongStructure: Codable {
    var hasIntro: Bool
    var hasVerse: Bool
    var hasChorus: Bool
    var hasBridge: Bool
    var hasOutro: Bool
    var verseCount: Int
    var chorusCount: Int
    var bridgeCount: Int
}

// MARK: - Supporting Enums

enum RecommendationType: String, Codable {
    case similar = "similar"
    case collaborative = "collaborative"
    case discovery = "discovery"
    case contextAware = "contextAware"
    case smartPlaylist = "smartPlaylist"
    case trending = "trending"
    case personalFavorite = "personalFavorite"
}

enum RecommendationReason: String, Codable {
    case sameKey = "Same key"
    case similarTempo = "Similar tempo"
    case similarChordComplexity = "Similar chord complexity"
    case similarLyricThemes = "Similar lyric themes"
    case sameGenre = "Same genre"
    case sameArtist = "Same artist"
    case frequentlyPlayedTogether = "Frequently played together"
    case popularWithSimilarUsers = "Popular with similar users"
    case complementsCurrentSong = "Complements current song"
    case smoothKeyTransition = "Smooth key transition"
    case smoothTempoTransition = "Smooth tempo transition"
    case maintainsEnergyFlow = "Maintains energy flow"
    case userPreference = "Matches your preferences"
    case trending = "Trending"
    case unplayed = "You haven't played this yet"
    case rediscovery = "Rediscover this song"
}

enum FeedbackType: String, Codable {
    case liked = "liked"
    case disliked = "disliked"
    case notInterested = "notInterested"
    case accepted = "accepted" // Added to set or played
}

enum PlayContext: String, Codable {
    case worship = "worship"
    case practice = "practice"
    case performance = "performance"
    case rehearsal = "rehearsal"
    case teaching = "teaching"
    case casual = "casual"
}

enum CapoPreference: String, Codable {
    case avoidsCapo = "avoidsCapo" // Prefers no capo
    case neutral = "neutral"
    case prefersCapo = "prefersCapo" // Prefers using capo
}

enum TempoCategory: String, Codable {
    case verySlow = "verySlow" // < 60 BPM
    case slow = "slow" // 60-80 BPM
    case moderate = "moderate" // 80-110 BPM
    case fast = "fast" // 110-140 BPM
    case veryFast = "veryFast" // > 140 BPM

    static func category(for tempo: Int) -> TempoCategory {
        switch tempo {
        case 0..<60: return .verySlow
        case 60..<80: return .slow
        case 80..<110: return .moderate
        case 110..<140: return .fast
        default: return .veryFast
        }
    }

    var bpmRange: ClosedRange<Int> {
        switch self {
        case .verySlow: return 0...59
        case .slow: return 60...79
        case .moderate: return 80...109
        case .fast: return 110...139
        case .veryFast: return 140...240
        }
    }
}

// MARK: - Playlist Criteria

enum PlaylistCriteria: Codable {
    case mood(Mood)
    case key(String)
    case tempo(TempoCategory)
    case theme(String)
    case artist(String)
    case genre(String)
    case noCapo
    case simple
    case complex
    case recent
    case unplayed
    case combined([PlaylistCriteria])

    var description: String {
        switch self {
        case .mood(let mood):
            return "Mood: \(mood.rawValue)"
        case .key(let key):
            return "Key: \(key)"
        case .tempo(let tempo):
            return "Tempo: \(tempo.rawValue)"
        case .theme(let theme):
            return "Theme: \(theme)"
        case .artist(let artist):
            return "Artist: \(artist)"
        case .genre(let genre):
            return "Genre: \(genre)"
        case .noCapo:
            return "No Capo"
        case .simple:
            return "Simple Chords"
        case .complex:
            return "Complex Chords"
        case .recent:
            return "Recently Added"
        case .unplayed:
            return "Unplayed"
        case .combined(let criteria):
            return criteria.map { $0.description }.joined(separator: ", ")
        }
    }
}

// MARK: - Mood Enum

enum Mood: String, Codable, CaseIterable {
    case joyful = "joyful"
    case peaceful = "peaceful"
    case celebratory = "celebratory"
    case reflective = "reflective"
    case hopeful = "hopeful"
    case solemn = "solemn"
    case energetic = "energetic"
    case intimate = "intimate"
    case triumphant = "triumphant"
    case contemplative = "contemplative"
}

// MARK: - Discovery Section

enum DiscoverySection: String, CaseIterable {
    case unplayed = "Unplayed"
    case trending = "Trending"
    case hiddenGems = "Hidden Gems"
    case personalized = "For You"
    case seasonal = "Seasonal"
    case forgotten = "Rediscover"
}

// MARK: - Recommendation Context

struct RecommendationContext: Codable {
    var currentSong: UUID?
    var currentSet: UUID?
    var timeOfDay: TimeOfDay
    var sessionType: PlayContext
    var energyLevel: EnergyLevel?
    var targetMood: Mood?

    enum TimeOfDay: String, Codable {
        case morning = "morning" // 6am-12pm
        case afternoon = "afternoon" // 12pm-6pm
        case evening = "evening" // 6pm-10pm
        case night = "night" // 10pm-6am

        static var current: TimeOfDay {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 6..<12: return .morning
            case 12..<18: return .afternoon
            case 18..<22: return .evening
            default: return .night
            }
        }
    }

    enum EnergyLevel: String, Codable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        case building = "building"
        case declining = "declining"
    }
}

// MARK: - Helper Extensions

extension Array where Element == String {
    /// Calculate frequency distribution
    func frequency() -> [(element: String, count: Int)] {
        var counts: [String: Int] = [:]
        for element in self {
            counts[element, default: 0] += 1
        }
        return counts.map { (element: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    /// Get top N most frequent elements
    func topN(_ n: Int) -> [String] {
        return frequency().prefix(n).map { $0.element }
    }
}

extension Array where Element == Int {
    /// Detect tempo ranges from play history
    func detectTempoRanges() -> [TempoCategory] {
        let categories = self.map { TempoCategory.category(for: $0) }
        let frequentCategories = categories.map { $0.rawValue }.topN(3)
        return frequentCategories.compactMap { TempoCategory(rawValue: $0) }
    }
}
