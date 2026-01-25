//
//  ConflictDetailView.swift
//  Lyra
//
//  Detailed view of a sync conflict with side-by-side comparison
//

import SwiftUI
import SwiftData

struct ConflictDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let conflict: SyncConflict

    @State private var conflictManager = ConflictResolutionManager.shared
    @State private var selectedResolution: SyncConflict.ConflictResolution?
    @State private var showConfirmation: Bool = false
    @State private var isResolving: Bool = false
    @State private var showContentDiff: Bool = false
    @State private var showMetadataComparison: Bool = false
    @State private var showSideBySide: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Conflict header
                    conflictHeader

                    // Version comparison
                    versionComparison

                    // Resolution options
                    resolutionOptions

                    // Additional info
                    additionalInfo
                }
                .padding()
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Resolve") {
                        showConfirmation = true
                    }
                    .disabled(selectedResolution == nil || isResolving)
                    .fontWeight(.semibold)
                }
            }
            .alert("Confirm Resolution", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm", role: .destructive) {
                    resolveConflict()
                }
            } message: {
                if let resolution = selectedResolution {
                    Text(confirmationMessage(for: resolution))
                }
            }
            .sheet(isPresented: $showContentDiff) {
                if let localContent = conflict.localVersion.data.content,
                   let remoteContent = conflict.remoteVersion.data.content {
                    ContentDiffView(
                        localContent: localContent,
                        remoteContent: remoteContent,
                        baseContent: nil
                    )
                }
            }
            .sheet(isPresented: $showMetadataComparison) {
                MetadataComparisonView(conflict: conflict)
            }
            .sheet(isPresented: $showSideBySide) {
                if let localContent = conflict.localVersion.data.content,
                   let remoteContent = conflict.remoteVersion.data.content {
                    SideBySideDiffView(
                        localContent: localContent,
                        remoteContent: remoteContent
                    )
                }
            }
        }
    }

    // MARK: - Conflict Header

    private var conflictHeader: some View {
        VStack(spacing: 12) {
            // Priority badge
            HStack {
                Image(systemName: priorityIcon)
                    .foregroundStyle(priorityColor)

                Text("\(conflict.priority.rawValue.capitalized) Priority")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(priorityColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(priorityColor.opacity(0.2))
            .clipShape(Capsule())

            // Entity info
            VStack(spacing: 4) {
                Text(entityIcon)
                    .font(.system(size: 40))

                Text(conflict.entityType.rawValue.capitalized)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // Conflict type
            Text(conflict.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Version Comparison

    private var versionComparison: some View {
        VStack(spacing: 16) {
            Text("Compare Versions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 16) {
                // Local version
                VersionCard(
                    title: "Local Version",
                    version: conflict.localVersion,
                    icon: "iphone",
                    color: .blue,
                    isSelected: selectedResolution == .keepLocal
                ) {
                    selectedResolution = .keepLocal
                }

                // Remote version
                VersionCard(
                    title: "Remote Version",
                    version: conflict.remoteVersion,
                    icon: "icloud",
                    color: .green,
                    isSelected: selectedResolution == .keepRemote
                ) {
                    selectedResolution = .keepRemote
                }
            }
        }
    }

    // MARK: - Resolution Options

    private var resolutionOptions: some View {
        VStack(spacing: 16) {
            Text("Resolution Options")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Analysis tools
            VStack(spacing: 12) {
                Text("Analysis Tools")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if conflict.conflictType == .contentModification {
                    Button {
                        showContentDiff = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundStyle(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("View Content Diff")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Line-by-line comparison")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showSideBySide = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.split.2x1")
                                .foregroundStyle(.purple)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Side-by-Side View")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Compare versions side-by-side")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                if conflict.conflictType == .propertyConflict {
                    Button {
                        showMetadataComparison = true
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(.orange)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Field-by-Field Selection")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Choose values for each field")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Keep both option
            if conflict.conflictType != .deletion {
                ResolutionOptionCard(
                    title: "Keep Both Versions",
                    description: "Create separate copies of both versions",
                    icon: "doc.on.doc",
                    color: .purple,
                    isSelected: selectedResolution == .keepBoth
                ) {
                    selectedResolution = .keepBoth
                }
            }

            // Merge option (for compatible conflicts)
            if canMerge {
                ResolutionOptionCard(
                    title: "Merge Versions",
                    description: "Combine non-conflicting changes from both",
                    icon: "arrow.triangle.merge",
                    color: .orange,
                    isSelected: selectedResolution == .merge
                ) {
                    selectedResolution = .merge
                }
            }

            // Skip option
            ResolutionOptionCard(
                title: "Skip for Now",
                description: "Decide later, won't sync until resolved",
                icon: "clock",
                color: .gray,
                isSelected: selectedResolution == .skipForNow
            ) {
                selectedResolution = .skipForNow
            }
        }
    }

    // MARK: - Additional Info

    private var additionalInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Detected", value: conflict.detectedAt.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "Conflict Type", value: conflict.conflictType.rawValue.capitalized)

                if conflict.requiresUserInput {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Manual resolution required")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Computed Properties

    private var priorityColor: Color {
        switch conflict.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }

    private var priorityIcon: String {
        switch conflict.priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        }
    }

    private var entityIcon: String {
        switch conflict.entityType {
        case .song: return "🎵"
        case .book: return "📚"
        case .performanceSet: return "🎭"
        case .annotation: return "✏️"
        case .attachment: return "📎"
        }
    }

    private var canMerge: Bool {
        // Can only merge if both versions exist and have non-overlapping changes
        conflict.conflictType == .propertyConflict &&
        !conflict.localVersion.data.isDeleted &&
        !conflict.remoteVersion.data.isDeleted
    }

    // MARK: - Actions

    private func resolveConflict() {
        guard let resolution = selectedResolution else { return }

        isResolving = true

        Task {
            do {
                try await conflictManager.resolveConflict(conflict, with: resolution, modelContext: modelContext)

                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("❌ Error resolving conflict: \(error)")
                HapticManager.shared.notification(.error)
                isResolving = false
            }
        }
    }

    private func confirmationMessage(for resolution: SyncConflict.ConflictResolution) -> String {
        switch resolution {
        case .keepLocal:
            return "This will keep your local version and discard the remote changes."
        case .keepRemote:
            return "This will keep the remote version and discard your local changes."
        case .keepBoth:
            return "This will create separate copies of both versions."
        case .merge:
            return "This will merge non-conflicting changes from both versions."
        case .skipForNow:
            return "This conflict will remain unresolved. Data won't sync until you resolve it."
        }
    }
}

// MARK: - Version Card

struct VersionCard: View {
    let title: String
    let version: ConflictVersion
    let icon: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(color)
                    }
                }

                Divider()

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    if let title = version.data.title {
                        Text(title)
                            .font(.headline)
                            .lineLimit(2)
                    }

                    if let artist = version.data.artist {
                        Text(artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if version.data.isDeleted {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.caption2)
                            Text("Deleted")
                                .font(.caption)
                        }
                        .foregroundStyle(.red)
                    }

                    Spacer()

                    // Timestamp
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(version.timestamp.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)

                    Text(version.deviceName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Resolution Option Card

struct ResolutionOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(color)
                }
            }
            .padding()
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    ConflictDetailView(
        conflict: SyncConflict(
            conflictType: .contentModification,
            entityType: .song,
            entityID: UUID(),
            localVersion: ConflictVersion(
                timestamp: Date().addingTimeInterval(-3600),
                deviceName: "iPhone 15 Pro",
                data: ConflictVersion.ConflictData(
                    title: "Amazing Grace",
                    artist: "John Newton",
                    content: "Local chord chart content...",
                    key: "G"
                )
            ),
            remoteVersion: ConflictVersion(
                timestamp: Date().addingTimeInterval(-1800),
                deviceName: "iPad Air",
                data: ConflictVersion.ConflictData(
                    title: "Amazing Grace",
                    artist: "John Newton",
                    content: "Remote chord chart content...",
                    key: "C"
                )
            ),
            detectedAt: Date()
        )
    )
    .modelContainer(for: [Song.self])
}
