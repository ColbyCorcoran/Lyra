//
//  CapoEngine.swift
//  Lyra
//
//  Capo calculation engine for guitarists
//

import Foundation

class CapoEngine {
    // MARK: - Capo Chord Calculation

    /// Get chords to play with capo
    /// - Parameters:
    ///   - actualChord: The actual chord in the song (e.g., "G" in a song in G)
    ///   - capoFret: The fret number where capo is placed (1-11)
    ///   - preferSharps: Whether to use sharps over flats
    /// - Returns: The chord shape to play (e.g., "F" for G with capo 2)
    static func capoChord(
        actualChord: String,
        capoFret: Int,
        preferSharps: Bool = true
    ) -> String {
        guard capoFret > 0 && capoFret <= 11 else {
            return actualChord
        }

        // Capo chords are transposed DOWN by the capo amount
        // If song is in G and you use capo 2, you play F shapes
        return TransposeEngine.transpose(actualChord, by: -capoFret, preferSharps: preferSharps)
    }

    /// Get all capo chords for song content
    /// - Parameters:
    ///   - content: Original ChordPro content
    ///   - capoFret: Capo position
    ///   - preferSharps: Sharp/flat preference
    /// - Returns: Content with capo chords
    static func capoContent(
        _ content: String,
        capoFret: Int,
        preferSharps: Bool = true
    ) -> String {
        guard capoFret > 0 && capoFret <= 11 else {
            return content
        }

        return TransposeEngine.transposeContent(content, by: -capoFret, preferSharps: preferSharps)
    }

    // MARK: - Capo Suggestions

    /// Difficulty rating for a chord
    enum ChordDifficulty: Int, Comparable {
        case veryEasy = 1    // C, Am, Em, G (no barre)
        case easy = 2        // D, A, E, Dm (easy open chords)
        case moderate = 3    // F (partial barre), Bm (barre)
        case hard = 4        // Barre chords, complex fingerings
        case veryHard = 5    // Complex extensions, unusual voicings

        static func < (lhs: ChordDifficulty, rhs: ChordDifficulty) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Get difficulty rating for a chord
    static func chordDifficulty(_ chord: String) -> ChordDifficulty {
        // Extract root note
        guard let components = TransposeEngine.parseChord(chord) else {
            return .moderate
        }

        let root = components.root

        // Very easy open chords (beginner friendly, no barre)
        let veryEasyRoots = ["C", "Am", "Em", "G"]
        if veryEasyRoots.contains(root) && !components.quality.contains("7") {
            return .veryEasy
        }

        // Easy open chords
        let easyRoots = ["D", "A", "E", "Dm", "G"]
        if easyRoots.contains(root) {
            return .easy
        }

        // Barre chords and harder shapes
        let barreRoots = ["F", "Fm", "Bm", "B", "Bb", "Gm", "Cm"]
        if barreRoots.contains(root) || barreRoots.contains(root + components.quality) {
            return .hard
        }

        // Complex extensions
        if components.quality.contains("9") || components.quality.contains("11") ||
           components.quality.contains("13") || components.quality.contains("dim") {
            return .veryHard
        }

        // Anything with sharps/flats tends to be harder
        if root.contains("#") || root.contains("b") {
            return .hard
        }

        return .moderate
    }

    /// Calculate average difficulty for a set of chords
    static func averageDifficulty(chords: [String]) -> Double {
        guard !chords.isEmpty else { return 0 }

        let total = chords.reduce(0) { sum, chord in
            sum + chordDifficulty(chord).rawValue
        }

        return Double(total) / Double(chords.count)
    }

