//
//  SongDetailView.swift
//  Lyra
//
//  Detail view for a song
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SongDetailView: View {
    let song: Song

    // MARK: - State

    @State private var showExportOptions: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var exportedFileURL: URL?

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
                        SongDetailMetadataRow(label: "Key", value: key)
                    }

                    if let tempo = song.tempo {
                        SongDetailMetadataRow(label: "Tempo", value: "\(tempo) BPM")
                    }

                    if let capo = song.capo, capo > 0 {
                        SongDetailMetadataRow(label: "Capo", value: "Fret \(capo)")
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

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showExportOptions = true
                    } label: {
                        Label("Export Song", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsSheet(song: song) { url in
                exportedFileURL = url
            }
        }
        .sheet(item: $exportedFileURL) { url in
            ShareSheet(items: [url])
        }
}

// MARK: - Metadata Row

private struct SongDetailMetadataRow: View {
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

// MARK: - Share Sheet

#if canImport(UIKit)
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - URL Extension

extension URL: @retroactive Identifiable {
    public var id: String {
        return absoluteString
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
