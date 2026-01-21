//
//  TransposeEngine.swift
//  Lyra
//
//  Chord transposition engine with enharmonic logic
//

import Foundation

class TransposeEngine {
    // MARK: - Note System

    /// All 12 chromatic notes in sharp notation
    private static let chromaticSharp = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// All 12 chromatic notes in flat notation
    private static let chromaticFlat = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

    /// Keys that prefer sharps
    private static let sharpKeys: Set<String> = ["G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#"]

    /// Keys that prefer flats
    private static let flatKeys: Set<String> = ["F", "Bb", "Eb", "Ab", "Db", "Gb", "Cb"]

    /// Enharmonic equivalents mapping
    private static let enharmonicMap: [String: String] = [
        "C#": "Db", "Db": "C#",
        "D#": "Eb", "Eb": "D#",
        "F#": "Gb", "Gb": "F#",
        "G#": "Ab", "Ab": "G#",
        "A#": "Bb", "Bb": "A#"
    ]

    // MARK: - Transposition

    /// Transpose a chord by semitones
    /// - Parameters:
    ///   - chord: Original chord symbol (e.g., "Cmaj7", "Am7", "D/F#")
    ///   - semitones: Number of semitones to transpose (-11 to 11)
    ///   - preferSharps: Whether to use sharps over flats for enharmonic notes
    /// - Returns: Transposed chord symbol
    static func transpose(_ chord: String, by semitones: Int, preferSharps: Bool = true) -> String {
        guard !chord.isEmpty else { return chord }

        // Parse chord into components
        guard let components = parseChord(chord) else {
            return chord // Return original if can't parse
        }

        // Transpose root note
        let transposedRoot = transposeNote(components.root, by: semitones, preferSharps: preferSharps)

        // Transpose bass note if present
        let transposedBass = components.bass.map {
            transposeNote($0, by: semitones, preferSharps: preferSharps)
        }

        // Reconstruct chord
        var result = transposedRoot + components.quality

        if let bass = transposedBass {
            result += "/" + bass
        }

        return result
    }

    /// Transpose a single note by semitones
    private static func transposeNote(_ note: String, by semitones: Int, preferSharps: Bool) -> String {
        // Normalize semitones to 0-11 range
        let normalizedSemitones = ((semitones % 12) + 12) % 12

        // Find current note index
        let noteScale = preferSharps ? chromaticSharp : chromaticFlat
        guard let currentIndex = noteScale.firstIndex(of: normalizeNote(note, preferSharps: preferSharps)) else {
            return note // Return original if not found
        }

        // Calculate new index
        let newIndex = (currentIndex + normalizedSemitones) % 12

        return noteScale[newIndex]
    }

    /// Normalize a note to the preferred enharmonic spelling
    private static func normalizeNote(_ note: String, preferSharps: Bool) -> String {
        let noteScale = preferSharps ? chromaticSharp : chromaticFlat

        // If note is already in the scale, return it
        if noteScale.contains(note) {
            return note
        }

        // Check if it's an enharmonic equivalent
        if let equivalent = enharmonicMap[note] {
            return equivalent
        }

        return note
    }

    // MARK: - Chord Parsing

    struct ChordComponents {
        let root: String       // Root note (C, C#, Db, etc.)
        let quality: String    // Everything after root (m7, maj7, sus4, etc.)
        let bass: String?      // Bass note for slash chords (optional)
    }

    /// Parse a chord symbol into components
    private static func parseChord(_ chord: String) -> ChordComponents? {
        guard !chord.isEmpty else { return nil }

        var remaining = chord

        // Extract root note (first 1-2 characters)
        var root = String(remaining.prefix(1))
        remaining = String(remaining.dropFirst())

        // Check for sharp or flat
        if let firstChar = remaining.first, (firstChar == "#" || firstChar == "b") {
            root += String(firstChar)
            remaining = String(remaining.dropFirst())
        }

        // Check for slash chord (bass note)
        var bass: String? = nil
        if let slashIndex = remaining.firstIndex(of: "/") {
            let bassString = String(remaining[remaining.index(after: slashIndex)...])
            bass = parseBassNote(bassString)
            remaining = String(remaining[..<slashIndex])
        }

        // Everything else is the quality
        let quality = remaining

        return ChordComponents(root: root, quality: quality, bass: bass)
    }

