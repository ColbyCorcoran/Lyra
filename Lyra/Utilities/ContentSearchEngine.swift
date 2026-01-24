//
//  ContentSearchEngine.swift
//  Lyra
//
//  Search engine for song content (lyrics, chords, chord progressions)
//  Part of Phase 7.4: Search Intelligence
//

import Foundation

/// Engine for searching within song lyrics and chord content
class ContentSearchEngine {

    // MARK: - Properties

    private let fuzzyEngine = FuzzyMatchingEngine()
    private let maxSnippetLength = 150

    // MARK: - Lyrics Search

    /// Search for text within song lyrics
    func searchLyrics(
        _ query: String,
        in lyrics: String,
        fuzzyMatch: Bool = true
    ) -> [LyricsMatch] {
        var matches: [LyricsMatch] = []

        let lines = lyrics.components(separatedBy: .newlines)
        let queryLowercased = query.lowercased()

        for (lineIndex, line) in lines.enumerated() {
            let lineLowercased = line.lowercased()

            // Exact match
            if let range = lineLowercased.range(of: queryLowercased) {
                let match = LyricsMatch(
                    lineNumber: lineIndex + 1,
                    lineText: line,
                    matchRange: range,
                    matchType: .exact,
                    relevance: 1.0,
                    context: getContext(lines: lines, lineIndex: lineIndex)
                )
                matches.append(match)
                continue
            }

            // Fuzzy match if enabled
            if fuzzyMatch {
                let score = fuzzyEngine.fuzzyMatch(query, line)
                if score > 0.7 {
                    let match = LyricsMatch(
                        lineNumber: lineIndex + 1,
                        lineText: line,
                        matchRange: nil,
                        matchType: .fuzzy,
                        relevance: score,
                        context: getContext(lines: lines, lineIndex: lineIndex)
                    )
                    matches.append(match)
                }
            }

            // Check for word matches within line
            let words = query.split(separator: " ")
            if words.count > 1 {
                var wordMatches = 0
                for word in words {
                    if lineLowercased.contains(word.lowercased()) {
                        wordMatches += 1
                    }
                }

                if wordMatches >= words.count / 2 {
                    let relevance = Float(wordMatches) / Float(words.count)
                    let match = LyricsMatch(
                        lineNumber: lineIndex + 1,
                        lineText: line,
                        matchRange: nil,
                        matchType: .partial,
                        relevance: relevance,
                        context: getContext(lines: lines, lineIndex: lineIndex)
                    )
                    matches.append(match)
                }
            }
        }

        return matches.sorted { $0.relevance > $1.relevance }
    }

    /// Get context lines around a match
    private func getContext(lines: [String], lineIndex: Int, contextLines: Int = 2) -> String {
        let startIndex = max(0, lineIndex - contextLines)
        let endIndex = min(lines.count - 1, lineIndex + contextLines)

        let contextLines = Array(lines[startIndex...endIndex])
        return contextLines.joined(separator: "\n")
    }

    /// Search for a phrase across multiple lines
    func searchPhrase(
        _ phrase: String,
        in lyrics: String
    ) -> [LyricsMatch] {
        var matches: [LyricsMatch] = []

        // Remove line breaks from lyrics for phrase searching
        let continuousText = lyrics.replacingOccurrences(of: "\n", with: " ")
        let phraseLowercased = phrase.lowercased()
        let textLowercased = continuousText.lowercased()

        // Find all occurrences
        var searchStartIndex = textLowercased.startIndex

        while let range = textLowercased.range(
            of: phraseLowercased,
            range: searchStartIndex..<textLowercased.endIndex
        ) {
            // Get surrounding context
            let contextStart = textLowercased.index(
                range.lowerBound,
                offsetBy: -50,
                limitedBy: textLowercased.startIndex
            ) ?? textLowercased.startIndex

            let contextEnd = textLowercased.index(
                range.upperBound,
                offsetBy: 50,
                limitedBy: textLowercased.endIndex
            ) ?? textLowercased.endIndex

            let context = String(continuousText[contextStart..<contextEnd])

            let match = LyricsMatch(
                lineNumber: 0, // Unknown when searching continuous text
                lineText: String(continuousText[range]),
                matchRange: range,
                matchType: .exact,
                relevance: 1.0,
                context: context
            )
            matches.append(match)

            // Move past this match
            searchStartIndex = range.upperBound
        }

        return matches
    }

    // MARK: - Chord Search

