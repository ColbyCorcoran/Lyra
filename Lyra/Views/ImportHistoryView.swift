//
//  ImportHistoryView.swift
//  Lyra
//
//  View for displaying import history and managing import records
//

import SwiftUI
import SwiftData

struct ImportHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ImportRecord.importDate, order: .reverse) private var imports: [ImportRecord]

    @State private var selectedRecord: ImportRecord?
    @State private var showDeleteConfirmation: Bool = false
    @State private var recordToDelete: ImportRecord?

    var body: some View {
        NavigationStack {
            Group {
                if imports.isEmpty {
                    emptyStateView
                } else {
                    importListView
                }
            }
            .navigationTitle("Import History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedRecord) { record in
                ImportRecordDetailView(record: record)
            }
            .alert("Delete Import Record?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let record = recordToDelete {
                        deleteRecord(record)
                    }
                }
            } message: {
                Text("This will delete the import record but keep all imported songs. This action cannot be undone.")
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundStyle(.gray)
                .padding(.top, 80)

            VStack(spacing: 12) {
                Text("No Import History")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Import history will appear here as you add songs to your library")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Import List

    @ViewBuilder
    private var importListView: some View {
        List {
            ForEach(groupedImports.keys.sorted(by: sortSections), id: \.self) { section in
                Section(header: Text(section)) {
                    ForEach(groupedImports[section] ?? []) { record in
                        ImportRecordRow(record: record)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRecord = record
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    recordToDelete = record
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouping Logic

    private var groupedImports: [String: [ImportRecord]] {
        Dictionary(grouping: imports) { $0.dateSection }
    }

    private func sortSections(_ s1: String, _ s2: String) -> Bool {
        let order = ["Today", "Yesterday", "This Week", "This Month"]

        if let i1 = order.firstIndex(of: s1), let i2 = order.firstIndex(of: s2) {
            return i1 < i2
        } else if order.contains(s1) {
            return true
        } else if order.contains(s2) {
            return false
        } else {
            // For month/year sections, reverse chronological
            return s1 > s2
        }
    }

    // MARK: - Actions

    private func deleteRecord(_ record: ImportRecord) {
        // Remove relationship from songs but keep the songs
        record.importedSongs?.forEach { song in
            song.importRecord = nil
        }

        modelContext.delete(record)
        try? modelContext.save()
        HapticManager.shared.success()
    }
}

// MARK: - Import Record Row

struct ImportRecordRow: View {
    let record: ImportRecord

    var body: some View {
        HStack(spacing: 12) {
            // Source icon
            Image(systemName: record.sourceIcon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(record.importSource)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(record.relativeDateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let method = record.importMethod {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(method)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Label("\(record.successCount)", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)

                    if record.failedCount > 0 {
                        Label("\(record.failedCount)", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if record.duplicateCount > 0 {
                        Label("\(record.duplicateCount)", systemImage: "doc.on.doc.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Import Record Detail View

struct ImportRecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: ImportRecord

    @State private var showDeleteConfirmation: Bool = false
    @State private var showCloudSyncOptions: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // Summary Section
                Section("Summary") {
                    HStack {
                        Image(systemName: record.sourceIcon)
                            .foregroundStyle(.blue)
                        Text(record.importSource)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                        Text(record.formattedDate)
                        Spacer()
                    }

                    if let method = record.importMethod {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                                .foregroundStyle(.blue)
                            Text(method)
                            Spacer()
                        }
                    }

                    if let duration = record.importDuration {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.blue)
                            Text(String(format: "%.1f seconds", duration))
                            Spacer()
                        }
                    }
                }

                // Statistics Section
                Section("Statistics") {
                    StatRow(icon: "doc", label: "Total Files", value: "\(record.totalFileCount)")
                    StatRow(icon: "checkmark.circle.fill", label: "Successful", value: "\(record.successCount)", color: .green)

                    if record.failedCount > 0 {
                        StatRow(icon: "xmark.circle.fill", label: "Failed", value: "\(record.failedCount)", color: .red)
                    }

                    if record.duplicateCount > 0 {
                        StatRow(icon: "doc.on.doc.fill", label: "Duplicates", value: "\(record.duplicateCount)", color: .orange)
                    }

                    if record.skippedCount > 0 {
                        StatRow(icon: "forward.fill", label: "Skipped", value: "\(record.skippedCount)", color: .gray)
                    }

                    HStack {
                        Image(systemName: "chart.bar")
                            .foregroundStyle(.blue)
                        Text("Success Rate")
                        Spacer()
                        Text(String(format: "%.0f%%", record.successRate * 100))
                            .foregroundStyle(.secondary)
                    }
                }

                // Imported Songs Section
                if let songs = record.importedSongs, !songs.isEmpty {
                    Section("Imported Songs (\(songs.count))") {
                        ForEach(songs.sorted(by: { $0.title < $1.title })) { song in
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.body)

                                    if let artist = song.artist {
                                        Text(artist)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                        }
                    }
                }

                // File Information
                if let filePaths = record.originalFilePaths, !filePaths.isEmpty {
                    Section("Original Files") {
                        ForEach(filePaths.prefix(10), id: \.self) { path in
                            HStack {
                                Image(systemName: "doc")
                                    .foregroundStyle(.blue)
                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                    .font(.caption)
                                Spacer()
                            }
                        }

                        if filePaths.count > 10 {
                            Text("+ \(filePaths.count - 10) more files")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // File Types
                if let fileTypes = record.fileTypes, !fileTypes.isEmpty {
                    Section("File Types") {
                        HStack {
                            ForEach(Array(Set(fileTypes)).sorted(), id: \.self) { type in
                                Text(".\(type)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }

                // Error Messages
                if let errors = record.errorMessages, !errors.isEmpty {
                    Section("Errors") {
                        ForEach(errors.prefix(5), id: \.self) { error in
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        if errors.count > 5 {
                            Text("+ \(errors.count - 5) more errors")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Cloud Sync (if applicable)
                if let cloudPath = record.cloudFolderPath {
                    Section("Cloud Sync") {
                        HStack {
                            Image(systemName: "folder.badge.gearshape")
                                .foregroundStyle(.blue)
                            Text("Folder Path")
                            Spacer()
                            Text(cloudPath)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Toggle(isOn: .constant(record.cloudSyncEnabled)) {
                            Label("Sync Enabled", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(true)

                        if record.cloudSyncEnabled {
                            Button {
                                showCloudSyncOptions = true
                            } label: {
                                Label("Check for Updates", systemImage: "arrow.clockwise")
                            }
                        }
                    }
                }

                // Actions Section
                Section("Actions") {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Import Record", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Import Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Import Record?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteRecord()
                }
            } message: {
                Text("This will delete the import record but keep all imported songs. This action cannot be undone.")
            }
            .alert("Check for Updates", isPresented: $showCloudSyncOptions) {
                Button("Cancel", role: .cancel) {}
                Button("Check Now") {
                    checkForUpdates()
                }
            } message: {
                Text("This will check if any files have been updated in \(record.importSource) since import.")
            }
        }
    }

    // MARK: - Actions

    private func deleteRecord() {
        // Remove relationship from songs
        record.importedSongs?.forEach { $0.importRecord = nil }

        modelContext.delete(record)
        try? modelContext.save()
        HapticManager.shared.success()
        dismiss()
    }

    private func checkForUpdates() {
        // TODO: Implement cloud sync check
        // This would check Dropbox/Drive for updated files
        HapticManager.shared.warning()
    }
}

// MARK: - Stat Row Component

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .blue

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Import History") {
    ImportHistoryView()
        .modelContainer(PreviewContainer.shared.container)
}
