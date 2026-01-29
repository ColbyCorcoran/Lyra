//
//  RecurrenceTests.swift
//  LyraTests
//
//  Created by Claude on 1/28/26.
//

import Testing
import SwiftData
import Foundation
@testable import Lyra

@Suite("Recurrence Tests")
@MainActor
struct RecurrenceTests {
    var container: ModelContainer
    var context: ModelContext

    init() throws {
        let schema = Schema([
            PerformanceSet.self,
            RecurrenceRule.self,
            SetEntry.self,
            Song.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    // MARK: - RecurrenceRule Tests

    @Test("RecurrenceRule creation with daily frequency")
    func testDailyRecurrenceRuleCreation() throws {
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            endType: .never
        )

        #expect(rule.frequency == .daily)
        #expect(rule.interval == 1)
        #expect(rule.endType == .never)
        #expect(rule.instanceCount == 0)
    }

    @Test("RecurrenceRule human-readable description for daily")
    func testDailyDescription() throws {
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            endType: .never
        )

        #expect(rule.humanReadableDescription.contains("daily"))
    }

    @Test("RecurrenceRule human-readable description for weekly")
    func testWeeklyDescription() throws {
        let rule = RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [1, 3, 5], // Sunday, Tuesday, Thursday
            endType: .never
        )

        let description = rule.humanReadableDescription
        #expect(description.contains("weekly"))
        #expect(description.contains("Sun"))
    }

    @Test("RecurrenceRule human-readable description with end date")
    func testDescriptionWithEndDate() throws {
        let endDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            endType: .afterDate,
            endDate: endDate
        )

