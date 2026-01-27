//
//  ModerationAppealManager.swift
//  Lyra
//
//  Phase 7.13: Manages appeal process for moderation decisions
//

import Foundation
import SwiftData
import CloudKit

@MainActor
class ModerationAppealManager {
    static let shared = ModerationAppealManager()

    private init() {}

    // MARK: - Submit Appeal

    /// Submits an appeal for a moderation decision
    func submitAppeal(
        publicSongID: UUID,
        userRecordID: String,
        appealReason: String,
        additionalDetails: String?,
        originalDecision: String,
        originalReason: String,
        modelContext: ModelContext
    ) throws -> ModerationAppeal {
        // Check if user already has a pending appeal for this song
        let existingDescriptor = FetchDescriptor<ModerationAppeal>(
            predicate: #Predicate { appeal in
                appeal.publicSongID == publicSongID &&
                appeal.userRecordID == userRecordID &&
                appeal.status == .pending || appeal.status == .underReview
            }
        )

        let existingAppeals = try modelContext.fetch(existingDescriptor)

        if !existingAppeals.isEmpty {
            throw AppealError.duplicateAppeal
        }

        // Create new appeal
        let appeal = ModerationAppeal(
            publicSongID: publicSongID,
            userRecordID: userRecordID,
            appealReason: appealReason,
            additionalDetails: additionalDetails,
            originalDecision: originalDecision,
            originalReason: originalReason
        )

        modelContext.insert(appeal)
        try modelContext.save()

        // Notify moderation team
        NotificationCenter.default.post(
            name: .moderationAppealSubmitted,
            object: nil,
            userInfo: ["appealID": appeal.id, "songID": publicSongID]
        )

