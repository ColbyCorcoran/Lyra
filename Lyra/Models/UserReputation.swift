//
//  UserReputation.swift
//  Lyra
//
//  Phase 7.13: User reputation tracking for content moderation
//

import SwiftData
import Foundation

/// Tracks uploader reputation for content moderation
@Model
final class UserReputation {
    // MARK: - Identifiers
    var id: UUID
    var userRecordID: String // CloudKit user ID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Reputation Score
    var score: Double // 0-100, starts at 50
    var tier: ReputationTier

    // MARK: - Upload Statistics
    var totalUploads: Int
    var approvedUploads: Int
    var rejectedUploads: Int
    var flaggedUploads: Int
    var autoApprovedUploads: Int

    // MARK: - Quality Metrics
    var averageQualityScore: Double // 0-100
    var averageDownloads: Double
    var averageLikes: Double
    var averageRating: Double

    // MARK: - Moderation History
    var warningCount: Int
    var lastWarningDate: Date?
    var temporaryBanCount: Int
    var lastBanDate: Date?
    var isBanned: Bool
    var banReason: String?

    // MARK: - Trust Indicators
    var isTrusted: Bool // Auto-approved submissions
    var isVerified: Bool // Identity verified
    var trustLevel: TrustLevel
    var consecutiveApprovals: Int

    // MARK: - Activity Tracking
    var lastUploadDate: Date?
    var uploadFrequency: UploadFrequency
    var suspiciousActivityCount: Int

    init(userRecordID: String) {
        self.id = UUID()
        self.userRecordID = userRecordID
        self.createdAt = Date()
        self.updatedAt = Date()

        // Start with neutral reputation
        self.score = 50.0
        self.tier = .bronze

        // Statistics
        self.totalUploads = 0
        self.approvedUploads = 0
        self.rejectedUploads = 0
        self.flaggedUploads = 0
        self.autoApprovedUploads = 0

        // Quality
        self.averageQualityScore = 0.0
        self.averageDownloads = 0.0
        self.averageLikes = 0.0
        self.averageRating = 0.0

        // Moderation
        self.warningCount = 0
        self.temporaryBanCount = 0
        self.isBanned = false

        // Trust
        self.isTrusted = false
        self.isVerified = false
        self.trustLevel = .newUser
        self.consecutiveApprovals = 0

        // Activity
        self.uploadFrequency = .normal
        self.suspiciousActivityCount = 0
    }

    // MARK: - Computed Properties

    var approvalRate: Double {
        guard totalUploads > 0 else { return 0.0 }
        return Double(approvedUploads) / Double(totalUploads)
    }

    var flagRate: Double {
        guard totalUploads > 0 else { return 0.0 }
        return Double(flaggedUploads) / Double(totalUploads)
    }

    var displayScore: String {
        String(format: "%.0f", score)
    }

    var statusDescription: String {
        if isBanned {
            return "Banned"
        } else if isTrusted {
            return "Trusted User"
        } else if isVerified {
            return "Verified User"
        } else {
            return trustLevel.rawValue
        }
    }

    // MARK: - Reputation Updates

    func recordApproval(qualityScore: Double, isAutoApproved: Bool) {
        totalUploads += 1
        approvedUploads += 1
        if isAutoApproved {
            autoApprovedUploads += 1
        }
        consecutiveApprovals += 1
        lastUploadDate = Date()
        updatedAt = Date()

        // Update quality score
        updateAverageQualityScore(qualityScore)

        // Increase reputation
        let bonus = isAutoApproved ? 2.0 : 1.0
        increaseScore(by: bonus)

        // Check for trust upgrade
        checkTrustUpgrade()
    }

    func recordRejection(reason: String) {
        totalUploads += 1
        rejectedUploads += 1
        consecutiveApprovals = 0
        lastUploadDate = Date()
        updatedAt = Date()

        // Decrease reputation
        decreaseScore(by: 5.0)

        // Downgrade trust if needed
        if isTrusted && rejectedUploads > 3 {
            isTrusted = false
            trustLevel = .established
        }
    }

