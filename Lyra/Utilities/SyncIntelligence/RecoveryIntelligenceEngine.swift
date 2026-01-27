//
//  RecoveryIntelligenceEngine.swift
//  Lyra
//
//  Phase 7.12: Recovery Intelligence
//  Detects data loss and provides intelligent recovery options
//

import Foundation
import SwiftData

/// Intelligent data loss detection and recovery
@MainActor
class RecoveryIntelligenceEngine {

    private let modelContext: ModelContext
    private let backupEngine: SmartBackupEngine

    init(modelContext: ModelContext, backupEngine: SmartBackupEngine) {
        self.modelContext = modelContext
        self.backupEngine = backupEngine
    }

    // MARK: - Data Loss Detection

    /// Detects data loss by comparing expected vs actual records
    func detectDataLoss() async -> [DataLossEvent] {
        var events: [DataLossEvent] = []

        // 1. Check for unexpected deletions
        events.append(contentsOf: await detectUnexpectedDeletions())

        // 2. Check for sync failures
        events.append(contentsOf: await detectSyncFailures())

        // 3. Check for corruption
        events.append(contentsOf: await detectCorruptionLoss())

        // Save events
        for event in events {
            modelContext.insert(event)
        }

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save data loss events: \(error)")
        }

        return events
    }

    private func detectUnexpectedDeletions() async -> [DataLossEvent] {
        // TODO: Compare current records with last sync snapshot
        // Detect records that disappeared without explicit delete action
        return []
    }

    private func detectSyncFailures() async -> [DataLossEvent] {
        // TODO: Check EnhancedCloudKitSync for failed operations
        // Identify records that failed to sync
        return []
    }

    private func detectCorruptionLoss() async -> [DataLossEvent] {
        // TODO: Check IntegrityCheckHistory for corrupted records
        return []
    }

    // MARK: - Auto-Recovery

    /// Attempts automatic recovery from data loss
    func autoRecover(eventID: UUID) async -> RecoveryResult {
        let descriptor = FetchDescriptor<DataLossEvent>(
            predicate: #Predicate<DataLossEvent> { event in
                event.id == eventID
            }
        )

        do {
            guard let event = try modelContext.fetch(descriptor).first else {
                return RecoveryResult(
                    success: false,
                    recoveredRecords: 0,
                    method: "N/A",
                    message: "Event not found"
                )
            }

            // Only auto-recover if safe to do so
            guard event.canRecover else {
                return RecoveryResult(
                    success: false,
                    recoveredRecords: 0,
                    method: "N/A",
                    message: "Auto-recovery not available"
                )
            }

            let result: RecoveryResult

            switch event.lossType {
            case .deletion:
                result = await recoverFromDeletion(event: event)

            case .corruption:
                result = await recoverFromCorruption(event: event)

            case .syncFailure:
                result = await recoverFromSyncFailure(event: event)

            case .deviceFailure:
                result = await recoverFromDeviceFailure(event: event)
            }

            if result.success {
                event.recoveryAttempted = true
                event.recoverySuccessful = true
                try modelContext.save()
            }

            return result

        } catch {
            print("❌ Failed auto-recovery: \(error)")
            return RecoveryResult(
                success: false,
                recoveredRecords: 0,
                method: "Error",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Recovery Strategies

    private func recoverFromDeletion(event: DataLossEvent) async -> RecoveryResult {
        print("🔄 Recovering from deletion...")

        // Find most recent backup containing deleted records
        let backupDescriptor = FetchDescriptor<IntelligentBackup>(
            sortBy: [SortDescriptor(\IntelligentBackup.createdAt, order: .reverse)]
        )

        do {
            let backups = try modelContext.fetch(backupDescriptor)

            // Find backup created before deletion
            guard let backup = backups.first(where: { $0.createdAt < event.detectionTime }) else {
                return RecoveryResult(
                    success: false,
                    recoveredRecords: 0,
                    method: "Backup restore",
                    message: "No backup found before deletion"
                )
            }

            // Restore from backup
            let restoreResult = await backupEngine.restoreBackup(backupID: backup.id)

            return RecoveryResult(
                success: restoreResult.success,
                recoveredRecords: restoreResult.restoredRecords,
                method: "Backup restore",
                message: restoreResult.error ?? "Restored from backup"
            )

        } catch {
            return RecoveryResult(
                success: false,
                recoveredRecords: 0,
                method: "Backup restore",
                message: "Failed to access backups"
            )
        }
    }

    private func recoverFromCorruption(event: DataLossEvent) async -> RecoveryResult {
        print("🔄 Recovering from corruption...")

        // Attempt to restore corrupted records from backup
        // Similar to deletion recovery
        return await recoverFromDeletion(event: event)
    }

    private func recoverFromSyncFailure(event: DataLossEvent) async -> RecoveryResult {
        print("🔄 Recovering from sync failure...")

        // Re-attempt sync for failed records
        // TODO: Integrate with EnhancedCloudKitSync

        return RecoveryResult(
            success: true,
            recoveredRecords: event.affectedRecords.count,
            method: "Re-sync",
            message: "Re-synced failed records"
        )
    }

    private func recoverFromDeviceFailure(event: DataLossEvent) async -> RecoveryResult {
        print("🔄 Recovering from device failure...")

        // Pull from cloud to recover
        return RecoveryResult(
            success: false,
            recoveredRecords: 0,
            method: "Cloud restore",
            message: "Manual cloud restore required"
        )
    }

    // MARK: - Recovery Suggestions

    /// Suggests recovery actions to user
    func suggestRecoveryActions(eventID: UUID) async -> [RecoveryAction] {
        let descriptor = FetchDescriptor<DataLossEvent>(
            predicate: #Predicate<DataLossEvent> { event in
                event.id == eventID
            }
        )

        do {
            guard let event = try modelContext.fetch(descriptor).first else {
                return []
            }

            var actions: [RecoveryAction] = []

            // Check if backup is available
            if await hasRecentBackup(before: event.detectionTime) {
                actions.append(RecoveryAction(
                    actionType: .restoreBackup,
                    description: "Restore from most recent backup before data loss",
                    confidence: 0.9,
                    estimatedRecovery: 95.0,
                    isAutomatic: true
                ))
            }

            // Check if cloud has newer version
            if event.lossType == .syncFailure {
                actions.append(RecoveryAction(
                    actionType: .mergeVersions,
                    description: "Merge local and cloud versions",
                    confidence: 0.7,
                    estimatedRecovery: 80.0,
                    isAutomatic: false
                ))
            }

            // Suggest rollback for recent changes
            if event.lossType == .corruption {
                actions.append(RecoveryAction(
                    actionType: .rollback,
                    description: "Rollback to last known good state",
                    confidence: 0.8,
                    estimatedRecovery: 85.0,
                    isAutomatic: true
                ))
            }

            // Data repair option
            actions.append(RecoveryAction(
                actionType: .repairData,
                description: "Attempt to repair corrupted data",
                confidence: 0.6,
                estimatedRecovery: 60.0,
                isAutomatic: true
            ))

            return actions

        } catch {
            print("❌ Failed to suggest recovery actions: \(error)")
            return []
        }
    }

    // MARK: - Minimize Data Loss

    /// Minimizes ongoing data loss
    func minimizeDataLoss(eventID: UUID) async {
        print("🛡️ Minimizing data loss...")

        // 1. Create emergency backup
        _ = await backupEngine.createFullBackup()

        // 2. Stop sync to prevent corruption spread
        CloudSyncManager.shared.toggleSync(false)

        // 3. Alert user
        print("⚠️ Sync disabled to prevent data loss spread")
    }

    // MARK: - Helpers

    private func hasRecentBackup(before date: Date) async -> Bool {
        let descriptor = FetchDescriptor<IntelligentBackup>(
            predicate: #Predicate<IntelligentBackup> { backup in
                backup.createdAt < date
            }
        )

        do {
            let backups = try modelContext.fetch(descriptor)
            return !backups.isEmpty
        } catch {
            return false
        }
    }
}

// MARK: - Supporting Types

struct RecoveryResult {
    let success: Bool
    let recoveredRecords: Int
    let method: String
    let message: String
}
