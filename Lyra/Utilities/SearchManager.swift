//
//  SearchManager.swift
//  Lyra
//
//  Manages search functionality, history, and content parsing
//

import Foundation
import SwiftData
import Combine

// MARK: - Search Scope

enum SearchScope: String, CaseIterable, Codable {
    case all = "All"
    case title = "Title"
    case artist = "Artist"
    case album = "Album"
    case key = "Key"
    case lyrics = "Lyrics"

    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .title: return "textformat"
        case .artist: return "person"
        case .album: return "opticaldisc"
        case .key: return "music.note"
        case .lyrics: return "text.quote"
        }
    }
}

// MARK: - Search Result

struct SearchResult: Identifiable {
    let id = UUID()
    let type: ResultType
    let song: Song?
    let book: Book?
    let set: PerformanceSet?
    let matchSnippet: String?
    let relevanceScore: Int

    enum ResultType {
        case song
        case book
        case set
    }
}

// MARK: - Search Manager

class SearchManager: ObservableObject {
    static let shared = SearchManager()

    private let historyKey = "lyra_search_history"
    private let maxHistoryItems = 10

    @Published var searchHistory: [String] = []

    private init() {
        loadSearchHistory()
    }

    // MARK: - Search History

    func saveSearch(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Remove if already exists
        searchHistory.removeAll { $0.lowercased() == query.lowercased() }

        // Add to beginning
        searchHistory.insert(query, at: 0)

        // Limit to max items
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    func clearSearchHistory() {
        searchHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            searchHistory = decoded
        }
    }

    // MARK: - Search Functions

    func search(
        query: String,
        songs: [Song],
        books: [Book],
        sets: [PerformanceSet],
        scope: SearchScope
    ) -> (songs: [SearchResult], books: [SearchResult], sets: [SearchResult]) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmedQuery.isEmpty else {
            return ([], [], [])
        }

        let songResults = searchSongs(query: trimmedQuery, songs: songs, scope: scope)
        let bookResults = searchBooks(query: trimmedQuery, books: books)
        let setResults = searchSets(query: trimmedQuery, sets: sets)

