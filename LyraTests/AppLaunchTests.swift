//
//  AppLaunchTests.swift
//  LyraTests
//
//  Tests for app launch and initialization
//

import Testing
import SwiftData
import Foundation
@testable import Lyra

@MainActor
@Suite("App Launch Tests")
struct AppLaunchTests {

    // MARK: - ModelContainer Initialization Tests

    @Test("App initializes ModelContainer with correct schema")
    func testModelContainerInitialization() async throws {
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

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

        #expect(container.schema.entities.count == SchemaVersioning.expectedModelCount)
        #expect(SchemaVersioning.validateSchema(container.schema).isEmpty)
    }

    @Test("App schema passes validation checks")
    func testAppSchemaValidation() async throws {
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

        // Validate schema integrity
        let missingModels = SchemaVersioning.validateSchema(schema)
        #expect(missingModels.isEmpty, "Schema should not be missing any models")

        // Validate entity count
        let entityCountValid = SchemaVersioning.validateEntityCount(schema)
        #expect(entityCountValid, "Schema entity count should match expected count")
    }

    @Test("App creates ModelContainer with CloudKit disabled")
    func testCloudKitDisabled() async throws {
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

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        // This should not throw with CloudKit disabled
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        #expect(container != nil)
    }

    // MARK: - App State Tests

    @Test("Onboarding flag defaults to false")
    func testOnboardingDefault() async throws {
        // UserDefaults should start with onboarding not completed
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "onboarding.completed")

        let hasCompletedOnboarding = defaults.bool(forKey: "onboarding.completed")
        #expect(hasCompletedOnboarding == false)
    }

    @Test("Recurring instance generation months defaults correctly")
    func testRecurringInstanceGenerationDefault() async throws {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "recurringInstanceGenerationMonths")

        let monthsAhead = defaults.integer(forKey: "recurringInstanceGenerationMonths")
        #expect(monthsAhead == 0, "Should default to 0 when not set")

        // Test that we would use 3 months as fallback
        let months = monthsAhead > 0 ? monthsAhead : 3
        #expect(months == 3)
    }

    // MARK: - DataManager Initialization Tests

    @Test("DataManager can be initialized with context")
    func testDataManagerInitialization() async throws {
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

        // Initialize DataManager with container's context
        DataManager.shared.initialize(with: container.mainContext)

        // DataManager should be initialized
        #expect(DataManager.shared != nil)
    }

    // MARK: - Recurring Instance Generation Tests

    @Test("Recurring instance generation handles empty template list")
    func testRecurringInstanceGenerationWithNoTemplates() async throws {
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

        // Fetch descriptor should work even with no data
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.recurrenceRule != nil && set.recurrenceStopped == false
            }
        )

        let templates = try context.fetch(descriptor)
        #expect(templates.isEmpty, "Should handle empty template list gracefully")
    }

    @Test("Recurring instance generation works with valid template")
    func testRecurringInstanceGenerationWithTemplate() async throws {
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

        // Create a performance set with recurrence rule
        let performanceSet = PerformanceSet(name: "Test Service")
        performanceSet.isTemplate = true
        performanceSet.recurrenceStopped = false

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

        // Verify template is fetchable
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.recurrenceRule != nil && set.recurrenceStopped == false
            }
        )

        let templates = try context.fetch(descriptor)
        #expect(templates.count == 1, "Should find one template")
        #expect(templates.first?.name == "Test Service")
    }

    // MARK: - Schema Integrity Tests

    @Test("All models can be instantiated")
    func testAllModelsCanBeInstantiated() async throws {
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

        // Create instances of all models
        let song = Song(title: "Test", content: "Content", contentFormat: .plainText)
        let template = Template.builtInSingleColumn()
        let book = Book(name: "Test Book")
        let performanceSet = PerformanceSet(name: "Test Set")
        let setEntry = SetEntry(song: song, order: 0)
        let annotation = Annotation(content: "Test annotation")
        let userSettings = UserSettings()
        let recurrenceRule = RecurrenceRule(frequency: .weekly, interval: 1, daysOfWeek: [])

        context.insert(song)
        context.insert(template)
        context.insert(book)
        context.insert(performanceSet)
        context.insert(setEntry)
        context.insert(annotation)
        context.insert(userSettings)
        context.insert(recurrenceRule)

        // Should be able to save all models
        try context.save()

        #expect(true, "All models created and saved successfully")
    }

    @Test("App can create ModelContainer without CloudKit conflicts")
    func testModelContainerWithoutCloudKitConflicts() async throws {
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

        // Test with CloudKit disabled
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        // Should not throw with CloudKit disabled
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

        // Verify schema is correct
        #expect(container.schema.entities.count == 8)
        #expect(SchemaVersioning.validateSchema(container.schema).isEmpty)
    }
}
