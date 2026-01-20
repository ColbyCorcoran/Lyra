import SwiftData
import Foundation

@Model
final class ImportRecord {
    // MARK: - Identifiers
    var id: UUID
    var importDate: Date

    // MARK: - Import Metadata
    var importSource: String // "Files", "Dropbox", "Google Drive", "Camera Scan", etc.
    var importMethod: String? // "Single File", "Bulk Import", "Multi-Page Scan", etc.

    // MARK: - Statistics
    var totalFileCount: Int
    var successCount: Int
    var failedCount: Int
    var duplicateCount: Int
    var skippedCount: Int

    // MARK: - File Information
    var originalFilePaths: [String]? // Original file paths if available
    var fileTypes: [String]? // Extensions: ["txt", "pdf", "cho"]

    // MARK: - Import Details
    var importDuration: TimeInterval? // How long the import took
    var errorMessages: [String]? // Error messages for failed imports
    var notes: String? // User notes about this import

    // MARK: - Cloud Sync (for Dropbox/Drive imports)
    var cloudFolderPath: String? // Path in cloud storage
    var cloudSyncEnabled: Bool // Whether to check for updates

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify)
    var importedSongs: [Song]?

    // MARK: - Computed Properties

    /// Human-readable summary of the import
    var summary: String {
        if successCount == totalFileCount && totalFileCount > 0 {
            return "Successfully imported \(successCount) file\(successCount == 1 ? "" : "s")"
        } else if successCount > 0 {
            return "Imported \(successCount) of \(totalFileCount) files"
        } else {
            return "Import failed - \(failedCount) error\(failedCount == 1 ? "" : "s")"
        }
    }

    /// Success rate as percentage
    var successRate: Double {
        guard totalFileCount > 0 else { return 0.0 }
        return Double(successCount) / Double(totalFileCount)
    }

    /// Import status icon
    var statusIcon: String {
        if successCount == totalFileCount && totalFileCount > 0 {
            return "checkmark.circle.fill"
        } else if successCount > 0 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }

    /// Status color name
    var statusColor: String {
        if successCount == totalFileCount && totalFileCount > 0 {
            return "green"
        } else if successCount > 0 {
            return "orange"
        } else {
            return "red"
        }
    }

    // MARK: - Initializer

    init(
        importSource: String,
        importMethod: String? = nil,
        totalFileCount: Int = 0,
        successCount: Int = 0,
        failedCount: Int = 0,
        duplicateCount: Int = 0,
        skippedCount: Int = 0,
        originalFilePaths: [String]? = nil,
        fileTypes: [String]? = nil,
        cloudFolderPath: String? = nil,
        cloudSyncEnabled: Bool = false
    ) {
        self.id = UUID()
        self.importDate = Date()
        self.importSource = importSource
        self.importMethod = importMethod
        self.totalFileCount = totalFileCount
        self.successCount = successCount
        self.failedCount = failedCount
        self.duplicateCount = duplicateCount
        self.skippedCount = skippedCount
        self.originalFilePaths = originalFilePaths
        self.fileTypes = fileTypes
        self.cloudFolderPath = cloudFolderPath
        self.cloudSyncEnabled = cloudSyncEnabled
    }

    // MARK: - Helper Methods

    /// Add a successfully imported song to this record
    func addImportedSong(_ song: Song) {
        if importedSongs == nil {
            importedSongs = []
        }
        importedSongs?.append(song)
        song.importRecord = self
    }

    /// Update statistics after import completion
    func updateStatistics(
        total: Int,
        successful: Int,
        failed: Int,
        duplicates: Int = 0,
        skipped: Int = 0,
        duration: TimeInterval? = nil
    ) {
        self.totalFileCount = total
        self.successCount = successful
        self.failedCount = failed
        self.duplicateCount = duplicates
        self.skippedCount = skipped
        self.importDuration = duration
    }

    /// Add an error message
    func addError(_ message: String) {
        if errorMessages == nil {
            errorMessages = []
        }
        errorMessages?.append(message)
    }
}

// MARK: - Import Source Extension

extension ImportRecord {
    /// Icon for the import source
    var sourceIcon: String {
        switch importSource.lowercased() {
        case let s where s.contains("dropbox"):
            return "cloud"
        case let s where s.contains("drive"):
            return "internaldrive"
        case let s where s.contains("files"):
            return "folder"
        case let s where s.contains("camera"), let s where s.contains("scan"):
            return "doc.viewfinder"
        case let s where s.contains("paste"), let s where s.contains("clipboard"):
            return "doc.on.clipboard"
        default:
            return "square.and.arrow.down"
        }
    }

    /// Formatted import date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: importDate)
    }

    /// Relative date string (e.g., "2 hours ago")
    var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: importDate, relativeTo: Date())
    }

    /// Date section for grouping (Today, Yesterday, This Week, etc.)
    var dateSection: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(importDate) {
            return "Today"
        } else if calendar.isDateInYesterday(importDate) {
            return "Yesterday"
        } else if calendar.isDate(importDate, equalTo: now, toGranularity: .weekOfYear) {
            return "This Week"
        } else if calendar.isDate(importDate, equalTo: now, toGranularity: .month) {
            return "This Month"
        } else if calendar.isDate(importDate, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: importDate)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: importDate)
        }
    }
}
