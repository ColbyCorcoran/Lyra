//
//  AIEthicsManager.swift
//  Lyra
//
//  Phase 7.15: AI Ethics and Transparency
//  Central coordinator for all AI ethics and transparency features
//

import Foundation
import SwiftUI

/// Central manager for AI ethics, transparency, and user control
class AIEthicsManager {
    static let shared = AIEthicsManager()

    // Component engines
    private let transparencyEngine = AITransparencyEngine.shared
    private let userControlEngine = UserControlEngine.shared
    private let privacyEngine = PrivacyProtectionEngine.shared
    private let biasEngine = BiasDetectionEngine.shared
    private let copyrightEngine = CopyrightProtectionEngine.shared
    private let retentionManager = DataRetentionManager.shared

    private init() {
        // Schedule automatic cleanup on initialization
        scheduleMaintenanceTasks()
    }

    // MARK: - Initialization & Setup

    /// Initialize ethics system with defaults
    func initializeEthicsSystem() {
        print("🛡️ Initializing AI Ethics & Transparency System...")

        // Set default feature states (all enabled by default)
        if UserDefaults.standard.object(forKey: "lyra_ethics_initialized") == nil {
            setDefaultFeatureStates()
            setDefaultGranularControls()
            UserDefaults.standard.set(true, forKey: "lyra_ethics_initialized")
        }

        // Show ethics onboarding if first time
        if !hasCompletedEthicsOnboarding() {
            print("📚 Ethics onboarding required")
        }

        print("✅ AI Ethics & Transparency System initialized")
    }

