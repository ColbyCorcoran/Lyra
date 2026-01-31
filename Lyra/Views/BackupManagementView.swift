//
//  BackupManagementView.swift
//  Lyra
//
//  UI for managing local backups and restoration
//

import SwiftUI

struct BackupManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backupManager = BackupManager.shared

    @State private var showCreateBackup = false
    @State private var showRestoreConfirmation = false
    @State private var selectedBackup: Backup?
    @State private var showError = false
    @State private var errorMessage: String = ""
    @State private var showSuccess = false
    @State private var successMessage: String = ""
    @State private var showImportPicker = false
    @State private var showExportPicker = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                // Status Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Backup")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let lastBackup = backupManager.lastBackupDate {
                                Text(lastBackup, style: .relative)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("ago")
                                    .font(.body)
                                    .fontWeight(.medium)
                            } else {
                                Text("Never")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if backupManager.isCreatingBackup {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(backupManager.lastBackupDate != nil ? .green : .secondary)
                                .font(.title2)
                        }
                    }
                } header: {
                    Text("Backup Status")
                }

                // Auto-Backup Settings
                Section {
                    Toggle("Automatic Backups", isOn: $backupManager.autoBackupEnabled)

                    if backupManager.autoBackupEnabled {
                        Picker("Frequency", selection: $backupManager.backupFrequency) {
                            ForEach(BackupFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }
                    }
                } header: {
                    Text("Auto-Backup")
                } footer: {
                    if backupManager.autoBackupEnabled {
                        Text("Backups are created \(backupManager.backupFrequency.displayName.lowercased()) and kept for up to 5 versions.")
                    } else {
                        Text("Enable automatic backups to protect your data")
                    }
                }

                // Manual Backup
                Section {
                    Button {
                        createBackup()
                    } label: {
                        HStack {
                            Label("Create Backup Now", systemImage: "arrow.down.doc")
                            Spacer()
                            if backupManager.isCreatingBackup {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(backupManager.isCreatingBackup)

                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Manual Actions")
                }

                // Available Backups
                Section {
                    if backupManager.availableBackups.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "archivebox")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tertiary)

                                Text("No Backups")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Text("Create your first backup above")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    } else {
                        ForEach(backupManager.availableBackups) { backup in
                            BackupRow(backup: backup)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteBackup(backup)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        exportBackup(backup)
                                    } label: {
                                        Label("Export", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.blue)

                                    Button {
                                        selectedBackup = backup
                                        showRestoreConfirmation = true
                                    } label: {
                                        Label("Restore", systemImage: "arrow.counterclockwise")
                                    }
                                    .tint(.orange)
                                }
                                .contextMenu {
                                    Button {
                                        selectedBackup = backup
                                        showRestoreConfirmation = true
                                    } label: {
                                        Label("Restore", systemImage: "arrow.counterclockwise")
                                    }

                                    Button {
                                        exportBackup(backup)
                                    } label: {
                                        Label("Export", systemImage: "square.and.arrow.up")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        deleteBackup(backup)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                } header: {
                    HStack {
                        Text("Available Backups")
                        Spacer()
                        Text("\(backupManager.availableBackups.count) of 5")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Swipe left to delete, swipe right to export or restore. Only the 5 most recent backups are kept.")
                }
            }
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Restore Backup?", isPresented: $showRestoreConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore", role: .destructive) {
                    if let backup = selectedBackup {
                        restoreBackup(backup)
                    }
                }
            } message: {
                Text("This will replace all current data with the backup from \(selectedBackup?.createdAt.formatted() ?? "unknown date"). This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(successMessage)
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .fileExporter(
                isPresented: $showExportPicker,
                document: BackupDocument(url: exportURL),
                contentType: .data,
                defaultFilename: exportURL?.lastPathComponent ?? "backup.lyrabackup"
            ) { result in
                handleExport(result)
            }
        }
    }

    // MARK: - Actions

    private func createBackup() {
        Task {
            do {
                try await backupManager.createBackup()
                successMessage = "Backup created successfully"
                showSuccess = true
                HapticManager.shared.success()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.shared.error()
            }
        }
    }

    private func restoreBackup(_ backup: Backup) {
        Task {
            do {
                try await backupManager.restoreBackup(backup)
                successMessage = "Backup restored successfully. Your library has been updated."
                showSuccess = true
                HapticManager.shared.success()
            } catch {
                errorMessage = "Failed to restore backup: \(error.localizedDescription)"
                showError = true
                HapticManager.shared.error()
            }
        }
    }

    private func deleteBackup(_ backup: Backup) {
        do {
            try backupManager.deleteBackup(backup)
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to delete backup: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.error()
        }
    }

    private func exportBackup(_ backup: Backup) {
        exportURL = backupManager.exportBackup(backup)
        showExportPicker = true
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                do {
                    try await backupManager.importBackup(from: url)
                    successMessage = "Backup imported successfully"
                    showSuccess = true
                    HapticManager.shared.success()
                } catch {
                    errorMessage = "Failed to import backup: \(error.localizedDescription)"
                    showError = true
                    HapticManager.shared.error()
                }
            }
        case .failure(let error):
            errorMessage = "Failed to import: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.error()
        }
    }

    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            successMessage = "Backup exported successfully"
            showSuccess = true
            HapticManager.shared.success()
        case .failure(let error):
            errorMessage = "Failed to export: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.error()
        }
    }
}

// MARK: - Backup Row

struct BackupRow: View {
    let backup: Backup

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(backup.displayName)
                .font(.headline)

            HStack {
                Label(
                    backup.createdAt.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Label(
                    backup.formattedSize,
                    systemImage: "externaldrive"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Backup Document

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    let url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url else {
            throw BackupError.backupFileNotFound
        }

        let data = try Data(contentsOf: url)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview {
    BackupManagementView()
}
