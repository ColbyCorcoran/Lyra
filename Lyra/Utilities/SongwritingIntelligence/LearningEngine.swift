//
//  LearningEngine.swift
//  Lyra
//
//  Phase 7.14: AI Songwriting Assistance - Learning Intelligence
//  On-device learning from user preferences and writing style
//

import Foundation
import SwiftData

/// Engine for learning user's writing style and preferences
/// Provides personalized suggestions that improve over time (100% on-device)
@MainActor
class LearningEngine {

    // MARK: - Shared Instance
    static let shared = LearningEngine()

    // MARK: - Storage
    private var userProfile: WritingProfile?
    private var preferenceHistory: [UserPreference] = []
    private var writingPatterns: [WritingPattern] = []

    // MARK: - Profile Learning

    /// Initialize user profile
    func initializeProfile(userID: String) -> WritingProfile {
        let profile = WritingProfile(
            userID: userID,
            preferredGenres: [],
            favoriteKeys: [],
            typicalTempo: 120,
            chordPreferences: [:],
            lyricStyle: .descriptive,
            structurePreferences: []
        )

        userProfile = profile
        return profile
    }

    /// Learn from user's song choices
    func learnFromSong(
        chords: [String],
        key: String,
        tempo: Int,
        genre: String,
        structure: [String]
    ) {
        guard var profile = userProfile else { return }

        // Track genre preference
        if !profile.preferredGenres.contains(genre) {
            profile.preferredGenres.append(genre)
        }

        // Track key preference
        profile.favoriteKeys[key, default: 0] += 1

        // Update typical tempo (running average)
        let tempoWeight = 0.1
        profile.typicalTempo = Int(Double(profile.typicalTempo) * (1 - tempoWeight) + Double(tempo) * tempoWeight)

        // Track chord usage
        for chord in chords {
            profile.chordPreferences[chord, default: 0] += 1
        }

        // Track structure preference
        let structurePattern = structure.joined(separator: "-")
        if !profile.structurePreferences.contains(structurePattern) {
            profile.structurePreferences.append(structurePattern)
        }

        userProfile = profile

        // Record as writing pattern
        let pattern = WritingPattern(
            chords: chords,
            key: key,
            tempo: tempo,
            genre: genre,
            structure: structure,
            usageCount: 1
        )
        writingPatterns.append(pattern)
    }

    /// Learn from user feedback on suggestions
    func learnFromFeedback(
        suggestionType: String,
        accepted: Bool,
        suggestionContent: String
    ) {
        let preference = UserPreference(
            suggestionType: suggestionType,
            accepted: accepted,
            content: suggestionContent
        )

        preferenceHistory.append(preference)

        // Adjust future suggestions based on feedback
        adjustSuggestionWeights(for: suggestionType, accepted: accepted)
    }

    /// Get personalized chord suggestions
    func getPersonalizedChordSuggestions(
        currentChord: String,
        count: Int = 3
    ) -> [String] {
        guard let profile = userProfile else {
            return ["C", "F", "G"] // Default
        }

        // Get user's most used chords
        let sortedChords = profile.chordPreferences.sorted { $0.value > $1.value }

        // Filter to chords that make sense after current chord
        // For simplicity, return top used chords
        return sortedChords.prefix(count).map { $0.key }
    }

    /// Get personalized key suggestions
    func getPersonalizedKeySuggestions(count: Int = 5) -> [String] {
        guard let profile = userProfile else {
            return ["C", "G", "D", "A", "E"]
        }

        let sortedKeys = profile.favoriteKeys.sorted { $0.value > $1.value }
        return sortedKeys.prefix(count).map { $0.key }
    }

    /// Get personalized tempo suggestion
    func getPersonalizedTempo() -> Int {
        return userProfile?.typicalTempo ?? 120
    }

    /// Get personalized genre suggestions
    func getPersonalizedGenres() -> [String] {
        return userProfile?.preferredGenres ?? ["pop", "folk", "worship"]
    }

