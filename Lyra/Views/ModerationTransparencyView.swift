//
//  ModerationTransparencyView.swift
//  Lyra
//
//  Phase 7.13: Transparency view for content moderation
//

import SwiftUI
import SwiftData

/// Shows moderation status and details for a public song
struct ModerationTransparencyView: View {
    let publicSong: PublicSong
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showAppealSheet = false
    @State private var appeal: ModerationAppeal?
    @State private var isLoadingAppeal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status Header
                    statusHeader

                    // Moderation Details
                    if let notes = publicSong.moderationNotes {
                        moderationDetailsSection(notes: notes)
                    }

                    // Why Flagged/Rejected
                    if publicSong.moderationStatus != .approved {
                        whyFlaggedSection
                    }

                    // Moderation Guidelines
                    guidelinesSection

                    // User's Options
                    userActionsSection
                }
                .padding()
            }
            .navigationTitle("Moderation Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAppealSheet) {
                AppealSubmissionView(publicSong: publicSong, existingAppeal: appeal)
            }
            .task {
                await loadAppeal()
            }
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: publicSong.moderationStatus.icon)
                .font(.system(size: 48))
                .foregroundStyle(statusColor)

            Text(publicSong.moderationStatus.rawValue)
                .font(.title2)
                .fontWeight(.bold)

            if let moderatedBy = publicSong.moderatedBy,
               let moderatedAt = publicSong.moderatedAt {
                Text("Reviewed by \(moderatedBy)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(moderatedAt, style: .relative) + Text(" ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(statusColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        switch publicSong.moderationStatus {
        case .approved:
            return .green
        case .pending:
            return .orange
        case .flagged:
            return .yellow
        case .rejected, .removed:
            return .red
        }
    }

    // MARK: - Moderation Details

    private func moderationDetailsSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Moderation Details", systemImage: "info.circle")
                .font(.headline)

            Text(notes)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Why Flagged Section

    private var whyFlaggedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Why Was This Content Flagged?", systemImage: "questionmark.circle")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                if publicSong.moderationStatus == .flagged || publicSong.flagCount > 0 {
                    flagReasonRow(
                        icon: "exclamationmark.triangle",
                        title: "Community Reports",
                        description: "This content received \(publicSong.flagCount) flag(s) from community members"
                    )
                }

                if publicSong.moderationStatus == .rejected {
                    flagReasonRow(
                        icon: "xmark.circle",
                        title: "Policy Violation",
                        description: "This content violates our community guidelines"
                    )
                }

                if publicSong.moderationStatus == .pending {
                    flagReasonRow(
                        icon: "clock",
                        title: "Pending Review",
                        description: "This content is awaiting human review by our moderation team"
                    )
                }
            }
        }
    }

    private func flagReasonRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Guidelines Section

    private var guidelinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Community Guidelines", systemImage: "book.closed")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                guidelineRow(
                    icon: "checkmark.circle",
                    text: "Original or properly licensed content only"
                )

                guidelineRow(
                    icon: "checkmark.circle",
                    text: "Appropriate for all ages"
                )

                guidelineRow(
                    icon: "checkmark.circle",
                    text: "Complete and properly formatted songs"
                )

                guidelineRow(
                    icon: "checkmark.circle",
                    text: "Respectful and constructive content"
                )

                guidelineRow(
                    icon: "checkmark.circle",
                    text: "No spam or promotional material"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func guidelineRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .font(.caption)

            Text(text)
                .font(.caption)
        }
    }

    // MARK: - User Actions

    private var userActionsSection: some View {
        VStack(spacing: 12) {
            if publicSong.moderationStatus == .rejected || publicSong.moderationStatus == .flagged {
                // Appeal button
                Button(action: {
                    showAppealSheet = true
                }) {
                    Label(appeal == nil ? "Submit Appeal" : "View Appeal Status", systemImage: "hand.raised")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(appeal != nil && appeal?.status == .pending)

                if let appeal = appeal {
                    appealStatusCard(appeal)
                }
            }

            // Learn More button
            Button(action: {
                // Open guidelines or help
            }) {
                Label("Learn More About Moderation", systemImage: "info.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func appealStatusCard(_ appeal: ModerationAppeal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: appeal.status.icon)
                    .foregroundStyle(Color(appeal.status.color))

                Text("Appeal \(appeal.status.rawValue)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(appeal.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let outcome = appeal.outcome {
                Divider()

                HStack {
                    Image(systemName: outcome.icon)
                        .foregroundStyle(Color(outcome.color))

                    Text(outcome.description)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Load Appeal

    private func loadAppeal() async {
        guard let userRecordID = publicSong.uploaderRecordID else { return }

        isLoadingAppeal = true
        defer { isLoadingAppeal = false }

        do {
            appeal = try ModerationAppealManager.shared.getAppeal(
                for: publicSong.id,
                userRecordID: userRecordID,
                modelContext: modelContext
            )
        } catch {
            print("Error loading appeal: \(error)")
        }
    }
}

// MARK: - Appeal Submission View

struct AppealSubmissionView: View {
    let publicSong: PublicSong
    let existingAppeal: ModerationAppeal?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var appealReason = ""
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                if let existingAppeal = existingAppeal {
                    // Show existing appeal status
                    Section("Your Appeal") {
                        appealStatusView(existingAppeal)
                    }
                } else {
                    // Submit new appeal
                    Section("Why should this content be reconsidered?") {
                        TextEditor(text: $appealReason)
                            .frame(minHeight: 100)
                    }

                    Section("Additional Details (Optional)") {
                        TextEditor(text: $additionalDetails)
                            .frame(minHeight: 80)
                    }

                    Section {
                        Button(action: submitAppeal) {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Submit Appeal")
                            }
                        }
                        .disabled(appealReason.isEmpty || isSubmitting)
                    }
                }
            }
            .navigationTitle("Appeal Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func appealStatusView(_ appeal: ModerationAppeal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: appeal.status.icon)
                    .foregroundStyle(Color(appeal.status.color))

                Text(appeal.status.rawValue)
                    .font(.headline)
            }

            Text("Submitted: \(appeal.createdAt, style: .date)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("Your Reason:")
                .font(.caption)
                .fontWeight(.semibold)

            Text(appeal.appealReason)
                .font(.body)

            if let outcome = appeal.outcome {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: outcome.icon)
                            .foregroundStyle(Color(outcome.color))

                        Text("Decision: \(outcome.rawValue)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Text(outcome.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let details = appeal.outcomeDetails {
                        Text(details)
                            .font(.body)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    private func submitAppeal() {
        guard let userRecordID = publicSong.uploaderRecordID else { return }

        isSubmitting = true

        Task {
            do {
                _ = try ModerationAppealManager.shared.submitAppeal(
                    publicSongID: publicSong.id,
                    userRecordID: userRecordID,
                    appealReason: appealReason,
                    additionalDetails: additionalDetails.isEmpty ? nil : additionalDetails,
                    originalDecision: publicSong.moderationStatus.rawValue,
                    originalReason: publicSong.moderationNotes ?? "Content flagged",
                    modelContext: modelContext
                )

                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PublicSong.self, configurations: config)

    let song = PublicSong(
        title: "Amazing Grace",
        artist: "John Newton",
        content: "[C]Amazing [F]grace...",
        contentFormat: .chordPro,
        genre: .traditional,
        uploaderDisplayName: "Test User",
        isAnonymous: false
    )
    song.moderationStatus = .flagged
    song.moderationNotes = "Content flagged for review due to potential copyright concerns."
    song.flagCount = 3

    return ModerationTransparencyView(publicSong: song)
        .modelContainer(container)
}
