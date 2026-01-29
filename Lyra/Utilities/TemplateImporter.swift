//
//  TemplateImporter.swift
//  Lyra
//
//  PDF Template Import Engine - Extracts layout and typography from documents
//

import Foundation
import SwiftData
import PDFKit
import UIKit

// MARK: - Supporting Structures

/// Represents text extracted from a PDF with position information
struct TextElement {
    let text: String
    let bounds: CGRect
    let fontSize: CGFloat

    var x: CGFloat { bounds.minX }
    var y: CGFloat { bounds.minY }
    var width: CGFloat { bounds.width }
    var height: CGFloat { bounds.height }
}

/// Detected column structure from PDF analysis
struct ColumnStructure {
    let columnCount: Int           // 1-4
    let columnGaps: [CGFloat]      // Gaps between columns
    let columnWidths: [CGFloat]    // Width of each column
    let pageWidth: CGFloat         // Total page width

    var averageGap: CGFloat {
        guard !columnGaps.isEmpty else { return 0 }
        return columnGaps.reduce(0, +) / CGFloat(columnGaps.count)
    }
}

/// Typography profile extracted from document
struct TypographyProfile {
    let titleFontSize: CGFloat
    let headingFontSize: CGFloat
    let bodyFontSize: CGFloat
    let chordFontSize: CGFloat
}

/// Complete layout analysis of a document
struct DocumentLayout {
    let columnStructure: ColumnStructure
    let typography: TypographyProfile
    let chordStyle: ChordPositioningStyle
}

// MARK: - Error Handling

enum TemplateImportError: LocalizedError {
    case noPDFDocument
    case analysisError
    case invalidLayout
    case noContentFound
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .noPDFDocument:
            return "Unable to read PDF document"
        case .analysisError:
            return "Failed to analyze document layout"
        case .invalidLayout:
            return "Document layout could not be determined"
        case .noContentFound:
            return "No content found in document"
        case .unsupportedFormat:
            return "Document format not supported"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noPDFDocument:
            return "The PDF file may be corrupted or password-protected."
        case .analysisError:
            return "Try a different document or create a template manually."
        case .invalidLayout:
            return "The document structure is too complex to analyze automatically."
        case .noContentFound:
            return "The document may be empty or contain only images."
        case .unsupportedFormat:
            return "Only PDF files are supported at this time."
        }
    }
}

// MARK: - Template Importer

@MainActor
class TemplateImporter {

    // MARK: - PDF Import

    /// Import a template from a PDF document
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - name: Name for the new template
    ///   - context: SwiftData ModelContext
    /// - Returns: The created template
    static func importFromPDF(
        url: URL,
        name: String,
        context: ModelContext
    ) async throws -> Template {
        // Load PDF document
        guard let document = PDFDocument(url: url) else {
            throw TemplateImportError.noPDFDocument
        }

        // Analyze the first page (assume consistent layout throughout)
        guard let firstPage = document.page(at: 0) else {
            throw TemplateImportError.noContentFound
        }

        // Extract and analyze layout
        let layout = try analyzePDFLayout(firstPage)

        // Map to Template model
        let template = mapToTemplate(
            layout: layout,
            name: name,
            context: context
        )

        // Validate the template
        guard template.isValid else {
            throw TemplateImportError.invalidLayout
        }

        // Save to context
        context.insert(template)
        try context.save()

        return template
    }

    // MARK: - PDF Analysis

    /// Analyze PDF layout to extract column structure and typography
    /// - Parameter page: PDF page to analyze
    /// - Returns: Analyzed document layout
    static func analyzePDFLayout(_ page: PDFPage) throws -> DocumentLayout {
        // Extract text elements with position information
        let textElements = extractTextElements(from: page)

        guard !textElements.isEmpty else {
            throw TemplateImportError.noContentFound
        }

        let pageBounds = page.bounds(for: .mediaBox)
        let pageWidth = pageBounds.width

        // Detect column structure
        let columnStructure = detectColumnStructure(textElements, pageWidth: pageWidth)

        // Extract typography
        let typography = extractTypography(textElements)

        // Detect chord positioning style
        let chordStyle = detectChordStyle(textElements)

        return DocumentLayout(
            columnStructure: columnStructure,
            typography: typography,
            chordStyle: chordStyle
        )
    }

    /// Extract text elements with position information from PDF page
    /// - Parameter page: PDF page to process
    /// - Returns: Array of text elements with bounds
    static func extractTextElements(from page: PDFPage) -> [TextElement] {
        var elements: [TextElement] = []

        guard let pageContent = page.attributedString else {
            return elements
        }

        let fullRange = NSRange(location: 0, length: pageContent.length)

        // Since we can't easily get precise bounds for each text segment from PDFPage,
        // we'll extract text with font information and use heuristics for positioning
        // This is a simplified approach that extracts font sizes which is our main need

        var currentY: CGFloat = 50.0 // Start position
        var currentX: CGFloat = 50.0 // Start position
        let lineHeight: CGFloat = 20.0
        let pageBounds = page.bounds(for: .mediaBox)

        // Split into lines and process each
        let lines = pageContent.string.components(separatedBy: .newlines)

        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                currentY += lineHeight
                continue
            }

