//
//  AddAttachmentView.swift
//  Lyra
//
//  View for adding attachments from various sources
//

import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct AddAttachmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let song: Song

    @State private var selectedSource: AttachmentSource?
    @State private var showFileImporter: Bool = false
    @State private var showCamera: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showDropboxPicker: Bool = false
    @State private var showDrivePicker: Bool = false
    @State private var showVersionNamePrompt: Bool = false
    @State private var versionName: String = ""
    @State private var pendingImport: PendingImport?
    @State private var isImporting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []

    @StateObject private var attachmentManager = AttachmentManager.shared

    enum AttachmentSource {
        case files
        case camera
        case photos
        case dropbox
        case googleDrive
    }

    struct PendingImport {
        let url: URL
        let filename: String
        let fileType: String
        let source: String
    }

    var body: some View {
        NavigationStack {
            formContent
        }
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            localSourcesSection
            cloudSourcesSection
            fileTypesInfoSection
        }
        .navigationTitle("Add Attachment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image, .audio],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 1,
            matching: .images
        )
        .onChange(of: selectedPhotos) { oldValue, newValue in
            handlePhotoSelection(newValue)
        }
        .sheet(isPresented: $showCamera) {
            cameraSheet
        }
        .sheet(isPresented: $showVersionNamePrompt) {
            versionNameSheet
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            importingOverlay
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var cameraSheet: some View {
        DocumentScannerView { images in
            handleScannedImages(images)
            showCamera = false
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var localSourcesSection: some View {
        Section {
            Button {
                selectedSource = .files
                showFileImporter = true
            } label: {
                SourceRow(
                    icon: "folder",
                    title: "Files",
                    description: "Import from Files app or iCloud Drive",
                    color: .blue
                )
            }

            Button {
                checkCameraPermissionAndShow()
            } label: {
                SourceRow(
                    icon: "camera",
                    title: "Camera",
                    description: "Take a photo or scan a document",
                    color: .gray
                )
            }

            Button {
                selectedSource = .photos
                showPhotoPicker = true
            } label: {
                SourceRow(
                    icon: "photo.on.rectangle",
                    title: "Photos",
                    description: "Choose from your photo library",
                    color: .purple
                )
            }
        } header: {
            Text("Local Sources")
        }
    }

    @ViewBuilder
    private var cloudSourcesSection: some View {
        Section {
            Button {
                selectedSource = .dropbox
                showDropboxPicker = true
            } label: {
                SourceRow(
                    icon: "cloud",
                    title: "Dropbox",
                    description: "Import from Dropbox",
                    color: .blue
                )
            }

            Button {
                selectedSource = .googleDrive
                showDrivePicker = true
            } label: {
                SourceRow(
                    icon: "internaldrive",
                    title: "Google Drive",
                    description: "Import from Google Drive",
                    color: .green
                )
            }
        } header: {
            Text("Cloud Sources")
        }
    }

    @ViewBuilder
    private var fileTypesInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Supported file types:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("• PDF documents")
                    Text("• Images (JPG, PNG, HEIC)")
                    Text("• Audio files (MP3, M4A, WAV)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("File Types")
        }
    }

    @ViewBuilder
    private var versionNameSheet: some View {
        VersionNamePromptView(
            versionName: $versionName,
            onSave: {
                if let pending = pendingImport {
                    importAttachment(
                        from: pending.url,
                        filename: pending.filename,
                        fileType: pending.fileType,
                        source: pending.source
                    )
                }
            },
            onCancel: {
                // Import without version name
                if let pending = pendingImport {
                    versionName = ""
                    importAttachment(
                        from: pending.url,
                        filename: pending.filename,
                        fileType: pending.fileType,
                        source: pending.source
                    )
                }
            }
        )
    }

    @ViewBuilder
    private var importingOverlay: some View {
        if isImporting {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)

                    Text("Importing attachment...")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(32)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Actions

    private func checkCameraPermissionAndShow() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            selectedSource = .camera
            showCamera = true

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        selectedSource = .camera
                        showCamera = true
                    } else {
                        errorMessage = "Camera access is required to scan documents"
                        showError = true
                    }
                }
            }

        default:
            errorMessage = "Camera access is denied. Please enable it in Settings."
            showError = true
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Failed to access file"
                showError = true
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            let filename = url.lastPathComponent
            let fileType = url.pathExtension.lowercased()

            // Store for import
            pendingImport = PendingImport(
                url: url,
                filename: filename,
                fileType: fileType,
                source: "Files"
            )

            // Prompt for version name
            showVersionNamePrompt = true

        case .failure(let error):
            errorMessage = "Failed to import: \(error.localizedDescription)"
            showError = true
        }
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard let item = items.first else { return }

        isImporting = true

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        errorMessage = "Failed to load image"
                        showError = true
                        isImporting = false
                    }
                    return
                }

                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).jpg")
                try data.write(to: tempURL)

                await MainActor.run {
                    pendingImport = PendingImport(
                        url: tempURL,
                        filename: "Photo.jpg",
                        fileType: "jpg",
                        source: "Photos"
                    )
                    isImporting = false
                    showVersionNamePrompt = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to import photo: \(error.localizedDescription)"
                    showError = true
                    isImporting = false
                }
            }
        }
    }

    private func handleScannedImages(_ images: [UIImage]) {
        guard let image = images.first else { return }

        isImporting = true

        Task {
            // Convert to PDF
            let pdfData = createPDF(from: images)

            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).pdf")

            do {
                try pdfData.write(to: tempURL)

                await MainActor.run {
                    pendingImport = PendingImport(
                        url: tempURL,
                        filename: "Scanned Document.pdf",
                        fileType: "pdf",
                        source: "Camera Scan"
                    )
                    isImporting = false
                    showCamera = false
                    showVersionNamePrompt = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save scan: \(error.localizedDescription)"
                    showError = true
                    isImporting = false
                }
            }
        }
    }

    private func importAttachment(
        from url: URL,
        filename: String,
        fileType: String,
        source: String
    ) {
        isImporting = true

        Task {
            do {
                // Import attachment
                let attachment = try attachmentManager.importAttachment(
                    from: url,
                    filename: filename,
                    fileType: fileType,
                    versionName: versionName.isEmpty ? nil : versionName,
                    source: source
                )

                // Add to song
                if song.attachments == nil {
                    song.attachments = []
                }

                // Set as default if first attachment
                if song.attachments?.isEmpty == true {
                    attachment.isDefault = true
                }

                song.attachments?.append(attachment)

                // Save to context
                modelContext.insert(attachment)
                try modelContext.save()

                await MainActor.run {
                    isImporting = false
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to import: \(error.localizedDescription)"
                    showError = true
                    isImporting = false
                }
            }
        }
    }

    private func createPDF(from images: [UIImage]) -> Data {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)

        for image in images {
            let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)

            guard let context = UIGraphicsGetCurrentContext() else { continue }

            // Calculate aspect fit
            let imageAspect = image.size.width / image.size.height
            let pageAspect = pageRect.width / pageRect.height

            var drawRect: CGRect
            if imageAspect > pageAspect {
                // Image is wider
                let height = pageRect.width / imageAspect
                let y = (pageRect.height - height) / 2
                drawRect = CGRect(x: 0, y: y, width: pageRect.width, height: height)
            } else {
                // Image is taller
                let width = pageRect.height * imageAspect
                let x = (pageRect.width - width) / 2
                drawRect = CGRect(x: x, y: 0, width: width, height: pageRect.height)
            }

            image.draw(in: drawRect)
        }

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}

// MARK: - Source Row

struct SourceRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Version Name Prompt

struct VersionNamePromptView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var versionName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Version Name (optional)", text: $versionName)
                        .focused($isTextFieldFocused)
                } header: {
                    Text("Name This Version")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Give this attachment a descriptive name to help identify it later.")

                        Text("Examples:")
                            .fontWeight(.semibold)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("• Original")
                            Text("• Transposed to C")
                            Text("• Simplified Version")
                            Text("• With Capo 2")
                            Text("• Lead Sheet")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Version Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                        onCancel()
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

    return AddAttachmentView(song: song)
        .modelContainer(container)
}
