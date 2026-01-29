//
//  TemplateTests.swift
//  LyraTests
//
//  Created by Claude on 1/28/26.
//

import Testing
import SwiftData
import Foundation
@testable import Lyra

@Suite("Template Tests")
@MainActor
struct TemplateTests {
    var container: ModelContainer
    var context: ModelContext

    init() throws {
        let schema = Schema([
            Template.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    // MARK: - Template Creation Tests

    @Test("Template creation with default values")
    func testTemplateCreationWithDefaults() throws {
        let template = Template(name: "Test Template")

        #expect(template.name == "Test Template")
        #expect(template.isBuiltIn == false)
        #expect(template.isDefault == false)
        #expect(template.columnCount == 1)
        #expect(template.columnGap == 20.0)
        #expect(template.columnWidthMode == .equal)
        #expect(template.columnBalancingStrategy == .sectionBased)
        #expect(template.chordPositioningStyle == .chordsOverLyrics)
        #expect(template.chordAlignment == .leftAligned)
        #expect(template.titleFontSize == 24.0)
        #expect(template.headingFontSize == 18.0)
        #expect(template.bodyFontSize == 16.0)
        #expect(template.chordFontSize == 14.0)
        #expect(template.sectionBreakBehavior == .spaceBefore)
    }

    @Test("Template creation with custom values")
    func testTemplateCreationWithCustomValues() throws {
        let template = Template(
            name: "Custom Template",
            isBuiltIn: true,
            isDefault: true,
            columnCount: 3,
            columnGap: 30.0,
            columnWidthMode: .custom,
            columnBalancingStrategy: .balanced,
            chordPositioningStyle: .inline,
            chordAlignment: .centered,
            titleFontSize: 28.0,
            headingFontSize: 20.0,
            bodyFontSize: 18.0,
            chordFontSize: 16.0,
            sectionBreakBehavior: .newColumn
        )

        #expect(template.name == "Custom Template")
        #expect(template.isBuiltIn == true)
        #expect(template.isDefault == true)
        #expect(template.columnCount == 3)
        #expect(template.columnGap == 30.0)
        #expect(template.columnWidthMode == .custom)
        #expect(template.columnBalancingStrategy == .balanced)
        #expect(template.chordPositioningStyle == .inline)
        #expect(template.chordAlignment == .centered)
        #expect(template.titleFontSize == 28.0)
        #expect(template.headingFontSize == 20.0)
        #expect(template.bodyFontSize == 18.0)
        #expect(template.chordFontSize == 16.0)
        #expect(template.sectionBreakBehavior == .newColumn)
    }

    @Test("Template has valid UUID and timestamps")
    func testTemplateIdentifiers() throws {
        let template = Template(name: "Test Template")

        #expect(template.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(template.createdAt <= Date())
        #expect(template.modifiedAt <= Date())
    }

    // MARK: - Built-in Template Tests

    @Test("Built-in single column template has correct properties")
    func testBuiltInSingleColumn() throws {
        let template = Template.builtInSingleColumn()

        #expect(template.name == "Single Column")
        #expect(template.isBuiltIn == true)
        #expect(template.isDefault == true)
        #expect(template.columnCount == 1)
        #expect(template.columnGap == 0)
        #expect(template.columnBalancingStrategy == .sectionBased)
    }

    @Test("Built-in two column template has correct properties")
    func testBuiltInTwoColumn() throws {
        let template = Template.builtInTwoColumn()

        #expect(template.name == "Two Column")
        #expect(template.isBuiltIn == true)
        #expect(template.columnCount == 2)
        #expect(template.columnGap == 24.0)
        #expect(template.columnBalancingStrategy == .balanced)
    }

    @Test("Built-in three column template has correct properties")
    func testBuiltInThreeColumn() throws {
        let template = Template.builtInThreeColumn()

        #expect(template.name == "Three Column")
        #expect(template.isBuiltIn == true)
        #expect(template.columnCount == 3)
        #expect(template.columnGap == 20.0)
        #expect(template.columnBalancingStrategy == .balanced)
    }

    // MARK: - Column Width Calculation Tests

    @Test("Effective column widths with equal mode")
    func testEffectiveColumnWidthsEqual() throws {
        let template = Template(name: "Test", columnCount: 3, columnGap: 20.0)
        let totalWidth: CGFloat = 1000.0

        let widths = template.effectiveColumnWidths(totalWidth: totalWidth)

        #expect(widths.count == 3)
        // Total gap = 2 * 20 = 40, available = 960, per column = 320
        #expect(widths[0] == 320.0)
        #expect(widths[1] == 320.0)
        #expect(widths[2] == 320.0)
    }

    @Test("Effective column widths with custom mode")
    func testEffectiveColumnWidthsCustom() throws {
        let template = Template(
            name: "Test",
            columnCount: 3,
            columnGap: 20.0,
            columnWidthMode: .custom
        )
        template.customColumnWidths = [1.0, 2.0, 1.0] // 25%, 50%, 25%
        let totalWidth: CGFloat = 1000.0

        let widths = template.effectiveColumnWidths(totalWidth: totalWidth)

        #expect(widths.count == 3)
        // Total gap = 40, available = 960
        // Weights: 1+2+1 = 4, so 240, 480, 240
        #expect(widths[0] == 240.0)
        #expect(widths[1] == 480.0)
        #expect(widths[2] == 240.0)
    }

    @Test("Effective column widths falls back to equal when custom weights invalid")
    func testEffectiveColumnWidthsCustomFallback() throws {
        let template = Template(
            name: "Test",
            columnCount: 3,
            columnGap: 20.0,
            columnWidthMode: .custom
        )
        // Don't set custom widths - should fallback to equal
        let totalWidth: CGFloat = 1000.0

        let widths = template.effectiveColumnWidths(totalWidth: totalWidth)

        #expect(widths.count == 3)
        #expect(widths[0] == 320.0)
        #expect(widths[1] == 320.0)
        #expect(widths[2] == 320.0)
    }

    @Test("Effective column widths with single column")
    func testEffectiveColumnWidthsSingleColumn() throws {
        let template = Template(name: "Test", columnCount: 1, columnGap: 0)
        let totalWidth: CGFloat = 1000.0

        let widths = template.effectiveColumnWidths(totalWidth: totalWidth)

        #expect(widths.count == 1)
        #expect(widths[0] == 1000.0)
    }

    // MARK: - Validation Tests

    @Test("Template validation with valid properties")
    func testValidTemplateIsValid() throws {
        let template = Template(
            name: "Valid Template",
            columnCount: 2,
            columnGap: 20.0
        )

        #expect(template.isValid == true)
    }

    @Test("Template validation fails with invalid column count")
    func testInvalidColumnCount() throws {
        let template = Template(name: "Invalid", columnCount: 5) // Max is 4
        #expect(template.isValid == false)

        let template2 = Template(name: "Invalid", columnCount: 0)
        #expect(template2.isValid == false)
    }

    @Test("Template validation fails with negative gap")
    func testInvalidColumnGap() throws {
        let template = Template(name: "Invalid", columnGap: -10.0)
        #expect(template.isValid == false)
    }

    @Test("Template validation fails with invalid font sizes")
    func testInvalidFontSizes() throws {
        let template = Template(name: "Invalid", titleFontSize: 0)
        #expect(template.isValid == false)

        let template2 = Template(name: "Invalid", bodyFontSize: -5.0)
        #expect(template2.isValid == false)
    }

    @Test("Template validation fails with custom mode but invalid weights")
    func testInvalidCustomWidths() throws {
        let template = Template(
            name: "Invalid",
            columnCount: 3,
            columnWidthMode: .custom
        )
        // No custom widths set
        #expect(template.isValid == false)

        // Wrong count
        template.customColumnWidths = [1.0, 1.0]
        #expect(template.isValid == false)

        // Negative weights
        template.customColumnWidths = [1.0, -1.0, 1.0]
        #expect(template.isValid == false)
    }

    @Test("Template validation passes with valid custom widths")
    func testValidCustomWidths() throws {
        let template = Template(
            name: "Valid",
            columnCount: 3,
            columnWidthMode: .custom
        )
        template.customColumnWidths = [1.0, 2.0, 1.0]
        #expect(template.isValid == true)
    }

    // MARK: - Duplicate Tests

    @Test("Duplicate creates new template with same properties")
    func testDuplicate() throws {
        let original = Template(
            name: "Original",
            isBuiltIn: true,
            isDefault: true,
            columnCount: 2,
            columnGap: 25.0,
            columnBalancingStrategy: .fillFirst,
            titleFontSize: 30.0
        )

        let duplicate = original.duplicate(newName: "Copy of Original")

        #expect(duplicate.name == "Copy of Original")
        #expect(duplicate.isBuiltIn == false) // Should not copy built-in status
        #expect(duplicate.isDefault == false) // Should not copy default status
        #expect(duplicate.columnCount == 2)
        #expect(duplicate.columnGap == 25.0)
        #expect(duplicate.columnBalancingStrategy == .fillFirst)
        #expect(duplicate.titleFontSize == 30.0)
        #expect(duplicate.id != original.id) // Should have different ID
    }

    // MARK: - Enum Tests

    @Test("ColumnBalancingStrategy enum has correct cases")
    func testColumnBalancingStrategyEnum() throws {
        let strategy1 = ColumnBalancingStrategy.fillFirst
        let strategy2 = ColumnBalancingStrategy.balanced
        let strategy3 = ColumnBalancingStrategy.sectionBased

        #expect(strategy1.rawValue == "fillFirst")
        #expect(strategy2.rawValue == "balanced")
        #expect(strategy3.rawValue == "sectionBased")
    }

    @Test("ChordPositioningStyle enum has correct cases")
    func testChordPositioningStyleEnum() throws {
        let style1 = ChordPositioningStyle.chordsOverLyrics
        let style2 = ChordPositioningStyle.inline
        let style3 = ChordPositioningStyle.separateLines

        #expect(style1.rawValue == "chordsOverLyrics")
        #expect(style2.rawValue == "inline")
        #expect(style3.rawValue == "separateLines")
    }

    @Test("ChordAlignment enum has correct cases")
    func testChordAlignmentEnum() throws {
        let alignment1 = ChordAlignment.leftAligned
        let alignment2 = ChordAlignment.centered
        let alignment3 = ChordAlignment.rightAligned

        #expect(alignment1.rawValue == "leftAligned")
        #expect(alignment2.rawValue == "centered")
        #expect(alignment3.rawValue == "rightAligned")
    }

    @Test("ColumnWidthMode enum has correct cases")
    func testColumnWidthModeEnum() throws {
        let mode1 = ColumnWidthMode.equal
        let mode2 = ColumnWidthMode.custom

        #expect(mode1.rawValue == "equal")
        #expect(mode2.rawValue == "custom")
    }

    @Test("SectionBreakBehavior enum has correct cases")
    func testSectionBreakBehaviorEnum() throws {
        let behavior1 = SectionBreakBehavior.continueInColumn
        let behavior2 = SectionBreakBehavior.newColumn
        let behavior3 = SectionBreakBehavior.spaceBefore

        #expect(behavior1.rawValue == "continueInColumn")
        #expect(behavior2.rawValue == "newColumn")
        #expect(behavior3.rawValue == "spaceBefore")
    }

    @Test("ImportSource enum has correct cases")
    func testImportSourceEnum() throws {
        let source1 = ImportSource.pdf
        let source2 = ImportSource.word
        let source3 = ImportSource.plainText
        let source4 = ImportSource.inAppDesigner

        #expect(source1.rawValue == "pdf")
        #expect(source2.rawValue == "word")
        #expect(source3.rawValue == "plainText")
        #expect(source4.rawValue == "inAppDesigner")
    }

    // MARK: - Import Metadata Tests

    @Test("Template creation with default import metadata")
    func testTemplateCreationWithDefaultImportMetadata() throws {
        let template = Template(name: "Test Template")

        #expect(template.importSource == nil)
        #expect(template.importedFromURL == nil)
        #expect(template.importedAt == nil)
    }

    @Test("Template creation with PDF import metadata")
    func testTemplateCreationWithPDFImportMetadata() throws {
        let importDate = Date()
        let template = Template(
            name: "Imported Template",
            importSource: .pdf,
            importedFromURL: "/path/to/template.pdf",
            importedAt: importDate
        )

        #expect(template.importSource == .pdf)
        #expect(template.importedFromURL == "/path/to/template.pdf")
        #expect(template.importedAt == importDate)
    }

    @Test("Template creation with Word import metadata")
    func testTemplateCreationWithWordImportMetadata() throws {
        let importDate = Date()
        let template = Template(
            name: "Word Template",
            importSource: .word,
            importedFromURL: "/path/to/template.docx",
            importedAt: importDate
        )

        #expect(template.importSource == .word)
        #expect(template.importedFromURL == "/path/to/template.docx")
        #expect(template.importedAt == importDate)
    }

    @Test("Template creation with plain text import metadata")
    func testTemplateCreationWithPlainTextImportMetadata() throws {
        let importDate = Date()
        let template = Template(
            name: "Text Template",
            importSource: .plainText,
            importedFromURL: "/path/to/template.txt",
            importedAt: importDate
        )

        #expect(template.importSource == .plainText)
        #expect(template.importedFromURL == "/path/to/template.txt")
        #expect(template.importedAt == importDate)
    }

    @Test("Template creation with inAppDesigner source")
    func testTemplateCreationWithInAppDesignerSource() throws {
        let template = Template(
            name: "Custom Template",
            importSource: .inAppDesigner
        )

        #expect(template.importSource == .inAppDesigner)
        #expect(template.importedFromURL == nil)
        #expect(template.importedAt == nil)
    }

    @Test("Import metadata persists in SwiftData")
    func testImportMetadataPersistence() throws {
        let importDate = Date()
        let template = Template(
            name: "Imported Template",
            columnCount: 2,
            importSource: .pdf,
            importedFromURL: "/path/to/document.pdf",
            importedAt: importDate
        )

        context.insert(template)
        try context.save()

        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)

        #expect(templates.count == 1)
        #expect(templates[0].name == "Imported Template")
        #expect(templates[0].importSource == .pdf)
        #expect(templates[0].importedFromURL == "/path/to/document.pdf")
        #expect(templates[0].importedAt != nil)
    }

    @Test("Import metadata can be updated")
    func testImportMetadataUpdate() throws {
        let template = Template(name: "Test Template")
        context.insert(template)
        try context.save()

        #expect(template.importSource == nil)

        let importDate = Date()
        template.importSource = .pdf
        template.importedFromURL = "/new/path.pdf"
        template.importedAt = importDate
        try context.save()

        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)

        #expect(templates.count == 1)
        #expect(templates[0].importSource == .pdf)
        #expect(templates[0].importedFromURL == "/new/path.pdf")
        #expect(templates[0].importedAt != nil)
    }

    // MARK: - SwiftData Persistence Tests

    @Test("Template can be saved and fetched from SwiftData")
    func testTemplatePersistence() throws {
        let template = Template(
            name: "Persistent Template",
            columnCount: 2,
            columnGap: 30.0
        )

        context.insert(template)
        try context.save()

        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)

        #expect(templates.count == 1)
        #expect(templates[0].name == "Persistent Template")
        #expect(templates[0].columnCount == 2)
        #expect(templates[0].columnGap == 30.0)
    }

