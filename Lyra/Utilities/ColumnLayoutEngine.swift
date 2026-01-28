//
//  ColumnLayoutEngine.swift
//  Lyra
//
//  Utility for distributing song content across multiple columns
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Column Content

/// Represents the content for a single column
struct ColumnContent: Identifiable {
    let id: UUID
    let index: Int
    let sections: [SongSection]

    init(index: Int, sections: [SongSection]) {
        self.id = UUID()
        self.index = index
        self.sections = sections
    }

    /// Total number of lines in this column
    var lineCount: Int {
        sections.reduce(0) { $0 + $1.lines.count }
    }

    /// Whether this column is empty
    var isEmpty: Bool {
        sections.isEmpty
    }
}

// MARK: - Column Layout Engine

/// Engine for distributing song content across multiple columns
struct ColumnLayoutEngine {

    // MARK: - Constants

    private static let averageLineHeight: CGFloat = 20.0
    private static let sectionLabelHeight: CGFloat = 24.0
    private static let sectionSpacing: CGFloat = 16.0
    private static let chordLineHeight: CGFloat = 18.0

    // MARK: - Main Distribution Method

    /// Distributes song sections across columns based on template configuration
    /// - Parameters:
    ///   - sections: The song sections to distribute
    ///   - template: The template defining column configuration
    ///   - availableWidth: Total width available for columns
    /// - Returns: Array of ColumnContent, one for each column
    static func distributeContent(
        _ sections: [SongSection],
        template: Template,
        availableWidth: CGFloat
    ) -> [ColumnContent] {
        // Handle edge cases
        guard !sections.isEmpty else {
            return []
        }

        guard template.columnCount > 0 else {
            return []
        }

        // Single column case - no distribution needed
        if template.columnCount == 1 {
            return [ColumnContent(index: 0, sections: sections)]
        }

        // Calculate column widths
        let columnWidths = template.effectiveColumnWidths(totalWidth: availableWidth)

        // Route to appropriate distribution strategy
        switch template.columnBalancingStrategy {
        case .fillFirst:
            return distributeFillFirst(sections, template: template, columnWidths: columnWidths)
        case .balanced:
            return distributeBalanced(sections, template: template, columnWidths: columnWidths)
        case .sectionBased:
            return distributeSectionBased(sections, template: template, columnWidths: columnWidths)
        }
    }

    // MARK: - Distribution Strategies

    /// Fill First Strategy: Fill each column completely before moving to the next
    /// - Parameters:
    ///   - sections: The song sections to distribute
    ///   - template: The template configuration
    ///   - columnWidths: Width of each column
    /// - Returns: Array of ColumnContent
    private static func distributeFillFirst(
        _ sections: [SongSection],
        template: Template,
        columnWidths: [CGFloat]
    ) -> [ColumnContent] {
        var columns: [ColumnContent] = []
        var currentColumnSections: [SongSection] = []
        var currentColumnIndex = 0

        for section in sections {
            currentColumnSections.append(section)

            // Check if we should move to next column (when we've used all columns, stay on last)
            if currentColumnIndex < template.columnCount - 1 {
                // Estimate if adding next section would exceed ideal height
                let currentHeight = estimateTotalHeight(currentColumnSections)
                let averageHeight = estimateTotalHeight(sections) / CGFloat(template.columnCount)

                if currentHeight >= averageHeight && !currentColumnSections.isEmpty {
                    columns.append(ColumnContent(index: currentColumnIndex, sections: currentColumnSections))
                    currentColumnSections = []
                    currentColumnIndex += 1
                }
            }
        }

        // Add remaining sections to last column
        if !currentColumnSections.isEmpty {
            columns.append(ColumnContent(index: currentColumnIndex, sections: currentColumnSections))
        }

        // Fill empty columns if needed
        while columns.count < template.columnCount {
            columns.append(ColumnContent(index: columns.count, sections: []))
        }

        return columns
    }

