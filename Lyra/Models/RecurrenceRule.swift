//
//  RecurrenceRule.swift
//  Lyra
//
//  Created by Claude on 1/28/26.
//

import SwiftData
import Foundation

// MARK: - Enums

enum RecurrenceFrequency: String, Codable {
    case daily
    case weekly
    case monthly
    case yearly
}

enum RecurrenceEndType: String, Codable {
    case never
    case afterDate
    case afterOccurrences
}

enum DayOfWeek: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

// MARK: - RecurrenceRule Model

@Model
final class RecurrenceRule {
    var id: UUID
    var createdAt: Date

    // Recurrence pattern
    var frequency: RecurrenceFrequency
    var interval: Int // Every N days/weeks/months/years

    // Weekly specific: days of week to recur on
    var daysOfWeek: [Int]? // Array of DayOfWeek raw values (1-7)

    // Monthly specific: day of month to recur on
    var dayOfMonth: Int? // 1-31, nil for month/year only mode

    // Yearly specific: month of year to recur on
    var monthOfYear: Int? // 1-12

    // End conditions
    var endType: RecurrenceEndType
    var endDate: Date?
    var endAfterOccurrences: Int?

    // Tracking
    var lastGeneratedDate: Date?
    var instanceCount: Int

    // Relationship to template set
    @Relationship(inverse: \PerformanceSet.recurrenceRule)
    var templateSet: PerformanceSet?

    init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        monthOfYear: Int? = nil,
        endType: RecurrenceEndType = .never,
        endDate: Date? = nil,
        endAfterOccurrences: Int? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.monthOfYear = monthOfYear
        self.endType = endType
        self.endDate = endDate
        self.endAfterOccurrences = endAfterOccurrences
        self.instanceCount = 0
    }

    // MARK: - Helper Methods

    /// Returns a human-readable description of the recurrence pattern
    var humanReadableDescription: String {
        var description = "Repeats "

        switch frequency {
        case .daily:
            description += interval == 1 ? "daily" : "every \(interval) days"

        case .weekly:
            description += interval == 1 ? "weekly" : "every \(interval) weeks"
            if let days = daysOfWeek, !days.isEmpty {
                let dayNames = days.compactMap { DayOfWeek(rawValue: $0)?.shortName }
                description += " on " + dayNames.joined(separator: ", ")
            }

        case .monthly:
            description += interval == 1 ? "monthly" : "every \(interval) months"
            if let day = dayOfMonth {
                description += " on day \(day)"
            } else {
                description += " (month/year only)"
            }

        case .yearly:
            description += interval == 1 ? "yearly" : "every \(interval) years"
            if let month = monthOfYear {
                let monthName = Calendar.current.monthSymbols[month - 1]
                description += " in \(monthName)"
                if let day = dayOfMonth {
                    description += " on day \(day)"
                }
            }
        }

        // Add end condition
        switch endType {
        case .never:
            break // No additional text needed
        case .afterDate:
            if let date = endDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                description += ", until \(formatter.string(from: date))"
            }
        case .afterOccurrences:
            if let count = endAfterOccurrences {
                description += ", \(count) times"
            }
        }

        return description
    }
}
