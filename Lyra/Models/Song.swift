import SwiftData
import Foundation

@Model
final class Song {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Basic Metadata
    var title: String
    var artist: String?
    var album: String?
    var year: Int?
    var copyright: String?
    var ccliNumber: String?

    // MARK: - Musical Information
    var originalKey: String? // e.g., "C", "Dm", "G#"
    var currentKey: String? // After transposition
    var tempo: Int? // BPM
    var timeSignature: String? // e.g., "4/4", "3/4"
    var capo: Int? // Fret number 0-11

    // MARK: - Content
    var content: String // ChordPro or OnSong formatted text
    var contentFormat: ContentFormat // Enum: chordPro, onSong, plainText
    var notes: String? // User notes about the song

    // MARK: - Organization
    @Relationship(deleteRule: .nullify, inverse: \Book.songs)
    var books: [Book]?

    @Relationship(deleteRule: .nullify, inverse: \SetEntry.song)
    var setEntries: [SetEntry]?

    // MARK: - Attachments (for PDFs, images, etc.)
    @Relationship(deleteRule: .cascade, inverse: \Attachment.song)
    var attachments: [Attachment]?

    // MARK: - Annotations (sticky notes, drawings, etc.)
    @Relationship(deleteRule: .cascade, inverse: \Annotation.song)
    var annotations: [Annotation]?

    // MARK: - Performance Settings
    var autoscrollDuration: Int? // Seconds
    var autoscrollEnabled: Bool

    // MARK: - Display Settings
    var fontSize: Int? // Override default (deprecated - use displaySettings)
    var fontName: String? // Override default (deprecated - use displaySettings)
    var displaySettingsData: Data? // Encoded DisplaySettings for per-song customization

    // MARK: - Custom Fields
    var tags: [String]? // For topic-based organization
    var customField1: String? // User-defined
    var customField2: String?
    var customField3: String?

    // MARK: - Usage Statistics
    var timesViewed: Int
    var timesPerformed: Int
    var lastViewed: Date?
    var lastPerformed: Date?

    // MARK: - Import Information
    var importSource: String? // e.g., "Dropbox", "SongSelect", "Manual"
    var importedAt: Date?
    var originalFilename: String?

    // MARK: - Initializer
    init(
        title: String,
        artist: String? = nil,
        content: String = "",
        contentFormat: ContentFormat = .chordPro,
        originalKey: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.title = title
        self.artist = artist
        self.content = content
        self.contentFormat = contentFormat
        self.originalKey = originalKey
        self.currentKey = originalKey
        self.autoscrollEnabled = false
        self.timesViewed = 0
        self.timesPerformed = 0
    }

    // MARK: - Display Settings Helpers

    /// Get display settings (song-specific or global default)
    var displaySettings: DisplaySettings {
        get {
            if let data = displaySettingsData,
               let settings = try? JSONDecoder().decode(DisplaySettings.self, from: data) {
                return settings
            }
            // Fall back to global defaults
            return UserDefaults.standard.globalDisplaySettings
        }
        set {
            displaySettingsData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Check if song has custom display settings
    var hasCustomDisplaySettings: Bool {
        return displaySettingsData != nil
    }

    /// Clear custom display settings (revert to global defaults)
    func clearCustomDisplaySettings() {
        displaySettingsData = nil
    }
}
