//
//  ActiveUsersView.swift
//  Lyra
//
//  Shows currently active collaborators in a shared library
//

import SwiftUI

struct ActiveUsersView: View {
    let libraryID: UUID
    @State private var activeUsers: [UserPresence] = []
    @State private var isLoading: Bool = false

    private let presenceManager = PresenceManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if activeUsers.isEmpty {
                    emptyState
                } else {
                    userList
                }
            }
            .navigationTitle("Active Now")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await refreshUsers()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadActiveUsers()

                // Listen for presence changes
                NotificationCenter.default.addObserver(
                    forName: .presenceDidChange,
                    object: nil,
                    queue: .main
                ) { _ in
                    Task {
                        await refreshUsers()
                    }
                }
            }
        }
    }

    // MARK: - User List

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Summary card
                summaryCard

                // User cards
                ForEach(activeUsers) { user in
                    UserPresenceCard(presence: user)
                }
            }
            .padding()
        }
        .refreshable {
            await refreshUsers()
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.2.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(activeUsers.count) Active")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("in this library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Device breakdown
            if !deviceBreakdown.isEmpty {
                Divider()

                HStack(spacing: 16) {
                    ForEach(deviceBreakdown, id: \.device) { item in
                        HStack(spacing: 6) {
                            Image(systemName: deviceIcon(for: item.device))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(item.count)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var deviceBreakdown: [(device: String, count: Int)] {
        let grouped = Dictionary(grouping: activeUsers) { $0.deviceType }
        return grouped.map { (device: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading active users...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("No One Active")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("You're the only one here right now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Data Loading

    private func loadActiveUsers() async {
        isLoading = true
        await presenceManager.fetchActiveUsers(in: libraryID)
        activeUsers = presenceManager.activeUsers
        isLoading = false
    }

    private func refreshUsers() async {
        await presenceManager.fetchActiveUsers(in: libraryID)
        activeUsers = presenceManager.activeUsers
    }

    // MARK: - Helper Methods

    private func deviceIcon(for deviceType: String) -> String {
        switch deviceType.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "macbook"
        default: return "desktopcomputer"
        }
    }
}

// MARK: - User Presence Card

struct UserPresenceCard: View {
    let presence: UserPresence

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User header
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color(hex: presence.colorHex))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(presence.displayNameOrDefault.prefix(1).uppercased())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        // Status indicator
                        Circle()
                            .fill(statusColor)
                            .frame(width: 16, height: 16)
                            .overlay {
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            }
                    }

                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(presence.displayNameOrDefault)
                        .font(.headline)

                    HStack(spacing: 6) {
                        Image(systemName: presence.statusIcon)
                            .font(.caption2)

                        Text(presence.activityDescription)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Device badge
                DeviceBadge(deviceType: presence.deviceType)
            }

            // Current activity
            if let songID = presence.currentSongID {
                Divider()

                HStack(spacing: 8) {
                    Image(systemName: presence.isEditing ? "pencil.circle.fill" : "eye.circle.fill")
                        .foregroundStyle(presence.isEditing ? .orange : .blue)

                    Text(presence.isEditing ? "Editing a song" : "Viewing a song")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if presence.isEditing, let cursor = presence.cursorPosition {
                        Text("Line \(cursor)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
            }

            // Last seen
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text("Active \(relativeTime)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var statusColor: Color {
        switch presence.status {
        case .online: return .green
        case .away: return .yellow
        case .offline: return .gray
        case .doNotDisturb: return .red
        }
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: presence.lastSeenAt, relativeTo: Date())
    }
}

// MARK: - Device Badge

struct DeviceBadge: View {
    let deviceType: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(deviceType)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    private var icon: String {
        switch deviceType.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "macbook"
        default: return "desktopcomputer"
        }
    }
}

// MARK: - Compact Active Users View

struct CompactActiveUsersView: View {
    let libraryID: UUID
    @State private var activeUsers: [UserPresence] = []

    private let presenceManager = PresenceManager.shared

    var body: some View {
        HStack(spacing: -8) {
            // User avatars (max 4)
            ForEach(activeUsers.prefix(4)) { user in
                Circle()
                    .fill(Color(hex: user.colorHex))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(user.displayNameOrDefault.prefix(1).uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    }
            }

            // Count indicator if more than 4
            if activeUsers.count > 4 {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("+\(activeUsers.count - 4)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    }
            }
        }
        .task {
            await presenceManager.fetchActiveUsers(in: libraryID)
            activeUsers = presenceManager.activeUsers
        }
    }
}

// MARK: - Preview

#Preview("Active Users") {
    ActiveUsersView(libraryID: UUID())
}

#Preview("Compact View") {
    CompactActiveUsersView(libraryID: UUID())
        .padding()
}
