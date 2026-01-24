//
//  SectionDetector.swift
//  Lyra
//
//  Detects song sections (verse, chorus, bridge) from chord patterns
//  Part of Phase 7: Audio Intelligence
//

import Foundation

/// Detects repeated chord patterns to identify song sections
class SectionDetector {

    // MARK: - Properties

    private let minSectionDuration: TimeInterval = 8.0 // Minimum section length
    private let minChordSequenceLength: Int = 4 // Minimum chords for a pattern

    // MARK: - Public API

    /// Detect sections from detected chords
    func detectSections(from chords: [DetectedChord]) -> [DetectedSection] {
        guard chords.count >= minChordSequenceLength else { return [] }

        // Find repeating chord patterns
        let patterns = findRepeatingPatterns(in: chords)

        // Classify patterns into sections
        let sections = classifyPatterns(patterns, chords: chords)

        return sections
    }

    // MARK: - Pattern Detection

    /// Find repeating chord patterns in the song
    private func findRepeatingPatterns(in chords: [DetectedChord]) -> [ChordPattern] {
        var patterns: [ChordPattern] = []

        // Try different pattern lengths
        for length in minChordSequenceLength...min(12, chords.count / 2) {
            let foundPatterns = findPatternsOfLength(length, in: chords)
            patterns.append(contentsOf: foundPatterns)
        }

        // Remove overlapping patterns, keeping longer/more confident ones
        return consolidatePatterns(patterns)
    }

    /// Find patterns of a specific length
    private func findPatternsOfLength(_ length: Int, in chords: [DetectedChord]) -> [ChordPattern] {
        var patterns: [ChordPattern] = []
        var seenPatterns: Set<String> = []

        for i in 0...(chords.count - length) {
            let sequence = chords[i..<(i + length)]
            let patternKey = sequence.map { $0.chord }.joined(separator: "-")

            // Skip if we've seen this pattern
            if seenPatterns.contains(patternKey) {
                continue
            }
            seenPatterns.insert(patternKey)

            // Find all occurrences of this pattern
            let occurrences = findOccurrences(of: Array(sequence), in: chords)

            // Pattern must repeat at least twice
            if occurrences.count >= 2 {
                let pattern = ChordPattern(
                    chords: Array(sequence.map { $0.chord }),
                    occurrences: occurrences,
                    confidence: calculatePatternConfidence(occurrences)
                )
                patterns.append(pattern)
            }
        }

        return patterns
    }

    /// Find all occurrences of a chord sequence
    private func findOccurrences(of sequence: [DetectedChord], in chords: [DetectedChord]) -> [PatternOccurrence] {
        var occurrences: [PatternOccurrence] = []
        let sequenceChords = sequence.map { $0.chord }

        for i in 0...(chords.count - sequence.count) {
            let candidate = chords[i..<(i + sequence.count)].map { $0.chord }

            if candidate == sequenceChords {
                let startPosition = chords[i].position
                let endPosition = i + sequence.count < chords.count
                    ? chords[i + sequence.count].position
                    : chords.last!.position + chords.last!.duration

                occurrences.append(PatternOccurrence(
                    startIndex: i,
                    startPosition: startPosition,
                    endPosition: endPosition
                ))
            }
        }

        return occurrences
    }

    /// Calculate confidence score for a pattern based on its occurrences
    private func calculatePatternConfidence(_ occurrences: [PatternOccurrence]) -> Float {
        // More occurrences = higher confidence
        let occurrenceScore = min(1.0, Float(occurrences.count) / 4.0)

        // More consistent duration = higher confidence
        let durations = occurrences.map { $0.duration }
        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.map { pow($0 - averageDuration, 2) }.reduce(0, +) / Double(durations.count)
        let consistencyScore = max(0.0, 1.0 - Float(variance / 100.0))

        return (occurrenceScore + consistencyScore) / 2.0
    }

