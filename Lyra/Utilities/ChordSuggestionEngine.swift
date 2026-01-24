//
//  ChordSuggestionEngine.swift
//  Lyra
//
//  Engine for AI-powered chord suggestions, autocomplete, and error detection
//  Part of Phase 7.2: Chord Analysis Intelligence
//

import Foundation

/// Provides intelligent chord suggestions and error detection
class ChordSuggestionEngine {

    // MARK: - Properties

    private let theoryEngine: MusicTheoryEngine
    private let database: ChordDatabase
    private var recentChords: [String] = []
    private let maxRecentChords = 20

    // Common chord patterns for autocomplete
    private let commonChords = [
        "C", "D", "E", "F", "G", "A", "B",
        "Cm", "Dm", "Em", "Fm", "Gm", "Am", "Bm",
        "C7", "D7", "E7", "F7", "G7", "A7", "B7",
        "Cmaj7", "Dmaj7", "Emaj7", "Fmaj7", "Gmaj7", "Amaj7", "Bmaj7",
        "Cm7", "Dm7", "Em7", "Fm7", "Gm7", "Am7", "Bm7"
    ]

    // MARK: - Initialization

    init() {
        self.theoryEngine = MusicTheoryEngine()
        self.database = ChordDatabase()
    }

    // MARK: - Autocomplete

    /// Get autocomplete suggestions for partial chord input
    func getAutocompleteSuggestions(for context: AutocompleteContext) -> [ChordSuggestion] {
        var suggestions: [ChordSuggestion] = []
        let partial = context.partialChord.uppercased()

        guard !partial.isEmpty else {
            // No input yet - suggest common starting chords
            return getInitialSuggestions(context: context)
        }

        // 1. Exact prefix matches in common chords
        let prefixMatches = commonChords.filter { $0.hasPrefix(partial) }
        for chord in prefixMatches {
            suggestions.append(ChordSuggestion(
                chord: chord,
                confidence: 0.9,
                reason: .autocomplete,
                context: "Common chord"
            ))
        }

        // 2. Recently used chords that match
        let recentMatches = context.recentChords.filter { $0.uppercased().hasPrefix(partial) }
        for chord in recentMatches {
            if !suggestions.contains(where: { $0.chord == chord }) {
                suggestions.append(ChordSuggestion(
                    chord: chord,
                    confidence: 0.95,
                    reason: .recentlyUsed,
                    context: "Used recently"
                ))
            }
        }

        // 3. Chords in current key
        if let key = context.currentKey,
           let keySignature = theoryEngine.getKeySignature(for: key) {
            for diatonicChord in keySignature.commonChords {
                if diatonicChord.uppercased().hasPrefix(partial) &&
                   !suggestions.contains(where: { $0.chord == diatonicChord }) {
                    suggestions.append(ChordSuggestion(
                        chord: diatonicChord,
                        confidence: 0.85,
                        reason: .inKey,
                        context: "In key of \(key)"
                    ))
                }
            }
        }

        // 4. Common progression continuations
        if !context.previousChords.isEmpty {
            let nextChords = predictNextChords(after: context.previousChords, key: context.currentKey)
            for (chord, probability) in nextChords {
                if chord.uppercased().hasPrefix(partial) &&
                   !suggestions.contains(where: { $0.chord == chord }) {
                    suggestions.append(ChordSuggestion(
                        chord: chord,
                        confidence: probability,
                        reason: .commonProgression,
                        context: "Common after \(context.previousChords.last ?? "")"
                    ))
                }
            }
        }

        // 5. Typo corrections
        if partial.count >= 2 {
            let corrections = detectTypos(in: partial)
            for (chord, confidence) in corrections {
                if !suggestions.contains(where: { $0.chord == chord }) {
                    suggestions.append(ChordSuggestion(
                        chord: chord,
                        confidence: confidence,
                        reason: .typoCorrection,
                        context: "Did you mean '\(chord)'?"
                    ))
                }
            }
        }

        // Sort by confidence and limit results
        return suggestions
            .sorted { $0.confidence > $1.confidence }
            .prefix(10)
            .map { $0 }
    }