        return appeal
    }

    // MARK: - Review Appeals

    /// Gets all pending appeals
    func getPendingAppeals(limit: Int = 50, modelContext: ModelContext) throws -> [ModerationAppeal] {
        let descriptor = FetchDescriptor<ModerationAppeal>(
            predicate: #Predicate { appeal in
                appeal.status == .pending
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        let appeals = try modelContext.fetch(descriptor)
        return Array(appeals.prefix(limit))
    }

    /// Gets appeals under review
    func getAppealsUnderReview(modelContext: ModelContext) throws -> [ModerationAppeal] {
        let descriptor = FetchDescriptor<ModerationAppeal>(
            predicate: #Predicate { appeal in
                appeal.status == .underReview
            },
            sortBy: [SortDescriptor(\.updatedAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Gets user's appeals
    func getAppeals(for userRecordID: String, modelContext: ModelContext) throws -> [ModerationAppeal] {
        let descriptor = FetchDescriptor<ModerationAppeal>(
            predicate: #Predicate { appeal in
                appeal.userRecordID == userRecordID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Gets appeal for a specific song
    func getAppeal(for publicSongID: UUID, userRecordID: String, modelContext: ModelContext) throws -> ModerationAppeal? {
        let descriptor = FetchDescriptor<ModerationAppeal>(
            predicate: #Predicate { appeal in
                appeal.publicSongID == publicSongID && appeal.userRecordID == userRecordID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let appeals = try modelContext.fetch(descriptor)
        return appeals.first
    }

    // MARK: - Process Appeals

    /// Starts reviewing an appeal
    func beginReview(
        _ appeal: ModerationAppeal,
        reviewerID: String,
        reviewerName: String,
        modelContext: ModelContext
    ) throws {
        appeal.beginReview(by: reviewerID, reviewerName: reviewerName)
        try modelContext.save()
    }

    /// Approves an appeal and reinstates content
    func approveAppeal(
        _ appeal: ModerationAppeal,
        reviewerNotes: String?,
        publicSong: PublicSong,
        modelContext: ModelContext
    ) async throws {
        // Resolve appeal
        appeal.resolve(
            outcome: .approved,
            details: "After review, the content meets community guidelines.",
            reinstated: true,
            reviewerNotes: reviewerNotes
        )

        // Reinstate the song
        publicSong.moderationStatus = .approved
        publicSong.moderatedAt = Date()
        publicSong.moderatedBy = appeal.reviewedBy

        try modelContext.save()

        // Update in CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await updateCloudKitModerationStatus(
                recordID: recordID,
                status: .approved,
                moderator: appeal.reviewedBy ?? "System"
            )
        }

        // Notify user
        await notifyUser(
            userRecordID: appeal.userRecordID,
            message: "Your appeal for '\(publicSong.title)' was approved. The content has been reinstated.",
            isPositive: true
        )

        // Improve reputation
        if let userID = appeal.userRecordID as String? {
            try UserReputationManager.shared.adjustScore(
                for: userID,
                adjustment: 5.0,
                reason: "Successful appeal",
                modelContext: modelContext
            )
        }
    }

    /// Partially approves an appeal with modifications
    func partiallyApproveAppeal(
        _ appeal: ModerationAppeal,
        reviewerNotes: String?,
        requiredChanges: String,
        modelContext: ModelContext
    ) throws {
        appeal.resolve(
            outcome: .partiallyApproved,
            details: requiredChanges,
            reinstated: false,
            reviewerNotes: reviewerNotes
        )

        try modelContext.save()

        // Notify user
        await notifyUser(
            userRecordID: appeal.userRecordID,
            message: "Your appeal was partially approved. Please make the following changes: \(requiredChanges)",
            isPositive: false
        )
    }

    /// Denies an appeal
    func denyAppeal(
        _ appeal: ModerationAppeal,
        reviewerNotes: String?,
        denialReason: String,
        modelContext: ModelContext
    ) throws {
        appeal.resolve(
            outcome: .denied,
            details: denialReason,
            reinstated: false,
            reviewerNotes: reviewerNotes
        )

        try modelContext.save()

        // Notify user
        await notifyUser(
            userRecordID: appeal.userRecordID,
            message: "Your appeal was reviewed. The original decision stands: \(denialReason)",
            isPositive: false
        )
    }

    /// Marks appeal as requiring edits
    func requireEdit(
        _ appeal: ModerationAppeal,
        reviewerNotes: String?,
        editRequirements: String,
        modelContext: ModelContext
    ) throws {
        appeal.resolve(
            outcome: .requiresEdit,
            details: editRequirements,
            reinstated: false,
            reviewerNotes: reviewerNotes
        )

        try modelContext.save()

        // Notify user
        await notifyUser(
            userRecordID: appeal.userRecordID,
            message: "Your appeal was reviewed. Please edit the content: \(editRequirements)",
            isPositive: false
        )
    }

    // MARK: - Learning from Appeals

    /// Marks an appeal as a learning opportunity for AI improvement
    func markAsLearningOpportunity(
        _ appeal: ModerationAppeal,
        feedbackToAI: String,
        modelContext: ModelContext
    ) throws {
        appeal.markAsLearningOpportunity(feedbackToAI: feedbackToAI)
        try modelContext.save()

        // Log for AI training improvements
        logAIFeedback(appeal: appeal, feedback: feedbackToAI)
    }

    /// Analyzes appeal patterns to improve moderation
    func analyzeAppealPatterns(modelContext: ModelContext) throws -> AppealAnalytics {
        let descriptor = FetchDescriptor<ModerationAppeal>(
            predicate: #Predicate { appeal in
                appeal.status == .resolved
            }
        )

        let resolvedAppeals = try modelContext.fetch(descriptor)

        var analytics = AppealAnalytics()
        analytics.totalAppeals = resolvedAppeals.count

        for appeal in resolvedAppeals {
            if appeal.reinstated {
                analytics.approvedAppeals += 1
            } else {
                analytics.deniedAppeals += 1
            }

            if appeal.improvedModerationRules {
                analytics.learningOpportunities += 1
            }

            // Track common appeal reasons
            let reason = appeal.appealReason.lowercased()
            analytics.commonReasons[reason, default: 0] += 1

            // Track outcomes
            if let outcome = appeal.outcome {
                analytics.outcomeBreakdown[outcome.rawValue, default: 0] += 1
            }
        }

        analytics.approvalRate = analytics.totalAppeals > 0 ?
            Double(analytics.approvedAppeals) / Double(analytics.totalAppeals) : 0.0

        return analytics
    }

    // MARK: - Statistics

    /// Gets appeal statistics for a user
    func getUserAppealStats(for userRecordID: String, modelContext: ModelContext) throws -> UserAppealStats {
        let descriptor = FetchDescriptor<ModerationAppeal>(
            predicate: #Predicate { appeal in
                appeal.userRecordID == userRecordID
            }
        )

        let appeals = try modelContext.fetch(descriptor)

        var stats = UserAppealStats()
        stats.totalAppeals = appeals.count

        for appeal in appeals {
            if appeal.reinstated {
                stats.successfulAppeals += 1
            }

            if appeal.status == .pending || appeal.status == .underReview {
                stats.pendingAppeals += 1
            }
        }

        stats.successRate = stats.totalAppeals > 0 ?
            Double(stats.successfulAppeals) / Double(stats.totalAppeals) : 0.0

        return stats
    }

    // MARK: - Private Helpers

    private func updateCloudKitModerationStatus(
        recordID: String,
        status: ModerationStatus,
        moderator: String
    ) async throws {
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDatabase.record(for: ckRecordID)

        record["moderationStatus"] = status.rawValue as CKRecordValue
        record["moderatedBy"] = moderator as CKRecordValue
        record["moderatedAt"] = Date() as CKRecordValue

        try await publicDatabase.save(record)
    }

    private func notifyUser(userRecordID: String, message: String, isPositive: Bool) async {
        // Send notification to user
        print("\(isPositive ? "✅" : "ℹ️") Notification to \(userRecordID): \(message)")

        // Implementation would use CloudKit notifications or APNS
    }

    private func logAIFeedback(appeal: ModerationAppeal, feedback: String) {
        // Log feedback for future AI training
        print("🤖 AI Feedback logged for appeal \(appeal.id): \(feedback)")

        // This would typically:
        // 1. Store in a training dataset
        // 2. Aggregate patterns
        // 3. Inform model retraining
    }
}

// MARK: - Analytics Structures

struct AppealAnalytics {
    var totalAppeals: Int = 0
    var approvedAppeals: Int = 0
    var deniedAppeals: Int = 0
    var learningOpportunities: Int = 0
    var approvalRate: Double = 0.0
    var commonReasons: [String: Int] = [:]
    var outcomeBreakdown: [String: Int] = [:]
}

struct UserAppealStats {
    var totalAppeals: Int = 0
    var successfulAppeals: Int = 0
    var pendingAppeals: Int = 0
    var successRate: Double = 0.0
}

// MARK: - Errors

enum AppealError: LocalizedError {
    case duplicateAppeal
    case appealNotFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .duplicateAppeal:
            return "You already have a pending appeal for this content."
        case .appealNotFound:
            return "Appeal not found."
        case .unauthorized:
            return "You are not authorized to perform this action."
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let moderationAppealSubmitted = Notification.Name("moderationAppealSubmitted")
    static let moderationAppealResolved = Notification.Name("moderationAppealResolved")
}
