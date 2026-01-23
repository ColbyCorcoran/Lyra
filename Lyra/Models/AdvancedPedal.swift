//
//  AdvancedPedal.swift
//  Lyra
//
//  Advanced foot pedal models for enhanced pedal support
//

import Foundation
import SwiftUI

// MARK: - Pedal Device Models

/// Recognized pedal device models with specific capabilities
enum PedalModel: String, Codable, CaseIterable, Identifiable {
    case airTurnBT200 = "AirTurn BT-200"
    case airTurnBT500 = "AirTurn BT-500"
    case airTurnQUAD = "AirTurn QUAD"
    case airTurnDUO = "AirTurn DUO"
    case pageFlipFirefly = "PageFlip Firefly"
    case pageFlipButterfly = "PageFlip Butterfly"
    case pageFlipCicada = "PageFlip Cicada"
    case donnerPageTurner = "Donner Page Turner"
    case irigBlueturn = "iRig BlueTurn"
    case airturnPED = "AirTurn PED"
    case airturnPEDPro = "AirTurn PED Pro"
    case generic = "Generic Bluetooth"
    case usbPedal = "USB Pedal"

    var id: String { rawValue }

    var numberOfPedals: Int {
        switch self {
        case .airTurnBT200, .pageFlipFirefly, .donnerPageTurner, .irigBlueturn:
            return 2
        case .airTurnBT500, .pageFlipButterfly, .pageFlipCicada:
            return 4
        case .airTurnQUAD, .airturnPED:
            return 4
        case .airTurnPEDPro:
            return 6
        case .airTurnDUO:
            return 2
        case .generic, .usbPedal:
            return 8 // Assume up to 8 for generic
        }
    }

    var supportsExpressionPedal: Bool {
        switch self {
        case .airturnPED, .airturnPEDPro:
            return true
        default:
            return false
        }
    }

    var manufacturerWebsite: String {
        switch self {
        case .airTurnBT200, .airTurnBT500, .airTurnQUAD, .airTurnDUO, .airturnPED, .airturnPEDPro:
            return "https://www.airturn.com"
        case .pageFlipFirefly, .pageFlipButterfly, .pageFlipCicada:
            return "https://www.pageflip.com"
        case .donnerPageTurner:
            return "https://www.donnerdeal.com"
        case .irigBlueturn:
            return "https://www.ikmultimedia.com"
        case .generic, .usbPedal:
            return ""
        }
    }

    var icon: String {
        switch self {
        case .airTurnBT200, .airTurnBT500, .airTurnQUAD, .airTurnDUO, .airturnPED, .airturnPEDPro:
            return "rectangle.3.group"
        case .pageFlipFirefly, .pageFlipButterfly, .pageFlipCicada:
            return "square.grid.2x2"
        case .donnerPageTurner:
            return "rectangle.split.2x1"
        case .irigBlueturn:
            return "square.split.2x1"
        case .generic:
            return "rectangle.and.hand.point.up.left"
        case .usbPedal:
            return "cable.connector"
        }
    }

    /// Detection keywords for auto-identification
    var detectionKeywords: [String] {
        switch self {
        case .airTurnBT200:
            return ["airturn", "bt-200", "bt200"]
        case .airTurnBT500:
            return ["airturn", "bt-500", "bt500"]
        case .airTurnQUAD:
            return ["airturn", "quad"]
        case .airTurnDUO:
            return ["airturn", "duo"]
        case .pageFlipFirefly:
            return ["pageflip", "firefly"]
        case .pageFlipButterfly:
            return ["pageflip", "butterfly"]
        case .pageFlipCicada:
            return ["pageflip", "cicada"]
        case .donnerPageTurner:
            return ["donner", "page", "turner"]
        case .irigBlueturn:
            return ["irig", "blueturn"]
        case .airturnPED:
            return ["airturn", "ped"]
        case .airturnPEDPro:
            return ["airturn", "ped", "pro"]
        case .generic, .usbPedal:
            return []
        }
    }
}

/// Connected pedal device
struct PedalDevice: Identifiable, Codable {
    var id: UUID
    var name: String
    var model: PedalModel
    var connectionType: PedalConnectionType
    var isConnected: Bool
    var batteryLevel: Int? // 0-100 if supported
    var lastSeen: Date
    var priority: Int // For multi-pedal setups

    // Expression pedal support
    var hasExpressionPedal: Bool
    var expressionValue: Double? // 0.0-1.0 if expression pedal present

