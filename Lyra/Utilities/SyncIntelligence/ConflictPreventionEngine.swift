//
//  ConflictPreventionEngine.swift
//  Lyra
//
//  Phase 7.12: Conflict Prevention
//  Detects and prevents sync conflicts before they occur
//

import Foundation
import SwiftData
import CloudKit

/// Detects and prevents sync conflicts proactively
@MainActor
class ConflictPreventionEngine {

    private let modelContext: ModelContext
    private let lockDuration: TimeInterval = 300  // 5 minutes default

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Conflict Detection

    /// Detects potential conflicts before they occur
    func detectPotentialConflicts(recordID: String, recordType: String) async -> ConflictRisk {
        // 1. Check for active edit locks on other devices
        let hasLockOnOtherDevice = await hasActiveLockOnOtherDevice(recordID: recordID)
        if hasLockOnOtherDevice {
            return .critical
        }

        // 2. Check recent edit activity from multiple sources
        let multiDeviceEdits = await hasRecentMultiDeviceEdits(recordID: recordID)
        if multiDeviceEdits {
            return .high
        }

        // 3. Check pending sync operations
        let hasPendingSync = await hasPendingSyncForRecord(recordID: recordID)
        if hasPendingSync {
            return .medium
        }

        // 4. Check version mismatch
        let versionMismatch = await hasVersionMismatch(recordID: recordID)
        if versionMismatch {
            return .medium
        }

        return .low
    }

    /// Scans all records for potential conflicts
    func scanForConflicts() async -> [ConflictDetection] {
        var detections: [ConflictDetection] = []

        // TODO: Integrate with actual record types (Song, Set, etc.)
        // For now, check editing sessions
        let descriptor = FetchDescriptor<EditingSession>(
            predicate: #Predicate<EditingSession> { session in
                session.endTime == nil  // Active sessions
            }
        )

        do {
            let activeSessions = try modelContext.fetch(descriptor)

            for session in activeSessions {
                let risk = await detectPotentialConflicts(
                    recordID: session.songID.uuidString,
                    recordType: "Song"
                )

                if risk != .low {
                    let detection = ConflictDetection(
                        recordID: session.songID.uuidString,
                        recordType: "Song",
                        conflictRisk: risk
                    )
                    detections.append(detection)
                    modelContext.insert(detection)
                }
            }

            try modelContext.save()
        } catch {
            print("❌ Failed to scan for conflicts: \(error)")
        }

