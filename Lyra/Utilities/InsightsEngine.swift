//
//  InsightsEngine.swift
//  Lyra
//
//  Generate intelligent insights and recommendations from performance data
//

import Foundation
import SwiftUI

struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let color: Color
    let type: InsightType
    let priority: Int // Higher = more important

    enum InsightType {
        case trend
        case recommendation
        case milestone
        case reminder
        case pattern
    }
}

class InsightsEngine {
    static func generateInsights(
        performances: [Performance],
        setPerformances: [SetPerformance],
        songs: [Song]
    ) -> [Insight] {
        var insights: [Insight] = []

        // Most common key insight
        if let keyInsight = generateKeyInsight(performances: performances) {
            insights.append(keyInsight)
        }

        // Autoscroll usage insight
        if let autoscrollInsight = generateAutoscrollInsight(performances: performances) {
            insights.append(autoscrollInsight)
        }

        // Song neglect reminder
        if let neglectedInsight = generateNeglectedSongInsight(songs: songs) {
            insights.append(neglectedInsight)
        }

        // Performance streak
        if let streakInsight = generateStreakInsight(performances: performances) {
            insights.append(streakInsight)
        }

        // Most improving song
        if let improvingInsight = generateImprovingInsight(performances: performances, songs: songs) {
            insights.append(improvingInsight)
        }

        // Set completion insight
        if let completionInsight = generateCompletionInsight(setPerformances: setPerformances) {
            insights.append(completionInsight)
        }

        // Performance frequency insight
        if let frequencyInsight = generateFrequencyInsight(performances: performances) {
            insights.append(frequencyInsight)
        }

        // Milestone achievements
        insights.append(contentsOf: generateMilestoneInsights(performances: performances, setPerformances: setPerformances))

        // Similar song recommendations
        if let recommendationInsight = generateSimilarSongInsight(performances: performances, songs: songs) {
            insights.append(recommendationInsight)
        }

        // Sort by priority (highest first)
        return insights.sorted { $0.priority > $1.priority }
    }

    // MARK: - Key Usage Insight

    private static func generateKeyInsight(performances: [Performance]) -> Insight? {
        let keys = performances.compactMap { $0.key }
        guard !keys.isEmpty else { return nil }

        let counts = Dictionary(grouping: keys, by: { $0 }).mapValues { $0.count }
        guard let mostCommon = counts.max(by: { $0.value < $1.value }) else { return nil }

        let percentage = (Double(mostCommon.value) / Double(keys.count)) * 100

        return Insight(
            title: "Key Preference",
            message: "You perform in \(mostCommon.key) most often (\(Int(percentage))% of songs)",
            icon: "music.note",
            color: .blue,
            type: .pattern,
            priority: 7
        )
    }

    // MARK: - Autoscroll Usage Insight

    private static func generateAutoscrollInsight(performances: [Performance]) -> Insight? {
        let autoscrollCount = performances.filter { $0.usedAutoscroll }.count
        guard performances.count > 0 else { return nil }

        let percentage = (Double(autoscrollCount) / Double(performances.count)) * 100

        if percentage > 70 {
            return Insight(
                title: "Autoscroll Pro",
                message: "You use autoscroll in \(Int(percentage))% of performances - you're a power user!",
                icon: "play.circle",
                color: .green,
                type: .pattern,
                priority: 5
            )
        } else if percentage < 30 {
            return Insight(
                title: "Manual Scrolling",
                message: "Consider trying autoscroll - it can make performances smoother",
                icon: "hand.tap",
                color: .orange,
                type: .recommendation,
                priority: 4
            )
        }

        return nil
    }

    // MARK: - Neglected Song Insight

    private static func generateNeglectedSongInsight(songs: [Song]) -> Insight? {
        let songsWithPerformances = songs.filter { ($0.performances?.count ?? 0) > 0 }
        guard !songsWithPerformances.isEmpty else { return nil }

        // Find songs not performed in 60+ days
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -60, to: Date()) ?? Date()

        let neglectedSongs = songsWithPerformances.filter { song in
            guard let lastPerformed = song.lastPerformed else { return true }
            return lastPerformed < cutoff
        }

        guard let oldestSong = neglectedSongs.sorted(by: { ($0.lastPerformed ?? .distantPast) < ($1.lastPerformed ?? .distantPast) }).first else {
            return nil
        }

        let daysSince: Int
        if let lastPerformed = oldestSong.lastPerformed {
            daysSince = calendar.dateComponents([.day], from: lastPerformed, to: Date()).day ?? 0
        } else {
            daysSince = 999
        }

