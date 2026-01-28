//
//  RecurrenceManager.swift
//  Lyra
//
//  Created by Claude on 1/28/26.
//

import SwiftData
import Foundation

enum RecurrenceDeleteOption {
    case thisOnly
    case allFuture
    case stopRecurrence
}

enum RecurrenceEditOption {
    case thisInstanceOnly
    case templateAndFuture
}

struct RecurrenceManager {

    // MARK: - Instance Generation

    /// Generate recurring instances up to N months ahead
    static func generateInstancesIfNeeded(
        for templateSet: PerformanceSet,
        context: ModelContext,
        monthsAhead: Int
    ) throws {
        guard let rule = templateSet.recurrenceRule,
              !templateSet.recurrenceStopped,
              let startDate = templateSet.scheduledDate else {
            return
        }

        let calendar = Calendar.current
        let today = Date()
        let endGenerationDate = calendar.date(byAdding: .month, value: monthsAhead, to: today) ?? today

        // Start from last generated date or the template's scheduled date
        var currentDate = rule.lastGeneratedDate ?? startDate

        // Generate instances until we reach the end generation date
        while currentDate <= endGenerationDate {
            // Check if we should stop generating based on rule's end conditions
            if shouldStopGenerating(rule: rule, date: currentDate) {
                break
            }

            // Calculate next occurrence
            guard let nextDate = nextOccurrence(after: currentDate, rule: rule, startDate: startDate) else {
                break
            }

            // Stop if next date is beyond our generation window
            if nextDate > endGenerationDate {
                break
            }

            // Check if instance already exists for this date
            if !instanceExists(for: nextDate, templateId: templateSet.id, context: context) {
                // Create instance
                try createInstance(from: templateSet, for: nextDate, context: context)

                // Update tracking
                rule.instanceCount += 1
                rule.lastGeneratedDate = nextDate
            }

            currentDate = nextDate
        }

        try context.save()
    }

    /// Calculate the next occurrence date based on recurrence rule
    static func nextOccurrence(
        after date: Date,
        rule: RecurrenceRule,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current

        switch rule.frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: rule.interval, to: date)

        case .weekly:
            // If specific days are set, find next matching day
            if let daysOfWeek = rule.daysOfWeek, !daysOfWeek.isEmpty {
                return nextWeeklyOccurrence(after: date, daysOfWeek: daysOfWeek, interval: rule.interval, calendar: calendar)
            } else {
                // Default to same day of week
                return calendar.date(byAdding: .weekOfYear, value: rule.interval, to: date)
            }

        case .monthly:
            if let dayOfMonth = rule.dayOfMonth {
                return nextMonthlyOccurrence(after: date, dayOfMonth: dayOfMonth, interval: rule.interval, calendar: calendar)
            } else {
                // Month/year only mode - just advance months
                return calendar.date(byAdding: .month, value: rule.interval, to: date)
            }

