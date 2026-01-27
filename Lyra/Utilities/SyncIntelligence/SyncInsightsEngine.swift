//
//  SyncInsightsEngine.swift
//  Lyra
//
//  Phase 7.12: Sync Insights
//  Provides sync health monitoring and optimization recommendations
//

import Foundation
import SwiftData

/// Provides sync insights and optimization recommendations
@MainActor
class SyncInsightsEngine {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Health Scoring

    /// Calculates overall sync health score
    func calculateSyncHealthScore() async -> SyncHealthScore {
        let syncReliability = await calculateSyncReliability()
        let dataIntegrity = await calculateDataIntegrity()
        let networkEfficiency = await calculateNetworkEfficiency()
        let backupCoverage = await calculateBackupCoverage()
        let conflictRate = await calculateConflictRate()

        // Weighted average
        let overallScore = (
            syncReliability * 0.3 +
            dataIntegrity * 0.3 +
            networkEfficiency * 0.2 +
            backupCoverage * 0.15 +
            (100 - conflictRate) * 0.05
        )

        return SyncHealthScore(
            overallScore: overallScore,
            syncReliability: syncReliability,
            dataIntegrity: dataIntegrity,
            networkEfficiency: networkEfficiency,
            backupCoverage: backupCoverage,
            conflictRate: conflictRate
        )
    }

    private func calculateSyncReliability() async -> Float {
        let thirtyDaysAgo = Date().addingTimeInterval(-2592000)

        let descriptor = FetchDescriptor<SyncStatistics>(
            predicate: #Predicate<SyncStatistics> { stats in
                stats.period >= thirtyDaysAgo
            }
        )

