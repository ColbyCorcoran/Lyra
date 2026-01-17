import SwiftData
import Foundation

@Model
final class UserSettings {
    var id: UUID

    // Display Defaults
    var defaultFontSize: Int
    var defaultFontName: String
    var defaultChordColor: String // Hex
    var defaultLyricsColor: String // Hex
    var chordFontSizeOffset: Int // Offset from lyrics font size (e.g., -2 means chords are 2pt smaller)
    var chordToLyricSpacing: Double // Vertical spacing between chord and lyric lines in points

    // Performance Defaults
    var defaultAutoscrollSpeed: Double
    var defaultTransposeStyle: String // "sharps" or "flats"

    // Import Settings
    var defaultImportFormat: ContentFormat
    var autoDetectChords: Bool

    // iCloud Sync
    var iCloudSyncEnabled: Bool

    init() {
        self.id = UUID()
        self.defaultFontSize = 16
        self.defaultFontName = "System"
        self.defaultChordColor = "#0066CC"
        self.defaultLyricsColor = "#000000"
        self.chordFontSizeOffset = -2 // Chords 2pt smaller than lyrics
        self.chordToLyricSpacing = 2.0 // 2pt between chord and lyric
        self.defaultAutoscrollSpeed = 1.0
        self.defaultTransposeStyle = "sharps"
        self.defaultImportFormat = .chordPro
        self.autoDetectChords = true
        self.iCloudSyncEnabled = false
    }
}
