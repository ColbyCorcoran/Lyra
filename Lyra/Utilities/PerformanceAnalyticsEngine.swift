//
//  PerformanceAnalyticsEngine.swift
//  Lyra
//
//  AI-powered performance analytics and insights engine
//  Analyzes live performance data to provide real-time coaching
//

import Foundation
import SwiftData
import Observation

/// Main coordinator for AI performance insights
@Observable
class PerformanceAnalyticsEngine {
    static let shared = PerformanceAnalyticsEngine()

    // MARK: - Properties

    private var currentSession: PerformanceSession?
    private(set) var liveInsights: [PerformanceInsight] = []
    private(set) var isTracking: Bool = false

    // Thresholds for insight generation
    private let pauseThreshold: TimeInterval = 3.0 // 3 seconds
    private let tempoVariationThreshold: Float = 0.15 // 15% deviation
    private let fatigueThreshold: Float = 0.7 // 70% energy drop
    private let problemSectionThreshold: Int = 2 // 2 errors = problem

    // MARK: - Initialization

    private init() {}

    // MARK: - Performance Session Tracking

    /// Start tracking a performance session
    func startPerformanceSession(
        setID: UUID?,
        setName: String,
        venue: String? = nil
    ) -> PerformanceSession {
        let session = PerformanceSession(
            setID: setID,
            setName: setName,
            startTime: Date(),
            venue: venue
        )

        currentSession = session
        isTracking = true
        liveInsights.removeAll()

        return session
    }

    /// End current performance session
    func endPerformanceSession() -> PerformanceSession? {
        guard let session = currentSession else { return nil }

        session.endTime = Date()
        session.duration = session.endTime!.timeIntervalSince(session.startTime)

        isTracking = false
        let finishedSession = session
        currentSession = nil

        return finishedSession
    }

    // MARK: - Real-Time Performance Analysis

    /// Track start of song in performance
    func startSongPerformance(
        songID: UUID,
        songTitle: String,
        orderInSet: Int,
        plannedDuration: TimeInterval? = nil
    ) -> SongPerformance {
        var performance = SongPerformance(
            songID: songID,
            songTitle: songTitle,
            orderInSet: orderInSet,
            startTime: Date(),
            plannedDuration: plannedDuration
        )

        // Analyze pre-song readiness
        let readinessInsights = analyzePreSongReadiness(
            songID: songID,
            orderInSet: orderInSet
        )
        liveInsights.append(contentsOf: readinessInsights)

        return performance
    }

    /// Log autoscroll usage during performance
    func logAutoscrollUsage(
        performance: inout SongPerformance,
        autoscrollSpeed: Float,
        targetSpeed: Float
    ) {
        performance.autoscrollUsed = true

        // Calculate accuracy (how close to target tempo)
        let variation = abs(autoscrollSpeed - targetSpeed) / targetSpeed
        performance.autoscrollAccuracy = 1.0 - min(variation, 1.0)

        // Generate insight if autoscroll is significantly off
        if variation > tempoVariationThreshold {
            let insight = PerformanceInsight(
                type: .autoscrollIssue,
                category: .analysis,
                title: "Autoscroll Tempo Mismatch",
                message: "Your autoscroll speed is \(Int(variation * 100))% off from the planned tempo. Consider adjusting the speed for better flow.",
                severity: .suggestion,
                actionable: true,
                action: "Tap to adjust autoscroll speed",
                relatedSongID: performance.songID,
                confidence: 0.95
            )
            liveInsights.append(insight)
        }
    }

    /// Log a pause during performance
    func logPause(
        performance: inout SongPerformance,
        section: String?,
        lineNumber: Int?,
        duration: TimeInterval,
        reason: PauseReason
    ) {
        let pauseLocation = PauseLocation(
            timestamp: Date(),
            section: section,
            lineNumber: lineNumber,
            duration: duration,
            reason: reason
        )

        performance.pauseLocations.append(pauseLocation)
        performance.pauseCount += 1

        // Significant pause detected
        if duration > pauseThreshold {
            let insight = generatePauseInsight(
                songID: performance.songID,
                songTitle: performance.songTitle,
                pause: pauseLocation
            )
            liveInsights.append(insight)
        }

        // Detect problem sections
        if let section = section {
            updateProblemSections(
                performance: &performance,
                section: section,
                difficulty: .moderate
            )
        }
    }

    /// Log a section skip
    func logSectionSkip(
        performance: inout SongPerformance,
        section: String
    ) {
        performance.skipSections.append(section)

        let insight = PerformanceInsight(
            type: .problemSectionDetected,
            category: .analysis,
            title: "Section Skipped",
            message: "You skipped the \(section) section. This might indicate a memory or difficulty issue. Consider practicing this section more.",
            severity: .warning,
            actionable: true,
            action: "Add to practice list",
            relatedSongID: performance.songID,
            relatedSection: section,
            confidence: 1.0
        )
        liveInsights.append(insight)
    }

