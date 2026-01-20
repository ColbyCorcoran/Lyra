//
//  AttachmentsView.swift
//  Lyra
//
//  View for displaying and managing song attachments
//

import SwiftUI
import SwiftData
import QuickLook

struct AttachmentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let song: Song

    @State private var showAddAttachment: Bool = false
    @State private var showAttachmentDetail: Attachment?
    @State private var deleteConfirmation: Attachment?
    @State private var quickLookURL: URL?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    @StateObject private var attachmentManager = AttachmentManager.shared

    private var attachments: [Attachment] {
        song.attachments ?? []
    }

    private var sortedAttachments: [Attachment] {
        attachments.sorted { attachment1, attachment2 in
            // Default attachment first
            if attachment1.isDefault != attachment2.isDefault {
                return attachment1.isDefault
            }
            // Then by creation date
            return attachment1.createdAt > attachment2.createdAt
        }
    }

    private var totalStorage: Int64 {
        attachmentManager.calculateSongStorage(song)
    }

    var body: some View {
        NavigationStack {
            Group {
                if attachments.isEmpty {
                    emptyStateView
                } else {
                    attachmentListView
                }
            }
            .navigationTitle("Attachments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddAttachment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddAttachment) {
                AddAttachmentView(song: song)
            }
            .sheet(item: $showAttachmentDetail) { attachment in
                AttachmentDetailView(attachment: attachment, song: song)
            }
            .quickLookPreview($quickLookURL)
            .alert("Confirm Delete", isPresented: .constant(deleteConfirmation != nil)) {
                Button("Cancel", role: .cancel) {
                    deleteConfirmation = nil
                }
                Button("Delete", role: .destructive) {
                    if let attachment = deleteConfirmation {
                        deleteAttachment(attachment)
                    }
                }
            } message: {
                if let attachment = deleteConfirmation {
                    Text("Delete \"\(attachment.displayName)\"? This action cannot be undone.")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "paperclip")
                .font(.system(size: 64))
                .foregroundStyle(.gray)
                .padding(.top, 80)

            VStack(spacing: 12) {
                Text("No Attachments")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add PDFs, images, or audio files to keep multiple versions or arrangements")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                showAddAttachment = true
            } label: {
                Label("Add Attachment", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    // MARK: - Attachment List

    @ViewBuilder
    private var attachmentListView: some View {
        List {
            // Storage Summary
            Section {
                HStack {
                    Image(systemName: "externaldrive")
                        .foregroundStyle(.blue)
                    Text("Total Storage")
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: totalStorage, countStyle: .file))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.blue)
                    Text("Attachments")
                    Spacer()
                    Text("\(attachments.count)")
                        .foregroundStyle(.secondary)
                }
            }

            // Attachments List
            Section {
                ForEach(sortedAttachments) { attachment in
                    AttachmentRowView(attachment: attachment)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openAttachment(attachment)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteConfirmation = attachment
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if !attachment.isDefault {
                                Button {
                                    setAsDefault(attachment)
                                } label: {
                                    Label("Set Default", systemImage: "star.fill")
                                }
                                .tint(.yellow)
                            }

                            Button {
                                showAttachmentDetail = attachment
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                openAttachment(attachment)
                            } label: {
                                Label("View", systemImage: "eye")
                            }

                            Button {
                                showAttachmentDetail = attachment
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }

                            if !attachment.isDefault {
                                Button {
                                    setAsDefault(attachment)
                                } label: {
                                    Label("Set as Default", systemImage: "star.fill")
                                }
                            }

                            Divider()

                            Button {
                                duplicateAttachment(attachment)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }

                            Divider()

                            Button(role: .destructive) {
                                deleteConfirmation = attachment
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text("Files")
            } footer: {
                Text("Tap to view, swipe for actions. Default attachment marked with ★")
            }
        }
    }

    // MARK: - Actions

    private func openAttachment(_ attachment: Attachment) {
        do {
            let url = try attachmentManager.getFileURL(for: attachment)
            quickLookURL = url
        } catch {
            errorMessage = "Failed to open attachment: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.operationFailed()
        }
    }

    private func setAsDefault(_ attachment: Attachment) {
        do {
            try attachmentManager.setDefaultAttachment(attachment, for: song, modelContext: modelContext)
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to set default: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.operationFailed()
        }
    }

    private func duplicateAttachment(_ attachment: Attachment) {
        do {
            // Load original data
            let data = try attachmentManager.loadAttachment(attachment)

            // Create duplicate
            let duplicate = attachment.duplicate()

            // Save data
            _ = try attachmentManager.saveAttachment(duplicate, data: data)

            // Add to song
            if song.attachments == nil {
                song.attachments = []
            }
            song.attachments?.append(duplicate)

            modelContext.insert(duplicate)
            try modelContext.save()

            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to duplicate: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.operationFailed()
        }
    }

    private func deleteAttachment(_ attachment: Attachment) {
        do {
            // Delete file
            try attachmentManager.deleteAttachment(attachment)

            // Remove from song
            song.attachments?.removeAll { $0.id == attachment.id }

            // Delete from context
            modelContext.delete(attachment)
            try modelContext.save()

            deleteConfirmation = nil
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            showError = true
            deleteConfirmation = nil
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Attachment Row

struct AttachmentRowView: View {
    let attachment: Attachment

    var body: some View {
        HStack(spacing: 12) {
            // File icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: attachment.fileIcon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(attachment.displayName)
                        .font(.body)
                        .lineLimit(1)

                    if attachment.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                HStack(spacing: 8) {
                    Text(attachment.formattedFileSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let source = attachment.originalSource {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: attachment.sourceIcon)
                                .font(.caption2)

                            Text(source)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if let versionName = attachment.versionName {
                    Text(versionName)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var iconColor: Color {
        switch attachment.fileCategory {
        case .pdf: return .red
        case .image: return .blue
        case .audio: return .purple
        case .video: return .orange
        case .other: return .gray
        }
    }
}

// MARK: - Preview

#Preview("With Attachments") {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

    // Add sample attachments
    let attachment1 = Attachment(
        filename: "Original Chart.pdf",
        fileType: "pdf",
        fileSize: 245_000,
        versionName: "Original",
        originalSource: "Files"
    )
    attachment1.isDefault = true

    let attachment2 = Attachment(
        filename: "Transposed to C.pdf",
        fileType: "pdf",
        fileSize: 240_000,
        versionName: "Transposed to C",
        originalSource: "Files"
    )

    let attachment3 = Attachment(
        filename: "Simplified Version.pdf",
        fileType: "pdf",
        fileSize: 180_000,
        versionName: "Simplified",
        originalSource: "Camera Scan"
    )

    song.attachments = [attachment1, attachment2, attachment3]

    return AttachmentsView(song: song)
        .modelContainer(container)
}

#Preview("Empty") {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!
    song.attachments = []

    return AttachmentsView(song: song)
        .modelContainer(container)
}
