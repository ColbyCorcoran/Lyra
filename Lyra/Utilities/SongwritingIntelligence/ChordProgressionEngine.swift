//
//  ChordProgressionEngine.swift
//  Lyra
//
//  Phase 7.14: AI Songwriting Assistance - Chord Progression Intelligence
//  On-device chord progression generation and continuation using music theory rules
//

import Foundation
import SwiftData

/// Engine for generating chord progressions and suggesting next chords
/// Uses rule-based music theory (100% on-device, no external APIs)
@MainActor
class ChordProgressionEngine {

    // MARK: - Shared Instance
    static let shared = ChordProgressionEngine()

    // MARK: - Music Theory Data

    /// Major scale chord qualities (I, ii, iii, IV, V, vi, vii°)
    private let majorScaleQualities = ["", "m", "m", "", "", "m", "dim"]

    /// Minor scale chord qualities (natural minor)
    private let minorScaleQualities = ["m", "dim", "", "m", "m", "", ""]

    /// Common chord progressions by genre
    private let genreProgressions: [String: [[Int]]] = [
        "pop": [
            [0, 3, 4, 0],      // I-IV-V-I
            [0, 5, 3, 4],      // I-vi-IV-V
            [5, 3, 0, 4],      // vi-IV-I-V (sensitive chord progression)
            [0, 4, 5, 3],      // I-V-vi-IV
            [3, 4, 0, 0]       // IV-V-I-I
        ],
        "rock": [
            [0, 3, 4, 0],      // I-IV-V-I
            [0, 6, 3, 4],      // I-bVII-IV-V
            [0, 3, 0, 4],      // I-IV-I-V
            [0, 5, 3, 4],      // I-vi-IV-V
            [4, 3, 0, 0]       // V-IV-I-I
        ],
        "jazz": [
            [0, 5, 1, 4],      // I-vi-ii-V (classic jazz)
            [1, 4, 0, 0],      // ii-V-I-I (turnaround)
            [0, 1, 4, 0],      // I-ii-V-I
            [3, 1, 4, 0],      // IV-ii-V-I
            [0, 2, 1, 4]       // I-iii-ii-V
        ],
        "folk": [
            [0, 0, 4, 4],      // I-I-V-V
            [0, 3, 0, 4],      // I-IV-I-V
            [0, 4, 0, 4],      // I-V-I-V
            [0, 3, 4, 0],      // I-IV-V-I
            [5, 3, 0, 4]       // vi-IV-I-V
        ],
        "country": [
            [0, 0, 4, 4],      // I-I-V-V
            [0, 3, 0, 4],      // I-IV-I-V
            [0, 0, 3, 4],      // I-I-IV-V
            [0, 3, 4, 3],      // I-IV-V-IV
            [0, 4, 3, 0]       // I-V-IV-I
        ],
        "blues": [
            [0, 0, 0, 0, 3, 3, 0, 0, 4, 3, 0, 4],  // 12-bar blues
            [0, 3, 0, 4],      // I-IV-I-V (simplified)
            [0, 0, 3, 3],      // I-I-IV-IV
            [0, 3, 4, 0]       // I-IV-V-I
        ],
        "worship": [
            [0, 3, 5, 4],      // I-IV-vi-V
            [5, 3, 0, 4],      // vi-IV-I-V
            [0, 5, 3, 4],      // I-vi-IV-V
            [3, 0, 4, 0],      // IV-I-V-I
            [0, 4, 5, 3]       // I-V-vi-IV
        ]
    ]

    /// Chromatic scale
    private let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// Enharmonic equivalents for key-appropriate naming
    private let enharmonicMap: [String: [String: String]] = [
        "sharp": ["C#": "C#", "D#": "D#", "F#": "F#", "G#": "G#", "A#": "A#"],
        "flat": ["C#": "Db", "D#": "Eb", "F#": "Gb", "G#": "Ab", "A#": "Bb"]
    ]

