//
//  SmartPlaylistEngine.swift
//  Lyra
//
//  Phase 7.5: Recommendation Intelligence
//  Auto-generates themed playlists with flow optimization
//  Created on January 24, 2026
//

import Foundation

/// Generates smart playlists based on criteria
@MainActor
class SmartPlaylistEngine {

    // MARK: - Properties

    private let analysisEngine: SongAnalysisEngine
    private let similarityEngine: SimilarityEngine

    // MARK: - Initialization

    init(
        analysisEngine: SongAnalysisEngine = SongAnalysisEngine(),
        similarityEngine: SimilarityEngine = SimilarityEngine()
    ) {
        self.analysisEngine = analysisEngine
        self.similarityEngine = similarityEngine
    }

    // MARK: - Public Methods

    /// Generate a playlist based on criteria
    func generatePlaylist(
        from songs: [Song],
        criteria: PlaylistCriteria,
        targetDuration: TimeInterval? = nil,
        optimizeFlow: Bool = true,
        limit: Int = 20
    ) -> [Song] {
        // Filter songs by criteria
        var matchingSongs = filterSongs(songs, by: criteria)

        // Limit results
        if matchingSongs.count > limit {
            matchingSongs = Array(matchingSongs.prefix(limit))
        }

        // Optimize flow if requested
        if optimizeFlow && matchingSongs.count > 1 {
            matchingSongs = optimizePlaylistFlow(matchingSongs)
        }

        // Trim to target duration if specified
        if let targetDuration = targetDuration {
            matchingSongs = trimToTargetDuration(matchingSongs, target: targetDuration)
        }

        return matchingSongs
    }

    /// Refresh an existing smart playlist
    func refreshSmartPlaylist(
        _ playlist: SmartPlaylist,
        from songs: [Song],
        keepFavorites: Bool = true
    ) -> [Song] {
        guard let criteria = playlist.criteria else { return [] }

        var newSongs = filterSongs(songs, by: criteria)

        // If keeping favorites, preserve songs user has in their sets
        if keepFavorites {
            // This would require access to user's sets - simplified for now
            newSongs = Array(newSongs.prefix(20))
        }

        if playlist.flowOptimized {
            newSongs = optimizePlaylistFlow(newSongs)
        }

        if let targetDuration = playlist.targetDuration {
            newSongs = trimToTargetDuration(newSongs, target: targetDuration)
        }

        return newSongs
    }

    // MARK: - Filtering Methods

    private func filterSongs(_ songs: [Song], by criteria: PlaylistCriteria) -> [Song] {
        switch criteria {
        case .mood(let mood):
            return filterByMood(songs, mood: mood)

        case .key(let key):
            return songs.filter { $0.key == key }

        case .tempo(let category):
            return filterByTempo(songs, category: category)

        case .theme(let theme):
            return filterByTheme(songs, theme: theme)

        case .artist(let artist):
            return songs.filter { $0.artist == artist }

        case .genre(let genre):
            return songs.filter { $0.genre == genre }

        case .noCapo:
            return songs.filter { ($0.capo ?? 0) == 0 }

        case .simple:
            return filterByComplexity(songs, maxComplexity: 0.3)

        case .complex:
            return filterByComplexity(songs, minComplexity: 0.6)

        case .recent:
            return filterRecent(songs, days: 30)

        case .unplayed:
            // Would require play history - simplified
            return songs

        case .combined(let criteriaList):
            var filtered = songs
            for criterion in criteriaList {
                filtered = filterSongs(filtered, by: criterion)
            }
            return filtered
        }
    }

