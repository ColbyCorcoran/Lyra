//
//  ModerationAppeal.swift
//  Lyra
//
//  Phase 7.13: Appeal process for content moderation decisions
//

import SwiftData
import Foundation

/// Represents an appeal against a moderation decision
@Model
final class ModerationAppeal {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Appeal Details
    var publicSongID: UUID
    var userRecordID: String
    var appealReason: String
    var additionalDetails: String?

    // MARK: - Original Decision
    var originalDecision: String // The moderation decision being appealed
    var originalReason: String // Why it was flagged/rejected
    var moderatedBy: String? // Who made the original decision

    // MARK: - Appeal Status
    var status: AppealStatus
    var reviewedAt: Date?
    var reviewedBy: String?
    var reviewerNotes: String?

    // MARK: - Outcome
    var outcome: AppealOutcome?
    var outcomeDetails: String?
    var reinstated: Bool

    // MARK: - Learning
    var improvedModerationRules: Bool // Did this appeal lead to rule improvements?
    var feedbackToAI: String? // Feedback for improving AI moderation

    init(
        publicSongID: UUID,
        userRecordID: String,
        appealReason: String,
        additionalDetails: String?,
        originalDecision: String,
        originalReason: String
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()

        self.publicSongID = publicSongID
        self.userRecordID = userRecordID
        self.appealReason = appealReason
        self.additionalDetails = additionalDetails

        self.originalDecision = originalDecision
        self.originalReason = originalReason

        self.status = .pending
        self.reinstated = false
        self.improvedModerationRules = false
    }

    // MARK: - Status Updates

    func beginReview(by reviewerID: String, reviewerName: String) {
        status = .underReview
        reviewedBy = reviewerName
        updatedAt = Date()
    }

    func resolve(
        outcome: AppealOutcome,
        details: String,
        reinstated: Bool,
        reviewerNotes: String?
    ) {
        self.status = .resolved
        self.outcome = outcome
        self.outcomeDetails = details
        self.reinstated = reinstated
        self.reviewerNotes = reviewerNotes
        self.reviewedAt = Date()
        self.updatedAt = Date()
    }

    func markAsLearningOpportunity(feedbackToAI: String) {
        self.improvedModerationRules = true
        self.feedbackToAI = feedbackToAI
        self.updatedAt = Date()
    }
}

// MARK: - Enums

enum AppealStatus: String, Codable, CaseIterable {
    case pending = "Pending Review"
    case underReview = "Under Review"
    case resolved = "Resolved"
    case dismissed = "Dismissed"

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .underReview: return "eye"
        case .resolved: return "checkmark.circle"
        case .dismissed: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .underReview: return "blue"
        case .resolved: return "green"
        case .dismissed: return "gray"
        }
    }
}

enum AppealOutcome: String, Codable, CaseIterable {
    case approved = "Appeal Approved - Content Reinstated"
    case partiallyApproved = "Partially Approved - Content Modified"
    case denied = "Appeal Denied"
    case requiresEdit = "Requires Edit Before Reinstatement"

    var icon: String {
        switch self {
        case .approved: return "checkmark.circle.fill"
        case .partiallyApproved: return "checkmark.circle"
        case .denied: return "xmark.circle.fill"
        case .requiresEdit: return "pencil.circle"
        }
    }

    var color: String {
        switch self {
        case .approved: return "green"
        case .partiallyApproved: return "yellow"
        case .denied: return "red"
        case .requiresEdit: return "orange"
        }
    }

    var description: String {
        switch self {
        case .approved:
            return "Your appeal was successful. The content has been reinstated to the public library."
        case .partiallyApproved:
            return "Your appeal was partially accepted. The content has been modified and approved."
        case .denied:
            return "After review, the original moderation decision stands. The content remains removed."
        case .requiresEdit:
            return "You can edit the content to address the issues, then resubmit for approval."
        }
    }
}
