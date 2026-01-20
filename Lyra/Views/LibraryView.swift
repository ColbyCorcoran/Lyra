//
//  LibraryView.swift
//  Lyra
//
//  Main library view with songs, books, and sets
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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

    // Stats state
    @State private var showLibraryStats: Bool = false

    // Search state
    @State private var showSearch: Bool = false

    // Dropbox import state
    @State private var showDropboxImport: Bool = false
    @StateObject private var dropboxManager = DropboxManager.shared

    // Google Drive import state
    @State private var showGoogleDriveImport: Bool = false
    @StateObject private var driveManager = GoogleDriveManager.shared

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

                // Stats button
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showLibraryStats = true
                    } label: {
                        Label("Statistics", systemImage: "chart.bar.fill")
                    }
                }

                // Import menu (Songs only)
                if selectedSection == .allSongs {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                showFileImporter = true
                            } label: {
                                Label("Import from Files", systemImage: "folder")
                            }

                            if dropboxManager.isAuthenticated {
                                Button {
                                    showDropboxImport = true
                                } label: {
                                    Label("Import from Dropbox", systemImage: "cloud")
                                }
                            } else {
                                Button {
                                    // Show connection message or navigate to settings
                                    showDropboxImport = true
                                } label: {
                                    Label("Connect Dropbox...", systemImage: "cloud")
                                }
                            }

                            if driveManager.isAuthenticated {
                                Button {
                                    showGoogleDriveImport = true
                                } label: {
                                    Label("Import from Google Drive", systemImage: "internaldrive")
                                }
                            } else {
                                Button {
                                    // Show connection message or navigate to settings
                                    showGoogleDriveImport = true
                                } label: {
                                    Label("Connect Google Drive...", systemImage: "internaldrive")
                                }
                            }
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                    }
                }

                // Paste button (Songs only)
                if selectedSection == .allSongs {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            handlePaste()
                        } label: {
                            Label("Paste", systemImage: "doc.on.clipboard")
                        }
                        .disabled(!ClipboardManager.shared.hasClipboardContent())
                    }
                }

                // Add button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handleAddButton()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSongSheet) {
                AddSongView()
            }
            .sheet(isPresented: $showAddBookSheet) {
                AddBookView()
            }
            .sheet(isPresented: $showAddSetSheet) {
                AddPerformanceSetView()
            }
            .sheet(isPresented: $showLibraryStats) {
                LibraryStatsView()
            }
            .sheet(isPresented: $showSearch) {
                LibrarySearchView()
            }
            .sheet(isPresented: $showDropboxImport) {
                if dropboxManager.isAuthenticated {
                    DropboxImportView()
                } else {
                    DropboxAuthView()
                }
            }
            .sheet(isPresented: $showGoogleDriveImport) {
                if driveManager.isAuthenticated {
                    GoogleDriveImportView()
                } else {
                    GoogleDriveAuthView()
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: ImportManager.supportedTypes,
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
                if failedImportURL != nil {
                    Button("Import as Plain Text") {
                        importAsPlainText()
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

        do {
            let result = try ImportManager.shared.importFile(
                from: url,
                to: modelContext,
                progress: { progress in
                    importProgress = progress
                }
            )

            importedSong = result.song
            isImporting = false

            if result.hadParsingWarnings {
                HapticManager.shared.warning()
                // Show warning but still treat as success
                showError(
                    message: "Import completed with warnings",
                    recovery: "The file was imported but some ChordPro formatting may not have been recognized."
                )
            } else {
                HapticManager.shared.success()
                showImportSuccess = true
            }

        } catch let error as ImportError {
            isImporting = false
            failedImportURL = url
            HapticManager.shared.operationFailed()
            showError(
                message: error.errorDescription ?? "Import failed",
                recovery: error.recoverySuggestion ?? ""
            )

        } catch {
            isImporting = false
            HapticManager.shared.operationFailed()
            showError(
                message: "Import failed",
                recovery: error.localizedDescription
            )
        }
    }

    private func importAsPlainText() {
        guard let url = failedImportURL else { return }

        do {
            let result = try ImportManager.shared.importAsPlainText(
                from: url,
                to: modelContext
            )

            importedSong = result.song
            failedImportURL = nil
            showImportSuccess = true

        } catch {
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
