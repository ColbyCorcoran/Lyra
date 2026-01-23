//
//  StageMonitor.swift
//  Lyra
//
//  Stage monitor models for band/team performance
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Monitor Layout Types

/// Layout types for stage monitors
enum StageMonitorLayoutType: String, Codable, CaseIterable {
    case chordsOnly = "chords_only"
    case chordsAndLyrics = "chords_and_lyrics"
    case currentAndNext = "current_and_next"
    case songStructure = "song_structure"
    case lyricsOnly = "lyrics_only"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .chordsOnly: return "Chords Only"
        case .chordsAndLyrics: return "Chords + Lyrics"
        case .currentAndNext: return "Current + Next Section"
        case .songStructure: return "Song Structure Overview"
        case .lyricsOnly: return "Lyrics Only"
        case .custom: return "Custom Layout"
        }
    }

    var description: String {
        switch self {
        case .chordsOnly: return "Large chords for maximum readability"
        case .chordsAndLyrics: return "Chords above lyrics"
        case .currentAndNext: return "Current section with preview of next"
        case .songStructure: return "Full song structure with current section highlighted"
        case .lyricsOnly: return "Lyrics without chords"
        case .custom: return "User-defined custom layout"
        }
    }

    var icon: String {
        switch self {
        case .chordsOnly: return "music.note"
        case .chordsAndLyrics: return "music.note.list"
        case .currentAndNext: return "arrow.right.arrow.left"
        case .songStructure: return "list.bullet"
        case .lyricsOnly: return "text.alignleft"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Monitor Roles

/// Role/position of band member viewing the monitor
enum MonitorRole: String, Codable, CaseIterable, Identifiable {
    case main = "main"
    case vocalist = "vocalist"
    case lead = "lead"
    case rhythm = "rhythm"
    case bass = "bass"
    case keys = "keys"
    case drummer = "drummer"
    case audience = "audience"
    case techBooth = "tech_booth"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .main: return "Main/Leader"
        case .vocalist: return "Vocalist"
        case .lead: return "Lead Guitar"
        case .rhythm: return "Rhythm Guitar"
        case .bass: return "Bass"
        case .keys: return "Keys/Piano"
        case .drummer: return "Drummer"
        case .audience: return "Audience Display"
        case .techBooth: return "Tech Booth"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .main: return "star.fill"
        case .vocalist: return "mic.fill"
        case .lead: return "guitars.fill"
        case .rhythm: return "guitars"
        case .bass: return "waveform"
        case .keys: return "pianokeys"
        case .drummer: return "circle.hexagongrid.fill"
        case .audience: return "person.3.fill"
        case .techBooth: return "slider.horizontal.3"
        case .custom: return "wand.and.stars"
        }
    }

    /// Default layout preference for this role
    var preferredLayout: StageMonitorLayoutType {
        switch self {
        case .main: return .chordsAndLyrics
        case .vocalist: return .lyricsOnly
        case .lead, .rhythm, .keys: return .chordsOnly
        case .bass: return .chordsOnly
        case .drummer: return .songStructure
        case .audience: return .lyricsOnly
        case .techBooth: return .currentAndNext
        case .custom: return .chordsAndLyrics
        }
    }
}

// MARK: - Stage Monitor Configuration

/// Configuration for a single stage monitor
struct StageMonitorConfiguration: Codable, Identifiable {
    var id: UUID
    var name: String
    var role: MonitorRole
    var layoutType: StageMonitorLayoutType

    // Display settings
    var fontSize: CGFloat
    var chordFontSize: CGFloat
    var lyricsFontSize: CGFloat
    var backgroundColor: String // Hex
    var textColor: String // Hex
    var chordColor: String // Hex
    var accentColor: String // Hex
    var fontFamily: String

    // Layout options
    var showSectionLabels: Bool
    var showSongMetadata: Bool // Title, artist, key, tempo, capo
    var showTranspose: Bool
    var showCapo: Bool
    var showNextSection: Bool
    var compactMode: Bool
    var horizontalMargin: CGFloat
    var verticalMargin: CGFloat
    var lineSpacing: CGFloat

    // Theme
    var useDarkTheme: Bool
    var highContrast: Bool

    // Network
    var isNetworkMonitor: Bool
    var deviceName: String?
    var deviceIdentifier: String?

