//
//  ExternalDisplay.swift
//  Lyra
//
//  External display models for professional projection
//

import Foundation
import UIKit
import SwiftUI

/// External display mode
enum ExternalDisplayMode: String, Codable, CaseIterable {
    case mirror = "mirror"
    case extended = "extended"
    case lyricsOnly = "lyrics_only"
    case blank = "blank"

    var displayName: String {
        switch self {
        case .mirror: return "Mirror"
        case .extended: return "Extended"
        case .lyricsOnly: return "Lyrics Only"
        case .blank: return "Blank"
        }
    }

    var description: String {
        switch self {
        case .mirror: return "Same content on both screens"
        case .extended: return "Different content on each screen"
        case .lyricsOnly: return "External shows lyrics, device shows chords"
        case .blank: return "External display is black"
        }
    }

    var icon: String {
        switch self {
        case .mirror: return "rectangle.2.swap"
        case .extended: return "rectangle.split.2x1"
        case .lyricsOnly: return "text.alignleft"
        case .blank: return "rectangle.fill"
        }
    }
}

/// Text alignment for projection
enum ProjectionTextAlignment: String, Codable, CaseIterable {
    case left = "left"
    case center = "center"
    case right = "right"

    var displayName: String {
        switch self {
        case .left: return "Left"
        case .center: return "Center"
        case .right: return "Right"
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

/// Display configuration for projection
struct ExternalDisplayConfiguration: Codable {
    var mode: ExternalDisplayMode

    // Appearance
    var backgroundColor: String // Hex color
    var backgroundImage: String? // Image name or URL
    var textColor: String // Hex color
    var fontSize: CGFloat
    var fontName: String // System font name
    var textAlignment: ProjectionTextAlignment

    // Text effects
    var shadowEnabled: Bool
    var shadowColor: String // Hex color
    var shadowRadius: CGFloat
    var outlineEnabled: Bool
    var outlineColor: String // Hex color
    var outlineWidth: CGFloat

    // Layout
    var horizontalMargin: CGFloat
    var verticalMargin: CGFloat
    var lineSpacing: CGFloat

    // Behavior
    var showSectionTitles: Bool
    var autoAdvanceSections: Bool
    var blankBetweenSongs: Bool
    var syncScroll: Bool

    // Confidence monitor
    var showNextLine: Bool
    var showTimer: Bool
    var showSetlist: Bool

    init(
        mode: ExternalDisplayMode = .lyricsOnly,
        backgroundColor: String = "#000000",
        backgroundImage: String? = nil,
        textColor: String = "#FFFFFF",
        fontSize: CGFloat = 48,
        fontName: String = "System",
        textAlignment: ProjectionTextAlignment = .center,
        shadowEnabled: Bool = true,
        shadowColor: String = "#000000",
        shadowRadius: CGFloat = 4,
        outlineEnabled: Bool = false,
        outlineColor: String = "#000000",
        outlineWidth: CGFloat = 2,
        horizontalMargin: CGFloat = 80,
        verticalMargin: CGFloat = 60,
        lineSpacing: CGFloat = 12,
        showSectionTitles: Bool = false,
        autoAdvanceSections: Bool = false,
        blankBetweenSongs: Bool = true,
        syncScroll: Bool = true,
        showNextLine: Bool = false,
        showTimer: Bool = false,
        showSetlist: Bool = false
    ) {
        self.mode = mode
        self.backgroundColor = backgroundColor
        self.backgroundImage = backgroundImage
        self.textColor = textColor
        self.fontSize = fontSize
        self.fontName = fontName
        self.textAlignment = textAlignment
        self.shadowEnabled = shadowEnabled
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.outlineEnabled = outlineEnabled
        self.outlineColor = outlineColor
        self.outlineWidth = outlineWidth
        self.horizontalMargin = horizontalMargin
        self.verticalMargin = verticalMargin
        self.lineSpacing = lineSpacing
        self.showSectionTitles = showSectionTitles
        self.autoAdvanceSections = autoAdvanceSections
        self.blankBetweenSongs = blankBetweenSongs
        self.syncScroll = syncScroll
        self.showNextLine = showNextLine
        self.showTimer = showTimer
        self.showSetlist = showSetlist
    }
}

/// Display profile for quick switching
struct ExternalDisplayProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var icon: String // SF Symbol name
    var configuration: ExternalDisplayConfiguration
    var isBuiltIn: Bool
    var dateCreated: Date
    var dateModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        icon: String = "tv",
        configuration: ExternalDisplayConfiguration,
        isBuiltIn: Bool = false,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.configuration = configuration
        self.isBuiltIn = isBuiltIn
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    // Built-in profiles

    /// Worship service profile - lyrics only, centered, large text
    static var worshipService: ExternalDisplayProfile {
        var config = ExternalDisplayConfiguration()
        config.mode = .lyricsOnly
        config.backgroundColor = "#000000"
        config.textColor = "#FFFFFF"
        config.fontSize = 56
        config.textAlignment = .center
        config.shadowEnabled = true
        config.shadowRadius = 6
        config.horizontalMargin = 100
        config.verticalMargin = 80
        config.lineSpacing = 16
        config.showSectionTitles = false
        config.blankBetweenSongs = true

        return ExternalDisplayProfile(
            name: "Worship Service",
            description: "Large centered lyrics for congregation",
            icon: "music.note.house",
            configuration: config,
            isBuiltIn: true
        )
    }

    /// Concert profile - lyrics with style
    static var concert: ExternalDisplayProfile {
        var config = ExternalDisplayConfiguration()
        config.mode = .lyricsOnly
        config.backgroundColor = "#1A1A1A"
        config.textColor = "#FFFFFF"
        config.fontSize = 52
        config.textAlignment = .center
        config.shadowEnabled = true
        config.shadowRadius = 8
        config.outlineEnabled = true
        config.outlineWidth = 1
        config.horizontalMargin = 120
        config.verticalMargin = 100
        config.lineSpacing = 18

        return ExternalDisplayProfile(
            name: "Concert",
            description: "Stylized lyrics for performance",
            icon: "music.mic",
            configuration: config,
            isBuiltIn: true
        )
    }

    /// Rehearsal profile - shows everything
    static var rehearsal: ExternalDisplayProfile {
        var config = ExternalDisplayConfiguration()
        config.mode = .extended
        config.backgroundColor = "#2C2C2E"
        config.textColor = "#FFFFFF"
        config.fontSize = 44
        config.textAlignment = .left
        config.shadowEnabled = false
        config.horizontalMargin = 60
        config.verticalMargin = 40
        config.lineSpacing = 10
        config.showSectionTitles = true
        config.showNextLine = true
        config.showTimer = true

        return ExternalDisplayProfile(
            name: "Rehearsal",
            description: "Full information for practice",
            icon: "music.note.list",
            configuration: config,
            isBuiltIn: true
        )
    }

    /// Confidence monitor profile
    static var confidenceMonitor: ExternalDisplayProfile {
        var config = ExternalDisplayConfiguration()
        config.mode = .extended
        config.backgroundColor = "#000000"
        config.textColor = "#FFFF00" // Yellow for high visibility
        config.fontSize = 60
        config.textAlignment = .center
        config.shadowEnabled = true
        config.horizontalMargin = 60
        config.verticalMargin = 60
        config.lineSpacing = 20
        config.showNextLine = true
        config.showTimer = true

        return ExternalDisplayProfile(
            name: "Confidence Monitor",
            description: "Current and next lines for performers",
            icon: "eye",
            configuration: config,
            isBuiltIn: true
        )
    }
}

/// External display information
struct ExternalDisplayInfo: Identifiable {
    let id = UUID()
    let screen: UIScreen
    let name: String
    let bounds: CGRect
    let scale: CGFloat
    let maximumFramesPerSecond: Int

    var resolution: String {
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        return "\(width) × \(height)"
    }

    var isPortrait: Bool {
        bounds.height > bounds.width
    }

    var aspectRatio: String {
        let width = bounds.width
        let height = bounds.height
        let gcd = greatestCommonDivisor(Int(width), Int(height))
        let aspectWidth = Int(width) / gcd
        let aspectHeight = Int(height) / gcd
        return "\(aspectWidth):\(aspectHeight)"
    }

    private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        return b == 0 ? a : greatestCommonDivisor(b, a % b)
    }

    init(screen: UIScreen) {
        self.screen = screen
        self.bounds = screen.bounds
        self.scale = screen.scale
        self.maximumFramesPerSecond = screen.maximumFramesPerSecond

        // Try to get a friendly name
        if screen == UIScreen.main {
            self.name = "Main Display"
        } else {
            self.name = "External Display"
        }
    }
}

/// Content to display on external screen
struct ExternalDisplayContent {
    var currentSection: String?
    var nextSection: String?
    var currentLine: String?
    var nextLine: String?
    var songTitle: String?
    var artist: String?
    var timer: TimeInterval?
    var setlistItems: [String]?
    var currentSetlistIndex: Int?

    var isEmpty: Bool {
        currentSection == nil && currentLine == nil && songTitle == nil
    }
}

/// Notification names for external display
extension Notification.Name {
    static let externalDisplayConnected = Notification.Name("externalDisplayConnected")
    static let externalDisplayDisconnected = Notification.Name("externalDisplayDisconnected")
    static let externalDisplayConfigurationChanged = Notification.Name("externalDisplayConfigurationChanged")
    static let externalDisplayContentChanged = Notification.Name("externalDisplayContentChanged")
}