    /// Analyze writing style
    func analyzeWritingStyle() -> WritingStyleAnalysis {
        guard let profile = userProfile else {
            return WritingStyleAnalysis(
                dominantGenre: "unknown",
                chordComplexity: .simple,
                favoriteProgressions: [],
                tempoRange: 80...140,
                lyricStyle: .descriptive,
                strengths: [],
                suggestions: []
            )
        }

        // Determine dominant genre
        let dominantGenre = profile.preferredGenres.first ?? "pop"

        // Analyze chord complexity
        let complexChords = profile.chordPreferences.keys.filter { $0.contains("7") || $0.contains("sus") }
        let chordComplexity: ChordComplexity = complexChords.count > profile.chordPreferences.count / 2 ? .complex : .simple

        // Find favorite progressions
        let favoriteProgressions = findCommonProgressions()

        // Determine tempo range
        let tempoRange = max(60, profile.typicalTempo - 20)...min(180, profile.typicalTempo + 20)

        // Generate insights
        var strengths: [String] = []
        var suggestions: [String] = []

        if profile.preferredGenres.count > 2 {
            strengths.append("Versatile across multiple genres")
        }

        if complexChords.count > 5 {
            strengths.append("Advanced harmonic vocabulary")
        } else {
            suggestions.append("Experiment with 7th chords and suspensions")
        }

        if profile.favoriteKeys.count < 3 {
            suggestions.append("Try writing in different keys for variety")
        }

        return WritingStyleAnalysis(
            dominantGenre: dominantGenre,
            chordComplexity: chordComplexity,
            favoriteProgressions: favoriteProgressions,
            tempoRange: tempoRange,
            lyricStyle: profile.lyricStyle,
            strengths: strengths,
            suggestions: suggestions
        )
    }

    /// Get improvement suggestions
    func getSuggestions(for aspect: WritingAspect) -> [ImprovementSuggestion] {
        guard let profile = userProfile else {
            return []
        }

        var suggestions: [ImprovementSuggestion] = []

        switch aspect {
        case .harmony:
            // Analyze chord usage patterns
            if profile.chordPreferences.count < 10 {
                suggestions.append(ImprovementSuggestion(
                    aspect: .harmony,
                    suggestion: "Expand your chord vocabulary - try adding 7th chords",
                    difficulty: .beginner,
                    benefit: "More harmonic interest and sophistication"
                ))
            }

        case .melody:
            suggestions.append(ImprovementSuggestion(
                aspect: .melody,
                suggestion: "Practice creating memorable hooks with 3-4 note motifs",
                difficulty: .intermediate,
                benefit: "More memorable and singable melodies"
            ))

        case .lyrics:
            suggestions.append(ImprovementSuggestion(
                aspect: .lyrics,
                suggestion: "Experiment with different rhyme schemes (ABAB, AABB, ABCB)",
                difficulty: .beginner,
                benefit: "More variety in lyrical structure"
            ))

        case .structure:
            if profile.structurePreferences.count < 3 {
                suggestions.append(ImprovementSuggestion(
                    aspect: .structure,
                    suggestion: "Try different song structures - experiment with bridges and pre-choruses",
                    difficulty: .intermediate,
                    benefit: "More dynamic and engaging arrangements"
                ))
            }

        case .overall:
            suggestions.append(contentsOf: [
                ImprovementSuggestion(
                    aspect: .overall,
                    suggestion: "Set a consistent writing schedule to develop your craft",
                    difficulty: .beginner,
                    benefit: "Steady improvement and skill development"
                ),
                ImprovementSuggestion(
                    aspect: .overall,
                    suggestion: "Study songs in your favorite genre to understand patterns",
                    difficulty: .intermediate,
                    benefit: "Deeper understanding of genre conventions"
                )
            ])
        }

        return suggestions
    }

