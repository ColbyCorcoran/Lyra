//
//  SkillAssessmentEngine.swift
//  Lyra
//
//  Engine for assessing player skills and identifying problem areas
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for assessing player skills and progress
@MainActor
class SkillAssessmentEngine {

    // MARK: - Properties

    private let modelContext: ModelContext

    // Skill level thresholds
    private let beginnerThreshold: Float = 0.2
    private let earlyIntermediateThreshold: Float = 0.4
    private let intermediateThreshold: Float = 0.6
    private let advancedThreshold: Float = 0.8

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Chord Change Speed Assessment

    /// Assess chord change speed from a session
    func assessChordChangeSpeed(session: PracticeSession) -> Float {
        guard let metrics = session.skillMetrics else { return 0 }
        return metrics.chordChangeSpeed
    }

    /// Calculate average chord change speed from practice history
    func calculateAverageChordSpeed(history: [PracticeSession]) -> Float {
        let speeds = history.compactMap { $0.skillMetrics?.chordChangeSpeed }
        guard !speeds.isEmpty else { return 0 }

        return speeds.reduce(0, +) / Float(speeds.count)
    }

    /// Get chord change speed improvement over time
    func getChordSpeedImprovement(history: [PracticeSession]) -> Float {
        guard history.count >= 2 else { return 0 }

        let sortedSessions = history.sorted { $0.startTime < $1.startTime }

        // Compare first 5 sessions with last 5 sessions
        let firstSessions = Array(sortedSessions.prefix(5))
        let lastSessions = Array(sortedSessions.suffix(5))

        let firstAverage = calculateAverageChordSpeed(history: firstSessions)
        let lastAverage = calculateAverageChordSpeed(history: lastSessions)

        guard firstAverage > 0 else { return 0 }

        return ((lastAverage - firstAverage) / firstAverage) * 100.0  // Return as percentage
    }

    // MARK: - Rhythm Accuracy Assessment

    /// Analyze rhythm accuracy from a session
    func analyzeRhythmAccuracy(session: PracticeSession) -> Float {
        guard let metrics = session.skillMetrics else { return 0 }
        return metrics.rhythmAccuracy
    }

    /// Calculate average rhythm accuracy from history
    func calculateAverageRhythmAccuracy(history: [PracticeSession]) -> Float {
        let accuracies = history.compactMap { $0.skillMetrics?.rhythmAccuracy }
        guard !accuracies.isEmpty else { return 0 }

        return accuracies.reduce(0, +) / Float(accuracies.count)
    }

    /// Get rhythm accuracy improvement trend
    func getRhythmImprovementTrend(history: [PracticeSession]) -> [RhythmDataPoint] {
        let sortedSessions = history.sorted { $0.startTime < $1.startTime }

        return sortedSessions.compactMap { session in
            guard let accuracy = session.skillMetrics?.rhythmAccuracy else { return nil }

            return RhythmDataPoint(
                date: session.startTime,
                accuracy: accuracy,
                sessionID: session.id
            )
        }
    }

    // MARK: - Problem Section Identification

    /// Identify problem sections from practice history
    func identifyProblemSections(history: [PracticeSession]) -> [AggregatedProblemSection] {
        var sectionMap: [String: AggregatedProblemSection] = [:]

        for session in history {
            guard let metrics = session.skillMetrics else { continue }

            for problemSection in metrics.problemSections {
                if var existing = sectionMap[problemSection.sectionName] {
                    existing.totalErrors += problemSection.errorCount
                    existing.occurrences += 1
                    existing.averageSeverity = (existing.averageSeverity + problemSection.severity) / 2.0
                    existing.lastEncountered = max(existing.lastEncountered, problemSection.lastEncountered)
                    sectionMap[problemSection.sectionName] = existing
                } else {
                    let aggregated = AggregatedProblemSection(
                        sectionName: problemSection.sectionName,
                        sectionType: problemSection.sectionType,
                        totalErrors: problemSection.errorCount,
                        occurrences: 1,
                        averageSeverity: problemSection.severity,
                        lastEncountered: problemSection.lastEncountered
                    )
                    sectionMap[problemSection.sectionName] = aggregated
                }
            }
        }

        return Array(sectionMap.values).sorted { $0.averageSeverity > $1.averageSeverity }
    }