    init(
        id: UUID = UUID(),
        name: String,
        model: PedalModel = .generic,
        connectionType: PedalConnectionType = .bluetooth,
        isConnected: Bool = true,
        batteryLevel: Int? = nil,
        lastSeen: Date = Date(),
        priority: Int = 0,
        hasExpressionPedal: Bool = false,
        expressionValue: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.connectionType = connectionType
        self.isConnected = isConnected
        self.batteryLevel = batteryLevel
        self.lastSeen = lastSeen
        self.priority = priority
        self.hasExpressionPedal = hasExpressionPedal
        self.expressionValue = expressionValue
    }
}

enum PedalConnectionType: String, Codable {
    case bluetooth = "Bluetooth"
    case usb = "USB"
    case midi = "MIDI"
}

// MARK: - Advanced Actions

/// Enhanced pedal action types
enum AdvancedPedalAction: String, Codable, CaseIterable, Identifiable {
    // Basic actions (from original)
    case nextSong = "Next Song"
    case previousSong = "Previous Song"
    case scrollDown = "Scroll Down"
    case scrollUp = "Scroll Up"
    case toggleAutoscroll = "Toggle Autoscroll"
    case nextSection = "Next Section"
    case previousSection = "Previous Section"
    case transposeUp = "Transpose Up"
    case transposeDown = "Transpose Down"
    case toggleMetronome = "Toggle Metronome"
    case markSongPerformed = "Mark Performed"

    // New advanced actions
    case jumpToTop = "Jump to Top"
    case jumpToBottom = "Jump to Bottom"
    case toggleChords = "Toggle Chords"
    case toggleLyrics = "Toggle Lyrics"
    case increaseFontSize = "Increase Font Size"
    case decreaseFontSize = "Decrease Font Size"
    case cycleDisplayMode = "Cycle Display Mode"
    case toggleAnnotations = "Toggle Annotations"
    case addStickyNote = "Add Sticky Note"
    case toggleSetList = "Toggle Set List"
    case toggleFullscreen = "Toggle Fullscreen"
    case blankScreen = "Blank Screen"
    case startRecording = "Start Recording"
    case stopRecording = "Stop Recording"
    case playbackToggle = "Toggle Playback"
    case loopSection = "Loop Section"
    case changeCapo = "Change Capo"
    case resetTranspose = "Reset Transpose"
    case favoriteToggle = "Toggle Favorite"
    case switchProfile = "Switch Profile"
    case switchMode = "Switch Mode"
    case sendMIDI = "Send MIDI"
    case triggerAction = "Trigger Action"
    case none = "None"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .nextSong: return "chevron.right.circle"
        case .previousSong: return "chevron.left.circle"
        case .scrollDown: return "arrow.down.circle"
        case .scrollUp: return "arrow.up.circle"
        case .toggleAutoscroll: return "play.circle"
        case .nextSection: return "forward.end"
        case .previousSection: return "backward.end"
        case .transposeUp: return "arrow.up.arrow.down.circle"
        case .transposeDown: return "arrow.up.arrow.down.circle"
        case .toggleMetronome: return "metronome"
        case .markSongPerformed: return "checkmark.circle"
        case .jumpToTop: return "arrow.up.to.line"
        case .jumpToBottom: return "arrow.down.to.line"
        case .toggleChords: return "music.note"
        case .toggleLyrics: return "text.alignleft"
        case .increaseFontSize: return "textformat.size.larger"
        case .decreaseFontSize: return "textformat.size.smaller"
        case .cycleDisplayMode: return "rectangle.3.group"
        case .toggleAnnotations: return "note.text"
        case .addStickyNote: return "note.text.badge.plus"
        case .toggleSetList: return "list.bullet"
        case .toggleFullscreen: return "arrow.up.left.and.arrow.down.right"
        case .blankScreen: return "eye.slash"
        case .startRecording: return "record.circle"
        case .stopRecording: return "stop.circle"
        case .playbackToggle: return "playpause"
        case .loopSection: return "repeat"
        case .changeCapo: return "tuningfork"
        case .resetTranspose: return "arrow.counterclockwise"
        case .favoriteToggle: return "star"
        case .switchProfile: return "person.2"
        case .switchMode: return "square.grid.2x2"
        case .sendMIDI: return "cable.connector"
        case .triggerAction: return "bolt.fill"
        case .none: return "xmark.circle"
        }
    }

    var description: String {
        switch self {
        case .nextSong: return "Advance to next song in set"
        case .previousSong: return "Return to previous song"
        case .scrollDown: return "Scroll content down"
        case .scrollUp: return "Scroll content up"
        case .toggleAutoscroll: return "Play/pause autoscroll"
        case .nextSection: return "Jump to next section"
        case .previousSection: return "Jump to previous section"
        case .transposeUp: return "Transpose up 1 semitone"
        case .transposeDown: return "Transpose down 1 semitone"
        case .toggleMetronome: return "Start/stop metronome"
        case .markSongPerformed: return "Mark song as performed"
        case .jumpToTop: return "Scroll to top of song"
        case .jumpToBottom: return "Scroll to bottom of song"
        case .toggleChords: return "Show/hide chords"
        case .toggleLyrics: return "Show/hide lyrics"
        case .increaseFontSize: return "Make text larger"
        case .decreaseFontSize: return "Make text smaller"
        case .cycleDisplayMode: return "Switch display mode"
        case .toggleAnnotations: return "Show/hide annotations"
        case .addStickyNote: return "Add sticky note at current position"
        case .toggleSetList: return "Show/hide set list"
        case .toggleFullscreen: return "Enter/exit fullscreen"
        case .blankScreen: return "Blank display temporarily"
        case .startRecording: return "Start audio recording"
        case .stopRecording: return "Stop audio recording"
        case .playbackToggle: return "Play/pause backing track"
        case .loopSection: return "Loop current section"
        case .changeCapo: return "Cycle capo position"
        case .resetTranspose: return "Reset to original key"
        case .favoriteToggle: return "Add/remove favorite"
        case .switchProfile: return "Switch to next profile"
        case .switchMode: return "Switch pedal mode"
        case .sendMIDI: return "Send MIDI message"
        case .triggerAction: return "Execute custom action"
        case .none: return "No action"
        }
    }

    var category: ActionCategory {
        switch self {
        case .nextSong, .previousSong, .toggleSetList, .markSongPerformed:
            return .navigation
        case .scrollDown, .scrollUp, .jumpToTop, .jumpToBottom, .toggleAutoscroll:
            return .scrolling
        case .nextSection, .previousSection, .loopSection:
            return .sections
        case .transposeUp, .transposeDown, .changeCapo, .resetTranspose:
            return .transpose
        case .increaseFontSize, .decreaseFontSize, .toggleChords, .toggleLyrics, .cycleDisplayMode, .toggleFullscreen, .blankScreen:
            return .display
        case .toggleAnnotations, .addStickyNote:
            return .annotations
        case .toggleMetronome, .startRecording, .stopRecording, .playbackToggle:
            return .audio
        case .favoriteToggle, .switchProfile, .switchMode, .sendMIDI, .triggerAction:
            return .advanced
        case .none:
            return .none
        }
    }
}

