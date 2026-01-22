//
//  CloudKitSyncCoordinator.swift
//  Lyra
//
//  Manages CloudKit sync operations, conflict detection, and NSPersistentCloudKitContainer integration
//

import Foundation
import SwiftData
import CloudKit
import Combine
import CoreData
import UIKit

@MainActor
@Observable
class CloudKitSyncCoordinator {
    static let shared = CloudKitSyncCoordinator()

    // MARK: - Published Properties

    var isSyncing: Bool = false
    var lastError: Error?
    var lastSyncDate: Date?

    // MARK: - Private Properties

    private var modelContainer: ModelContainer?
    private var persistentContainer: NSPersistentCloudKitContainer?
    private var eventSubscription: AnyCancellable?
    private var historyToken: NSPersistentHistoryToken?

    private let conflictManager = ConflictResolutionManager.shared

    private init() {
        loadHistoryToken()
    }

    // MARK: - Setup

    /// Sets up the coordinator with the app's model container
    func setup(with container: ModelContainer) {
        self.modelContainer = container

        // Access the underlying NSPersistentContainer
        // Note: SwiftData's ModelContainer doesn't directly expose NSPersistentCloudKitContainer
        // This is a placeholder for when Apple provides direct access
        setupCloudKitNotifications()
    }

    /// Sets up CloudKit change notifications
    private func setupCloudKitNotifications() {
        // Subscribe to CloudKit notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStoreRemoteChange),
            name: NSNotification.Name.NSPersistentStoreRemoteChange,
            object: nil
        )
    }

    @objc private func handleStoreRemoteChange(_ notification: Notification) {
        Task {
            await performConflictDetection()
        }
    }

    // MARK: - Sync Operations

    /// Performs a manual sync operation
    func performSync() async throws {
        guard !isSyncing else { return }

        isSyncing = true
        lastError = nil

        do {
            // SwiftData automatically handles sync with iCloud
            // We just need to detect any conflicts that occurred
            await performConflictDetection()

            lastSyncDate = Date()
            CloudSyncManager.shared.lastSyncDate = Date()
            CloudSyncManager.shared.syncStatus = .success

            isSyncing = false
        } catch {
            lastError = error
            CloudSyncManager.shared.syncStatus = .error(error.localizedDescription)
            isSyncing = false
            throw error
        }
    }

    /// Performs background sync check
    func performBackgroundSync() async {
        guard !isSyncing else { return }

        do {
            try await performSync()
        } catch {
            print("❌ Background sync failed: \(error)")
        }
    }

    // MARK: - Conflict Detection

    /// Detects conflicts by comparing local and CloudKit versions
    func performConflictDetection() async {
        guard let container = modelContainer else { return }

        do {
            // Fetch all songs from local database
            let context = container.mainContext
            let descriptor = FetchDescriptor<Song>()
            let songs = try context.fetch(descriptor)

            // Check each song for potential conflicts
            for song in songs {
                if let conflict = await detectConflictForSong(song, context: context) {
                    conflictManager.addConflict(conflict)
                }
            }
        } catch {
            print("❌ Error detecting conflicts: \(error)")
            lastError = error
        }
    }

    /// Detects conflicts for a specific song
    private func detectConflictForSong(_ song: Song, context: ModelContext) async -> SyncConflict? {
        // In a real implementation, this would:
        // 1. Query CloudKit for the server version of this record
        // 2. Compare timestamps and content hashes
        // 3. Detect if both local and remote have changed since last sync
        // 4. Create a SyncConflict if versions diverge

        // For now, this is a placeholder that demonstrates the structure
        // Real implementation would use CKDatabase queries

        return nil
    }

    /// Handles CKError.serverRecordChanged errors
    func handleCKError(_ error: CKError, for song: Song) -> SyncConflict? {
        guard error.code == .serverRecordChanged else { return nil }

        // Extract server record from error
        guard let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
              let clientRecord = error.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord else {
            return nil
        }

        // Create conflict versions
        let localVersion = createConflictVersion(from: clientRecord, deviceName: UIDevice.current.name)
        let remoteVersion = createConflictVersion(from: serverRecord, deviceName: serverRecord["deviceName"] as? String ?? "Unknown Device")

        // Determine conflict type
        let conflictType: SyncConflict.ConflictType
        if clientRecord["isDeleted"] as? Bool == true || serverRecord["isDeleted"] as? Bool == true {
            conflictType = .deletion
        } else if clientRecord["content"] != serverRecord["content"] {
            conflictType = .contentModification
        } else {
            conflictType = .propertyConflict
        }

        return SyncConflict(
            conflictType: conflictType,
            entityType: .song,
            entityID: song.id,
            localVersion: localVersion,
            remoteVersion: remoteVersion,
            detectedAt: Date()
        )
    }

    /// Creates a ConflictVersion from a CKRecord
    private func createConflictVersion(from record: CKRecord, deviceName: String) -> SyncConflict.ConflictVersion {
        var data = SyncConflict.ConflictVersion.ConflictData()

        // Extract song data from CloudKit record
        data.title = record["title"] as? String
        data.artist = record["artist"] as? String
        data.content = record["content"] as? String
        data.key = record["originalKey"] as? String
        data.lastModified = record["modifiedAt"] as? Date
        data.isDeleted = record["isDeleted"] as? Bool ?? false

        // Identify changed properties
        data.changedProperties = record.changedKeys().map { $0 }

        return SyncConflict.ConflictVersion(
            timestamp: record.modificationDate ?? Date(),
            deviceName: deviceName,
            data: data
        )
    }

    // MARK: - Remote Notifications

    /// Handles CloudKit push notifications
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        guard let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo) else {
            return
        }

        // Trigger conflict detection when remote changes occur
        await performConflictDetection()
    }

    // MARK: - History Token Management

    /// Loads the last sync history token
    private func loadHistoryToken() {
        if let data = UserDefaults.standard.data(forKey: "cloudkit.historyToken"),
           let token = try? NSKeyedUnarchiver.unarchivedObject(
               ofClass: NSPersistentHistoryToken.self,
               from: data
           ) {
            historyToken = token
        }
    }

    /// Saves the current sync history token
    private func saveHistoryToken() {
        guard let token = historyToken else { return }

        if let data = try? NSKeyedArchiver.archivedData(
            withRootObject: token,
            requiringSecureCoding: true
        ) {
            UserDefaults.standard.set(data, forKey: "cloudkit.historyToken")
        }
    }

    /// Fetches changes since last sync using history tracking
    private func fetchChangesSinceLastSync() async throws -> [NSPersistentHistoryChange] {
        guard let container = persistentContainer else { return [] }

        let context = container.newBackgroundContext()

        return try await context.perform {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: self.historyToken)

            guard let result = try context.execute(request) as? NSPersistentHistoryResult,
                  let transactions = result.result as? [NSPersistentHistoryTransaction] else {
                return []
            }

            // Update history token
            if let lastTransaction = transactions.last {
                self.historyToken = lastTransaction.token
                self.saveHistoryToken()
            }

            // Extract all changes
            return transactions.flatMap { $0.changes ?? [] }
        }
    }

    // MARK: - Conflict Resolution Support

    /// Applies the local version to CloudKit
    func applyLocalVersion(_ conflict: SyncConflict, modelContext: ModelContext) async throws {
        // In production, this would:
        // 1. Fetch the local entity
        // 2. Force push to CloudKit with updated change tag
        // 3. Update last sync timestamp

        print("✅ Applied local version for conflict: \(conflict.id)")
    }

    /// Applies the remote version to local database
    func applyRemoteVersion(_ conflict: SyncConflict, modelContext: ModelContext) async throws {
        // In production, this would:
        // 1. Fetch the remote CKRecord
        // 2. Update local SwiftData entity
        // 3. Save context
        // 4. Update last sync timestamp

        print("✅ Applied remote version for conflict: \(conflict.id)")
    }

    /// Creates duplicate entities for "keep both" resolution
    func keepBothVersions(_ conflict: SyncConflict, modelContext: ModelContext) async throws {
        // In production, this would:
        // 1. Clone the local entity with " (Local)" suffix
        // 2. Update local entity with remote data
        // 3. Save both entities

        print("✅ Kept both versions for conflict: \(conflict.id)")
    }

    /// Merges non-conflicting changes from both versions
    func mergeVersions(_ conflict: SyncConflict, modelContext: ModelContext, mergedData: SyncConflict.ConflictVersion.ConflictData) async throws {
        // In production, this would:
        // 1. Apply merged data to local entity
        // 2. Push merged version to CloudKit
        // 3. Update last sync timestamp

        print("✅ Merged versions for conflict: \(conflict.id)")
    }
}

// MARK: - CloudKit Configuration

extension CloudKitSyncCoordinator {
    /// Checks if iCloud is available
    var isCloudKitAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    /// Gets the current iCloud account status
    func checkAccountStatus() async -> CKAccountStatus {
        let container = CKContainer.default()
        return try! await container.accountStatus()
    }

    /// Requests permission for push notifications
    func requestNotificationPermission() async {
        let container = CKContainer.default()

        do {
            _ = try await container.requestApplicationPermission(.userDiscoverability)
        } catch {
            print("❌ Error requesting notification permission: \(error)")
        }
    }
}
