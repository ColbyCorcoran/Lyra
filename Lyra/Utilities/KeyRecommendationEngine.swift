//
//  KeyRecommendationEngine.swift
//  Lyra
//
//  Engine for intelligent key detection and recommendation
//  Part of Phase 7.3: Key Intelligence
//

import Foundation

/// Main engine for key recommendations
class KeyRecommendationEngine {

    // MARK: - Properties

    private let theoryEngine: MusicTheoryEngine
    private let vocalAnalyzer: VocalRangeAnalyzer
    private let learningEngine: KeyLearningEngine

    // Easy guitar keys (for capo logic)
    private let easyGuitarKeys = ["C", "G", "D", "A", "E", "Am", "Em", "Dm"]

    // MARK: - Initialization

    init() {
        self.theoryEngine = MusicTheoryEngine()
        self.vocalAnalyzer = VocalRangeAnalyzer()
        self.learningEngine = KeyLearningEngine()
    }

    // MARK: - Auto Key Detection

    /// Automatically detect key from chord progression
    func detectKey(from chords: [String]) -> KeyDetectionResult {
        guard !chords.isEmpty else {
            return KeyDetectionResult(
                possibleKeys: [],
                explanation: "No chords provided for analysis"
            )
        }

        var detectedKeys: [DetectedKey] = []

        // Analyze for all major and minor keys
        for key in getAllKeys() {
            let analysis = analyzeKeyFit(chords: chords, key: key.key, scale: key.scale)
            if analysis.confidence > 0.3 {
                detectedKeys.append(analysis)
            }
        }

        // Sort by confidence
        detectedKeys.sort { $0.confidence > $1.confidence }

        // Check for modal ambiguity
        let modalAmbiguity = checkModalAmbiguity(detectedKeys)

        // Generate explanation
        let explanation = generateKeyDetectionExplanation(detectedKeys: detectedKeys, chords: chords)

        return KeyDetectionResult(
            possibleKeys: detectedKeys,
            mostLikelyKey: detectedKeys.first,
            modalAmbiguity: modalAmbiguity,
            explanation: explanation
        )
    }

    // MARK: - Find Best Key

    /// Find the optimal key for a song based on multiple factors
    func findBestKey(
        chords: [String],
        vocalRange: VocalRange?,
        userPreferences: UserKeyPreferences?
    ) -> [KeyRecommendation] {
        var recommendations: [KeyRecommendation] = []

        // 1. Detect probable keys from chords
        let detection = detectKey(from: chords)

        // 2. For each probable key, create recommendation
        for detectedKey in detection.possibleKeys.prefix(5) {
            var reasons: [KeyRecommendationReason] = [.detectedFromChords]
            var confidence = detectedKey.confidence

            // 3. Check vocal range fit if available
            var vocalFit: VocalRangeFit? = nil
            if let vocalRange = vocalRange {
                let songRange = vocalAnalyzer.analyzeSongRange(
                    chords: chords,
                    key: detectedKey.key
                )
                vocalFit = vocalAnalyzer.checkVocalRangeFit(
                    songRange: songRange,
                    vocalRange: vocalRange
                )

                // Boost confidence for good vocal fit
                if vocalFit?.fitsWithinRange == true {
                    confidence += 0.1
                    reasons.append(.vocalRangeOptimal)
                }
            }

            // 4. Check if easy guitar key
            if easyGuitarKeys.contains(detectedKey.key) {
                confidence += 0.05
                reasons.append(.easyGuitarKey)
            }

            // 5. Analyze capo options
            let capoDifficulty = analyzeCapoDifficulty(chords: chords, key: detectedKey.key)
            if capoDifficulty.worthUsing {
                reasons.append(.capoAvailable)
            }

            // 6. Check user preferences
            if let prefs = userPreferences {
                if prefs.favoriteKeys[detectedKey.key] != nil {
                    confidence += 0.15
                    reasons.append(.userPreference)
                }
            }

            // 7. Boost for modally stable keys
            if detectedKey.hasStrongCadences {
                confidence += 0.05
                reasons.append(.modallyStable)
            }

            // Create recommendation
            recommendations.append(KeyRecommendation(
                key: detectedKey.key,
                scale: detectedKey.scale,
                confidence: min(1.0, confidence),
                reasons: reasons,
                vocalRangeFit: vocalFit,
                capoDifficulty: capoDifficulty
            ))
        }

        // Sort by confidence
        recommendations.sort { $0.confidence > $1.confidence }

        return recommendations
    }

    // MARK: - Suggest Transposition

