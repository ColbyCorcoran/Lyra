//
//  DataMigrationManager.swift
//  Lyra
//
//  Handles data migration between schema versions
//

import Foundation
import SwiftData

@Observable
class DataMigrationManager {
    static let shared = DataMigrationManager()

    // Current schema version
    static let currentSchemaVersion = SchemaVersion(major: 1, minor: 0, patch: 0)

    // Migration state
    var isMigrating: Bool = false
    var migrationProgress: Double = 0.0
    var migrationStatus: String = ""
    var migrationError: Error?

    // Version tracking
    var installedSchemaVersion: SchemaVersion {
        get {
            if let data = UserDefaults.standard.data(forKey: "schema.version"),
               let version = try? JSONDecoder().decode(SchemaVersion.self, from: data) {
                return version
            }
            // Default to 1.0.0 if not set
            return SchemaVersion(major: 1, minor: 0, patch: 0)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "schema.version")
            }
        }
    }

    // Migration history
    var migrationHistory: [MigrationRecord] {
        get {
            if let data = UserDefaults.standard.data(forKey: "migration.history"),
               let history = try? JSONDecoder().decode([MigrationRecord].self, from: data) {
                return history
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "migration.history")
            }
        }
    }

    private init() {}

    // MARK: - Migration Check

    /// Checks if migration is needed
    func needsMigration() -> Bool {
        let installed = installedSchemaVersion
        let current = Self.currentSchemaVersion

        return installed < current
    }

    /// Gets the required migration path
    func getMigrationPath() -> [MigrationStep] {
        let fromVersion = installedSchemaVersion
        let toVersion = Self.currentSchemaVersion

        var steps: [MigrationStep] = []

        // Build migration path from installed version to current version
        // Each step represents a version upgrade

        // Example migration steps:
        // 1.0.0 -> 1.1.0: Add performance tracking
        if fromVersion < SchemaVersion(major: 1, minor: 1, patch: 0) &&
           toVersion >= SchemaVersion(major: 1, minor: 1, patch: 0) {
            steps.append(MigrationStep(
                fromVersion: SchemaVersion(major: 1, minor: 0, patch: 0),
                toVersion: SchemaVersion(major: 1, minor: 1, patch: 0),
                description: "Add performance tracking",
                migration: migrateToV1_1_0
            ))
        }

        // 1.1.0 -> 1.2.0: Add conflict resolution
        if fromVersion < SchemaVersion(major: 1, minor: 2, patch: 0) &&
           toVersion >= SchemaVersion(major: 1, minor: 2, patch: 0) {
            steps.append(MigrationStep(
                fromVersion: SchemaVersion(major: 1, minor: 1, patch: 0),
                toVersion: SchemaVersion(major: 1, minor: 2, patch: 0),
                description: "Add conflict resolution",
                migration: migrateToV1_2_0
            ))
        }

        // 1.x.x -> 2.0.0: Major schema overhaul (example)
        if fromVersion < SchemaVersion(major: 2, minor: 0, patch: 0) &&
           toVersion >= SchemaVersion(major: 2, minor: 0, patch: 0) {
            steps.append(MigrationStep(
                fromVersion: SchemaVersion(major: 1, minor: 2, patch: 0),
                toVersion: SchemaVersion(major: 2, minor: 0, patch: 0),
                description: "Major schema update",
                migration: migrateToV2_0_0
            ))
        }

        return steps
    }

    // MARK: - Migration Execution

    /// Performs all necessary migrations
    func performMigrations(modelContext: ModelContext) async throws {
        guard needsMigration() else {
            print("✅ No migration needed. Schema is up to date.")
            return
        }

        isMigrating = true
        migrationProgress = 0.0
        migrationError = nil

        let steps = getMigrationPath()
        let totalSteps = Double(steps.count)

        print("🔄 Starting migration from \(installedSchemaVersion) to \(Self.currentSchemaVersion)")
        print("📋 Migration path: \(steps.count) step(s)")

        do {
            // Create backup before migration
            migrationStatus = "Creating backup..."
            try await createPreMigrationBackup(modelContext: modelContext)
            migrationProgress = 0.1

            // Execute each migration step
            for (index, step) in steps.enumerated() {
                migrationStatus = "Migrating: \(step.description)"
                print("➡️  Step \(index + 1)/\(steps.count): \(step.fromVersion) → \(step.toVersion)")
                print("   \(step.description)")

                try await step.migration(modelContext)

                // Record successful migration
                let record = MigrationRecord(
                    fromVersion: step.fromVersion,
                    toVersion: step.toVersion,
                    description: step.description,
                    timestamp: Date(),
                    success: true
                )
                var history = migrationHistory
                history.append(record)
                migrationHistory = history

                // Update installed version
                installedSchemaVersion = step.toVersion

                // Update progress
                migrationProgress = 0.1 + (Double(index + 1) / totalSteps) * 0.9
            }

            migrationStatus = "Migration complete"
            migrationProgress = 1.0
            isMigrating = false

            print("✅ Migration completed successfully")
            print("📊 Current schema version: \(installedSchemaVersion)")

            HapticManager.shared.success()
        } catch {
            migrationError = error
            migrationStatus = "Migration failed"
            isMigrating = false

            print("❌ Migration failed: \(error)")

            // Record failed migration
            if let currentStep = steps.first {
                let record = MigrationRecord(
                    fromVersion: currentStep.fromVersion,
                    toVersion: currentStep.toVersion,
                    description: currentStep.description,
                    timestamp: Date(),
                    success: false,
                    error: error.localizedDescription
                )
                var history = migrationHistory
                history.append(record)
                migrationHistory = history
            }

            HapticManager.shared.error()
            throw error
        }
    }

    // MARK: - Individual Migration Functions

    private func migrateToV1_1_0(_ context: ModelContext) async throws {
        // Example: Add performance tracking models
        // In real implementation, you'd modify schema here
        print("   Adding performance tracking models...")

        // Simulate migration work
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        print("   ✅ Performance tracking models added")
    }

    private func migrateToV1_2_0(_ context: ModelContext) async throws {
        // Example: Add conflict resolution
        print("   Adding conflict resolution support...")

        try await Task.sleep(nanoseconds: 500_000_000)

        print("   ✅ Conflict resolution support added")
    }

    private func migrateToV2_0_0(_ context: ModelContext) async throws {
        // Example: Major schema overhaul
        print("   Performing major schema update...")
        print("   - Updating Song model...")
        print("   - Updating Book model...")
        print("   - Migrating relationships...")

        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        print("   ✅ Major schema update complete")
    }

    // MARK: - Backup and Recovery

    private func createPreMigrationBackup(modelContext: ModelContext) async throws {
        print("💾 Creating pre-migration backup...")

        // Use BackupManager to create backup
        let backupURL = try await BackupManager.shared.createBackup(modelContext: modelContext)

        // Store backup location for potential rollback
        UserDefaults.standard.set(backupURL.path, forKey: "migration.lastBackup")

        print("✅ Backup created at: \(backupURL.path)")
    }

    /// Rolls back to pre-migration backup if migration fails
    func rollbackMigration(modelContext: ModelContext) async throws {
        guard let backupPath = UserDefaults.standard.string(forKey: "migration.lastBackup") else {
            throw MigrationError.noBackupAvailable
        }

        let backupURL = URL(fileURLWithPath: backupPath)

        print("⚠️  Rolling back to pre-migration backup...")

        try await BackupManager.shared.restoreBackup(from: backupURL, to: modelContext)

        print("✅ Rollback complete")

        HapticManager.shared.warning()
    }

    // MARK: - Version Management

    /// Forces schema version (use with caution)
    func setSchemaVersion(_ version: SchemaVersion) {
        installedSchemaVersion = version
        print("⚠️  Forced schema version to \(version)")
    }

    /// Resets migration history (for testing)
    func resetMigrationHistory() {
        migrationHistory = []
        print("⚠️  Migration history reset")
    }
}