    init(
        id: UUID = UUID(),
        name: String = "Stage Monitor",
        role: MonitorRole = .main,
        layoutType: StageMonitorLayoutType = .chordsAndLyrics,
        fontSize: CGFloat = 48,
        chordFontSize: CGFloat = 56,
        lyricsFontSize: CGFloat = 44,
        backgroundColor: String = "#000000",
        textColor: String = "#FFFFFF",
        chordColor: String = "#00FF00",
        accentColor: String = "#FFD700",
        fontFamily: String = "System",
        showSectionLabels: Bool = true,
        showSongMetadata: Bool = true,
        showTranspose: Bool = true,
        showCapo: Bool = true,
        showNextSection: Bool = false,
        compactMode: Bool = false,
        horizontalMargin: CGFloat = 40,
        verticalMargin: CGFloat = 40,
        lineSpacing: CGFloat = 12,
        useDarkTheme: Bool = true,
        highContrast: Bool = false,
        isNetworkMonitor: Bool = false,
        deviceName: String? = nil,
        deviceIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.layoutType = layoutType
        self.fontSize = fontSize
        self.chordFontSize = chordFontSize
        self.lyricsFontSize = lyricsFontSize
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.chordColor = chordColor
        self.accentColor = accentColor
        self.fontFamily = fontFamily
        self.showSectionLabels = showSectionLabels
        self.showSongMetadata = showSongMetadata
        self.showTranspose = showTranspose
        self.showCapo = showCapo
        self.showNextSection = showNextSection
        self.compactMode = compactMode
        self.horizontalMargin = horizontalMargin
        self.verticalMargin = verticalMargin
        self.lineSpacing = lineSpacing
        self.useDarkTheme = useDarkTheme
        self.highContrast = highContrast
        self.isNetworkMonitor = isNetworkMonitor
        self.deviceName = deviceName
        self.deviceIdentifier = deviceIdentifier
    }

    // Preset configurations

    static func forRole(_ role: MonitorRole) -> StageMonitorConfiguration {
        var config = StageMonitorConfiguration()
        config.role = role
        config.name = role.displayName
        config.layoutType = role.preferredLayout

        switch role {
        case .vocalist:
            config.layoutType = .lyricsOnly
            config.lyricsFontSize = 60
            config.showSongMetadata = true
            config.showTranspose = true
            config.showCapo = true

        case .lead, .rhythm:
            config.layoutType = .chordsOnly
            config.chordFontSize = 72
            config.chordColor = "#00FF00"
            config.showSectionLabels = true
            config.showNextSection = true

        case .bass:
            config.layoutType = .chordsOnly
            config.chordFontSize = 64
            config.chordColor = "#00BFFF" // Deep sky blue
            config.showSectionLabels = true

        case .keys:
            config.layoutType = .chordsAndLyrics
            config.chordFontSize = 56
            config.lyricsFontSize = 40
            config.chordColor = "#FF69B4" // Hot pink

        case .drummer:
            config.layoutType = .songStructure
            config.fontSize = 48
            config.showSectionLabels = true
            config.compactMode = true

        case .audience:
            config.layoutType = .lyricsOnly
            config.lyricsFontSize = 72
            config.backgroundColor = "#1A1A1A"
            config.horizontalMargin = 100
            config.verticalMargin = 80

        case .techBooth:
            config.layoutType = .currentAndNext
            config.fontSize = 40
            config.showSongMetadata = true
            config.showNextSection = true

        case .main:
            config.layoutType = .chordsAndLyrics
            config.showSongMetadata = true
            config.showNextSection = true

        case .custom:
            break
        }

        return config
    }
}

// MARK: - Multi-Monitor Setup

