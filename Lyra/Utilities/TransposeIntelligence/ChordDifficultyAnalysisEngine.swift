//
//  ChordDifficultyAnalysisEngine.swift
//  Lyra
//
//  Engine for analyzing chord difficulty and finding easier keys
//  Part of Phase 7.9: Transpose Intelligence
//

import Foundation

/// Engine responsible for chord difficulty analysis
class ChordDifficultyAnalysisEngine {

    // MARK: - Constants

    // Difficulty scoring constants
    private let basicOpenChords: Set<String> = ["C", "G", "D", "Em", "Am", "E", "A", "Dm"]
    private let barreChords: Set<String> = ["F", "Fm", "Bm", "B", "Bb", "Bbm", "Gm", "Cm", "F#", "F#m", "Abm", "Ebm"]
    private let difficultRoots: Set<String> = ["C#", "Db", "D#", "Eb", "F#", "Gb", "G#", "Ab", "A#", "Bb"]

    // Skill level multipliers
    private let skillMultipliers: [SkillLevel: Float] = [
        .beginner: 1.5,
        .earlyIntermediate: 1.2,
        .intermediate: 1.0,
        .advanced: 0.8,
        .expert: 0.6
    ]

    // MARK: - Chord Difficulty Scoring

    /// Score a chord for a given skill level (0-10 scale)
    /// - Parameters:
    ///   - chord: Chord symbol (e.g., "Cmaj7", "Dm", "F#m7")
    ///   - skillLevel: Player's skill level
    /// - Returns: Difficulty score (0 = easiest, 10 = hardest)
    func scoreChordForSkillLevel(chord: String, skillLevel: SkillLevel) -> Float {
        guard let components = TransposeEngine.parseChord(chord) else {
            return 5.0 // Default moderate difficulty
        }

        var score: Float = 0.0

        // Base difficulty from root note and quality
        score += getBaseDifficulty(root: components.root, quality: components.quality)

        // Slash chord penalty
        if components.bass != nil {
            score += 1.5
        }

        // Apply skill level multiplier
        let multiplier = skillMultipliers[skillLevel] ?? 1.0
        score *= multiplier

        // Clamp to 0-10 range
        return min(max(score, 0.0), 10.0)
    }

    /// Calculate average difficulty for a set of chords
    /// - Parameters:
    ///   - chords: Array of chord symbols
    ///   - skillLevel: Player's skill level
    /// - Returns: Average difficulty score (0-10)
    func averageDifficulty(chords: [String], skillLevel: SkillLevel) -> Float {
        guard !chords.isEmpty else { return 0.0 }

        let totalDifficulty = chords.reduce(0.0) { sum, chord in
            sum + scoreChordForSkillLevel(chord: chord, skillLevel: skillLevel)
        }

        return totalDifficulty / Float(chords.count)
    }

    // MARK: - Find Easiest Key

    /// Find the easiest key to play a song
    /// - Parameters:
    ///   - content: Song content with chords
    ///   - currentKey: Current key of the song
    ///   - skillLevel: Player's skill level
    /// - Returns: Array of (semitones, difficulty) sorted by easiest first
    func findEasiestKey(
        content: String,
        currentKey: String?,
        skillLevel: SkillLevel
    ) -> [(semitones: Int, difficulty: Float)] {
        let originalChords = TransposeEngine.extractChords(from: content)
        guard !originalChords.isEmpty else { return [] }

        var results: [(semitones: Int, difficulty: Float)] = []

        // Test all 12 possible transpositions
        for semitones in -11...11 {
            let transposedChords = originalChords.map { chord in
                TransposeEngine.transpose(chord, by: semitones, preferSharps: true)
            }

            let avgDifficulty = averageDifficulty(chords: transposedChords, skillLevel: skillLevel)
            results.append((semitones: semitones, difficulty: avgDifficulty))
        }

        // Sort by difficulty (lowest first)
        return results.sorted { $0.difficulty < $1.difficulty }
    }

    // MARK: - Capo Options Comparison

    /// Compare difficulty with different capo positions
    /// - Parameters:
    ///   - content: Song content
    ///   - skillLevel: Player's skill level
    ///   - maxCapo: Maximum capo position to test (default 7)
    /// - Returns: Array of (capoPosition, difficulty, improvement)
    func compareCapoOptions(
        content: String,
        skillLevel: SkillLevel,
        maxCapo: Int = 7
    ) -> [(capo: Int, difficulty: Float, improvement: Float)] {
        let originalChords = TransposeEngine.extractChords(from: content)
        guard !originalChords.isEmpty else { return [] }

        let originalDifficulty = averageDifficulty(chords: originalChords, skillLevel: skillLevel)
        var results: [(capo: Int, difficulty: Float, improvement: Float)] = []

        // Test capo positions 0 through maxCapo
        for capoPosition in 0...maxCapo {
            let capoChords = originalChords.map { chord in
                TransposeEngine.transpose(chord, by: -capoPosition, preferSharps: true)
            }

            let capoDifficulty = averageDifficulty(chords: capoChords, skillLevel: skillLevel)
            let improvement = originalDifficulty - capoDifficulty

            results.append((
                capo: capoPosition,
                difficulty: capoDifficulty,
                improvement: improvement
            ))
        }

        // Sort by improvement (highest first)
        return results.sorted { $0.improvement > $1.improvement }
    }

