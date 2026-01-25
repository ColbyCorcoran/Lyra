//
//  CapoOptimizationEngine.swift
//  Lyra
//
//  Engine for optimizing capo position for easier chord shapes
//  Part of Phase 7.9: Transpose Intelligence
//

import Foundation

/// Engine responsible for capo optimization and analysis
class CapoOptimizationEngine {

    // MARK: - Dependencies

    private let difficultyEngine: ChordDifficultyAnalysisEngine

    // MARK: - Constants

    private let maxCapoPosition = 7
    private let minImprovementThreshold: Float = 0.3 // Minimum improvement to suggest capo

    // MARK: - Initialization

    init(difficultyEngine: ChordDifficultyAnalysisEngine) {
        self.difficultyEngine = difficultyEngine
    }

    // MARK: - Optimal Capo Finding

    /// Find optimal capo position for easier playing
    /// - Parameters:
    ///   - content: Song content with chords
    ///   - skillLevel: Player's skill level
    ///   - userPreferences: User's capo usage preference (0.0-1.0)
    /// - Returns: Array of capo recommendations sorted by benefit
    func findOptimalCapo(
        content: String,
        skillLevel: SkillLevel,
        userPreferences: Float = 0.5
    ) -> [CapoRecommendation] {
        let capoOptions = difficultyEngine.compareCapoOptions(
            content: content,
            skillLevel: skillLevel,
            maxCapo: maxCapoPosition
        )

        var recommendations: [CapoRecommendation] = []

        for option in capoOptions {
            // Skip if no improvement or capo 0 (no capo)
            guard option.capo > 0 && option.improvement > minImprovementThreshold else {
                continue
            }

            let explanation = explainCapoBenefits(
                capoPosition: option.capo,
                difficulty: option.difficulty,
                improvement: option.improvement,
                content: content,
                skillLevel: skillLevel
            )

            let barreReduction = calculateBarreReduction(
                content: content,
                capoPosition: option.capo
            )

            // Calculate overall score (0-1)
            let score = calculateCapoScore(
                improvement: option.improvement,
                barreReduction: barreReduction,
                capoPosition: option.capo,
                userPreference: userPreferences
            )

            let recommendation = CapoRecommendation(
                capoPosition: option.capo,
                difficulty: option.difficulty,
                improvementScore: option.improvement,
                barreReduction: barreReduction,
                overallScore: score,
                explanation: explanation
            )

            recommendations.append(recommendation)
        }

        // Sort by overall score (highest first)
        return recommendations.sorted { $0.overallScore > $1.overallScore }
    }

    // MARK: - Benefit Explanation

    /// Generate human-readable explanation of capo benefits
    /// - Parameters:
    ///   - capoPosition: Capo fret position
    ///   - difficulty: Difficulty with capo
    ///   - improvement: Difficulty improvement
    ///   - content: Song content
    ///   - skillLevel: Player's skill level
    /// - Returns: Detailed explanation string
    func explainCapoBenefits(
        capoPosition: Int,
        difficulty: Float,
        improvement: Float,
        content: String,
        skillLevel: SkillLevel
    ) -> String {
        let originalChords = TransposeEngine.extractChords(from: content)
        let capoChords = originalChords.map { chord in
            TransposeEngine.transpose(chord, by: -capoPosition, preferSharps: true)
        }

        let barreReduction = calculateBarreReduction(content: content, capoPosition: capoPosition)
        let percentEasier = Int((improvement / 10.0) * 100)

        var explanation = "Capo on fret \(capoPosition) makes chords \(percentEasier)% easier to play. "

        if barreReduction > 0 {
            explanation += "Eliminates \(barreReduction) barre chord\(barreReduction == 1 ? "" : "s"). "
        }

        // Identify key chord improvements
        let beforeDifficult = difficultyEngine.getMostDifficultChords(
            content: content,
            skillLevel: skillLevel,
            count: 3
        )

        if let hardest = beforeDifficult.first {
            let transposed = TransposeEngine.transpose(
                hardest.chord,
                by: -capoPosition,
                preferSharps: true
            )
            explanation += "Transforms \(hardest.chord) into easier \(transposed). "
        }

        return explanation
    }

    // MARK: - Barre Chord Analysis

