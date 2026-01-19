//
//  OrganizationPillsView.swift
//  Lyra
//
//  Visual pills showing which books/sets a song belongs to
//

import SwiftUI
import SwiftData

struct OrganizationPillsView: View {
    let song: Song
    @Environment(\.modelContext) private var modelContext

    private var memberBooks: [Book] {
        song.books ?? []
    }

    private var memberSets: [PerformanceSet] {
        // Extract unique sets from setEntries
        let entries = song.setEntries ?? []
        let uniqueSets = Array(Set(entries.compactMap { $0.performanceSet }))
        return uniqueSets.sorted { $0.name < $1.name }
    }

    private let maxVisiblePills = 3

    var body: some View {
        if !memberBooks.isEmpty || !memberSets.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Book pills
                    ForEach(Array(memberBooks.prefix(maxVisiblePills)), id: \.id) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            OrganizationPill(
                                name: book.name,
                                color: Color(hex: book.color ?? "") ?? .blue,
                                icon: book.icon ?? "folder.fill"
                            )
                        }
                        .accessibilityLabel("Book: \(book.name)")
                        .accessibilityHint("Tap to view book")
                    }

                    // Set pills
                    ForEach(Array(memberSets.prefix(maxVisiblePills)), id: \.id) { set in
                        NavigationLink(destination: SetDetailView(performanceSet: set)) {
                            OrganizationPill(
                                name: set.name,
                                color: .green,
                                icon: "list.bullet.rectangle"
                            )
                        }
                        .accessibilityLabel("Set: \(set.name)")
                        .accessibilityHint("Tap to view set")
                    }

                    // "+N more" indicator
                    let totalCount = memberBooks.count + memberSets.count
                    if totalCount > maxVisiblePills {
                        let additionalCount = totalCount - maxVisiblePills
                        Text("+\(additionalCount) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray5))
                            )
                            .accessibilityLabel("\(additionalCount) more collection\(additionalCount == 1 ? "" : "s")")
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 32)
        }
    }
}

// MARK: - Organization Pill

struct OrganizationPill: View {
    let name: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))

            Text(name)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.gradient)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Previews

#Preview("With Books and Sets") {
    let song = Song(title: "Amazing Grace", artist: "Traditional")

    let book1 = Book(name: "Hymns")
    book1.color = "#4A90E2"
    book1.icon = "book.fill"

    let book2 = Book(name: "Classics")
    book2.color = "#E91E63"
    book2.icon = "music.note.list"

    song.books = [book1, book2]

    let set1 = PerformanceSet(name: "Sunday Service")
    let entry1 = SetEntry(song: song, orderIndex: 0)
    entry1.performanceSet = set1

    let set2 = PerformanceSet(name: "Christmas Eve")
    let entry2 = SetEntry(song: song, orderIndex: 0)
    entry2.performanceSet = set2

    song.setEntries = [entry1, entry2]

    return VStack(alignment: .leading, spacing: 8) {
        Text("Amazing Grace")
            .font(.title)
            .fontWeight(.bold)

        OrganizationPillsView(song: song)

        Spacer()
    }
    .padding()
    .modelContainer(PreviewContainer.shared.container)
}

#Preview("Books Only") {
    let song = Song(title: "How Great Thou Art", artist: "Traditional")

    let book1 = Book(name: "Classic Hymns")
    book1.color = "#4A90E2"
    book1.icon = "book.fill"

    song.books = [book1]

    return VStack(alignment: .leading, spacing: 8) {
        Text("How Great Thou Art")
            .font(.title)
            .fontWeight(.bold)

        OrganizationPillsView(song: song)

        Spacer()
    }
    .padding()
    .modelContainer(PreviewContainer.shared.container)
}

#Preview("Many Collections") {
    let song = Song(title: "Great Is Thy Faithfulness", artist: "Traditional")

    let book1 = Book(name: "Hymns")
    book1.color = "#4A90E2"

    let book2 = Book(name: "Classics")
    book2.color = "#E91E63"

    let book3 = Book(name: "Traditional")
    book3.color = "#27AE60"

    song.books = [book1, book2, book3]

    let set1 = PerformanceSet(name: "Sunday Service")
    let entry1 = SetEntry(song: song, orderIndex: 0)
    entry1.performanceSet = set1

    let set2 = PerformanceSet(name: "Christmas Eve")
    let entry2 = SetEntry(song: song, orderIndex: 0)
    entry2.performanceSet = set2

    song.setEntries = [entry1, entry2]

    return VStack(alignment: .leading, spacing: 8) {
        Text("Great Is Thy Faithfulness")
            .font(.title)
            .fontWeight(.bold)

        OrganizationPillsView(song: song)

        Spacer()
    }
    .padding()
    .modelContainer(PreviewContainer.shared.container)
}

#Preview("Empty") {
    let song = Song(title: "Unorganized Song", artist: "Artist")

    return VStack(alignment: .leading, spacing: 8) {
        Text("Unorganized Song")
            .font(.title)
            .fontWeight(.bold)

        OrganizationPillsView(song: song)

        Text("No pills shown when song has no memberships")
            .font(.caption)
            .foregroundStyle(.secondary)

        Spacer()
    }
    .padding()
    .modelContainer(PreviewContainer.shared.container)
}