    /// Suggest optimal capo positions for easier playing
    /// - Parameters:
    ///   - content: Song content to analyze
    ///   - currentKey: Current key of song
    /// - Returns: Array of capo suggestions with difficulty ratings
    static func suggestCapo(
        content: String,
        currentKey: String?
    ) -> [CapoSuggestion] {
        // Extract all chords from content
        let originalChords = TransposeEngine.extractChords(from: content)
        guard !originalChords.isEmpty else {
            return []
        }

        // Calculate difficulty for original (no capo)
        let originalDifficulty = averageDifficulty(chords: originalChords)

        var suggestions: [CapoSuggestion] = []

        // Try capo positions 1-7 (common range)
        for capoFret in 1...7 {
            // Get capo chords
            let capoChords = originalChords.map { chord in
                capoChord(actualChord: chord, capoFret: capoFret)
            }

            // Calculate difficulty
            let capoDifficulty = averageDifficulty(chords: capoChords)

            // Only suggest if it makes chords easier
            let improvement = originalDifficulty - capoDifficulty

            if improvement > 0.3 { // Meaningful improvement threshold
                let suggestion = CapoSuggestion(
                    fret: capoFret,
                    difficulty: capoDifficulty,
                    improvement: improvement,
                    sampleChords: Array(capoChords.prefix(4)),
                    reason: generateReason(
                        improvement: improvement,
                        originalDifficulty: originalDifficulty,
                        capoDifficulty: capoDifficulty
                    )
                )
                suggestions.append(suggestion)
            }
        }

        // Sort by improvement (best first)
        return suggestions.sorted { $0.improvement > $1.improvement }
    }

    private static func generateReason(
        improvement: Double,
        originalDifficulty: Double,
        capoDifficulty: Double
    ) -> String {
        if improvement > 1.5 {
            return "Much easier chords - highly recommended"
        } else if improvement > 1.0 {
            return "Significantly easier chords"
        } else if improvement > 0.5 {
            return "Moderately easier chords"
        } else {
            return "Slightly easier chords"
        }
    }

    // MARK: - Key Analysis

    /// Analyze what key the song sounds in with capo
    static func soundingKey(
        originalKey: String?,
        capoFret: Int,
        preferSharps: Bool = true
    ) -> String? {
        guard let key = originalKey, capoFret > 0 else {
            return originalKey
        }

        // With capo, the sounding key is HIGHER than written
        // Capo 2 in F = sounds like G
        return TransposeEngine.transpose(key, by: capoFret, preferSharps: preferSharps)
    }

    /// Analyze what key to write/play for a sounding key with capo
    static func writtenKey(
        soundingKey: String?,
        capoFret: Int,
        preferSharps: Bool = true
    ) -> String? {
        guard let key = soundingKey, capoFret > 0 else {
            return soundingKey
        }

        // To find what to play, transpose DOWN from sounding key
        return TransposeEngine.transpose(key, by: -capoFret, preferSharps: preferSharps)
    }

    // MARK: - Common Capo Patterns

    /// Common capo positions for different keys
    static func commonCapoPositions(for key: String) -> [CapoPattern] {
        let patterns: [String: [CapoPattern]] = [
            "C": [
                CapoPattern(capo: 0, plays: "C", reason: "Natural open position"),
                CapoPattern(capo: 5, plays: "G", reason: "Play easier G shapes")
            ],
            "G": [
                CapoPattern(capo: 0, plays: "G", reason: "Natural open position"),
                CapoPattern(capo: 2, plays: "F", reason: "Simpler F-based chords"),
                CapoPattern(capo: 7, plays: "C", reason: "Play easy C shapes")
            ],
            "D": [
                CapoPattern(capo: 0, plays: "D", reason: "Natural open position"),
                CapoPattern(capo: 2, plays: "C", reason: "Play easy C shapes"),
                CapoPattern(capo: 5, plays: "A", reason: "Play easy A shapes")
            ],
            "A": [
                CapoPattern(capo: 0, plays: "A", reason: "Natural open position"),
                CapoPattern(capo: 2, plays: "G", reason: "Play easy G shapes"),
                CapoPattern(capo: 5, plays: "E", reason: "Play easy E shapes")
            ],
            "E": [
                CapoPattern(capo: 0, plays: "E", reason: "Natural open position"),
                CapoPattern(capo: 2, plays: "D", reason: "Play easy D shapes"),
                CapoPattern(capo: 4, plays: "C", reason: "Play easy C shapes")
            ],
            "Bb": [
                CapoPattern(capo: 1, plays: "A", reason: "Avoid barre chords"),
                CapoPattern(capo: 3, plays: "G", reason: "Play easy G shapes")
            ],
            "F": [
                CapoPattern(capo: 1, plays: "E", reason: "Avoid F barre chord"),
                CapoPattern(capo: 3, plays: "D", reason: "Play easy D shapes"),
                CapoPattern(capo: 5, plays: "C", reason: "Play easy C shapes")
            ]
        ]

        return patterns[key] ?? []
    }

