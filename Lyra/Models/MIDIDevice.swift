//
//  MIDIDevice.swift
//  Lyra
//
//  MIDI device model representing connected MIDI hardware
//

import Foundation
import CoreMIDI

// MARK: - MIDI Device

struct MIDIDevice: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let manufacturer: String?
    let model: String?
    let uniqueID: Int32
    let isInput: Bool
    let isOutput: Bool
    var isConnected: Bool
    var isEnabled: Bool

    // CoreMIDI references (not codable)
    var endpointRef: MIDIEndpointRef?

    init(
        id: UUID = UUID(),
        name: String,
        manufacturer: String? = nil,
        model: String? = nil,
        uniqueID: Int32,
        isInput: Bool,
        isOutput: Bool,
        isConnected: Bool = true,
        isEnabled: Bool = true,
        endpointRef: MIDIEndpointRef? = nil
    ) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
        self.model = model
        self.uniqueID = uniqueID
        self.isInput = isInput
        self.isOutput = isOutput
        self.isConnected = isConnected
        self.isEnabled = isEnabled
        self.endpointRef = endpointRef
    }

    var displayName: String {
        if let manufacturer = manufacturer, !manufacturer.isEmpty {
            return "\(manufacturer) - \(name)"
        }
        return name
    }

    var typeDescription: String {
        if isInput && isOutput {
            return "Input/Output"
        } else if isInput {
            return "Input"
        } else if isOutput {
            return "Output"
        } else {
            return "Unknown"
        }
    }

    var icon: String {
        if isInput && isOutput {
            return "pianokeys"
        } else if isInput {
            return "arrow.down.circle"
        } else if isOutput {
            return "arrow.up.circle"
        } else {
            return "questionmark.circle"
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, name, manufacturer, model, uniqueID
        case isInput, isOutput, isConnected, isEnabled
    }
}

// MARK: - MIDI Message Types

enum MIDIMessageType: String, Codable {
    case noteOn = "Note On"
    case noteOff = "Note Off"
    case programChange = "Program Change"
    case controlChange = "Control Change"
    case pitchBend = "Pitch Bend"
    case aftertouch = "Aftertouch"
    case systemExclusive = "System Exclusive"
    case clock = "Clock"
    case start = "Start"
    case stop = "Stop"
    case continue_ = "Continue"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .noteOn: return "music.note"
        case .noteOff: return "music.note"
        case .programChange: return "1.circle"
        case .controlChange: return "slider.horizontal.3"
        case .pitchBend: return "waveform.path.ecg"
        case .aftertouch: return "hand.raised"
        case .systemExclusive: return "doc.text"
        case .clock: return "clock"
        case .start: return "play.circle"
        case .stop: return "stop.circle"
        case .continue_: return "playpause.circle"
        case .unknown: return "questionmark"
        }
    }
}

// MARK: - MIDI Message

struct MIDIMessage: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: MIDIMessageType
    let channel: UInt8 // 1-16
    let data1: UInt8
    let data2: UInt8?
    let data3: UInt8?
    let rawBytes: [UInt8]
    let deviceName: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: MIDIMessageType,
        channel: UInt8,
        data1: UInt8,
        data2: UInt8? = nil,
        data3: UInt8? = nil,
        rawBytes: [UInt8] = [],
        deviceName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.channel = channel
        self.data1 = data1
        self.data2 = data2
        self.data3 = data3
        self.rawBytes = rawBytes
        self.deviceName = deviceName
    }

    // MARK: - Formatted Output

    var description: String {
        switch type {
        case .noteOn:
            return "Note On: Note \(data1), Velocity \(data2 ?? 0), Ch \(channel)"
        case .noteOff:
            return "Note Off: Note \(data1), Velocity \(data2 ?? 0), Ch \(channel)"
        case .programChange:
            return "Program Change: \(data1), Ch \(channel)"
        case .controlChange:
            return "Control Change: CC\(data1) = \(data2 ?? 0), Ch \(channel)"
        case .pitchBend:
            let value = Int(data2 ?? 0) * 128 + Int(data1)
            return "Pitch Bend: \(value), Ch \(channel)"
        case .aftertouch:
            return "Aftertouch: \(data1), Ch \(channel)"
        case .systemExclusive:
            return "SysEx: \(rawBytes.count) bytes"
        case .clock:
            return "MIDI Clock"
        case .start:
            return "MIDI Start"
        case .stop:
            return "MIDI Stop"
        case .continue_:
            return "MIDI Continue"
        case .unknown:
            return "Unknown: \(rawBytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
        }
    }

    var hexString: String {
        rawBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    // MARK: - Convenience Accessors

    /// Value (typically data2 - velocity for notes, value for CC)
    var value: UInt8? {
        data2
    }

    /// Note number (data1 for note messages)
    var note: UInt8 {
        data1
    }

    /// Controller number (data1 for CC messages)
    var controller: UInt8 {
        data1
    }

    // MARK: - Parsing

    static func parse(bytes: [UInt8], deviceName: String? = nil) -> MIDIMessage? {
        guard !bytes.isEmpty else { return nil }

        let statusByte = bytes[0]
        let messageType = statusByte & 0xF0
        let channel = (statusByte & 0x0F) + 1 // Convert to 1-16

        var type: MIDIMessageType = .unknown
        var data1: UInt8 = 0
        var data2: UInt8? = nil
        var data3: UInt8? = nil

        switch messageType {
        case 0x80: // Note Off
            type = .noteOff
            data1 = bytes.count > 1 ? bytes[1] : 0
            data2 = bytes.count > 2 ? bytes[2] : 0

        case 0x90: // Note On
            type = .noteOn
            data1 = bytes.count > 1 ? bytes[1] : 0
            data2 = bytes.count > 2 ? bytes[2] : 0
            // Note: Velocity 0 is actually Note Off
            if data2 == 0 {
                type = .noteOff
            }

        case 0xA0: // Polyphonic Aftertouch
            type = .aftertouch
            data1 = bytes.count > 1 ? bytes[1] : 0
            data2 = bytes.count > 2 ? bytes[2] : 0

        case 0xB0: // Control Change
            type = .controlChange
            data1 = bytes.count > 1 ? bytes[1] : 0
            data2 = bytes.count > 2 ? bytes[2] : 0

        case 0xC0: // Program Change
            type = .programChange
            data1 = bytes.count > 1 ? bytes[1] : 0

        case 0xD0: // Channel Aftertouch
            type = .aftertouch
            data1 = bytes.count > 1 ? bytes[1] : 0

        case 0xE0: // Pitch Bend
            type = .pitchBend
            data1 = bytes.count > 1 ? bytes[1] : 0
            data2 = bytes.count > 2 ? bytes[2] : 0

        case 0xF0: // System Messages
            switch statusByte {
            case 0xF0: type = .systemExclusive
            case 0xF8: type = .clock
            case 0xFA: type = .start
            case 0xFB: type = .continue_
            case 0xFC: type = .stop
            default: type = .unknown
            }

        default:
            type = .unknown
        }

        return MIDIMessage(
            timestamp: Date(),
            type: type,
            channel: channel,
            data1: data1,
            data2: data2,
            data3: data3,
            rawBytes: bytes,
            deviceName: deviceName
        )
    }
}