    /// Get most problematic difficulty types
    func getMostProblematicDifficulties(history: [PracticeSession]) -> [DifficultyAnalysis] {
        var difficultyMap: [PracticeDifficulty.DifficultyType: DifficultyAnalysis] = [:]

        for session in history {
            for difficulty in session.difficulties {
                if var existing = difficultyMap[difficulty.type] {
                    existing.count += 1
                    existing.totalSeverity += difficulty.severity
                    existing.lastEncountered = max(existing.lastEncountered, difficulty.timestamp)
                    difficultyMap[difficulty.type] = existing
                } else {
                    let analysis = DifficultyAnalysis(
                        type: difficulty.type,
                        count: 1,
                        totalSeverity: difficulty.severity,
                        lastEncountered: difficulty.timestamp
                    )
                    difficultyMap[difficulty.type] = analysis
                }
            }
        }

        return Array(difficultyMap.values).sorted { $0.averageSeverity > $1.averageSeverity }
    }

    // MARK: - Overall Skill Level Assessment

    /// Estimate overall skill level from practice history
    func estimateSkillLevel(history: [PracticeSession]) -> SkillLevel {
        guard !history.isEmpty else { return .beginner }

        let avgChordSpeed = calculateAverageChordSpeed(history: history)
        let avgAccuracy = calculateAverageRhythmAccuracy(history: history)
        let songsMastered = countMasteredSongs(history: history)
        let avgDifficulty = calculateAverageSongDifficulty(history: history)

        // Calculate weighted score
        var score: Float = 0

        // Chord speed component (30%)
        score += min(avgChordSpeed / 30.0, 1.0) * 0.3

        // Rhythm accuracy component (30%)
        score += avgAccuracy * 0.3

        // Songs mastered component (20%)
        score += min(Float(songsMastered) / 20.0, 1.0) * 0.2

        // Average difficulty component (20%)
        score += avgDifficulty * 0.2

        // Map score to skill level
        return skillLevelFromScore(score)
    }

    /// Convert numeric score to skill level
    private func skillLevelFromScore(_ score: Float) -> SkillLevel {
        switch score {
        case 0..<beginnerThreshold:
            return .beginner
        case beginnerThreshold..<earlyIntermediateThreshold:
            return .earlyIntermediate
        case earlyIntermediateThreshold..<intermediateThreshold:
            return .intermediate
        case intermediateThreshold..<advancedThreshold:
            return .advanced
        default:
            return .expert
        }
    }

    /// Count songs mastered based on practice history
    private func countMasteredSongs(history: [PracticeSession]) -> Int {
        var songMastery: [UUID: SongMasteryData] = [:]

        for session in history {
            if var data = songMastery[session.songID] {
                data.sessionCount += 1
                data.totalPracticeTime += session.duration
                data.averageCompletion = (data.averageCompletion + session.completionRate) / 2.0

                if let metrics = session.skillMetrics {
                    data.latestSkillScore = metrics.overallScore
                }

                songMastery[session.songID] = data
            } else {
                let data = SongMasteryData(
                    sessionCount: 1,
                    totalPracticeTime: session.duration,
                    averageCompletion: session.completionRate,
                    latestSkillScore: session.skillMetrics?.overallScore ?? 0
                )
                songMastery[session.songID] = data
            }
        }

        // Count songs as mastered if they meet criteria
        return songMastery.values.filter { data in
            data.sessionCount >= 3 &&  // At least 3 practice sessions
            data.averageCompletion >= 0.8 &&  // Average 80%+ completion
            data.latestSkillScore >= 0.7  // Latest skill score 70%+
        }.count
    }

