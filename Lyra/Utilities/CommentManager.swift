//
//  CommentManager.swift
//  Lyra
//
//  Manages comments with CloudKit synchronization and real-time updates
//

import Foundation
import SwiftData
import CloudKit
import Combine

@MainActor
@Observable
class CommentManager {
    static let shared = CommentManager()

    // MARK: - Published Properties

    var comments: [Comment] = []
    var reactions: [CommentReaction] = []
    var typingUsers: [String: Date] = [:] // userRecordID -> last typing time

    // MARK: - Private Properties

    private let container = CKContainer.default()
    private lazy var sharedDatabase = container.sharedCloudDatabase
    private var subscriptions: Set<AnyCancellable> = []

    private init() {
        setupCommentObservers()
    }

    // MARK: - Setup

    private func setupCommentObservers() {
        // Subscribe to comment notifications
        Task {
            await subscribeToCommentChanges()
        }
    }

    // MARK: - Fetching Comments

    /// Fetches all comments for a song
    func fetchComments(for songID: UUID) async throws -> [Comment] {
        let predicate = NSPredicate(format: "songID == %@", songID.uuidString)
        let query = CKQuery(recordType: "Comment", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        do {
            let results = try await sharedDatabase.records(matching: query)

            var fetchedComments: [Comment] = []

            for (_, result) in results.matchResults {
                if let record = try? result.get(),
                   let comment = Comment.fromCKRecord(record) {
                    fetchedComments.append(comment)
                }
            }

            await MainActor.run {
                self.comments = fetchedComments
            }

            return fetchedComments
        } catch {
            print("❌ Error fetching comments: \(error)")
            throw error
        }
    }

    /// Fetches reactions for specific comments
    func fetchReactions(for commentIDs: [UUID]) async throws -> [CommentReaction] {
        let commentIDStrings = commentIDs.map { $0.uuidString }
        let predicate = NSPredicate(format: "commentID IN %@", commentIDStrings)
        let query = CKQuery(recordType: "CommentReaction", predicate: predicate)

        do {
            let results = try await sharedDatabase.records(matching: query)

            var fetchedReactions: [CommentReaction] = []

            for (_, result) in results.matchResults {
                if let record = try? result.get(),
                   let reaction = CommentReaction.fromCKRecord(record) {
                    fetchedReactions.append(reaction)
                }
            }

            await MainActor.run {
                self.reactions = fetchedReactions
            }

            return fetchedReactions
        } catch {
            print("❌ Error fetching reactions: \(error)")
            throw error
        }
    }

    // MARK: - Creating Comments

    /// Adds a new comment
    func addComment(
        _ comment: Comment,
        modelContext: ModelContext
    ) async throws {
        // Insert into SwiftData
        modelContext.insert(comment)
        try modelContext.save()

        // Sync to CloudKit
        let record = comment.toCKRecord()

        do {
            _ = try await sharedDatabase.save(record)

            // Add to local cache
            await MainActor.run {
                comments.append(comment)
            }

            // Send notifications for mentions
            await notifyMentionedUsers(in: comment)

            // Post notification
            NotificationCenter.default.post(
                name: .commentAdded,
                object: nil,
                userInfo: ["comment": comment]
            )

            print("✅ Comment added successfully")
        } catch {
            print("❌ Error saving comment to CloudKit: \(error)")
            throw error
        }
    }

    /// Replies to an existing comment
    func replyToComment(
        parentCommentID: UUID,
        content: String,
        authorRecordID: String,
        authorDisplayName: String?,
        songID: UUID,
        libraryID: UUID?,
        modelContext: ModelContext
    ) async throws {
        let reply = Comment(
            content: content,
            authorRecordID: authorRecordID,
            authorDisplayName: authorDisplayName,
            songID: songID,
            libraryID: libraryID,
            parentCommentID: parentCommentID
        )

        try await addComment(reply, modelContext: modelContext)

        // Notify parent comment author
        if let parentComment = comments.first(where: { $0.id == parentCommentID }) {
            await notifyCommentReply(reply: reply, to: parentComment)
        }
    }

    // MARK: - Editing Comments

    /// Edits an existing comment
    func editComment(
        _ comment: Comment,
        newContent: String,
        modelContext: ModelContext
    ) async throws {
        comment.edit(newContent: newContent)

        try modelContext.save()

        // Sync to CloudKit
        let record = comment.toCKRecord()

        do {
            _ = try await sharedDatabase.save(record)

            print("✅ Comment edited successfully")
        } catch {
            print("❌ Error editing comment in CloudKit: \(error)")
            throw error
        }
    }

    // MARK: - Deleting Comments

    /// Deletes a comment
    func deleteComment(
        _ comment: Comment,
        modelContext: ModelContext
    ) async throws {
        // Remove from SwiftData
        modelContext.delete(comment)
        try modelContext.save()

        // Delete from CloudKit
        let record = comment.toCKRecord()

        do {
            try await sharedDatabase.delete(withRecordID: record.recordID)

            // Remove from local cache
            await MainActor.run {
                comments.removeAll { $0.id == comment.id }
            }

            print("✅ Comment deleted successfully")
        } catch {
            print("❌ Error deleting comment from CloudKit: \(error)")
            throw error
        }
    }

    // MARK: - Resolving Comments

    /// Marks a comment as resolved
    func resolveComment(
        _ comment: Comment,
        resolvedBy: String,
        modelContext: ModelContext
    ) async throws {
        comment.markResolved(by: resolvedBy)

        try modelContext.save()

        // Sync to CloudKit
        let record = comment.toCKRecord()

        do {
            _ = try await sharedDatabase.save(record)

            print("✅ Comment resolved")
        } catch {
            print("❌ Error resolving comment: \(error)")
            throw error
        }
    }

    /// Marks a comment as unresolved
    func unresolveComment(
        _ comment: Comment,
        modelContext: ModelContext
    ) async throws {
        comment.markUnresolved()

        try modelContext.save()

        // Sync to CloudKit
        let record = comment.toCKRecord()

        do {
            _ = try await sharedDatabase.save(record)

            print("✅ Comment unresolved")
        } catch {
            print("❌ Error unresolving comment: \(error)")
            throw error
        }
    }

    // MARK: - Reactions

    /// Adds a reaction to a comment
    func addReaction(
        to comment: Comment,
        emoji: String,
        userRecordID: String,
        userDisplayName: String?,
        modelContext: ModelContext
    ) async throws {
        // Check if user already reacted with this emoji
        let existingReaction = reactions.first {
            $0.commentID == comment.id &&
            $0.emoji == emoji &&
            $0.userRecordID == userRecordID
        }

        if existingReaction != nil {
            // User already reacted, remove reaction
            try await removeReaction(emoji, from: comment, userRecordID: userRecordID, modelContext: modelContext)
            return
        }

        // Create new reaction
        let reaction = CommentReaction(
            commentID: comment.id,
            emoji: emoji,
            userRecordID: userRecordID,
            userDisplayName: userDisplayName
        )

        modelContext.insert(reaction)
        try modelContext.save()

        // Sync to CloudKit
        let record = reaction.toCKRecord()

        do {
            _ = try await sharedDatabase.save(record)

            // Update comment reaction counts
            comment.addReaction(emoji)
            try modelContext.save()

            // Add to local cache
            await MainActor.run {
                reactions.append(reaction)
            }

            print("✅ Reaction added")
        } catch {
            print("❌ Error adding reaction: \(error)")
            throw error
        }
    }

    /// Removes a reaction from a comment
    func removeReaction(
        _ emoji: String,
        from comment: Comment,
        userRecordID: String,
        modelContext: ModelContext
    ) async throws {
        // Find the reaction
        guard let reaction = reactions.first(where: {
            $0.commentID == comment.id &&
            $0.emoji == emoji &&
            $0.userRecordID == userRecordID
        }) else {
            return
        }

        // Remove from SwiftData
        modelContext.delete(reaction)
        try modelContext.save()

        // Delete from CloudKit
        let record = reaction.toCKRecord()

        do {
            try await sharedDatabase.delete(withRecordID: record.recordID)

            // Update comment reaction counts
            comment.removeReaction(emoji)
            try modelContext.save()

            // Remove from local cache
            await MainActor.run {
                reactions.removeAll { $0.id == reaction.id }
            }

            print("✅ Reaction removed")
        } catch {
            print("❌ Error removing reaction: \(error)")
            throw error
        }
    }

    // MARK: - Typing Indicators

    /// Updates typing status
    func updateTypingStatus(userRecordID: String, isTyping: Bool) {
        if isTyping {
            typingUsers[userRecordID] = Date()
        } else {
            typingUsers.removeValue(forKey: userRecordID)
        }

        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .typingStatusChanged,
            object: nil,
            userInfo: ["userRecordID": userRecordID, "isTyping": isTyping]
        )
    }

