//
//  ConversationContextManager.swift
//  Lyra
//
//  Manages conversation context for follow-up commands and pronoun resolution
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import SwiftData

/// Manages conversation state and context for multi-turn interactions
@MainActor
class ConversationContextManager {

    // MARK: - Properties

    private var currentContext: ConversationContext?
    private let modelContext: ModelContext
    private let maxContextAge: TimeInterval = 300  // 5 minutes

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateContext()
    }

    // MARK: - Context Management

    /// Get or create current conversation context
    func getContext() -> ConversationContext {
        if let context = currentContext, !context.isStale() {
            return context
        }

        // Context is stale or doesn't exist, create new
        let newContext = ConversationContext()
        modelContext.insert(newContext)
        currentContext = newContext
        return newContext
    }

    /// Update context with new information
    func updateContext(
        currentSong: UUID? = nil,
        currentSet: UUID? = nil,
        searchResults: [UUID]? = nil,
        topic: String? = nil
    ) {
        let context = getContext()

        if let song = currentSong {
            context.currentSong = song
            context.itRefers = song
            context.thisRefers = song
        }

        if let set = currentSet {
            context.currentSet = set
        }

        if let results = searchResults {
            context.lastSearchResults = results
            context.themRefers = results
        }

        if let topic = topic {
            context.recentTopics.append(topic)
            // Keep only last 10 topics
            if context.recentTopics.count > 10 {
                context.recentTopics.removeFirst()
            }
        }

        context.updateActivity()
    }

    /// Add command to context
    func addCommand(_ commandID: UUID) {
        let context = getContext()
        context.commands.append(commandID)
        context.updateActivity()
    }

    /// Clear context
    func clearContext() {
        currentContext = nil
        let newContext = ConversationContext()
        modelContext.insert(newContext)
        currentContext = newContext
    }

    /// Check if context is stale
    func isContextStale() -> Bool {
        guard let context = currentContext else { return true }
        return context.isStale()
    }

    // MARK: - Pronoun Resolution

    /// Resolve pronoun to entity ID
    func resolvePronoun(_ pronoun: String) -> UUID? {
        let context = getContext()
        let lowercased = pronoun.lowercased()

        switch lowercased {
        case "it", "this", "that":
            return context.itRefers ?? context.thisRefers ?? context.thatRefers
        case "them", "these", "those":
            return context.themRefers.first
        default:
            return nil
        }
    }

    /// Resolve "it" pronoun
    func resolveIt() -> UUID? {
        return getContext().itRefers
    }

    /// Resolve "this" pronoun
    func resolveThis() -> UUID? {
        return getContext().thisRefers
    }

    /// Resolve "that" pronoun
    func resolveThat() -> UUID? {
        return getContext().thatRefers
    }

    /// Resolve "them" pronoun
    func resolveThem() -> [UUID] {
        return getContext().themRefers
    }

    // MARK: - Reference Resolution

    /// Check if text contains pronouns
    func containsPronouns(_ text: String) -> Bool {
        let pronouns = ["it", "this", "that", "them", "these", "those"]
        let lowercased = text.lowercased()

        return pronouns.contains { lowercased.contains($0) }
    }

    /// Resolve references in command text
    func resolveReferences(_ text: String) -> String {
        var resolved = text
        let context = getContext()

        // Replace pronouns with actual references
        let replacements: [(String, UUID?, String)] = [
            ("it", context.itRefers, "the current song"),
            ("this", context.thisRefers, "this song"),
            ("that", context.thatRefers, "that song")
        ]

        for (pronoun, reference, replacement) in replacements {
            if resolved.lowercased().contains(pronoun), reference != nil {
                resolved = resolved.replacingOccurrences(
                    of: pronoun,
                    with: replacement,
                    options: .caseInsensitive
                )
            }
        }

        return resolved
    }

    /// Get referenced song ID
    func getReferencedSong() -> UUID? {
        let context = getContext()
        return context.itRefers ?? context.thisRefers ?? context.currentSong
    }

    /// Get referenced set ID
    func getReferencedSet() -> UUID? {
        let context = getContext()
        return context.currentSet
    }

    // MARK: - Follow-up Detection

    /// Check if command is a follow-up
    func isFollowUpCommand(_ text: String) -> Bool {
        let followUpIndicators = [
            "also", "and", "or", "too", "additionally",
            "more", "another", "else", "similar", "like that"
        ]

        let lowercased = text.lowercased()

        for indicator in followUpIndicators {
            if lowercased.starts(with: indicator) || lowercased.contains(" \(indicator) ") {
                return true
            }
        }

        return false
    }

    /// Detect "more like this" queries
    func isMoreLikeThisQuery(_ text: String) -> Bool {
        let patterns = [
            "more like",
            "similar to",
            "like this",
            "like that",
            "more of these",
            "others like"
        ]

        let lowercased = text.lowercased()

        return patterns.contains { lowercased.contains($0) }
    }

    /// Get reference for "more like this"
    func getMoreLikeThisReference() -> UUID? {
        let context = getContext()

        // Prefer explicit references
        if let it = context.itRefers {
            return it
        }

        // Fall back to current song
        if let current = context.currentSong {
            return current
        }

        // Last resort: first search result
        return context.lastSearchResults.first
    }

    // MARK: - Context History

    /// Get recent commands
    func getRecentCommands(limit: Int = 5) -> [VoiceCommand] {
        let context = getContext()
        let recentIDs = Array(context.commands.suffix(limit))

        let descriptor = FetchDescriptor<VoiceCommand>(
            predicate: #Predicate { command in
                recentIDs.contains(command.id)
            }
        )

        guard let commands = try? modelContext.fetch(descriptor) else {
            return []
        }

        return commands
    }

    /// Get last command
    func getLastCommand() -> VoiceCommand? {
        return getRecentCommands(limit: 1).first
    }

    /// Get commands by intent
    func getCommandsByIntent(_ intent: CommandIntent, limit: Int = 5) -> [VoiceCommand] {
        let descriptor = FetchDescriptor<VoiceCommand>(
            predicate: #Predicate { command in
                command.intent == intent.rawValue
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let commands = try? modelContext.fetch(descriptor) else {
            return []
        }

        return Array(commands.prefix(limit))
    }

    // MARK: - Topic Tracking

    /// Get recent topics
    func getRecentTopics() -> [String] {
        return getContext().recentTopics
    }

    /// Check if topic was recently discussed
    func wasRecentlyDiscussed(_ topic: String) -> Bool {
        let topics = getContext().recentTopics.map { $0.lowercased() }
        return topics.contains(topic.lowercased())
    }

    /// Get dominant topic
    func getDominantTopic() -> String? {
        let topics = getContext().recentTopics

        // Count topic frequencies
        var frequencies: [String: Int] = [:]
        for topic in topics {
            frequencies[topic, default: 0] += 1
        }

        // Return most frequent
        return frequencies.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Search Context

    /// Get last search results
    func getLastSearchResults() -> [UUID] {
        return getContext().lastSearchResults
    }

    /// Update search results
    func updateSearchResults(_ results: [UUID]) {
        let context = getContext()
        context.lastSearchResults = results
        context.themRefers = results
        context.updateActivity()
    }

    /// Get search result by index
    func getSearchResult(at index: Int) -> UUID? {
        let results = getLastSearchResults()
        guard index >= 0 && index < results.count else {
            return nil
        }
        return results[index]
    }

    // MARK: - Clarification

    /// Generate clarification question
    func generateClarification(
        ambiguousEntity: String,
        candidates: [UUID]
    ) -> String {
        if candidates.count == 2 {
            return "I found two items that match '\(ambiguousEntity)'. Which one do you mean?"
        } else if candidates.count > 2 {
            return "I found \(candidates.count) items that match '\(ambiguousEntity)'. Can you be more specific?"
        } else {
            return "I'm not sure what '\(ambiguousEntity)' refers to. Can you clarify?"
        }
    }

    /// Store clarification candidates
    func storeClarificationCandidates(_ candidates: [UUID], for entity: String) {
        let context = getContext()
        context.themRefers = candidates
        context.updateActivity()
    }

    // MARK: - Session Management

    /// Start new session
    func startNewSession() {
        clearContext()
    }

    /// End current session
    func endSession() {
        if let context = currentContext {
            // Mark session as ended (could add flag to model if needed)
            context.updateActivity()
        }
        currentContext = nil
    }

    /// Get session duration
    func getSessionDuration() -> TimeInterval {
        guard let context = currentContext else { return 0 }
        return Date().timeIntervalSince(context.sessionStart)
    }

    /// Get time since last activity
    func getTimeSinceLastActivity() -> TimeInterval {
        guard let context = currentContext else { return .infinity }
        return Date().timeIntervalSince(context.lastActivity)
    }

    // MARK: - Private Helpers

    private func loadOrCreateContext() {
        // Try to load most recent context
        let descriptor = FetchDescriptor<ConversationContext>(
            sortBy: [SortDescriptor(\.lastActivity, order: .reverse)]
        )

        if let contexts = try? modelContext.fetch(descriptor),
           let latest = contexts.first,
           !latest.isStale() {
            currentContext = latest
        } else {
            // Create new context
            let newContext = ConversationContext()
            modelContext.insert(newContext)
            currentContext = newContext
        }
    }

    /// Clean up old contexts
    func cleanupOldContexts() {
        let cutoffDate = Date().addingTimeInterval(-86400)  // 24 hours ago

        let descriptor = FetchDescriptor<ConversationContext>(
            predicate: #Predicate { context in
                context.lastActivity < cutoffDate
            }
        )

        guard let oldContexts = try? modelContext.fetch(descriptor) else {
            return
        }

        for context in oldContexts {
            modelContext.delete(context)
        }
    }
}

// MARK: - Context Query Helpers

extension ConversationContextManager {

    /// Check if we have a current song in context
    var hasCurrentSong: Bool {
        return getContext().currentSong != nil
    }

    /// Check if we have a current set in context
    var hasCurrentSet: Bool {
        return getContext().currentSet != nil
    }

    /// Check if we have recent search results
    var hasSearchResults: Bool {
        return !getContext().lastSearchResults.isEmpty
    }

    /// Get context summary
    func getContextSummary() -> String {
        let context = getContext()
        var parts: [String] = []

        if context.currentSong != nil {
            parts.append("viewing a song")
        }

        if context.currentSet != nil {
            parts.append("in a set")
        }

        if !context.lastSearchResults.isEmpty {
            parts.append("\(context.lastSearchResults.count) search results")
        }

        if parts.isEmpty {
            return "No active context"
        }

        return "Context: " + parts.joined(separator: ", ")
    }
}
