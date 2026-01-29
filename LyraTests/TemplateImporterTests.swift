//
//  TemplateImporterTests.swift
//  LyraTests
//
//  Tests for TemplateImporter utility
//

import Testing
import SwiftData
import Foundation
import PDFKit
@testable import Lyra

@Suite("TemplateImporter Tests")
@MainActor
struct TemplateImporterTests {
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

    // MARK: - Helper Methods

    /// Create a mock PDF document for testing
    func createMockPDF(columnCount: Int = 1) -> PDFDocument? {
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let pdfDocument = PDFDocument()

        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        let data = renderer.pdfData { context in
            context.beginPage()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold)
            ]

            // Draw title
            let title = "Amazing Grace"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)

            // Draw content based on column count
            let bodyFont = UIFont.systemFont(ofSize: 16)
            let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]

            let chordFont = UIFont.systemFont(ofSize: 14)
            let chordAttributes: [NSAttributedString.Key: Any] = [.font: chordFont]

            if columnCount == 1 {
                // Single column layout
                "[G]".draw(at: CGPoint(x: 50, y: 100), withAttributes: chordAttributes)
                "Amazing grace how sweet the sound".draw(at: CGPoint(x: 50, y: 120), withAttributes: bodyAttributes)
            } else if columnCount == 2 {
                // Two column layout
                // Column 1
                "[G]".draw(at: CGPoint(x: 50, y: 100), withAttributes: chordAttributes)
                "Amazing grace how sweet the sound".draw(at: CGPoint(x: 50, y: 120), withAttributes: bodyAttributes)

                // Column 2 (with gap)
                "[D]".draw(at: CGPoint(x: 350, y: 100), withAttributes: chordAttributes)
                "That saved a wretch like me".draw(at: CGPoint(x: 350, y: 120), withAttributes: bodyAttributes)
            } else if columnCount == 3 {
                // Three column layout
                "[G]".draw(at: CGPoint(x: 50, y: 100), withAttributes: chordAttributes)
                "Amazing grace".draw(at: CGPoint(x: 50, y: 120), withAttributes: bodyAttributes)

                "[C]".draw(at: CGPoint(x: 250, y: 100), withAttributes: chordAttributes)
                "How sweet the sound".draw(at: CGPoint(x: 250, y: 120), withAttributes: bodyAttributes)

                "[D]".draw(at: CGPoint(x: 450, y: 100), withAttributes: chordAttributes)
                "That saved a wretch".draw(at: CGPoint(x: 450, y: 120), withAttributes: bodyAttributes)
            }
        }

        return PDFDocument(data: data)
    }

    // MARK: - Text Element Extraction Tests

    @Test("Extract text elements from PDF page")
    func testExtractTextElements() throws {
        guard let document = createMockPDF() else {
            Issue.record("Failed to create mock PDF")
            return
        }

        guard let page = document.page(at: 0) else {
            Issue.record("Failed to get page from PDF")
            return
        }

        let elements = TemplateImporter.extractTextElements(from: page)

        #expect(!elements.isEmpty)
        #expect(elements.contains { $0.text.contains("Amazing Grace") || $0.text.contains("Amazing") })
    }

    @Test("Extract text elements returns empty for empty page")
    func testExtractTextElementsEmptyPage() throws {
        // Create an empty PDF
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        let data = renderer.pdfData { context in
            context.beginPage()
            // Draw nothing
        }

        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else {
            Issue.record("Failed to create empty PDF")
            return
        }

        let elements = TemplateImporter.extractTextElements(from: page)

        #expect(elements.isEmpty)
    }

    // MARK: - Column Detection Tests

    @Test("Detect single column layout")
    func testDetectSingleColumn() throws {
        let elements = [
            TextElement(text: "Title", bounds: CGRect(x: 50, y: 50, width: 200, height: 24), fontSize: 24),
            TextElement(text: "Line 1", bounds: CGRect(x: 50, y: 100, width: 200, height: 16), fontSize: 16),
            TextElement(text: "Line 2", bounds: CGRect(x: 50, y: 120, width: 200, height: 16), fontSize: 16)
        ]

        let structure = TemplateImporter.detectColumnStructure(elements, pageWidth: 612)

        #expect(structure.columnCount == 1)
        #expect(structure.columnGaps.isEmpty)
    }

    @Test("Detect two column layout")
    func testDetectTwoColumns() throws {
        let elements = [
            TextElement(text: "Col 1 Line 1", bounds: CGRect(x: 50, y: 100, width: 200, height: 16), fontSize: 16),
            TextElement(text: "Col 2 Line 1", bounds: CGRect(x: 350, y: 100, width: 200, height: 16), fontSize: 16)
        ]

        let structure = TemplateImporter.detectColumnStructure(elements, pageWidth: 612)

        #expect(structure.columnCount == 2)
        #expect(!structure.columnGaps.isEmpty)
    }

    @Test("Detect three column layout")
    func testDetectThreeColumns() throws {
        let elements = [
            TextElement(text: "Col 1", bounds: CGRect(x: 50, y: 100, width: 100, height: 16), fontSize: 16),
            TextElement(text: "Col 2", bounds: CGRect(x: 250, y: 100, width: 100, height: 16), fontSize: 16),
            TextElement(text: "Col 3", bounds: CGRect(x: 450, y: 100, width: 100, height: 16), fontSize: 16)
        ]

        let structure = TemplateImporter.detectColumnStructure(elements, pageWidth: 612)

        #expect(structure.columnCount == 3)
        #expect(structure.columnGaps.count == 2)
    }

    @Test("Detect column structure with empty elements returns single column")
    func testDetectColumnStructureEmpty() throws {
        let structure = TemplateImporter.detectColumnStructure([], pageWidth: 612)

        #expect(structure.columnCount == 1)
        #expect(structure.columnGaps.isEmpty)
        #expect(structure.columnWidths.count == 1)
    }

    // MARK: - Typography Extraction Tests

    @Test("Extract typography from elements")
    func testExtractTypography() throws {
        let elements = [
            TextElement(text: "Title", bounds: CGRect(x: 50, y: 50, width: 200, height: 24), fontSize: 24),
            TextElement(text: "Heading", bounds: CGRect(x: 50, y: 80, width: 150, height: 18), fontSize: 18),
            TextElement(text: "Body text", bounds: CGRect(x: 50, y: 100, width: 200, height: 16), fontSize: 16),
            TextElement(text: "Chord", bounds: CGRect(x: 50, y: 90, width: 30, height: 14), fontSize: 14)
        ]

        let typography = TemplateImporter.extractTypography(elements)

        #expect(typography.titleFontSize >= typography.headingFontSize)
        #expect(typography.headingFontSize >= typography.bodyFontSize)
        #expect(typography.bodyFontSize > 0)
    }

    @Test("Extract typography with no elements returns defaults")
    func testExtractTypographyEmpty() throws {
        let typography = TemplateImporter.extractTypography([])

        #expect(typography.titleFontSize == 24.0)
        #expect(typography.headingFontSize == 18.0)
        #expect(typography.bodyFontSize == 16.0)
        #expect(typography.chordFontSize == 14.0)
    }

    @Test("Extract typography with single size")
    func testExtractTypographySingleSize() throws {
        let elements = [
            TextElement(text: "Text 1", bounds: CGRect(x: 50, y: 50, width: 100, height: 16), fontSize: 16),
            TextElement(text: "Text 2", bounds: CGRect(x: 50, y: 70, width: 100, height: 16), fontSize: 16)
        ]

        let typography = TemplateImporter.extractTypography(elements)

        #expect(typography.titleFontSize == 16.0)
        #expect(typography.bodyFontSize > 0)
    }

    // MARK: - Chord Style Detection Tests

    @Test("Detect chords over lyrics style")
    func testDetectChordsOverLyrics() throws {
        let elements = [
            // Chord above lyric
            TextElement(text: "G", bounds: CGRect(x: 50, y: 100, width: 20, height: 14), fontSize: 14),
            TextElement(text: "Amazing grace how sweet the sound", bounds: CGRect(x: 50, y: 120, width: 300, height: 16), fontSize: 16)
        ]

        let style = TemplateImporter.detectChordStyle(elements)

        #expect(style == .chordsOverLyrics)
    }

    @Test("Detect inline chord style")
    func testDetectInlineChordStyle() throws {
        let elements = [
            // Chord and lyric on same line
            TextElement(text: "G", bounds: CGRect(x: 50, y: 100, width: 20, height: 14), fontSize: 14),
            TextElement(text: "Amazing grace", bounds: CGRect(x: 80, y: 100, width: 120, height: 16), fontSize: 16)
        ]

        let style = TemplateImporter.detectChordStyle(elements)

        #expect(style == .inline)
    }

    @Test("Detect chord style with no chords returns default")
    func testDetectChordStyleNoChords() throws {
        let elements = [
            TextElement(text: "Just lyrics here", bounds: CGRect(x: 50, y: 100, width: 200, height: 16), fontSize: 16)
        ]

        let style = TemplateImporter.detectChordStyle(elements)

        #expect(style == .chordsOverLyrics) // Default
    }

    // MARK: - Chord/Lyric Detection Tests

    @Test("Identify likely chords")
    func testIsLikelyChord() throws {
        #expect(TemplateImporter.isLikelyChord("G") == true)
        #expect(TemplateImporter.isLikelyChord("Am") == true)
        #expect(TemplateImporter.isLikelyChord("D7") == true)
        #expect(TemplateImporter.isLikelyChord("Cmaj7") == true)
        #expect(TemplateImporter.isLikelyChord("F#m") == true)
        #expect(TemplateImporter.isLikelyChord("Bb") == true)
    }

    @Test("Reject non-chord text")
    func testIsNotChord() throws {
        #expect(TemplateImporter.isLikelyChord("Amazing grace") == false)
        #expect(TemplateImporter.isLikelyChord("Verse 1") == false)
        #expect(TemplateImporter.isLikelyChord("This is a long sentence") == false)
        #expect(TemplateImporter.isLikelyChord("123") == false)
    }

    @Test("Identify likely lyrics")
    func testIsLikelyLyric() throws {
        #expect(TemplateImporter.isLikelyLyric("Amazing grace how sweet the sound") == true)
        #expect(TemplateImporter.isLikelyLyric("That saved a wretch like me") == true)
    }

    @Test("Reject non-lyric text")
    func testIsNotLyric() throws {
        #expect(TemplateImporter.isLikelyLyric("G") == false)
        #expect(TemplateImporter.isLikelyLyric("Am") == false)
        #expect(TemplateImporter.isLikelyLyric("Title") == false)
    }

    // MARK: - Template Mapping Tests

    @Test("Map single column layout to template")
    func testMapSingleColumnTemplate() throws {
        let layout = DocumentLayout(
            columnStructure: ColumnStructure(
                columnCount: 1,
                columnGaps: [],
                columnWidths: [612],
                pageWidth: 612
            ),
            typography: TypographyProfile(
                titleFontSize: 24,
                headingFontSize: 18,
                bodyFontSize: 16,
                chordFontSize: 14
            ),
            chordStyle: .chordsOverLyrics
        )

        let template = TemplateImporter.mapToTemplate(
            layout: layout,
            name: "Test Template",
            context: context
        )

        #expect(template.name == "Test Template")
        #expect(template.columnCount == 1)
        #expect(template.columnWidthMode == .equal)
        #expect(template.titleFontSize == 24.0)
        #expect(template.bodyFontSize == 16.0)
        #expect(template.chordPositioningStyle == .chordsOverLyrics)
        #expect(!template.isBuiltIn)
    }

    @Test("Map two column layout with equal widths")
    func testMapTwoColumnEqualTemplate() throws {
        let layout = DocumentLayout(
            columnStructure: ColumnStructure(
                columnCount: 2,
                columnGaps: [24],
                columnWidths: [294, 294],
                pageWidth: 612
            ),
            typography: TypographyProfile(
                titleFontSize: 24,
                headingFontSize: 18,
                bodyFontSize: 16,
                chordFontSize: 14
            ),
            chordStyle: .inline
        )

        let template = TemplateImporter.mapToTemplate(
            layout: layout,
            name: "Two Column Template",
            context: context
        )

        #expect(template.columnCount == 2)
        #expect(template.columnWidthMode == .equal)
        #expect(template.columnGap == 24.0)
        #expect(template.chordPositioningStyle == .inline)
    }

    @Test("Map two column layout with custom widths")
    func testMapTwoColumnCustomTemplate() throws {
        let layout = DocumentLayout(
            columnStructure: ColumnStructure(
                columnCount: 2,
                columnGaps: [24],
                columnWidths: [200, 388], // Unequal widths
                pageWidth: 612
            ),
            typography: TypographyProfile(
                titleFontSize: 24,
                headingFontSize: 18,
                bodyFontSize: 16,
                chordFontSize: 14
            ),
            chordStyle: .chordsOverLyrics
        )

        let template = TemplateImporter.mapToTemplate(
            layout: layout,
            name: "Custom Width Template",
            context: context
        )

        #expect(template.columnCount == 2)
        #expect(template.columnWidthMode == .custom)
        #expect(template.customColumnWidths != nil)
        #expect(template.customColumnWidths?.count == 2)
    }

    @Test("Template validation after mapping")
    func testMappedTemplateIsValid() throws {
        let layout = DocumentLayout(
            columnStructure: ColumnStructure(
                columnCount: 2,
                columnGaps: [20],
                columnWidths: [296, 296],
                pageWidth: 612
            ),
            typography: TypographyProfile(
                titleFontSize: 24,
                headingFontSize: 18,
                bodyFontSize: 16,
                chordFontSize: 14
            ),
            chordStyle: .chordsOverLyrics
        )

        let template = TemplateImporter.mapToTemplate(
            layout: layout,
            name: "Valid Template",
            context: context
        )

        #expect(template.isValid)
    }

    // MARK: - PDF Analysis Tests

    @Test("Analyze single column PDF layout")
    func testAnalyzeSingleColumnPDF() async throws {
        guard let document = createMockPDF(columnCount: 1),
              let page = document.page(at: 0) else {
            Issue.record("Failed to create mock PDF")
            return
        }

        let layout = try TemplateImporter.analyzePDFLayout(page)

        #expect(layout.columnStructure.columnCount >= 1)
        #expect(layout.typography.bodyFontSize > 0)
    }

    @Test("Analyze two column PDF layout")
    func testAnalyzeTwoColumnPDF() async throws {
        guard let document = createMockPDF(columnCount: 2),
              let page = document.page(at: 0) else {
            Issue.record("Failed to create mock PDF")
            return
        }

        let layout = try TemplateImporter.analyzePDFLayout(page)

        // Should detect at least 1 column (may detect 2 depending on gap detection)
        #expect(layout.columnStructure.columnCount >= 1)
        #expect(layout.columnStructure.columnCount <= 4)
    }

    @Test("Analyze PDF layout throws on empty page")
    func testAnalyzeEmptyPDFThrows() throws {
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        let data = renderer.pdfData { context in
            context.beginPage()
        }

        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else {
            Issue.record("Failed to create empty PDF")
            return
        }

        #expect(throws: TemplateImportError.self) {
            try TemplateImporter.analyzePDFLayout(page)
        }
    }

    // MARK: - PDF Import Integration Tests

    @Test("Import template from PDF creates valid template")
    func testImportFromPDF() async throws {
        guard let document = createMockPDF(columnCount: 1) else {
            Issue.record("Failed to create mock PDF")
            return
        }

        // Save document to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
        document.write(to: tempURL)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let template = try await TemplateImporter.importFromPDF(
            url: tempURL,
            name: "Imported Template",
            context: context
        )

        #expect(template.name == "Imported Template")
        #expect(template.isValid)
        #expect(!template.isBuiltIn)

        // Verify template was saved to context
        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)
        #expect(templates.count == 1)
        #expect(templates[0].name == "Imported Template")
    }

    @Test("Import from invalid PDF URL throws error")
    func testImportFromInvalidURL() async throws {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.pdf")

        await #expect(throws: TemplateImportError.self) {
            try await TemplateImporter.importFromPDF(
                url: invalidURL,
                name: "Test",
                context: context
            )
        }
    }

    // MARK: - Error Handling Tests

    @Test("TemplateImportError has correct descriptions")
    func testTemplateImportErrorDescriptions() {
        let error1 = TemplateImportError.noPDFDocument
        #expect(error1.errorDescription == "Unable to read PDF document")

        let error2 = TemplateImportError.analysisError
        #expect(error2.errorDescription == "Failed to analyze document layout")

        let error3 = TemplateImportError.invalidLayout
        #expect(error3.errorDescription == "Document layout could not be determined")

        let error4 = TemplateImportError.noContentFound
        #expect(error4.errorDescription == "No content found in document")

        let error5 = TemplateImportError.unsupportedFormat
        #expect(error5.errorDescription == "Document format not supported")
    }

    @Test("TemplateImportError has recovery suggestions")
    func testTemplateImportErrorRecoverySuggestions() {
        let error1 = TemplateImportError.noPDFDocument
        #expect(error1.recoverySuggestion != nil)

        let error2 = TemplateImportError.analysisError
        #expect(error2.recoverySuggestion != nil)
    }
}
