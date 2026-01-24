//
//  AdaptiveDifficultyEngine.swift
//  Lyra
//
//  Engine for managing progressive learning paths and difficulty adaptation
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for adaptive difficulty and learning path management
@MainActor
class AdaptiveDifficultyEngine {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let assessmentEngine: SkillAssessmentEngine

    // Difficulty thresholds
    private let beginnerChordMax = 4
    private let earlyIntermediateChordMax = 6
    private let intermediateChordMax = 8
    private let advancedChordMax = 12

    // MARK: - Initialization

    init(modelContext: ModelContext, assessmentEngine: SkillAssessmentEngine) {
        self.modelContext = modelContext
        self.assessmentEngine = assessmentEngine
    }

    // MARK: - Song Difficulty Assessment

    /// Assess difficulty of a song
    func assessSongDifficulty(song: SongAnalysisData) -> DifficultyAssessment {
        var factors = DifficultyAssessment.DifficultyFactors(
            uniqueChords: song.uniqueChordCount,
            chordComplexity: calculateChordComplexity(chords: song.chords),
            tempo: song.tempo,
            changeFrequency: calculateChangeFrequency(song: song),
            rhythmComplexity: estimateRhythmComplexity(song: song),
            songLength: song.duration,
            hasBarreChords: song.hasBarreChords,
            hasExtendedChords: song.hasExtendedChords,
            requiresFingerPicking: song.requiresFingerPicking
        )

        let overallDifficulty = calculateOverallDifficulty(factors: factors)
        let estimatedTime = estimatePracticeTime(difficulty: overallDifficulty, songLength: song.duration)
        let prerequisites = determinePrerequisites(factors: factors)

        return DifficultyAssessment(
            songID: song.id,
            overallDifficulty: overallDifficulty,
            factors: factors,
            estimatedPracticeTime: estimatedTime,
            prerequisiteSkills: prerequisites,
            assessedAt: Date()
        )
    }

    /// Calculate chord complexity score
    private func calculateChordComplexity(chords: [String]) -> Float {
        var complexityScore: Float = 0
        let chordCount = max(Float(chords.count), 1.0)

        for chord in chords {
            // Basic chords (A, C, D, E, G, Am, Dm, Em): 0.1
            // Barre chords (F, Bm, Fm, B): 0.3
            // 7th chords (C7, D7, etc.): 0.2
            // Extended chords (9th, 11th, 13th): 0.5
            // Diminished/Augmented: 0.4

            if chord.contains("maj7") || chord.contains("min7") || chord.contains("9") ||
               chord.contains("11") || chord.contains("13") {
                complexityScore += 0.5
            } else if chord.contains("dim") || chord.contains("aug") {
                complexityScore += 0.4
            } else if chord.contains("7") {
                complexityScore += 0.2
            } else if chord.hasPrefix("F") || chord.hasPrefix("B") || chord.contains("m") {
                complexityScore += 0.3
            } else {
                complexityScore += 0.1
            }
        }

        return min(complexityScore / chordCount, 1.0)
    }

    /// Calculate chord change frequency
    private func calculateChangeFrequency(song: SongAnalysisData) -> Float {
        guard song.duration > 0 else { return 0 }

        // Estimate changes per measure
        let measuresPerMinute = Float(song.tempo) / 4.0
        let totalMeasures = measuresPerMinute * Float(song.duration / 60.0)

        guard totalMeasures > 0 else { return 0 }

        return Float(song.uniqueChordCount) / totalMeasures
    }

    /// Estimate rhythm complexity
    private func estimateRhythmComplexity(song: SongAnalysisData) -> Float {
        // Simple estimation based on tempo and time signature
        var complexity: Float = 0

        // Faster tempo = more complex
        switch song.tempo {
        case 0..<80:
            complexity += 0.2
        case 80..<120:
            complexity += 0.4
        case 120..<160:
            complexity += 0.6
        default:
            complexity += 0.8
        }

        // Finger picking adds complexity
        if song.requiresFingerPicking {
            complexity += 0.3
        }

        return min(complexity, 1.0)
    }

    /// Calculate overall difficulty from factors
    private func calculateOverallDifficulty(
        factors: DifficultyAssessment.DifficultyFactors
    ) -> DifficultyAssessment.DifficultyLevel {
        let score = (Float(factors.uniqueChords) / 12.0 * 0.2) +
                    (factors.chordComplexity * 0.3) +
                    (Float(factors.tempo) / 180.0 * 0.2) +
                    (factors.changeFrequency * 0.2) +
                    (factors.rhythmComplexity * 0.1)

        switch score {
        case 0..<0.2:
            return .veryEasy
        case 0.2..<0.35:
            return .easy
        case 0.35..<0.5:
            return .moderate
        case 0.5..<0.65:
            return .challenging
        case 0.65..<0.8:
            return .difficult
        default:
            return .veryDifficult
        }
    }

