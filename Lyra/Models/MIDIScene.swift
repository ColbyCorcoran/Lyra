//
//  MIDIScene.swift
//  Lyra
//
//  MIDI scene system for controlling lighting, effects, and patches
//

import Foundation
import SwiftData

/// A collection of MIDI messages that can be sent together
struct MIDIScene: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var color: String // Hex color for UI (e.g., "#FF5733")
    var messages: [MIDISceneMessage]
    var enabled: Bool
    var sendOnLoad: Bool // Auto-send when song loads
    var delay: TimeInterval // Delay between messages in seconds
    var dateCreated: Date
    var dateModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        color: String = "#3B82F6",
        messages: [MIDISceneMessage] = [],
        enabled: Bool = true,
        sendOnLoad: Bool = false,
        delay: TimeInterval = 0.05,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
        self.messages = messages
        self.enabled = enabled
        self.sendOnLoad = sendOnLoad
        self.delay = delay
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    var messageCount: Int {
        messages.count
    }

    var estimatedDuration: TimeInterval {
        Double(messages.count) * delay
    }
}

/// A single MIDI message within a scene
struct MIDISceneMessage: Codable, Identifiable {
    let id: UUID
    var type: MIDISceneMessageType
    var channel: Int // 1-16
    var data: [UInt8] // MIDI message data bytes
    var delayAfter: TimeInterval // Additional delay after this message
    var enabled: Bool

    init(
        id: UUID = UUID(),
        type: MIDISceneMessageType,
        channel: Int,
        data: [UInt8],
        delayAfter: TimeInterval = 0.0,
        enabled: Bool = true
    ) {
        self.id = id
        self.type = type
        self.channel = channel
        self.data = data
        self.delayAfter = delayAfter
        self.enabled = enabled
    }

    var displayName: String {
        switch type {
        case .programChange:
            return "Program Change: \(data.first ?? 0)"
        case .controlChange:
            if data.count >= 2 {
                return "CC \(data[0]): \(data[1])"
            }
            return "Control Change"
        case .noteOn:
            if let note = data.first {
                return "Note On: \(MIDIControlSource.noteName(for: Int(note)))"
            }
            return "Note On"
        case .noteOff:
            if let note = data.first {
                return "Note Off: \(MIDIControlSource.noteName(for: Int(note)))"
            }
            return "Note Off"
        case .pitchBend:
            return "Pitch Bend"
        case .aftertouch:
            return "Aftertouch"
        case .sysex:
            return "SysEx (\(data.count) bytes)"
        }
    }

    /// Create a program change message
    static func programChange(program: Int, channel: Int) -> MIDISceneMessage {
        MIDISceneMessage(
            type: .programChange,
            channel: channel,
            data: [UInt8(program & 0x7F)]
        )
    }

    /// Create a control change message
    static func controlChange(controller: Int, value: Int, channel: Int) -> MIDISceneMessage {
        MIDISceneMessage(
            type: .controlChange,
            channel: channel,
            data: [UInt8(controller & 0x7F), UInt8(value & 0x7F)]
        )
    }

    /// Create a note on message
    static func noteOn(note: Int, velocity: Int, channel: Int) -> MIDISceneMessage {
        MIDISceneMessage(
            type: .noteOn,
            channel: channel,
            data: [UInt8(note & 0x7F), UInt8(velocity & 0x7F)]
        )
    }

    /// Create a note off message
    static func noteOff(note: Int, channel: Int) -> MIDISceneMessage {
        MIDISceneMessage(
            type: .noteOff,
            channel: channel,
            data: [UInt8(note & 0x7F), 0]
        )
    }

    /// Create a SysEx message
    static func sysex(data: [UInt8]) -> MIDISceneMessage {
        MIDISceneMessage(
            type: .sysex,
            channel: 1, // Channel not used for SysEx
            data: data
        )
    }
}

/// Types of MIDI messages in a scene
enum MIDISceneMessageType: String, Codable, CaseIterable {
    case programChange = "program_change"
    case controlChange = "control_change"
    case noteOn = "note_on"
    case noteOff = "note_off"
    case pitchBend = "pitch_bend"
    case aftertouch = "aftertouch"
    case sysex = "sysex"

    var displayName: String {
        switch self {
        case .programChange: return "Program Change"
        case .controlChange: return "Control Change"
        case .noteOn: return "Note On"
        case .noteOff: return "Note Off"
        case .pitchBend: return "Pitch Bend"
        case .aftertouch: return "Aftertouch"
        case .sysex: return "SysEx"
        }
    }
}

/// Library of scenes organized by category
struct MIDISceneLibrary: Codable {
    var scenes: [MIDIScene]
    var categories: [MIDISceneCategory]

