//
//  EntityExtractor.swift
//  Lyra
//
//  Extracts entities and parameters from voice commands
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import NaturalLanguage

/// Extracts entities (song names, keys, tempos, etc.) from text
class EntityExtractor {

    // MARK: - Properties

    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .lemma])
    private let musicalKeys = ["C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"]

    // MARK: - Main Extraction

    /// Extract all entities from text
    func extractEntities(_ text: String, intent: CommandIntent) -> [CommandEntity] {
        var entities: [CommandEntity] = []

        // Extract based on intent type
        switch intent.category {
        case .search:
            entities.append(contentsOf: extractSearchEntities(text))
        case .edit:
            entities.append(contentsOf: extractEditEntities(text))
        case .perform:
            entities.append(contentsOf: extractPerformanceEntities(text))
        case .manage:
            entities.append(contentsOf: extractManagementEntities(text))
        case .navigate:
            entities.append(contentsOf: extractNavigationEntities(text))
        default:
            break
        }

        // Always try to extract common entities
        entities.append(contentsOf: extractMusicalKeys(text))
        entities.append(contentsOf: extractNumbers(text))
        entities.append(contentsOf: extractTempoDescriptors(text))
        entities.append(contentsOf: extractMoodAttributes(text))

        // Remove duplicates
        return removeDuplicates(entities)
    }

    /// Extract specific entity type
    func extractEntity(_ text: String, type: CommandEntity.EntityType) -> CommandEntity? {
        switch type {
        case .songTitle:
            return extractSongTitle(text)
        case .artistName:
            return extractArtistName(text)
        case .musicalKey:
            return extractMusicalKey(text)
        case .tempo:
            return extractTempo(text)
        case .mood:
            return extractMood(text)
        case .action:
            return extractAction(text)
        case .number:
            return extractNumber(text)
        case .setName:
            return extractSetName(text)
        case .direction:
            return extractDirection(text)
        case .attribute:
            return extractAttribute(text)
        case .timeSignature:
            return extractTimeSignature(text)
        case .capoPosition:
            return extractCapoPosition(text)
        }
    }

    // MARK: - Search Entities

    private func extractSearchEntities(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []

        // Song title
        if let songTitle = extractSongTitle(text) {
            entities.append(songTitle)
        }

        // Artist name
        if let artistName = extractArtistName(text) {
            entities.append(artistName)
        }

        // Mood/attribute
        if let mood = extractMood(text) {
            entities.append(mood)
        }

        return entities
    }

    // MARK: - Edit Entities

    private func extractEditEntities(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []

        // Musical key
        if let key = extractMusicalKey(text) {
            entities.append(key)
        }

        // Transpose direction and steps
        if let direction = extractDirection(text) {
            entities.append(direction)
        }

        if let steps = extractTransposeSteps(text) {
            entities.append(steps)
        }

        // Capo position
        if let capo = extractCapoPosition(text) {
            entities.append(capo)
        }

        return entities
    }

    // MARK: - Performance Entities

    private func extractPerformanceEntities(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []

        // Tempo/BPM
        if let tempo = extractTempo(text) {
            entities.append(tempo)
        }

        // Speed adjustments
        if let direction = extractSpeedAdjustment(text) {
            entities.append(direction)
        }

        return entities
    }

    // MARK: - Management Entities

    private func extractManagementEntities(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []

        // Set name
        if let setName = extractSetName(text) {
            entities.append(setName)
        }

        // Song title
        if let songTitle = extractSongTitle(text) {
            entities.append(songTitle)
        }

        return entities
    }

    // MARK: - Navigation Entities

    private func extractNavigationEntities(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []

        // Target (song or set name)
        if let setName = extractSetName(text) {
            entities.append(setName)
        } else if let songTitle = extractSongTitle(text) {
            entities.append(songTitle)
        }

        return entities
    }

    // MARK: - Specific Extractors

    /// Extract song title
    private func extractSongTitle(_ text: String) -> CommandEntity? {
        // Pattern: after "find", "show", "go to", etc.
        let patterns = [
            #"(?:find|search for|show me|go to|open|play)\s+(.+?)(?:\s+(?:in|by|from|to)|\s*$)"#,
            #"called\s+(.+?)(?:\s+(?:in|by|from)|\s*$)"#,
            #"song\s+(.+?)(?:\s+(?:in|by|from)|\s*$)"#
        ]

        for pattern in patterns {
            if let match = extractWithPattern(text, pattern: pattern, type: .songTitle) {
                return match
            }
        }

        // Fallback: look for capitalized phrases
        return extractCapitalizedPhrase(text, type: .songTitle)
    }

    /// Extract artist name
    private func extractArtistName(_ text: String) -> CommandEntity? {
        // Pattern: "by [artist]", "from [artist]"
        let patterns = [
            #"(?:by|from)\s+([A-Z][a-zA-Z\s&]+)"#,
            #"([A-Z][a-zA-Z\s&]+)\s+songs"#
        ]

        for pattern in patterns {
            if let match = extractWithPattern(text, pattern: pattern, type: .artistName) {
                return match
            }
        }

        return nil
    }

    /// Extract musical key
    private func extractMusicalKey(_ text: String) -> CommandEntity? {
        let pattern = #"(?:in|to|key of|key:)?\s*([A-G][#b]?)\s*(?:major|minor|m)?"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        let nsString = text as NSString
        let keyString = nsString.substring(with: match.range(at: 1))

        // Validate key
        guard musicalKeys.contains(keyString) || musicalKeys.contains(keyString.dropLast().description) else {
            return nil
        }

        let range = Range(match.range(at: 1), in: text)

        return CommandEntity(
            type: .musicalKey,
            value: keyString,
            confidence: 0.95,
            range: range
        )
    }

    /// Extract multiple musical keys
    private func extractMusicalKeys(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []
        let pattern = #"([A-G][#b]?m?)\b"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches {
            let nsString = text as NSString
            let keyString = nsString.substring(with: match.range(at: 1))

            // Validate key
            if musicalKeys.contains(keyString) || musicalKeys.contains(String(keyString.dropLast())) {
                let range = Range(match.range(at: 1), in: text)
                entities.append(CommandEntity(
                    type: .musicalKey,
                    value: keyString,
                    confidence: 0.85,
                    range: range
                ))
            }
        }

        return entities
    }

    /// Extract tempo
    private func extractTempo(_ text: String) -> CommandEntity? {
        // Pattern: number followed by "bpm"
        let pattern = #"(\d+)\s*bpm"#

        return extractWithPattern(text, pattern: pattern, type: .tempo)
    }

    /// Extract tempo descriptors (fast, slow, etc.)
    private func extractTempoDescriptors(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []

        let descriptors = [
            ("fast", "fast"),
            ("slow", "slow"),
            ("upbeat", "fast"),
            ("ballad", "slow"),
            ("moderate", "moderate"),
            ("quick", "fast"),
            ("gentle", "slow")
        ]

        for (word, value) in descriptors {
            if text.lowercased().contains(word) {
                if let range = text.range(of: word, options: .caseInsensitive) {
                    entities.append(CommandEntity(
                        type: .tempo,
                        value: value,
                        confidence: 0.80,
                        range: range
                    ))
                }
            }
        }

        return entities
    }

    /// Extract mood
    private func extractMood(_ text: String) -> CommandEntity? {
        let moods = [
            "happy", "sad", "joyful", "peaceful", "worship", "celebratory",
            "reflective", "contemplative", "energetic", "calm", "uplifting"
        ]

        for mood in moods {
            if text.lowercased().contains(mood) {
                if let range = text.range(of: mood, options: .caseInsensitive) {
                    return CommandEntity(
                        type: .mood,
                        value: mood,
                        confidence: 0.85,
                        range: range
                    )
                }
            }
        }

        return nil
    }

    /// Extract mood attributes
    private func extractMoodAttributes(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []

        let attributes = [
            "happy", "sad", "joyful", "peaceful", "worship", "celebratory",
            "reflective", "contemplative", "energetic", "calm", "uplifting"
        ]

        for attribute in attributes {
            if text.lowercased().contains(attribute) {
                if let range = text.range(of: attribute, options: .caseInsensitive) {
                    entities.append(CommandEntity(
                        type: .mood,
                        value: attribute,
                        confidence: 0.75,
                        range: range
                    ))
                }
            }
        }

        return entities
    }

    /// Extract action verb
    private func extractAction(_ text: String) -> CommandEntity? {
        tagger.string = text

        var action: String?
        var actionRange: Range<String.Index>?

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            if tag == .verb {
                action = String(text[range])
                actionRange = range
                return false  // Stop after first verb
            }
            return true
        }

        guard let actionText = action, let range = actionRange else {
            return nil
        }

        return CommandEntity(
            type: .action,
            value: actionText.lowercased(),
            confidence: 0.90,
            range: range
        )
    }

    /// Extract number
    private func extractNumber(_ text: String) -> CommandEntity? {
        let pattern = #"(\d+)"#

        return extractWithPattern(text, pattern: pattern, type: .number)
    }

    /// Extract all numbers
    private func extractNumbers(_ text: String) -> [CommandEntity] {
        var entities: [CommandEntity] = []
        let pattern = #"(\d+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches {
            let nsString = text as NSString
            let number = nsString.substring(with: match.range(at: 1))
            let range = Range(match.range(at: 1), in: text)

            entities.append(CommandEntity(
                type: .number,
                value: number,
                confidence: 0.95,
                range: range
            ))
        }

        return entities
    }

    /// Extract set name
    private func extractSetName(_ text: String) -> CommandEntity? {
        // Pattern: "to [set name]", "set [set name]", etc.
        let patterns = [
            #"(?:to|set|called)\s+(.+?)(?:\s*$|set)"#,
            #"my\s+(.+?)\s+set"#
        ]

        for pattern in patterns {
            if let match = extractWithPattern(text, pattern: pattern, type: .setName) {
                return match
            }
        }

        // Check for specific phrases
        if text.contains("my set") {
            return CommandEntity(
                type: .setName,
                value: "default",
                confidence: 0.70,
                range: nil
            )
        }

        return nil
    }

    /// Extract direction (up/down)
    private func extractDirection(_ text: String) -> CommandEntity? {
        if text.contains("up") {
            if let range = text.range(of: "up", options: .caseInsensitive) {
                return CommandEntity(
                    type: .direction,
                    value: "up",
                    confidence: 0.95,
                    range: range
                )
            }
        }

        if text.contains("down") {
            if let range = text.range(of: "down", options: .caseInsensitive) {
                return CommandEntity(
                    type: .direction,
                    value: "down",
                    confidence: 0.95,
                    range: range
                )
            }
        }

        return nil
    }

    /// Extract transpose steps
    private func extractTransposeSteps(_ text: String) -> CommandEntity? {
        // Pattern: "up 2", "down 3", etc.
        let pattern = #"(?:up|down)\s+(\d+)"#

        return extractWithPattern(text, pattern: pattern, type: .number)
    }

    /// Extract speed adjustment
    private func extractSpeedAdjustment(_ text: String) -> CommandEntity? {
        if text.contains("faster") || text.contains("speed up") {
            return CommandEntity(
                type: .direction,
                value: "faster",
                confidence: 0.90,
                range: nil
            )
        }

        if text.contains("slower") || text.contains("slow down") {
            return CommandEntity(
                type: .direction,
                value: "slower",
                confidence: 0.90,
                range: nil
            )
        }

        return nil
    }

    /// Extract attribute (simple, complex, etc.)
    private func extractAttribute(_ text: String) -> CommandEntity? {
        let attributes = ["simple", "complex", "easy", "hard", "difficult"]

        for attribute in attributes {
            if text.lowercased().contains(attribute) {
                if let range = text.range(of: attribute, options: .caseInsensitive) {
                    return CommandEntity(
                        type: .attribute,
                        value: attribute,
                        confidence: 0.80,
                        range: range
                    )
                }
            }
        }

        return nil
    }

    /// Extract time signature
    private func extractTimeSignature(_ text: String) -> CommandEntity? {
        let pattern = #"(\d+/\d+)"#

        return extractWithPattern(text, pattern: pattern, type: .timeSignature)
    }

    /// Extract capo position
    private func extractCapoPosition(_ text: String) -> CommandEntity? {
        // Pattern: "capo 2", "capo on 3", etc.
        let patterns = [
            #"capo\s+(?:on\s+)?(\d+)"#,
            #"capo\s+(none|no|zero)"#
        ]

        for pattern in patterns {
            if let match = extractWithPattern(text, pattern: pattern, type: .capoPosition) {
                // Normalize "none", "no" to "0"
                if ["none", "no", "zero"].contains(match.value.lowercased()) {
                    return CommandEntity(
                        type: .capoPosition,
                        value: "0",
                        confidence: match.confidence,
                        range: match.range
                    )
                }
                return match
            }
        }

        return nil
    }

    // MARK: - Helper Methods

    /// Extract using regex pattern
    private func extractWithPattern(
        _ text: String,
        pattern: String,
        type: CommandEntity.EntityType
    ) -> CommandEntity? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1 else {
            return nil
        }

        let nsString = text as NSString
        let value = nsString.substring(with: match.range(at: 1))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let range = Range(match.range(at: 1), in: text)

        return CommandEntity(
            type: type,
            value: value,
            confidence: 0.90,
            range: range
        )
    }

    /// Extract capitalized phrase (likely a proper noun)
    private func extractCapitalizedPhrase(
        _ text: String,
        type: CommandEntity.EntityType
    ) -> CommandEntity? {
        tagger.string = text

        var phrase: String?
        var phraseRange: Range<String.Index>?

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            if tag == .personalName || tag == .organizationName {
                phrase = String(text[range])
                phraseRange = range
                return false
            }
            return true
        }

        guard let phraseText = phrase, let range = phraseRange else {
            return nil
        }

        return CommandEntity(
            type: type,
            value: phraseText,
            confidence: 0.70,
            range: range
        )
    }

    /// Remove duplicate entities
    private func removeDuplicates(_ entities: [CommandEntity]) -> [CommandEntity] {
        var seen = Set<String>()
        var unique: [CommandEntity] = []

        for entity in entities {
            let key = "\(entity.type.rawValue):\(entity.value)"
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(entity)
            }
        }

        return unique
    }
}
