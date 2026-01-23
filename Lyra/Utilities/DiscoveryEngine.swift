//
//  DiscoveryEngine.swift
//  Lyra
//
//  Recommendation and discovery algorithm for public library
//

import Foundation
import SwiftData

@MainActor
class DiscoveryEngine {
    static let shared = DiscoveryEngine()

    private init() {}

    // MARK: - Recommendations

    /// Recommends songs based on user's library
    func getRecommendations(
        basedOnUserLibrary songs: [Song],
        fromPublicLibrary publicSongs: [PublicSong],
        limit: Int = 20
    ) -> [PublicSong] {
        // Analyze user's library
        let userGenres = extractGenres(from: songs)
        let userKeys = extractKeys(from: songs)
        let userArtists = extractArtists(from: songs)
        let userTags = extractTags(from: songs)

        // Score each public song based on similarity
        var scoredSongs: [(song: PublicSong, score: Double)] = []

        for publicSong in publicSongs where publicSong.isApproved {
            var score = 0.0

            // Genre match (high weight)
            if userGenres.contains(publicSong.genre) {
                score += 10.0
            }

            // Key match (medium weight)
            if let key = publicSong.originalKey, userKeys.contains(key) {
                score += 5.0
            }

            // Artist match (high weight)
            if let artist = publicSong.artist, userArtists.contains(artist) {
                score += 8.0
            }

            // Tag overlap (medium weight)
            let publicTags = Set(publicSong.tags ?? [])
            let commonTags = userTags.intersection(publicTags)
            score += Double(commonTags.count) * 2.0

            // Popularity bonus (low weight)
            score += log(Double(publicSong.downloadCount + 1)) * 0.5
            score += publicSong.averageRating

            if score > 0 {
                scoredSongs.append((publicSong, score))
            }
        }

        // Sort by score and return top results
        scoredSongs.sort { $0.score > $1.score }
        return scoredSongs.prefix(limit).map { $0.song }
    }

    /// Finds similar songs to a given song
    func findSimilarSongs(
        to song: Song,
        in publicSongs: [PublicSong],
        limit: Int = 10
    ) -> [PublicSong] {
        var scoredSongs: [(song: PublicSong, score: Double)] = []

        for publicSong in publicSongs where publicSong.isApproved {
            var score = 0.0

            // Same artist (very high weight)
            if let artist = song.artist,
               let publicArtist = publicSong.artist,
               artist.lowercased() == publicArtist.lowercased() {
                score += 15.0
            }

            // Same key (high weight)
            if let key = song.originalKey,
               let publicKey = publicSong.originalKey,
               key == publicKey {
                score += 8.0
            }

            // Similar tempo (medium weight)
            if let tempo = song.tempo,
               let publicTempo = publicSong.tempo {
                let tempoDiff = abs(tempo - publicTempo)
                if tempoDiff < 20 {
                    score += 5.0 - (Double(tempoDiff) * 0.2)
                }
            }

            // Tag overlap (medium weight)
            if let songTags = song.tags,
               let publicTags = publicSong.tags {
                let commonTags = Set(songTags).intersection(Set(publicTags))
                score += Double(commonTags.count) * 3.0
            }

            // Title similarity (low weight)
            let titleSimilarity = calculateStringSimilarity(song.title, publicSong.title)
            score += titleSimilarity * 2.0

            if score > 0 {
                scoredSongs.append((publicSong, score))
            }
        }

        // Sort by score and return top results
        scoredSongs.sort { $0.score > $1.score }
        return scoredSongs.prefix(limit).map { $0.song }
    }

    /// Finds songs for a specific occasion/category
    func findSongsForOccasion(
        category: SongCategory,
        genre: SongGenre? = nil,
        in publicSongs: [PublicSong],
        limit: Int = 20
    ) -> [PublicSong] {
        var filtered = publicSongs.filter { song in
            song.isApproved && song.category == category
        }

        if let genre = genre {
            filtered = filtered.filter { $0.genre == genre }
        }

        // Sort by rating and downloads
        filtered.sort { song1, song2 in
            let score1 = song1.averageRating * 2.0 + Double(song1.downloadCount) * 0.1
            let score2 = song2.averageRating * 2.0 + Double(song2.downloadCount) * 0.1
            return score1 > score2
        }

        return Array(filtered.prefix(limit))
    }

    // MARK: - Helper Methods

    private func extractGenres(from songs: [Song]) -> Set<SongGenre> {
        // In a real implementation, we'd analyze song metadata
        // For now, return a default set
        return [.worship, .contemporary, .traditional]
    }

    private func extractKeys(from songs: [Song]) -> Set<String> {
        return Set(songs.compactMap { $0.originalKey })
    }

    private func extractArtists(from songs: [Song]) -> Set<String> {
        return Set(songs.compactMap { $0.artist })
    }

    private func extractTags(from songs: [Song]) -> Set<String> {
        var allTags = Set<String>()
        for song in songs {
            if let tags = song.tags {
                allTags.formUnion(tags)
            }
        }
        return allTags
    }

    private func calculateStringSimilarity(_ str1: String, _ str2: String) -> Double {
        let s1 = str1.lowercased()
        let s2 = str2.lowercased()

        // Simple word overlap calculation
        let words1 = Set(s1.components(separatedBy: .whitespaces))
        let words2 = Set(s2.components(separatedBy: .whitespaces))

        let intersection = words1.intersection(words2)
        let union = words1.union(words2)

        guard !union.isEmpty else { return 0.0 }

        return Double(intersection.count) / Double(union.count)
    }
}
