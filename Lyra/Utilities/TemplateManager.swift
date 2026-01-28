//
//  TemplateManager.swift
//  Lyra
//
//  Utility for managing Templates
//

import Foundation
import SwiftData

@MainActor
class TemplateManager {

    // MARK: - Template Operations

    /// Create a new template
    /// - Parameters:
    ///   - name: Template name
    ///   - context: SwiftData ModelContext
    /// - Returns: The created template
    static func createTemplate(
        name: String,
        context: ModelContext
    ) throws -> Template {
        let template = Template(name: name)
        context.insert(template)
        try context.save()
        return template
    }

    /// Update a template
    /// - Parameters:
    ///   - template: The template to update
    ///   - context: SwiftData ModelContext
    static func updateTemplate(_ template: Template, context: ModelContext) throws {
        template.modifiedAt = Date()
        try context.save()
    }

    /// Delete a template
    /// - Parameters:
    ///   - template: The template to delete
    ///   - context: SwiftData ModelContext
    static func deleteTemplate(_ template: Template, context: ModelContext) throws {
        guard !template.isBuiltIn else {
            throw TemplateError.cannotDeleteBuiltIn
        }

        context.delete(template)
        try context.save()
    }

    /// Duplicate a template
    /// - Parameters:
    ///   - template: The template to duplicate
    ///   - newName: Name for the duplicated template
    ///   - context: SwiftData ModelContext
    /// - Returns: The duplicated template
    static func duplicateTemplate(
        _ template: Template,
        newName: String,
        context: ModelContext
    ) throws -> Template {
        let duplicate = template.duplicate(newName: newName)
        context.insert(duplicate)
        try context.save()
        return duplicate
    }

    // MARK: - Query Operations

    /// Fetch all templates
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Array of all templates sorted by name
    static func fetchAllTemplates(from context: ModelContext) throws -> [Template] {
        let descriptor = FetchDescriptor<Template>(
            sortBy: [SortDescriptor(\Template.name)]
        )
        return try context.fetch(descriptor)
    }

    /// Fetch built-in templates
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Array of built-in templates
    static func fetchBuiltInTemplates(from context: ModelContext) throws -> [Template] {
        var descriptor = FetchDescriptor<Template>(
            sortBy: [SortDescriptor(\Template.name)]
        )
        descriptor.predicate = #Predicate<Template> { template in
            template.isBuiltIn == true
        }
        return try context.fetch(descriptor)
    }

    /// Fetch user-created templates
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Array of user-created templates
    static func fetchUserTemplates(from context: ModelContext) throws -> [Template] {
        var descriptor = FetchDescriptor<Template>(
            sortBy: [SortDescriptor(\Template.name)]
        )
        descriptor.predicate = #Predicate<Template> { template in
            template.isBuiltIn == false
        }
        return try context.fetch(descriptor)
    }

    /// Fetch the default template
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: The default template, or nil if none is set
    static func fetchDefaultTemplate(from context: ModelContext) throws -> Template? {
        var descriptor = FetchDescriptor<Template>()
        descriptor.predicate = #Predicate<Template> { template in
            template.isDefault == true
        }
        let templates = try context.fetch(descriptor)
        return templates.first
    }

    /// Set a template as the default
    /// - Parameters:
    ///   - template: The template to set as default
    ///   - context: SwiftData ModelContext
    static func setDefaultTemplate(_ template: Template, context: ModelContext) throws {
        // Clear existing default
        if let currentDefault = try fetchDefaultTemplate(from: context) {
            currentDefault.isDefault = false
        }

        // Set new default
        template.isDefault = true
        template.modifiedAt = Date()
        try context.save()
    }

    /// Clear the default template
    /// - Parameter context: SwiftData ModelContext
    static func clearDefaultTemplate(context: ModelContext) throws {
        if let currentDefault = try fetchDefaultTemplate(from: context) {
            currentDefault.isDefault = false
            currentDefault.modifiedAt = Date()
            try context.save()
        }
    }

    // MARK: - Built-in Template Setup

    /// Initialize built-in templates if they don't exist
    /// - Parameter context: SwiftData ModelContext
    static func initializeBuiltInTemplates(in context: ModelContext) throws {
        let existingBuiltIns = try fetchBuiltInTemplates(from: context)

        // Check which built-in templates are missing
        let hasDefault = existingBuiltIns.contains { $0.name == "Single Column" }
        let hasTwoColumn = existingBuiltIns.contains { $0.name == "Two Column" }
        let hasThreeColumn = existingBuiltIns.contains { $0.name == "Three Column" }

        // Create missing built-in templates
        if !hasDefault {
            let template = Template.builtInSingleColumn()
            context.insert(template)
        }

        if !hasTwoColumn {
            let template = Template.builtInTwoColumn()
            context.insert(template)
        }

        if !hasThreeColumn {
            let template = Template.builtInThreeColumn()
            context.insert(template)
        }

        try context.save()
    }

    // MARK: - Validation

    /// Validate a template name
    /// - Parameters:
    ///   - name: The name to validate
    ///   - excludingTemplate: Optional template to exclude from uniqueness check (for renames)
    ///   - context: SwiftData ModelContext
    /// - Returns: True if the name is valid and unique
    static func isValidTemplateName(
        _ name: String,
        excludingTemplate: Template? = nil,
        in context: ModelContext
    ) throws -> Bool {
        // Check if name is empty
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return false
        }

        // Check for uniqueness
        let allTemplates = try fetchAllTemplates(from: context)

        for template in allTemplates {
            // Skip the template we're excluding (if any)
            if let excluding = excludingTemplate, template.id == excluding.id {
                continue
            }

            // Check for case-insensitive match
            if template.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame {
                return false
            }
        }

        return true
    }

    /// Check if a template name already exists
    /// - Parameters:
    ///   - name: The name to check
    ///   - context: SwiftData ModelContext
    /// - Returns: True if the name exists
    static func templateNameExists(_ name: String, in context: ModelContext) throws -> Bool {
        let allTemplates = try fetchAllTemplates(from: context)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        return allTemplates.contains { template in
            template.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }
}

// MARK: - Error Handling

enum TemplateError: LocalizedError {
    case cannotDeleteBuiltIn
    case invalidTemplateName
    case templateNameExists
    case templateNotFound

    var errorDescription: String? {
        switch self {
        case .cannotDeleteBuiltIn:
            return "Built-in templates cannot be deleted."
        case .invalidTemplateName:
            return "The template name is invalid or empty."
        case .templateNameExists:
            return "A template with this name already exists."
        case .templateNotFound:
            return "The requested template could not be found."
        }
    }
}
