//
//  QualityScoringEngine.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Analyzes formatting quality and suggests improvements
//
//  Created by Claude AI on 1/24/26.
//

import Foundation

/// Analyzes formatting quality and generates improvement suggestions
class QualityScoringEngine {

    // MARK: - Properties

    private let chordEngine = ChordExtractionEngine()
    private let metadataEngine = MetadataExtractionEngine()
    private let patternEngine = PatternRecognitionEngine()
    private let structureEngine = StructureDetectionEngine()

    // MARK: - Public Methods

    /// Calculate comprehensive quality score
    func calculateQualityScore(_ text: String) -> QualityScore {
        let spacingScore = calculateSpacingScore(text)
        let alignmentScore = calculateAlignmentScore(text)
        let structureScore = calculateStructureScore(text)
        let chordFormatScore = calculateChordFormatScore(text)
        let metadataScore = calculateMetadataScore(text)

        // Weighted overall score
        let overall = (spacingScore * 0.20) +
                     (alignmentScore * 0.25) +
                     (structureScore * 0.25) +
                     (chordFormatScore * 0.20) +
                     (metadataScore * 0.10)

        let issues = detectIssues(text)

        return QualityScore(
            overall: overall,
            spacing: spacingScore,
            alignment: alignmentScore,
            structure: structureScore,
            chordFormat: chordFormatScore,
            metadata: metadataScore,
            issues: issues
        )
    }

    /// Detect all formatting issues
    func detectIssues(_ text: String) -> [QualityIssue] {
        var issues: [QualityIssue] = []

        issues.append(contentsOf: detectSpacingIssues(text))
        issues.append(contentsOf: detectAlignmentIssues(text))
        issues.append(contentsOf: detectStructureIssues(text))
        issues.append(contentsOf: detectChordFormatIssues(text))
        issues.append(contentsOf: detectMetadataIssues(text))

        return issues
    }

    /// Generate improvement suggestions
    func generateSuggestions(_ score: QualityScore) -> [FormattingSuggestion] {
        var suggestions: [FormattingSuggestion] = []

        if score.spacing < 0.8 {
            suggestions.append(FormattingSuggestion(
                title: "Improve Spacing",
                description: "Clean up inconsistent spacing and remove extra blank lines",
                impact: "Will improve readability by \(Int((0.8 - score.spacing) * 100))%",
                autoApplicable: true
            ))
        }

        if score.alignment < 0.8 {
            suggestions.append(FormattingSuggestion(
                title: "Align Chords",
                description: "Align chord symbols with their corresponding lyrics",
                impact: "Will improve chord placement accuracy",
                autoApplicable: true
            ))
        }

        if score.structure < 0.7 {
            suggestions.append(FormattingSuggestion(
                title: "Add Section Labels",
                description: "Label song sections (Verse, Chorus, Bridge) for better organization",
                impact: "Will improve navigation and structure clarity",
                autoApplicable: true
            ))
        }

        if score.chordFormat < 0.8 {
            suggestions.append(FormattingSuggestion(
                title: "Standardize Chord Format",
                description: "Convert all chords to consistent notation format",
                impact: "Will improve chord consistency",
                autoApplicable: true
            ))
        }

        if score.metadata < 0.6 {
            suggestions.append(FormattingSuggestion(
                title: "Add Missing Metadata",
                description: "Add title, artist, key, and other metadata",
                impact: "Will improve song organization and searchability",
                autoApplicable: false
            ))
        }

        return suggestions
    }

    /// Generate auto-fixes for issues
    func generateAutoFixes(_ text: String, issues: [QualityIssue]) -> [FormattingChange] {
        var changes: [FormattingChange] = []

        for issue in issues where issue.autoFixable {
            switch issue.type {
            case .inconsistentSpacing:
                changes.append(FormattingChange(
                    type: .fixedSpacing,
                    description: "Fixed inconsistent spacing",
                    lineNumber: issue.lineNumber,
                    before: "Multiple spaces",
                    after: "Single spaces"
                ))

            case .duplicateBlankLines:
                changes.append(FormattingChange(
                    type: .removedBlankLines,
                    description: "Removed extra blank lines",
                    lineNumber: issue.lineNumber,
                    before: "Multiple blank lines",
                    after: "Single blank line"
                ))

            case .misalignedChords:
                changes.append(FormattingChange(
                    type: .alignedChords,
                    description: "Aligned chords with lyrics",
                    lineNumber: issue.lineNumber,
                    before: "Misaligned",
                    after: "Aligned"
                ))

            case .inconsistentChordFormat:
                changes.append(FormattingChange(
                    type: .standardizedChords,
                    description: "Standardized chord notation",
                    lineNumber: issue.lineNumber,
                    before: "Mixed formats",
                    after: "ChordPro format"
                ))

            case .missingSection:
                changes.append(FormattingChange(
                    type: .addedSection,
                    description: "Added section label",
                    lineNumber: issue.lineNumber,
                    before: "Unlabeled section",
                    after: "Labeled section"
                ))

            default:
                break
            }
        }

        return changes
    }