    /// Search for specific chords in a song
    func searchChords(
        _ query: String,
        in chordsData: String
    ) -> [ChordMatch] {
        var matches: [ChordMatch] = []

        // Parse query for chord names
        let requestedChords = parseChordQuery(query)

        // Parse chords from song data
        let songChords = extractChords(from: chordsData)

        // Find matches
        for requestedChord in requestedChords {
            for (index, songChord) in songChords.enumerated() {
                if isSameChord(requestedChord, songChord) {
                    let match = ChordMatch(
                        chordName: songChord,
                        position: index,
                        matchType: .exact
                    )
                    matches.append(match)
                } else if isRelatedChord(requestedChord, songChord) {
                    let match = ChordMatch(
                        chordName: songChord,
                        position: index,
                        matchType: .related
                    )
                    matches.append(match)
                }
            }
        }

        return matches
    }

    /// Parse chord names from natural language query
    private func parseChordQuery(_ query: String) -> [String] {
        // Pattern to match chord names: C, Cmaj7, D#m, etc.
        let pattern = #"[A-G][#b]?(?:maj|min|m|sus|dim|aug)?(?:\d+)?"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsString = query as NSString
        let matches = regex.matches(
            in: query,
            range: NSRange(location: 0, length: nsString.length)
        )

        return matches.map { nsString.substring(with: $0.range) }
    }

    /// Extract all chords from chord sheet data
    private func extractChords(from chordsData: String) -> [String] {
        // Pattern to match chord names in various formats
        let pattern = #"\b[A-G][#b]?(?:maj|min|m|sus|dim|aug)?(?:\d+)?(?:/[A-G][#b]?)?\b"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsString = chordsData as NSString
        let matches = regex.matches(
            in: chordsData,
            range: NSRange(location: 0, length: nsString.length)
        )

        return matches.map { nsString.substring(with: $0.range) }
    }

    /// Check if two chord names represent the same chord
    private func isSameChord(_ chord1: String, _ chord2: String) -> Bool {
        // Normalize chord names
        let normalized1 = normalizeChordName(chord1)
        let normalized2 = normalizeChordName(chord2)

        return normalized1 == normalized2
    }

    /// Check if two chords are related (e.g., C and Cmaj7)
    private func isRelatedChord(_ chord1: String, _ chord2: String) -> Bool {
        let root1 = extractChordRoot(chord1)
        let root2 = extractChordRoot(chord2)

        return root1 == root2
    }

    /// Normalize chord name for comparison
    private func normalizeChordName(_ chord: String) -> String {
        var normalized = chord

        // Normalize minor notation
        normalized = normalized.replacingOccurrences(of: "min", with: "m")

        // Normalize sharp/flat
        // (Could expand this to handle enharmonic equivalents like C# and Db)

        return normalized.uppercased()
    }

    /// Extract root note from chord
    private func extractChordRoot(_ chord: String) -> String {
        // Get first 1-2 characters (note + accidental)
        let pattern = #"^[A-G][#b]?"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(
                in: chord,
                range: NSRange(location: 0, length: (chord as NSString).length)
              ) else {
            return chord
        }

