//
//  SchemaValidationTests.swift
//  LyraTests
//
//  Tests for SwiftData schema validation and migration safety
//

import Testing
import SwiftData
import Foundation
@testable import Lyra

@MainActor
@Suite("Schema Validation Tests")
struct SchemaValidationTests {

    // MARK: - Schema Completeness Tests

    @Test("Production schema contains all expected models")
    func testProductionSchemaContainsAllModels() async throws {
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let missingModels = SchemaVersioning.validateSchema(schema)
        #expect(missingModels.isEmpty, "Schema is missing models: \(missingModels.joined(separator: ", "))")
    }

    @Test("Production schema has correct entity count")
    func testProductionSchemaEntityCount() async throws {
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        #expect(SchemaVersioning.validateEntityCount(schema), "Schema entity count should match expected count")
        #expect(schema.entities.count == SchemaVersioning.expectedModelCount)
    }

    @Test("Preview schema matches production schema")
    func testPreviewSchemaMatchesProduction() async throws {
        let previewSchema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let missingModels = SchemaVersioning.validateSchema(previewSchema)
        #expect(missingModels.isEmpty, "Preview schema is missing models: \(missingModels.joined(separator: ", "))")
    }

    @Test("Incomplete schema is detected - missing Song")
    func testIncompleteSchemaDetectedMissingSong() async throws {
        let incompleteSchema = Schema([
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let missingModels = SchemaVersioning.validateSchema(incompleteSchema)
        #expect(!missingModels.isEmpty, "Should detect missing Song model")
        #expect(missingModels.contains("Song"), "Missing models should include 'Song'")
    }

    @Test("Incomplete schema is detected - missing Template")
    func testIncompleteSchemaDetectedMissingTemplate() async throws {
        let incompleteSchema = Schema([
            Song.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let missingModels = SchemaVersioning.validateSchema(incompleteSchema)
        #expect(!missingModels.isEmpty, "Should detect missing Template model")
        #expect(missingModels.contains("Template"), "Missing models should include 'Template'")
    }

    @Test("Incomplete schema is detected - missing RecurrenceRule")
    func testIncompleteSchemaDetectedMissingRecurrenceRule() async throws {
        let incompleteSchema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self
        ])

        let missingModels = SchemaVersioning.validateSchema(incompleteSchema)
        #expect(!missingModels.isEmpty, "Should detect missing RecurrenceRule model")
        #expect(missingModels.contains("RecurrenceRule"), "Missing models should include 'RecurrenceRule'")
    }

    @Test("Entity count validation detects extra models")
    func testEntityCountValidationDetectsExtra() async throws {
        // This test verifies that if someone adds a model to the schema
        // without updating the expected count, it will be detected
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let actualCount = schema.entities.count
        #expect(actualCount == SchemaVersioning.expectedModelCount,
                "Actual entity count (\(actualCount)) should match expected (\(SchemaVersioning.expectedModelCount))")
    }

    // MARK: - Model Container Tests

    @Test("ModelContainer can be created with valid schema")
    func testModelContainerCreation() async throws {
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)

        // This should not throw
        let container = try ModelContainer(for: schema, configurations: [config])
        #expect(container.schema.entities.count == SchemaVersioning.expectedModelCount)
    }

    @Test("In-memory container can be created for testing")
    func testInMemoryContainerCreation() async throws {
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        #expect(container.schema == schema)
    }

    // MARK: - Model Relationship Tests

    @Test("Song relationships are properly configured")
    func testSongRelationships() async throws {
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Create a song with relationships
        let song = Song(title: "Test Song", content: "Test content", contentFormat: .plainText)
        context.insert(song)

        // Create related entities
        let template = Template.builtInSingleColumn()
        song.template = template
        context.insert(template)

        let book = Book(name: "Test Book")
        book.songs = [song]
        context.insert(book)

        try context.save()

        // Verify relationships
        #expect(song.template != nil, "Song should have template relationship")
        #expect(book.songs?.contains(where: { $0.id == song.id }) == true, "Book should contain song")
    }

    @Test("PerformanceSet and RecurrenceRule relationship works")
    func testPerformanceSetRecurrenceRelationship() async throws {
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Create performance set with recurrence rule
        let performanceSet = PerformanceSet(name: "Weekly Service")
        let recurrenceRule = RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [DayOfWeek.sunday.rawValue]
        )

        performanceSet.recurrenceRule = recurrenceRule
        recurrenceRule.templateSet = performanceSet

        context.insert(performanceSet)
        context.insert(recurrenceRule)

        try context.save()

        // Verify relationship
        #expect(performanceSet.recurrenceRule != nil, "PerformanceSet should have recurrence rule")
        #expect(recurrenceRule.templateSet?.id == performanceSet.id, "RecurrenceRule should reference performance set")
    }

    // MARK: - Schema Error Detection Tests

    @Test("SchemaValidationError provides meaningful descriptions")
    func testSchemaValidationErrorDescriptions() async throws {
        let noSchemasError = SchemaValidationError.noSchemasDefinied
        #expect(noSchemasError.errorDescription != nil)
        #expect(noSchemasError.errorDescription?.contains("No schema versions") == true)

        let missingBaseError = SchemaValidationError.missingBaseSchema
        #expect(missingBaseError.errorDescription != nil)
        #expect(missingBaseError.errorDescription?.contains("Base schema") == true)

        let missingModelsError = SchemaValidationError.missingModels(["Song", "Book"])
        #expect(missingModelsError.errorDescription != nil)
        #expect(missingModelsError.errorDescription?.contains("Song") == true)
        #expect(missingModelsError.errorDescription?.contains("Book") == true)

        let wrongCountError = SchemaValidationError.wrongEntityCount(expected: 8, actual: 6)
        #expect(wrongCountError.errorDescription != nil)
        #expect(wrongCountError.errorDescription?.contains("8") == true)
        #expect(wrongCountError.errorDescription?.contains("6") == true)
    }

    // MARK: - Expected Model Names Test

    @Test("All expected model names are defined")
    func testExpectedModelNamesList() async throws {
        let expectedNames = SchemaVersioning.expectedModelNames

        #expect(expectedNames.count == 8, "Should have 8 expected model names")
        #expect(expectedNames.contains("Song"))
        #expect(expectedNames.contains("Template"))
        #expect(expectedNames.contains("Book"))
        #expect(expectedNames.contains("PerformanceSet"))
        #expect(expectedNames.contains("SetEntry"))
        #expect(expectedNames.contains("Annotation"))
        #expect(expectedNames.contains("UserSettings"))
        #expect(expectedNames.contains("RecurrenceRule"))
    }
}
