//
//  SearchSuggestionEngine.swift
//  Lyra
//
//  Intelligent autocomplete and search suggestions
//  Part of Phase 7.4: Search Intelligence
//

import Foundation

/// Engine for generating intelligent search suggestions and autocomplete
class SearchSuggestionEngine {

    // MARK: - Properties

    private let fuzzyEngine = FuzzyMatchingEngine()
    private let parser = NaturalLanguageParser()

    // Cache of suggestions
    private var suggestionCache: [String: [SearchSuggestion]] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes

    // Popular searches
    private var popularSearches: [String: Int] = [:]  // query -> count

    // Recent searches (per-user)
    private var recentSearches: [String] = []
    private let maxRecentSearches = 50

    // MARK: - Autocomplete

    /// Generate autocomplete suggestions as user types
    func generateAutocompleteSuggestions(
        for query: String,
        songTitles: [String],
        artists: [String],
        limit: Int = 5
    ) -> [SearchSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return getRecentSearchSuggestions(limit: limit)
        }

        // Check cache
        if let cached = getCachedSuggestions(query: trimmedQuery) {
            return Array(cached.prefix(limit))
        }

        var suggestions: [SearchSuggestion] = []

        // 1. Exact prefix matches from song titles
        let titleMatches = songTitles.filter {
            $0.lowercased().hasPrefix(trimmedQuery.lowercased())
        }

        for title in titleMatches.prefix(3) {
            suggestions.append(SearchSuggestion(
                text: title,
                type: .autocomplete,
                confidence: 1.0,
                reasoning: "Song title"
            ))
        }

        // 2. Exact prefix matches from artists
        let artistMatches = artists.filter {
            $0.lowercased().hasPrefix(trimmedQuery.lowercased())
        }

        for artist in artistMatches.prefix(2) {
            suggestions.append(SearchSuggestion(
                text: artist,
                type: .autocomplete,
                confidence: 0.95,
                reasoning: "Artist name"
            ))
        }

        // 3. Fuzzy matches if not enough exact matches
        if suggestions.count < limit {
            let fuzzyMatches = getFuzzyMatches(
                query: trimmedQuery,
                candidates: songTitles + artists,
                limit: limit - suggestions.count
            )
            suggestions.append(contentsOf: fuzzyMatches)
        }

        // 4. Popular searches that match
        let popularMatches = getPopularSearchMatches(query: trimmedQuery, limit: 2)
        suggestions.append(contentsOf: popularMatches)

        // Cache and return
        cacheSuggestions(query: trimmedQuery, suggestions: suggestions)

