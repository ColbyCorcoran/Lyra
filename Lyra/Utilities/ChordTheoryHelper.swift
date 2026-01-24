//
//  ChordTheoryHelper.swift
//  Lyra
//
//  Provides educational chord theory information
//  Part of Phase 7.2: Chord Analysis Intelligence
//

import Foundation

/// Provides theoretical information and education about chords
class ChordTheoryHelper {

    // MARK: - Properties

    private let theoryEngine: MusicTheoryEngine

    private let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    // Chord formulas (intervals from root)
    private let chordFormulas: [String: (intervals: [Int], formula: String, description: String)] = [
        "major": ([0, 4, 7], "1-3-5", "Major triad - happy, bright sound"),
        "minor": ([0, 3, 7], "1-♭3-5", "Minor triad - sad, dark sound"),
        "diminished": ([0, 3, 6], "1-♭3-♭5", "Diminished triad - tense, unstable"),
        "augmented": ([0, 4, 8], "1-3-#5", "Augmented triad - mysterious, dreamlike"),
        "dominant7": ([0, 4, 7, 10], "1-3-5-♭7", "Dominant 7th - bluesy, wants to resolve"),
        "major7": ([0, 4, 7, 11], "1-3-5-7", "Major 7th - jazzy, sophisticated"),
        "minor7": ([0, 3, 7, 10], "1-♭3-5-♭7", "Minor 7th - smooth, mellow"),
        "sus4": ([0, 5, 7], "1-4-5", "Suspended 4th - suspended tension"),
        "sus2": ([0, 2, 7], "1-2-5", "Suspended 2nd - open, ambiguous"),
        "add9": ([0, 4, 7, 14], "1-3-5-9", "Added 9th - colorful, rich"),
        "6": ([0, 4, 7, 9], "1-3-5-6", "Major 6th - bright, jazzy")
    ]

    // MARK: - Initialization

    init() {
        self.theoryEngine = MusicTheoryEngine()
    }

    // MARK: - Chord Information

    /// Get comprehensive theory information for a chord
    func getChordInfo(_ chord: String) -> ChordTheoryInfo {
        let root = theoryEngine.extractChordRoot(chord)
        let quality = theoryEngine.getChordQuality(chord)

        // Get formula and intervals
        let qualityKey = qualityToKey(quality)
        let (intervals, formula, description) = chordFormulas[qualityKey] ?? ([0, 4, 7], "1-3-5", "Major chord")

        // Calculate actual notes
        let notes = calculateNotes(root: root, intervals: intervals)

        // Find related chords
        let related = findRelatedChords(chord, root: root, quality: quality)

        // Common progressions using this chord
        let progressions = getCommonProgressions(for: chord)

        return ChordTheoryInfo(
            chord: chord,
            root: root,
            quality: quality,
            intervals: intervals,
            notes: notes,
            formula: formula,
            description: description,
            relatedChords: related,
            commonProgressions: progressions
        )
    }

    // MARK: - Note Calculation

    /// Calculate the notes in a chord given root and intervals
    private func calculateNotes(root: String, intervals: [Int]) -> [String] {
        guard let rootIndex = chromaticScale.firstIndex(of: root) else {
            return []
        }

        return intervals.map { interval in
            let noteIndex = (rootIndex + interval) % 12
            return chromaticScale[noteIndex]
        }
    }

    // MARK: - Related Chords