    @Test("Multiple templates can be saved and retrieved")
    func testMultipleTemplates() throws {
        let template1 = Template.builtInSingleColumn()
        let template2 = Template.builtInTwoColumn()
        let template3 = Template(name: "Custom Template", columnCount: 4)

        context.insert(template1)
        context.insert(template2)
        context.insert(template3)
        try context.save()

        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)

        #expect(templates.count == 3)
    }

    @Test("Template can be updated and changes persist")
    func testTemplateUpdate() throws {
        let template = Template(name: "Original Name", columnCount: 1)
        context.insert(template)
        try context.save()

        template.name = "Updated Name"
        template.columnCount = 3
        try context.save()

        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)

        #expect(templates.count == 1)
        #expect(templates[0].name == "Updated Name")
        #expect(templates[0].columnCount == 3)
    }

    @Test("Template can be deleted")
    func testTemplateDelete() throws {
        let template = Template(name: "To Delete", columnCount: 1)
        context.insert(template)
        try context.save()

        var descriptor = FetchDescriptor<Template>()
        var templates = try context.fetch(descriptor)
        #expect(templates.count == 1)

        context.delete(template)
        try context.save()

        descriptor = FetchDescriptor<Template>()
        templates = try context.fetch(descriptor)
        #expect(templates.count == 0)
    }
}
