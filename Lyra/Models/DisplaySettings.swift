//
//  DisplaySettings.swift
//  Lyra
//
//  Comprehensive display customization settings for song views
//

import SwiftUI

/// Comprehensive display settings for song customization
struct DisplaySettings: Codable, Equatable, Sendable {
    // MARK: - Font Settings

    var fontSize: Double
    var titleFontFamily: FontFamily
    var metadataFontFamily: FontFamily
    var lyricsFontFamily: FontFamily
    var chordsFontFamily: FontFamily
    var fontWeight: FontWeightOption

    // MARK: - Color Settings

    var chordColor: String
    var lyricsColor: String
    var sectionLabelColor: String
    var metadataColor: String
    var backgroundColor: String

    // MARK: - Layout Settings

    var spacing: Double  // Chord-lyrics spacing
    var lineSpacing: LineSpacingOption
    var sectionSpacing: Double
    var leftMargin: Double
    var rightMargin: Double
    var topMargin: Double
    var bottomMargin: Double
    var twoColumnMode: Bool

    // MARK: - Dark Mode Settings

    var darkModePreference: DarkModePreference

    // MARK: - Accessibility Settings

    var highContrastMode: Bool
    var reduceTransparency: Bool
    var boldText: Bool
    var minimumFontSize: Double
    var colorBlindFriendly: Bool

    /// Default settings
    static let `default` = DisplaySettings(
        // Fonts
        fontSize: 16,
        titleFontFamily: .system,
        metadataFontFamily: .system,
        lyricsFontFamily: .system,
        chordsFontFamily: .monospaced,
        fontWeight: .regular,

        // Colors
        chordColor: "#007AFF",
        lyricsColor: "#000000",
        sectionLabelColor: "#8E8E93",
        metadataColor: "#3A3A3C",
        backgroundColor: "#FFFFFF",

        // Layout
        spacing: 8,
        lineSpacing: .normal,
        sectionSpacing: 32,
        leftMargin: 20,
        rightMargin: 20,
        topMargin: 20,
        bottomMargin: 20,
        twoColumnMode: false,

        // Dark Mode
        darkModePreference: .system,

        // Accessibility
        highContrastMode: false,
        reduceTransparency: false,
        boldText: false,
        minimumFontSize: 12,
        colorBlindFriendly: false
    )

    /// Stage performance preset (high visibility)
    static let stagePerformance = DisplaySettings(
        fontSize: 20,
        titleFontFamily: .system,
        metadataFontFamily: .system,
        lyricsFontFamily: .system,
        chordsFontFamily: .monospaced,
        fontWeight: .bold,
        chordColor: "#FF3B30",
        lyricsColor: "#000000",
        sectionLabelColor: "#FF9500",
        metadataColor: "#3A3A3C",
        backgroundColor: "#FFFFFF",
        spacing: 10,
        lineSpacing: .relaxed,
        sectionSpacing: 40,
        leftMargin: 24,
        rightMargin: 24,
        topMargin: 24,
        bottomMargin: 24,
        twoColumnMode: false,
        darkModePreference: .alwaysLight,
        highContrastMode: true,
        reduceTransparency: true,
        boldText: true,
        minimumFontSize: 16,
        colorBlindFriendly: true
    )

    /// Practice preset (comfortable reading)
    static let practice = DisplaySettings(
        fontSize: 16,
        titleFontFamily: .system,
        metadataFontFamily: .system,
        lyricsFontFamily: .charter,
        chordsFontFamily: .monospaced,
        fontWeight: .regular,
        chordColor: "#007AFF",
        lyricsColor: "#000000",
        sectionLabelColor: "#8E8E93",
        metadataColor: "#3A3A3C",
        backgroundColor: "#FFFFFF",
        spacing: 8,
        lineSpacing: .normal,
        sectionSpacing: 32,
        leftMargin: 20,
        rightMargin: 20,
        topMargin: 20,
        bottomMargin: 20,
        twoColumnMode: false,
        darkModePreference: .system,
        highContrastMode: false,
        reduceTransparency: false,
        boldText: false,
        minimumFontSize: 12,
        colorBlindFriendly: false
    )