            // Extract font size from this range
            var fontSize: CGFloat = 16.0
            let lineRange = (pageContent.string as NSString).range(of: line)
            if lineRange.location != NSNotFound && lineRange.location < pageContent.length {
                pageContent.enumerateAttributes(in: lineRange, options: []) { attributes, _, stop in
                    if let font = attributes[.font] as? UIFont {
                        fontSize = font.pointSize
                        stop.pointee = true
                    }
                }
            }

            // Estimate bounds based on position
            // For column detection, horizontal position is most important
            let estimatedWidth = CGFloat(trimmed.count) * (fontSize * 0.5) // Rough estimate
            let bounds = CGRect(x: currentX, y: currentY, width: estimatedWidth, height: fontSize)

            elements.append(TextElement(
                text: trimmed,
                bounds: bounds,
                fontSize: fontSize
            ))

            currentY += lineHeight

            // Reset X for new line
            currentX = 50.0
        }

        return elements
    }

    /// Detect column structure by clustering text elements horizontally
    /// - Parameters:
    ///   - elements: Text elements to analyze
    ///   - pageWidth: Width of the page
    /// - Returns: Detected column structure
    static func detectColumnStructure(_ elements: [TextElement], pageWidth: CGFloat) -> ColumnStructure {
        guard !elements.isEmpty else {
            return ColumnStructure(
                columnCount: 1,
                columnGaps: [],
                columnWidths: [pageWidth],
                pageWidth: pageWidth
            )
        }

        // Sort elements by x position
        let sortedByX = elements.sorted { $0.x < $1.x }

        // Find gaps in x positions (potential column separators)
        var gaps: [(position: CGFloat, width: CGFloat)] = []
        let gapThreshold: CGFloat = 30.0 // Minimum gap width to consider as column separator

        var lastMaxX: CGFloat = sortedByX[0].x

        for element in sortedByX {
            let gapWidth = element.x - lastMaxX
            if gapWidth > gapThreshold {
                gaps.append((position: lastMaxX, width: gapWidth))
            }
            lastMaxX = max(lastMaxX, element.x + element.width)
        }

        // Column count = number of gaps + 1
        let columnCount = min(gaps.count + 1, 4) // Cap at 4 columns

        if columnCount == 1 {
            return ColumnStructure(
                columnCount: 1,
                columnGaps: [],
                columnWidths: [pageWidth],
                pageWidth: pageWidth
            )
        }

        // Calculate column widths and gaps
        var columnBoundaries: [CGFloat] = [0]
        for gap in gaps {
            columnBoundaries.append(gap.position)
        }
        columnBoundaries.append(pageWidth)

        var columnWidths: [CGFloat] = []
        var columnGaps: [CGFloat] = []

        for i in 0..<(columnBoundaries.count - 1) {
            let start = columnBoundaries[i]
            let end = columnBoundaries[i + 1]

            if i < gaps.count {
                let gapWidth = gaps[i].width
                let columnWidth = (end - start) - gapWidth
                columnWidths.append(columnWidth)
                columnGaps.append(gapWidth)
            } else {
                columnWidths.append(end - start)
            }
        }

        return ColumnStructure(
            columnCount: columnCount,
            columnGaps: columnGaps,
            columnWidths: columnWidths,
            pageWidth: pageWidth
        )
    }

    /// Extract typography information from text elements
    /// - Parameter elements: Text elements to analyze
    /// - Returns: Typography profile
    static func extractTypography(_ elements: [TextElement]) -> TypographyProfile {
        guard !elements.isEmpty else {
            return TypographyProfile(
                titleFontSize: 24.0,
                headingFontSize: 18.0,
                bodyFontSize: 16.0,
                chordFontSize: 14.0
            )
        }

        // Group elements by font size
        var sizeGroups: [CGFloat: Int] = [:]
        for element in elements {
            sizeGroups[element.fontSize, default: 0] += 1
        }

        // Sort sizes by frequency
        let sortedSizes = sizeGroups.sorted { $0.value > $1.value }
        let uniqueSizes = sortedSizes.map { $0.key }.sorted { $0 > $1 }

        // Assign sizes based on hierarchy
        let titleFontSize = uniqueSizes.first ?? 24.0
        let headingFontSize = uniqueSizes.count > 1 ? uniqueSizes[1] : titleFontSize * 0.75
        let bodyFontSize = uniqueSizes.count > 2 ? uniqueSizes[2] : titleFontSize * 0.67
        let chordFontSize = uniqueSizes.count > 3 ? uniqueSizes[3] : bodyFontSize * 0.875

        return TypographyProfile(
            titleFontSize: titleFontSize,
            headingFontSize: headingFontSize,
            bodyFontSize: bodyFontSize,
            chordFontSize: chordFontSize
        )
    }

    /// Detect chord positioning style from text elements
    /// - Parameter elements: Text elements to analyze
    /// - Returns: Detected chord positioning style
    static func detectChordStyle(_ elements: [TextElement]) -> ChordPositioningStyle {
        var chordElements: [TextElement] = []
        var lyricElements: [TextElement] = []

        // Heuristic: identify potential chord vs lyric elements
        for element in elements {
            if isLikelyChord(element.text) {
                chordElements.append(element)
            } else if isLikelyLyric(element.text) {
                lyricElements.append(element)
            }
        }

        guard !chordElements.isEmpty else {
            return .chordsOverLyrics // Default
        }

        // Check if chords appear on separate lines from lyrics
        var hasChordLinesAboveLyrics = false

        for chord in chordElements {
            // Find lyrics below this chord
            let lyricsBelow = lyricElements.filter { lyric in
                lyric.y > chord.y && lyric.y < chord.y + 50 // Within reasonable distance
            }

            if !lyricsBelow.isEmpty {
                hasChordLinesAboveLyrics = true
                break
            }
        }

        if hasChordLinesAboveLyrics {
            return .chordsOverLyrics
        }

        // If chords and lyrics are on same Y coordinate, likely inline
        let inlineChords = chordElements.filter { chord in
            lyricElements.contains { lyric in
                abs(lyric.y - chord.y) < 5 // Same line
            }
        }

        if !inlineChords.isEmpty {
            return .inline
        }

        // Default to chords over lyrics
        return .chordsOverLyrics
    }

    /// Check if text looks like a chord
    /// - Parameter text: Text to check
    /// - Returns: True if it looks like a chord
    static func isLikelyChord(_ text: String) -> Bool {
        // Chords are typically short and contain musical notation
        guard text.count < 8 else { return false }

        // Check for chord patterns
        let chordPattern = "^[A-G][#b♯♭]?(m|maj|min|dim|aug|sus)?[0-9]*(add|sus|dim|aug)?[0-9]*(/[A-G][#b♯♭]?)?$"

        do {
            let regex = try NSRegularExpression(pattern: chordPattern, options: [])
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        } catch {
            return false
        }
    }

    /// Check if text looks like lyrics
    /// - Parameter text: Text to check
    /// - Returns: True if it looks like lyrics
    static func isLikelyLyric(_ text: String) -> Bool {
        // Lyrics are typically longer and contain multiple words
        let words = text.split(separator: " ")
        return words.count >= 3 && text.count > 10
    }

    // MARK: - Template Mapping

    /// Map analyzed document layout to Template model
    /// - Parameters:
    ///   - layout: Analyzed document layout
    ///   - name: Template name
    ///   - context: SwiftData ModelContext
    /// - Returns: Created template
    static func mapToTemplate(
        layout: DocumentLayout,
        name: String,
        context: ModelContext
    ) -> Template {
        let columnStructure = layout.columnStructure
        let typography = layout.typography

        // Determine column width mode
        let columnWidthMode: ColumnWidthMode
        let customColumnWidths: [Double]?

        if columnStructure.columnCount > 1 {
            // Check if columns have equal widths
            let widths = columnStructure.columnWidths
            let avgWidth = widths.reduce(0, +) / CGFloat(widths.count)
            let tolerance: CGFloat = avgWidth * 0.1 // 10% tolerance

            let allEqual = widths.allSatisfy { abs($0 - avgWidth) < tolerance }

            if allEqual {
                columnWidthMode = .equal
                customColumnWidths = nil
            } else {
                columnWidthMode = .custom
                // Convert to relative weights
                let totalWidth = widths.reduce(0, +)
                customColumnWidths = widths.map { Double($0 / totalWidth) }
            }
        } else {
            columnWidthMode = .equal
            customColumnWidths = nil
        }

        // Create template
        let template = Template(
            name: name,
            isBuiltIn: false,
            isDefault: false,
            columnCount: columnStructure.columnCount,
            columnGap: Double(columnStructure.averageGap),
            columnWidthMode: columnWidthMode,
            columnBalancingStrategy: columnStructure.columnCount > 1 ? .balanced : .sectionBased,
            chordPositioningStyle: layout.chordStyle,
            chordAlignment: .leftAligned,
            titleFontSize: Double(typography.titleFontSize),
            headingFontSize: Double(typography.headingFontSize),
            bodyFontSize: Double(typography.bodyFontSize),
            chordFontSize: Double(typography.chordFontSize),
            sectionBreakBehavior: .spaceBefore
        )

        // Store custom column widths if needed
        if columnWidthMode == .custom {
            template.customColumnWidths = customColumnWidths
        }

        return template
    }
}
