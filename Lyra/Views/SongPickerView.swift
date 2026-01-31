//
//  SongPickerView.swift
//  Lyra
//
//  Multi-select picker for adding songs to a book
//

import SwiftUI
import SwiftData

struct SongPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let book: Book
    @Query(sort: \Song.title) private var allSongs: [Song]

    @State private var selectedSongs: Set<Song> = []
    @State private var searchText: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // Songs not yet in this book
    private var availableSongs: [Song] {
        let bookSongs = book.songs ?? []
        return allSongs.filter { song in
            !bookSongs.contains(where: { $0.id == song.id })
        }
    }

    // Filtered songs based on search
    private var filteredSongs: [Song] {
        if searchText.isEmpty {
            return availableSongs
        } else {
            return availableSongs.filter { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                (song.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if availableSongs.isEmpty {
                    // All songs already in book
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        VStack(spacing: 8) {
                            Text("All Songs Added")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Every song in your library is already in this book")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredSongs.isEmpty && !searchText.isEmpty {
                    // No search results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 8) {
                            Text("No Results")
                                .font(.headline)

                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredSongs) { song in
                            SongPickerRow(
                                song: song,
                                isSelected: selectedSongs.contains(song),
                                action: {
                                    HapticManager.shared.selection()
                                    toggleSelection(song)
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search songs")
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addSelectedSongs()
                    } label: {
                        if selectedSongs.isEmpty {
                            Text("Add")
                        } else {
                            Text("Add (\(selectedSongs.count))")
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedSongs.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ song: Song) {
        if selectedSongs.contains(song) {
            selectedSongs.remove(song)
        } else {
            selectedSongs.insert(song)
        }
    }

    private func addSelectedSongs() {
        // Add songs to book
        var bookSongs = book.songs ?? []
        bookSongs.append(contentsOf: selectedSongs)
        book.songs = bookSongs

        // Update modified date
        book.modifiedAt = Date()

        // Save to SwiftData
        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error adding songs to book: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
            errorMessage = "Failed to add songs to book: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Song Picker Row

struct SongPickerRow: View {
    let song: Song
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let artist = song.artist {
                        Text(artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Metadata badges
                    if song.originalKey != nil || (song.capo ?? 0) > 0 {
                        HStack(spacing: 6) {
                            if let key = song.originalKey {
                                SmallBadge(icon: "music.note", text: key, color: .blue)
                            }

                            if let capo = song.capo, capo > 0 {
                                SmallBadge(icon: "guitars", text: "Capo \(capo)", color: .orange)
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small Badge

struct SmallBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .medium))

            Text(text)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Song Picker") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, Song.self, configurations: config)

    // Create sample book
    let book = Book(name: "Worship Songs", description: "Sunday morning worship")
    book.color = "#4A90E2"
    book.icon = "music.note.list"

    // Create sample songs
    let song1 = Song(title: "Amazing Grace", artist: "John Newton", originalKey: "G")
    song1.capo = 2
    let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg", originalKey: "C")
    let song3 = Song(title: "10,000 Reasons", artist: "Matt Redman", originalKey: "D")
    let song4 = Song(title: "Way Maker", artist: "Sinach", originalKey: "A")

    // Add first two songs to book
    book.songs = [song1, song2]

    container.mainContext.insert(book)
    container.mainContext.insert(song1)
    container.mainContext.insert(song2)
    container.mainContext.insert(song3)
    container.mainContext.insert(song4)

    return SongPickerView(book: book)
        .modelContainer(container)
}

#Preview("All Songs Added") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, Song.self, configurations: config)

    let book = Book(name: "Complete Collection", description: "All my songs")
    let song1 = Song(title: "Song 1", artist: "Artist 1")
    let song2 = Song(title: "Song 2", artist: "Artist 2")

    book.songs = [song1, song2]

    container.mainContext.insert(book)
    container.mainContext.insert(song1)
    container.mainContext.insert(song2)

    return SongPickerView(book: book)
        .modelContainer(container)
}