    /// Log a difficulty encountered during performance
    func logDifficulty(
        performance: inout SongPerformance,
        type: DifficultyType,
        section: String?,
        chord: String?,
        severity: Float
    ) {
        let difficulty = PerformanceDifficulty(
            type: type,
            section: section,
            chord: chord,
            timestamp: Date(),
            severity: severity
        )

        performance.performerDifficulties.append(difficulty)

        // Update problem sections if applicable
        if let section = section {
            let problemLevel: ProblemDifficulty = severity > 0.8 ? .major :
                                                   severity > 0.5 ? .moderate : .minor
            updateProblemSections(
                performance: &performance,
                section: section,
                difficulty: problemLevel
            )
        }

        // Generate insight for significant difficulties
        if severity > 0.7 {
            let insight = generateDifficultyInsight(
                songID: performance.songID,
                songTitle: performance.songTitle,
                difficulty: difficulty
            )
            liveInsights.append(insight)
        }
    }

    /// End song performance
    func endSongPerformance(
        performance: inout SongPerformance,
        performerRating: Int? = nil,
        audienceResponse: AudienceResponse? = nil
    ) {
        performance.endTime = Date()
        performance.duration = performance.endTime!.timeIntervalSince(performance.startTime)
        performance.performerRating = performerRating
        performance.audienceResponse = audienceResponse

        // Analyze timing
        if let planned = performance.plannedDuration {
            let difference = performance.duration - planned
            let percentOff = abs(difference) / planned

            if percentOff > 0.2 { // 20% off
                let insight = generateTimingInsight(
                    performance: performance,
                    plannedDuration: planned,
                    actualDuration: performance.duration
                )
                liveInsights.append(insight)
            }
        }

        // Add to session
        currentSession?.songPerformances.append(performance)

        // Analyze energy and fatigue
        analyzeEnergy(performance: performance)
    }

    // MARK: - Predictive Insights

    /// Analyze song before performing to predict difficulties
    func predictSongDifficulties(
        songID: UUID,
        songTitle: String,
        chords: [String],
        tempo: Int?,
        key: String?
    ) -> [PerformanceInsight] {
        var insights: [PerformanceInsight] = []

        // Analyze chord complexity
        let complexChords = chords.filter { isComplexChord($0) }
        if !complexChords.isEmpty {
            let insight = PerformanceInsight(
                type: .difficultyPrediction,
                category: .prediction,
                title: "Complex Chords Ahead",
                message: "This song contains \(complexChords.count) complex chords (\(complexChords.prefix(3).joined(separator: ", "))). Be prepared for challenging transitions.",
                severity: .suggestion,
                actionable: true,
                action: "Review chord fingerings",
                relatedSongID: songID,
                confidence: 0.85
            )
            insights.append(insight)
        }

        // Analyze tempo
        if let tempo = tempo, tempo > 140 {
            let insight = PerformanceInsight(
                type: .tempoChallenge,
                category: .prediction,
                title: "Fast Tempo Warning",
                message: "This song has a tempo of \(tempo) BPM. Maintain focus on chord changes and strumming accuracy at this speed.",
                severity: .warning,
                actionable: true,
                action: "Practice with metronome",
                relatedSongID: songID,
                confidence: 0.9
            )
            insights.append(insight)
        }

        return insights
    }

    // MARK: - Private Helper Methods

    private func analyzePreSongReadiness(
        songID: UUID,
        orderInSet: Int
    ) -> [PerformanceInsight] {
        var insights: [PerformanceInsight] = []

        // Check if this is early in set (potential cold start)
        if orderInSet <= 2 {
            let insight = PerformanceInsight(
                type: .suggestionPerformance,
                category: .prediction,
                title: "Warm-Up Song",
                message: "This is early in your set. Use it to settle into your performance rhythm and warm up your voice/fingers.",
                severity: .info,
                actionable: false,
                relatedSongID: songID,
                confidence: 0.7
            )
            insights.append(insight)
        }

        // TODO: Check practice history for this song
        // TODO: Detect if recently added to set (insufficient rehearsal)

        return insights
    }

    private func generatePauseInsight(
        songID: UUID,
        songTitle: String,
        pause: PauseLocation
    ) -> PerformanceInsight {
        let message: String
        let action: String?

        switch pause.reason {
        case .memoryLapse:
            message = "Memory lapse detected in \(songTitle). Consider using larger text or lyrics reference during performance."
            action = "Increase font size"
        case .chordDifficulty:
            message = "Chord transition difficulty in \(songTitle). Practice this section slowly to build muscle memory."
            action = "Add to practice queue"
        case .lyricForgotten:
            message = "Lyric forgotten in \(songTitle). Review lyrics before next performance."
            action = "Review lyrics now"
        default:
            message = "Pause detected in \(songTitle). Monitor pacing to maintain audience engagement."
            action = nil
        }

        return PerformanceInsight(
            type: .struggleWarning,
            category: .analysis,
            title: "Significant Pause",
            message: message,
            severity: .warning,
            actionable: action != nil,
            action: action,
            relatedSongID: songID,
            relatedSection: pause.section,
            confidence: 0.8
        )
    }