    /// Gets list of currently typing users
    func getTypingUsers() -> [String] {
        let fiveSecondsAgo = Date().addingTimeInterval(-5)
        return typingUsers.filter { $0.value > fiveSecondsAgo }.map { $0.key }
    }

    // MARK: - Organizing Comments

    /// Organizes comments into threads
    func organizeIntoThreads(_ comments: [Comment]) -> [CommentThread] {
        // Find root comments (no parent)
        let rootComments = comments.filter { !$0.isReply }

        // Build threads
        var threads: [CommentThread] = []

        for rootComment in rootComments {
            let replies = comments.filter { $0.parentCommentID == rootComment.id }
                .sorted { $0.createdAt < $1.createdAt }

            let thread = CommentThread(
                id: rootComment.id,
                rootComment: rootComment,
                replies: replies
            )

            threads.append(thread)
        }

        return threads
    }

    /// Filters comments based on criteria
    func filterComments(_ comments: [Comment], by filter: CommentFilter) -> [Comment] {
        switch filter {
        case .all:
            return comments
        case .unresolvedOnly:
            return comments.filter { !$0.isResolved }
        case .resolvedOnly:
            return comments.filter { $0.isResolved }
        case .byUser(let userRecordID):
            return comments.filter { $0.authorRecordID == userRecordID }
        case .bySection(let section):
            return comments.filter { $0.attachedToSection == section }
        }
    }

