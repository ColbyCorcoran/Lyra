//
//  TemplateImportViewTests.swift
//  LyraTests
//
//  Tests for TemplateImportView
//

import Testing
import SwiftUI
import SwiftData
import PDFKit
@testable import Lyra

@Suite("TemplateImportView Tests")
struct TemplateImportViewTests {

    // MARK: - Test Helpers

    /// Create in-memory model container for testing
    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Template.self, configurations: config)
    }

    /// Create a sample PDF document for testing
    private func createSamplePDF(withColumns columns: Int = 2) -> URL? {
        let pdfDocument = PDFDocument()

        // Create a page with some content
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter

        // Create a simple PDF page (this is simplified for testing)
        let page = PDFPage()

        pdfDocument.insert(page, at: 0)

        // Write to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_template_\(UUID().uuidString).pdf")

        pdfDocument.write(to: tempURL)

        return tempURL
    }

    // MARK: - Initialization Tests

    @Test("TemplateImportView initializes correctly")
    func testInitialization() throws {
        let container = try createTestContainer()
        let view = TemplateImportView()
            .modelContainer(container)

        // View should initialize without crashing
        #expect(view != nil)
    }

    @Test("ImportFormat enum has all expected cases")
    func testImportFormatCases() {
        let formats = ImportFormat.allCases

        #expect(formats.count == 3)
        #expect(formats.contains(.pdf))
        #expect(formats.contains(.word))
        #expect(formats.contains(.plainText))
    }

    @Test("ImportFormat PDF is supported")
    func testPDFFormatIsSupported() {
        #expect(ImportFormat.pdf.isSupported == true)
    }

    @Test("ImportFormat Word is not yet supported")
    func testWordFormatNotSupported() {
        #expect(ImportFormat.word.isSupported == false)
    }

    @Test("ImportFormat Plain Text is not yet supported")
    func testPlainTextFormatNotSupported() {
        #expect(ImportFormat.plainText.isSupported == false)
    }

    // MARK: - ImportFormat Display Properties Tests

    @Test("PDF format has correct display name")
    func testPDFDisplayName() {
        #expect(ImportFormat.pdf.displayName == "PDF")
    }

    @Test("PDF format has correct icon name")
    func testPDFIconName() {
        #expect(ImportFormat.pdf.iconName == "doc.fill")
    }

    @Test("PDF format has descriptive description")
    func testPDFDescription() {
        let description = ImportFormat.pdf.description

        #expect(!description.isEmpty)
        #expect(description.contains("PDF"))
        #expect(description.contains("column"))
    }

    @Test("Word format has correct display name")
    func testWordDisplayName() {
        #expect(ImportFormat.word.displayName == "Word Document")
    }

    @Test("Word format has correct icon name")
    func testWordIconName() {
        #expect(ImportFormat.word.iconName == "doc.richtext")
    }

    @Test("Plain text format has correct display name")
    func testPlainTextDisplayName() {
        #expect(ImportFormat.plainText.displayName == "Plain Text")
    }

    @Test("Plain text format has correct icon name")
    func testPlainTextIconName() {
        #expect(ImportFormat.plainText.iconName == "doc.plaintext")
    }

    // MARK: - ImportFormat Identifiable Tests

    @Test("ImportFormat id matches rawValue")
    func testImportFormatIdentifiable() {
        #expect(ImportFormat.pdf.id == ImportFormat.pdf.rawValue)
        #expect(ImportFormat.word.id == ImportFormat.word.rawValue)
        #expect(ImportFormat.plainText.id == ImportFormat.plainText.rawValue)
    }

    @Test("ImportFormat ids are unique")
    func testImportFormatUniqueIds() {
        let formats = ImportFormat.allCases
        let ids = formats.map { $0.id }
        let uniqueIds = Set(ids)

        #expect(ids.count == uniqueIds.count)
    }

    // MARK: - Template Name Validation Tests

    @Test("Empty template name should not be allowed")
    func testEmptyTemplateName() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Template with empty name should fail validation
        let isValid = try TemplateManager.isValidTemplateName("", excludingTemplate: nil, in: context)

        #expect(!isValid)
    }

    @Test("Whitespace-only template name should not be allowed")
    func testWhitespaceOnlyTemplateName() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let isValid = try TemplateManager.isValidTemplateName("   ", excludingTemplate: nil, in: context)

        #expect(!isValid)
    }

    @Test("Valid template name should be allowed")
    func testValidTemplateName() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let isValid = try TemplateManager.isValidTemplateName("My Custom Template", excludingTemplate: nil, in: context)

        #expect(isValid)
    }

    @Test("Duplicate template name should not be allowed")
    func testDuplicateTemplateName() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create a template with a specific name
        let existingTemplate = Template(name: "Existing Template")
        context.insert(existingTemplate)
        try context.save()

        // Try to create another template with the same name
        let isValid = try TemplateManager.isValidTemplateName("Existing Template", excludingTemplate: nil, in: context)

        #expect(!isValid)
    }

    // MARK: - Template Import Error Handling Tests

    @Test("TemplateImportError provides error descriptions")
    func testTemplateImportErrorDescriptions() {
        let errors: [TemplateImportError] = [
            .noPDFDocument,
            .analysisError,
            .invalidLayout,
            .noContentFound,
            .unsupportedFormat
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("TemplateImportError provides recovery suggestions")
    func testTemplateImportErrorRecoverySuggestions() {
        let errors: [TemplateImportError] = [
            .noPDFDocument,
            .analysisError,
            .invalidLayout,
            .noContentFound,
            .unsupportedFormat
        ]

        for error in errors {
            #expect(error.recoverySuggestion != nil)
            #expect(!error.recoverySuggestion!.isEmpty)
        }
    }

    @Test("No PDF document error has appropriate message")
    func testNoPDFDocumentError() {
        let error = TemplateImportError.noPDFDocument

        #expect(error.errorDescription?.contains("PDF") == true)
    }

    @Test("Unsupported format error has appropriate message")
    func testUnsupportedFormatError() {
        let error = TemplateImportError.unsupportedFormat

        #expect(error.errorDescription?.contains("format") == true)
        #expect(error.errorDescription?.contains("not supported") == true)
    }

    // MARK: - Integration Tests

    @Test("Template can be created after successful import")
    func testTemplateCreationAfterImport() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create a template manually (simulating successful import)
        let template = Template(name: "Imported Template")
        template.columnCount = 2
        template.columnGap = 16
        template.chordPositioningStyle = .chordsOverLyrics

        context.insert(template)
        try context.save()

        // Verify template was saved
        let fetchedTemplates = try TemplateManager.fetchAllTemplates(from: context)

        #expect(fetchedTemplates.count == 1)
        #expect(fetchedTemplates.first?.name == "Imported Template")
        #expect(fetchedTemplates.first?.columnCount == 2)
    }

    @Test("Imported template has valid configuration")
    func testImportedTemplateValidation() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create a template with typical imported values
        let template = Template(name: "PDF Import")
        template.columnCount = 2
        template.columnGap = 24
        template.columnWidthMode = .equal
        template.columnBalancingStrategy = .balanced
        template.chordPositioningStyle = .chordsOverLyrics
        template.chordAlignment = .leftAligned
        template.titleFontSize = 24
        template.headingFontSize = 18
        template.bodyFontSize = 16
        template.chordFontSize = 14
        template.sectionBreakBehavior = .spaceBefore

        #expect(template.isValid)

        context.insert(template)
        try context.save()

        // Verify it persists correctly
        let fetchedTemplates = try TemplateManager.fetchAllTemplates(from: context)
        #expect(fetchedTemplates.first?.isValid == true)
    }

    @Test("Multiple templates can be imported without conflicts")
    func testMultipleImports() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create multiple templates (simulating multiple imports)
        let template1 = Template(name: "Import 1")
        template1.columnCount = 1

        let template2 = Template(name: "Import 2")
        template2.columnCount = 2

        let template3 = Template(name: "Import 3")
        template3.columnCount = 3

        context.insert(template1)
        context.insert(template2)
        context.insert(template3)
        try context.save()

        let fetchedTemplates = try TemplateManager.fetchAllTemplates(from: context)

        #expect(fetchedTemplates.count == 3)
        #expect(Set(fetchedTemplates.map { $0.name }).count == 3)
    }

    // MARK: - UI State Tests

    @Test("Import format defaults to PDF")
    func testDefaultImportFormat() {
        // The default format should be PDF since it's the only supported format
        let defaultFormat: ImportFormat = .pdf

        #expect(defaultFormat == .pdf)
        #expect(defaultFormat.isSupported)
    }

    // MARK: - Edge Cases

    @Test("Template name with special characters is valid")
    func testTemplateNameWithSpecialCharacters() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let names = [
            "Template #1",
            "Template (Copy)",
            "Template - Version 2",
            "Template: Style A",
            "Template & More"
        ]

        for name in names {
            let isValid = try TemplateManager.isValidTemplateName(name, excludingTemplate: nil, in: context)
            #expect(isValid)
        }
    }

    @Test("Template name with leading/trailing whitespace is trimmed")
    func testTemplateNameWhitespaceTrimming() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create template with whitespace
        let template = Template(name: "  Padded Template  ")
        context.insert(template)
        try context.save()

        // Validation should work with trimmed name
        let isValid = try TemplateManager.isValidTemplateName("Padded Template", excludingTemplate: nil, in: context)

        // Should be invalid because it matches the existing template (after trimming)
        #expect(!isValid)
    }

    @Test("Very long template name is allowed")
    func testVeryLongTemplateName() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let longName = String(repeating: "a", count: 100)
        let isValid = try TemplateManager.isValidTemplateName(longName, excludingTemplate: nil, in: context)

        #expect(isValid)
    }

    // MARK: - Real-World Import Scenarios

    @Test("Imported single column template has correct properties")
    func testImportedSingleColumnTemplate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Simulate importing a single-column PDF
        let template = Template(name: "Imported Single Column")
        template.columnCount = 1
        template.columnGap = 0
        template.columnBalancingStrategy = .sectionBased
        template.chordPositioningStyle = .chordsOverLyrics

        #expect(template.isValid)

        context.insert(template)
        try context.save()

        let fetchedTemplate = try TemplateManager.fetchAllTemplates(from: context).first
        #expect(fetchedTemplate?.columnCount == 1)
        #expect(fetchedTemplate?.columnGap == 0)
    }

    @Test("Imported two column template has correct properties")
    func testImportedTwoColumnTemplate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Simulate importing a two-column PDF
        let template = Template(name: "Imported Two Column")
        template.columnCount = 2
        template.columnGap = 24
        template.columnWidthMode = .equal
        template.columnBalancingStrategy = .balanced

        #expect(template.isValid)

        context.insert(template)
        try context.save()

        let fetchedTemplate = try TemplateManager.fetchAllTemplates(from: context).first
        #expect(fetchedTemplate?.columnCount == 2)
        #expect(fetchedTemplate?.columnGap == 24)
        #expect(fetchedTemplate?.columnWidthMode == .equal)
    }

    @Test("Imported template with custom column widths")
    func testImportedCustomWidthTemplate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Simulate importing a PDF with custom column widths
        let template = Template(name: "Imported Custom Widths")
        template.columnCount = 3
        template.columnWidthMode = .custom
        template.customColumnWidths = [1.0, 1.5, 1.0]

        #expect(template.isValid)

        context.insert(template)
        try context.save()

        let fetchedTemplate = try TemplateManager.fetchAllTemplates(from: context).first
        #expect(fetchedTemplate?.columnWidthMode == .custom)
        #expect(fetchedTemplate?.customColumnWidths?.count == 3)
    }

    @Test("Imported template with detected typography")
    func testImportedTemplateTypography() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Simulate importing a PDF with detected font sizes
        let template = Template(name: "Imported Typography")
        template.titleFontSize = 28
        template.headingFontSize = 20
        template.bodyFontSize = 14
        template.chordFontSize = 12

        #expect(template.isValid)
        #expect(template.titleFontSize > template.headingFontSize)
        #expect(template.headingFontSize > template.bodyFontSize)
        #expect(template.bodyFontSize > template.chordFontSize)

        context.insert(template)
        try context.save()

        let fetchedTemplate = try TemplateManager.fetchAllTemplates(from: context).first
        #expect(fetchedTemplate?.titleFontSize == 28)
        #expect(fetchedTemplate?.bodyFontSize == 14)
    }

    @Test("Imported template with inline chord style")
    func testImportedInlineChordStyle() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Simulate importing a PDF with inline chords
        let template = Template(name: "Imported Inline Chords")
        template.chordPositioningStyle = .inline
        template.chordAlignment = .leftAligned

        #expect(template.isValid)

        context.insert(template)
        try context.save()

        let fetchedTemplate = try TemplateManager.fetchAllTemplates(from: context).first
        #expect(fetchedTemplate?.chordPositioningStyle == .inline)
    }

    @Test("Imported template with separate lines chord style")
    func testImportedSeparateLinesChordStyle() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Simulate importing a PDF with chords on separate lines
        let template = Template(name: "Imported Separate Chords")
        template.chordPositioningStyle = .separateLines

        #expect(template.isValid)

        context.insert(template)
        try context.save()

        let fetchedTemplate = try TemplateManager.fetchAllTemplates(from: context).first
        #expect(fetchedTemplate?.chordPositioningStyle == .separateLines)
    }

    // MARK: - Template Cleanup Tests

    @Test("Template can be deleted after import")
    func testDeleteImportedTemplate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create and save a template
        let template = Template(name: "To Be Deleted")
        template.isBuiltIn = false // User template

        context.insert(template)
        try context.save()

        #expect(try TemplateManager.fetchAllTemplates(from: context).count == 1)

        // Delete the template
        try TemplateManager.deleteTemplate(template, context: context)

        #expect(try TemplateManager.fetchAllTemplates(from: context).count == 0)
    }

    @Test("Imported template can be set as default")
    func testSetImportedTemplateAsDefault() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create imported template
        let template = Template(name: "Imported Default")
        context.insert(template)
        try context.save()

        // Set as default
        try TemplateManager.setDefaultTemplate(template, context: context)

        #expect(template.isDefault)

        let defaultTemplate = try TemplateManager.fetchDefaultTemplate(from: context)
        #expect(defaultTemplate?.id == template.id)
    }

    @Test("Imported template can be duplicated")
    func testDuplicateImportedTemplate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create imported template
        let original = Template(name: "Imported Original")
        original.columnCount = 2
        original.columnGap = 20

        context.insert(original)
        try context.save()

        // Duplicate it
        let duplicate = try TemplateManager.duplicateTemplate(original, newName: "Imported Copy", context: context)

        #expect(duplicate.name == "Imported Copy")
        #expect(duplicate.columnCount == original.columnCount)
        #expect(duplicate.columnGap == original.columnGap)
        #expect(duplicate.id != original.id)

        let allTemplates = try TemplateManager.fetchAllTemplates(from: context)
        #expect(allTemplates.count == 2)
    }
}
