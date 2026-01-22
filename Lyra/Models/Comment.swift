//
//  Comment.swift
//  Lyra
//
//  Model for song comments and threaded discussions
//

import Foundation
import SwiftData
import CloudKit

/// Comment on a song for team collaboration
@Model
final class Comment {
    // MARK: - Identifiers

    var id: UUID
    var createdAt: Date
    var editedAt: Date?

    // MARK: - Content

    var content: String
    var contentMarkdown: String? // Formatted markdown version

    // MARK: - Author

    var authorRecordID: String
    var authorDisplayName: String?

    // MARK: - References

    var songID: UUID
    var libraryID: UUID?

    // Optional: Attach to specific section/line
    var attachedToLine: Int?
    var attachedToSection: String? // "Verse 1", "Chorus", etc.

    // MARK: - Threading

    var parentCommentID: UUID? // For reply threads

    // MARK: - Status

    var isEdited: Bool = false
    var isResolved: Bool = false
    var resolvedBy: String?
    var resolvedAt: Date?

    // MARK: - Metadata

    var reactionCounts: [String: Int] = [:] // emoji -> count

    // MARK: - Initializer

    init(
        content: String,
        authorRecordID: String,
        authorDisplayName: String?,
        songID: UUID,
        libraryID: UUID? = nil,
        parentCommentID: UUID? = nil,
        attachedToLine: Int? = nil,
        attachedToSection: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.content = content
        self.authorRecordID = authorRecordID
        self.authorDisplayName = authorDisplayName
        self.songID = songID
        self.libraryID = libraryID
        self.parentCommentID = parentCommentID
        self.attachedToLine = attachedToLine
        self.attachedToSection = attachedToSection
    }

    // MARK: - Computed Properties

    var isReply: Bool {
        parentCommentID != nil
    }

    var hasReactions: Bool {
        !reactionCounts.isEmpty
    }

    var totalReactions: Int {
        reactionCounts.values.reduce(0, +)
    }

    var mentions: [String] {
        // Extract @mentions from content
        let pattern = #"@(\w+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(
            in: content,
            range: NSRange(content.startIndex..., in: content)
        ) ?? []

        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[range])
        }
    }

    var attachmentDescription: String? {
        if let section = attachedToSection {
            if let line = attachedToLine {
                return "\(section), Line \(line)"
            }
            return section
        } else if let line = attachedToLine {
            return "Line \(line)"
        }
        return nil
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    // MARK: - Methods

    func edit(newContent: String) {
        self.content = newContent
        self.isEdited = true
        self.editedAt = Date()
    }

    func markResolved(by userRecordID: String) {
        self.isResolved = true
        self.resolvedBy = userRecordID
        self.resolvedAt = Date()
    }

    func markUnresolved() {
        self.isResolved = false
        self.resolvedBy = nil
        self.resolvedAt = nil
    }

    func addReaction(_ emoji: String) {
        reactionCounts[emoji, default: 0] += 1
    }

    func removeReaction(_ emoji: String) {
        if let count = reactionCounts[emoji], count > 0 {
            if count == 1 {
                reactionCounts.removeValue(forKey: emoji)
            } else {
                reactionCounts[emoji] = count - 1
            }
        }
    }

    // MARK: - CloudKit Conversion

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Comment")
        record["commentID"] = id.uuidString as CKRecordValue
        record["content"] = content as CKRecordValue
        record["authorRecordID"] = authorRecordID as CKRecordValue
        record["authorDisplayName"] = authorDisplayName as? CKRecordValue
        record["songID"] = songID.uuidString as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["isEdited"] = (isEdited ? 1 : 0) as CKRecordValue
        record["isResolved"] = (isResolved ? 1 : 0) as CKRecordValue

        if let libraryID = libraryID {
            record["libraryID"] = libraryID.uuidString as CKRecordValue
        }

        if let parentCommentID = parentCommentID {
            record["parentCommentID"] = parentCommentID.uuidString as CKRecordValue
        }

        if let editedAt = editedAt {
            record["editedAt"] = editedAt as CKRecordValue
        }

        if let attachedToLine = attachedToLine {
            record["attachedToLine"] = attachedToLine as CKRecordValue
        }

        if let attachedToSection = attachedToSection {
            record["attachedToSection"] = attachedToSection as CKRecordValue
        }

        if let resolvedBy = resolvedBy {
            record["resolvedBy"] = resolvedBy as CKRecordValue
        }

        if let resolvedAt = resolvedAt {
            record["resolvedAt"] = resolvedAt as CKRecordValue
        }

        // Store reaction counts as JSON
        if let jsonData = try? JSONEncoder().encode(reactionCounts),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            record["reactionCounts"] = jsonString as CKRecordValue
        }

        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> Comment? {
        guard let commentIDString = record["commentID"] as? String,
              let commentID = UUID(uuidString: commentIDString),
              let content = record["content"] as? String,
              let authorRecordID = record["authorRecordID"] as? String,
              let songIDString = record["songID"] as? String,
              let songID = UUID(uuidString: songIDString),
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        let comment = Comment(
            content: content,
            authorRecordID: authorRecordID,
            authorDisplayName: record["authorDisplayName"] as? String,
            songID: songID,
            libraryID: {
                guard let libraryIDString = record["libraryID"] as? String else { return nil }
                return UUID(uuidString: libraryIDString)
            }(),
            parentCommentID: {
                guard let parentIDString = record["parentCommentID"] as? String else { return nil }
                return UUID(uuidString: parentIDString)
            }(),
            attachedToLine: record["attachedToLine"] as? Int,
            attachedToSection: record["attachedToSection"] as? String
        )

        comment.id = commentID
        comment.createdAt = createdAt
        comment.isEdited = (record["isEdited"] as? Int) == 1
        comment.isResolved = (record["isResolved"] as? Int) == 1
        comment.editedAt = record["editedAt"] as? Date
        comment.resolvedBy = record["resolvedBy"] as? String
        comment.resolvedAt = record["resolvedAt"] as? Date

        // Parse reaction counts
        if let jsonString = record["reactionCounts"] as? String,
           let jsonData = jsonString.data(using: .utf8),
           let reactionCounts = try? JSONDecoder().decode([String: Int].self, from: jsonData) {
            comment.reactionCounts = reactionCounts
        }

        return comment
    }
}