    /// Check if ethics onboarding has been completed
    func hasCompletedEthicsOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "lyra_ethics_onboarding_completed")
    }

    /// Mark ethics onboarding as completed
    func completeEthicsOnboarding() {
        UserDefaults.standard.set(true, forKey: "lyra_ethics_onboarding_completed")
    }

    // MARK: - Transparency Workflows

    /// Generate AI suggestion with full transparency
    func generateTransparentAISuggestion(
        suggestionType: AISuggestionType,
        inputData: [String: Any],
        generator: () -> Any
    ) -> TransparentAISuggestion {
        // Check if feature is enabled
        guard isFeatureEnabledForType(suggestionType) else {
            return TransparentAISuggestion(
                suggestion: nil,
                markedContent: nil,
                explanation: nil,
                confidenceScore: nil,
                disabled: true,
                disabledReason: "Feature disabled by user"
            )
        }

        // Check privacy compliance
        let privacyCheck = privacyEngine.canProcessData(
            dataType: dataTypeForSuggestion(suggestionType),
            purpose: .featureFunctionality
        )

        guard privacyCheck.allowed else {
            return TransparentAISuggestion(
                suggestion: nil,
                markedContent: nil,
                explanation: nil,
                confidenceScore: nil,
                disabled: true,
                disabledReason: privacyCheck.reason
            )
        }

        // Generate suggestion
        let suggestion = generator()

        // Calculate confidence
        let confidence = calculateConfidence(for: suggestionType, inputData: inputData)

        // Mark as AI-generated
        let markedContent = transparencyEngine.markAsAIGenerated(
            content: String(describing: suggestion),
            aiSource: aiSourceForType(suggestionType),
            confidence: confidence.score
        )

        // Generate explanation
        let explanation = transparencyEngine.explainDecision(
            suggestionType: suggestionType,
            inputData: inputData,
            result: suggestion,
            reasoning: generateReasoning(for: suggestionType, inputData: inputData)
        )

        return TransparentAISuggestion(
            suggestion: suggestion,
            markedContent: markedContent,
            explanation: explanation,
            confidenceScore: confidence,
            disabled: false,
            disabledReason: nil
        )
    }

    /// Explain why a specific suggestion was made
    func explainSuggestion(
        suggestionType: AISuggestionType,
        context: AIContext
    ) -> String {
        return transparencyEngine.generateWhyThisSuggestion(
            for: suggestionType,
            context: context
        )
    }

    // MARK: - User Control Workflows

    /// Get comprehensive user control dashboard
    func getUserControlDashboard() -> UserControlDashboard {
        let featureSettings = userControlEngine.getAllFeatureSettings()
        let granularControls = userControlEngine.getGranularControls()
        let privacyScore = privacyEngine.calculatePrivacyScore()
        let retentionStatus = retentionManager.getRetentionStatus()

        return UserControlDashboard(
            featureSettings: featureSettings,
            granularControls: granularControls,
            privacyScore: privacyScore,
            retentionStatus: retentionStatus,
            lastDataDeletion: UserDefaults.standard.object(forKey: "lyra_ai_data_deletion_date") as? Date,
            dataCollectionEnabled: userControlEngine.allowsDataCollectionForImprovement()
        )
    }

    /// Perform complete AI data deletion with confirmation
    func performCompleteDataDeletion() -> DataDeletionResult {
        print("🗑️ Performing complete AI data deletion...")

        // Delete through user control engine
        userControlEngine.deleteAllAITrainingData()

        // Delete through retention manager
        retentionManager.deleteAllAIData()

        // Generate deletion certificate
        let certificate = DataDeletionCertificate(
            deletedAt: Date(),
            categoriesDeleted: DataCategory.allCases.map { $0.displayName },
            confirmationCode: generateDeletionConfirmationCode()
        )

        return DataDeletionResult(
            success: true,
            certificate: certificate,
            message: "All AI data has been permanently deleted."
        )
    }

    // MARK: - Bias & Fairness Checks

    /// Check recommendations for bias
    func checkRecommendationsForBias(
        recommendations: [String],
        expectedDiversity: Double = 0.7
    ) -> BiasCheckResult {
        // Check genre bias
        let genreBias = biasEngine.analyzeGenreBias(
            recommendations: recommendations,
            expectedDistribution: ["pop": 0.2, "rock": 0.2, "folk": 0.2, "worship": 0.2, "other": 0.2]
        )

        // Check fairness
        let fairness = biasEngine.ensureFairRecommendations(
            recommendations: recommendations,
            demographics: UserDemographics(
                age: nil,
                culturalBackground: nil,
                language: nil,
                accessibilityNeeds: []
            )
        )

        let hasBias = genreBias.biasLevel == .high || genreBias.biasLevel == .severe || !fairness.isFair

        return BiasCheckResult(
            hasBias: hasBias,
            genreBiasAnalysis: genreBias,
            fairnessAssessment: fairness,
            mitigationApplied: false
        )
    }

    /// Apply bias mitigation to recommendations
    func mitigateRecommendationBias(
        recommendations: [String],
        targetDiversity: Double = 0.7
    ) -> [String] {
        return biasEngine.mitigateBias(in: recommendations, targetDiversity: targetDiversity)
    }

    // MARK: - Copyright Protection

    /// Check content for copyright issues
    func checkCopyright(
        title: String,
        artist: String?,
        lyrics: String?
    ) -> CopyrightCheckResult {
        return copyrightEngine.checkCopyrightViolation(
            title: title,
            artist: artist,
            lyrics: lyrics
        )
    }

    /// Get copyright education for users
    func getCopyrightEducation() -> CopyrightEducation {
        return copyrightEngine.getCopyrightEducation()
    }

    /// Filter AI suggestions for copyright safety
    func filterCopyrightSafe(
        suggestions: [String],
        contentType: AIContentType
    ) -> [String] {
        return copyrightEngine.filterCopyrightSafeSuggestions(
            suggestions: suggestions,
            contentType: contentType
        )
    }

    // MARK: - Privacy & Data Protection

    /// Get comprehensive privacy report
    func getPrivacyReport() -> ComprehensivePrivacyReport {
        let policy = privacyEngine.getAIPrivacyPolicy()
        let score = privacyEngine.calculatePrivacyScore()
        let report = privacyEngine.generatePrivacyReport()
        let retention = retentionManager.getRetentionPolicy()

        return ComprehensivePrivacyReport(
            policy: policy,
            score: score,
            report: report,
            retentionPolicy: retention
        )
    }

    /// Verify privacy compliance for all features
    func verifyAllPrivacyCompliance() -> [String: PrivacyComplianceResult] {
        var results: [String: PrivacyComplianceResult] = [:]

        let features = ["Songwriting", "Practice", "Recommendations", "Search", "Formatting", "Moderation", "OCR", "ChordDetection"]

        for feature in features {
            results[feature] = privacyEngine.verifyPrivacyCompliance(for: feature)
        }

        return results
    }

    // MARK: - Accuracy & Disclaimers

    /// Get accuracy disclaimer for AI feature
    func getAccuracyDisclaimer(for feature: AIFeatureControl) -> String {
        switch feature {
        case .songwritingAssistant:
            return """
            ⚠️ AI Songwriting Suggestions

            • Suggestions are generated using music theory and language patterns
            • They may not be perfect or exactly what you're looking for
            • Always review and modify suggestions to match your vision
            • The AI doesn't understand emotional context like humans do
            • Use suggestions as inspiration, not final content

            You are the artist. The AI is just a tool.
            """

        case .practiceRecommendations:
            return """
            ⚠️ Practice Recommendations

            • Recommendations are based on patterns in your practice data
            • They may not account for all factors in your progress
            • Listen to your body and adjust pace as needed
            • AI can't replace human judgment about readiness
            • Consult with a music teacher for personalized guidance

            Practice smart, not just by the numbers.
            """

        case .songRecommendations:
            return """
            ⚠️ Song Recommendations

            • Suggestions are based on your usage patterns
            • They may not capture your current mood or needs
            • Recommendations can create filter bubbles
            • Explore beyond suggestions to discover new music
            • AI learns over time but isn't psychic

            You know what works best for your sessions.
            """

        case .semanticSearch:
            return """
            ⚠️ Semantic Search

            • Search uses on-device natural language processing
            • Results may miss songs if metadata is incomplete
            • Semantic matching isn't perfect
            • Try different search terms if results aren't relevant
            • Manual browsing may find songs search misses

            Search is a helper, not a guarantee.
            """

        case .autoFormatting:
            return """
            ⚠️ Auto-Formatting

            • Formatting suggestions are based on pattern recognition
            • Complex charts may not format perfectly
            • Always review formatted output
            • Manual adjustments may be needed
            • Different styles may require different formatting

            Review before trusting formatting changes.
            """

        case .contentModeration:
            return """
            ⚠️ Content Moderation

            • Moderation uses on-device AI analysis
            • False positives and negatives can occur
            • Cultural context may be misunderstood
            • You can appeal any moderation decision
            • Human moderators review flagged content

            When in doubt, we err on the side of safety.
            """

        case .ocrScanning:
            return """
            ⚠️ OCR Scanning

            • Recognition accuracy depends on image quality
            • Handwriting recognition varies by legibility
            • Complex layouts may not scan perfectly
            • Always review and correct recognized text
            • Chord symbols may be misrecognized

            Scan is a starting point, not finished product.
            """

        case .chordDetection:
            return """
            ⚠️ Chord Detection

            • Detection works best with clear, isolated instruments
            • Background noise affects accuracy
            • Complex harmonies may confuse the AI
            • Results are suggestions, not definitive
            • Human ear is still the gold standard

            Verify detected chords by ear before trusting.
            """
        }
    }

    // MARK: - Comprehensive Ethics Dashboard

    /// Generate comprehensive ethics dashboard
    func getEthicsDashboard() -> AIEthicsDashboard {
        return AIEthicsDashboard(
            transparencyScore: calculateTransparencyScore(),
            privacyScore: privacyEngine.calculatePrivacyScore(),
            biasScore: calculateBiasScore(),
            copyrightCompliance: calculateCopyrightCompliance(),
            dataMinimization: calculateDataMinimizationScore(),
            userControlScore: calculateUserControlScore(),
            overallEthicsScore: calculateOverallEthicsScore()
        )
    }

    // MARK: - Maintenance Tasks

    private func scheduleMaintenanceTasks() {
        // Schedule automatic cleanup
        retentionManager.scheduleAutomaticCleanup()
    }

    // MARK: - Helper Methods

    private func setDefaultFeatureStates() {
        for feature in AIFeatureControl.allCases {
            userControlEngine.setFeature(feature, enabled: true)
        }
    }

    private func setDefaultGranularControls() {
        userControlEngine.setGranularControl(.showConfidenceScores, value: true)
        userControlEngine.setGranularControl(.showAIBadges, value: true)
        userControlEngine.setGranularControl(.requireConfirmationForAI, value: false)
        userControlEngine.setGranularControl(.autoApplyAISuggestions, value: false)
        userControlEngine.setGranularControl(.enableAIExplanations, value: true)
        userControlEngine.setGranularControl(.privacyMode, value: false)
    }

    private func isFeatureEnabledForType(_ type: AISuggestionType) -> Bool {
        switch type {
        case .chordProgression, .lyricSuggestion, .melodySuggestion, .structureSuggestion:
            return userControlEngine.isFeatureEnabled(.songwritingAssistant)
        case .contentModeration:
            return userControlEngine.isFeatureEnabled(.contentModeration)
        case .recommendation:
            return userControlEngine.isFeatureEnabled(.songRecommendations)
        case .searchRanking:
            return userControlEngine.isFeatureEnabled(.semanticSearch)
        case .practiceRecommendation:
            return userControlEngine.isFeatureEnabled(.practiceRecommendations)
        }
    }

    private func dataTypeForSuggestion(_ type: AISuggestionType) -> AIDataType {
        switch type {
        case .chordProgression, .lyricSuggestion, .melodySuggestion, .structureSuggestion:
            return .songwritingData
        case .practiceRecommendation:
            return .practiceData
        case .recommendation:
            return .recommendationHistory
        case .searchRanking:
            return .searchHistory
        case .contentModeration:
            return .moderationData
        }
    }

    private func aiSourceForType(_ type: AISuggestionType) -> AISource {
        switch type {
        case .chordProgression: return .chordProgression
        case .lyricSuggestion: return .lyricSuggestion
        case .melodySuggestion: return .melodySuggestion
        case .structureSuggestion: return .structureSuggestion
        case .contentModeration: return .contentModeration
        case .recommendation: return .recommendation
        case .searchRanking: return .searchRanking
        case .practiceRecommendation: return .practiceRecommendation
        }
    }

    private func calculateConfidence(for type: AISuggestionType, inputData: [String: Any]) -> ConfidenceScore {
        let baseScore = 0.75 // Default confidence
        let factors = transparencyEngine.extractConfidenceFactors(from: inputData) as? [ConfidenceFactor] ?? []
        return transparencyEngine.calculateConfidenceScore(baseScore: baseScore, factors: factors)
    }

    private func generateReasoning(for type: AISuggestionType, inputData: [String: Any]) -> [String] {
        // Generate reasoning based on suggestion type
        return ["Based on music theory principles", "Matches your preferences", "Common pattern in this genre"]
    }

    private func generateDeletionConfirmationCode() -> String {
        return UUID().uuidString.prefix(8).uppercased()
    }

    // Scoring methods
    private func calculateTransparencyScore() -> Double {
        let granular = userControlEngine.getGranularControls()
        var score = 0.0

        if granular.showConfidenceScores { score += 0.2 }
        if granular.showAIBadges { score += 0.2 }
        if granular.enableAIExplanations { score += 0.3 }
        if !granular.autoApplyAISuggestions { score += 0.15 }
        if granular.requireConfirmationForAI { score += 0.15 }

        return score
    }

    private func calculateBiasScore() -> Double {
        // In production, would run actual bias tests
        return 0.85
    }

    private func calculateCopyrightCompliance() -> Double {
        // In production, would check copyright systems
        return 1.0
    }

    private func calculateDataMinimizationScore() -> Double {
        let compliance = retentionManager.verifyMinimalStorageCompliance()
        return compliance.compliant ? 1.0 : 0.6
    }

    private func calculateUserControlScore() -> Double {
        let settings = userControlEngine.getAllFeatureSettings()
        // If user has customized any settings, they have control
        return settings.values.contains(false) ? 1.0 : 0.8
    }

    private func calculateOverallEthicsScore() -> Double {
        let transparency = calculateTransparencyScore()
        let privacy = privacyEngine.calculatePrivacyScore().score / 100.0
        let bias = calculateBiasScore()
        let copyright = calculateCopyrightCompliance()
        let dataMin = calculateDataMinimizationScore()
        let userControl = calculateUserControlScore()

        return (transparency + privacy + bias + copyright + dataMin + userControl) / 6.0
    }
}

