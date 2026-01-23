//
//  VersionComparisonView.swift
//  Lyra
//
//  Side-by-side comparison view for two song versions with diff highlighting
//

import SwiftUI
import SwiftData

struct VersionComparisonView: View {
    @Environment(\.dismiss) private var dismiss

    let version1: SongVersion
    let version2: SongVersion
    let allVersions: [SongVersion]

    @State private var diffResult: DiffResult?
    @State private var metadataChanges: [MetadataChange] = []
    @State private var selectedTab: ComparisonTab = .content

    private let versionManager = VersionManager.shared

    enum ComparisonTab: String, CaseIterable {
        case content = "Content"
        case metadata = "Metadata"
        case sideBySide = "Side by Side"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Version headers
                versionHeaders

                // Tab picker
                Picker("View Mode", selection: $selectedTab) {
                    ForEach(ComparisonTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .content:
                        unifiedDiffView
                    case .metadata:
                        metadataChangesView
                    case .sideBySide:
                        sideBySideView
                    }
                }
            }
            .navigationTitle("Compare Versions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                loadComparison()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var versionHeaders: some View {
        HStack(spacing: 0) {
            // Version 1
            VStack(spacing: 4) {
                Text("Version \(version1.versionNumber)")
                    .font(.headline)
                Text(version1.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))

            Divider()

            // Version 2
            VStack(spacing: 4) {
                Text("Version \(version2.versionNumber)")
                    .font(.headline)
                Text(version2.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
        }
        .frame(height: 60)
    }

    @ViewBuilder
    private var unifiedDiffView: some View {
        ScrollView {
            if let diff = diffResult {
                VStack(alignment: .leading, spacing: 0) {
                    // Summary
                    diffSummary(diff)

                    Divider()
                        .padding(.vertical, 8)

                    // Diff lines
                    ForEach(diff.lines) { line in
                        DiffLineView(line: line)
                    }
                }
                .padding()
            } else {
                ProgressView("Calculating differences...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var sideBySideView: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 0) {
                    // Version 1 content
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(version1.reconstructContent(allVersions: allVersions).components(separatedBy: .newlines).enumerated().map { LineItem(number: $0.offset + 1, content: $0.element) }) { line in
                            Text(line.content.isEmpty ? " " : line.content)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(lineBackground(for: line.number, version: 1))
                        }
                    }
                    .frame(width: geometry.size.width / 2)

                    Divider()

                    // Version 2 content
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(version2.reconstructContent(allVersions: allVersions).components(separatedBy: .newlines).enumerated().map { LineItem(number: $0.offset + 1, content: $0.element) }) { line in
                            Text(line.content.isEmpty ? " " : line.content)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(lineBackground(for: line.number, version: 2))
                        }
                    }
                    .frame(width: geometry.size.width / 2)
                }
            }
        }
    }

    @ViewBuilder
    private var metadataChangesView: some View {
        if metadataChanges.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("No Metadata Changes")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("The metadata (title, artist, key, tempo, etc.) is identical between these versions.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(metadataChanges) { change in
                    MetadataChangeRow(change: change)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private func diffSummary(_ diff: DiffResult) -> some View {
        HStack(spacing: 24) {
            if diff.addedCount > 0 {
                Label("\(diff.addedCount) added", systemImage: "plus.circle.fill")
                    .foregroundStyle(.green)
            }

            if diff.removedCount > 0 {
                Label("\(diff.removedCount) removed", systemImage: "minus.circle.fill")
                    .foregroundStyle(.red)
            }

            if diff.modifiedCount > 0 {
                Label("\(diff.modifiedCount) modified", systemImage: "pencil.circle.fill")
                    .foregroundStyle(.orange)
            }

            if !diff.hasChanges {
                Label("No changes", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .font(.subheadline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private func loadComparison() {
        diffResult = versionManager.compareVersions(
            version1: version1,
            version2: version2,
            allVersions: allVersions
        )
        metadataChanges = versionManager.compareMetadata(
            version1: version1,
            version2: version2
        )
    }

    private func lineBackground(for lineNumber: Int, version: Int) -> Color {
        guard let diff = diffResult else { return .clear }

        // Find corresponding diff line
        let diffLine = diff.lines.first { $0.lineNumber == lineNumber }

        guard let line = diffLine else { return .clear }

        switch line.type {
        case .added:
            return version == 2 ? Color.green.opacity(0.2) : .clear
        case .removed:
            return version == 1 ? Color.red.opacity(0.2) : .clear
        case .modified:
            return Color.orange.opacity(0.2)
        case .unchanged:
            return .clear
        }
    }
}

// MARK: - Diff Line View

struct DiffLineView: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Line indicator
            Image(systemName: lineIcon)
                .font(.caption)
                .foregroundStyle(lineColor)
                .frame(width: 20)

            // Line content
            Text(line.content.isEmpty ? " " : line.content)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(lineBackground)
    }

    private var lineIcon: String {
        switch line.type {
        case .unchanged:
            return "minus"
        case .added:
            return "plus"
        case .removed:
            return "minus"
        case .modified:
            return "pencil"
        }
    }

    private var lineColor: Color {
        switch line.type {
        case .unchanged:
            return .secondary
        case .added:
            return .green
        case .removed:
            return .red
        case .modified:
            return .orange
        }
    }

    private var lineBackground: Color {
        switch line.type {
        case .unchanged:
            return .clear
        case .added:
            return Color.green.opacity(0.1)
        case .removed:
            return Color.red.opacity(0.1)
        case .modified:
            return Color.orange.opacity(0.1)
        }
    }
}

// MARK: - Metadata Change Row

struct MetadataChangeRow: View {
    let change: MetadataChange

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(change.field)
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Before")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(change.oldValue.isEmpty ? "(empty)" : change.oldValue)
                        .font(.subheadline)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("After")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(change.newValue.isEmpty ? "(empty)" : change.newValue)
                        .font(.subheadline)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

struct LineItem: Identifiable {
    let id = UUID()
    let number: Int
    let content: String
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace", artist: "John Newton")
    let version1 = SongVersion(song: song, versionNumber: 1, changedBy: "John")
    let version2 = SongVersion(song: song, versionNumber: 2, changedBy: "Jane")

    return VersionComparisonView(
        version1: version1,
        version2: version2,
        allVersions: [version1, version2]
    )
}
