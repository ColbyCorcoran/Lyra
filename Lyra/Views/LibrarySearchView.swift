//
//  LibrarySearchView.swift
//  Lyra
//
//  Comprehensive search view with filters, history, and suggestions
//

import SwiftUI
import SwiftData

struct LibrarySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allSongs: [Song]
    @Query private var allBooks: [Book]
    @Query private var allSets: [PerformanceSet]

    @StateObject private var searchManager = SearchManager.shared

    @State private var searchText: String = ""
    @State private var selectedScope: SearchScope = .all
    @State private var showFilterSheet: Bool = false
    @State private var isSearching: Bool = false

    // Debounced search
    @State private var searchTask: Task<Void, Never>?

    // Results
    @State private var songResults: [SearchResult] = []
    @State private var bookResults: [SearchResult] = []
    @State private var setResults: [SearchResult] = []

    // Suggestions
    @State private var suggestions: [String] = []
    @State private var showSuggestions: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar and filters
                VStack(spacing: 12) {
                    // Search field
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search songs, books, sets...", text: $searchText)
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
                            Button {
                                searchText = ""
                                clearResults()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Scope picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SearchScope.allCases, id: \.self) { scope in
                                ScopeButton(
                                    scope: scope,
                                    isSelected: selectedScope == scope
                                ) {
                                    selectedScope = scope
                                    if !searchText.isEmpty {
                                        performSearch()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .padding()

                // Content
                if showSuggestions && !suggestions.isEmpty {
                    // Suggestions
                    suggestionsList
                } else if searchText.isEmpty {
                    // Search history or empty state
                    searchHistoryView
                } else if isSearching {
                    // Loading
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if hasResults {
                    // Results
                    searchResultsView
                } else {
                    // No results
                    noResultsView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Suggestions List

    @ViewBuilder
    private var suggestionsList: some View {
        List {
            Section("Suggestions") {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        searchText = suggestion
                        showSuggestions = false
                        performSearch()
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text(suggestion)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Search History View

    @ViewBuilder
    private var searchHistoryView: some View {
        List {
            if !searchManager.searchHistory.isEmpty {
                Section {
                    ForEach(searchManager.searchHistory, id: \.self) { query in
                        Button {
                            searchText = query
                            performSearch()
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                Text(query)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent Searches")
                        Spacer()
                        Button("Clear") {
                            searchManager.clearSearchHistory()
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 4) {
                        Text("Search Your Library")
                            .font(.headline)

                        Text("Find songs, books, and sets")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Search Results View

    @ViewBuilder
    private var searchResultsView: some View {
        List {
            // Songs section
            if !songResults.isEmpty {
                Section {
                    ForEach(songResults.prefix(10)) { result in
                        if let song = result.song {
                            NavigationLink(destination: SongDisplayView(song: song)) {
                                SongResultRow(result: result, song: song)
                            }
                        }
                    }

                    if songResults.count > 10 {
                        Button {
                            // Show all songs
                        } label: {
                            HStack {
                                Text("Show All \(songResults.count) Songs")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "music.note")
                        Text("Songs")
                        Spacer()
                        Text("\(songResults.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Books section
            if !bookResults.isEmpty {
                Section {
                    ForEach(bookResults.prefix(10)) { result in
                        if let book = result.book {
                            NavigationLink(destination: BookDetailView(book: book)) {
                                BookResultRow(book: book)
                            }
                        }
                    }

                    if bookResults.count > 10 {
                        Button {
                            // Show all books
                        } label: {
                            HStack {
                                Text("Show All \(bookResults.count) Books")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Books")
                        Spacer()
                        Text("\(bookResults.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Sets section
            if !setResults.isEmpty {
                Section {
                    ForEach(setResults.prefix(10)) { result in
                        if let set = result.set {
                            NavigationLink(destination: SetDetailView(performanceSet: set)) {
                                SetResultRow(set: set)
                            }
                        }
                    }

                    if setResults.count > 10 {
                        Button {
                            // Show all sets
                        } label: {
                            HStack {
                                Text("Show All \(setResults.count) Sets")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "music.note.list")
                        Text("Sets")
                        Spacer()
                        Text("\(setResults.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - No Results View

    @ViewBuilder
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("No Results")
                    .font(.headline)

                Text("Try a different search term or filter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                selectedScope = .all
            } label: {
                Text("Search in All Fields")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var hasResults: Bool {
        !songResults.isEmpty || !bookResults.isEmpty || !setResults.isEmpty
    }

    // MARK: - Search Functions

    private func handleSearchTextChange(_ newValue: String) {
        // Cancel previous search task
        searchTask?.cancel()

        // Update suggestions
        if !newValue.isEmpty {
            suggestions = searchManager.getSuggestions(for: newValue, songs: allSongs)
            showSuggestions = !suggestions.isEmpty
        } else {
            showSuggestions = false
            clearResults()
            return
        }

        // Debounce search
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            guard !Task.isCancelled else { return }

            await MainActor.run {
                performSearch()
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            clearResults()
            return
        }

        isSearching = true
        showSuggestions = false

        // Save to history
        searchManager.saveSearch(searchText)

        // Perform search
        Task {
            let results = searchManager.search(
                query: searchText,
                songs: allSongs,
                books: allBooks,
                sets: allSets,
                scope: selectedScope
            )

            await MainActor.run {
                songResults = results.songs
                bookResults = results.books
                setResults = results.sets
                isSearching = false
            }
        }
    }

    private func clearResults() {
        songResults = []
        bookResults = []
        setResults = []
        suggestions = []
        showSuggestions = false
    }
}

// MARK: - Scope Button

struct ScopeButton: View {
    let scope: SearchScope
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: scope.icon)
                    .font(.caption)
                Text(scope.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Result Rows

struct SongResultRow: View {
    let result: SearchResult
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let artist = song.artist {
                        Text(artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let key = song.originalKey {
                    Text(key)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }

            // Match snippet if available
            if let snippet = result.matchSnippet {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BookResultRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            // Book icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: book.color ?? "#4A90E2").opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: book.icon)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: book.color ?? "#4A90E2"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(book.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(book.songs?.count ?? 0) songs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SetResultRow: View {
    let set: PerformanceSet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(set.name)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 12) {
                if let venue = set.venue, !venue.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(venue)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if let date = set.scheduledDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(formatDate(date))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Song.self, Book.self, PerformanceSet.self, configurations: config)

    // Create sample data
    for i in 1...20 {
        let song = Song(title: "Song \(i)", artist: "Artist \(i % 5)", originalKey: ["C", "G", "D"].randomElement())
        song.content = "Sample lyrics for song \(i)"
        container.mainContext.insert(song)
    }

    for i in 1...5 {
        let book = Book(name: "Book \(i)", color: "#4A90E2")
        container.mainContext.insert(book)
    }

    for i in 1...3 {
        let set = PerformanceSet(name: "Set \(i)", scheduledDate: Date())
        set.venue = "Venue \(i)"
        container.mainContext.insert(set)
    }

    return LibrarySearchView()
        .modelContainer(container)
}
