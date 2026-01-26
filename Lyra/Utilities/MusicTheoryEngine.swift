//
//  MusicTheoryEngine.swift
//  Lyra
//
//  Music theory engine for key detection, chord validation, and capo suggestions
//  Part of Phase 7: Logical Intelligence
//

import Foundation

/// Rule-based music theory engine for chord analysis
class MusicTheoryEngine {

    // MARK: - Properties

    /// Chromatic scale
    private let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// Key signatures with their diatonic chords
    private let keySignatures: [KeySignature] = [
        // Major keys
        KeySignature(root: "C", scale: .major, notes: ["C", "D", "E", "F", "G", "A", "B"],
                     commonChords: ["C", "Dm", "Em", "F", "G", "Am", "Bdim"]),
        KeySignature(root: "G", scale: .major, notes: ["G", "A", "B", "C", "D", "E", "F#"],
                     commonChords: ["G", "Am", "Bm", "C", "D", "Em", "F#dim"]),
        KeySignature(root: "D", scale: .major, notes: ["D", "E", "F#", "G", "A", "B", "C#"],
                     commonChords: ["D", "Em", "F#m", "G", "A", "Bm", "C#dim"]),
        KeySignature(root: "A", scale: .major, notes: ["A", "B", "C#", "D", "E", "F#", "G#"],
                     commonChords: ["A", "Bm", "C#m", "D", "E", "F#m", "G#dim"]),
        KeySignature(root: "E", scale: .major, notes: ["E", "F#", "G#", "A", "B", "C#", "D#"],
                     commonChords: ["E", "F#m", "G#m", "A", "B", "C#m", "D#dim"]),
        KeySignature(root: "B", scale: .major, notes: ["B", "C#", "D#", "E", "F#", "G#", "A#"],
                     commonChords: ["B", "C#m", "D#m", "E", "F#", "G#m", "A#dim"]),
        KeySignature(root: "F", scale: .major, notes: ["F", "G", "A", "Bb", "C", "D", "E"],
                     commonChords: ["F", "Gm", "Am", "Bb", "C", "Dm", "Edim"]),
        KeySignature(root: "Bb", scale: .major, notes: ["Bb", "C", "D", "Eb", "F", "G", "A"],
                     commonChords: ["Bb", "Cm", "Dm", "Eb", "F", "Gm", "Adim"]),
        KeySignature(root: "Eb", scale: .major, notes: ["Eb", "F", "G", "Ab", "Bb", "C", "D"],
                     commonChords: ["Eb", "Fm", "Gm", "Ab", "Bb", "Cm", "Ddim"]),

        // Minor keys (natural minor)
        KeySignature(root: "Am", scale: .minor, notes: ["A", "B", "C", "D", "E", "F", "G"],
                     commonChords: ["Am", "Bdim", "C", "Dm", "Em", "F", "G"]),
        KeySignature(root: "Em", scale: .minor, notes: ["E", "F#", "G", "A", "B", "C", "D"],
                     commonChords: ["Em", "F#dim", "G", "Am", "Bm", "C", "D"]),
        KeySignature(root: "Bm", scale: .minor, notes: ["B", "C#", "D", "E", "F#", "G", "A"],
                     commonChords: ["Bm", "C#dim", "D", "Em", "F#m", "G", "A"]),
        KeySignature(root: "F#m", scale: .minor, notes: ["F#", "G#", "A", "B", "C#", "D", "E"],
                     commonChords: ["F#m", "G#dim", "A", "Bm", "C#m", "D", "E"]),
        KeySignature(root: "C#m", scale: .minor, notes: ["C#", "D#", "E", "F#", "G#", "A", "B"],
                     commonChords: ["C#m", "D#dim", "E", "F#m", "G#m", "A", "B"]),
        KeySignature(root: "Dm", scale: .minor, notes: ["D", "E", "F", "G", "A", "Bb", "C"],
                     commonChords: ["Dm", "Edim", "F", "Gm", "Am", "Bb", "C"]),
        KeySignature(root: "Gm", scale: .minor, notes: ["G", "A", "Bb", "C", "D", "Eb", "F"],
                     commonChords: ["Gm", "Adim", "Bb", "Cm", "Dm", "Eb", "F"]),
        KeySignature(root: "Cm", scale: .minor, notes: ["C", "D", "Eb", "F", "G", "Ab", "Bb"],
                     commonChords: ["Cm", "Ddim", "Eb", "Fm", "Gm", "Ab", "Bb"])
    ]

    /// Easy guitar keys (for capo suggestions)
    private let easyGuitarKeys = ["C", "G", "D", "A", "E", "Am", "Em", "Dm"]

    // MARK: - Key Detection

