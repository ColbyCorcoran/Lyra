//
//  KeyLearningEngine.swift
//  Lyra
//
//  Learns user preferences for keys and adapts recommendations
//  Part of Phase 7.3: Key Intelligence
//

import Foundation

/// Learns and adapts to user's key preferences over time
class KeyLearningEngine {

    // MARK: - Properties

    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "userKeyPreferences"

    // MARK: - Preferences Management

    /// Get current user preferences
    func getUserPreferences() -> UserKeyPreferences {
        if let data = userDefaults.data(forKey: preferencesKey),
           let prefs = try? JSONDecoder().decode(UserKeyPreferences.self, from: data) {
            return prefs
        }

        // Return default preferences
        return UserKeyPreferences()
    }

    /// Save user preferences
    func savePreferences(_ preferences: UserKeyPreferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: preferencesKey)
        }
    }

    // MARK: - Learning

    /// Record that user used a song in a specific key
    func recordKeyUsage(_ key: String) {
        var prefs = getUserPreferences()
        prefs.favoriteKeys[key, default: 0] += 1
        prefs.lastUpdated = Date()
        savePreferences(prefs)
    }

    /// Update user's vocal range
    func updateVocalRange(_ range: VocalRange) {
        var prefs = getUserPreferences()
        prefs.vocalRange = range
        prefs.preferredVoiceType = range.voiceType
        prefs.lastUpdated = Date()
        savePreferences(prefs)
    }

    /// Record capo usage
    func recordCapoUsage(used: Bool) {
        var prefs = getUserPreferences()

        // Weighted average
        if used {
            prefs.capoUsageFrequency = prefs.capoUsageFrequency * 0.9 + 0.1
        } else {
            prefs.capoUsageFrequency = prefs.capoUsageFrequency * 0.9
        }

        prefs.lastUpdated = Date()
        savePreferences(prefs)
    }

    /// Update average chord difficulty user plays
    func recordChordDifficulty(_ difficulty: ChordDifficulty) {
        var prefs = getUserPreferences()
        prefs.averageKeyDifficulty = difficulty
        prefs.lastUpdated = Date()
        savePreferences(prefs)
    }

    // MARK: - Recommendations

    /// Get personalized key recommendations based on learning
    func getPersonalizedRecommendations(count: Int = 5) -> [String] {
        let prefs = getUserPreferences()

        // Sort favorite keys by usage
        let sortedKeys = prefs.favoriteKeys.sorted { $0.value > $1.value }

        return sortedKeys.prefix(count).map { $0.key }
    }

    /// Predict if user will like a key
    func predictKeyPreference(key: String) -> Float {
        let prefs = getUserPreferences()

        // Check usage history
        let usageCount = prefs.favoriteKeys[key] ?? 0
        let maxUsage = prefs.favoriteKeys.values.max() ?? 1

        return Float(usageCount) / Float(maxUsage)
    }

    /// Get insights about user's key preferences
    func getKeyInsights() -> KeyInsights {
        let prefs = getUserPreferences()

        let mostUsedKey = prefs.mostUsedKey
        let totalSongs = prefs.favoriteKeys.values.reduce(0, +)
        let prefersCapo = prefs.capoUsageFrequency > 0.5

        return KeyInsights(
            mostUsedKey: mostUsedKey,
            totalSongsTracked: totalSongs,
            preferredVoiceType: prefs.preferredVoiceType,
            vocalRange: prefs.vocalRange,
            prefersCapo: prefersCapo,
            averageDifficulty: prefs.averageKeyDifficulty
        )
    }
}

// MARK: - Key Insights

struct KeyInsights {
    var mostUsedKey: String?
    var totalSongsTracked: Int
    var preferredVoiceType: VoiceType?
    var vocalRange: VocalRange?
    var prefersCapo: Bool
    var averageDifficulty: ChordDifficulty
}
