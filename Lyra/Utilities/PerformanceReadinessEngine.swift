//
//  PerformanceReadinessEngine.swift
//  Lyra
//
//  Assesses performance readiness and identifies red flags
//

import Foundation
import SwiftData

/// Engine for assessing performance readiness
class PerformanceReadinessEngine {
    static let shared = PerformanceReadinessEngine()

    // MARK: - Readiness Thresholds

    private let minimumPracticeHours: TimeInterval = 3600 // 1 hour
    private let recentlyAddedDays: Int = 3
    private let fastTempoThreshold: Int = 140
    private let complexChordThreshold: Int = 8

    // MARK: - Readiness Assessment

    /// Assess overall readiness for a set
    func assessSetReadiness(
        setID: UUID?,
        setName: String,
        songs: [(
            id: UUID,
            title: String,
            key: String?,
            tempo: Int?,
            chords: [String],
            dateAdded: Date?,
            practiceTime: TimeInterval,
            lastPracticed: Date?,
            difficulty: Float?
        )]
    ) -> (score: Float, flags: [ReadinessFlag]) {
        var redFlags: [ReadinessFlag] = []
        var scores: [Float] = []

        for song in songs {
            let (songScore, songFlags) = assessSongReadiness(song: song)
            scores.append(songScore)
            redFlags.append(contentsOf: songFlags)
        }

        // Calculate overall readiness score
        let overallScore = scores.isEmpty ? 1.0 : scores.reduce(0, +) / Float(scores.count)

        return (overallScore, redFlags)
    }

    /// Assess readiness for a single song
    private func assessSongReadiness(
        song: (
            id: UUID,
            title: String,
            key: String?,
            tempo: Int?,
            chords: [String],
            dateAdded: Date?,
            practiceTime: TimeInterval,
            lastPracticed: Date?,
            difficulty: Float?
        )
    ) -> (score: Float, flags: [ReadinessFlag]) {
        var score: Float = 1.0
        var flags: [ReadinessFlag] = []

        // Check practice time
        if song.practiceTime < minimumPracticeHours {
            score -= 0.3
            flags.append(ReadinessFlag(
                type: .insufficientPractice,
                songID: song.id,
                songTitle: song.title,
                severity: .warning,
                message: "Only \(Int(song.practiceTime / 60)) minutes of practice time",
                recommendation: "Practice for at least another \(Int((minimumPracticeHours - song.practiceTime) / 60)) minutes before performing"
            ))
        }

        // Check if recently added
        if let dateAdded = song.dateAdded {
            let daysSinceAdded = Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day ?? 0
            if daysSinceAdded < recentlyAddedDays {
                score -= 0.2
                flags.append(ReadinessFlag(
                    type: .recentlyAdded,
                    songID: song.id,
                    songTitle: song.title,
                    severity: .suggestion,
                    message: "Added only \(daysSinceAdded) day(s) ago",
                    recommendation: "Newer songs benefit from more practice time. Consider additional rehearsal"
                ))
            }
        }

        // Check tempo
        if let tempo = song.tempo, tempo > fastTempoThreshold {
            score -= 0.1
            flags.append(ReadinessFlag(
                type: .fastTempo,
                songID: song.id,
                songTitle: song.title,
                severity: .suggestion,
                message: "Fast tempo (\(tempo) BPM)",
                recommendation: "Practice with metronome to maintain consistent tempo at this speed"
            ))
        }

        // Check chord complexity
        let complexChords = song.chords.filter { isComplexChord($0) }
        if complexChords.count >= 5 {
            score -= 0.2
            flags.append(ReadinessFlag(
                type: .complexChords,
                songID: song.id,
                songTitle: song.title,
                severity: .warning,
                message: "\(complexChords.count) complex chords (\(complexChords.prefix(3).joined(separator: ", "))...)",
                recommendation: "Review fingerings for: \(complexChords.joined(separator: ", "))"
            ))
        }

        // Check recency of practice
        if let lastPracticed = song.lastPracticed {
            let daysSince = Calendar.current.dateComponents([.day], from: lastPracticed, to: Date()).day ?? 0
            if daysSince > 7 {
                score -= 0.15
                flags.append(ReadinessFlag(
                    type: .insufficientPractice,
                    songID: song.id,
                    songTitle: song.title,
                    severity: .suggestion,
                    message: "Last practiced \(daysSince) days ago",
                    recommendation: "Practice once more before performing to refresh memory"
                ))
            }
        }

        // Check overall difficulty
        if let difficulty = song.difficulty, difficulty > 0.7 {
            score -= 0.2
            flags.append(ReadinessFlag(
                type: .complexChords,
                songID: song.id,
                songTitle: song.title,
                severity: .warning,
                message: "High difficulty rating (\(Int(difficulty * 100))%)",
                recommendation: "Extra attention needed - practice problem sections multiple times"
            ))
        }

        return (max(0, score), flags)
    }

    // MARK: - Pre-Performance Checks

