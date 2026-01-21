//
//  BookListView.swift
//  Lyra
//
//  List view for all books
//

import SwiftUI
import SwiftData

enum BookSortOption: String, CaseIterable {
    case nameAZ = "Name (A-Z)"
    case nameZA = "Name (Z-A)"
    case songCount = "Song Count"
    case recentlyModified = "Recently Modified"

    var icon: String {
        switch self {
        case .nameAZ: return "textformat.abc"
        case .nameZA: return "textformat.abc"
        case .songCount: return "music.note.list"
        case .recentlyModified: return "clock"
        }
    }
}

struct BookListView: View {
    @Query private var allBooks: [Book]
    @State private var showAddBookSheet: Bool = false
    @State private var selectedSort: BookSortOption = .nameAZ

    private var sortedBooks: [Book] {
        var result = allBooks

        switch selectedSort {
        case .nameAZ:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameZA:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .songCount:
            result.sort { ($0.songs?.count ?? 0) > ($1.songs?.count ?? 0) }
        case .recentlyModified:
            result.sort { $0.modifiedAt > $1.modifiedAt }
        }

        return result
    }

    var body: some View {
        Group {
            if allBooks.isEmpty {
                EnhancedBookEmptyStateView(showAddBookSheet: $showAddBookSheet)
            } else {
                List {
                    ForEach(sortedBooks) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookRowView(book: book)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort By", selection: $selectedSort) {
                        ForEach(BookSortOption.allCases, id: \.self) { option in
                            Label(option.rawValue, systemImage: option.icon)
                                .tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Sort books")
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
