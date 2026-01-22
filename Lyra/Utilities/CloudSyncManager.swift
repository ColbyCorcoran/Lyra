//
//  CloudSyncManager.swift
//  Lyra
//
//  Manages iCloud sync configuration and status
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class CloudSyncManager {
    static let shared = CloudSyncManager()

    var isSyncEnabled: Bool = false
    var syncScope: SyncScope = .all
    var allowCellularSync: Bool = false
    var lastSyncDate: Date?
    var syncStatus: SyncStatus = .idle
    var syncError: String?

    enum SyncScope: String, CaseIterable, Codable {
        case all = "Everything"
        case setsOnly = "Sets & Performances Only"
        case songsOnly = "Songs Only"
        case analyticsExcluded = "Exclude Analytics"
    }

    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }

    private init() {
        loadSettings()
    }

    // MARK: - Settings

    func loadSettings() {
        let defaults = UserDefaults.standard

        isSyncEnabled = defaults.bool(forKey: "sync.enabled")
        allowCellularSync = defaults.bool(forKey: "sync.allowCellular")

        if let scopeString = defaults.string(forKey: "sync.scope"),
           let scope = SyncScope(rawValue: scopeString) {
            syncScope = scope
        }

        if let timestamp = defaults.object(forKey: "sync.lastSyncDate") as? Date {
            lastSyncDate = timestamp
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(isSyncEnabled, forKey: "sync.enabled")
        defaults.set(allowCellularSync, forKey: "sync.allowCellular")
        defaults.set(syncScope.rawValue, forKey: "sync.scope")

        if let lastSync = lastSyncDate {
            defaults.set(lastSync, forKey: "sync.lastSyncDate")
        }
    }

    func toggleSync(_ enabled: Bool) {
        isSyncEnabled = enabled
        saveSettings()

        if enabled {
            // Trigger initial sync
            performSync()
        }
    }

    // MARK: - Sync Operations

    func performSync() {
        guard isSyncEnabled else { return }
        guard OfflineManager.shared.shouldSync else {
            syncError = "Sync disabled on cellular"
            return
        }

        syncStatus = .syncing
        syncError = nil

        // Simulate sync operation
        // In production, this would trigger CloudKit sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.lastSyncDate = Date()
            self?.syncStatus = .success
            self?.saveSettings()
        }
    }

    func forceSyncNow() {
        performSync()
        HapticManager.shared.impact(.medium)
    }

    // MARK: - Status Helpers

    var syncStatusMessage: String {
        switch syncStatus {
        case .idle:
            if let lastSync = lastSyncDate {
                return "Last synced \(lastSync.timeAgo())"
            } else {
                return "Not synced yet"
            }
        case .syncing:
            return "Syncing..."
        case .success:
            return "Sync complete"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    var syncStatusColor: Color {
        switch syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }

    var syncIcon: String {
        switch syncStatus {
        case .idle:
            return "icloud"
        case .syncing:
            return "icloud.and.arrow.up.and.down"
        case .success:
            return "icloud.and.arrow.up"
        case .error:
            return "icloud.slash"
        }
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
