//
//  TemplateEditorViewTests.swift
//  LyraTests
//
//  Tests for TemplateEditorView
//

import Testing
import SwiftUI
import SwiftData
@testable import Lyra

@Suite("TemplateEditorView Tests")
struct TemplateEditorViewTests {

    // MARK: - Test Helpers

    /// Create a test template
    private func createTemplate(
        name: String = "Test Template",
        isBuiltIn: Bool = false,
        columnCount: Int = 2
    ) -> Template {
        let template = Template(name: name)
        template.isBuiltIn = isBuiltIn
        template.columnCount = columnCount
        template.columnGap = 16
        template.columnWidthMode = .equal
        template.columnBalancingStrategy = .balanced
        template.chordPositioningStyle = .chordsOverLyrics
        template.chordAlignment = .leftAligned
        template.titleFontSize = 24
        template.headingFontSize = 18
        template.bodyFontSize = 14
        template.chordFontSize = 12
        template.sectionBreakBehavior = .spaceBefore
        return template
    }

    /// Create in-memory model container for testing
    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Template.self, configurations: config)
    }

    // MARK: - Initialization Tests

    @Test("TemplateEditorView initializes with template properties")
    func testInitialization() {
        let template = createTemplate(name: "Custom Layout")

        let view = TemplateEditorView(template: template)

        #expect(view.template.name == "Custom Layout")
        #expect(view.template.columnCount == 2)
    }

    @Test("TemplateEditorView initializes with built-in template")
    func testBuiltInTemplateInitialization() {
        let template = createTemplate(name: "Single Column", isBuiltIn: true)
        template.columnCount = 1

        let view = TemplateEditorView(template: template)

        #expect(view.template.isBuiltIn == true)
        #expect(view.template.name == "Single Column")
    }

    @Test("TemplateEditorView initializes with custom column count")
    func testCustomColumnCount() {
        let template = createTemplate(columnCount: 4)

        let view = TemplateEditorView(template: template)

        #expect(view.template.columnCount == 4)
    }

    // MARK: - Column Configuration Tests

    @Test("Template supports single column configuration")
    func testSingleColumnConfiguration() {
        let template = createTemplate(columnCount: 1)

        #expect(template.columnCount == 1)
        #expect(template.columnCount >= 1 && template.columnCount <= 4)
    }

    @Test("Template supports four column configuration")
    func testFourColumnConfiguration() {
        let template = createTemplate(columnCount: 4)

        #expect(template.columnCount == 4)
        #expect(template.columnCount >= 1 && template.columnCount <= 4)
    }

    @Test("Template column gap is configurable")
    func testColumnGapConfiguration() {
        let template = createTemplate()
        template.columnGap = 24

        #expect(template.columnGap == 24)
    }

    @Test("Template supports equal column width mode")
    func testEqualColumnWidthMode() {
        let template = createTemplate()
        template.columnWidthMode = .equal

        #expect(template.columnWidthMode == .equal)
    }

    @Test("Template supports custom column width mode")
    func testCustomColumnWidthMode() {
        let template = createTemplate()
        template.columnWidthMode = .custom
        template.customColumnWidths = [1.0, 1.5, 1.0]

        #expect(template.columnWidthMode == .custom)
        #expect(template.customColumnWidths?.count == 3)
    }

    @Test("Template supports all balancing strategies")
    func testBalancingStrategies() {
        let template = createTemplate()

        template.columnBalancingStrategy = .fillFirst
        #expect(template.columnBalancingStrategy == .fillFirst)

        template.columnBalancingStrategy = .balanced
        #expect(template.columnBalancingStrategy == .balanced)

        template.columnBalancingStrategy = .sectionBased
        #expect(template.columnBalancingStrategy == .sectionBased)
    }

    // MARK: - Chord Positioning Tests

    @Test("Template supports all chord positioning styles")
    func testChordPositioningStyles() {
        let template = createTemplate()

        template.chordPositioningStyle = .chordsOverLyrics
        #expect(template.chordPositioningStyle == .chordsOverLyrics)

        template.chordPositioningStyle = .inline
        #expect(template.chordPositioningStyle == .inline)

        template.chordPositioningStyle = .separateLines
        #expect(template.chordPositioningStyle == .separateLines)
    }

    @Test("Template supports all chord alignments")
    func testChordAlignments() {
        let template = createTemplate()

        template.chordAlignment = .leftAligned
        #expect(template.chordAlignment == .leftAligned)

        template.chordAlignment = .centered
        #expect(template.chordAlignment == .centered)

        template.chordAlignment = .rightAligned
        #expect(template.chordAlignment == .rightAligned)
    }

    // MARK: - Typography Tests

    @Test("Template title font size is configurable")
    func testTitleFontSize() {
        let template = createTemplate()
        template.titleFontSize = 32

        #expect(template.titleFontSize == 32)
        #expect(template.titleFontSize >= 18 && template.titleFontSize <= 48)
    }

    @Test("Template heading font size is configurable")
    func testHeadingFontSize() {
        let template = createTemplate()
        template.headingFontSize = 20

        #expect(template.headingFontSize == 20)
        #expect(template.headingFontSize >= 12 && template.headingFontSize <= 32)
    }

    @Test("Template body font size is configurable")
    func testBodyFontSize() {
        let template = createTemplate()
        template.bodyFontSize = 16

        #expect(template.bodyFontSize == 16)
        #expect(template.bodyFontSize >= 10 && template.bodyFontSize <= 24)
    }

    @Test("Template chord font size is configurable")
    func testChordFontSize() {
        let template = createTemplate()
        template.chordFontSize = 14

        #expect(template.chordFontSize == 14)
        #expect(template.chordFontSize >= 8 && template.chordFontSize <= 20)
    }

    // MARK: - Layout Rules Tests

    @Test("Template supports all section break behaviors")
    func testSectionBreakBehaviors() {
        let template = createTemplate()

        template.sectionBreakBehavior = .continueInColumn
        #expect(template.sectionBreakBehavior == .continueInColumn)

        template.sectionBreakBehavior = .newColumn
        #expect(template.sectionBreakBehavior == .newColumn)

        template.sectionBreakBehavior = .spaceBefore
        #expect(template.sectionBreakBehavior == .spaceBefore)
    }

    // MARK: - Validation Tests

    @Test("Template with valid configuration passes validation")
    func testValidTemplateConfiguration() {
        let template = createTemplate()

        #expect(template.isValid)
    }

    @Test("Template with invalid column count fails validation")
    func testInvalidColumnCount() {
        let template = createTemplate()
        template.columnCount = 0

        #expect(!template.isValid)
    }

    @Test("Template with negative font size fails validation")
    func testInvalidFontSize() {
        let template = createTemplate()
        template.bodyFontSize = -1

        #expect(!template.isValid)
    }

    @Test("Template with negative column gap fails validation")
    func testInvalidColumnGap() {
        let template = createTemplate()
        template.columnGap = -10

        #expect(!template.isValid)
    }

    // MARK: - Custom Column Widths Tests

    @Test("Custom column widths array matches column count")
    func testCustomColumnWidthsArraySize() {
        let template = createTemplate(columnCount: 3)
        template.columnWidthMode = .custom
        template.customColumnWidths = [1.0, 1.5, 1.0]

        #expect(template.customColumnWidths?.count == template.columnCount)
    }

    @Test("Custom column widths with valid values")
    func testValidCustomColumnWidths() {
        let template = createTemplate(columnCount: 3)
        template.columnWidthMode = .custom
        template.customColumnWidths = [1.0, 1.5, 2.0]

        #expect(template.isValid)
    }

    @Test("Custom column widths returns nil for equal mode")
    func testNilCustomColumnWidthsForEqualMode() {
        let template = createTemplate()
        template.columnWidthMode = .equal
        template.customColumnWidths = nil

        #expect(template.customColumnWidths == nil)
    }

    // MARK: - Built-in Template Tests

    @Test("Built-in templates cannot be edited flag")
    func testBuiltInTemplateFlag() {
        let template = createTemplate(isBuiltIn: true)

        #expect(template.isBuiltIn)
    }

    @Test("User templates can be edited")
    func testUserTemplateFlag() {
        let template = createTemplate(isBuiltIn: false)

        #expect(!template.isBuiltIn)
    }

    // MARK: - Default Template Tests

    @Test("Template can be set as default")
    func testDefaultTemplateFlag() {
        let template = createTemplate()
        template.isDefault = true

        #expect(template.isDefault)
    }

    @Test("Template default flag can be cleared")
    func testClearDefaultTemplateFlag() {
        let template = createTemplate()
        template.isDefault = true
        template.isDefault = false

        #expect(!template.isDefault)
    }

    // MARK: - Integration Tests

    @Test("Template properties update correctly")
    func testTemplatePropertyUpdates() {
        let template = createTemplate()

        // Update various properties
        template.name = "Updated Template"
        template.columnCount = 3
        template.columnGap = 20
        template.chordPositioningStyle = .inline
        template.chordAlignment = .centered
        template.titleFontSize = 28

        #expect(template.name == "Updated Template")
        #expect(template.columnCount == 3)
        #expect(template.columnGap == 20)
        #expect(template.chordPositioningStyle == .inline)
        #expect(template.chordAlignment == .centered)
        #expect(template.titleFontSize == 28)
    }

    @Test("Template effective column widths calculation")
    func testEffectiveColumnWidthsCalculation() {
        let template = createTemplate(columnCount: 3)
        template.columnWidthMode = .equal

        let widths = template.effectiveColumnWidths(totalWidth: 900)

        #expect(widths.count == 3)

        // All widths should be equal for equal mode
        let firstWidth = widths[0]
        for width in widths {
            #expect(abs(width - firstWidth) < 1.0)
        }
    }

    @Test("Template effective column widths with custom mode")
    func testEffectiveColumnWidthsCustomMode() {
        let template = createTemplate(columnCount: 3)
        template.columnWidthMode = .custom
        template.customColumnWidths = [1.0, 2.0, 1.0]

        let widths = template.effectiveColumnWidths(totalWidth: 900)

        #expect(widths.count == 3)
        #expect(widths[1] > widths[0]) // Middle column should be wider
    }

    // MARK: - Edge Cases

    @Test("Template handles empty name")
    func testEmptyTemplateName() {
        let template = createTemplate(name: "")

        #expect(template.name.isEmpty)
    }

    @Test("Template handles very long name")
    func testVeryLongTemplateName() {
        let longName = String(repeating: "a", count: 200)
        let template = createTemplate(name: longName)

        #expect(template.name.count == 200)
    }

    @Test("Template handles minimum font sizes")
    func testMinimumFontSizes() {
        let template = createTemplate()
        template.titleFontSize = 18
        template.headingFontSize = 12
        template.bodyFontSize = 10
        template.chordFontSize = 8

        #expect(template.titleFontSize == 18)
        #expect(template.headingFontSize == 12)
        #expect(template.bodyFontSize == 10)
        #expect(template.chordFontSize == 8)
    }

    @Test("Template handles maximum font sizes")
    func testMaximumFontSizes() {
        let template = createTemplate()
        template.titleFontSize = 48
        template.headingFontSize = 32
        template.bodyFontSize = 24
        template.chordFontSize = 20

        #expect(template.titleFontSize == 48)
        #expect(template.headingFontSize == 32)
        #expect(template.bodyFontSize == 24)
        #expect(template.chordFontSize == 20)
    }

    @Test("Template handles zero column gap")
    func testZeroColumnGap() {
        let template = createTemplate()
        template.columnGap = 0

        #expect(template.columnGap == 0)
        #expect(template.isValid)
    }

    @Test("Template handles maximum column gap")
    func testMaximumColumnGap() {
        let template = createTemplate()
        template.columnGap = 40

        #expect(template.columnGap == 40)
    }

    // MARK: - Real-World Scenarios

    @Test("Template for single column lyrics-only layout")
    func testSingleColumnLyricsLayout() {
        let template = createTemplate(name: "Lyrics Only")
        template.columnCount = 1
        template.columnGap = 0
        template.chordPositioningStyle = .separateLines
        template.bodyFontSize = 16

        #expect(template.columnCount == 1)
        #expect(template.chordPositioningStyle == .separateLines)
        #expect(template.isValid)
    }

    @Test("Template for two column balanced layout")
    func testTwoColumnBalancedLayout() {
        let template = createTemplate(name: "Two Column Balanced")
        template.columnCount = 2
        template.columnGap = 20
        template.columnBalancingStrategy = .balanced
        template.columnWidthMode = .equal

        #expect(template.columnCount == 2)
        #expect(template.columnBalancingStrategy == .balanced)
        #expect(template.columnWidthMode == .equal)
        #expect(template.isValid)
    }

    @Test("Template for three column custom width layout")
    func testThreeColumnCustomLayout() {
        let template = createTemplate(name: "Three Column Custom")
        template.columnCount = 3
        template.columnGap = 16
        template.columnBalancingStrategy = .sectionBased
        template.columnWidthMode = .custom
        template.customColumnWidths = [1.0, 1.5, 1.0]

        #expect(template.columnCount == 3)
        #expect(template.columnBalancingStrategy == .sectionBased)
        #expect(template.columnWidthMode == .custom)
        #expect(template.customColumnWidths?.count == 3)
        #expect(template.isValid)
    }

    @Test("Template for compact mobile layout")
    func testCompactMobileLayout() {
        let template = createTemplate(name: "Mobile Compact")
        template.columnCount = 1
        template.titleFontSize = 20
        template.headingFontSize = 14
        template.bodyFontSize = 12
        template.chordFontSize = 10
        template.sectionBreakBehavior = .spaceBefore

        #expect(template.columnCount == 1)
        #expect(template.bodyFontSize == 12)
        #expect(template.isValid)
    }

    @Test("Template for large display layout")
    func testLargeDisplayLayout() {
        let template = createTemplate(name: "Large Display")
        template.columnCount = 3
        template.columnGap = 32
        template.titleFontSize = 36
        template.headingFontSize = 24
        template.bodyFontSize = 18
        template.chordFontSize = 16

        #expect(template.columnCount == 3)
        #expect(template.columnGap == 32)
        #expect(template.titleFontSize == 36)
        #expect(template.isValid)
    }

    @Test("Template for projection layout")
    func testProjectionLayout() {
        let template = createTemplate(name: "Projection")
        template.columnCount = 1
        template.columnGap = 0
        template.titleFontSize = 48
        template.bodyFontSize = 24
        template.chordFontSize = 20
        template.chordPositioningStyle = .chordsOverLyrics
        template.chordAlignment = .centered

        #expect(template.columnCount == 1)
        #expect(template.titleFontSize == 48)
        #expect(template.chordAlignment == .centered)
        #expect(template.isValid)
    }
}
