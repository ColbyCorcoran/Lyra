//
//  MultiPageEngine.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Engine 5
//  Multi-page document handling and stitching
//

import Foundation
import UIKit

/// Engine for handling multi-page chord chart documents
@MainActor
class MultiPageEngine {

    // MARK: - Properties

    private let layoutAnalyzer = LayoutAnalysisEngine()

    // Section keywords that might span pages
    private let sectionKeywords = ["verse", "chorus", "bridge", "intro", "outro", "pre-chorus", "interlude", "solo"]

    // MARK: - Public API

    /// Stitch multiple pages together into a cohesive document
    /// - Parameter results: Array of OCR results, one per page
    /// - Returns: Combined result with page information preserved
    func stitchPages(_ results: [EnhancedOCRResult]) -> EnhancedOCRResult {
        guard !results.isEmpty else {
            return createEmptyResult()
        }

        guard results.count > 1 else {
            // Single page, no stitching needed
            return results[0]
        }

        // Detect continuations across pages
        let continuations = detectContinuations(results)

        // Stitch text with smart page breaks
        let stitchedText = stitchText(results: results, continuations: continuations)

        // Merge layouts
        let mergedLayout = mergeLayouts(results: results)

        // Combine confidence scores
        let avgConfidence = calculateAverageConfidence(results: results)

        // Merge review items
        let allReviewItems = results.flatMap { $0.reviewItems }

        // Create combined metadata
        let totalProcessingTime = results.reduce(0.0) { $0 + $1.processingMetadata.processingTime }
        let combinedMetadata = ProcessingMetadata(
            processingTime: totalProcessingTime,
            engineUsed: results.first?.processingMetadata.engineUsed ?? "Vision",
            enhancementsApplied: Array(Set(results.flatMap { $0.processingMetadata.enhancementsApplied })),
            pageCount: results.count,
            timestamp: Date()
        )

        // Create combined result
        return EnhancedOCRResult(
            originalImage: results.first?.originalImage,
            enhancedImage: results.first?.enhancedImage,
            rawOCRResult: combineOCRResults(results.map { $0.rawOCRResult }),
            correctedText: stitchedText,
            layoutStructure: mergedLayout,
            confidenceBreakdown: avgConfidence,
            reviewItems: allReviewItems,
            processingMetadata: combinedMetadata
        )
    }

    /// Detect page continuations (sections that span pages)
    /// - Parameter results: Array of page results
    /// - Returns: Array of continuation information
    func detectContinuations(_ results: [EnhancedOCRResult]) -> [PageContinuation] {
        var continuations: [PageContinuation] = []

        for i in 0..<results.count-1 {
            let currentPage = results[i]
            let nextPage = results[i+1]

            // Check if last section of current page continues on next page
            if let continuation = detectSectionContinuation(
                currentPage: currentPage,
                nextPage: nextPage,
                pageNumber: i
            ) {
                continuations.append(continuation)
            }
        }

        return continuations
    }

    /// Insert smart page breaks in the combined text
    /// - Parameters:
    ///   - results: Array of page results
    ///   - continuations: Detected continuations
    /// - Returns: Combined text with appropriate page breaks
    func insertPageBreaks(results: [EnhancedOCRResult], continuations: [PageContinuation]) -> String {
        var combinedText = ""

        for (index, result) in results.enumerated() {
            combinedText += result.correctedText

            // Check if this page continues to next
            let hasContinuation = continuations.contains { $0.pageNumber == index }

            if index < results.count - 1 {
                if hasContinuation {
                    // Continuation - no page break marker, just newline
                    combinedText += "\n"
                } else {
                    // New section - insert page break
                    combinedText += "\n\n--- Page \(index + 2) ---\n\n"
                }
            }
        }

        return combinedText
    }

