//
//  MIDIAction.swift
//  Lyra
//
//  MIDI action system for mapping MIDI messages to app functions
//

import Foundation
import SwiftData

/// Types of actions that can be triggered by MIDI
enum MIDIActionType: String, Codable, CaseIterable {
    // Transport & Playback
    case toggleAutoscroll = "toggle_autoscroll"
    case startAutoscroll = "start_autoscroll"
    case stopAutoscroll = "stop_autoscroll"
    case setAutoscrollSpeed = "set_autoscroll_speed"
    case increaseAutoscrollSpeed = "increase_autoscroll_speed"
    case decreaseAutoscrollSpeed = "decrease_autoscroll_speed"

    // Navigation
    case scrollUp = "scroll_up"
    case scrollDown = "scroll_down"
    case scrollToTop = "scroll_to_top"
    case scrollToBottom = "scroll_to_bottom"
    case setScrollPosition = "set_scroll_position"
    case nextSong = "next_song"
    case previousSong = "previous_song"
    case nextSection = "next_section"
    case previousSection = "previous_section"

    // Transpose
    case transposeUp = "transpose_up"
    case transposeDown = "transpose_down"
    case setTranspose = "set_transpose"
    case resetTranspose = "reset_transpose"

    // Volume & Audio
    case setMetronomeVolume = "set_metronome_volume"
    case setBackingTrackVolume = "set_backing_track_volume"
    case setMasterVolume = "set_master_volume"
    case toggleMetronome = "toggle_metronome"
    case toggleBackingTrack = "toggle_backing_track"
    case muteAll = "mute_all"

    // Display & UI
    case setBrightness = "set_brightness"
    case toggleFullscreen = "toggle_fullscreen"
    case toggleDarkMode = "toggle_dark_mode"
    case increaseFontSize = "increase_font_size"
    case decreaseFontSize = "decrease_font_size"
    case setFontSize = "set_font_size"

    // Markers & Sections
    case addMarker = "add_marker"
    case removeMarker = "remove_marker"
    case jumpToMarker = "jump_to_marker"
    case toggleLoopSection = "toggle_loop_section"

    // Recording & Notes
    case startRecording = "start_recording"
    case stopRecording = "stop_recording"
    case addNote = "add_note"
    case toggleAnnotations = "toggle_annotations"

    // Setlist Management
    case loadSetlist = "load_setlist"
    case nextInSetlist = "next_in_setlist"
    case previousInSetlist = "previous_in_setlist"

    // MIDI & Control
    case sendMIDIScene = "send_midi_scene"
    case toggleMIDIThru = "toggle_midi_thru"
    case panicAllNotesOff = "panic_all_notes_off"

    // Custom Actions
    case custom = "custom"

    var displayName: String {
        switch self {
        case .toggleAutoscroll: return "Toggle Autoscroll"
        case .startAutoscroll: return "Start Autoscroll"
        case .stopAutoscroll: return "Stop Autoscroll"
        case .setAutoscrollSpeed: return "Set Autoscroll Speed"
        case .increaseAutoscrollSpeed: return "Increase Autoscroll Speed"
        case .decreaseAutoscrollSpeed: return "Decrease Autoscroll Speed"
        case .scrollUp: return "Scroll Up"
        case .scrollDown: return "Scroll Down"
        case .scrollToTop: return "Scroll to Top"
        case .scrollToBottom: return "Scroll to Bottom"
        case .setScrollPosition: return "Set Scroll Position"
        case .nextSong: return "Next Song"
        case .previousSong: return "Previous Song"
        case .nextSection: return "Next Section"
        case .previousSection: return "Previous Section"
        case .transposeUp: return "Transpose Up"
        case .transposeDown: return "Transpose Down"
        case .setTranspose: return "Set Transpose"
        case .resetTranspose: return "Reset Transpose"
        case .setMetronomeVolume: return "Set Metronome Volume"
        case .setBackingTrackVolume: return "Set Backing Track Volume"
        case .setMasterVolume: return "Set Master Volume"
        case .toggleMetronome: return "Toggle Metronome"
        case .toggleBackingTrack: return "Toggle Backing Track"
        case .muteAll: return "Mute All"
        case .setBrightness: return "Set Brightness"
        case .toggleFullscreen: return "Toggle Fullscreen"
        case .toggleDarkMode: return "Toggle Dark Mode"
        case .increaseFontSize: return "Increase Font Size"
        case .decreaseFontSize: return "Decrease Font Size"
        case .setFontSize: return "Set Font Size"
        case .addMarker: return "Add Marker"
        case .removeMarker: return "Remove Marker"
        case .jumpToMarker: return "Jump to Marker"
        case .toggleLoopSection: return "Toggle Loop Section"
        case .startRecording: return "Start Recording"
        case .stopRecording: return "Stop Recording"
        case .addNote: return "Add Note"
        case .toggleAnnotations: return "Toggle Annotations"
        case .loadSetlist: return "Load Setlist"
        case .nextInSetlist: return "Next in Setlist"
        case .previousInSetlist: return "Previous in Setlist"
        case .sendMIDIScene: return "Send MIDI Scene"
        case .toggleMIDIThru: return "Toggle MIDI Thru"
        case .panicAllNotesOff: return "Panic (All Notes Off)"
        case .custom: return "Custom Action"
        }
    }

