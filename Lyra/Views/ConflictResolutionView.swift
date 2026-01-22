//
//  ConflictResolutionView.swift
//  Lyra
//
//  UI for managing and resolving sync conflicts
//

import SwiftUI
import SwiftData

struct ConflictResolutionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var conflictManager = ConflictResolutionManager.shared
    @State private var selectedConflict: SyncConflict?
    @State private var showSettings: Bool = false
    @State private var showResolvedHistory: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if conflictManager.unresolvedConflicts.isEmpty {
                    emptyState
                } else {
                    conflictsList
                }
            }
            .navigationTitle("Sync Conflicts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showSettings = true
                        } label: {
                            Label("Auto-Resolve Settings", systemImage: "gearshape")
                        }

                        Button {
                            showResolvedHistory = true
                        } label: {
                            Label("View History", systemImage: "clock")
                        }

                        Divider()

                        Section("Batch Actions") {
                            Button {
                                resolveAllWithStrategy(.keepLocal)
                            } label: {
                                Label("Keep All Local", systemImage: "iphone")
                            }

                            Button {
                                resolveAllWithStrategy(.keepRemote)
                            } label: {
                                Label("Keep All Remote", systemImage: "icloud")
                            }

                            Button {
                                resolveAllWithStrategy(.keepBoth)
                            } label: {
                                Label("Keep All (Duplicate)", systemImage: "doc.on.doc")
                            }

                            Button {
                                skipAllConflicts()
                            } label: {
                                Label("Skip All", systemImage: "forward")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            // Delete all conflicts (cancel resolution)
                            clearAllConflicts()
                        } label: {
                            Label("Clear All Conflicts", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(conflictManager.unresolvedConflicts.isEmpty)
                }
            }
            .sheet(isPresented: $showSettings) {
                ConflictSettingsView()
            }
            .sheet(isPresented: $showResolvedHistory) {
                ResolvedConflictsView()
            }
            .sheet(item: $selectedConflict) { conflict in
                ConflictDetailView(conflict: conflict)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("No Conflicts")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("All your data is in sync!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if conflictManager.totalConflictsDetected > 0 {
                VStack(spacing: 4) {
                    Text("Total conflicts resolved: \(conflictManager.totalConflictsDetected)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Auto-resolved: \(conflictManager.totalAutoResolved) • Manual: \(conflictManager.totalUserResolved)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }

    // MARK: - Conflicts List

    private var conflictsList: some View {
        List {
            // Summary section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(conflictManager.unresolvedCount) Conflict\(conflictManager.unresolvedCount == 1 ? "" : "s")")
                            .font(.headline)

                        Text("Review and resolve sync conflicts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // High priority conflicts
            if !conflictManager.highPriorityConflicts.isEmpty {
                Section {
                    ForEach(conflictManager.highPriorityConflicts) { conflict in
                        ConflictRow(conflict: conflict) {
                            selectedConflict = conflict
                        }
                    }
                } header: {
                    Label("High Priority", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }

            // All other conflicts
            Section {
                ForEach(conflictManager.conflictsByPriority.filter { $0.priority != .high }) { conflict in
                    ConflictRow(conflict: conflict) {
                        selectedConflict = conflict
                    }
                }
            } header: {
                Text("Other Conflicts")
            }
        }
    }

    // MARK: - Actions

    private func resolveAllWithStrategy(_ resolution: SyncConflict.ConflictResolution) {
        Task {
            do {
                try await conflictManager.resolveAllConflicts(with: resolution, modelContext: modelContext)
                HapticManager.shared.notification(.success)
            } catch {
                print("❌ Error resolving all conflicts: \(error)")
                HapticManager.shared.notification(.error)
            }
        }
    }

    private func skipAllConflicts() {
        Task {
            do {
                try await conflictManager.resolveAllConflicts(with: .skipForNow, modelContext: modelContext)
                HapticManager.shared.notification(.success)
            } catch {
                print("❌ Error skipping conflicts: \(error)")
                HapticManager.shared.notification(.error)
            }
        }
    }

    private func clearAllConflicts() {
        // Remove all unresolved conflicts without resolving them
        conflictManager.unresolvedConflicts.removeAll()
        HapticManager.shared.notification(.success)
    }
}

// MARK: - Conflict Row

struct ConflictRow: View {
    let conflict: SyncConflict
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Priority indicator
                Circle()
                    .fill(priorityColor)
                    .frame(width: 10, height: 10)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entityIcon)
                            .font(.title3)

                        Text(conflict.entityType.rawValue.capitalized)
                            .font(.headline)
                            .textCase(.none)
                    }

                    Text(conflict.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(
                            conflict.detectedAt.formatted(.relative(presentation: .named)),
                            systemImage: "clock"
                        )
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                        if conflict.requiresUserInput {
                            Label("Action Required", systemImage: "hand.raised.fill")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var priorityColor: Color {
        switch conflict.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
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
}

// MARK: - Conflict Settings View

struct ConflictSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var conflictManager = ConflictResolutionManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $conflictManager.autoResolveSimpleConflicts) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-Resolve Simple Conflicts")
                                .font(.headline)

                            Text("Automatically resolve conflicts that don't require review")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if conflictManager.autoResolveSimpleConflicts {
                        Picker("Strategy", selection: $conflictManager.autoResolveStrategy) {
                            ForEach(ConflictResolutionManager.AutoResolveStrategy.allCases, id: \.self) { strategy in
                                Text(strategy.rawValue).tag(strategy)
                            }
                        }
                    }
                } header: {
                    Text("Auto-Resolution")
                } footer: {
                    Text("Simple conflicts include property changes without deletions. Complex conflicts like content modifications always require your review.")
                }

                Section {
                    HStack {
                        Text("Total Conflicts")
                        Spacer()
                        Text("\(conflictManager.totalConflictsDetected)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Auto-Resolved")
                        Spacer()
                        Text("\(conflictManager.totalAutoResolved)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Manually Resolved")
                        Spacer()
                        Text("\(conflictManager.totalUserResolved)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Statistics")
                }
            }
            .navigationTitle("Conflict Settings")
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

// MARK: - Resolved Conflicts View

struct ResolvedConflictsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var conflictManager = ConflictResolutionManager.shared

    var body: some View {
        NavigationStack {
            List {
                if conflictManager.resolvedConflicts.isEmpty {
                    ContentUnavailableView(
                        "No Resolved Conflicts",
                        systemImage: "checkmark.circle",
                        description: Text("Resolved conflicts will appear here")
                    )
                } else {
                    ForEach(conflictManager.resolvedConflicts.reversed()) { conflict in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(conflict.entityType.rawValue.capitalized)
                                    .font(.headline)

                                Spacer()

                                if let resolution = conflict.resolution {
                                    Text(resolution.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundStyle(.green)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(conflict.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let resolvedAt = conflict.resolvedAt {
                                Text("Resolved \(resolvedAt.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Resolved Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if !conflictManager.resolvedConflicts.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            conflictManager.clearResolvedHistory()
                        } label: {
                            Text("Clear")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Conflicts") {
    ConflictResolutionView()
        .onAppear {
            // Add sample conflicts for preview
            let conflict1 = SyncConflict(
                conflictType: .contentModification,
                entityType: .song,
                entityID: UUID(),
                localVersion: SyncConflict.ConflictVersion(
                    timestamp: Date().addingTimeInterval(-3600),
                    deviceName: "iPhone",
                    data: SyncConflict.ConflictVersion.ConflictData(
                        title: "Amazing Grace",
                        content: "Local content..."
                    )
                ),
                remoteVersion: SyncConflict.ConflictVersion(
                    timestamp: Date().addingTimeInterval(-1800),
                    deviceName: "iPad",
                    data: SyncConflict.ConflictVersion.ConflictData(
                        title: "Amazing Grace",
                        content: "Remote content..."
                    )
                ),
                detectedAt: Date()
            )

            ConflictResolutionManager.shared.addConflict(conflict1)
        }
}

#Preview("Empty State") {
    ConflictResolutionView()
}
