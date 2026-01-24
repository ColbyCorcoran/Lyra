//
//  PatternRecognitionEngine.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Detects and converts different chord notation patterns
//
//  Created by Claude AI on 1/24/26.
//

import Foundation

/// Detects and converts between different chord notation patterns
class PatternRecognitionEngine {

    // MARK: - Pattern Detection

    /// Detect the primary chord pattern in text
    func detectPattern(_ text: String) -> ChordPattern {
        let patterns = analyzePatterns(text)

        // Find dominant pattern
        let sorted = patterns.sorted { $0.value > $1.value }
        guard let dominant = sorted.first, dominant.value > 0.3 else {
            return .unknown
        }

        // Check for mixed patterns
        let significantPatterns = sorted.filter { $0.value > 0.2 }
        if significantPatterns.count > 1 {
            return .mixed
        }

        return dominant.key
    }

    /// Analyze all patterns in text
    func analyzePatterns(_ text: String) -> [ChordPattern: Float] {
        var scores: [ChordPattern: Float] = [:]

        scores[.chordOverLyric] = detectChordOverLyric(text)
        scores[.inlineBrackets] = detectInlineBrackets(text)
        scores[.chordPro] = detectChordPro(text)
        scores[.nashville] = detectNashville(text)

        return scores
    }

    // MARK: - Pattern Conversion

    /// Convert to ChordPro format
    func convertToChordPro(_ text: String, from sourcePattern: ChordPattern) -> String {
        switch sourcePattern {
        case .chordOverLyric:
            return convertChordOverLyricToChordPro(text)
        case .inlineBrackets:
            return convertInlineToChordPro(text)
        case .chordPro:
            return text  // Already ChordPro
        case .nashville:
            return text  // Not supported yet
        case .mixed, .unknown:
            return text  // Cannot convert mixed/unknown
        }
    }

    /// Standardize format across song
    func standardizeFormat(_ text: String, targetPattern: ChordPattern) -> String {
        let currentPattern = detectPattern(text)
        return convertToChordPro(text, from: currentPattern)
    }

    // MARK: - Specific Pattern Detection

    private func detectChordOverLyric(_ text: String) -> Float {
        let lines = text.components(separatedBy: .newlines)
        var chordLyricPairs = 0
        var totalLines = 0

        for i in 0..<lines.count - 1 {
            let line = lines[i]
            let nextLine = lines[i + 1]

            if isChordLine(line) && isLyricLine(nextLine) {
                chordLyricPairs += 1
            }

            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                totalLines += 1
            }
        }

        guard totalLines > 0 else { return 0 }
        return Float(chordLyricPairs * 2) / Float(totalLines)
    }

    private func detectInlineBrackets(_ text: String) -> Float {
        let pattern = "\\[[A-G][#b]?(?:maj|min|m|dim|aug|sus)?[0-9]?(?:/[A-G][#b]?)?\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.numberOfMatches(in: text, range: range)

        // Normalize by text length
        let score = Float(matches) / Float(max(text.count / 50, 1))
        return min(score, 1.0)
    }

    private func detectChordPro(_ text: String) -> Float {
        let pattern = "\\{c?:?[A-G][#b]?(?:maj|min|m|dim|aug|sus)?[0-9]?(?:/[A-G][#b]?)?\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.numberOfMatches(in: text, range: range)

        let score = Float(matches) / Float(max(text.count / 50, 1))
        return min(score, 1.0)
    }

    private func detectNashville(_ text: String) -> Float {
        let pattern = "\\b[1-7][mb]?\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.numberOfMatches(in: text, range: range)

        // Nashville numbers are rare, need higher threshold
        let score = Float(matches) / Float(max(text.count / 100, 1))
        return min(score, 1.0)
    }

    // MARK: - Pattern Conversion Implementation

    private func convertChordOverLyricToChordPro(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            if isChordLine(line) && i + 1 < lines.count {
                let chordLine = line
                let lyricLine = lines[i + 1]

                // Convert pair to ChordPro
                let converted = mergeChordAndLyric(chordLine: chordLine, lyricLine: lyricLine)
                result.append(converted)
                i += 2
            } else {
                result.append(line)
                i += 1
            }
        }

        return result.joined(separator: "\n")
    }

    private func convertInlineToChordPro(_ text: String) -> String {
        // Replace [C] with {c:C}
        let pattern = "\\[([A-G][#b]?(?:maj|min|m|dim|aug|sus)?[0-9]?(?:/[A-G][#b]?)?)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }

        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: "{c:$1}"
        )
    }

    private func mergeChordAndLyric(chordLine: String, lyricLine: String) -> String {
        // Extract chord positions
        let chords = extractChordsWithPositions(chordLine)

        // Insert chords into lyric line
        var result = lyricLine
        var offset = 0

        for (chord, position) in chords.sorted(by: { $0.1 < $1.1 }) {
            let chordPro = "{c:\(chord)}"
            let insertPos = min(position + offset, result.count)

            let index = result.index(result.startIndex, offsetBy: insertPos)
            result.insert(contentsOf: chordPro, at: index)
            offset += chordPro.count
        }

        return result
    }

    // MARK: - Helper Methods

    private func isChordLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return false }

        let chordCount = words.filter { isLikelyChord($0) }.count
        return Float(chordCount) / Float(words.count) > 0.7
    }

    private func isLyricLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !isChordLine(line)
    }

    private func isLikelyChord(_ word: String) -> Bool {
        let chordPattern = "^[A-G][#b]?(maj|min|m|dim|aug|sus)?[0-9]?(/[A-G][#b]?)?$"
        guard let regex = try? NSRegularExpression(pattern: chordPattern) else { return false }

        let range = NSRange(word.startIndex..., in: word)
        return regex.firstMatch(in: word, range: range) != nil
    }

    private func extractChordsWithPositions(_ line: String) -> [(String, Int)] {
        var result: [(String, Int)] = []
        var currentWord = ""
        var currentPosition = 0

        for (i, char) in line.enumerated() {
            if char.isWhitespace {
                if !currentWord.isEmpty && isLikelyChord(currentWord) {
                    result.append((currentWord, currentPosition))
                    currentWord = ""
                }
            } else {
                if currentWord.isEmpty {
                    currentPosition = i
                }
                currentWord.append(char)
            }
        }

        if !currentWord.isEmpty && isLikelyChord(currentWord) {
            result.append((currentWord, currentPosition))
        }

        return result
    }
}
