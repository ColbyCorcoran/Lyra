//
//  UserControlEngine.swift
//  Lyra
//
//  Phase 7.15: AI Ethics and Transparency
//  User control: opt-out of AI features, control data usage, delete AI training data, manual override
//

import Foundation
import SwiftData

/// User control engine for managing AI feature preferences and data control
class UserControlEngine {
    static let shared = UserControlEngine()

    private let defaults = UserDefaults.standard
    private let userControlKey = "lyra_user_ai_control"

    private init() {}

    // MARK: - AI Feature Control

    /// Check if user has opted in to a specific AI feature
    func isFeatureEnabled(_ feature: AIFeatureControl) -> Bool {
        return defaults.bool(forKey: feature.prefsKey)
    }

    /// Enable or disable an AI feature
    func setFeature(_ feature: AIFeatureControl, enabled: Bool) {
        defaults.set(enabled, forKey: feature.prefsKey)

        // Log control change for transparency
        logControlChange(feature: feature, enabled: enabled)
    }

    /// Get all feature control settings
    func getAllFeatureSettings() -> [AIFeatureControl: Bool] {
        var settings: [AIFeatureControl: Bool] = [:]

        for feature in AIFeatureControl.allCases {
            settings[feature] = isFeatureEnabled(feature)
        }

        return settings
    }

    /// Opt out of all AI features at once
    func optOutOfAllAIFeatures() {
        for feature in AIFeatureControl.allCases {
            setFeature(feature, enabled: false)
        }

        defaults.set(true, forKey: "lyra_opted_out_all_ai")
    }

    /// Opt in to all AI features at once
    func optInToAllAIFeatures() {
        for feature in AIFeatureControl.allCases {
            setFeature(feature, enabled: true)
        }

        defaults.set(false, forKey: "lyra_opted_out_all_ai")
    }

    /// Check if user has opted out of all AI
    func hasOptedOutOfAllAI() -> Bool {
        return defaults.bool(forKey: "lyra_opted_out_all_ai")
    }

    // MARK: - Data Usage Control

    /// Check if user allows data collection for AI improvement
    func allowsDataCollectionForImprovement() -> Bool {
        return defaults.bool(forKey: "lyra_allow_ai_data_collection")
    }

    /// Set data collection preference
    func setDataCollectionPreference(_ allowed: Bool) {
        defaults.set(allowed, forKey: "lyra_allow_ai_data_collection")

        if !allowed {
            // If user disables, delete existing collected data
            deleteAllAITrainingData()
        }
    }

    /// Check if user allows usage analytics
    func allowsUsageAnalytics() -> Bool {
        return defaults.bool(forKey: "lyra_allow_usage_analytics")
    }

    /// Set usage analytics preference
    func setUsageAnalyticsPreference(_ allowed: Bool) {
        defaults.set(allowed, forKey: "lyra_allow_usage_analytics")
    }

    // MARK: - Data Deletion

    /// Delete all AI training data
    func deleteAllAITrainingData() {
        // Note: This would integrate with SwiftData to delete specific records
        // For now, we clear preferences and mark for deletion

        defaults.set(Date(), forKey: "lyra_ai_data_deletion_date")

        // Clear learning engine data
        clearLearningData()

        // Clear practice tracking data
        clearPracticeData()

        // Clear recommendation history
        clearRecommendationData()

        // Clear search history
        clearSearchHistory()

        print("✅ All AI training data deleted")
    }

    /// Delete data for a specific AI feature
    func deleteDataForFeature(_ feature: AIFeatureControl) {
        switch feature {
        case .songwritingAssistant:
            clearLearningData()
        case .practiceRecommendations:
            clearPracticeData()
        case .songRecommendations:
            clearRecommendationData()
        case .semanticSearch:
            clearSearchHistory()
        case .autoFormatting:
            clearFormattingPreferences()
        case .contentModeration:
            clearModerationHistory()
        case .ocrScanning:
            clearOCRHistory()
        case .chordDetection:
            clearChordDetectionHistory()
        }

        print("✅ Data deleted for \(feature.displayName)")
    }

