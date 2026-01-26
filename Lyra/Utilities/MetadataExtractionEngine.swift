//
//  MetadataExtractionEngine.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Extracts song metadata from text
//
//  Created by Claude AI on 1/24/26.
//

import Foundation

/// Extracts title, artist, key, tempo, and other metadata from song text
class MetadataExtractionEngine {

    // MARK: - Properties

    private let chordEngine = ChordExtractionEngine()

    // MARK: - Public Methods

    /// Extract all metadata from text
    func extractMetadata(_ text: String) -> FormattingSongMetadata {
        var metadata = FormattingSongMetadata()

        metadata.title = extractTitle(text)
        metadata.artist = extractArtist(text)
        metadata.key = extractKey(text)
        metadata.tempo = extractTempo(text)
        metadata.timeSignature = extractTimeSignature(text)
        metadata.capo = extractCapo(text)

        // Calculate confidence based on how much metadata was found
        metadata.confidence = metadata.completenessPercentage

        return metadata
    }

    /// Extract song title
    func extractTitle(_ text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return nil }

        // Check for explicit title tag
        if let title = extractFromPattern(text, pattern: "(?:title|song)\\s*:?\\s*(.+)", groupIndex: 1) {
            return title
        }

        // Check for ChordPro title
        if let title = extractFromPattern(text, pattern: "\\{title?:\\s*(.+?)\\}", groupIndex: 1) {
            return title
        }

        // Use first non-metadata line
        for line in lines {
            // Skip known metadata lines
            if isMetadataLine(line) {
                continue
            }

            // Skip chord lines
            if chordEngine.isValidChord(line) {
                continue
            }

            // First substantial line is likely the title
            if line.count > 2 && !line.contains(":") {
                return line
            }
        }

        return nil
    }

    /// Extract artist name
    func extractArtist(_ text: String) -> String? {
        // Check for explicit artist tag
        if let artist = extractFromPattern(text, pattern: "(?:artist|by|author)\\s*:?\\s*(.+)", groupIndex: 1) {
            return artist
        }

        // Check for ChordPro artist
        if let artist = extractFromPattern(text, pattern: "\\{(?:artist|subtitle):\\s*(.+?)\\}", groupIndex: 1) {
            return artist
        }

        // Check for "by Artist Name" pattern
        if let artist = extractFromPattern(text, pattern: "by\\s+([A-Z][\\w\\s]+)", groupIndex: 1) {
            return artist.trimmingCharacters(in: .whitespaces)
        }

        return nil
    }

    /// Extract or detect musical key
    func extractKey(_ text: String) -> String? {
        // Check for explicit key tag
        if let key = extractFromPattern(text, pattern: "key\\s*(?:of)?\\s*:?\\s*([A-G][#b]?(?:\\s*(?:major|minor|maj|min|m))?)", groupIndex: 1) {
            return normalizeKey(key)
        }

        // Check for ChordPro key
        if let key = extractFromPattern(text, pattern: "\\{key:\\s*([A-G][#b]?(?:\\s*(?:major|minor|maj|min|m))?)\\}", groupIndex: 1) {
            return normalizeKey(key)
        }

        // Infer from chords
        let chords = chordEngine.extractChords(text)
        if !chords.isEmpty {
            return inferKey(from: chords)
        }

        return nil
    }

    /// Extract tempo (BPM)
    func extractTempo(_ text: String) -> Int? {
        // Check for explicit tempo tag
        if let tempoStr = extractFromPattern(text, pattern: "tempo\\s*:?\\s*(\\d+)", groupIndex: 1) {
            return Int(tempoStr)
        }

        // Check for BPM notation
        if let bpmStr = extractFromPattern(text, pattern: "(\\d+)\\s*bpm", groupIndex: 1) {
            return Int(bpmStr)
        }

        // Check for ChordPro tempo
        if let tempoStr = extractFromPattern(text, pattern: "\\{tempo:\\s*(\\d+)\\}", groupIndex: 1) {
            return Int(tempoStr)
        }

        return nil
    }

    /// Extract time signature
    func extractTimeSignature(_ text: String) -> String? {
        // Check for explicit time signature tag
        if let timeSig = extractFromPattern(text, pattern: "time\\s+signature\\s*:?\\s*(\\d+/\\d+)", groupIndex: 1) {
            return timeSig
        }

        // Check for standalone time signature
        if let timeSig = extractFromPattern(text, pattern: "\\b(\\d+/\\d+)\\b", groupIndex: 1) {
            let components = timeSig.components(separatedBy: "/")
            if components.count == 2,
               let numerator = Int(components[0]),
               let denominator = Int(components[1]),
               [1, 2, 3, 4, 6, 8, 12, 16].contains(numerator),
               [2, 4, 8, 16].contains(denominator) {
                return timeSig
            }
        }

        // Check for ChordPro time signature
        if let timeSig = extractFromPattern(text, pattern: "\\{time:\\s*(\\d+/\\d+)\\}", groupIndex: 1) {
            return timeSig
        }

        // Default assumption
        return nil
    }

    /// Extract capo position
    func extractCapo(_ text: String) -> Int? {
        // Check for capo tag
        if let capoStr = extractFromPattern(text, pattern: "capo\\s*:?\\s*(\\d+)", groupIndex: 1) {
            return Int(capoStr)
        }

        // Check for ChordPro capo
        if let capoStr = extractFromPattern(text, pattern: "\\{capo:\\s*(\\d+)\\}", groupIndex: 1) {
            return Int(capoStr)
        }

        // Check for "no capo"
        if text.lowercased().contains("no capo") {
            return 0
        }

        return nil
    }

    // MARK: - Private Helpers

    private func extractFromPattern(_ text: String, pattern: String, groupIndex: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > groupIndex else {
            return nil
        }

        let matchRange = match.range(at: groupIndex)
        guard let swiftRange = Range(matchRange, in: text) else {
            return nil
        }

        return String(text[swiftRange]).trimmingCharacters(in: .whitespaces)
    }

    private func isMetadataLine(_ line: String) -> Bool {
        let metadataPatterns = [
            "(?:title|artist|by|key|tempo|time|capo)\\s*:?\\s*",
            "\\{(?:title|artist|key|tempo|time|capo):",
            "\\d+\\s*bpm"
        ]

        for pattern in metadataPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(line.startIndex..., in: line)
                if regex.firstMatch(in: line, range: range) != nil {
                    return true
                }
            }
        }

        return false
    }

    private func normalizeKey(_ key: String) -> String {
        var normalized = key.trimmingCharacters(in: .whitespaces)

        // Standardize major/minor notation
        normalized = normalized.replacingOccurrences(of: "major", with: "", options: .caseInsensitive)
        normalized = normalized.replacingOccurrences(of: "maj", with: "", options: .caseInsensitive)
        normalized = normalized.replacingOccurrences(of: "minor", with: "m", options: .caseInsensitive)
        normalized = normalized.replacingOccurrences(of: "min", with: "m", options: .caseInsensitive)

        return normalized.trimmingCharacters(in: .whitespaces)
    }

    private func inferKey(from chords: [String]) -> String? {
        // Simple key inference based on most common chord
        guard !chords.isEmpty else { return nil }

        // Count chord occurrences
        var chordCounts: [String: Int] = [:]
        for chord in chords {
            // Extract just the root note (first 1-2 characters)
            let root = String(chord.prefix(while: { $0.isLetter || $0 == "#" || $0 == "b" }))
            chordCounts[root, default: 0] += 1
        }

        // Return most common chord as likely key
        let sorted = chordCounts.sorted { $0.value > $1.value }
        return sorted.first?.key
    }
}
