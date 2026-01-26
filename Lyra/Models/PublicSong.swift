//
//  PublicSong.swift
//  Lyra
//
//  Model for community-shared songs in the public library
//

import SwiftData
import Foundation
import CloudKit

@Model
final class PublicSong {
    // MARK: - Identifiers
    var id: UUID
    var cloudKitRecordID: String? // CKRecord ID in public database
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Song Content
    var title: String
    var artist: String?
    var content: String
    var contentFormat: ContentFormat

    // MARK: - Musical Metadata
    var originalKey: String?
    var tempo: Int?
    var timeSignature: String?
    var capo: Int?
    var tags: [String]?

    // MARK: - Categorization
    var genre: SongGenre
    var category: SongCategory
    var language: String? // e.g., "English", "Spanish"
    var ccliNumber: String? // CCLI license number if applicable

    // MARK: - Uploader Information
    var uploaderRecordID: String? // CloudKit user ID (nil if anonymous)
    var uploaderDisplayName: String // Can be "Anonymous" or actual name
    var isAnonymous: Bool
    var uploaderAttribution: String? // Optional credit text

    // MARK: - Statistics
    var downloadCount: Int
    var viewCount: Int
    var likeCount: Int
    var averageRating: Double // 0.0 to 5.0

    // MARK: - Licensing & Copyright
    var licenseType: LicenseType
    var copyrightInfo: String?
    var isPublicDomain: Bool
    var sourceAttribution: String? // Where the song came from

    // MARK: - Moderation
    var moderationStatus: ModerationStatus
    var moderatedAt: Date?
    var moderatedBy: String?
    var moderationNotes: String?
    var flagCount: Int
    var isFeatured: Bool // Editor's pick

    // MARK: - Discovery
    var trendingScore: Double // Calculated score for trending
    var lastDownloadedAt: Date?

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \PublicSongRating.publicSong)
    var ratings: [PublicSongRating]?

    @Relationship(deleteRule: .cascade, inverse: \PublicSongFlag.publicSong)
    var flags: [PublicSongFlag]?

    init(
        title: String,
        artist: String?,
        content: String,
        contentFormat: ContentFormat,
        genre: SongGenre,
        uploaderDisplayName: String,
        isAnonymous: Bool = false
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.title = title
        self.artist = artist
        self.content = content
        self.contentFormat = contentFormat
        self.genre = genre
        self.category = .worship // Default
        self.uploaderDisplayName = uploaderDisplayName
        self.isAnonymous = isAnonymous
        self.downloadCount = 0
        self.viewCount = 0
        self.likeCount = 0
        self.averageRating = 0.0
        self.licenseType = .userGenerated
        self.isPublicDomain = false
        self.moderationStatus = .pending
        self.flagCount = 0
        self.isFeatured = false
        self.trendingScore = 0.0
    }

    // MARK: - Computed Properties

    var displayAttribution: String {
        if isAnonymous {
            return "Shared anonymously"
        } else if let attribution = uploaderAttribution {
            return attribution
        } else {
            return "Shared by \(uploaderDisplayName)"
        }
    }

    var isApproved: Bool {
        moderationStatus == .approved
    }

    var canDownload: Bool {
        isApproved && flagCount < 10
    }

    // MARK: - Statistics Updates

    func incrementViews() {
        viewCount += 1
        updateTrendingScore()
    }

    func incrementDownloads() {
        downloadCount += 1
        lastDownloadedAt = Date()
        updateTrendingScore()
    }

    func incrementLikes() {
        likeCount += 1
        updateTrendingScore()
    }

    func decrementLikes() {
        likeCount = max(0, likeCount - 1)
        updateTrendingScore()
    }

    func updateAverageRating(newRating: Double, totalRatings: Int) {
        // Weighted average
        averageRating = ((averageRating * Double(totalRatings - 1)) + newRating) / Double(totalRatings)
        updateTrendingScore()
    }

    // MARK: - Trending Score Calculation

    /// Calculates trending score based on recent activity
    private func updateTrendingScore() {
        let now = Date()
        let daysSinceUpload = now.timeIntervalSince(createdAt) / (24 * 60 * 60)

        // Recent downloads are weighted more heavily
        let recentDownloadBoost: Double
        if let lastDownload = lastDownloadedAt {
            let hoursSinceDownload = now.timeIntervalSince(lastDownload) / (60 * 60)
            recentDownloadBoost = max(0, 10 - hoursSinceDownload) * 2
        } else {
            recentDownloadBoost = 0
        }

        // Score formula: combines downloads, likes, ratings, and recency
        let downloadScore = Double(downloadCount) * 2.0
        let likeScore = Double(likeCount) * 1.5
        let ratingScore = averageRating * Double(ratings?.count ?? 1)
        let recencyPenalty = daysSinceUpload > 30 ? 0.5 : 1.0

        trendingScore = (downloadScore + likeScore + ratingScore + recentDownloadBoost) * recencyPenalty
    }
}

// MARK: - Song Genre

enum SongGenre: String, Codable, CaseIterable {
    case worship = "Worship"
    case contemporary = "Contemporary Christian"
    case traditional = "Traditional Hymn"
    case gospel = "Gospel"
    case praise = "Praise & Worship"
    case acoustic = "Acoustic"
    case rock = "Rock"
    case folk = "Folk"
    case country = "Country"
    case pop = "Pop"
    case jazz = "Jazz"
    case classical = "Classical"
    case other = "Other"

