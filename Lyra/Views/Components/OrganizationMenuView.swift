//
//  OrganizationMenuView.swift
//  Lyra
//
//  Menu content for adding/removing songs from books and sets
//

import SwiftUI
import SwiftData

struct OrganizationMenuView: View {
    let song: Song
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Book.name, order: .forward) private var allBooks: [Book]
    @Query(sort: \PerformanceSet.name, order: .forward) private var allSets: [PerformanceSet]

    @State private var showNewBookSheet = false
    @State private var showNewSetSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private var songBooks: [Book] {
        song.books ?? []
    }

    private var songSets: [PerformanceSet] {
        let entries = song.setEntries ?? []
        return Array(Set(entries.compactMap { $0.performanceSet }))
    }

    var body: some View {
        Group {
            // Books Section
            Section("Add to Book") {
                if allBooks.isEmpty {
                    Button {
                        showNewBookSheet = true
                    } label: {
                        Label("Create First Book", systemImage: "folder.badge.plus")
                    }
                } else {
                    ForEach(allBooks) { book in
                        Button {
                            toggleBookMembership(book)
                        } label: {
                            Label {
                                Text(book.name)
                            } icon: {
                                if songBooks.contains(where: { $0.id == book.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accentColor)
                                }
                            }
                        }
                    }

                    Divider()

                    Button {
                        showNewBookSheet = true
                    } label: {
                        Label("New Book...", systemImage: "plus.circle")
                    }
                }
            }

            // Sets Section
            Section("Add to Set") {
                if allSets.isEmpty {
                    Button {
                        showNewSetSheet = true
                    } label: {
                        Label("Create First Set", systemImage: "calendar.badge.plus")
                    }
                } else {
                    ForEach(allSets) { set in
                        Button {
                            toggleSetMembership(set)
                        } label: {
                            Label {
                                Text(set.name)
                            } icon: {
                                if songSets.contains(where: { $0.id == set.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accentColor)
                                }
                            }
                        }
                    }

                    Divider()

                    Button {
                        showNewSetSheet = true
                    } label: {
                        Label("New Set...", systemImage: "plus.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showNewBookSheet) {
            AddBookView()
        }
        .sheet(isPresented: $showNewSetSheet) {
            AddSetView()
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Actions

    private func toggleBookMembership(_ book: Book) {
        do {
            if songBooks.contains(where: { $0.id == book.id }) {
                // Remove from book
                try DataManager.shared.removeSongFromBook(song, book: book)
                HapticManager.shared.success()
            } else {
                // Add to book
                try DataManager.shared.addSongToBook(song, book: book)
                HapticManager.shared.success()
            }
        } catch {
            errorMessage = "Unable to update book membership. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func toggleSetMembership(_ set: PerformanceSet) {
        do {
            let existingEntry = song.setEntries?.first(where: { $0.performanceSet?.id == set.id })

            if let entry = existingEntry {
                // Remove from set
                try DataManager.shared.removeSongFromPerformanceSet(entry, set: set)
                HapticManager.shared.success()
            } else {
                // Add to set
                _ = try DataManager.shared.addSongToPerformanceSet(song, set: set)
                HapticManager.shared.success()
            }
        } catch {
            errorMessage = "Unable to update set membership. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace", artist: "Traditional")

    let book1 = Book(name: "Hymns")
    let book2 = Book(name: "Classics")
    song.books = [book1]

    let set1 = PerformanceSet(name: "Sunday Service")
    let entry1 = SetEntry(song: song, orderIndex: 0)
    entry1.performanceSet = set1
    song.setEntries = [entry1]

    return Menu("Add to...") {
        OrganizationMenuView(song: song)
    }
    .modelContainer(PreviewContainer.shared.container)
    .padding()
}
