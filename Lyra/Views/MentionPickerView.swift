//
//  MentionPickerView.swift
//  Lyra
//
//  Autocomplete picker for @mentions in comments
//

import SwiftUI

struct MentionPickerView: View {
    let searchText: String
    let libraryID: UUID?
    let onSelect: (String) -> Void

    @State private var availableUsers: [UserPresence] = []
    @State private var isLoading: Bool = false

    private let presenceManager = PresenceManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "at.circle.fill")
                    .foregroundStyle(.blue)
                Text("Mention Someone")
                    .font(.headline)

                Spacer()
            }
            .padding()

            Divider()

            // User list
            if isLoading {
                loadingView
            } else if filteredUsers.isEmpty {
                emptyState
            } else {
                userList
            }
        }
        .frame(width: 300, height: 400)
        .presentationDetents([.height(400)])
        .task {
            await loadUsers()
        }
    }

    // MARK: - User List

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredUsers) { user in
                    Button {
                        onSelect(user.displayNameOrDefault)
                    } label: {
                        HStack(spacing: 12) {
                            // Avatar
                            Circle()
                                .fill(Color(hex: user.colorHex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Text(user.displayNameOrDefault.prefix(1).uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }

                            // User info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayNameOrDefault)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(user.isActive ? .green : .gray)
                                        .frame(width: 6, height: 6)

                                    Text(user.isActive ? "Active now" : "Offline")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            // Device badge
                            Text(user.deviceType)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading users...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No users found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var filteredUsers: [UserPresence] {
        if searchText.isEmpty {
            return availableUsers
        }

        return availableUsers.filter {
            $0.displayNameOrDefault
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Data Loading

    private func loadUsers() async {
        isLoading = true

        // Load users from library if available
        if let libraryID = libraryID {
            await presenceManager.fetchActiveUsers(in: libraryID)
            availableUsers = presenceManager.activeUsers
        } else {
            // Fallback: show recent collaborators or all users
            // For now, just show active users from PresenceManager
            availableUsers = presenceManager.activeUsers
        }

        // Sort by online status, then by name
        availableUsers.sort { user1, user2 in
            if user1.isActive != user2.isActive {
                return user1.isActive
            }
            return user1.displayNameOrDefault < user2.displayNameOrDefault
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    MentionPickerView(
        searchText: "",
        libraryID: UUID(),
        onSelect: { name in
            print("Selected: \(name)")
        }
    )
}
