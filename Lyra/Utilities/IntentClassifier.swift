//
//  IntentClassifier.swift
//  Lyra
//
//  ML-based intent classification for voice commands
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import NaturalLanguage
import CoreML

/// Classifies command intent using pattern matching and ML
class IntentClassifier {

    // MARK: - Properties

    private let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
    private var customPatterns: [CommandIntent: [String]] = [:]
    private let semanticEngine = SemanticSearchEngine()

    // MARK: - Initialization

    init() {
        loadDefaultPatterns()
    }

    // MARK: - Intent Classification

    /// Classify intent with confidence score
    func classifyIntent(_ text: String) -> (intent: CommandIntent, confidence: Float) {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Try pattern matching first (highest confidence)
        if let patternIntent = matchPatterns(normalized) {
            return (patternIntent, 0.95)
        }

        // Try keyword-based classification
        if let keywordIntent = classifyByKeywords(normalized) {
            return (keywordIntent, 0.85)
        }

        // Fallback to structural analysis
        let structuralIntent = classifyByStructure(normalized)
        return (structuralIntent, 0.70)
    }

    /// Get multiple possible intents ranked by confidence
    func getPossibleIntents(_ text: String) -> [(intent: CommandIntent, confidence: Float)] {
        let normalized = text.lowercased()
        var results: [(CommandIntent, Float)] = []

        // Pattern matching
        if let patternIntent = matchPatterns(normalized) {
            results.append((patternIntent, 0.95))
        }

        // Keyword-based
        let keywordIntents = getAllKeywordMatches(normalized)
        results.append(contentsOf: keywordIntents)

        // Structural
        let structuralIntent = classifyByStructure(normalized)
        if !results.contains(where: { $0.0 == structuralIntent }) {
            results.append((structuralIntent, 0.70))
        }

        // Sort by confidence
        return results.sorted { $0.1 > $1.1 }
    }

    // MARK: - Pattern Matching

    /// Match against known command patterns
    private func matchPatterns(_ text: String) -> CommandIntent? {
        for (intent, patterns) in customPatterns {
            for pattern in patterns {
                if matchesPattern(text, pattern: pattern) {
                    return intent
                }
            }
        }
        return nil
    }