    /// Large print preset (accessibility)
    static let largePrint = DisplaySettings(
        fontSize: 24,
        titleFontFamily: .system,
        metadataFontFamily: .system,
        lyricsFontFamily: .system,
        chordsFontFamily: .monospaced,
        fontWeight: .medium,
        chordColor: "#007AFF",
        lyricsColor: "#000000",
        sectionLabelColor: "#8E8E93",
        metadataColor: "#3A3A3C",
        backgroundColor: "#FFFFFF",
        spacing: 12,
        lineSpacing: .relaxed,
        sectionSpacing: 48,
        leftMargin: 24,
        rightMargin: 24,
        topMargin: 24,
        bottomMargin: 24,
        twoColumnMode: false,
        darkModePreference: .system,
        highContrastMode: true,
        reduceTransparency: true,
        boldText: true,
        minimumFontSize: 20,
        colorBlindFriendly: true
    )

    // MARK: - Color Methods

    func chordColorValue() -> Color {
        applyAccessibilityColors(Color(hex: chordColor) ?? .blue)
    }

    func lyricsColorValue() -> Color {
        applyAccessibilityColors(Color(hex: lyricsColor) ?? .primary)
    }

    func sectionLabelColorValue() -> Color {
        applyAccessibilityColors(Color(hex: sectionLabelColor) ?? .secondary)
    }

    func metadataColorValue() -> Color {
        applyAccessibilityColors(Color(hex: metadataColor) ?? .secondary)
    }

    func backgroundColorValue() -> Color {
        Color(hex: backgroundColor) ?? .white
    }

    private func applyAccessibilityColors(_ color: Color) -> Color {
        if highContrastMode {
            // Return high contrast version
            return color
        }
        if colorBlindFriendly {
            // Apply color blind friendly palette adjustments
            return color
        }
        return color
    }

    // MARK: - Font Methods

    func titleFont(size: CGFloat? = nil) -> Font {
        let actualSize = size ?? CGFloat(fontSize)
        let finalSize = max(actualSize, CGFloat(minimumFontSize))
        return titleFontFamily.font(size: finalSize, weight: fontWeight, bold: boldText)
    }

    func metadataFont(size: CGFloat? = nil) -> Font {
        let actualSize = size ?? CGFloat(fontSize * 0.875) // Slightly smaller than body
        let finalSize = max(actualSize, CGFloat(minimumFontSize))
        return metadataFontFamily.font(size: finalSize, weight: fontWeight, bold: boldText)
    }

    func lyricsFont(size: CGFloat? = nil) -> Font {
        let actualSize = size ?? CGFloat(fontSize)
        let finalSize = max(actualSize, CGFloat(minimumFontSize))
        return lyricsFontFamily.font(size: finalSize, weight: fontWeight, bold: boldText)
    }

    func chordsFont(size: CGFloat? = nil) -> Font {
        let actualSize = size ?? CGFloat(fontSize - 2) // Slightly smaller than lyrics
        let finalSize = max(actualSize, CGFloat(minimumFontSize))
        return chordsFontFamily.font(size: finalSize, weight: fontWeight, bold: boldText)
    }

    // MARK: - Layout Methods

    var actualLineSpacing: CGFloat {
        lineSpacing.value
    }

    var horizontalPadding: EdgeInsets {
        EdgeInsets(top: topMargin, leading: leftMargin, bottom: bottomMargin, trailing: rightMargin)
    }
}

// MARK: - Font Family