    /// Calculate average difficulty of practiced songs
    private func calculateAverageSongDifficulty(history: [PracticeSession]) -> Float {
        // This is a placeholder - in real implementation, would reference song difficulty data
        // For now, estimate based on session complexity
        let complexityScores = history.map { session -> Float in
            let difficultyCount = Float(session.difficulties.count)
            let avgSeverity = session.difficulties.reduce(0.0) { $0 + $1.severity } / max(difficultyCount, 1.0)
            return min((difficultyCount / 10.0) * avgSeverity, 1.0)
        }

        guard !complexityScores.isEmpty else { return 0 }
        return complexityScores.reduce(0, +) / Float(complexityScores.count)
    }

    // MARK: - Weakness Analysis

    /// Analyze player weaknesses from practice history
    func analyzeWeaknesses(history: [PracticeSession]) -> WeaknessAnalysis {
        let difficultyAnalysis = getMostProblematicDifficulties(history: history)
        let problemSections = identifyProblemSections(history: history)
        let avgChordSpeed = calculateAverageChordSpeed(history: history)
        let avgRhythm = calculateAverageRhythmAccuracy(history: history)

        var weaknesses: [PracticeRecommendation.FocusArea] = []

        // Analyze chord speed
        if avgChordSpeed < 10 {
            weaknesses.append(.chordTransitions)
        }

        // Analyze rhythm
        if avgRhythm < 0.7 {
            weaknesses.append(.rhythmAccuracy)
        }

        // Analyze difficulty types
        for analysis in difficultyAnalysis.prefix(3) {
            switch analysis.type {
            case .chordTransition:
                if !weaknesses.contains(.chordTransitions) {
                    weaknesses.append(.chordTransitions)
                }
            case .strummingPattern:
                if !weaknesses.contains(.strummingPatterns) {
                    weaknesses.append(.strummingPatterns)
                }
            case .fingerPicking:
                if !weaknesses.contains(.fingerPicking) {
                    weaknesses.append(.fingerPicking)
                }
            case .barreChord:
                if !weaknesses.contains(.barreChords) {
                    weaknesses.append(.barreChords)
                }
            case .rhythmTiming, .tempo:
                if !weaknesses.contains(.rhythmAccuracy) {
                    weaknesses.append(.rhythmAccuracy)
                }
            case .memory:
                if !weaknesses.contains(.memorization) {
                    weaknesses.append(.memorization)
                }
            default:
                break
            }
        }

        return WeaknessAnalysis(
            primaryWeaknesses: Array(weaknesses.prefix(3)),
            secondaryWeaknesses: Array(weaknesses.dropFirst(3)),
            problematicDifficulties: difficultyAnalysis,
            problemSections: problemSections,
            overallWeaknessScore: calculateOverallWeaknessScore(from: difficultyAnalysis)
        )
    }

    /// Calculate overall weakness score
    private func calculateOverallWeaknessScore(from difficulties: [DifficultyAnalysis]) -> Float {
        guard !difficulties.isEmpty else { return 0 }

        let topDifficulties = Array(difficulties.prefix(5))
        let averageSeverity = topDifficulties.reduce(0.0) { $0 + $1.averageSeverity } / Float(topDifficulties.count)

        return averageSeverity
    }

    // MARK: - Strength Analysis

    /// Analyze player strengths from practice history
    func analyzeStrengths(history: [PracticeSession]) -> StrengthAnalysis {
        let avgChordSpeed = calculateAverageChordSpeed(history: history)
        let avgRhythm = calculateAverageRhythmAccuracy(history: history)
        let avgMemorization = calculateAverageMemorization(history: history)
        let songsMastered = countMasteredSongs(history: history)

        var strengths: [PracticeRecommendation.FocusArea] = []

        // Analyze strengths
        if avgChordSpeed >= 20 {
            strengths.append(.chordTransitions)
        }

        if avgRhythm >= 0.85 {
            strengths.append(.rhythmAccuracy)
        }

        if avgMemorization >= 0.8 {
            strengths.append(.memorization)
        }

        if songsMastered >= 10 {
            strengths.append(.overall)
        }

        return StrengthAnalysis(
            primaryStrengths: Array(strengths.prefix(3)),
            chordChangeStrength: min(avgChordSpeed / 30.0, 1.0),
            rhythmStrength: avgRhythm,
            memorizationStrength: avgMemorization,
            songsMastered: songsMastered
        )
    }