        return (songResults, bookResults, setResults)
    }

    private func searchSongs(query: String, songs: [Song], scope: SearchScope) -> [SearchResult] {
        var results: [SearchResult] = []

        for song in songs {
            var score = 0
            var snippet: String?

            switch scope {
            case .all:
                // Search all fields
                if let titleMatch = matchField(song.title, query: query) {
                    score += titleMatch.score * 3 // Title matches are most important
                }
                if let artistMatch = matchField(song.artist, query: query) {
                    score += artistMatch.score * 2
                }
                if let albumMatch = matchField(song.album, query: query) {
                    score += albumMatch.score
                }
                if let keyMatch = matchField(song.originalKey, query: query) {
                    score += keyMatch.score
                }
                // Search in lyrics
                if let lyricsMatch = searchInContent(song.content, query: query) {
                    score += lyricsMatch.score
                    snippet = lyricsMatch.snippet
                }

            case .title:
                if let match = matchField(song.title, query: query) {
                    score += match.score * 3
                }

            case .artist:
                if let match = matchField(song.artist, query: query) {
                    score += match.score * 2
                }

            case .album:
                if let match = matchField(song.album, query: query) {
                    score += match.score
                }

            case .key:
                if let match = matchField(song.originalKey, query: query) {
                    score += match.score
                }

            case .lyrics:
                if let match = searchInContent(song.content, query: query) {
                    score += match.score
                    snippet = match.snippet
                }
            }

            if score > 0 {
                results.append(SearchResult(
                    type: .song,
                    song: song,
                    book: nil,
                    set: nil,
                    matchSnippet: snippet,
                    relevanceScore: score
                ))
            }
        }

        // Sort by relevance
        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    private func searchBooks(query: String, books: [Book]) -> [SearchResult] {
        var results: [SearchResult] = []

        for book in books {
            var score = 0

            if let match = matchField(book.name, query: query) {
                score += match.score * 3
            }
            if let match = matchField(book.bookDescription, query: query) {
                score += match.score
            }

            if score > 0 {
                results.append(SearchResult(
                    type: .book,
                    song: nil,
                    book: book,
                    set: nil,
                    matchSnippet: nil,
                    relevanceScore: score
                ))
            }
        }

        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    private func searchSets(query: String, sets: [PerformanceSet]) -> [SearchResult] {
        var results: [SearchResult] = []

        for set in sets {
            var score = 0

            if let match = matchField(set.name, query: query) {
                score += match.score * 3
            }
            if let match = matchField(set.venue, query: query) {
                score += match.score * 2
            }
            if let match = matchField(set.setDescription, query: query) {
                score += match.score
            }
            if let match = matchField(set.folder, query: query) {
                score += match.score
            }

            if score > 0 {
                results.append(SearchResult(
                    type: .set,
                    song: nil,
                    book: nil,
                    set: set,
                    matchSnippet: nil,
                    relevanceScore: score
                ))
            }
        }

        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    // MARK: - Helper Functions

    private func matchField(_ field: String?, query: String) -> (score: Int, snippet: String?)? {
        guard let field = field else { return nil }
        let lowercased = field.lowercased()

        // Exact match
        if lowercased == query {
            return (100, nil)
        }

        // Starts with
        if lowercased.hasPrefix(query) {
            return (80, nil)
        }

        // Contains
        if lowercased.contains(query) {
            return (50, nil)
        }

        // Word match (space-separated)
        let words = lowercased.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            if word == query {
                return (70, nil)
            }
            if word.hasPrefix(query) {
                return (60, nil)
            }
        }

        return nil
    }

    private func searchInContent(_ content: String, query: String) -> (score: Int, snippet: String)? {
        let lowercased = content.lowercased()

        guard lowercased.contains(query) else { return nil }

        // Find the position of the match
        guard let range = lowercased.range(of: query) else { return nil }

        // Extract a snippet around the match
        let snippet = extractSnippet(from: content, around: range)

        return (30, snippet)
    }

    private func extractSnippet(from content: String, around range: Range<String.Index>) -> String {
        let snippetLength = 60
        let halfLength = snippetLength / 2

        // Calculate start and end positions
        let startOffset = content.distance(from: content.startIndex, to: range.lowerBound)
        let endOffset = content.distance(from: content.startIndex, to: range.upperBound)

        var snippetStart = max(0, startOffset - halfLength)
        var snippetEnd = min(content.count, endOffset + halfLength)

        // Adjust to word boundaries
        let contentString = String(content)

        if snippetStart > 0 {
            let startIndex = contentString.index(contentString.startIndex, offsetBy: snippetStart)
            if let spaceIndex = contentString[startIndex...].firstIndex(of: " ") {
                snippetStart = contentString.distance(from: contentString.startIndex, to: spaceIndex) + 1
            }
        }

        if snippetEnd < content.count {
            let endIndex = contentString.index(contentString.startIndex, offsetBy: snippetEnd)
            if let spaceIndex = contentString[..<endIndex].lastIndex(of: " ") {
                snippetEnd = contentString.distance(from: contentString.startIndex, to: spaceIndex)
            }
        }

        let start = contentString.index(contentString.startIndex, offsetBy: snippetStart)
        let end = contentString.index(contentString.startIndex, offsetBy: min(snippetEnd, contentString.count))

        var snippet = String(contentString[start..<end])

        // Add ellipsis
        if snippetStart > 0 {
            snippet = "..." + snippet
        }
        if snippetEnd < content.count {
            snippet = snippet + "..."
        }

        return snippet
    }

    // MARK: - Suggestions

    func getSuggestions(for query: String, songs: [Song]) -> [String] {
        guard !query.isEmpty else { return [] }

        let lowercased = query.lowercased()
        var suggestions = Set<String>()

        // Title suggestions
        for song in songs {
            if song.title.lowercased().hasPrefix(lowercased) {
                suggestions.insert(song.title)
            }
        }

        // Artist suggestions
        for song in songs {
            if let artist = song.artist, artist.lowercased().hasPrefix(lowercased) {
                suggestions.insert(artist)
            }
        }

        // Key suggestions
        let keys = ["C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"]
        for key in keys {
            if key.lowercased().hasPrefix(lowercased) {
                suggestions.insert(key)
            }
        }

        return Array(suggestions).sorted().prefix(5).map { $0 }
    }
}