    /// Parse bass note from slash chord notation
    private static func parseBassNote(_ bassString: String) -> String? {
        guard !bassString.isEmpty else { return nil }

        var bass = String(bassString.prefix(1))
        let remaining = String(bassString.dropFirst())

        // Check for sharp or flat
        if let firstChar = remaining.first, (firstChar == "#" || firstChar == "b") {
            bass += String(firstChar)
        }

        return bass
    }

    // MARK: - Key Detection

    /// Determine if a key prefers sharps or flats
    static func prefersSharps(key: String?) -> Bool {
        guard let key = key else { return true }

        // Extract just the note name (remove 'm' for minor keys)
        let cleanKey = key.replacingOccurrences(of: "m", with: "")

        if sharpKeys.contains(cleanKey) {
            return true
        } else if flatKeys.contains(cleanKey) {
            return false
        }

        // Default to sharps for C major or unknown keys
        return true
    }

    // MARK: - Semitone Calculation

    /// Calculate semitones between two keys
    static func semitonesBetween(from: String?, to: String?) -> Int {
        guard let fromKey = from, let toKey = to else { return 0 }

        // Use sharp notation for calculation
        guard let fromIndex = chromaticSharp.firstIndex(of: normalizeNote(fromKey, preferSharps: true)),
              let toIndex = chromaticSharp.firstIndex(of: normalizeNote(toKey, preferSharps: true)) else {
            return 0
        }

        var diff = toIndex - fromIndex

        // Normalize to shortest path (-5 to 6)
        if diff > 6 {
            diff -= 12
        } else if diff < -5 {
            diff += 12
        }

        return diff
    }

    // MARK: - Song Transposition

    /// Transpose all chords in song content
    /// - Parameters:
    ///   - content: Original ChordPro/OnSong content
    ///   - semitones: Number of semitones to transpose
    ///   - preferSharps: Whether to use sharps over flats
    /// - Returns: Transposed content
    static func transposeContent(_ content: String, by semitones: Int, preferSharps: Bool = true) -> String {
        guard semitones != 0 else { return content }

        var result = content

        // Pattern to match ChordPro inline chords: [ChordName]
        let chordProPattern = "\\[([A-G][#b]?(?:m|maj|min|dim|aug|sus)?[0-9]?(?:[#b]?[0-9])?(?:/[A-G][#b]?)?)\\]"

        if let regex = try? NSRegularExpression(pattern: chordProPattern, options: []) {
            let nsString = content as NSString
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

            // Process matches in reverse to maintain string indices
            for match in matches.reversed() {
                if match.numberOfRanges >= 2 {
                    let chordRange = match.range(at: 1)
                    let originalChord = nsString.substring(with: chordRange)
                    let transposedChord = transpose(originalChord, by: semitones, preferSharps: preferSharps)

                    // Replace in result
                    let fullRange = match.range(at: 0)
                    let replacement = "[\(transposedChord)]"
                    result = (result as NSString).replacingCharacters(in: fullRange, with: replacement)
                }
            }
        }

        return result
    }

    // MARK: - Capo Calculation

    /// Calculate capo position for transposition
    /// - Parameters:
    ///   - semitones: Number of semitones transposed
    /// - Returns: Suggested capo position (0-11)
    static func calculateCapo(for semitones: Int) -> Int {
        // If transposing down, suggest capo to play original chords
        if semitones < 0 {
            return (12 + semitones) % 12
        }
        return 0
    }

    // MARK: - Common Intervals

