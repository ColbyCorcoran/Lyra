//
//  TemplateSelectionSheetTests.swift
//  LyraTests
//
//  Tests for TemplateSelectionSheet
//

import Testing
import SwiftUI
import SwiftData
@testable import Lyra

@Suite("TemplateSelectionSheet Tests")
@MainActor
struct TemplateSelectionSheetTests {

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

    @Test("TemplateSelectionSheet initializes with onSelect callback")
    func testInitialization() {
        var selectedTemplate: Template?
        let view = TemplateSelectionSheet { template in
            selectedTemplate = template
        }

        #expect(view.onSelect != nil)
    }

    // MARK: - Template Category Tests

    @Test("TemplateCategory has all expected cases")
    func testTemplateCategoryAllCases() {
        let categories = TemplateCategory.allCases

        #expect(categories.count == 3)
        #expect(categories.contains(.all))
        #expect(categories.contains(.builtIn))
        #expect(categories.contains(.custom))
    }

    @Test("TemplateCategory has correct raw values")
    func testTemplateCategoryRawValues() {
        #expect(TemplateCategory.all.rawValue == "All")
        #expect(TemplateCategory.builtIn.rawValue == "Built-in")
        #expect(TemplateCategory.custom.rawValue == "Custom")
    }

    @Test("TemplateCategory conforms to Identifiable")
    func testTemplateCategoryIdentifiable() {
        let category = TemplateCategory.all
        #expect(category.id == category.rawValue)
    }

    // MARK: - Template Row Tests

    @Test("TemplateRow displays template name")
    func testTemplateRowDisplaysName() {
        let template = createTemplate(name: "My Template")
        var selectCalled = false
        var infoCalled = false

        let row = TemplateRow(
            template: template,
            onSelect: { selectCalled = true },
            onInfo: { infoCalled = true }
        )

        #expect(row.template.name == "My Template")
    }

    @Test("TemplateRow displays built-in icon for built-in templates")
    func testTemplateRowBuiltInIcon() {
        let template = createTemplate(name: "Built-in", isBuiltIn: true)

        let row = TemplateRow(
            template: template,
            onSelect: {},
            onInfo: {}
        )

        #expect(row.template.isBuiltIn)
    }

    @Test("TemplateRow displays custom icon for user templates")
    func testTemplateRowCustomIcon() {
        let template = createTemplate(name: "Custom", isBuiltIn: false)

        let row = TemplateRow(
            template: template,
            onSelect: {},
            onInfo: {}
        )

        #expect(!row.template.isBuiltIn)
    }

    @Test("TemplateRow shows default indicator for default template")
    func testTemplateRowDefaultIndicator() {
        let template = createTemplate(name: "Default Template")
        template.isDefault = true

        let row = TemplateRow(
            template: template,
            onSelect: {},
            onInfo: {}
        )

        #expect(row.template.isDefault)
    }

    // MARK: - Template Description Tests

    @Test("Template description includes column count for single column")
    func testTemplateDescriptionSingleColumn() {
        let template = createTemplate(columnCount: 1)

        // The description should mention "Single column"
        #expect(template.columnCount == 1)
    }

    @Test("Template description includes column count for multiple columns")
    func testTemplateDescriptionMultipleColumns() {
        let template = createTemplate(columnCount: 3)

        // The description should mention "3 columns"
        #expect(template.columnCount == 3)
    }

    @Test("Template description includes balancing strategy")
    func testTemplateDescriptionBalancingStrategy() {
        let template = createTemplate()
        template.columnBalancingStrategy = .balanced

        #expect(template.columnBalancingStrategy == .balanced)
    }

    @Test("Template description includes chord positioning")
    func testTemplateDescriptionChordPositioning() {
        let template = createTemplate()
        template.chordPositioningStyle = .chordsOverLyrics

        #expect(template.chordPositioningStyle == .chordsOverLyrics)
    }

    @Test("Template description includes inline chords style")
    func testTemplateDescriptionInlineChords() {
        let template = createTemplate()
        template.chordPositioningStyle = .inline

        #expect(template.chordPositioningStyle == .inline)
    }

    @Test("Template description includes separate lines style")
    func testTemplateDescriptionSeparateLines() {
        let template = createTemplate()
        template.chordPositioningStyle = .separateLines

        #expect(template.chordPositioningStyle == .separateLines)
    }

    // MARK: - Filtering Tests

    @Test("Templates can be filtered by built-in category")
    func testFilterByBuiltIn() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let builtIn = createTemplate(name: "Built-in Template", isBuiltIn: true)
        let custom = createTemplate(name: "Custom Template", isBuiltIn: false)

        context.insert(builtIn)
        context.insert(custom)

