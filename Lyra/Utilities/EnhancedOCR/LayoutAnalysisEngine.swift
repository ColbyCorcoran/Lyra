//
//  LayoutAnalysisEngine.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Engine 4
//  Intelligent layout detection and structure preservation
//

import Foundation
import UIKit

/// Engine for analyzing and understanding chord chart layouts
@MainActor
class LayoutAnalysisEngine {

    // MARK: - Properties

    private let sectionKeywords: [String: OCRSectionType] = [
        "verse": .verse,
        "chorus": .chorus,
        "bridge": .bridge,
        "intro": .intro,
        "outro": .outro,
        "pre-chorus": .preChorus,
        "prechorus": .preChorus,
        "interlude": .interlude,
        "solo": .solo,
        "instrumental": .instrumental,
        "refrain": .refrain
    ]

    // MARK: - Public API

    /// Analyze OCR result and detect layout structure
    /// - Parameters:
    ///   - ocrResult: Raw OCR result with text blocks
    ///   - pageNumber: Page number (for multi-page documents)
    /// - Returns: Detected layout structure
    func analyzeLayout(_ ocrResult: OCRResult, pageNumber: Int = 0) -> LayoutStructure {
        let blocks = ocrResult.recognizedBlocks

        // Detect layout type
        let layoutType = detectLayoutType(blocks: blocks)

        // Extract sections
        let sections = extractSections(blocks: blocks, pageNumber: pageNumber)

        // Map chord placements
        let chordPlacements = mapChordPlacements(blocks: blocks, layoutType: layoutType)

        // Preserve spacing
        let spacingRules = preserveStructure(blocks: blocks)

        return LayoutStructure(
            layoutType: layoutType,
            sections: sections,
            chordPlacements: chordPlacements,
            preservedSpacing: spacingRules
        )
    }

    // MARK: - Layout Type Detection

    /// Detect the type of chord chart layout
    /// - Parameter blocks: Recognized text blocks
    /// - Returns: Detected layout type
    func detectLayoutType(blocks: [OCRResult.RecognizedTextBlock]) -> LayoutType {
        guard !blocks.isEmpty else { return .unknown }

        // Sort blocks by vertical position
        let sortedBlocks = blocks.sorted { $0.boundingBox.minY < $1.boundingBox.minY }

        // Calculate vertical spacings
        var spacings: [CGFloat] = []
        for i in 0..<sortedBlocks.count-1 {
            let gap = sortedBlocks[i+1].boundingBox.minY - sortedBlocks[i].boundingBox.maxY
            spacings.append(gap)
        }

        guard !spacings.isEmpty else { return .unknown }

        // Check for inline brackets [C], [G], etc.
        let hasInlineBrackets = blocks.contains { block in
            block.text.contains("[") && block.text.contains("]")
        }
        if hasInlineBrackets {
            return .inline
        }

        // Check for Nashville numbers (1, 4, 5, etc.)
        let hasNashvillePattern = detectNashvilleNumbers(blocks: blocks)
        if hasNashvillePattern {
            return .nashville
        }

        // Check for tablature (guitar tabs)
        let hasTablature = detectTablature(blocks: blocks)
        if hasTablature {
            return .tablature
        }

        // Check for chord-over-lyric pattern
        // This is characterized by alternating small/large gaps
        let hasAlternatingPattern = detectAlternatingPattern(spacings: spacings)
        if hasAlternatingPattern {
            return .chordOverLyric
        }

        // Default to chord-over-lyric if we detect chord-like patterns
        let hasChordPattern = blocks.contains { block in
            isChordLike(text: block.text)
        }
        return hasChordPattern ? .chordOverLyric : .unknown
    }

    /// Detect alternating spacing pattern (chord-over-lyric indicator)
    private func detectAlternatingPattern(spacings: [CGFloat]) -> Bool {
        guard spacings.count >= 4 else { return false }

        // Look for pattern of small-large-small-large gaps
        var smallLargePattern = 0
        let threshold = spacings.reduce(0, +) / CGFloat(spacings.count) * 0.7

        for i in 0..<spacings.count-1 {
            let current = spacings[i]
            let next = spacings[i+1]

            if current < threshold && next > threshold {
                smallLargePattern += 1
            } else if current > threshold && next < threshold {
                smallLargePattern += 1
            }
        }

        // If more than 50% show alternating pattern
        return smallLargePattern > spacings.count / 2
    }

    /// Detect Nashville number system
    private func detectNashvilleNumbers(blocks: [OCRResult.RecognizedTextBlock]) -> Bool {
        var numberBlockCount = 0

        for block in blocks {
            let trimmed = block.text.trimmingCharacters(in: .whitespaces)
            if trimmed.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil && !trimmed.isEmpty {
                numberBlockCount += 1
            }
        }

        // If more than 40% are pure numbers, likely Nashville
        return numberBlockCount > blocks.count * 4 / 10
    }