    var icon: String {
        switch self {
        case .worship, .praise: return "hands.sparkles"
        case .contemporary: return "music.mic"
        case .traditional: return "book.closed"
        case .gospel: return "music.note.house"
        case .acoustic: return "guitars"
        case .rock: return "bolt.fill"
        case .folk: return "leaf.fill"
        case .country: return "star.fill"
        case .pop: return "waveform"
        case .jazz: return "music.quarternote.3"
        case .classical: return "pianokeys"
        case .other: return "music.note"
        }
    }
}

// MARK: - Song Category

enum SongCategory: String, Codable, CaseIterable {
    case worship = "Worship Service"
    case christmas = "Christmas"
    case easter = "Easter"
    case baptism = "Baptism"
    case communion = "Communion"
    case wedding = "Wedding"
    case funeral = "Funeral"
    case youth = "Youth"
    case kids = "Kids"
    case seasonal = "Seasonal"
    case general = "General"

    var icon: String {
        switch self {
        case .worship: return "hands.sparkles"
        case .christmas: return "snowflake"
        case .easter: return "cross.case"
        case .baptism: return "drop.fill"
        case .communion: return "cup.and.saucer.fill"
        case .wedding: return "heart.fill"
        case .funeral: return "cloud.fill"
        case .youth: return "figure.wave"
        case .kids: return "figure.2.and.child.holdinghands"
        case .seasonal: return "calendar"
        case .general: return "music.note.list"
        }
    }
}

// MARK: - License Type

enum LicenseType: String, Codable, CaseIterable {
    case userGenerated = "User Generated"
    case publicDomain = "Public Domain"
    case ccli = "CCLI Licensed"
    case creativeCommons = "Creative Commons"
    case copyrighted = "Copyrighted (Permission Granted)"
    case unknown = "Unknown"

    var requiresAttribution: Bool {
        switch self {
        case .userGenerated, .creativeCommons:
            return true
        case .publicDomain, .ccli, .copyrighted, .unknown:
            return false
        }
    }

    var description: String {
        switch self {
        case .userGenerated:
            return "Created and shared by community member"
        case .publicDomain:
            return "Public domain - free to use"
        case .ccli:
            return "Licensed through CCLI"
        case .creativeCommons:
            return "Creative Commons license"
        case .copyrighted:
            return "Copyrighted with permission to share"
        case .unknown:
            return "License status unknown"
        }
    }
}

// MARK: - Moderation Status

enum ModerationStatus: String, Codable, CaseIterable {
    case pending = "Pending Review"
    case approved = "Approved"
    case rejected = "Rejected"
    case flagged = "Flagged for Review"
    case removed = "Removed"

    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected, .removed: return "red"
        case .flagged: return "yellow"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .flagged: return "flag.fill"
        case .removed: return "trash.fill"
        }
    }
}

// MARK: - Public Song Rating

@Model
final class PublicSongRating {
    var id: UUID
    var createdAt: Date

    var userRecordID: String
    var rating: Int // 1-5 stars
    var review: String? // Optional written review

    @Relationship(deleteRule: .nullify)
    var publicSong: PublicSong?

    init(userRecordID: String, rating: Int, review: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.userRecordID = userRecordID
        self.rating = max(1, min(5, rating)) // Clamp to 1-5
        self.review = review
    }
}

// MARK: - Public Song Flag

@Model
final class PublicSongFlag {
    var id: UUID
    var createdAt: Date

    var userRecordID: String
    var reason: FlagReason
    var details: String?

    var reviewedAt: Date?
    var reviewedBy: String?
    var reviewOutcome: FlagOutcome?

    @Relationship(deleteRule: .nullify)
    var publicSong: PublicSong?

    init(userRecordID: String, reason: FlagReason, details: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.userRecordID = userRecordID
        self.reason = reason
        self.details = details
    }

    func resolve(outcome: FlagOutcome, reviewedBy: String) {
        self.reviewedAt = Date()
        self.reviewedBy = reviewedBy
        self.reviewOutcome = outcome
    }
}

enum FlagReason: String, Codable, CaseIterable {
    case copyright = "Copyright Violation"
    case inappropriate = "Inappropriate Content"
    case inaccurate = "Inaccurate Information"
    case spam = "Spam"
    case duplicate = "Duplicate Song"
    case other = "Other"

    var icon: String {
        switch self {
        case .copyright: return "c.circle"
        case .inappropriate: return "exclamationmark.triangle"
        case .inaccurate: return "questionmark.circle"
        case .spam: return "trash"
        case .duplicate: return "doc.on.doc"
        case .other: return "flag"
        }
    }
}

enum FlagOutcome: String, Codable {
    case dismissed = "Dismissed"
    case warning = "Warning Issued"
    case contentRemoved = "Content Removed"
    case userBanned = "User Banned"
}

// MARK: - User Like Tracking

@Model
final class PublicSongLike {
    var id: UUID
    var createdAt: Date

    var userRecordID: String
    var songID: UUID

    init(userRecordID: String, songID: UUID) {
        self.id = UUID()
        self.createdAt = Date()
        self.userRecordID = userRecordID
        self.songID = songID
    }
}
