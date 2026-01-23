//
//  ContentModerationManager.swift
//  Lyra
//
//  Admin tools for moderating public library content
//

import Foundation
import SwiftData
import CloudKit

@MainActor
class ContentModerationManager {
    static let shared = ContentModerationManager()

    private let publicDatabase = CKContainer.default().publicCloudDatabase
    private let recordType = "PublicSong"

    // Admin user record IDs (would be configured server-side in production)
    private var adminUserIDs: Set<String> = []

    private init() {}

    // MARK: - Admin Check

    func isAdmin(_ userRecordID: String) -> Bool {
        // In production, this would check against server-side admin list
        return adminUserIDs.contains(userRecordID)
    }

    func addAdmin(_ userRecordID: String) {
        adminUserIDs.insert(userRecordID)
    }

    // MARK: - Moderation Queue

    /// Fetches songs pending moderation
    func fetchPendingReview(limit: Int = 50) async throws -> [PublicSong] {
        let predicate = NSPredicate(format: "moderationStatus == %@", ModerationStatus.pending.rawValue)
        return try await fetchSongsWithPredicate(predicate, limit: limit)
    }

    /// Fetches flagged songs
    func fetchFlaggedSongs(limit: Int = 50) async throws -> [PublicSong] {
        let predicate = NSPredicate(format: "moderationStatus == %@ OR flagCount >= %d",
                                   ModerationStatus.flagged.rawValue,
                                   5)
        return try await fetchSongsWithPredicate(predicate, limit: limit)
    }

    private func fetchSongsWithPredicate(_ predicate: NSPredicate, limit: Int) async throws -> [PublicSong] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results = try await publicDatabase.records(matching: query, resultsLimit: limit)
        var songs: [PublicSong] = []

        for (_, result) in results.matchResults {
            if let record = try? result.get(),
               let song = publicSongFromRecord(record) {
                songs.append(song)
            }
        }

        return songs
    }

    // MARK: - Moderation Actions

    /// Approves a song for public viewing
    func approveSong(
        _ publicSong: PublicSong,
        moderatorID: String,
        moderatorName: String,
        modelContext: ModelContext
    ) async throws {
        publicSong.moderationStatus = .approved
        publicSong.moderatedAt = Date()
        publicSong.moderatedBy = moderatorName

        try modelContext.save()

        // Update CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await updateModerationStatus(
                recordID: recordID,
                status: .approved,
                moderator: moderatorName
            )
        }
    }

    /// Rejects a song
    func rejectSong(
        _ publicSong: PublicSong,
        reason: String,
        moderatorID: String,
        moderatorName: String,
        modelContext: ModelContext
    ) async throws {
        publicSong.moderationStatus = .rejected
        publicSong.moderatedAt = Date()
        publicSong.moderatedBy = moderatorName
        publicSong.moderationNotes = reason

        try modelContext.save()

        // Update CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await updateModerationStatus(
                recordID: recordID,
                status: .rejected,
                moderator: moderatorName
            )
        }

        // Notify uploader (if not anonymous)
        if !publicSong.isAnonymous, let uploaderID = publicSong.uploaderRecordID {
            await notifyUploader(uploaderID: uploaderID, songTitle: publicSong.title, reason: reason)
        }
    }

    /// Removes a song from public library
    func removeSong(
        _ publicSong: PublicSong,
        reason: String,
        moderatorID: String,
        moderatorName: String,
        modelContext: ModelContext
    ) async throws {
        publicSong.moderationStatus = .removed
        publicSong.moderatedAt = Date()
        publicSong.moderatedBy = moderatorName
        publicSong.moderationNotes = reason

        try modelContext.save()

        // Update CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await updateModerationStatus(
                recordID: recordID,
                status: .removed,
                moderator: moderatorName
            )
        }
    }

    /// Marks a song as featured (editor's pick)
    func featureSong(
        _ publicSong: PublicSong,
        modelContext: ModelContext
    ) async throws {
        publicSong.isFeatured = true
        try modelContext.save()

        // Update CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await updateFeaturedStatus(recordID: recordID, isFeatured: true)
        }
    }

    /// Removes featured status
    func unfeatureSong(
        _ publicSong: PublicSong,
        modelContext: ModelContext
    ) async throws {
        publicSong.isFeatured = false
        try modelContext.save()

        // Update CloudKit
        if let recordID = publicSong.cloudKitRecordID {
            try await updateFeaturedStatus(recordID: recordID, isFeatured: false)
        }
    }

    // MARK: - Flag Management

    /// Reviews a flag
    func reviewFlag(
        _ flag: PublicSongFlag,
        outcome: FlagOutcome,
        reviewerID: String,
        reviewerName: String,
        modelContext: ModelContext
    ) throws {
        flag.resolve(outcome: outcome, reviewedBy: reviewerName)
        try modelContext.save()
    }

    /// Dismisses a flag without action
    func dismissFlag(
        _ flag: PublicSongFlag,
        reviewerID: String,
        reviewerName: String,
        modelContext: ModelContext
    ) throws {
        flag.resolve(outcome: .dismissed, reviewedBy: reviewerName)
        try modelContext.save()
    }

    // MARK: - CloudKit Updates

    private func updateModerationStatus(
        recordID: String,
        status: ModerationStatus,
        moderator: String
    ) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDatabase.record(for: ckRecordID)

        record["moderationStatus"] = status.rawValue as CKRecordValue
        record["moderatedBy"] = moderator as CKRecordValue
        record["moderatedAt"] = Date() as CKRecordValue

        try await publicDatabase.save(record)
    }

    private func updateFeaturedStatus(
        recordID: String,
        isFeatured: Bool
    ) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let record = try await publicDatabase.record(for: ckRecordID)

        record["isFeatured"] = (isFeatured ? 1 : 0) as CKRecordValue

        try await publicDatabase.save(record)
    }

    // MARK: - Notifications

    private func notifyUploader(uploaderID: String, songTitle: String, reason: String) async {
        // Implementation would send notification to uploader
        print("📧 Notifying uploader about \(songTitle): \(reason)")
    }

    // MARK: - Helper

    private func publicSongFromRecord(_ record: CKRecord) -> PublicSong? {
        // Reuse PublicLibraryManager's conversion logic
        return PublicLibraryManager.shared.publicSongFromRecord(record)
    }
}

// MARK: - Public Extension for Helper

extension PublicLibraryManager {
    func publicSongFromRecord(_ record: CKRecord) -> PublicSong? {
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
        publicSong.createdAt = record.creationDate ?? Date()
        publicSong.modifiedAt = record.modificationDate ?? Date()

        return publicSong
    }
}
