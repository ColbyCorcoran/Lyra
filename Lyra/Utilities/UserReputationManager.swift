//
//  UserReputationManager.swift
//  Lyra
//
//  Phase 7.13: Manages user reputation for content moderation
//

import Foundation
import SwiftData
import CloudKit

@MainActor
class UserReputationManager {
    static let shared = UserReputationManager()

    private init() {}

    // MARK: - Reputation Lookup

    /// Gets or creates reputation for a user
    func getReputation(for userRecordID: String, modelContext: ModelContext) throws -> UserReputation {
        // Try to fetch existing reputation
        let descriptor = FetchDescriptor<UserReputation>(
            predicate: #Predicate { reputation in
                reputation.userRecordID == userRecordID
            }
        )

        let existingReputations = try modelContext.fetch(descriptor)

        if let existing = existingReputations.first {
            return existing
        }

        // Create new reputation
        let newReputation = UserReputation(userRecordID: userRecordID)
        modelContext.insert(newReputation)
        try modelContext.save()

        return newReputation
    }

    /// Gets reputation if it exists (doesn't create)
    func fetchReputation(for userRecordID: String, modelContext: ModelContext) throws -> UserReputation? {
        let descriptor = FetchDescriptor<UserReputation>(
            predicate: #Predicate { reputation in
                reputation.userRecordID == userRecordID
            }
        )

        let reputations = try modelContext.fetch(descriptor)
        return reputations.first
    }

    // MARK: - Reputation Updates

    /// Records a successful upload approval
    func recordApproval(
        for userRecordID: String,
        publicSong: PublicSong,
        qualityScore: Double,
        isAutoApproved: Bool,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.recordApproval(qualityScore: qualityScore, isAutoApproved: isAutoApproved)

        try modelContext.save()

        // Post notification
        NotificationCenter.default.post(
            name: .userReputationUpdated,
            object: nil,
            userInfo: ["userRecordID": userRecordID, "reputation": reputation]
        )
    }

    /// Records a rejection
    func recordRejection(
        for userRecordID: String,
        reason: String,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.recordRejection(reason: reason)

        try modelContext.save()

        NotificationCenter.default.post(
            name: .userReputationUpdated,
            object: nil,
            userInfo: ["userRecordID": userRecordID, "reputation": reputation]
        )
    }

    /// Records a flag on user's content
    func recordFlag(
        for userRecordID: String,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.recordFlag()

        try modelContext.save()
    }

    /// Records successful content performance
    func recordContentSuccess(
        for userRecordID: String,
        downloads: Int,
        likes: Int,
        rating: Double,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.recordSuccessfulContent(downloads: downloads, likes: likes, rating: rating)

        try modelContext.save()
    }

    /// Issues a warning to a user
    func issueWarning(
        for userRecordID: String,
        reason: String,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.recordWarning()

        try modelContext.save()

        // Notify user
        await notifyUser(userRecordID: userRecordID, message: "Warning: \(reason)")
    }

    /// Temporarily bans a user
    func temporaryBan(
        for userRecordID: String,
        reason: String,
        duration: TimeInterval = 7 * 24 * 60 * 60, // 7 days
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.temporaryBan()
        reputation.banReason = reason

        try modelContext.save()

        // Schedule unban
        scheduleUnban(userRecordID: userRecordID, after: duration)

        // Notify user
        await notifyUser(userRecordID: userRecordID, message: "Account temporarily restricted: \(reason)")
    }

    /// Lifts a ban
    func liftBan(
        for userRecordID: String,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.liftBan()
        reputation.banReason = nil

        try modelContext.save()

        await notifyUser(userRecordID: userRecordID, message: "Account restrictions lifted")
    }

    /// Manually adjusts reputation score
    func adjustScore(
        for userRecordID: String,
        adjustment: Double,
        reason: String,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        if adjustment > 0 {
            reputation.increaseScore(by: adjustment)
        } else {
            reputation.decreaseScore(by: abs(adjustment))
        }

        try modelContext.save()
    }

    /// Grants trusted status
    func grantTrustedStatus(
        for userRecordID: String,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.isTrusted = true
        reputation.trustLevel = .trusted

        try modelContext.save()

        await notifyUser(userRecordID: userRecordID, message: "Congratulations! You're now a trusted contributor.")
    }

    /// Revokes trusted status
    func revokeTrustedStatus(
        for userRecordID: String,
        reason: String,
        modelContext: ModelContext
    ) throws {
        let reputation = try getReputation(for: userRecordID, modelContext: modelContext)

        reputation.isTrusted = false
        reputation.trustLevel = .established

        try modelContext.save()

        await notifyUser(userRecordID: userRecordID, message: "Trusted status revoked: \(reason)")
    }

    // MARK: - Statistics & Analytics

    /// Gets top contributors
    func getTopContributors(limit: Int = 10, modelContext: ModelContext) throws -> [UserReputation] {
        var descriptor = FetchDescriptor<UserReputation>(
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try modelContext.fetch(descriptor)
    }

    /// Gets users requiring review
    func getUsersRequiringReview(modelContext: ModelContext) throws -> [UserReputation] {
        let descriptor = FetchDescriptor<UserReputation>(
            predicate: #Predicate { reputation in
                reputation.flaggedUploads > 0 || reputation.suspiciousActivityCount > 0 || reputation.score < 25
            },
            sortBy: [SortDescriptor(\.score)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Checks if user is rate-limited
    func isRateLimited(for userRecordID: String, modelContext: ModelContext) throws -> Bool {
        guard let reputation = try fetchReputation(for: userRecordID, modelContext: modelContext) else {
            return false
        }

        // Banned users are rate-limited
        if reputation.isBanned {
            return true
        }

        // Check upload frequency
        if let lastUpload = reputation.lastUploadDate {
            let timeSinceLastUpload = Date().timeIntervalSince(lastUpload)

            // Rate limits based on reputation
            if reputation.isTrusted {
                return false // No rate limit for trusted users
            } else if reputation.score >= 70 {
                return timeSinceLastUpload < 60 // 1 minute
            } else if reputation.score >= 50 {
                return timeSinceLastUpload < 300 // 5 minutes
            } else {
                return timeSinceLastUpload < 600 // 10 minutes
            }
        }

        return false
    }

    /// Gets user's recent uploads
    func getRecentUploads(for userRecordID: String, limit: Int = 20, modelContext: ModelContext) throws -> [PublicSong] {
        let descriptor = FetchDescriptor<PublicSong>(
            predicate: #Predicate { song in
                song.uploaderRecordID == userRecordID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let allUploads = try modelContext.fetch(descriptor)
        return Array(allUploads.prefix(limit))
    }

    // MARK: - Notifications

    private func notifyUser(userRecordID: String, message: String) async {
        // Send notification to user via CloudKit or push notification
        print("📧 Notification to \(userRecordID): \(message)")

        // Implementation would use CloudKit notifications or APNS
    }

    private func scheduleUnban(userRecordID: String, after duration: TimeInterval) {
        // Schedule a task to unban user after duration
        // This would typically use background tasks or server-side scheduling
        print("⏰ Scheduled unban for \(userRecordID) after \(duration) seconds")
    }

    // MARK: - Batch Operations

    /// Updates reputation for all users based on their content performance
    func batchUpdateReputations(modelContext: ModelContext) async throws {
        let allReputations = try modelContext.fetch(FetchDescriptor<UserReputation>())

        for reputation in allReputations {
            if let userID = reputation.userRecordID as String? {
                let uploads = try getRecentUploads(for: userID, limit: 100, modelContext: modelContext)

                // Calculate average performance
                var totalDownloads = 0
                var totalLikes = 0
                var totalRatings = 0.0
                var ratingCount = 0

                for upload in uploads where upload.isApproved {
                    totalDownloads += upload.downloadCount
                    totalLikes += upload.likeCount
                    if upload.averageRating > 0 {
                        totalRatings += upload.averageRating
                        ratingCount += 1
                    }
                }

                let avgDownloads = uploads.isEmpty ? 0.0 : Double(totalDownloads) / Double(uploads.count)
                let avgLikes = uploads.isEmpty ? 0.0 : Double(totalLikes) / Double(uploads.count)
                let avgRating = ratingCount == 0 ? 0.0 : totalRatings / Double(ratingCount)

                // Update reputation
                reputation.averageDownloads = avgDownloads
                reputation.averageLikes = avgLikes
                reputation.averageRating = avgRating

                // Bonus for high-performing content
                if avgDownloads > 100 {
                    reputation.increaseScore(by: 5.0)
                }
            }
        }

        try modelContext.save()
    }

    /// Resets reputation scores (admin function)
    func resetReputation(for userRecordID: String, modelContext: ModelContext) throws {
        guard let reputation = try fetchReputation(for: userRecordID, modelContext: modelContext) else {
            return
        }

        // Reset to default
        reputation.score = 50.0
        reputation.tier = .bronze
        reputation.isTrusted = false
        reputation.trustLevel = .newUser
        reputation.warningCount = 0
        reputation.isBanned = false
        reputation.banReason = nil

        try modelContext.save()
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let userReputationUpdated = Notification.Name("userReputationUpdated")
}

// MARK: - Extensions

extension UserReputation {
    /// Public helper to increase score (used by manager)
    func increaseScore(by amount: Double) {
        score = min(100.0, score + amount)
        updateTier()
    }

    /// Public helper to decrease score (used by manager)
    func decreaseScore(by amount: Double) {
        score = max(0.0, score - amount)
        updateTier()
    }

    private func updateTier() {
        if score >= 90 {
            tier = .platinum
        } else if score >= 75 {
            tier = .gold
        } else if score >= 50 {
            tier = .silver
        } else if score >= 25 {
            tier = .bronze
        } else {
            tier = .restricted
        }
    }
}
