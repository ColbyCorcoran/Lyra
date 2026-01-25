//
//  FormattingManager.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Orchestrates all formatting engines
//
//  Created by Claude AI on 1/24/26.
//

import Foundation
import SwiftData

/// Orchestrates all formatting engines to provide unified formatting API
@MainActor
@Observable
class FormattingManager {

    // MARK: - Properties

    var isProcessing = false
    var progress: Double = 0

    private let structureEngine = StructureDetectionEngine()
    private let autoFormatEngine = AutoFormattingEngine()
    private let patternEngine = PatternRecognitionEngine()
    private let chordEngine = ChordExtractionEngine()
    private let metadataEngine = MetadataExtractionEngine()
    private let qualityEngine = QualityScoringEngine()

    // MARK: - Public Methods

    /// Format a single song
    func formatSong(_ text: String, options: FormattingOptions = .standard) async -> FormattingResult {
        isProcessing = true
        progress = 0

        // Analyze original
        let originalQuality = qualityEngine.calculateQualityScore(text)
        progress = 0.2

        // Detect structure
        let structure = structureEngine.detectStructure(text)
        progress = 0.3

        // Detect pattern
        let pattern = patternEngine.detectPattern(text)
        progress = 0.4

        // Extract chords
        let chords = chordEngine.getUniqueChords(text)
        progress = 0.5

        // Extract metadata
        let metadata = metadataEngine.extractMetadata(text)
        progress = 0.6

        // Apply formatting
        var formatted = text
        if options.fixSpacing || options.removeExtraBlankLines || options.alignChords {
            formatted = autoFormatEngine.autoFormat(formatted, options: options)
        }
        progress = 0.7

        // Auto-label sections if enabled
        var finalStructure = structure
        if options.autoLabelSections {
            finalStructure = structureEngine.autoLabelSections(structure)
            formatted = applyStructureLabels(formatted, structure: finalStructure)
        }
        progress = 0.8

        // Standardize chords if enabled
        if options.standardizeChords && pattern != .unknown && pattern != options.targetPattern {
            formatted = patternEngine.convertToChordPro(formatted, from: pattern)
        }
        progress = 0.9

        // Calculate new quality
        let newQuality = qualityEngine.calculateQualityScore(formatted)

        // Generate suggestions
        let suggestions = qualityEngine.generateSuggestions(newQuality)

        // Track changes
        let changes = detectChanges(original: text, formatted: formatted)

        progress = 1.0
        isProcessing = false

        return FormattingResult(
            originalText: text,
            formattedText: formatted,
            detectedStructure: finalStructure,
            detectedPattern: pattern,
            extractedChords: chords,
            extractedMetadata: metadata,
            qualityScore: newQuality,
            suggestions: suggestions,
            changes: changes
        )
    }

    /// Batch format multiple songs
    func batchFormat(
        _ songs: [Song],
        options: FormattingOptions = .standard,
        progressHandler: ((Double) -> Void)? = nil
    ) async -> BatchFormattingResult {
        isProcessing = true
        var results: [UUID: FormattingResult] = [:]
        var successCount = 0
        var failureCount = 0
        var totalQualityImprovement: Float = 0
        var totalIssuesFixed = 0

        for (index, song) in songs.enumerated() {
            do {
                let result = await formatSong(song.content, options: options)
                results[song.id] = result
                successCount += 1

                // Calculate improvement
                let originalQuality = qualityEngine.calculateQualityScore(song.content)
                let improvement = result.qualityScore.overall - originalQuality.overall
                totalQualityImprovement += improvement
                totalIssuesFixed += result.changes.count

            } catch {
                failureCount += 1
            }

            // Update progress
            let currentProgress = Double(index + 1) / Double(songs.count)
            progress = currentProgress
            progressHandler?(currentProgress)
        }

        isProcessing = false

        let avgImprovement = successCount > 0 ? totalQualityImprovement / Float(successCount) : 0

        return BatchFormattingResult(
            totalSongs: songs.count,
            successCount: successCount,
            failureCount: failureCount,
            results: results,
            averageQualityImprovement: avgImprovement,
            totalIssuesFixed: totalIssuesFixed
        )
    }

