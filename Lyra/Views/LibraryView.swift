//
//  LibraryView.swift
//  Lyra
//
//  Main library view with songs, books, and sets
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AVFoundation
import PDFKit

enum LibrarySection: String, CaseIterable {
    case allSongs = "All Songs"
    case books = "Books"
    case sets = "Sets"
}

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSection: LibrarySection = .allSongs
    @State private var showAddSongSheet: Bool = false
    @State private var showAddBookSheet: Bool = false
    @State private var showAddSetSheet: Bool = false

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
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Library Section", selection: $selectedSection) {
                    ForEach(LibrarySection.allCases, id: \.self) { section in
                        Text(section.rawValue)
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected section with smooth transition
                Group {
                    switch selectedSection {
                    case .allSongs:
                        SongListView()
                    case .books:
                        BookListView()
                    case .sets:
                        SetListView()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .animation(.easeInOut(duration: 0.3), value: selectedSection)
            }
            .navigationTitle("Library")
            .toolbar {
                // Search button
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSearch = true
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                }

                // Add button - Menu for Songs, simple button for Books/Sets
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedSection == .allSongs {
                        // Comprehensive add/import menu for songs
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
                    } else {
                        // Simple add button for Books and Sets
                        Button {
                            handleAddButton()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(selectedSection == .books ? "Add book" : "Add set")
                    }
                }
            }
            .sheet(isPresented: $showAddSongSheet) {
                AddSongView()
                    .iPadSheetPresentation(detents: [.large])
            }
            .sheet(isPresented: $showAddBookSheet) {
                AddBookView()
                    .iPadSheetPresentation()
            }
            .sheet(isPresented: $showAddSetSheet) {
                AddPerformanceSetView()
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
                ScanProcessingView(scannedImages: scannedImages)
            }
            .sheet(isPresented: $showCameraPermission) {
                CameraPermissionView()
            }
            .sheet(isPresented: $showPDFExtractor) {
                if let pdfDoc = pdfDocumentToExtract, let song = pdfImportSong {
                    ExtractTextFromPDFView(pdfDocument: pdfDoc, song: song)
                        .onDisappear {
                            handlePDFExtractionComplete()
                        }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.text, .plainText, .data, .pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .alert("Import Successful", isPresented: $showImportSuccess) {
                Button("View Song") {
                    navigateToImportedSong = true
                }
                Button("OK", role: .cancel) {}
            } message: {
                if let song = importedSong {
                    Text("Successfully imported \"\(song.title)\"")
                }
            }
            .alert("Import Failed", isPresented: $showImportError) {
                if let url = failedImportURL {
                    if url.pathExtension.lowercased() == "pdf" {
                        Button("Try PDF Extraction") {
                            importAsPlainText()
                        }
                    } else {
                        Button("Import as Plain Text") {
                            importAsPlainText()
                        }
                    }
                }
                Button("OK", role: .cancel) {
                    failedImportURL = nil
                }
            } message: {
                VStack {
                    Text(importErrorMessage)
                    if !importRecoverySuggestion.isEmpty {
                        Text(importRecoverySuggestion)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToImportedSong) {
                if let song = importedSong {
                    SongDisplayView(song: song)
                }
            }
            .navigationDestination(isPresented: $navigateToPastedSong) {
                if let song = pastedSong {
                    SongDisplayView(song: song)
                }
            }
            .alert("Paste Failed", isPresented: $showPasteError) {
                Button("OK", role: .cancel) {}
            } message: {
                VStack {
                    Text(pasteErrorMessage)
                    if !pasteRecoverySuggestion.isEmpty {
                        Text(pasteRecoverySuggestion)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showPasteToast {
                    ToastView(message: pasteToastMessage)
                        .padding(.top, 60)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7)),
                            removal: .move(edge: .top)
                                .combined(with: .opacity)
                                .animation(.easeInOut(duration: 0.2))
                        ))
                }
            }
            .overlay {
                if isImporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView(value: importProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                                .tint(.blue)

                            Text("Importing...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.2), radius: 10)
                        )
                    }
                }
            }
        }
    }

    /// Handle the add button based on current section
    private func handleAddButton() {
        switch selectedSection {
        case .allSongs:
            showAddSongSheet = true
        case .books:
            showAddBookSheet = true
        case .sets:
            showAddSetSheet = true
        }
    }

    // MARK: - File Import Handling

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFile(from: url)

        case .failure(let error):
            showError(
                message: "Unable to access file",
                recovery: error.localizedDescription
            )
        }
    }

    private func importFile(from url: URL) {
        isImporting = true
        importProgress = 0.0

        let fileExtension = url.pathExtension.lowercased()

        // Route PDF files through the PDF extraction flow
        if fileExtension == "pdf" {
            importPDFFile(from: url)
            return
        }

        do {
            // Start accessing security scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "Lyra", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
            }
            defer { url.stopAccessingSecurityScopedResource() }

            // Read file content
            let content = try String(contentsOf: url, encoding: .utf8)
            let filename = url.deletingPathExtension().lastPathComponent

            // Create song from content
            let song = Song(
                title: filename,
                content: content,
                contentFormat: .chordPro
            )
            song.importSource = "File Import"
            song.importedAt = Date()

            // Try to parse metadata from ChordPro directives
            parseChordProMetadata(from: content, into: song)

            // Insert into context
            modelContext.insert(song)
            try modelContext.save()

            importedSong = song
            isImporting = false
            HapticManager.shared.success()
            showImportSuccess = true

        } catch {
            isImporting = false
            failedImportURL = url
            HapticManager.shared.operationFailed()
            showError(
                message: "Import failed",
                recovery: error.localizedDescription
            )
        }
    }

    private func importPDFFile(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "Lyra", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
            }
            defer { url.stopAccessingSecurityScopedResource() }

            // Validate PDF using FileValidationUtility
            let validation = FileValidationUtility.shared.validateFile(at: url)
            if !validation.isValid, let error = validation.error {
                throw error
            }

            // Load PDF data fully into memory before security-scoped access ends
            let pdfData = try Data(contentsOf: url)
            guard let pdfDocument = PDFDocument(data: pdfData) else {
                throw PDFExtractionError.noPDFDocument
            }

            let filename = url.deletingPathExtension().lastPathComponent

            // Create a song placeholder that ExtractTextFromPDFView will populate
            let song = Song(
                title: filename,
                content: "",
                contentFormat: .chordPro
            )
            song.importSource = "PDF Import"
            song.importedAt = Date()

            modelContext.insert(song)
            try modelContext.save()

            // Store references for the extraction view
            pdfDocumentToExtract = pdfDocument
            pdfImportSong = song
            isImporting = false

            // Present the PDF extraction view
            showPDFExtractor = true

        } catch {
            isImporting = false
            failedImportURL = url
            HapticManager.shared.operationFailed()

            let message: String
            let recovery: String

            if let pdfError = error as? PDFExtractionError {
                message = pdfError.errorDescription ?? "PDF import failed"
                recovery = pdfError.recoverySuggestion ?? ""
            } else if let validationError = error as? FileValidationError {
                message = validationError.errorDescription ?? "PDF validation failed"
                recovery = validationError.recoverySuggestion ?? ""
            } else {
                message = "PDF import failed"
                recovery = error.localizedDescription
            }

            showError(message: message, recovery: recovery)
        }
    }

    private func handlePDFExtractionComplete() {
        if let song = pdfImportSong {
            // Check if extraction actually populated the song content
            if !song.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                importedSong = song
                HapticManager.shared.success()
                showImportSuccess = true
            } else {
                // User cancelled or extraction failed - remove the empty placeholder
                modelContext.delete(song)
                try? modelContext.save()
            }
        }

        // Clean up state
        pdfDocumentToExtract = nil
        pdfImportSong = nil
    }

    private func parseChordProMetadata(from content: String, into song: Song) {
        let lines = content.components(separatedBy: .newlines)

        for line in lines.prefix(50) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("{title:") || trimmed.hasPrefix("{t:") {
                if let value = extractDirectiveValue(from: trimmed) {
                    song.title = value
                }
            } else if trimmed.hasPrefix("{artist:") || trimmed.hasPrefix("{a:") {
                if let value = extractDirectiveValue(from: trimmed) {
                    song.artist = value
                }
            } else if trimmed.hasPrefix("{key:") || trimmed.hasPrefix("{k:") {
                if let value = extractDirectiveValue(from: trimmed) {
                    song.originalKey = value
                    song.currentKey = value
                }
            } else if trimmed.hasPrefix("{tempo:") {
                if let value = extractDirectiveValue(from: trimmed), let tempo = Int(value) {
                    song.tempo = tempo
                }
            } else if trimmed.hasPrefix("{capo:") {
                if let value = extractDirectiveValue(from: trimmed), let capo = Int(value) {
                    song.capo = capo
                }
            }
        }
    }

    private func extractDirectiveValue(from line: String) -> String? {
        guard let colonIndex = line.firstIndex(of: ":"),
              let closingBrace = line.lastIndex(of: "}") else {
            return nil
        }
        let startIndex = line.index(after: colonIndex)
        let value = String(line[startIndex..<closingBrace]).trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    private func importAsPlainText() {
        guard let url = failedImportURL else { return }

        let fileExtension = url.pathExtension.lowercased()

        // For PDFs, route through the PDF extraction flow instead
        if fileExtension == "pdf" {
            failedImportURL = nil
            importPDFFile(from: url)
            return
        }

        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "Lyra", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
            }
            defer { url.stopAccessingSecurityScopedResource() }

            // Try multiple encodings for text files
            var content: String?
            let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .windowsCP1252]
            for encoding in encodings {
                if let text = try? String(contentsOf: url, encoding: encoding) {
                    content = text
                    break
                }
            }

            guard let fileContent = content else {
                throw NSError(domain: "Lyra", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to read file with any supported encoding"])
            }

            let filename = url.deletingPathExtension().lastPathComponent

            let song = Song(
                title: filename,
                content: fileContent,
                contentFormat: .plainText
            )
            song.importSource = "Plain Text Import"
            song.importedAt = Date()

            modelContext.insert(song)
            try modelContext.save()

            importedSong = song
            failedImportURL = nil
            HapticManager.shared.success()
            showImportSuccess = true

        } catch {
            HapticManager.shared.operationFailed()
            showError(
                message: "Plain text import failed",
                recovery: error.localizedDescription
            )
        }
    }

    private func showError(message: String, recovery: String) {
        importErrorMessage = message
        importRecoverySuggestion = recovery
        showImportError = true
    }

    // MARK: - Paste Handling

    private func handlePaste() {
        do {
            let result = try ClipboardManager.shared.pasteSongFromClipboard(to: modelContext)
            pastedSong = result.song

            HapticManager.shared.success()

            // Show toast notification
            if result.wasUntitled {
                pasteToastMessage = "Song pasted as \"Untitled Song\""
            } else {
                pasteToastMessage = "Pasted \"\(result.song.title)\""
            }

            showPasteToast = true

            // Auto-dismiss toast after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showPasteToast = false
                }
            }

            // Navigate to pasted song after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                navigateToPastedSong = true
            }

        } catch let error as ClipboardError {
            HapticManager.shared.operationFailed()
            pasteErrorMessage = error.errorDescription ?? "Paste failed"
            pasteRecoverySuggestion = error.recoverySuggestion ?? ""
            showPasteError = true

        } catch {
            HapticManager.shared.operationFailed()
            pasteErrorMessage = "Paste failed"
            pasteRecoverySuggestion = error.localizedDescription
            showPasteError = true
        }
    }

    // MARK: - Scanner Handling

    private func checkCameraPermissionAndScan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Permission already granted
            showScanner = true

        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showScanner = true
                    } else {
                        showCameraPermission = true
                    }
                }
            }

        case .denied, .restricted:
            // Permission denied - show settings prompt
            showCameraPermission = true

        @unknown default:
            showCameraPermission = true
        }
    }
}

// MARK: - Toast Notification

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 20))

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Previews

#Preview("Library View") {
    LibraryView()
        .modelContainer(PreviewContainer.shared.container)
}
