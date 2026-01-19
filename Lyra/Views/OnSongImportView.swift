//
//  OnSongImportView.swift
//  Lyra
//
//  Import flow for OnSong backup files
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct OnSongImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showFilePicker: Bool = false
    @State private var isImporting: Bool = false
    @State private var importProgress: Double = 0.0
    @State private var importStatus: String = ""
    @State private var importResult: OnSongImportResult?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // Duplicate handling
    @State private var duplicates: [DuplicateInfo] = []
    @State private var showDuplicateSheet: Bool = false
    @State private var duplicateAction: DuplicateAction = .importAsNew

    enum DuplicateAction {
        case skip
        case replace
        case importAsNew
    }

    struct DuplicateInfo: Identifiable {
        let id = UUID()
        let newSong: Song
        let existingSong: Song
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let result = importResult {
                    // Import complete - show summary
                    importSummaryView(result: result)
                } else if isImporting {
                    // Importing - show progress
                    importingView
                } else {
                    // Initial state - explain and show import button
                    initialView
                }
            }
            .navigationTitle("Import from OnSong")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(importResult != nil ? "Done" : "Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [
                    UTType(filenameExtension: "backup")!,
                    UTType(filenameExtension: "onsongarchive")!,
                    .zip
                ],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showDuplicateSheet) {
                duplicateHandlingSheet
            }
        }
    }

    // MARK: - Initial View

    @ViewBuilder
    private var initialView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 40)

                // Title and description
                VStack(spacing: 12) {
                    Text("Import Your OnSong Library")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Migrate your songs, books, and sets from OnSong to Lyra")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    InstructionRow(
                        number: 1,
                        icon: "iphone.gen3",
                        title: "Create OnSong Backup",
                        description: "In OnSong, tap Settings > Utilities > Backup & Restore > Create Backup"
                    )

                    InstructionRow(
                        number: 2,
                        icon: "square.and.arrow.up",
                        title: "Share the Backup File",
                        description: "Export the .backup or .onsongarchive file to Files or email it to yourself"
                    )

                    InstructionRow(
                        number: 3,
                        icon: "arrow.down.circle.fill",
                        title: "Import to Lyra",
                        description: "Tap the button below and select your OnSong backup file"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Import button
                Button {
                    showFilePicker = true
                } label: {
                    Label("Choose OnSong Backup File", systemImage: "folder.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Note
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                        Text("Phase 2 Note")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.orange)

                    Text("PDF attachments will be skipped in this version. Support for attachments is coming in Phase 3.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Spacer()
            }
        }
    }

    // MARK: - Importing View

    @ViewBuilder
    private var importingView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: importProgress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: importProgress)

                Text("\(Int(importProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }

            // Status text
            VStack(spacing: 8) {
                Text("Importing...")
                    .font(.headline)

                Text(importStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    // MARK: - Import Summary View

    @ViewBuilder
    private func importSummaryView(result: OnSongImportResult) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green.gradient)
                    .padding(.top, 40)

                // Title
                VStack(spacing: 8) {
                    Text("Import Complete!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Successfully imported your OnSong library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Statistics
                VStack(spacing: 16) {
                    StatRow(
                        icon: "music.note",
                        label: "Songs",
                        value: "\(result.songs.count)",
                        color: .blue
                    )

                    StatRow(
                        icon: "book.fill",
                        label: "Books",
                        value: "\(result.books.count)",
                        color: .purple
                    )

                    StatRow(
                        icon: "music.note.list",
                        label: "Performance Sets",
                        value: "\(result.sets.count)",
                        color: .green
                    )

                    if result.skippedAttachments > 0 {
                        StatRow(
                            icon: "paperclip",
                            label: "Attachments Skipped",
                            value: "\(result.skippedAttachments)",
                            color: .orange,
                            note: "PDF support coming in Phase 3"
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Errors (if any)
                if !result.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Import Warnings")
                                .font(.headline)
                        }

                        ForEach(result.errors.prefix(5), id: \.fileName) { error in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(error.fileName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(error.error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        if result.errors.count > 5 {
                            Text("+ \(result.errors.count - 5) more errors")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Duplicate Handling Sheet

    @ViewBuilder
    private var duplicateHandlingSheet: some View {
        NavigationStack {
            List {
                Section {
                    Text("Found \(duplicates.count) songs that may already exist in your library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Duplicate Handling") {
                    Button {
                        duplicateAction = .importAsNew
                        showDuplicateSheet = false
                        proceedWithImport()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import as New")
                                    .foregroundStyle(.primary)
                                Text("Keep both versions (recommended)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if duplicateAction == .importAsNew {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    Button {
                        duplicateAction = .skip
                        showDuplicateSheet = false
                        proceedWithImport()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Skip Duplicates")
                                    .foregroundStyle(.primary)
                                Text("Don't import songs that already exist")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if duplicateAction == .skip {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    Button {
                        duplicateAction = .replace
                        showDuplicateSheet = false
                        proceedWithImport()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Replace Existing")
                                    .foregroundStyle(.primary)
                                Text("Replace old versions with new ones")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if duplicateAction == .replace {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Duplicate Songs")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helper Functions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            startImport(from: url)

        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func startImport(from url: URL) {
        isImporting = true
        importProgress = 0.0
        importStatus = "Starting import..."

        Task {
            do {
                let result = try OnSongParser.parseBackup(from: url) { progress, status in
                    Task { @MainActor in
                        importProgress = progress
                        importStatus = status
                    }
                }

                await MainActor.run {
                    // Check for duplicates
                    checkForDuplicates(result)
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func checkForDuplicates(_ result: OnSongImportResult) {
        // Query existing songs
        let descriptor = FetchDescriptor<Song>()
        let existingSongs = (try? modelContext.fetch(descriptor)) ?? []

        var foundDuplicates: [DuplicateInfo] = []

        for newSong in result.songs {
            if let existing = existingSongs.first(where: {
                $0.title.lowercased() == newSong.title.lowercased() &&
                $0.artist?.lowercased() == newSong.artist?.lowercased()
            }) {
                foundDuplicates.append(DuplicateInfo(newSong: newSong, existingSong: existing))
            }
        }

        duplicates = foundDuplicates

        if duplicates.isEmpty {
            // No duplicates - proceed with import
            saveToDatabase(result)
        } else {
            // Show duplicate handling sheet
            isImporting = false
            showDuplicateSheet = true
            importResult = result
        }
    }

    private func proceedWithImport() {
        guard let result = importResult else { return }

        isImporting = true
        importStatus = "Saving to library..."

        Task {
            await MainActor.run {
                saveToDatabase(result)
            }
        }
    }

    private func saveToDatabase(_ result: OnSongImportResult) {
        var finalResult = result

        // Handle duplicates based on selected action
        switch duplicateAction {
        case .skip:
            // Remove duplicates from result
            let duplicateTitles = Set(duplicates.map { $0.newSong.title.lowercased() })
            finalResult.songs.removeAll { duplicateTitles.contains($0.title.lowercased()) }

        case .replace:
            // Delete existing duplicates
            for duplicate in duplicates {
                modelContext.delete(duplicate.existingSong)
            }

        case .importAsNew:
            // Import all songs as is
            break
        }

        // Insert songs
        for song in finalResult.songs {
            modelContext.insert(song)
        }

        // Insert books
        for book in finalResult.books {
            modelContext.insert(book)
        }

        // Insert sets and entries
        for set in finalResult.sets {
            modelContext.insert(set)
            for entry in set.songEntries ?? [] {
                modelContext.insert(entry)
            }
        }

        // Save
        do {
            try modelContext.save()
            HapticManager.shared.success()

            // Show summary
            importResult = finalResult
            isImporting = false
        } catch {
            errorMessage = "Failed to save imported data: \(error.localizedDescription)"
            showError = true
            isImporting = false
        }
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: Int
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(.blue)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var note: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }

                Text(label)
                    .font(.subheadline)

                Spacer()

                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }

            if let note = note {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                    Text(note)
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    OnSongImportView()
        .modelContainer(PreviewContainer.shared.container)
}