    /// Check if text matches a specific pattern
    private func matchesPattern(_ text: String, pattern: String) -> Bool {
        // Convert pattern to regex
        var regexPattern = pattern
            .replacingOccurrences(of: "{songName}", with: "[\\w\\s]+")
            .replacingOccurrences(of: "{key}", with: "[A-G][#b]?m?")
            .replacingOccurrences(of: "{number}", with: "\\d+")
            .replacingOccurrences(of: "{setName}", with: "[\\w\\s]+")
            .replacingOccurrences(of: "{tempo}", with: "(fast|slow|\\d+)")

        regexPattern = "^" + regexPattern + "$"

        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) else {
            return false
        }

        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }

    // MARK: - Keyword Classification

    /// Classify based on keyword presence
    private func classifyByKeywords(_ text: String) -> CommandIntent? {
        // Search intents
        if containsAny(text, ["find", "search", "show me", "looking for", "get"]) {
            if containsAny(text, ["key", "in c", "in g", "in d"]) {
                return .findByKey
            }
            if containsAny(text, ["fast", "slow", "tempo", "bpm", "upbeat", "ballad"]) {
                return .findByTempo
            }
            if containsAny(text, ["happy", "sad", "joyful", "peaceful", "worship"]) {
                return .findByMood
            }
            if containsAny(text, ["by ", "from ", "artist"]) {
                return .findByArtist
            }
            if containsAny(text, ["lyrics", "words", "says"]) {
                return .findByLyrics
            }
            return .findSongs
        }

        // Navigation intents
        if containsAny(text, ["go to", "open", "show", "display"]) {
            if containsAny(text, ["set", "setlist"]) {
                return .goToSet
            }
            if containsAny(text, ["home", "main", "back"]) {
                return .goHome
            }
            return .goToSong
        }

        if containsAny(text, ["next", "forward"]) {
            return .showNext
        }

        if containsAny(text, ["previous", "back", "last"]) {
            return .showPrevious
        }

        // Edit intents
        if containsAny(text, ["transpose", "change key", "move to"]) {
            return .transpose
        }

        if containsAny(text, ["capo", "set capo", "use capo"]) {
            return .setCapo
        }

        if containsAny(text, ["delete", "remove"]) && !containsAny(text, ["set", "from set"]) {
            return .deleteSong
        }

        // Performance intents
        if containsAny(text, ["start", "begin"]) {
            if containsAny(text, ["scroll", "autoscroll"]) {
                return .startAutoscroll
            }
            if containsAny(text, ["metronome", "click"]) {
                return .startMetronome
            }
            if containsAny(text, ["performance", "performance mode"]) {
                return .enablePerformanceMode
            }
        }

        if containsAny(text, ["stop", "end"]) {
            if containsAny(text, ["scroll", "autoscroll"]) {
                return .stopAutoscroll
            }
            if containsAny(text, ["metronome", "click"]) {
                return .stopMetronome
            }
            if containsAny(text, ["performance"]) {
                return .disablePerformanceMode
            }
        }

        if containsAny(text, ["faster", "speed up", "increase speed"]) {
            if containsAny(text, ["scroll"]) {
                return .adjustScrollSpeed
            }
            return .adjustTempo
        }

        if containsAny(text, ["slower", "slow down", "decrease speed"]) {
            if containsAny(text, ["scroll"]) {
                return .adjustScrollSpeed
            }
            return .adjustTempo
        }

        // Set management intents
        if containsAny(text, ["add to", "add this to", "put in"]) {
            return .addToSet
        }

        if containsAny(text, ["remove from", "take out of"]) {
            return .removeFromSet
        }

        if containsAny(text, ["create set", "new set", "make a set"]) {
            return .createSet
        }

        // Query intents
        if containsAny(text, ["what song", "what's this", "what am i"]) {
            return .whatSong
        }

        if containsAny(text, ["what set", "which set", "current set"]) {
            return .whatSet
        }

        if containsAny(text, ["what's next", "what comes next", "next up"]) {
            return .whatsNext
        }

        if containsAny(text, ["how many", "count"]) {
            return .howMany
        }

        if containsAny(text, ["list sets", "show sets", "my sets"]) {
            return .listSets
        }

        // System intents
        if containsAny(text, ["help", "what can", "how do i"]) {
            return .help
        }

        if containsAny(text, ["repeat", "say again", "what did you say"]) {
            return .repeat
        }

        if containsAny(text, ["cancel", "never mind", "stop"]) {
            return .cancel
        }

        return nil
    }

    /// Get all keyword matches with confidence scores
    private func getAllKeywordMatches(_ text: String) -> [(CommandIntent, Float)] {
        var matches: [(CommandIntent, Float)] = []

        let intentKeywords: [(CommandIntent, [String], Float)] = [
            (.findSongs, ["find", "search", "show"], 0.85),
            (.transpose, ["transpose", "change key"], 0.90),
            (.startAutoscroll, ["start scroll", "autoscroll"], 0.90),
            (.addToSet, ["add to", "add this"], 0.85),
            (.goToSet, ["go to", "open"], 0.75)
        ]

        for (intent, keywords, confidence) in intentKeywords {
            if containsAny(text, keywords) {
                matches.append((intent, confidence))
            }
        }

        return matches
    }

    // MARK: - Structural Classification

    /// Classify based on sentence structure
    private func classifyByStructure(_ text: String) -> CommandIntent {
        tagger.string = text

        var verbs: [String] = []
        var isQuestion = false

        // Extract verbs
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            if tag == .verb {
                verbs.append(String(text[range]))
            }
            return true
        }

        // Check if question
        isQuestion = text.hasPrefix("what") || text.hasPrefix("how") ||
                    text.hasPrefix("where") || text.hasPrefix("when") ||
                    text.hasSuffix("?")

        // Classify based on structure
        if isQuestion {
            return .whatSong  // Default query intent
        }

        if verbs.contains(where: { ["find", "search", "show", "get"].contains($0.lowercased()) }) {
            return .findSongs
        }

        if verbs.contains(where: { ["go", "open", "navigate"].contains($0.lowercased()) }) {
            return .goToSong
        }

        if verbs.contains(where: { ["add", "put", "insert"].contains($0.lowercased()) }) {
            return .addToSet
        }

        if verbs.contains(where: { ["start", "begin", "play"].contains($0.lowercased()) }) {
            return .startAutoscroll
        }

        // Default to find songs for unknown structure
        return .findSongs
    }

    // MARK: - Custom Patterns

    /// Register custom command pattern
    func registerCustomPattern(_ pattern: String, intent: CommandIntent) {
        customPatterns[intent, default: []].append(pattern.lowercased())
    }

    /// Load default command patterns
    private func loadDefaultPatterns() {
        // Search patterns
        customPatterns[.findSongs] = [
            "find {songName}",
            "search for {songName}",
            "show me {songName}",
            "looking for {songName}"
        ]

        customPatterns[.findByKey] = [
            "find songs in {key}",
            "show me songs in {key}",
            "songs in the key of {key}"
        ]

        customPatterns[.findByTempo] = [
            "find {tempo} songs",
            "show me {tempo} songs",
            "songs at {tempo} bpm"
        ]

        // Navigation patterns
        customPatterns[.goToSong] = [
            "go to {songName}",
            "open {songName}",
            "show {songName}"
        ]

        customPatterns[.goToSet] = [
            "go to {setName}",
            "open {setName} set",
            "show me {setName}"
        ]

        // Edit patterns
        customPatterns[.transpose] = [
            "transpose to {key}",
            "change key to {key}",
            "move to {key}",
            "transpose up {number}",
            "transpose down {number}"
        ]

        customPatterns[.setCapo] = [
            "set capo to {number}",
            "capo {number}",
            "use capo {number}",
            "put capo on {number}"
        ]

        // Performance patterns
        customPatterns[.startAutoscroll] = [
            "start autoscroll",
            "start scrolling",
            "begin autoscroll"
        ]

        customPatterns[.stopAutoscroll] = [
            "stop autoscroll",
            "stop scrolling"
        ]

        customPatterns[.startMetronome] = [
            "start metronome",
            "start metronome at {number}",
            "metronome {number} bpm"
        ]

        // Set management patterns
        customPatterns[.addToSet] = [
            "add to {setName}",
            "add this to {setName}",
            "put in {setName}",
            "add to my set"
        ]

        customPatterns[.createSet] = [
            "create set {setName}",
            "new set {setName}",
            "make a set called {setName}"
        ]

        // Query patterns
        customPatterns[.whatSong] = [
            "what song is this",
            "what's this song",
            "what am i looking at"
        ]

        customPatterns[.whatsNext] = [
            "what's next",
            "what comes next",
            "what's next in the set"
        ]
    }

    // MARK: - Helper Methods

    /// Check if text contains any of the given keywords
    private func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        for keyword in keywords {
            if text.contains(keyword.lowercased()) {
                return true
            }
        }
        return false
    }

    /// Calculate text similarity (for fallback classification)
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Float {
        let set1 = Set(text1.split(separator: " "))
        let set2 = Set(text2.split(separator: " "))

        let intersection = set1.intersection(set2)
        let union = set1.union(set2)

        guard union.count > 0 else { return 0 }

        return Float(intersection.count) / Float(union.count)
    }

    // MARK: - Intent Context

    /// Get intent category
    func getIntentCategory(_ intent: CommandIntent) -> IntentCategory {
        return intent.category
    }

    /// Check if intent requires confirmation
    func requiresConfirmation(_ intent: CommandIntent) -> Bool {
        switch intent {
        case .deleteSong, .deleteSet:
            return true
        case .transpose, .setCapo where getDestructiveLevel(intent) > 0.5:
            return true
        default:
            return false
        }
    }

    /// Get destructive level of intent (0.0 to 1.0)
    private func getDestructiveLevel(_ intent: CommandIntent) -> Float {
        switch intent {
        case .deleteSong, .deleteSet:
            return 1.0
        case .transpose, .setCapo, .editSong:
            return 0.6
        case .removeFromSet:
            return 0.4
        default:
            return 0.0
        }
    }
}