    /// Remove duplicate headers/footers across pages
    /// - Parameter results: Array of page results
    /// - Returns: Results with duplicates removed
    func removeDuplicates(_ results: [EnhancedOCRResult]) -> [EnhancedOCRResult] {
        var cleaned: [EnhancedOCRResult] = []

        for (index, result) in results.enumerated() {
            var cleanedResult = result

            // Remove headers (top 10% of page)
            let headerText = extractHeader(from: result)

            // Remove footers (bottom 10% of page)
            let footerText = extractFooter(from: result)

            // Check if header/footer appears on other pages
            if index > 0 {
                let previousHeader = extractHeader(from: results[index - 1])
                let previousFooter = extractFooter(from: results[index - 1])

                // Remove if duplicate
                var text = result.correctedText
                if !headerText.isEmpty && headerText == previousHeader {
                    text = text.replacingOccurrences(of: headerText, with: "", options: [.anchored])
                }
                if !footerText.isEmpty && footerText == previousFooter {
                    text = removeFooter(from: text, footer: footerText)
                }

                cleanedResult.correctedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            cleaned.append(cleanedResult)
        }

        return cleaned
    }

    // MARK: - Private Helper Methods

    /// Detect if a section continues from one page to the next
    private func detectSectionContinuation(currentPage: EnhancedOCRResult, nextPage: EnhancedOCRResult, pageNumber: Int) -> PageContinuation? {
        let currentSections = currentPage.layoutStructure.sections
        let nextSections = nextPage.layoutStructure.sections

        guard !currentSections.isEmpty, !nextSections.isEmpty else { return nil }

        // Check last section of current page
        let lastSection = currentSections.last!

        // Check first section of next page
        let firstSection = nextSections.first!

        // If sections have the same type or first section has no type (continuation)
        if lastSection.type == firstSection.type || firstSection.type == .unknown {
            return PageContinuation(
                pageNumber: pageNumber,
                sectionType: lastSection.type,
                continuesTo: pageNumber + 1
            )
        }

        // Check if last line ends mid-sentence (no period, no colon)
        let lastLine = lastSection.content.components(separatedBy: "\n").last ?? ""
        let endsWithPunctuation = lastLine.hasSuffix(".") || lastLine.hasSuffix(":") || lastLine.hasSuffix("?") || lastLine.hasSuffix("!")

        if !endsWithPunctuation && !lastLine.isEmpty {
            return PageContinuation(
                pageNumber: pageNumber,
                sectionType: lastSection.type,
                continuesTo: pageNumber + 1
            )
        }

        return nil
    }

    /// Stitch text from multiple pages
    private func stitchText(results: [EnhancedOCRResult], continuations: [PageContinuation]) -> String {
        return insertPageBreaks(results: results, continuations: continuations)
    }

    /// Merge layouts from multiple pages
    private func mergeLayouts(results: [EnhancedOCRResult]) -> LayoutStructure {
        var allSections: [SongSection] = []
        var allChordPlacements: [ChordPlacement] = []
        var allSpacingRules: [SpacingRule] = []

        // Detect overall layout type (use most common)
        let layoutTypes = results.map { $0.layoutStructure.layoutType }
        let layoutType = mostCommon(layoutTypes) ?? .unknown

        for (pageIndex, result) in results.enumerated() {
            // Add sections with updated page numbers
            var pageSections = result.layoutStructure.sections
            for i in 0..<pageSections.count {
                pageSections[i].pageNumber = pageIndex
            }
            allSections.append(contentsOf: pageSections)

            // Add chord placements
            allChordPlacements.append(contentsOf: result.layoutStructure.chordPlacements)

            // Add spacing rules
            allSpacingRules.append(contentsOf: result.layoutStructure.preservedSpacing)
        }

        return LayoutStructure(
            layoutType: layoutType,
            sections: allSections,
            chordPlacements: allChordPlacements,
            preservedSpacing: allSpacingRules
        )
    }

    /// Calculate average confidence across pages
    private func calculateAverageConfidence(results: [EnhancedOCRResult]) -> ConfidenceBreakdown {
        guard !results.isEmpty else {
            return ConfidenceBreakdown(
                imageQuality: 0.0,
                ocrAccuracy: 0.0,
                contextValidation: 0.0,
                overallConfidence: 0.0
            )
        }

        let totalImageQuality = results.reduce(0.0) { $0 + $1.confidenceBreakdown.imageQuality }
        let totalOCRAccuracy = results.reduce(0.0) { $0 + $1.confidenceBreakdown.ocrAccuracy }
        let totalContextValidation = results.reduce(0.0) { $0 + $1.confidenceBreakdown.contextValidation }

        let count = Float(results.count)

        let avgImageQuality = totalImageQuality / count
        let avgOCRAccuracy = totalOCRAccuracy / count
        let avgContextValidation = totalContextValidation / count

        return ConfidenceBreakdown(
            imageQuality: avgImageQuality,
            ocrAccuracy: avgOCRAccuracy,
            contextValidation: avgContextValidation,
            overallConfidence: ConfidenceBreakdown.calculate(
                imageQuality: avgImageQuality,
                ocrAccuracy: avgOCRAccuracy,
                contextValidation: avgContextValidation
            )
        )
    }

    /// Combine multiple OCR results into one
    private func combineOCRResults(_ results: [OCRResult]) -> OCRResult {
        let combinedText = results.map { $0.text }.joined(separator: "\n\n--- Page Break ---\n\n")
        let allBlocks = results.flatMap { $0.recognizedBlocks }
        let avgConfidence = results.isEmpty ? 0.0 : results.reduce(0.0) { $0 + $1.confidence } / Float(results.count)

        return OCRResult(
            text: combinedText,
            confidence: avgConfidence,
            recognizedBlocks: allBlocks
        )
    }

    /// Extract header text (top 10% of page)
    private func extractHeader(from result: EnhancedOCRResult) -> String {
        let blocks = result.rawOCRResult.recognizedBlocks
            .filter { $0.boundingBox.minY < 0.1 }
            .sorted { $0.boundingBox.minY < $1.boundingBox.minY }

        return blocks.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extract footer text (bottom 10% of page)
    private func extractFooter(from result: EnhancedOCRResult) -> String {
        let blocks = result.rawOCRResult.recognizedBlocks
            .filter { $0.boundingBox.maxY > 0.9 }
            .sorted { $0.boundingBox.minY < $1.boundingBox.minY }

        return blocks.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Remove footer from text
    private func removeFooter(from text: String, footer: String) -> String {
        if text.hasSuffix(footer) {
            return String(text.dropLast(footer.count))
        }
        return text
    }

    /// Find most common element in array
    private func mostCommon<T: Hashable>(_ array: [T]) -> T? {
        let counts = Dictionary(grouping: array) { $0 }.mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key
    }

    /// Create empty result
    private func createEmptyResult() -> EnhancedOCRResult {
        return EnhancedOCRResult(
            rawOCRResult: OCRResult(text: "", confidence: 0.0, recognizedBlocks: []),
            correctedText: "",
            layoutStructure: LayoutStructure(
                layoutType: .unknown,
                sections: [],
                chordPlacements: [],
                preservedSpacing: []
            ),
            confidenceBreakdown: ConfidenceBreakdown(
                imageQuality: 0.0,
                ocrAccuracy: 0.0,
                contextValidation: 0.0,
                overallConfidence: 0.0
            ),
            reviewItems: [],
            processingMetadata: ProcessingMetadata(
                processingTime: 0.0,
                engineUsed: "None",
                enhancementsApplied: [],
                pageCount: 0,
                timestamp: Date()
            )
        )
    }
}

// MARK: - Supporting Types

/// Information about a page continuation
struct PageContinuation {
    let pageNumber: Int
    let sectionType: SongSection.SectionType
    let continuesTo: Int
}