    /// Get initial suggestions when no input yet
    private func getInitialSuggestions(context: AutocompleteContext) -> [ChordSuggestion] {
        var suggestions: [ChordSuggestion] = []

        // If we have a key, suggest tonic chord first
        if let key = context.currentKey {
            suggestions.append(ChordSuggestion(
                chord: key,
                confidence: 1.0,
                reason: .inKey,
                context: "Tonic chord"
            ))
        }

        // Recently used chords
        for chord in context.recentChords.prefix(3) {
            if !suggestions.contains(where: { $0.chord == chord }) {
                suggestions.append(ChordSuggestion(
                    chord: chord,
                    confidence: 0.9,
                    reason: .recentlyUsed
                ))
            }
        }

        // Common starting chords if nothing else
        if suggestions.isEmpty {
            for chord in ["C", "G", "Am", "F", "D"] {
                suggestions.append(ChordSuggestion(
                    chord: chord,
                    confidence: 0.7,
                    reason: .autocomplete,
                    context: "Popular starting chord"
                ))
            }
        }

        return suggestions.prefix(5).map { $0 }
    }

    // MARK: - Error Detection

    /// Detect errors in a chord progression
    func detectErrors(in chords: [String], key: String?) -> [ChordError] {
        var errors: [ChordError] = []

        for (index, chord) in chords.enumerated() {
            // Check for invalid syntax
            if !isValidChordSyntax(chord) {
                errors.append(ChordError(
                    chordIndex: index,
                    chord: chord,
                    errorType: .invalidSyntax,
                    severity: .error,
                    suggestions: suggestCorrections(for: chord, key: key),
                    explanation: "Invalid chord syntax. Check spelling and format."
                ))
                continue
            }

            // Check if chord is out of key
            if let key = key {
                if !theoryEngine.validateChord(chord, in: key) {
                    errors.append(ChordError(
                        chordIndex: index,
                        chord: chord,
                        errorType: .outOfKey,
                        severity: .warning,
                        suggestions: theoryEngine.suggestCorrections(for: chord, in: key).map {
                            ChordSuggestion(chord: $0, confidence: 0.8, reason: .enharmonic)
                        },
                        explanation: "\(chord) is not diatonic to \(key). This may be intentional (modal interchange, secondary dominant, etc.)"
                    ))
                }
            }

            // Check for typos
            let typoSuggestions = detectTypos(in: chord)
            if !typoSuggestions.isEmpty {
                errors.append(ChordError(
                    chordIndex: index,
                    chord: chord,
                    errorType: .typo,
                    severity: .info,
                    suggestions: typoSuggestions.map {
                        ChordSuggestion(chord: $0.chord, confidence: $0.probability, reason: .typoCorrection)
                    },
                    explanation: "Possible typo detected. Did you mean one of these?"
                ))
            }

            // Check for unlikely progressions
            if index > 0 {
                let previousChord = chords[index - 1]
                if isUnlikelyProgression(from: previousChord, to: chord) {
                    errors.append(ChordError(
                        chordIndex: index,
                        chord: chord,
                        errorType: .unlikelyProgression,
                        severity: .info,
                        suggestions: suggestBetterProgressions(after: previousChord, key: key),
                        explanation: "\(previousChord) → \(chord) is an unusual progression. Consider alternatives."
                    ))
                }
            }
        }

        return errors
    }

    // MARK: - Chord Corrections

