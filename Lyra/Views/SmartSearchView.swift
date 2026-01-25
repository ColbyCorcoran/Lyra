//
//  SmartSearchView.swift
//  Lyra
//
//  Intelligent search interface with autocomplete, suggestions, and AI-powered results
//  Part of Phase 7.4: Search Intelligence
//

import SwiftUI
import SwiftData

struct SmartSearchView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [SearchResult] = []
    @State private var suggestions: [SearchSuggestion] = []
    @State private var showingSuggestions = false
    @State private var selectedFilter: SearchFilter?
    @State private var sortBy: SearchQuery.SortCriteria = .relevance

    // MARK: - Search Engines

    private let parser = NaturalLanguageParser()
    private let suggestionEngine = SearchSuggestionEngine()
    private let rankingEngine = SearchRankingEngine()
    private let fuzzyEngine = FuzzyMatchingEngine()
    private let semanticEngine = SemanticSearchEngine()
    private let contentEngine = ContentSearchEngine()

    // MARK: - Query

    @Query private var allSongs: [Song]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                if showingSuggestions && !suggestions.isEmpty {
                    // Suggestions list
                    suggestionsList
                } else if isSearching {
                    // Loading indicator
                    ProgressView("Searching...")
                        .padding()
                } else if !searchResults.isEmpty {
                    // Search results
                    resultsList
                } else if !searchText.isEmpty {
                    // No results
                    noResultsView
                } else {
                    // Initial state with AI suggestions
                    initialStateView
                }
            }
            .navigationTitle("Smart Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $sortBy) {
                            Label("Relevance", systemImage: "star.fill")
                                .tag(SearchQuery.SortCriteria.relevance)
                            Label("Title", systemImage: "textformat")
                                .tag(SearchQuery.SortCriteria.title)
                            Label("Artist", systemImage: "music.mic")
                                .tag(SearchQuery.SortCriteria.artist)
                            Label("Recently Added", systemImage: "clock")
                                .tag(SearchQuery.SortCriteria.recentlyAdded)
                            Label("Tempo", systemImage: "metronome")
                                .tag(SearchQuery.SortCriteria.tempo)
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .onAppear {
            loadInitialSuggestions()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search songs, artists, lyrics...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { _, newValue in
                    handleSearchTextChange(newValue)
                }
                .onSubmit {
                    performSearch()
                }

            if !searchText.isEmpty {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Suggestions List

    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(suggestions) { suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        selectSuggestion(suggestion)
                    }
                }
            }
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults) { result in
                    SearchResultRow(result: result) {
                        selectResult(result)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Try adjusting your search or check for typos")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Spelling suggestions
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Did you mean:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(suggestions.prefix(3)) { suggestion in
                        Button(action: { selectSuggestion(suggestion) }) {
                            Text(suggestion.text)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding()
    }

    // MARK: - Initial State View

    private var initialStateView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent searches
                if !suggestionEngine.getRecentSearches().isEmpty {
                    SuggestionSection(
                        title: "Recent Searches",
                        icon: "clock",
                        suggestions: suggestionEngine.getRecentSearches().prefix(5).map {
                            SearchSuggestion(
                                text: $0,
                                type: .recentSearch,
                                confidence: 1.0
                            )
                        }
                    ) { suggestion in
                        selectSuggestion(suggestion)
                    }
                }

                // AI Suggestions
                SuggestionSection(
                    title: "Suggested for You",
                    icon: "sparkles",
                    suggestions: getAISuggestions()
                ) { suggestion in
                    selectSuggestion(suggestion)
                }

                // Quick filters
                QuickFiltersSection { filter in
                    applyQuickFilter(filter)
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Search Logic

    private func handleSearchTextChange(_ text: String) {
        // Update suggestions as user types
        if text.isEmpty {
            showingSuggestions = false
            suggestions = []
            searchResults = []
        } else if text.count >= 2 {
            showingSuggestions = true
            generateAutocompleteSuggestions(for: text)
        }
    }

    private func generateAutocompleteSuggestions(for query: String) {
        // Get song titles and artists
        let titles = allSongs.map { $0.title }
        let artists = allSongs.compactMap { $0.artist }

        // Generate suggestions
        suggestions = suggestionEngine.generateAutocompleteSuggestions(
            for: query,
            songTitles: titles,
            artists: artists,
            limit: 8
        )

        // Add spelling corrections if needed
        let corrections = suggestionEngine.suggestCorrections(for: query)
        if !corrections.isEmpty {
            suggestions.insert(contentsOf: corrections, at: 0)
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        showingSuggestions = false

        // Record this search
        suggestionEngine.recordSearch(searchText)

        // Parse the query
        let parsedQuery = parser.parseQuery(searchText)

        // Adjust ranking weights based on query type
        rankingEngine.adjustWeightsForQuery(parsedQuery)

        // Search and rank
        Task {
            let results = await searchSongs(query: parsedQuery)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }

    private func searchSongs(query: SearchQuery) async -> [SearchResult] {
        // Create song matches
        var songMatches: [SongMatch] = []

        for song in allSongs {
            // Calculate match scores
            let titleScore = fuzzyEngine.fuzzyMatch(query.rawQuery, song.title)
            let artistScore = song.artist.map { fuzzyEngine.matchArtistName(query.rawQuery, $0) } ?? 0.0

            // Content search
            var contentScore: Float = 0.0
            var matchedFields: [SearchResult.MatchedField] = []

            if titleScore > 0.5 {
                matchedFields.append(SearchResult.MatchedField(
                    fieldName: "title",
                    matchScore: titleScore,
                    snippet: song.title
                ))
                contentScore = max(contentScore, titleScore)
            }

            if artistScore > 0.5, let artist = song.artist {
                matchedFields.append(SearchResult.MatchedField(
                    fieldName: "artist",
                    matchScore: artistScore,
                    snippet: artist
                ))
                contentScore = max(contentScore, artistScore)
            }

            // Search content if available
            let contentMatches = contentEngine.searchLyrics(query.rawQuery, in: song.content)
            if !contentMatches.isEmpty {
                let contentMatchScore = contentMatches.first?.relevance ?? 0.0
                matchedFields.append(SearchResult.MatchedField(
                    fieldName: "content",
                    matchScore: contentMatchScore,
                    snippet: contentMatches.first?.context
                ))
                contentScore = max(contentScore, contentMatchScore)
            }

            // Apply filters
            if !passesFilters(song, filters: query.filters) {
                continue
            }

            // Create match if score is high enough
            if contentScore > 0.3 || !matchedFields.isEmpty {
                let songMatch = SongMatch(
                    songID: song.id,
                    title: song.title,
                    artist: song.artist,
                    key: song.currentKey ?? song.originalKey,
                    lyrics: song.content,
                    dateAdded: song.createdAt,
                    matchType: determineMatchType(score: contentScore),
                    matchedFields: matchedFields,
                    highlights: []
                )
                songMatches.append(songMatch)
            }
        }

        // Rank results
        return rankingEngine.rankResults(songMatches, query: query)
    }

    private func passesFilters(_ song: Song, filters: [SearchFilter]) -> Bool {
        for filter in filters {
            switch filter.type {
            case .key:
                let songKey = song.currentKey ?? song.originalKey
                if songKey != filter.value {
                    return false
                }
            case .capo:
                if String(song.capo ?? 0) != filter.value {
                    return false
                }
            case .artist:
                if song.artist?.lowercased() != filter.value.lowercased() {
                    return false
                }
            default:
                continue
            }
        }
        return true
    }

    private func determineMatchType(score: Float) -> SearchResult.MatchType {
        if score > 0.9 {
            return .exact
        } else if score > 0.7 {
            return .fuzzy
        } else if score > 0.5 {
            return .partial
        } else {
            return .semantic
        }
    }

    // MARK: - Actions

    private func selectSuggestion(_ suggestion: SearchSuggestion) {
        searchText = suggestion.text
        showingSuggestions = false
        performSearch()
    }

    private func selectResult(_ result: SearchResult) {
        // Record click-through
        rankingEngine.recordClickThrough(
            query: searchText,
            selectedSongID: result.songID,
            position: searchResults.firstIndex(of: result) ?? 0,
            allResults: searchResults
        )

        // Navigate to song detail
        // (Implementation depends on navigation setup)
    }

    private func clearSearch() {
        searchText = ""
        searchResults = []
        suggestions = []
        showingSuggestions = false
    }

    private func applyQuickFilter(_ filter: SearchFilter) {
        // Apply filter and search
        selectedFilter = filter
        // Implementation depends on how filters are applied
    }

    // MARK: - Helpers

    private func loadInitialSuggestions() {
        suggestionEngine.loadSuggestionData()
        rankingEngine.loadLearningData()
    }

    private func getAISuggestions() -> [SearchSuggestion] {
        let context = SearchContext(
            recentSearches: suggestionEngine.getRecentSearches(),
            recentSongIDs: [], // Would come from user history
            preferredKeys: [],
            preferredArtists: [],
            searchHistory: [],
            lastUpdated: Date()
        )

        return suggestionEngine.generateAISuggestions(context: context, limit: 5)
    }
}

// MARK: - Supporting Views

struct SuggestionRow: View {
    let suggestion: SearchSuggestion
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: suggestion.type.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.text)
                        .foregroundStyle(.primary)

                    if let reasoning = suggestion.reasoning {
                        Text(reasoning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

extension SearchSuggestion.SuggestionType {
    var icon: String {
        switch self {
        case .autocomplete: return "magnifyingglass"
        case .relatedSearch: return "arrow.triangle.branch"
        case .popularSearch: return "chart.line.uptrend.xyaxis"
        case .recentSearch: return "clock"
        case .aiSuggested: return "sparkles"
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.headline)

                        if let artist = result.artist {
                            Text(artist)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Match type badge
                    Text(result.matchType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(result.matchType.color.opacity(0.2))
                        .foregroundStyle(result.matchType.color)
                        .cornerRadius(4)
                }

                // Matched fields
                if !result.matchedFields.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(result.matchedFields, id: \.fieldName) { field in
                            HStack(spacing: 4) {
                                Text(field.fieldName.capitalized)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                if let snippet = field.snippet {
                                    Text("· \(snippet.prefix(30))...")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }

                // Reasoning
                if let reasoning = result.reasoning {
                    Text(reasoning)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

extension SearchResult.MatchType {
    var color: Color {
        switch self {
        case .exact: return .green
        case .fuzzy: return .blue
        case .semantic: return .purple
        case .partial: return .orange
        case .phonetic: return .pink
        case .content: return .teal
        }
    }
}

struct SuggestionSection: View {
    let title: String
    let icon: String
    let suggestions: [SearchSuggestion]
    let action: (SearchSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.secondary)

            SearchFlowLayout(spacing: 8) {
                ForEach(suggestions) { suggestion in
                    Button(action: { action(suggestion) }) {
                        Text(suggestion.text)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
}

struct QuickFiltersSection: View {
    let action: (SearchFilter) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Filters", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(.secondary)

            SearchFlowLayout(spacing: 8) {
                quickFilterButton("No Capo", icon: "hand.raised.slash", filter: SearchFilter(type: .capo, value: "0", operator_: .equals))
                quickFilterButton("Fast Tempo", icon: "hare", filter: SearchFilter(type: .tempo, value: "120", operator_: .greaterThan))
                quickFilterButton("Recently Added", icon: "clock", filter: SearchFilter(type: .dateAdded, value: "recent", operator_: .equals))
            }
        }
    }

    private func quickFilterButton(_ title: String, icon: String, filter: SearchFilter) -> some View {
        Button(action: { action(filter) }) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBlue).opacity(0.1))
                .foregroundStyle(.blue)
                .cornerRadius(16)
        }
    }
}

// Simple flow layout for wrapping buttons
struct SearchFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in sizes {
            if lineWidth + size.width > (proposal.width ?? 0) {
                totalHeight += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            totalWidth = max(totalWidth, lineWidth)
        }

        totalHeight += lineHeight
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if lineX + size.width > bounds.maxX {
                lineY += lineHeight + spacing
                lineX = bounds.minX
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: lineX, y: lineY), proposal: .unspecified)
            lineX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    SmartSearchView()
        .modelContainer(for: Song.self, inMemory: true)
}
