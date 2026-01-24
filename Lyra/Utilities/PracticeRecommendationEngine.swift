//
//  PracticeRecommendationEngine.swift
//  Lyra
//
//  Engine for generating personalized practice recommendations
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for generating AI-powered practice recommendations
@MainActor
class PracticeRecommendationEngine {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let trackingEngine: PracticeTrackingEngine
    private let assessmentEngine: SkillAssessmentEngine

    // Recommendation weights
    private let rustySongDaysThreshold = 7.0  // Days since last practice
    private let masteryThreshold: Float = 0.75
    private let weeklyRecommendationCount = 7

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        trackingEngine: PracticeTrackingEngine,
        assessmentEngine: SkillAssessmentEngine
    ) {
        self.modelContext = modelContext
        self.trackingEngine = trackingEngine
        self.assessmentEngine = assessmentEngine
    }

    // MARK: - Weekly Recommendations

    /// Generate weekly practice recommendations
    func generateWeeklyRecommendations(
        allSongs: [SongData],
        practiceHistory: [PracticeSession],
        userSkillLevel: SkillLevel
    ) -> [PracticeRecommendation] {
        var recommendations: [PracticeRecommendation] = []

        // 1. Get rusty songs (songs not practiced recently)
        let rustySongs = detectRustySongs(
            allSongs: allSongs,
            practiceHistory: practiceHistory
        )

        for song in rustySongs.prefix(2) {
            let recommendation = PracticeRecommendation(
                songID: song.id,
                songTitle: song.title,
                reason: .needsReview,
                priority: 8,
                estimatedTime: 10 * 60,  // 10 minutes
                focusAreas: [.overall],
                createdAt: Date()
            )
            recommendations.append(recommendation)
        }

        // 2. Get songs matching skill level
        let skillMatchedSongs = findSkillMatchedSongs(
            allSongs: allSongs,
            practiceHistory: practiceHistory,
            skillLevel: userSkillLevel
        )

        for song in skillMatchedSongs.prefix(3) {
            let recommendation = PracticeRecommendation(
                songID: song.id,
                songTitle: song.title,
                reason: .skillMatch,
                priority: 6,
                estimatedTime: 15 * 60,  // 15 minutes
                focusAreas: determineFocusAreas(song: song, history: practiceHistory),
                createdAt: Date()
            )
            recommendations.append(recommendation)
        }

        // 3. Get challenge song (slightly above skill level)
        if let challengeSong = suggestNextChallenge(
            allSongs: allSongs,
            practiceHistory: practiceHistory,
            currentSkillLevel: userSkillLevel
        ) {
            let recommendation = PracticeRecommendation(
                songID: challengeSong.id,
                songTitle: challengeSong.title,
                reason: .nextChallenge,
                priority: 7,
                estimatedTime: 20 * 60,  // 20 minutes
                focusAreas: [.overall],
                createdAt: Date()
            )
            recommendations.append(recommendation)
        }

        // 4. Get songs aligned with weaknesses
        let weaknessAnalysis = assessmentEngine.analyzeWeaknesses(history: practiceHistory)
        let weaknessAlignedSongs = findWeaknessAlignedSongs(
            allSongs: allSongs,
            weaknesses: weaknessAnalysis.primaryWeaknesses
        )

        for song in weaknessAlignedSongs.prefix(2) {
            let recommendation = PracticeRecommendation(
                songID: song.id,
                songTitle: song.title,
                reason: .weaknessAlignment,
                priority: 9,
                estimatedTime: 15 * 60,  // 15 minutes
                focusAreas: weaknessAnalysis.primaryWeaknesses,
                createdAt: Date()
            )
            recommendations.append(recommendation)
        }

        // Sort by priority and return top recommendations
        return Array(recommendations.sorted { $0.priority > $1.priority }.prefix(weeklyRecommendationCount))
    }

    // MARK: - Rusty Song Detection

    /// Detect songs that haven't been practiced recently
    func detectRustySongs(
        allSongs: [SongData],
        practiceHistory: [PracticeSession],
        threshold: Double = 7.0
    ) -> [SongData] {
        let thresholdDate = Date().addingTimeInterval(-threshold * 24 * 60 * 60)

        // Group sessions by song
        var songLastPracticed: [UUID: Date] = [:]
        var songMasteryLevel: [UUID: Float] = [:]

        for session in practiceHistory {
            if let existingDate = songLastPracticed[session.songID] {
                songLastPracticed[session.songID] = max(existingDate, session.startTime)
            } else {
                songLastPracticed[session.songID] = session.startTime
            }

            // Calculate mastery level
            if let metrics = session.skillMetrics {
                let currentMastery = songMasteryLevel[session.songID] ?? 0
                songMasteryLevel[session.songID] = max(currentMastery, metrics.overallScore)
            }
        }

        // Find rusty songs
        var rustySongs: [SongData] = []

        for song in allSongs {
            guard let lastPracticed = songLastPracticed[song.id] else { continue }
            let mastery = songMasteryLevel[song.id] ?? 0

            // Song is rusty if:
            // - Not practiced since threshold date
            // - Was previously mastered (or partially mastered)
            if lastPracticed < thresholdDate && mastery >= 0.5 {
                rustySongs.append(song)
            }
        }

        // Sort by how long ago they were practiced
        return rustySongs.sorted { song1, song2 in
            let date1 = songLastPracticed[song1.id] ?? Date.distantPast
            let date2 = songLastPracticed[song2.id] ?? Date.distantPast
            return date1 < date2  // Earlier date = more rusty
        }
    }

    // MARK: - Skill-Matched Songs

    /// Find songs matching user's skill level
    func findSkillMatchedSongs(
        allSongs: [SongData],
        practiceHistory: [PracticeSession],
        skillLevel: SkillLevel
    ) -> [SongData] {
        // Get songs user hasn't practiced much
        let songPracticeCounts = getSongPracticeCounts(practiceHistory: practiceHistory)

        return allSongs.filter { song in
            let practiceCount = songPracticeCounts[song.id] ?? 0

            // Song matches if:
            // - Practiced fewer than 5 times (not over-practiced)
            // - Difficulty matches skill level (would need difficulty data)
            return practiceCount < 5
        }
    }

    /// Get practice count per song
    private func getSongPracticeCounts(practiceHistory: [PracticeSession]) -> [UUID: Int] {
        var counts: [UUID: Int] = [:]

        for session in practiceHistory {
            counts[session.songID, default: 0] += 1
        }

        return counts
    }

    // MARK: - Challenge Songs

    /// Suggest next challenge song (slightly above current level)
    func suggestNextChallenge(
        allSongs: [SongData],
        practiceHistory: [PracticeSession],
        currentSkillLevel: SkillLevel
    ) -> SongData? {
        // Get songs user hasn't practiced
        let practicedSongIDs = Set(practiceHistory.map { $0.songID })
        let unpracticedSongs = allSongs.filter { !practicedSongIDs.contains($0.id) }

        // In real implementation, would filter by difficulty
        // For now, return a random unpracticed song
        return unpracticedSongs.randomElement()
    }

    // MARK: - Weakness-Aligned Songs

    /// Find songs that address user's weaknesses
    func findWeaknessAlignedSongs(
        allSongs: [SongData],
        weaknesses: [PracticeRecommendation.FocusArea]
    ) -> [SongData] {
        // In real implementation, would match songs to weakness areas
        // For now, return songs user hasn't practiced much
        return Array(allSongs.prefix(2))
    }

    // MARK: - Practice Schedule Generation

    /// Generate a balanced practice schedule
    func generatePracticeSchedule(
        availableTime: TimeInterval,
        recommendations: [PracticeRecommendation]
    ) -> PracticeSchedule {
        var selectedRecommendations: [PracticeRecommendation] = []
        var totalTime: TimeInterval = 0

        // Sort by priority
        let sortedRecommendations = recommendations.sorted { $0.priority > $1.priority }

        // Add recommendations until time limit reached
        for recommendation in sortedRecommendations {
            if totalTime + recommendation.estimatedTime <= availableTime {
                selectedRecommendations.append(recommendation)
                totalTime += recommendation.estimatedTime
            }
        }

        // Calculate balance score
        let balanceScore = calculateBalanceScore(recommendations: selectedRecommendations)

        // Determine focus of the day
        let focusOfDay = determineDailyFocus(recommendations: selectedRecommendations)

        return PracticeSchedule(
            date: Date(),
            recommendations: selectedRecommendations,
            totalEstimatedTime: totalTime,
            focusOfTheDay: focusOfDay,
            balanceScore: balanceScore
        )
    }

    /// Calculate how well-balanced a schedule is
    private func calculateBalanceScore(recommendations: [PracticeRecommendation]) -> Float {
        guard !recommendations.isEmpty else { return 0 }

        // Check diversity of focus areas
        var focusAreaCounts: [PracticeRecommendation.FocusArea: Int] = [:]

        for recommendation in recommendations {
            for focusArea in recommendation.focusAreas {
                focusAreaCounts[focusArea, default: 0] += 1
            }
        }

        // More diverse = more balanced
        let uniqueFocusAreas = focusAreaCounts.count
        let maxPossibleAreas = PracticeRecommendation.FocusArea.allCases.count

        return Float(uniqueFocusAreas) / Float(maxPossibleAreas)
    }

    /// Determine the primary focus for the day
    private func determineDailyFocus(recommendations: [PracticeRecommendation]) -> String {
        guard !recommendations.isEmpty else { return "General Practice" }

        // Count focus areas
        var focusAreaCounts: [PracticeRecommendation.FocusArea: Int] = [:]

        for recommendation in recommendations {
            for focusArea in recommendation.focusAreas {
                focusAreaCounts[focusArea, default: 0] += 1
            }
        }

        // Find most common focus area
        if let topFocus = focusAreaCounts.max(by: { $0.value < $1.value }) {
            return topFocus.key.rawValue
        }

        return "Balanced Practice"
    }

    // MARK: - Focus Area Determination

    /// Determine focus areas for a specific song based on history
    private func determineFocusAreas(
        song: SongData,
        history: [PracticeSession]
    ) -> [PracticeRecommendation.FocusArea] {
        // Get sessions for this song
        let songSessions = history.filter { $0.songID == song.id }

        guard !songSessions.isEmpty else {
            return [.overall]  // New song
        }

        // Analyze difficulties from previous sessions
        var focusAreas: [PracticeRecommendation.FocusArea] = []
        var difficultyTypeCounts: [PracticeDifficulty.DifficultyType: Int] = [:]

        for session in songSessions {
            for difficulty in session.difficulties {
                difficultyTypeCounts[difficulty.type, default: 0] += 1
            }
        }

        // Map difficulty types to focus areas
        for (type, count) in difficultyTypeCounts.sorted(by: { $0.value > $1.value }) {
            guard count >= 2 else { continue }  // At least 2 occurrences

            switch type {
            case .chordTransition:
                focusAreas.append(.chordTransitions)
            case .strummingPattern:
                focusAreas.append(.strummingPatterns)
            case .fingerPicking:
                focusAreas.append(.fingerPicking)
            case .barreChord:
                focusAreas.append(.barreChords)
            case .rhythmTiming, .tempo:
                focusAreas.append(.rhythmAccuracy)
            case .memory:
                focusAreas.append(.memorization)
            default:
                break
            }
        }

        return focusAreas.isEmpty ? [.overall] : Array(focusAreas.prefix(3))
    }

    // MARK: - Smart Recommendations

    /// Get smart recommendations based on time of day and available time
    func getSmartRecommendations(
        allSongs: [SongData],
        practiceHistory: [PracticeSession],
        userSkillLevel: SkillLevel,
        availableTime: TimeInterval,
        timeOfDay: TimeOfDay = .any
    ) -> [PracticeRecommendation] {
        let allRecommendations = generateWeeklyRecommendations(
            allSongs: allSongs,
            practiceHistory: practiceHistory,
            userSkillLevel: userSkillLevel
        )

        // Filter based on available time
        var filtered = allRecommendations.filter { $0.estimatedTime <= availableTime }

        // Adjust based on time of day
        filtered = adjustForTimeOfDay(recommendations: filtered, timeOfDay: timeOfDay)

        return filtered
    }

    /// Adjust recommendations based on time of day
    private func adjustForTimeOfDay(
        recommendations: [PracticeRecommendation],
        timeOfDay: TimeOfDay
    ) -> [PracticeRecommendation] {
        var adjusted = recommendations

        switch timeOfDay {
        case .morning:
            // Morning: prioritize energetic songs, new challenges
            adjusted.sort { rec1, rec2 in
                if rec1.reason == .nextChallenge && rec2.reason != .nextChallenge {
                    return true
                }
                return rec1.priority > rec2.priority
            }

        case .evening:
            // Evening: prioritize review and maintenance
            adjusted.sort { rec1, rec2 in
                if rec1.reason == .needsReview && rec2.reason != .needsReview {
                    return true
                }
                return rec1.priority > rec2.priority
            }

        case .any:
            break
        }

        return adjusted
    }

    // MARK: - Priority Calculation

    /// Calculate priority score for a recommendation
    func calculatePriority(
        songID: UUID,
        daysSinceLastPractice: Double,
        skillLevelMatch: Float,
        weaknessAlignment: Float,
        masteryLevel: Float
    ) -> Int {
        var priority: Float = 0

        // Days since last practice (weight: 2)
        priority += Float(min(daysSinceLastPractice, 30)) / 30.0 * 2.0

        // Skill level match (weight: 3)
        priority += skillLevelMatch * 3.0

        // Weakness alignment (weight: 5)
        priority += weaknessAlignment * 5.0

        // Inverse mastery level (weight: -2, more mastered = lower priority)
        priority -= masteryLevel * 2.0

        // Clamp to 1-10 range
        return max(1, min(10, Int(priority)))
    }
}

// MARK: - Supporting Types

/// Basic song data structure (in real app, would use actual Song model)
struct SongData {
    var id: UUID
    var title: String
    var artist: String?
    var difficulty: Float  // 0.0-1.0
}

/// Time of day for practice
enum TimeOfDay {
    case morning
    case afternoon
    case evening
    case any

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<22:
            return .evening
        default:
            return .any
        }
    }
}
