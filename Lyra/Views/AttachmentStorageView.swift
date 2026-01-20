//
//  AttachmentStorageView.swift
//  Lyra
//
//  View for managing attachment storage and statistics
//

import SwiftUI
import SwiftData

struct AttachmentStorageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var attachments: [Attachment]
    @Query private var songs: [Song]

    @State private var stats: StorageStats?
    @State private var isLoading: Bool = true
    @State private var isCleaningUp: Bool = false
    @State private var showCleanupConfirmation: Bool = false
    @State private var showCompressAllConfirmation: Bool = false
    @State private var compressionProgress: Double = 0.0
    @State private var isCompressing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    @State private var successMessage: String = ""

    @StateObject private var attachmentManager = AttachmentManager.shared

    private var songsWithAttachments: [Song] {
        songs.filter { ($0.attachments?.count ?? 0) > 0 }
    }

    private var compressibleSize: Int64 {
        attachments
            .filter { $0.fileType.lowercased() == "pdf" && $0.fileSize > 1_000_000 }
            .reduce(0) { $0 + Int64($1.fileSize) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Storage Overview
                Section {
                    if let stats = stats {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundStyle(.blue)
                            Text("Total Storage")
                            Spacer()
                            Text(stats.formattedTotalSize)
                                .foregroundStyle(.secondary)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.blue)
                            Text("Total Attachments")
                            Spacer()
                            Text("\(stats.attachmentCount)")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Image(systemName: "music.note")
                                .foregroundStyle(.blue)
                            Text("Songs with Attachments")
                            Spacer()
                            Text("\(songsWithAttachments.count)")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Image(systemName: "chart.bar")
                                .foregroundStyle(.blue)
                            Text("Average Size")
                            Spacer()
                            Text(stats.formattedAverageSize)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ProgressView()
                    }
                } header: {
                    Text("Storage Overview")
                }

                // Storage Details
                if let stats = stats {
                    Section {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(.green)
                            Text("Inline Storage")
                            Spacer()
                            Text("\(stats.inlineCount)")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.orange)
                            Text("File Storage")
                            Spacer()
                            Text("\(stats.fileCount)")
                                .foregroundStyle(.secondary)
                        }

                        if let largest = stats.largestAttachment {
                            HStack {
                                Image(systemName: "arrow.up.circle")
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Largest Attachment")
                                    Text(largest.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(largest.formattedFileSize)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Storage Details")
                    } footer: {
                        Text("Inline: stored in database. File: stored in documents folder")
                    }
                }

                // Optimization
                Section {
                    if compressibleSize > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundStyle(.blue)
                                Text("Compressible PDFs")
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: compressibleSize, countStyle: .file))
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                showCompressAllConfirmation = true
                            } label: {
                                Label("Compress All Large PDFs", systemImage: "arrow.down.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isCompressing)
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        showCleanupConfirmation = true
                    } label: {
                        HStack {
                            Label("Clean Up Orphaned Files", systemImage: "trash.circle")
                            Spacer()
                            if isCleaningUp {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(isCleaningUp)
                } header: {
                    Text("Optimization")
                } footer: {
                    Text("Remove files that are no longer referenced by any attachment")
                }

                // Top Storage Users
                Section {
                    ForEach(topStorageSongs, id: \.id) { song in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(song.title)
                                    .font(.body)

                                if let count = song.attachments?.count {
                                    Text("\(count) \(count == 1 ? "attachment" : "attachments")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text(ByteCountFormatter.string(
                                fromByteCount: attachmentManager.calculateSongStorage(song),
                                countStyle: .file
                            ))
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Top Storage Users")
                } footer: {
                    Text("Songs using the most storage")
                }
            }
            .navigationTitle("Attachment Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        loadStats()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Clean Up?", isPresented: $showCleanupConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clean Up") {
                    cleanupOrphanedFiles()
                }
            } message: {
                Text("This will remove files that are no longer referenced by any attachment. This action cannot be undone.")
            }
            .alert("Compress PDFs?", isPresented: $showCompressAllConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Compress") {
                    compressAllPDFs()
                }
            } message: {
                Text("This will compress all PDFs larger than 1MB using medium quality (70%). This may take a few minutes.")
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(successMessage)
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
                            ProgressView(value: compressionProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 200)

                            Text("Compressing PDFs...")
                                .font(.headline)

                            Text("\(Int(compressionProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .onAppear {
                loadStats()
            }
        }
    }

    // MARK: - Computed Properties

    private var topStorageSongs: [Song] {
        songsWithAttachments
            .sorted { attachmentManager.calculateSongStorage($0) > attachmentManager.calculateSongStorage($1) }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Actions

    private func loadStats() {
        isLoading = true

        Task {
            await Task.sleep(nanoseconds: 100_000_000) // Small delay for UI

            let loadedStats = attachmentManager.getStorageStats(modelContext: modelContext)

            await MainActor.run {
                stats = loadedStats
                isLoading = false
            }
        }
    }

    private func cleanupOrphanedFiles() {
        isCleaningUp = true

        Task {
            do {
                let deletedCount = try attachmentManager.cleanupOrphanedFiles(modelContext: modelContext)

                await MainActor.run {
                    isCleaningUp = false
                    successMessage = "Cleaned up \(deletedCount) orphaned \(deletedCount == 1 ? "file" : "files")"
                    showSuccess = true
                    HapticManager.shared.success()
                    loadStats()
                }
            } catch {
                await MainActor.run {
                    isCleaningUp = false
                    errorMessage = "Failed to clean up: \(error.localizedDescription)"
                    showError = true
                    HapticManager.shared.operationFailed()
                }
            }
        }
    }

    private func compressAllPDFs() {
        isCompressing = true
        compressionProgress = 0.0

        Task {
            let pdfAttachments = attachments.filter {
                $0.fileType.lowercased() == "pdf" && $0.fileSize > 1_000_000
            }

            guard !pdfAttachments.isEmpty else {
                await MainActor.run {
                    isCompressing = false
                    successMessage = "No PDFs need compression"
                    showSuccess = true
                }
                return
            }

            var totalSaved: Int64 = 0
            let total = pdfAttachments.count

            for (index, attachment) in pdfAttachments.enumerated() {
                do {
                    let originalSize = attachment.fileSize
                    _ = try attachmentManager.compressPDF(attachment: attachment, quality: .medium)
                    let savedBytes = originalSize - attachment.fileSize
                    totalSaved += Int64(savedBytes)

                    await MainActor.run {
                        compressionProgress = Double(index + 1) / Double(total)
                    }
                } catch {
                    print("Failed to compress \(attachment.filename): \(error)")
                }
            }

            try? modelContext.save()

            await MainActor.run {
                isCompressing = false
                successMessage = "Compressed \(total) PDFs. Saved \(ByteCountFormatter.string(fromByteCount: totalSaved, countStyle: .file))"
                showSuccess = true
                HapticManager.shared.success()
                loadStats()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AttachmentStorageView()
        .modelContainer(PreviewContainer.shared.container)
}
