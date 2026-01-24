//
//  PostPerformanceReportEngine.swift
//  Lyra
//
//  Generates comprehensive post-performance reports and analysis
//

import Foundation
import SwiftData

/// Engine for generating post-performance reports
class PostPerformanceReportEngine {
    static let shared = PostPerformanceReportEngine()

    // MARK: - Report Generation

    /// Generate comprehensive post-performance report
    func generateReport(
        session: PerformanceSession,
        previousSessions: [PerformanceSession]
    ) -> PostPerformanceReport {
        // Calculate summary statistics
        let songsPerformed = session.songPerformances.count
        let songsCompleted = session.songPerformances.filter { $0.pauseCount < 3 }.count
        let averagePerformance = calculateAveragePerformance(session: session)

        // Calculate overall score
        let overallScore = calculateOverallScore(session: session)

        // Identify strengths and improvements
        let strengthAreas = identifyStrengths(session: session)
        let improvementAreas = identifyImprovements(session: session)

        // Compare to previous performance
        let comparison = compareToPrevious(
            current: session,
            previous: previousSessions.first
        )

        // Identify personal bests
        let personalBest = identifyPersonalBests(
            current: session,
            allSessions: [session] + previousSessions
        )

        // Analyze audience feedback
        let topSongs = identifyTopSongs(session: session)
        let requestedSongs = session.songPerformances.filter {
            $0.audienceResponse?.requests ?? 0 > 0
        }.map { $0.songID }

        // Generate insights
        let keyInsights = generateKeyInsights(
            session: session,
            comparison: comparison
        )

        // Generate recommendations
        let practiceRecommendations = generatePracticeRecommendations(
            improvementAreas: improvementAreas
        )
        let setlistRecommendations = generateSetlistRecommendations(
            session: session,
            topSongs: topSongs
        )

        // Suggest goals
        let suggestedGoals = generatePerformanceGoals(
            improvementAreas: improvementAreas,
            comparison: comparison
        )

        return PostPerformanceReport(
            sessionID: session.id,
            performanceDate: session.startTime,
            setName: session.setName,
            venue: session.venue,
            totalDuration: session.duration,
            songsPerformed: songsPerformed,
            songsCompleted: songsCompleted,
            averagePerformance: averagePerformance,
            overallScore: overallScore,
            strengthAreas: strengthAreas,
            improvementAreas: improvementAreas,
            comparisonToPrevious: comparison,
            personalBest: personalBest,
            audienceRating: session.audienceEngagement,
            topSongs: topSongs,
            requestedSongs: requestedSongs,
            keyInsights: keyInsights,
            practiceRecommendations: practiceRecommendations,
            setlistRecommendations: setlistRecommendations,
            suggestedGoals: suggestedGoals
        )
    }

    // MARK: - Performance Metrics

    private func calculateAveragePerformance(session: PerformanceSession) -> Float {
        guard !session.songPerformances.isEmpty else { return 0 }

        var scores: [Float] = []

        for performance in session.songPerformances {
            var score: Float = 1.0

            // Deduct for pauses
            score -= Float(performance.pauseCount) * 0.1

            // Deduct for difficulties
            score -= Float(performance.performerDifficulties.count) * 0.05

            // Deduct for autoscroll inaccuracy
            if performance.autoscrollUsed {
                score -= (1.0 - performance.autoscrollAccuracy) * 0.2
            }

            // Bonus for audience engagement
            if let response = performance.audienceResponse {
                score += response.engagementLevel * 0.2
            }

            scores.append(max(0, score))
        }

        return scores.reduce(0, +) / Float(scores.count)
    }

    private func calculateOverallScore(session: PerformanceSession) -> Float {
        let avgPerformance = calculateAveragePerformance(session: session)
        let completionRate = Float(session.songPerformances.filter { $0.pauseCount < 3 }.count) /
                            Float(max(session.songPerformances.count, 1))

        // Weighted combination
        return (avgPerformance * 0.7 + completionRate * 0.3) * 100.0
    }

