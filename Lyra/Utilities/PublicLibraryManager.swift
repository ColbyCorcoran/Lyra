//
//  PublicLibraryManager.swift
//  Lyra
//
//  Manages public song library with CloudKit integration
//

import Foundation
import SwiftData
import CloudKit

@MainActor
class PublicLibraryManager {
    static let shared = PublicLibraryManager()

    private let publicDatabase = CKContainer.default().publicCloudDatabase
    private let recordType = "PublicSong"

    private init() {}

    // MARK: - Upload to Public Library

    /// Uploads a song to the public library with AI moderation
    func uploadSong(
        _ song: Song,
        genre: SongGenre,
        category: SongCategory,
        tags: [String],
        isAnonymous: Bool,
        licenseType: LicenseType,
        copyrightInfo: String?,
        modelContext: ModelContext
    ) async throws -> PublicSong {
        // Get current user info
        let userRecordID = try await getCurrentUserRecordID()
        let displayName = isAnonymous ? "Anonymous" : (PresenceManager.shared.currentUserPresence?.displayName ?? "User")

        // Check rate limiting
        if !isAnonymous {
            let isLimited = try UserReputationManager.shared.isRateLimited(
                for: userRecordID,
                modelContext: modelContext
            )

            if isLimited {
                throw PublicLibraryError.rateLimited
            }
        }

        // Get user reputation
        let reputation = isAnonymous ? nil : try? UserReputationManager.shared.fetchReputation(
            for: userRecordID,
            modelContext: modelContext
        )

        // Check if user is banned
        if let reputation = reputation, reputation.isBanned {
            throw PublicLibraryError.userBanned(reason: reputation.banReason ?? "Policy violation")
        }

        // Create PublicSong model
        let publicSong = PublicSong(
            title: song.title,
            artist: song.artist,
            content: song.content,
            contentFormat: song.contentFormat,
            genre: genre,
            uploaderDisplayName: displayName,
            isAnonymous: isAnonymous
        )

        publicSong.uploaderRecordID = isAnonymous ? nil : userRecordID
        publicSong.originalKey = song.originalKey
        publicSong.tempo = song.tempo
        publicSong.timeSignature = song.timeSignature
        publicSong.capo = song.capo
        publicSong.tags = tags
        publicSong.category = category
        publicSong.licenseType = licenseType
        publicSong.copyrightInfo = copyrightInfo

        // Get recent uploads for spam detection
        let recentUploads = isAnonymous ? [] : try UserReputationManager.shared.getRecentUploads(
            for: userRecordID,
            limit: 20,
            modelContext: modelContext
        )

        // Run AI content moderation analysis
        let moderationResult = await AIContentModerationEngine.shared.analyzeSong(
            publicSong,
            uploaderReputation: reputation,
            recentUploads: recentUploads
        )

        // Apply moderation decision
        switch moderationResult.decision {
        case .autoApprove:
            publicSong.moderationStatus = .approved
            publicSong.moderatedBy = "AI Moderation"
            publicSong.moderatedAt = Date()

        case .requiresReview:
            publicSong.moderationStatus = .pending
            publicSong.moderationNotes = moderationResult.details

        case .quarantine:
            publicSong.moderationStatus = .flagged
            publicSong.moderationNotes = "Quarantined for review: " + moderationResult.details

        case .rejected:
            // Don't save rejected songs
            throw PublicLibraryError.contentRejected(reason: moderationResult.details)
        }

        // Save to local database first
        modelContext.insert(publicSong)
        try modelContext.save()

        // Upload to CloudKit public database
        let record = try await uploadToCloudKit(publicSong)
        publicSong.cloudKitRecordID = record.recordID.recordName

        try modelContext.save()

        // Update user reputation
        if !isAnonymous {
            if moderationResult.isApproved {
                try UserReputationManager.shared.recordApproval(
                    for: userRecordID,
                    publicSong: publicSong,
                    qualityScore: (1.0 - moderationResult.score) * 100,
                    isAutoApproved: true,
                    modelContext: modelContext
                )
            }
        }

        // Post notification
        NotificationCenter.default.post(
            name: .songUploadedToPublic,
            object: nil,
            userInfo: [
                "songID": publicSong.id,
                "moderationDecision": moderationResult.decision.rawValue,
                "autoApproved": moderationResult.isApproved
            ]
        )

        return publicSong
    }

