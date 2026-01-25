//
//  SearchModels.swift
//  Lyra
//
//  Data models for AI-powered search system
//  Part of Phase 7.4: Search Intelligence
//

import Foundation

// MARK: - Search Result

/// A single search result with relevance scoring
struct SearchResult: Identifiable, Codable, Equatable {
    var id: UUID
    var songID: UUID
    var title: String
    var artist: String?
    var relevanceScore: Float
    var matchType: MatchType
    var matchedFields: [MatchedField]
    var highlights: [SearchHighlight]
    var reasoning: String?

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }

    enum MatchType: String, Codable {
        case exact = "Exact Match"
        case fuzzy = "Fuzzy Match"
        case semantic = "Semantic Match"
        case partial = "Partial Match"
        case phonetic = "Sounds Like"
        case content = "Content Match"
    }

    struct MatchedField: Codable {
        var fieldName: String
        var matchScore: Float
        var snippet: String?
    }
}

// MARK: - Search Highlight

/// Highlighted text in search results
struct SearchHighlight: Identifiable, Codable {
    var id = UUID()
    var fieldName: String
    var text: String
    var ranges: [Range<Int>]

    enum CodingKeys: String, CodingKey {
        case id, fieldName, text, ranges
    }

    init(id: UUID = UUID(), fieldName: String, text: String, ranges: [Range<Int>]) {
        self.id = id
        self.fieldName = fieldName
        self.text = text
        self.ranges = ranges
    }

    // Custom Codable implementation for Range
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        fieldName = try container.decode(String.self, forKey: .fieldName)
        text = try container.decode(String.self, forKey: .text)

        let rangeData = try container.decode([[Int]].self, forKey: .ranges)
        ranges = rangeData.compactMap { arr in
            guard arr.count == 2 else { return nil }
            return arr[0]..<arr[1]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fieldName, forKey: .fieldName)
        try container.encode(text, forKey: .text)

        let rangeData = ranges.map { [$0.lowerBound, $0.upperBound] }
        try container.encode(rangeData, forKey: .ranges)
    }
}

// MARK: - Search Query

/// Parsed natural language search query
struct SearchQuery: Codable {
    var rawQuery: String
    var parsedIntent: SearchIntent
    var filters: [SearchFilter]
    var sortBy: SortCriteria?
    var sentiment: Sentiment?
    var timestamp: Date

    enum SearchIntent: String, Codable {
        case findSongs = "Find Songs"
        case findByKey = "Find by Key"
        case findByTempo = "Find by Tempo"
        case findByMood = "Find by Mood"
        case findByDate = "Find by Date"
        case findByChords = "Find by Chords"
        case findByLyrics = "Find by Lyrics"
        case unknown = "General Search"
    }

    enum Sentiment: String, Codable {
        case positive = "Positive"
        case negative = "Negative"
        case neutral = "Neutral"
    }

    enum SortCriteria: String, Codable {
        case relevance = "Relevance"
        case title = "Title"
        case artist = "Artist"
        case recentlyPlayed = "Recently Played"
        case recentlyAdded = "Recently Added"
        case tempo = "Tempo"
        case key = "Key"
    }
}

// MARK: - Search Filter

/// A filter extracted from search query
struct SearchFilter: Codable, Equatable {
    var type: FilterType
    var value: String
    var operator_: FilterOperator

    enum FilterType: String, Codable {
        case key = "Key"
        case capo = "Capo"
        case tempo = "Tempo"
        case artist = "Artist"
        case tag = "Tag"
        case setlist = "Setlist"
        case dateAdded = "Date Added"
        case dateModified = "Date Modified"
        case mood = "Mood"
        case timeSignature = "Time Signature"
        case lyrics = "Lyrics"
        case chords = "Chords"
    }

    enum FilterOperator: String, Codable {
        case equals = "="
        case contains = "contains"
        case greaterThan = ">"
        case lessThan = "<"
        case between = "between"
    }
}

// MARK: - Search Suggestion

/// Autocomplete or related search suggestion
struct SearchSuggestion: Identifiable, Codable {
    var id = UUID()
    var text: String
    var type: SuggestionType
    var confidence: Float
    var reasoning: String?

    enum SuggestionType: String, Codable {
        case autocomplete = "Autocomplete"
        case relatedSearch = "Related Search"
        case popularSearch = "Popular Search"
        case recentSearch = "Recent Search"
        case aiSuggested = "AI Suggested"
    }
}

// MARK: - Search History Entry

/// A record of a search query and its results
struct SearchHistoryEntry: Identifiable, Codable {
    var id = UUID()
    var query: String
    var parsedQuery: SearchQuery?
    var resultCount: Int
    var selectedResultID: UUID?
    var timestamp: Date
    var wasSuccessful: Bool

    var success: Bool {
        resultCount > 0 && selectedResultID != nil
    }
}

// MARK: - Search Analytics

/// Analytics data for improving search
struct SearchAnalytics: Codable {
    var totalSearches: Int
    var successfulSearches: Int
    var failedSearches: Int
    var averageResultCount: Float
    var popularQueries: [String: Int]
    var popularFilters: [SearchFilter.FilterType: Int]
    var clickThroughRate: Float
    var lastUpdated: Date

    var successRate: Float {
        guard totalSearches > 0 else { return 0 }
        return Float(successfulSearches) / Float(totalSearches)
    }
}

// MARK: - Search Ranking Factors

/// Factors used to rank search results
struct SearchRankingFactors: Codable {
    var textMatchScore: Float = 0.0
    var fuzzyMatchScore: Float = 0.0
    var semanticScore: Float = 0.0
    var recencyScore: Float = 0.0
    var popularityScore: Float = 0.0
    var personalizedScore: Float = 0.0
    var fieldBoosts: [String: Float] = [:]