    /// Suggest corrections for a chord
    func suggestCorrections(for chord: String, key: String?) -> [ChordSuggestion] {
        var suggestions: [ChordSuggestion] = []

        // Typo corrections
        let typos = detectTypos(in: chord)
        suggestions.append(contentsOf: typos.map {
            ChordSuggestion(chord: $0.chord, confidence: $0.probability, reason: .typoCorrection)
        })

        // Enharmonic equivalents
        let root = theoryEngine.extractChordRoot(chord)
        if let enharmonic = theoryEngine.getEnharmonicEquivalent(root) {
            let enharmonicChord = chord.replacingOccurrences(of: root, with: enharmonic)
            suggestions.append(ChordSuggestion(
                chord: enharmonicChord,
                confidence: 0.9,
                reason: .enharmonic,
                context: "Enharmonic equivalent"
            ))
        }

        // Diatonic alternatives if out of key
        if let key = key {
            let diatonicCorrections = theoryEngine.suggestCorrections(for: chord, in: key)
            suggestions.append(contentsOf: diatonicCorrections.map {
                ChordSuggestion(chord: $0, confidence: 0.7, reason: .inKey, context: "Diatonic to \(key)")
            })
        }

        return suggestions.sorted { $0.confidence > $1.confidence }.prefix(5).map { $0 }
    }

    // MARK: - Progression Prediction

    /// Predict likely next chords based on progression
    private func predictNextChords(after chords: [String], key: String?) -> [(chord: String, probability: Float)] {
        var predictions: [(chord: String, probability: Float)] = []

        guard let lastChord = chords.last else { return [] }

        // Check against common progressions database
        let matchingProgressions = database.findProgressionsContaining(chords: chords)
        for progression in matchingProgressions {
            if let nextChord = progression.getNextChord(after: chords) {
                predictions.append((chord: nextChord, probability: progression.popularity))
            }
        }

        // Music theory predictions (V -> I, etc.)
        if let key = key {
            let theoryPredictions = theoryEngine.predictNextChord(after: lastChord, in: key)
            predictions.append(contentsOf: theoryPredictions)
        }

        // Remove duplicates, keeping highest probability
        var seen = Set<String>()
        var unique: [(chord: String, probability: Float)] = []
        for prediction in predictions.sorted(by: { $0.probability > $1.probability }) {
            if !seen.contains(prediction.chord) {
                seen.insert(prediction.chord)
                unique.append(prediction)
            }
        }

        return unique.prefix(5).map { $0 }
    }

    // MARK: - Typo Detection