    /// Detect the key from a series of chords
    func detectKey(from chords: [String]) -> SimpleKeyDetectionResult? {
        guard !chords.isEmpty else { return nil }

        var keyScores: [(key: KeySignature, score: Float)] = []

        // Score each possible key
        for key in keySignatures {
            let score = scoreKey(key, against: chords)
            keyScores.append((key: key, score: score))
        }

        // Sort by score
        keyScores.sort { $0.score > $1.score }

        guard let topKey = keyScores.first else { return nil }

        // Calculate confidence
        let confidence = calculateKeyConfidence(scores: keyScores.map { $0.score })

        // Get alternative keys
        let alternatives = keyScores.dropFirst().prefix(3).map {
            SimpleKeyDetectionResult(
                key: $0.key.root,
                scale: $0.key.scale,
                confidence: $0.score
            )
        }

        return SimpleKeyDetectionResult(
            key: topKey.key.root,
            scale: topKey.key.scale,
            confidence: confidence,
            alternatives: alternatives
        )
    }

    /// Score how well a key matches the given chords
    private func scoreKey(_ key: KeySignature, against chords: [String]) -> Float {
        var score: Float = 0
        let totalChords = chords.count

        for chord in chords {
            let chordRoot = extractChordRoot(chord)

            // Check if chord is diatonic to this key
            if key.commonChords.contains(where: { matchesChord($0, chordRoot) }) {
                score += 1.0
            } else {
                // Check if at least the root note is in the scale
                if key.notes.contains(chordRoot) {
                    score += 0.5
                }
            }

            // Bonus for tonic (I) chord
            if matchesChord(key.root, chordRoot) {
                score += 0.5
            }

            // Bonus for dominant (V) chord
            if key.commonChords.count > 4 {
                let dominantChord = key.commonChords[4]
                if matchesChord(dominantChord, chord) {
                    score += 0.3
                }
            }
        }

        // Normalize score
        return score / Float(totalChords)
    }

    /// Extract root note from chord name
    func extractChordRoot(_ chord: String) -> String {
        // Handle two-character roots (e.g., "C#", "Bb")
        if chord.count >= 2 {
            let firstTwo = String(chord.prefix(2))
            if chromaticScale.contains(firstTwo) {
                return firstTwo
            }
        }

        // Single character root
        if chord.count >= 1 {
            let first = String(chord.prefix(1))
            if chromaticScale.contains(first) {
                return first
            }
        }

        return chord
    }

    /// Check if two chords match (ignoring quality)
    private func matchesChord(_ a: String, _ b: String) -> Bool {
        let rootA = extractChordRoot(a)
        let rootB = extractChordRoot(b)
        return rootA == rootB
    }

    /// Calculate confidence based on score distribution
    private func calculateKeyConfidence(scores: [Float]) -> Float {
        guard scores.count > 1 else { return 0.5 }

        let topScore = scores[0]
        let secondScore = scores[1]

        // Higher difference = higher confidence
        let difference = topScore - secondScore
        return min(1.0, difference * 2.0)
    }

    // MARK: - Capo Suggestions

    /// Suggest capo position to play in an easier key
    func suggestCapoPosition(for key: String) -> Int {
        // If already an easy key, no capo needed
        if easyGuitarKeys.contains(key) {
            return 0
        }

        // Find the nearest easy key
        guard let keyIndex = chromaticScale.firstIndex(of: extractChordRoot(key)) else {
            return 0
        }

        var bestCapo = 0
        var bestScore = 0

        // Try capo positions 1-7
        for capo in 1...7 {
            let transposedIndex = (keyIndex - capo + 12) % 12
            let transposedKey = chromaticScale[transposedIndex]

            // Check if transposed key is easy
            if easyGuitarKeys.contains(transposedKey) {
                // Prefer lower capo positions
                let score = 10 - capo
                if score > bestScore {
                    bestScore = score
                    bestCapo = capo
                }
            }
        }

        return bestCapo
    }

    /// Transpose a chord by semitones
    func transposeChord(_ chord: String, by semitones: Int) -> String {
        let root = extractChordRoot(chord)
        guard let rootIndex = chromaticScale.firstIndex(of: root) else {
            return chord
        }

        // Calculate new root
        let newIndex = (rootIndex + semitones + 12) % 12
        let newRoot = chromaticScale[newIndex]

        // Replace root in chord
        return chord.replacingOccurrences(of: root, with: newRoot)
    }

    /// Get chord quality (major, minor, 7th, etc.)
    func getChordQuality(_ chord: String) -> ChordQuality {
        let root = extractChordRoot(chord)
        let suffix = String(chord.dropFirst(root.count)).lowercased()

        if suffix.isEmpty {
            return .major
        } else if suffix.contains("m") && !suffix.contains("maj") {
            return .minor
        } else if suffix.contains("7") && !suffix.contains("maj") {
            return .dominant7
        } else if suffix.contains("maj7") {
            return .major7
        } else if suffix.contains("m7") {
            return .minor7
        } else if suffix.contains("dim") {
            return .diminished
        } else if suffix.contains("aug") {
            return .augmented
        } else if suffix.contains("sus") {
            return .suspended
        } else {
            return .other
        }
    }

    // MARK: - Chord Validation

