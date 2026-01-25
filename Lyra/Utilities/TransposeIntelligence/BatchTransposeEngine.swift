//
//  BatchTransposeEngine.swift
//  Lyra
//
//  Engine for batch transposing multiple songs with flow optimization
//  Part of Phase 7.9: Transpose Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for batch transpose operations on setlists
@MainActor
class BatchTransposeEngine {

    // MARK: - Properties

    private let modelContext: ModelContext

    // Constants
    private let maxKeyJump = 5 // Maximum semitone jump between songs
    private let preferredKeyJump = 2 // Ideal semitone jump

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Setlist Key Analysis

    /// Analyze current keys in a setlist
    /// - Parameter songIDs: Array of song IDs in setlist
    /// - Returns: Setlist key analysis
    func analyzeSetlistKeys(songIDs: [UUID]) -> SetlistKeyAnalysis {
        let songs = fetchSongs(songIDs: songIDs)
        guard !songs.isEmpty else {
            return SetlistKeyAnalysis(
                songs: [],
                keyFlow: [],
                averageKeyJump: 0.0,
                problematicTransitions: []
            )
        }

        var keyFlow: [String] = []
        var keyJumps: [Int] = []
        var problematicTransitions: [ProblematicTransition] = []

        for (index, song) in songs.enumerated() {
            let key = song.currentKey ?? song.originalKey ?? "C"
            keyFlow.append(key)

            if index > 0 {
                let prevKey = keyFlow[index - 1]
                let jump = TransposeEngine.semitonesBetween(from: prevKey, to: key)
                keyJumps.append(abs(jump))

                // Identify problematic transitions
                if abs(jump) > maxKeyJump {
                    problematicTransitions.append(ProblematicTransition(
                        fromSongIndex: index - 1,
                        toSongIndex: index,
                        fromKey: prevKey,
                        toKey: key,
                        semitoneJump: jump,
                        severity: Float(abs(jump)) / 12.0
                    ))
                }
            }
        }

        let averageJump = keyJumps.isEmpty ? 0.0 :
            Float(keyJumps.reduce(0, +)) / Float(keyJumps.count)

        return SetlistKeyAnalysis(
            songs: songs.map { SongKeyInfo(id: $0.id, title: $0.title, currentKey: $0.currentKey ?? $0.originalKey ?? "C") },
            keyFlow: keyFlow,
            averageKeyJump: averageJump,
            problematicTransitions: problematicTransitions
        )
    }

    // MARK: - Common Key Suggestion

    /// Suggest a common key for entire setlist
    /// - Parameter songIDs: Array of song IDs
    /// - Returns: Common key suggestions with analysis
    func suggestCommonKey(songIDs: [UUID]) -> [CommonKeySuggestion] {
        let songs = fetchSongs(songIDs: songIDs)
        guard songs.count > 1 else { return [] }

        var suggestions: [CommonKeySuggestion] = []

        // Test all possible common keys
        for testKey in ["C", "G", "D", "A", "E", "F", "Bb", "Eb"] {
            var totalTranspose = 0
            var maxTranspose = 0
            var feasibleCount = 0

            for song in songs {
                let currentKey = song.currentKey ?? song.originalKey ?? "C"
                let semitones = TransposeEngine.semitonesBetween(from: currentKey, to: testKey)

                totalTranspose += abs(semitones)
                maxTranspose = max(maxTranspose, abs(semitones))

                // Check if transposition is reasonable (within 6 semitones)
                if abs(semitones) <= 6 {
                    feasibleCount += 1
                }
            }

            let averageTranspose = Float(totalTranspose) / Float(songs.count)
            let feasibilityScore = Float(feasibleCount) / Float(songs.count)

            // Only suggest if reasonably feasible
            if feasibilityScore >= 0.6 {
                suggestions.append(CommonKeySuggestion(
                    key: testKey,
                    averageTranspose: averageTranspose,
                    maxTranspose: maxTranspose,
                    feasibilityScore: feasibilityScore,
                    songsAffected: songs.count
                ))
            }
        }

        // Sort by feasibility and average transpose
        return suggestions.sorted {
            ($0.feasibilityScore, -$0.averageTranspose) > ($1.feasibilityScore, -$1.averageTranspose)
        }
    }

