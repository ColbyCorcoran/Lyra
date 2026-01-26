//
//  ProgressAnalyticsEngine.swift
//  Lyra
//
//  Engine for analyzing practice progress and generating insights
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for practice progress analytics and insights
@MainActor
class ProgressAnalyticsEngine {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let trackingEngine: PracticeTrackingEngine

    // MARK: - Initialization

    init(modelContext: ModelContext, trackingEngine: PracticeTrackingEngine) {
        self.modelContext = modelContext
        self.trackingEngine = trackingEngine
    }

    // MARK: - Overall Analytics

    /// Get comprehensive practice analytics
    func getPracticeAnalytics(timeRange: AnalyticsTimeRange = .all) -> PracticeAnalytics {
        let sessions = getSessionsForAnalyticsTimeRange(timeRange)

        // Calculate metrics
        let totalSessions = sessions.count
        let totalTime = sessions.reduce(0.0) { $0 + $1.duration }
        let avgDuration = totalTime / max(Double(totalSessions), 1.0)

        // Get unique songs
        let uniqueSongs = Set(sessions.map { $0.songID }).count

        // Get mastered songs
        let masteredCount = countMasteredSongs(sessions: sessions)

        // Calculate streaks
        let (currentStreak, longestStreak) = calculateStreaks(sessions: sessions)

        // Calculate skill metrics
        let avgSkillScore = calculateAverageSkillScore(sessions: sessions)

        // Calculate improvement
        let improvementRate = calculateImprovementRate(sessions: sessions)

        // Identify weak/strong areas
        let (weakAreas, strongAreas) = identifySkillAreas(sessions: sessions)

        // Last practice date
        let lastPractice = sessions.max { $0.startTime < $1.startTime }?.startTime

        return PracticeAnalytics(
            totalSessions: totalSessions,
            totalPracticeTime: totalTime,
            averageSessionDuration: avgDuration,
            songsPracticed: uniqueSongs,
            songsMastered: masteredCount,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageSkillScore: avgSkillScore,
            improvementRate: improvementRate,
            weakestAreas: weakAreas,
            strongestAreas: strongAreas,
            lastPracticeDate: lastPractice,
            practiceGoal: 30 * 60  // 30 minutes default
        )
    }

    /// Get sessions for a specific time range
    private func getSessionsForAnalyticsTimeRange(_ timeRange: AnalyticsTimeRange) -> [PracticeSession] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date

        switch timeRange {
        case .last7Days:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .last90Days:
            startDate = calendar.date(byAdding: .day, value: -90, to: now) ?? now
        case .lastYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            startDate = Date.distantPast
        }