    /// Validate if a chord is diatonic to a key
    func validateChord(_ chord: String, in key: String) -> Bool {
        guard let keySignature = keySignatures.first(where: { $0.root == key }) else {
            return false
        }

        let chordRoot = extractChordRoot(chord)
        return keySignature.notes.contains(chordRoot)
    }

    /// Suggest corrections for a chord in a given key
    func suggestCorrections(for chord: String, in key: String) -> [String] {
        guard let keySignature = keySignatures.first(where: { $0.root == key }) else {
            return []
        }

        let chordRoot = extractChordRoot(chord)

        // If chord is already diatonic, no correction needed
        if keySignature.notes.contains(chordRoot) {
            return []
        }

        // Find enharmonic equivalent
        var suggestions: [String] = []

        // Check for sharp/flat alternatives
        if let sharpVersion = getEnharmonicEquivalent(chordRoot) {
            if keySignature.notes.contains(sharpVersion) {
                let corrected = chord.replacingOccurrences(of: chordRoot, with: sharpVersion)
                suggestions.append(corrected)
            }
        }

        // Suggest nearest diatonic chord
        if let nearest = findNearestDiatonicChord(to: chordRoot, in: keySignature) {
            suggestions.append(nearest)
        }

        return suggestions
    }

    /// Get enharmonic equivalent (e.g., C# <-> Db)
    func getEnharmonicEquivalent(_ note: String) -> String? {
        let enharmonics: [String: String] = [
            "C#": "Db", "Db": "C#",
            "D#": "Eb", "Eb": "D#",
            "F#": "Gb", "Gb": "F#",
            "G#": "Ab", "Ab": "G#",
            "A#": "Bb", "Bb": "A#"
        ]

        return enharmonics[note]
    }

    /// Find the nearest diatonic chord in a key
    private func findNearestDiatonicChord(to note: String, in key: KeySignature) -> String? {
        guard let noteIndex = chromaticScale.firstIndex(of: note) else {
            return nil
        }

        var nearestDistance = 12
        var nearestChord: String?

        for diatonicNote in key.notes {
            guard let diatonicIndex = chromaticScale.firstIndex(of: diatonicNote) else {
                continue
            }

            let distance = min(
                abs(noteIndex - diatonicIndex),
                12 - abs(noteIndex - diatonicIndex)
            )

            if distance < nearestDistance {
                nearestDistance = distance
                nearestChord = diatonicNote
            }
        }

        return nearestChord
    }

    // MARK: - Key Relationships

    /// Get the relative major/minor key
    func getRelativeKey(_ key: String) -> String? {
        let root = extractChordRoot(key)
        let isMinor = key.contains("m") && !key.contains("maj")

        if isMinor {
            // Relative major is 3 semitones up
            guard let rootIndex = chromaticScale.firstIndex(of: root) else {
                return nil
            }
            let majorIndex = (rootIndex + 3) % 12
            return chromaticScale[majorIndex]
        } else {
            // Relative minor is 3 semitones down
            guard let rootIndex = chromaticScale.firstIndex(of: root) else {
                return nil
            }
            let minorIndex = (rootIndex - 3 + 12) % 12
            return chromaticScale[minorIndex] + "m"
        }
    }

    /// Get the dominant (V) key
    func getDominantKey(_ key: String) -> String? {
        let root = extractChordRoot(key)
        let isMinor = key.contains("m") && !key.contains("maj")

        guard let rootIndex = chromaticScale.firstIndex(of: root) else {
            return nil
        }

        // Dominant is 7 semitones up (perfect fifth)
        let dominantIndex = (rootIndex + 7) % 12
        let dominantRoot = chromaticScale[dominantIndex]

        return isMinor ? dominantRoot + "m" : dominantRoot
    }

    /// Get the subdominant (IV) key
    func getSubdominantKey(_ key: String) -> String? {
        let root = extractChordRoot(key)
        let isMinor = key.contains("m") && !key.contains("maj")

        guard let rootIndex = chromaticScale.firstIndex(of: root) else {
            return nil
        }

        // Subdominant is 5 semitones up (perfect fourth)
        let subdominantIndex = (rootIndex + 5) % 12
        let subdominantRoot = chromaticScale[subdominantIndex]

        return isMinor ? subdominantRoot + "m" : subdominantRoot
    }
}

// MARK: - Supporting Types

enum ScaleType: String, Codable {
    case major = "Major"
    case minor = "Minor"
}

struct SimpleKeyDetectionResult {
    let key: String
    let scale: ScaleType
    let confidence: Float
    let alternatives: [SimpleKeyDetectionResult]

    init(key: String, scale: ScaleType, confidence: Float, alternatives: [SimpleKeyDetectionResult] = []) {
        self.key = key
        self.scale = scale
        self.confidence = confidence
        self.alternatives = alternatives
    }

    var fullKeyName: String {
        "\(key) \(scale.rawValue)"
    }
}

struct KeySignature {
    let root: String
    let scale: ScaleType
    let notes: [String]
    let commonChords: [String]
}

enum ChordQuality {
    case major
    case minor
    case dominant7
    case major7
    case minor7
    case diminished
    case augmented
    case suspended
    case other
}
