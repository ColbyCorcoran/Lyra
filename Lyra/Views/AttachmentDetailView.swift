//
//  AttachmentDetailView.swift
//  Lyra
//
//  Detail view for viewing and managing individual attachments
//

import SwiftUI
import SwiftData
import QuickLook

struct AttachmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let attachment: Attachment
    let song: Song

    @State private var editedFilename: String
    @State private var editedVersionName: String
    @State private var editedNotes: String
    @State private var showRenameSheet: Bool = false
    @State private var showVersionNameSheet: Bool = false
    @State private var showNotesSheet: Bool = false
    @State private var showReplaceFile: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showCompressionOptions: Bool = false
    @State private var isCompressing: Bool = false
    @State private var compressionQuality: PDFCompressionQuality = .medium
    @State private var quickLookURL: URL?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    @StateObject private var attachmentManager = AttachmentManager.shared

    init(attachment: Attachment, song: Song) {
        self.attachment = attachment
        self.song = song
        _editedFilename = State(initialValue: attachment.filename)
        _editedVersionName = State(initialValue: attachment.versionName ?? "")
        _editedNotes = State(initialValue: attachment.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Preview Section
                Section {
                    Button {
                        openAttachment()
                    } label: {
                        HStack {
                            Image(systemName: "eye")
                                .foregroundStyle(.blue)
                            Text("View Attachment")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Preview")
                }

                // Details Section
                Section {
                    HStack {
                        Image(systemName: "doc")
                            .foregroundStyle(.blue)
                        Text("Filename")
                        Spacer()
                        Text(attachment.filename)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "tag")
                            .foregroundStyle(.blue)
                        Text("File Type")
                        Spacer()
                        Text(".\(attachment.fileType.uppercased())")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundStyle(.blue)
                        Text("File Size")
                        Spacer()
                        Text(attachment.formattedFileSize)
                            .foregroundStyle(.secondary)
                    }

                    if let source = attachment.originalSource {
                        HStack {
                            Image(systemName: attachment.sourceIcon)
                                .foregroundStyle(.blue)
                            Text("Source")
                            Spacer()
                            Text(source)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                        Text("Added")
                        Spacer()
                        Text(attachment.createdAt, style: .relative)
                            .foregroundStyle(.secondary)
                    }

                    if attachment.modifiedAt != attachment.createdAt {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.blue)
                            Text("Modified")
                            Spacer()
                            Text(attachment.modifiedAt, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Details")
                }

                // Metadata Section
                Section {
                    Button {
                        showVersionNameSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "text.badge.star")
                                .foregroundStyle(.blue)
                            Text("Version Name")
                            Spacer()
                            if let versionName = attachment.versionName, !versionName.isEmpty {
                                Text(versionName)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("None")
                                    .foregroundStyle(.tertiary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

                    Button {
                        showNotesSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundStyle(.blue)
                            Text("Notes")
                            Spacer()
                            if let notes = attachment.notes, !notes.isEmpty {
                                Text(notes.prefix(20))
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("None")
                                    .foregroundStyle(.tertiary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Metadata")
                } footer: {
                    Text("Add a version name and notes to help identify this attachment")
                }

                // Properties Section
                Section {
                    Toggle(isOn: Binding(
                        get: { attachment.isDefault },
                        set: { newValue in
                            if newValue {
                                setAsDefault()
                            }
                        }
                    )) {
                        Label("Default Attachment", systemImage: "star.fill")
                    }
                    .tint(.yellow)
                } header: {
                    Text("Properties")
                } footer: {
                    Text("The default attachment is shown first and used for quick access")
                }

                // Actions Section
                Section {
                    Button {
                        showRenameSheet = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    Button {
                        showReplaceFile = true
                    } label: {
                        Label("Replace File", systemImage: "arrow.triangle.2.circlepath")
                    }

                    if attachment.fileType.lowercased() == "pdf" && attachment.fileSize > 1_000_000 {
                        Button {
                            showCompressionOptions = true
                        } label: {
                            Label("Compress PDF", systemImage: "arrow.down.circle")
                        }
                    }
                } header: {
                    Text("Actions")
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Attachment", systemImage: "trash")
                    }
                } header: {
                    Text("Danger Zone")
                }
            }
            .navigationTitle("Attachment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRenameSheet) {
                RenameAttachmentView(filename: $editedFilename) {
                    renameAttachment()
                }
            }
            .sheet(isPresented: $showVersionNameSheet) {
                EditVersionNameView(versionName: $editedVersionName) {
                    updateVersionName()
                }
            }
            .sheet(isPresented: $showNotesSheet) {
                EditNotesView(notes: $editedNotes) {
                    updateNotes()
                }
            }
            .fileImporter(
                isPresented: $showReplaceFile,
                allowedContentTypes: [.pdf, .image, .audio],
                allowsMultipleSelection: false
            ) { result in
                handleReplaceFile(result: result)
            }
            .quickLookPreview($quickLookURL)
            .alert("Compress PDF", isPresented: $showCompressionOptions) {
                Button("Cancel", role: .cancel) {}
                Button("Low Quality (50%)") {
                    compressionQuality = .low
                    compressPDF()
                }
                Button("Medium Quality (70%)") {
                    compressionQuality = .medium
                    compressPDF()
                }
                Button("High Quality (85%)") {
                    compressionQuality = .high
                    compressPDF()
                }
            } message: {
                Text("Choose compression quality. Lower quality results in smaller file size.")
            }
            .alert("Delete Attachment?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAttachment()
                }
            } message: {
                Text("This will permanently delete \"\(attachment.displayName)\". This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isCompressing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)

                            Text("Compressing PDF...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func openAttachment() {
        do {
            let url = try attachmentManager.getFileURL(for: attachment)
            quickLookURL = url
        } catch {
            errorMessage = "Failed to open attachment: \(error.localizedDescription)"
            showError = true
        }
    }

    private func setAsDefault() {
        do {
            try attachmentManager.setDefaultAttachment(attachment, for: song, modelContext: modelContext)
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to set as default: \(error.localizedDescription)"
            showError = true
        }
    }

    private func renameAttachment() {
        attachmentManager.renameAttachment(attachment, newName: editedFilename)
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to rename: \(error.localizedDescription)"
            showError = true
        }
    }

    private func updateVersionName() {
        attachmentManager.updateVersionName(
            attachment,
            versionName: editedVersionName.isEmpty ? nil : editedVersionName
        )
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to update version name: \(error.localizedDescription)"
            showError = true
        }
    }

    private func updateNotes() {
        attachment.notes = editedNotes.isEmpty ? nil : editedNotes
        attachment.touch()
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to update notes: \(error.localizedDescription)"
            showError = true
        }
    }

    private func handleReplaceFile(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Failed to access file"
                showError = true
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                try attachmentManager.replaceAttachment(attachment, with: data)
                try modelContext.save()
                HapticManager.shared.success()
            } catch {
                errorMessage = "Failed to replace file: \(error.localizedDescription)"
                showError = true
            }

        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
            showError = true
        }
    }

    private func compressPDF() {
        isCompressing = true

        Task {
            do {
                let originalSize = attachment.fileSize
                let newSize = try attachmentManager.compressPDF(attachment: attachment, quality: compressionQuality)

                let savedBytes = originalSize - newSize
                let savedPercent = Double(savedBytes) / Double(originalSize) * 100

                try modelContext.save()

                await MainActor.run {
                    isCompressing = false
                    HapticManager.shared.success()

                    if savedBytes > 0 {
                        errorMessage = "Compressed successfully! Saved \(ByteCountFormatter.string(fromByteCount: Int64(savedBytes), countStyle: .file)) (\(String(format: "%.0f%%", savedPercent)))"
                        showError = true
                    } else {
                        errorMessage = "File is already well compressed"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isCompressing = false
                    errorMessage = "Compression failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func deleteAttachment() {
        do {
            try attachmentManager.deleteAttachment(attachment)
            song.attachments?.removeAll { $0.id == attachment.id }
            modelContext.delete(attachment)
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Rename View

struct RenameAttachmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filename: String
    let onSave: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Filename", text: $filename)
                        .focused($isTextFieldFocused)
                } footer: {
                    Text("Enter a new name for this attachment")
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(filename.isEmpty)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Edit Version Name View

struct EditVersionNameView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var versionName: String
    let onSave: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Version Name", text: $versionName)
                        .focused($isTextFieldFocused)
                } header: {
                    Text("Version Name")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Give this attachment a descriptive name")

                        Text("Examples:")
                            .fontWeight(.semibold)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("• Original")
                            Text("• Transposed to C")
                            Text("• Simplified Version")
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Version Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                        onSave()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Edit Notes View

struct EditNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notes: String
    let onSave: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .focused($isTextFieldFocused)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add notes about this attachment (e.g., what makes this version different, when to use it)")
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                        onSave()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

    let attachment = Attachment(
        filename: "Original Chart.pdf",
        fileType: "pdf",
        fileSize: 245_000,
        versionName: "Original",
        originalSource: "Files"
    )
    attachment.isDefault = true
    attachment.notes = "This is the original chart as received from the worship leader."

    return AttachmentDetailView(attachment: attachment, song: song)
        .modelContainer(container)
}
