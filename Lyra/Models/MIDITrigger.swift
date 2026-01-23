//
//  MIDITrigger.swift
//  Lyra
//
//  MIDI trigger configuration for automatic song loading
//

import Foundation
import SwiftData

// MARK: - MIDI Trigger

struct MIDITrigger: Codable, Identifiable, Hashable {
    let id: UUID
    var type: MIDITriggerType
    var channel: UInt8 // 1-16 (0 = any channel)
    var enabled: Bool

    // For Program Change triggers
    var programNumber: UInt8? // 0-127

    // For Control Change triggers
    var controllerNumber: UInt8? // 0-127
    var controllerValue: UInt8? // 0-127 (nil = any value)
    var controllerValueRange: ClosedRange<UInt8>? // Optional range

    // For Note triggers
    var noteNumber: UInt8? // 0-127
    var noteVelocity: UInt8? // 0-127 (nil = any velocity)

    // Conditional triggers
    var requiresSet: UUID? // Only trigger if song is in this set
    var requiresCombination: [MIDITrigger]? // Require multiple triggers

    init(
        id: UUID = UUID(),
        type: MIDITriggerType,
        channel: UInt8,
        enabled: Bool = true,
        programNumber: UInt8? = nil,
        controllerNumber: UInt8? = nil,
        controllerValue: UInt8? = nil,
        controllerValueRange: ClosedRange<UInt8>? = nil,
        noteNumber: UInt8? = nil,
        noteVelocity: UInt8? = nil,
        requiresSet: UUID? = nil,
        requiresCombination: [MIDITrigger]? = nil
    ) {
        self.id = id
        self.type = type
        self.channel = channel
        self.enabled = enabled
        self.programNumber = programNumber
        self.controllerNumber = controllerNumber
        self.controllerValue = controllerValue
        self.controllerValueRange = controllerValueRange
        self.noteNumber = noteNumber
        self.noteVelocity = noteVelocity
        self.requiresSet = requiresSet
        self.requiresCombination = requiresCombination
    }

    var description: String {
        let channelStr = channel == 0 ? "Any" : "Ch \(channel)"

        switch type {
        case .programChange:
            return "PC \(programNumber ?? 0) (\(channelStr))"

        case .controlChange:
            if let range = controllerValueRange {
                return "CC\(controllerNumber ?? 0): \(range.lowerBound)-\(range.upperBound) (\(channelStr))"
            } else if let value = controllerValue {
                return "CC\(controllerNumber ?? 0): \(value) (\(channelStr))"
            } else {
                return "CC\(controllerNumber ?? 0): Any (\(channelStr))"
            }

        case .noteOn:
            let noteStr = noteName(for: noteNumber ?? 0)
            if let velocity = noteVelocity {
                return "Note \(noteStr) Vel \(velocity) (\(channelStr))"
            } else {
                return "Note \(noteStr) (\(channelStr))"
            }

        case .combination:
            return "Combination (\(requiresCombination?.count ?? 0) triggers)"
        }
    }

    func matches(message: MIDIMessage) -> Bool {
        guard enabled else { return false }

        // Check channel (0 = any channel)
        if channel != 0 && message.channel != channel {
            return false
        }

        switch type {
        case .programChange:
            return message.type == .programChange &&
                   message.data1 == programNumber

        case .controlChange:
            guard message.type == .controlChange,
                  message.data1 == controllerNumber else {
                return false
            }

            let value = message.data2 ?? 0

            if let range = controllerValueRange {
                return range.contains(value)
            } else if let expectedValue = controllerValue {
                return value == expectedValue
            } else {
                return true // Any value
            }

        case .noteOn:
            guard message.type == .noteOn,
                  message.data1 == noteNumber else {
                return false
            }

            if let expectedVelocity = noteVelocity {
                return message.data2 == expectedVelocity
            } else {
                return true // Any velocity
            }

        case .combination:
            // Combination triggers are checked differently
            return false
        }
    }

    private func noteName(for number: UInt8) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(number) / 12 - 1
        let noteIndex = Int(number) % 12
        return "\(notes[noteIndex])\(octave)"
    }
}

// MARK: - MIDI Trigger Type

enum MIDITriggerType: String, Codable, CaseIterable {
    case programChange = "Program Change"
    case controlChange = "Control Change"
    case noteOn = "Note On"
    case combination = "Combination"

    var icon: String {
        switch self {
        case .programChange: return "1.circle"
        case .controlChange: return "slider.horizontal.3"
        case .noteOn: return "music.note"
        case .combination: return "rectangle.3.group"
        }
    }

    var description: String {
        rawValue
    }
}

// MARK: - MIDI Mapping Preset

enum MIDIMappingPreset: String, Codable, CaseIterable {
    case sequential = "Sequential"
    case byKey = "By Key"
    case byTempo = "By Tempo"
    case bySetList = "By Set List"
    case custom = "Custom"

    var description: String {
        switch self {
        case .sequential:
            return "Song 1 = PC 0, Song 2 = PC 1, etc."
        case .byKey:
            return "Group songs by musical key"
        case .byTempo:
            return "Group songs by tempo range"
        case .bySetList:
            return "Map songs in current set list"
        case .custom:
            return "Manually assign each trigger"
        }
    }

    var icon: String {
        switch self {
        case .sequential: return "number"
        case .byKey: return "music.note"
        case .byTempo: return "metronome"
        case .bySetList: return "list.number"
        case .custom: return "hand.point.up"
        }
    }
}

// MARK: - MIDI Feedback Configuration

struct MIDIFeedbackConfiguration: Codable {
    var enabled: Bool
    var sendOnSongLoad: Bool
    var sendProgramChange: Bool
    var programChangeChannel: UInt8
    var sendKeyAsNote: Bool
    var keyNoteChannel: UInt8
    var sendTempoClock: Bool
    var sendCustomCC: Bool
    var customCCNumber: UInt8
    var customCCValue: UInt8

    init(
        enabled: Bool = false,
        sendOnSongLoad: Bool = true,
        sendProgramChange: Bool = true,
        programChangeChannel: UInt8 = 1,
        sendKeyAsNote: Bool = false,
        keyNoteChannel: UInt8 = 1,
        sendTempoClock: Bool = false,
        sendCustomCC: Bool = false,
        customCCNumber: UInt8 = 102,
        customCCValue: UInt8 = 127
    ) {
        self.enabled = enabled
        self.sendOnSongLoad = sendOnSongLoad
        self.sendProgramChange = sendProgramChange
        self.programChangeChannel = programChangeChannel
        self.sendKeyAsNote = sendKeyAsNote
        self.keyNoteChannel = keyNoteChannel
        self.sendTempoClock = sendTempoClock
        self.sendCustomCC = sendCustomCC
        self.customCCNumber = customCCNumber
        self.customCCValue = customCCValue
    }
}