    private func generateDifficultyInsight(
        songID: UUID,
        songTitle: String,
        difficulty: PerformanceDifficulty
    ) -> PerformanceInsight {
        let message: String
        let action: String

        switch difficulty.type {
        case .chordTransition:
            message = "Struggling with chord transition in \(songTitle). Slow down and focus on clean changes."
            action = "Practice transitions"
        case .tempo:
            message = "Tempo inconsistency in \(songTitle). Use metronome or autoscroll to maintain steady pace."
            action = "Enable metronome"
        case .memory:
            message = "Memory difficulty in \(songTitle). Consider using larger text or practicing with hide-chord mode."
            action = "Practice memory"
        default:
            message = "Difficulty encountered in \(songTitle). Focus on this section in your next practice."
            action = "Add to practice"
        }

        return PerformanceInsight(
            type: .struggleWarning,
            category: .analysis,
            title: "\(difficulty.type.rawValue) Difficulty",
            message: message,
            severity: difficulty.severity > 0.8 ? .warning : .suggestion,
            actionable: true,
            action: action,
            relatedSongID: songID,
            relatedSection: difficulty.section,
            confidence: 0.75
        )
    }

    private func generateTimingInsight(
        performance: SongPerformance,
        plannedDuration: TimeInterval,
        actualDuration: TimeInterval
    ) -> PerformanceInsight {
        let difference = actualDuration - plannedDuration
        let direction = difference > 0 ? "longer" : "shorter"
        let minutes = Int(abs(difference) / 60)
        let seconds = Int(abs(difference).truncatingRemainder(dividingBy: 60))

        let message = "\(performance.songTitle) ran \(minutes)m \(seconds)s \(direction) than planned. Adjust pacing for next performance."

        return PerformanceInsight(
            type: difference > 0 ? .runningLong : .runningShort,
            category: .analysis,
            title: "Timing Variance",
            message: message,
            severity: abs(difference) > 120 ? .warning : .info,
            actionable: true,
            action: "Adjust autoscroll speed",
            relatedSongID: performance.songID,
            confidence: 0.9
        )
    }

    private func updateProblemSections(
        performance: inout SongPerformance,
        section: String,
        difficulty: ProblemDifficulty
    ) {
        if let index = performance.problemSections.firstIndex(where: { $0.section == section }) {
            performance.problemSections[index].occurrenceCount += 1
            performance.problemSections[index].lastOccurrence = Date()

            // Escalate difficulty if recurring
            if performance.problemSections[index].occurrenceCount >= problemSectionThreshold {
                performance.problemSections[index].difficulty = .major
            }
        } else {
            let problemSection = ProblemSection(
                section: section,
                chords: [], // TODO: Extract from song data
                difficulty: difficulty,
                lastOccurrence: Date()
            )
            performance.problemSections.append(problemSection)
        }
    }

    private func analyzeEnergy(performance: SongPerformance) {
        guard let session = currentSession else { return }

        // Detect fatigue patterns
        if session.songPerformances.count >= 5 {
            let recentPerformances = session.songPerformances.suffix(5)
            let avgErrorsEarly = recentPerformances.prefix(2).reduce(0) { $0 + $1.pauseCount } / 2
            let avgErrorsRecent = recentPerformances.suffix(2).reduce(0) { $0 + $1.pauseCount } / 2

            if avgErrorsRecent > avgErrorsEarly * 2 {
                let insight = PerformanceInsight(
                    type: .fatigueWarning,
                    category: .analysis,
                    title: "Fatigue Detected",
                    message: "Error rate is increasing. Consider taking a short break or reducing intensity for next song.",
                    severity: .warning,
                    actionable: true,
                    action: "Schedule break",
                    confidence: 0.75
                )
                liveInsights.append(insight)
            }
        }
    }

    private func isComplexChord(_ chord: String) -> Bool {
        // Check for 7ths, 9ths, 11ths, 13ths, sus, add, diminished, augmented
        let complexPatterns = ["7", "9", "11", "13", "sus", "add", "dim", "aug", "maj7", "m7", "ø"]
        return complexPatterns.contains(where: { chord.lowercased().contains($0) })
    }

    // MARK: - Insights Access

    /// Get current live insights
    func getLiveInsights() -> [PerformanceInsight] {
        return liveInsights
    }

    /// Clear insights (e.g., when acknowledged by user)
    func clearInsights() {
        liveInsights.removeAll()
    }

    /// Dismiss specific insight
    func dismissInsight(_ insightID: UUID) {
        liveInsights.removeAll { $0.id == insightID }
    }
}

// MARK: - InsightType Extension for Additional Cases

extension InsightType {
    static let suggestionPerformance: InsightType = .energyBoostOpportunity // Reuse existing case
}
