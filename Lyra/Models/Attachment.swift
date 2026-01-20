import SwiftData
import Foundation

@Model
final class Attachment {
    // MARK: - Identity
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Relationship
    var song: Song?

    // MARK: - File Information
    var filename: String
    var fileType: String // e.g., "pdf", "jpg", "png", "mp3"
    var fileSize: Int // Bytes

    // Store relative path or use external storage
    var filePath: String? // Path in app's documents directory
    var fileData: Data? // For small files, store inline

    // MARK: - Attachment Properties
    var isDefault: Bool // Is this the primary attachment?
    var notes: String? // What is this version? User notes
    var versionName: String? // "Original", "Transposed to C", "Simplified", etc.

    // MARK: - Source Information
    var originalSource: String? // "Files", "Dropbox", "Google Drive", "Camera Scan", etc.
    var cloudFileId: String? // For cloud-synced attachments
    var cloudFileModifiedDate: Date? // Last modified in cloud

    // MARK: - Computed Properties

    /// File extension from filename
    var fileExtension: String {
        (filename as NSString).pathExtension.lowercased()
    }

    /// Human-readable file size
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    /// File type category
    var fileCategory: FileCategory {
        switch fileType.lowercased() {
        case "pdf":
            return .pdf
        case "jpg", "jpeg", "png", "heic", "gif":
            return .image
        case "mp3", "m4a", "wav", "aac":
            return .audio
        case "mov", "mp4", "m4v":
            return .video
        default:
            return .other
        }
    }

    /// Icon for file type
    var fileIcon: String {
        switch fileCategory {
        case .pdf:
            return "doc.richtext"
        case .image:
            return "photo"
        case .audio:
            return "waveform"
        case .video:
            return "video"
        case .other:
            return "doc"
        }
    }

    /// Source icon
    var sourceIcon: String {
        guard let source = originalSource else { return "doc" }

        switch source.lowercased() {
        case let s where s.contains("dropbox"):
            return "cloud"
        case let s where s.contains("drive"):
            return "internaldrive"
        case let s where s.contains("files"):
            return "folder"
        case let s where s.contains("camera"), let s where s.contains("scan"):
            return "doc.viewfinder"
        default:
            return "square.and.arrow.down"
        }
    }

    /// Display name (version name if available, otherwise filename)
    var displayName: String {
        if let version = versionName, !version.isEmpty {
            return version
        }
        return filename
    }

    // MARK: - Initializer

    init(
        filename: String,
        fileType: String,
        fileSize: Int,
        versionName: String? = nil,
        originalSource: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.filename = filename
        self.fileType = fileType
        self.fileSize = fileSize
        self.isDefault = false
        self.versionName = versionName
        self.originalSource = originalSource
    }

    // MARK: - Helper Methods

    /// Update modification date
    func touch() {
        self.modifiedAt = Date()
    }

    /// Create a copy of this attachment
    func duplicate() -> Attachment {
        let copy = Attachment(
            filename: "Copy of \(filename)",
            fileType: fileType,
            fileSize: fileSize,
            versionName: versionName.map { "Copy of \($0)" },
            originalSource: originalSource
        )
        copy.fileData = fileData
        copy.filePath = nil // Don't copy file path, will need new storage
        copy.notes = notes
        return copy
    }
}

// MARK: - File Category

enum FileCategory {
    case pdf
    case image
    case audio
    case video
    case other
}
