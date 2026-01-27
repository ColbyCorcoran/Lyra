//
//  PredictiveSyncEngine.swift
//  Lyra
//
//  Phase 7.12: Predictive Sync
//  Pre-fetches songs likely to be used based on patterns and predictions
//

import Foundation
import SwiftData

/// Predicts and pre-fetches songs user will likely need
@MainActor
class PredictiveSyncEngine {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Prediction

    /// Predicts songs that will be needed soon
    func predictUpcomingSongs(userID: String = "default", count: Int = 10) async -> [PredictedSongUsage] {
        var predictions: [PredictedSongUsage] = []

        // 1. Upcoming set songs (highest priority)
        predictions.append(contentsOf: await predictUpcomingSetSongs())

        // 2. Recently edited songs
        predictions.append(contentsOf: await predictRecentlyEditedSongs())

        // 3. Time-based patterns
        predictions.append(contentsOf: await predictTimeBasedSongs(userID: userID))

        // 4. Frequently used songs
        predictions.append(contentsOf: await predictFrequentlyUsedSongs(userID: userID))

        // 5. Set sequence predictions
        predictions.append(contentsOf: await predictSetSequenceSongs())

        // 6. Offline period predictions
        predictions.append(contentsOf: await predictOfflinePeriodSongs(userID: userID))

        // Sort by score and take top N
        let uniquePredictions = Dictionary(grouping: predictions) { $0.songID }
            .compactMap { $0.value.max { $0.predictionScore < $1.predictionScore } }

        let topPredictions = uniquePredictions
            .sorted { $0.predictionScore > $1.predictionScore }
            .prefix(count)

        // Store predictions
        for prediction in topPredictions {
            modelContext.insert(prediction)
        }

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save predictions: \(error)")
        }