    // MARK: - Chord Progression Generation

    /// Generate a chord progression in a specific key and style
    func generateProgression(
        in key: String,
        style: String = "pop",
        length: Int = 4,
        isMinor: Bool = false
    ) -> GeneratedProgression {

        // Get template progressions for the style
        let templates = genreProgressions[style.lowercased()] ?? genreProgressions["pop"]!

        // Select a random template that matches desired length (or use longest available)
        var template = templates.randomElement() ?? [0, 3, 4, 0]

        // Adjust template length if needed
        if template.count > length {
            template = Array(template.prefix(length))
        } else if template.count < length {
            // Extend by repeating last chord or adding V-I resolution
            while template.count < length {
                if length - template.count == 1 {
                    template.append(0) // End on I
                } else {
                    template.append(4) // Add V chord
                }
            }
        }

        // Convert scale degrees to actual chords
        let chords = template.map { degree in
            buildChord(degree: degree, key: key, isMinor: isMinor)
        }

        // Create explanations
        let explanations = template.map { degree in
            explainChordFunction(degree: degree, isMinor: isMinor)
        }

        return GeneratedProgression(
            chords: chords,
            romanNumerals: template.map { degreeToRomanNumeral($0, isMinor: isMinor) },
            explanations: explanations,
            style: style,
            key: key,
            isMinor: isMinor
        )
    }

    /// Suggest next chord based on current progression
    func suggestNextChord(
        after progression: [String],
        in key: String,
        isMinor: Bool = false,
        count: Int = 3
    ) -> [ChordSuggestion] {

        var suggestions: [ChordSuggestion] = []

        // Analyze the current progression
        let lastChord = progression.last ?? key
        let lastDegree = chordToDegree(lastChord, in: key, isMinor: isMinor)

        // Get common progressions from this degree
        let nextDegrees = getCommonNextDegrees(from: lastDegree, isMinor: isMinor)

        // Build suggestions
        for (degree, probability, reason) in nextDegrees.prefix(count) {
            let chord = buildChord(degree: degree, key: key, isMinor: isMinor)
            let romanNumeral = degreeToRomanNumeral(degree, isMinor: isMinor)

            suggestions.append(ChordSuggestion(
                chord: chord,
                romanNumeral: romanNumeral,
                probability: probability,
                musicTheoryReason: reason,
                voicing: getBasicVoicing(for: chord)
            ))
        }

        return suggestions
    }

    /// Create variations of an existing progression
    func createVariations(
        of progression: [String],
        in key: String,
        isMinor: Bool = false,
        count: Int = 3
    ) -> [GeneratedProgression] {

        var variations: [GeneratedProgression] = []

        // Variation 1: Substitute with relative chords
        if progression.count >= 2 {
            var relativeSubstitution = progression
            // Substitute ii for IV (or vice versa)
            for i in 0..<relativeSubstitution.count {
                let degree = chordToDegree(relativeSubstitution[i], in: key, isMinor: isMinor)
                if degree == 3 { // IV -> ii
                    relativeSubstitution[i] = buildChord(degree: 1, key: key, isMinor: isMinor)
                } else if degree == 1 { // ii -> IV
                    relativeSubstitution[i] = buildChord(degree: 3, key: key, isMinor: isMinor)
                }
            }

            variations.append(GeneratedProgression(
                chords: relativeSubstitution,
                romanNumerals: relativeSubstitution.map { degreeToRomanNumeral(chordToDegree($0, in: key, isMinor: isMinor), isMinor: isMinor) },
                explanations: ["Relative substitution (ii ↔ IV)"],
                style: "variation",
                key: key,
                isMinor: isMinor
            ))
        }

        // Variation 2: Add passing chords
        if progression.count >= 2 {
            var withPassingChords: [String] = []
            for i in 0..<progression.count - 1 {
                withPassingChords.append(progression[i])
                // Add a passing chord between some chords
                if Double.random(in: 0...1) > 0.5 {
                    let degree = (chordToDegree(progression[i], in: key, isMinor: isMinor) + 1) % 7
                    withPassingChords.append(buildChord(degree: degree, key: key, isMinor: isMinor))
                }
            }
            withPassingChords.append(progression.last!)

            variations.append(GeneratedProgression(
                chords: withPassingChords,
                romanNumerals: withPassingChords.map { degreeToRomanNumeral(chordToDegree($0, in: key, isMinor: isMinor), isMinor: isMinor) },
                explanations: ["With passing chords"],
                style: "variation",
                key: key,
                isMinor: isMinor
            ))
        }

        // Variation 3: Modal interchange (borrow from parallel minor/major)
        var modalInterchange = progression
        if !isMinor && progression.count >= 2 {
            // Borrow bVII from minor
            modalInterchange[1] = buildChord(degree: 6, key: key, isMinor: true, flatted: true)

            variations.append(GeneratedProgression(
                chords: modalInterchange,
                romanNumerals: modalInterchange.map { degreeToRomanNumeral(chordToDegree($0, in: key, isMinor: false), isMinor: false) },
                explanations: ["Modal interchange (borrowed from parallel minor)"],
                style: "variation",
                key: key,
                isMinor: isMinor
            ))
        }

        return Array(variations.prefix(count))
    }