    /// Detect possible typos in chord name
    private func detectTypos(in chord: String) -> [(chord: String, probability: Float)] {
        var corrections: [(chord: String, probability: Float)] = []

        // Common typos
        let typoMap: [String: String] = [
            "Csus": "Csus4",
            "Dsus": "Dsus4",
            "Esus": "Esus4",
            "Fsus": "Fsus4",
            "Gsus": "Gsus4",
            "Asus": "Asus4",
            "Bsus": "Bsus4",
            "C#": "Db",  // In flat keys
            "D#": "Eb",
            "F#": "Gb",
            "G#": "Ab",
            "A#": "Bb"
        ]

        if let correction = typoMap[chord] {
            corrections.append((chord: correction, probability: 0.9))
        }

        // Check for missing chord quality (e.g., "C7" entered as "C")
        if chord.count <= 2 && !chord.contains("m") {
            corrections.append((chord: "\(chord)7", probability: 0.6))
            corrections.append((chord: "\(chord)m", probability: 0.6))
        }

        // Fuzzy matching against common chords
        for commonChord in commonChords {
            let distance = levenshteinDistance(chord, commonChord)
            if distance == 1 {
                // One character difference - likely typo
                corrections.append((chord: commonChord, probability: 0.8))
            } else if distance == 2 {
                // Two character difference - possible typo
                corrections.append((chord: commonChord, probability: 0.5))
            }
        }

        return corrections.sorted { $0.probability > $1.probability }.prefix(3).map { $0 }
    }

    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)

        for i in 0...s1Array.count {
            matrix[i][0] = i
        }
        for j in 0...s2Array.count {
            matrix[0][j] = j
        }

        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[s1Array.count][s2Array.count]
    }

    // MARK: - Validation

    /// Check if chord has valid syntax
    private func isValidChordSyntax(_ chord: String) -> Bool {
        // Very basic validation
        guard !chord.isEmpty else { return false }
        guard chord.count <= 10 else { return false } // Reasonable length limit

        // First character should be A-G
        let first = chord.uppercased().first!
        guard "ABCDEFG".contains(first) else { return false }

        // Can't start with lowercase (root should be capital)
        if chord.first!.isLowercase && chord.first! != "m" {
            return false
        }

        return true
    }

    /// Check if progression is unlikely
    private func isUnlikelyProgression(from chord1: String, to chord2: String) -> Bool {
        // Simplified heuristic - in real implementation, use music theory
        // For now, just flag some obviously weird progressions

        // Same chord repeated (might be intentional but worth noting)
        if chord1 == chord2 {
            return false // Actually common, so not unlikely
        }

        // TODO: Add more sophisticated progression analysis
        return false
    }

    /// Suggest better progressions after a chord
    private func suggestBetterProgressions(after chord: String, key: String?) -> [ChordSuggestion] {
        guard let key = key else { return [] }

        let predictions = theoryEngine.predictNextChord(after: chord, in: key)
        return predictions.map {
            ChordSuggestion(
                chord: $0.chord,
                confidence: $0.probability,
                reason: .commonProgression,
                context: "Common after \(chord)"
            )
        }
    }

    // MARK: - Recent Chords Tracking

    /// Add a chord to recent history
    func addToRecentChords(_ chord: String) {
        recentChords.insert(chord, at: 0)
        if recentChords.count > maxRecentChords {
            recentChords.removeLast()
        }
    }

    /// Clear recent chords history
    func clearRecentChords() {
        recentChords.removeAll()
    }
}

// MARK: - Extensions

extension MusicTheoryEngine {
    /// Get key signature for a key
    func getKeySignature(for key: String) -> KeySignature? {
        // This would need to be added to MusicTheoryEngine
        // For now, return nil
        return nil
    }

    /// Predict next chord based on music theory
    func predictNextChord(after chord: String, in key: String) -> [(chord: String, probability: Float)] {
        // Simplified prediction based on common progressions
        var predictions: [(chord: String, probability: Float)] = []

        // Common progressions in major keys
        if key.uppercased() == key { // Major key (heuristic)
            let chordRoot = extractChordRoot(chord)

            // V -> I is very common
            if chordRoot == "G" && key == "C" {
                predictions.append(("C", 0.9))
            }

            // I -> IV is common
            if chordRoot == key {
                predictions.append(("\(transposeChord(key, by: 5))", 0.7)) // IV
                predictions.append(("\(transposeChord(key, by: 7))", 0.8)) // V
            }
        }

        return predictions
    }

    /// Get enharmonic equivalent
    func getEnharmonicEquivalent(_ note: String) -> String? {
        let enharmonics: [String: String] = [
            "C#": "Db", "Db": "C#",
            "D#": "Eb", "Eb": "D#",
            "F#": "Gb", "Gb": "F#",
            "G#": "Ab", "Ab": "G#",
            "A#": "Bb", "Bb": "A#"
        ]
        return enharmonics[note]
    }

    /// Extract chord root (make public if needed)
    func extractChordRoot(_ chord: String) -> String {
        // Handle two-character roots (e.g., "C#", "Bb")
        if chord.count >= 2 {
            let firstTwo = String(chord.prefix(2))
            let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
                                  "Db", "Eb", "Gb", "Ab", "Bb"]
            if chromaticScale.contains(firstTwo) {
                return firstTwo
            }
        }

        // Single character root
        if chord.count >= 1 {
            return String(chord.prefix(1))
        }

        return chord
    }
}