    /// Track progress over time
    func getProgressMetrics() -> WritingProgress {
        let totalSongs = writingPatterns.count

        let uniqueKeys = Set(writingPatterns.map { $0.key }).count
        let uniqueGenres = Set(writingPatterns.map { $0.genre }).count
        let uniqueChords = Set(writingPatterns.flatMap { $0.chords }).count

        // Calculate diversity score
        let diversityScore = (Double(uniqueKeys) / 12.0 * 0.3) +
                            (Double(uniqueGenres) / 5.0 * 0.4) +
                            (Double(uniqueChords) / 20.0 * 0.3)

        // Calculate recent activity
        let recentPatterns = writingPatterns.filter { $0.timestamp > Date().addingTimeInterval(-30*24*60*60) }
        let songsThisMonth = recentPatterns.count

        return WritingProgress(
            totalSongs: totalSongs,
            uniqueKeys: uniqueKeys,
            uniqueGenres: uniqueGenres,
            uniqueChords: uniqueChords,
            diversityScore: min(diversityScore, 1.0),
            songsThisMonth: songsThisMonth,
            improvementAreas: identifyImprovementAreas()
        )
    }

    // MARK: - Helper Methods

    private func adjustSuggestionWeights(for type: String, accepted: Bool) {
        // Adjust internal weights for future suggestions
        // In a real implementation, this would update ML model weights
        // For now, just track the feedback
    }

    private func findCommonProgressions() -> [String] {
        // Analyze patterns to find common chord progressions
        var progressionCounts: [String: Int] = [:]

        for pattern in writingPatterns {
            let progression = pattern.chords.prefix(4).joined(separator: "-")
            progressionCounts[progression, default: 0] += 1
        }

        return progressionCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }

    private func identifyImprovementAreas() -> [String] {
        var areas: [String] = []

        guard let profile = userProfile else {
            return areas
        }

        if profile.favoriteKeys.count < 3 {
            areas.append("Key variety")
        }

        if profile.chordPreferences.count < 12 {
            areas.append("Chord vocabulary")
        }

        if profile.preferredGenres.count < 2 {
            areas.append("Genre exploration")
        }

        return areas
    }
}

// MARK: - Data Models

enum LyricStyle: String, Codable {
    case descriptive = "Descriptive"
    case abstract = "Abstract"
    case narrative = "Narrative"
    case conversational = "Conversational"
}

enum WritingAspect: String, Codable, CaseIterable {
    case harmony = "Harmony"
    case melody = "Melody"
    case lyrics = "Lyrics"
    case structure = "Structure"
    case overall = "Overall"
}

enum DifficultyLevel: String, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

struct WritingProfile: Codable {
    let userID: String
    var preferredGenres: [String]
    var favoriteKeys: [String: Int]
    var typicalTempo: Int
    var chordPreferences: [String: Int]
    var lyricStyle: LyricStyle
    var structurePreferences: [String]
    let createdAt: Date = Date()
    var lastUpdated: Date = Date()
}

struct UserPreference: Identifiable, Codable {
    let id: UUID = UUID()
    let suggestionType: String
    let accepted: Bool
    let content: String
    let timestamp: Date = Date()
}

struct WritingPattern: Identifiable, Codable {
    let id: UUID = UUID()
    let chords: [String]
    let key: String
    let tempo: Int
    let genre: String
    let structure: [String]
    var usageCount: Int
    let timestamp: Date = Date()
}

struct WritingStyleAnalysis: Codable {
    let dominantGenre: String
    let chordComplexity: ChordComplexity
    let favoriteProgressions: [String]
    let tempoRange: ClosedRange<Int>
    let lyricStyle: LyricStyle
    let strengths: [String]
    let suggestions: [String]
}

struct ImprovementSuggestion: Identifiable, Codable {
    let id: UUID = UUID()
    let aspect: WritingAspect
    let suggestion: String
    let difficulty: DifficultyLevel
    let benefit: String
}

struct WritingProgress: Codable {
    let totalSongs: Int
    let uniqueKeys: Int
    let uniqueGenres: Int
    let uniqueChords: Int
    let diversityScore: Double
    let songsThisMonth: Int
    let improvementAreas: [String]
}