    // MARK: - Helper Methods

    private func buildChord(degree: Int, key: String, isMinor: Bool, flatted: Bool = false) -> String {
        // Get root note index
        guard let rootIndex = chromaticScale.firstIndex(of: key.uppercased()) else {
            return key
        }

        // Calculate chord root (degree in scale)
        let majorScaleIntervals = [0, 2, 4, 5, 7, 9, 11] // Major scale intervals
        let minorScaleIntervals = [0, 2, 3, 5, 7, 8, 10] // Natural minor scale intervals

        let intervals = isMinor ? minorScaleIntervals : majorScaleIntervals
        var semitones = intervals[min(degree, 6)]

        // Apply flatting for modal interchange
        if flatted && degree == 6 {
            semitones = 10 // bVII
        }

        let chordRootIndex = (rootIndex + semitones) % 12
        var chordRoot = chromaticScale[chordRootIndex]

        // Apply enharmonic spelling based on key
        if key.contains("#") {
            chordRoot = enharmonicMap["sharp"]?[chordRoot] ?? chordRoot
        } else if key.contains("b") {
            chordRoot = enharmonicMap["flat"]?[chordRoot] ?? chordRoot
        }

        // Get chord quality
        let qualities = isMinor ? minorScaleQualities : majorScaleQualities
        let quality = qualities[min(degree, 6)]

        return chordRoot + quality
    }

    private func chordToDegree(_ chord: String, in key: String, isMinor: Bool) -> Int {
        // Extract root note from chord symbol
        let root = String(chord.prefix(chord.count > 1 && (chord.contains("#") || chord.contains("b")) ? 2 : 1))

        guard let rootIndex = chromaticScale.firstIndex(where: { $0 == root || enharmonicMap["flat"]?[$0] == root }),
              let keyIndex = chromaticScale.firstIndex(of: key.uppercased()) else {
            return 0
        }

        let semitones = (rootIndex - keyIndex + 12) % 12

        let intervals = isMinor ? [0, 2, 3, 5, 7, 8, 10] : [0, 2, 4, 5, 7, 9, 11]

        // Find closest scale degree
        return intervals.enumerated().min(by: { abs($0.element - semitones) < abs($1.element - semitones) })?.offset ?? 0
    }