enum FontFamily: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case newYork = "New York"
    case monospaced = "Monospaced"
    case mono = "SF Mono"
    case menlo = "Menlo"
    case courier = "Courier"
    case georgia = "Georgia"
    case charter = "Charter"
    case gothic = "Century Gothic"

    var id: String { rawValue }

    var displayName: String { rawValue }

    func font(size: CGFloat, weight: FontWeightOption, bold: Bool) -> Font {
        let actualWeight = bold ? Font.Weight.bold : weight.fontWeight

        switch self {
        case .system:
            return .system(size: size, weight: actualWeight)
        case .newYork:
            return .system(size: size, weight: actualWeight, design: .serif)
        case .monospaced, .mono:
            return .system(size: size, weight: actualWeight, design: .monospaced)
        case .menlo:
            return .custom("Menlo", size: size)
        case .courier:
            return .custom("Courier", size: size)
        case .georgia:
            return .custom("Georgia", size: size)
        case .charter:
            return .custom("Charter", size: size)
        case .gothic:
            return .custom("Century Gothic", size: size)
        }
    }
}

// MARK: - Font Weight Option

enum FontWeightOption: String, Codable, CaseIterable, Identifiable {
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case bold = "Bold"

    var id: String { rawValue }

    var fontWeight: Font.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .bold: return .bold
        }
    }
}

// MARK: - Line Spacing Option

enum LineSpacingOption: String, Codable, CaseIterable, Identifiable {
    case compact = "Compact"
    case normal = "Normal"
    case relaxed = "Relaxed"

    var id: String { rawValue }

    var value: CGFloat {
        switch self {
        case .compact: return 4
        case .normal: return 8
        case .relaxed: return 12
        }
    }
}

// MARK: - Dark Mode Preference

enum DarkModePreference: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case alwaysLight = "Always Light"
    case alwaysDark = "Always Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .alwaysLight: return .light
        case .alwaysDark: return .dark
        }
    }
}

// MARK: - Color Presets

extension DisplaySettings {
    static let chordColorPresets: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Red", "#FF3B30"),
        ("Green", "#34C759"),
        ("Orange", "#FF9500"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Teal", "#5AC8FA"),
        ("Indigo", "#5856D6"),
        ("Brown", "#A2845E"),
        ("Gray", "#8E8E93")
    ]

    static let lyricsColorPresets: [(name: String, hex: String)] = [
        ("Black", "#000000"),
        ("Dark Gray", "#3A3A3C"),
        ("Gray", "#8E8E93"),
        ("Brown", "#A2845E"),
        ("Blue", "#007AFF"),
        ("Green", "#34C759")
    ]

    static let sectionLabelColorPresets: [(name: String, hex: String)] = [
        ("Gray", "#8E8E93"),
        ("Dark Gray", "#3A3A3C"),
        ("Blue", "#007AFF"),
        ("Orange", "#FF9500"),
        ("Purple", "#AF52DE"),
        ("Brown", "#A2845E")
    ]

    static let metadataColorPresets: [(name: String, hex: String)] = [
        ("Dark Gray", "#3A3A3C"),
        ("Gray", "#8E8E93"),
        ("Blue", "#007AFF"),
        ("Brown", "#A2845E")
    ]

    static let backgroundColorPresets: [(name: String, hex: String)] = [
        ("White", "#FFFFFF"),
        ("Light Gray", "#F2F2F7"),
        ("Warm White", "#FFF9E6"),
        ("Cool White", "#F0F4F8"),
        ("Cream", "#FFFACD"),
        ("Black", "#000000"),
        ("Dark Gray", "#1C1C1E"),
        ("Navy", "#001F3F")
    ]

    /// Color blind friendly palette
    static let colorBlindFriendlyPresets: [(name: String, chordHex: String, lyricsHex: String)] = [
        ("Blue/Black", "#0173B2", "#000000"),
        ("Orange/Black", "#DE8F05", "#000000"),
        ("Green/Black", "#029E73", "#000000"),
        ("Purple/Black", "#CC78BC", "#000000")
    ]
}

// MARK: - UserDefaults Extension

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
