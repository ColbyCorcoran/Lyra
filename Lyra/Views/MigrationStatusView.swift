//
//  MigrationStatusView.swift
//  Lyra
//
//  View for displaying migration status and history
//

import SwiftUI
import SwiftData

struct MigrationStatusView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var migrationManager = DataMigrationManager.shared
    @State private var showMigrationPrompt: Bool = false
    @State private var showRollbackConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // Current version section
                currentVersionSection

                // Migration status section
                if migrationManager.needsMigration() {
                    migrationNeededSection
                } else if migrationManager.isMigrating {
                    migrationInProgressSection
                } else {
                    upToDateSection
                }

                // Migration history
                if !migrationManager.migrationHistory.isEmpty {
                    migrationHistorySection
                }

                // Developer options
                #if DEBUG
                developerSection
                #endif
            }
            .navigationTitle("Data Migration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Perform Migration?", isPresented: $showMigrationPrompt) {
                Button("Cancel", role: .cancel) {}
                Button("Migrate Now") {
                    performMigration()
                }
            } message: {
                Text("This will update your data to the latest schema version. A backup will be created automatically.")
            }
            .alert("Rollback Migration?", isPresented: $showRollbackConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Rollback", role: .destructive) {
                    rollbackMigration()
                }
            } message: {
                Text("This will restore your data to the state before the last migration. Any changes since then will be lost.")
            }
        }
    }

    // MARK: - Current Version Section

    private var currentVersionSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Schema Version")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(DataMigrationManager.currentSchemaVersion.description)
                        .font(.title)
                        .fontWeight(.bold)
                        .monospaced()
                }

                Spacer()

                Image(systemName: "doc.text.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 8)

            HStack {
                Text("Installed Version")
                Spacer()
                Text(migrationManager.installedSchemaVersion.description)
                    .fontWeight(.medium)
                    .monospaced()
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Schema Information")
        }
    }

    // MARK: - Up to Date Section

    private var upToDateSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Up to Date")
                        .font(.headline)

                    Text("Your data schema is current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Status")
        }
    }

    // MARK: - Migration Needed Section

    private var migrationNeededSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Migration Available")
                        .font(.headline)

                    Text("Update to schema \(DataMigrationManager.currentSchemaVersion.description)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)

            // Migration path
            VStack(alignment: .leading, spacing: 8) {
                Text("Migration Steps")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(Array(migrationManager.getMigrationPath().enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.description)
                                .font(.subheadline)

                            Text("\(step.fromVersion) → \(step.toVersion)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .monospaced()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                showMigrationPrompt = true
            } label: {
                HStack {
                    Spacer()
                    Text("Perform Migration")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
        } header: {
            Text("Status")
        } footer: {
            Text("A backup will be created automatically before migration. You can rollback if needed.")
        }
    }

    // MARK: - Migration In Progress Section

    private var migrationInProgressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ProgressView()
                    Text("Migrating...")
                        .font(.headline)
                }

                if !migrationManager.migrationStatus.isEmpty {
                    Text(migrationManager.migrationStatus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: migrationManager.migrationProgress)
                    .progressViewStyle(.linear)

                Text("\(Int(migrationManager.migrationProgress * 100))% complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Status")
        } footer: {
            Text("Please wait while your data is being migrated. Do not close the app.")
        }
    }

    // MARK: - Migration History Section

    private var migrationHistorySection: some View {
        Section {
            ForEach(migrationManager.migrationHistory.reversed()) { record in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: record.statusIcon)
                            .foregroundStyle(record.success ? Color.green : Color.red)

                        Text("\(record.fromVersion) → \(record.toVersion)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .monospaced()

                        Spacer()
                    }

                    Text(record.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if let error = record.error {
                        Text("Error: \(error)")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Migration History")
        }
    }

    // MARK: - Developer Section

    #if DEBUG
    private var developerSection: some View {
        Section {
            Button(role: .destructive) {
                migrationManager.resetMigrationHistory()
            } label: {
                Label("Reset Migration History", systemImage: "trash")
            }

            Button(role: .destructive) {
                showRollbackConfirmation = true
            } label: {
                Label("Rollback Last Migration", systemImage: "arrow.uturn.backward")
            }
            .disabled(migrationManager.migrationHistory.isEmpty)

            Button {
                // Simulate older version for testing
                let olderVersion = SchemaVersion(major: 0, minor: 9, patch: 0)
                migrationManager.setSchemaVersion(olderVersion)
            } label: {
                Label("Simulate Older Version", systemImage: "clock.arrow.circlepath")
            }
        } header: {
            Text("Developer Options")
        } footer: {
            Text("⚠️ These options are for development only and can cause data loss.")
        }
    }
    #endif

    // MARK: - Actions

    private func performMigration() {
        Task {
            do {
                try await migrationManager.performMigrations(modelContext: modelContext)
            } catch {
                print("❌ Migration error: \(error)")
            }
        }
    }

    private func rollbackMigration() {
        Task {
            do {
                try await migrationManager.rollbackMigration(modelContext: modelContext)
            } catch {
                print("❌ Rollback error: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MigrationStatusView()
        .modelContainer(for: [Song.self])
        .onAppear {
            // Simulate migration history for preview
            let manager = DataMigrationManager.shared

            let record1 = MigrationRecord(
                fromVersion: SchemaVersion(major: 1, minor: 0, patch: 0),
                toVersion: SchemaVersion(major: 1, minor: 1, patch: 0),
                description: "Add performance tracking",
                timestamp: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                success: true
            )

            let record2 = MigrationRecord(
                fromVersion: SchemaVersion(major: 1, minor: 1, patch: 0),
                toVersion: SchemaVersion(major: 1, minor: 2, patch: 0),
                description: "Add conflict resolution",
                timestamp: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                success: true
            )

            manager.migrationHistory = [record1, record2]
        }
}