    /// Remove overlapping patterns, keeping the best ones
    private func consolidatePatterns(_ patterns: [ChordPattern]) -> [ChordPattern] {
        guard !patterns.isEmpty else { return [] }

        // Sort by confidence and length
        let sorted = patterns.sorted {
            if $0.confidence != $1.confidence {
                return $0.confidence > $1.confidence
            }
            return $0.chords.count > $1.chords.count
        }

        var result: [ChordPattern] = []
        var usedRanges: [(start: Int, end: Int)] = []

        for pattern in sorted {
            var hasOverlap = false

            for occurrence in pattern.occurrences {
                let range = (start: occurrence.startIndex, end: occurrence.startIndex + pattern.chords.count)

                // Check if this range overlaps with any used range
                for usedRange in usedRanges {
                    if rangesOverlap(range, usedRange) {
                        hasOverlap = true
                        break
                    }
                }

                if hasOverlap {
                    break
                }
            }

            if !hasOverlap {
                result.append(pattern)
                for occurrence in pattern.occurrences {
                    usedRanges.append((
                        start: occurrence.startIndex,
                        end: occurrence.startIndex + pattern.chords.count
                    ))
                }
            }
        }

        return result
    }

    /// Check if two ranges overlap
    private func rangesOverlap(_ a: (start: Int, end: Int), _ b: (start: Int, end: Int)) -> Bool {
        return a.start < b.end && b.start < a.end
    }

    // MARK: - Section Classification

    /// Classify patterns into section types (verse, chorus, bridge)
    private func classifyPatterns(_ patterns: [ChordPattern], chords: [DetectedChord]) -> [DetectedSection] {
        var sections: [DetectedSection] = []

        // Sort patterns by first occurrence
        let sortedPatterns = patterns.sorted {
            $0.occurrences.first!.startPosition < $1.occurrences.first!.startPosition
        }

        // Assign section types based on repetition and position
        for (index, pattern) in sortedPatterns.enumerated() {
            let sectionType = determineSectionType(
                pattern: pattern,
                index: index,
                totalPatterns: sortedPatterns.count
            )

            // Create sections for each occurrence
            for (occurrenceIndex, occurrence) in pattern.occurrences.enumerated() {
                let section = DetectedSection(
                    type: sectionType,
                    startPosition: occurrence.startPosition,
                    endPosition: occurrence.endPosition,
                    chordPattern: pattern.chords,
                    confidence: pattern.confidence
                )
                sections.append(section)
            }
        }

        // Sort sections by start position
        return sections.sorted { $0.startPosition < $1.startPosition }
    }

    /// Determine section type based on pattern characteristics
    private func determineSectionType(pattern: ChordPattern, index: Int, totalPatterns: Int) -> SectionType {
        let occurrenceCount = pattern.occurrences.count

        // Chorus: typically repeats most often (3+ times)
        if occurrenceCount >= 3 {
            return .chorus
        }

        // Bridge: typically appears once, often near the end
        if occurrenceCount == 1 && index > totalPatterns / 2 {
            return .bridge
        }

        // Intro/Outro: at beginning or end
        if let firstOccurrence = pattern.occurrences.first {
            if firstOccurrence.startPosition < 10.0 {
                return .intro
            }
        }

        // Default to verse
        return .verse
    }
}

// MARK: - Supporting Types

private struct ChordPattern {
    let chords: [String]
    let occurrences: [PatternOccurrence]
    let confidence: Float
}

private struct PatternOccurrence {
    let startIndex: Int
    let startPosition: TimeInterval
    let endPosition: TimeInterval

    var duration: TimeInterval {
        endPosition - startPosition
    }
}

// MARK: - Extensions

extension SectionType {
    var chordProDirective: String {
        switch self {
        case .intro: return "intro"
        case .verse: return "verse"
        case .chorus: return "chorus"
        case .bridge: return "bridge"
        case .interlude: return "interlude"
        case .outro: return "outro"
        case .prechorus: return "prechorus"
        case .solo: return "solo"
        case .instrumental: return "instrumental"
        case .coda: return "coda"
        case .tag: return "tag"
        case .unknown: return "verse"
        }
    }
}
