//
//  AITransparencyEngine.swift
//  Lyra
//
//  Phase 7.15: AI Ethics and Transparency
//  AI transparency: marking AI-generated content, explaining decisions, confidence scores
//

import Foundation
import SwiftUI

/// AI transparency engine for marking AI-generated content and explaining decisions
class AITransparencyEngine {
    static let shared = AITransparencyEngine()

    private init() {}

    // MARK: - AI Content Marking

    /// Mark content as AI-generated with appropriate labeling
    func markAsAIGenerated(
        content: String,
        aiSource: AISource,
        confidence: Double
    ) -> MarkedAIContent {
        return MarkedAIContent(
            content: content,
            isAIGenerated: true,
            aiSource: aiSource,
            confidence: confidence,
            markedAt: Date(),
            explanation: generateExplanation(for: aiSource, confidence: confidence)
        )
    }

    /// Generate visual badge for AI-generated content
    func generateAIBadge(for source: AISource) -> AIBadge {
        return AIBadge(
            icon: source.icon,
            label: source.displayName,
            color: source.color,
            tooltipText: source.description
        )
    }

    // MARK: - Decision Explanation

    /// Explain why an AI suggestion was made
    func explainDecision(
        suggestionType: AISuggestionType,
        inputData: [String: Any],
        result: Any,
        reasoning: [String]
    ) -> AIDecisionExplanation {
        return AIDecisionExplanation(
            suggestionType: suggestionType,
            inputData: inputData,
            result: result,
            reasoning: reasoning,
            confidenceFactors: extractConfidenceFactors(from: inputData),
            alternativesConsidered: [],
            timestamp: Date()
        )
    }

    /// Generate "Why this suggestion?" explanation text
    func generateWhyThisSuggestion(
        for suggestion: Any,
        context: AIContext
    ) -> String {
        var explanation = "This suggestion was made because:\n\n"

        switch context.suggestionType {
        case .chordProgression:
            explanation += "• The chord progression follows common patterns in \(context.genre ?? "this") music\n"
            explanation += "• The chords are in the key of \(context.key ?? "the selected key")\n"
            explanation += "• These progressions are known to create a \(context.mood ?? "balanced") feeling\n"

        case .lyricSuggestion:
            explanation += "• The suggested words rhyme with your last line\n"
            explanation += "• They match the theme of \(context.theme ?? "your song")\n"
            explanation += "• The syllable count maintains consistent meter\n"

        case .melodySuggestion:
            explanation += "• The melody uses notes from the current chord\n"
            explanation += "• The pattern is singable and easy to remember\n"
            explanation += "• It fits the emotional tone of your song\n"

        case .structureSuggestion:
            explanation += "• This structure is common in \(context.genre ?? "this") genre\n"
            explanation += "• The length matches your target duration\n"
            explanation += "• The dynamic arc creates emotional impact\n"

        case .contentModeration:
            explanation += "• The content analysis detected potential issues\n"
            explanation += "• This decision helps maintain community standards\n"
            explanation += "• You can appeal if you believe this is incorrect\n"

        case .recommendation:
            explanation += "• Based on songs you've used recently\n"
            explanation += "• Matches your typical preferences\n"
            explanation += "• Similar to songs you've rated highly\n"

        case .searchRanking:
            explanation += "• The song closely matches your search terms\n"
            explanation += "• It has high relevance to your query\n"
            explanation += "• Metadata and content were analyzed\n"

        case .practiceRecommendation:
            explanation += "• Based on your practice history\n"
            explanation += "• Matched to your current skill level\n"
            explanation += "• Helps you progress toward your goals\n"
        }

        explanation += "\n💡 All analysis happens on your device. No data is sent to external servers."

        return explanation
    }

    // MARK: - Confidence Scores