// MARK: - Schema Version

struct SchemaVersion: Codable, Comparable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    var description: String {
        "\(major).\(minor).\(patch)"
    }

    static func < (lhs: SchemaVersion, rhs: SchemaVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}

// MARK: - Migration Step

struct MigrationStep {
    let fromVersion: SchemaVersion
    let toVersion: SchemaVersion
    let description: String
    let migration: @Sendable (ModelContext) async throws -> Void
}

// MARK: - Migration Record

struct MigrationRecord: Codable, Identifiable {
    let id: UUID
    let fromVersion: SchemaVersion
    let toVersion: SchemaVersion
    let description: String
    let timestamp: Date
    let success: Bool
    var error: String?

    init(fromVersion: SchemaVersion, toVersion: SchemaVersion, description: String, timestamp: Date, success: Bool, error: String? = nil) {
        self.id = UUID()
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.description = description
        self.timestamp = timestamp
        self.success = success
        self.error = error
    }

    var statusIcon: String {
        success ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    var statusColor: String {
        success ? "green" : "red"
    }
}

// MARK: - Migration Error

enum MigrationError: LocalizedError {
    case noBackupAvailable
    case migrationFailed(String)
    case incompatibleVersion
    case dataCorrupted

    var errorDescription: String? {
        switch self {
        case .noBackupAvailable:
            return "No backup available for rollback"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .incompatibleVersion:
            return "Schema version is incompatible"
        case .dataCorrupted:
            return "Data corruption detected"
        }
    }
}