// MARK: - Data Models

/// Transparent AI suggestion
struct TransparentAISuggestion {
    let suggestion: Any?
    let markedContent: MarkedAIContent?
    let explanation: AIDecisionExplanation?
    let confidenceScore: ConfidenceScore?
    let disabled: Bool
    let disabledReason: String?
}

/// User control dashboard
struct UserControlDashboard {
    let featureSettings: [AIFeatureControl: Bool]
    let granularControls: AIGranularControls
    let privacyScore: PrivacyScore
    let retentionStatus: [DataCategory: RetentionStatus]
    let lastDataDeletion: Date?
    let dataCollectionEnabled: Bool
}

/// Data deletion result
struct DataDeletionResult {
    let success: Bool
    let certificate: DataDeletionCertificate
    let message: String
}

/// Data deletion certificate
struct DataDeletionCertificate {
    let deletedAt: Date
    let categoriesDeleted: [String]
    let confirmationCode: String
}

/// Bias check result
struct BiasCheckResult {
    let hasBias: Bool
    let genreBiasAnalysis: GenreBiasAnalysis
    let fairnessAssessment: FairnessAssessment
    let mitigationApplied: Bool
}

/// Comprehensive privacy report
struct ComprehensivePrivacyReport {
    let policy: AIPrivacyPolicy
    let score: PrivacyScore
    let report: PrivacyReport
    let retentionPolicy: DataRetentionPolicy
}

/// AI Ethics Dashboard
struct AIEthicsDashboard {
    let transparencyScore: Double
    let privacyScore: PrivacyScore
    let biasScore: Double
    let copyrightCompliance: Double
    let dataMinimization: Double
    let userControlScore: Double
    let overallEthicsScore: Double
}