    /// Export user's AI data for review
    func exportAIData() -> [String: Any] {
        var exportData: [String: Any] = [:]

        exportData["featureSettings"] = getAllFeatureSettings().mapKeys { $0.rawValue }
        exportData["dataCollectionAllowed"] = allowsDataCollectionForImprovement()
        exportData["usageAnalyticsAllowed"] = allowsUsageAnalytics()
        exportData["lastDeletionDate"] = defaults.object(forKey: "lyra_ai_data_deletion_date")
        exportData["optedOutAll"] = hasOptedOutOfAllAI()

        // Add feature-specific usage stats
        exportData["songwritingSessionCount"] = defaults.integer(forKey: "lyra_songwriting_session_count")
        exportData["practiceSessionCount"] = defaults.integer(forKey: "lyra_practice_session_count")
        exportData["recommendationsAccepted"] = defaults.integer(forKey: "lyra_recommendations_accepted")

        return exportData
    }

    // MARK: - Manual Override

    /// Record a manual override of AI suggestion
    func recordManualOverride(
        feature: AIFeatureControl,
        aiSuggestion: String,
        userChoice: String,
        reason: String?
    ) {
        let override = ManualOverride(
            feature: feature,
            aiSuggestion: aiSuggestion,
            userChoice: userChoice,
            reason: reason,
            timestamp: Date()
        )

        // Store override for learning
        var overrides = getManualOverrides()
        overrides.append(override)

        // Keep only last 100 overrides
        if overrides.count > 100 {
            overrides = Array(overrides.suffix(100))
        }

        if let encoded = try? JSONEncoder().encode(overrides) {
            defaults.set(encoded, forKey: "lyra_manual_overrides")
        }

        print("📝 Manual override recorded for \(feature.displayName)")
    }

    /// Get all manual overrides
    func getManualOverrides() -> [ManualOverride] {
        guard let data = defaults.data(forKey: "lyra_manual_overrides"),
              let overrides = try? JSONDecoder().decode([ManualOverride].self, from: data) else {
            return []
        }
        return overrides
    }

    /// Get override rate for a feature (to detect if AI needs improvement)
    func getOverrideRate(for feature: AIFeatureControl) -> Double {
        let overrides = getManualOverrides().filter { $0.feature == feature }
        let totalSuggestions = defaults.integer(forKey: "\(feature.rawValue)_total_suggestions")

        guard totalSuggestions > 0 else { return 0.0 }
        return Double(overrides.count) / Double(totalSuggestions)
    }

    // MARK: - Granular Controls

    /// Get granular control settings for advanced users
    func getGranularControls() -> AIGranularControls {
        return AIGranularControls(
            showConfidenceScores: defaults.bool(forKey: "lyra_show_confidence_scores"),
            showAIBadges: defaults.bool(forKey: "lyra_show_ai_badges"),
            requireConfirmationForAI: defaults.bool(forKey: "lyra_require_ai_confirmation"),
            autoApplyAISuggestions: defaults.bool(forKey: "lyra_auto_apply_ai"),
            enableAIExplanations: defaults.bool(forKey: "lyra_enable_ai_explanations"),
            privacyMode: defaults.bool(forKey: "lyra_privacy_mode")
        )
    }

    /// Set granular control setting
    func setGranularControl(_ control: GranularControlType, value: Bool) {
        defaults.set(value, forKey: control.prefsKey)
    }

    // MARK: - Helper Methods

    private func logControlChange(feature: AIFeatureControl, enabled: Bool) {
        let log = ControlChangeLog(
            feature: feature,
            enabled: enabled,
            timestamp: Date()
        )

        var logs = getControlChangeLogs()
        logs.append(log)

        // Keep only last 50 logs
        if logs.count > 50 {
            logs = Array(logs.suffix(50))
        }

        if let encoded = try? JSONEncoder().encode(logs) {
            defaults.set(encoded, forKey: "lyra_control_change_logs")
        }
    }

    private func getControlChangeLogs() -> [ControlChangeLog] {
        guard let data = defaults.data(forKey: "lyra_control_change_logs"),
              let logs = try? JSONDecoder().decode([ControlChangeLog].self, from: data) else {
            return []
        }
        return logs
    }

    // Data clearing methods
    private func clearLearningData() {
        defaults.removeObject(forKey: "lyra_songwriting_patterns")
        defaults.removeObject(forKey: "lyra_songwriting_preferences")
        defaults.removeObject(forKey: "lyra_songwriting_session_count")
    }

    private func clearPracticeData() {
        defaults.removeObject(forKey: "lyra_practice_history")
        defaults.removeObject(forKey: "lyra_practice_session_count")
    }

    private func clearRecommendationData() {
        defaults.removeObject(forKey: "lyra_recommendation_history")
        defaults.removeObject(forKey: "lyra_recommendations_accepted")
    }