        return Array(suggestions.prefix(limit))
    }

    // MARK: - Related Searches

    /// Generate related search suggestions based on current query
    func generateRelatedSearches(
        for query: String,
        context: SearchContext?,
        limit: Int = 5
    ) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []

        // Parse the query to understand intent
        let parsedQuery = parser.parseQuery(query)

        // 1. Suggest refinements based on filters
        if parsedQuery.filters.isEmpty {
            // Suggest adding filters
            suggestions.append(SearchSuggestion(
                text: "\(query) in C",
                type: .relatedSearch,
                confidence: 0.8,
                reasoning: "Add key filter"
            ))

            suggestions.append(SearchSuggestion(
                text: "\(query) fast",
                type: .relatedSearch,
                confidence: 0.7,
                reasoning: "Add tempo filter"
            ))
        }

        // 2. Suggest alternative queries
        let alternatives = generateAlternativeQueries(parsedQuery)
        suggestions.append(contentsOf: alternatives)

        // 3. Suggest based on user history
        if let context = context {
            let historyBasedSuggestions = getSuggestionsFromHistory(
                query: query,
                context: context
            )
            suggestions.append(contentsOf: historyBasedSuggestions)
        }

        // 4. Suggest popular related searches
        let popularRelated = getPopularRelatedSearches(query: query)
        suggestions.append(contentsOf: popularRelated)

        return Array(suggestions.prefix(limit))
    }

    // MARK: - AI Suggestions

    /// Generate AI-powered suggestions based on context
    func generateAISuggestions(
        context: SearchContext,
        currentTime: Date = Date(),
        limit: Int = 3
    ) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []

        // Time-based suggestions
        let timeOfDay = Calendar.current.component(.hour, from: currentTime)

        if timeOfDay >= 6 && timeOfDay < 12 {
            // Morning
            suggestions.append(SearchSuggestion(
                text: "uplifting worship songs",
                type: .aiSuggested,
                confidence: 0.7,
                reasoning: "Good morning! Start your day with uplifting music"
            ))
        } else if timeOfDay >= 18 && timeOfDay < 22 {
            // Evening
            suggestions.append(SearchSuggestion(
                text: "peaceful reflective songs",
                type: .aiSuggested,
                confidence: 0.7,
                reasoning: "Evening reflection time"
            ))
        }

        // Pattern-based suggestions from user history
        let patterns = context.getSearchPatterns()

        if let commonKey = getMostCommonValue(patterns) {
            suggestions.append(SearchSuggestion(
                text: "songs in \(commonKey)",
                type: .aiSuggested,
                confidence: 0.8,
                reasoning: "You often search for this"
            ))
        }

        // Suggest exploring new content
        if context.recentSearches.count > 10 {
            suggestions.append(SearchSuggestion(
                text: "recent additions",
                type: .aiSuggested,
                confidence: 0.6,
                reasoning: "Discover newly added songs"
            ))
        }

        return Array(suggestions.prefix(limit))
    }

    // MARK: - Helper Methods

    /// Get fuzzy matches for autocomplete
    private func getFuzzyMatches(
        query: String,
        candidates: [String],
        limit: Int
    ) -> [SearchSuggestion] {
        var scoredCandidates: [(String, Float)] = []

        for candidate in candidates {
            let score = fuzzyEngine.prefixMatch(query, candidate)
            if score > 0.5 {
                scoredCandidates.append((candidate, score))
            }
        }

        return scoredCandidates
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { candidate, score in
                SearchSuggestion(
                    text: candidate,
                    type: .autocomplete,
                    confidence: score,
                    reasoning: "Similar to your search"
                )
            }
    }

    /// Get popular searches that match query
    private func getPopularSearchMatches(query: String, limit: Int) -> [SearchSuggestion] {
        let matches = popularSearches
            .filter { $0.key.lowercased().contains(query.lowercased()) }
            .sorted { $0.value > $1.value }
            .prefix(limit)

        return matches.map { searchQuery, count in
            SearchSuggestion(
                text: searchQuery,
                type: .popularSearch,
                confidence: 0.9,
                reasoning: "Searched \(count) times"
            )
        }
    }

    /// Generate alternative query formulations
    private func generateAlternativeQueries(_ parsedQuery: SearchQuery) -> [SearchSuggestion] {
        var alternatives: [SearchSuggestion] = []

        // Expand with synonyms
        let expansions = parser.expandQuery(parsedQuery.rawQuery)

        for expansion in expansions.prefix(2) {
            if expansion != parsedQuery.rawQuery.lowercased() {
                alternatives.append(SearchSuggestion(
                    text: expansion,
                    type: .relatedSearch,
                    confidence: 0.75,
                    reasoning: "Similar meaning"
                ))
            }
        }

        return alternatives
    }

    /// Get suggestions based on search history
    private func getSuggestionsFromHistory(
        query: String,
        context: SearchContext
    ) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []

        // Find related searches from history
        let relatedHistorySearches = context.recentSearches.filter { historical in
            historical.lowercased().contains(query.lowercased()) ||
            query.lowercased().contains(historical.lowercased())
        }

        for historical in relatedHistorySearches.prefix(2) {
            suggestions.append(SearchSuggestion(
                text: historical,
                type: .recentSearch,
                confidence: 0.85,
                reasoning: "You searched this before"
            ))
        }

        return suggestions
    }

    /// Get popular related searches
    private func getPopularRelatedSearches(query: String) -> [SearchSuggestion] {
        // Simplified: In production, would use collaborative filtering
        // to find what users who searched for X also searched for

        var related: [SearchSuggestion] = []

        // Common query patterns
        let commonRefinements = [
            "with chords",
            "lyrics only",
            "no capo",
            "easy version"
        ]

        for refinement in commonRefinements.prefix(2) {
            let combinedQuery = "\(query) \(refinement)"

            related.append(SearchSuggestion(
                text: combinedQuery,
                type: .relatedSearch,
                confidence: 0.65,
                reasoning: "Common refinement"
            ))
        }

        return related
    }

    /// Get recent search suggestions
    private func getRecentSearchSuggestions(limit: Int) -> [SearchSuggestion] {
        return recentSearches
            .prefix(limit)
            .map { query in
                SearchSuggestion(
                    text: query,
                    type: .recentSearch,
                    confidence: 1.0,
                    reasoning: "Recent search"
                )
            }
    }

    /// Get most common value from patterns dictionary
    private func getMostCommonValue(_ patterns: [String: Int]) -> String? {
        return patterns.max { $0.value < $1.value }?.key
    }

    // MARK: - Caching

    /// Get cached suggestions if available and not expired
    private func getCachedSuggestions(query: String) -> [SearchSuggestion]? {
        return suggestionCache[query]
        // In production, would check expiration timestamp
    }

    /// Cache suggestions for a query
    private func cacheSuggestions(query: String, suggestions: [SearchSuggestion]) {
        suggestionCache[query] = suggestions

        // Limit cache size
        if suggestionCache.count > 100 {
            // Remove oldest entries (simplified - would use LRU in production)
            let keysToRemove = Array(suggestionCache.keys.prefix(20))
            for key in keysToRemove {
                suggestionCache.removeValue(forKey: key)
            }
        }
    }

    // MARK: - Learning

    /// Record a search query
    func recordSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return }

        // Add to recent searches
        if !recentSearches.contains(trimmed) {
            recentSearches.insert(trimmed, at: 0)

            // Limit size
            if recentSearches.count > maxRecentSearches {
                recentSearches = Array(recentSearches.prefix(maxRecentSearches))
            }
        }

        // Update popularity count
        popularSearches[trimmed, default: 0] += 1
    }

    /// Clear recent searches
    func clearRecentSearches() {
        recentSearches.removeAll()
    }

    /// Get recent searches
    func getRecentSearches() -> [String] {
        return recentSearches
    }

    // MARK: - Query Correction

    /// Suggest corrections for misspelled queries
    func suggestCorrections(for query: String) -> [SearchSuggestion] {
        let corrections = parser.suggestCorrections(query)

        return corrections.map { correction in
            SearchSuggestion(
                text: correction,
                type: .autocomplete,
                confidence: 0.9,
                reasoning: "Did you mean?"
            )
        }
    }

    // MARK: - Trending Searches

    /// Get currently trending searches
    func getTrendingSearches(limit: Int = 5, timeWindow: TimeInterval = 86400) -> [SearchSuggestion] {
        // Simplified: In production, would track searches over time
        // and identify queries with increasing frequency

        let trending = popularSearches
            .sorted { $0.value > $1.value }
            .prefix(limit)

        return trending.map { query, count in
            SearchSuggestion(
                text: query,
                type: .popularSearch,
                confidence: 0.95,
                reasoning: "Trending now (\(count) searches)"
            )
        }
    }

    // MARK: - Category Suggestions

    /// Generate suggestions for specific categories
    func generateCategorySuggestions(category: String, limit: Int = 5) -> [SearchSuggestion] {
        let categoryKeywords: [String: [String]] = [
            "worship": ["praise", "adoration", "glory", "hallelujah", "holy"],
            "christmas": ["joy to the world", "silent night", "o come", "angels"],
            "easter": ["resurrection", "risen", "victory", "cross", "tomb"],
            "thanksgiving": ["grateful", "thankful", "blessings", "harvest"],
            "communion": ["bread", "cup", "sacrifice", "remember"]
        ]

        guard let keywords = categoryKeywords[category.lowercased()] else {
            return []
        }

        return keywords.prefix(limit).map { keyword in
            SearchSuggestion(
                text: keyword,
                type: .aiSuggested,
                confidence: 0.8,
                reasoning: "\(category.capitalized) song"
            )
        }
    }

    // MARK: - Persistence

    /// Save suggestion data
    func saveSuggestionData() {
        // Save recent searches
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")

        // Save popular searches
        if let encoded = try? JSONEncoder().encode(popularSearches) {
            UserDefaults.standard.set(encoded, forKey: "popularSearches")
        }
    }

    /// Load suggestion data
    func loadSuggestionData() {
        // Load recent searches
        if let recent = UserDefaults.standard.array(forKey: "recentSearches") as? [String] {
            recentSearches = recent
        }

        // Load popular searches
        if let data = UserDefaults.standard.data(forKey: "popularSearches"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            popularSearches = decoded
        }
    }
}