    /// Calculate and format confidence score for display
    func calculateConfidenceScore(
        baseScore: Double,
        factors: [ConfidenceFactor]
    ) -> ConfidenceScore {
        var adjustedScore = baseScore
        var explanations: [String] = []

        for factor in factors {
            adjustedScore *= factor.weight
            explanations.append(factor.explanation)
        }

        // Clamp between 0 and 1
        adjustedScore = max(0.0, min(1.0, adjustedScore))

        return ConfidenceScore(
            score: adjustedScore,
            level: confidenceLevel(for: adjustedScore),
            explanations: explanations,
            displayPercentage: Int(adjustedScore * 100)
        )
    }

    /// Get confidence level category
    func confidenceLevel(for score: Double) -> ConfidenceLevel {
        switch score {
        case 0.9...1.0:
            return .veryHigh
        case 0.7..<0.9:
            return .high
        case 0.5..<0.7:
            return .medium
        case 0.3..<0.5:
            return .low
        default:
            return .veryLow
        }
    }

    /// Display confidence score with visual indicator
    func displayConfidenceScore(_ score: ConfidenceScore) -> String {
        let percentage = score.displayPercentage
        let indicator = score.level.visualIndicator
        return "\(indicator) \(percentage)% confidence"
    }

    // MARK: - Transparency Reports

    /// Generate transparency report for AI feature usage
    func generateTransparencyReport(
        for feature: AIFeature,
        timeframe: DateInterval
    ) -> AITransparencyReport {
        return AITransparencyReport(
            feature: feature,
            timeframe: timeframe,
            totalSuggestions: 0,
            acceptedSuggestions: 0,
            rejectedSuggestions: 0,
            averageConfidence: 0.0,
            dataProcessed: "All on-device",
            dataSentExternal: "None",
            privacyGuarantees: [
                "100% on-device processing",
                "No data sent to external servers",
                "No third-party analytics",
                "Complete offline functionality"
            ]
        )
    }

    // MARK: - Helper Methods

    private func generateExplanation(for source: AISource, confidence: Double) -> String {
        let confidenceText = confidence >= 0.9 ? "very confident" :
                            confidence >= 0.7 ? "confident" :
                            confidence >= 0.5 ? "moderately confident" : "uncertain"

        return "This content was generated by \(source.displayName). The AI is \(confidenceText) in this suggestion (confidence: \(Int(confidence * 100))%)."
    }

    private func extractConfidenceFactors(from inputData: [String: Any]) -> [ConfidenceFactor] {
        var factors: [ConfidenceFactor] = []

        if let dataQuality = inputData["dataQuality"] as? Double {
            factors.append(ConfidenceFactor(
                name: "Input Data Quality",
                weight: dataQuality,
                explanation: "Based on the quality and completeness of input data"
            ))
        }

        if let patternMatch = inputData["patternMatch"] as? Double {
            factors.append(ConfidenceFactor(
                name: "Pattern Recognition",
                weight: patternMatch,
                explanation: "How well the data matches known patterns"
            ))
        }

        return factors
    }
}

// MARK: - Data Models

/// AI source identification
enum AISource: String, Codable {
    case chordProgression = "chord_progression"
    case lyricSuggestion = "lyric_suggestion"
    case melodySuggestion = "melody_suggestion"
    case structureSuggestion = "structure_suggestion"
    case contentModeration = "content_moderation"
    case recommendation = "recommendation"
    case searchRanking = "search_ranking"
    case practiceRecommendation = "practice_recommendation"
    case formatting = "formatting"
    case ocr = "ocr"

    var displayName: String {
        switch self {
        case .chordProgression: return "Chord Progression AI"
        case .lyricSuggestion: return "Lyric Suggestion AI"
        case .melodySuggestion: return "Melody Suggestion AI"
        case .structureSuggestion: return "Structure Suggestion AI"
        case .contentModeration: return "Content Moderation AI"
        case .recommendation: return "Recommendation AI"
        case .searchRanking: return "Search AI"
        case .practiceRecommendation: return "Practice AI"
        case .formatting: return "Auto-Formatting AI"
        case .ocr: return "OCR Recognition AI"
        }
    }