    private func uploadToCloudKit(_ publicSong: PublicSong) async throws -> CKRecord {
        let record = CKRecord(recordType: recordType)

        // Basic info
        record["title"] = publicSong.title as CKRecordValue
        record["artist"] = (publicSong.artist ?? "") as CKRecordValue
        record["content"] = publicSong.content as CKRecordValue
        record["contentFormat"] = publicSong.contentFormat.rawValue as CKRecordValue

        // Metadata
        record["originalKey"] = (publicSong.originalKey ?? "") as CKRecordValue
        record["tempo"] = (publicSong.tempo ?? 0) as CKRecordValue
        record["genre"] = publicSong.genre.rawValue as CKRecordValue
        record["category"] = publicSong.category.rawValue as CKRecordValue
        record["tags"] = (publicSong.tags ?? []) as CKRecordValue

        // Uploader
        record["uploaderDisplayName"] = publicSong.uploaderDisplayName as CKRecordValue
        record["isAnonymous"] = (publicSong.isAnonymous ? 1 : 0) as CKRecordValue

        // License
        record["licenseType"] = publicSong.licenseType.rawValue as CKRecordValue
        record["copyrightInfo"] = (publicSong.copyrightInfo ?? "") as CKRecordValue

        // Stats (initialize to 0)
        record["downloadCount"] = 0 as CKRecordValue
        record["viewCount"] = 0 as CKRecordValue
        record["likeCount"] = 0 as CKRecordValue
        record["averageRating"] = 0.0 as CKRecordValue

        // Moderation
        record["moderationStatus"] = ModerationStatus.pending.rawValue as CKRecordValue

        return try await publicDatabase.save(record)
    }

    // MARK: - Browse and Search