    /// Get difficulty reduction by using capo
    /// - Parameters:
    ///   - content: Song content
    ///   - capoPosition: Capo fret position
    ///   - skillLevel: Player's skill level
    /// - Returns: Difficulty improvement (positive = easier with capo)
    func getDifficultyReduction(
        content: String,
        capoPosition: Int,
        skillLevel: SkillLevel
    ) -> Float {
        let originalChords = TransposeEngine.extractChords(from: content)
        guard !originalChords.isEmpty else { return 0.0 }

        let originalDifficulty = averageDifficulty(chords: originalChords, skillLevel: skillLevel)

        let capoChords = originalChords.map { chord in
            TransposeEngine.transpose(chord, by: -capoPosition, preferSharps: true)
        }

        let capoDifficulty = averageDifficulty(chords: capoChords, skillLevel: skillLevel)

        return originalDifficulty - capoDifficulty
    }

    // MARK: - Detailed Chord Analysis

    /// Get detailed analysis of chords in a song
    /// - Parameters:
    ///   - content: Song content
    ///   - skillLevel: Player's skill level
    /// - Returns: Dictionary mapping chords to their difficulty scores
    func analyzeChordDifficulties(
        content: String,
        skillLevel: SkillLevel
    ) -> [(chord: String, difficulty: Float)] {
        let chords = TransposeEngine.extractChords(from: content)
        return chords.map { chord in
            (chord: chord, difficulty: scoreChordForSkillLevel(chord: chord, skillLevel: skillLevel))
        }.sorted { $0.difficulty > $1.difficulty } // Hardest first
    }

    /// Identify the most difficult chords in a song
    /// - Parameters:
    ///   - content: Song content
    ///   - skillLevel: Player's skill level
    ///   - count: Number of difficult chords to return
    /// - Returns: Array of most difficult chords
    func getMostDifficultChords(
        content: String,
        skillLevel: SkillLevel,
        count: Int = 5
    ) -> [(chord: String, difficulty: Float)] {
        let analysis = analyzeChordDifficulties(content: content, skillLevel: skillLevel)
        return Array(analysis.prefix(count))
    }

    // MARK: - Private Helper Methods

    /// Get base difficulty for a chord
    private func getBaseDifficulty(root: String, quality: String) -> Float {
        var score: Float = 3.0 // Default moderate

        // Check root note complexity
        if basicOpenChords.contains(root) {
            score = 2.0 // Easy open chord
        } else if barreChords.contains(root) || difficultRoots.contains(root) {
            score = 6.0 // Barre chord or difficult root
        }

        // Adjust for chord quality/extensions
        if quality.isEmpty || quality == "m" {
            // Simple major or minor - keep base score
        } else if quality.contains("7") && !quality.contains("maj7") {
            score += 1.0 // Dominant 7th adds complexity
        } else if quality.contains("maj7") {
            score += 1.5 // Major 7th
        } else if quality.contains("9") {
            score += 2.0 // 9th chord
        } else if quality.contains("11") || quality.contains("13") {
            score += 2.5 // Extended chords
        } else if quality.contains("dim") || quality.contains("aug") {
            score += 2.0 // Diminished/augmented
        } else if quality.contains("sus") {
            score += 0.5 // Suspended chords
        } else if quality.contains("add") {
            score += 1.0 // Add chords
        }

        return score
    }

    /// Check if a chord is a barre chord
    private func isBarreChord(_ chord: String) -> Bool {
        guard let components = TransposeEngine.parseChord(chord) else { return false }
        return barreChords.contains(components.root) ||
               barreChords.contains(components.root + components.quality)
    }

    /// Count barre chords in a chord list
    func countBarreChords(_ chords: [String]) -> Int {
        return chords.filter { isBarreChord($0) }.count
    }

    /// Calculate barre chord percentage
    func barreChordPercentage(_ chords: [String]) -> Float {
        guard !chords.isEmpty else { return 0.0 }
        let barreCount = countBarreChords(chords)
        return Float(barreCount) / Float(chords.count)
    }
}
