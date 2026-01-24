//
//  ChordExtractionEngine.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Extracts and processes chords from messy text
//
//  Created by Claude AI on 1/24/26.
//

import Foundation

/// Extracts chords from text and validates/normalizes chord syntax
class ChordExtractionEngine {

    // MARK: - Chord Patterns

    private let chordPattern = "\\b[A-G][#b♯♭]?(maj|min|m|dim|aug|sus|add)?[0-9]?([b#♯♭][0-9])?(/[A-G][#b♯♭]?)?\\b"

    private let enharmonicMap: [String: String] = [
        "C#": "Db", "D#": "Eb", "F#": "Gb", "G#": "Ab", "A#": "Bb",
        "Db": "C#", "Eb": "D#", "Gb": "F#", "Ab": "G#", "Bb": "A#"
    ]

    // MARK: - Public Methods

    /// Extract all chords from text
    func extractChords(_ text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: chordPattern, options: [.caseInsensitive]) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }.filter { isValidChord($0) }
    }

    /// Extract unique chords
    func getUniqueChords(_ text: String) -> [String] {
        let chords = extractChords(text)
        var uniqueChords: [String] = []
        var seen = Set<String>()

        for chord in chords {
            let normalized = normalizeChord(chord)
            if !seen.contains(normalized) {
                uniqueChords.append(normalized)
                seen.insert(normalized)
            }
        }

        return uniqueChords
    }

    /// Separate chords from lyrics
    func separateChordsAndLyrics(_ text: String) -> (chords: [String], lyrics: String) {
        let lines = text.components(separatedBy: .newlines)
        var chords: [String] = []
        var lyricLines: [String] = []

        for line in lines {
            if isChordLine(line) {
                // Extract chords from chord line
                chords.append(contentsOf: extractChords(line))
            } else {
                // Extract chords from inline notation
                let lineChords = extractChords(line)
                chords.append(contentsOf: lineChords)

                // Remove chords from lyric line
                let cleanedLine = removeChords(line)
                if !cleanedLine.isEmpty {
                    lyricLines.append(cleanedLine)
                }
            }
        }

        return (chords, lyricLines.joined(separator: "\n"))
    }

    /// Normalize chord notation
    func normalizeChord(_ chord: String) -> String {
        var normalized = chord.trimmingCharacters(in: .whitespaces)

        // Replace unicode sharp/flat symbols
        normalized = normalized.replacingOccurrences(of: "♯", with: "#")
        normalized = normalized.replacingOccurrences(of: "♭", with: "b")

        // Standardize quality notation
        normalized = normalized.replacingOccurrences(of: "min", with: "m")
        normalized = normalized.replacingOccurrences(of: "minor", with: "m")
        normalized = normalized.replacingOccurrences(of: "major", with: "maj")

        return normalized
    }

    /// Validate chord syntax
    func isValidChord(_ chord: String) -> Bool {
        let validPattern = "^[A-G][#b♯♭]?(maj|min|m|dim|aug|sus|add)?[0-9]?([b#♯♭][0-9])?(/[A-G][#b♯♭]?)?$"
        guard let regex = try? NSRegularExpression(pattern: validPattern, options: [.caseInsensitive]) else {
            return false
        }

        let range = NSRange(chord.startIndex..., in: chord)
        return regex.firstMatch(in: chord, range: range) != nil
    }

    /// Fix common chord syntax errors
    func fixChordSyntax(_ chord: String) -> String {
        var fixed = chord

        // Common typos
        fixed = fixed.replacingOccurrences(of: "sharp", with: "#")
        fixed = fixed.replacingOccurrences(of: "flat", with: "b")
        fixed = fixed.replacingOccurrences(of: "Csharp", with: "C#")
        fixed = fixed.replacingOccurrences(of: "Dflat", with: "Db")

        return normalizeChord(fixed)
    }

    /// Choose enharmonic spelling based on key
    func chooseEnharmonic(_ chord: String, key: String) -> String {
        let root = extractRoot(chord)
        let quality = extractQuality(chord)

        // Simple heuristic: sharp keys use sharps, flat keys use flats
        let keyUsesFlats = ["F", "Bb", "Eb", "Ab", "Db", "Gb", "Cb"].contains(key)

        var enharmonicRoot = root
        if let alternate = enharmonicMap[root] {
            if keyUsesFlats && root.contains("#") {
                enharmonicRoot = alternate
            } else if !keyUsesFlats && root.contains("b") {
                enharmonicRoot = alternate
            }
        }

        return enharmonicRoot + quality
    }

    // MARK: - Private Helpers

    private func isChordLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return false }

        let chordCount = words.filter { isValidChord($0) }.count
        return Float(chordCount) / Float(words.count) > 0.7
    }

    private func removeChords(_ line: String) -> String {
        var cleaned = line

        // Remove inline bracket chords [C]
        cleaned = cleaned.replacingOccurrences(
            of: "\\[[A-G][#b♯♭]?(?:maj|min|m|dim|aug|sus|add)?[0-9]?(?:/[A-G][#b♯♭]?)?\\]",
            with: "",
            options: .regularExpression
        )

        // Remove ChordPro chords {c:C}
        cleaned = cleaned.replacingOccurrences(
            of: "\\{c?:?[A-G][#b♯♭]?(?:maj|min|m|dim|aug|sus|add)?[0-9]?(?:/[A-G][#b♯♭]?)?\\}",
            with: "",
            options: .regularExpression
        )

        // Clean up extra spaces
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private func extractRoot(_ chord: String) -> String {
        let rootPattern = "^[A-G][#b♯♭]?"
        guard let regex = try? NSRegularExpression(pattern: rootPattern) else {
            return chord
        }

        let range = NSRange(chord.startIndex..., in: chord)
        if let match = regex.firstMatch(in: chord, range: range),
           let matchRange = Range(match.range, in: chord) {
            return String(chord[matchRange])
        }

        return chord
    }

    private func extractQuality(_ chord: String) -> String {
        let root = extractRoot(chord)
        return String(chord.dropFirst(root.count))
    }
}