    // MARK: - Capo + Transpose Interaction

    /// Explain what's happening with capo and transpose together
    static func explainCapoTranspose(
        originalKey: String?,
        transpose: Int,
        capo: Int
    ) -> CapoTransposeExplanation {
        guard let original = originalKey else {
            return CapoTransposeExplanation(
                originalKey: "Unknown",
                transposedKey: "Unknown",
                capoChords: "Unknown",
                soundingKey: "Unknown",
                explanation: "Key information not available"
            )
        }

        // Step 1: Transpose changes the actual song key
        let transposedKey = transpose != 0 ?
            TransposeEngine.transpose(original, by: transpose, preferSharps: true) :
            original

        // Step 2: Capo changes what chords you play
        let capoChords = capo > 0 ?
            TransposeEngine.transpose(transposedKey, by: -capo, preferSharps: true) :
            transposedKey

        // Step 3: What it sounds like
        let soundingKey = capo > 0 ?
            TransposeEngine.transpose(capoChords, by: capo, preferSharps: true) :
            capoChords

        // Generate explanation
        var explanation = ""
        if transpose != 0 && capo > 0 {
            explanation = "Song transposed from \(original) to \(transposedKey). "
            explanation += "With capo on fret \(capo), you play \(capoChords) shapes. "
            explanation += "It sounds in \(soundingKey)."
        } else if transpose != 0 {
            explanation = "Song transposed from \(original) to \(transposedKey). "
            explanation += "No capo, so you play \(transposedKey) chords."
        } else if capo > 0 {
            explanation = "Song in \(original). "
            explanation += "With capo on fret \(capo), you play \(capoChords) shapes. "
            explanation += "It sounds in \(soundingKey)."
        } else {
            explanation = "Song in \(original) with no capo or transposition."
        }

        return CapoTransposeExplanation(
            originalKey: original,
            transposedKey: transposedKey,
            capoChords: capoChords,
            soundingKey: soundingKey,
            explanation: explanation
        )
    }
}

// MARK: - Models

struct CapoSuggestion: Identifiable {
    let id = UUID()
    let fret: Int
    let difficulty: Double
    let improvement: Double
    let sampleChords: [String]
    let reason: String

    var difficultyDescription: String {
        switch difficulty {
        case ..<2.0: return "Very Easy"
        case 2.0..<2.5: return "Easy"
        case 2.5..<3.5: return "Moderate"
        case 3.5..<4.5: return "Hard"
        default: return "Very Hard"
        }
    }

    var improvementDescription: String {
        let percentage = Int(improvement / 5.0 * 100)
        return "\(percentage)% easier"
    }
}

struct CapoPattern: Identifiable {
    let id = UUID()
    let capo: Int
    let plays: String
    let reason: String
}

struct CapoTransposeExplanation {
    let originalKey: String
    let transposedKey: String
    let capoChords: String
    let soundingKey: String
    let explanation: String
}

/// Display mode for capo chords
enum CapoDisplayMode: String, CaseIterable, Identifiable {
    case actual = "Actual Chords"
    case capo = "Capo Chords"
    case dual = "Both (Dual Display)"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .actual:
            return "Show the actual chords in the song"
        case .capo:
            return "Show the chord shapes to play with capo"
        case .dual:
            return "Show both actual and capo chords"
        }
    }

    var icon: String {
        switch self {
        case .actual: return "music.note"
        case .capo: return "guitars"
        case .dual: return "square.split.2x1"
        }
    }
}
