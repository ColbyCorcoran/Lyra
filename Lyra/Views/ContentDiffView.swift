//
//  ContentDiffView.swift
//  Lyra
//
//  Visual diff display for comparing song content changes
//

import SwiftUI

struct ContentDiffView: View {
    let localContent: String
    let remoteContent: String
    let baseContent: String?

    @Environment(\.dismiss) private var dismiss

    @State private var diffLines: [DiffLine] = []
    @State private var showOnlyChanges: Bool = false
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats bar
                if !isLoading {
                    statsBar
                }

                Divider()

                // Diff content
                if isLoading {
                    ProgressView("Calculating differences...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    diffScrollView
                }
            }
            .navigationTitle("Content Diff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: $showOnlyChanges) {
                            Label("Show Only Changes", systemImage: "line.3.horizontal.decrease")
                        }

                        Divider()

                        Button {
                            exportDiff()
                        } label: {
                            Label("Export Diff", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await calculateDiff()
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 20) {
            DiffStat(
                icon: "plus.circle.fill",
                color: .green,
                count: addedCount,
                label: "Added"
            )

            DiffStat(
                icon: "minus.circle.fill",
                color: .red,
                count: removedCount,
                label: "Removed"
            )

            DiffStat(
                icon: "pencil.circle.fill",
                color: .yellow,
                count: modifiedCount,
                label: "Modified"
            )

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }

    // MARK: - Diff Content

    private var diffScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(filteredLines) { line in
                    DiffLineView(line: line)
                }
            }
        }
        .background(Color(.systemBackground))
    }

    private var filteredLines: [DiffLine] {
        if showOnlyChanges {
            return diffLines.filter { $0.type != .unchanged }
        }
        return diffLines
    }

    private var addedCount: Int {
        diffLines.filter { $0.type == .added }.count
    }

    private var removedCount: Int {
        diffLines.filter { $0.type == .removed }.count
    }

    private var modifiedCount: Int {
        diffLines.filter { $0.type == .modified }.count
    }

    // MARK: - Actions

    private func calculateDiff() async {
        isLoading = true

        // Perform diff calculation on background thread
        let result = await Task.detached {
            DiffAlgorithm.diff(original: localContent, modified: remoteContent)
        }.value

        await MainActor.run {
            diffLines = result.lines
            isLoading = false
        }
    }

    private func exportDiff() {
        // Create a text representation of the diff
        var diffText = "=== Content Diff ===\n\n"
        diffText += "Added: \(addedCount) lines\n"
        diffText += "Removed: \(removedCount) lines\n"
        diffText += "Modified: \(modifiedCount) lines\n\n"
        diffText += "---\n\n"

        for line in diffLines {
            let prefix: String
            switch line.type {
            case .unchanged: prefix = "  "
            case .added: prefix = "+ "
            case .removed: prefix = "- "
            case .modified: prefix = "~ "
            }
            diffText += "\(prefix)\(line.content)\n"
        }

        // Share the diff
        let activityVC = UIActivityViewController(
            activityItems: [diffText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Diff Line View

struct DiffLineView: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line number
            Text("\(line.lineNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, 12)

            // Type indicator
            typeIndicator
                .frame(width: 20)

            // Content
            Text(line.content.isEmpty ? " " : line.content)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .fill(borderColor)
                .frame(width: 3),
            alignment: .leading
        )
    }

    private var typeIndicator: some View {
        Group {
            switch line.type {
            case .unchanged:
                Text("")
            case .added:
                Image(systemName: "plus")
                    .font(.caption2)
                    .foregroundStyle(.green)
            case .removed:
                Image(systemName: "minus")
                    .font(.caption2)
                    .foregroundStyle(.red)
            case .modified:
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
    }

    private var backgroundColor: Color {
        switch line.type {
        case .unchanged:
            return .clear
        case .added:
            return Color.green.opacity(0.1)
        case .removed:
            return Color.red.opacity(0.1)
        case .modified:
            return Color.yellow.opacity(0.1)
        }
    }

    private var borderColor: Color {
        switch line.type {
        case .unchanged:
            return .clear
        case .added:
            return .green
        case .removed:
            return .red
        case .modified:
            return .yellow
        }
    }
}

// MARK: - Diff Stat

struct DiffStat: View {
    let icon: String
    let color: Color
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Side-by-Side Diff View

struct SideBySideDiffView: View {
    let localContent: String
    let remoteContent: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    // Local version
                    VStack(spacing: 0) {
                        Text("Local Version")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))

                        ScrollView {
                            Text(localContent)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .textSelection(.enabled)
                        }
                    }
                    .frame(width: geometry.size.width / 2)
                    .background(Color(.systemBackground))

                    // Remote version
                    VStack(spacing: 0) {
                        Text("Remote Version")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))

                        ScrollView {
                            Text(remoteContent)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .textSelection(.enabled)
                        }
                    }
                    .frame(width: geometry.size.width / 2)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Side-by-Side Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Content Diff") {
    ContentDiffView(
        localContent: """
        {title: Amazing Grace}
        {artist: John Newton}
        {key: G}

        [Verse 1]
        [G]Amazing [C]grace how [G]sweet the sound
        That [D]saved a wretch like [G]me
        I [G]once was [C]lost but [G]now am found
        Was [D]blind but now I [G]see
        """,
        remoteContent: """
        {title: Amazing Grace}
        {artist: John Newton}
        {key: C}

        [Verse 1]
        [C]Amazing [F]grace how [C]sweet the sound
        That [G]saved a wretch like [C]me
        I [C]once was [F]lost but [C]now am found
        Was [G]blind but now I [C]see

        [Verse 2]
        'Twas grace that taught my heart to fear
        And grace my fears relieved
        """,
        baseContent: nil
    )
}

#Preview("Side by Side") {
    SideBySideDiffView(
        localContent: "Local version content here...",
        remoteContent: "Remote version content here..."
    )
}
