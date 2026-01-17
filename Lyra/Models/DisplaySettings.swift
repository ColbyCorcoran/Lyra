//
//  DisplaySettings.swift
//  Lyra
//
//  Display customization settings for song views
//

import SwiftUI

/// Display settings for song customization
struct DisplaySettings: Codable, Equatable {
    var fontSize: Double
    var chordColor: String  // Hex color
    var lyricsColor: String // Hex color
    var spacing: Double     // Spacing between chords and lyrics

    /// Default settings
    static let `default` = DisplaySettings(
        fontSize: 16,
        chordColor: "#007AFF",  // iOS blue
        lyricsColor: "#000000",  // Black (adapts to dark mode)
        spacing: 8
    )

    /// Preset chord colors
    static let chordColorPresets: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Red", "#FF3B30"),
        ("Green", "#34C759"),
        ("Orange", "#FF9500"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Teal", "#5AC8FA"),
        ("Indigo", "#5856D6")
    ]

    /// Preset lyrics colors
    static let lyricsColorPresets: [(name: String, hex: String)] = [
        ("Black", "#000000"),
        ("Dark Gray", "#3A3A3C"),
        ("Gray", "#8E8E93"),
        ("Brown", "#A2845E")
    ]

    /// Convert hex to Color
    func chordColorValue() -> Color {
        Color(hex: chordColor) ?? .blue
    }

    func lyricsColorValue() -> Color {
        Color(hex: lyricsColor) ?? .primary
    }
}

/// UserDefaults extension for global settings
extension UserDefaults {
    private enum Keys {
        static let displaySettings = "globalDisplaySettings"
    }

    var globalDisplaySettings: DisplaySettings {
        get {
            if let data = data(forKey: Keys.displaySettings),
               let settings = try? JSONDecoder().decode(DisplaySettings.self, from: data) {
                return settings
            }
            return .default
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.displaySettings)
            }
        }
    }
}