    /// Calculate average memorization level
    private func calculateAverageMemorization(history: [PracticeSession]) -> Float {
        let memorizations = history.compactMap { $0.skillMetrics?.memorizationLevel }
        guard !memorizations.isEmpty else { return 0 }

        return memorizations.reduce(0, +) / Float(memorizations.count)
    }

    // MARK: - Progress Tracking

    /// Track skill improvement over time
    func trackSkillImprovement(history: [PracticeSession]) -> SkillProgressTracking {
        let sortedSessions = history.sorted { $0.startTime < $1.startTime }

        var dataPoints: [SkillProgressDataPoint] = []

        for session in sortedSessions {
            guard let metrics = session.skillMetrics else { continue }

            let dataPoint = SkillProgressDataPoint(
                date: session.startTime,
                chordSpeed: metrics.chordChangeSpeed,
                rhythmAccuracy: metrics.rhythmAccuracy,
                memorization: metrics.memorizationLevel,
                overallScore: metrics.overallScore,
                skillLevel: metrics.overallSkillLevel
            )

            dataPoints.append(dataPoint)
        }

        let improvementRate = calculateImprovementRate(dataPoints: dataPoints)

        return SkillProgressTracking(
            dataPoints: dataPoints,
            currentSkillLevel: estimateSkillLevel(history: history),
            improvementRate: improvementRate,
            isImproving: improvementRate > 0
        )
    }

    /// Calculate improvement rate from data points
    private func calculateImprovementRate(dataPoints: [SkillProgressDataPoint]) -> Float {
        guard dataPoints.count >= 2 else { return 0 }

        let first5 = Array(dataPoints.prefix(5))
        let last5 = Array(dataPoints.suffix(5))

        let firstAverage = first5.reduce(0.0) { $0 + $1.overallScore } / Float(first5.count)
        let lastAverage = last5.reduce(0.0) { $0 + $1.overallScore } / Float(last5.count)

        guard firstAverage > 0 else { return 0 }

        return ((lastAverage - firstAverage) / firstAverage) * 100.0
    }

    // MARK: - Skill Predictions

    /// Predict when player will reach next skill level
    func predictNextSkillLevel(history: [PracticeSession]) -> SkillLevelPrediction? {
        let currentLevel = estimateSkillLevel(history: history)

        guard currentLevel != .expert else { return nil }  // Already at max level

        let tracking = trackSkillImprovement(history: history)

        guard tracking.improvementRate > 0 else { return nil }  // Not improving

        let currentScore = tracking.dataPoints.last?.overallScore ?? 0
        let nextLevelThreshold = getThresholdForNextLevel(currentLevel: currentLevel)

        let scoreGapNeeded = nextLevelThreshold - currentScore
        let improvementPerSession = tracking.improvementRate / 100.0  // Convert from percentage

        guard improvementPerSession > 0 else { return nil }

        let sessionsNeeded = Int(ceil(scoreGapNeeded / improvementPerSession))
        let averageSessionsPerWeek = calculateAverageSessionsPerWeek(history: history)

        guard averageSessionsPerWeek > 0 else { return nil }

        let weeksNeeded = Float(sessionsNeeded) / averageSessionsPerWeek

        return SkillLevelPrediction(
            currentLevel: currentLevel,
            nextLevel: getNextLevel(currentLevel: currentLevel),
            estimatedSessionsNeeded: sessionsNeeded,
            estimatedWeeksNeeded: Int(ceil(weeksNeeded)),
            confidence: min(tracking.improvementRate / 10.0, 1.0)
        )
    }