        #expect(rule.humanReadableDescription.contains("until"))
    }

    // MARK: - PerformanceSet Recurring Properties Tests

    @Test("PerformanceSet isRecurringTemplate when rule attached")
    func testIsRecurringTemplate() throws {
        let set = PerformanceSet(name: "Test Set", scheduledDate: Date())
        let rule = RecurrenceRule(frequency: .daily, interval: 1)

        set.recurrenceRule = rule
        context.insert(set)
        context.insert(rule)

        #expect(set.isRecurringTemplate == true)
        #expect(set.isRecurringInstance == false)
    }

    @Test("PerformanceSet isRecurringInstance when properties set")
    func testIsRecurringInstance() throws {
        let template = PerformanceSet(name: "Template", scheduledDate: Date())
        context.insert(template)

        let instance = PerformanceSet(name: "Instance", scheduledDate: Date())
        instance.isRecurringInstance = true
        instance.recurringTemplateId = template.id
        instance.instanceDate = Date()
        context.insert(instance)

        #expect(instance.isRecurringInstance == true)
        #expect(instance.isRecurringTemplate == false)
    }

    @Test("PerformanceSet displayDate for month/year only")
    func testDisplayDateMonthYearOnly() throws {
        let set = PerformanceSet(name: "Test Set")
        set.isMonthYearOnly = true
        set.scheduledMonth = 1 // January
        set.scheduledYear = 2027

        let displayDate = set.displayDate
        #expect(displayDate.contains("January"))
        #expect(displayDate.contains("2027"))
        #expect(displayDate.contains("TBD"))
    }

    // MARK: - RecurrenceManager Tests

    @Test("RecurrenceManager generates daily instances")
    func testGenerateDailyInstances() throws {
        let startDate = Date()
        let template = PerformanceSet(name: "Daily Set", scheduledDate: startDate)

        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            endType: .afterOccurrences,
            endAfterOccurrences: 5
        )

        template.recurrenceRule = rule
        context.insert(template)
        context.insert(rule)

        try RecurrenceManager.generateInstancesIfNeeded(
            for: template,
            context: context,
            monthsAhead: 1
        )

        // Should generate 5 instances (as specified by endAfterOccurrences)
        let templateId = template.id
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.recurringTemplateId == templateId
            }
        )

        let instances = try context.fetch(descriptor)
        #expect(instances.count == 5)
    }

    @Test("RecurrenceManager calculates next daily occurrence")
    func testNextDailyOccurrence() throws {
        let startDate = Date()
        let rule = RecurrenceRule(frequency: .daily, interval: 2)

        let nextDate = RecurrenceManager.nextOccurrence(
            after: startDate,
            rule: rule,
            startDate: startDate
        )

        #expect(nextDate != nil)

        if let nextDate = nextDate {
            let calendar = Calendar.current
            let daysDiff = calendar.dateComponents([.day], from: startDate, to: nextDate).day
            #expect(daysDiff == 2)
        }
    }

    @Test("RecurrenceManager stops at end date")
    func testStopsAtEndDate() throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 5) // 5 days

        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            endType: .afterDate,
            endDate: endDate
        )

        // Should stop before the date past end date
        let checkDate = startDate.addingTimeInterval(86400 * 6)
        let shouldStop = RecurrenceManager.shouldStopGenerating(rule: rule, date: checkDate)

        #expect(shouldStop == true)
    }

    @Test("RecurrenceManager checks instance existence")
    func testInstanceExists() throws {
        let template = PerformanceSet(name: "Template", scheduledDate: Date())
        context.insert(template)

        let instanceDate = Date().addingTimeInterval(86400) // Tomorrow
        let instance = PerformanceSet(name: "Instance", scheduledDate: instanceDate)
        instance.recurringTemplateId = template.id
        instance.instanceDate = instanceDate
        context.insert(instance)

        try context.save()

        let exists = RecurrenceManager.instanceExists(
            for: instanceDate,
            templateId: template.id,
            context: context
        )

        #expect(exists == true)
    }

    @Test("RecurrenceManager creates instance with all properties")
    func testCreateInstanceCopiesProperties() throws {
        let template = PerformanceSet(name: "Original", scheduledDate: Date())
        template.venue = "Test Venue"
        template.setDescription = "Test Description"
        template.folder = "Test Folder"
        template.notes = "Test Notes"

        context.insert(template)

        let instanceDate = Date().addingTimeInterval(86400)
        try RecurrenceManager.createInstance(
            from: template,
            for: instanceDate,
            context: context
        )

        let templateId = template.id
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.recurringTemplateId == templateId
            }
        )

        let instances = try context.fetch(descriptor)
        #expect(instances.count == 1)

        let instance = instances[0]
        #expect(instance.name == "Original")
        #expect(instance.venue == "Test Venue")
        #expect(instance.setDescription == "Test Description")
        #expect(instance.folder == "Test Folder")
        #expect(instance.notes == "Test Notes")
        #expect(instance.isRecurringInstance == true)
    }

    @Test("RecurrenceManager updates single instance breaks link")
    func testUpdateSingleInstanceBreaksLink() throws {
        let template = PerformanceSet(name: "Template", scheduledDate: Date())
        context.insert(template)

        let instance = PerformanceSet(name: "Instance", scheduledDate: Date())
        instance.recurringTemplateId = template.id
        instance.isRecurringInstance = true
        context.insert(instance)

        try context.save()

        try RecurrenceManager.updateSingleInstance(
            instance,
            updateBlock: { set in
                set.name = "Updated Instance"
            },
            context: context
        )

        #expect(instance.name == "Updated Instance")
        #expect(instance.isRecurringInstance == false)
        #expect(instance.recurringTemplateId == nil)
    }

    @Test("RecurrenceManager deletes with thisOnly option")
    func testDeleteThisOnly() throws {
        let template = PerformanceSet(name: "Template", scheduledDate: Date())
        context.insert(template)

        let instance1 = PerformanceSet(name: "Instance 1", scheduledDate: Date())
        instance1.recurringTemplateId = template.id
        instance1.isRecurringInstance = true
        context.insert(instance1)

        let instance2 = PerformanceSet(name: "Instance 2", scheduledDate: Date().addingTimeInterval(86400))
        instance2.recurringTemplateId = template.id
        instance2.isRecurringInstance = true
        context.insert(instance2)

        try context.save()

        try RecurrenceManager.deleteRecurringSet(
            instance1,
            option: .thisOnly,
            context: context
        )

        let templateId = template.id
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.recurringTemplateId == templateId
            }
        )

        let remainingInstances = try context.fetch(descriptor)
        #expect(remainingInstances.count == 1)
        #expect(remainingInstances[0].name == "Instance 2")
    }

    @Test("RecurrenceManager stops recurrence")
    func testStopRecurrence() throws {
        let template = PerformanceSet(name: "Template", scheduledDate: Date())
        let rule = RecurrenceRule(frequency: .daily, interval: 1)
        template.recurrenceRule = rule

        context.insert(template)
        context.insert(rule)

        try context.save()

        try RecurrenceManager.stopRecurrence(for: template, context: context)

        #expect(template.recurrenceStopped == true)
    }

    @Test("RecurrenceManager venue history autocomplete")
    func testVenueHistory() throws {
        let set1 = PerformanceSet(name: "Set 1", scheduledDate: Date())
        set1.venue = "Turner's Rock"
        context.insert(set1)

        let set2 = PerformanceSet(name: "Set 2", scheduledDate: Date())
        set2.venue = "Turner's Rock"
        context.insert(set2)

        let set3 = PerformanceSet(name: "Set 3", scheduledDate: Date())
        set3.venue = "Blue Note Jazz Club"
        context.insert(set3)

        try context.save()

        let suggestions = RecurrenceManager.getVenueHistory(matching: "Turn", context: context)

        #expect(suggestions.contains("Turner's Rock"))
        #expect(!suggestions.contains("Blue Note Jazz Club"))
    }

    @Test("DayOfWeek enum has correct display names")
    func testDayOfWeekDisplayNames() throws {
        #expect(DayOfWeek.sunday.displayName == "Sunday")
        #expect(DayOfWeek.monday.shortName == "Mon")
        #expect(DayOfWeek.saturday.rawValue == 7)
    }
}