/// Configuration for multiple monitors
struct MultiMonitorSetup: Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var dateCreated: Date
    var dateModified: Date
    var isActive: Bool

    var monitors: [MonitorZone]
    var leaderControlEnabled: Bool
    var syncScrolling: Bool
    var allowIndividualCustomization: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        isActive: Bool = false,
        monitors: [MonitorZone] = [],
        leaderControlEnabled: Bool = true,
        syncScrolling: Bool = true,
        allowIndividualCustomization: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isActive = isActive
        self.monitors = monitors
        self.leaderControlEnabled = leaderControlEnabled
        self.syncScrolling = syncScrolling
        self.allowIndividualCustomization = allowIndividualCustomization
    }

    // Preset multi-monitor setups

    static var smallBand: MultiMonitorSetup {
        MultiMonitorSetup(
            name: "Small Band (3-4)",
            description: "Vocalist, lead guitar, bass, and drummer",
            monitors: [
                MonitorZone(role: .vocalist, priority: 1, configuration: .forRole(.vocalist)),
                MonitorZone(role: .lead, priority: 2, configuration: .forRole(.lead)),
                MonitorZone(role: .bass, priority: 3, configuration: .forRole(.bass)),
                MonitorZone(role: .drummer, priority: 4, configuration: .forRole(.drummer))
            ]
        )
    }

    static var fullBand: MultiMonitorSetup {
        MultiMonitorSetup(
            name: "Full Band (5-6)",
            description: "Complete band with keys",
            monitors: [
                MonitorZone(role: .vocalist, priority: 1, configuration: .forRole(.vocalist)),
                MonitorZone(role: .lead, priority: 2, configuration: .forRole(.lead)),
                MonitorZone(role: .rhythm, priority: 3, configuration: .forRole(.rhythm)),
                MonitorZone(role: .bass, priority: 4, configuration: .forRole(.bass)),
                MonitorZone(role: .keys, priority: 5, configuration: .forRole(.keys)),
                MonitorZone(role: .drummer, priority: 6, configuration: .forRole(.drummer))
            ]
        )
    }

    static var worshipTeam: MultiMonitorSetup {
        MultiMonitorSetup(
            name: "Worship Team",
            description: "Vocals, instruments, and audience display",
            monitors: [
                MonitorZone(role: .vocalist, priority: 1, configuration: .forRole(.vocalist)),
                MonitorZone(role: .keys, priority: 2, configuration: .forRole(.keys)),
                MonitorZone(role: .lead, priority: 3, configuration: .forRole(.lead)),
                MonitorZone(role: .audience, priority: 4, configuration: .forRole(.audience))
            ]
        )
    }
}

/// A zone/assignment for a specific monitor
struct MonitorZone: Codable, Identifiable {
    var id: UUID
    var role: MonitorRole
    var priority: Int // For fallback when fewer physical displays available
    var configuration: StageMonitorConfiguration
    var displayIdentifier: String? // Maps to physical display
    var isBlank: Bool
    var customName: String?

    init(
        id: UUID = UUID(),
        role: MonitorRole,
        priority: Int = 0,
        configuration: StageMonitorConfiguration,
        displayIdentifier: String? = nil,
        isBlank: Bool = false,
        customName: String? = nil
    ) {
        self.id = id
        self.role = role
        self.priority = priority
        self.configuration = configuration
        self.displayIdentifier = displayIdentifier
        self.isBlank = isBlank
        self.customName = customName
    }

    var displayName: String {
        customName ?? role.displayName
    }
}

// MARK: - Network Monitor

/// Network mode for wireless monitors
enum StageNetworkMode: String, Codable, CaseIterable {
    case local = "local" // Single device, multiple displays via UIScreen
    case wifi = "wifi" // WiFi network with manual IP
    case bonjour = "bonjour" // Auto-discovery via Bonjour
    case cloud = "cloud" // CloudKit-based remote sync

    var displayName: String {
        switch self {
        case .local: return "Local Only"
        case .wifi: return "WiFi Network"
        case .bonjour: return "Auto-Discovery"
        case .cloud: return "Cloud Sync"
        }
    }

    var description: String {
        switch self {
        case .local: return "Multiple monitors on this device"
        case .wifi: return "Connect via WiFi using IP address"
        case .bonjour: return "Automatic device discovery on local network"
        case .cloud: return "Sync via iCloud for remote devices"
        }
    }

    var icon: String {
        switch self {
        case .local: return "tv"
        case .wifi: return "wifi"
        case .bonjour: return "dot.radiowaves.left.and.right"
        case .cloud: return "icloud"
        }
    }
}

