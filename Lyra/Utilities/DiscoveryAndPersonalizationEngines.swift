//
//  DiscoveryAndPersonalizationEngines.swift
//  Lyra
//
//  Phase 7.5: Recommendation Intelligence
//  Discovery, Personalization, and Context-Aware recommendation engines
//  Created on January 24, 2026
//

import Foundation
import SwiftData

// MARK: - Discovery Engine

/// Helps users discover new and forgotten songs
@MainActor
class DiscoveryEngine {

    // MARK: - Public Methods

    /// Get songs the user hasn't played yet
    func getUnplayedSongs(
        from songs: [Song],
        playHistory: [PlayHistoryEntry],
        limit: Int = 10,
        sortBy: SortOption = .recentlyAdded
    ) -> [Song] {
        let playedSongIDs = Set(playHistory.map { $0.songID })

        let unplayed = songs.filter { !playedSongIDs.contains($0.id) }

        return sortSongs(unplayed, by: sortBy).prefix(limit).map { $0 }
    }

    /// Get songs the user hasn't played recently
    func getForgottenSongs(
        from songs: [Song],
        playHistory: [PlayHistoryEntry],
        threshold: TimeInterval = 30 * 86400, // 30 days
        limit: Int = 10
    ) -> [Song] {
        let cutoffDate = Date().addingTimeInterval(-threshold)

        // Find songs played, but not recently
        let recentPlays = Set(playHistory.filter { $0.playedAt >= cutoffDate }.map { $0.songID })
        let allPlays = Set(playHistory.map { $0.songID })

        let forgotten = songs.filter { song in
            allPlays.contains(song.id) && !recentPlays.contains(song.id)
        }

        return Array(forgotten.prefix(limit))
    }

    /// Get trending songs (most played recently)
    func getTrendingSongs(
        from songs: [Song],
        playHistory: [PlayHistoryEntry],
        timeframe: TimeInterval = 7 * 86400, // 1 week
        limit: Int = 10
    ) -> [(song: Song, playCount: Int)] {
        let cutoffDate = Date().addingTimeInterval(-timeframe)
        let recentPlays = playHistory.filter { $0.playedAt >= cutoffDate }

        // Count plays per song
        var playCounts: [UUID: Int] = [:]
        for play in recentPlays {
            playCounts[play.songID, default: 0] += 1
        }

        // Sort songs by play count
        let trending = songs.compactMap { song -> (Song, Int)? in
            guard let count = playCounts[song.id], count > 0 else { return nil }
            return (song, count)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(limit)

        return Array(trending)
    }

    /// Discover hidden gems (high quality, low play count)
    func discoverHiddenGems(
        from songs: [Song],
        playHistory: [PlayHistoryEntry],
        minQualityScore: Float = 0.8,
        maxPlayCount: Int = 5,
        limit: Int = 10
    ) -> [Song] {
        let playCounts = calculatePlayCounts(playHistory)

        let gems = songs.filter { song in
            let playCount = playCounts[song.id] ?? 0
            let qualityScore = calculateQualityScore(song)

            return qualityScore >= minQualityScore &&
                   playCount <= maxPlayCount &&
                   isOldEnough(song, days: 30)
        }

        return Array(gems.prefix(limit))
    }

    // MARK: - Helper Methods

    private func calculateQualityScore(_ song: Song) -> Float {
        var score: Float = 0

        // Has complete metadata (30%)
        if song.key != nil { score += 0.1 }
        if song.tempo != nil { score += 0.1 }
        if song.artist != nil { score += 0.1 }

        // Well-formatted chords (30%)
        if !song.chords.isEmpty { score += 0.3 }

        // Has lyrics (20%)
        if !song.lyrics.isEmpty { score += 0.2 }

        // Has tags or genre (10%)
        if song.genre != nil { score += 0.1 }

        // Has CCLI number (professional song) (10%)
        if song.ccli != nil { score += 0.1 }

        return score
    }

    private func isOldEnough(_ song: Song, days: Int) -> Bool {
        let age = Date().timeIntervalSince(song.createdAt)
        return age > Double(days * 86400)
    }

    private func calculatePlayCounts(_ playHistory: [PlayHistoryEntry]) -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for play in playHistory {
            counts[play.songID, default: 0] += 1
        }
        return counts
    }