    var category: String {
        switch self {
        case .toggleAutoscroll, .startAutoscroll, .stopAutoscroll, .setAutoscrollSpeed, .increaseAutoscrollSpeed, .decreaseAutoscrollSpeed:
            return "Autoscroll"
        case .scrollUp, .scrollDown, .scrollToTop, .scrollToBottom, .setScrollPosition, .nextSong, .previousSong, .nextSection, .previousSection:
            return "Navigation"
        case .transposeUp, .transposeDown, .setTranspose, .resetTranspose:
            return "Transpose"
        case .setMetronomeVolume, .setBackingTrackVolume, .setMasterVolume, .toggleMetronome, .toggleBackingTrack, .muteAll:
            return "Audio"
        case .setBrightness, .toggleFullscreen, .toggleDarkMode, .increaseFontSize, .decreaseFontSize, .setFontSize:
            return "Display"
        case .addMarker, .removeMarker, .jumpToMarker, .toggleLoopSection:
            return "Markers"
        case .startRecording, .stopRecording, .addNote, .toggleAnnotations:
            return "Recording"
        case .loadSetlist, .nextInSetlist, .previousInSetlist:
            return "Setlist"
        case .sendMIDIScene, .toggleMIDIThru, .panicAllNotesOff:
            return "MIDI"
        case .custom:
            return "Custom"
        }
    }

    /// Whether this action accepts a continuous value (0-127)
    var acceptsContinuousValue: Bool {
        switch self {
        case .setAutoscrollSpeed, .setScrollPosition, .setTranspose,
             .setMetronomeVolume, .setBackingTrackVolume, .setMasterVolume,
             .setBrightness, .setFontSize:
            return true
        default:
            return false
        }
    }

    /// Whether this action is a toggle (on/off)
    var isToggle: Bool {
        switch self {
        case .toggleAutoscroll, .toggleMetronome, .toggleBackingTrack,
             .toggleFullscreen, .toggleDarkMode, .toggleAnnotations,
             .toggleLoopSection, .toggleMIDIThru:
            return true
        default:
            return false
        }
    }
}

/// MIDI control source (what triggers the action)
enum MIDIControlSource: Codable, Equatable {
    case controlChange(controller: Int, channel: Int) // CC number (0-127), channel (0 = any, 1-16 = specific)
    case note(note: Int, channel: Int, velocitySensitive: Bool)
    case pitchBend(channel: Int)
    case aftertouch(channel: Int)
    case programChange(channel: Int)

