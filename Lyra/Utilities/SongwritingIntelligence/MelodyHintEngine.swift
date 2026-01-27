//
//  MelodyHintEngine.swift
//  Lyra
//
//  Phase 7.14: AI Songwriting Assistance - Melody Intelligence
//  On-device melody pattern generation based on chord progressions
//

import Foundation
import AVFoundation

/// Engine for suggesting melodic patterns based on chord progressions
/// Uses music theory rules and scale relationships (100% on-device)
@MainActor
class MelodyHintEngine {

    // MARK: - Shared Instance
    static let shared = MelodyHintEngine()

    // MARK: - Music Theory Data

    private let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// Scale intervals (in semitones from root)
    private let scaleIntervals: [String: [Int]] = [
        "major": [0, 2, 4, 5, 7, 9, 11],
        "minor": [0, 2, 3, 5, 7, 8, 10],
        "pentatonic_major": [0, 2, 4, 7, 9],
        "pentatonic_minor": [0, 3, 5, 7, 10],
        "blues": [0, 3, 5, 6, 7, 10]
    ]

    /// Common melodic patterns (intervals)
    private let melodicPatterns: [String: [[Int]]] = [
        "stepwise_up": [[0, 2, 4, 5], [0, 2, 4, 7]],
        "stepwise_down": [[7, 5, 4, 2], [7, 5, 4, 0]],
        "arpeggio_up": [[0, 4, 7, 12], [0, 4, 7, 11]],
        "arpeggio_down": [[12, 7, 4, 0], [11, 7, 4, 0]],
        "neighbor": [[0, 2, 0, -2], [0, -2, 0, 2]],
        "leap": [[0, 7, 5, 4], [0, 5, 7, 12]]
    ]

    // MARK: - Melody Generation

    /// Generate melodic hints based on a chord
    func suggestMelody(
        for chord: String,
        in key: String,
        style: MelodyStyle = .stepwise,
        length: Int = 8
    ) -> MelodyHint {

        // Get scale notes for the key
        let scaleType = style.scaleType
        let scaleNotes = getScaleNotes(root: key, scaleType: scaleType)

        // Get chord tones
        let chordTones = getChordTones(for: chord)

        // Generate melody pattern
        let pattern = generatePattern(
            scaleNotes: scaleNotes,
            chordTones: chordTones,
            style: style,
            length: length
        )

        // Convert to note names
        let noteNames = pattern.map { getNoteNameFromMIDI($0) }

        // Generate singability score
        let singabilityScore = calculateSingability(pattern)

        return MelodyHint(
            notes: noteNames,
            midiNotes: pattern,
            chordTones: chordTones,
            scaleType: scaleType,
            style: style,
            singabilityScore: singabilityScore,
            contour: analyzeContour(pattern),
            range: getNoteRange(pattern)
        )
    }

    /// Generate multiple melodic variations
    func suggestMelodyVariations(
        for chord: String,
        in key: String,
        count: Int = 3
    ) -> [MelodyHint] {

        let styles: [MelodyStyle] = [.stepwise, .arpeggio, .pentatonic, .mixed]

        var variations: [MelodyHint] = []

        for style in styles.prefix(count) {
            let hint = suggestMelody(for: chord, in: key, style: style, length: 8)
            variations.append(hint)
        }

        return variations
    }

    /// Suggest next melodic phrase based on previous pattern
    func continuemelody(
        from previousNotes: [String],
        in key: String,
        currentChord: String
    ) -> MelodyHint {

        // Analyze previous pattern
        let previousMIDI = previousNotes.compactMap { noteNameToMIDI($0) }

        guard !previousMIDI.isEmpty else {
            return suggestMelody(for: currentChord, in: key, length: 4)
        }

        // Determine continuation strategy
        let lastNote = previousMIDI.last!
        let contour = analyzeContour(previousMIDI)

        // Generate continuation
        let scaleNotes = getScaleNotes(root: key, scaleType: "major")
        let chordTones = getChordTones(for: currentChord)

        var continuationPattern: [Int] = []

        // Create answering phrase (opposite contour)
        if contour == "ascending" {
            // Answer with descending
            continuationPattern = generateDescendingPhrase(from: lastNote, scaleNotes: scaleNotes, length: 4)
        } else if contour == "descending" {
            // Answer with ascending
            continuationPattern = generateAscendingPhrase(from: lastNote, scaleNotes: scaleNotes, length: 4)
        } else {
            // Answer with wave pattern
            continuationPattern = generateWavePhrase(from: lastNote, scaleNotes: scaleNotes, length: 4)
        }

        let noteNames = continuationPattern.map { getNoteNameFromMIDI($0) }

        return MelodyHint(
            notes: noteNames,
            midiNotes: continuationPattern,
            chordTones: chordTones,
            scaleType: "major",
            style: .stepwise,
            singabilityScore: calculateSingability(continuationPattern),
            contour: analyzeContour(continuationPattern),
            range: getNoteRange(continuationPattern)
        )
    }