    private func sortSongs(_ songs: [Song], by option: SortOption) -> [Song] {
        switch option {
        case .recentlyAdded:
            return songs.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return songs.sorted { $0.title < $1.title }
        case .artist:
            return songs.sorted { ($0.artist ?? "") < ($1.artist ?? "") }
        }
    }

    enum SortOption {
        case recentlyAdded
        case title
        case artist
    }
}

// MARK: - Personalization Engine

/// Learns from user behavior to personalize recommendations
@MainActor
class PersonalizationEngine {

    private let analysisEngine: SongAnalysisEngine

    init(analysisEngine: SongAnalysisEngine = SongAnalysisEngine()) {
        self.analysisEngine = analysisEngine
    }

    // MARK: - Taste Profile

    /// Build user taste profile from play history
    func buildTasteProfile(
        from playHistory: [PlayHistoryEntry],
        songs: [Song]
    ) -> UserTasteProfile {
        // Map play history to songs
        let playedSongs = playHistory.compactMap { play in
            songs.first { $0.id == play.songID }
        }

        // Extract preferences
        let preferredKeys = extractPreferredKeys(from: playedSongs)
        let preferredTempos = extractPreferredTempos(from: playedSongs)
        let preferredArtists = extractPreferredArtists(from: playedSongs)
        let chordPreference = calculateChordComplexityPreference(from: playedSongs)
        let capoPreference = calculateCapoPreference(from: playedSongs)
        let playPatterns = detectTimePatterns(from: playHistory)

        return UserTasteProfile(
            userID: "default",
            preferredKeys: preferredKeys,
            preferredTempos: preferredTempos.map { $0.rawValue },
            preferredArtists: preferredArtists,
            chordComplexityPreference: chordPreference,
            capoPreference: capoPreference.rawValue,
            playPatterns: playPatterns
        )
    }

    /// Detect user patterns
    func detectPatterns(
        from playHistory: [PlayHistoryEntry],
        songs: [Song]
    ) -> [String] {
        var patterns: [String] = []

        let profile = buildTasteProfile(from: playHistory, songs: songs)

        // Key preferences
        if !profile.preferredKeys.isEmpty {
            patterns.append("Prefers \(profile.preferredKeys.prefix(3).joined(separator: ", ")) keys")
        }

        // Time of day patterns
        let morningPlays = playHistory.filter { Calendar.current.component(.hour, from: $0.playedAt) < 12 }.count
        let totalPlays = playHistory.count
        if Float(morningPlays) / Float(totalPlays) > 0.6 {
            patterns.append("Often plays in morning")
        }

        // Chord complexity
        if profile.chordComplexityPreference < 0.3 {
            patterns.append("Prefers simple chord progressions")
        } else if profile.chordComplexityPreference > 0.7 {
            patterns.append("Enjoys complex arrangements")
        }

        // Capo preferences
        if let capoPreference = CapoPreference(rawValue: profile.capoPreference) {
            switch capoPreference {
            case .avoidsCapo:
                patterns.append("Avoids capo usage")
            case .prefersCapo:
                patterns.append("Often uses capo")
            case .neutral:
                break
            }
        }

        return patterns
    }