enum ActionCategory: String {
    case navigation = "Navigation"
    case scrolling = "Scrolling"
    case sections = "Sections"
    case transpose = "Transpose"
    case display = "Display"
    case annotations = "Annotations"
    case audio = "Audio"
    case advanced = "Advanced"
    case none = "None"
}

// MARK: - Press Types

/// Type of pedal press
enum PedalPressType: String, Codable, Equatable {
    case singlePress = "Single Press"
    case doublePress = "Double Press"
    case longPress = "Long Press"
    case triplePress = "Triple Press"

    var description: String {
        switch self {
        case .singlePress: return "Quick tap"
        case .doublePress: return "Two quick taps"
        case .longPress: return "Hold for 0.5s+"
        case .triplePress: return "Three quick taps"
        }
    }

    var icon: String {
        switch self {
        case .singlePress: return "hand.tap"
        case .doublePress: return "hand.tap.fill"
        case .longPress: return "hand.point.down.fill"
        case .triplePress: return "hand.tap.fill"
        }
    }
}

/// Pedal press gesture configuration
struct PedalGesture: Codable, Identifiable {
    var id: UUID
    var pressType: PedalPressType
    var action: AdvancedPedalAction
    var requiresSimultaneous: [Int]? // Other pedal indices that must be pressed simultaneously
    var sequence: [Int]? // Pedal sequence (e.g., [1,2,3] = press 1, then 2, then 3)

    init(
        id: UUID = UUID(),
        pressType: PedalPressType,
        action: AdvancedPedalAction,
        requiresSimultaneous: [Int]? = nil,
        sequence: [Int]? = nil
    ) {
        self.id = id
        self.pressType = pressType
        self.action = action
        self.requiresSimultaneous = requiresSimultaneous
        self.sequence = sequence
    }
}

