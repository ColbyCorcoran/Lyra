//
//  SyncSettingsView.swift
//  Lyra
//
//  Settings for iCloud sync, backups, and offline mode
//

import SwiftUI
import SwiftData

struct SyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var cloudSync = CloudSyncManager.shared
    @State private var offline = OfflineManager.shared
    @State private var backup = BackupManager.shared

    @State private var showBackupPicker: Bool = false
    @State private var showRestorePicker: Bool = false
    @State private var showBackupSuccess: Bool = false
    @State private var showRestoreConfirmation: Bool = false
    @State private var backupURL: URL?

    var body: some View {
        NavigationView {
            List {
                // Network Status
                networkStatusSection

                // iCloud Sync
                iCloudSyncSection

                // Local Backup
                localBackupSection

                // Offline Mode
                offlineModeSection
            }
            .navigationTitle("Sync & Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBackupPicker) {
                if let url = backupURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Backup Created", isPresented: $showBackupSuccess) {
                Button("Share") {
                    showBackupPicker = true
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your backup has been created successfully")
            }
            .alert("Restore Backup?", isPresented: $showRestoreConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Restore", role: .destructive) {
                    // Handle restore
                }
            } message: {
                Text("This will replace all current data with the backup. This cannot be undone.")
            }
        }
    }

    // MARK: - Network Status Section

    private var networkStatusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: offline.networkIcon)
                    .font(.title2)
                    .foregroundStyle(offline.isOnline ? .green : .orange)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(offline.isOnline ? "Connected" : "Offline")
                        .font(.headline)

                    Text(offline.networkStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        } header: {
            Text("Network Status")
        }
    }

    // MARK: - iCloud Sync Section

    private var iCloudSyncSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { cloudSync.isSyncEnabled },
                set: { cloudSync.toggleSync($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Sync")
                        .font(.headline)

                    Text("Sync your library across devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if cloudSync.isSyncEnabled {
                // Sync Scope
                Picker("Sync Scope", selection: $cloudSync.syncScope) {
                    ForEach(CloudSyncManager.SyncScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .onChange(of: cloudSync.syncScope) { _, _ in
                    cloudSync.saveSettings()
                }

                // Allow Cellular
                Toggle("Sync Over Cellular", isOn: $cloudSync.allowCellularSync)
                    .onChange(of: cloudSync.allowCellularSync) { _, _ in
                        cloudSync.saveSettings()
                    }

                // Sync Status
                HStack {
                    Image(systemName: cloudSync.syncIcon)
                        .foregroundStyle(cloudSync.syncStatusColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(cloudSync.syncStatusMessage)
                            .font(.caption)
                    }

                    Spacer()

                    if cloudSync.syncStatus != .syncing {
                        Button("Sync Now") {
                            cloudSync.forceSyncNow()
                        }
                        .font(.caption)
                    } else {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        } header: {
            Text("iCloud Sync")
        } footer: {
            if cloudSync.isSyncEnabled {
                Text("Your data is automatically synced across all devices signed in with the same Apple ID.")
            } else {
                Text("Enable iCloud sync to keep your library in sync across devices.")
            }
        }
    }

    // MARK: - Local Backup Section

    private var localBackupSection: some View {
        Section {
            // Auto Backup Toggle
            Toggle(isOn: $backup.autoBackupEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto Backup")
                        .font(.headline)

                    Text("Automatically backup your library")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: backup.autoBackupEnabled) { _, _ in
                backup.saveSettings()
            }

            if backup.autoBackupEnabled {
                // Backup Frequency
                Picker("Frequency", selection: $backup.backupFrequency) {
                    ForEach(BackupManager.BackupFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .onChange(of: backup.backupFrequency) { _, _ in
                    backup.saveSettings()
                }
            }

            // Backup Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.blue)

                    Text(backup.backupStatusMessage)
                        .font(.subheadline)

                    Spacer()
                }

                if backup.autoBackupEnabled {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.green)

                        Text(backup.nextBackupMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)

            // Manual Backup Button
            Button {
                createManualBackup()
            } label: {
                HStack {
                    Spacer()
                    if backup.isBackingUp {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Text(backup.isBackingUp ? "Creating Backup..." : "Create Backup Now")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(backup.isBackingUp)

            // Export to Files
            Button {
                exportToFiles()
            } label: {
                Label("Export to Files", systemImage: "folder")
            }

            // Restore from Backup
            Button {
                showRestoreConfirmation = true
            } label: {
                Label("Restore from Backup", systemImage: "arrow.clockwise")
            }
            .foregroundStyle(.red)
        } header: {
            Text("Local Backup")
        } footer: {
            Text("Backups are stored locally on your device and are not synced to iCloud. Export backups to Files app for safekeeping.")
        }
    }

    // MARK: - Offline Mode Section

    private var offlineModeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text("All features work offline")
                        .font(.subheadline)
                }

                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.blue)

                    Text("Changes sync when back online")
                        .font(.subheadline)
                }

                if !offline.queuedOperations.isEmpty {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.orange)

                        Text("\(offline.queuedOperations.count) operation(s) queued")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Offline Mode")
        } footer: {
            Text("Lyra is designed to work perfectly offline. All features are available without internet connection.")
        }
    }

    // MARK: - Actions

    private func createManualBackup() {
        Task {
            do {
                let url = try await backup.createBackup(modelContext: modelContext)
                await MainActor.run {
                    backupURL = url
                    showBackupSuccess = true
                }
            } catch {
                print("❌ Backup error: \(error)")
            }
        }
    }

    private func exportToFiles() {
        Task {
            do {
                let url = try await backup.exportToFiles()
                await MainActor.run {
                    backupURL = url
                    showBackupPicker = true
                }
            } catch {
                print("❌ Export error: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SyncSettingsView()
        .modelContainer(for: [Song.self])
}