        case .yearly:
            if let monthOfYear = rule.monthOfYear {
                return nextYearlyOccurrence(
                    after: date,
                    monthOfYear: monthOfYear,
                    dayOfMonth: rule.dayOfMonth,
                    interval: rule.interval,
                    calendar: calendar
                )
            } else {
                return calendar.date(byAdding: .year, value: rule.interval, to: date)
            }
        }
    }

    /// Check if we should stop generating instances
    static func shouldStopGenerating(rule: RecurrenceRule, date: Date) -> Bool {
        switch rule.endType {
        case .never:
            return false

        case .afterDate:
            guard let endDate = rule.endDate else { return false }
            return date > endDate

        case .afterOccurrences:
            guard let maxOccurrences = rule.endAfterOccurrences else { return false }
            return rule.instanceCount >= maxOccurrences
        }
    }

    /// Check if an instance already exists for a specific date
    static func instanceExists(for date: Date, templateId: UUID, context: ModelContext) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.recurringTemplateId == templateId &&
                set.instanceDate != nil &&
                set.instanceDate! >= startOfDay &&
                set.instanceDate! < endOfDay
            }
        )

        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    /// Create a recurring instance from a template set
    static func createInstance(
        from template: PerformanceSet,
        for date: Date,
        context: ModelContext
    ) throws {
        let instance = PerformanceSet(name: template.name, scheduledDate: date)

        // Copy basic properties
        instance.setDescription = template.setDescription
        instance.venue = template.venue
        instance.folder = template.folder
        instance.notes = template.notes

        // Set recurring instance properties
        instance.isRecurringInstance = true
        instance.recurringTemplateId = template.id
        instance.instanceDate = date

        // Handle month/year only mode
        if template.isMonthYearOnly {
            let calendar = Calendar.current
            instance.isMonthYearOnly = true
            instance.scheduledMonth = calendar.component(.month, from: date)
            instance.scheduledYear = calendar.component(.year, from: date)
            instance.scheduledDate = nil // Clear specific date
        }

        // Insert instance
        context.insert(instance)

        // Deep copy all song entries
        if let entries = template.sortedSongEntries {
            for entry in entries {
                guard let song = entry.song else { continue }

                let newEntry = SetEntry(song: song, orderIndex: entry.orderIndex)
                newEntry.performanceSet = instance

                // Copy entry-specific properties
                newEntry.keyOverride = entry.keyOverride
                newEntry.capoOverride = entry.capoOverride
                newEntry.tempoOverride = entry.tempoOverride
                newEntry.autoscrollDurationOverride = entry.autoscrollDurationOverride
                newEntry.notes = entry.notes

                context.insert(newEntry)
            }
        }
    }

    // MARK: - Update Operations

    /// Update a single recurring instance
    static func updateSingleInstance(
        _ instance: PerformanceSet,
        updateBlock: (PerformanceSet) -> Void,
        context: ModelContext
    ) throws {
        // Break the link to the template so it becomes independent
        instance.isRecurringInstance = false
        instance.recurringTemplateId = nil
        instance.instanceDate = nil

        // Apply the update
        updateBlock(instance)

        try context.save()
    }

    /// Update the template and all future instances
    static func updateTemplateAndFutureInstances(
        _ instance: PerformanceSet,
        updateBlock: (PerformanceSet) -> Void,
        context: ModelContext
    ) throws {
        guard let templateId = instance.recurringTemplateId else { return }

        // Find the template
        let templateDescriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.id == templateId
            }
        )

        guard let template = try context.fetch(templateDescriptor).first else { return }

        // Update template
        updateBlock(template)

        // Find all future instances (including this one)
        let instanceDate = instance.instanceDate ?? instance.scheduledDate ?? Date()

        let futureDescriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.recurringTemplateId == templateId &&
                set.instanceDate != nil &&
                set.instanceDate! >= instanceDate
            }
        )

        let futureInstances = try context.fetch(futureDescriptor)

        // Update all future instances
        for futureInstance in futureInstances {
            updateBlock(futureInstance)
        }

        try context.save()
    }

    // MARK: - Delete Operations

    /// Delete recurring set with options
    static func deleteRecurringSet(
        _ instance: PerformanceSet,
        option: RecurrenceDeleteOption,
        context: ModelContext
    ) throws {
        guard let templateId = instance.recurringTemplateId else {
            // Not a recurring instance, just delete normally
            context.delete(instance)
            try context.save()
            return
        }

        switch option {
        case .thisOnly:
            // Delete only this instance
            context.delete(instance)

        case .allFuture:
            // Delete this instance and all future instances
            let instanceDate = instance.instanceDate ?? instance.scheduledDate ?? Date()

            let futureDescriptor = FetchDescriptor<PerformanceSet>(
                predicate: #Predicate { set in
                    set.recurringTemplateId == templateId &&
                    set.instanceDate != nil &&
                    set.instanceDate! >= instanceDate
                }
            )

            let futureInstances = try context.fetch(futureDescriptor)

            for futureInstance in futureInstances {
                context.delete(futureInstance)
            }

        case .stopRecurrence:
            // Find and update the template to stop generating new instances
            let templateDescriptor = FetchDescriptor<PerformanceSet>(
                predicate: #Predicate { set in
                    set.id == templateId
                }
            )

            if let template = try context.fetch(templateDescriptor).first {
                template.recurrenceStopped = true
            }
        }

        try context.save()
    }

    /// Stop recurrence for a template set
    static func stopRecurrence(for template: PerformanceSet, context: ModelContext) throws {
        template.recurrenceStopped = true
        try context.save()
    }

    // MARK: - Venue Autocomplete

    /// Get venue history for autocomplete
    static func getVenueHistory(matching searchText: String, context: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.venue != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let allSets = try? context.fetch(descriptor) else { return [] }

        // Get unique venues
        let venues = Set(allSets.compactMap { $0.venue })

        // Filter by search text
        let filtered = searchText.isEmpty
            ? Array(venues)
            : venues.filter { $0.localizedCaseInsensitiveContains(searchText) }

        // Return top 5 matches, sorted alphabetically
        return Array(filtered.sorted().prefix(5))
    }

    // MARK: - Helper Methods for Specific Frequencies

    private static func nextWeeklyOccurrence(
        after date: Date,
        daysOfWeek: [Int],
        interval: Int,
        calendar: Calendar
    ) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: date)

        // Find next matching day in current week
        let sortedDays = daysOfWeek.sorted()

        for day in sortedDays where day > currentWeekday {
            if let nextDate = calendar.date(bySetting: .weekday, value: day, of: date) {
                return nextDate
            }
        }

        // No matching day in current week, move to next interval week
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: interval, to: date) else {
            return nil
        }

        // Get first day of week in the next interval
        if let firstDay = sortedDays.first,
           let nextDate = calendar.date(bySetting: .weekday, value: firstDay, of: nextWeek) {
            return nextDate
        }

        return nil
    }

    private static func nextMonthlyOccurrence(
        after date: Date,
        dayOfMonth: Int,
        interval: Int,
        calendar: Calendar
    ) -> Date? {
        guard let nextMonth = calendar.date(byAdding: .month, value: interval, to: date) else {
            return nil
        }

        // Handle invalid dates (e.g., day 31 in a 30-day month)
        var components = calendar.dateComponents([.year, .month], from: nextMonth)
        components.day = dayOfMonth

        return calendar.date(from: components)
    }

    private static func nextYearlyOccurrence(
        after date: Date,
        monthOfYear: Int,
        dayOfMonth: Int?,
        interval: Int,
        calendar: Calendar
    ) -> Date? {
        guard let nextYear = calendar.date(byAdding: .year, value: interval, to: date) else {
            return nil
        }

        var components = calendar.dateComponents([.year], from: nextYear)
        components.month = monthOfYear

        if let day = dayOfMonth {
            components.day = day
        } else {
            components.day = 1 // Default to first day if not specified
        }

        return calendar.date(from: components)
    }
}
