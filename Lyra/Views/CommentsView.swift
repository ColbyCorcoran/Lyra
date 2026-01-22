//
//  CommentsView.swift
//  Lyra
//
//  Main view for displaying and managing song comments
//

import SwiftUI
import SwiftData

struct CommentsView: View {
    let song: Song

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allComments: [Comment]
    @Query private var allReactions: [CommentReaction]

    @State private var commentManager = CommentManager.shared
    @State private var presenceManager = PresenceManager.shared

    @State private var selectedFilter: CommentFilter = .all
    @State private var selectedSort: CommentSort = .threadOrder
    @State private var searchText: String = ""
    @State private var showAddComment: Bool = false
    @State private var replyingTo: Comment?
    @State private var editingComment: Comment?
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter and sort bar
                filterSortBar

                // Comments list
                if isLoading {
                    loadingView
                } else if filteredComments.isEmpty {
                    emptyState
                } else {
                    commentsList
                }

                // Add comment button
                addCommentButton
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach([CommentFilter.all, .unresolvedOnly, .resolvedOnly], id: \.displayName) { filter in
                                Label(filter.displayName, systemImage: filter.icon)
                                    .tag(filter)
                            }
                        }

                        Picker("Sort", selection: $selectedSort) {
                            ForEach([CommentSort.threadOrder, .newestFirst, .oldestFirst, .mostReactions], id: \.displayName) { sort in
                                Text(sort.displayName)
                                    .tag(sort)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await loadComments()

                // Listen for comment changes
                NotificationCenter.default.addObserver(
                    forName: .commentAdded,
                    object: nil,
                    queue: .main
                ) { _ in
                    Task {
                        await loadComments()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search comments")
            .sheet(isPresented: $showAddComment) {
                AddCommentView(
                    song: song,
                    replyingTo: replyingTo,
                    editingComment: editingComment
                )
            }
        }
    }

    // MARK: - Filter and Sort Bar

    private var filterSortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Comment count
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.caption)
                    Text("\(songComments.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)

                Divider()
                    .frame(height: 20)

                // Quick filters
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter.displayName == "All Comments"
                ) {
                    selectedFilter = .all
                }

                FilterChip(
                    title: "Unresolved",
                    isSelected: selectedFilter.displayName == "Unresolved"
                ) {
                    selectedFilter = .unresolvedOnly
                }

                FilterChip(
                    title: "Resolved",
                    isSelected: selectedFilter.displayName == "Resolved"
                ) {
                    selectedFilter = .resolvedOnly
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Comments List

    private var commentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12, pinnedViews: []) {
                // Group comments into threads
                if selectedSort == .threadOrder {
                    ForEach(commentThreads) { thread in
                        CommentThreadView(
                            thread: thread,
                            onReply: { comment in
                                replyingTo = comment
                                showAddComment = true
                            },
                            onEdit: { comment in
                                editingComment = comment
                                showAddComment = true
                            },
                            onDelete: { comment in
                                Task {
                                    await deleteComment(comment)
                                }
                            },
                            onResolve: { comment in
                                Task {
                                    await toggleResolve(comment)
                                }
                            },
                            onReact: { comment, emoji in
                                Task {
                                    await reactToComment(comment, emoji: emoji)
                                }
                            }
                        )
                    }
                } else {
                    // Show comments individually (not threaded)
                    ForEach(sortedComments) { comment in
                        CommentRow(
                            comment: comment,
                            level: 0,
                            onReply: { comment in
                                replyingTo = comment
                                showAddComment = true
                            },
                            onEdit: { comment in
                                editingComment = comment
                                showAddComment = true
                            },
                            onDelete: { comment in
                                Task {
                                    await deleteComment(comment)
                                }
                            },
                            onResolve: { comment in
                                Task {
                                    await toggleResolve(comment)
                                }
                            },
                            onReact: { comment, emoji in
                                Task {
                                    await reactToComment(comment, emoji: emoji)
                                }
                            }
                        )
                    }
                }

                // Typing indicators
                if !typingUsers.isEmpty {
                    TypingIndicatorView(users: typingUsers)
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("No Comments Yet")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Start the conversation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading comments...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Add Comment Button

    private var addCommentButton: some View {
        Button {
            replyingTo = nil
            editingComment = nil
            showAddComment = true
        } label: {
            HStack {
                Image(systemName: "plus.bubble")
                Text("Add Comment")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Properties

    private var songComments: [Comment] {
        allComments.filter { $0.songID == song.id }
    }

    private var filteredComments: [Comment] {
        var comments = songComments

        // Apply search filter
        if !searchText.isEmpty {
            comments = comments.filter {
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                ($0.authorDisplayName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply selected filter
        comments = commentManager.filterComments(comments, by: selectedFilter)

        return comments
    }

    private var sortedComments: [Comment] {
        commentManager.sortComments(filteredComments, by: selectedSort)
    }

    private var commentThreads: [CommentThread] {
        commentManager.organizeIntoThreads(filteredComments)
            .sorted { thread1, thread2 in
                switch selectedSort {
                case .newestFirst:
                    return thread1.latestActivity > thread2.latestActivity
                case .oldestFirst:
                    return thread1.latestActivity < thread2.latestActivity
                case .mostReactions:
                    return thread1.rootComment.totalReactions > thread2.rootComment.totalReactions
                case .threadOrder:
                    return thread1.rootComment.createdAt < thread2.rootComment.createdAt
                }
            }
    }

    private var typingUsers: [String] {
        commentManager.getTypingUsers()
            .filter { $0 != presenceManager.currentUserPresence?.userRecordID }
    }

    // MARK: - Actions

    private func loadComments() async {
        isLoading = true
        do {
            let comments = try await commentManager.fetchComments(for: song.id)
            let commentIDs = comments.map { $0.id }
            _ = try await commentManager.fetchReactions(for: commentIDs)
        } catch {
            print("❌ Error loading comments: \(error)")
        }
        isLoading = false
    }

    private func deleteComment(_ comment: Comment) async {
        do {
            try await commentManager.deleteComment(comment, modelContext: modelContext)
            HapticManager.shared.success()
        } catch {
            print("❌ Error deleting comment: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func toggleResolve(_ comment: Comment) async {
        guard let currentUser = presenceManager.currentUserPresence else { return }

        do {
            if comment.isResolved {
                try await commentManager.unresolveComment(comment, modelContext: modelContext)
            } else {
                try await commentManager.resolveComment(
                    comment,
                    resolvedBy: currentUser.userRecordID,
                    modelContext: modelContext
                )
            }
            HapticManager.shared.success()
        } catch {
            print("❌ Error toggling resolve: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func reactToComment(_ comment: Comment, emoji: String) async {
        guard let currentUser = presenceManager.currentUserPresence else { return }

        do {
            try await commentManager.addReaction(
                to: comment,
                emoji: emoji,
                userRecordID: currentUser.userRecordID,
                userDisplayName: currentUser.displayName,
                modelContext: modelContext
            )
            HapticManager.shared.selection()
        } catch {
            print("❌ Error reacting to comment: \(error)")
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Comment Thread View

struct CommentThreadView: View {
    let thread: CommentThread
    let onReply: (Comment) -> Void
    let onEdit: (Comment) -> Void
    let onDelete: (Comment) -> Void
    let onResolve: (Comment) -> Void
    let onReact: (Comment, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Root comment
            CommentRow(
                comment: thread.rootComment,
                level: 0,
                onReply: onReply,
                onEdit: onEdit,
                onDelete: onDelete,
                onResolve: onResolve,
                onReact: onReact
            )

            // Replies
            if !thread.replies.isEmpty {
                ForEach(thread.replies) { reply in
                    CommentRow(
                        comment: reply,
                        level: 1,
                        onReply: onReply,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onResolve: onResolve,
                        onReact: onReact
                    )
                }
            }
        }
    }
}

// MARK: - Typing Indicator View

struct TypingIndicatorView: View {
    let users: [String]

    var body: some View {
        HStack(spacing: 8) {
            // Animated dots
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: index
                        )
                }
            }

            Text(typingText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var typingText: String {
        if users.count == 1 {
            return "\(users[0]) is typing..."
        } else if users.count == 2 {
            return "\(users[0]) and \(users[1]) are typing..."
        } else {
            return "\(users[0]) and \(users.count - 1) others are typing..."
        }
    }
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace")
    return CommentsView(song: song)
        .modelContainer(for: [Comment.self, CommentReaction.self], inMemory: true)
}
