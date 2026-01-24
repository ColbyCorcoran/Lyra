//
//  RecommendationViews.swift
//  Lyra
//
//  Phase 7.5: Recommendation Intelligence
//  UI views for displaying recommendations, smart playlists, and discovery
//  Created on January 24, 2026
//

import SwiftUI
import SwiftData

// MARK: - Similar Songs View

struct SimilarSongsView: View {
    let song: Song

    @Environment(\.modelContext) private var modelContext
    @Query private var allSongs: [Song]

    @State private var recommendations: [SongRecommendation] = []
    @State private var sortBy: SortOption = .similarity
    @State private var isLoading = true

    enum SortOption: String, CaseIterable {
        case similarity = "Similarity"
        case key = "Key"
        case tempo = "Tempo"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Similar Songs")
                    .font(.headline)

                Spacer()

                // Sort picker
                Picker("Sort", selection: $sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if recommendations.isEmpty {
                Text("No similar songs found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Recommendations list
                ForEach(sortedRecommendations) { recommendation in
                    if let recommendedSong = allSongs.first(where: { $0.id == recommendation.recommendedSongID }) {
                        SimilarSongRow(
                            song: recommendedSong,
                            recommendation: recommendation
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .task {
            await loadRecommendations()
        }
        .onChange(of: sortBy) { _, _ in
            // Re-sort will happen automatically
        }
    }

    private var sortedRecommendations: [SongRecommendation] {
        switch sortBy {
        case .similarity:
            return recommendations.sorted { $0.similarityScore > $1.similarityScore }

        case .key:
            return recommendations.sorted { rec1, rec2 in
                let song1 = allSongs.first { $0.id == rec1.recommendedSongID }
                let song2 = allSongs.first { $0.id == rec2.recommendedSongID }
                return (song1?.key ?? "") < (song2?.key ?? "")
            }

        case .tempo:
            return recommendations.sorted { rec1, rec2 in
                let song1 = allSongs.first { $0.id == rec1.recommendedSongID }
                let song2 = allSongs.first { $0.id == rec2.recommendedSongID }
                return (song1?.tempo ?? 0) < (song2?.tempo ?? 0)
            }
        }
    }

    private func loadRecommendations() async {
        isLoading = true
        defer { isLoading = false }

        // Use RecommendationManager to get similar songs
        let recs = await RecommendationManager.shared.getRecommendations(
            for: song,
            in: allSongs,
            types: [.similar],
            limit: 10
        )

        recommendations = recs
    }
}

// MARK: - Similar Song Row

struct SimilarSongRow: View {
    let song: Song
    let recommendation: SongRecommendation

    @State private var showingFeedback = false

    var body: some View {
        HStack(spacing: 12) {
            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body)
                    .fontWeight(.medium)

                if let artist = song.artist {
                    Text(artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Reasons
                Text(recommendation.reasons.joined(separator: " • "))
                    .font(.caption2)
                    .foregroundColor(.blue)
            }

            Spacer()

            // Metadata
            VStack(alignment: .trailing, spacing: 4) {
                // Similarity score
                Text("\(Int(recommendation.similarityScore * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                // Key and tempo
                HStack(spacing: 4) {
                    if let key = song.key {
                        Text(key)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let tempo = song.tempo {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("\(tempo) BPM")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Smart Playlists View

struct SmartPlaylistsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSongs: [Song]
    @Query private var savedPlaylists: [SmartPlaylist]

    @State private var showingCreatePlaylist = false
    @State private var selectedPlaylist: SmartPlaylist?
    @State private var generatedSongs: [Song] = []

    var body: some View {
        NavigationStack {
            List {
                // Preset playlists
                Section("Preset Playlists") {
                    ForEach(presetPlaylists, id: \.name) { preset in
                        Button(action: {
                            generatePlaylist(criteria: preset.criteria)
                        }) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading) {
                                    Text(preset.name)
                                        .font(.body)

                                    Text(preset.criteria.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                // Saved playlists
                if !savedPlaylists.isEmpty {
                    Section("My Smart Playlists") {
                        ForEach(savedPlaylists) { playlist in
                            Button(action: {
                                selectedPlaylist = playlist
                                refreshPlaylist(playlist)
                            }) {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .foregroundColor(.purple)

                                    VStack(alignment: .leading) {
                                        Text(playlist.name)
                                            .font(.body)

                                        Text("\(playlist.songIDs.count) songs")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if playlist.autoRefresh {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deletePlaylists)
                    }
                }
            }
            .navigationTitle("Smart Playlists")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePlaylist = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                CreateSmartPlaylistView()
            }
            .sheet(item: $selectedPlaylist) { playlist in
                PlaylistPreviewView(
                    playlist: playlist,
                    songs: generatedSongs
                )
            }
        }
    }

    private var presetPlaylists: [(name: String, criteria: PlaylistCriteria)] {
        return RecommendationManager.shared.getPresetPlaylists()
    }

    private func generatePlaylist(criteria: PlaylistCriteria) {
        generatedSongs = RecommendationManager.shared.generateSmartPlaylist(
            from: allSongs,
            criteria: criteria,
            optimizeFlow: true
        )
    }

    private func refreshPlaylist(_ playlist: SmartPlaylist) {
        guard let criteria = playlist.criteria else { return }

        generatedSongs = RecommendationManager.shared.generateSmartPlaylist(
            from: allSongs,
            criteria: criteria,
            targetDuration: playlist.targetDuration,
            optimizeFlow: playlist.flowOptimized
        )
    }

    private func deletePlaylists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedPlaylists[index])
        }
    }
}

// MARK: - Create Smart Playlist View

struct CreateSmartPlaylistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedMood: Mood?
    @State private var selectedKey: String?
    @State private var selectedTempo: TempoCategory?
    @State private var autoRefresh = true
    @State private var optimizeFlow = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist Name") {
                    TextField("Enter name", text: $name)
                }

                Section("Criteria") {
                    Picker("Mood", selection: $selectedMood) {
                        Text("Any").tag(nil as Mood?)
                        ForEach(Mood.allCases, id: \.self) { mood in
                            Text(mood.rawValue.capitalized).tag(mood as Mood?)
                        }
                    }

                    Picker("Key", selection: $selectedKey) {
                        Text("Any").tag(nil as String?)
                        ForEach(["C", "G", "D", "A", "E", "F"], id: \.self) { key in
                            Text(key).tag(key as String?)
                        }
                    }

                    Picker("Tempo", selection: $selectedTempo) {
                        Text("Any").tag(nil as TempoCategory?)
                        ForEach([TempoCategory.slow, .moderate, .fast], id: \.self) { tempo in
                            Text(tempo.rawValue.capitalized).tag(tempo as TempoCategory?)
                        }
                    }
                }

                Section("Options") {
                    Toggle("Auto-refresh daily", isOn: $autoRefresh)
                    Toggle("Optimize song flow", isOn: $optimizeFlow)
                }

                Section {
                    Button("Create Playlist") {
                        createPlaylist()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("New Smart Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func createPlaylist() {
        var criteriaList: [PlaylistCriteria] = []

        if let mood = selectedMood {
            criteriaList.append(.mood(mood))
        }

        if let key = selectedKey {
            criteriaList.append(.key(key))
        }

        if let tempo = selectedTempo {
            criteriaList.append(.tempo(tempo))
        }

        let criteria: PlaylistCriteria = criteriaList.isEmpty ? .recent : .combined(criteriaList)

        let playlist = SmartPlaylist(
            name: name,
            criteria: criteria,
            autoRefresh: autoRefresh,
            flowOptimized: optimizeFlow
        )

        modelContext.insert(playlist)

        dismiss()
    }
}

// MARK: - Playlist Preview View

struct PlaylistPreviewView: View {
    let playlist: SmartPlaylist
    let songs: [Song]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text(song.title)
                                .font(.body)

                            if let artist = song.artist {
                                Text(artist)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if let key = song.key {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(playlist.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Discovery View

struct DiscoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSongs: [Song]
    @Query private var playHistory: [PlayHistoryEntry]

    @State private var currentSection: DiscoverySection = .unplayed
    @State private var discoveryFeed: [(section: DiscoverySection, songs: [Song])] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            VStack {
                // Section picker
                Picker("Discovery Type", selection: $currentSection) {
                    ForEach(DiscoverySection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Display current section's songs
                    if let currentSongs = discoveryFeed.first(where: { $0.section == currentSection })?.songs {
                        if currentSongs.isEmpty {
                            ContentUnavailableView(
                                "No Songs Found",
                                systemImage: "music.note",
                                description: Text("Try a different discovery section")
                            )
                        } else {
                            List(currentSongs) { song in
                                DiscoveryCard(song: song)
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No Songs Found",
                            systemImage: "music.note",
                            description: Text("Try a different discovery section")
                        )
                    }
                }
            }
            .navigationTitle("Discover")
            .task {
                await loadDiscoveryFeed()
            }
        }
    }

    private func loadDiscoveryFeed() async {
        isLoading = true
        defer { isLoading = false }

        discoveryFeed = RecommendationManager.shared.getDiscoveryFeed(
            from: allSongs,
            playHistory: playHistory,
            includeTypes: DiscoverySection.allCases,
            limit: 20
        )
    }
}

// MARK: - Discovery Card

struct DiscoveryCard: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Song info
            Text(song.title)
                .font(.headline)

            if let artist = song.artist {
                Text(artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Metadata
            HStack(spacing: 16) {
                if let key = song.key {
                    Label(key, systemImage: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let tempo = song.tempo {
                    Label("\(tempo) BPM", systemImage: "metronome")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let capo = song.capo, capo > 0 {
                    Label("Capo \(capo)", systemImage: "arrow.up.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Quick actions
            HStack(spacing: 12) {
                Button(action: {
                    // Add to set action
                }) {
                    Label("Add to Set", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    // View song action
                }) {
                    Label("View", systemImage: "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