        do {
            let stats = try modelContext.fetch(descriptor)
            let totalSyncs = stats.reduce(0) { $0 + $1.totalSyncs }
            let successfulSyncs = stats.reduce(0) { $0 + $1.successfulSyncs }

            guard totalSyncs > 0 else { return 100.0 }

            return Float(successfulSyncs) / Float(totalSyncs) * 100.0
        } catch {
            return 100.0
        }
    }

    private func calculateDataIntegrity() async -> Float {
        let descriptor = FetchDescriptor<IntegrityCheckHistory>(
            sortBy: [SortDescriptor(\IntegrityCheckHistory.checkTime, order: .reverse)]
        )

        do {
            guard let latest = try modelContext.fetch(descriptor).first else {
                return 100.0
            }

            guard latest.totalRecords > 0 else { return 100.0 }

            return Float(latest.validRecords) / Float(latest.totalRecords) * 100.0
        } catch {
            return 100.0
        }
    }

    private func calculateNetworkEfficiency() async -> Float {
        // Based on delta sync usage and compression ratios
        let descriptor = FetchDescriptor<DeltaSyncRecord>(
            sortBy: [SortDescriptor(\DeltaSyncRecord.syncTime, order: .reverse)]
        )

        do {
            let recentRecords = try modelContext.fetch(descriptor).prefix(100)
            let avgCompressionRatio = recentRecords.reduce(0.0) { $0 + $1.compressionRatio } / Float(recentRecords.count)

            // Lower ratio = better compression = higher score
            return (1.0 - avgCompressionRatio) * 100.0
        } catch {
            return 70.0  // Assume moderate efficiency
        }
    }

    private func calculateBackupCoverage() async -> Float {
        let descriptor = FetchDescriptor<IntelligentBackup>(
            sortBy: [SortDescriptor(\IntelligentBackup.createdAt, order: .reverse)]
        )

        do {
            let backups = try modelContext.fetch(descriptor)

            // Check backup recency
            guard let latest = backups.first else {
                return 0.0  // No backups
            }

            let hoursSinceBackup = Date().timeIntervalSince(latest.createdAt) / 3600

            // Score based on backup age
            if hoursSinceBackup < 24 {
                return 100.0
            } else if hoursSinceBackup < 72 {
                return 80.0
            } else if hoursSinceBackup < 168 {
                return 60.0
            } else {
                return 30.0
            }
        } catch {
            return 50.0
        }
    }

    private func calculateConflictRate() async -> Float {
        let thirtyDaysAgo = Date().addingTimeInterval(-2592000)

        let descriptor = FetchDescriptor<SyncStatistics>(
            predicate: #Predicate<SyncStatistics> { stats in
                stats.period >= thirtyDaysAgo
            }
        )

        do {
            let stats = try modelContext.fetch(descriptor)
            let totalSyncs = stats.reduce(0) { $0 + $1.totalSyncs }
            let conflicts = stats.reduce(0) { $0 + $1.conflictsDetected }

            guard totalSyncs > 0 else { return 0.0 }

            return Float(conflicts) / Float(totalSyncs) * 100.0
        } catch {
            return 0.0
        }
    }

    // MARK: - Sync Status

    /// Shows what's currently synced
    func getSyncedStatus() async -> SyncedStatus {
        // TODO: Query actual synced vs pending records
        return SyncedStatus(
            totalRecords: 0,
            syncedRecords: 0,
            pendingRecords: 0,
            lastSyncTime: Date()
        )
    }

    /// Shows pending changes
    func getPendingChanges() async -> [PendingChange] {
        // TODO: Query records with unsyncedChanges
        return []
    }

    // MARK: - Optimization Tips

    /// Generates optimization tips based on current state
    func generateOptimizationTips() async -> [SyncOptimizationTip] {
        var tips: [SyncOptimizationTip] = []

        // Check storage
        if await isStorageHigh() {
            tips.append(SyncOptimizationTip(
                category: .storage,
                title: "High Storage Usage",
                description: "Consider cleaning up old backups or syncing less frequently.",
                impact: .high
            ))
        }

        // Check network usage
        if await isNetworkUsageHigh() {
            tips.append(SyncOptimizationTip(
                category: .network,
                title: "High Network Usage",
                description: "Enable delta sync to reduce bandwidth consumption.",
                impact: .medium
            ))
        }

        // Check sync timing
        if await shouldAdjustSyncTiming() {
            tips.append(SyncOptimizationTip(
                category: .timing,
                title: "Suboptimal Sync Timing",
                description: "Sync is happening during high activity. Adjust timing for better performance.",
                impact: .medium
            ))
        }

        // Check conflicts
        let conflictRate = await calculateConflictRate()
        if conflictRate > 5.0 {
            tips.append(SyncOptimizationTip(
                category: .conflicts,
                title: "Frequent Conflicts",
                description: "Multiple devices are editing simultaneously. Enable edit locking.",
                impact: .high
            ))
        }

        // Check backup status
        let backupCoverage = await calculateBackupCoverage()
        if backupCoverage < 70.0 {
            tips.append(SyncOptimizationTip(
                category: .backup,
                title: "Infrequent Backups",
                description: "Your backups are outdated. Enable automatic backups for better protection.",
                impact: .high
            ))
        }

        return tips
    }

    // MARK: - Statistics

    /// Gets sync statistics for a period
    func getSyncStatistics(period: StatisticsPeriod) async -> AggregatedStatistics {
        let startDate = period.startDate

        let descriptor = FetchDescriptor<SyncStatistics>(
            predicate: #Predicate<SyncStatistics> { stats in
                stats.period >= startDate
            }
        )

        do {
            let stats = try modelContext.fetch(descriptor)

            return AggregatedStatistics(
                period: period,
                totalSyncs: stats.reduce(0) { $0 + $1.totalSyncs },
                successfulSyncs: stats.reduce(0) { $0 + $1.successfulSyncs },
                failedSyncs: stats.reduce(0) { $0 + $1.failedSyncs },
                dataUploaded: stats.reduce(0) { $0 + $1.dataUploaded },
                dataDownloaded: stats.reduce(0) { $0 + $1.dataDownloaded },
                conflictsDetected: stats.reduce(0) { $0 + $1.conflictsDetected },
                conflictsResolved: stats.reduce(0) { $0 + $1.conflictsResolved },
                backupCount: stats.reduce(0) { $0 + $1.backupCount }
            )

        } catch {
            print("❌ Failed to get sync statistics: \(error)")
            return AggregatedStatistics(period: period)
        }
    }

    /// Records sync statistics
    func recordSyncStatistics(
        success: Bool,
        dataUploaded: Int64,
        dataDownloaded: Int64,
        duration: TimeInterval,
        conflictsDetected: Int = 0
    ) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<SyncStatistics>(
            predicate: #Predicate<SyncStatistics> { stats in
                stats.period == today
            }
        )

        do {
            let existing = try modelContext.fetch(descriptor)

            if let stats = existing.first {
                // Update existing
                stats.totalSyncs += 1
                if success {
                    stats.successfulSyncs += 1
                } else {
                    stats.failedSyncs += 1
                }
                stats.dataUploaded += dataUploaded
                stats.dataDownloaded += dataDownloaded
                stats.conflictsDetected += conflictsDetected

                // Update average duration
                let totalDuration = stats.averageSyncDuration * Double(stats.totalSyncs - 1) + duration
                stats.averageSyncDuration = totalDuration / Double(stats.totalSyncs)
            } else {
                // Create new
                let stats = SyncStatistics(
                    period: today,
                    totalSyncs: 1,
                    successfulSyncs: success ? 1 : 0,
                    failedSyncs: success ? 0 : 1,
                    dataUploaded: dataUploaded,
                    dataDownloaded: dataDownloaded,
                    conflictsDetected: conflictsDetected,
                    averageSyncDuration: duration
                )
                modelContext.insert(stats)
            }

            try modelContext.save()
        } catch {
            print("❌ Failed to record sync statistics: \(error)")
        }
    }

    // MARK: - Helpers

    private func isStorageHigh() async -> Bool {
        // Check if backups are taking up too much space
        let descriptor = FetchDescriptor<IntelligentBackup>()

        do {
            let backups = try modelContext.fetch(descriptor)
            let totalSize = backups.reduce(0) { $0 + $1.dataSize }

            // If backups exceed 100MB, suggest cleanup
            return totalSize > 100_000_000
        } catch {
            return false
        }
    }

    private func isNetworkUsageHigh() async -> Bool {
        // Check if delta sync is being used
        let descriptor = FetchDescriptor<DeltaSyncRecord>()

        do {
            let records = try modelContext.fetch(descriptor)
            let avgCompressionRatio = records.reduce(0.0) { $0 + $1.compressionRatio } / Float(records.count)

            // If compression ratio is high (> 0.7), not optimizing well
            return avgCompressionRatio > 0.7
        } catch {
            return false
        }
    }

    private func shouldAdjustSyncTiming() async -> Bool {
        // Check if sync is happening during high activity periods
        // TODO: Integrate with UserActivityPattern
        return false
    }
}

