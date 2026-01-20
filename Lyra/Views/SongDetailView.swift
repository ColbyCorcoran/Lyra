//
//  SongDetailView.swift
//  Lyra
//
//  Detail view for a song
//

import SwiftUI

struct SongDetailView: View {
    let song: Song

    @State private var showExportOptions: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareItem: ShareItem?
    @State private var isExporting: Bool = false
    @State private var exportError: Error?
    @State private var showError: Bool = false
    @State private var showAttachments: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(song.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let artist = song.artist {
                        Text(artist)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                Divider()

                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    if let key = song.originalKey {
                        MetadataRow(label: "Key", value: key)
                    }

                    if let tempo = song.tempo {
                        MetadataRow(label: "Tempo", value: "\(tempo) BPM")
                    }

                    if let capo = song.capo, capo > 0 {
                        MetadataRow(label: "Capo", value: "Fret \(capo)")
                    }
                }
                .padding(.horizontal)

                Divider()

                // Content preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)

                    if song.content.isEmpty {
                        Text("No content yet")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        Text(song.content)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)

                // Attachments section
                if let attachments = song.attachments, !attachments.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Attachments")
                                .font(.headline)

                            Spacer()

                            Button {
                                showAttachments = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("View All")
                                        .font(.subheadline)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                            }
                        }

                        ForEach(attachments.prefix(3)) { attachment in
                            HStack(spacing: 12) {
                                Image(systemName: attachment.fileIcon)
                                    .foregroundStyle(attachmentIconColor(attachment))
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(attachment.displayName)
                                            .font(.subheadline)
                                            .lineLimit(1)

                                        if attachment.isDefault {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.yellow)
                                        }
                                    }

                                    Text(attachment.formattedFileSize)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }

                        if attachments.count > 3 {
                            Text("+ \(attachments.count - 3) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showExportOptions = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        printSong()
                    } label: {
                        Label("Print", systemImage: "printer")
                    }

                    Divider()

                    Button {
                        quickExport(format: .pdf)
                    } label: {
                        Label("Quick Export as PDF", systemImage: "doc.richtext")
                    }

                    Button {
                        quickExport(format: .chordPro)
                    } label: {
                        Label("Quick Export as ChordPro", systemImage: "text.badge.star")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(
                exportType: .song(song),
                onExport: { format, configuration in
                    exportSong(format: format, configuration: configuration)
                }
            )
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: item.items)
        }
        .sheet(isPresented: $showAttachments) {
            AttachmentsView(song: song)
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = exportError {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Helper Methods

    private func attachmentIconColor(_ attachment: Attachment) -> Color {
        switch attachment.fileCategory {
        case .pdf: return .red
        case .image: return .blue
        case .audio: return .purple
        case .video: return .orange
        case .other: return .gray
        }
    }

    // MARK: - Actions

    private func exportSong(format: ExportManager.ExportFormat, configuration: PDFExporter.PDFConfiguration) {
        isExporting = true

        Task {
            do {
                let data = try ExportManager.shared.exportSong(song, format: format, configuration: configuration)
                let filename = "\(song.title).\(format.fileExtension)"

                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try data.write(to: tempURL)

                // Show share sheet
                await MainActor.run {
                    shareItem = ShareItem(items: [tempURL])
                    showShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showError = true
                    isExporting = false
                }
            }
        }
    }

    private func quickExport(format: ExportManager.ExportFormat) {
        exportSong(format: format, configuration: PDFExporter.PDFConfiguration())
    }

    private func printSong() {
        Task {
            do {
                let data = try ExportManager.shared.exportSong(song, format: .pdf)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(song.title).pdf")
                try data.write(to: tempURL)

                await MainActor.run {
                    let printController = UIPrintInteractionController.shared
                    printController.printingItem = tempURL

                    let printInfo = UIPrintInfo.printInfo()
                    printInfo.outputType = .general
                    printInfo.jobName = song.title
                    printController.printInfo = printInfo

                    printController.present(animated: true) { _, _, _ in }
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showError = true
                }
            }
        }
    }
}

// MARK: - Share Item

struct ShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Metadata Row

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SongDetailView(song: Song(
            title: "Amazing Grace",
            artist: "Traditional",
            content: """
            {title: Amazing Grace}
            {key: G}

            [G]Amazing grace, how [C]sweet the [G]sound
            That saved a wretch like [D]me
            """,
            originalKey: "G"
        ))
    }
}
