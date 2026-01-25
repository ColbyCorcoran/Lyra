//
//  AdvancedMetronome.swift
//  Lyra
//
//  Advanced metronome models for professional practice and performance
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Time Signature

/// Advanced time signature with complex meter support
struct TimeSignature: Codable, Equatable, Identifiable {
    var id: UUID
    var beatsPerBar: Int
    var noteValue: Int // 4 = quarter, 8 = eighth, etc.
    var name: String?

    init(
        id: UUID = UUID(),
        beatsPerBar: Int = 4,
        noteValue: Int = 4,
        name: String? = nil
    ) {
        self.id = id
        self.beatsPerBar = beatsPerBar
        self.noteValue = noteValue
        self.name = name
    }

    var displayString: String {
        "\(beatsPerBar)/\(noteValue)"
    }

    var fullName: String {
        name ?? displayString
    }

    var isCompound: Bool {
        beatsPerBar % 3 == 0 && beatsPerBar >= 6
    }

    var isComplex: Bool {
        beatsPerBar == 5 || beatsPerBar == 7 || beatsPerBar == 11 || beatsPerBar == 13
    }

    var beatGrouping: [Int] {
        // Return how beats are grouped
        if isCompound {
            let groups = beatsPerBar / 3
            return Array(repeating: 3, count: groups)
        } else if beatsPerBar == 5 {
            return [3, 2] // or [2, 3]
        } else if beatsPerBar == 7 {
            return [3, 2, 2] // or [2, 2, 3]
        } else if beatsPerBar == 11 {
            return [3, 3, 3, 2]
        } else {
            return Array(repeating: 1, count: beatsPerBar)
        }
    }

    // Common time signatures
    static var common: TimeSignature {
        TimeSignature(beatsPerBar: 4, noteValue: 4, name: "Common Time")
    }

    static var waltz: TimeSignature {
        TimeSignature(beatsPerBar: 3, noteValue: 4, name: "Waltz")
    }

    static var cutTime: TimeSignature {
        TimeSignature(beatsPerBar: 2, noteValue: 2, name: "Cut Time")
    }

    static var sixEight: TimeSignature {
        TimeSignature(beatsPerBar: 6, noteValue: 8, name: "6/8 Compound")
    }

    static var nineEight: TimeSignature {
        TimeSignature(beatsPerBar: 9, noteValue: 8, name: "9/8 Compound")
    }

    static var twelveEight: TimeSignature {
        TimeSignature(beatsPerBar: 12, noteValue: 8, name: "12/8 Compound")
    }

    static var fiveEight: TimeSignature {
        TimeSignature(beatsPerBar: 5, noteValue: 8, name: "5/8 Complex")
    }

    static var sevenEight: TimeSignature {
        TimeSignature(beatsPerBar: 7, noteValue: 8, name: "7/8 Complex")
    }

    static var allCommon: [TimeSignature] {
        [.common, .waltz, .cutTime, .sixEight, .nineEight, .twelveEight, .fiveEight, .sevenEight]
    }
}

// MARK: - Subdivision

/// Subdivision patterns for metronome
enum Subdivision: String, Codable, CaseIterable, Identifiable {
    case quarter = "Quarter Notes"
    case eighth = "8th Notes"
    case sixteenth = "16th Notes"
    case triplet = "Triplets"
    case quintuplet = "Quintuplets"
    case sextuplet = "Sextuplets"
    case mixed = "Mixed Subdivisions"

    var id: String { rawValue }

    var clicksPerBeat: Int {
        switch self {
        case .quarter: return 1
        case .eighth: return 2
        case .sixteenth: return 4
        case .triplet: return 3
        case .quintuplet: return 5
        case .sextuplet: return 6
        case .mixed: return 1 // Custom
        }
    }

    var icon: String {
        switch self {
        case .quarter: return "music.quarternote.3"
        case .eighth: return "music.note"
        case .sixteenth: return "music.note.list"
        case .triplet: return "number.3.circle"
        case .quintuplet: return "number.5.circle"
        case .sextuplet: return "number.6.circle"
        case .mixed: return "shuffle"
        }
    }