    /// Get personalized recommendations
    func getPersonalizedRecommendations(
        for songs: [Song],
        profile: UserTasteProfile,
        limit: Int = 10
    ) -> [Song] {
        var scored: [(song: Song, score: Float)] = []

        for song in songs {
            let score = calculatePersonalizedScore(song, profile: profile)
            if score > 0.3 {
                scored.append((song, score))
            }
        }

        return scored
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.song }
    }

    // MARK: - Private Methods

    private func extractPreferredKeys(from songs: [Song]) -> [String] {
        let keys = songs.compactMap { $0.key }
        return keys.frequency().prefix(5).map { $0.element }
    }

    private func extractPreferredTempos(from songs: [Song]) -> [TempoCategory] {
        let tempos = songs.compactMap { $0.tempo }
        return tempos.detectTempoRanges()
    }

    private func extractPreferredArtists(from songs: [Song]) -> [String] {
        let artists = songs.compactMap { $0.artist }
        return artists.frequency().prefix(5).map { $0.element }
    }

    private func calculateChordComplexityPreference(from songs: [Song]) -> Float {
        let complexities = songs.map { song in
            analysisEngine.analyzeSong(song).chordComplexity
        }

        guard !complexities.isEmpty else { return 0.5 }

        return complexities.reduce(0, +) / Float(complexities.count)
    }

    private func calculateCapoPreference(from songs: [Song]) -> CapoPreference {
        let capoSongs = songs.filter { ($0.capo ?? 0) > 0 }.count
        let totalSongs = songs.count

        guard totalSongs > 0 else { return .neutral }

        let capoRatio = Float(capoSongs) / Float(totalSongs)

        if capoRatio < 0.2 {
            return .avoidsCapo
        } else if capoRatio > 0.6 {
            return .prefersCapo
        } else {
            return .neutral
        }
    }

    private func detectTimePatterns(from playHistory: [PlayHistoryEntry]) -> [String: Int] {
        var patterns: [String: Int] = [:]

        for play in playHistory {
            let hour = Calendar.current.component(.hour, from: play.playedAt)
            let timeOfDay: String

            switch hour {
            case 6..<12: timeOfDay = "morning"
            case 12..<18: timeOfDay = "afternoon"
            case 18..<22: timeOfDay = "evening"
            default: timeOfDay = "night"
            }

            patterns[timeOfDay, default: 0] += 1
        }

        return patterns
    }

    private func calculatePersonalizedScore(_ song: Song, profile: UserTasteProfile) -> Float {
        var score: Float = 0

        // Preferred key
        if let key = song.key, profile.preferredKeys.contains(key) {
            score += 0.4
        }

        // Preferred artist
        if let artist = song.artist, profile.preferredArtists.contains(artist) {
            score += 0.3
        }

        // Tempo preference
        if let tempo = song.tempo {
            let category = TempoCategory.category(for: tempo)
            if profile.preferredTempos.contains(category.rawValue) {
                score += 0.2
            }
        }

        // Chord complexity match
        let songComplexity = analysisEngine.analyzeSong(song).chordComplexity
        let complexityDiff = abs(songComplexity - profile.chordComplexityPreference)
        if complexityDiff < 0.2 {
            score += 0.1
        }

        return score
    }
}

// MARK: - Context-Aware Recommendation Engine

/// Provides context-aware suggestions based on current state
@MainActor
class ContextAwareRecommendationEngine {

    private let analysisEngine: SongAnalysisEngine
    private let similarityEngine: SimilarityEngine

    init(
        analysisEngine: SongAnalysisEngine = SongAnalysisEngine(),
        similarityEngine: SimilarityEngine = SimilarityEngine()
    ) {
        self.analysisEngine = analysisEngine
        self.similarityEngine = similarityEngine
    }

    // MARK: - Public Methods

    /// Suggest next song in a set
    func suggestNextSong(
        after current: Song,
        from candidates: [Song],
        targetMood: Mood? = nil
    ) -> Song? {
        var filtered = candidates

        // Filter by target mood if specified
        if let mood = targetMood {
            filtered = filtered.filter { song in
                matchesMood(song, mood: mood)
            }
        }

        // Score each candidate
        let currentChar = analysisEngine.analyzeSong(current)

        let scored = filtered.map { candidate -> (song: Song, score: Float) in
            let candidateChar = analysisEngine.analyzeSong(candidate)
            let score = scoreNextSong(from: currentChar, to: candidateChar)
            return (candidate, score)
        }

        return scored.max(by: { $0.score < $1.score })?.song
    }

