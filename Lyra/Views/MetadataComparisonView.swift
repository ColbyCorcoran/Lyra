//
//  MetadataComparisonView.swift
//  Lyra
//
//  Field-by-field metadata comparison and selection for conflict resolution
//

import SwiftUI
import SwiftData

struct MetadataComparisonView: View {
    let conflict: SyncConflict

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFields: [String: FieldChoice] = [:]
    @State private var showPreview: Bool = false
    @State private var isApplying: Bool = false
    @State private var previewData: ConflictVersion.ConflictData?

    private let conflictManager = ConflictResolutionManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator

                Divider()

                // Field comparison list
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(conflictingFields, id: \.key) { field in
                            MetadataFieldRow(
                                field: field,
                                selection: Binding(
                                    get: { selectedFields[field.key] ?? .local },
                                    set: { selectedFields[field.key] = $0 }
                                )
                            )
                        }

                        // Preview button
                        if !conflictingFields.isEmpty {
                            Button {
                                generatePreview()
                                showPreview = true
                            } label: {
                                HStack {
                                    Image(systemName: "eye")
                                    Text("Preview Merged Result")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Field-by-Field Resolution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyMerge()
                    }
                    .disabled(isApplying || !hasAllFieldsSelected)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPreview) {
                if let preview = previewData {
                    MergePreviewView(
                        originalLocal: conflict.localVersion.data,
                        originalRemote: conflict.remoteVersion.data,
                        merged: preview,
                        selectedFields: selectedFields
                    )
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(completionPercentage == 1.0 ? .green : .blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Resolution Progress")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ProgressView(value: completionPercentage)
                    .tint(.blue)

                Text("\(selectedCount) of \(conflictingFields.count) fields selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    // MARK: - Computed Properties

    private var conflictingFields: [ConflictingFieldData] {
        var fields: [ConflictingFieldData] = []

        let local = conflict.localVersion.data
        let remote = conflict.remoteVersion.data

        // Title
        if local.title != remote.title {
            fields.append(ConflictingFieldData(
                key: "title",
                displayName: "Title",
                localValue: local.title,
                remoteValue: remote.title,
                baseValue: nil,
                fieldType: .text
            ))
        }

        // Artist
        if local.artist != remote.artist {
            fields.append(ConflictingFieldData(
                key: "artist",
                displayName: "Artist",
                localValue: local.artist,
                remoteValue: remote.artist,
                baseValue: nil,
                fieldType: .text
            ))
        }

        // Key
        if local.key != remote.key {
            fields.append(ConflictingFieldData(
                key: "key",
                displayName: "Musical Key",
                localValue: local.key,
                remoteValue: remote.key,
                baseValue: nil,
                fieldType: .text
            ))
        }

        // Tags
        if local.tags != remote.tags {
            let localTags = local.tags?.joined(separator: ", ") ?? "None"
            let remoteTags = remote.tags?.joined(separator: ", ") ?? "None"

            fields.append(ConflictingFieldData(
                key: "tags",
                displayName: "Tags",
                localValue: localTags,
                remoteValue: remoteTags,
                baseValue: nil,
                fieldType: .array
            ))
        }

        return fields
    }

    private var selectedCount: Int {
        selectedFields.count
    }

    private var completionPercentage: Double {
        guard !conflictingFields.isEmpty else { return 1.0 }
        return Double(selectedCount) / Double(conflictingFields.count)
    }

    private var hasAllFieldsSelected: Bool {
        selectedCount == conflictingFields.count
    }

    // MARK: - Actions

    private func generatePreview() {
        previewData = ConflictMergeEngine.applyFieldChoices(
            local: conflict.localVersion.data,
            remote: conflict.remoteVersion.data,
            choices: selectedFields
        )
    }

    private func applyMerge() {
        guard let merged = previewData else {
            generatePreview()
            guard let merged = previewData else { return }
            self.previewData = merged
        }

        isApplying = true

        Task {
            do {
                // Apply the merged data
                try await CloudKitSyncCoordinator.shared.mergeVersions(
                    conflict,
                    modelContext: modelContext,
                    mergedData: merged
                )

                // Mark conflict as resolved
                try await conflictManager.resolveConflict(
                    conflict,
                    with: .merge,
                    modelContext: modelContext
                )

                await MainActor.run {
                    HapticManager.shared.notification(.success)
                    dismiss()
                }
            } catch {
                print("❌ Error applying merge: \(error)")
                HapticManager.shared.notification(.error)
                isApplying = false
            }
        }
    }
}

// MARK: - Metadata Field Row

struct MetadataFieldRow: View {
    let field: ConflictingFieldData
    @Binding var selection: FieldChoice

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Field header
            HStack {
                Image(systemName: fieldIcon)
                    .foregroundStyle(.blue)

                Text(field.displayName)
                    .font(.headline)

                Spacer()

                if selection != .local && selection != .remote {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            // Version options
            HStack(spacing: 12) {
                // Local option
                VersionOptionButton(
                    title: "Local",
                    icon: "iphone",
                    value: field.localValue ?? "None",
                    color: .blue,
                    isSelected: selection == .local
                ) {
                    selection = .local
                    HapticManager.shared.selection()
                }

                // Remote option
                VersionOptionButton(
                    title: "Remote",
                    icon: "icloud",
                    value: field.remoteValue ?? "None",
                    color: .green,
                    isSelected: selection == .remote
                ) {
                    selection = .remote
                    HapticManager.shared.selection()
                }
            }

            // Custom value option for text fields
            if field.fieldType == .text {
                Button {
                    // Show custom input
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Enter Custom Value")
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var fieldIcon: String {
        switch field.fieldType {
        case .text: return "textformat"
        case .number: return "number"
        case .date: return "calendar"
        case .boolean: return "checkmark.circle"
        case .array: return "list.bullet"
        }
    }
}

// MARK: - Version Option Button

struct VersionOptionButton: View {
    let title: String
    let icon: String
    let value: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(isSelected ? color : .secondary)

                    Text(title)
                        .font(.caption)
                        .foregroundStyle(isSelected ? color : .secondary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(color)
                    }
                }

                Text(value)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(isSelected ? color.opacity(0.1) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color(.separator), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Merge Preview View

struct MergePreviewView: View {
    let originalLocal: ConflictVersion.ConflictData
    let originalRemote: ConflictVersion.ConflictData
    let merged: ConflictVersion.ConflictData
    let selectedFields: [String: FieldChoice]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Merged Result") {
                    if let title = merged.title {
                        PreviewRow(label: "Title", value: title, source: selectedFields["title"])
                    }

                    if let artist = merged.artist {
                        PreviewRow(label: "Artist", value: artist, source: selectedFields["artist"])
                    }

                    if let key = merged.key {
                        PreviewRow(label: "Key", value: key, source: selectedFields["key"])
                    }

                    if let tags = merged.tags {
                        PreviewRow(label: "Tags", value: tags.joined(separator: ", "), source: selectedFields["tags"])
                    }
                }

                Section("Summary") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Text("\(selectedFields.count) fields merged")
                            .font(.subheadline)
                    }

                    let localCount = selectedFields.values.filter { $0 == .local }.count
                    let remoteCount = selectedFields.values.filter { $0 == .remote }.count

                    HStack {
                        Image(systemName: "iphone")
                            .foregroundStyle(.blue)

                        Text("\(localCount) from local")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "icloud")
                            .foregroundStyle(.green)

                        Text("\(remoteCount) from remote")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Merge Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview Row

struct PreviewRow: View {
    let label: String
    let value: String
    let source: FieldChoice?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let source = source {
                    HStack(spacing: 4) {
                        Image(systemName: sourceIcon)
                            .font(.caption2)

                        Text(sourceLabel)
                            .font(.caption2)
                    }
                    .foregroundStyle(sourceColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(sourceColor.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private var sourceIcon: String {
        switch source {
        case .local: return "iphone"
        case .remote: return "icloud"
        case .custom: return "pencil"
        default: return "questionmark"
        }
    }

    private var sourceLabel: String {
        switch source {
        case .local: return "Local"
        case .remote: return "Remote"
        case .custom: return "Custom"
        default: return "Unknown"
        }
    }

    private var sourceColor: Color {
        switch source {
        case .local: return .blue
        case .remote: return .green
        case .custom: return .orange
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    MetadataComparisonView(
        conflict: SyncConflict(
            conflictType: .propertyConflict,
            entityType: .song,
            entityID: UUID(),
            localVersion: ConflictVersion(
                timestamp: Date().addingTimeInterval(-3600),
                deviceName: "iPhone",
                data: ConflictVersion.ConflictData(
                    title: "Amazing Grace",
                    artist: "John Newton",
                    key: "G",
                    tags: ["Hymn", "Traditional"]
                )
            ),
            remoteVersion: ConflictVersion(
                timestamp: Date().addingTimeInterval(-1800),
                deviceName: "iPad",
                data: ConflictVersion.ConflictData(
                    title: "Amazing Grace",
                    artist: "John Newton (1779)",
                    key: "C",
                    tags: ["Hymn", "Classic"]
                )
            ),
            detectedAt: Date()
        )
    )
    .modelContainer(for: [Song.self])
}