    var displayName: String {
        switch self {
        case .controlChange(let controller, let channel):
            let channelStr = channel == 0 ? "Any" : "\(channel)"
            return "CC \(controller) (Ch \(channelStr))"
        case .note(let note, let channel, let velocitySensitive):
            let channelStr = channel == 0 ? "Any" : "\(channel)"
            let noteName = Self.noteName(for: note)
            let velocityStr = velocitySensitive ? " (Velocity)" : ""
            return "Note \(noteName) (Ch \(channelStr))\(velocityStr)"
        case .pitchBend(let channel):
            let channelStr = channel == 0 ? "Any" : "\(channel)"
            return "Pitch Bend (Ch \(channelStr))"
        case .aftertouch(let channel):
            let channelStr = channel == 0 ? "Any" : "\(channel)"
            return "Aftertouch (Ch \(channelStr))"
        case .programChange(let channel):
            let channelStr = channel == 0 ? "Any" : "\(channel)"
            return "Program Change (Ch \(channelStr))"
        }
    }

    static func noteName(for noteNumber: Int) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (noteNumber / 12) - 1
        let note = notes[noteNumber % 12]
        return "\(note)\(octave)"
    }

    /// Check if this source matches a received MIDI message
    func matches(_ message: MIDIMessage) -> Bool {
        switch (self, message.type) {
        case (.controlChange(let controller, let channel), .controlChange):
            guard let messageController = message.controller,
                  controller == messageController else { return false }
            return channel == 0 || channel == message.channel

        case (.note(let note, let channel, _), .noteOn), (.note(let note, let channel, _), .noteOff):
            guard let messageNote = message.note,
                  note == messageNote else { return false }
            return channel == 0 || channel == message.channel

        case (.pitchBend(let channel), .pitchBend):
            return channel == 0 || channel == message.channel

        case (.aftertouch(let channel), .aftertouch):
            return channel == 0 || channel == message.channel

        case (.programChange(let channel), .programChange):
            return channel == 0 || channel == message.channel

        default:
            return false
        }
    }
}

/// A mapping from a MIDI control to an action
struct MIDIControlMapping: Codable, Identifiable {
    let id: UUID
    var name: String
    var source: MIDIControlSource
    var action: MIDIActionType
    var enabled: Bool

    // Value mapping for continuous controls
    var minValue: Int // MIDI value (0-127)
    var maxValue: Int // MIDI value (0-127)
    var minOutput: Double // Action value (e.g., 0.0-1.0 for volume, 0-100 for scroll position)
    var maxOutput: Double // Action value
    var curve: MIDIValueCurve // Linear, exponential, logarithmic

    // Toggle behavior (for CC used as toggle)
    var toggleThreshold: Int // Value above this = on, below = off (default 64)

    // Custom parameters
    var customParameters: [String: String]

    var dateCreated: Date
    var dateModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        source: MIDIControlSource,
        action: MIDIActionType,
        enabled: Bool = true,
        minValue: Int = 0,
        maxValue: Int = 127,
        minOutput: Double = 0.0,
        maxOutput: Double = 1.0,
        curve: MIDIValueCurve = .linear,
        toggleThreshold: Int = 64,
        customParameters: [String: String] = [:],
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.action = action
        self.enabled = enabled
        self.minValue = minValue
        self.maxValue = maxValue
        self.minOutput = minOutput
        self.maxOutput = maxOutput
        self.curve = curve
        self.toggleThreshold = toggleThreshold
        self.customParameters = customParameters
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    /// Map a MIDI value (0-127) to an output value based on the mapping settings
    func mapValue(_ midiValue: Int) -> Double {
        // Clamp input
        let clampedInput = max(minValue, min(maxValue, midiValue))

        // Normalize to 0.0-1.0
        let normalizedInput = Double(clampedInput - minValue) / Double(maxValue - minValue)

        // Apply curve
        let curvedValue: Double
        switch curve {
        case .linear:
            curvedValue = normalizedInput
        case .exponential:
            curvedValue = normalizedInput * normalizedInput
        case .logarithmic:
            curvedValue = sqrt(normalizedInput)
        case .inverse:
            curvedValue = 1.0 - normalizedInput
        case .sCurve:
            // Sigmoid-like S-curve
            curvedValue = (1.0 / (1.0 + exp(-12.0 * (normalizedInput - 0.5))))
        }

        // Map to output range
        return minOutput + (curvedValue * (maxOutput - minOutput))
    }

    /// Check if the mapping should toggle based on the MIDI value
    func shouldToggle(_ midiValue: Int) -> Bool? {
        if action.isToggle {
            return midiValue >= toggleThreshold
        }
        return nil
    }
}