    /// Get threshold score for next skill level
    private func getThresholdForNextLevel(currentLevel: SkillLevel) -> Float {
        switch currentLevel {
        case .beginner: return beginnerThreshold
        case .earlyIntermediate: return earlyIntermediateThreshold
        case .intermediate: return intermediateThreshold
        case .advanced: return advancedThreshold
        case .expert: return 1.0
        }
    }

    /// Get next skill level
    private func getNextLevel(currentLevel: SkillLevel) -> SkillLevel {
        switch currentLevel {
        case .beginner: return .earlyIntermediate
        case .earlyIntermediate: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return .expert
        case .expert: return .expert
        }
    }

    /// Calculate average practice sessions per week
    private func calculateAverageSessionsPerWeek(history: [PracticeSession]) -> Float {
        guard !history.isEmpty else { return 0 }

        let sortedSessions = history.sorted { $0.startTime < $1.startTime }

        guard let firstDate = sortedSessions.first?.startTime,
              let lastDate = sortedSessions.last?.startTime else {
            return 0
        }

        let totalWeeks = max(lastDate.timeIntervalSince(firstDate) / (7 * 24 * 60 * 60), 1.0)
        return Float(history.count) / Float(totalWeeks)
    }
}

// MARK: - Supporting Types

/// Aggregated problem section data
struct AggregatedProblemSection: Identifiable {
    var id = UUID()
    var sectionName: String
    var sectionType: ProblemSection.SectionType
    var totalErrors: Int
    var occurrences: Int
    var averageSeverity: Float
    var lastEncountered: Date
}

/// Analysis of a specific difficulty type
struct DifficultyAnalysis: Identifiable {
    var id = UUID()
    var type: PracticeDifficulty.DifficultyType
    var count: Int
    var totalSeverity: Float
    var lastEncountered: Date

    var averageSeverity: Float {
        guard count > 0 else { return 0 }
        return totalSeverity / Float(count)
    }
}

/// Rhythm accuracy data point
struct RhythmDataPoint: Identifiable {
    var id = UUID()
    var date: Date
    var accuracy: Float
    var sessionID: UUID
}

/// Song mastery tracking data
private struct SongMasteryData {
    var sessionCount: Int
    var totalPracticeTime: TimeInterval
    var averageCompletion: Float
    var latestSkillScore: Float
}

/// Weakness analysis results
struct WeaknessAnalysis {
    var primaryWeaknesses: [PracticeRecommendation.FocusArea]
    var secondaryWeaknesses: [PracticeRecommendation.FocusArea]
    var problematicDifficulties: [DifficultyAnalysis]
    var problemSections: [AggregatedProblemSection]
    var overallWeaknessScore: Float
}

/// Strength analysis results
struct StrengthAnalysis {
    var primaryStrengths: [PracticeRecommendation.FocusArea]
    var chordChangeStrength: Float
    var rhythmStrength: Float
    var memorizationStrength: Float
    var songsMastered: Int
}

/// Skill progress tracking data
struct SkillProgressTracking {
    var dataPoints: [SkillProgressDataPoint]
    var currentSkillLevel: SkillLevel
    var improvementRate: Float  // Percentage
    var isImproving: Bool
}

/// Single data point in skill progress
struct SkillProgressDataPoint: Identifiable {
    var id = UUID()
    var date: Date
    var chordSpeed: Float
    var rhythmAccuracy: Float
    var memorization: Float
    var overallScore: Float
    var skillLevel: SkillLevel
}

/// Prediction for reaching next skill level
struct SkillLevelPrediction {
    var currentLevel: SkillLevel
    var nextLevel: SkillLevel
    var estimatedSessionsNeeded: Int
    var estimatedWeeksNeeded: Int
    var confidence: Float  // 0.0-1.0
}
