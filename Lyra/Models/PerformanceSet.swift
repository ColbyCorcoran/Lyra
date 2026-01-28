import SwiftData
import Foundation

@Model
final class PerformanceSet {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    var name: String
    var setDescription: String?
    var venue: String?
    var scheduledDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.performanceSet)
    var songEntries: [SetEntry]? // Ordered list

    var isArchived: Bool
    var folder: String? // For organizing sets by venue/band

    var notes: String? // Overall set notes

    // MARK: - Recurring Set Properties

    /// The recurrence rule for this set (only present on template sets)
    @Relationship(deleteRule: .cascade)
    var recurrenceRule: RecurrenceRule?

    /// True if this set is a recurring instance (generated from a template)
    var isRecurringInstance: Bool

    /// Link to the parent template set if this is a recurring instance
    var recurringTemplateId: UUID?

    /// The specific date this instance represents in the recurrence pattern
    var instanceDate: Date?

    /// For month/year only scheduling (e.g., "January 2027 TBD")
    var scheduledMonth: Int?
    var scheduledYear: Int?
    var isMonthYearOnly: Bool

    /// True if recurrence has been manually stopped (no new instances will be created)
    var recurrenceStopped: Bool

    init(name: String, scheduledDate: Date? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.scheduledDate = scheduledDate
        self.isArchived = false
        self.isRecurringInstance = false
        self.isMonthYearOnly = false
        self.recurrenceStopped = false
    }

    var sortedSongEntries: [SetEntry]? {
        songEntries?.sorted { $0.orderIndex < $1.orderIndex }
    }

    // MARK: - Computed Properties

    /// True if this set is a recurring template (has a recurrence rule)
    var isRecurringTemplate: Bool {
        recurrenceRule != nil
    }

    /// Display date string that handles month/year only mode
    var displayDate: String {
        if isMonthYearOnly, let month = scheduledMonth, let year = scheduledYear {
            let monthName = Calendar.current.monthSymbols[month - 1]
            return "\(monthName) \(year) (TBD)"
        } else if let date = scheduledDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            return "No date set"
        }
    }
}
