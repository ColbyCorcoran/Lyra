//
//  StructureDetectionEngine.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Analyzes chord chart text to detect song structure
//
//  Created by Claude AI on 1/24/26.
//

import Foundation
import NaturalLanguage

/// Analyzes chord chart text to detect verse/chorus/bridge patterns
@MainActor
class StructureDetectionEngine {

    // MARK: - Properties

    private let sectionIdentifier = SectionIdentificationEngine()

    // MARK: - Section Labels Pattern Matching

    private let sectionPatterns: [(SectionType, NSRegularExpression)] = {
        let patterns: [(SectionType, String)] = [
            (.intro, "^\\s*(intro|introduction)\\s*:?\\s*$"),
            (.verse, "^\\s*(verse|v)\\s*([0-9]+)?\\s*:?\\s*$"),
            (.preChorus, "^\\s*(pre-?chorus|prechorus|pc)\\s*:?\\s*$"),
            (.chorus, "^\\s*(chorus|refrain|hook|c)\\s*([0-9]+)?\\s*:?\\s*$"),
            (.bridge, "^\\s*(bridge|b)\\s*:?\\s*$"),
            (.outro, "^\\s*(outro|ending|end)\\s*:?\\s*$"),
            (.instrumental, "^\\s*(instrumental|solo|interlude)\\s*:?\\s*$"),
            (.tag, "^\\s*(tag|coda)\\s*:?\\s*$")
        ]

        return patterns.compactMap { type, pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                return nil
            }
            return (type, regex)
        }
    }()

    // MARK: - Public Methods

    /// Detect complete song structure from text
    func detectStructure(_ text: String) -> SongStructure {
        let lines = text.components(separatedBy: .newlines)

        // Detect sections
        let sections = detectSections(lines)

        // Find repeated sections
        let repetitions = findRepeatedSections(sections)

        // Build section order
        let order = sections.map { $0.label }

        // Calculate overall confidence
        let confidence = calculateStructureConfidence(sections, repetitions: repetitions)

        return SongStructure(
            sections: sections,
            repeatedSections: repetitions,
            sectionOrder: order,
            confidence: confidence
        )
    }

    /// Detect individual sections in the text
    func detectSections(_ lines: [String]) -> [SongSection] {
        var sections: [SongSection] = []
        var currentSectionLines: [String] = []
        var currentSectionStart = 0
        var currentSectionType: SectionType?
        var currentSectionLabel: String?

        for (index, line) in lines.enumerated() {
            // Check if line is a section label
            if let (type, label) = detectSectionLabel(line) {
                // Save previous section if exists
                if !currentSectionLines.isEmpty, let sectionType = currentSectionType, let sectionLabel = currentSectionLabel {
                    let section = createSection(
                        type: sectionType,
                        label: sectionLabel,
                        lines: currentSectionLines,
                        startLine: currentSectionStart,
                        endLine: index - 1
                    )
                    sections.append(section)
                }

                // Start new section
                currentSectionType = type
                currentSectionLabel = label
                currentSectionLines = []
                currentSectionStart = index + 1
            }
            // Check if blank line (potential section boundary)
            else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // If we have accumulated lines and next line might be new section, save current
                if !currentSectionLines.isEmpty && mightBeNewSection(lines, index: index + 1) {
                    let sectionType = currentSectionType ?? inferSectionType(currentSectionLines, position: sections.count)
                    let sectionLabel = currentSectionLabel ?? generateDefaultLabel(type: sectionType, sections: sections)

                    let section = createSection(
                        type: sectionType,
                        label: sectionLabel,
                        lines: currentSectionLines,
                        startLine: currentSectionStart,
                        endLine: index - 1
                    )
                    sections.append(section)

                    currentSectionLines = []
                    currentSectionStart = index + 1
                    currentSectionType = nil
                    currentSectionLabel = nil
                }
            }
            // Regular content line
            else {
                currentSectionLines.append(line)
            }
        }

        // Save final section
        if !currentSectionLines.isEmpty {
            let sectionType = currentSectionType ?? inferSectionType(currentSectionLines, position: sections.count)
            let sectionLabel = currentSectionLabel ?? generateDefaultLabel(type: sectionType, sections: sections)

            let section = createSection(
                type: sectionType,
                label: sectionLabel,
                lines: currentSectionLines,
                startLine: currentSectionStart,
                endLine: lines.count - 1
            )
            sections.append(section)
        }

        return sections
    }

    /// Auto-label sections based on detected structure
    func autoLabelSections(_ structure: SongStructure) -> SongStructure {
        var labeledSections = structure.sections
        var sectionCounts: [SectionType: Int] = [:]

        for i in 0..<labeledSections.count {
            let section = labeledSections[i]
            let count = sectionCounts[section.type, default: 0] + 1
            sectionCounts[section.type] = count

            // Generate numbered label for verses and choruses
            if section.type == .verse || section.type == .chorus {
                labeledSections[i].label = "\(section.type.displayName) \(count)"
            } else {
                labeledSections[i].label = section.type.displayName
            }
        }

        return SongStructure(
            sections: labeledSections,
            repeatedSections: structure.repeatedSections,
            sectionOrder: labeledSections.map { $0.label },
            confidence: structure.confidence
        )
    }

    /// Find repeated sections in the structure
    func findRepeatedSections(_ sections: [SongSection]) -> [SectionRepetition] {
        var repetitions: [SectionRepetition] = []
        var sectionGroups: [SectionType: [Int]] = [:]

        // Group sections by type
        for (index, section) in sections.enumerated() {
            sectionGroups[section.type, default: []].append(index)
        }

        // Find repetitions for each type
        for (type, indices) in sectionGroups where indices.count > 1 {
            // Compare content similarity
            let firstSection = sections[indices[0]]
            var similarOccurrences: [Int] = [indices[0]]

            for i in 1..<indices.count {
                let section = sections[indices[i]]
                let similarity = calculateContentSimilarity(firstSection.lines, section.lines)

                if similarity > 0.7 {  // 70% similarity threshold
                    similarOccurrences.append(indices[i])
                }
            }

            if similarOccurrences.count > 1 {
                let repetition = SectionRepetition(
                    sectionType: type,
                    label: firstSection.label,
                    occurrences: similarOccurrences,
                    similarity: calculateAverageSimilarity(sections, indices: similarOccurrences)
                )
                repetitions.append(repetition)
            }
        }

        return repetitions
    }

    // MARK: - Private Helpers

    /// Detect section label from line
    private func detectSectionLabel(_ line: String) -> (SectionType, String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        for (type, regex) in sectionPatterns {
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            if regex.firstMatch(in: trimmed, range: range) != nil {
                return (type, trimmed)
            }
        }

        return nil
    }

    /// Check if next section might start soon
    private func mightBeNewSection(_ lines: [String], index: Int) -> Bool {
        guard index < lines.count else { return false }

        let nextLine = lines[index].trimmingCharacters(in: .whitespaces)

        // Check if next line is a section label
        if detectSectionLabel(nextLine) != nil {
            return true
        }

        // Check if we have enough accumulated lines for a section
        // Sections typically have at least 2-4 lines
        return false
    }

    /// Infer section type from content
    private func inferSectionType(_ lines: [String], position: Int) -> SectionType {
        // Use the section identification engine
        return sectionIdentifier.identifySection(lines: lines, position: position)
    }

    /// Generate default label for section
    private func generateDefaultLabel(type: SectionType, sections: [SongSection]) -> String {
        let count = sections.filter { $0.type == type }.count + 1

        if type == .verse || type == .chorus {
            return "\(type.displayName) \(count)"
        } else {
            return type.displayName
        }
    }

    /// Create section from components
    private func createSection(
        type: SectionType,
        label: String,
        lines: [String],
        startLine: Int,
        endLine: Int
    ) -> SongSection {
        let isInstrumental = sectionIdentifier.isInstrumental(lines: lines)
        let confidence = sectionIdentifier.calculateConfidence(lines: lines, expectedType: type)

        return SongSection(
            type: type,
            label: label,
            lines: lines,
            startLine: startLine,
            endLine: endLine,
            confidence: confidence,
            isInstrumental: isInstrumental
        )
    }

    /// Calculate content similarity between two sections
    private func calculateContentSimilarity(_ lines1: [String], _ lines2: [String]) -> Float {
        guard !lines1.isEmpty && !lines2.isEmpty else { return 0 }

        // Compare line counts
        let countRatio = Float(min(lines1.count, lines2.count)) / Float(max(lines1.count, lines2.count))

        // Compare line content
        var matchingLines = 0
        let minCount = min(lines1.count, lines2.count)

        for i in 0..<minCount {
            let similarity = stringSimilarity(lines1[i], lines2[i])
            if similarity > 0.8 {
                matchingLines += 1
            }
        }

        let contentRatio = Float(matchingLines) / Float(minCount)

        return (countRatio + contentRatio) / 2.0
    }

    /// Calculate average similarity across sections
    private func calculateAverageSimilarity(_ sections: [SongSection], indices: [Int]) -> Float {
        guard indices.count > 1 else { return 1.0 }

        var totalSimilarity: Float = 0
        var comparisons = 0

        for i in 0..<indices.count - 1 {
            for j in (i + 1)..<indices.count {
                let similarity = calculateContentSimilarity(
                    sections[indices[i]].lines,
                    sections[indices[j]].lines
                )
                totalSimilarity += similarity
                comparisons += 1
            }
        }

        return comparisons > 0 ? totalSimilarity / Float(comparisons) : 1.0
    }

    /// Calculate structure detection confidence
    private func calculateStructureConfidence(_ sections: [SongSection], repetitions: [SectionRepetition]) -> Float {
        guard !sections.isEmpty else { return 0 }

        var confidence: Float = 0.5  // Base confidence

        // Boost for labeled sections
        let labeledCount = sections.filter { $0.type != .unknown }.count
        confidence += Float(labeledCount) / Float(sections.count) * 0.3

        // Boost for repeated sections (common in songs)
        if !repetitions.isEmpty {
            confidence += 0.1
        }

        // Boost for logical structure (verse-chorus pattern)
        if hasLogicalStructure(sections) {
            confidence += 0.1
        }

        return min(1.0, confidence)
    }

    /// Check if structure follows logical pattern
    private func hasLogicalStructure(_ sections: [SongSection]) -> Bool {
        // Common patterns: verse-chorus, verse-chorus-verse-chorus-bridge-chorus
        let types = sections.map { $0.type }

        // Check for verse-chorus alternation
        var hasVerseChorus = false
        for i in 0..<types.count - 1 {
            if types[i] == .verse && types[i + 1] == .chorus {
                hasVerseChorus = true
                break
            }
        }

        return hasVerseChorus
    }

    /// Calculate string similarity using simple algorithm
    private func stringSimilarity(_ str1: String, _ str2: String) -> Float {
        let s1 = str1.lowercased().trimmingCharacters(in: .whitespaces)
        let s2 = str2.lowercased().trimmingCharacters(in: .whitespaces)

        guard !s1.isEmpty && !s2.isEmpty else { return 0 }

        if s1 == s2 { return 1.0 }

        // Simple character-based similarity
        let maxLen = max(s1.count, s2.count)
        let minLen = min(s1.count, s2.count)

        var matches = 0
        let arr1 = Array(s1)
        let arr2 = Array(s2)

        for i in 0..<minLen {
            if arr1[i] == arr2[i] {
                matches += 1
            }
        }

        return Float(matches) / Float(maxLen)
    }
}

