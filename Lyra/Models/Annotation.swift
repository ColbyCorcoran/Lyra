import SwiftData
import Foundation

@Model
final class Annotation {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    var song: Song?

    var type: AnnotationType // Enum: stickyNote, drawing, text

    // Position on page (percentage-based for scaling)
    var xPosition: Double // 0.0 to 1.0
    var yPosition: Double // 0.0 to 1.0

    // For sticky notes
    var text: String?
    var noteColor: String? // Hex color
    var textColor: String?
    var fontSize: Int?
    var rotation: Double? // -45 to 45 degrees
    var scale: Double? // 0.5 to 1.5

    // For drawings
    var drawingData: Data? // Encoded PencilKit drawing

    init(song: Song, type: AnnotationType, x: Double, y: Double) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.song = song
        self.type = type
        self.xPosition = x
        self.yPosition = y
    }
}