    /// Estimate practice time needed
    private func estimatePracticeTime(
        difficulty: DifficultyAssessment.DifficultyLevel,
        songLength: TimeInterval
    ) -> TimeInterval {
        let baseMultiplier: Double

        switch difficulty {
        case .veryEasy:
            baseMultiplier = 3.0
        case .easy:
            baseMultiplier = 5.0
        case .moderate:
            baseMultiplier = 8.0
        case .challenging:
            baseMultiplier = 12.0
        case .difficult:
            baseMultiplier = 20.0
        case .veryDifficult:
            baseMultiplier = 30.0
        }

        return songLength * baseMultiplier
    }

    /// Determine prerequisite skills
    private func determinePrerequisites(
        factors: DifficultyAssessment.DifficultyFactors
    ) -> [String] {
        var prerequisites: [String] = []

        if factors.hasBarreChords {
            prerequisites.append("Barre Chords")
        }

        if factors.hasExtendedChords {
            prerequisites.append("Extended Chords (7th, 9th, etc.)")
        }

        if factors.requiresFingerPicking {
            prerequisites.append("Finger Picking")
        }

        if factors.tempo > 140 {
            prerequisites.append("Fast Tempo Control")
        }

        if factors.chordComplexity > 0.6 {
            prerequisites.append("Complex Chord Shapes")
        }

        return prerequisites
    }

    // MARK: - Learning Path Generation

    /// Generate a learning path based on skill level and goals
    func generateLearningPath(
        allSongs: [SongAnalysisData],
        skillLevel: SkillLevel,
        goals: [LearningPath.LearningGoal],
        practiceHistory: [PracticeSession]
    ) -> LearningPath {
        // Get mastered songs
        let masteredSongs = getMasteredSongs(history: practiceHistory)

        // Get current challenge songs (songs being practiced)
        let currentChallengeSongs = getCurrentChallengeSongs(
            allSongs: allSongs,
            history: practiceHistory,
            masteredSongs: masteredSongs
        )

        // Get next challenge songs
        let nextChallengeSongs = getNextChallengeSongs(
            allSongs: allSongs,
            skillLevel: skillLevel,
            goals: goals,
            masteredSongs: masteredSongs,
            currentSongs: currentChallengeSongs
        )

        // Calculate progress
        let progressPercentage = calculateProgress(
            skillLevel: skillLevel,
            masteredCount: masteredSongs.count
        )

        return LearningPath(
            currentLevel: skillLevel,
            masteredSongs: masteredSongs,
            currentChallengeSongs: currentChallengeSongs,
            nextChallengeSongs: nextChallengeSongs,
            progressPercentage: progressPercentage,
            goals: goals,
            lastUpdated: Date()
        )
    }

    /// Get mastered song IDs from practice history
    private func getMasteredSongs(history: [PracticeSession]) -> [UUID] {
        var songMastery: [UUID: (count: Int, avgScore: Float)] = [:]

        for session in history {
            guard let metrics = session.skillMetrics else { continue }

            if var data = songMastery[session.songID] {
                data.count += 1
                data.avgScore = (data.avgScore + metrics.overallScore) / 2.0
                songMastery[session.songID] = data
            } else {
                songMastery[session.songID] = (1, metrics.overallScore)
            }
        }

        // Song is mastered if practiced 3+ times with 0.75+ average score
        return songMastery.filter { $0.value.count >= 3 && $0.value.avgScore >= 0.75 }
            .map { $0.key }
    }