    // MARK: - Score Calculation

    private func calculateSpacingScore(_ text: String) -> Float {
        var score: Float = 1.0
        let lines = text.components(separatedBy: .newlines)

        // Penalize trailing whitespace
        let trailingWhitespace = lines.filter { $0.hasSuffix(" ") || $0.hasSuffix("\t") }.count
        score -= Float(trailingWhitespace) * 0.05

        // Penalize excessive blank lines
        var consecutiveBlank = 0
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                consecutiveBlank += 1
                if consecutiveBlank > 2 {
                    score -= 0.1
                }
            } else {
                consecutiveBlank = 0
            }
        }

        // Penalize mixed tabs/spaces
        let hasTabs = text.contains("\t")
        let hasMultipleSpaces = text.contains("  ")
        if hasTabs && hasMultipleSpaces {
            score -= 0.2
        }

        return max(0, score)
    }

    private func calculateAlignmentScore(_ text: String) -> Float {
        let pattern = patternEngine.detectPattern(text)
        guard pattern == .chordOverLyric else { return 1.0 }

        var score: Float = 1.0
        let lines = text.components(separatedBy: .newlines)

        for i in 0..<lines.count - 1 {
            let line = lines[i]
            let nextLine = lines[i + 1]

            if isChordLine(line) && !nextLine.trimmingCharacters(in: .whitespaces).isEmpty {
                let alignment = calculateLineAlignment(line, nextLine)
                score *= alignment
            }
        }

        return score
    }

    private func calculateStructureScore(_ text: String) -> Float {
        let structure = structureEngine.detectStructure(text)

        var score: Float = 0.5

        // Points for having sections
        if structure.sections.count >= 3 {
            score += 0.2
        }

        // Points for labeled sections
        let labeledCount = structure.sections.filter { $0.type != .unknown }.count
        if !structure.sections.isEmpty {
            score += Float(labeledCount) / Float(structure.sections.count) * 0.2
        }

        // Points for repeated sections
        if !structure.repeatedSections.isEmpty {
            score += 0.1
        }

        return min(1.0, score)
    }

    private func calculateChordFormatScore(_ text: String) -> Float {
        let patterns = patternEngine.analyzePatterns(text)
        let dominantPattern = patterns.max(by: { $0.value < $1.value })

        var score: Float = 1.0

        // Penalize mixed patterns
        let significantPatterns = patterns.filter { $0.value > 0.2 }
        if significantPatterns.count > 1 {
            score -= 0.3
        }

        // Penalize unknown patterns
        if dominantPattern?.key == .unknown {
            score -= 0.4
        }

        // Check chord validity
        let chords = chordEngine.extractChords(text)
        let invalidChords = chords.filter { !chordEngine.isValidChord($0) }
        if !chords.isEmpty {
            score -= Float(invalidChords.count) / Float(chords.count) * 0.3
        }

        return max(0, score)
    }

    private func calculateMetadataScore(_ text: String) -> Float {
        let metadata = metadataEngine.extractMetadata(text)
        return metadata.completenessPercentage
    }

    // MARK: - Issue Detection

    private func detectSpacingIssues(_ text: String) -> [QualityIssue] {
        var issues: [QualityIssue] = []
        let lines = text.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            if line.hasSuffix(" ") || line.hasSuffix("\t") {
                issues.append(QualityIssue(
                    type: .inconsistentSpacing,
                    severity: .low,
                    description: "Line has trailing whitespace",
                    lineNumber: index + 1,
                    suggestion: "Remove trailing whitespace",
                    autoFixable: true
                ))
            }
        }

        // Check for excessive blank lines
        var consecutiveBlank = 0
        for (index, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                consecutiveBlank += 1
                if consecutiveBlank > 2 {
                    issues.append(QualityIssue(
                        type: .duplicateBlankLines,
                        severity: .medium,
                        description: "More than 2 consecutive blank lines",
                        lineNumber: index + 1,
                        suggestion: "Remove extra blank lines",
                        autoFixable: true
                    ))
                }
            } else {
                consecutiveBlank = 0
            }
        }

        return issues
    }

    private func detectAlignmentIssues(_ text: String) -> [QualityIssue] {
        var issues: [QualityIssue] = []
        let lines = text.components(separatedBy: .newlines)

        for i in 0..<lines.count - 1 {
            let line = lines[i]
            let nextLine = lines[i + 1]

            if isChordLine(line) && !nextLine.trimmingCharacters(in: .whitespaces).isEmpty {
                let alignment = calculateLineAlignment(line, nextLine)

                if alignment < 0.8 {
                    issues.append(QualityIssue(
                        type: .misalignedChords,
                        severity: .medium,
                        description: "Chords not properly aligned with lyrics",
                        lineNumber: i + 1,
                        suggestion: "Align chords above corresponding syllables",
                        autoFixable: true
                    ))
                }
            }
        }

        return issues
    }

    private func detectStructureIssues(_ text: String) -> [QualityIssue] {
        var issues: [QualityIssue] = []
        let structure = structureEngine.detectStructure(text)

        let unlabeledSections = structure.sections.filter { $0.type == .unknown }
        if !unlabeledSections.isEmpty {
            issues.append(QualityIssue(
                type: .missingSection,
                severity: .medium,
                description: "\(unlabeledSections.count) sections without labels",
                suggestion: "Add section labels (Verse, Chorus, etc.)",
                autoFixable: true
            ))
        }

        return issues
    }

    private func detectChordFormatIssues(_ text: String) -> [QualityIssue] {
        var issues: [QualityIssue] = []
        let patterns = patternEngine.analyzePatterns(text)

        let significantPatterns = patterns.filter { $0.value > 0.2 }
        if significantPatterns.count > 1 {
            issues.append(QualityIssue(
                type: .mixedPatterns,
                severity: .high,
                description: "Multiple chord notation formats detected",
                suggestion: "Standardize to single format (ChordPro recommended)",
                autoFixable: true
            ))
        }

        // Check for invalid chords
        let chords = chordEngine.extractChords(text)
        let invalidChords = chords.filter { !chordEngine.isValidChord($0) }

        for invalidChord in invalidChords {
            issues.append(QualityIssue(
                type: .invalidChord,
                severity: .high,
                description: "Invalid chord: \(invalidChord)",
                suggestion: "Fix chord notation",
                autoFixable: false
            ))
        }

        return issues
    }

    private func detectMetadataIssues(_ text: String) -> [QualityIssue] {
        var issues: [QualityIssue] = []
        let metadata = metadataEngine.extractMetadata(text)

        if metadata.title == nil {
            issues.append(QualityIssue(
                type: .missingMetadata,
                severity: .medium,
                description: "Song title not found",
                suggestion: "Add title at the beginning of the song",
                autoFixable: false
            ))
        }

        if metadata.key == nil {
            issues.append(QualityIssue(
                type: .missingMetadata,
                severity: .low,
                description: "Musical key not specified",
                suggestion: "Add 'Key: C' or similar",
                autoFixable: false
            ))
        }

        return issues
    }

    // MARK: - Helpers

    private func isChordLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return false }

        let chordCount = words.filter { chordEngine.isValidChord($0) }.count
        return Float(chordCount) / Float(words.count) > 0.7
    }

    private func calculateLineAlignment(_ chordLine: String, _ lyricLine: String) -> Float {
        let chords = extractChordPositions(chordLine)
        guard !chords.isEmpty else { return 1.0 }

        var alignmentScore: Float = 1.0

        for (_, position) in chords {
            if position >= lyricLine.count {
                alignmentScore *= 0.8
            } else {
                let index = lyricLine.index(lyricLine.startIndex, offsetBy: position)
                let char = lyricLine[index]

                if char == " " {
                    alignmentScore *= 1.0  // Perfect alignment
                } else {
                    alignmentScore *= 0.9  // Mid-word alignment
                }
            }
        }

        return alignmentScore
    }

    private func extractChordPositions(_ line: String) -> [(String, Int)] {
        var result: [(String, Int)] = []
        var currentWord = ""
        var currentPosition = 0

        for (i, char) in line.enumerated() {
            if char.isWhitespace {
                if !currentWord.isEmpty && chordEngine.isValidChord(currentWord) {
                    result.append((currentWord, currentPosition))
                    currentWord = ""
                }
            } else {
                if currentWord.isEmpty {
                    currentPosition = i
                }
                currentWord.append(char)
            }
        }

        if !currentWord.isEmpty && chordEngine.isValidChord(currentWord) {
            result.append((currentWord, currentPosition))
        }

        return result
    }
}
