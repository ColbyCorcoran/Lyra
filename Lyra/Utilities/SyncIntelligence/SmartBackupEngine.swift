//
//  SmartBackupEngine.swift
//  Lyra
//
//  Phase 7.12: Smart Backup
//  Intelligent backup with automatic triggers and retention management
//

import Foundation
import SwiftData
import CryptoKit

/// Smart backup system with intelligent triggers and retention
@MainActor
class SmartBackupEngine {

    private let modelContext: ModelContext
    private let maxBackups: Int = 50  // Maximum backups to keep

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Backup Creation

    /// Creates a backup with automatic importance assessment
    func createBackup(trigger: BackupTrigger, dataSnapshot: BackupSnapshot) async -> IntelligentBackup? {
        let importance = await assessBackupImportance(trigger: trigger, snapshot: dataSnapshot)
        let compressed = await compressBackupData(dataSnapshot.data)

        let checksum = await calculateChecksum(data: compressed)

        let backup = IntelligentBackup(
            backupType: dataSnapshot.type,
            trigger: trigger,
            dataSize: Int64(compressed.count),
            recordCount: dataSnapshot.recordCount,
            importance: importance,
            checksum: checksum
        )

        // Set retention based on importance
        backup.retentionUntil = await calculateRetentionDate(importance: importance)

        modelContext.insert(backup)

        do {
            try modelContext.save()

            // Save backup data
            await saveBackupData(backupID: backup.id, data: compressed)

            print("✅ Backup created: \(backup.id) (Importance: \(importance.rawValue))")

            // Cleanup old backups
            await cleanupOldBackups()

            return backup
        } catch {
            print("❌ Failed to create backup: \(error)")
            return nil
        }
    }

    /// Auto-backup before major changes
    func backupBeforeMajorChange(changeType: MajorChangeType, affectedRecords: [String]) async -> Bool {
        print("🔄 Creating backup before major change: \(changeType.rawValue)")

        let snapshot = await createSnapshot(type: .snapshot, recordIDs: affectedRecords)

        let backup = await createBackup(
            trigger: .majorChange,
            dataSnapshot: snapshot
        )

        return backup != nil
    }

    /// Backup before performance
    func backupBeforePerformance(performanceID: UUID, setID: UUID) async -> Bool {
        print("🎭 Creating backup before performance")

        // Get all songs in the set
        let songIDs = await getSongsInSet(setID: setID)
        let snapshot = await createSnapshot(type: .snapshot, recordIDs: songIDs)

        let backup = await createBackup(
            trigger: .beforePerformance,
            dataSnapshot: snapshot
        )

        return backup != nil
    }

    /// Creates incremental backup
    func createIncrementalBackup(since: Date) async -> IntelligentBackup? {
        print("📦 Creating incremental backup")

        let changedRecords = await getChangedRecordsSince(date: since)
        let snapshot = await createSnapshot(type: .incremental, recordIDs: changedRecords)

        return await createBackup(
            trigger: .scheduled,
            dataSnapshot: snapshot
        )
    }

    /// Creates full backup
    func createFullBackup() async -> IntelligentBackup? {
        print("💾 Creating full backup")

        let snapshot = await createSnapshot(type: .full, recordIDs: [])

        return await createBackup(
            trigger: .manual,
            dataSnapshot: snapshot
        )
    }

    // MARK: - Backup Assessment

    /// Assesses importance of backup for retention decisions
    private func assessBackupImportance(trigger: BackupTrigger, snapshot: BackupSnapshot) async -> BackupImportance {
        switch trigger {
        case .beforePerformance:
            return .critical  // Always keep performance backups

        case .majorChange:
            // Assess based on change magnitude
            if snapshot.recordCount > 10 {
                return .high
            } else if snapshot.recordCount > 3 {
                return .medium
            }
            return .low

        case .scheduled:
            // Check if there were significant changes since last backup
            let lastBackup = await getLastBackup()
            if let last = lastBackup {
                let timeSinceLastBackup = Date().timeIntervalSince(last.createdAt)
                if timeSinceLastBackup < 3600 {  // Less than 1 hour
                    return .low
                }
            }
            return .medium

        case .manual:
            return .high  // User-initiated backups are important

        case .preSync:
            return .medium  // Keep for rollback capability
        }
    }

    // MARK: - Retention Management

    /// Calculates retention date based on importance
    private func calculateRetentionDate(importance: BackupImportance) async -> Date? {
        let calendar = Calendar.current
        let now = Date()

        switch importance {
        case .critical:
            return nil  // Keep forever

        case .high:
            return calendar.date(byAdding: .month, value: 6, to: now)  // 6 months

        case .medium:
            return calendar.date(byAdding: .month, value: 1, to: now)  // 1 month

        case .low:
            return calendar.date(byAdding: .day, value: 7, to: now)  // 1 week
        }
    }

