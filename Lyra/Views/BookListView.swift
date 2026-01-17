//
//  BookListView.swift
//  Lyra
//
//  List view for all books
//

import SwiftUI
import SwiftData

struct BookListView: View {
    @Query(sort: \Book.name, order: .forward) private var books: [Book]

    var body: some View {
        Group {
            if books.isEmpty {
                EmptyStateView(
                    icon: "books.vertical",
                    title: "No Books Yet",
                    message: "Create a book to organize your songs into collections like \"Worship\", \"Hymns\", or \"Kids Songs\""
                )
            } else {
                List {
                    ForEach(books) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookRowView(book: book)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Book Row View

struct BookRowView: View {
    let book: Book

    private var songCount: Int {
        book.songs?.count ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon with color
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(bookColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: book.icon ?? "book.fill")
                    .font(.title3)
                    .foregroundStyle(bookColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let description = book.bookDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text("\(songCount) \(songCount == 1 ? "song" : "songs")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var bookColor: Color {
        if let colorHex = book.color {
            return Color(hex: colorHex) ?? .accentColor
        }
        return .accentColor
    }
}

// MARK: - Previews

#Preview("Books List with Data") {
    NavigationStack {
        BookListView()
    }
    .modelContainer(PreviewContainer.shared.container)
}

#Preview("Empty Books List") {
    NavigationStack {
        BookListView()
    }
    .modelContainer(for: Book.self, inMemory: true)
}

#Preview("Book Row") {
    let book = Book(name: "Classic Hymns", description: "Traditional hymns collection")
    book.color = "#4A90E2"
    book.icon = "music.note.list"

    // Create sample songs
    let song1 = Song(title: "Amazing Grace", artist: "Traditional")
    let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg")
    book.songs = [song1, song2]

    return List {
        BookRowView(book: book)
    }
}