// MARK: - Section Identification Engine

/// ML-inspired engine to identify song sections
class SectionIdentificationEngine {

    // MARK: - Section Detection

    /// Identify section type from lines
    func identifySection(lines: [String], position: Int = 0) -> SectionType {
        let features = extractFeatures(lines, position: position)
        return classifySection(features)
    }

    /// Check if section is instrumental
    func isInstrumental(lines: [String]) -> Bool {
        let lyricLines = lines.filter { !isChordLine($0) && !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return lyricLines.isEmpty && !lines.isEmpty
    }

    /// Calculate confidence for section type
    func calculateConfidence(lines: [String], expectedType: SectionType) -> Float {
        let features = extractFeatures(lines, position: 0)
        let predictedType = classifySection(features)
        return predictedType == expectedType ? 0.9 : 0.6
    }

    // MARK: - Feature Extraction

    private struct SectionFeatures {
        var lineCount: Int
        var chordDensity: Float
        var hasLyrics: Bool
        var avgLineLength: Float
        var position: Int
        var hasRepetition: Bool
    }

    private func extractFeatures(_ lines: [String], position: Int) -> SectionFeatures {
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let chordLines = nonEmptyLines.filter { isChordLine($0) }
        let chordDensity = Float(chordLines.count) / Float(max(nonEmptyLines.count, 1))

        let lyricLines = nonEmptyLines.filter { !isChordLine($0) }
        let hasLyrics = !lyricLines.isEmpty

        let avgLineLength = lyricLines.isEmpty ? 0 : Float(lyricLines.map { $0.count }.reduce(0, +)) / Float(lyricLines.count)

        let hasRepetition = checkRepetition(lyricLines)

        return SectionFeatures(
            lineCount: nonEmptyLines.count,
            chordDensity: chordDensity,
            hasLyrics: hasLyrics,
            avgLineLength: avgLineLength,
            position: position,
            hasRepetition: hasRepetition
        )
    }

    // MARK: - Classification

    private func classifySection(_ features: SectionFeatures) -> SectionType {
        // Intro: short, early position, may be instrumental
        if features.position == 0 && features.lineCount <= 4 {
            return .intro
        }

        // Outro: short, would be detected by position in structure detection
        if features.lineCount <= 4 && !features.hasLyrics {
            return .outro
        }

        // Instrumental: no lyrics
        if !features.hasLyrics {
            return .instrumental
        }

        // Chorus: shorter, repetitive, higher chord density
        if features.hasRepetition && features.lineCount <= 6 && features.chordDensity > 0.4 {
            return .chorus
        }

        // Bridge: different characteristics, typically in latter half
        if features.lineCount <= 6 && features.position > 2 {
            return .bridge
        }

        // Pre-chorus: moderate length, before chorus
        if features.lineCount <= 4 {
            return .preChorus
        }

        // Verse: longer, story-telling
        return .verse
    }

    // MARK: - Helpers

    private func isChordLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        // Check if line consists mostly of chord symbols
        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return false }

        let chordCount = words.filter { isLikelyChord($0) }.count
        return Float(chordCount) / Float(words.count) > 0.7
    }

    private func isLikelyChord(_ word: String) -> Bool {
        // Simple chord pattern matching
        let chordPattern = "^[A-G][#b]?(maj|min|m|dim|aug|sus)?[0-9]?(/[A-G][#b]?)?$"
        guard let regex = try? NSRegularExpression(pattern: chordPattern) else { return false }

        let range = NSRange(word.startIndex..., in: word)
        return regex.firstMatch(in: word, range: range) != nil
    }

    private func checkRepetition(_ lines: [String]) -> Bool {
        guard lines.count >= 2 else { return false }

        // Check if any lines repeat
        let uniqueLines = Set(lines.map { $0.lowercased().trimmingCharacters(in: .whitespaces) })
        return uniqueLines.count < lines.count
    }
}