    /// Calculate barre chord reduction with capo
    /// - Parameters:
    ///   - content: Song content
    ///   - capoPosition: Capo fret position
    /// - Returns: Number of barre chords eliminated
    func calculateBarreReduction(
        content: String,
        capoPosition: Int
    ) -> Int {
        let originalChords = TransposeEngine.extractChords(from: content)
        let capoChords = originalChords.map { chord in
            TransposeEngine.transpose(chord, by: -capoPosition, preferSharps: true)
        }

        let originalBarreCount = difficultyEngine.countBarreChords(originalChords)
        let capoBarreCount = difficultyEngine.countBarreChords(capoChords)

        return max(0, originalBarreCount - capoBarreCount)
    }

    /// Get barre chord percentage reduction
    /// - Parameters:
    ///   - content: Song content
    ///   - capoPosition: Capo fret position
    /// - Returns: Percentage reduction (0.0-1.0)
    func barreChordReductionPercentage(
        content: String,
        capoPosition: Int
    ) -> Float {
        let originalChords = TransposeEngine.extractChords(from: content)
        guard !originalChords.isEmpty else { return 0.0 }

        let originalBarreCount = difficultyEngine.countBarreChords(originalChords)
        guard originalBarreCount > 0 else { return 0.0 }

        let reduction = calculateBarreReduction(content: content, capoPosition: capoPosition)
        return Float(reduction) / Float(originalBarreCount)
    }

    // MARK: - Capo Scoring

    /// Calculate overall capo score
    private func calculateCapoScore(
        improvement: Float,
        barreReduction: Int,
        capoPosition: Int,
        userPreference: Float
    ) -> Float {
        var score: Float = 0.0

        // Difficulty improvement component (50%)
        let improvementScore = min(improvement / 5.0, 1.0) // Normalize to 0-1
        score += improvementScore * 0.5

        // Barre reduction component (30%)
        let barreScore = min(Float(barreReduction) / 3.0, 1.0) // 3+ barre reductions = max score
        score += barreScore * 0.3

        // User preference component (15%)
        score += userPreference * 0.15

        // Capo position penalty (5%) - prefer lower capo positions
        let positionPenalty = Float(capoPosition) / Float(maxCapoPosition)
        score += (1.0 - positionPenalty) * 0.05

        return min(score, 1.0)
    }

    // MARK: - Quick Capo Check

    /// Check if capo would help for a specific song
    /// - Parameters:
    ///   - content: Song content
    ///   - skillLevel: Player's skill level
    /// - Returns: True if capo is recommended
    func shouldUseCapo(
        content: String,
        skillLevel: SkillLevel
    ) -> Bool {
        let recommendations = findOptimalCapo(content: content, skillLevel: skillLevel)
        return !recommendations.isEmpty
    }

    /// Get best capo position (nil if no capo recommended)
    /// - Parameters:
    ///   - content: Song content
    ///   - skillLevel: Player's skill level
    /// - Returns: Best capo position or nil
    func getBestCapoPosition(
        content: String,
        skillLevel: SkillLevel
    ) -> Int? {
        let recommendations = findOptimalCapo(content: content, skillLevel: skillLevel)
        return recommendations.first?.capoPosition
    }
}

// MARK: - Capo Recommendation Model

/// A capo position recommendation with detailed analysis
struct CapoRecommendation: Identifiable, Codable {
    var id: UUID
    var capoPosition: Int
    var difficulty: Float // 0-10 scale
    var improvementScore: Float // How much easier
    var barreReduction: Int // Number of barre chords eliminated
    var overallScore: Float // 0-1 overall benefit score
    var explanation: String

    init(
        id: UUID = UUID(),
        capoPosition: Int,
        difficulty: Float,
        improvementScore: Float,
        barreReduction: Int,
        overallScore: Float,
        explanation: String
    ) {
        self.id = id
        self.capoPosition = capoPosition
        self.difficulty = difficulty
        self.improvementScore = improvementScore
        self.barreReduction = barreReduction
        self.overallScore = overallScore
        self.explanation = explanation
    }

    var difficultyDescription: String {
        switch difficulty {
        case 0..<2.0: return "Very Easy"
        case 2.0..<4.0: return "Easy"
        case 4.0..<6.0: return "Moderate"
        case 6.0..<8.0: return "Difficult"
        default: return "Very Difficult"
        }
    }

    var improvementDescription: String {
        let percent = Int((improvementScore / 10.0) * 100)
        return "\(percent)% easier"
    }
}