    enum TransposeInterval: String, CaseIterable {
        case halfStepUp = "Half Step Up"
        case halfStepDown = "Half Step Down"
        case wholeStepUp = "Whole Step Up"
        case wholeStepDown = "Whole Step Down"
        case minorThirdUp = "Minor 3rd Up"
        case minorThirdDown = "Minor 3rd Down"
        case majorThirdUp = "Major 3rd Up"
        case majorThirdDown = "Major 3rd Down"
        case fourthUp = "4th Up"
        case fourthDown = "4th Down"
        case fifthUp = "5th Up"
        case fifthDown = "5th Down"

        var semitones: Int {
            switch self {
            case .halfStepUp: return 1
            case .halfStepDown: return -1
            case .wholeStepUp: return 2
            case .wholeStepDown: return -2
            case .minorThirdUp: return 3
            case .minorThirdDown: return -3
            case .majorThirdUp: return 4
            case .majorThirdDown: return -4
            case .fourthUp: return 5
            case .fourthDown: return -5
            case .fifthUp: return 7
            case .fifthDown: return -7
            }
        }
    }

    // MARK: - Chord Analysis

    /// Extract all unique chords from content
    static func extractChords(from content: String) -> [String] {
        var chords: [String] = []

        // Pattern to match ChordPro inline chords: [ChordName]
        let chordProPattern = "\\[([A-G][#b]?(?:m|maj|min|dim|aug|sus)?[0-9]?(?:[#b]?[0-9])?(?:/[A-G][#b]?)?)\\]"

        if let regex = try? NSRegularExpression(pattern: chordProPattern, options: []) {
            let nsString = content as NSString
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                if match.numberOfRanges >= 2 {
                    let chordRange = match.range(at: 1)
                    let chord = nsString.substring(with: chordRange)
                    if !chords.contains(chord) {
                        chords.append(chord)
                    }
                }
            }
        }

        return chords
    }

    /// Preview transposition by showing original and transposed chords
    static func previewTransposition(
        content: String,
        semitones: Int,
        preferSharps: Bool = true
    ) -> [(original: String, transposed: String)] {
        let chords = extractChords(from: content)
        return chords.map { chord in
            (original: chord, transposed: transpose(chord, by: semitones, preferSharps: preferSharps))
        }
    }
}

// MARK: - Key Model

struct MusicalKey: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let prefersSharps: Bool

    static let allKeys: [MusicalKey] = [
        MusicalKey(name: "C", prefersSharps: true),
        MusicalKey(name: "C#", prefersSharps: true),
        MusicalKey(name: "Db", prefersSharps: false),
        MusicalKey(name: "D", prefersSharps: true),
        MusicalKey(name: "D#", prefersSharps: true),
        MusicalKey(name: "Eb", prefersSharps: false),
        MusicalKey(name: "E", prefersSharps: true),
        MusicalKey(name: "F", prefersSharps: false),
        MusicalKey(name: "F#", prefersSharps: true),
        MusicalKey(name: "Gb", prefersSharps: false),
        MusicalKey(name: "G", prefersSharps: true),
        MusicalKey(name: "G#", prefersSharps: true),
        MusicalKey(name: "Ab", prefersSharps: false),
        MusicalKey(name: "A", prefersSharps: true),
        MusicalKey(name: "A#", prefersSharps: true),
        MusicalKey(name: "Bb", prefersSharps: false),
        MusicalKey(name: "B", prefersSharps: true)
    ]

    static let commonKeys: [MusicalKey] = [
        MusicalKey(name: "C", prefersSharps: true),
        MusicalKey(name: "Db", prefersSharps: false),
        MusicalKey(name: "D", prefersSharps: true),
        MusicalKey(name: "Eb", prefersSharps: false),
        MusicalKey(name: "E", prefersSharps: true),
        MusicalKey(name: "F", prefersSharps: false),
        MusicalKey(name: "Gb", prefersSharps: false),
        MusicalKey(name: "G", prefersSharps: true),
        MusicalKey(name: "Ab", prefersSharps: false),
        MusicalKey(name: "A", prefersSharps: true),
        MusicalKey(name: "Bb", prefersSharps: false),
        MusicalKey(name: "B", prefersSharps: true)
    ]
}