// MARK: - Pedal Modes

/// Pedal operating mode
enum PedalMode: String, Codable, CaseIterable, Identifiable {
    case performance = "Performance"
    case editing = "Editing"
    case annotation = "Annotation"
    case practice = "Practice"
    case teaching = "Teaching"
    case recording = "Recording"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .performance: return "Live performance with set navigation"
        case .editing: return "Edit songs and navigate fields"
        case .annotation: return "Add notes and annotations"
        case .practice: return "Loop sections and adjust tempo"
        case .teaching: return "Teaching mode with student controls"
        case .recording: return "Recording and playback control"
        }
    }

    var icon: String {
        switch self {
        case .performance: return "music.mic"
        case .editing: return "pencil"
        case .annotation: return "note.text"
        case .practice: return "repeat"
        case .teaching: return "person.2"
        case .recording: return "record.circle"
        }
    }

    var defaultActions: [AdvancedPedalAction] {
        switch self {
        case .performance:
            return [.previousSong, .nextSong, .scrollDown, .scrollUp]
        case .editing:
            return [.scrollUp, .scrollDown, .none, .none]
        case .annotation:
            return [.addStickyNote, .toggleAnnotations, .scrollDown, .scrollUp]
        case .practice:
            return [.previousSection, .nextSection, .loopSection, .toggleMetronome]
        case .teaching:
            return [.decreaseFontSize, .increaseFontSize, .scrollDown, .scrollUp]
        case .recording:
            return [.startRecording, .stopRecording, .playbackToggle, .loopSection]
        }
    }
}

// MARK: - Expression Pedal

/// Expression pedal configuration
struct ExpressionPedalConfig: Codable {
    var isEnabled: Bool
    var targetParameter: ExpressionTarget
    var minValue: Double
    var maxValue: Double
    var curve: ExpressionCurve
    var smoothing: Double // 0.0 - 1.0

    init(
        isEnabled: Bool = false,
        targetParameter: ExpressionTarget = .scrollPosition,
        minValue: Double = 0.0,
        maxValue: Double = 1.0,
        curve: ExpressionCurve = .linear,
        smoothing: Double = 0.2
    ) {
        self.isEnabled = isEnabled
        self.targetParameter = targetParameter
        self.minValue = minValue
        self.maxValue = maxValue
        self.curve = curve
        self.smoothing = smoothing
    }
}

enum ExpressionTarget: String, Codable, CaseIterable {
    case scrollPosition = "Scroll Position"
    case autoscrollSpeed = "Autoscroll Speed"
    case volume = "Volume"
    case brightness = "Screen Brightness"
    case metronomeVolume = "Metronome Volume"
    case fontSize = "Font Size"

    var description: String {
        switch self {
        case .scrollPosition: return "Control scroll position with pedal"
        case .autoscrollSpeed: return "Adjust autoscroll speed in real-time"
        case .volume: return "Control audio playback volume"
        case .brightness: return "Adjust screen brightness"
        case .metronomeVolume: return "Control metronome volume"
        case .fontSize: return "Adjust font size dynamically"
        }
    }

    var icon: String {
        switch self {
        case .scrollPosition: return "arrow.up.and.down"
        case .autoscrollSpeed: return "speedometer"
        case .volume: return "speaker.wave.3"
        case .brightness: return "sun.max"
        case .metronomeVolume: return "metronome"
        case .fontSize: return "textformat.size"
        }
    }
}

enum ExpressionCurve: String, Codable, CaseIterable {
    case linear = "Linear"
    case exponential = "Exponential"
    case logarithmic = "Logarithmic"
    case sCurve = "S-Curve"

    func apply(value: Double) -> Double {
        switch self {
        case .linear:
            return value
        case .exponential:
            return pow(value, 2)
        case .logarithmic:
            return value > 0 ? log10(value * 9 + 1) : 0
        case .sCurve:
            // Smoothstep function
            return value * value * (3 - 2 * value)
        }
    }
}

// MARK: - Advanced Profile