    // MARK: - Key Flow Optimization

    /// Optimize key transitions in a setlist
    /// - Parameters:
    ///   - songIDs: Array of song IDs in order
    ///   - preserveOrder: Whether to keep song order fixed
    /// - Returns: Optimized transpose plan
    func optimizeKeyFlow(
        songIDs: [UUID],
        preserveOrder: Bool = true
    ) -> KeyFlowOptimization {
        let songs = fetchSongs(songIDs: songIDs)
        guard songs.count > 1 else {
            return KeyFlowOptimization(
                originalOrder: songIDs,
                optimizedOrder: songIDs,
                transposeRecommendations: [:],
                improvementScore: 0.0
            )
        }

        if preserveOrder {
            return optimizeKeysFixedOrder(songs: songs)
        } else {
            return optimizeKeysAndOrder(songs: songs)
        }
    }

    // MARK: - Batch Transpose Preview

    /// Preview batch transpose operation
    /// - Parameters:
    ///   - songIDs: Songs to transpose
    ///   - transposeMap: Map of song ID to semitone shift
    /// - Returns: Preview of all changes
    func previewBatchTranspose(
        songIDs: [UUID],
        transposeMap: [UUID: Int]
    ) -> BatchTransposePreview {
        let songs = fetchSongs(songIDs: songIDs)

        let previews = songs.compactMap { song -> SongTransposePreview? in
            guard let semitones = transposeMap[song.id], semitones != 0 else {
                return nil
            }

            let originalKey = song.currentKey ?? song.originalKey ?? "C"
            let newKey = TransposeEngine.transpose(originalKey, by: semitones, preferSharps: true)

            // Get chord changes
            let chordChanges = TransposeEngine.previewTransposition(
                content: song.content,
                semitones: semitones,
                preferSharps: true
            )

            // Identify warnings
            var warnings: [String] = []
            if abs(semitones) > 6 {
                warnings.append("Large transposition (\(abs(semitones)) semitones)")
            }

            return SongTransposePreview(
                songID: song.id,
                songTitle: song.title,
                originalKey: originalKey,
                newKey: newKey,
                semitones: semitones,
                chordChangesCount: chordChanges.count,
                warnings: warnings
            )
        }

        return BatchTransposePreview(
            songsToTranspose: previews.count,
            previews: previews,
            totalSemitonesChanged: previews.reduce(0) { $0 + abs($1.semitones) }
        )
    }

    // MARK: - Apply Batch Transpose

    /// Apply batch transpose to songs
    /// - Parameters:
    ///   - transposeMap: Map of song ID to semitone shift
    ///   - saveMode: How to save changes
    func applyBatchTranspose(
        transposeMap: [UUID: Int],
        saveMode: TransposeSaveMode = .permanent
    ) {
        for (songID, semitones) in transposeMap {
            guard semitones != 0 else { continue }

            let descriptor = FetchDescriptor<Song>(
                predicate: #Predicate<Song> { $0.id == songID }
            )

            if let song = try? modelContext.fetch(descriptor).first {
                let transposedContent = TransposeEngine.transposeContent(
                    song.content,
                    by: semitones,
                    preferSharps: true
                )

                let newKey = TransposeEngine.transpose(
                    song.currentKey ?? song.originalKey ?? "C",
                    by: semitones,
                    preferSharps: true
                )

                switch saveMode {
                case .permanent:
                    song.content = transposedContent
                    song.currentKey = newKey
                    song.modifiedAt = Date()

                case .temporary:
                    // Temporary changes not persisted
                    break

                case .duplicate:
                    // Create duplicate song (handled elsewhere)
                    break
                }
            }
        }

        if saveMode == .permanent {
            try? modelContext.save()
        }
    }