    var description: String {
        switch self {
        case .quarter: return "1 click per beat"
        case .eighth: return "2 clicks per beat"
        case .sixteenth: return "4 clicks per beat"
        case .triplet: return "3 clicks per beat"
        case .quintuplet: return "5 clicks per beat"
        case .sextuplet: return "6 clicks per beat"
        case .mixed: return "Custom pattern"
        }
    }
}

// MARK: - Accent Pattern

/// Custom accent pattern for beats
struct AccentPattern: Codable, Identifiable {
    var id: UUID
    var name: String
    var pattern: [Bool] // true = accent, false = normal
    var timeSignature: TimeSignature?

    init(
        id: UUID = UUID(),
        name: String,
        pattern: [Bool],
        timeSignature: TimeSignature? = nil
    ) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.timeSignature = timeSignature
    }

    // Common patterns
    static var downbeat: AccentPattern {
        AccentPattern(name: "Downbeat Only", pattern: [true, false, false, false])
    }

    static var backbeat: AccentPattern {
        AccentPattern(name: "Backbeat (2 & 4)", pattern: [false, true, false, true])
    }

    static var every2: AccentPattern {
        AccentPattern(name: "Every 2 Beats", pattern: [true, false])
    }

    static var every3: AccentPattern {
        AccentPattern(name: "Every 3 Beats", pattern: [true, false, false])
    }

    static var allAccents: AccentPattern {
        AccentPattern(name: "All Accented", pattern: [true, true, true, true])
    }

    static var none: AccentPattern {
        AccentPattern(name: "No Accents", pattern: [false, false, false, false])
    }
}

// MARK: - Count-In

/// Count-in configuration
struct CountInConfig: Codable {
    var isEnabled: Bool
    var bars: Int // 1-8 bars
    var useVisualCounIn: Bool
    var useDifferentSound: Bool
    var startAutoscroll: Bool // Start autoscroll after count-in
    var startBackingTrack: Bool // Start backing track after count-in

    init(
        isEnabled: Bool = false,
        bars: Int = 1,
        useVisualCountIn: Bool = true,
        useDifferentSound: Bool = true,
        startAutoscroll: Bool = false,
        startBackingTrack: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.bars = bars
        self.useVisualCounIn = useVisualCountIn
        self.useDifferentSound = useDifferentSound
        self.startAutoscroll = startAutoscroll
        self.startBackingTrack = startBackingTrack
    }

    var totalBeats: Int {
        // Calculate based on time signature
        bars * 4 // Simplified, should use actual time signature
    }
}

// MARK: - Tempo Trainer

/// Tempo trainer for gradual tempo increases
struct TempoTrainer: Codable {
    var isEnabled: Bool
    var startTempo: Int
    var targetTempo: Int
    var increment: Int // BPM to increase per interval
    var intervalBars: Int // Bars before increasing
    var currentTempo: Int
    var isPaused: Bool

    init(
        isEnabled: Bool = false,
        startTempo: Int = 60,
        targetTempo: Int = 120,
        increment: Int = 5,
        intervalBars: Int = 4,
        currentTempo: Int? = nil,
        isPaused: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.startTempo = startTempo
        self.targetTempo = targetTempo
        self.increment = increment
        self.intervalBars = intervalBars
        self.currentTempo = currentTempo ?? startTempo
        self.isPaused = isPaused
    }

    var progress: Double {
        let range = Double(targetTempo - startTempo)
        guard range > 0 else { return 1.0 }
        return Double(currentTempo - startTempo) / range
    }

    var isComplete: Bool {
        currentTempo >= targetTempo
    }

    var totalSteps: Int {
        max(1, (targetTempo - startTempo) / increment)
    }

    var currentStep: Int {
        (currentTempo - startTempo) / increment
    }
}

// MARK: - Metronome Sound

/// Metronome click sound options
enum MetronomeSound: String, Codable, CaseIterable, Identifiable {
    case click = "Click"
    case beep = "Beep"
    case woodblock = "Woodblock"
    case drumStick = "Drum Stick"
    case cowbell = "Cowbell"
    case rim = "Rim Shot"
    case hiHat = "Hi-Hat"
    case clave = "Clave"
    case custom = "Custom"

    var id: String { rawValue }

