//
//  SongAnalysisEngine.swift
//  Lyra
//
//  Phase 7.5: Recommendation Intelligence
//  Analyzes song characteristics for similarity matching and recommendations
//  Created on January 24, 2026
//

import Foundation
import NaturalLanguage

/// Analyzes song characteristics for recommendation purposes
@MainActor
class SongAnalysisEngine {

    // MARK: - Properties

    private let keyRecommendationEngine: KeyRecommendationEngine
    private let musicTheoryEngine: MusicTheoryEngine

    // Common worship themes for lyric analysis
    private let worshipThemes = [
        "grace", "hope", "love", "faith", "peace",
        "praise", "worship", "salvation", "redemption",
        "joy", "trust", "strength", "mercy", "glory",
        "holy", "spirit", "father", "jesus", "christ",
        "heaven", "king", "lord", "god", "savior"
    ]

    // MARK: - Initialization

    init(
        keyRecommendationEngine: KeyRecommendationEngine = KeyRecommendationEngine(),
        musicTheoryEngine: MusicTheoryEngine = MusicTheoryEngine()
    ) {
        self.keyRecommendationEngine = keyRecommendationEngine
        self.musicTheoryEngine = musicTheoryEngine
    }

    // MARK: - Public Methods

    /// Analyze comprehensive song characteristics
    func analyzeSong(_ song: Song) -> SongCharacteristics {
        let key = determineKey(song)
        let tempo = song.tempo ?? 120
        let chords = extractChords(from: song.chords)
        let complexity = calculateChordComplexity(chords)
        let themes = extractLyricThemes(song.lyrics)
        let genre = estimateGenre(song)
        let structure = analyzeSongStructure(song)

        return SongCharacteristics(
            songID: song.id,
            key: key,
            tempo: tempo,
            timeSignature: song.timeSignature ?? "4/4",
            chordComplexity: complexity,
            chordCount: chords.count,
            uniqueChords: Set(chords).count,
            lyricThemes: themes,
            estimatedGenre: genre,
            harmonicComplexity: calculateHarmonicComplexity(chords, key: key),
            songStructure: structure,
            estimatedDuration: estimateDuration(song)
        )
    }

    /// Calculate chord complexity score (0.0 = simple, 1.0 = complex)
    func calculateChordComplexity(_ chords: [String]) -> Float {
        guard !chords.isEmpty else { return 0.0 }

        let totalCount = Float(chords.count)
        let uniqueCount = Float(Set(chords).count)

        // Count different chord types
        let extensionCount = Float(chords.filter { hasExtension($0) }.count)
        let slashCount = Float(chords.filter { $0.contains("/") }.count)
        let diminishedAugmented = Float(chords.filter { isDiminishedOrAugmented($0) }.count)

        // Calculate ratios
        let uniqueRatio = uniqueCount / totalCount
        let extensionRatio = extensionCount / totalCount
        let slashRatio = slashCount / totalCount
        let dimAugRatio = diminishedAugmented / totalCount

        // Weighted complexity score
        let complexity = (uniqueRatio * 0.3) +
                        (extensionRatio * 0.25) +
                        (slashRatio * 0.2) +
                        (dimAugRatio * 0.25)

        return min(1.0, complexity)
    }

    /// Extract lyric themes using NaturalLanguage framework
    func extractLyricThemes(_ lyrics: String) -> [String] {
        guard !lyrics.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = lyrics.lowercased()

        var keywords: [String] = []

        tagger.enumerateTags(
            in: lyrics.startIndex..<lyrics.endIndex,
            unit: .word,
            scheme: .lexicalClass
        ) { tag, range in
            if tag == .noun || tag == .verb {
                let word = String(lyrics[range]).lowercased()
                if isSignificantWord(word) {
                    keywords.append(word)
                }
            }
            return true
        }

        // Get most frequent significant words
        let frequentWords = keywords.frequency().prefix(10).map { $0.element }

        // Filter for worship themes
        let themes = frequentWords.filter { worshipThemes.contains($0) }

        return Array(themes.prefix(5))
    }

    /// Estimate genre based on song characteristics
    func estimateGenre(_ song: Song) -> String? {
        // If genre is explicitly set, use it
        if let genre = song.genre, !genre.isEmpty {
            return genre
        }

        // Estimate based on characteristics
        let themes = extractLyricThemes(song.lyrics)
        let hasWorshipThemes = !themes.isEmpty

        if hasWorshipThemes {
            return "Contemporary Worship"
        }

        return nil
    }

    /// Analyze song structure (verse/chorus/bridge)
    func analyzeSongStructure(_ song: Song) -> SongStructure {
        let sections = song.chords.lowercased()

        let hasIntro = sections.contains("intro")
        let hasVerse = sections.contains("verse")
        let hasChorus = sections.contains("chorus")
        let hasBridge = sections.contains("bridge")
        let hasOutro = sections.contains("outro") || sections.contains("ending")

        // Count sections
        let verseCount = countOccurrences(of: "verse", in: sections)
        let chorusCount = countOccurrences(of: "chorus", in: sections)
        let bridgeCount = countOccurrences(of: "bridge", in: sections)

        return SongStructure(
            hasIntro: hasIntro,
            hasVerse: hasVerse,
            hasChorus: hasChorus,
            hasBridge: hasBridge,
            hasOutro: hasOutro,
            verseCount: verseCount,
            chorusCount: chorusCount,
            bridgeCount: bridgeCount
        )
    }