    /// Find bridge songs for key modulation
    func findBridgeSongs(
        from fromKey: String,
        to toKey: String,
        in songs: [Song]
    ) -> [Song] {
        let bridgeKeys = calculateBridgeKeys(from: fromKey, to: toKey)

        return songs.filter { song in
            guard let key = song.key else { return false }

            return bridgeKeys.contains(key) &&
                   similarityEngine.keyCompatibilityScore(fromKey, key) > 0.7 &&
                   similarityEngine.keyCompatibilityScore(key, toKey) > 0.7
        }
    }

    /// Get time-based suggestions
    func getTimeBasedSuggestions(
        from songs: [Song],
        time: Date = Date(),
        context: PlayContext = .worship
    ) -> [String] {
        let hour = Calendar.current.component(.hour, from: time)

        switch hour {
        case 6..<12:
            return ["uplifting worship songs", "energetic praise", "morning songs"]
        case 12..<18:
            return ["steady worship", "team songs", "learning new songs"]
        case 18..<22:
            return ["peaceful worship", "reflective songs", "evening praise"]
        default:
            return ["quiet worship", "contemplative songs", "prayer songs"]
        }
    }

    // MARK: - Private Methods

    private func scoreNextSong(from: SongCharacteristics, to: SongCharacteristics) -> Float {
        var score: Float = 0

        // Key transition smoothness (40%)
        let keyScore = similarityEngine.keyCompatibilityScore(from.key, to.key)
        score += keyScore * 0.4

        // Tempo transition smoothness (30%)
        let tempoDiff = abs(from.tempo - to.tempo)
        let tempoScore = max(0, 1.0 - Float(tempoDiff) / 40.0)
        score += tempoScore * 0.3

        // Some variety in complexity (20%)
        let complexityDiff = abs(from.chordComplexity - to.chordComplexity)
        let varietyScore = complexityDiff > 0.1 && complexityDiff < 0.4 ? 1.0 : 0.5
        score += varietyScore * 0.2

        // Theme continuity (10%)
        let themeScore = similarityEngine.lyricThemeSimilarity(from.lyricThemes, to.lyricThemes)
        score += themeScore * 0.1

        return score
    }

    private func matchesMood(_ song: Song, mood: Mood) -> Bool {
        let characteristics = analysisEngine.analyzeSong(song)

        switch mood {
        case .joyful, .celebratory, .energetic:
            return characteristics.tempo >= 110
        case .peaceful, .contemplative, .intimate:
            return characteristics.tempo <= 90
        case .reflective, .solemn:
            return characteristics.tempo <= 80
        default:
            return true
        }
    }

    private func calculateBridgeKeys(from: String, to: String) -> [String] {
        // Calculate intermediate keys that transition smoothly
        // This is a simplified version - in production, use music theory engine

        var bridges: [String] = []

        // Relative majors/minors
        if let relativeTo = getRelativeKey(to) {
            bridges.append(relativeTo)
        }

        // Fifth relationships
        if let fifthAbove = getKeyFifthAbove(from) {
            bridges.append(fifthAbove)
        }

        return bridges
    }

    private func getRelativeKey(_ key: String) -> String? {
        let relatives: [String: String] = [
            "C": "Am", "Am": "C",
            "G": "Em", "Em": "G",
            "D": "Bm", "Bm": "D",
            "A": "F#m", "F#m": "A",
            "E": "C#m", "C#m": "E",
            "F": "Dm", "Dm": "F"
        ]
        return relatives[key]
    }

    private func getKeyFifthAbove(_ key: String) -> String? {
        let fifths: [String: String] = [
            "C": "G", "G": "D", "D": "A",
            "A": "E", "E": "B", "F": "C"
        ]
        return fifths[key]
    }
}