    /// Generate pre-performance checklist
    func generatePrePerformanceChecklist(
        setName: String,
        songCount: Int,
        totalDuration: TimeInterval,
        equipmentNeeds: [String]
    ) -> [String] {
        var checklist: [String] = []

        // Basic preparation
        checklist.append("✓ Review all \(songCount) songs in order")
        checklist.append("✓ Verify iPad is fully charged")
        checklist.append("✓ Test external display connection (if using)")

        // Duration-based
        if totalDuration > 3600 {
            checklist.append("✓ Plan intermission break (set is \(Int(totalDuration/3600)) hour(s))")
        }

        // Equipment
        for equipment in equipmentNeeds {
            checklist.append("✓ Verify \(equipment) is ready")
        }

        // Performance specifics
        checklist.append("✓ Set autoscroll speeds for each song")
        checklist.append("✓ Mark any sections to skip or repeat")
        checklist.append("✓ Test foot pedal (if using)")
        checklist.append("✓ Review key transitions between songs")

        // Comfort and environment
        checklist.append("✓ Position iPad/monitor for easy viewing")
        checklist.append("✓ Adjust font size for venue distance")
        checklist.append("✓ Test lighting conditions")

        return checklist
    }

    /// Identify critical red flags that should prevent performance
    func identifyCriticalFlags(flags: [ReadinessFlag]) -> [ReadinessFlag] {
        return flags.filter { flag in
            switch flag.type {
            case .insufficientPractice:
                return flag.severity == .critical || flag.severity == .warning
            case .recentlyAdded:
                return false // Not critical
            case .complexChords, .fastTempo, .difficultKey:
                return flag.severity == .critical
            case .longDuration, .equipmentRequired:
                return flag.severity == .warning || flag.severity == .critical
            }
        }
    }

    // MARK: - Practice Recommendations

    /// Generate practice recommendations based on readiness flags
    func generatePracticeRecommendations(flags: [ReadinessFlag]) -> [String] {
        var recommendations: [String] = []

        // Group flags by song
        let flagsBySong = Dictionary(grouping: flags) { $0.songID }

        for (_, songFlags) in flagsBySong {
            guard let firstFlag = songFlags.first else { continue }

            let issues = songFlags.map { $0.type.rawValue }.joined(separator: ", ")
            let time = estimatePracticeTime(for: songFlags)

            recommendations.append(
                "\(firstFlag.songTitle): Focus on \(issues). Recommended practice time: \(time) minutes"
            )
        }

        return recommendations
    }

    /// Estimate recommended practice time based on flags
    private func estimatePracticeTime(for flags: [ReadinessFlag]) -> Int {
        var minutes = 0

        for flag in flags {
            switch flag.type {
            case .insufficientPractice:
                minutes += 20
            case .recentlyAdded:
                minutes += 15
            case .complexChords:
                minutes += 10
            case .fastTempo:
                minutes += 10
            case .difficultKey:
                minutes += 5
            case .longDuration:
                minutes += 5
            case .equipmentRequired:
                minutes += 0 // Not practice time
            }
        }

        return minutes
    }

    // MARK: - Helper Methods

    private func isComplexChord(_ chord: String) -> Bool {
        let complexPatterns = ["7", "9", "11", "13", "sus", "add", "dim", "aug", "maj7", "m7", "ø"]
        return complexPatterns.contains(where: { chord.lowercased().contains($0) })
    }

    // MARK: - Readiness Insights

    /// Generate performance insights from readiness assessment
    func generateReadinessInsights(
        readinessScore: Float,
        flags: [ReadinessFlag]
    ) -> [PerformanceInsight] {
        var insights: [PerformanceInsight] = []

        // Overall readiness insight
        if readinessScore < 0.5 {
            insights.append(PerformanceInsight(
                type: .complexSongUnprepared,
                category: .readiness,
                title: "Low Readiness Score",
                message: "Overall readiness is \(Int(readinessScore * 100))%. Consider additional practice or simplifying the setlist.",
                severity: .critical,
                actionable: true,
                action: "Review practice recommendations",
                confidence: 0.9
            ))
        } else if readinessScore < 0.7 {
            insights.append(PerformanceInsight(
                type: .complexSongUnprepared,
                category: .readiness,
                title: "Moderate Readiness",
                message: "Readiness is \(Int(readinessScore * 100))%. Some songs need more attention before performing.",
                severity: .warning,
                actionable: true,
                action: "Focus practice on flagged songs",
                confidence: 0.85
            ))
        }

        // Convert critical flags to insights
        let criticalFlags = identifyCriticalFlags(flags: flags)
        for flag in criticalFlags.prefix(5) { // Limit to top 5
            let insight = PerformanceInsight(
                type: flagTypeToInsightType(flag.type),
                category: .readiness,
                title: flag.type.rawValue,
                message: "\(flag.songTitle): \(flag.message)",
                severity: flag.severity,
                actionable: flag.recommendation != nil,
                action: flag.recommendation,
                relatedSongID: flag.songID,
                confidence: 0.8
            )
            insights.append(insight)
        }

        return insights
    }

    private func flagTypeToInsightType(_ type: ReadinessFlagType) -> InsightType {
        switch type {
        case .insufficientPractice:
            return .insufficientRehearsalTime
        case .complexChords, .fastTempo, .difficultKey, .longDuration:
            return .complexSongUnprepared
        case .recentlyAdded:
            return .insufficientRehearsalTime
        case .equipmentRequired:
            return .complexSongUnprepared
        }
    }
}