    // MARK: - Private Helper Methods

    private func determineKey(_ song: Song) -> String {
        // Use existing key if available and valid
        if let key = song.key, !key.isEmpty {
            return key
        }

        // Try to detect key from chords
        let chords = extractChords(from: song.chords)
        if !chords.isEmpty {
            let recommendations = keyRecommendationEngine.detectPossibleKeys(from: chords)
            if let bestKey = recommendations.first {
                return bestKey.key
            }
        }

        // Default to C
        return "C"
    }

    private func extractChords(from text: String) -> [String] {
        // Parse chord symbols from chord chart text
        let lines = text.components(separatedBy: .newlines)
        var chords: [String] = []

        for line in lines {
            // Skip section headers
            if line.lowercased().contains("verse") ||
               line.lowercased().contains("chorus") ||
               line.lowercased().contains("bridge") ||
               line.lowercased().contains("intro") ||
               line.lowercased().contains("outro") {
                continue
            }

            // Extract chord symbols (simplified pattern)
            let pattern = #"[A-G][#b]?(?:maj|min|m|M|aug|dim|sus)?[0-9]?(?:/[A-G][#b]?)?"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = line as NSString
                let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))

                for match in matches {
                    let chord = nsString.substring(with: match.range)
                    if !chord.isEmpty {
                        chords.append(chord)
                    }
                }
            }
        }

        return chords
    }

    private func hasExtension(_ chord: String) -> Bool {
        // Check for 7ths, 9ths, 11ths, 13ths
        let extensionPattern = #"[0-9]"#
        if let regex = try? NSRegularExpression(pattern: extensionPattern, options: []) {
            let range = NSRange(location: 0, length: chord.utf16.count)
            return regex.firstMatch(in: chord, options: [], range: range) != nil
        }
        return false
    }

    private func isDiminishedOrAugmented(_ chord: String) -> Bool {
        return chord.contains("dim") || chord.contains("aug") || chord.contains("°") || chord.contains("+")
    }

    private func isSignificantWord(_ word: String) -> Bool {
        // Filter out common stop words
        let stopWords = Set([
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "up", "down", "is", "are", "was", "were",
            "be", "been", "being", "have", "has", "had", "do", "does", "did",
            "will", "would", "could", "should", "may", "might", "must", "can",
            "i", "you", "he", "she", "it", "we", "they", "my", "your", "his",
            "her", "its", "our", "their", "this", "that", "these", "those"
        ])

        return word.count > 2 && !stopWords.contains(word)
    }

    private func calculateHarmonicComplexity(_ chords: [String], key: String) -> Float {
        guard !chords.isEmpty else { return 0.0 }

        // Count non-diatonic chords (chords outside the key)
        var nonDiatonicCount = 0

        for chord in chords {
            // This is a simplified check - in production, use MusicTheoryEngine
            // to properly determine if chord is diatonic to the key
            let chordRoot = String(chord.prefix(1))
            if !isDiatonicToKey(chordRoot, key: key) {
                nonDiatonicCount += 1
            }
        }

        let nonDiatonicRatio = Float(nonDiatonicCount) / Float(chords.count)

        // Combine with chord complexity
        let chordComplexity = calculateChordComplexity(chords)

        return (chordComplexity * 0.6) + (nonDiatonicRatio * 0.4)
    }

    private func isDiatonicToKey(_ chordRoot: String, key: String) -> Bool {
        // Simplified diatonic check
        // In production, use full music theory engine
        let majorKeys: [String: [String]] = [
            "C": ["C", "D", "E", "F", "G", "A", "B"],
            "G": ["G", "A", "B", "C", "D", "E", "F"],
            "D": ["D", "E", "F", "G", "A", "B", "C"],
            "A": ["A", "B", "C", "D", "E", "F", "G"],
            "E": ["E", "F", "G", "A", "B", "C", "D"],
            "F": ["F", "G", "A", "B", "C", "D", "E"]
        ]

        let keyNotes = majorKeys[key] ?? []
        return keyNotes.contains(chordRoot)
    }

    private func estimateDuration(_ song: Song) -> TimeInterval? {
        // Estimate based on number of sections and tempo
        let structure = analyzeSongStructure(song)
        let tempo = song.tempo ?? 120

        // Rough estimate: each verse ~30s, chorus ~20s, bridge ~20s
        var estimatedSeconds: TimeInterval = 0

        if structure.hasIntro { estimatedSeconds += 10 }
        estimatedSeconds += TimeInterval(structure.verseCount * 30)
        estimatedSeconds += TimeInterval(structure.chorusCount * 20)
        estimatedSeconds += TimeInterval(structure.bridgeCount * 20)
        if structure.hasOutro { estimatedSeconds += 10 }

        // Adjust for tempo (faster tempo = potentially shorter)
        let tempoFactor = Double(tempo) / 120.0
        estimatedSeconds = estimatedSeconds / tempoFactor

        return estimatedSeconds > 0 ? estimatedSeconds : nil
    }

    private func countOccurrences(of text: String, in string: String) -> Int {
        return string.components(separatedBy: text).count - 1
    }
}

// MARK: - Array Extension for Frequency Counting

private extension Array where Element == String {
    func frequency() -> [(element: String, count: Int)] {
        var counts: [String: Int] = [:]
        for element in self {
            counts[element, default: 0] += 1
        }
        return counts.map { (element: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}
