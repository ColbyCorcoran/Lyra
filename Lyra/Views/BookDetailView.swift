//
//  BookDetailView.swift
//  Lyra
//
//  Detail view for a book (placeholder)
//

import SwiftUI

struct BookDetailView: View {
    let book: Book

    private var songs: [Song] {
        book.songs ?? []
    }

    var body: some View {
        List {
            // Book info section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let description = book.bookDescription, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(songs.count) \(songs.count == 1 ? "song" : "songs")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
            }

            // Songs section
            Section("Songs") {
                if songs.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)

                            Text("No songs in this book")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(songs) { song in
                        NavigationLink(destination: SongDetailView(song: song)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(song.title)
                                    .font(.headline)

                                if let artist = song.artist {
                                    Text(artist)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var book = {
        let book = Book(name: "Classic Hymns", description: "Traditional hymns collection")
        book.color = "#4A90E2"
        book.icon = "music.note.list"

        let song1 = Song(title: "Amazing Grace", artist: "Traditional")
        let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg")
        book.songs = [song1, song2]
        return book
    }()

    NavigationStack {
        BookDetailView(book: book)
    }
}
