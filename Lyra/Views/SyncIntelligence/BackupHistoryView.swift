//
//  BackupHistoryView.swift
//  Lyra
//
//  Phase 7.12: View for managing backups
//

import SwiftUI
import SwiftData

struct BackupHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IntelligentBackup.createdAt, order: .reverse) private var backups: [IntelligentBackup]
    @State private var syncManager: IntelligentSyncManager?
    @State private var selectedBackup: IntelligentBackup?
    @State private var showingRestoreConfirmation = false

    var body: some View {
        List {
            if backups.isEmpty {
                ContentUnavailableView(
                    "No Backups",
                    systemImage: "externaldrive.badge.xmark",
                    description: Text("Create your first backup to protect your data")
                )
            } else {
                ForEach(backups) { backup in
                    backupRow(backup)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteBackup(backup)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                selectedBackup = backup
                                showingRestoreConfirmation = true
                            } label: {
                                Label("Restore", systemImage: "arrow.counterclockwise")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .navigationTitle("Backups")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    createBackup()
                } label: {
                    Label("Create Backup", systemImage: "plus")
                }
            }
        }
        .confirmationDialog(
            "Restore Backup?",
            isPresented: $showingRestoreConfirmation,
            presenting: selectedBackup
        ) { backup in
            Button("Restore", role: .destructive) {
                restoreBackup(backup)
            }
            Button("Cancel", role: .cancel) {}
        } message: { backup in
            Text("This will restore your data to \(backup.createdAt.formatted()). Current data may be lost.")
        }
        .task {
            syncManager = IntelligentSyncManager(modelContext: modelContext)
        }
    }

    // MARK: - Backup Row

    private func backupRow(_ backup: IntelligentBackup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    BackupType(rawValue: backup.backupType)?.rawValue ?? "Unknown",
                    systemImage: iconForBackupType(backup.backupType)
                )
                .font(.headline)

                Spacer()

                importanceBadge(backup.importance)
            }

            HStack {
                Text(backup.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formatSize(backup.dataSize))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let trigger = BackupTrigger(rawValue: backup.trigger) {
                Text(trigger.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }

            HStack {
                Text("\(backup.recordCount) records")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if backup.isCompressed {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func importanceBadge(_ importance: BackupImportance) -> some View {
        Text(importance.rawValue)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForImportance(importance))
            .foregroundStyle(.white)
            .cornerRadius(8)
    }

    private func iconForBackupType(_ type: String) -> String {
        switch BackupType(rawValue: type) {
        case .full:
            return "externaldrive.fill"
        case .incremental:
            return "externaldrive.badge.plus"
        case .snapshot:
            return "camera.circle"
        case .none:
            return "externaldrive"
        }
    }

    private func colorForImportance(_ importance: BackupImportance) -> Color {
        switch importance {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .blue
        case .low:
            return .gray
        }
    }

    // MARK: - Actions

    private func createBackup() {
        Task {
            guard let manager = syncManager else { return }
            _ = await manager.createManualBackup()
        }
    }

    private func restoreBackup(_ backup: IntelligentBackup) {
        Task {
            guard let manager = syncManager else { return }
            let result = await manager.restoreBackup(backupID: backup.id)

            if result.success {
                print("✅ Restored \(result.restoredRecords) records")
            } else {
                print("❌ Restore failed: \(result.error ?? "Unknown error")")
            }
        }
    }

    private func deleteBackup(_ backup: IntelligentBackup) {
        modelContext.delete(backup)
    }

    // MARK: - Helpers

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    NavigationStack {
        BackupHistoryView()
            .modelContainer(for: IntelligentBackup.self)
    }
}
