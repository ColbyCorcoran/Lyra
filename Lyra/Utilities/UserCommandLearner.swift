//
//  UserCommandLearner.swift
//  Lyra
//
//  Learns user's command patterns and improves accuracy over time
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import SwiftData

/// Learns and adapts to user's command style and vocabulary
@MainActor
class UserCommandLearner {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let userID: String
    private var vocabulary: UserCommandVocabulary
    private let minUsageForLearning = 3

    // MARK: - Initialization

    init(modelContext: ModelContext, userID: String = "default") {
        self.modelContext = modelContext
        self.userID = userID
        self.vocabulary = Self.loadOrCreateVocabulary(modelContext: modelContext, userID: userID)
    }

    // MARK: - Learning

    /// Learn from successful command
    func learnFromSuccess(command: VoiceCommand, action: CommandAction) {
        // Extract and learn patterns
        let pattern = extractPattern(from: command.rawText, intent: command.getIntent())

        // Update or create pattern
        if let existingPattern = findPattern(pattern.patternText) {
            existingPattern.recordUsage(success: true)
        } else {
            modelContext.insert(pattern)
        }

        // Learn custom terms
        learnCustomTerms(from: command)

        // Update preferred phrasing
        updatePreferredPhrasing(for: command.getIntent(), text: command.rawText)
    }

    /// Learn from failed command
    func learnFromFailure(command: VoiceCommand, feedback: CommandFeedback) {
        guard let pattern = findPattern(command.rawText) else { return }

        pattern.recordUsage(success: false)

        // If pattern has low success rate, consider removing it
        if pattern.successRate < 0.3 && pattern.usageCount > 5 {
            modelContext.delete(pattern)
        }
    }

    /// Learn from correction
    func learnFromCorrection(
        original: VoiceCommand,
        corrected: CommandIntent,
        correctedEntities: [CommandEntity]? = nil
    ) {
        // Create new pattern with corrected intent
        let pattern = CommandPattern(
            patternText: original.rawText,
            intent: corrected,
            entityMappings: extractEntityMappings(correctedEntities ?? original.getEntities())
        )

        pattern.usageCount = 1
        modelContext.insert(pattern)

        // Store custom term mapping if entities were corrected
        if let corrected = correctedEntities {
            learnEntityCorrections(original: original.getEntities(), corrected: corrected)
        }
    }

    // MARK: - Pattern Extraction

    /// Extract learnable pattern from command
    private func extractPattern(from text: String, intent: CommandIntent) -> CommandPattern {
        // Tokenize and generalize
        let generalized = generalizePattern(text)

        // Extract entity positions
        let entities = EntityExtractor().extractEntities(text, intent: intent)
        let mappings = extractEntityMappings(entities)

        return CommandPattern(
            patternText: generalized,
            intent: intent,
            entityMappings: mappings
        )
    }

    /// Generalize pattern by replacing specific values with placeholders
    private func generalizePattern(_ text: String) -> String {
        var pattern = text.lowercased()

        // Replace song titles with placeholder
        pattern = pattern.replacingOccurrences(
            of: #"(?<=find |show |go to )[\w\s]+"#,
            with: "{songName}",
            options: .regularExpression
        )

        // Replace keys with placeholder
        pattern = pattern.replacingOccurrences(
            of: #"[A-G][#b]?m?"#,
            with: "{key}",
            options: .regularExpression
        )

        // Replace numbers with placeholder
        pattern = pattern.replacingOccurrences(
            of: #"\d+"#,
            with: "{number}",
            options: .regularExpression
        )

        // Replace set names with placeholder
        pattern = pattern.replacingOccurrences(
            of: #"(?<=to |set |called )[\w\s]+"#,
            with: "{setName}",
            options: .regularExpression
        )

        return pattern
    }

    /// Extract entity type mappings
    private func extractEntityMappings(_ entities: [CommandEntity]) -> [String: CommandEntity.EntityType] {
        var mappings: [String: CommandEntity.EntityType] = [:]

        for entity in entities {
            let placeholder = getPlaceholder(for: entity.type)
            mappings[placeholder] = entity.type
        }

        return mappings
    }