    init(scenes: [MIDIScene] = [], categories: [MIDISceneCategory] = []) {
        self.scenes = scenes
        self.categories = categories
    }

    func scenes(in category: MIDISceneCategory) -> [MIDIScene] {
        scenes.filter { scene in
            category.sceneIDs.contains(scene.id)
        }
    }

    mutating func addScene(_ scene: MIDIScene, to categoryID: UUID? = nil) {
        scenes.append(scene)
        if let categoryID = categoryID,
           let index = categories.firstIndex(where: { $0.id == categoryID }) {
            categories[index].sceneIDs.append(scene.id)
        }
    }

    mutating func removeScene(_ sceneID: UUID) {
        scenes.removeAll { $0.id == sceneID }
        for index in categories.indices {
            categories[index].sceneIDs.removeAll { $0 == sceneID }
        }
    }
}

/// Category for organizing scenes
struct MIDISceneCategory: Codable, Identifiable {
    let id: UUID
    var name: String
    var icon: String // SF Symbol name
    var sceneIDs: [UUID]
    var color: String

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        sceneIDs: [UUID] = [],
        color: String = "#6B7280"
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sceneIDs = sceneIDs
        self.color = color
    }

    /// Built-in category: Lighting
    static var lighting: MIDISceneCategory {
        MIDISceneCategory(
            name: "Lighting",
            icon: "lightbulb.fill",
            color: "#F59E0B"
        )
    }

    /// Built-in category: Effects
    static var effects: MIDISceneCategory {
        MIDISceneCategory(
            name: "Effects",
            icon: "wand.and.stars",
            color: "#8B5CF6"
        )
    }

    /// Built-in category: Patches
    static var patches: MIDISceneCategory {
        MIDISceneCategory(
            name: "Patches",
            icon: "music.note.list",
            color: "#3B82F6"
        )
    }

    /// Built-in category: Custom
    static var custom: MIDISceneCategory {
        MIDISceneCategory(
            name: "Custom",
            icon: "slider.horizontal.3",
            color: "#10B981"
        )
    }
}

/// Example scenes for common use cases
extension MIDIScene {
    /// Example: Stage lighting for worship intro
    static var worshipIntroLighting: MIDIScene {
        MIDIScene(
            name: "Worship Intro - Warm Lighting",
            description: "Warm ambient lighting for worship intro",
            color: "#F59E0B",
            messages: [
                .controlChange(controller: 1, value: 85, channel: 1),  // Main dimmer
                .controlChange(controller: 10, value: 127, channel: 1), // Warm color
                .controlChange(controller: 11, value: 40, channel: 1),  // Cool color
                .controlChange(controller: 20, value: 60, channel: 1)   // Haze
            ]
        )
    }

    /// Example: Stage lighting for energetic chorus
    static var energeticChorusLighting: MIDIScene {
        MIDIScene(
            name: "Energetic Chorus - Bright Lighting",
            description: "Bright, dynamic lighting for energetic chorus",
            color: "#EF4444",
            messages: [
                .controlChange(controller: 1, value: 127, channel: 1),  // Main dimmer full
                .controlChange(controller: 10, value: 100, channel: 1), // Warm color
                .controlChange(controller: 11, value: 100, channel: 1), // Cool color
                .controlChange(controller: 12, value: 80, channel: 1),  // Strobe/flash
                .controlChange(controller: 20, value: 90, channel: 1)   // Haze increase
            ]
        )
    }

    /// Example: Keyboard patch change
    static var keyboardPatch: MIDIScene {
        MIDIScene(
            name: "Piano + Strings",
            description: "Layer piano with strings on keyboard",
            color: "#3B82F6",
            messages: [
                .programChange(program: 0, channel: 1),   // Piano on channel 1
                .programChange(program: 48, channel: 2),  // Strings on channel 2
                .controlChange(controller: 7, value: 100, channel: 1), // Piano volume
                .controlChange(controller: 7, value: 70, channel: 2)   // Strings volume (lower)
            ]
        )
    }

    /// Example: Effects preset
    static var reverbHallPreset: MIDIScene {
        MIDIScene(
            name: "Hall Reverb - Large",
            description: "Large hall reverb for spacious sound",
            color: "#8B5CF6",
            messages: [
                .controlChange(controller: 91, value: 100, channel: 1), // Reverb depth
                .controlChange(controller: 93, value: 90, channel: 1),  // Chorus depth
                .controlChange(controller: 73, value: 85, channel: 1),  // Attack time
                .controlChange(controller: 72, value: 70, channel: 1)   // Release time
            ]
        )
    }
}
