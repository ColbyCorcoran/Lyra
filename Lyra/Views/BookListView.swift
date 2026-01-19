//
//  BookListView.swift
//  Lyra
//
//  List view for all books
//

import SwiftUI
import SwiftData

struct BookListView: View {
    @Query private var allBooks: [Book]
    @State private var showAddBookSheet: Bool = false
    @State private var searchText: String = ""

    private var filteredBooks: [Book] {
        var result = allBooks

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { book in
                book.name.localizedCaseInsensitiveContains(searchText) ||
                (book.bookDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Sort alphabetically
        result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return result
    }

    var body: some View {
        Group {
            if allBooks.isEmpty {
                EnhancedBookEmptyStateView(showAddBookSheet: $showAddBookSheet)
            } else {
                List {
                    ForEach(filteredBooks) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookRowView(book: book)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $searchText, prompt: "Search books")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddBookSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add book")
                .accessibilityHint("Create a new book collection")
            }
        }
        .sheet(isPresented: $showAddBookSheet) {
            AddBookView()
        }
    }
}

// MARK: - Enhanced Book Empty State View

struct EnhancedBookEmptyStateView: View {
    @Binding var showAddBookSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(.purple)
                    .symbolEffect(.bounce, value: showAddBookSheet)
            }

            VStack(spacing: 12) {
                Text("No Books Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Organize your songs into collections like \"Worship\", \"Holiday Songs\", or \"Kids Music\"")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Create first book button
            Button {
                showAddBookSheet = true
            } label: {
                Label("Create Your First Book", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
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
