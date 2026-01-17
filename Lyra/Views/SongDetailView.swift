//
//  SongDetailView.swift
//  Lyra
//
//  Detail view for a song (placeholder)
//

import SwiftUI

struct SongDetailView: View {
    let song: Song

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

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
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