        return Array(topPredictions)
    }

    // MARK: - Prediction Strategies

    /// Predicts songs in upcoming sets/performances
    private func predictUpcomingSetSongs() async -> [PredictedSongUsage] {
        // TODO: Query Performance/Set models for upcoming performances
        // For now, return empty array
        // In production: integrate with SetManager to find songs in next 7 days
        return []
    }

    /// Predicts songs that were recently edited
    private func predictRecentlyEditedSongs() async -> [PredictedSongUsage] {
        let oneDayAgo = Date().addingTimeInterval(-86400)

        let descriptor = FetchDescriptor<EditingSession>(
            predicate: #Predicate<EditingSession> { session in
                session.startTime >= oneDayAgo
            },
            sortBy: [SortDescriptor(\EditingSession.startTime, order: .reverse)]
        )

        do {
            let recentSessions = try modelContext.fetch(descriptor)
            let uniqueSongs = Set(recentSessions.map { $0.songID })

            return uniqueSongs.map { songID in
                let sessionCount = recentSessions.filter { $0.songID == songID }.count
                let score = min(0.7 + Float(sessionCount) * 0.05, 0.95)

                return PredictedSongUsage(
                    songID: songID,
                    predictionScore: score,
                    predictionReason: .recentlyEdited,
                    predictedTime: Date().addingTimeInterval(3600)  // Within 1 hour
                )
            }
        } catch {
            print("❌ Failed to predict recently edited songs: \(error)")
            return []
        }
    }

    /// Predicts songs based on time patterns
    private func predictTimeBasedSongs(userID: String) async -> [PredictedSongUsage] {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)

        // Look for songs used at similar times
        let descriptor = FetchDescriptor<UserActivityPattern>(
            predicate: #Predicate<UserActivityPattern> { pattern in
                pattern.userID == userID &&
                abs(pattern.hourOfDay - currentHour) <= 1  // Within 1 hour
            }
        )

        do {
            let patterns = try modelContext.fetch(descriptor)
            // In production: map patterns to actual song usage
            // For now: return placeholder
            return []
        } catch {
            print("❌ Failed to predict time-based songs: \(error)")
            return []
        }
    }

    /// Predicts frequently used songs
    private func predictFrequentlyUsedSongs(userID: String) async -> [PredictedSongUsage] {
        let thirtyDaysAgo = Date().addingTimeInterval(-2592000)

        let descriptor = FetchDescriptor<EditingSession>(
            predicate: #Predicate<EditingSession> { session in
                session.startTime >= thirtyDaysAgo
            }
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            let songUsageCounts = Dictionary(grouping: sessions) { $0.songID }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .prefix(5)

            let maxCount = Float(songUsageCounts.first?.value ?? 1)

            return songUsageCounts.map { songID, count in
                let score = min(0.6 + (Float(count) / maxCount) * 0.2, 0.8)

                return PredictedSongUsage(
                    songID: songID,
                    predictionScore: score,
                    predictionReason: .frequentlyUsed,
                    predictedTime: Date().addingTimeInterval(7200)  // Within 2 hours
                )
            }
        } catch {
            print("❌ Failed to predict frequently used songs: \(error)")
            return []
        }
    }

    /// Predicts songs based on set sequences
    private func predictSetSequenceSongs() async -> [PredictedSongUsage] {
        // TODO: Analyze set lists to predict "if song A, then probably song B"
        // This requires integration with SetManager and historical set data
        return []
    }

    /// Predicts songs for anticipated offline periods
    private func predictOfflinePeriodSongs(userID: String) async -> [PredictedSongUsage] {
        // Detect if user typically goes offline at certain times
        // Pre-fetch songs that might be needed during offline period

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // Check if next few hours are typically offline
        // For now, return high-priority songs if evening (when users might travel)
        if currentHour >= 17 && currentHour <= 20 {
            // Evening - might go offline for commute/performance
            return await predictUpcomingSetSongs().map { prediction in
                var updated = prediction
                updated.predictionScore = min(prediction.predictionScore + 0.1, 1.0)
                return updated
            }
        }

        return []
    }

    // MARK: - Pre-fetching

    /// Pre-fetches predicted songs
    func prefetchPredictedSongs() async -> PrefetchResult {
        let predictions = await predictUpcomingSongs()
        var prefetchedCount = 0
        var failedCount = 0

        for prediction in predictions where !prediction.isPrefetched {
            let success = await prefetchSong(songID: prediction.songID)
            if success {
                prefetchedCount += 1
                prediction.isPrefetched = true
            } else {
                failedCount += 1
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save prefetch status: \(error)")
        }

        return PrefetchResult(
            totalPredictions: predictions.count,
            prefetched: prefetchedCount,
            failed: failedCount
        )
    }

    /// Pre-fetches a specific song
    private func prefetchSong(songID: UUID) async -> Bool {
        // TODO: Integrate with CloudKitSyncCoordinator to fetch song
        // For now: simulate prefetch
        print("📥 Pre-fetching song: \(songID)")

        // In production:
        // 1. Check if song is already synced
        // 2. Fetch song from CloudKit if needed
        // 3. Cache locally

        return true
    }

    /// Downloads songs for upcoming set in advance
    func prefetchUpcomingSet(setID: UUID) async -> Bool {
        print("📥 Pre-fetching songs for set: \(setID)")

        // TODO: Integrate with Set model
        // 1. Get all songs in set
        // 2. Predict order
        // 3. Download in sequence
        // 4. Return success

        return true
    }

    /// Anticipates offline period and downloads accordingly
    func prepareForOffline(duration: TimeInterval) async -> OfflinePreparationResult {
        let estimatedSongsNeeded = Int(duration / 600)  // Assume 10 min per song
        let predictions = await predictUpcomingSongs(count: estimatedSongsNeeded)

        var downloadedSongs: [UUID] = []
        var estimatedDataSize: Int64 = 0

        for prediction in predictions {
            if await prefetchSong(songID: prediction.songID) {
                downloadedSongs.append(prediction.songID)
                // Estimate 100KB per song
                estimatedDataSize += 100_000
            }
        }

        return OfflinePreparationResult(
            songsDownloaded: downloadedSongs,
            totalCount: downloadedSongs.count,
            estimatedDataSize: estimatedDataSize,
            readyForOffline: downloadedSongs.count >= min(estimatedSongsNeeded, predictions.count)
        )
    }

    // MARK: - Analysis

    /// Analyzes prediction accuracy for learning
    func analyzePredictionAccuracy() async -> PredictionAccuracyReport {
        let oneDayAgo = Date().addingTimeInterval(-86400)

        let predictDescriptor = FetchDescriptor<PredictedSongUsage>(
            predicate: #Predicate<PredictedSongUsage> { prediction in
                prediction.createdAt >= oneDayAgo &&
                prediction.predictedTime <= Date()
            }
        )

        let sessionDescriptor = FetchDescriptor<EditingSession>(
            predicate: #Predicate<EditingSession> { session in
                session.startTime >= oneDayAgo
            }
        )

        do {
            let predictions = try modelContext.fetch(predictDescriptor)
            let sessions = try modelContext.fetch(sessionDescriptor)

            let predictedSongIDs = Set(predictions.map { $0.songID })
            let actualSongIDs = Set(sessions.map { $0.songID })

            let correctPredictions = predictedSongIDs.intersection(actualSongIDs)
            let falsePositives = predictedSongIDs.subtracting(actualSongIDs)
            let missedSongs = actualSongIDs.subtracting(predictedSongIDs)

            let accuracy = predictions.isEmpty ? 0.0 : Float(correctPredictions.count) / Float(predictions.count)
            let recall = actualSongIDs.isEmpty ? 0.0 : Float(correctPredictions.count) / Float(actualSongIDs.count)
            let precision = predictedSongIDs.isEmpty ? 0.0 : Float(correctPredictions.count) / Float(predictedSongIDs.count)

            return PredictionAccuracyReport(
                totalPredictions: predictions.count,
                correctPredictions: correctPredictions.count,
                falsePositives: falsePositives.count,
                missedSongs: missedSongs.count,
                accuracy: accuracy,
                recall: recall,
                precision: precision
            )
        } catch {
            print("❌ Failed to analyze prediction accuracy: \(error)")
            return PredictionAccuracyReport(
                totalPredictions: 0,
                correctPredictions: 0,
                falsePositives: 0,
                missedSongs: 0,
                accuracy: 0,
                recall: 0,
                precision: 0
            )
        }
    }
}

// MARK: - Supporting Types

struct PrefetchResult {
    let totalPredictions: Int
    let prefetched: Int
    let failed: Int

    var successRate: Float {
        guard totalPredictions > 0 else { return 0 }
        return Float(prefetched) / Float(totalPredictions)
    }
}

struct OfflinePreparationResult {
    let songsDownloaded: [UUID]
    let totalCount: Int
    let estimatedDataSize: Int64
    let readyForOffline: Bool
}

struct PredictionAccuracyReport {
    let totalPredictions: Int
    let correctPredictions: Int
    let falsePositives: Int
    let missedSongs: Int
    let accuracy: Float  // Correct / Total predictions
    let recall: Float    // Correct / Total actual songs
    let precision: Float // Correct / Total predicted

    var f1Score: Float {
        guard precision + recall > 0 else { return 0 }
        return 2 * (precision * recall) / (precision + recall)
    }
}