    /// Get placeholder for entity type
    private func getPlaceholder(for type: CommandEntity.EntityType) -> String {
        switch type {
        case .songTitle: return "{songName}"
        case .musicalKey: return "{key}"
        case .number: return "{number}"
        case .setName: return "{setName}"
        case .tempo: return "{tempo}"
        case .artistName: return "{artist}"
        default: return "{\(type.rawValue)}"
        }
    }

    // MARK: - Custom Terms

    /// Learn custom terms from command
    private func learnCustomTerms(from command: VoiceCommand) {
        let entities = command.getEntities()

        for entity in entities {
            // Check if this is a non-standard term
            if isCustomTerm(entity.value) {
                // Store mapping to standard term
                if let standard = findStandardTerm(for: entity.value) {
                    vocabulary.addCustomTerm(from: entity.value, to: standard)
                }
            }
        }
    }

    /// Check if term is custom (non-standard)
    private func isCustomTerm(_ term: String) -> Bool {
        // In real implementation, check against dictionary
        // For now, simple heuristic
        return term.contains("'") || term.split(separator: " ").count > 3
    }

    /// Find standard term for custom term
    private func findStandardTerm(for custom: String) -> String? {
        // In real implementation, use similarity matching
        // For now, return the custom term
        return custom
    }

    /// Learn entity corrections
    private func learnEntityCorrections(
        original: [CommandEntity],
        corrected: [CommandEntity]
    ) {
        // Map original entity values to corrected ones
        for (orig, corr) in zip(original, corrected) {
            if orig.value != corr.value {
                vocabulary.addCustomTerm(from: orig.value, to: corr.value)
            }
        }
    }

    // MARK: - Preferred Phrasing

    /// Update preferred phrasing for intent
    private func updatePreferredPhrasing(for intent: CommandIntent, text: String) {
        // Store common phrasings for each intent
        // This helps suggest better ways to phrase commands
    }

    // MARK: - Pattern Retrieval

    /// Find pattern by text
    private func findPattern(_ text: String) -> CommandPattern? {
        let generalized = generalizePattern(text)

        let descriptor = FetchDescriptor<CommandPattern>(
            predicate: #Predicate { pattern in
                pattern.patternText == generalized
            }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// Get user's most used patterns
    func getMostUsedPatterns(limit: Int = 10) -> [CommandPattern] {
        let descriptor = FetchDescriptor<CommandPattern>(
            predicate: #Predicate { pattern in
                pattern.userID == nil || pattern.userID == userID
            },
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        guard let patterns = try? modelContext.fetch(descriptor) else {
            return []
        }

        return Array(patterns.prefix(limit))
    }

    /// Get patterns for specific intent
    func getPatternsForIntent(_ intent: CommandIntent, limit: Int = 5) -> [CommandPattern] {
        let descriptor = FetchDescriptor<CommandPattern>(
            predicate: #Predicate { pattern in
                pattern.intent == intent.rawValue &&
                (pattern.userID == nil || pattern.userID == userID)
            },
            sortBy: [
                SortDescriptor(\.successRate, order: .reverse),
                SortDescriptor(\.usageCount, order: .reverse)
            ]
        )

        guard let patterns = try? modelContext.fetch(descriptor) else {
            return []
        }

        return Array(patterns.prefix(limit))
    }

    // MARK: - Suggestions

    /// Suggest command based on partial input
    func suggestCommands(for partialText: String, limit: Int = 3) -> [String] {
        let patterns = getMostUsedPatterns(limit: 20)

        // Filter patterns that match partial text
        let matching = patterns.filter { pattern in
            pattern.patternText.starts(with: partialText.lowercased())
        }

        // Return top suggestions
        return matching.prefix(limit).map { $0.patternText }
    }

    /// Suggest better phrasing for intent
    func suggestBetterPhrasing(for intent: CommandIntent) -> [String] {
        let patterns = getPatternsForIntent(intent, limit: 3)

        return patterns
            .filter { $0.successRate > 0.8 }
            .map { $0.patternText }
    }

