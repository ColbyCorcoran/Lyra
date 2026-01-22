//
//  CommentRow.swift
//  Lyra
//
//  Individual comment display with threading, reactions, and actions
//

import SwiftUI

struct CommentRow: View {
    let comment: Comment
    let level: Int // 0 = root, 1 = reply
    let onReply: (Comment) -> Void
    let onEdit: (Comment) -> Void
    let onDelete: (Comment) -> Void
    let onResolve: (Comment) -> Void
    let onReact: (Comment, String) -> Void

    @State private var showReactionPicker: Bool = false
    @State private var showActions: Bool = false

    private let presenceManager = PresenceManager.shared

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Indent for replies
            if level > 0 {
                Color.clear
                    .frame(width: CGFloat(level * 32))
            }

            // Author avatar
            Circle()
                .fill(authorColor)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(authorInitials)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            // Comment content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 8) {
                    Text(comment.authorDisplayName ?? "Anonymous")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(comment.relativeTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if comment.isEdited {
                        Text("(edited)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Resolved badge
                    if comment.isResolved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Resolved")
                                .font(.caption2)
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                // Attachment badge
                if let attachment = comment.attachmentDescription {
                    HStack(spacing: 4) {
                        Image(systemName: "paperclip")
                            .font(.caption2)
                        Text(attachment)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }

                // Content with markdown formatting
                Text(formattedContent)
                    .font(.body)
                    .textSelection(.enabled)

                // Reactions
                if comment.hasReactions {
                    ReactionsBar(
                        reactions: comment.reactionCounts,
                        onReact: { emoji in
                            onReact(comment, emoji)
                        }
                    )
                }

                // Actions
                HStack(spacing: 16) {
                    // Reply button
                    Button {
                        onReply(comment)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrowshape.turn.up.left")
                            Text("Reply")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    // React button
                    Button {
                        showReactionPicker.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "face.smiling")
                            Text("React")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showReactionPicker) {
                        ReactionPickerView { emoji in
                            onReact(comment, emoji)
                            showReactionPicker = false
                        }
                    }

                    // More actions
                    Button {
                        showActions = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Comment Actions", isPresented: $showActions) {
                        // Resolve/Unresolve
                        Button(comment.isResolved ? "Mark as Unresolved" : "Mark as Resolved") {
                            onResolve(comment)
                        }

                        // Edit (only own comments)
                        if isOwnComment {
                            Button("Edit") {
                                onEdit(comment)
                            }
                        }

                        // Delete (own comments or admin)
                        if canDeleteComment {
                            Button("Delete", role: .destructive) {
                                onDelete(comment)
                            }
                        }

                        Button("Cancel", role: .cancel) {}
                    }

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed Properties

    private var authorInitials: String {
        (comment.authorDisplayName ?? "?")
            .components(separatedBy: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }

    private var authorColor: Color {
        // Generate color based on author ID
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo]
        let hash = comment.authorRecordID.hashValue
        return colors[abs(hash) % colors.count]
    }

    private var backgroundColor: Color {
        if comment.isResolved {
            return Color.green.opacity(0.05)
        } else if level > 0 {
            return Color(.systemGray6).opacity(0.5)
        } else {
            return Color(.systemBackground)
        }
    }

    private var formattedContent: AttributedString {
        // Convert markdown to attributed string
        var attributedString = try? AttributedString(
            markdown: comment.content,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )

        // Highlight @mentions
        if let text = attributedString {
            for mention in comment.mentions {
                if let range = text.range(of: "@\(mention)") {
                    attributedString?[range].foregroundColor = .blue
                    attributedString?[range].font = .body.bold()
                }
            }
        }

        return attributedString ?? AttributedString(comment.content)
    }

    private var isOwnComment: Bool {
        comment.authorRecordID == presenceManager.currentUserPresence?.userRecordID
    }

    private var canDeleteComment: Bool {
        // Can delete own comments or if admin
        isOwnComment // TODO: Add admin check
    }
}

// MARK: - Reactions Bar

struct ReactionsBar: View {
    let reactions: [String: Int]
    let onReact: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sortedReactions, id: \.emoji) { reaction in
                    Button {
                        onReact(reaction.emoji)
                    } label: {
                        HStack(spacing: 4) {
                            Text(reaction.emoji)
                                .font(.body)

                            Text("\(reaction.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sortedReactions: [(emoji: String, count: Int)] {
        reactions
            .map { (emoji: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Reaction Picker View

struct ReactionPickerView: View {
    let onSelect: (String) -> Void

    private let commonEmojis = ["👍", "❤️", "🎵", "🎸", "🎤", "🙏", "🔥", "✨", "👏", "🎹"]

    var body: some View {
        VStack(spacing: 0) {
            Text("Add Reaction")
                .font(.headline)
                .padding()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(commonEmojis, id: \.self) { emoji in
                    Button {
                        onSelect(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 32))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .frame(width: 300)
        .presentationDetents([.height(200)])
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        // Root comment
        CommentRow(
            comment: {
                let comment = Comment(
                    content: "This is a **great** song! Check out @john's arrangement.",
                    authorRecordID: "user1",
                    authorDisplayName: "Jane Doe",
                    songID: UUID()
                )
                comment.reactionCounts = ["👍": 5, "❤️": 3]
                return comment
            }(),
            level: 0,
            onReply: { _ in },
            onEdit: { _ in },
            onDelete: { _ in },
            onResolve: { _ in },
            onReact: { _, _ in }
        )

        // Reply comment
        CommentRow(
            comment: {
                let comment = Comment(
                    content: "Thanks! I'll try that in practice.",
                    authorRecordID: "user2",
                    authorDisplayName: "John Smith",
                    songID: UUID(),
                    parentCommentID: UUID()
                )
                return comment
            }(),
            level: 1,
            onReply: { _ in },
            onEdit: { _ in },
            onDelete: { _ in },
            onResolve: { _ in },
            onReact: { _, _ in }
        )

        // Resolved comment
        CommentRow(
            comment: {
                let comment = Comment(
                    content: "Fixed the key signature.",
                    authorRecordID: "user3",
                    authorDisplayName: "Admin",
                    songID: UUID()
                )
                comment.markResolved(by: "user1")
                return comment
            }(),
            level: 0,
            onReply: { _ in },
            onEdit: { _ in },
            onDelete: { _ in },
            onResolve: { _ in },
            onReact: { _, _ in }
        )
    }
    .padding()
}
