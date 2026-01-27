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

    // CCLI numbers are globally unique identifiers
    @Attribute(.unique)
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

    // MARK: - Performance Tracking
    @Relationship(deleteRule: .cascade, inverse: \Performance.song)
    var performances: [Performance]?

    // MARK: - Performance Settings
    var autoscrollDuration: Int? // Seconds
    var autoscrollEnabled: Bool
    var autoscrollConfigData: Data? // Encoded AdvancedAutoscrollConfig

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

    // Cloud file IDs should be unique per song
    @Attribute(.unique)
    var cloudFileId: String? // Dropbox/Drive file ID for sync

    var cloudFileModifiedDate: Date? // Last modified date from cloud
    var cloudFilePath: String? // Full path in cloud storage

    var importRecord: ImportRecord?

    // MARK: - Sync Metadata

    // Hash of last synced content for conflict detection
    var lastSyncedHash: String?

    // Incremented on each conflict resolution
    var conflictVersion: Int = 0

    // Device name that made last change
    var deviceModifiedOn: String?

    // MARK: - MIDI Configuration

    /// MIDI settings for this song (program changes, control changes, etc.)
    var midiConfigurationData: Data? // Encoded SongMIDIConfiguration

    /// MIDI triggers for automatic song loading
    var midiTriggersData: Data? // Encoded [MIDITrigger]

    /// MIDI feedback configuration
    var midiFeedbackData: Data? // Encoded MIDIFeedbackConfiguration

    // MARK: - Version History

    /// Historical versions of this song
    @Relationship(deleteRule: .cascade, inverse: \SongVersion.song)
    var versions: [SongVersion]?

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
            if let data = displaySettingsData {
                do {
                    return try JSONDecoder().decode(DisplaySettings.self, from: data)
                } catch {
                    print("⚠️ Error decoding display settings: \(error.localizedDescription)")
                    // Fall back to global defaults if decoding fails
                    return UserDefaults.standard.globalDisplaySettings
                }
            }
            // Fall back to global defaults
            return UserDefaults.standard.globalDisplaySettings
        }
        set {
            do {
                displaySettingsData = try JSONEncoder().encode(newValue)
            } catch {
                print("⚠️ Error encoding display settings: \(error.localizedDescription)")
                // Fall back to not saving (use global defaults)
                displaySettingsData = nil
            }
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

    // MARK: - MIDI Configuration Helpers

    /// Get MIDI configuration
    var midiConfiguration: SongMIDIConfiguration {
        get {
            if let data = midiConfigurationData {
                do {
                    return try JSONDecoder().decode(SongMIDIConfiguration.self, from: data)
                } catch {
                    print("⚠️ Error decoding MIDI configuration: \(error.localizedDescription)")
                    return SongMIDIConfiguration()
                }
            }
            return SongMIDIConfiguration()
        }
        set {
            do {
                midiConfigurationData = try JSONEncoder().encode(newValue)
            } catch {
                print("⚠️ Error encoding MIDI configuration: \(error.localizedDescription)")
                midiConfigurationData = nil
            }
        }
    }

    /// Check if song has MIDI configuration
    var hasMIDIConfiguration: Bool {
        return midiConfigurationData != nil && midiConfiguration.hasMessages
    }

    /// Clear MIDI configuration
    func clearMIDIConfiguration() {
        midiConfigurationData = nil
    }

    /// Get MIDI triggers
    var midiTriggers: [MIDITrigger] {
        get {
            if let data = midiTriggersData {
                do {
                    return try JSONDecoder().decode([MIDITrigger].self, from: data)
                } catch {
                    print("⚠️ Error decoding MIDI triggers: \(error.localizedDescription)")
                    return []
                }
            }
            return []
        }
        set {
            do {
                midiTriggersData = try JSONEncoder().encode(newValue)
            } catch {
                print("⚠️ Error encoding MIDI triggers: \(error.localizedDescription)")
                midiTriggersData = nil
            }
        }
    }

    /// Check if song has MIDI triggers
    var hasMIDITriggers: Bool {
        return !midiTriggers.isEmpty
    }

    /// Clear MIDI triggers
    func clearMIDITriggers() {
        midiTriggersData = nil
    }

    /// Get MIDI feedback configuration
    var midiFeedback: MIDIFeedbackConfiguration {
        get {
            if let data = midiFeedbackData {
                do {
                    return try JSONDecoder().decode(MIDIFeedbackConfiguration.self, from: data)
                } catch {
                    print("⚠️ Error decoding MIDI feedback: \(error.localizedDescription)")
                    return MIDIFeedbackConfiguration()
                }
            }
            return MIDIFeedbackConfiguration()
        }
        set {
            do {
                midiFeedbackData = try JSONEncoder().encode(newValue)
            } catch {
                print("⚠️ Error encoding MIDI feedback: \(error.localizedDescription)")
                midiFeedbackData = nil
            }
        }
    }

    /// Check if song has MIDI feedback enabled
    var hasMIDIFeedback: Bool {
        return midiFeedback.enabled
    }

    // MARK: - Sync Helpers

    /// Generates a hash of the song content for conflict detection
    func generateContentHash() -> String {
        var hashContent = ""
        hashContent += title
        hashContent += artist ?? ""
        hashContent += content
        hashContent += originalKey ?? ""
        hashContent += modifiedAt.description

        return String(hashContent.hashValue)
    }

    /// Updates sync metadata after modification
    func updateSyncMetadata() {
        modifiedAt = Date()
        lastSyncedHash = generateContentHash()
        deviceModifiedOn = UIDevice.current.name
    }

    /// Checks if content has changed since last sync
    func hasChangedSinceLastSync() -> Bool {
        guard let lastHash = lastSyncedHash else { return true }
        return generateContentHash() != lastHash
    }
}

// MARK: - UIDevice Extension

import UIKit

extension UIDevice {
    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