    // MARK: - Private Helper Methods

    /// Fetch songs by IDs
    private func fetchSongs(songIDs: [UUID]) -> [Song] {
        var songs: [Song] = []

        for songID in songIDs {
            let descriptor = FetchDescriptor<Song>(
                predicate: #Predicate<Song> { $0.id == songID }
            )

            if let song = try? modelContext.fetch(descriptor).first {
                songs.append(song)
            }
        }

        return songs
    }

    /// Optimize keys with fixed song order
    private func optimizeKeysFixedOrder(songs: [Song]) -> KeyFlowOptimization {
        var transposeRecommendations: [UUID: Int] = [:]
        var currentKey = songs[0].currentKey ?? songs[0].originalKey ?? "C"

        for i in 1..<songs.count {
            let song = songs[i]
            let songKey = song.currentKey ?? song.originalKey ?? "C"

            let currentJump = abs(TransposeEngine.semitonesBetween(from: currentKey, to: songKey))

            // If jump is too large, suggest transpose to minimize it
            if currentJump > maxKeyJump {
                // Find best key within preferred range
                var bestTranspose = 0
                var bestJump = currentJump

                for testTranspose in -6...6 {
                    let testKey = TransposeEngine.transpose(songKey, by: testTranspose, preferSharps: true)
                    let testJump = abs(TransposeEngine.semitonesBetween(from: currentKey, to: testKey))

                    if testJump < bestJump {
                        bestJump = testJump
                        bestTranspose = testTranspose
                    }
                }

                if bestTranspose != 0 {
                    transposeRecommendations[song.id] = bestTranspose
                    currentKey = TransposeEngine.transpose(songKey, by: bestTranspose, preferSharps: true)
                } else {
                    currentKey = songKey
                }
            } else {
                currentKey = songKey
            }
        }

        let improvement = Float(transposeRecommendations.count) / Float(max(songs.count - 1, 1))

        return KeyFlowOptimization(
            originalOrder: songs.map { $0.id },
            optimizedOrder: songs.map { $0.id },
            transposeRecommendations: transposeRecommendations,
            improvementScore: improvement
        )
    }

    /// Optimize both keys and song order
    private func optimizeKeysAndOrder(songs: [Song]) -> KeyFlowOptimization {
        // For now, just use fixed order optimization
        // Full reordering would require more complex algorithm
        return optimizeKeysFixedOrder(songs: songs)
    }
}

// MARK: - Supporting Types

/// Analysis of setlist key flow
struct SetlistKeyAnalysis {
    var songs: [SongKeyInfo]
    var keyFlow: [String]
    var averageKeyJump: Float
    var problematicTransitions: [ProblematicTransition]
}

/// Song key information
struct SongKeyInfo: Identifiable {
    var id: UUID
    var title: String
    var currentKey: String
}

/// A problematic key transition
struct ProblematicTransition: Identifiable {
    var id = UUID()
    var fromSongIndex: Int
    var toSongIndex: Int
    var fromKey: String
    var toKey: String
    var semitoneJump: Int
    var severity: Float // 0.0-1.0
}

/// Common key suggestion
struct CommonKeySuggestion: Identifiable {
    var id = UUID()
    var key: String
    var averageTranspose: Float
    var maxTranspose: Int
    var feasibilityScore: Float
    var songsAffected: Int
}

/// Key flow optimization result
struct KeyFlowOptimization {
    var originalOrder: [UUID]
    var optimizedOrder: [UUID]
    var transposeRecommendations: [UUID: Int]
    var improvementScore: Float
}

/// Batch transpose preview
struct BatchTransposePreview {
    var songsToTranspose: Int
    var previews: [SongTransposePreview]
    var totalSemitonesChanged: Int
}

/// Single song transpose preview
struct SongTransposePreview: Identifiable {
    var id = UUID()
    var songID: UUID
    var songTitle: String
    var originalKey: String
    var newKey: String
    var semitones: Int
    var chordChangesCount: Int
    var warnings: [String]
}