        return detections
    }

    // MARK: - Edit Locking

    /// Acquires an edit lock for a record
    func acquireEditLock(recordID: String, recordType: String, deviceID: String) async -> LockResult {
        // Check if lock already exists
        let descriptor = FetchDescriptor<EditLock>(
            predicate: #Predicate<EditLock> { lock in
                lock.recordID == recordID &&
                lock.isActive &&
                lock.expiresAt > Date()
            }
        )

        do {
            let existingLocks = try modelContext.fetch(descriptor)

            // If lock exists on another device, deny
            if let existingLock = existingLocks.first, existingLock.deviceID != deviceID {
                return LockResult(
                    success: false,
                    lockID: nil,
                    reason: "Already locked by another device",
                    lockedBy: existingLock.deviceID,
                    expiresAt: existingLock.expiresAt
                )
            }

            // If lock exists on this device, extend it
            if let existingLock = existingLocks.first, existingLock.deviceID == deviceID {
                existingLock.expiresAt = Date().addingTimeInterval(lockDuration)
                try modelContext.save()

                return LockResult(
                    success: true,
                    lockID: existingLock.id,
                    reason: "Lock extended",
                    lockedBy: deviceID,
                    expiresAt: existingLock.expiresAt
                )
            }

            // Create new lock
            let lock = EditLock(
                recordID: recordID,
                recordType: recordType,
                deviceID: deviceID
            )
            modelContext.insert(lock)
            try modelContext.save()

            return LockResult(
                success: true,
                lockID: lock.id,
                reason: "Lock acquired",
                lockedBy: deviceID,
                expiresAt: lock.expiresAt
            )

        } catch {
            print("❌ Failed to acquire edit lock: \(error)")
            return LockResult(
                success: false,
                lockID: nil,
                reason: "Error acquiring lock: \(error.localizedDescription)",
                lockedBy: nil,
                expiresAt: nil
            )
        }
    }

    /// Releases an edit lock
    func releaseEditLock(lockID: UUID) async -> Bool {
        let descriptor = FetchDescriptor<EditLock>(
            predicate: #Predicate<EditLock> { lock in
                lock.id == lockID
            }
        )

        do {
            let locks = try modelContext.fetch(descriptor)
            if let lock = locks.first {
                lock.isActive = false
                try modelContext.save()
                return true
            }
            return false
        } catch {
            print("❌ Failed to release edit lock: \(error)")
            return false
        }
    }

    /// Extends an existing lock
    func extendEditLock(lockID: UUID, additionalTime: TimeInterval = 300) async -> Bool {
        let descriptor = FetchDescriptor<EditLock>(
            predicate: #Predicate<EditLock> { lock in
                lock.id == lockID && lock.isActive
            }
        )

        do {
            let locks = try modelContext.fetch(descriptor)
            if let lock = locks.first {
                lock.expiresAt = lock.expiresAt.addingTimeInterval(additionalTime)
                try modelContext.save()
                return true
            }
            return false
        } catch {
            print("❌ Failed to extend edit lock: \(error)")
            return false
        }
    }

    /// Cleans up expired locks
    func cleanupExpiredLocks() async -> Int {
        let descriptor = FetchDescriptor<EditLock>(
            predicate: #Predicate<EditLock> { lock in
                lock.isActive && lock.expiresAt <= Date()
            }
        )

        do {
            let expiredLocks = try modelContext.fetch(descriptor)
            for lock in expiredLocks {
                lock.isActive = false
            }
            try modelContext.save()
            return expiredLocks.count
        } catch {
            print("❌ Failed to cleanup expired locks: \(error)")
            return 0
        }
    }

    // MARK: - Real-Time Collaboration

    /// Suggests taking turns for editing
    func suggestTurnTaking(recordID: String) async -> TurnSuggestion? {
        let descriptor = FetchDescriptor<EditLock>(
            predicate: #Predicate<EditLock> { lock in
                lock.recordID == recordID &&
                lock.isActive &&
                lock.expiresAt > Date()
            }
        )

        do {
            let activeLocks = try modelContext.fetch(descriptor)
            if let lock = activeLocks.first {
                let waitTime = lock.expiresAt.timeIntervalSinceNow

                return TurnSuggestion(
                    recordID: recordID,
                    currentEditor: lock.deviceID,
                    estimatedWaitTime: waitTime,
                    suggestion: "Another device is editing this. Please wait \(Int(waitTime / 60)) minutes or ask them to finish."
                )
            }
            return nil
        } catch {
            print("❌ Failed to suggest turn taking: \(error)")
            return nil
        }
    }

    /// Notifies user of concurrent edits
    func notifyOfConcurrentEdit(recordID: String) async {
        // TODO: Send local notification or in-app alert
        print("⚠️ Concurrent edit detected for record: \(recordID)")
    }

    // MARK: - Private Helpers

    private func hasActiveLockOnOtherDevice(recordID: String) async -> Bool {
        let currentDeviceID = await getCurrentDeviceID()

        let descriptor = FetchDescriptor<EditLock>(
            predicate: #Predicate<EditLock> { lock in
                lock.recordID == recordID &&
                lock.isActive &&
                lock.expiresAt > Date()
            }
        )

        do {
            let locks = try modelContext.fetch(descriptor)
            return locks.contains { $0.deviceID != currentDeviceID }
        } catch {
            print("❌ Failed to check locks: \(error)")
            return false
        }
    }

    private func hasRecentMultiDeviceEdits(recordID: String) async -> Bool {
        // TODO: Check CloudKit change tokens for multi-device edits
        // For now: check local edit history
        return false
    }

    private func hasPendingSyncForRecord(recordID: String) async -> Bool {
        // TODO: Check EnhancedCloudKitSync pending operations
        // For now: return false
        return false
    }

    private func hasVersionMismatch(recordID: String) async -> Bool {
        // TODO: Compare local and remote versions
        // For now: return false
        return false
    }

    private func getCurrentDeviceID() async -> String {
        // Use device identifierForVendor as device ID
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    // MARK: - Conflict Resolution

    /// Resolves a detected conflict
    func resolveConflict(detectionID: UUID, strategy: ConflictResolution) async -> Bool {
        let descriptor = FetchDescriptor<ConflictDetection>(
            predicate: #Predicate<ConflictDetection> { detection in
                detection.id == detectionID
            }
        )

        do {
            let detections = try modelContext.fetch(descriptor)
            guard let detection = detections.first else {
                return false
            }

            switch strategy {
            case .lock:
                let deviceID = await getCurrentDeviceID()
                let result = await acquireEditLock(
                    recordID: detection.recordID,
                    recordType: detection.recordType,
                    deviceID: deviceID
                )
                if result.success {
                    detection.isResolved = true
                    detection.resolutionStrategy = strategy.rawValue
                }
                return result.success

            case .queue:
                // Queue changes for later sync
                detection.isResolved = true
                detection.resolutionStrategy = strategy.rawValue
                try modelContext.save()
                return true

            case .merge:
                // Attempt auto-merge
                detection.isResolved = true
                detection.resolutionStrategy = strategy.rawValue
                try modelContext.save()
                return true

            case .notify:
                await notifyOfConcurrentEdit(recordID: detection.recordID)
                detection.isResolved = true
                detection.resolutionStrategy = strategy.rawValue
                try modelContext.save()
                return true
            }

        } catch {
            print("❌ Failed to resolve conflict: \(error)")
            return false
        }
    }
}

// MARK: - Supporting Types

struct LockResult {
    let success: Bool
    let lockID: UUID?
    let reason: String
    let lockedBy: String?
    let expiresAt: Date?
}

struct TurnSuggestion {
    let recordID: String
    let currentEditor: String
    let estimatedWaitTime: TimeInterval
    let suggestion: String
}
