//
//  TransposeLearningEngine.swift
//  Lyra
//
//  Engine for learning user transpose preferences and patterns
//  Part of Phase 7.9: Transpose Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for learning transpose patterns and user preferences
@MainActor
class TransposeLearningEngine {

    // MARK: - Properties

    private let modelContext: ModelContext

    // Learning constants
    private let historyRetentionDays = 90 // Keep last 90 days
    private let minHistoryForLearning = 5 // Need at least 5 transposes to learn

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Recording Transpose History

    /// Record a transpose operation
    /// - Parameters:
    ///   - songID: Song being transposed
    ///   - originalKey: Key before transposition
    ///   - newKey: Key after transposition
    ///   - semitones: Semitone difference
    ///   - recommendationID: ID of recommendation if user chose one
    func recordTranspose(
        songID: UUID,
        originalKey: String,
        newKey: String,
        semitones: Int,
        recommendationID: UUID? = nil
    ) {
        let history = TransposeHistory(
            songID: songID,
            originalKey: originalKey,
            newKey: newKey,
            semitones: semitones,
            recommendationID: recommendationID
        )

        modelContext.insert(history)
        try? modelContext.save()

        // Clean old history
        cleanOldHistory()
    }

    /// Record that a transpose was reverted
    /// - Parameters:
    ///   - historyID: History record ID
    ///   - revertedAfter: Time elapsed before reverting
    func recordRevert(historyID: UUID, revertedAfter: TimeInterval) {
        let descriptor = FetchDescriptor<TransposeHistory>(
            predicate: #Predicate<TransposeHistory> { $0.id == historyID }
        )

        if let history = try? modelContext.fetch(descriptor).first {
            history.kept = false
            history.revertedAfter = revertedAfter
            try? modelContext.save()
        }
    }

    /// Record user satisfaction with a transpose
    /// - Parameters:
    ///   - historyID: History record ID
    ///   - rating: User rating (1-5)
    func recordSatisfaction(historyID: UUID, rating: Int) {
        let descriptor = FetchDescriptor<TransposeHistory>(
            predicate: #Predicate<TransposeHistory> { $0.id == historyID }
        )

        if let history = try? modelContext.fetch(descriptor).first {
            history.userSatisfaction = max(1, min(5, rating))
            try? modelContext.save()
        }
    }

    // MARK: - Recording Problem Keys

    /// Record a key that caused problems
    /// - Parameters:
    ///   - songID: Song with problem
    ///   - key: Problematic key
    ///   - issues: Array of issue descriptions
    func recordProblemKey(
        songID: UUID,
        key: String,
        issues: [String]
    ) {
        let problemKey = ProblemKeyRecord(
            songID: songID,
            key: key,
            issues: issues
        )

        modelContext.insert(problemKey)
        try? modelContext.save()
    }

    /// Mark a problem key as resolved
    /// - Parameters:
    ///   - songID: Song ID
    ///   - key: Key that was resolved
    func resolveProblemKey(songID: UUID, key: String) {
        let descriptor = FetchDescriptor<ProblemKeyRecord>(
            predicate: #Predicate<ProblemKeyRecord> {
                $0.songID == songID && $0.key == key && $0.resolved == false
            }
        )