    // MARK: - Strength Analysis

    private func identifyStrengths(session: PerformanceSession) -> [StrengthArea] {
        var strengths: [StrengthArea] = []

        // Check autoscroll accuracy
        let autoscrollSongs = session.songPerformances.filter { $0.autoscrollUsed }
        if !autoscrollSongs.isEmpty {
            let avgAccuracy = autoscrollSongs.reduce(0.0) { $0 + $1.autoscrollAccuracy } /
                             Float(autoscrollSongs.count)
            if avgAccuracy > 0.85 {
                strengths.append(StrengthArea(
                    area: "Tempo Control",
                    score: avgAccuracy,
                    description: "Excellent autoscroll accuracy - maintaining consistent tempo",
                    examples: ["Average accuracy: \(Int(avgAccuracy * 100))%"]
                ))
            }
        }

        // Check low pause rate
        let avgPauses = session.songPerformances.reduce(0) { $0 + $1.pauseCount } /
                       max(session.songPerformances.count, 1)
        if avgPauses <= 1 {
            strengths.append(StrengthArea(
                area: "Flow and Continuity",
                score: 1.0 - Float(avgPauses) / 5.0,
                description: "Minimal pauses - strong song memorization and flow",
                examples: ["Average pauses per song: \(avgPauses)"]
            ))
        }

        // Check audience engagement
        let engagedSongs = session.songPerformances.filter {
            ($0.audienceResponse?.engagementLevel ?? 0) > 0.7
        }
        if engagedSongs.count >= session.songPerformances.count / 2 {
            let avgEngagement = session.songPerformances.compactMap {
                $0.audienceResponse?.engagementLevel
            }.reduce(0, +) / Float(max(engagedSongs.count, 1))

            strengths.append(StrengthArea(
                area: "Audience Connection",
                score: avgEngagement,
                description: "Strong audience engagement throughout performance",
                examples: ["\(engagedSongs.count) songs with high engagement"]
            ))
        }

        return strengths
    }

    // MARK: - Improvement Analysis

    private func identifyImprovements(session: PerformanceSession) -> [ImprovementArea] {
        var improvements: [ImprovementArea] = []

        // Identify songs with problems
        let problematicSongs = session.songPerformances.filter { !$0.problemSections.isEmpty }
        if !problematicSongs.isEmpty {
            let sectionNames = problematicSongs.flatMap { $0.problemSections.map { $0.section } }
            improvements.append(ImprovementArea(
                area: "Problem Sections",
                currentScore: 1.0 - Float(problematicSongs.count) / Float(session.songPerformances.count),
                targetScore: 1.0,
                description: "\(problematicSongs.count) songs had problem sections needing attention",
                actionItems: [
                    "Practice sections: \(Set(sectionNames).prefix(5).joined(separator: ", "))",
                    "Use loop mode for difficult sections",
                    "Slow down tempo during practice"
                ]
            ))
        }

        // Check timing issues
        let timingIssues = session.songPerformances.filter { performance in
            guard let planned = performance.plannedDuration else { return false }
            let difference = abs(performance.duration - planned)
            return difference / planned > 0.2 // 20% off
        }
        if !timingIssues.isEmpty {
            improvements.append(ImprovementArea(
                area: "Timing Consistency",
                currentScore: 1.0 - Float(timingIssues.count) / Float(session.songPerformances.count),
                targetScore: 0.9,
                description: "\(timingIssues.count) songs had significant timing variance",
                actionItems: [
                    "Practice with metronome",
                    "Adjust autoscroll speeds",
                    "Record yourself to identify rushed/dragged sections"
                ]
            ))
        }

        // Check audience response
        let lowResponseSongs = session.songPerformances.filter {
            ($0.audienceResponse?.engagementLevel ?? 1.0) < 0.5
        }
        if !lowResponseSongs.isEmpty {
            improvements.append(ImprovementArea(
                area: "Audience Engagement",
                currentScore: 1.0 - Float(lowResponseSongs.count) / Float(session.songPerformances.count),
                targetScore: 0.85,
                description: "\(lowResponseSongs.count) songs had lower audience engagement",
                actionItems: [
                    "Increase energy and stage presence",
                    "Make eye contact with audience",
                    "Consider song selection and placement in set"
                ]
            ))
        }

        return improvements
    }