/// Network configuration for stage monitors
struct StageNetworkConfiguration: Codable {
    var mode: StageNetworkMode
    var isEnabled: Bool
    var port: UInt16
    var broadcastInterval: TimeInterval // seconds
    var allowRemoteControl: Bool
    var requireAuthentication: Bool
    var passphrase: String?
    var maxLatency: TimeInterval // milliseconds
    var autoReconnect: Bool

    init(
        mode: StageNetworkMode = .bonjour,
        isEnabled: Bool = false,
        port: UInt16 = 8765,
        broadcastInterval: TimeInterval = 0.1, // 100ms for low latency
        allowRemoteControl: Bool = false,
        requireAuthentication: Bool = true,
        passphrase: String? = nil,
        maxLatency: TimeInterval = 0.1, // 100ms
        autoReconnect: Bool = true
    ) {
        self.mode = mode
        self.isEnabled = isEnabled
        self.port = port
        self.broadcastInterval = broadcastInterval
        self.allowRemoteControl = allowRemoteControl
        self.requireAuthentication = requireAuthentication
        self.passphrase = passphrase
        self.maxLatency = maxLatency
        self.autoReconnect = autoReconnect
    }
}

/// Connected network monitor device
struct NetworkMonitorDevice: Identifiable, Codable {
    var id: UUID
    var deviceName: String
    var deviceType: String // iPhone, iPad, Mac
    var ipAddress: String?
    var role: MonitorRole
    var configuration: StageMonitorConfiguration
    var connectionStatus: ConnectionStatus
    var lastSeen: Date
    var latency: TimeInterval?

    enum ConnectionStatus: String, Codable {
        case connecting = "connecting"
        case connected = "connected"
        case disconnected = "disconnected"
        case error = "error"

        var displayName: String {
            switch self {
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .error: return "Error"
            }
        }

        var color: Color {
            switch self {
            case .connecting: return .orange
            case .connected: return .green
            case .disconnected: return .gray
            case .error: return .red
            }
        }
    }

    var isActive: Bool {
        connectionStatus == .connected && Date().timeIntervalSince(lastSeen) < 5
    }
}

// MARK: - Leader Control

/// Leader control commands for managing monitors
enum LeaderControlCommand: String, Codable {
    case blankAll = "blank_all"
    case unblankAll = "unblank_all"
    case blankMonitor = "blank_monitor"
    case unblankMonitor = "unblank_monitor"
    case overrideMonitor = "override_monitor"
    case sendMessage = "send_message"
    case changeSong = "change_song"
    case changeSection = "change_section"
    case updateConfiguration = "update_configuration"

    var displayName: String {
        switch self {
        case .blankAll: return "Blank All Monitors"
        case .unblankAll: return "Unblank All Monitors"
        case .blankMonitor: return "Blank Monitor"
        case .unblankMonitor: return "Unblank Monitor"
        case .overrideMonitor: return "Override Monitor"
        case .sendMessage: return "Send Message"
        case .changeSong: return "Change Song"
        case .changeSection: return "Change Section"
        case .updateConfiguration: return "Update Configuration"
        }
    }
}

/// Message from leader to monitors
struct LeaderMessage: Codable, Identifiable {
    var id: UUID
    var command: LeaderControlCommand
    var targetMonitorId: UUID?
    var message: String?
    var songId: UUID?
    var sectionName: String?
    var configuration: StageMonitorConfiguration?
    var timestamp: Date

    init(
        id: UUID = UUID(),
        command: LeaderControlCommand,
        targetMonitorId: UUID? = nil,
        message: String? = nil,
        songId: UUID? = nil,
        sectionName: String? = nil,
        configuration: StageMonitorConfiguration? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.command = command
        self.targetMonitorId = targetMonitorId
        self.message = message
        self.songId = songId
        self.sectionName = sectionName
        self.configuration = configuration
        self.timestamp = timestamp
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let stageMonitorConfigurationChanged = Notification.Name("stageMonitorConfigurationChanged")
    static let stageMonitorNetworkDeviceConnected = Notification.Name("stageMonitorNetworkDeviceConnected")
    static let stageMonitorNetworkDeviceDisconnected = Notification.Name("stageMonitorNetworkDeviceDisconnected")
    static let stageMonitorLeaderCommandReceived = Notification.Name("stageMonitorLeaderCommandReceived")
    static let stageMonitorContentUpdated = Notification.Name("stageMonitorContentUpdated")
}
