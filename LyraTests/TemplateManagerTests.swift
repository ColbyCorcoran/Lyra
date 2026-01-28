//
//  TemplateManagerTests.swift
//  LyraTests
//
//  Tests for TemplateManager utility
//

import Testing
import SwiftData
import Foundation
@testable import Lyra

@Suite("TemplateManager Tests")
struct TemplateManagerTests {
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

    @Test("Create template with valid name")
    @MainActor
    func testCreateTemplate() throws {
        let template = try TemplateManager.createTemplate(
            name: "Test Template",
            context: context
        )

        #expect(template.name == "Test Template")
        #expect(!template.isBuiltIn)
        #expect(!template.isDefault)

        // Verify it was saved to context
        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)
        #expect(templates.count == 1)
        #expect(templates[0].name == "Test Template")
    }

    // MARK: - Update Tests

    @Test("Update template modifies timestamp")
    @MainActor
    func testUpdateTemplate() throws {
        let template = try TemplateManager.createTemplate(
            name: "Test Template",
            context: context
        )

        let originalModifiedAt = template.modifiedAt

        // Wait a tiny bit to ensure timestamp changes
        Thread.sleep(forTimeInterval: 0.01)

        template.columnCount = 3
        try TemplateManager.updateTemplate(template, context: context)

        #expect(template.modifiedAt > originalModifiedAt)
        #expect(template.columnCount == 3)
    }

    // MARK: - Delete Tests

    @Test("Delete user template")
    @MainActor
    func testDeleteUserTemplate() throws {
        let template = try TemplateManager.createTemplate(
            name: "To Delete",
            context: context
        )

        var descriptor = FetchDescriptor<Template>()
        var templates = try context.fetch(descriptor)
        #expect(templates.count == 1)

        try TemplateManager.deleteTemplate(template, context: context)

        descriptor = FetchDescriptor<Template>()
        templates = try context.fetch(descriptor)
        #expect(templates.count == 0)
    }

    @Test("Cannot delete built-in template")
    @MainActor
    func testCannotDeleteBuiltInTemplate() throws {
        let template = Template.builtInSingleColumn()
        context.insert(template)
        try context.save()

        #expect(throws: TemplateError.self) {
            try TemplateManager.deleteTemplate(template, context: context)
        }

        // Verify template still exists
        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)
        #expect(templates.count == 1)
    }

    // MARK: - Duplicate Tests

    @Test("Duplicate template creates copy with new name")
    @MainActor
    func testDuplicateTemplate() throws {
        let original = Template(
            name: "Original",
            columnCount: 2,
            columnGap: 25.0,
            titleFontSize: 30.0
        )
        context.insert(original)
        try context.save()

        let duplicate = try TemplateManager.duplicateTemplate(
            original,
            newName: "Copy of Original",
            context: context
        )

        #expect(duplicate.name == "Copy of Original")
        #expect(duplicate.id != original.id)
        #expect(duplicate.columnCount == 2)
        #expect(duplicate.columnGap == 25.0)
        #expect(duplicate.titleFontSize == 30.0)
        #expect(!duplicate.isBuiltIn)
        #expect(!duplicate.isDefault)

        // Verify both exist
        let descriptor = FetchDescriptor<Template>()
        let templates = try context.fetch(descriptor)
        #expect(templates.count == 2)
    }

    // MARK: - Query Tests

    @Test("Fetch all templates")
    @MainActor
    func testFetchAllTemplates() throws {
        let template1 = try TemplateManager.createTemplate(name: "Template 1", context: context)
        let template2 = try TemplateManager.createTemplate(name: "Template 2", context: context)
        let template3 = Template.builtInSingleColumn()
        context.insert(template3)
        try context.save()

        let templates = try TemplateManager.fetchAllTemplates(from: context)

        #expect(templates.count == 3)
        // Should be sorted by name
        #expect(templates[0].name == "Single Column")
        #expect(templates[1].name == "Template 1")
        #expect(templates[2].name == "Template 2")
    }

    @Test("Fetch built-in templates only")
    @MainActor
    func testFetchBuiltInTemplates() throws {
        let userTemplate = try TemplateManager.createTemplate(name: "User Template", context: context)
        let builtIn1 = Template.builtInSingleColumn()
        let builtIn2 = Template.builtInTwoColumn()
        context.insert(builtIn1)
        context.insert(builtIn2)
        try context.save()

        let builtInTemplates = try TemplateManager.fetchBuiltInTemplates(from: context)

        #expect(builtInTemplates.count == 2)
        #expect(builtInTemplates.allSatisfy { $0.isBuiltIn })
    }

    @Test("Fetch user templates only")
    @MainActor
    func testFetchUserTemplates() throws {
        let user1 = try TemplateManager.createTemplate(name: "User 1", context: context)
        let user2 = try TemplateManager.createTemplate(name: "User 2", context: context)
        let builtIn = Template.builtInSingleColumn()
        context.insert(builtIn)
        try context.save()

        let userTemplates = try TemplateManager.fetchUserTemplates(from: context)

        #expect(userTemplates.count == 2)
        #expect(userTemplates.allSatisfy { !$0.isBuiltIn })
    }

    // MARK: - Default Template Tests

    @Test("Fetch default template")
    @MainActor
    func testFetchDefaultTemplate() throws {
        let template1 = try TemplateManager.createTemplate(name: "Template 1", context: context)
        let template2 = try TemplateManager.createTemplate(name: "Template 2", context: context)
        template2.isDefault = true
        try context.save()

        let defaultTemplate = try TemplateManager.fetchDefaultTemplate(from: context)

        #expect(defaultTemplate != nil)
        #expect(defaultTemplate?.name == "Template 2")
    }

    @Test("Fetch default template returns nil when none set")
    @MainActor
    func testFetchDefaultTemplateNoneSet() throws {
        let template = try TemplateManager.createTemplate(name: "Template", context: context)

        let defaultTemplate = try TemplateManager.fetchDefaultTemplate(from: context)

        #expect(defaultTemplate == nil)
    }

    @Test("Set default template")
    @MainActor
    func testSetDefaultTemplate() throws {
        let template1 = try TemplateManager.createTemplate(name: "Template 1", context: context)
        let template2 = try TemplateManager.createTemplate(name: "Template 2", context: context)

        try TemplateManager.setDefaultTemplate(template2, context: context)

        #expect(template2.isDefault == true)
        #expect(template1.isDefault == false)

        let defaultTemplate = try TemplateManager.fetchDefaultTemplate(from: context)
        #expect(defaultTemplate?.id == template2.id)
    }

    @Test("Set default template clears previous default")
    @MainActor
    func testSetDefaultTemplateClearsPrevious() throws {
        let template1 = try TemplateManager.createTemplate(name: "Template 1", context: context)
        let template2 = try TemplateManager.createTemplate(name: "Template 2", context: context)

        try TemplateManager.setDefaultTemplate(template1, context: context)
        #expect(template1.isDefault == true)

        try TemplateManager.setDefaultTemplate(template2, context: context)

        #expect(template1.isDefault == false)
        #expect(template2.isDefault == true)

        let defaultTemplate = try TemplateManager.fetchDefaultTemplate(from: context)
        #expect(defaultTemplate?.id == template2.id)
    }

    @Test("Clear default template")
    @MainActor
    func testClearDefaultTemplate() throws {
        let template = try TemplateManager.createTemplate(name: "Template", context: context)
        try TemplateManager.setDefaultTemplate(template, context: context)
        #expect(template.isDefault == true)

        try TemplateManager.clearDefaultTemplate(context: context)

        #expect(template.isDefault == false)

        let defaultTemplate = try TemplateManager.fetchDefaultTemplate(from: context)
        #expect(defaultTemplate == nil)
    }

    @Test("Clear default template when none set does not error")
    @MainActor
    func testClearDefaultTemplateNoneSet() throws {
        let template = try TemplateManager.createTemplate(name: "Template", context: context)

        // Should not throw
        try TemplateManager.clearDefaultTemplate(context: context)

        let defaultTemplate = try TemplateManager.fetchDefaultTemplate(from: context)
        #expect(defaultTemplate == nil)
    }

    // MARK: - Built-in Template Initialization Tests

    @Test("Initialize built-in templates creates all three")
    @MainActor
    func testInitializeBuiltInTemplates() throws {
        try TemplateManager.initializeBuiltInTemplates(in: context)

        let builtInTemplates = try TemplateManager.fetchBuiltInTemplates(from: context)

        #expect(builtInTemplates.count == 3)

        let names = builtInTemplates.map { $0.name }
        #expect(names.contains("Single Column"))
        #expect(names.contains("Two Column"))
        #expect(names.contains("Three Column"))
    }

    @Test("Initialize built-in templates does not duplicate existing")
    @MainActor
    func testInitializeBuiltInTemplatesNoDuplicates() throws {
        // Create one built-in template manually
        let existing = Template.builtInSingleColumn()
        context.insert(existing)
        try context.save()

        try TemplateManager.initializeBuiltInTemplates(in: context)

        let builtInTemplates = try TemplateManager.fetchBuiltInTemplates(from: context)

        // Should have all 3, but no duplicates
        #expect(builtInTemplates.count == 3)

        let singleColumnCount = builtInTemplates.filter { $0.name == "Single Column" }.count
        #expect(singleColumnCount == 1)
    }

    @Test("Initialize built-in templates sets default correctly")
    @MainActor
    func testInitializeBuiltInTemplatesDefault() throws {
        try TemplateManager.initializeBuiltInTemplates(in: context)

        let defaultTemplate = try TemplateManager.fetchDefaultTemplate(from: context)

        #expect(defaultTemplate != nil)
        #expect(defaultTemplate?.name == "Single Column")
        #expect(defaultTemplate?.isDefault == true)
    }

    // MARK: - Validation Tests

    @Test("Valid template name is accepted")
    @MainActor
    func testValidTemplateName() throws {
        let isValid = try TemplateManager.isValidTemplateName("My Template", in: context)

        #expect(isValid == true)
    }

    @Test("Empty template name is invalid")
    @MainActor
    func testEmptyTemplateNameInvalid() throws {
        let isValid = try TemplateManager.isValidTemplateName("", in: context)
        #expect(isValid == false)

        let isValid2 = try TemplateManager.isValidTemplateName("   ", in: context)
        #expect(isValid2 == false)
    }

    @Test("Duplicate template name is invalid")
    @MainActor
    func testDuplicateTemplateNameInvalid() throws {
        let template = try TemplateManager.createTemplate(name: "Existing Template", context: context)

        let isValid = try TemplateManager.isValidTemplateName("Existing Template", in: context)

        #expect(isValid == false)
    }

    @Test("Duplicate template name case-insensitive")
    @MainActor
    func testDuplicateTemplateNameCaseInsensitive() throws {
        let template = try TemplateManager.createTemplate(name: "My Template", context: context)

        let isValid1 = try TemplateManager.isValidTemplateName("my template", in: context)
        #expect(isValid1 == false)

        let isValid2 = try TemplateManager.isValidTemplateName("MY TEMPLATE", in: context)
        #expect(isValid2 == false)

        let isValid3 = try TemplateManager.isValidTemplateName("My Template", in: context)
        #expect(isValid3 == false)
    }

    @Test("Rename template to same name is valid")
    @MainActor
    func testRenameToSameNameValid() throws {
        let template = try TemplateManager.createTemplate(name: "Template", context: context)

        let isValid = try TemplateManager.isValidTemplateName(
            "Template",
            excludingTemplate: template,
            in: context
        )

        #expect(isValid == true)
    }

    @Test("Rename template to different existing name is invalid")
    @MainActor
    func testRenameToExistingNameInvalid() throws {
        let template1 = try TemplateManager.createTemplate(name: "Template 1", context: context)
        let template2 = try TemplateManager.createTemplate(name: "Template 2", context: context)

        let isValid = try TemplateManager.isValidTemplateName(
            "Template 2",
            excludingTemplate: template1,
            in: context
        )

        #expect(isValid == false)
    }

    @Test("Template name exists check")
    @MainActor
    func testTemplateNameExists() throws {
        let template = try TemplateManager.createTemplate(name: "Existing", context: context)

        let exists = try TemplateManager.templateNameExists("Existing", in: context)
        #expect(exists == true)

        let notExists = try TemplateManager.templateNameExists("Not Existing", in: context)
        #expect(notExists == false)
    }

    @Test("Template name exists is case-insensitive")
    @MainActor
    func testTemplateNameExistsCaseInsensitive() throws {
        let template = try TemplateManager.createTemplate(name: "My Template", context: context)

        let exists1 = try TemplateManager.templateNameExists("my template", in: context)
        #expect(exists1 == true)

        let exists2 = try TemplateManager.templateNameExists("MY TEMPLATE", in: context)
        #expect(exists2 == true)
    }

    // MARK: - Error Tests

    @Test("TemplateError has correct descriptions")
    func testTemplateErrorDescriptions() {
        let error1 = TemplateError.cannotDeleteBuiltIn
        #expect(error1.errorDescription == "Built-in templates cannot be deleted.")

        let error2 = TemplateError.invalidTemplateName
        #expect(error2.errorDescription == "The template name is invalid or empty.")

        let error3 = TemplateError.templateNameExists
        #expect(error3.errorDescription == "A template with this name already exists.")

        let error4 = TemplateError.templateNotFound
        #expect(error4.errorDescription == "The requested template could not be found.")
    }
}
