import SwiftData
import Foundation

@Model
final class Attachment {
    var id: UUID
    var createdAt: Date

    var song: Song?

    var filename: String
    var fileType: String // e.g., "pdf", "jpg", "png"
    var fileSize: Int // Bytes

    // Store relative path or use external storage
    var filePath: String? // Path in app's documents directory
    var fileData: Data? // For small files, store inline

    var isDefault: Bool // Is this the primary attachment?

    var notes: String?

    init(filename: String, fileType: String, fileSize: Int) {
        self.id = UUID()
        self.createdAt = Date()
        self.filename = filename
        self.fileType = fileType
        self.fileSize = fileSize
        self.isDefault = false
    }
}