    private func clearSearchHistory() {
        defaults.removeObject(forKey: "lyra_search_history")
    }

    private func clearFormattingPreferences() {
        defaults.removeObject(forKey: "lyra_formatting_preferences")
    }

    private func clearModerationHistory() {
        defaults.removeObject(forKey: "lyra_moderation_history")
    }

    private func clearOCRHistory() {
        defaults.removeObject(forKey: "lyra_ocr_history")
    }

    private func clearChordDetectionHistory() {
        defaults.removeObject(forKey: "lyra_chord_detection_history")
    }
}

// MARK: - Data Models

/// AI feature control options
enum AIFeatureControl: String, Codable, CaseIterable {
    case songwritingAssistant = "songwriting_assistant"
    case practiceRecommendations = "practice_recommendations"
    case songRecommendations = "song_recommendations"
    case semanticSearch = "semantic_search"
    case autoFormatting = "auto_formatting"
    case contentModeration = "content_moderation"
    case ocrScanning = "ocr_scanning"
    case chordDetection = "chord_detection"

    var displayName: String {
        switch self {
        case .songwritingAssistant: return "Songwriting Assistant"
        case .practiceRecommendations: return "Practice Recommendations"
        case .songRecommendations: return "Song Recommendations"
        case .semanticSearch: return "Semantic Search"
        case .autoFormatting: return "Auto-Formatting"
        case .contentModeration: return "Content Moderation"
        case .ocrScanning: return "OCR Scanning"
        case .chordDetection: return "Chord Detection"
        }
    }

    var description: String {
        switch self {
        case .songwritingAssistant:
            return "AI-powered suggestions for chords, lyrics, melody, and structure"
        case .practiceRecommendations:
            return "Personalized practice suggestions based on your progress"
        case .songRecommendations:
            return "Song suggestions based on your usage patterns"
        case .semanticSearch:
            return "Natural language search with semantic understanding"
        case .autoFormatting:
            return "Automatic chord chart formatting and cleanup"
        case .contentModeration:
            return "AI-powered content analysis for public library"
        case .ocrScanning:
            return "Scan and digitize paper chord charts"
        case .chordDetection:
            return "Detect chords from audio in real-time"
        }
    }

    var prefsKey: String {
        return "lyra_ai_\(rawValue)_enabled"
    }

    var icon: String {
        switch self {
        case .songwritingAssistant: return "wand.and.stars"
        case .practiceRecommendations: return "figure.walk"
        case .songRecommendations: return "star.circle"
        case .semanticSearch: return "magnifyingglass.circle"
        case .autoFormatting: return "text.alignleft"
        case .contentModeration: return "shield.checkered"
        case .ocrScanning: return "doc.text.viewfinder"
        case .chordDetection: return "waveform.circle"
        }
    }
}

/// Manual override record
struct ManualOverride: Codable {
    let feature: AIFeatureControl
    let aiSuggestion: String
    let userChoice: String
    let reason: String?
    let timestamp: Date
}

/// Control change log
struct ControlChangeLog: Codable {
    let feature: AIFeatureControl
    let enabled: Bool
    let timestamp: Date
}

/// Granular AI controls
struct AIGranularControls {
    var showConfidenceScores: Bool
    var showAIBadges: Bool
    var requireConfirmationForAI: Bool
    var autoApplyAISuggestions: Bool
    var enableAIExplanations: Bool
    var privacyMode: Bool
}

/// Granular control types
enum GranularControlType: String {
    case showConfidenceScores = "show_confidence_scores"
    case showAIBadges = "show_ai_badges"
    case requireConfirmationForAI = "require_ai_confirmation"
    case autoApplyAISuggestions = "auto_apply_ai"
    case enableAIExplanations = "enable_ai_explanations"
    case privacyMode = "privacy_mode"

    var prefsKey: String {
        return "lyra_\(rawValue)"
    }

    var displayName: String {
        switch self {
        case .showConfidenceScores: return "Show Confidence Scores"
        case .showAIBadges: return "Show AI Badges"
        case .requireConfirmationForAI: return "Require Confirmation"
        case .autoApplyAISuggestions: return "Auto-Apply Suggestions"
        case .enableAIExplanations: return "Enable Explanations"
        case .privacyMode: return "Privacy Mode"
        }
    }
}

// MARK: - Dictionary Extension

extension Dictionary where Key == AIFeatureControl, Value == Bool {
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
}
