//
//  IntelligentSyncManager.swift
//  Lyra
//
//  Phase 7.12: Intelligent Sync Manager
//  Orchestrates all sync intelligence engines for seamless, worry-free sync
//

import Foundation
import SwiftData
import Combine

/// Main orchestrator for AI-powered sync and backup intelligence
@MainActor
@Observable
class IntelligentSyncManager {

    // MARK: - Properties

    private let modelContext: ModelContext

    // Engines
    private let timingEngine: IntelligentSyncTimingEngine
    private let predictiveEngine: PredictiveSyncEngine
    private let conflictEngine: ConflictPreventionEngine
    private let backupEngine: SmartBackupEngine
    private let integrityEngine: DataIntegrityEngine
    private let networkEngine: NetworkOptimizationEngine
    private let recoveryEngine: RecoveryIntelligenceEngine
    private let insightsEngine: SyncInsightsEngine

    // State
    var isIntelligentSyncEnabled: Bool = true
    var currentHealthScore: SyncHealthScore?
    var lastIntelligentSync: Date?

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Initialize all engines
        self.timingEngine = IntelligentSyncTimingEngine(modelContext: modelContext)
        self.predictiveEngine = PredictiveSyncEngine(modelContext: modelContext)
        self.conflictEngine = ConflictPreventionEngine(modelContext: modelContext)
        self.backupEngine = SmartBackupEngine(modelContext: modelContext)
        self.integrityEngine = DataIntegrityEngine(modelContext: modelContext)
        self.networkEngine = NetworkOptimizationEngine(modelContext: modelContext)
        self.recoveryEngine = RecoveryIntelligenceEngine(modelContext: modelContext, backupEngine: backupEngine)
        self.insightsEngine = SyncInsightsEngine(modelContext: modelContext)
    }

    // MARK: - Main Sync Flow

    /// Performs intelligent sync with all AI enhancements
    func performIntelligentSync(userID: String = "default") async -> IntelligentSyncResult {
        guard isIntelligentSyncEnabled else {
            return IntelligentSyncResult(
                success: false,
                stage: "Disabled",
                message: "Intelligent sync is disabled"
            )
        }

        print("🤖 Starting intelligent sync...")
        let startTime = Date()

        // Stage 1: Check if now is a good time to sync
        let timingDecision = await timingEngine.shouldSyncNow(userID: userID)
        guard timingDecision.shouldSync else {
            print("⏸️ Deferring sync: \(timingDecision.reason)")
            return IntelligentSyncResult(
                success: false,
                stage: "Timing",
                message: "Deferred: \(timingDecision.reason)",
                nextRecommendedTime: timingDecision.nextRecommendedTime
            )
        }

        // Stage 2: Pre-sync backup
        print("💾 Creating pre-sync backup...")
        let backupCreated = await backupEngine.backupBeforeMajorChange(
            changeType: .importData,
            affectedRecords: []
        )
        if !backupCreated {
            print("⚠️ Backup failed, but continuing...")
        }

        // Stage 3: Scan for conflicts
        print("🔍 Scanning for conflicts...")
        let conflicts = await conflictEngine.scanForConflicts()
        if !conflicts.isEmpty {
            print("⚠️ Found \(conflicts.count) potential conflicts")
            // Attempt to resolve
            for conflict in conflicts {
                _ = await conflictEngine.resolveConflict(
                    detectionID: conflict.id,
                    strategy: .lock
                )
            }
        }

        // Stage 4: Predictive pre-fetch
        print("📥 Pre-fetching predicted songs...")
        let prefetchResult = await predictiveEngine.prefetchPredictedSongs()
        print("  Pre-fetched: \(prefetchResult.prefetched)/\(prefetchResult.totalPredictions)")

        // Stage 5: Network optimization
        print("📡 Optimizing network...")
        let networkSpeed = await networkEngine.estimateNetworkSpeed()
        let syncQuality = await networkEngine.determineAdaptiveQuality(networkSpeed: networkSpeed)
        print("  Network: \(networkSpeed.rawValue), Quality: \(syncQuality.rawValue)")

        // Stage 6: Perform actual sync (delegate to EnhancedCloudKitSync)
        print("☁️ Syncing with CloudKit...")
        let syncSuccess = await performCloudKitSync(quality: syncQuality)

        if !syncSuccess {
            print("❌ CloudKit sync failed")
            return IntelligentSyncResult(
                success: false,
                stage: "CloudKit",
                message: "Sync failed"
            )
        }

        // Stage 7: Verify data integrity
        print("✅ Verifying data integrity...")
        let verificationResult = await integrityEngine.verifyAfterSync(recordIDs: [])
        if verificationResult.corruptedRecords > 0 {
            print("⚠️ Found \(verificationResult.corruptedRecords) corrupted records")
            await integrityEngine.alertUserOfIssues(result: verificationResult)
        }

        // Stage 8: Post-sync backup
        print("💾 Creating post-sync backup...")
        _ = await backupEngine.createIncrementalBackup(since: startTime)

        // Stage 9: Record statistics
        let duration = Date().timeIntervalSince(startTime)
        await insightsEngine.recordSyncStatistics(
            success: true,
            dataUploaded: 0,  // TODO: Get actual values
            dataDownloaded: 0,
            duration: duration
        )

        // Stage 10: Update health score
        currentHealthScore = await insightsEngine.calculateSyncHealthScore()
        lastIntelligentSync = Date()

        print("✅ Intelligent sync completed in \(String(format: "%.1f", duration))s")
        print("   Health Score: \(String(format: "%.0f", currentHealthScore?.overallScore ?? 0))/100")

        return IntelligentSyncResult(
            success: true,
            stage: "Complete",
            message: "Sync completed successfully",
            healthScore: currentHealthScore,
            duration: duration
        )
    }

    // MARK: - Individual Operations

    /// Checks if sync should happen now
    func shouldSyncNow(userID: String = "default") async -> SyncTimingDecision {
        return await timingEngine.shouldSyncNow(userID: userID)
    }

    /// Predicts upcoming songs
    func predictUpcomingSongs(count: Int = 10) async -> [PredictedSongUsage] {
        return await predictiveEngine.predictUpcomingSongs(userID: "default", count: count)
    }

    /// Prepares for offline period
    func prepareForOffline(duration: TimeInterval) async -> OfflinePreparationResult {
        return await predictiveEngine.prepareForOffline(duration: duration)
    }

    /// Acquires edit lock
    func acquireEditLock(recordID: String, recordType: String) async -> LockResult {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        return await conflictEngine.acquireEditLock(
            recordID: recordID,
            recordType: recordType,
            deviceID: deviceID
        )
    }

    /// Releases edit lock
    func releaseEditLock(lockID: UUID) async -> Bool {
        return await conflictEngine.releaseEditLock(lockID: lockID)
    }

    /// Creates manual backup
    func createManualBackup() async -> IntelligentBackup? {
        return await backupEngine.createFullBackup()
    }

    /// Restores from backup
    func restoreBackup(backupID: UUID) async -> RestoreResult {
        return await backupEngine.restoreBackup(backupID: backupID)
    }

    /// Detects data loss
    func detectDataLoss() async -> [DataLossEvent] {
        return await recoveryEngine.detectDataLoss()
    }

    /// Auto-recovers from data loss
    func autoRecover(eventID: UUID) async -> RecoveryResult {
        return await recoveryEngine.autoRecover(eventID: eventID)
    }

    /// Gets sync health score
    func getSyncHealthScore() async -> SyncHealthScore {
        if let cached = currentHealthScore,
           Date().timeIntervalSince(cached.lastCalculated) < 300 {  // 5 min cache
            return cached
        }

        let score = await insightsEngine.calculateSyncHealthScore()
        currentHealthScore = score
        return score
    }

    /// Gets optimization tips
    func getOptimizationTips() async -> [SyncOptimizationTip] {
        return await insightsEngine.generateOptimizationTips()
    }

    /// Gets sync statistics
    func getSyncStatistics(period: StatisticsPeriod) async -> AggregatedStatistics {
        return await insightsEngine.getSyncStatistics(period: period)
    }

    // MARK: - Background Tasks

    /// Runs background maintenance
    func runBackgroundMaintenance() async {
        print("🔧 Running background maintenance...")

        // 1. Cleanup expired locks
        let expiredLocks = await conflictEngine.cleanupExpiredLocks()
        if expiredLocks > 0 {
            print("  Cleaned \(expiredLocks) expired locks")
        }

        // 2. Optimize download queue
        await networkEngine.optimizeDownloadQueue()

        // 3. Detect data loss
        let lossEvents = await recoveryEngine.detectDataLoss()
        if !lossEvents.isEmpty {
            print("  ⚠️ Detected \(lossEvents.count) data loss events")
        }

        // 4. Update activity patterns
        await timingEngine.recordActivity(activityLevel: 0.0)

        print("✅ Background maintenance complete")
    }

    /// Schedules intelligent sync
    func scheduleIntelligentSync() async {
        // Check if good time to sync
        let decision = await timingEngine.shouldSyncNow()

        if decision.shouldSync {
            _ = await performIntelligentSync()
        } else if let nextTime = decision.nextRecommendedTime {
            print("⏰ Next sync scheduled for: \(nextTime)")
            // TODO: Schedule background task for nextTime
        }
    }

    // MARK: - Private Helpers

    private func performCloudKitSync(quality: SyncQuality) async -> Bool {
        // Delegate to existing EnhancedCloudKitSync
        do {
            try await EnhancedCloudKitSync.shared.performIncrementalSync()
            return true
        } catch {
            print("❌ CloudKit sync error: \(error)")
            return false
        }
    }

    // MARK: - Record Editing Session

    /// Starts tracking an editing session
    func startEditingSession(songID: UUID) async -> UUID {
        let session = EditingSession(songID: songID)
        modelContext.insert(session)

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to start editing session: \(error)")
        }

        return session.id
    }

    /// Ends an editing session
    func endEditingSession(sessionID: UUID) async {
        let descriptor = FetchDescriptor<EditingSession>(
            predicate: #Predicate<EditingSession> { session in
                session.id == sessionID
            }
        )

        do {
            guard let session = try modelContext.fetch(descriptor).first else { return }

            session.endTime = Date()
            session.isComplete = true

            try modelContext.save()

            // Check if probably done editing (trigger sync?)
            let doneConfidence = await timingEngine.isProbablyDoneEditing(sessionID: sessionID)
            if doneConfidence > 0.8 {
                print("📤 User likely done editing - triggering sync")
                Task {
                    await scheduleIntelligentSync()
                }
            }
        } catch {
            print("❌ Failed to end editing session: \(error)")
        }
    }

    /// Records an edit in current session
    func recordEdit(sessionID: UUID) async {
        let descriptor = FetchDescriptor<EditingSession>(
            predicate: #Predicate<EditingSession> { session in
                session.id == sessionID
            }
        )

        do {
            guard let session = try modelContext.fetch(descriptor).first else { return }

            session.editCount += 1

            try modelContext.save()
        } catch {
            print("❌ Failed to record edit: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct IntelligentSyncResult {
    let success: Bool
    let stage: String
    let message: String
    var nextRecommendedTime: Date? = nil
    var healthScore: SyncHealthScore? = nil
    var duration: TimeInterval = 0
}