/// Value curve types for mapping MIDI values to action values
enum MIDIValueCurve: String, Codable, CaseIterable {
    case linear = "linear"
    case exponential = "exponential"
    case logarithmic = "logarithmic"
    case inverse = "inverse"
    case sCurve = "s_curve"

    var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .exponential: return "Exponential"
        case .logarithmic: return "Logarithmic"
        case .inverse: return "Inverse"
        case .sCurve: return "S-Curve"
        }
    }

    var description: String {
        switch self {
        case .linear: return "Straight 1:1 mapping"
        case .exponential: return "Slow start, fast finish"
        case .logarithmic: return "Fast start, slow finish"
        case .inverse: return "Inverted values"
        case .sCurve: return "Smooth acceleration in middle"
        }
    }
}

/// Preset mapping configurations
struct MIDIControlMappingPreset: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var mappings: [MIDIControlMapping]
    var dateCreated: Date
    var dateModified: Date
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        mappings: [MIDIControlMapping] = [],
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.mappings = mappings
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isBuiltIn = isBuiltIn
    }

    /// Built-in preset: Standard MIDI CC mappings
    static var standardCCPreset: MIDIControlMappingPreset {
        MIDIControlMappingPreset(
            name: "Standard MIDI CC",
            description: "Common MIDI CC mappings for worship performance",
            mappings: [
                MIDIControlMapping(
                    name: "CC 1 → Transpose",
                    source: .controlChange(controller: 1, channel: 0),
                    action: .setTranspose,
                    minValue: 0,
                    maxValue: 127,
                    minOutput: -12.0,
                    maxOutput: 12.0
                ),
                MIDIControlMapping(
                    name: "CC 7 → Master Volume",
                    source: .controlChange(controller: 7, channel: 0),
                    action: .setMasterVolume,
                    curve: .exponential
                ),
                MIDIControlMapping(
                    name: "CC 11 → Autoscroll Speed",
                    source: .controlChange(controller: 11, channel: 0),
                    action: .setAutoscrollSpeed,
                    minOutput: 0.0,
                    maxOutput: 2.0
                ),
                MIDIControlMapping(
                    name: "CC 64 → Toggle Autoscroll",
                    source: .controlChange(controller: 64, channel: 0),
                    action: .toggleAutoscroll,
                    toggleThreshold: 64
                ),
                MIDIControlMapping(
                    name: "CC 10 → Metronome Volume",
                    source: .controlChange(controller: 10, channel: 0),
                    action: .setMetronomeVolume
                ),
                MIDIControlMapping(
                    name: "CC 74 → Brightness",
                    source: .controlChange(controller: 74, channel: 0),
                    action: .setBrightness
                )
            ],
            isBuiltIn: true
        )
    }

    /// Built-in preset: Expression pedal mappings
    static var expressionPedalPreset: MIDIControlMappingPreset {
        MIDIControlMappingPreset(
            name: "Expression Pedal",
            description: "Expression pedal for smooth continuous control",
            mappings: [
                MIDIControlMapping(
                    name: "CC 11 → Autoscroll Speed",
                    source: .controlChange(controller: 11, channel: 0),
                    action: .setAutoscrollSpeed,
                    minOutput: 0.0,
                    maxOutput: 2.0,
                    curve: .linear
                )
            ],
            isBuiltIn: true
        )
    }

    /// Built-in preset: Footswitch mappings
    static var footswitchPreset: MIDIControlMappingPreset {
        MIDIControlMappingPreset(
            name: "Footswitch",
            description: "Footswitch controls for hands-free operation",
            mappings: [
                MIDIControlMapping(
                    name: "CC 64 → Toggle Autoscroll",
                    source: .controlChange(controller: 64, channel: 0),
                    action: .toggleAutoscroll
                ),
                MIDIControlMapping(
                    name: "CC 65 → Next Song",
                    source: .controlChange(controller: 65, channel: 0),
                    action: .nextSong
                ),
                MIDIControlMapping(
                    name: "CC 66 → Previous Song",
                    source: .controlChange(controller: 66, channel: 0),
                    action: .previousSong
                )
            ],
            isBuiltIn: true
        )
    }
}