    /// Sorts comments
    func sortComments(_ comments: [Comment], by sort: CommentSort) -> [Comment] {
        switch sort {
        case .newestFirst:
            return comments.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return comments.sorted { $0.createdAt < $1.createdAt }
        case .mostReactions:
            return comments.sorted { $0.totalReactions > $1.totalReactions }
        case .threadOrder:
            // Group by threads, then by time
            let threads = organizeIntoThreads(comments)
            return threads.flatMap { $0.allComments }
        }
    }

    // MARK: - Notifications

    private func notifyMentionedUsers(in comment: Comment) async {
        let mentions = comment.mentions

        for mention in mentions {
            // Create notification for mentioned user
            let notification = CollaborationNotification(
                id: UUID(),
                type: .mentionedYou,
                title: "You were mentioned",
                body: "\(comment.authorDisplayName ?? "Someone") mentioned you in a comment",
                timestamp: Date(),
                relatedSongID: comment.songID,
                relatedLibraryID: comment.libraryID
            )

            // Send push notification
            CollaborationNotificationManager.shared.sendPushNotification(notification)

            print("✅ Notified @\(mention)")
        }
    }

    private func notifyCommentReply(reply: Comment, to parentComment: Comment) async {
        // Don't notify if replying to own comment
        guard reply.authorRecordID != parentComment.authorRecordID else { return }

        let notification = CollaborationNotification(
            id: UUID(),
            type: .commentAdded,
            title: "New reply",
            body: "\(reply.authorDisplayName ?? "Someone") replied to your comment",
            timestamp: Date(),
            relatedSongID: reply.songID,
            relatedLibraryID: reply.libraryID
        )

        CollaborationNotificationManager.shared.sendPushNotification(notification)

        print("✅ Notified parent comment author")
    }

    // MARK: - CloudKit Subscriptions

    private func subscribeToCommentChanges() async {
        let subscription = CKQuerySubscription(
            recordType: "Comment",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            try await sharedDatabase.save(subscription)
            print("✅ Subscribed to comment changes")
        } catch {
            print("❌ Error subscribing to comments: \(error)")
        }

        // Subscribe to reactions
        let reactionSubscription = CKQuerySubscription(
            recordType: "CommentReaction",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordDeletion]
        )

        reactionSubscription.notificationInfo = notificationInfo

        do {
            try await sharedDatabase.save(reactionSubscription)
            print("✅ Subscribed to reaction changes")
        } catch {
            print("❌ Error subscribing to reactions: \(error)")
        }
    }

    /// Handles comment change notification from CloudKit
    func handleCommentChange(notification: CKNotification) async {
        guard let queryNotification = notification as? CKQueryNotification,
              let recordID = queryNotification.recordID else {
            return
        }

        do {
            let record = try await sharedDatabase.record(for: recordID)

            if let comment = Comment.fromCKRecord(record) {
                // Update local cache
                if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                    comments[index] = comment
                } else {
                    comments.append(comment)
                }

                // Post notification
                NotificationCenter.default.post(
                    name: .commentChanged,
                    object: nil,
                    userInfo: ["comment": comment]
                )
            }
        } catch {
            print("❌ Error fetching comment record: \(error)")
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let commentAdded = Notification.Name("commentAdded")
    static let commentChanged = Notification.Name("commentChanged")
    static let typingStatusChanged = Notification.Name("typingStatusChanged")
}
