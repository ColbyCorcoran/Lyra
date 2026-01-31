//
//  SongsTabView.swift
//  Lyra
//
//  Songs tab with import and management functionality
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AVFoundation
import PDFKit

struct SongsTabView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showAddSongSheet: Bool = false

    // Import state
    @State private var showFileImporter: Bool = false
    @State private var importedSong: Song?
    @State private var showImportSuccess: Bool = false
    @State private var showImportError: Bool = false
    @State private var importErrorMessage: String = ""
    @State private var importRecoverySuggestion: String = ""
    @State private var failedImportURL: URL?
    @State private var navigateToImportedSong: Bool = false
    @State private var isImporting: Bool = false
    @State private var importProgress: Double = 0.0

    // Paste state
    @State private var pastedSong: Song?
    @State private var showPasteToast: Bool = false
    @State private var pasteToastMessage: String = ""
    @State private var navigateToPastedSong: Bool = false
    @State private var showPasteError: Bool = false
    @State private var pasteErrorMessage: String = ""
    @State private var pasteRecoverySuggestion: String = ""

    // Search state
    @State private var showSearch: Bool = false

    // PDF extraction state
    @State private var showPDFExtractor: Bool = false
    @State private var pdfDocumentToExtract: PDFDocument?
    @State private var pdfImportSong: Song?

    // Scanner state
    @State private var showScanner: Bool = false
    @State private var showCameraPermission: Bool = false
    @State private var scannedImages: [UIImage] = []
    @State private var showScanProcessing: Bool = false

    var body: some View {
        NavigationStack {
            SongListView()
                .navigationTitle("Songs")
                .toolbar {
                    // Search button
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showSearch = true
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    }

                    // Add/Import menu
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            // New Song option
                            Button {
                                showAddSongSheet = true
                            } label: {
                                Label("New Song", systemImage: "music.note")
                            }

                            Divider()

                            // Import options
                            Button {
                                showFileImporter = true
                            } label: {
                                Label("Import from Files", systemImage: "folder")
                            }

                            Divider()

                            // Scan option
                            Button {
                                checkCameraPermissionAndScan()
                            } label: {
                                Label("Scan Paper Chart", systemImage: "doc.viewfinder")
                            }

                            Divider()

                            // Paste option
                            Button {
                                handlePaste()
                            } label: {
                                Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                            }
                            .disabled(!ClipboardManager.shared.hasClipboardContent())
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add or import song")
                    }
                }
        }
        .sheet(isPresented: $showAddSongSheet) {
            AddSongView()
                .iPadSheetPresentation(detents: [.large])
        }
        .sheet(isPresented: $showSearch) {
            LibrarySearchView()
                .iPadSheetPresentation(detents: [.large])
        }
        .sheet(isPresented: $showScanner) {
            DocumentScannerView { images in
                scannedImages = images
                showScanProcessing = true
            }
        }
        .sheet(isPresented: $showScanProcessing) {
            ScanProcessingView(images: scannedImages) { song in
                importedSong = song
                showImportSuccess = true
            }
        }
        .sheet(isPresented: $showPDFExtractor) {
            if let pdf = pdfDocumentToExtract {
                PDFTextExtractorView(pdfDocument: pdf) { extractedText in
                    handleExtractedPDFText(extractedText)
                }
            }
        }
        .sheet(isPresented: $showImportSuccess) {
            if let song = importedSong {
                NavigationStack {
                    SongDisplayView(song: song, setEntry: nil)
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.plainText, .text, .pdf, UTType(filenameExtension: "onsong") ?? .text, UTType(filenameExtension: "cho") ?? .text, UTType(filenameExtension: "chopro") ?? .text, UTType(filenameExtension: "pro") ?? .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Camera Permission Required", isPresented: $showCameraPermission) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings to scan paper charts.")
        }
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            VStack {
                Text(importErrorMessage)
                if !importRecoverySuggestion.isEmpty {
                    Text(importRecoverySuggestion)
                }
            }
        }
        .alert("Paste Error", isPresented: $showPasteError) {
            Button("OK", role: .cancel) { }
        } message: {
            VStack {
                Text(pasteErrorMessage)
                if !pasteRecoverySuggestion.isEmpty {
                    Text(pasteRecoverySuggestion)
                }
            }
        }
        .overlay {
            if showPasteToast {
                VStack {
                    Spacer()
                    ToastView(message: pasteToastMessage, type: .success)
                        .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Import Handling

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                showImportError(message: "Cannot access file", recovery: "Please try importing again")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            isImporting = true

            // Check file type
            if url.pathExtension.lowercased() == "pdf" {
                handlePDFImport(url: url)
            } else {
                handleTextImport(url: url)
            }
        case .failure(let error):
            showImportError(message: "Import failed", recovery: error.localizedDescription)
        }
    }

    private func handlePDFImport(url: URL) {
        guard let pdfDocument = PDFDocument(url: url) else {
            showImportError(message: "Cannot read PDF", recovery: "File may be corrupted")
            isImporting = false
            return
        }

        pdfDocumentToExtract = pdfDocument
        showPDFExtractor = true
        isImporting = false
    }

    private func handleTextImport(url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let filename = url.deletingPathExtension().lastPathComponent

            // Parse based on file extension
            let parser = ChordProParser()
            let result = try parser.parse(content)

            let song = Song(
                title: result.title ?? filename,
                artist: result.artist,
                content: content,
                contentFormat: .chordPro,
                originalKey: result.key
            )

            modelContext.insert(song)
            try modelContext.save()

            importedSong = song
            showImportSuccess = true
            isImporting = false
            HapticManager.shared.success()
        } catch {
            showImportError(message: "Import failed", recovery: error.localizedDescription)
            isImporting = false
        }
    }

    private func handleExtractedPDFText(_ text: String) {
        let song = Song(
            title: "Imported from PDF",
            content: text,
            contentFormat: .chordPro
        )

        modelContext.insert(song)
        do {
            try modelContext.save()
            pdfImportSong = song
            importedSong = song
            showImportSuccess = true
            HapticManager.shared.success()
        } catch {
            showImportError(message: "Failed to save song", recovery: error.localizedDescription)
        }
    }

    private func handlePaste() {
        let result = ClipboardManager.shared.importSongFromClipboard()

        switch result {
        case .success(let content):
            do {
                let parser = ChordProParser()
                let parseResult = try parser.parse(content)

                let song = Song(
                    title: parseResult.title ?? "Pasted Song",
                    artist: parseResult.artist,
                    content: content,
                    contentFormat: .chordPro,
                    originalKey: parseResult.key
                )

                modelContext.insert(song)
                try modelContext.save()

                pastedSong = song
                pasteToastMessage = "Song pasted successfully"
                showPasteToast = true
                HapticManager.shared.success()

                // Hide toast after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showPasteToast = false
                    }
                }
            } catch {
                showPasteError(message: "Failed to paste song", recovery: error.localizedDescription)
            }
        case .failure(let error):
            showPasteError(message: "Paste failed", recovery: error.localizedDescription)
        }
    }

    private func checkCameraPermissionAndScan() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    showScanner = true
                } else {
                    showCameraPermission = true
                }
            }
        }
    }

    private func showImportError(message: String, recovery: String) {
        importErrorMessage = message
        importRecoverySuggestion = recovery
        showImportError = true
        HapticManager.shared.error()
    }

    private func showPasteError(message: String, recovery: String) {
        pasteErrorMessage = message
        pasteRecoverySuggestion = recovery
        showPasteError = true
        HapticManager.shared.error()
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let type: ToastType

    enum ToastType {
        case success
        case error

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)

            Text(message)
                .font(.subheadline)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 10)
    }
}

#Preview {
    SongsTabView()
        .modelContainer(PreviewContainer.shared.container)
}
