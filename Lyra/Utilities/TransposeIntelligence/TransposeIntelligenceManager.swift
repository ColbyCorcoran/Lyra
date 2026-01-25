//
//  TransposeIntelligenceManager.swift
//  Lyra
//
//  Main orchestration manager for AI-enhanced transpose intelligence
//  Part of Phase 7.9: Transpose Intelligence
//

import Foundation
import SwiftData
import Observation

/// Main manager coordinating all transpose intelligence engines
@MainActor
@Observable
class TransposeIntelligenceManager {

    // MARK: - Properties

    private let modelContext: ModelContext

    // Engines
    private let voiceRangeEngine: VoiceRangeAnalysisEngine
    private let difficultyEngine: ChordDifficultyAnalysisEngine
    private let capoEngine: CapoOptimizationEngine
    private var learningEngine: TransposeLearningEngine?
    private var multiInstrumentEngine: MultiInstrumentOptimizationEngine?
    private var batchEngine: BatchTransposeEngine?

    // Cache
    private var analysisCache: [String: CachedAnalysis] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    // Integration points
    private let keyLearningEngine: KeyLearningEngine
    private let skillAssessmentEngine: SkillAssessmentEngine?

    // MARK: - Multi-Factor Weights

    private struct ScoringWeights {
        static let voiceRange: Float = 0.30
        static let chordDifficulty: Float = 0.25
        static let capoAvailability: Float = 0.15
        static let userPreferences: Float = 0.20
        static let bandCompatibility: Float = 0.10
    }

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        keyLearningEngine: KeyLearningEngine,
        skillAssessmentEngine: SkillAssessmentEngine? = nil
    ) {
        self.modelContext = modelContext
        self.keyLearningEngine = keyLearningEngine
        self.skillAssessmentEngine = skillAssessmentEngine

        // Initialize engines
        self.voiceRangeEngine = VoiceRangeAnalysisEngine()
        self.difficultyEngine = ChordDifficultyAnalysisEngine()
        self.capoEngine = CapoOptimizationEngine(difficultyEngine: difficultyEngine)

        // Initialize learning engines (will be set up later)
        self.learningEngine = TransposeLearningEngine(modelContext: modelContext)
        self.multiInstrumentEngine = MultiInstrumentOptimizationEngine(
            voiceRangeEngine: voiceRangeEngine,
            difficultyEngine: difficultyEngine
        )
        self.batchEngine = BatchTransposeEngine(modelContext: modelContext)
    }

    // MARK: - Feature 1: Smart Transpose Recommendations

    /// Get smart transpose recommendations with multi-factor analysis
    /// - Parameters:
    ///   - song: Song to analyze
    ///   - context: Optional context (vocal range, band members, etc.)
    /// - Returns: Smart transpose result with recommendations
    func getSmartTransposeRecommendations(
        song: Song,
        context: TransposeContext? = nil
    ) -> SmartTransposeResult {
        // Check cache first
        let cacheKey = "\(song.id.uuidString)-\(Date().timeIntervalSince1970 / cacheTimeout)"
        if let cached = analysisCache[cacheKey] {
            if Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
                return cached.result
            }
        }

        // Build context
        let analysisContext = context ?? buildDefaultContext(for: song)

        // Analyze all possible transpositions
        var recommendations: [TransposeRecommendation] = []

        for semitones in -11...11 {
            if let recommendation = analyzeTransposition(
                song: song,
                semitones: semitones,
                context: analysisContext
            ) {
                recommendations.append(recommendation)
            }
        }

        // Sort by overall score (highest first)
        recommendations.sort { $0.overallScore > $1.overallScore }

        // Take top 5
        recommendations = Array(recommendations.prefix(5))

        let result = SmartTransposeResult(
            recommendations: recommendations,
            contextUsed: analysisContext
        )

        // Cache the result
        analysisCache[cacheKey] = CachedAnalysis(result: result, timestamp: Date())

        return result
    }

    // MARK: - Feature 2: Voice Range Matching

    /// Analyze voice match for a song
    /// - Parameters:
    ///   - song: Song to analyze
    ///   - vocalRange: User's vocal range
    /// - Returns: Vocal range fit with recommendations
    func analyzeVoiceMatch(
        song: Song,
        vocalRange: VocalRange
    ) -> VoiceMatchAnalysis {
        guard let songRange = voiceRangeEngine.analyzeSongRange(content: song.content) else {
            return VoiceMatchAnalysis(
                currentFit: nil,
                recommendations: [],
                optimalSemitones: 0
            )
        }

        let currentFit = voiceRangeEngine.matchToVocalRange(
            songRange: songRange,
            vocalRange: vocalRange
        )

        let optimalKeys = voiceRangeEngine.findOptimalKeyForVoice(
            songContent: song.content,
            currentKey: song.currentKey,
            vocalRange: vocalRange
        )

        let recommendations = optimalKeys.prefix(5).map { option in
            (semitones: option.semitones, score: option.score)
        }

        return VoiceMatchAnalysis(
            currentFit: currentFit,
            recommendations: Array(recommendations),
            optimalSemitones: optimalKeys.first?.semitones ?? 0
        )
    }

    // MARK: - Feature 3: Chord Difficulty Analysis

    /// Get chord difficulty analysis for a song
    /// - Parameters:
    ///   - song: Song to analyze
    ///   - skillLevel: Player's skill level
    /// - Returns: Difficulty analysis with easier key suggestions
    func getChordDifficultyAnalysis(
        song: Song,
        skillLevel: SkillLevel
    ) -> DifficultyAnalysisResult {
        let currentDifficulty = difficultyEngine.averageDifficulty(
            chords: TransposeEngine.extractChords(from: song.content),
            skillLevel: skillLevel
        )

        let easiestKeys = difficultyEngine.findEasiestKey(
            content: song.content,
            currentKey: song.currentKey,
            skillLevel: skillLevel
        )

        let mostDifficult = difficultyEngine.getMostDifficultChords(
            content: song.content,
            skillLevel: skillLevel,
            count: 5
        )

        return DifficultyAnalysisResult(
            currentDifficulty: currentDifficulty,
            easiestKeys: Array(easiestKeys.prefix(5)),
            mostDifficultChords: mostDifficult
        )
    }

    // MARK: - Feature 4: Capo Optimization

    /// Get capo optimization recommendations
    /// - Parameters:
    ///   - song: Song to analyze
    ///   - skillLevel: Player's skill level
    /// - Returns: Capo recommendations
    func getCapoOptimizations(
        song: Song,
        skillLevel: SkillLevel
    ) -> [CapoRecommendation] {
        let userPrefs = keyLearningEngine.getUserPreferences()
        return capoEngine.findOptimalCapo(
            content: song.content,
            skillLevel: skillLevel,
            userPreferences: userPrefs.capoUsageFrequency
        )
    }

    // MARK: - Private Analysis Methods

    /// Analyze a specific transposition
    private func analyzeTransposition(
        song: Song,
        semitones: Int,
        context: TransposeContext
    ) -> TransposeRecommendation? {
        let targetKey = TransposeEngine.transpose(
            song.currentKey ?? "C",
            by: semitones,
            preferSharps: true
        )

        // Calculate individual scores
        var voiceScore: Float? = nil
        if let vocalRange = context.vocalRange {
            voiceScore = calculateVoiceScore(
                song: song,
                semitones: semitones,
                vocalRange: vocalRange
            )
        }

        let difficultyScore = calculateDifficultyScore(
            song: song,
            semitones: semitones,
            skillLevel: context.skillLevel
        )

        let capoScore = calculateCapoScore(
            song: song,
            semitones: semitones,
            skillLevel: context.skillLevel
        )

        let preferenceScore = calculatePreferenceScore(
            targetKey: targetKey,
            semitones: semitones
        )

        var bandScore: Float? = nil
        if let bandMembers = context.bandMembers, !bandMembers.isEmpty {
            bandScore = calculateBandScore(
                song: song,
                semitones: semitones,
                bandMembers: bandMembers
            )
        }

        // Calculate overall score (0-100)
        let overallScore = calculateOverallScore(
            voiceScore: voiceScore,
            difficultyScore: difficultyScore,
            capoScore: capoScore,
            preferenceScore: preferenceScore,
            bandScore: bandScore
        )

        // Generate benefits and warnings
        let benefits = generateBenefits(
            voiceScore: voiceScore,
            difficultyScore: difficultyScore,
            capoScore: capoScore
        )

        let warnings = generateWarnings(
            song: song,
            semitones: semitones,
            context: context
        )

        // Generate theory explanation
        let theory = generateTheoryExplanation(
            fromKey: song.currentKey ?? "C",
            toKey: targetKey,
            semitones: semitones
        )

        // Confidence score
        let confidence = calculateConfidence(
            voiceScore: voiceScore,
            difficultyScore: difficultyScore,
            preferenceScore: preferenceScore
        )

        return TransposeRecommendation(
            targetKey: targetKey,
            semitones: semitones,
            confidenceScore: confidence,
            overallScore: overallScore,
            voiceRangeScore: voiceScore,
            difficultyScore: difficultyScore,
            capoScore: capoScore,
            userPreferenceScore: preferenceScore,
            bandFitnessScore: bandScore,
            benefits: benefits,
            warnings: warnings,
            theoryExplanation: theory,
            suggestedCapo: nil // TODO: Calculate suggested capo
        )
    }

    /// Calculate voice range score for transposition
    private func calculateVoiceScore(
        song: Song,
        semitones: Int,
        vocalRange: VocalRange
    ) -> Float {
        guard let songRange = voiceRangeEngine.analyzeSongRange(content: song.content) else {
            return 0.5 // Neutral score if can't analyze
        }

        // Transpose the song range
        let transposedRange = transposeSongRange(songRange, by: semitones)
        let fit = voiceRangeEngine.matchToVocalRange(
            songRange: transposedRange,
            vocalRange: vocalRange
        )

        // Convert fit to 0-1 score
        if fit.fitsWithinRange && fit.lowestIsComfortable && fit.highestIsComfortable {
            return 1.0
        } else if fit.fitsWithinRange {
            return 0.75
        } else if let _ = fit.optimalTransposition {
            return 0.4
        } else {
            return 0.0
        }
    }

    /// Calculate difficulty score for transposition
    private func calculateDifficultyScore(
        song: Song,
        semitones: Int,
        skillLevel: SkillLevel
    ) -> Float {
        let originalChords = TransposeEngine.extractChords(from: song.content)
        let transposedChords = originalChords.map { chord in
            TransposeEngine.transpose(chord, by: semitones, preferSharps: true)
        }

        return difficultyEngine.averageDifficulty(
            chords: transposedChords,
            skillLevel: skillLevel
        )
    }

    /// Calculate capo score for transposition
    private func calculateCapoScore(
        song: Song,
        semitones: Int,
        skillLevel: SkillLevel
    ) -> Float? {
        // Only consider capo for downward transpositions
        guard semitones < 0 else { return nil }

        let capoPosition = (12 + semitones) % 12
        guard capoPosition > 0 && capoPosition <= 7 else { return nil }

        let improvement = difficultyEngine.getDifficultyReduction(
            content: song.content,
            capoPosition: capoPosition,
            skillLevel: skillLevel
        )

        return min(improvement / 5.0, 1.0) // Normalize to 0-1
    }

    /// Calculate user preference score
    private func calculatePreferenceScore(
        targetKey: String,
        semitones: Int
    ) -> Float {
        let prediction = keyLearningEngine.predictKeyPreference(key: targetKey)

        // Prefer smaller transpositions
        let transposePenalty = Float(abs(semitones)) / 12.0
        let transposeScore = 1.0 - transposePenalty

        // Combine: 70% preference, 30% transpose distance
        return (prediction * 0.7) + (transposeScore * 0.3)
    }

    /// Calculate band fitness score
    private func calculateBandScore(
        song: Song,
        semitones: Int,
        bandMembers: [MusicianProfile]
    ) -> Float {
        // TODO: Implement with MultiInstrumentOptimizationEngine
        return 0.5 // Placeholder
    }

    /// Calculate overall weighted score
    private func calculateOverallScore(
        voiceScore: Float?,
        difficultyScore: Float,
        capoScore: Float?,
        preferenceScore: Float,
        bandScore: Float?
    ) -> Float {
        // Convert difficulty to inverse (lower difficulty = higher score)
        let diffNormalized = 1.0 - (difficultyScore / 10.0)

        var weightedSum: Float = 0.0
        var totalWeight: Float = 0.0

        if let voice = voiceScore {
            weightedSum += voice * ScoringWeights.voiceRange
            totalWeight += ScoringWeights.voiceRange
        }

        weightedSum += diffNormalized * ScoringWeights.chordDifficulty
        totalWeight += ScoringWeights.chordDifficulty

        if let capo = capoScore {
            weightedSum += capo * ScoringWeights.capoAvailability
            totalWeight += ScoringWeights.capoAvailability
        }

        weightedSum += preferenceScore * ScoringWeights.userPreferences
        totalWeight += ScoringWeights.userPreferences

        if let band = bandScore {
            weightedSum += band * ScoringWeights.bandCompatibility
            totalWeight += ScoringWeights.bandCompatibility
        }

        // Normalize and convert to 0-100 scale
        return (weightedSum / totalWeight) * 100.0
    }

    /// Calculate confidence score
    private func calculateConfidence(
        voiceScore: Float?,
        difficultyScore: Float,
        preferenceScore: Float
    ) -> Float {
        var confidence: Float = 0.7 // Base confidence

        if voiceScore != nil {
            confidence += 0.15 // Higher confidence with voice data
        }

        if preferenceScore > 0.7 {
            confidence += 0.1 // User likely to prefer this
        }

        if difficultyScore < 3.0 {
            confidence += 0.05 // Easy chords boost confidence
        }

        return min(confidence, 1.0)
    }

    // MARK: - Helper Methods

    /// Build default context from user preferences
    private func buildDefaultContext(for song: Song) -> TransposeContext {
        let userPrefs = keyLearningEngine.getUserPreferences()

        // Get skill level
        var skillLevel: SkillLevel = .intermediate
        if let skillEngine = skillAssessmentEngine {
            // Fetch practice history
            let descriptor = FetchDescriptor<PracticeSession>()
            if let sessions = try? modelContext.fetch(descriptor) {
                skillLevel = skillEngine.estimateSkillLevel(history: sessions)
            }
        }

        return TransposeContext(
            vocalRange: userPrefs.vocalRange,
            skillLevel: skillLevel,
            bandMembers: nil,
            setlistContext: nil
        )
    }

    /// Transpose a song range
    private func transposeSongRange(
        _ range: SongRangeAnalysis,
        by semitones: Int
    ) -> SongRangeAnalysis {
        let newLow = MusicalNote.fromMIDI(range.lowestNote.midiNumber + semitones)
        let newHigh = MusicalNote.fromMIDI(range.highestNote.midiNumber + semitones)

        return SongRangeAnalysis(
            lowestNote: newLow,
            highestNote: newHigh,
            rangeInSemitones: range.rangeInSemitones
        )
    }

    /// Generate benefits list
    private func generateBenefits(
        voiceScore: Float?,
        difficultyScore: Float,
        capoScore: Float?
    ) -> [TransposeBenefit] {
        var benefits: [TransposeBenefit] = []

        if let voice = voiceScore, voice > 0.8 {
            benefits.append(TransposeBenefit(
                category: .vocalFit,
                description: "Perfect fit for your vocal range",
                impact: voice,
                icon: "mic.fill"
            ))
        }

        if difficultyScore < 4.0 {
            benefits.append(TransposeBenefit(
                category: .easierChords,
                description: "Much easier chord shapes",
                impact: 1.0 - (difficultyScore / 10.0),
                icon: "guitars"
            ))
        }

        if let capo = capoScore, capo > 0.5 {
            benefits.append(TransposeBenefit(
                category: .capoOption,
                description: "Capo option available for easier playing",
                impact: capo,
                icon: "bookmark.fill"
            ))
        }

        return benefits
    }

    /// Generate warnings list
    private func generateWarnings(
        song: Song,
        semitones: Int,
        context: TransposeContext
    ) -> [TransposeWarning] {
        var warnings: [TransposeWarning] = []

        if abs(semitones) > 6 {
            warnings.append(TransposeWarning(
                severity: .caution,
                issue: "Large transposition may change the song's character",
                mitigation: "Try listening to the new key before committing"
            ))
        }

        return warnings
    }

    /// Generate theory explanation
    private func generateTheoryExplanation(
        fromKey: String,
        toKey: String,
        semitones: Int
    ) -> TheoryExplanation {
        let circleOfFifths = ["C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F"]
        let distance = calculateCircleDistance(fromKey, toKey, circle: circleOfFifths)

        var relationship: KeyRelationship = .distantKeys
        if semitones == 0 {
            relationship = .same
        } else if distance <= 2 {
            relationship = .circleOfFifths
        } else if distance >= 6 {
            relationship = .distantKeys
        }

        let keySignature = getKeySignature(toKey)

        return TheoryExplanation(
            summary: generateTheorySummary(distance: distance, semitones: semitones),
            keyRelationship: relationship,
            circleOfFifthsDistance: distance,
            keySignature: keySignature,
            educationalNotes: []
        )
    }

    private func calculateCircleDistance(
        _ key1: String,
        _ key2: String,
        circle: [String]
    ) -> Int {
        guard let idx1 = circle.firstIndex(of: key1),
              let idx2 = circle.firstIndex(of: key2) else { return 0 }
        let distance = abs(idx1 - idx2)
        return min(distance, 12 - distance)
    }

    private func generateTheorySummary(distance: Int, semitones: Int) -> String {
        if semitones == 0 {
            return "No transposition needed."
        } else if distance <= 1 {
            return "Close key relationship - smooth transition."
        } else if distance <= 3 {
            return "Moderate key change - still familiar."
        } else {
            return "Significant key change - new tonal center."
        }
    }

    private func getKeySignature(_ key: String) -> String {
        // Simplified key signatures
        let signatures: [String: String] = [
            "C": "No sharps or flats",
            "G": "1 sharp (F#)",
            "D": "2 sharps (F#, C#)",
            "A": "3 sharps (F#, C#, G#)",
            "E": "4 sharps (F#, C#, G#, D#)",
            "F": "1 flat (Bb)",
            "Bb": "2 flats (Bb, Eb)",
            "Eb": "3 flats (Bb, Eb, Ab)"
        ]
        return signatures[key] ?? "Unknown"
    }

    /// Clear analysis cache
    func clearCache() {
        analysisCache.removeAll()
    }
}

// MARK: - Supporting Types

/// Cached analysis result
private struct CachedAnalysis {
    let result: SmartTransposeResult
    let timestamp: Date
}

/// Voice match analysis result
struct VoiceMatchAnalysis {
    var currentFit: VocalRangeFit?
    var recommendations: [(semitones: Int, score: Float)]
    var optimalSemitones: Int
}

/// Difficulty analysis result
struct DifficultyAnalysisResult {
    var currentDifficulty: Float
    var easiestKeys: [(semitones: Int, difficulty: Float)]
    var mostDifficultChords: [(chord: String, difficulty: Float)]
}