    /// Fetches public songs with filters
    func fetchPublicSongs(
        searchTerm: String? = nil,
        genre: SongGenre? = nil,
        category: SongCategory? = nil,
        key: String? = nil,
        sortBy: PublicSongSortOption = .recentlyAdded,
        limit: Int = 50
    ) async throws -> [PublicSong] {
        var predicates: [NSPredicate] = []

        // Only show approved songs
        predicates.append(NSPredicate(format: "moderationStatus == %@", ModerationStatus.approved.rawValue))

        // Search term (title or artist)
        if let search = searchTerm, !search.isEmpty {
            let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", search)
            let artistPredicate = NSPredicate(format: "artist CONTAINS[cd] %@", search)
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, artistPredicate]))
        }

        // Genre filter
        if let genre = genre {
            predicates.append(NSPredicate(format: "genre == %@", genre.rawValue))
        }

        // Category filter
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }

        // Key filter
        if let key = key {
            predicates.append(NSPredicate(format: "originalKey == %@", key))
        }

        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: recordType, predicate: compoundPredicate)

        // Sort
        switch sortBy {
        case .recentlyAdded:
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .mostDownloaded:
            query.sortDescriptors = [NSSortDescriptor(key: "downloadCount", ascending: false)]
        case .highestRated:
            query.sortDescriptors = [NSSortDescriptor(key: "averageRating", ascending: false)]
        case .trending:
            query.sortDescriptors = [NSSortDescriptor(key: "trendingScore", ascending: false)]
        case .alphabetical:
            query.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        }

        let results = try await publicDatabase.records(matching: query, resultsLimit: limit)
        var publicSongs: [PublicSong] = []

        for (recordID, result) in results.matchResults {
            if let record = try? result.get() {
                if let publicSong = publicSongFromRecord(record) {
                    publicSongs.append(publicSong)
                }
            }
        }

        return publicSongs
    }

    /// Fetches trending songs
    func fetchTrendingSongs(limit: Int = 20) async throws -> [PublicSong] {
        return try await fetchPublicSongs(sortBy: .trending, limit: limit)
    }

    /// Fetches featured/editor's pick songs
    func fetchFeaturedSongs(limit: Int = 10) async throws -> [PublicSong] {
        let predicate = NSPredicate(format: "isFeatured == %@ AND moderationStatus == %@",
                                   NSNumber(value: true),
                                   ModerationStatus.approved.rawValue)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results = try await publicDatabase.records(matching: query, resultsLimit: limit)
        var publicSongs: [PublicSong] = []

        for (_, result) in results.matchResults {
            if let record = try? result.get() {
                if let publicSong = publicSongFromRecord(record) {
                    publicSongs.append(publicSong)
                }
            }
        }

        return publicSongs
    }

    // MARK: - Download from Public Library

    /// Downloads a song from public library to personal library
    func downloadSong(
        _ publicSong: PublicSong,
        modelContext: ModelContext
    ) async throws -> Song {
        // Create local song from public song
        let song = Song(
            title: publicSong.title,
            artist: publicSong.artist,
            content: publicSong.content,
            contentFormat: publicSong.contentFormat,
            originalKey: publicSong.originalKey
        )

        song.tempo = publicSong.tempo
        song.timeSignature = publicSong.timeSignature
        song.capo = publicSong.capo
        song.tags = publicSong.tags

        // Add attribution note
        var attribution = "Downloaded from Lyra Community Library\n"
        attribution += publicSong.displayAttribution

        if song.notes != nil {
            song.notes! += "\n\n" + attribution
        } else {
            song.notes = attribution
        }

        modelContext.insert(song)
        try modelContext.save()

        // Increment download count
        try await incrementDownloadCount(publicSong)

        // Post notification
        NotificationCenter.default.post(
            name: .songDownloadedFromPublic,
            object: nil,
            userInfo: ["songID": song.id, "publicSongID": publicSong.id]
        )

        return song
    }

    private func incrementDownloadCount(_ publicSong: PublicSong) async throws {
        guard let recordID = publicSong.cloudKitRecordID else { return }

        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDatabase.record(for: ckRecordID)

        let currentCount = record["downloadCount"] as? Int ?? 0
        record["downloadCount"] = (currentCount + 1) as CKRecordValue

        try await publicDatabase.save(record)

        // Update local copy
        publicSong.incrementDownloads()
    }

    // MARK: - Rating and Feedback

    /// Rates a public song
    func rateSong(
        _ publicSong: PublicSong,
        rating: Int,
        review: String? = nil,
        userRecordID: String,
        modelContext: ModelContext
    ) async throws {
        // Create or update local rating
        let songRating = PublicSongRating(
            userRecordID: userRecordID,
            rating: rating,
            review: review
        )
        songRating.publicSong = publicSong
        modelContext.insert(songRating)

        // Update average rating
        let totalRatings = (publicSong.ratings?.count ?? 0) + 1
        publicSong.updateAverageRating(newRating: Double(rating), totalRatings: totalRatings)

        try modelContext.save()

        // Update CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await updateRatingInCloudKit(recordID: recordID, averageRating: publicSong.averageRating)
        }
    }

    private func updateRatingInCloudKit(recordID: String, averageRating: Double) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDatabase.record(for: ckRecordID)

        record["averageRating"] = averageRating as CKRecordValue

        try await publicDatabase.save(record)
    }

    /// Likes a public song
    func likeSong(
        _ publicSong: PublicSong,
        userRecordID: String,
        modelContext: ModelContext
    ) async throws {
        // Check if already liked
        let descriptor = FetchDescriptor<PublicSongLike>(
            predicate: #Predicate { like in
                like.userRecordID == userRecordID && like.songID == publicSong.id
            }
        )

        let existingLikes = try modelContext.fetch(descriptor)

        if existingLikes.isEmpty {
            // Add like
            let like = PublicSongLike(userRecordID: userRecordID, songID: publicSong.id)
            modelContext.insert(like)

            publicSong.incrementLikes()
            try modelContext.save()

            // Update CloudKit
            if let recordID = publicSong.cloudKitRecordID {
                try await incrementLikeCount(recordID: recordID)
            }
        }
    }

    /// Unlikes a public song
    func unlikeSong(
        _ publicSong: PublicSong,
        userRecordID: String,
        modelContext: ModelContext
    ) async throws {
        let descriptor = FetchDescriptor<PublicSongLike>(
            predicate: #Predicate { like in
                like.userRecordID == userRecordID && like.songID == publicSong.id
            }
        )

        let existingLikes = try modelContext.fetch(descriptor)

        for like in existingLikes {
            modelContext.delete(like)
        }

        publicSong.decrementLikes()
        try modelContext.save()

        // Update CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await decrementLikeCount(recordID: recordID)
        }
    }

    private func incrementLikeCount(recordID: String) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDatabase.record(for: ckRecordID)

        let currentCount = record["likeCount"] as? Int ?? 0
        record["likeCount"] = (currentCount + 1) as CKRecordValue

        try await publicDatabase.save(record)
    }

    private func decrementLikeCount(recordID: String) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDatabase.record(for: ckRecordID)

        let currentCount = record["likeCount"] as? Int ?? 0
        record["likeCount"] = max(0, currentCount - 1) as CKRecordValue

        try await publicDatabase.save(record)
    }

    // MARK: - Flagging

    /// Flags a public song for moderation
    func flagSong(
        _ publicSong: PublicSong,
        reason: FlagReason,
        details: String?,
        userRecordID: String,
        modelContext: ModelContext
    ) async throws {
        let flag = PublicSongFlag(
            userRecordID: userRecordID,
            reason: reason,
            details: details
        )
        flag.publicSong = publicSong
        modelContext.insert(flag)

        publicSong.flagCount += 1
        try modelContext.save()

        // Update CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await incrementFlagCount(recordID: recordID)
        }

        // Notify moderation team
        NotificationCenter.default.post(
            name: .publicSongFlagged,
            object: nil,
            userInfo: ["songID": publicSong.id, "reason": reason.rawValue]
        )
    }

    private func incrementFlagCount(recordID: String) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDatabase.record(for: ckRecordID)

        let currentCount = record["flagCount"] as? Int ?? 0
        record["flagCount"] = (currentCount + 1) as CKRecordValue

        // Auto-flag for review if too many reports
        if currentCount + 1 >= 5 {
            record["moderationStatus"] = ModerationStatus.flagged.rawValue as CKRecordValue
        }

        try await publicDatabase.save(record)
    }

    // MARK: - Helper Methods

    private func getCurrentUserRecordID() async throws -> String {
        let recordID = try await CKContainer.default().userRecordID()
        return recordID.recordName
    }

    private func publicSongFromRecord(_ record: CKRecord) -> PublicSong? {
        guard let title = record["title"] as? String,
              let content = record["content"] as? String,
              let contentFormatStr = record["contentFormat"] as? String,
              let contentFormat = ContentFormat(rawValue: contentFormatStr),
              let genreStr = record["genre"] as? String,
              let genre = SongGenre(rawValue: genreStr),
              let uploaderDisplayName = record["uploaderDisplayName"] as? String else {
            return nil
        }

        let publicSong = PublicSong(
            title: title,
            artist: record["artist"] as? String,
            content: content,
            contentFormat: contentFormat,
            genre: genre,
            uploaderDisplayName: uploaderDisplayName,
            isAnonymous: (record["isAnonymous"] as? Int ?? 0) == 1
        )

        publicSong.cloudKitRecordID = record.recordID.recordName
        publicSong.originalKey = record["originalKey"] as? String
        publicSong.tempo = record["tempo"] as? Int
        publicSong.tags = record["tags"] as? [String]

        if let categoryStr = record["category"] as? String,
           let category = SongCategory(rawValue: categoryStr) {
            publicSong.category = category
        }

        if let licenseStr = record["licenseType"] as? String,
           let license = LicenseType(rawValue: licenseStr) {
            publicSong.licenseType = license
        }

        publicSong.downloadCount = record["downloadCount"] as? Int ?? 0
        publicSong.viewCount = record["viewCount"] as? Int ?? 0
        publicSong.likeCount = record["likeCount"] as? Int ?? 0
        publicSong.averageRating = record["averageRating"] as? Double ?? 0.0

        if let statusStr = record["moderationStatus"] as? String,
           let status = ModerationStatus(rawValue: statusStr) {
            publicSong.moderationStatus = status
        }

        publicSong.createdAt = record.creationDate ?? Date()
        publicSong.modifiedAt = record.modificationDate ?? Date()

        return publicSong
    }
}

// MARK: - Sort Options

enum PublicSongSortOption: String, CaseIterable {
    case recentlyAdded = "Recently Added"
    case mostDownloaded = "Most Downloaded"
    case highestRated = "Highest Rated"
    case trending = "Trending"
    case alphabetical = "A-Z"

    var icon: String {
        switch self {
        case .recentlyAdded: return "clock"
        case .mostDownloaded: return "arrow.down.circle"
        case .highestRated: return "star.fill"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .alphabetical: return "textformat.abc"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let songUploadedToPublic = Notification.Name("songUploadedToPublic")
    static let songDownloadedFromPublic = Notification.Name("songDownloadedFromPublic")
    static let publicSongFlagged = Notification.Name("publicSongFlagged")
}

// MARK: - Errors

enum PublicLibraryError: LocalizedError {
    case rateLimited
    case userBanned(reason: String)
    case contentRejected(reason: String)

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "You're uploading too quickly. Please wait a few minutes before uploading again."
        case .userBanned(let reason):
            return "Your account has been temporarily restricted: \(reason)"
        case .contentRejected(let reason):
            return "Content was rejected: \(reason)"
        }
    }
}