    private func filterByMood(_ songs: [Song], mood: Mood) -> [Song] {
        // Filter songs based on tempo and characteristics that match mood
        return songs.filter { song in
            let characteristics = analysisEngine.analyzeSong(song)

            switch mood {
            case .joyful, .celebratory:
                return characteristics.tempo >= 110

            case .peaceful, .contemplative:
                return characteristics.tempo <= 90

            case .energetic:
                return characteristics.tempo >= 130

            case .reflective, .solemn:
                return characteristics.tempo <= 80

            case .hopeful, .triumphant:
                return characteristics.tempo >= 100 && characteristics.tempo <= 130

            case .intimate:
                return characteristics.tempo <= 100 &&
                       characteristics.chordComplexity <= 0.5

            }
        }
    }

    private func filterByTempo(_ songs: [Song], category: TempoCategory) -> [Song] {
        let range = category.bpmRange

        return songs.filter { song in
            guard let tempo = song.tempo else { return false }
            return range.contains(tempo)
        }
    }

    private func filterByTheme(_ songs: [Song], theme: String) -> [Song] {
        let themeLower = theme.lowercased()

        return songs.filter { song in
            let characteristics = analysisEngine.analyzeSong(song)
            return characteristics.lyricThemes.contains { $0.lowercased().contains(themeLower) }
        }
    }

    private func filterByComplexity(
        _ songs: [Song],
        minComplexity: Float = 0.0,
        maxComplexity: Float = 1.0
    ) -> [Song] {
        return songs.filter { song in
            let characteristics = analysisEngine.analyzeSong(song)
            return characteristics.chordComplexity >= minComplexity &&
                   characteristics.chordComplexity <= maxComplexity
        }
    }

    private func filterRecent(_ songs: [Song], days: Int) -> [Song] {
        let cutoffDate = Date().addingTimeInterval(-Double(days * 86400))

        return songs.filter { song in
            song.createdAt >= cutoffDate
        }
    }

    // MARK: - Flow Optimization

    private func optimizePlaylistFlow(_ songs: [Song]) -> [Song] {
        guard songs.count > 1 else { return songs }

        var optimized = [songs[0]]
        var remaining = Array(songs.dropFirst())

        while !remaining.isEmpty {
            let current = optimized.last!
            let next = findBestNext(current, from: remaining)
            optimized.append(next)
            remaining.removeAll { $0.id == next.id }
        }

        return optimized
    }

    private func findBestNext(_ current: Song, from candidates: [Song]) -> Song {
        let currentChar = analysisEngine.analyzeSong(current)

        return candidates.max { a, b in
            let aChar = analysisEngine.analyzeSong(a)
            let bChar = analysisEngine.analyzeSong(b)

            return flowScore(from: currentChar, to: aChar) <
                   flowScore(from: currentChar, to: bChar)
        }!
    }

    private func flowScore(from: SongCharacteristics, to: SongCharacteristics) -> Float {
        // Key transition smoothness: 40%
        let keyScore = similarityEngine.keyCompatibilityScore(from.key, to.key)

        // Tempo transition smoothness: 30%
        let tempoDiff = abs(from.tempo - to.tempo)
        let tempoScore = max(0, 1.0 - Float(tempoDiff) / 40.0)

        // Complexity variation (some variety is good): 20%
        let complexityDiff = abs(from.chordComplexity - to.chordComplexity)
        let varietyScore = complexityDiff < 0.1 ? 0.5 : 1.0 // Prefer some variety

        // Theme similarity: 10%
        let themeScore = similarityEngine.lyricThemeSimilarity(from.lyricThemes, to.lyricThemes)

        return (keyScore * 0.4) +
               (tempoScore * 0.3) +
               (varietyScore * 0.2) +
               (themeScore * 0.1)
    }

    // MARK: - Duration Management

    private func trimToTargetDuration(_ songs: [Song], target: TimeInterval) -> [Song] {
        var totalDuration: TimeInterval = 0
        var result: [Song] = []

        for song in songs {
            let characteristics = analysisEngine.analyzeSong(song)
            let duration = characteristics.estimatedDuration ?? 180 // Default 3 minutes

            if totalDuration + duration <= target {
                result.append(song)
                totalDuration += duration
            } else {
                break
            }
        }

        return result
    }
}