    /// Calculate combined relevance score
    func calculateRelevance(weights: SearchWeights = .default) -> Float {
        return (textMatchScore * weights.textMatch) +
               (fuzzyMatchScore * weights.fuzzyMatch) +
               (semanticScore * weights.semantic) +
               (recencyScore * weights.recency) +
               (popularityScore * weights.popularity) +
               (personalizedScore * weights.personalized)
    }
}

// MARK: - Search Weights

/// Configurable weights for ranking factors
struct SearchWeights: Codable {
    var textMatch: Float
    var fuzzyMatch: Float
    var semantic: Float
    var recency: Float
    var popularity: Float
    var personalized: Float

    static let `default` = SearchWeights(
        textMatch: 0.35,
        fuzzyMatch: 0.20,
        semantic: 0.20,
        recency: 0.10,
        popularity: 0.10,
        personalized: 0.05
    )

    static let semanticFocused = SearchWeights(
        textMatch: 0.25,
        fuzzyMatch: 0.15,
        semantic: 0.40,
        recency: 0.08,
        popularity: 0.07,
        personalized: 0.05
    )

    static let recencyFocused = SearchWeights(
        textMatch: 0.30,
        fuzzyMatch: 0.15,
        semantic: 0.15,
        recency: 0.25,
        popularity: 0.10,
        personalized: 0.05
    )
}

// MARK: - Voice Search Request

/// Voice search input and transcription
struct VoiceSearchRequest: Identifiable {
    var id = UUID()
    var transcription: String?
    var confidence: Float?
    var isListening: Bool
    var error: String?
    var timestamp: Date
}

// MARK: - Smart Filter Suggestion

/// AI-suggested filter based on query context
struct SmartFilterSuggestion: Identifiable {
    var id = UUID()
    var filter: SearchFilter
    var reasoning: String
    var confidence: Float
    var isApplied: Bool = false
}

// MARK: - Search Context

/// Context for personalized search
struct SearchContext: Codable {
    var recentSearches: [String]
    var recentSongIDs: [UUID]
    var preferredKeys: [String]
    var preferredArtists: [String]
    var searchHistory: [SearchHistoryEntry]
    var lastUpdated: Date

    /// Get most common search patterns
    func getSearchPatterns() -> [String: Int] {
        var patterns: [String: Int] = [:]

        for search in recentSearches {
            let lowercased = search.lowercased()
            patterns[lowercased, default: 0] += 1
        }

        return patterns.sorted { $0.value > $1.value }
            .prefix(10)
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
}

// MARK: - Mood Category

/// Mood/sentiment categories for songs
enum MoodCategory: String, Codable, CaseIterable {
    case joyful = "Joyful"
    case peaceful = "Peaceful"
    case hopeful = "Hopeful"
    case energetic = "Energetic"
    case melancholic = "Melancholic"
    case reflective = "Reflective"
    case worship = "Worship"
    case celebratory = "Celebratory"
    case comforting = "Comforting"
    case triumphant = "Triumphant"

    var keywords: [String] {
        switch self {
        case .joyful:
            return ["happy", "joy", "joyful", "cheerful", "glad", "delight"]
        case .peaceful:
            return ["peace", "peaceful", "calm", "quiet", "still", "rest"]
        case .hopeful:
            return ["hope", "hopeful", "promise", "future", "trust", "believe"]
        case .energetic:
            return ["energy", "power", "strong", "mighty", "victorious", "triumphant"]
        case .melancholic:
            return ["sad", "sorrow", "grief", "mourn", "weep", "tears"]
        case .reflective:
            return ["reflect", "think", "ponder", "meditate", "consider", "wonder"]
        case .worship:
            return ["worship", "praise", "adore", "exalt", "glorify", "honor"]
        case .celebratory:
            return ["celebrate", "rejoice", "sing", "shout", "dance", "festival"]
        case .comforting:
            return ["comfort", "heal", "restore", "tender", "gentle", "kindness"]
        case .triumphant:
            return ["victory", "triumph", "conquer", "overcome", "win", "prevail"]
        }
    }

    var color: String {
        switch self {
        case .joyful: return "yellow"
        case .peaceful: return "blue"
        case .hopeful: return "cyan"
        case .energetic: return "orange"
        case .melancholic: return "indigo"
        case .reflective: return "purple"
        case .worship: return "gold"
        case .celebratory: return "pink"
        case .comforting: return "green"
        case .triumphant: return "red"
        }
    }
}

// MARK: - Tempo Category

/// Tempo categories for filtering
enum SearchSearchTempoCategory: String, Codable, CaseIterable {
    case verySlow = "Very Slow"
    case slow = "Slow"
    case moderate = "Moderate"
    case fast = "Fast"
    case veryFast = "Very Fast"

    var bpmRange: ClosedRange<Int> {
        switch self {
        case .verySlow: return 0...60
        case .slow: return 61...90
        case .moderate: return 91...120
        case .fast: return 121...150
        case .veryFast: return 151...300
        }
    }

    var keywords: [String] {
        switch self {
        case .verySlow: return ["very slow", "largo", "grave", "ballad"]
        case .slow: return ["slow", "adagio", "andante"]
        case .moderate: return ["moderate", "moderato", "medium"]
        case .fast: return ["fast", "allegro", "upbeat"]
        case .veryFast: return ["very fast", "presto", "vivace"]
        }
    }
}

// MARK: - Phonetic Encoding

/// Phonetic encoding for sounds-like matching
struct PhoneticEncoding: Codable {
    var original: String
    var soundex: String
    var metaphone: String?

    /// Check if two words sound similar
    func soundsLike(_ other: PhoneticEncoding) -> Bool {
        return soundex == other.soundex
    }
}
