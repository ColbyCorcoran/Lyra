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

    init(name: String, scheduledDate: Date? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.scheduledDate = scheduledDate
        self.isArchived = false
    }

    var sortedSongEntries: [SetEntry]? {
        songEntries?.sorted { $0.orderIndex < $1.orderIndex }
    }
}