// MARK: - MIDI Control Change Numbers

enum MIDIControlChange: UInt8, CaseIterable {
    case bankSelect = 0
    case modulation = 1
    case breathController = 2
    case footController = 4
    case portamentoTime = 5
    case volume = 7
    case balance = 8
    case pan = 10
    case expression = 11
    case effectControl1 = 12
    case effectControl2 = 13
    case sustain = 64
    case portamento = 65
    case sostenuto = 66
    case softPedal = 67
    case legato = 68
    case hold2 = 69
    case soundController1 = 70 // Default: Sound Variation
    case soundController2 = 71 // Default: Timbre/Harmonic Content
    case soundController3 = 72 // Default: Release Time
    case soundController4 = 73 // Default: Attack Time
    case soundController5 = 74 // Default: Brightness
    case reverb = 91
    case tremolo = 92
    case chorus = 93
    case detune = 94
    case phaser = 95
    case allSoundOff = 120
    case resetAllControllers = 121
    case allNotesOff = 123

    var name: String {
        switch self {
        case .bankSelect: return "Bank Select"
        case .modulation: return "Modulation"
        case .breathController: return "Breath Controller"
        case .footController: return "Foot Controller"
        case .portamentoTime: return "Portamento Time"
        case .volume: return "Volume"
        case .balance: return "Balance"
        case .pan: return "Pan"
        case .expression: return "Expression"
        case .effectControl1: return "Effect 1"
        case .effectControl2: return "Effect 2"
        case .sustain: return "Sustain Pedal"
        case .portamento: return "Portamento"
        case .sostenuto: return "Sostenuto"
        case .softPedal: return "Soft Pedal"
        case .legato: return "Legato"
        case .hold2: return "Hold 2"
        case .soundController1: return "Sound Variation"
        case .soundController2: return "Timbre"
        case .soundController3: return "Release Time"
        case .soundController4: return "Attack Time"
        case .soundController5: return "Brightness"
        case .reverb: return "Reverb"
        case .tremolo: return "Tremolo"
        case .chorus: return "Chorus"
        case .detune: return "Detune"
        case .phaser: return "Phaser"
        case .allSoundOff: return "All Sound Off"
        case .resetAllControllers: return "Reset All"
        case .allNotesOff: return "All Notes Off"
        }
    }
}

// MARK: - Song MIDI Configuration

struct SongMIDIConfiguration: Codable {
    var enabled: Bool
    var sendOnLoad: Bool
    var programChange: UInt8? // 0-127
    var bankSelectMSB: UInt8? // CC 0
    var bankSelectLSB: UInt8? // CC 32
    var controlChanges: [UInt8: UInt8] // CC number -> value
    var sysExMessages: [[UInt8]] // SysEx data
    var channel: UInt8 // 1-16

    init(
        enabled: Bool = false,
        sendOnLoad: Bool = true,
        programChange: UInt8? = nil,
        bankSelectMSB: UInt8? = nil,
        bankSelectLSB: UInt8? = nil,
        controlChanges: [UInt8: UInt8] = [:],
        sysExMessages: [[UInt8]] = [],
        channel: UInt8 = 1
    ) {
        self.enabled = enabled
        self.sendOnLoad = sendOnLoad
        self.programChange = programChange
        self.bankSelectMSB = bankSelectMSB
        self.bankSelectLSB = bankSelectLSB
        self.controlChanges = controlChanges
        self.sysExMessages = sysExMessages
        self.channel = channel
    }

    var hasMessages: Bool {
        programChange != nil ||
        bankSelectMSB != nil ||
        bankSelectLSB != nil ||
        !controlChanges.isEmpty ||
        !sysExMessages.isEmpty
    }
}