// MARK: - Supporting Types

struct SyncedStatus {
    let totalRecords: Int
    let syncedRecords: Int
    let pendingRecords: Int
    let lastSyncTime: Date

    var syncedPercentage: Float {
        guard totalRecords > 0 else { return 100.0 }
        return Float(syncedRecords) / Float(totalRecords) * 100.0
    }
}

struct PendingChange {
    let recordID: String
    let recordType: String
    let changeType: String
    let timestamp: Date
}

enum StatisticsPeriod {
    case day
    case week
    case month
    case year

    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
}

struct AggregatedStatistics {
    let period: StatisticsPeriod
    var totalSyncs: Int = 0
    var successfulSyncs: Int = 0
    var failedSyncs: Int = 0
    var dataUploaded: Int64 = 0
    var dataDownloaded: Int64 = 0
    var conflictsDetected: Int = 0
    var conflictsResolved: Int = 0
    var backupCount: Int = 0

    var successRate: Float {
        guard totalSyncs > 0 else { return 100.0 }
        return Float(successfulSyncs) / Float(totalSyncs) * 100.0
    }

    var conflictResolutionRate: Float {
        guard conflictsDetected > 0 else { return 100.0 }
        return Float(conflictsResolved) / Float(conflictsDetected) * 100.0
    }
}