        if let problemKey = try? modelContext.fetch(descriptor).first {
            problemKey.resolved = true
            try? modelContext.save()
        }
    }

    // MARK: - Personalized Recommendations

    /// Get personalized recommendations based on history
    /// - Parameters:
    ///   - baseRecommendations: Initial recommendations
    ///   - songID: Current song ID
    /// - Returns: Adjusted recommendations with boosted/penalized scores
    func getPersonalizedRecommendations(
        baseRecommendations: [TransposeRecommendation],
        songID: UUID
    ) -> [TransposeRecommendation] {
        let history = getRecentHistory()
        guard history.count >= minHistoryForLearning else {
            return baseRecommendations // Not enough data
        }

        return baseRecommendations.map { recommendation in
            var adjusted = recommendation

            // Boost score based on user patterns
            let boost = calculatePersonalizationBoost(
                recommendation: recommendation,
                history: history,
                songID: songID
            )

            adjusted.overallScore += boost
            adjusted.userPreferenceScore = min(adjusted.userPreferenceScore + (boost / 100.0), 1.0)

            return adjusted
        }
    }

    /// Predict likelihood user will like a transpose
    /// - Parameters:
    ///   - targetKey: Target key
    ///   - semitones: Semitone shift
    ///   - songID: Song being transposed
    /// - Returns: Prediction score (0.0-1.0)
    func predictUserPreference(
        targetKey: String,
        semitones: Int,
        songID: UUID
    ) -> Float {
        let history = getRecentHistory()
        guard !history.isEmpty else { return 0.5 } // Neutral if no history

        // Analyze patterns
        var score: Float = 0.5

        // Pattern 1: User frequently transposes to this key
        let keyFrequency = history.filter { $0.newKey == targetKey && $0.kept }.count
        let totalKept = history.filter { $0.kept }.count
        if totalKept > 0 {
            let keyPreference = Float(keyFrequency) / Float(totalKept)
            score += keyPreference * 0.3
        }

        // Pattern 2: User prefers similar semitone shifts
        let similarShifts = history.filter {
            abs($0.semitones - semitones) <= 2 && $0.kept
        }.count
        if totalKept > 0 {
            let shiftPreference = Float(similarShifts) / Float(totalKept)
            score += shiftPreference * 0.2
        }

        // Pattern 3: Check if similar keys were problematic
        let problemKeys = getProblemKeys(songID: songID)
        if problemKeys.contains(where: { $0.key == targetKey }) {
            score -= 0.3 // Penalize known problem keys
        }

        // Pattern 4: User satisfaction with this key
        let satisfactionScores = history
            .filter { $0.newKey == targetKey && $0.userSatisfaction != nil }
            .compactMap { $0.userSatisfaction }

        if !satisfactionScores.isEmpty {
            let avgSatisfaction = Float(satisfactionScores.reduce(0, +)) / Float(satisfactionScores.count)
            let normalizedSatisfaction = (avgSatisfaction - 1.0) / 4.0 // Map 1-5 to 0-1
            score += normalizedSatisfaction * 0.3
        }

        return min(max(score, 0.0), 1.0)
    }

    // MARK: - Learning Insights

    /// Get insights about user's transpose patterns
    /// - Returns: Learning insights
    func getLearningInsights() -> TransposeLearningInsights {
        let history = getRecentHistory()
        let problemKeys = getAllProblemKeys()

        // Most successful transposes
        let successfulTransposes = history
            .filter { $0.kept && ($0.userSatisfaction ?? 0) >= 4 }
            .map { $0.newKey }

        let mostSuccessfulKeys = Dictionary(grouping: successfulTransposes) { $0 }
            .map { (key: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        // Common semitone shifts
        let commonShifts = Dictionary(grouping: history.filter { $0.kept }) { $0.semitones }
            .map { (semitones: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        // Average satisfaction
        let satisfactionScores = history.compactMap { $0.userSatisfaction }
        let avgSatisfaction = satisfactionScores.isEmpty ? 0.0 :
            Float(satisfactionScores.reduce(0, +)) / Float(satisfactionScores.count)

        return TransposeLearningInsights(
            totalTransposes: history.count,
            successRate: calculateSuccessRate(history: history),
            mostSuccessfulKeys: mostSuccessfulKeys.prefix(5).map { $0.key },
            commonSemitoneShifts: commonShifts.prefix(3).map { $0.semitones },
            averageSatisfaction: avgSatisfaction,
            activeProblemKeys: problemKeys.filter { !$0.resolved }.count
        )
    }

    // MARK: - Private Helper Methods

    /// Get recent transpose history
    private func getRecentHistory() -> [TransposeHistory] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -historyRetentionDays,
            to: Date()
        ) ?? Date()

        let descriptor = FetchDescriptor<TransposeHistory>(
            predicate: #Predicate<TransposeHistory> { $0.timestamp >= cutoffDate }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get problem keys for a song
    private func getProblemKeys(songID: UUID) -> [ProblemKeyRecord] {
        let descriptor = FetchDescriptor<ProblemKeyRecord>(
            predicate: #Predicate<ProblemKeyRecord> {
                $0.songID == songID && $0.resolved == false
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Get all problem keys
    private func getAllProblemKeys() -> [ProblemKeyRecord] {
        let descriptor = FetchDescriptor<ProblemKeyRecord>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Calculate personalization boost
    private func calculatePersonalizationBoost(
        recommendation: TransposeRecommendation,
        history: [TransposeHistory],
        songID: UUID
    ) -> Float {
        var boost: Float = 0.0

        // Boost if user frequently uses this key
        let keyPreference = predictUserPreference(
            targetKey: recommendation.targetKey,
            semitones: recommendation.semitones,
            songID: songID
        )

        boost += (keyPreference - 0.5) * 20.0 // Max ±10 points

        // Boost if recommendation matches user patterns
        let recID = recommendation.id
        let wasChosen = history.contains { $0.recommendationID == recID && $0.kept }
        if wasChosen {
            boost += 5.0
        }

        return boost
    }

    /// Calculate success rate
    private func calculateSuccessRate(history: [TransposeHistory]) -> Float {
        guard !history.isEmpty else { return 0.0 }
        let keptCount = history.filter { $0.kept }.count
        return Float(keptCount) / Float(history.count)
    }

    /// Clean old history beyond retention period
    private func cleanOldHistory() {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -historyRetentionDays,
            to: Date()
        ) ?? Date()

        let descriptor = FetchDescriptor<TransposeHistory>(
            predicate: #Predicate<TransposeHistory> { $0.timestamp < cutoffDate }
        )

        if let oldRecords = try? modelContext.fetch(descriptor) {
            for record in oldRecords {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Supporting Types

/// Insights from transpose learning
struct TransposeLearningInsights {
    var totalTransposes: Int
    var successRate: Float // 0.0-1.0
    var mostSuccessfulKeys: [String]
    var commonSemitoneShifts: [Int]
    var averageSatisfaction: Float // 1.0-5.0
    var activeProblemKeys: Int
}
