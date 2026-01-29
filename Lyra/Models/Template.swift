import SwiftData
import Foundation

// MARK: - Enums

enum ColumnBalancingStrategy: String, Codable {
    case fillFirst
    case balanced
    case sectionBased
}

enum ChordPositioningStyle: String, Codable {
    case chordsOverLyrics
    case inline
    case separateLines
}

enum ChordAlignment: String, Codable {
    case leftAligned
    case centered
    case rightAligned
}

enum ColumnWidthMode: String, Codable {
    case equal
    case custom
}

enum SectionBreakBehavior: String, Codable {
    case continueInColumn
    case newColumn
    case spaceBefore
}

enum ImportSource: String, Codable {
    case pdf
    case word
    case plainText
    case inAppDesigner
}

// MARK: - Template Model

@Model
final class Template {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Basic Properties
    var name: String
    var isBuiltIn: Bool
    var isDefault: Bool

    // MARK: - Column Configuration
    var columnCount: Int // 1-4
    var columnGap: Double // Spacing between columns in points
    var columnWidthMode: ColumnWidthMode
    var columnBalancingStrategy: ColumnBalancingStrategy

    // Custom column widths (only used when columnWidthMode is .custom)
    // Array of relative weights (e.g., [1.0, 1.5, 1.0] for 3 columns)
    var customColumnWidths: [Double]?

    // MARK: - Chord Positioning
    var chordPositioningStyle: ChordPositioningStyle
    var chordAlignment: ChordAlignment

    // MARK: - Typography
    var titleFontSize: Double
    var headingFontSize: Double
    var bodyFontSize: Double
    var chordFontSize: Double

    // MARK: - Layout Rules
    var sectionBreakBehavior: SectionBreakBehavior

    // MARK: - Import Metadata
    var importSource: ImportSource?
    var importedFromURL: String?
    var importedAt: Date?

    // MARK: - Relationships
    // Note: The relationship with Song will be established when Song.swift is modified
    // to add the template property (as per Phase 1 implementation plan)

    // MARK: - Initializer
    init(
        name: String,
        isBuiltIn: Bool = false,
        isDefault: Bool = false,
        columnCount: Int = 1,
        columnGap: Double = 20.0,
        columnWidthMode: ColumnWidthMode = .equal,
        columnBalancingStrategy: ColumnBalancingStrategy = .sectionBased,
        chordPositioningStyle: ChordPositioningStyle = .chordsOverLyrics,
        chordAlignment: ChordAlignment = .leftAligned,
        titleFontSize: Double = 24.0,
        headingFontSize: Double = 18.0,
        bodyFontSize: Double = 16.0,
        chordFontSize: Double = 14.0,
        sectionBreakBehavior: SectionBreakBehavior = .spaceBefore,
        importSource: ImportSource? = nil,
        importedFromURL: String? = nil,
        importedAt: Date? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.isDefault = isDefault
        self.columnCount = columnCount
        self.columnGap = columnGap
        self.columnWidthMode = columnWidthMode
        self.columnBalancingStrategy = columnBalancingStrategy
        self.chordPositioningStyle = chordPositioningStyle
        self.chordAlignment = chordAlignment
        self.titleFontSize = titleFontSize
        self.headingFontSize = headingFontSize
        self.bodyFontSize = bodyFontSize
        self.chordFontSize = chordFontSize
        self.sectionBreakBehavior = sectionBreakBehavior
        self.importSource = importSource
        self.importedFromURL = importedFromURL
        self.importedAt = importedAt
    }

    // MARK: - Built-in Templates

    static func builtInSingleColumn() -> Template {
        return Template(
            name: "Single Column",
            isBuiltIn: true,
            isDefault: true,
            columnCount: 1,
            columnGap: 0,
            columnBalancingStrategy: .sectionBased
        )
    }

    static func builtInTwoColumn() -> Template {
        return Template(
            name: "Two Column",
            isBuiltIn: true,
            columnCount: 2,
            columnGap: 24.0,
            columnBalancingStrategy: .balanced
        )
    }

    static func builtInThreeColumn() -> Template {
        return Template(
            name: "Three Column",
            isBuiltIn: true,
            columnCount: 3,
            columnGap: 20.0,
            columnBalancingStrategy: .balanced
        )
    }

    // MARK: - Helper Methods

    /// Returns the effective column widths based on the width mode
    func effectiveColumnWidths(totalWidth: CGFloat) -> [CGFloat] {
        guard columnCount > 0 else { return [] }

        let totalGap = CGFloat(columnCount - 1) * CGFloat(columnGap)
        let availableWidth = totalWidth - totalGap

        switch columnWidthMode {
        case .equal:
            let width = availableWidth / CGFloat(columnCount)
            return Array(repeating: width, count: columnCount)

        case .custom:
            guard let weights = customColumnWidths, weights.count == columnCount else {
                // Fallback to equal if custom widths are invalid
                let width = availableWidth / CGFloat(columnCount)
                return Array(repeating: width, count: columnCount)
            }

            let totalWeight = weights.reduce(0, +)
            guard totalWeight > 0 else {
                let width = availableWidth / CGFloat(columnCount)
                return Array(repeating: width, count: columnCount)
            }

            return weights.map { weight in
                availableWidth * CGFloat(weight / totalWeight)
            }
        }
    }

    /// Validates that the template configuration is valid
    var isValid: Bool {
        guard columnCount >= 1 && columnCount <= 4 else { return false }
        guard columnGap >= 0 else { return false }
        guard titleFontSize > 0 else { return false }
        guard headingFontSize > 0 else { return false }
        guard bodyFontSize > 0 else { return false }
        guard chordFontSize > 0 else { return false }

        if columnWidthMode == .custom {
            guard let weights = customColumnWidths else { return false }
            guard weights.count == columnCount else { return false }
            guard weights.allSatisfy({ $0 > 0 }) else { return false }
        }

        return true
    }

    /// Creates a copy of this template with a new name
    func duplicate(newName: String) -> Template {
        return Template(
            name: newName,
            isBuiltIn: false,
            isDefault: false,
            columnCount: columnCount,
            columnGap: columnGap,
            columnWidthMode: columnWidthMode,
            columnBalancingStrategy: columnBalancingStrategy,
            chordPositioningStyle: chordPositioningStyle,
            chordAlignment: chordAlignment,
            titleFontSize: titleFontSize,
            headingFontSize: headingFontSize,
            bodyFontSize: bodyFontSize,
            chordFontSize: chordFontSize,
            sectionBreakBehavior: sectionBreakBehavior
        )
    }
}
