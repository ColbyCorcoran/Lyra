//
//  RecommendationManager.swift
//  Lyra
//
//  Phase 7.5: Recommendation Intelligence
//  Orchestrates all recommendation engines and provides unified API
//  Created on January 24, 2026
//

import Foundation
import SwiftData

/// Orchestrates all recommendation engines
@MainActor
class RecommendationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = RecommendationManager()

    // MARK: - Properties

    private let analysisEngine: SongAnalysisEngine
    private let similarityEngine: SimilarityEngine
    private let smartPlaylistEngine: SmartPlaylistEngine
    private let discoveryEngine: DiscoveryEngine
    private let personalizationEngine: PersonalizationEngine
    private let contextEngine: ContextAwareRecommendationEngine

    // Cache
    private var cachedRecommendations: [UUID: [SongRecommendation]] = [:]
    private var cachedTasteProfile: UserTasteProfile?
    private var lastProfileUpdate: Date?

    // MARK: - Initialization

    private init() {
        self.analysisEngine = SongAnalysisEngine()
        self.similarityEngine = SimilarityEngine()
        self.smartPlaylistEngine = SmartPlaylistEngine()
        self.discoveryEngine = DiscoveryEngine()
        self.personalizationEngine = PersonalizationEngine()
        self.contextEngine = ContextAwareRecommendationEngine()
    }

    // MARK: - Public API

    /// Get comprehensive recommendations for a song
    func getRecommendations(
        for song: Song,
        in allSongs: [Song],
        types: [RecommendationType] = [.similar, .contextAware],
        limit: Int = 10
    ) -> [SongRecommendation] {
        // Check cache first
        if let cached = cachedRecommendations[song.id] {
            return Array(cached.prefix(limit))
        }

        var recommendations: [SongRecommendation] = []

        for type in types {
            switch type {
            case .similar:
                let similar = similarityEngine.findSimilarSongs(
                    to: song,
                    in: allSongs,
                    limit: limit
                )
                recommendations.append(contentsOf: similar)

            case .contextAware:
                if let next = contextEngine.suggestNextSong(
                    after: song,
                    from: allSongs
                ) {
                    let rec = SongRecommendation(
                        songID: song.id,
                        recommendedSongID: next.id,
                        similarityScore: 0.8,
                        recommendationType: .contextAware,
                        reasons: [.complementsCurrentSong]
                    )
                    recommendations.append(rec)
                }

            default:
                break
            }
        }

        // Ensure diversity
        recommendations = ensureDiversity(recommendations, in: allSongs)

        // Cache results
        cachedRecommendations[song.id] = recommendations

        return Array(recommendations.prefix(limit))
    }

    /// Get discovery feed for user
    func getDiscoveryFeed(
        from allSongs: [Song],
        playHistory: [PlayHistoryEntry],
        includeTypes: [DiscoverySection] = [.unplayed, .trending, .personalized],
        limit: Int = 20
    ) -> [(section: DiscoverySection, songs: [Song])] {
        var feed: [(DiscoverySection, [Song])] = []

        for type in includeTypes {
            switch type {
            case .unplayed:
                let unplayed = discoveryEngine.getUnplayedSongs(
                    from: allSongs,
                    playHistory: playHistory,
                    limit: limit
                )
                if !unplayed.isEmpty {
                    feed.append((.unplayed, unplayed))
                }

            case .trending:
                let trending = discoveryEngine.getTrendingSongs(
                    from: allSongs,
                    playHistory: playHistory,
                    limit: limit
                ).map { $0.song }
                if !trending.isEmpty {
                    feed.append((.trending, trending))
                }

            case .hiddenGems:
                let gems = discoveryEngine.discoverHiddenGems(
                    from: allSongs,
                    playHistory: playHistory,
                    limit: limit
                )
                if !gems.isEmpty {
                    feed.append((.hiddenGems, gems))
                }

            case .personalized:
                let profile = getTasteProfile(from: playHistory, songs: allSongs)
                let personalized = personalizationEngine.getPersonalizedRecommendations(
                    for: allSongs,
                    profile: profile,
                    limit: limit
                )
                if !personalized.isEmpty {
                    feed.append((.personalized, personalized))
                }

            case .forgotten:
                let forgotten = discoveryEngine.getForgottenSongs(
                    from: allSongs,
                    playHistory: playHistory,
                    limit: limit
                )
                if !forgotten.isEmpty {
                    feed.append((.forgotten, forgotten))
                }

            case .seasonal:
                // Seasonal recommendations would go here
                break
            }
        }

        return feed
    }

    /// Generate smart playlist
    func generateSmartPlaylist(
        from songs: [Song],
        criteria: PlaylistCriteria,
        targetDuration: TimeInterval? = nil,
        optimizeFlow: Bool = true
    ) -> [Song] {
        return smartPlaylistEngine.generatePlaylist(
            from: songs,
            criteria: criteria,
            targetDuration: targetDuration,
            optimizeFlow: optimizeFlow
        )
    }

    /// Get user taste profile
    func getTasteProfile(
        from playHistory: [PlayHistoryEntry],
        songs: [Song],
        forceRefresh: Bool = false
    ) -> UserTasteProfile {
        // Check if we need to update
        let shouldUpdate = forceRefresh ||
                          cachedTasteProfile == nil ||
                          shouldUpdateProfile()

        if shouldUpdate {
            let profile = personalizationEngine.buildTasteProfile(
                from: playHistory,
                songs: songs
            )
            cachedTasteProfile = profile
            lastProfileUpdate = Date()
            return profile
        }

        return cachedTasteProfile ?? UserTasteProfile(userID: "default")
    }

    /// Process user feedback
    func processFeedback(
        _ feedback: RecommendationFeedback,
        modelContext: ModelContext
    ) {
        // Save feedback to database
        modelContext.insert(feedback)

        // Invalidate cache for affected recommendations
        if let recommendation = try? modelContext.fetch(
            FetchDescriptor<SongRecommendation>(
                predicate: #Predicate { $0.id == feedback.recommendationID }
            )
        ).first {
            cachedRecommendations.removeValue(forKey: recommendation.songID)
        }

        // In future: Adjust weights based on feedback
        adjustWeightsFromFeedback(feedback)
    }

    /// Suggest next song for a set
    func suggestNextForSet(
        currentSong: Song,
        from candidates: [Song],
        targetMood: Mood? = nil
    ) -> Song? {
        return contextEngine.suggestNextSong(
            after: currentSong,
            from: candidates,
            targetMood: targetMood
        )
    }

    /// Find bridge songs for key modulation
    func findBridgeSongs(
        from fromKey: String,
        to toKey: String,
        in songs: [Song]
    ) -> [Song] {
        return contextEngine.findBridgeSongs(
            from: fromKey,
            to: toKey,
            in: songs
        )
    }

    /// Record song play for learning
    func recordPlay(
        _ song: Song,
        context: PlayContext = .worship,
        modelContext: ModelContext
    ) {
        let entry = PlayHistoryEntry(
            songID: song.id,
            playedAt: Date(),
            context: context,
            duration: 180, // Default 3 minutes
            completedPercentage: 1.0
        )

        modelContext.insert(entry)

        // Invalidate profile cache
        cachedTasteProfile = nil
    }

    /// Clear cache
    func clearCache() {
        cachedRecommendations.removeAll()
        cachedTasteProfile = nil
        lastProfileUpdate = nil
    }

    // MARK: - Private Methods

    private func ensureDiversity(
        _ recommendations: [SongRecommendation],
        in allSongs: [Song]
    ) -> [SongRecommendation] {
        var diverse: [SongRecommendation] = []
        var usedKeys = Set<String>()
        var usedArtists = Set<String>()

        for rec in recommendations {
            guard let song = allSongs.first(where: { $0.id == rec.recommendedSongID }) else {
                continue
            }

            // Ensure variety in keys (max 3 of same key in first 10)
            if let key = song.key {
                let keyCount = diverse.prefix(10).filter { existingRec in
                    allSongs.first { $0.id == existingRec.recommendedSongID }?.key == key
                }.count

                if keyCount >= 3 {
                    continue
                }
            }

            // Ensure variety in artists (max 2 of same artist in first 10)
            if let artist = song.artist {
                let artistCount = diverse.prefix(10).filter { existingRec in
                    allSongs.first { $0.id == existingRec.recommendedSongID }?.artist == artist
                }.count

                if artistCount >= 2 {
                    continue
                }
            }

            diverse.append(rec)
        }

        return diverse
    }

    private func shouldUpdateProfile() -> Bool {
        guard let lastUpdate = lastProfileUpdate else { return true }

        let daysSinceUpdate = Date().timeIntervalSince(lastUpdate) / 86400
        return daysSinceUpdate > 7 // Update weekly
    }

    private func adjustWeightsFromFeedback(_ feedback: RecommendationFeedback) {
        // In future: Implement weight adjustment based on feedback
        // For now, this is a placeholder
    }

    // MARK: - Preset Playlists

    /// Get preset smart playlist configurations
    func getPresetPlaylists() -> [(name: String, criteria: PlaylistCriteria)] {
        return [
            ("Peaceful Worship", .combined([.mood(.peaceful), .tempo(.slow)])),
            ("Upbeat Praise", .combined([.mood(.joyful), .tempo(.fast)])),
            ("Simple Songs", .combined([.simple, .noCapo])),
            ("In the Key of C", .key("C")),
            ("In the Key of G", .key("G")),
            ("In the Key of D", .key("D")),
            ("Recent Additions", .recent),
            ("Songs to Rediscover", .unplayed),
            ("Reflective Worship", .combined([.mood(.reflective), .tempo(.slow)])),
            ("Energetic Praise", .combined([.mood(.energetic), .tempo(.fast)]))
        ]
    }

    /// Get time-based suggestions
    func getTimeBasedSuggestions() -> [String] {
        return contextEngine.getTimeBasedSuggestions()
    }
}

// MARK: - Helper Extensions

extension RecommendationManager {
    /// Get song characteristics
    func analyzeSong(_ song: Song) -> SongCharacteristics {
        return analysisEngine.analyzeSong(song)
    }

    /// Calculate similarity between two songs
    func calculateSimilarity(_ song1: Song, _ song2: Song) -> Float {
        let char1 = analysisEngine.analyzeSong(song1)
        let char2 = analysisEngine.analyzeSong(song2)
        return similarityEngine.calculateSimilarity(char1, char2)
    }
}
