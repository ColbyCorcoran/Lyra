import SwiftData
import Foundation

@Model
final class Book {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    var name: String
    var bookDescription: String?
    var color: String? // Hex color code for UI
    var icon: String? // SF Symbol name

    var songs: [Song]?

    var sortOrder: Int // For user-defined ordering

    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.bookDescription = description
        self.sortOrder = 0
    }
}
