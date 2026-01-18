//
//  SongPickerForSetView.swift
//  Lyra
//
//  Multi-select song picker for performance sets that allows duplicates
//

import SwiftUI
import SwiftData

struct SongPickerForSetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let performanceSet: PerformanceSet

    @Query(sort: \Song.title) private var allSongs: [Song]

    @State private var selectedSongs: Set<Song.ID> = []
    @State private var searchText: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    private var filteredSongs: [Song] {
        if searchText.isEmpty {
            return allSongs
        }

        return allSongs.filter { song in
            song.title.localizedCaseInsensitiveContains(searchText) ||
            (song.artist?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allSongs.isEmpty {
                    // No songs in library
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No Songs in Library")
                            .font(.headline)

                        Text("Add songs to your library first")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredSongs.isEmpty {
                    // No search results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No Results")
                            .font(.headline)

                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    songList
                }
            }
            .navigationTitle("Add Songs to Set")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search songs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedSongs.count))") {
                        addSelectedSongs()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedSongs.isEmpty)
                }
            }
            .alert("Error Adding Songs", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Song List

    @ViewBuilder
    private var songList: some View {
        List(filteredSongs) { song in
            Button {
                toggleSelection(for: song)
            } label: {
                HStack(spacing: 12) {
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
                                    SongMetadataBadge(
                                        icon: "music.note",
                                        text: key,
                                        color: .blue
                                    )
                                }

                                if let capo = song.capo, capo > 0 {
                                    SongMetadataBadge(
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

                    // Checkmark indicator
                    if selectedSongs.contains(song.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func toggleSelection(for song: Song) {
        HapticManager.shared.selection()

        if selectedSongs.contains(song.id) {
            selectedSongs.remove(song.id)
        } else {
            selectedSongs.insert(song.id)
        }
    }

    private func addSelectedSongs() {
        guard !selectedSongs.isEmpty else {
            return
        }

        // Calculate starting orderIndex (add to end of current entries)
        let currentEntries = performanceSet.songEntries ?? []
        var nextOrderIndex = currentEntries.count

        // Create SetEntry objects for each selected song
        var newEntries: [SetEntry] = []

        for songID in selectedSongs {
            guard let song = allSongs.first(where: { $0.id == songID }) else {
                continue
            }

            let entry = SetEntry(song: song, orderIndex: nextOrderIndex)
            entry.performanceSet = performanceSet
            modelContext.insert(entry)

            newEntries.append(entry)
            nextOrderIndex += 1
        }

        // Add new entries to performance set
        var updatedEntries = currentEntries
        updatedEntries.append(contentsOf: newEntries)
        performanceSet.songEntries = updatedEntries
        performanceSet.modifiedAt = Date()

        // Save to SwiftData
        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error adding songs to set: \(error.localizedDescription)")
            errorMessage = "Unable to add songs. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Song Metadata Badge

struct SongMetadataBadge: View {
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

// MARK: - Preview

#Preview("Song Picker for Set") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, Song.self, SetEntry.self, configurations: config)

    // Create performance set
    let performanceSet = PerformanceSet(name: "Sunday Morning Worship", scheduledDate: Date())
    performanceSet.venue = "Main Sanctuary"

    // Create songs
    let song1 = Song(title: "Amazing Grace", artist: "John Newton", originalKey: "G")
    song1.capo = 2

    let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg", originalKey: "C")

    let song3 = Song(title: "It Is Well", artist: "Horatio Spafford", originalKey: "D")
    song3.capo = 4

    let song4 = Song(title: "Cornerstone", artist: "Hillsong Worship", originalKey: "E")

    // Add one existing entry to the set
    let entry1 = SetEntry(song: song1, orderIndex: 0)
    entry1.performanceSet = performanceSet
    performanceSet.songEntries = [entry1]

    container.mainContext.insert(performanceSet)
    container.mainContext.insert(song1)
    container.mainContext.insert(song2)
    container.mainContext.insert(song3)
    container.mainContext.insert(song4)
    container.mainContext.insert(entry1)

    return SongPickerForSetView(performanceSet: performanceSet)
        .modelContainer(container)
}

#Preview("Empty Library") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, Song.self, SetEntry.self, configurations: config)

    let performanceSet = PerformanceSet(name: "Sunday Morning Worship", scheduledDate: Date())
    container.mainContext.insert(performanceSet)

    return SongPickerForSetView(performanceSet: performanceSet)
        .modelContainer(container)
}