    // MARK: - Custom Shortcuts

    /// Add custom shortcut
    func addShortcut(phrase: String, intent: CommandIntent) {
        let pattern = CommandPattern(
            patternText: phrase.lowercased(),
            intent: intent,
            entityMappings: [:]
        )

        pattern.userID = userID
        modelContext.insert(pattern)
    }

    /// Remove shortcut
    func removeShortcut(_ phrase: String) {
        if let pattern = findPattern(phrase) {
            modelContext.delete(pattern)
        }
    }

    /// Get all shortcuts
    func getAllShortcuts() -> [CommandPattern] {
        let descriptor = FetchDescriptor<CommandPattern>(
            predicate: #Predicate { pattern in
                pattern.userID == userID
            },
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Statistics

    /// Get learning statistics
    func getStatistics() -> CommandStatistics {
        let descriptor = FetchDescriptor<CommandStatistics>()

        if let stats = try? modelContext.fetch(descriptor).first {
            return stats
        }

        let newStats = CommandStatistics()
        modelContext.insert(newStats)
        return newStats
    }

    /// Record command for statistics
    func recordCommand(intent: CommandIntent, success: Bool, confidence: Float) {
        let stats = getStatistics()
        stats.recordCommand(intent: intent, success: success, confidence: confidence)
    }

    // MARK: - Vocabulary Management

    /// Get custom vocabulary
    func getVocabulary() -> UserCommandVocabulary {
        return vocabulary
    }

    /// Get custom term mapping
    func getCustomTerm(for term: String) -> String? {
        let terms = vocabulary.getCustomTerms()
        return terms[term.lowercased()]
    }

    /// Clear learned patterns
    func clearAllLearning() {
        // Delete all user patterns
        let descriptor = FetchDescriptor<CommandPattern>(
            predicate: #Predicate { pattern in
                pattern.userID == userID
            }
        )

        if let patterns = try? modelContext.fetch(descriptor) {
            for pattern in patterns {
                modelContext.delete(pattern)
            }
        }

        // Reset vocabulary
        vocabulary = UserCommandVocabulary(userID: userID)
        modelContext.insert(vocabulary)
    }

    // MARK: - Export/Import

    /// Export learned patterns
    func exportLearning() -> Data? {
        let patterns = getAllShortcuts()

        let export = patterns.map { pattern in
            [
                "pattern": pattern.patternText,
                "intent": pattern.intent,
                "usageCount": pattern.usageCount,
                "successRate": pattern.successRate
            ] as [String: Any]
        }

        return try? JSONSerialization.data(withJSONObject: export)
    }

    /// Import learned patterns
    func importLearning(_ data: Data) throws {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw LearningError.invalidFormat
        }

        for item in json {
            guard let patternText = item["pattern"] as? String,
                  let intentString = item["intent"] as? String,
                  let intent = CommandIntent(rawValue: intentString) else {
                continue
            }

            let pattern = CommandPattern(
                patternText: patternText,
                intent: intent,
                entityMappings: [:]
            )

            if let usage = item["usageCount"] as? Int {
                pattern.usageCount = usage
            }

            if let success = item["successRate"] as? Float {
                pattern.successRate = success
            }

            pattern.userID = userID
            modelContext.insert(pattern)
        }
    }

    // MARK: - Private Helpers

    private static func loadOrCreateVocabulary(
        modelContext: ModelContext,
        userID: String
    ) -> UserCommandVocabulary {
        let descriptor = FetchDescriptor<UserCommandVocabulary>(
            predicate: #Predicate { vocab in
                vocab.userID == userID
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let newVocab = UserCommandVocabulary(userID: userID)
        modelContext.insert(newVocab)
        return newVocab
    }
}

// MARK: - Learning Errors

enum LearningError: LocalizedError {
    case invalidFormat
    case importFailed

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid learning data format"
        case .importFailed:
            return "Failed to import learning data"
        }
    }
}