        return Insight(
            title: "Long Time, No See",
            message: "You haven't performed \"\(oldestSong.title)\" in \(daysSince) days",
            icon: "clock.arrow.circlepath",
            color: .orange,
            type: .reminder,
            priority: 6
        )
    }

    // MARK: - Performance Streak Insight

    private static func generateStreakInsight(performances: [Performance]) -> Insight? {
        guard performances.count >= 3 else { return nil }

        let calendar = Calendar.current
        let sortedPerformances = performances.sorted { $0.performanceDate < $1.performanceDate }

        var currentStreak = 1
        var maxStreak = 1

        for i in 1..<sortedPerformances.count {
            let prevDate = sortedPerformances[i - 1].performanceDate
            let currDate = sortedPerformances[i].performanceDate

            let daysDiff = calendar.dateComponents([.day], from: prevDate, to: currDate).day ?? 0

            if daysDiff <= 7 { // Within a week
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        if maxStreak >= 5 {
            return Insight(
                title: "Performance Streak",
                message: "You performed songs for \(maxStreak) consecutive weeks - keep it up!",
                icon: "flame",
                color: .red,
                type: .milestone,
                priority: 8
            )
        }

        return nil
    }

    // MARK: - Most Improving Song Insight

    private static func generateImprovingInsight(performances: [Performance], songs: [Song]) -> Insight? {
        // Find songs performed multiple times with duration data
        let songPerformances = Dictionary(grouping: performances.filter { $0.duration != nil }, by: { $0.song?.id })

        var improvements: [(song: Song, improvement: TimeInterval)] = []

        for (songId, perfs) in songPerformances {
            guard perfs.count >= 3,
                  let songId = songId,
                  let song = songs.first(where: { $0.id == songId }) else { continue }

            let sorted = perfs.sorted { $0.performanceDate < $1.performanceDate }
            let firstThree = sorted.prefix(3).compactMap { $0.duration }.reduce(0, +) / 3
            let lastThree = sorted.suffix(3).compactMap { $0.duration }.reduce(0, +) / 3

            let improvement = firstThree - lastThree
            if improvement > 10 { // 10+ seconds improvement
                improvements.append((song: song, improvement: improvement))
            }
        }

        guard let best = improvements.max(by: { $0.improvement < $1.improvement }) else { return nil }

        return Insight(
            title: "Getting Faster",
            message: "You've improved \"\(best.song.title)\" by \(Int(best.improvement))s - you're mastering it!",
            icon: "chart.line.uptrend.xyaxis",
            color: .green,
            type: .trend,
            priority: 7
        )
    }

    // MARK: - Set Completion Insight

    private static func generateCompletionInsight(setPerformances: [SetPerformance]) -> Insight? {
        guard !setPerformances.isEmpty else { return nil }

        let avgCompletion = setPerformances.map { $0.completionPercentage }.reduce(0, +) / Double(setPerformances.count)

        if avgCompletion >= 0.9 {
            return Insight(
                title: "Set Completion Master",
                message: "You complete \(Int(avgCompletion * 100))% of your sets - excellent consistency!",
                icon: "checkmark.circle",
                color: .green,
                type: .milestone,
                priority: 6
            )
        } else if avgCompletion < 0.7 {
            return Insight(
                title: "Set Completion",
                message: "You skip \(Int((1 - avgCompletion) * 100))% of songs in sets - consider shorter sets?",
                icon: "exclamationmark.triangle",
                color: .orange,
                type: .recommendation,
                priority: 5
            )
        }

        return nil
    }

    // MARK: - Performance Frequency Insight

    private static func generateFrequencyInsight(performances: [Performance]) -> Insight? {
        guard performances.count >= 5 else { return nil }

        let calendar = Calendar.current
        let sorted = performances.sorted { $0.performanceDate < $1.performanceDate }

        guard let firstDate = sorted.first?.performanceDate,
              let lastDate = sorted.last?.performanceDate else { return nil }

        let daysBetween = calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
        guard daysBetween > 0 else { return nil }

        let performancesPerWeek = (Double(performances.count) / Double(daysBetween)) * 7

        if performancesPerWeek >= 3 {
            return Insight(
                title: "High Activity",
                message: "You perform \(String(format: "%.1f", performancesPerWeek)) songs per week - that's impressive!",
                icon: "sparkles",
                color: .purple,
                type: .pattern,
                priority: 6
            )
        }

        return nil
    }

    // MARK: - Milestone Insights

    private static func generateMilestoneInsights(performances: [Performance], setPerformances: [SetPerformance]) -> [Insight] {
        var milestones: [Insight] = []

        // Total performances milestone
        let performanceCount = performances.count
        let milestoneCounts = [10, 25, 50, 100, 250, 500, 1000]

        if let milestone = milestoneCounts.first(where: { $0 == performanceCount }) {
            milestones.append(Insight(
                title: "Milestone Reached!",
                message: "You've performed \(milestone) songs - congratulations!",
                icon: "star.fill",
                color: .yellow,
                type: .milestone,
                priority: 9
            ))
        }

        // Set performances milestone
        let setCount = setPerformances.count
        if let milestone = milestoneCounts.first(where: { $0 == setCount }) {
            milestones.append(Insight(
                title: "Set Milestone",
                message: "You've completed \(milestone) set performances!",
                icon: "trophy.fill",
                color: .yellow,
                type: .milestone,
                priority: 9
            ))
        }

        return milestones
    }

    // MARK: - Similar Song Recommendation

    private static func generateSimilarSongInsight(performances: [Performance], songs: [Song]) -> Insight? {
        // Find most performed songs
        let songCounts = Dictionary(grouping: performances.compactMap { $0.song }, by: { $0.id }).mapValues { $0.count }
        guard let topSongId = songCounts.max(by: { $0.value < $1.value })?.key,
              let topSong = songs.first(where: { $0.id == topSongId }) else { return nil }

        // Find songs with similar key that haven't been performed much
        let topSongKey = topSong.currentKey ?? topSong.originalKey
        let similarSongs = songs.filter { song in
            guard let songKey = song.currentKey ?? song.originalKey else { return false }
            return songKey == topSongKey && song.id != topSongId && (song.timesPerformed < 3)
        }

        guard let recommendation = similarSongs.randomElement() else { return nil }

        return Insight(
            title: "Try Something Similar",
            message: "Since you love \"\(topSong.title)\", try \"\(recommendation.title)\" - it's in the same key!",
            icon: "lightbulb",
            color: .blue,
            type: .recommendation,
            priority: 5
        )
    }
}