    /// Generate a singable hook melody
    func generateHook(
        in key: String,
        over chord: String,
        style: String = "catchy"
    ) -> MelodyHint {

        // Hooks are typically 4 bars, repetitive, stepwise, narrow range
        let scaleNotes = getScaleNotes(root: key, scaleType: "pentatonic_major")
        let chordTones = getChordTones(for: chord)

        // Create catchy pattern (repetition + variation)
        var hookPattern: [Int] = []

        let rootMIDI = noteNameToMIDI(key) ?? 60

        // Phrase 1: Simple ascending
        hookPattern.append(contentsOf: [rootMIDI, rootMIDI + 2, rootMIDI + 4, rootMIDI + 2])

        // Phrase 2: Repeat with variation
        hookPattern.append(contentsOf: [rootMIDI, rootMIDI + 2, rootMIDI + 4, rootMIDI + 5])

        let noteNames = hookPattern.map { getNoteNameFromMIDI($0) }

        return MelodyHint(
            notes: noteNames,
            midiNotes: hookPattern,
            chordTones: chordTones,
            scaleType: "pentatonic_major",
            style: .hook,
            singabilityScore: 0.95,
            contour: "wave",
            range: MelodyRange(lowest: noteNames.first!, highest: noteNames.max()!, semitones: 5)
        )
    }

    // MARK: - Helper Methods

    private func getScaleNotes(root: String, scaleType: String) -> [Int] {
        guard let rootIndex = chromaticScale.firstIndex(of: root.uppercased()) else {
            return [60, 62, 64, 65, 67, 69, 71] // Default C major
        }

        let intervals = scaleIntervals[scaleType] ?? scaleIntervals["major"]!
        let rootMIDI = 60 + rootIndex // Middle C octave

        return intervals.map { rootMIDI + $0 }
    }

    private func getChordTones(for chord: String) -> [String] {
        // Parse chord and return constituent notes
        let root = String(chord.prefix(chord.contains("#") || chord.contains("b") ? 2 : 1))

        guard let rootIndex = chromaticScale.firstIndex(where: { $0 == root.uppercased() }) else {
            return [root]
        }

        let rootMIDI = 60 + rootIndex

        // Determine chord type
        let isMinor = chord.contains("m") && !chord.contains("maj")
        let isDim = chord.contains("dim")
        let is7th = chord.contains("7")

        var tones: [Int] = [rootMIDI]

        if isDim {
            tones.append(contentsOf: [rootMIDI + 3, rootMIDI + 6])
        } else if isMinor {
            tones.append(contentsOf: [rootMIDI + 3, rootMIDI + 7])
        } else {
            tones.append(contentsOf: [rootMIDI + 4, rootMIDI + 7])
        }

        if is7th {
            tones.append(rootMIDI + (isMinor ? 10 : 11))
        }

        return tones.map { getNoteNameFromMIDI($0) }
    }

    private func generatePattern(
        scaleNotes: [Int],
        chordTones: [String],
        style: MelodyStyle,
        length: Int
    ) -> [Int] {

        var pattern: [Int] = []

        switch style {
        case .stepwise:
            // Stepwise motion within scale
            var currentIndex = 0
            for _ in 0..<length {
                pattern.append(scaleNotes[currentIndex % scaleNotes.count])
                currentIndex += [-1, 1, 1, 2].randomElement()!
                currentIndex = max(0, min(currentIndex, scaleNotes.count - 1))
            }

        case .arpeggio:
            // Arpeggiate chord tones
            let chordMIDI = chordTones.compactMap { noteNameToMIDI($0) }
            for i in 0..<length {
                pattern.append(chordMIDI[i % chordMIDI.count])
            }

        case .pentatonic:
            // Pentatonic scale motion
            let pentatonicNotes = scaleNotes.enumerated().filter { [0, 2, 4, 7, 9].contains($0.offset % 12) }.map { $0.element }
            for i in 0..<length {
                pattern.append(pentatonicNotes[i % pentatonicNotes.count])
            }

        case .mixed:
            // Mix of chord tones and passing tones
            let chordMIDI = chordTones.compactMap { noteNameToMIDI($0) }
            for i in 0..<length {
                if i % 2 == 0 {
                    pattern.append(chordMIDI[i / 2 % chordMIDI.count])
                } else {
                    pattern.append(scaleNotes[i % scaleNotes.count])
                }
            }

        case .hook:
            // Catchy, repetitive pattern
            let rootNote = scaleNotes[0]
            pattern = [rootNote, rootNote + 2, rootNote + 4, rootNote + 2,
                      rootNote, rootNote + 2, rootNote + 4, rootNote + 5]
        }

        return Array(pattern.prefix(length))
    }

    private func generateAscendingPhrase(from startNote: Int, scaleNotes: [Int], length: Int) -> [Int] {
        var phrase: [Int] = []
        var currentNote = startNote

        for _ in 0..<length {
            // Find next higher scale note
            if let nextNote = scaleNotes.first(where: { $0 > currentNote }) {
                phrase.append(nextNote)
                currentNote = nextNote
            } else {
                // Wrap to next octave
                if let firstNote = scaleNotes.first {
                    currentNote = firstNote + 12
                    phrase.append(currentNote)
                }
            }
        }

        return phrase
    }

