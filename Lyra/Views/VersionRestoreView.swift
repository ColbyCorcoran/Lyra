//
//  VersionRestoreView.swift
//  Lyra
//
//  Confirmation dialog for restoring a song version with options
//

import SwiftUI

struct VersionRestoreView: View {
    @Environment(\.dismiss) private var dismiss

    let version: SongVersion
    let song: Song
    let allVersions: [SongVersion]
    let onRestore: (Bool) -> Void

    @State private var restoreMode: RestoreMode = .inPlace
    @State private var showingPreview = false

    enum RestoreMode: String, CaseIterable {
        case inPlace = "Replace Current"
        case createCopy = "Create Copy"

        var description: String {
            switch self {
            case .inPlace:
                return "Replace the current song with this version. The current state will be saved as a new version."
            case .createCopy:
                return "Create a new song with this version's content. The current song will remain unchanged."
            }
        }

        var icon: String {
            switch self {
            case .inPlace:
                return "arrow.counterclockwise.circle.fill"
            case .createCopy:
                return "doc.on.doc.fill"
            }
        }

        var color: Color {
            switch self {
            case .inPlace:
                return .orange
            case .createCopy:
                return .blue
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Warning banner
                warningBanner

                // Restore mode selection
                Form {
                    Section {
                        ForEach(RestoreMode.allCases, id: \.self) { mode in
                            Button {
                                restoreMode = mode
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: mode.icon)
                                        .font(.title2)
                                        .foregroundStyle(mode.color)
                                        .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mode.rawValue)
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text(mode.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()

                                    if restoreMode == mode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Restore Mode")
                    }

                    // Version details
                    Section {
                        versionDetails
                    } header: {
                        Text("Version Details")
                    }

                    // Preview
                    Section {
                        Button {
                            showingPreview = true
                        } label: {
                            Label("Preview Content", systemImage: "eye")
                        }
                    }
                }

                // Action buttons
                actionButtons
            }
            .navigationTitle("Restore Version")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                versionPreviewSheet
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var warningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Restore Version \(version.versionNumber)")
                    .font(.headline)

                Text("This will restore the song to its state from \(version.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
    }

    @ViewBuilder
    private var versionDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(label: "Version", value: "#\(version.versionNumber)")
            DetailRow(label: "Date", value: version.createdAt.formatted(date: .long, time: .shortened))
            DetailRow(label: "Changed By", value: version.changedBy)

            if let description = version.changeDescription {
                DetailRow(label: "Description", value: description)
            }

            Divider()

            DetailRow(label: "Title", value: version.snapshotTitle)
            if let artist = version.snapshotArtist {
                DetailRow(label: "Artist", value: artist)
            }
            if let key = version.snapshotOriginalKey {
                DetailRow(label: "Key", value: key)
            }
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                performRestore()
            } label: {
                HStack {
                    Image(systemName: restoreMode.icon)
                    Text(restoreMode == .inPlace ? "Restore Version" : "Create Copy")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(restoreMode.color)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }

            if restoreMode == .inPlace {
                Text("The current version will be automatically saved before restoring")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var versionPreviewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Content Preview")
                        .font(.headline)

                    Text(version.reconstructContent(allVersions: allVersions))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Version \(version.versionNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingPreview = false
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func performRestore() {
        HapticManager.shared.mediumImpact()
        onRestore(restoreMode == .createCopy)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace", artist: "John Newton")
    let version = SongVersion(
        song: song,
        versionNumber: 5,
        changedBy: "John Doe",
        changeDescription: "Updated chorus chords"
    )

    return VersionRestoreView(
        version: version,
        song: song,
        allVersions: [version]
    ) { createCopy in
        print("Restore with createCopy: \(createCopy)")
    }
}
