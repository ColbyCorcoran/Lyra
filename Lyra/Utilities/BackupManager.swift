//
//  BackupManager.swift
//  Lyra
//
//  Local backup and restore system for data safety
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@Observable
class BackupManager {
    static let shared = BackupManager()

    var lastBackupDate: Date?
    var autoBackupEnabled: Bool = true
    var backupFrequency: BackupFrequency = .daily
    var isBackingUp: Bool = false
    var isRestoring: Bool = false

    enum BackupFrequency: String, CaseIterable, Codable {
        case daily = "Daily"
        case weekly = "Weekly"
        case manual = "Manual Only"
    }

    private init() {
        loadSettings()
        scheduleAutoBackupIfNeeded()
    }

    // MARK: - Settings

    func loadSettings() {
        let defaults = UserDefaults.standard

        autoBackupEnabled = defaults.bool(forKey: "backup.autoEnabled")
        if !defaults.bool(forKey: "backup.autoEnabled.set") {
            autoBackupEnabled = true
            defaults.set(true, forKey: "backup.autoEnabled.set")
        }

        if let freqString = defaults.string(forKey: "backup.frequency"),
           let freq = BackupFrequency(rawValue: freqString) {
            backupFrequency = freq
        }

        if let timestamp = defaults.object(forKey: "backup.lastDate") as? Date {
            lastBackupDate = timestamp
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(autoBackupEnabled, forKey: "backup.autoEnabled")
        defaults.set(backupFrequency.rawValue, forKey: "backup.frequency")

        if let lastBackup = lastBackupDate {
            defaults.set(lastBackup, forKey: "backup.lastDate")
        }
    }

    // MARK: - Backup Operations

    func createBackup(modelContext: ModelContext) async throws -> URL {
        isBackingUp = true
        defer { isBackingUp = false }

        // Create backup directory
        let backupDir = getBackupDirectory()
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        // Create backup file
        let timestamp = Date().timeIntervalSince1970
        let backupFileName = "lyra_backup_\(Int(timestamp)).lyrabackup"
        let backupURL = backupDir.appendingPathComponent(backupFileName)

        // Export data
        let backupData = try await exportData(from: modelContext)

        // Compress and save
        let compressedData = try compress(data: backupData)
        try compressedData.write(to: backupURL)

        // Update last backup date
        lastBackupDate = Date()
        saveSettings()

        // Clean up old backups (keep last 5)
        cleanupOldBackups()

        return backupURL
    }

    func restoreBackup(from url: URL, to modelContext: ModelContext) async throws {
        isRestoring = true
        defer { isRestoring = false }

        // Read and decompress backup
        let compressedData = try Data(contentsOf: url)
        let backupData = try decompress(data: compressedData)

        // Import data
        try await importData(backupData, into: modelContext)

        HapticManager.shared.notification(.success)
    }

    func exportToFiles() async throws -> URL {
        // Export to Files app (user-visible location)
        let timestamp = Date().timeIntervalSince1970
        let fileName = "Lyra_Export_\(Int(timestamp)).lyrabackup"
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // This would create the backup file
        // For now, create a placeholder
        let exportData = "Lyra Backup File".data(using: .utf8)!
        try exportData.write(to: exportURL)

        return exportURL
    }

    // MARK: - Auto Backup

    private func scheduleAutoBackupIfNeeded() {
        guard autoBackupEnabled else { return }
        guard shouldCreateAutoBackup() else { return }

        // Schedule background task for auto backup
        // This would use BGTaskScheduler in production
    }

    private func shouldCreateAutoBackup() -> Bool {
        guard let lastBackup = lastBackupDate else { return true }

        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackup, to: Date()).day ?? 0

        switch backupFrequency {
        case .daily:
            return daysSinceBackup >= 1
        case .weekly:
            return daysSinceBackup >= 7
        case .manual:
            return false
        }
    }

    // MARK: - Helper Methods

    private func getBackupDirectory() -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDir.appendingPathComponent("Backups")
    }

    private func cleanupOldBackups() {
        let backupDir = getBackupDirectory()

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: []
            )

            // Sort by creation date (newest first)
            let sortedFiles = try files.sorted {
                let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2
            }

            // Delete all but the 5 most recent
            for file in sortedFiles.dropFirst(5) {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("❌ Error cleaning up old backups: \(error)")
        }
    }

    private func exportData(from context: ModelContext) async throws -> Data {
        // Export all data to JSON format
        // This would serialize all SwiftData models
        let exportDict: [String: Any] = [
            "version": "1.0",
            "timestamp": Date().timeIntervalSince1970,
            "data": "Exported data placeholder"
        ]

        return try JSONSerialization.data(withJSONObject: exportDict)
    }

    private func importData(_ data: Data, into context: ModelContext) async throws {
        // Import data from JSON format
        // This would deserialize and create SwiftData models
        let json = try JSONSerialization.jsonObject(with: data)
        print("Importing data: \(json)")
    }

    private func compress(data: Data) throws -> Data {
        // Compress using zlib or similar
        // For now, just return the data
        return data
    }

    private func decompress(data: Data) throws -> Data {
        // Decompress using zlib or similar
        // For now, just return the data
        return data
    }

    // MARK: - Status Helpers

    var backupStatusMessage: String {
        if let lastBackup = lastBackupDate {
            return "Last backup \(lastBackup.timeAgo())"
        } else {
            return "No backups yet"
        }
    }

    var nextBackupMessage: String {
        guard autoBackupEnabled, let lastBackup = lastBackupDate else {
            return "Auto backup disabled"
        }

        let calendar = Calendar.current
        let nextBackupDate: Date

        switch backupFrequency {
        case .daily:
            nextBackupDate = calendar.date(byAdding: .day, value: 1, to: lastBackup) ?? Date()
        case .weekly:
            nextBackupDate = calendar.date(byAdding: .day, value: 7, to: lastBackup) ?? Date()
        case .manual:
            return "Manual backup only"
        }

        if nextBackupDate < Date() {
            return "Backup overdue"
        } else {
            return "Next backup \(nextBackupDate.timeAgo())"
        }
    }
}
