//
//  SimilarityEngine.swift
//  Lyra
//
//  Phase 7.5: Recommendation Intelligence
//  Finds similar songs based on multiple factors
//  Created on January 24, 2026
//

import Foundation
import SwiftData

/// Finds similar songs using multi-factor similarity scoring
@MainActor
class SimilarityEngine {

    // MARK: - Properties

    private let analysisEngine: SongAnalysisEngine
    private let keyCompatibilityAnalyzer: KeyCompatibilityAnalyzer

    // Similarity weight configuration
    struct SimilarityWeights {
        var keyCompatibility: Float = 0.30
        var tempoSimilarity: Float = 0.20
        var chordComplexity: Float = 0.15
        var lyricThemes: Float = 0.15
        var genreSimilarity: Float = 0.10
        var artistSimilarity: Float = 0.05
        var timeSignature: Float = 0.05
    }

    private var weights = SimilarityWeights()

    // Circle of fifths for key compatibility
    private let circleOfFifths = ["C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F"]

    // MARK: - Initialization

    init(
        analysisEngine: SongAnalysisEngine,
        keyCompatibilityAnalyzer: KeyCompatibilityAnalyzer
    ) {
        self.analysisEngine = analysisEngine
        self.keyCompatibilityAnalyzer = keyCompatibilityAnalyzer
    }

    // MARK: - Public Methods

    /// Find similar songs to a reference song
    func findSimilarSongs(
        to referenceSong: Song,
        in songs: [Song],
        limit: Int = 10
    ) -> [SongRecommendation] {
        let referenceCharacteristics = analysisEngine.analyzeSong(referenceSong)

        var recommendations: [SongRecommendation] = []

        for song in songs {
            // Don't recommend the song to itself
            guard song.id != referenceSong.id else { continue }

            let characteristics = analysisEngine.analyzeSong(song)
            let similarity = calculateSimilarity(referenceCharacteristics, characteristics)
            let reasons = getSimilarityReasons(referenceCharacteristics, characteristics, similarity: similarity)

            let recommendation = SongRecommendation(
                songID: referenceSong.id,
                recommendedSongID: song.id,
                similarityScore: similarity,
                recommendationType: .similar,
                reasons: reasons
            )

            recommendations.append(recommendation)
        }

        // Sort by similarity and return top N
        return recommendations
            .sorted { $0.similarityScore > $1.similarityScore }
            .prefix(limit)
            .map { $0 }
    }

    /// Calculate similarity between two songs
    func calculateSimilarity(_ song1: SongCharacteristics, _ song2: SongCharacteristics) -> Float {
        var totalScore: Float = 0

        // 1. Key compatibility (30%)
        let keyScore = keyCompatibilityScore(song1.key, song2.key)
        totalScore += keyScore * weights.keyCompatibility

        // 2. Tempo similarity (20%)
        let tempoScore = tempoSimilarityScore(song1.tempo, song2.tempo)
        totalScore += tempoScore * weights.tempoSimilarity

        // 3. Chord complexity similarity (15%)
        let complexityScore = 1.0 - abs(song1.chordComplexity - song2.chordComplexity)
        totalScore += complexityScore * weights.chordComplexity

        // 4. Lyric theme similarity (15%)
        let themeScore = lyricThemeSimilarity(song1.lyricThemes, song2.lyricThemes)
        totalScore += themeScore * weights.lyricThemes

        // 5. Genre similarity (10%)
        let genreScore = genreSimilarity(song1.estimatedGenre, song2.estimatedGenre)
        totalScore += genreScore * weights.genreSimilarity

        // 6. Time signature similarity (5%)
        let timeSignatureScore: Float = song1.timeSignature == song2.timeSignature ? 1.0 : 0.5
        totalScore += timeSignatureScore * weights.timeSignature

        return min(1.0, max(0.0, totalScore))
    }

    /// Get reasons for similarity between two songs
    func getSimilarityReasons(
        _ song1: SongCharacteristics,
        _ song2: SongCharacteristics,
        similarity: Float
    ) -> [RecommendationReason] {
        var reasons: [RecommendationReason] = []

        // Same key
        if song1.key == song2.key {
            reasons.append(.sameKey)
        } else if keyCompatibilityScore(song1.key, song2.key) > 0.8 {
            reasons.append(.smoothKeyTransition)
        }

        // Similar tempo
        let tempoDiff = abs(song1.tempo - song2.tempo)
        if tempoDiff < 10 {
            reasons.append(.similarTempo)
        }

        // Similar chord complexity
        let complexityDiff = abs(song1.chordComplexity - song2.chordComplexity)
        if complexityDiff < 0.2 {
            reasons.append(.similarChordComplexity)
        }

        // Similar lyric themes
        let commonThemes = Set(song1.lyricThemes).intersection(Set(song2.lyricThemes))
        if !commonThemes.isEmpty {
            reasons.append(.similarLyricThemes)
        }

        // Same genre
        if let genre1 = song1.estimatedGenre,
           let genre2 = song2.estimatedGenre,
           genre1 == genre2 {
            reasons.append(.sameGenre)
        }

        // If no specific reasons but high similarity, add generic reason
        if reasons.isEmpty && similarity > 0.7 {
            reasons.append(.complementsCurrentSong)
        }

        return reasons
    }