    /// Balanced Strategy: Distribute sections to balance total height across columns
    /// - Parameters:
    ///   - sections: The song sections to distribute
    ///   - template: The template configuration
    ///   - columnWidths: Width of each column
    /// - Returns: Array of ColumnContent
    private static func distributeBalanced(
        _ sections: [SongSection],
        template: Template,
        columnWidths: [CGFloat]
    ) -> [ColumnContent] {
        // Initialize columns
        var columnSections: [[SongSection]] = Array(repeating: [], count: template.columnCount)
        var columnHeights: [CGFloat] = Array(repeating: 0, count: template.columnCount)

        // Sort sections by estimated height (largest first) for better balancing
        let sortedSections = sections.sorted { section1, section2 in
            estimateSectionHeight(section1, width: columnWidths[0]) >
            estimateSectionHeight(section2, width: columnWidths[0])
        }

        // Greedy algorithm: assign each section to the shortest column
        for section in sortedSections {
            // Find column with minimum height
            if let minIndex = columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] }) {
                columnSections[minIndex].append(section)
                columnHeights[minIndex] += estimateSectionHeight(section, width: columnWidths[minIndex])
            }
        }

        // Convert to ColumnContent array, maintaining original section order where possible
        return columnSections.enumerated().map { index, sections in
            // Re-sort sections within each column to maintain original order
            let sortedColumnSections = sections.sorted { s1, s2 in
                guard let idx1 = sections.firstIndex(where: { $0.id == s1.id }),
                      let idx2 = sections.firstIndex(where: { $0.id == s2.id }) else {
                    return false
                }
                return idx1 < idx2
            }
            return ColumnContent(index: index, sections: sortedColumnSections)
        }
    }

    /// Section-Based Strategy: Keep sections together, never split a section across columns
    /// - Parameters:
    ///   - sections: The song sections to distribute
    ///   - template: The template configuration
    ///   - columnWidths: Width of each column
    /// - Returns: Array of ColumnContent
    private static func distributeSectionBased(
        _ sections: [SongSection],
        template: Template,
        columnWidths: [CGFloat]
    ) -> [ColumnContent] {
        // Initialize columns
        var columnSections: [[SongSection]] = Array(repeating: [], count: template.columnCount)
        var columnHeights: [CGFloat] = Array(repeating: 0, count: template.columnCount)

        // Calculate target height per column
        let totalHeight = estimateTotalHeight(sections)
        let targetHeight = totalHeight / CGFloat(template.columnCount)

        var currentColumnIndex = 0

        for section in sections {
            let sectionHeight = estimateSectionHeight(section, width: columnWidths[currentColumnIndex])

            // Check if adding this section would significantly exceed target
            // and we're not on the last column
            if currentColumnIndex < template.columnCount - 1 &&
               !columnSections[currentColumnIndex].isEmpty {
                let currentHeight = columnHeights[currentColumnIndex]
                let heightWithSection = currentHeight + sectionHeight

                // Move to next column if we'd exceed target by more than 50%
                if heightWithSection > targetHeight * 1.5 {
                    currentColumnIndex += 1
                }
            }

            // Add section to current column
            columnSections[currentColumnIndex].append(section)
            columnHeights[currentColumnIndex] += sectionHeight
        }

        // Convert to ColumnContent array
        return columnSections.enumerated().map { index, sections in
            ColumnContent(index: index, sections: sections)
        }
    }

    // MARK: - Height Estimation

    /// Estimates the height of a single section
    /// - Parameters:
    ///   - section: The section to measure
    ///   - width: Available width for the section
    /// - Returns: Estimated height in points
    static func estimateSectionHeight(_ section: SongSection, width: CGFloat) -> CGFloat {
        var height: CGFloat = 0

        // Add section label height
        height += sectionLabelHeight

        // Add section spacing
        height += sectionSpacing

        // Estimate line heights
        for line in section.lines {
            if line.isEmpty {
                // Blank lines
                height += averageLineHeight / 2
            } else if line.hasChords {
                // Lines with chords need space for both chord and lyrics
                height += chordLineHeight + averageLineHeight
            } else {
                // Regular lyric lines
                height += averageLineHeight
            }
        }

        return height
    }

    /// Estimates the total height of all sections
    /// - Parameter sections: Array of sections to measure
    /// - Returns: Estimated total height in points
    static func estimateTotalHeight(_ sections: [SongSection]) -> CGFloat {
        sections.reduce(0) { total, section in
            total + estimateSectionHeight(section, width: 300) // Use default width for estimation
        }
    }
}
