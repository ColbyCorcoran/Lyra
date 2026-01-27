//
//  UserReputationView.swift
//  Lyra
//
//  Phase 7.13: View for displaying user reputation and upload statistics
//

import SwiftUI
import SwiftData

/// Displays user's reputation score and upload history
struct UserReputationView: View {
    let userRecordID: String

    @Environment(\.modelContext) private var modelContext
    @State private var reputation: UserReputation?
    @State private var recentUploads: [PublicSong] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading reputation...")
                } else if let reputation = reputation {
                    // Reputation Score Card
                    reputationScoreCard(reputation)

                    // Trust Level
                    trustLevelCard(reputation)

                    // Statistics
                    statisticsCard(reputation)

                    // Recent Uploads
                    recentUploadsSection

                    // Tips for Improvement
                    if !reputation.isTrusted {
                        improvementTips(reputation)
                    }
                } else {
                    newUserCard
                }
            }
            .padding()
        }
        .navigationTitle("Your Reputation")
        .task {
            await loadReputation()
        }
    }

    // MARK: - Reputation Score Card

    private func reputationScoreCard(_ reputation: UserReputation) -> some View {
        VStack(spacing: 16) {
            // Tier icon and score
            VStack(spacing: 8) {
                Image(systemName: reputation.tier.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(Color(reputation.tier.color))

                Text(reputation.tier.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(reputation.displayScore) / 100")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            ProgressView(value: reputation.score, total: 100)
                .tint(Color(reputation.tier.color))

            // Status
            if reputation.isBanned {
                Label("Account Restricted", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            } else if reputation.isTrusted {
                Label("Trusted Contributor", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Trust Level Card

    private func trustLevelCard(_ reputation: UserReputation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Trust Level", systemImage: "shield.checkered")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reputation.trustLevel.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(reputation.trustLevel.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: reputation.isTrusted ? "checkmark.circle.fill" : "clock")
                    .foregroundStyle(reputation.isTrusted ? .green : .orange)
                    .font(.title2)
            }

            if !reputation.isTrusted && reputation.consecutiveApprovals > 0 {
                ProgressView(
                    "Progress to Trusted: \(reputation.consecutiveApprovals) / 10",
                    value: Double(reputation.consecutiveApprovals),
                    total: 10
                )
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Statistics Card

    private func statisticsCard(_ reputation: UserReputation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upload Statistics", systemImage: "chart.bar")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statBox(
                    title: "Total Uploads",
                    value: "\(reputation.totalUploads)",
                    icon: "arrow.up.circle",
                    color: .blue
                )

                statBox(
                    title: "Approved",
                    value: "\(reputation.approvedUploads)",
                    icon: "checkmark.circle",
                    color: .green
                )

                statBox(
                    title: "Rejected",
                    value: "\(reputation.rejectedUploads)",
                    icon: "xmark.circle",
                    color: .red
                )

                statBox(
                    title: "Flagged",
                    value: "\(reputation.flaggedUploads)",
                    icon: "flag",
                    color: .orange
                )
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Approval Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(String(format: "%.1f%%", reputation.approvalRate * 100))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Rating")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)

                        Text(String(format: "%.1f", reputation.averageRating))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Recent Uploads Section

    private var recentUploadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Uploads", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            if recentUploads.isEmpty {
                Text("No uploads yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentUploads.prefix(5)) { upload in
                    uploadRow(upload)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func uploadRow(_ song: PublicSong) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let artist = song.artist {
                    Text(artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: song.moderationStatus.icon)
                    .foregroundStyle(Color(song.moderationStatus.color))

                Text(song.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Improvement Tips

    private func improvementTips(_ reputation: UserReputation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tips to Improve Your Reputation", systemImage: "lightbulb")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                if reputation.score < 70 {
                    tipRow(
                        icon: "checkmark.circle",
                        text: "Upload high-quality, complete songs"
                    )
                }

                if reputation.flaggedUploads > 0 {
                    tipRow(
                        icon: "book.closed",
                        text: "Review and follow community guidelines"
                    )
                }

                tipRow(
                    icon: "c.circle",
                    text: "Only upload original or properly licensed content"
                )

                tipRow(
                    icon: "music.note.list",
                    text: "Include accurate metadata (artist, key, tempo)"
                )

                if reputation.consecutiveApprovals < 10 {
                    tipRow(
                        icon: "arrow.up.circle",
                        text: "Get \(10 - reputation.consecutiveApprovals) more approvals to become trusted"
                    )
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .font(.caption)

            Text(text)
                .font(.caption)
        }
    }

    // MARK: - New User Card

    private var newUserCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Welcome!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start uploading quality content to build your reputation. Trusted users get auto-approved submissions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Load Data

    private func loadReputation() async {
        isLoading = true
        defer { isLoading = false }

        do {
            reputation = try UserReputationManager.shared.fetchReputation(
                for: userRecordID,
                modelContext: modelContext
            )

            recentUploads = try UserReputationManager.shared.getRecentUploads(
                for: userRecordID,
                limit: 10,
                modelContext: modelContext
            )
        } catch {
            print("Error loading reputation: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserReputation.self, PublicSong.self, configurations: config)

    let reputation = UserReputation(userRecordID: "test-user")
    reputation.score = 75
    reputation.tier = .gold
    reputation.trustLevel = .established
    reputation.totalUploads = 15
    reputation.approvedUploads = 13
    reputation.rejectedUploads = 1
    reputation.flaggedUploads = 1
    reputation.averageRating = 4.5
    reputation.consecutiveApprovals = 8

    return NavigationStack {
        UserReputationView(userRecordID: "test-user")
            .modelContainer(container)
    }
}