    private func generateDescendingPhrase(from startNote: Int, scaleNotes: [Int], length: Int) -> [Int] {
        var phrase: [Int] = []
        var currentNote = startNote

        for _ in 0..<length {
            // Find next lower scale note
            if let nextNote = scaleNotes.last(where: { $0 < currentNote }) {
                phrase.append(nextNote)
                currentNote = nextNote
            } else {
                // Wrap to previous octave
                if let lastNote = scaleNotes.last {
                    currentNote = lastNote - 12
                    phrase.append(currentNote)
                }
            }
        }

        return phrase
    }

    private func generateWavePhrase(from startNote: Int, scaleNotes: [Int], length: Int) -> [Int] {
        var phrase: [Int] = [startNote]
        var goingUp = true

        for _ in 1..<length {
            let lastNote = phrase.last!

            if goingUp {
                if let nextNote = scaleNotes.first(where: { $0 > lastNote }) {
                    phrase.append(nextNote)
                } else {
                    goingUp = false
                    if let nextNote = scaleNotes.last(where: { $0 < lastNote }) {
                        phrase.append(nextNote)
                    }
                }
            } else {
                if let nextNote = scaleNotes.last(where: { $0 < lastNote }) {
                    phrase.append(nextNote)
                } else {
                    goingUp = true
                    if let nextNote = scaleNotes.first(where: { $0 > lastNote }) {
                        phrase.append(nextNote)
                    }
                }
            }
        }

        return phrase
    }

    private func calculateSingability(_ midiNotes: [Int]) -> Double {
        guard midiNotes.count > 1 else { return 1.0 }

        var score = 1.0

        // Check range (penalize if too wide)
        let range = (midiNotes.max() ?? 0) - (midiNotes.min() ?? 0)
        if range > 12 {
            score -= 0.2
        }

        // Check for large leaps (penalize)
        for i in 1..<midiNotes.count {
            let interval = abs(midiNotes[i] - midiNotes[i-1])
            if interval > 5 {
                score -= 0.1
            }
        }

        // Reward stepwise motion
        let stepwiseCount = zip(midiNotes, midiNotes.dropFirst()).filter { abs($1 - $0) <= 2 }.count
        let stepwiseRatio = Double(stepwiseCount) / Double(midiNotes.count - 1)
        score += stepwiseRatio * 0.3

        return max(0, min(1.0, score))
    }

    private func analyzeContour(_ midiNotes: [Int]) -> String {
        guard midiNotes.count > 1 else { return "static" }

        let firstNote = midiNotes.first!
        let lastNote = midiNotes.last!

        if lastNote > firstNote + 2 {
            return "ascending"
        } else if lastNote < firstNote - 2 {
            return "descending"
        } else {
            return "wave"
        }
    }

    private func getNoteRange(_ midiNotes: [Int]) -> MelodyRange {
        guard let min = midiNotes.min(), let max = midiNotes.max() else {
            return MelodyRange(lowest: "C4", highest: "C4", semitones: 0)
        }

        return MelodyRange(
            lowest: getNoteNameFromMIDI(min),
            highest: getNoteNameFromMIDI(max),
            semitones: max - min
        )
    }

    private func noteNameToMIDI(_ noteName: String) -> Int? {
        let note = String(noteName.prefix(noteName.contains("#") || noteName.contains("b") ? 2 : 1))
        let octaveStr = noteName.dropFirst(note.count)
        let octave = Int(octaveStr) ?? 4

        guard let noteIndex = chromaticScale.firstIndex(of: note.uppercased()) else {
            return nil
        }

        return (octave + 1) * 12 + noteIndex
    }

    private func getNoteNameFromMIDI(_ midi: Int) -> String {
        let octave = (midi / 12) - 1
        let noteIndex = midi % 12
        let noteName = chromaticScale[noteIndex]

        return "\(noteName)\(octave)"
    }
}

// MARK: - Data Models

enum MelodyStyle: String, Codable, CaseIterable {
    case stepwise = "Stepwise Motion"
    case arpeggio = "Arpeggiated"
    case pentatonic = "Pentatonic"
    case mixed = "Mixed"
    case hook = "Catchy Hook"

    var scaleType: String {
        switch self {
        case .pentatonic, .hook:
            return "pentatonic_major"
        default:
            return "major"
        }
    }
}

struct MelodyHint: Identifiable, Codable {
    let id: UUID = UUID()
    let notes: [String]
    let midiNotes: [Int]
    let chordTones: [String]
    let scaleType: String
    let style: MelodyStyle
    let singabilityScore: Double
    let contour: String
    let range: MelodyRange
}

struct MelodyRange: Codable {
    let lowest: String
    let highest: String
    let semitones: Int
}