        return trackingEngine.getSessions(from: startDate, to: now)
    }

    // MARK: - Streak Calculation

    /// Calculate current and longest practice streaks
    private func calculateStreaks(sessions: [PracticeSession]) -> (current: Int, longest: Int) {
        guard !sessions.isEmpty else { return (0, 0) }

        let calendar = Calendar.current
        let sortedSessions = sessions.sorted { $0.startTime < $1.startTime }

        // Get unique practice dates
        var practiceDates = Set<Date>()
        for session in sortedSessions {
            let components = calendar.dateComponents([.year, .month, .day], from: session.startTime)
            if let date = calendar.date(from: components) {
                practiceDates.insert(date)
            }
        }

        let sortedDates = practiceDates.sorted()

        // Calculate streaks
        var currentStreak = 0
        var longestStreak = 0
        var streakCount = 0

        for i in 0..<sortedDates.count {
            if i == 0 {
                streakCount = 1
            } else {
                let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0

                if daysBetween == 1 {
                    streakCount += 1
                } else {
                    longestStreak = max(longestStreak, streakCount)
                    streakCount = 1
                }
            }
        }

        longestStreak = max(longestStreak, streakCount)

        // Check if current streak is active
        if let lastDate = sortedDates.last {
            let daysSince = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            currentStreak = (daysSince <= 1) ? streakCount : 0
        }

        return (currentStreak, longestStreak)
    }

    // MARK: - Skill Analysis

    /// Calculate average skill score
    private func calculateAverageSkillScore(sessions: [PracticeSession]) -> Float {
        let scores = sessions.compactMap { $0.skillMetrics?.overallScore }
        guard !scores.isEmpty else { return 0 }

        return scores.reduce(0, +) / Float(scores.count)
    }

    /// Calculate improvement rate
    private func calculateImprovementRate(sessions: [PracticeSession]) -> Float {
        guard sessions.count >= 10 else { return 0 }

        let sorted = sessions.sorted { $0.startTime < $1.startTime }
        let firstHalf = Array(sorted.prefix(sorted.count / 2))
        let secondHalf = Array(sorted.suffix(sorted.count / 2))

        let firstAvg = calculateAverageSkillScore(sessions: firstHalf)
        let secondAvg = calculateAverageSkillScore(sessions: secondHalf)

        guard firstAvg > 0 else { return 0 }

        return ((secondAvg - firstAvg) / firstAvg) * 100.0
    }

    /// Identify weak and strong skill areas
    private func identifySkillAreas(sessions: [PracticeSession]) -> (
        weak: [PracticeRecommendation.FocusArea],
        strong: [PracticeRecommendation.FocusArea]
    ) {
        var difficultyMap: [PracticeDifficulty.DifficultyType: Int] = [:]

        // Count difficulties
        for session in sessions {
            for difficulty in session.difficulties {
                difficultyMap[difficulty.type, default: 0] += 1
            }
        }

        // Map to focus areas
        var weakAreas: [PracticeRecommendation.FocusArea] = []
        var strongAreas: [PracticeRecommendation.FocusArea] = []

        let avgChordSpeed = sessions.compactMap { $0.skillMetrics?.chordChangeSpeed }.reduce(0, +) / max(Float(sessions.count), 1.0)
        let avgRhythm = sessions.compactMap { $0.skillMetrics?.rhythmAccuracy }.reduce(0, +) / max(Float(sessions.count), 1.0)

        // Identify areas
        if avgChordSpeed < 12 {
            weakAreas.append(.chordTransitions)
        } else if avgChordSpeed > 20 {
            strongAreas.append(.chordTransitions)
        }

        if avgRhythm < 0.7 {
            weakAreas.append(.rhythmAccuracy)
        } else if avgRhythm > 0.85 {
            strongAreas.append(.rhythmAccuracy)
        }

        return (weakAreas, strongAreas)
    }

    // MARK: - Mastery Tracking

    /// Count mastered songs
    private func countMasteredSongs(sessions: [PracticeSession]) -> Int {
        var songData: [UUID: (sessions: Int, avgScore: Float)] = [:]

        for session in sessions {
            guard let score = session.skillMetrics?.overallScore else { continue }

            if var data = songData[session.songID] {
                data.sessions += 1
                data.avgScore = (data.avgScore + score) / 2.0
                songData[session.songID] = data
            } else {
                songData[session.songID] = (1, score)
            }
        }

        return songData.filter { $0.value.sessions >= 3 && $0.value.avgScore >= 0.75 }.count
    }

    /// Get mastery timeline
    func getMasteryTimeline() -> [MasteryTimelinePoint] {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )

        guard let sessions = try? modelContext.fetch(descriptor) else { return [] }

        var timeline: [MasteryTimelinePoint] = []
        var masteredSongs = Set<UUID>()
        var songProgress: [UUID: (count: Int, totalScore: Float)] = [:]

        for session in sessions {
            guard let score = session.skillMetrics?.overallScore else { continue }

            // Update progress
            if var progress = songProgress[session.songID] {
                progress.count += 1
                progress.totalScore += score
                songProgress[session.songID] = progress
            } else {
                songProgress[session.songID] = (1, score)
            }

            // Check if newly mastered
            if let progress = songProgress[session.songID],
               progress.count >= 3,
               progress.totalScore / Float(progress.count) >= 0.75,
               !masteredSongs.contains(session.songID) {

                masteredSongs.insert(session.songID)

                let point = MasteryTimelinePoint(
                    date: session.startTime,
                    songID: session.songID,
                    masteryScore: progress.totalScore / Float(progress.count),
                    totalMastered: masteredSongs.count
                )

                timeline.append(point)
            }
        }

        return timeline
    }

    // MARK: - Improvement Charts

    /// Calculate improvement over time for a specific metric
    func calculateImprovement(metric: MetricType, timeRange: AnalyticsTimeRange) -> [ImprovementDataPoint] {
        let sessions = getSessionsForAnalyticsTimeRange(timeRange).sorted { $0.startTime < $1.startTime }

        return sessions.compactMap { session -> ImprovementDataPoint? in
            guard let metrics = session.skillMetrics else { return nil }

            let value: Float

            switch metric {
            case .chordChangeSpeed:
                value = metrics.chordChangeSpeed
            case .rhythmAccuracy:
                value = metrics.rhythmAccuracy
            case .memorization:
                value = metrics.memorizationLevel
            case .overallSkill:
                value = metrics.overallScore
            }

            return ImprovementDataPoint(
                date: session.startTime,
                value: value,
                sessionID: session.id
            )
        }
    }

    // MARK: - Practice Patterns

    /// Analyze practice patterns and consistency
    func analyzePracticePatterns(timeRange: AnalyticsTimeRange = .last30Days) -> PracticePatternAnalysis {
        let sessions = getSessionsForAnalyticsTimeRange(timeRange)

        // Most active day of week
        let mostActiveDay = getMostActiveDay(sessions: sessions)

        // Most active time of day
        let mostActiveTime = getMostActiveTime(sessions: sessions)

        // Average session length by day
        let avgByDay = getAverageSessionByDay(sessions: sessions)

        // Practice frequency
        let frequency = calculatePracticeFrequency(sessions: sessions, timeRange: timeRange)

        return PracticePatternAnalysis(
            mostActiveDay: mostActiveDay,
            mostActiveTime: mostActiveTime,
            averageSessionByDay: avgByDay,
            practiceFrequency: frequency,
            consistencyScore: frequency / 7.0  // Sessions per week / 7 days
        )
    }

    /// Get most active day of week
    private func getMostActiveDay(sessions: [PracticeSession]) -> String {
        var dayCounts: [String: Int] = [:]

        for session in sessions {
            let dayName = session.startTime.formatted(.dateTime.weekday(.wide))
            dayCounts[dayName, default: 0] += 1
        }

        return dayCounts.max { $0.value < $1.value }?.key ?? "Unknown"
    }

    /// Get most active time of day
    private func getMostActiveTime(sessions: [PracticeSession]) -> String {
        var timeCounts: [String: Int] = [:]

        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.startTime)

            let timeOfDay: String
            switch hour {
            case 5..<12:
                timeOfDay = "Morning"
            case 12..<17:
                timeOfDay = "Afternoon"
            case 17..<22:
                timeOfDay = "Evening"
            default:
                timeOfDay = "Night"
            }

            timeCounts[timeOfDay, default: 0] += 1
        }

        return timeCounts.max { $0.value < $1.value }?.key ?? "Unknown"
    }

    /// Get average session length by day of week
    private func getAverageSessionByDay(sessions: [PracticeSession]) -> [String: TimeInterval] {
        var dayTotals: [String: (total: TimeInterval, count: Int)] = [:]

        for session in sessions {
            let dayName = session.startTime.formatted(.dateTime.weekday(.wide))

            if var data = dayTotals[dayName] {
                data.total += session.duration
                data.count += 1
                dayTotals[dayName] = data
            } else {
                dayTotals[dayName] = (session.duration, 1)
            }
        }

        return dayTotals.mapValues { $0.total / Double($0.count) }
    }

    /// Calculate practice frequency (sessions per week)
    private func calculatePracticeFrequency(sessions: [PracticeSession], timeRange: AnalyticsTimeRange) -> Float {
        guard !sessions.isEmpty else { return 0 }

        let days: Int
        switch timeRange {
        case .last7Days: days = 7
        case .last30Days: days = 30
        case .last90Days: days = 90
        case .lastYear: days = 365
        case .all: days = 30  // Default
        }

        let weeks = Float(days) / 7.0
        return Float(sessions.count) / weeks
    }
}

// MARK: - Supporting Types

/// Time range for analytics
enum AnalyticsTimeRange {
    case last7Days
    case last30Days
    case last90Days
    case lastYear
    case all
}

/// Metric type for tracking
enum MetricType {
    case chordChangeSpeed
    case rhythmAccuracy
    case memorization
    case overallSkill
}

/// Mastery timeline data point
struct MasteryTimelinePoint: Identifiable {
    var id = UUID()
    var date: Date
    var songID: UUID
    var masteryScore: Float
    var totalMastered: Int
}

/// Improvement data point
struct ImprovementDataPoint: Identifiable {
    var id = UUID()
    var date: Date
    var value: Float
    var sessionID: UUID
}

/// Practice pattern analysis
struct PracticePatternAnalysis {
    var mostActiveDay: String
    var mostActiveTime: String
    var averageSessionByDay: [String: TimeInterval]
    var practiceFrequency: Float  // Sessions per week
    var consistencyScore: Float  // 0.0-1.0
}