    /// Intelligent retention - keeps important versions
    private func cleanupOldBackups() async {
        let descriptor = FetchDescriptor<IntelligentBackup>(
            sortBy: [SortDescriptor(\IntelligentBackup.createdAt, order: .reverse)]
        )

        do {
            let allBackups = try modelContext.fetch(descriptor)

            // Always keep critical backups
            let criticalBackups = allBackups.filter { $0.importance == .critical }

            // Keep recent backups (last 10)
            let recentBackups = Array(allBackups.prefix(10))

            // Delete expired backups
            let now = Date()
            var deletedCount = 0

            for backup in allBackups {
                // Skip if critical or recent
                if criticalBackups.contains(where: { $0.id == backup.id }) ||
                   recentBackups.contains(where: { $0.id == backup.id }) {
                    continue
                }

                // Check retention date
                if let retentionDate = backup.retentionUntil, now > retentionDate {
                    await deleteBackup(backupID: backup.id)
                    modelContext.delete(backup)
                    deletedCount += 1
                }
            }

            // If still over limit, delete oldest low-importance backups
            let remainingBackups = try modelContext.fetch(descriptor)
            if remainingBackups.count > maxBackups {
                let toDelete = remainingBackups
                    .filter { $0.importance == .low }
                    .sorted { $0.createdAt < $1.createdAt }
                    .prefix(remainingBackups.count - maxBackups)

                for backup in toDelete {
                    await deleteBackup(backupID: backup.id)
                    modelContext.delete(backup)
                    deletedCount += 1
                }
            }

            try modelContext.save()

            if deletedCount > 0 {
                print("🗑️ Cleaned up \(deletedCount) old backups")
            }

        } catch {
            print("❌ Failed to cleanup old backups: \(error)")
        }
    }

    // MARK: - Backup Restore

    /// Restores data from a backup
    func restoreBackup(backupID: UUID) async -> RestoreResult {
        let descriptor = FetchDescriptor<IntelligentBackup>(
            predicate: #Predicate<IntelligentBackup> { backup in
                backup.id == backupID
            }
        )

        do {
            guard let backup = try modelContext.fetch(descriptor).first else {
                return RestoreResult(success: false, restoredRecords: 0, error: "Backup not found")
            }

            // Load backup data
            guard let data = await loadBackupData(backupID: backupID) else {
                return RestoreResult(success: false, restoredRecords: 0, error: "Failed to load backup data")
            }

            // Verify checksum
            let checksum = await calculateChecksum(data: data)
            guard checksum == backup.checksum else {
                return RestoreResult(success: false, restoredRecords: 0, error: "Backup data corrupted (checksum mismatch)")
            }

            // Decompress
            let decompressed = await decompressBackupData(data)

            // Restore data
            // TODO: Implement actual data restoration
            // This would involve deserializing and applying changes

            return RestoreResult(
                success: true,
                restoredRecords: backup.recordCount,
                error: nil
            )

        } catch {
            return RestoreResult(success: false, restoredRecords: 0, error: error.localizedDescription)
        }
    }

    // MARK: - Data Helpers

    private func createSnapshot(type: BackupType, recordIDs: [String]) async -> BackupSnapshot {
        // TODO: Serialize actual data from SwiftData
        // For now: create placeholder
        let data = Data("snapshot".utf8)

        return BackupSnapshot(
            type: type,
            data: data,
            recordCount: recordIDs.count
        )
    }

    private func compressBackupData(_ data: Data) async -> Data {
        // Use NSData compression
        if let compressed = try? (data as NSData).compressed(using: .lzfse) as Data {
            return compressed
        }
        return data
    }

    private func decompressBackupData(_ data: Data) async -> Data {
        if let decompressed = try? (data as NSData).decompressed(using: .lzfse) as Data {
            return decompressed
        }
        return data
    }

    private func calculateChecksum(data: Data) async -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func saveBackupData(backupID: UUID, data: Data) async {
        // Save to file system
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let backupDirectory = documentsURL.appendingPathComponent("Backups")
        try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        let backupFile = backupDirectory.appendingPathComponent("\(backupID.uuidString).backup")
        try? data.write(to: backupFile)
    }

    private func loadBackupData(backupID: UUID) async -> Data? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let backupFile = documentsURL
            .appendingPathComponent("Backups")
            .appendingPathComponent("\(backupID.uuidString).backup")

        return try? Data(contentsOf: backupFile)
    }

    private func deleteBackup(backupID: UUID) async {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let backupFile = documentsURL
            .appendingPathComponent("Backups")
            .appendingPathComponent("\(backupID.uuidString).backup")

        try? fileManager.removeItem(at: backupFile)
    }

    private func getLastBackup() async -> IntelligentBackup? {
        let descriptor = FetchDescriptor<IntelligentBackup>(
            sortBy: [SortDescriptor(\IntelligentBackup.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    private func getSongsInSet(setID: UUID) async -> [String] {
        // TODO: Query Set model for songs
        return []
    }

    private func getChangedRecordsSince(date: Date) async -> [String] {
        // TODO: Query SwiftData for changed records
        return []
    }
}

// MARK: - Supporting Types

enum MajorChangeType: String {
    case bulkDelete = "Bulk Delete"
    case bulkEdit = "Bulk Edit"
    case importData = "Import Data"
    case resetSettings = "Reset Settings"
}

struct BackupSnapshot {
    let type: BackupType
    let data: Data
    let recordCount: Int
}

struct RestoreResult {
    let success: Bool
    let restoredRecords: Int
    let error: String?
}