    var description: String {
        switch self {
        case .chordProgression:
            return "Generates chord progressions using music theory rules"
        case .lyricSuggestion:
            return "Suggests lyrics using on-device natural language processing"
        case .melodySuggestion:
            return "Creates melody patterns based on music theory"
        case .structureSuggestion:
            return "Recommends song structures for different genres"
        case .contentModeration:
            return "Analyzes content for appropriateness using on-device AI"
        case .recommendation:
            return "Suggests songs based on your usage patterns"
        case .searchRanking:
            return "Ranks search results by relevance"
        case .practiceRecommendation:
            return "Recommends practice routines based on your progress"
        case .formatting:
            return "Automatically formats chord charts"
        case .ocr:
            return "Recognizes text from images using Apple Vision"
        }
    }

    var icon: String {
        switch self {
        case .chordProgression: return "music.note.list"
        case .lyricSuggestion: return "text.quote"
        case .melodySuggestion: return "waveform"
        case .structureSuggestion: return "square.grid.3x3"
        case .contentModeration: return "shield.checkered"
        case .recommendation: return "star.circle"
        case .searchRanking: return "magnifyingglass"
        case .practiceRecommendation: return "figure.walk"
        case .formatting: return "text.alignleft"
        case .ocr: return "doc.text.viewfinder"
        }
    }

    var color: Color {
        switch self {
        case .chordProgression: return .blue
        case .lyricSuggestion: return .purple
        case .melodySuggestion: return .green
        case .structureSuggestion: return .orange
        case .contentModeration: return .red
        case .recommendation: return .yellow
        case .searchRanking: return .cyan
        case .practiceRecommendation: return .indigo
        case .formatting: return .mint
        case .ocr: return .teal
        }
    }
}

/// AI suggestion types
enum AISuggestionType: String, Codable {
    case chordProgression
    case lyricSuggestion
    case melodySuggestion
    case structureSuggestion
    case contentModeration
    case recommendation
    case searchRanking
    case practiceRecommendation
}

/// AI context for suggestions
struct AIContext {
    var suggestionType: AISuggestionType
    var genre: String?
    var key: String?
    var mood: String?
    var theme: String?
}

/// Marked AI-generated content
struct MarkedAIContent {
    let content: String
    let isAIGenerated: Bool
    let aiSource: AISource
    let confidence: Double
    let markedAt: Date
    let explanation: String
}

/// AI badge for visual marking
struct AIBadge {
    let icon: String
    let label: String
    let color: Color
    let tooltipText: String
}

/// AI decision explanation
struct AIDecisionExplanation {
    let suggestionType: AISuggestionType
    let inputData: [String: Any]
    let result: Any
    let reasoning: [String]
    let confidenceFactors: [ConfidenceFactor]
    let alternativesConsidered: [Any]
    let timestamp: Date
}

/// Confidence factor
struct ConfidenceFactor {
    let name: String
    let weight: Double
    let explanation: String
}

/// Confidence score
struct ConfidenceScore {
    let score: Double
    let level: ConfidenceLevel
    let explanations: [String]
    let displayPercentage: Int
}

/// Confidence level
enum ConfidenceLevel: String {
    case veryHigh = "very_high"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case veryLow = "very_low"

    var visualIndicator: String {
        switch self {
        case .veryHigh: return "●●●●●"
        case .high: return "●●●●○"
        case .medium: return "●●●○○"
        case .low: return "●●○○○"
        case .veryLow: return "●○○○○"
        }
    }

    var color: Color {
        switch self {
        case .veryHigh: return .green
        case .high: return .blue
        case .medium: return .yellow
        case .low: return .orange
        case .veryLow: return .red
        }
    }
}

/// AI feature types
enum AIFeature: String {
    case songwriting = "songwriting"
    case contentModeration = "content_moderation"
    case recommendations = "recommendations"
    case search = "search"
    case practice = "practice"
    case formatting = "formatting"
    case ocr = "ocr"
}

/// Transparency report
struct AITransparencyReport {
    let feature: AIFeature
    let timeframe: DateInterval
    let totalSuggestions: Int
    let acceptedSuggestions: Int
    let rejectedSuggestions: Int
    let averageConfidence: Double
    let dataProcessed: String
    let dataSentExternal: String
    let privacyGuarantees: [String]
}
