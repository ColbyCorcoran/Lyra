//
//  VersionHistoryView.swift
//  Lyra
//
//  Displays version history timeline for a song with preview and comparison options
//

import SwiftUI
import SwiftData

struct VersionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song

    @State private var versions: [SongVersion] = []
    @State private var selectedVersion: SongVersion?
    @State private var showComparison = false
    @State private var compareVersion1: SongVersion?
    @State private var compareVersion2: SongVersion?
    @State private var showRestoreSheet = false
    @State private var versionToRestore: SongVersion?
    @State private var showManualSaveSheet = false
    @State private var storageStats: VersionStorageStats?
    @State private var selectionMode = false

    private let versionManager = VersionManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Storage stats header
                if let stats = storageStats {
                    storageStatsHeader(stats)
                }

                // Version timeline
                if versions.isEmpty {
                    emptyState
                } else {
                    versionList
                }
            }
            .navigationTitle("Version History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showManualSaveSheet = true
                        } label: {
                            Label("Save Version", systemImage: "plus.circle")
                        }

                        Button {
                            selectionMode.toggle()
                            if !selectionMode {
                                compareVersion1 = nil
                                compareVersion2 = nil
                            }
                        } label: {
                            Label(selectionMode ? "Cancel Selection" : "Compare Versions", systemImage: "arrow.left.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedVersion) { version in
                VersionPreviewView(
                    version: version,
                    allVersions: versions,
                    onRestore: {
                        versionToRestore = version
                        selectedVersion = nil
                        showRestoreSheet = true
                    }
                )
            }
            .sheet(isPresented: $showComparison) {
                if let v1 = compareVersion1, let v2 = compareVersion2 {
                    VersionComparisonView(
                        version1: v1,
                        version2: v2,
                        allVersions: versions
                    )
                }
            }
            .sheet(isPresented: $showRestoreSheet) {
                if let version = versionToRestore {
                    VersionRestoreView(
                        version: version,
                        song: song,
                        allVersions: versions,
                        onRestore: { createCopy in
                            do {
                                _ = try versionManager.restoreVersion(
                                    version,
                                    to: song,
                                    modelContext: modelContext,
                                    createCopy: createCopy,
                                    allVersions: versions
                                )
                                HapticManager.shared.success()
                                loadVersions()
                                showRestoreSheet = false
                                if !createCopy {
                                    dismiss()
                                }
                            } catch {
                                print("⚠️ Failed to restore version: \(error)")
                                HapticManager.shared.operationFailed()
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showManualSaveSheet) {
                ManualVersionSaveView(song: song) {
                    loadVersions()
                }
            }
            .task {
                loadVersions()
            }
            .onChange(of: compareVersion1) { _, _ in checkComparison() }
            .onChange(of: compareVersion2) { _, _ in checkComparison() }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func storageStatsHeader(_ stats: VersionStorageStats) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(stats.versionCount) Versions")
                        .font(.headline)
                    Text("\(stats.formattedStorageSize) stored")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if stats.deltaVersionCount > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(String(format: "%.1f", stats.compressionRatio))% saved")
                            .font(.headline)
                            .foregroundStyle(.green)
                        Text("\(stats.deltaVersionCount) compressed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Version History")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Versions are created automatically when you edit this song. You can also save versions manually.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showManualSaveSheet = true
            } label: {
                Label("Save Current Version", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var versionList: some View {
        List {
            ForEach(versions) { version in
                VersionRow(
                    version: version,
                    isLatest: version.id == versions.first?.id,
                    isSelected: selectionMode && (version.id == compareVersion1?.id || version.id == compareVersion2?.id),
                    selectionNumber: getSelectionNumber(for: version)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    handleVersionTap(version)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if version.versionType != .import {
                        Button(role: .destructive) {
                            deleteVersion(version)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    Button {
                        versionToRestore = version
                        showRestoreSheet = true
                    } label: {
                        Label("Restore", systemImage: "arrow.counterclockwise")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func loadVersions() {
        versions = versionManager.fetchVersions(for: song, context: modelContext)
        storageStats = versionManager.getStorageStats(for: song, context: modelContext)
    }

    private func handleVersionTap(_ version: SongVersion) {
        if selectionMode {
            selectVersionForComparison(version)
        } else {
            selectedVersion = version
        }
    }

    private func selectVersionForComparison(_ version: SongVersion) {
        if compareVersion1 == nil {
            compareVersion1 = version
        } else if compareVersion2 == nil && version.id != compareVersion1?.id {
            compareVersion2 = version
        } else if version.id == compareVersion1?.id {
            compareVersion1 = nil
        } else if version.id == compareVersion2?.id {
            compareVersion2 = nil
        }
    }

    private func checkComparison() {
        if let v1 = compareVersion1, let v2 = compareVersion2 {
            showComparison = true
            selectionMode = false
            compareVersion1 = nil
            compareVersion2 = nil
        }
    }

    private func getSelectionNumber(for version: SongVersion) -> Int? {
        if version.id == compareVersion1?.id {
            return 1
        } else if version.id == compareVersion2?.id {
            return 2
        }
        return nil
    }

    private func deleteVersion(_ version: SongVersion) {
        do {
            try versionManager.deleteVersion(version, modelContext: modelContext)
            loadVersions()
            HapticManager.shared.success()
        } catch {
            print("⚠️ Failed to delete version: \(error)")
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Version Row

struct VersionRow: View {
    let version: SongVersion
    let isLatest: Bool
    let isSelected: Bool
    let selectionNumber: Int?

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator or version icon
            if let number = selectionNumber {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)

                    Text("\(number)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            } else {
                Image(systemName: versionIcon)
                    .font(.title3)
                    .foregroundStyle(versionColor)
                    .frame(width: 32)
            }

            // Version info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Version \(version.versionNumber)")
                        .font(.headline)

                    if isLatest {
                        Text("Current")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .cornerRadius(4)
                    }

                    if version.isDelta {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Text(version.changeSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label(version.changedBy, systemImage: "person.fill")
                    Label(version.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }

            Spacer()

            if isSelected && selectionNumber == nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
    }

    private var versionIcon: String {
        switch version.versionType {
        case .manual:
            return "bookmark.fill"
        case .autoSave:
            return "arrow.clockwise"
        case .restore:
            return "arrow.counterclockwise"
        case .import:
            return "arrow.down.doc.fill"
        }
    }

    private var versionColor: Color {
        switch version.versionType {
        case .manual:
            return .orange
        case .autoSave:
            return .blue
        case .restore:
            return .purple
        case .import:
            return .green
        }
    }
}

// MARK: - Version Preview

struct VersionPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let version: SongVersion
    let allVersions: [SongVersion]
    let onRestore: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Metadata
                    metadataSection

                    Divider()

                    // Content preview
                    contentSection
                }
                .padding()
            }
            .navigationTitle("Version \(version.versionNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onRestore()
                    } label: {
                        Label("Restore", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            InfoRow(label: "Title", value: version.snapshotTitle)
            if let artist = version.snapshotArtist {
                InfoRow(label: "Artist", value: artist)
            }
            if let key = version.snapshotOriginalKey {
                InfoRow(label: "Key", value: key)
            }
            if let tempo = version.snapshotTempo {
                InfoRow(label: "Tempo", value: "\(tempo) BPM")
            }

            Divider()

            InfoRow(label: "Changed By", value: version.changedBy)
            InfoRow(label: "Date", value: version.createdAt.formatted(date: .long, time: .shortened))
            if let description = version.changeDescription {
                InfoRow(label: "Description", value: description)
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.headline)

            Text(version.reconstructContent(allVersions: allVersions))
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Manual Version Save Sheet

struct ManualVersionSaveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let onSave: () -> Void

    @State private var description = ""
    @State private var isSaving = false

    private let versionManager = VersionManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Version Description")
                } footer: {
                    Text("Add a description to help identify this version later")
                }
            }
            .navigationTitle("Save Version")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVersion()
                    }
                    .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveVersion() {
        isSaving = true
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try versionManager.createManualVersion(
                for: song,
                modelContext: modelContext,
                description: trimmedDescription
            )
            HapticManager.shared.success()
            onSave()
            dismiss()
        } catch {
            print("⚠️ Failed to save version: \(error)")
            HapticManager.shared.operationFailed()
            isSaving = false
        }
    }
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace", artist: "John Newton")
    return VersionHistoryView(song: song)
        .modelContainer(PreviewContainer.shared.container)
}