    /// Detect guitar tablature
    private func detectTablature(blocks: [OCRResult.RecognizedTextBlock]) -> Bool {
        for block in blocks {
            let text = block.text.lowercased()
            // Look for tab patterns like "e|--0--2--" or "E |---"
            if (text.contains("e|") || text.contains("e |") || text.contains("a|") || text.contains("d|") || text.contains("g|") || text.contains("b|")) &&
               (text.contains("-") || text.contains("0") || text.contains("1") || text.contains("2")) {
                return true
            }
        }

        return false
    }

    /// Check if text looks like a chord
    private func isChordLike(text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Common chord patterns: C, Cm, Cmaj7, C#, Db, etc.
        let validRoots = ["A", "B", "C", "D", "E", "F", "G"]
        _ = ["", "#", "b", "♯", "♭"] // validModifiers for future use
        _ = ["", "m", "M", "maj", "min", "sus", "dim", "aug", "add"] // validQualities for future use

        guard !trimmed.isEmpty else { return false }

        // Check if starts with valid root note
        let firstChar = String(trimmed.prefix(1))
        guard validRoots.contains(firstChar) else { return false }

        // Basic pattern: starts with note letter
        return trimmed.count <= 6 && !trimmed.contains(" ")
    }

    // MARK: - Section Extraction

    /// Extract song sections (Verse, Chorus, Bridge, etc.)
    /// - Parameters:
    ///   - blocks: Recognized text blocks
    ///   - pageNumber: Page number
    /// - Returns: Array of detected sections
    func extractSections(blocks: [OCRResult.RecognizedTextBlock], pageNumber: Int) -> [OCRSongSection] {
        var sections: [OCRSongSection] = []

        // Sort blocks by vertical position
        let sortedBlocks = blocks.sorted { $0.boundingBox.minY < $1.boundingBox.minY }

        var currentSection: OCRSongSection?
        var currentContent: [String] = []
        var currentBoundingBox: CGRect?

        for block in sortedBlocks {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if this is a section header
            if let sectionType = detectSectionType(text: text) {
                // Save previous section
                if let section = currentSection {
                    var finalSection = section
                    finalSection.content = currentContent.joined(separator: "\n")
                    if let bbox = currentBoundingBox {
                        finalSection.boundingBox = bbox
                    }
                    sections.append(finalSection)
                }

                // Start new section
                currentSection = OCRSongSection(
                    type: sectionType,
                    content: "",
                    boundingBox: block.boundingBox,
                    pageNumber: pageNumber
                )
                currentContent = []
                currentBoundingBox = block.boundingBox
            } else {
                // Add to current section content
                currentContent.append(text)

                // Expand bounding box
                if let bbox = currentBoundingBox {
                    currentBoundingBox = bbox.union(block.boundingBox)
                } else {
                    currentBoundingBox = block.boundingBox
                }
            }
        }

        // Save last section
        if let section = currentSection {
            var finalSection = section
            finalSection.content = currentContent.joined(separator: "\n")
            if let bbox = currentBoundingBox {
                finalSection.boundingBox = bbox
            }
            sections.append(finalSection)
        } else if !currentContent.isEmpty {
            // No explicit sections found, create one unknown section
            sections.append(OCRSongSection(
                type: .unknown,
                content: currentContent.joined(separator: "\n"),
                boundingBox: currentBoundingBox ?? .zero,
                pageNumber: pageNumber
            ))
        }

        return sections
    }

    /// Detect section type from text
    private func detectSectionType(text: String) -> OCRSectionType? {
        let lowercased = text.lowercased()

        // Check for exact or partial matches with section keywords
        for (keyword, type) in sectionKeywords {
            if lowercased.contains(keyword) {
                return type
            }
        }

        return nil
    }

    // MARK: - Chord Placement Mapping

    /// Map chord placements to lyrics
    /// - Parameters:
    ///   - blocks: Recognized text blocks
    ///   - layoutType: Detected layout type
    /// - Returns: Array of chord placements
    func mapChordPlacements(blocks: [OCRResult.RecognizedTextBlock], layoutType: LayoutType) -> [ChordPlacement] {
        var placements: [ChordPlacement] = []

        guard layoutType == .chordOverLyric else {
            // For inline or other layouts, extract chords differently
            return extractInlineChords(blocks: blocks)
        }

        // Sort blocks by vertical position
        let sortedBlocks = blocks.sorted { $0.boundingBox.minY < $1.boundingBox.minY }

        // Look for chord-lyric pairs
        for i in 0..<sortedBlocks.count {
            let block = sortedBlocks[i]

            // Check if this looks like a chord line
            if isChordLine(block: block) {
                // Try to find the lyric line below it
                let lyricBlock = findLyricLineBelow(chordBlock: block, allBlocks: sortedBlocks, startIndex: i)

                let chords = extractChordsFromLine(block.text)
                for chord in chords {
                    placements.append(ChordPlacement(
                        chord: chord.text,
                        position: CGPoint(
                            x: (block.boundingBox.minX + chord.relativePosition) / 1.0,
                            y: block.boundingBox.minY
                        ),
                        alignedWithLyric: lyricBlock?.text,
                        confidence: block.confidence
                    ))
                }
            }
        }

        return placements
    }