    private func getCommonNextDegrees(from degree: Int, isMinor: Bool) -> [(Int, Double, String)] {
        // Common progressions and their probabilities
        let commonProgressions: [Int: [(Int, Double, String)]] = [
            0: [ // From I
                (3, 0.35, "Strong subdominant movement (I → IV)"),
                (4, 0.30, "Dominant preparation (I → V)"),
                (5, 0.20, "Relative minor connection (I → vi)"),
                (1, 0.15, "Stepwise movement (I → ii)")
            ],
            1: [ // From ii
                (4, 0.60, "Classic ii-V progression"),
                (0, 0.25, "Deceptive resolution (ii → I)"),
                (3, 0.15, "Subdominant movement (ii → IV)")
            ],
            3: [ // From IV
                (4, 0.45, "Strong dominant movement (IV → V)"),
                (0, 0.35, "Plagal cadence (IV → I)"),
                (1, 0.20, "Stepwise descent (IV → ii)")
            ],
            4: [ // From V
                (0, 0.70, "Authentic cadence (V → I)"),
                (5, 0.20, "Deceptive cadence (V → vi)"),
                (3, 0.10, "Retrogression (V → IV)")
            ],
            5: [ // From vi
                (3, 0.40, "Relative major connection (vi → IV)"),
                (1, 0.30, "Stepwise movement (vi → ii)"),
                (4, 0.30, "Strong to dominant (vi → V)")
            ]
        ]

        return commonProgressions[degree] ?? [(0, 1.0, "Resolution to tonic")]
    }

    private func degreeToRomanNumeral(_ degree: Int, isMinor: Bool) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]
        let qualities = isMinor ? minorScaleQualities : majorScaleQualities

        var numeral = numerals[min(degree, 6)]
        let quality = qualities[min(degree, 6)]

        if quality == "m" {
            numeral = numeral.lowercased()
        } else if quality == "dim" {
            numeral = numeral.lowercased() + "°"
        }

        return numeral
    }

    private func explainChordFunction(degree: Int, isMinor: Bool) -> String {
        let functions = [
            "Tonic - Home base, stable and resolved",
            "Supertonic - Creates movement away from tonic",
            "Mediant - Gentle, transitional character",
            "Subdominant - Moves away from tonic, prepares for dominant",
            "Dominant - Strong tension, wants to resolve to tonic",
            "Submediant - Relative minor/major, emotional depth",
            "Leading tone - Strong pull back to tonic"
        ]

        return functions[min(degree, 6)]
    }

    private func getBasicVoicing(for chord: String) -> [String] {
        // Extract root
        let root = String(chord.prefix(chord.count > 1 && (chord.contains("#") || chord.contains("b")) ? 2 : 1))

        guard let rootIndex = chromaticScale.firstIndex(of: root) else {
            return [root]
        }

        // Determine chord type
        let isMinor = chord.contains("m") && !chord.contains("maj")
        let isDim = chord.contains("dim")

        // Build basic triad
        var voicing: [String] = [root]

        if isDim {
            // Diminished: R, m3, d5
            voicing.append(chromaticScale[(rootIndex + 3) % 12])
            voicing.append(chromaticScale[(rootIndex + 6) % 12])
        } else if isMinor {
            // Minor: R, m3, P5
            voicing.append(chromaticScale[(rootIndex + 3) % 12])
            voicing.append(chromaticScale[(rootIndex + 7) % 12])
        } else {
            // Major: R, M3, P5
            voicing.append(chromaticScale[(rootIndex + 4) % 12])
            voicing.append(chromaticScale[(rootIndex + 7) % 12])
        }

        return voicing
    }
}

// MARK: - Data Models

struct GeneratedProgression: Codable, Identifiable {
    let id: UUID = UUID()
    let chords: [String]
    let romanNumerals: [String]
    let explanations: [String]
    let style: String
    let key: String
    let isMinor: Bool
    let timestamp: Date = Date()
}

struct ChordSuggestion: Identifiable, Codable {
    let id: UUID = UUID()
    let chord: String
    let romanNumeral: String
    let probability: Double
    let musicTheoryReason: String
    let voicing: [String]
}
