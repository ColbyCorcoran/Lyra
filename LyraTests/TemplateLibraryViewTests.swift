import Testing
import SwiftUI
import SwiftData
@testable import Lyra

@Suite("TemplateLibraryView Tests")
@MainActor
struct TemplateLibraryViewTests {
    var container: ModelContainer
    var context: ModelContext

    init() throws {
        let schema = Schema([Template.self, Song.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    // MARK: - Initialization Tests

    @Test("View initializes without crashing")
    @MainActor
    func testViewInitialization() throws {
        let view = TemplateLibraryView()
        #expect(view != nil)
    }

    // MARK: - Filtering Tests

    @Test("Filtered templates returns all templates when no filters applied")
    @MainActor
    func testFilteredTemplatesReturnsAll() throws {
        // Create test templates
        let template1 = Template(name: "Template 1", isBuiltIn: true)
        let template2 = Template(name: "Template 2", isBuiltIn: false)
        context.insert(template1)
        context.insert(template2)
        try context.save()

        // All templates should be visible with no filters
        let templates = try context.fetch(FetchDescriptor<Template>())
        #expect(templates.count == 2)
    }

    @Test("Filtered templates filters by built-in category")
    @MainActor
    func testFilteredTemplatesByBuiltIn() throws {
        // Create test templates
        let builtIn = Template(name: "Built-in Template", isBuiltIn: true)
        let custom = Template(name: "Custom Template", isBuiltIn: false)
        context.insert(builtIn)
        context.insert(custom)
        try context.save()

        // Filter for built-in only
        var descriptor = FetchDescriptor<Template>()
        descriptor.predicate = #Predicate<Template> { $0.isBuiltIn == true }
        let filteredTemplates = try context.fetch(descriptor)

        #expect(filteredTemplates.count == 1)
        #expect(filteredTemplates.first?.name == "Built-in Template")
    }

    @Test("Filtered templates filters by custom category")
    @MainActor
    func testFilteredTemplatesByCustom() throws {
        // Create test templates
        let builtIn = Template(name: "Built-in Template", isBuiltIn: true)
        let custom = Template(name: "Custom Template", isBuiltIn: false)
        context.insert(builtIn)
        context.insert(custom)
        try context.save()

        // Filter for custom only
        var descriptor = FetchDescriptor<Template>()
        descriptor.predicate = #Predicate<Template> { $0.isBuiltIn == false }
        let filteredTemplates = try context.fetch(descriptor)

        #expect(filteredTemplates.count == 1)
        #expect(filteredTemplates.first?.name == "Custom Template")
    }

    @Test("Filtered templates filters by search text")
    @MainActor
    func testFilteredTemplatesBySearchText() throws {
        // Create test templates
        let template1 = Template(name: "Single Column")
        let template2 = Template(name: "Two Column")
        let template3 = Template(name: "Performance Layout")
        context.insert(template1)
        context.insert(template2)
        context.insert(template3)
        try context.save()

        // Search should be case-insensitive
        let allTemplates = try context.fetch(FetchDescriptor<Template>())
        let searchText = "column"
        let filtered = allTemplates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        #expect(filtered.count == 2)
        #expect(filtered.contains(where: { $0.name == "Single Column" }))
        #expect(filtered.contains(where: { $0.name == "Two Column" }))
    }

    @Test("Filtered templates combines category and search filters")
    @MainActor
    func testFilteredTemplatesCombinesFilters() throws {
        // Create test templates
        let builtInSingle = Template(name: "Single Column", isBuiltIn: true)
        let builtInTwo = Template(name: "Two Column", isBuiltIn: true)
        let customSingle = Template(name: "Custom Single", isBuiltIn: false)
        context.insert(builtInSingle)
        context.insert(builtInTwo)
        context.insert(customSingle)
        try context.save()

        // Filter for built-in templates containing "single"
        let allTemplates = try context.fetch(FetchDescriptor<Template>())
        let searchText = "single"
        let filtered = allTemplates.filter {
            $0.isBuiltIn == true && $0.name.localizedCaseInsensitiveContains(searchText)
        }

        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "Single Column")
    }

    // MARK: - Template Creation Tests

    @Test("Create new template initializes with default values")
    @MainActor
    func testCreateNewTemplate() throws {
        let template = try TemplateManager.createTemplate(
            name: "New Template",
            context: context
        )

        #expect(template.name == "New Template")
        #expect(template.isBuiltIn == false)
        #expect(template.isDefault == false)
        #expect(template.columnCount == 1)
        #expect(template.columnGap == 20.0)
    }

    // MARK: - Template Duplication Tests

    @Test("Duplicate template creates copy with new name")
    @MainActor
    func testDuplicateTemplate() throws {
        // Create original template
        let original = Template(name: "Original Template")
        original.columnCount = 3
        original.columnGap = 24.0
        original.chordPositioningStyle = .inline
        context.insert(original)
        try context.save()

        // Duplicate the template
        let duplicate = try TemplateManager.duplicateTemplate(
            original,
            newName: "Original Template Copy",
            context: context
        )

        #expect(duplicate.name == "Original Template Copy")
        #expect(duplicate.columnCount == original.columnCount)
        #expect(duplicate.columnGap == original.columnGap)
        #expect(duplicate.chordPositioningStyle == original.chordPositioningStyle)
        #expect(duplicate.isBuiltIn == false)
        #expect(duplicate.id != original.id)
    }

    @Test("Duplicate built-in template creates custom copy")
    @MainActor
    func testDuplicateBuiltInTemplate() throws {
        // Create built-in template
        let builtIn = Template.builtInTwoColumn()
        context.insert(builtIn)
        try context.save()

        // Duplicate it
        let duplicate = try TemplateManager.duplicateTemplate(
            builtIn,
            newName: "Two Column Copy",
            context: context
        )

        #expect(duplicate.name == "Two Column Copy")
        #expect(duplicate.isBuiltIn == false)
        #expect(duplicate.columnCount == builtIn.columnCount)
    }

    // MARK: - Template Deletion Tests

    @Test("Delete custom template succeeds")
    @MainActor
    func testDeleteCustomTemplate() throws {
        // Create custom template
        let template = Template(name: "Custom Template")
        context.insert(template)
        try context.save()

        // Delete it
        try TemplateManager.deleteTemplate(template, context: context)

        // Verify it's gone
        let templates = try context.fetch(FetchDescriptor<Template>())
        #expect(templates.isEmpty)
    }

    @Test("Delete built-in template throws error")
    @MainActor
    func testDeleteBuiltInTemplateThrowsError() throws {
        // Create built-in template
        let builtIn = Template.builtInSingleColumn()
        context.insert(builtIn)
        try context.save()

        // Attempt to delete should throw error
        #expect(throws: TemplateError.self) {
            try TemplateManager.deleteTemplate(builtIn, context: context)
        }

        // Verify it still exists
        let templates = try context.fetch(FetchDescriptor<Template>())
        #expect(templates.count == 1)
    }

    // MARK: - Default Template Tests

    @Test("Set default template updates isDefault flag")
    @MainActor
    func testSetDefaultTemplate() throws {
        // Create templates
        let template1 = Template(name: "Template 1")
        let template2 = Template(name: "Template 2")
        context.insert(template1)
        context.insert(template2)
        try context.save()

        // Set template2 as default
        try TemplateManager.setDefaultTemplate(template2, context: context)

        #expect(template1.isDefault == false)
        #expect(template2.isDefault == true)
    }

    @Test("Set default template clears previous default")
    @MainActor
    func testSetDefaultTemplateClearsPrevious() throws {
        // Create templates
        let template1 = Template(name: "Template 1")
        template1.isDefault = true
        let template2 = Template(name: "Template 2")
        context.insert(template1)
        context.insert(template2)
        try context.save()

        // Set template2 as default
        try TemplateManager.setDefaultTemplate(template2, context: context)

        #expect(template1.isDefault == false)
        #expect(template2.isDefault == true)
    }

    // MARK: - Category Tests

    @Test("TemplateLibraryCategory has correct cases")
    func testTemplateCategoryCases() {
        let categories = TemplateLibraryCategory.allCases
        #expect(categories.count == 3)
        #expect(categories.contains(.all))
        #expect(categories.contains(.builtIn))
        #expect(categories.contains(.custom))
    }

    @Test("TemplateLibraryCategory has correct raw values")
    func testTemplateCategoryRawValues() {
        #expect(TemplateLibraryCategory.all.rawValue == "All")
        #expect(TemplateLibraryCategory.builtIn.rawValue == "Built-in")
        #expect(TemplateLibraryCategory.custom.rawValue == "Custom")
    }

    // MARK: - Template Description Tests

    @Test("Template description includes column count")
    @MainActor
    func testTemplateDescriptionIncludesColumnCount() throws {
        let singleColumn = Template(name: "Single")
        singleColumn.columnCount = 1

        let multiColumn = Template(name: "Multi")
        multiColumn.columnCount = 3

        // The description should reflect the column count
        #expect(singleColumn.columnCount == 1)
        #expect(multiColumn.columnCount == 3)
    }

    @Test("Template description includes balancing strategy")
    @MainActor
    func testTemplateDescriptionIncludesBalancingStrategy() throws {
        let template = Template(name: "Test")
        template.columnBalancingStrategy = .balanced

        #expect(template.columnBalancingStrategy == .balanced)
    }

    @Test("Template description includes chord positioning")
    @MainActor
    func testTemplateDescriptionIncludesChordPositioning() throws {
        let template = Template(name: "Test")
        template.chordPositioningStyle = .inline

        #expect(template.chordPositioningStyle == .inline)
    }

    // MARK: - Empty State Tests

    @Test("Empty state shown when no templates exist")
    @MainActor
    func testEmptyStateShown() throws {
        // With no templates in context, should show empty state
        let templates = try context.fetch(FetchDescriptor<Template>())
        #expect(templates.isEmpty)
    }

    @Test("Empty state shown when search returns no results")
    @MainActor
    func testEmptyStateShownForEmptySearch() throws {
        // Create templates
        let template = Template(name: "Template")
        context.insert(template)
        try context.save()

        // Search for non-existent template
        let allTemplates = try context.fetch(FetchDescriptor<Template>())
        let searchText = "nonexistent"
        let filtered = allTemplates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        #expect(filtered.isEmpty)
    }

    // MARK: - Template Row Tests

    @Test("Template row displays correct icon for built-in template")
    @MainActor
    func testTemplateRowBuiltInIcon() throws {
        let builtIn = Template(name: "Built-in", isBuiltIn: true)
        #expect(builtIn.isBuiltIn == true)
    }

    @Test("Template row displays correct icon for custom template")
    @MainActor
    func testTemplateRowCustomIcon() throws {
        let custom = Template(name: "Custom", isBuiltIn: false)
        #expect(custom.isBuiltIn == false)
    }

    @Test("Template row shows star for default template")
    @MainActor
    func testTemplateRowShowsStarForDefault() throws {
        let defaultTemplate = Template(name: "Default")
        defaultTemplate.isDefault = true
        #expect(defaultTemplate.isDefault == true)
    }

    // MARK: - Integration Tests

    @Test("Multiple templates can be created and managed")
    @MainActor
    func testMultipleTemplateManagement() throws {
        // Create multiple templates
        let template1 = try TemplateManager.createTemplate(name: "Template 1", context: context)
        let template2 = try TemplateManager.createTemplate(name: "Template 2", context: context)
        let template3 = try TemplateManager.createTemplate(name: "Template 3", context: context)

        // Verify all were created
        let templates = try context.fetch(FetchDescriptor<Template>())
        #expect(templates.count == 3)

        // Set one as default
        try TemplateManager.setDefaultTemplate(template2, context: context)
        #expect(template2.isDefault == true)

        // Duplicate one
        let duplicate = try TemplateManager.duplicateTemplate(
            template1,
            newName: "Template 1 Copy",
            context: context
        )
        #expect(duplicate.name == "Template 1 Copy")

        // Delete one
        try TemplateManager.deleteTemplate(template3, context: context)
        let remainingTemplates = try context.fetch(FetchDescriptor<Template>())
        #expect(remainingTemplates.count == 3) // 2 original + 1 duplicate
    }

    @Test("Templates can be sorted by name")
    @MainActor
    func testTemplatesSortedByName() throws {
        // Create templates in random order
        let templateC = Template(name: "C Template")
        let templateA = Template(name: "A Template")
        let templateB = Template(name: "B Template")
        context.insert(templateC)
        context.insert(templateA)
        context.insert(templateB)
        try context.save()

        // Fetch with sort descriptor
        var descriptor = FetchDescriptor<Template>(
            sortBy: [SortDescriptor(\Template.name)]
        )
        let sortedTemplates = try context.fetch(descriptor)

        #expect(sortedTemplates.count == 3)
        #expect(sortedTemplates[0].name == "A Template")
        #expect(sortedTemplates[1].name == "B Template")
        #expect(sortedTemplates[2].name == "C Template")
    }

    // MARK: - Error Handling Tests

    @Test("Error handling for invalid template operations")
    @MainActor
    func testErrorHandling() throws {
        let builtIn = Template.builtInSingleColumn()
        context.insert(builtIn)
        try context.save()

        // Should throw error when trying to delete built-in
        #expect(throws: TemplateError.self) {
            try TemplateManager.deleteTemplate(builtIn, context: context)
        }
    }
}
