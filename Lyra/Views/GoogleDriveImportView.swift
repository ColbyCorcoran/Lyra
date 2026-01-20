//
//  GoogleDriveImportView.swift
//  Lyra
//
//  Import workflow for Google Drive files with progress tracking
//

import SwiftUI
import SwiftData

enum GoogleDriveImportState {
    case selectingFiles
    case importing
    case complete
    case error
}

struct GoogleDriveImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var driveManager = GoogleDriveManager.shared

    @State private var importState: GoogleDriveImportState = .selectingFiles
    @State private var selectedFiles: [GoogleDriveFile] = []
    @State private var importProgress: Double = 0.0
    @State private var currentFileName: String = ""
    @State private var importedCount: Int = 0
    @State private var failedCount: Int = 0
    @State private var importedSongs: [Song] = []
    @State private var errorMessages: [String] = []
    @State private var showBrowser: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if importState == .selectingFiles && showBrowser {
                    // Show browser for file selection
                    GoogleDriveBrowserView { files in
                        selectedFiles = files
                        showBrowser = false
                        startImport()
                    }
                } else {
                    contentView
                }
            }
            .navigationTitle("Import from Google Drive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(importState == .importing)
                }

                if importState == .complete {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var contentView: some View {
        switch importState {
        case .selectingFiles:
            selectingView
        case .importing:
            importingView
        case .complete:
            completeView
        case .error:
            errorView
        }
    }

    @ViewBuilder
    private var selectingView: some View {
        VStack(spacing: 32) {
            // Google Drive icon
            ZStack {
                LinearGradient(
                    colors: [Color.blue, Color.green, Color.yellow, Color.red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Image(systemName: "internaldrive")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            .padding(.top, 60)

            VStack(spacing: 16) {
                Text("Select Files to Import")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(selectedFiles.count) file\(selectedFiles.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !selectedFiles.isEmpty {
                Button {
                    startImport()
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Import \(selectedFiles.count) File\(selectedFiles.count == 1 ? "" : "s")")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var importingView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Progress circle with Google colors
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: importProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .green, .yellow, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: importProgress)

                VStack(spacing: 4) {
                    Text("\(Int(importProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)

                    Image(systemName: "arrow.down.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Status
            VStack(spacing: 8) {
                Text("Importing Files...")
                    .font(.headline)

                Text(currentFileName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("\(importedCount) of \(selectedFiles.count) complete")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var completeView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Success icon
                Image(systemName: failedCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(failedCount == 0 ? .green : .orange)
                    .padding(.top, 40)

                // Summary
                VStack(spacing: 16) {
                    Text("Import Complete")
                        .font(.title2)
                        .fontWeight(.bold)

                    VStack(spacing: 12) {
                        StatRow(
                            icon: "checkmark.circle.fill",
                            label: "Successfully Imported",
                            value: "\(importedCount)",
                            color: .green
                        )

                        if failedCount > 0 {
                            StatRow(
                                icon: "xmark.circle.fill",
                                label: "Failed",
                                value: "\(failedCount)",
                                color: .red
                            )
                        }

                        StatRow(
                            icon: "doc.fill",
                            label: "Total Files",
                            value: "\(selectedFiles.count)",
                            color: .blue
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Error messages (if any)
                if !errorMessages.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Errors")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(Array(errorMessages.enumerated()), id: \.offset) { _, message in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)

                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal)
                    }
                }

                // Recently imported songs
                if !importedSongs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Imported Songs")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(importedSongs.prefix(10)) { song in
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.blue)

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
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal)

                        if importedSongs.count > 10 {
                            Text("and \(importedSongs.count - 10) more...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
    }

    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            VStack(spacing: 12) {
                Text("Import Failed")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("An error occurred while importing files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                importState = .selectingFiles
                showBrowser = true
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Import Logic

    private func startImport() {
        importState = .importing
        importProgress = 0.0
        importedCount = 0
        failedCount = 0
        importedSongs = []
        errorMessages = []

        Task {
            for (index, file) in selectedFiles.enumerated() {
                await MainActor.run {
                    currentFileName = file.name
                    importProgress = Double(index) / Double(selectedFiles.count)
                }

                do {
                    let data = try await driveManager.downloadFile(fileId: file.id) { progress in
                        // Could show individual file progress here
                    }

                    // Import the file based on type
                    let song = try await importFile(data: data, filename: file.name, fileExtension: file.fileExtension)

                    await MainActor.run {
                        importedSongs.append(song)
                        importedCount += 1
                    }

                } catch {
                    await MainActor.run {
                        failedCount += 1
                        errorMessages.append("\(file.name): \(error.localizedDescription)")
                    }
                }
            }

            await MainActor.run {
                importProgress = 1.0
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    importState = .complete
                }
                HapticManager.shared.success()
            }
        }
    }

    private func importFile(data: Data, filename: String, fileExtension: String) async throws -> Song {
        // Create temporary URL for the data
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: tempURL)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // Import based on file type
        if fileExtension == "pdf" {
            let result = try ImportManager.shared.importPDF(from: tempURL, to: modelContext)
            return result.song
        } else {
            let result = try ImportManager.shared.importFile(from: tempURL, to: modelContext)
            return result.song
        }
    }
}

// MARK: - Preview

#Preview {
    GoogleDriveImportView()
        .modelContainer(PreviewContainer.shared.container)
}