        return (chord as NSString).substring(with: match.range)
    }

    // MARK: - Chord Progression Search

    /// Search for chord progressions
    func searchChordProgression(
        _ progression: [String],
        in chordsData: String
    ) -> [ProgressionMatch] {
        let songChords = extractChords(from: chordsData)

        var matches: [ProgressionMatch] = []

        // Sliding window search
        for startIndex in 0..<max(1, songChords.count - progression.count + 1) {
            let window = Array(songChords[startIndex..<min(startIndex + progression.count, songChords.count)])

            var matchCount = 0
            for (index, chord) in progression.enumerated() {
                if index < window.count && isSameChord(chord, window[index]) {
                    matchCount += 1
                }
            }

            if matchCount >= progression.count {
                // Exact match
                let match = ProgressionMatch(
                    progression: window,
                    startPosition: startIndex,
                    matchType: .exact,
                    confidence: 1.0
                )
                matches.append(match)
            } else if matchCount >= progression.count / 2 {
                // Partial match
                let confidence = Float(matchCount) / Float(progression.count)
                let match = ProgressionMatch(
                    progression: window,
                    startPosition: startIndex,
                    matchType: .partial,
                    confidence: confidence
                )
                matches.append(match)
            }
        }

        return matches
    }

    /// Detect common chord progressions (I-IV-V, etc.)
    func detectCommonProgressions(in chordsData: String, key: String) -> [String] {
        let chords = extractChords(from: chordsData)

        var detectedProgressions: [String] = []

        // Define common progressions in relative notation
        let commonProgressions = [
            "I-IV-V": ["I", "IV", "V"],
            "I-V-vi-IV": ["I", "V", "vi", "IV"],
            "ii-V-I": ["ii", "V", "I"],
            "I-vi-IV-V": ["I", "vi", "IV", "V"]
        ]

        // Convert song chords to Roman numeral notation
        let romanNumerals = convertToRomanNumerals(chords, key: key)

        // Check for each common progression
        for (name, progression) in commonProgressions {
            if containsProgression(romanNumerals, progression: progression) {
                detectedProgressions.append(name)
            }
        }

        return detectedProgressions
    }

    /// Convert chords to Roman numeral notation
    private func convertToRomanNumerals(_ chords: [String], key: String) -> [String] {
        // Simplified implementation - would need full music theory
        // This is a placeholder for the concept
        return chords // In reality, would convert based on key
    }

    /// Check if progression contains a pattern
    private func containsProgression(_ chords: [String], progression: [String]) -> Bool {
        for startIndex in 0..<max(1, chords.count - progression.count + 1) {
            let window = Array(chords[startIndex..<min(startIndex + progression.count, chords.count)])

            if window == progression {
                return true
            }
        }
        return false
    }

    // MARK: - Content Highlighting

    /// Generate highlighted snippet for search result
    func generateSnippet(
        text: String,
        query: String,
        maxLength: Int = 150
    ) -> (snippet: String, highlights: [Range<String.Index>]) {
        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()

        guard let matchRange = lowercasedText.range(of: lowercasedQuery) else {
            // No match - return first part of text
            let endIndex = text.index(
                text.startIndex,
                offsetBy: min(maxLength, text.count),
                limitedBy: text.endIndex
            ) ?? text.endIndex

            return (String(text[..<endIndex]) + "...", [])
        }

        // Calculate snippet range around match
        let snippetStart = text.index(
            matchRange.lowerBound,
            offsetBy: -(maxLength / 2),
            limitedBy: text.startIndex
        ) ?? text.startIndex

        let snippetEnd = text.index(
            matchRange.upperBound,
            offsetBy: maxLength / 2,
            limitedBy: text.endIndex
        ) ?? text.endIndex

        let snippet = String(text[snippetStart..<snippetEnd])

        // Adjust match range to be relative to snippet
        let matchInSnippet = snippet.range(of: String(text[matchRange]))

        let highlights = matchInSnippet.map { [$0] } ?? []

        var formattedSnippet = snippet
        if snippetStart != text.startIndex {
            formattedSnippet = "..." + formattedSnippet
        }
        if snippetEnd != text.endIndex {
            formattedSnippet = formattedSnippet + "..."
        }

        return (formattedSnippet, highlights)
    }

    // MARK: - Combined Content Search

    /// Search across both lyrics and chords
    func searchSongContent(
        query: String,
        lyrics: String?,
        chords: String?,
        fuzzyMatch: Bool = true
    ) -> ContentSearchResult {
        var lyricsMatches: [LyricsMatch] = []
        var chordMatches: [ChordMatch] = []

        if let lyrics = lyrics {
            lyricsMatches = searchLyrics(query, in: lyrics, fuzzyMatch: fuzzyMatch)
        }

        if let chords = chords {
            chordMatches = searchChords(query, in: chords)
        }

        // Calculate overall relevance
        let lyricsScore = lyricsMatches.first?.relevance ?? 0.0
        let chordScore = chordMatches.isEmpty ? 0.0 : 1.0
        let overallRelevance = (lyricsScore * 0.7) + (chordScore * 0.3)

        return ContentSearchResult(
            lyricsMatches: lyricsMatches,
            chordMatches: chordMatches,
            overallRelevance: overallRelevance,
            hasLyricsMatch: !lyricsMatches.isEmpty,
            hasChordsMatch: !chordMatches.isEmpty
        )
    }
}

// MARK: - Supporting Types

/// Represents a match in lyrics
struct LyricsMatch {
    let lineNumber: Int
    let lineText: String
    let matchRange: Range<String.Index>?
    let matchType: MatchType
    let relevance: Float
    let context: String

    enum MatchType {
        case exact
        case fuzzy
        case partial
    }
}

/// Represents a chord match
struct ChordMatch {
    let chordName: String
    let position: Int
    let matchType: MatchType

    enum MatchType {
        case exact
        case related
    }
}

/// Represents a chord progression match
struct ProgressionMatch {
    let progression: [String]
    let startPosition: Int
    let matchType: MatchType
    let confidence: Float

    enum MatchType {
        case exact
        case partial
    }
}

/// Combined content search result
struct ContentSearchResult {
    let lyricsMatches: [LyricsMatch]
    let chordMatches: [ChordMatch]
    let overallRelevance: Float
    let hasLyricsMatch: Bool
    let hasChordsMatch: Bool

    var matchCount: Int {
        lyricsMatches.count + chordMatches.count
    }

    var bestSnippet: String? {
        lyricsMatches.first?.context
    }
}