    /// Find chords related to the given chord
    private func findRelatedChords(_ chord: String, root: String, quality: ChordQuality) -> [RelatedChord] {
        var related: [RelatedChord] = []

        // Parallel major/minor
        if quality == .major {
            related.append(RelatedChord(
                chord: "\(root)m",
                relationship: .parallel,
                substitutionContext: "Parallel minor - same root, different quality"
            ))
        } else if quality == .minor {
            related.append(RelatedChord(
                chord: root,
                relationship: .parallel,
                substitutionContext: "Parallel major - same root, different quality"
            ))
        }

        // Relative major/minor
        if quality == .major {
            let relativeMinor = theoryEngine.transposeChord(root, by: 9) // 6th scale degree
            related.append(RelatedChord(
                chord: "\(relativeMinor)m",
                relationship: .relative,
                substitutionContext: "Relative minor - shares the same notes"
            ))
        } else if quality == .minor {
            let relativeMajor = theoryEngine.transposeChord(root, by: 3) // 3rd scale degree
            related.append(RelatedChord(
                chord: relativeMajor,
                relationship: .relative,
                substitutionContext: "Relative major - shares the same notes"
            ))
        }

        // Dominant (V chord)
        let dominant = theoryEngine.transposeChord(root, by: 7)
        related.append(RelatedChord(
            chord: "\(dominant)7",
            relationship: .dominant,
            substitutionContext: "Dominant 7th - creates tension, wants to resolve to \(chord)"
        ))

        // Subdominant (IV chord)
        let subdominant = theoryEngine.transposeChord(root, by: 5)
        related.append(RelatedChord(
            chord: subdominant,
            relationship: .subdominant,
            substitutionContext: "Subdominant - often precedes the dominant"
        ))

        // Extended version (add 7th)
        if quality == .major {
            related.append(RelatedChord(
                chord: "\(root)maj7",
                relationship: .extended,
                substitutionContext: "Major 7th - richer, more sophisticated version"
            ))
        } else if quality == .minor {
            related.append(RelatedChord(
                chord: "\(root)m7",
                relationship: .extended,
                substitutionContext: "Minor 7th - smoother, jazzier version"
            ))
        }

        // Tritone substitution (for dominant 7ths)
        if quality == .dominant7 {
            let tritone = theoryEngine.transposeChord(root, by: 6)
            related.append(RelatedChord(
                chord: "\(tritone)7",
                relationship: .tritoneSubstitution,
                substitutionContext: "Tritone sub - jazz substitution, shares same function"
            ))
        }

        return related
    }

    // MARK: - Common Progressions

    /// Get common progressions that use this chord
    private func getCommonProgressions(for chord: String) -> [String] {
        let root = theoryEngine.extractChordRoot(chord)
        var progressions: [String] = []

        // Common progressions in this key
        if root == "C" {
            progressions.append("C - G - Am - F (I-V-vi-IV)")
            progressions.append("C - Am - F - G (I-vi-IV-V)")
            progressions.append("C - F - G - C (I-IV-V-I)")
        }

        // Generic progressions
        progressions.append("\(root) → \(theoryEngine.transposeChord(root, by: 5)) (I→IV)")
        progressions.append("\(root) → \(theoryEngine.transposeChord(root, by: 7)) (I→V)")

        return progressions
    }

    // MARK: - Helper Methods

    /// Convert ChordQuality to key for formula lookup
    private func qualityToKey(_ quality: ChordQuality) -> String {
        switch quality {
        case .major: return "major"
        case .minor: return "minor"
        case .dominant7: return "dominant7"
        case .major7: return "major7"
        case .minor7: return "minor7"
        case .diminished: return "diminished"
        case .augmented: return "augmented"
        case .suspended: return "sus4"
        case .other: return "major"
        }
    }

    // MARK: - Scale Degrees

    /// Get scale degree information for a chord in a key
    func getScaleDegree(chord: String, in key: String) -> (degree: Int, numeral: String)? {
        let chordRoot = theoryEngine.extractChordRoot(chord)

        guard let keyIndex = chromaticScale.firstIndex(of: key),
              let chordIndex = chromaticScale.firstIndex(of: chordRoot) else {
            return nil
        }

        let degree = (chordIndex - keyIndex + 12) % 12

        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]
        let scaleDegrees = [0, 2, 4, 5, 7, 9, 11]

        if let index = scaleDegrees.firstIndex(of: degree) {
            return (degree: index + 1, numeral: numerals[index])
        }

        return nil
    }

    // MARK: - Chord Learning

    /// Get practice exercises for learning a chord
    func getPracticeExercises(for chord: String) -> [String] {
        var exercises: [String] = []

        let chordInfo = getChordInfo(chord)

        exercises.append("Practice forming \(chord) and listen to its sound")
        exercises.append("Play \(chord) → \(chordInfo.relatedChords.first?.chord ?? "C") back and forth")
        exercises.append("Strum pattern: Down, Down-Up, Up-Down-Up")

        // Progressions to practice
        if let progression = chordInfo.commonProgressions.first {
            exercises.append("Practice this progression: \(progression)")
        }

        return exercises
    }

    /// Get fingering tips (simplified - would need guitar-specific data)
    func getFingeringTips(for chord: String) -> [String] {
        let quality = theoryEngine.getChordQuality(chord)
        var tips: [String] = []

        switch quality {
        case .major:
            tips.append("Form a triangle shape with your fingers")
            tips.append("Press firmly but don't tense up")

        case .minor:
            tips.append("Similar to major, but flatten the 3rd")
            tips.append("Compare side-by-side with the major version")

        case .dominant7:
            tips.append("Like a major chord with one note added")
            tips.append("The 7th adds bluesy flavor")

        default:
            tips.append("Practice slowly, ensuring each note rings clear")
        }

        return tips
    }
}