    func recordFlag() {
        flaggedUploads += 1
        updatedAt = Date()

        // Decrease reputation
        decreaseScore(by: 3.0)

        // Check for warning
        if flagRate > 0.3 {
            issueWarning()
        }
    }

    func recordWarning() {
        warningCount += 1
        lastWarningDate = Date()
        updatedAt = Date()

        decreaseScore(by: 10.0)

        if warningCount >= 3 {
            temporaryBan()
        }
    }

    func temporaryBan() {
        isBanned = true
        temporaryBanCount += 1
        lastBanDate = Date()
        updatedAt = Date()

        decreaseScore(by: 20.0)
        isTrusted = false
        trustLevel = .restricted
    }

    func liftBan() {
        isBanned = false
        updatedAt = Date()
    }

    func recordSuccessfulContent(downloads: Int, likes: Int, rating: Double) {
        // Update averages
        averageDownloads = (averageDownloads * Double(approvedUploads - 1) + Double(downloads)) / Double(approvedUploads)
        averageLikes = (averageLikes * Double(approvedUploads - 1) + Double(likes)) / Double(approvedUploads)
        if rating > 0 {
            averageRating = (averageRating * Double(approvedUploads - 1) + rating) / Double(approvedUploads)
        }

        updatedAt = Date()

        // Bonus for popular content
        if downloads > 50 {
            increaseScore(by: 5.0)
        }
    }

    // MARK: - Private Methods

    private func increaseScore(by amount: Double) {
        score = min(100.0, score + amount)
        updateTier()
    }

    private func decreaseScore(by amount: Double) {
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

    private func updateAverageQualityScore(_ newScore: Double) {
        let totalScored = approvedUploads
        averageQualityScore = (averageQualityScore * Double(totalScored - 1) + newScore) / Double(totalScored)
    }

    private func checkTrustUpgrade() {
        // Become trusted after consistent good behavior
        if !isTrusted && consecutiveApprovals >= 10 && score >= 70 && flagRate < 0.1 {
            isTrusted = true
            trustLevel = .trusted
        }

        // Update trust level
        if score >= 90 && approvedUploads >= 50 {
            trustLevel = .expert
        } else if score >= 75 && approvedUploads >= 25 {
            trustLevel = .trusted
        } else if score >= 60 && approvedUploads >= 10 {
            trustLevel = .established
        } else if approvedUploads >= 3 {
            trustLevel = .growing
        }
    }

    private func issueWarning() {
        recordWarning()
    }
}

// MARK: - Enums

enum ReputationTier: String, Codable, CaseIterable {
    case restricted = "Restricted"
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"

    var icon: String {
        switch self {
        case .restricted: return "exclamationmark.triangle"
        case .bronze: return "3.circle.fill"
        case .silver: return "2.circle.fill"
        case .gold: return "1.circle.fill"
        case .platinum: return "crown.fill"
        }
    }

    var color: String {
        switch self {
        case .restricted: return "red"
        case .bronze: return "brown"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "purple"
        }
    }
}

enum TrustLevel: String, Codable, CaseIterable {
    case newUser = "New User"
    case growing = "Growing"
    case established = "Established"
    case trusted = "Trusted"
    case expert = "Expert"
    case restricted = "Restricted"

    var description: String {
        switch self {
        case .newUser:
            return "All uploads require manual review"
        case .growing:
            return "Building reputation"
        case .established:
            return "Consistent quality uploads"
        case .trusted:
            return "Auto-approved submissions"
        case .expert:
            return "Top contributor - instant approval"
        case .restricted:
            return "Limited due to policy violations"
        }
    }
}

enum UploadFrequency: String, Codable {
    case normal = "Normal"
    case high = "High"
    case suspicious = "Suspicious"
}