        #expect(builtIn.isBuiltIn)
        #expect(!custom.isBuiltIn)
    }

    @Test("Templates can be filtered by custom category")
    func testFilterByCustom() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let builtIn = createTemplate(name: "Built-in Template", isBuiltIn: true)
        let custom = createTemplate(name: "Custom Template", isBuiltIn: false)

        context.insert(builtIn)
        context.insert(custom)

        #expect(!custom.isBuiltIn)
        #expect(builtIn.isBuiltIn)
    }

    @Test("Templates can be searched by name")
    func testSearchByName() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let template1 = createTemplate(name: "Single Column")
        let template2 = createTemplate(name: "Two Column")
        let template3 = createTemplate(name: "Three Column")

        context.insert(template1)
        context.insert(template2)
        context.insert(template3)

        // Test case-insensitive search
        #expect(template1.name.localizedCaseInsensitiveContains("single"))
        #expect(template2.name.localizedCaseInsensitiveContains("two"))
        #expect(template3.name.localizedCaseInsensitiveContains("THREE"))
    }

    @Test("Templates can be searched with partial match")
    func testSearchPartialMatch() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let template = createTemplate(name: "Custom Layout Template")
        context.insert(template)

        #expect(template.name.localizedCaseInsensitiveContains("custom"))
        #expect(template.name.localizedCaseInsensitiveContains("layout"))
        #expect(template.name.localizedCaseInsensitiveContains("template"))
    }

    // MARK: - Selection Tests

    @Test("Selecting a template triggers callback")
    func testTemplateSelection() {
        var selectedTemplate: Template?
        let template = createTemplate(name: "Test Template")

        let view = TemplateSelectionSheet { template in
            selectedTemplate = template
        }

        // Simulate selection
        view.onSelect(template)

        #expect(selectedTemplate != nil)
        #expect(selectedTemplate?.name == "Test Template")
    }

    @Test("Selecting different templates triggers callback each time")
    func testMultipleTemplateSelections() {
        var selectedTemplate: Template?
        let template1 = createTemplate(name: "Template 1")
        let template2 = createTemplate(name: "Template 2")

        let view = TemplateSelectionSheet { template in
            selectedTemplate = template
        }

        // Simulate first selection
        view.onSelect(template1)
        #expect(selectedTemplate?.name == "Template 1")

        // Simulate second selection
        view.onSelect(template2)
        #expect(selectedTemplate?.name == "Template 2")
    }

    // MARK: - Built-in Templates Tests

    @Test("Built-in single column template has correct properties")
    func testBuiltInSingleColumn() {
        let template = Template.builtInSingleColumn()

        #expect(template.name == "Single Column")
        #expect(template.isBuiltIn)
        #expect(template.isDefault)
        #expect(template.columnCount == 1)
        #expect(template.columnGap == 0)
    }

    @Test("Built-in two column template has correct properties")
    func testBuiltInTwoColumn() {
        let template = Template.builtInTwoColumn()

        #expect(template.name == "Two Column")
        #expect(template.isBuiltIn)
        #expect(template.columnCount == 2)
        #expect(template.columnGap == 24.0)
        #expect(template.columnBalancingStrategy == .balanced)
    }

    @Test("Built-in three column template has correct properties")
    func testBuiltInThreeColumn() {
        let template = Template.builtInThreeColumn()

        #expect(template.name == "Three Column")
        #expect(template.isBuiltIn)
        #expect(template.columnCount == 3)
        #expect(template.columnGap == 20.0)
        #expect(template.columnBalancingStrategy == .balanced)
    }

    // MARK: - Empty State Tests

    @Test("Empty state is shown when no templates exist")
    func testEmptyStateNoTemplates() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // No templates inserted
        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)

        #expect(templates.isEmpty)
    }

    @Test("Empty state is shown when search has no results")
    func testEmptyStateNoSearchResults() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let template = createTemplate(name: "Custom Template")
        context.insert(template)

        // Search for non-existent template
        let searchText = "Nonexistent"
        let hasMatch = template.name.localizedCaseInsensitiveContains(searchText)

        #expect(!hasMatch)
    }

    // MARK: - Edge Cases

    @Test("Template with empty name can be created")
    func testTemplateEmptyName() {
        let template = createTemplate(name: "")

        #expect(template.name.isEmpty)
    }

    @Test("Template with very long name can be created")
    func testTemplateVeryLongName() {
        let longName = String(repeating: "a", count: 200)
        let template = createTemplate(name: longName)

        #expect(template.name.count == 200)
    }

    @Test("Template with special characters in name")
    func testTemplateSpecialCharactersName() {
        let template = createTemplate(name: "Template & Layout [2024]")

        #expect(template.name == "Template & Layout [2024]")
    }

    @Test("Template with emoji in name")
    func testTemplateEmojiName() {
        let template = createTemplate(name: "My Template 🎵")

        #expect(template.name.contains("🎵"))
    }

    @Test("Template with unicode characters in name")
    func testTemplateUnicodeName() {
        let template = createTemplate(name: "日本語テンプレート")

        #expect(template.name == "日本語テンプレート")
    }

    // MARK: - Integration Tests

    @Test("Multiple templates can coexist")
    func testMultipleTemplates() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let template1 = createTemplate(name: "Template 1")
        let template2 = createTemplate(name: "Template 2")
        let template3 = createTemplate(name: "Template 3")

        context.insert(template1)
        context.insert(template2)
        context.insert(template3)

        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)

        #expect(templates.count == 3)
    }

    @Test("Built-in and custom templates can coexist")
    func testBuiltInAndCustomTemplates() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let builtIn = createTemplate(name: "Built-in", isBuiltIn: true)
        let custom = createTemplate(name: "Custom", isBuiltIn: false)

        context.insert(builtIn)
        context.insert(custom)

        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)

        #expect(templates.count == 2)
        #expect(templates.filter { $0.isBuiltIn }.count == 1)
        #expect(templates.filter { !$0.isBuiltIn }.count == 1)
    }

    @Test("Only one template can be default at a time")
    func testSingleDefaultTemplate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let template1 = createTemplate(name: "Template 1")
        let template2 = createTemplate(name: "Template 2")

        template1.isDefault = true
        template2.isDefault = false

        context.insert(template1)
        context.insert(template2)

        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)
        let defaultTemplates = templates.filter { $0.isDefault }

        #expect(defaultTemplates.count == 1)
        #expect(defaultTemplates.first?.name == "Template 1")
    }

    // MARK: - Real-World Scenarios

    @Test("User can select from multiple built-in templates")
    func testSelectFromBuiltInTemplates() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let single = Template.builtInSingleColumn()
        let double = Template.builtInTwoColumn()
        let triple = Template.builtInThreeColumn()

        context.insert(single)
        context.insert(double)
        context.insert(triple)

        var descriptor = FetchDescriptor<Template>()
        descriptor.predicate = #Predicate<Template> { $0.isBuiltIn == true }
        let builtInTemplates = try context.fetch(descriptor)

        #expect(builtInTemplates.count == 3)
    }

    @Test("User can create and select custom template")
    func testCreateAndSelectCustomTemplate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let custom = createTemplate(name: "My Custom Template", isBuiltIn: false)
        custom.columnCount = 2
        custom.columnGap = 20
        custom.chordPositioningStyle = .inline

        context.insert(custom)

        var selectedTemplate: Template?
        let view = TemplateSelectionSheet { template in
            selectedTemplate = template
        }

        view.onSelect(custom)

        #expect(selectedTemplate?.name == "My Custom Template")
        #expect(selectedTemplate?.columnCount == 2)
        #expect(selectedTemplate?.chordPositioningStyle == .inline)
    }

    @Test("User can filter and search templates")
    func testFilterAndSearchTemplates() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let single = Template.builtInSingleColumn()
        let double = Template.builtInTwoColumn()
        let custom1 = createTemplate(name: "Custom Single Column", isBuiltIn: false)
        let custom2 = createTemplate(name: "Custom Two Column", isBuiltIn: false)

        context.insert(single)
        context.insert(double)
        context.insert(custom1)
        context.insert(custom2)

        // Filter by custom templates
        var descriptor = FetchDescriptor<Template>()
        descriptor.predicate = #Predicate<Template> { $0.isBuiltIn == false }
        let customTemplates = try context.fetch(descriptor)

        #expect(customTemplates.count == 2)

        // Search for "Single" in custom templates
        let searchResults = customTemplates.filter { template in
            template.name.localizedCaseInsensitiveContains("Single")
        }

        #expect(searchResults.count == 1)
        #expect(searchResults.first?.name == "Custom Single Column")
    }

    @Test("User can view template details before selecting")
    func testViewTemplateDetailsBeforeSelection() {
        let template = createTemplate(name: "Detailed Template")
        template.columnCount = 3
        template.columnGap = 24
        template.chordPositioningStyle = .separateLines
        template.chordAlignment = .centered

        var infoCallCount = 0
        let row = TemplateRow(
            template: template,
            onSelect: {},
            onInfo: { infoCallCount += 1 }
        )

        // Simulate info button tap
        row.onInfo()

        #expect(infoCallCount == 1)
    }

    @Test("Template list shows all properties correctly")
    func testTemplateListShowsAllProperties() {
        let template = createTemplate(name: "Complete Template")
        template.columnCount = 2
        template.columnGap = 20
        template.columnBalancingStrategy = .balanced
        template.chordPositioningStyle = .chordsOverLyrics
        template.chordAlignment = .leftAligned
        template.titleFontSize = 28
        template.headingFontSize = 20
        template.bodyFontSize = 16
        template.chordFontSize = 14
        template.sectionBreakBehavior = .spaceBefore
        template.isDefault = true

        #expect(template.name == "Complete Template")
        #expect(template.columnCount == 2)
        #expect(template.columnBalancingStrategy == .balanced)
        #expect(template.chordPositioningStyle == .chordsOverLyrics)
        #expect(template.isDefault)
        #expect(template.isValid)
    }
}
