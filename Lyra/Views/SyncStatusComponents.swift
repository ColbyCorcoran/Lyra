//
//  SyncStatusComponents.swift
//  Lyra
//
//  Comprehensive sync status UI components with error handling and progress indication
//

import SwiftUI

// MARK: - Sync Status Indicator

struct SyncStatusIndicator: View {
    @State private var syncCoordinator = EnhancedCloudKitSync.shared
    @State private var showSyncDetails = false
    @State private var isAnimating = false

    var body: some View {
        Button {
            showSyncDetails = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: syncCoordinator.syncState.icon)
                    .foregroundStyle(colorForState)
                    .rotationEffect(.degrees(isAnimating && isSyncing ? 360 : 0))
                    .animation(
                        isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: isAnimating
                    )

                if isSyncing {
                    Text(syncCoordinator.syncState.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
        .sheet(isPresented: $showSyncDetails) {
            SyncDetailsView()
        }
        .onChange(of: syncCoordinator.syncState) { oldValue, newValue in
            if case .syncing = newValue {
                isAnimating = true
            } else {
                isAnimating = false
            }
        }
        .onAppear {
            if isSyncing {
                isAnimating = true
            }
        }
    }

    private var isSyncing: Bool {
        if case .syncing = syncCoordinator.syncState {
            return true
        }
        return false
    }

    private var colorForState: Color {
        switch syncCoordinator.syncState {
        case .idle:
            return .green
        case .syncing:
            return .blue
        case .paused:
            return .orange
        case .error:
            return .red
        }
    }
}

// MARK: - Sync Details View

struct SyncDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var syncCoordinator = EnhancedCloudKitSync.shared
    @State private var offlineManager = OfflineManager.shared
    @State private var showErrorHistory = false

    var body: some View {
        NavigationStack {
            List {
                // Current Status
                Section("Current Status") {
                    HStack {
                        Image(systemName: syncCoordinator.syncState.icon)
                            .foregroundStyle(stateColor)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(syncCoordinator.syncState.displayText)
                                .font(.headline)

                            Text(statusDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)

                    // Progress bar for syncing
                    if case .syncing(let progress) = syncCoordinator.syncState {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: progress)

                            Text("\(Int(progress * 100))% complete")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Network Status
                Section("Network") {
                    HStack {
                        Image(systemName: offlineManager.networkIcon)
                            .foregroundStyle(offlineManager.isOnline ? .green : .red)

                        Text(offlineManager.networkStatusMessage)
                            .font(.subheadline)

                        Spacer()
                    }

                    if !offlineManager.queuedOperations.isEmpty {
                        HStack {
                            Image(systemName: "tray.full")
                                .foregroundStyle(.orange)

                            Text("\(offlineManager.queuedOperations.count) pending operations")
                                .font(.subheadline)

                            Spacer()
                        }
                    }
                }

                // Last Sync
                if let lastSync = syncCoordinator.lastSyncDate {
                    Section("Last Sync") {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.blue)

                            Text(lastSync, style: .relative)
                                .font(.subheadline)

                            Spacer()

                            Text(lastSync, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Errors
                if !syncCoordinator.errorHistory.isEmpty {
                    Section {
                        Button {
                            showErrorHistory = true
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.red)

                                Text("\(syncCoordinator.errorHistory.count) sync errors")
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } header: {
                        Text("Error History")
                    }
                }

                // Actions
                Section {
                    Button {
                        Task {
                            try? await syncCoordinator.performFullSync()
                        }
                    } label: {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(!canSync)

                    Button {
                        // Clear cache and force full sync
                    } label: {
                        Label("Force Full Sync", systemImage: "arrow.clockwise.icloud")
                    }
                    .disabled(!canSync)
                }
            }
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showErrorHistory) {
                ErrorHistoryView(errors: syncCoordinator.errorHistory)
            }
        }
    }

    private var stateColor: Color {
        switch syncCoordinator.syncState {
        case .idle: return .green
        case .syncing: return .blue
        case .paused: return .orange
        case .error: return .red
        }
    }

    private var statusDescription: String {
        switch syncCoordinator.syncState {
        case .idle:
            return "All changes are synced"
        case .syncing:
            return "Syncing your data with iCloud"
        case .paused:
            return "Sync is paused - will resume when online"
        case .error:
            return "Sync encountered errors - tap for details"
        }
    }

    private var canSync: Bool {
        offlineManager.isOnline && syncCoordinator.syncState != .syncing(progress: 0)
    }
}

// MARK: - Error History View

struct ErrorHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    let errors: [SyncError]

    var body: some View {
        NavigationStack {
            List {
                if errors.isEmpty {
                    ContentUnavailableView(
                        "No Errors",
                        systemImage: "checkmark.circle",
                        description: Text("Your sync is working perfectly")
                    )
                } else {
                    ForEach(errors) { error in
                        ErrorRow(error: error)
                    }
                }
            }
            .navigationTitle("Error History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ErrorRow: View {
    let error: SyncError

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: error.isRetryable ? "arrow.clockwise" : "xmark.circle")
                    .foregroundStyle(error.isRetryable ? .orange : .red)

                Text(error.message)
                    .font(.subheadline)
                    .lineLimit(2)

                Spacer()
            }

            HStack {
                Text(error.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if error.isRetryable {
                    Text("Will retry")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sync Progress View

struct SyncProgressView: View {
    let progress: Double
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress) {
                HStack {
                    Image(systemName: "icloud.and.arrow.up.and.down")
                        .foregroundStyle(.blue)

                    Text(message)
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .progressViewStyle(.linear)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Sync Error Alert

struct SyncErrorAlert: View {
    let title: String
    let message: String
    let isRetryable: Bool
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: isRetryable ? "exclamationmark.triangle" : "xmark.octagon")
                .font(.system(size: 50))
                .foregroundStyle(isRetryable ? .orange : .red)

            // Title
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Actions
            VStack(spacing: 12) {
                if isRetryable {
                    Button {
                        onRetry()
                    } label: {
                        Text("Retry")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Button {
                    onDismiss()
                } label: {
                    Text(isRetryable ? "Cancel" : "OK")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }
}

// MARK: - Network Status Banner

struct NetworkStatusBanner: View {
    @State private var offlineManager = OfflineManager.shared
    @State private var isVisible = true

    var body: some View {
        if !offlineManager.isOnline && isVisible {
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You're Offline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("Changes will sync when you reconnect")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Button {
                    withAnimation {
                        isVisible = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                        .font(.caption)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.orange.gradient)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Sync Conflict Badge

struct SyncConflictBadge: View {
    let conflictCount: Int

    var body: some View {
        if conflictCount > 0 {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)

                Text("\(conflictCount) conflict\(conflictCount == 1 ? "" : "s")")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Loading Overlay

struct SyncLoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Preview

#Preview("Sync Status") {
    VStack(spacing: 20) {
        SyncStatusIndicator()

        SyncProgressView(progress: 0.65, message: "Syncing library...")

        SyncConflictBadge(conflictCount: 3)

        NetworkStatusBanner()
    }
    .padding()
}
