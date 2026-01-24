//
//  SearchRankingEngine.swift
//  Lyra
//
//  Intelligent ranking engine that learns from user behavior
//  Part of Phase 7.4: Search Intelligence
//

import Foundation
import SwiftData

/// Engine for ranking search results with machine learning-inspired scoring
class SearchRankingEngine {

    // MARK: - Properties

    private let fuzzyEngine = FuzzyMatchingEngine()
    private let semanticEngine = SemanticSearchEngine()
    private let contentEngine = ContentSearchEngine()

    // Default weights for ranking factors
    private var weights: SearchWeights

    // Learning data
    private var clickThroughData: [String: [ClickData]] = [:] // query -> click data
    private var popularSongs: [UUID: PopularityScore] = [:] // songID -> popularity

    // MARK: - Initialization

    init(weights: SearchWeights = .default) {
        self.weights = weights
    }

    // MARK: - Main Ranking

    /// Rank search results based on multiple factors
    func rankResults(
        _ songs: [SongMatch],
        query: SearchQuery,
        userContext: SearchContext? = nil
    ) -> [SearchResult] {
        var results: [SearchResult] = []

        for songMatch in songs {
            let factors = calculateRankingFactors(
                songMatch: songMatch,
                query: query,
                userContext: userContext
            )

            let relevance = factors.calculateRelevance(weights: weights)

            let result = SearchResult(
                id: UUID(),
                songID: songMatch.songID,
                title: songMatch.title,
                artist: songMatch.artist,
                relevanceScore: relevance,
                matchType: songMatch.matchType,
                matchedFields: songMatch.matchedFields,
                highlights: songMatch.highlights,
                reasoning: generateReasoning(factors: factors, songMatch: songMatch)
            )

            results.append(result)
        }

        // Sort by relevance
        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    // MARK: - Ranking Factors

    /// Calculate all ranking factors for a song
    private func calculateRankingFactors(
        songMatch: SongMatch,
        query: SearchQuery,
        userContext: SearchContext?
    ) -> SearchRankingFactors {
        var factors = SearchRankingFactors()

        // Text matching score
        factors.textMatchScore = calculateTextMatch(songMatch, query: query.rawQuery)

        // Fuzzy matching score
        factors.fuzzyMatchScore = calculateFuzzyMatch(songMatch, query: query.rawQuery)

        // Semantic similarity score
        factors.semanticScore = calculateSemanticScore(songMatch, query: query)

        // Recency score
        factors.recencyScore = calculateRecencyScore(songMatch)

        // Popularity score
        factors.popularityScore = calculatePopularityScore(songMatch.songID)

        // Personalized score
        if let context = userContext {
            factors.personalizedScore = calculatePersonalizedScore(
                songMatch,
                context: context,
                query: query
            )
        }

        // Field-specific boosts
        factors.fieldBoosts = calculateFieldBoosts(songMatch)

        return factors
    }

    /// Calculate text matching score
    private func calculateTextMatch(_ songMatch: SongMatch, query: String) -> Float {
        var score: Float = 0.0

        // Title exact match
        if songMatch.title.lowercased() == query.lowercased() {
            score += 1.0
        } else if songMatch.title.lowercased().contains(query.lowercased()) {
            score += 0.8
        }

        // Artist exact match
        if let artist = songMatch.artist, artist.lowercased() == query.lowercased() {
            score += 0.8
        }

        // Normalize to 0-1
        return min(1.0, score)
    }

    /// Calculate fuzzy matching score
    private func calculateFuzzyMatch(_ songMatch: SongMatch, query: String) -> Float {
        let titleScore = fuzzyEngine.fuzzyMatch(query, songMatch.title)

        var artistScore: Float = 0.0
        if let artist = songMatch.artist {
            artistScore = fuzzyEngine.matchArtistName(query, artist)
        }

        return max(titleScore, artistScore)
    }

    /// Calculate semantic similarity score
    private func calculateSemanticScore(_ songMatch: SongMatch, query: SearchQuery) -> Float {
        guard let lyrics = songMatch.lyrics else {
            return 0.0
        }

        return semanticEngine.semanticSimilarity(query.rawQuery, lyrics)
    }

    /// Calculate recency score
    private func calculateRecencyScore(_ songMatch: SongMatch) -> Float {
        guard let addedDate = songMatch.dateAdded else {
            return 0.0
        }

        let daysSinceAdded = Date().timeIntervalSince(addedDate) / (24 * 60 * 60)

        // Exponential decay: newer songs get higher scores
        // Score approaches 0 after 365 days
        return Float(exp(-daysSinceAdded / 365.0))
    }

    /// Calculate popularity score
    private func calculatePopularityScore(_ songID: UUID) -> Float {
        guard let popularity = popularSongs[songID] else {
            return 0.0
        }

        // Normalize based on max plays/views
        let maxPlays: Float = 1000.0 // Configurable threshold
        return min(1.0, Float(popularity.playCount) / maxPlays)
    }

    /// Calculate personalized score
    private func calculatePersonalizedScore(
        _ songMatch: SongMatch,
        context: SearchContext,
        query: SearchQuery
    ) -> Float {
        var score: Float = 0.0

        // Recently accessed songs get a boost
        if context.recentSongIDs.contains(songMatch.songID) {
            score += 0.5
        }

        // Preferred keys get a boost
        if let key = songMatch.key, context.preferredKeys.contains(key) {
            score += 0.3
        }

        // Preferred artists get a boost
        if let artist = songMatch.artist, context.preferredArtists.contains(artist) {
            score += 0.4
        }

        return min(1.0, score)
    }

    /// Calculate field-specific boosts
    private func calculateFieldBoosts(_ songMatch: SongMatch) -> [String: Float] {
        var boosts: [String: Float] = [:]

        // Title match is most important
        boosts["title"] = 2.0

        // Artist match is important
        boosts["artist"] = 1.5

        // Lyrics match is moderately important
        boosts["lyrics"] = 1.0

        // Tags are somewhat important
        boosts["tags"] = 0.8

        // Key/chords are less important for text search
        boosts["key"] = 0.5
        boosts["chords"] = 0.5

        return boosts
    }

    // MARK: - Learning from User Behavior

    /// Record a click-through (user selected a search result)
    func recordClickThrough(
        query: String,
        selectedSongID: UUID,
        position: Int,
        allResults: [SearchResult]
    ) {
        let clickData = ClickData(
            selectedSongID: selectedSongID,
            position: position,
            totalResults: allResults.count,
            timestamp: Date()
        )

        if clickThroughData[query] != nil {
            clickThroughData[query]?.append(clickData)
        } else {
            clickThroughData[query] = [clickData]
        }

        // Update popularity score
        updatePopularity(songID: selectedSongID, action: .selected)

        // Learn from this interaction
        learnFromClickThrough(query: query, clickData: clickData)
    }

    /// Record song play (increases popularity)
    func recordSongPlay(songID: UUID) {
        updatePopularity(songID: songID, action: .played)
    }

    /// Record song skip (decreases popularity slightly)
    func recordSongSkip(songID: UUID) {
        updatePopularity(songID: songID, action: .skipped)
    }

    /// Update popularity score for a song
    private func updatePopularity(songID: UUID, action: PopularityAction) {
        var popularity = popularSongs[songID] ?? PopularityScore(songID: songID)

        switch action {
        case .selected:
            popularity.selectionCount += 1
        case .played:
            popularity.playCount += 1
        case .skipped:
            popularity.skipCount += 1
        }

        popularity.lastAccessedAt = Date()
        popularSongs[songID] = popularity
    }

    /// Learn from click-through data to adjust weights
    private func learnFromClickThrough(query: String, clickData: ClickData) {
        // If users consistently select results at lower positions,
        // it suggests our ranking isn't optimal

        guard let allClicks = clickThroughData[query] else {
            return
        }

        // Calculate average click position
        let avgPosition = allClicks.reduce(0) { $0 + $1.position } / allClicks.count

        // If average position is > 3, consider adjusting weights
        if avgPosition > 3 {
            // Users are clicking on lower-ranked results
            // This is a signal that we should adjust our ranking
            // (In a production system, this would trigger ML retraining)
        }
    }

    // MARK: - Dynamic Weight Adjustment

    /// Adjust weights based on query type
    func adjustWeightsForQuery(_ query: SearchQuery) {
        switch query.parsedIntent {
        case .findByKey, .findByTempo, .findByChords:
            // For technical queries, prioritize exact matches
            weights = .exactMatchFocused

        case .findByMood, .findByLyrics:
            // For content queries, prioritize semantic search
            weights = .semanticFocused

        case .findByDate:
            // For date queries, prioritize recency
            weights = .recencyFocused

        case .findSongs, .unknown:
            // Default balanced weights
            weights = .default
        }
    }

    // MARK: - Result Explanation

    /// Generate human-readable reasoning for ranking
    private func generateReasoning(
        factors: SearchRankingFactors,
        songMatch: SongMatch
    ) -> String? {
        var reasons: [String] = []

        if factors.textMatchScore > 0.8 {
            reasons.append("Strong text match in title")
        }

        if factors.fuzzyMatchScore > 0.7 {
            reasons.append("Similar spelling")
        }

        if factors.semanticScore > 0.6 {
            reasons.append("Matching theme or meaning")
        }

        if factors.recencyScore > 0.8 {
            reasons.append("Recently added")
        }

        if factors.popularityScore > 0.6 {
            reasons.append("Popular song")
        }

        if factors.personalizedScore > 0.5 {
            reasons.append("Matches your preferences")
        }

        return reasons.isEmpty ? nil : reasons.joined(separator: ", ")
    }

    // MARK: - Analytics

    /// Get search analytics for a query
    func getQueryAnalytics(query: String) -> QueryAnalytics? {
        guard let clicks = clickThroughData[query] else {
            return nil
        }

        let avgPosition = Float(clicks.reduce(0) { $0 + $1.position }) / Float(clicks.count)

        let clickThroughRate = clicks.isEmpty ? 0.0 : 1.0 // Simplified

        return QueryAnalytics(
            query: query,
            searchCount: clicks.count,
            avgClickPosition: avgPosition,
            clickThroughRate: clickThroughRate,
            topResults: Array(clicks.prefix(5).map { $0.selectedSongID })
        )
    }

    /// Get most popular songs
    func getMostPopularSongs(limit: Int = 10) -> [UUID] {
        return popularSongs
            .sorted { $0.value.playCount > $1.value.playCount }
            .prefix(limit)
            .map { $0.key }
    }

    /// Get personalized recommendations based on search history
    func getRecommendations(
        context: SearchContext,
        limit: Int = 5
    ) -> [UUID] {
        // Simple recommendation based on recently accessed songs
        return Array(context.recentSongIDs.prefix(limit))
    }

    // MARK: - Persistence

    /// Save learning data to UserDefaults
    func saveLearningData() {
        // Encode and save click-through data
        if let encoded = try? JSONEncoder().encode(clickThroughData) {
            UserDefaults.standard.set(encoded, forKey: "searchClickThroughData")
        }

        // Encode and save popularity data
        if let encoded = try? JSONEncoder().encode(popularSongs) {
            UserDefaults.standard.set(encoded, forKey: "songPopularityData")
        }
    }

    /// Load learning data from UserDefaults
    func loadLearningData() {
        // Load click-through data
        if let data = UserDefaults.standard.data(forKey: "searchClickThroughData"),
           let decoded = try? JSONDecoder().decode([String: [ClickData]].self, from: data) {
            clickThroughData = decoded
        }

        // Load popularity data
        if let data = UserDefaults.standard.data(forKey: "songPopularityData"),
           let decoded = try? JSONDecoder().decode([UUID: PopularityScore].self, from: data) {
            popularSongs = decoded
        }
    }
}

// MARK: - Supporting Types

/// Represents a song match before ranking
struct SongMatch {
    let songID: UUID
    let title: String
    let artist: String?
    let key: String?
    let lyrics: String?
    let dateAdded: Date?
    let matchType: SearchResult.MatchType
    let matchedFields: [SearchResult.MatchedField]
    let highlights: [SearchHighlight]
}

/// Click-through data for learning
struct ClickData: Codable {
    let selectedSongID: UUID
    let position: Int // Position in search results (0-indexed)
    let totalResults: Int
    let timestamp: Date
}

/// Popularity scoring for a song
struct PopularityScore: Codable {
    let songID: UUID
    var selectionCount: Int = 0
    var playCount: Int = 0
    var skipCount: Int = 0
    var lastAccessedAt: Date = Date()

    var overallScore: Float {
        // Weighted combination
        let selectionWeight: Float = 2.0
        let playWeight: Float = 3.0
        let skipPenalty: Float = 0.5

        return Float(selectionCount) * selectionWeight +
               Float(playCount) * playWeight -
               Float(skipCount) * skipPenalty
    }
}

/// Actions that affect popularity
enum PopularityAction {
    case selected // User selected in search results
    case played // User played the song
    case skipped // User skipped the song
}

/// Query analytics
struct QueryAnalytics {
    let query: String
    let searchCount: Int
    let avgClickPosition: Float
    let clickThroughRate: Float
    let topResults: [UUID]
}

/// Additional weight presets
extension SearchWeights {
    static let exactMatchFocused = SearchWeights(
        textMatch: 0.50,
        fuzzyMatch: 0.10,
        semantic: 0.10,
        recency: 0.10,
        popularity: 0.15,
        personalized: 0.05
    )
}
