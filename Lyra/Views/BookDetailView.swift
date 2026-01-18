//
//  BookDetailView.swift
//  Lyra
//
//  Detail view for a book showing all songs in the collection
//

import SwiftUI

struct BookDetailView: View {
    let book: Book

    private var songs: [Song] {
        book.songs ?? []
    }

    private var bookColor: Color {
        if let colorHex = book.color {
            return Color(hex: colorHex) ?? .accentColor
        }
        return .accentColor
    }

    var body: some View {
        List {
            // Book info header
            Section {
                HStack(spacing: 16) {
                    // Book icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(bookColor.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: book.icon ?? "book.fill")
                            .font(.largeTitle)
                            .foregroundStyle(bookColor)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let description = book.bookDescription, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Text("\(songs.count) \(songs.count == 1 ? "song" : "songs")")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            // Songs section
            Section {
                if songs.isEmpty {
                    BookEmptyStateView()
                } else {
                    ForEach(songs) { song in
                        NavigationLink(destination: SongDisplayView(song: song)) {
                            BookSongRowView(song: song)
                        }
                    }
                }
            } header: {
                Text("Songs")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        // TODO: Add songs to book
                    } label: {
                        Label("Add Songs", systemImage: "plus")
                    }

                    Button {
                        // TODO: Edit book
                    } label: {
                        Label("Edit Book", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        // TODO: Delete book
                    } label: {
                        Label("Delete Book", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Book options")
            }
        }
    }
}

// MARK: - Book Song Row View

struct BookSongRowView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)

                if let artist = song.artist {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Metadata badges
                if song.originalKey != nil || (song.capo ?? 0) > 0 {
                    HStack(spacing: 6) {
                        if let key = song.originalKey {
                            MetadataBadge(
                                icon: "music.note",
                                text: key,
                                color: .blue
                            )
                        }

                        if let capo = song.capo, capo > 0 {
                            MetadataBadge(
                                icon: "guitars",
                                text: "Capo \(capo)",
                                color: .orange
                            )
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Metadata Badge

struct MetadataBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))

            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Book Empty State View

struct BookEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Songs Yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Add songs to this book to organize your collection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                // TODO: Add songs to book
            } label: {
                Label("Add Songs", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .disabled(true) // TODO: Remove when add songs is implemented
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview("Book with Songs") {
    @Previewable @State var book = {
        let book = Book(name: "Classic Hymns", description: "Traditional hymns and worship songs")
        book.color = "#4A90E2"
        book.icon = "music.note.list"

        let song1 = Song(title: "Amazing Grace", artist: "John Newton", originalKey: "G")
        song1.capo = 2
        let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg", originalKey: "C")
        let song3 = Song(title: "It Is Well", artist: "Horatio Spafford", originalKey: "D")
        song3.capo = 4
        book.songs = [song1, song2, song3]
        return book
    }()

    NavigationStack {
        BookDetailView(book: book)
    }
}

#Preview("Empty Book") {
    @Previewable @State var book = {
        let book = Book(name: "New Collection", description: "A fresh collection waiting for songs")
        book.color = "#9B59B6"
        book.icon = "books.vertical.fill"
        return book
    }()

    NavigationStack {
        BookDetailView(book: book)
    }
}