    /// Preview formatting changes without applying
    func previewFormatting(_ text: String, options: FormattingOptions = .standard) -> FormattingResult {
        let quality = qualityEngine.calculateQualityScore(text)
        let structure = structureEngine.detectStructure(text)
        let pattern = patternEngine.detectPattern(text)
        let chords = chordEngine.getUniqueChords(text)
        let metadata = metadataEngine.extractMetadata(text)
        let suggestions = qualityEngine.generateSuggestions(quality)

        return FormattingResult(
            originalText: text,
            formattedText: text,  // No changes yet
            detectedStructure: structure,
            detectedPattern: pattern,
            extractedChords: chords,
            extractedMetadata: metadata,
            qualityScore: quality,
            suggestions: suggestions,
            changes: []
        )
    }

    /// Apply specific fixes
    func applyFixes(_ text: String, issues: [QualityIssue]) -> String {
        var fixed = text

        for issue in issues where issue.autoFixable {
            switch issue.type {
            case .inconsistentSpacing:
                fixed = autoFormatEngine.cleanupSpacing(fixed)
            case .duplicateBlankLines:
                fixed = autoFormatEngine.removeExtraBlankLines(fixed)
            case .misalignedChords:
                fixed = autoFormatEngine.alignChords(fixed)
            case .inconsistentChordFormat:
                let pattern = patternEngine.detectPattern(fixed)
                fixed = patternEngine.convertToChordPro(fixed, from: pattern)
            case .missingSection:
                let structure = structureEngine.detectStructure(fixed)
                let labeled = structureEngine.autoLabelSections(structure)
                fixed = applyStructureLabels(fixed, structure: labeled)
            default:
                break
            }
        }

        return fixed
    }

    /// Get quality score for text
    func getQualityScore(_ text: String) -> QualityScore {
        qualityEngine.calculateQualityScore(text)
    }

    // MARK: - Private Helpers

    private func applyStructureLabels(_ text: String, structure: FormattingSongStructure) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var sectionIndex = 0

        for (lineIndex, line) in lines.enumerated() {
            // Check if we're at a section boundary
            if sectionIndex < structure.sections.count {
                let section = structure.sections[sectionIndex]

                // If we're at the start of a section, add label
                if lineIndex == section.startLine && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Only add label if not already present
                    if !line.lowercased().contains(section.type.rawValue.lowercased()) {
                        result.append("\(section.label):")
                        result.append("")  // Blank line after label
                    }
                }
            }

            result.append(line)

            // Check if we've finished a section
            if sectionIndex < structure.sections.count {
                let section = structure.sections[sectionIndex]
                if lineIndex == section.endLine {
                    sectionIndex += 1
                }
            }
        }

        return result.joined(separator: "\n")
    }

    private func detectChanges(original: String, formatted: String) -> [FormattingChange] {
        var changes: [FormattingChange] = []

        // Compare line counts
        let originalLines = original.components(separatedBy: .newlines)
        let formattedLines = formatted.components(separatedBy: .newlines)

        if originalLines.count != formattedLines.count {
            let diff = formattedLines.count - originalLines.count
            if diff < 0 {
                changes.append(FormattingChange(
                    type: .removedBlankLines,
                    description: "Removed \(abs(diff)) blank lines",
                    before: "\(originalLines.count) lines",
                    after: "\(formattedLines.count) lines"
                ))
            } else if diff > 0 {
                changes.append(FormattingChange(
                    type: .addedSection,
                    description: "Added \(diff) section labels",
                    before: "\(originalLines.count) lines",
                    after: "\(formattedLines.count) lines"
                ))
            }
        }

        // Compare patterns
        let originalPattern = patternEngine.detectPattern(original)
        let formattedPattern = patternEngine.detectPattern(formatted)

        if originalPattern != formattedPattern && formattedPattern == .chordPro {
            changes.append(FormattingChange(
                type: .convertedPattern,
                description: "Converted from \(originalPattern.displayName) to ChordPro",
                before: originalPattern.displayName,
                after: formattedPattern.displayName
            ))
        }

        // Check for spacing changes
        let originalHasTrailing = original.contains(where: { $0 == " " && original.suffix(1) == " " })
        let formattedHasTrailing = formatted.contains(where: { $0 == " " && formatted.suffix(1) == " " })

        if originalHasTrailing && !formattedHasTrailing {
            changes.append(FormattingChange(
                type: .fixedSpacing,
                description: "Removed trailing whitespace",
                before: "Trailing spaces present",
                after: "No trailing spaces"
            ))
        }

        return changes
    }
}

// MARK: - Song Model Extension

extension Song {
    /// Get formatting quality score
    func getFormattingQuality() -> QualityScore {
        let manager = FormattingManager()
        return manager.getQualityScore(self.content)
    }
}