    var filename: String {
        switch self {
        case .click: return "metronome_click.wav"
        case .beep: return "metronome_beep.wav"
        case .woodblock: return "metronome_woodblock.wav"
        case .drumStick: return "metronome_stick.wav"
        case .cowbell: return "metronome_cowbell.wav"
        case .rim: return "metronome_rim.wav"
        case .hiHat: return "metronome_hihat.wav"
        case .clave: return "metronome_clave.wav"
        case .custom: return "custom_click.wav"
        }
    }

    var icon: String {
        switch self {
        case .click: return "speaker.wave.2"
        case .beep: return "waveform"
        case .woodblock: return "cube"
        case .drumStick: return "wand.and.rays"
        case .cowbell: return "bell"
        case .rim: return "circle"
        case .hiHat: return "circle.hexagongrid"
        case .clave: return "rectangle.split.2x1"
        case .custom: return "music.note"
        }
    }
}

// MARK: - Visual Metronome Style

/// Visual metronome display styles
enum VisualMetronomeStyle: String, Codable, CaseIterable {
    case circle = "Circle Pulse"
    case bar = "Progress Bar"
    case pendulum = "Pendulum"
    case flash = "Screen Flash"
    case bouncing = "Bouncing Ball"
    case rotating = "Rotating Dial"

    var icon: String {
        switch self {
        case .circle: return "circle"
        case .bar: return "rectangle.fill"
        case .pendulum: return "arrow.down.circle"
        case .flash: return "flashlight.on.fill"
        case .bouncing: return "circle.fill"
        case .rotating: return "arrow.clockwise.circle"
        }
    }

    var description: String {
        switch self {
        case .circle: return "Pulsing circle that changes size"
        case .bar: return "Progress bar moving across beats"
        case .pendulum: return "Swinging pendulum animation"
        case .flash: return "Full screen flash on beats"
        case .bouncing: return "Ball bouncing with tempo"
        case .rotating: return "Rotating dial like clock"
        }
    }
}

// MARK: - Metronome Configuration

/// Complete metronome configuration
struct MetronomeConfig: Codable {
    var tempo: Int // BPM
    var timeSignature: TimeSignature
    var subdivision: Subdivision
    var accentPattern: AccentPattern
    var sound: MetronomeSound
    var accentSound: MetronomeSound
    var volume: Float // 0.0 - 1.0
    var accentVolume: Float
    var countIn: CountInConfig
    var tempoTrainer: TempoTrainer?
    var visualStyle: VisualMetronomeStyle
    var visualEnabled: Bool

    // Audio routing
    var outputDevice: String? // Device ID for routing
    var mixWithBacking: Bool // Mix click with backing track

    init(
        tempo: Int = 120,
        timeSignature: TimeSignature = .common,
        subdivision: Subdivision = .quarter,
        accentPattern: AccentPattern = .downbeat,
        sound: MetronomeSound = .click,
        accentSound: MetronomeSound = .woodblock,
        volume: Float = 0.7,
        accentVolume: Float = 0.9,
        countIn: CountInConfig = CountInConfig(),
        tempoTrainer: TempoTrainer? = nil,
        visualStyle: VisualMetronomeStyle = .circle,
        visualEnabled: Bool = true,
        outputDevice: String? = nil,
        mixWithBacking: Bool = true
    ) {
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.subdivision = subdivision
        self.accentPattern = accentPattern
        self.sound = sound
        self.accentSound = accentSound
        self.volume = volume
        self.accentVolume = accentVolume
        self.countIn = countIn
        self.tempoTrainer = tempoTrainer
        self.visualStyle = visualStyle
        self.visualEnabled = visualEnabled
        self.outputDevice = outputDevice
        self.mixWithBacking = mixWithBacking
    }

    var beatsPerMinute: Int {
        tempo
    }

    var millisecondsPerBeat: Double {
        60000.0 / Double(tempo)
    }

    var secondsPerBeat: Double {
        60.0 / Double(tempo)
    }
}

// MARK: - Click Track Export

/// Configuration for exporting click track as audio
struct ClickTrackExportConfig: Codable {
    var format: AudioFormat
    var duration: TimeInterval? // nil = match song duration
    var includeCountIn: Bool
    var tempoMap: [TempoChange]? // For tempo changes
    var fadeOut: TimeInterval // Fade out duration