    /// Check if a block is a chord line
    private func isChordLine(block: OCRResult.RecognizedTextBlock) -> Bool {
        let words = block.text.split(separator: " ")

        guard !words.isEmpty else { return false }

        // If more than 60% of words look like chords, it's a chord line
        let chordCount = words.filter { isChordLike(text: String($0)) }.count
        return chordCount > words.count * 6 / 10
    }

    /// Find lyric line below a chord line
    private func findLyricLineBelow(chordBlock: OCRResult.RecognizedTextBlock, allBlocks: [OCRResult.RecognizedTextBlock], startIndex: Int) -> OCRResult.RecognizedTextBlock? {
        // Look for the next block that's not a chord line
        for i in (startIndex + 1)..<allBlocks.count {
            let block = allBlocks[i]

            // Must be close vertically
            let verticalGap = block.boundingBox.minY - chordBlock.boundingBox.maxY
            guard verticalGap < 0.05 else { break } // Too far

            // Must not be a chord line
            if !isChordLine(block: block) {
                return block
            }
        }

        return nil
    }

    /// Extract chords from a chord line with positions
    private func extractChordsFromLine(_ line: String) -> [(text: String, relativePosition: CGFloat)] {
        var chords: [(String, CGFloat)] = []
        let words = line.split(separator: " ")

        var position: CGFloat = 0.0
        let increment = 1.0 / CGFloat(max(words.count, 1))

        for word in words {
            let wordStr = String(word)
            if isChordLike(text: wordStr) {
                chords.append((wordStr, position))
            }
            position += increment
        }

        return chords
    }

    /// Extract inline chords (format: [C] lyrics [G] more lyrics)
    private func extractInlineChords(blocks: [OCRResult.RecognizedTextBlock]) -> [ChordPlacement] {
        var placements: [ChordPlacement] = []

        for block in blocks {
            // Find patterns like [C], [Gm], [Dmaj7] in brackets
            let text = block.text
            var searchRange = text.startIndex..<text.endIndex

            while let openBracket = text.range(of: "[", range: searchRange) {
                searchRange = openBracket.upperBound..<text.endIndex
                if let closeBracket = text.range(of: "]", range: searchRange) {
                    let chordText = String(text[openBracket.upperBound..<closeBracket.lowerBound])
                    if isChordLike(text: chordText) {
                        placements.append(ChordPlacement(
                            chord: chordText,
                            position: CGPoint(x: block.boundingBox.minX, y: block.boundingBox.minY),
                            alignedWithLyric: block.text,
                            confidence: block.confidence
                        ))
                    }
                    searchRange = closeBracket.upperBound..<text.endIndex
                } else {
                    break
                }
            }
        }

        return placements
    }

    // MARK: - Structure Preservation

    /// Preserve spacing and indentation structure
    /// - Parameter blocks: Recognized text blocks
    /// - Returns: Array of spacing rules
    func preserveStructure(blocks: [OCRResult.RecognizedTextBlock]) -> [SpacingRule] {
        var rules: [SpacingRule] = []

        // Sort blocks by vertical position
        let sortedBlocks = blocks.sorted { $0.boundingBox.minY < $1.boundingBox.minY }

        for (index, block) in sortedBlocks.enumerated() {
            let indentation = Float(block.boundingBox.minX)

            var topSpacing: Float = 0.0
            if index > 0 {
                let previousBlock = sortedBlocks[index - 1]
                topSpacing = Float(block.boundingBox.minY - previousBlock.boundingBox.maxY)
            }

            rules.append(SpacingRule(
                lineNumber: index,
                indentation: indentation,
                topSpacing: topSpacing
            ))
        }

        return rules
    }

    // MARK: - Utility Methods

    /// Convert layout structure to ChordPro format
    func convertToChordPro(layout: LayoutStructure, text: String) -> String {
        var chordProLines: [String] = []

        // Add metadata
        chordProLines.append("{title: Untitled}")
        chordProLines.append("")

        // Process sections
        for section in layout.sections {
            // Add section marker
            if section.type != .unknown {
                let firstLine = section.content.split(separator: "\n").first ?? ""
                chordProLines.append("{\(section.type.rawValue): \(firstLine)}")
            }

            // Add content
            let lines = section.content.split(separator: "\n")
            for line in lines {
                chordProLines.append(String(line))
            }

            chordProLines.append("") // Blank line between sections
        }

        return chordProLines.joined(separator: "\n")
    }
}