    /// Get songs currently being practiced
    private func getCurrentChallengeSongs(
        allSongs: [SongAnalysisData],
        history: [PracticeSession],
        masteredSongs: [UUID]
    ) -> [UUID] {
        let recentHistory = history.sorted { $0.startTime > $1.startTime }.prefix(20)
        var songCounts: [UUID: Int] = [:]

        for session in recentHistory {
            if !masteredSongs.contains(session.songID) {
                songCounts[session.songID, default: 0] += 1
            }
        }

        return songCounts.filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    /// Get next recommended challenge songs
    private func getNextChallengeSongs(
        allSongs: [SongAnalysisData],
        skillLevel: SkillLevel,
        goals: [LearningPath.LearningGoal],
        masteredSongs: [UUID],
        currentSongs: [UUID]
    ) -> [UUID] {
        let practicedSongIDs = Set(masteredSongs + currentSongs)

        // Filter unpracticed songs matching skill level
        let candidates = allSongs.filter { song in
            !practicedSongIDs.contains(song.id) &&
            isAppropriateForSkillLevel(song: song, skillLevel: skillLevel)
        }

        // Sort by goal alignment
        let sorted = candidates.sorted { song1, song2 in
            let score1 = scoreForGoals(song: song1, goals: goals)
            let score2 = scoreForGoals(song: song2, goals: goals)
            return score1 > score2
        }

        return sorted.prefix(5).map { $0.id }
    }

    /// Check if song is appropriate for skill level
    private func isAppropriateForSkillLevel(song: SongAnalysisData, skillLevel: SkillLevel) -> Bool {
        let assessment = assessSongDifficulty(song: song)

        switch skillLevel {
        case .beginner:
            return assessment.overallDifficulty == .veryEasy || assessment.overallDifficulty == .easy
        case .earlyIntermediate:
            return assessment.overallDifficulty == .easy || assessment.overallDifficulty == .moderate
        case .intermediate:
            return assessment.overallDifficulty == .moderate || assessment.overallDifficulty == .challenging
        case .advanced:
            return assessment.overallDifficulty == .challenging || assessment.overallDifficulty == .difficult
        case .expert:
            return true  // All difficulty levels appropriate
        }
    }

    /// Score song for goal alignment
    private func scoreForGoals(song: SongAnalysisData, goals: [LearningPath.LearningGoal]) -> Float {
        var score: Float = 0

        for goal in goals {
            switch goal {
            case .improveChordChanges:
                score += Float(song.uniqueChordCount) / 10.0
            case .learnNewSongs:
                score += 1.0
            case .masterBarreChords:
                score += song.hasBarreChords ? 2.0 : 0.0
            case .increaseSpeed:
                score += song.tempo > 120 ? 1.5 : 0.5
            case .improveRhythm:
                score += song.requiresFingerPicking ? 1.5 : 1.0
            case .expandRepertoire:
                score += 1.0
            case .learnFingerPicking:
                score += song.requiresFingerPicking ? 2.0 : 0.0
            case .masterTheory:
                score += song.hasExtendedChords ? 1.5 : 0.5
            }
        }

        return score
    }

    /// Calculate learning progress percentage
    private func calculateProgress(skillLevel: SkillLevel, masteredCount: Int) -> Float {
        // Simple progression based on mastered songs
        let targetForLevel: Int

        switch skillLevel {
        case .beginner:
            targetForLevel = 5
        case .earlyIntermediate:
            targetForLevel = 10
        case .intermediate:
            targetForLevel = 20
        case .advanced:
            targetForLevel = 40
        case .expert:
            targetForLevel = 60
        }

        return min(Float(masteredCount) / Float(targetForLevel), 1.0)
    }

    // MARK: - Next Challenge Selection

    /// Suggest next challenge song slightly above current level
    func suggestNextChallenge(
        allSongs: [SongAnalysisData],
        currentLevel: SkillLevel,
        masteredSongs: [UUID]
    ) -> SongAnalysisData? {
        // Get songs not yet mastered
        let unmastered = allSongs.filter { !masteredSongs.contains($0.id) }

        // Find songs at next difficulty level
        let nextLevel = getNextSkillLevel(current: currentLevel)
        let appropriate = unmastered.filter { song in
            isAppropriateForSkillLevel(song: song, skillLevel: nextLevel)
        }

        // Return easiest song at next level
        return appropriate.min { song1, song2 in
            let diff1 = assessSongDifficulty(song: song1)
            let diff2 = assessSongDifficulty(song: song2)
            return diff1.overallDifficulty.numericValue < diff2.overallDifficulty.numericValue
        }
    }

    /// Get next skill level
    private func getNextSkillLevel(current: SkillLevel) -> SkillLevel {
        switch current {
        case .beginner: return .earlyIntermediate
        case .earlyIntermediate: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return .expert
        case .expert: return .expert
        }
    }
}

// MARK: - Supporting Types

/// Song analysis data (placeholder - would integrate with actual Song model)
struct SongAnalysisData {
    var id: UUID
    var title: String
    var uniqueChordCount: Int
    var chords: [String]
    var tempo: Int
    var duration: TimeInterval
    var hasBarreChords: Bool
    var hasExtendedChords: Bool
    var requiresFingerPicking: Bool
}
