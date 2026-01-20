//
//  GoogleDriveImportView.swift
//  Lyra
//
//  Import workflow for Google Drive files with bulk import support
//

import SwiftUI
import SwiftData

struct GoogleDriveImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var driveManager = GoogleDriveManager.shared
    @StateObject private var queueManager = ImportQueueManager.shared

    @State private var selectedFiles: [GoogleDriveFile] = []
    @State private var isDownloading: Bool = false
    @State private var downloadProgress: Double = 0.0
    @State private var downloadedFiles: Int = 0
    @State private var showBrowser: Bool = true
    @State private var showBulkImportProgress: Bool = false
    @State private var downloadError: String?
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showBrowser {
                    // Show browser for file selection
                    GoogleDriveBrowserView { files in
                        selectedFiles = files
                        showBrowser = false
                    }
                } else if isDownloading {
                    downloadingView
                } else {
                    readyToImportView
                }
            }
            .navigationTitle("Import from Google Drive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if !isDownloading {
                            dismiss()
                        }
                    }
                    .disabled(isDownloading)
                }

                if !showBrowser && !isDownloading {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Import") {
                            startDownloadAndImport()
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedFiles.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showBulkImportProgress) {
                BulkImportProgressView()
            }
            .alert("Download Error", isPresented: $showError) {
                Button("OK") {
                    showBrowser = true
                    selectedFiles.removeAll()
                }
            } message: {
                if let error = downloadError {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var downloadingView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Progress circle with Google colors
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: downloadProgress)
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
                    .animation(.easeInOut, value: downloadProgress)

                VStack(spacing: 4) {
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)

                    Image(systemName: "icloud.and.arrow.down")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Status
            VStack(spacing: 8) {
                Text("Downloading Files...")
                    .font(.headline)

                Text("\(downloadedFiles) of \(selectedFiles.count) downloaded")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var readyToImportView: some View {
        VStack(spacing: 32) {
            // Google Drive icon with gradient
            ZStack {
                LinearGradient(
                    colors: [Color.blue, Color.green, Color.yellow, Color.red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Image(systemName: "internaldrive")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            .padding(.top, 60)

            VStack(spacing: 16) {
                Text("Ready to Import")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(selectedFiles.count) file\(selectedFiles.count == 1 ? "" : "s") selected from Google Drive")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // File list preview
            if !selectedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(selectedFiles.prefix(5)) { file in
                        HStack(spacing: 12) {
                            Image(systemName: file.isFolder ? "folder.fill" : "doc.fill")
                                .foregroundStyle(.blue)

                            Text(file.name)
                                .font(.subheadline)
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    if selectedFiles.count > 5 {
                        Text("+ \(selectedFiles.count - 5) more files")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    // MARK: - Download and Import Logic

    private func startDownloadAndImport() {
        isDownloading = true
        downloadProgress = 0.0
        downloadedFiles = 0

        Task {
            var downloadedURLs: [URL] = []

            for (index, file) in selectedFiles.enumerated() {
                do {
                    let data = try await driveManager.downloadFile(fileId: file.id) { progress in
                        // Individual file progress could be shown here
                    }

                    // Save to temporary directory
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(file.fileExtension)

                    try data.write(to: tempURL)
                    downloadedURLs.append(tempURL)

                    await MainActor.run {
                        downloadedFiles = index + 1
                        downloadProgress = Double(downloadedFiles) / Double(selectedFiles.count)
                    }

                } catch {
                    await MainActor.run {
                        downloadError = "Failed to download \(file.name): \(error.localizedDescription)"
                        showError = true
                        isDownloading = false
                    }
                    return
                }
            }

            // All files downloaded successfully, now import them
            await MainActor.run {
                isDownloading = false
                queueManager.clearQueue()
                queueManager.addToQueue(urls: downloadedURLs)
                showBulkImportProgress = true
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GoogleDriveImportView()
        .modelContainer(PreviewContainer.shared.container)
}
