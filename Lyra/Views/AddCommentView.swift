//
//  AddCommentView.swift
//  Lyra
//
//  View for adding or editing comments with markdown support and @mentions
//

import SwiftUI
import SwiftData

struct AddCommentView: View {
    let song: Song
    var replyingTo: Comment?
    var editingComment: Comment?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var commentText: String = ""
    @State private var selectedSection: String?
    @State private var attachedLine: Int?
    @State private var showSectionPicker: Bool = false
    @State private var showMentionPicker: Bool = false
    @State private var mentionSearchText: String = ""
    @State private var isSubmitting: Bool = false

    private let commentManager = CommentManager.shared
    private let presenceManager = PresenceManager.shared

    private let characterLimit = 500

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                // Editor
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Reply context
                        if let replyingTo = replyingTo {
                            replyContextView(replyingTo)
                        }

                        // Text editor
                        textEditorView

                        // Markdown formatting help
                        markdownHelpView

                        // Attachment section
                        attachmentSectionView

                        // Character count
                        characterCountView
                    }
                    .padding()
                }

                Divider()

                // Bottom toolbar
                bottomToolbar
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmButtonTitle) {
                        Task {
                            await submitComment()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSubmit || isSubmitting)
                }
            }
            .onAppear {
                if let editingComment = editingComment {
                    commentText = editingComment.content
                    selectedSection = editingComment.attachedToSection
                    attachedLine = editingComment.attachedToLine
                }
            }
            .onChange(of: commentText) { oldValue, newValue in
                // Detect @mention trigger
                checkForMentionTrigger(newValue)

                // Update typing status
                commentManager.updateTypingStatus(
                    userRecordID: presenceManager.currentUserPresence?.userRecordID ?? "",
                    isTyping: !newValue.isEmpty
                )
            }
            .sheet(isPresented: $showMentionPicker) {
                MentionPickerView(
                    searchText: mentionSearchText,
                    libraryID: song.sharedLibrary?.id
                ) { selectedUser in
                    insertMention(selectedUser)
                    showMentionPicker = false
                }
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(song.title)
                .font(.headline)

            if let artist = song.artist {
                Text(artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
    }

    // MARK: - Reply Context View

    private func replyContextView(_ comment: Comment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrowshape.turn.up.left")
                    .foregroundStyle(.secondary)
                Text("Replying to \(comment.authorDisplayName ?? "Anonymous")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(comment.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .padding(.leading, 20)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Text Editor View

    private var textEditorView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comment")
                .font(.subheadline)
                .fontWeight(.medium)

            TextEditor(text: $commentText)
                .font(.body)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(focusedBorderColor, lineWidth: 1)
                )
        }
    }

    // MARK: - Markdown Help View

    private var markdownHelpView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Formatting")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                FormattingHintView(icon: "bold", text: "**bold**")
                FormattingHintView(icon: "italic", text: "*italic*")
                FormattingHintView(icon: "link", text: "[link](url)")
                FormattingHintView(icon: "at", text: "@mention")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Attachment Section View

    private var attachmentSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attach to Section (Optional)")
                .font(.subheadline)
                .fontWeight(.medium)

            Button {
                showSectionPicker.toggle()
            } label: {
                HStack {
                    Image(systemName: "music.note")
                    Text(selectedSection ?? "Select section...")
                        .foregroundStyle(selectedSection == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSectionPicker) {
                SectionPickerView(selectedSection: $selectedSection)
            }

            if selectedSection != nil {
                Button(role: .destructive) {
                    selectedSection = nil
                    attachedLine = nil
                } label: {
                    Text("Remove attachment")
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Character Count View

    private var characterCountView: some View {
        HStack {
            Spacer()
            Text("\(commentText.count) / \(characterLimit)")
                .font(.caption)
                .foregroundStyle(isOverCharacterLimit ? .red : .secondary)
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            // Quick format buttons
            Button {
                insertFormatting("**", "**")
            } label: {
                Image(systemName: "bold")
            }

            Button {
                insertFormatting("*", "*")
            } label: {
                Image(systemName: "italic")
            }

            Button {
                insertFormatting("[", "](url)")
            } label: {
                Image(systemName: "link")
            }

            Button {
                showMentionPicker = true
            } label: {
                Image(systemName: "at")
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        if editingComment != nil {
            return "Edit Comment"
        } else if replyingTo != nil {
            return "Reply"
        } else {
            return "Add Comment"
        }
    }

    private var confirmButtonTitle: String {
        if editingComment != nil {
            return "Save"
        } else {
            return "Post"
        }
    }

    private var canSubmit: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isOverCharacterLimit
    }

    private var isOverCharacterLimit: Bool {
        commentText.count > characterLimit
    }

    private var focusedBorderColor: Color {
        isOverCharacterLimit ? .red : .clear
    }

    // MARK: - Actions

    private func submitComment() async {
        guard let currentUser = presenceManager.currentUserPresence else {
            print("❌ No current user presence")
            return
        }

        isSubmitting = true

        do {
            if let editingComment = editingComment {
                // Edit existing comment
                try await commentManager.editComment(
                    editingComment,
                    newContent: commentText,
                    modelContext: modelContext
                )
            } else if let replyingTo = replyingTo {
                // Reply to comment
                try await commentManager.replyToComment(
                    parentCommentID: replyingTo.id,
                    content: commentText,
                    authorRecordID: currentUser.userRecordID,
                    authorDisplayName: currentUser.displayName,
                    songID: song.id,
                    libraryID: song.sharedLibrary?.id,
                    modelContext: modelContext
                )
            } else {
                // Create new comment
                let comment = Comment(
                    content: commentText,
                    authorRecordID: currentUser.userRecordID,
                    authorDisplayName: currentUser.displayName,
                    songID: song.id,
                    libraryID: song.sharedLibrary?.id,
                    attachedToLine: attachedLine,
                    attachedToSection: selectedSection
                )

                try await commentManager.addComment(comment, modelContext: modelContext)
            }

            // Stop typing indicator
            commentManager.updateTypingStatus(
                userRecordID: currentUser.userRecordID,
                isTyping: false
            )

            HapticManager.shared.success()
            dismiss()
        } catch {
            print("❌ Error submitting comment: \(error)")
            HapticManager.shared.operationFailed()
        }

        isSubmitting = false
    }

    private func insertFormatting(_ prefix: String, _ suffix: String) {
        commentText += prefix + suffix
        // TODO: Move cursor between prefix and suffix
    }

    private func checkForMentionTrigger(_ text: String) {
        // Check if user just typed @ followed by a letter
        if text.hasSuffix("@") || (text.contains("@") && text.last?.isLetter == true) {
            // Extract the mention search text
            if let atIndex = text.lastIndex(of: "@") {
                let afterAt = text[text.index(after: atIndex)...]
                mentionSearchText = String(afterAt)
                if mentionSearchText.count > 0 && mentionSearchText.count < 20 {
                    showMentionPicker = true
                }
            }
        }
    }

    private func insertMention(_ userName: String) {
        // Find the last @ and replace text after it
        if let atIndex = commentText.lastIndex(of: "@") {
            let beforeAt = commentText[..<atIndex]
            commentText = String(beforeAt) + "@\(userName) "
        }
    }
}

// MARK: - Formatting Hint View

struct FormattingHintView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
                .font(.system(.caption, design: .monospaced))
        }
    }
}

// MARK: - Section Picker View

struct SectionPickerView: View {
    @Binding var selectedSection: String?

    private let sections = [
        "Intro",
        "Verse 1",
        "Verse 2",
        "Verse 3",
        "Chorus",
        "Bridge",
        "Outro",
        "Solo",
        "Pre-Chorus",
        "Tag"
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("Select Section")
                .font(.headline)
                .padding()

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(sections, id: \.self) { section in
                        Button {
                            selectedSection = section
                        } label: {
                            HStack {
                                Text(section)
                                    .font(.body)

                                Spacer()

                                if selectedSection == section {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
            }
        }
        .frame(width: 250, height: 400)
        .presentationDetents([.height(400)])
    }
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace", artist: "John Newton")
    return AddCommentView(song: song)
        .modelContainer(for: [Comment.self], inMemory: true)
}
