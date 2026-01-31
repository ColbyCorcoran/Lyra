//
//  OnSongImportView.swift
//  Lyra
//
//  UI for importing OnSong files and folders
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct OnSongImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showFilePicker = false
    @State private var showFolderPicker = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var importedCount: Int = 0
    @State private var totalFiles: Int = 0
    @State private var showError = false
    @State private var errorMessage: String = ""
    @State private var showSuccess = false
    @State private var successMessage: String = ""
    @State private var importedSongs: [Song] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("Import from OnSong")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Import your existing OnSong library using the Files app")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)

                    // Import Options
                    VStack(spacing: 16) {
                        // Single File Import
                        ImportOptionCard(
                            icon: "doc.fill",
                            title: "Import Single File",
                            description: "Import one OnSong file (.onsong, .txt, .pro, .chopro)",
                            color: .blue
                        ) {
                            showFilePicker = true
                        }

                        // Folder Import
                        ImportOptionCard(
                            icon: "folder.fill",
                            title: "Import Folder",
                            description: "Import an entire folder of OnSong files",
                            color: .green
                        ) {
                            showFolderPicker = true
                        }

                        // Cloud Storage Info
                        InfoCard(
                            icon: "icloud.fill",
                            title: "Cloud Storage Access",
                            description: "Access Dropbox, Google Drive, or other cloud storage through the Files app. Make sure your cloud service is configured in iOS Settings.",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // Import Progress
                    if isImporting {
                        VStack(spacing: 16) {
                            ProgressView(value: importProgress, total: 1.0)
                                .progressViewStyle(.linear)

                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)

                                Text("Importing \(importedCount) of \(totalFiles) files...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Recently Imported
                    if !importedSongs.isEmpty && !isImporting {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recently Imported")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(importedSongs.prefix(5)) { song in
                                HStack {
                                    Image(systemName: "music.note")
                                        .foregroundStyle(.green)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(song.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        if let artist = song.artist {
                                            Text(artist)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("OnSong Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.text, .plainText, UTType(filenameExtension: "onsong") ?? .text],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .fileImporter(
                isPresented: $showFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                handleFolderImport(result)
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Import Complete", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
            .disabled(isImporting)
        }
    }

    // MARK: - Import Handlers

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await importFiles(urls)
            }
        case .failure(let error):
            errorMessage = "Failed to access files: \(error.localizedDescription)"
            showError = true
        }
    }

    private func handleFolderImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let folderURL = urls.first else { return }
            Task {
                await importFolder(folderURL)
            }
        case .failure(let error):
            errorMessage = "Failed to access folder: \(error.localizedDescription)"
            showError = true
        }
    }

    private func importFiles(_ urls: [URL]) async {
        isImporting = true
        importedCount = 0
        totalFiles = urls.count
        importProgress = 0
        importedSongs = []

        for (index, url) in urls.enumerated() {
            do {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    print("⚠️ Could not access: \(url.lastPathComponent)")
                    continue
                }
                defer { url.stopAccessingSecurityScopedResource() }

                let content = try String(contentsOf: url, encoding: .utf8)

                // Parse OnSong content
                let parser = OnSongParser()
                let result = try parser.parseOnSongFile(content: content, filename: url.lastPathComponent)

                // Create song in database
                let song = Song(
                    title: result.title ?? url.deletingPathExtension().lastPathComponent,
                    artist: result.artist,
                    content: result.content,
                    contentFormat: .chordPro,
                    originalKey: result.key
                )

                // Set additional metadata
                if let tempo = result.tempo {
                    song.tempo = tempo
                }
                if let timeSignature = result.timeSignature {
                    song.timeSignature = timeSignature
                }

                modelContext.insert(song)
                importedSongs.append(song)
                importedCount += 1
                importProgress = Double(index + 1) / Double(totalFiles)

            } catch {
                print("❌ Error importing \(url.lastPathComponent): \(error)")
            }
        }

        // Save all changes
        do {
            try modelContext.save()
            isImporting = false

            if importedCount > 0 {
                successMessage = "Successfully imported \(importedCount) song\(importedCount == 1 ? "" : "s")"
                showSuccess = true
                HapticManager.shared.success()
            } else {
                errorMessage = "No songs were imported. Make sure the files are valid OnSong format."
                showError = true
                HapticManager.shared.error()
            }
        } catch {
            isImporting = false
            errorMessage = "Failed to save imported songs: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.error()
        }
    }

    private func importFolder(_ folderURL: URL) async {
        guard folderURL.startAccessingSecurityScopedResource() else {
            errorMessage = "Could not access folder"
            showError = true
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        do {
            // Get all files in folder
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            // Filter for OnSong-compatible files
            let onSongFiles = files.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "onsong" || ext == "txt" || ext == "pro" || ext == "chopro"
            }

            if onSongFiles.isEmpty {
                errorMessage = "No OnSong files found in folder"
                showError = true
                return
            }

            await importFiles(onSongFiles)

        } catch {
            errorMessage = "Failed to read folder: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Supporting Views

struct ImportOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    OnSongImportView()
        .modelContainer(for: Song.self, inMemory: true)
}
