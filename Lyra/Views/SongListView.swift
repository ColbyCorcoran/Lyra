//
//  SongListView.swift
//  Lyra
//
//  Enhanced list view for all songs with search, sort, and swipe actions
//

import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable {
    case titleAZ = "Title (A-Z)"
    case titleZA = "Title (Z-A)"
    case artistAZ = "Artist (A-Z)"
    case recentlyAdded = "Recently Added"
    case recentlyViewed = "Recently Viewed"

    var icon: String {
        switch self {
        case .titleAZ: return "textformat.abc"
        case .titleZA: return "textformat.abc"
        case .artistAZ: return "person.fill"
        case .recentlyAdded: return "clock.fill"
        case .recentlyViewed: return "eye.fill"
        }
    }
}

struct SongListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSongs: [Song]

    @State private var searchText: String = ""
    @State private var selectedSort: SortOption = .titleAZ
    @State private var showAddSongSheet: Bool = false

    var body: some View {
        Group {
            if allSongs.isEmpty {
                EnhancedEmptyStateView(showAddSongSheet: $showAddSongSheet)
            } else {
                songListContent
            }
        }
        .searchable(text: $searchText, prompt: "Search songs or artists")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort By", selection: $selectedSort) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Label(option.rawValue, systemImage: option.icon)
                                .tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .sheet(isPresented: $showAddSongSheet) {
            AddSongView()
        }
    }

    // MARK: - Song List Content

    @ViewBuilder
    private var songListContent: some View {
        List {
            ForEach(filteredAndSortedSongs) { song in
                NavigationLink(destination: SongDisplayView(song: song)) {
                    EnhancedSongRowView(song: song)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(makeAccessibilityLabel(for: song))
                .accessibilityHint("Double tap to view song")
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        HapticManager.shared.swipeAction()
                        deleteSong(song)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        // TODO: Edit song functionality
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                    .disabled(true)
                }
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: filteredAndSortedSongs.count)
    }

    /// Create accessibility label for song row
    private func makeAccessibilityLabel(for song: Song) -> String {
        var parts: [String] = [song.title]

        if let artist = song.artist {
            parts.append("by \(artist)")
        }

        if let key = song.originalKey {
            parts.append("in key of \(key)")
        }

        if let capo = song.capo, capo > 0 {
            parts.append("capo \(capo)")
        }

        return parts.joined(separator: ", ")
    }

    // MARK: - Filtering & Sorting

    private var filteredAndSortedSongs: [Song] {
        var songs = allSongs

        // Filter by search text
        if !searchText.isEmpty {
            songs = songs.filter { song in
                song.title.lowercased().contains(searchText.lowercased()) ||
                (song.artist?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }

        // Sort
        switch selectedSort {
        case .titleAZ:
            songs.sort { $0.title.lowercased() < $1.title.lowercased() }
        case .titleZA:
            songs.sort { $0.title.lowercased() > $1.title.lowercased() }
        case .artistAZ:
            songs.sort { ($0.artist ?? "").lowercased() < ($1.artist ?? "").lowercased() }
        case .recentlyAdded:
            songs.sort { $0.createdAt > $1.createdAt }
        case .recentlyViewed:
            songs.sort { ($0.lastViewed ?? Date.distantPast) > ($1.lastViewed ?? Date.distantPast) }
        }

        // Note: SwiftData @Query already efficiently handles large datasets
        // For libraries with 1000+ songs, consider implementing pagination here
        return songs
    }

    // MARK: - Actions

    private func deleteSong(_ song: Song) {
        modelContext.delete(song)
        try? modelContext.save()
    }
}

// MARK: - Enhanced Song Row View

struct EnhancedSongRowView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            // Music icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue)
            }

            // Song info
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(song.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Artist
                if let artist = song.artist {
                    Text(artist)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Badges row
                if song.originalKey != nil || (song.capo ?? 0) > 0 {
                    HStack(spacing: 6) {
                        if let key = song.originalKey {
                            KeyBadge(key: key)
                        }

                        if let capo = song.capo, capo > 0 {
                            CapoBadge(fret: capo)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Key Badge

struct KeyBadge: View {
    let key: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "music.note")
                .font(.system(size: 9, weight: .medium))

            Text(key)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.blue.opacity(0.15))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }
}

// MARK: - Capo Badge

struct CapoBadge: View {
    let fret: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "guitars")
                .font(.system(size: 9, weight: .medium))

            Text("Capo \(fret)")
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.15))
        .foregroundStyle(.orange)
        .clipShape(Capsule())
    }
}

// MARK: - Enhanced Empty State View

struct EnhancedEmptyStateView: View {
    @Binding var showAddSongSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "music.note.list")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(.blue)
                    .symbolEffect(.bounce, value: showAddSongSheet)
            }

            VStack(spacing: 12) {
                Text("No Songs Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Start building your chord chart library.\nAdd your first song to get started!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Add first song button
            Button {
                showAddSongSheet = true
            } label: {
                Label("Add Your First Song", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
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

// MARK: - Simple Empty State View (for BookListView and SetListView)

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Previews

#Preview("Songs List with Data") {
    NavigationStack {
        SongListView()
    }
    .modelContainer(PreviewContainer.shared.container)
}

#Preview("Empty Songs List") {
    NavigationStack {
        SongListView()
    }
    .modelContainer(for: Song.self, inMemory: true)
}

#Preview("Enhanced Song Row") {
    let song = Song(
        title: "Amazing Grace",
        artist: "John Newton",
        originalKey: "G"
    )
    song.capo = 2

    return NavigationStack {
        List {
            NavigationLink(destination: Text("Detail")) {
                EnhancedSongRowView(song: song)
            }
        }
        .listStyle(.plain)
    }
}

#Preview("Search & Sort") {
    NavigationStack {
        SongListView()
    }
    .modelContainer(PreviewContainer.shared.container)
}
