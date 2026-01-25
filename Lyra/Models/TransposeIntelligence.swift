//
//  TransposeIntelligence.swift
//  Lyra
//
//  Data models for AI-Enhanced Transpose Intelligence system
//  Part of Phase 7.9: Transpose Intelligence
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Transpose Recommendation

/// A recommendation for transposing a song with multi-factor analysis
struct TransposeRecommendation: Identifiable, Codable {
    var id: UUID
    var targetKey: String
    var semitones: Int
    var confidenceScore: Float // 0.0-1.0
    var overallScore: Float // 0-100

    // Multi-factor breakdown
    var voiceRangeScore: Float?
    var difficultyScore: Float // 0-10 (enhanced from 1-5)
    var capoScore: Float?
    var userPreferenceScore: Float
    var bandFitnessScore: Float?

    // Explanations
    var benefits: [TransposeBenefit]
    var warnings: [TransposeWarning]
    var theoryExplanation: TheoryExplanation?
    var suggestedCapo: Int?

    init(
        id: UUID = UUID(),
        targetKey: String,
        semitones: Int,
        confidenceScore: Float,
        overallScore: Float,
        voiceRangeScore: Float? = nil,
        difficultyScore: Float,
        capoScore: Float? = nil,
        userPreferenceScore: Float,
        bandFitnessScore: Float? = nil,
        benefits: [TransposeBenefit] = [],
        warnings: [TransposeWarning] = [],
        theoryExplanation: TheoryExplanation? = nil,
        suggestedCapo: Int? = nil
    ) {
        self.id = id
        self.targetKey = targetKey
        self.semitones = semitones
        self.confidenceScore = confidenceScore
        self.overallScore = overallScore
        self.voiceRangeScore = voiceRangeScore
        self.difficultyScore = difficultyScore
        self.capoScore = capoScore
        self.userPreferenceScore = userPreferenceScore
        self.bandFitnessScore = bandFitnessScore
        self.benefits = benefits
        self.warnings = warnings
        self.theoryExplanation = theoryExplanation
        self.suggestedCapo = suggestedCapo
    }
}

// MARK: - Transpose Benefit

/// A benefit of a transpose recommendation
struct TransposeBenefit: Identifiable, Codable {
    var id: UUID
    var category: BenefitCategory
    var description: String
    var impact: Float // 0.0-1.0
    var icon: String

    init(
        id: UUID = UUID(),
        category: BenefitCategory,
        description: String,
        impact: Float,
        icon: String
    ) {
        self.id = id
        self.category = category
        self.description = description
        self.impact = impact
        self.icon = icon
    }

    enum BenefitCategory: String, Codable {
        case vocalFit = "Vocal Fit"
        case easierChords = "Easier Chords"
        case capoOption = "Capo Option"
        case bandFit = "Band Fit"
        case userPreference = "User Preference"

        var color: Color {
            switch self {
            case .vocalFit: return .green
            case .easierChords: return .blue
            case .capoOption: return .orange
            case .bandFit: return .purple
            case .userPreference: return .pink
            }
        }
    }
}

// MARK: - Transpose Warning

/// A warning about a transpose recommendation
struct TransposeWarning: Identifiable, Codable {
    var id: UUID
    var severity: WarningSeverity
    var issue: String
    var mitigation: String?

    init(
        id: UUID = UUID(),
        severity: WarningSeverity,
        issue: String,
        mitigation: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.issue = issue
        self.mitigation = mitigation
    }

    enum WarningSeverity: String, Codable {
        case info = "Info"
        case caution = "Caution"
        case warning = "Warning"

        var color: Color {
            switch self {
            case .info: return .blue
            case .caution: return .orange
            case .warning: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .caution: return "exclamationmark.triangle"
            case .warning: return "exclamationmark.octagon"
            }
        }
    }
}

// MARK: - Theory Explanation

/// Educational explanation of key relationships and music theory
struct TheoryExplanation: Codable {
    var summary: String
    var keyRelationship: KeyRelationship
    var circleOfFifthsDistance: Int
    var keySignature: String
    var educationalNotes: [String]

    init(
        summary: String,
        keyRelationship: KeyRelationship,
        circleOfFifthsDistance: Int,
        keySignature: String,
        educationalNotes: [String] = []
    ) {
        self.summary = summary
        self.keyRelationship = keyRelationship
        self.circleOfFifthsDistance = circleOfFifthsDistance
        self.keySignature = keySignature
        self.educationalNotes = educationalNotes
    }
}

// MARK: - Musician Profile

/// Profile for a band member with instrument and capabilities
struct MusicianProfile: Identifiable, Codable {
    var id: UUID
    var name: String
    var instrument: String
    var vocalRange: VocalRange?
    var skillLevel: SkillLevel
    var preferences: [String: String]