    // MARK: - Comparison

    private func compareToPrevious(
        current: PerformanceSession,
        previous: PerformanceSession?
    ) -> PerformanceComparison? {
        guard let previous = previous else { return nil }

        let currentScore = calculateOverallScore(session: current)
        let previousScore = calculateOverallScore(session: previous)
        let scoreChange = currentScore - previousScore

        let durationChange = current.duration - previous.duration

        let currentErrorRate = Float(current.songPerformances.reduce(0) { $0 + $1.pauseCount }) /
                              Float(max(current.songPerformances.count, 1))
        let previousErrorRate = Float(previous.songPerformances.reduce(0) { $0 + $1.pauseCount }) /
                               Float(max(previous.songPerformances.count, 1))
        let errorRateChange = currentErrorRate - previousErrorRate

        let improvementPercentage = (scoreChange / max(previousScore, 1.0)) * 100.0

        var significantChanges: [String] = []

        if abs(scoreChange) > 5 {
            significantChanges.append(
                scoreChange > 0 ? "Overall performance improved by \(Int(abs(scoreChange))) points" :
                                 "Overall performance decreased by \(Int(abs(scoreChange))) points"
            )
        }

        if abs(errorRateChange) > 0.5 {
            significantChanges.append(
                errorRateChange < 0 ? "Fewer pauses/errors" : "More pauses/errors"
            )
        }

        if abs(durationChange) > 300 { // 5 minutes
            significantChanges.append(
                durationChange > 0 ? "Longer performance duration" : "Shorter performance duration"
            )
        }

        return PerformanceComparison(
            previousDate: previous.startTime,
            scoreChange: scoreChange,
            durationChange: durationChange,
            errorRateChange: errorRateChange,
            improvementPercentage: improvementPercentage,
            significantChanges: significantChanges
        )
    }

    // MARK: - Personal Bests

    private func identifyPersonalBests(
        current: PerformanceSession,
        allSessions: [PerformanceSession]
    ) -> [String] {
        var bests: [String] = []

        // Check overall score
        let currentScore = calculateOverallScore(session: current)
        let allScores = allSessions.map { calculateOverallScore(session: $0) }
        if currentScore == allScores.max() {
            bests.append("Highest overall score")
        }

        // Check low error rate
        let currentErrorRate = Float(current.songPerformances.reduce(0) { $0 + $1.pauseCount }) /
                              Float(max(current.songPerformances.count, 1))
        let allErrorRates = allSessions.map {
            Float($0.songPerformances.reduce(0) { $0 + $1.pauseCount }) /
            Float(max($0.songPerformances.count, 1))
        }
        if currentErrorRate == allErrorRates.min() {
            bests.append("Fewest pauses/errors")
        }

        // Check song count
        if current.songPerformances.count == allSessions.map({ $0.songPerformances.count }).max() {
            bests.append("Most songs performed")
        }

        return bests
    }

    // MARK: - Audience Analysis

    private func identifyTopSongs(session: PerformanceSession) -> [UUID] {
        return session.songPerformances
            .sorted { (a, b) in
                let aScore = (a.audienceResponse?.engagementLevel ?? 0) +
                            Float(a.audienceResponse?.requests ?? 0) * 0.2
                let bScore = (b.audienceResponse?.engagementLevel ?? 0) +
                            Float(b.audienceResponse?.requests ?? 0) * 0.2
                return aScore > bScore
            }
            .prefix(5)
            .map { $0.songID }
    }