// MARK: - Comment Reaction

/// Individual user's reaction to a comment
@Model
final class CommentReaction {
    var id: UUID
    var createdAt: Date

    var commentID: UUID
    var emoji: String
    var userRecordID: String
    var userDisplayName: String?

    init(
        commentID: UUID,
        emoji: String,
        userRecordID: String,
        userDisplayName: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.commentID = commentID
        self.emoji = emoji
        self.userRecordID = userRecordID
        self.userDisplayName = userDisplayName
    }

    // MARK: - CloudKit Conversion

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "CommentReaction")
        record["reactionID"] = id.uuidString as CKRecordValue
        record["commentID"] = commentID.uuidString as CKRecordValue
        record["emoji"] = emoji as CKRecordValue
        record["userRecordID"] = userRecordID as CKRecordValue
        record["userDisplayName"] = userDisplayName as? CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> CommentReaction? {
        guard let reactionIDString = record["reactionID"] as? String,
              let reactionID = UUID(uuidString: reactionIDString),
              let commentIDString = record["commentID"] as? String,
              let commentID = UUID(uuidString: commentIDString),
              let emoji = record["emoji"] as? String,
              let userRecordID = record["userRecordID"] as? String else {
            return nil
        }

        let reaction = CommentReaction(
            commentID: commentID,
            emoji: emoji,
            userRecordID: userRecordID,
            userDisplayName: record["userDisplayName"] as? String
        )

        reaction.id = reactionID
        if let createdAt = record["createdAt"] as? Date {
            reaction.createdAt = createdAt
        }

        return reaction
    }
}

// MARK: - Comment Thread

/// Helper structure for organizing comments into threads
struct CommentThread: Identifiable {
    let id: UUID
    let rootComment: Comment
    var replies: [Comment]

    var allComments: [Comment] {
        [rootComment] + replies
    }

    var totalCount: Int {
        allComments.count
    }

    var hasUnresolvedComments: Bool {
        allComments.contains { !$0.isResolved }
    }

    var latestActivity: Date {
        allComments.map { $0.editedAt ?? $0.createdAt }.max() ?? rootComment.createdAt
    }
}

// MARK: - Comment Filter

enum CommentFilter {
    case all
    case unresolvedOnly
    case resolvedOnly
    case byUser(String)
    case bySection(String)

    var displayName: String {
        switch self {
        case .all: return "All Comments"
        case .unresolvedOnly: return "Unresolved"
        case .resolvedOnly: return "Resolved"
        case .byUser(let name): return "By \(name)"
        case .bySection(let section): return section
        }
    }

    var icon: String {
        switch self {
        case .all: return "bubble.left.and.bubble.right"
        case .unresolvedOnly: return "exclamationmark.bubble"
        case .resolvedOnly: return "checkmark.bubble"
        case .byUser: return "person.circle"
        case .bySection: return "music.note"
        }
    }
}

// MARK: - Comment Sort

enum CommentSort {
    case newestFirst
    case oldestFirst
    case mostReactions
    case threadOrder

    var displayName: String {
        switch self {
        case .newestFirst: return "Newest First"
        case .oldestFirst: return "Oldest First"
        case .mostReactions: return "Most Reactions"
        case .threadOrder: return "Thread Order"
        }
    }
}
