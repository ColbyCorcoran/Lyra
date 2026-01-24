//
//  NaturalLanguageParser.swift
//  Lyra
//
//  Natural language query parsing and intent detection
//  Part of Phase 7.4: Search Intelligence
//

import Foundation
import NaturalLanguage

/// Parses natural language queries to extract search intent and parameters
class NaturalLanguageParser {

    // MARK: - Properties

    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .lemma])
    private let semanticEngine = SemanticSearchEngine()

    // MARK: - Query Parsing

    /// Parse natural language query into structured SearchQuery
    func parseQuery(_ queryText: String) -> SearchQuery {
        let normalized = queryText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Detect intent
        let intent = detectIntent(normalized)

        // Extract filters
        let filters = extractFilters(normalized)

        // Detect sort preference
        let sortBy = detectSortCriteria(normalized)

        // Analyze sentiment
        let sentiment = semanticEngine.analyzeSentiment(normalized)

        return SearchQuery(
            rawQuery: queryText,
            parsedIntent: intent,
            filters: filters,
            sortBy: sortBy,
            sentiment: sentiment,
            timestamp: Date()
        )
    }

    // MARK: - Intent Detection

    /// Detect the primary intent of the search query
    func detectIntent(_ query: String) -> SearchQuery.SearchIntent {
        let lowercased = query.lowercased()

        // Key-based search patterns
        if matchesPattern(lowercased, patterns: [
            "in [A-G][#b]?",
            "key of [A-G]",
            "[A-G] (major|minor)",
            "songs? in [A-G]"
        ]) {
            return .findByKey
        }

        // Tempo-based search patterns
        if matchesPattern(lowercased, patterns: [
            "fast",
            "slow",
            "upbeat",
            "ballad",
            "tempo",
            "bpm",
            "\\d+ bpm"
        ]) {
            return .findByTempo
        }

        // Mood-based search patterns
        if matchesPattern(lowercased, patterns: [
            "happy",
            "sad",
            "joyful",
            "peaceful",
            "worship",
            "celebrat",
            "reflective",
            "mood",
            "feeling"
        ]) {
            return .findByMood
        }

        // Date-based search patterns
        if matchesPattern(lowercased, patterns: [
            "recent",
            "new",
            "last week",
            "this month",
            "added (today|yesterday)",
            "\\d{4}",
            "january|february|march|april|may|june|july|august|september|october|november|december"
        ]) {
            return .findByDate
        }

        // Chord-based search patterns
        if matchesPattern(lowercased, patterns: [
            "chord",
            "progression",
            "uses [A-G]",
            "contains [A-G]"
        ]) {
            return .findByChords
        }

        // Lyrics-based search patterns
        if matchesPattern(lowercased, patterns: [
            "lyrics",
            "words",
            "says",
            "with the words",
            "contains"
        ]) {
            return .findByLyrics
        }

        // Default to general search
        return .findSongs
    }

    /// Check if query matches any of the given regex patterns
    private func matchesPattern(_ text: String, patterns: [String]) -> Bool {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if regex.firstMatch(in: text, range: range) != nil {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Filter Extraction

    /// Extract filters from natural language query
    func extractFilters(_ query: String) -> [SearchFilter] {
        var filters: [SearchFilter] = []

        // Extract key filter
        if let keyFilter = extractKeyFilter(query) {
            filters.append(keyFilter)
        }

        // Extract tempo filter
        if let tempoFilter = extractTempoFilter(query) {
            filters.append(tempoFilter)
        }

        // Extract capo filter
        if let capoFilter = extractCapoFilter(query) {
            filters.append(capoFilter)
        }

        // Extract artist filter
        if let artistFilter = extractArtistFilter(query) {
            filters.append(artistFilter)
        }

        // Extract tag filter
        if let tagFilter = extractTagFilter(query) {
            filters.append(tagFilter)
        }

        // Extract mood filter
        if let moodFilter = extractMoodFilter(query) {
            filters.append(moodFilter)
        }

        // Extract time signature filter
        if let timeSignatureFilter = extractTimeSignatureFilter(query) {
            filters.append(timeSignatureFilter)
        }

        return filters
    }

    /// Extract musical key from query
    private func extractKeyFilter(_ query: String) -> SearchFilter? {
        // Pattern: "in C", "key of G", "C major", "Dm", etc.
        let pattern = #"(?:in|key of|key:)?\s*([A-G][#b]?)\s*(?:major|minor|m)?"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) else {
            return nil
        }

        let nsString = query as NSString
        let keyString = nsString.substring(with: match.range(at: 1))

        return SearchFilter(
            type: .key,
            value: keyString,
            operator_: .equals
        )
    }

    /// Extract tempo filter from query
    private func extractTempoFilter(_ query: String) -> SearchFilter? {
        let lowercased = query.lowercased()

        // Check for specific BPM
        if let bpmMatch = lowercased.range(of: #"\d+\s*bpm"#, options: .regularExpression) {
            let bpmString = String(lowercased[bpmMatch])
                .replacingOccurrences(of: "bpm", with: "")
                .trimmingCharacters(in: .whitespaces)

            return SearchFilter(
                type: .tempo,
                value: bpmString,
                operator_: .equals
            )
        }

        // Check for tempo descriptors
        if lowercased.contains("fast") || lowercased.contains("upbeat") {
            return SearchFilter(
                type: .tempo,
                value: "120",
                operator_: .greaterThan
            )
        }

        if lowercased.contains("slow") || lowercased.contains("ballad") {
            return SearchFilter(
                type: .tempo,
                value: "90",
                operator_: .lessThan
            )
        }

        return nil
    }

    /// Extract capo filter from query
    private func extractCapoFilter(_ query: String) -> SearchFilter? {
        // Pattern: "capo 2", "no capo", "with capo", etc.
        let pattern = #"capo\s*(\d+|none|no)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) else {
            return nil
        }

        let nsString = query as NSString
        let capoString = nsString.substring(with: match.range(at: 1))

        if capoString.lowercased() == "none" || capoString.lowercased() == "no" {
            return SearchFilter(
                type: .capo,
                value: "0",
                operator_: .equals
            )
        }

        return SearchFilter(
            type: .capo,
            value: capoString,
            operator_: .equals
        )
    }

    /// Extract artist filter from query
    private func extractArtistFilter(_ query: String) -> SearchFilter? {
        // Pattern: "by [artist]", "from [artist]", "[artist] songs"
        let patterns = [
            #"(?:by|from)\s+([A-Z][a-zA-Z\s&]+)"#,
            #"([A-Z][a-zA-Z\s&]+)\s+songs"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) {
                let nsString = query as NSString
                let artistString = nsString.substring(with: match.range(at: 1))
                    .trimmingCharacters(in: .whitespaces)

                return SearchFilter(
                    type: .artist,
                    value: artistString,
                    operator_: .equals
                )
            }
        }

        return nil
    }

    /// Extract tag filter from query
    private func extractTagFilter(_ query: String) -> SearchFilter? {
        // Pattern: "tagged [tag]", "with tag [tag]", "#[tag]"
        let patterns = [
            #"(?:tagged|with tag)\s+([a-zA-Z]+)"#,
            #"#([a-zA-Z]+)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) {
                let nsString = query as NSString
                let tagString = nsString.substring(with: match.range(at: 1))

                return SearchFilter(
                    type: .tag,
                    value: tagString,
                    operator_: .contains
                )
            }
        }

        return nil
    }

    /// Extract mood filter from query
    private func extractMoodFilter(_ query: String) -> SearchFilter? {
        let moods = semanticEngine.detectMood(query)

        guard let primaryMood = moods.first else {
            return nil
        }

        return SearchFilter(
            type: .mood,
            value: primaryMood.rawValue,
            operator_: .equals
        )
    }

    /// Extract time signature filter from query
    private func extractTimeSignatureFilter(_ query: String) -> SearchFilter? {
        // Pattern: "4/4", "3/4", "6/8", etc.
        let pattern = #"(\d+/\d+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) else {
            return nil
        }

        let nsString = query as NSString
        let timeSignature = nsString.substring(with: match.range(at: 1))

        return SearchFilter(
            type: .timeSignature,
            value: timeSignature,
            operator_: .equals
        )
    }

    // MARK: - Sort Detection

    /// Detect preferred sort order from query
    func detectSortCriteria(_ query: String) -> SearchQuery.SortCriteria? {
        let lowercased = query.lowercased()

        if lowercased.contains("recent") || lowercased.contains("newest") || lowercased.contains("latest") {
            return .recentlyAdded
        }

        if lowercased.contains("played") || lowercased.contains("last played") {
            return .recentlyPlayed
        }

        if lowercased.contains("alphabetical") || lowercased.contains("a-z") || lowercased.contains("title") {
            return .title
        }

        if lowercased.contains("artist") {
            return .artist
        }

        if lowercased.contains("tempo") || lowercased.contains("bpm") {
            return .tempo
        }

        if lowercased.contains("key") {
            return .key
        }

        // Default to relevance
        return .relevance
    }

    // MARK: - Query Expansion

    /// Expand query with synonyms and related terms
    func expandQuery(_ query: String) -> [String] {
        return semanticEngine.expandQuery(query)
    }

    // MARK: - Entity Extraction

    /// Extract named entities from query (song titles, artists, etc.)
    func extractEntities(_ query: String) -> [String: [String]] {
        tagger.string = query

        var entities: [String: [String]] = [
            "persons": [],
            "organizations": [],
            "places": []
        ]

        tagger.enumerateTags(
            in: query.startIndex..<query.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            if let tag = tag {
                let entity = String(query[range])

                switch tag {
                case .personalName:
                    entities["persons"]?.append(entity)
                case .organizationName:
                    entities["organizations"]?.append(entity)
                case .placeName:
                    entities["places"]?.append(entity)
                default:
                    break
                }
            }
            return true
        }

        return entities
    }

    // MARK: - Query Cleaning

    /// Clean and normalize query text
    func cleanQuery(_ query: String) -> String {
        var cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove extra whitespace
        cleaned = cleaned.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        // Remove special characters (keep letters, numbers, spaces, common punctuation)
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "#-'\""))

        cleaned = String(cleaned.unicodeScalars.filter { allowedCharacters.contains($0) })

        return cleaned
    }

    // MARK: - Query Suggestions

    /// Generate query correction suggestions
    func suggestCorrections(_ query: String) -> [String] {
        var suggestions: [String] = []

        // Split into words
        let words = query.split(separator: " ").map(String.init)

        // Check for common misspellings
        let commonMisspellings: [String: String] = [
            "amayzing": "amazing",
            "grays": "grace",
            "thow": "thou",
            "grait": "great",
            "gud": "good",
            "wurship": "worship",
            "prays": "praise"
        ]

        var correctedWords = words
        var hasSuggestions = false

        for (index, word) in words.enumerated() {
            let lowercased = word.lowercased()

            // Check exact misspelling match
            if let correction = commonMisspellings[lowercased] {
                correctedWords[index] = correction
                hasSuggestions = true
            }
        }

        if hasSuggestions {
            suggestions.append(correctedWords.joined(separator: " "))
        }

        return suggestions
    }

    // MARK: - Question Detection

    /// Detect if query is a question and extract question type
    func detectQuestion(_ query: String) -> (isQuestion: Bool, type: String?) {
        let lowercased = query.lowercased()

        // Question words
        let questionWords = [
            "what", "when", "where", "who", "which", "how", "why"
        ]

        for word in questionWords {
            if lowercased.hasPrefix(word) {
                return (true, word)
            }
        }

        // Check for question mark
        if query.hasSuffix("?") {
            return (true, "unknown")
        }

        return (false, nil)
    }

    // MARK: - Context Understanding

    /// Understand query in context of search history
    func parseWithContext(
        _ query: String,
        previousQueries: [String],
        recentResults: [SearchResult]
    ) -> SearchQuery {
        var parsedQuery = parseQuery(query)

        // Detect follow-up queries
        let lowercased = query.lowercased()

        if lowercased.starts(with: "also ") ||
           lowercased.starts(with: "and ") ||
           lowercased.starts(with: "or ") {
            // This is a refinement of the previous query
            if let previousQuery = previousQueries.last {
                let previousParsed = parseQuery(previousQuery)

                // Inherit filters from previous query
                parsedQuery.filters.append(contentsOf: previousParsed.filters)
            }
        }

        // Detect "more like this" queries
        if lowercased.contains("similar") ||
           lowercased.contains("like this") ||
           lowercased.contains("more like") {
            // Use most recent result as reference
            if let recentResult = recentResults.first {
                // Add filters based on recent result attributes
                // (would need access to song metadata)
            }
        }

        return parsedQuery
    }

    // MARK: - Advanced Pattern Matching

    /// Match complex query patterns
    func matchComplexPattern(_ query: String) -> SearchQuery.SearchIntent? {
        let lowercased = query.lowercased()

        // Pattern: "songs for [occasion]"
        if lowercased.contains("songs for") {
            if lowercased.contains("christmas") || lowercased.contains("easter") ||
               lowercased.contains("wedding") || lowercased.contains("funeral") {
                return .findByMood
            }
        }

        // Pattern: "I need [type] songs"
        if lowercased.contains("i need") || lowercased.contains("i want") {
            return .findSongs
        }

        // Pattern: "show me [description]"
        if lowercased.contains("show me") || lowercased.contains("find") {
            return .findSongs
        }

        return nil
    }
}