    init(
        id: UUID = UUID(),
        name: String,
        instrument: String,
        vocalRange: VocalRange? = nil,
        skillLevel: SkillLevel = .intermediate,
        preferences: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.instrument = instrument
        self.vocalRange = vocalRange
        self.skillLevel = skillLevel
        self.preferences = preferences
    }
}

// MARK: - Smart Transpose Result

/// Result of smart transpose analysis
struct SmartTransposeResult {
    var recommendations: [TransposeRecommendation]
    var analysisTimestamp: Date
    var contextUsed: TransposeContext

    init(
        recommendations: [TransposeRecommendation],
        analysisTimestamp: Date = Date(),
        contextUsed: TransposeContext
    ) {
        self.recommendations = recommendations
        self.analysisTimestamp = analysisTimestamp
        self.contextUsed = contextUsed
    }
}

// MARK: - Transpose Context

/// Context information for transpose analysis
struct TransposeContext {
    var vocalRange: VocalRange?
    var skillLevel: SkillLevel
    var bandMembers: [MusicianProfile]?
    var setlistContext: PerformanceSet?

    init(
        vocalRange: VocalRange? = nil,
        skillLevel: SkillLevel = .intermediate,
        bandMembers: [MusicianProfile]? = nil,
        setlistContext: PerformanceSet? = nil
    ) {
        self.vocalRange = vocalRange
        self.skillLevel = skillLevel
        self.bandMembers = bandMembers
        self.setlistContext = setlistContext
    }
}

// MARK: - Transpose History (SwiftData)

/// Historical record of transpose operations for learning
@Model
class TransposeHistory {
    @Attribute(.unique) var id: UUID
    var songID: UUID
    var originalKey: String
    var newKey: String
    var semitones: Int
    var timestamp: Date
    var kept: Bool // Did user keep the change?
    var revertedAfter: TimeInterval? // If reverted, how long?
    var userSatisfaction: Int? // 1-5 rating
    var recommendationID: UUID? // Which recommendation was chosen

    init(
        id: UUID = UUID(),
        songID: UUID,
        originalKey: String,
        newKey: String,
        semitones: Int,
        timestamp: Date = Date(),
        kept: Bool = true,
        revertedAfter: TimeInterval? = nil,
        userSatisfaction: Int? = nil,
        recommendationID: UUID? = nil
    ) {
        self.id = id
        self.songID = songID
        self.originalKey = originalKey
        self.newKey = newKey
        self.semitones = semitones
        self.timestamp = timestamp
        self.kept = kept
        self.revertedAfter = revertedAfter
        self.userSatisfaction = userSatisfaction
        self.recommendationID = recommendationID
    }
}

// MARK: - Problem Key Record (SwiftData)

/// Record of keys that caused problems for the user
@Model
class ProblemKeyRecord {
    @Attribute(.unique) var id: UUID
    var songID: UUID
    var key: String
    var issuesData: Data? // JSON-encoded [String]
    var timestamp: Date
    var resolved: Bool

    init(
        id: UUID = UUID(),
        songID: UUID,
        key: String,
        issues: [String] = [],
        timestamp: Date = Date(),
        resolved: Bool = false
    ) {
        self.id = id
        self.songID = songID
        self.key = key
        self.timestamp = timestamp
        self.resolved = resolved

        // Encode issues as JSON
        if let data = try? JSONEncoder().encode(issues) {
            self.issuesData = data
        }
    }

    /// Get issues as array of strings
    var issues: [String] {
        get {
            guard let data = issuesData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            issuesData = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Band Member Profile (SwiftData)

/// Persistent profile for band members
@Model
class BandMemberProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var instrument: String
    var vocalRangeData: Data? // Encoded VocalRange
    var skillLevel: String
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        instrument: String,
        vocalRange: VocalRange? = nil,
        skillLevel: SkillLevel = .intermediate,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.instrument = instrument
        self.skillLevel = skillLevel.rawValue
        self.isActive = isActive
        self.createdAt = createdAt

        // Encode vocal range
        if let range = vocalRange {
            self.vocalRangeData = try? JSONEncoder().encode(range)
        }
    }

    /// Get vocal range
    var vocalRange: VocalRange? {
        get {
            guard let data = vocalRangeData else { return nil }
            return try? JSONDecoder().decode(VocalRange.self, from: data)
        }
        set {
            vocalRangeData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Get skill level enum
    var skillLevelEnum: SkillLevel {
        SkillLevel(rawValue: skillLevel) ?? .intermediate
    }

    /// Convert to MusicianProfile for analysis
    func toMusicianProfile() -> MusicianProfile {
        MusicianProfile(
            id: id,
            name: name,
            instrument: instrument,
            vocalRange: vocalRange,
            skillLevel: skillLevelEnum,
            preferences: [:]
        )
    }
}

// PerformanceSet model is defined in Models/PerformanceSet.swift