    // MARK: - Insights

    private func generateKeyInsights(
        session: PerformanceSession,
        comparison: PerformanceComparison?
    ) -> [PerformanceInsight] {
        var insights: [PerformanceInsight] = []

        // Overall performance insight
        let score = calculateOverallScore(session: session)
        if score >= 80 {
            insights.append(PerformanceInsight(
                type: .performanceImprovement,
                category: .feedback,
                title: "Excellent Performance",
                message: "Outstanding performance with a score of \(Int(score))/100. Keep up the great work!",
                severity: .suggestion,
                actionable: false,
                confidence: 1.0
            ))
        } else if score < 60 {
            insights.append(PerformanceInsight(
                type: .improvementArea,
                category: .feedback,
                title: "Room for Improvement",
                message: "Performance score was \(Int(score))/100. Focus on the improvement areas below to enhance future performances.",
                severity: .suggestion,
                actionable: true,
                action: "Review recommendations",
                confidence: 0.9
            ))
        }

        // Comparison insight
        if let comparison = comparison {
            if comparison.improvementPercentage > 10 {
                insights.append(PerformanceInsight(
                    type: .performanceImprovement,
                    category: .feedback,
                    title: "Significant Improvement",
                    message: "You improved by \(Int(comparison.improvementPercentage))% compared to last performance!",
                    severity: .suggestion,
                    actionable: false,
                    confidence: 0.95
                ))
            } else if comparison.improvementPercentage < -10 {
                insights.append(PerformanceInsight(
                    type: .improvementArea,
                    category: .feedback,
                    title: "Performance Dip",
                    message: "Performance was \(Int(abs(comparison.improvementPercentage)))% lower than last time. Review what changed and adjust.",
                    severity: .warning,
                    actionable: true,
                    action: "Compare performances",
                    confidence: 0.9
                ))
            }
        }

        return insights
    }

    // MARK: - Recommendations

    private func generatePracticeRecommendations(
        improvementAreas: [ImprovementArea]
    ) -> [String] {
        return improvementAreas.flatMap { $0.actionItems }
    }

    private func generateSetlistRecommendations(
        session: PerformanceSession,
        topSongs: [UUID]
    ) -> [String] {
        var recommendations: [String] = []

        // Suggest keeping top songs
        if !topSongs.isEmpty {
            recommendations.append("Keep your top \(topSongs.count) audience favorites in future setlists")
        }

        // Suggest removing low-performing songs
        let lowPerformers = session.songPerformances.filter {
            $0.pauseCount > 3 || ($0.audienceResponse?.engagementLevel ?? 1.0) < 0.3
        }
        if !lowPerformers.isEmpty {
            recommendations.append("Consider replacing or reworking \(lowPerformers.count) songs that had difficulties or low engagement")
        }

        return recommendations
    }

    private func generatePerformanceGoals(
        improvementAreas: [ImprovementArea],
        comparison: PerformanceComparison?
    ) -> [PerformanceGoal] {
        var goals: [PerformanceGoal] = []

        // Goals from improvement areas
        for area in improvementAreas.prefix(3) {
            goals.append(PerformanceGoal(
                title: "Improve \(area.area)",
                description: area.description,
                category: .technical,
                measurable: true,
                specificMetric: area.area,
                targetValue: area.targetScore
            ))
        }

        // Goal from comparison
        if let comparison = comparison, comparison.scoreChange < 0 {
            goals.append(PerformanceGoal(
                title: "Return to Previous Performance Level",
                description: "Regain the \(Int(abs(comparison.scoreChange))) points lost from last performance",
                category: .performance,
                measurable: true,
                specificMetric: "Overall Score",
                targetValue: calculateOverallScore(session: PerformanceSession(setID: nil, setName: "", startTime: Date())) + abs(comparison.scoreChange)
            ))
        }

        return goals
    }
}
