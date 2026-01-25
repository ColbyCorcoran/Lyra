//
//  AutoFormattingEngine.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Cleans up and standardizes song formatting
//
//  Created by Claude AI on 1/24/26.
//

import Foundation

/// Cleans up spacing, alignment, and formatting inconsistencies
class AutoFormattingEngine {

    // MARK: - Public Methods

    /// Perform complete auto-formatting
    func autoFormat(_ text: String, options: FormattingOptions = .standard) -> String {
        var formatted = text

        if options.fixSpacing {
            formatted = cleanupSpacing(formatted)
        }

        if options.removeExtraBlankLines {
            formatted = removeExtraBlankLines(formatted)
        }

        if options.alignChords {
            formatted = alignChords(formatted)
        }

        return formatted
    }

    /// Clean up spacing inconsistencies
    func cleanupSpacing(_ text: String) -> String {
        var lines = text.components(separatedBy: .newlines)

        // Remove trailing whitespace
        lines = lines.map { $0.trimmingTrailingWhitespace() }

        // Standardize indentation (convert tabs to spaces)
        lines = lines.map { $0.replacingOccurrences(of: "\t", with: "    ") }

        return lines.joined(separator: "\n")
    }

    /// Remove extra blank lines (max 1 blank line between sections)
    func removeExtraBlankLines(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var consecutiveBlank = 0

        for line in lines {
            let isBlank = line.trimmingCharacters(in: .whitespaces).isEmpty

            if isBlank {
                consecutiveBlank += 1
                if consecutiveBlank <= 1 {
                    result.append(line)
                }
            } else {
                consecutiveBlank = 0
                result.append(line)
            }
        }

        // Remove leading/trailing blank lines
        while result.first?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeFirst()
        }

        while result.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeLast()
        }

        return result.joined(separator: "\n")
    }

    /// Align chords properly above lyrics
    func alignChords(_ text: String, pattern: ChordPattern = .chordOverLyric) -> String {
        guard pattern == .chordOverLyric else { return text }

        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Check if this is a chord line
            if isChordLine(line) && i + 1 < lines.count {
                let nextLine = lines[i + 1]

                // Align chords with lyrics
                let aligned = alignChordLine(chordLine: line, lyricLine: nextLine)
                result.append(aligned)
                result.append(nextLine)
                i += 2
            } else {
                result.append(line)
                i += 1
            }
        }

        return result.joined(separator: "\n")
    }

    /// Normalize line endings
    func normalizeLineEndings(_ text: String) -> String {
        // Convert all line endings to \n
        return text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    /// Optimize line lengths (wrap long lines)
    func optimizeLineLength(_ text: String, maxLength: Int = 80) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []

        for line in lines {
            if line.count <= maxLength {
                result.append(line)
            } else {
                // Wrap long line
                let wrapped = wrapLine(line, maxLength: maxLength)
                result.append(contentsOf: wrapped)
            }
        }

        return result.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Check if line contains only chords
    private func isChordLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return false }

        let chordCount = words.filter { isLikelyChord($0) }.count
        return Float(chordCount) / Float(words.count) > 0.7
    }

    /// Check if word is likely a chord
    private func isLikelyChord(_ word: String) -> Bool {
        let chordPattern = "^[A-G][#b]?(maj|min|m|dim|aug|sus)?[0-9]?(/[A-G][#b]?)?$"
        guard let regex = try? NSRegularExpression(pattern: chordPattern) else { return false }

        let range = NSRange(word.startIndex..., in: word)
        return regex.firstMatch(in: word, range: range) != nil
    }

    /// Align chord line with lyric line below
    private func alignChordLine(chordLine: String, lyricLine: String) -> String {
        // Extract chord positions
        let chords = extractChordsWithPositions(chordLine)

        // Rebuild chord line with proper spacing
        let result = String(repeating: " ", count: max(chordLine.count, lyricLine.count))
        var resultArray = Array(result)

        for (chord, position) in chords {
            guard position < resultArray.count else { continue }

            // Place chord at position
            for (i, char) in chord.enumerated() {
                let index = position + i
                if index < resultArray.count {
                    resultArray[index] = char
                }
            }
        }

        return String(resultArray).trimmingTrailingWhitespace()
    }

    /// Extract chords with their positions
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

        // Add last word
        if !currentWord.isEmpty && isLikelyChord(currentWord) {
            result.append((currentWord, currentPosition))
        }

        return result
    }

    /// Wrap long line into multiple lines
    private func wrapLine(_ line: String, maxLength: Int) -> [String] {
        var result: [String] = []
        var currentLine = ""

        let words = line.components(separatedBy: .whitespaces)

        for word in words {
            if (currentLine + " " + word).count <= maxLength {
                currentLine += (currentLine.isEmpty ? "" : " ") + word
            } else {
                if !currentLine.isEmpty {
                    result.append(currentLine)
                }
                currentLine = word
            }
        }

        if !currentLine.isEmpty {
            result.append(currentLine)
        }

        return result.isEmpty ? [line] : result
    }
}

// MARK: - String Extension

private extension String {
    func trimmingTrailingWhitespace() -> String {
        guard let range = self.range(of: "\\s+$", options: .regularExpression) else {
            return self
        }
        return self.replacingCharacters(in: range, with: "")
    }
}