/// Enhanced pedal profile with advanced features
struct AdvancedPedalProfile: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var mode: PedalMode
    var isBuiltIn: Bool

    // Per-pedal mappings (pedal index -> gestures)
    var pedalMappings: [Int: [PedalGesture]]

    // Expression pedal
    var expressionConfig: ExpressionPedalConfig?

    // Mode switching
    var modeSwitchCombo: [Int]? // Pedal combo to switch modes

    // Visual feedback
    var feedbackColor: String // Hex color
    var feedbackDuration: Double // seconds
    var feedbackStyle: FeedbackStyle

    // Audio feedback
    var audioFeedbackEnabled: Bool
    var audioFeedbackSound: FeedbackSound

    // Context-aware
    var contextAware: Bool // Adjust based on current view

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        mode: PedalMode = .performance,
        isBuiltIn: Bool = false,
        pedalMappings: [Int: [PedalGesture]] = [:],
        expressionConfig: ExpressionPedalConfig? = nil,
        modeSwitchCombo: [Int]? = nil,
        feedbackColor: String = "#007AFF",
        feedbackDuration: Double = 0.3,
        feedbackStyle: FeedbackStyle = .flash,
        audioFeedbackEnabled: Bool = false,
        audioFeedbackSound: FeedbackSound = .click,
        contextAware: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.mode = mode
        self.isBuiltIn = isBuiltIn
        self.pedalMappings = pedalMappings
        self.expressionConfig = expressionConfig
        self.modeSwitchCombo = modeSwitchCombo
        self.feedbackColor = feedbackColor
        self.feedbackDuration = feedbackDuration
        self.feedbackStyle = feedbackStyle
        self.audioFeedbackEnabled = audioFeedbackEnabled
        self.audioFeedbackSound = audioFeedbackSound
        self.contextAware = contextAware
    }
}

enum FeedbackStyle: String, Codable, CaseIterable {
    case flash = "Flash"
    case pulse = "Pulse"
    case ripple = "Ripple"
    case none = "None"

    var description: String {
        switch self {
        case .flash: return "Quick flash of color"
        case .pulse: return "Pulsing animation"
        case .ripple: return "Ripple effect from pedal"
        case .none: return "No visual feedback"
        }
    }
}

enum FeedbackSound: String, Codable, CaseIterable {
    case click = "Click"
    case beep = "Beep"
    case tap = "Tap"
    case none = "None"

    var filename: String? {
        switch self {
        case .click: return "pedal_click.wav"
        case .beep: return "pedal_beep.wav"
        case .tap: return "pedal_tap.wav"
        case .none: return nil
        }
    }
}

// MARK: - Multi-Pedal Setup

/// Configuration for multi-pedal setups
struct MultiPedalSetup: Identifiable, Codable {
    var id: UUID
    var name: String
    var devices: [PedalDevice]
    var chainMode: ChainMode
    var primaryDeviceId: UUID? // Leader device for chaining

    init(
        id: UUID = UUID(),
        name: String,
        devices: [PedalDevice] = [],
        chainMode: ChainMode = .independent,
        primaryDeviceId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.devices = devices
        self.chainMode = chainMode
        self.primaryDeviceId = primaryDeviceId
    }
}

enum ChainMode: String, Codable, CaseIterable {
    case independent = "Independent"
    case sequential = "Sequential"
    case mirrored = "Mirrored"

    var description: String {
        switch self {
        case .independent: return "Each pedal has its own mapping"
        case .sequential: return "Pedals numbered sequentially (1-12)"
        case .mirrored: return "All pedals mirror the same actions"
        }
    }
}

// MARK: - Pedal State Tracking

/// Track press state for advanced gestures
struct PedalPressState {
    var pedalIndex: Int
    var pressStartTime: Date
    var lastPressTime: Date?
    var pressCount: Int
    var isHeld: Bool

    mutating func recordPress() {
        let now = Date()
        if let last = lastPressTime, now.timeIntervalSince(last) < 0.5 {
            pressCount += 1
        } else {
            pressCount = 1
        }
        lastPressTime = now
        pressStartTime = now
        isHeld = true
    }

    mutating func recordRelease() {
        isHeld = false
    }

    var pressType: PedalPressType {
        let holdDuration = Date().timeIntervalSince(pressStartTime)

        if holdDuration > 0.5 && isHeld {
            return .longPress
        } else if pressCount == 3 {
            return .triplePress
        } else if pressCount == 2 {
            return .doublePress
        } else {
            return .singlePress
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let pedalDeviceConnected = Notification.Name("pedalDeviceConnected")
    static let pedalDeviceDisconnected = Notification.Name("pedalDeviceDisconnected")
    static let pedalPressed = Notification.Name("pedalPressed")
    static let pedalModeChanged = Notification.Name("pedalModeChanged")
    static let pedalProfileChanged = Notification.Name("pedalProfileChanged")
    static let expressionPedalValueChanged = Notification.Name("expressionPedalValueChanged")
}