    // MARK: - Similarity Scoring Methods

    /// Calculate key compatibility score based on circle of fifths
    func keyCompatibilityScore(_ key1: String, _ key2: String) -> Float {
        // Perfect match
        if key1 == key2 {
            return 1.0
        }

        // Use KeyCompatibilityAnalyzer for accurate compatibility
        let compatibility = keyCompatibilityAnalyzer.analyzeCompatibility(
            fromKey: key1,
            toKey: key2
        )

        // Convert compatibility level to score
        switch compatibility.compatibilityLevel {
        case .perfect:
            return 1.0
        case .veryCompatible:
            return 0.9
        case .compatible:
            return 0.7
        case .somewhatCompatible:
            return 0.5
        case .lessCompatible:
            return 0.3
        case .leastCompatible:
            return 0.1
        }
    }

    /// Calculate tempo similarity score
    func tempoSimilarityScore(_ tempo1: Int, _ tempo2: Int) -> Float {
        let tempoDiff = abs(tempo1 - tempo2)

        // Calculate similarity based on difference
        // Within 10 BPM: >0.8
        // Within 30 BPM: >0.5
        // Within 60 BPM: >0.0

        let maxDiff: Float = 60.0
        let similarity = max(0, 1.0 - (Float(tempoDiff) / maxDiff))

        return similarity
    }

    /// Calculate lyric theme similarity using Jaccard index
    func lyricThemeSimilarity(_ themes1: [String], _ themes2: [String]) -> Float {
        guard !themes1.isEmpty || !themes2.isEmpty else { return 1.0 }
        guard !themes1.isEmpty && !themes2.isEmpty else { return 0.0 }

        let set1 = Set(themes1)
        let set2 = Set(themes2)

        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count

        return Float(intersection) / Float(union)
    }

    /// Calculate genre similarity
    func genreSimilarity(_ genre1: String?, _ genre2: String?) -> Float {
        guard let g1 = genre1, let g2 = genre2 else { return 0.5 }

        if g1.lowercased() == g2.lowercased() {
            return 1.0
        }

        // Check for similar genres
        if isRelatedGenre(g1, g2) {
            return 0.7
        }

        return 0.0
    }

    // MARK: - Helper Methods

    private func isRelatedGenre(_ genre1: String, _ genre2: String) -> Bool {
        let relatedGenres: [Set<String>] = [
            Set(["contemporary worship", "modern worship", "praise"]),
            Set(["traditional", "hymn", "classic"]),
            Set(["gospel", "southern gospel", "black gospel"]),
            Set(["christian rock", "christian alternative", "christian metal"])
        ]

        let g1Lower = genre1.lowercased()
        let g2Lower = genre2.lowercased()

        for group in relatedGenres {
            if group.contains(g1Lower) && group.contains(g2Lower) {
                return true
            }
        }

        return false
    }

    /// Adjust weights based on specific use case
    func adjustWeights(_ newWeights: SimilarityWeights) {
        self.weights = newWeights
    }

    /// Get current weights
    func getWeights() -> SimilarityWeights {
        return weights
    }
}

// MARK: - Extensions for Convenience

extension SimilarityEngine {
    /// Find songs similar by key
    func findSongsByKey(
        _ key: String,
        in songs: [Song],
        includeCompatibleKeys: Bool = true,
        limit: Int = 20
    ) -> [Song] {
        var matchingSongs: [(song: Song, score: Float)] = []

        for song in songs {
            let songKey = song.key ?? "C"

            if songKey == key {
                matchingSongs.append((song, 1.0))
            } else if includeCompatibleKeys {
                let score = keyCompatibilityScore(key, songKey)
                if score > 0.5 {
                    matchingSongs.append((song, score))
                }
            }
        }

        return matchingSongs
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.song }
    }

    /// Find songs with similar tempo
    func findSongsByTempo(
        _ tempo: Int,
        in songs: [Song],
        tolerance: Int = 20,
        limit: Int = 20
    ) -> [Song] {
        return songs
            .filter { song in
                guard let songTempo = song.tempo else { return false }
                return abs(songTempo - tempo) <= tolerance
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Find songs with similar complexity
    func findSongsByComplexity(
        _ complexity: Float,
        in songs: [Song],
        tolerance: Float = 0.2,
        limit: Int = 20
    ) -> [Song] {
        var matchingSongs: [(song: Song, diff: Float)] = []

        for song in songs {
            let characteristics = analysisEngine.analyzeSong(song)
            let diff = abs(characteristics.chordComplexity - complexity)

            if diff <= tolerance {
                matchingSongs.append((song, diff))
            }
        }

        return matchingSongs
            .sorted { $0.diff < $1.diff }
            .prefix(limit)
            .map { $0.song }
    }
}