    /// Suggest transposition for vocal range
    func suggestTransposition(
        currentKey: String,
        chords: [String],
        vocalRange: VocalRange
    ) -> [KeyRecommendation] {
        var recommendations: [KeyRecommendation] = []

        // Try transposing to different keys
        for semitones in -12...12 {
            let newKey = theoryEngine.transposeChord(currentKey, by: semitones)

            // Analyze vocal fit in this key
            let songRange = vocalAnalyzer.analyzeSongRange(chords: chords, key: newKey)
            let vocalFit = vocalAnalyzer.checkVocalRangeFit(
                songRange: songRange,
                vocalRange: vocalRange
            )

            if vocalFit.fitsWithinRange {
                var reasons: [KeyRecommendationReason] = [.vocalRangeOptimal]
                var confidence: Float = 0.8

                // Prefer less transposition
                confidence -= Float(abs(semitones)) * 0.02

                // Check if easy key
                if easyGuitarKeys.contains(newKey) {
                    reasons.append(.easyGuitarKey)
                    confidence += 0.1
                }

                recommendations.append(KeyRecommendation(
                    key: newKey,
                    scale: .major, // Simplified
                    confidence: confidence,
                    reasons: reasons,
                    vocalRangeFit: vocalFit,
                    transpositionSteps: semitones
                ))
            }
        }

        return recommendations.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Private Methods

    /// Analyze how well chords fit a key
    private func analyzeKeyFit(chords: [String], key: String, scale: ScaleType) -> DetectedKey {
        var diatonicCount = 0
        var chromaticCount = 0
        var reasons: [String] = []

        // Get key signature
        let keySignature = theoryEngine.getKeySignature(for: key, scale: scale)

        for chord in chords {
            let chordRoot = theoryEngine.extractChordRoot(chord)

            if keySignature.notes.contains(chordRoot) {
                diatonicCount += 1
            } else {
                chromaticCount += 1
            }
        }

        // Calculate confidence
        let totalChords = Float(chords.count)
        let diatonicRatio = Float(diatonicCount) / totalChords
        var confidence = diatonicRatio

        // Check for strong cadences (V-I, IV-I)
        let hasStrongCadences = detectCadences(chords: chords, key: key)
        if hasStrongCadences {
            confidence += 0.2
            reasons.append("Contains strong cadences (V-I or IV-I)")
        }

        // Check for tonic chord
        if chords.contains(key) || chords.contains("\(key)m") {
            confidence += 0.1
            reasons.append("Contains tonic chord")
        }

        // Penalize too many chromatic chords
        if chromaticCount > chords.count / 2 {
            confidence -= 0.2
        }

        if diatonicCount > 0 {
            reasons.append("\(diatonicCount)/\(chords.count) chords are diatonic")
        }

        return DetectedKey(
            key: key,
            scale: scale,
            confidence: max(0, min(1, confidence)),
            diatonicChordCount: diatonicCount,
            chromaticChordCount: chromaticCount,
            hasStrongCadences: hasStrongCadences,
            reasons: reasons
        )
    }

    /// Detect cadences in progression
    private func detectCadences(chords: [String], key: String) -> Bool {
        // Simplified cadence detection
        let dominant = theoryEngine.transposeChord(key, by: 7) // V
        let subdominant = theoryEngine.transposeChord(key, by: 5) // IV

        for i in 0..<(chords.count - 1) {
            let current = chords[i]
            let next = chords[i + 1]

            // V-I cadence
            if current.starts(with: dominant) && next.starts(with: key) {
                return true
            }

            // IV-I cadence
            if current.starts(with: subdominant) && next.starts(with: key) {
                return true
            }
        }

        return false
    }

    /// Check for modal ambiguity (major vs relative minor)
    private func checkModalAmbiguity(_ keys: [DetectedKey]) -> Bool {
        guard keys.count >= 2 else { return false }

        let topTwo = Array(keys.prefix(2))
        let confidenceDiff = abs(topTwo[0].confidence - topTwo[1].confidence)

        // If top two are close in confidence, check if they're relative
        if confidenceDiff < 0.1 {
            let key1 = topTwo[0].key
            let key2 = topTwo[1].key

            // Check if relative major/minor
            let relativeMajor = theoryEngine.transposeChord(key2, by: 3)
            let relativeMinor = theoryEngine.transposeChord(key1, by: 9)

            if key1 == relativeMajor || key2 == relativeMinor {
                return true
            }
        }

        return false
    }

    /// Generate explanation for key detection
    private func generateKeyDetectionExplanation(detectedKeys: [DetectedKey], chords: [String]) -> String {
        guard let topKey = detectedKeys.first else {
            return "Unable to detect key from given chords."
        }

        var explanation = "Most likely key: \(topKey.fullKeyName) (\(Int(topKey.confidence * 100))% confidence)\n\n"

        explanation += "Reasoning:\n"
        for reason in topKey.reasons {
            explanation += "• \(reason)\n"
        }

        if detectedKeys.count > 1 {
            explanation += "\nAlternative possibilities:\n"
            for key in detectedKeys.dropFirst().prefix(2) {
                explanation += "• \(key.fullKeyName) (\(Int(key.confidence * 100))%)\n"
            }
        }

        return explanation
    }

    /// Analyze chord difficulty and capo options
    private func analyzeCapoDifficulty(chords: [String], key: String) -> CapoDifficulty {
        // Calculate original difficulty
        let originalDifficulty = calculateChordDifficulty(chords)

        // Try capo positions 1-7
        var bestCapo: Int? = nil
        var bestDifficulty = originalDifficulty
        var bestImprovement: Float = 0

        for capo in 1...7 {
            let transposedChords = chords.map { theoryEngine.transposeChord($0, by: -capo) }
            let capoedDifficulty = calculateChordDifficulty(transposedChords)

            let improvement = Float(originalDifficulty.score - capoedDifficulty.score) / Float(originalDifficulty.score)

            if improvement > bestImprovement {
                bestImprovement = improvement
                bestCapo = capo
                bestDifficulty = capoedDifficulty
            }
        }

        return CapoDifficulty(
            originalDifficulty: originalDifficulty,
            suggestedCapo: bestCapo,
            capoedDifficulty: bestCapo != nil ? bestDifficulty : nil,
            beforeChords: chords,
            afterChords: bestCapo != nil ? chords.map { theoryEngine.transposeChord($0, by: -(bestCapo!)) } : chords,
            improvementScore: bestImprovement
        )
    }

    /// Calculate overall difficulty of a chord progression
    private func calculateChordDifficulty(_ chords: [String]) -> ChordDifficulty {
        let difficultChords = ["B", "Bm", "F", "Fm", "F#", "F#m", "Bb", "Bbm"]
        let moderateChords = ["E", "Em", "A", "Am"]

        var difficultyScore = 0

        for chord in chords {
            let root = theoryEngine.extractChordRoot(chord)

            if difficultChords.contains(root) || difficultChords.contains(chord) {
                difficultyScore += 3
            } else if moderateChords.contains(root) || moderateChords.contains(chord) {
                difficultyScore += 2
            } else {
                difficultyScore += 1
            }

            // Add extra difficulty for extended chords
            if chord.contains("7") || chord.contains("9") || chord.contains("11") || chord.contains("13") {
                difficultyScore += 1
            }
        }

        let avgDifficulty = Float(difficultyScore) / Float(chords.count)

        if avgDifficulty < 1.5 {
            return .veryEasy
        } else if avgDifficulty < 2.0 {
            return .easy
        } else if avgDifficulty < 2.5 {
            return .moderate
        } else if avgDifficulty < 3.5 {
            return .difficult
        } else {
            return .veryDifficult
        }
    }

    /// Get all possible keys (major and minor)
    private func getAllKeys() -> [(key: String, scale: ScaleType)] {
        let roots = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
                     "Db", "Eb", "Gb", "Ab", "Bb"]

        var keys: [(key: String, scale: ScaleType)] = []

        for root in roots {
            keys.append((key: root, scale: .major))
            keys.append((key: "\(root)m", scale: .minor))
        }

        return keys
    }
}

// MARK: - MusicTheoryEngine Extension

extension MusicTheoryEngine {
    /// Get key signature for a key and scale
    func getKeySignature(for key: String, scale: ScaleType) -> (notes: [String], commonChords: [String]) {
        // Simplified - return basic scale
        let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        guard let rootIndex = chromaticScale.firstIndex(of: key.replacingOccurrences(of: "m", with: "")) else {
            return (notes: [], commonChords: [])
        }

        var notes: [String] = []
        var intervals: [Int]

        if scale == .major {
            // Major scale intervals: W-W-H-W-W-W-H
            intervals = [0, 2, 4, 5, 7, 9, 11]
        } else {
            // Natural minor scale intervals: W-H-W-W-H-W-W
            intervals = [0, 2, 3, 5, 7, 8, 10]
        }

        for interval in intervals {
            let noteIndex = (rootIndex + interval) % 12
            notes.append(chromaticScale[noteIndex])
        }

        // Generate common chords (simplified)
        let commonChords = notes.map { $0 } // Just root notes for now

        return (notes: notes, commonChords: commonChords)
    }
}