    init(
        format: AudioFormat = .wav,
        duration: TimeInterval? = nil,
        includeCountIn: Bool = true,
        tempoMap: [TempoChange]? = nil,
        fadeOut: TimeInterval = 1.0
    ) {
        self.format = format
        self.duration = duration
        self.includeCountIn = includeCountIn
        self.tempoMap = tempoMap
        self.fadeOut = fadeOut
    }
}

/// Tempo change point for tempo maps
struct TempoChange: Codable, Identifiable {
    var id: UUID
    var position: TimeInterval // Position in seconds
    var tempo: Int // New tempo BPM
    var rampDuration: TimeInterval? // Gradual change over time

    init(
        id: UUID = UUID(),
        position: TimeInterval,
        tempo: Int,
        rampDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.position = position
        self.tempo = tempo
        self.rampDuration = rampDuration
    }
}

// MARK: - Metronome Practice Session

/// Saved metronome practice session with tempo progression
struct MetronomeMetronomePracticeSession: Identifiable, Codable {
    var id: UUID
    var name: String
    var songId: UUID?
    var date: Date
    var startTempo: Int
    var endTempo: Int
    var tempoChanges: [Int] // Tempo at each interval
    var duration: TimeInterval
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        songId: UUID? = nil,
        date: Date = Date(),
        startTempo: Int,
        endTempo: Int,
        tempoChanges: [Int] = [],
        duration: TimeInterval,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.songId = songId
        self.date = date
        self.startTempo = startTempo
        self.endTempo = endTempo
        self.tempoChanges = tempoChanges
        self.duration = duration
        self.notes = notes
    }

    var averageTempo: Int {
        guard !tempoChanges.isEmpty else { return (startTempo + endTempo) / 2 }
        return tempoChanges.reduce(0, +) / tempoChanges.count
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

// MARK: - Metronome State

/// Current state of metronome
enum MetronomeState: String, Codable {
    case stopped = "Stopped"
    case playing = "Playing"
    case countingIn = "Counting In"
    case paused = "Paused"

    var icon: String {
        switch self {
        case .stopped: return "stop.fill"
        case .playing: return "metronome.fill"
        case .countingIn: return "timer"
        case .paused: return "pause.fill"
        }
    }

    var color: Color {
        switch self {
        case .stopped: return .gray
        case .playing: return .green
        case .countingIn: return .orange
        case .paused: return .yellow
        }
    }
}

// MARK: - Mixed Meter

/// Support for mixed/alternating meters
struct MixedMeter: Codable, Identifiable {
    var id: UUID
    var name: String
    var meters: [TimeSignature] // Alternating time signatures
    var currentIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        meters: [TimeSignature],
        currentIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.meters = meters
        self.currentIndex = currentIndex
    }

    var currentMeter: TimeSignature {
        meters[currentIndex % meters.count]
    }

    mutating func advance() {
        currentIndex = (currentIndex + 1) % meters.count
    }

    // Common mixed meters
    static var fiveFour: MixedMeter {
        MixedMeter(
            name: "5/4 (alternating 3+2)",
            meters: [
                TimeSignature(beatsPerBar: 3, noteValue: 4),
                TimeSignature(beatsPerBar: 2, noteValue: 4)
            ]
        )
    }

    static var sevenEight: MixedMeter {
        MixedMeter(
            name: "7/8 (alternating 3+2+2)",
            meters: [
                TimeSignature(beatsPerBar: 3, noteValue: 8),
                TimeSignature(beatsPerBar: 2, noteValue: 8),
                TimeSignature(beatsPerBar: 2, noteValue: 8)
            ]
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let metronomeStateChanged = Notification.Name("metronomeStateChanged")
    static let metronomeBeatTick = Notification.Name("metronomeBeatTick")
    static let metronomeTempoChanged = Notification.Name("metronomeTempoChanged")
    static let metronomeCountInComplete = Notification.Name("metronomeCountInComplete")
    static let metronomeTrainerIncreased = Notification.Name("metronomeTrainerIncreased")
    static let metronomeTrainerComplete = Notification.Name("metronomeTrainerComplete")
}
