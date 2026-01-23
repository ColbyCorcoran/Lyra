//
//  BackingTrack.swift
//  Lyra
//
//  Models for backing track playback system
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - Audio Track

/// Audio track attached to a song
struct AudioTrack: Identifiable, Codable {
    var id: UUID
    var name: String
    var filename: String // Local filename or cloud path
    var fileURL: URL? // Computed or stored
    var type: AudioTrackType
    var format: AudioFormat

    // Playback settings
    var volume: Float // 0.0 - 1.0
    var pan: Float // -1.0 (left) to 1.0 (right)
    var isMuted: Bool
    var isSolo: Bool
    var playbackRate: Float // 0.5 - 2.0

    // Timing
    var duration: TimeInterval
    var startOffset: TimeInterval // Delay before starting
    var endTrim: TimeInterval // Trim from end

    // Sync
    var syncWithAutoscroll: Bool
    var autoscrollDuration: TimeInterval? // Override song autoscroll

    // Effects
    var fadeInDuration: TimeInterval
    var fadeOutDuration: TimeInterval
    var eq: EQSettings
    var compression: CompressionSettings?

    // Markers
    var markers: [AudioMarker]

    // Metadata
    var dateAdded: Date
    var fileSize: Int64? // Bytes
    var sampleRate: Double?
    var bitDepth: Int?
    var channels: Int? // 1 = mono, 2 = stereo

    init(
        id: UUID = UUID(),
        name: String,
        filename: String,
        fileURL: URL? = nil,
        type: AudioTrackType = .backing,
        format: AudioFormat = .mp3,
        volume: Float = 0.8,
        pan: Float = 0.0,
        isMuted: Bool = false,
        isSolo: Bool = false,
        playbackRate: Float = 1.0,
        duration: TimeInterval = 0,
        startOffset: TimeInterval = 0,
        endTrim: TimeInterval = 0,
        syncWithAutoscroll: Bool = false,
        autoscrollDuration: TimeInterval? = nil,
        fadeInDuration: TimeInterval = 0,
        fadeOutDuration: TimeInterval = 0,
        eq: EQSettings = EQSettings(),
        compression: CompressionSettings? = nil,
        markers: [AudioMarker] = [],
        dateAdded: Date = Date(),
        fileSize: Int64? = nil,
        sampleRate: Double? = nil,
        bitDepth: Int? = nil,
        channels: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.filename = filename
        self.fileURL = fileURL
        self.type = type
        self.format = format
        self.volume = volume
        self.pan = pan
        self.isMuted = isMuted
        self.isSolo = isSolo
        self.playbackRate = playbackRate
        self.duration = duration
        self.startOffset = startOffset
        self.endTrim = endTrim
        self.syncWithAutoscroll = syncWithAutoscroll
        self.autoscrollDuration = autoscrollDuration
        self.fadeInDuration = fadeInDuration
        self.fadeOutDuration = fadeOutDuration
        self.eq = eq
        self.compression = compression
        self.markers = markers
        self.dateAdded = dateAdded
        self.fileSize = fileSize
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.channels = channels
    }

    var effectiveDuration: TimeInterval {
        max(0, duration - startOffset - endTrim)
    }

    var formattedDuration: String {
        formatTime(effectiveDuration)
    }

    var formattedFileSize: String {
        guard let size = fileSize else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var qualityDescription: String {
        guard let sampleRate = sampleRate else { return "Unknown" }
        let khz = Int(sampleRate / 1000)
        let bit = bitDepth ?? 0
        let ch = channels == 1 ? "Mono" : "Stereo"
        return "\(khz)kHz • \(bit)-bit • \(ch)"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum AudioTrackType: String, Codable, CaseIterable {
    case backing = "Backing Track"
    case click = "Click Track"
    case vocals = "Backing Vocals"
    case instrument = "Instrument"
    case drums = "Drums"
    case bass = "Bass"
    case guitar = "Guitar"
    case keys = "Keys"
    case strings = "Strings"
    case other = "Other"

    var icon: String {
        switch self {
        case .backing: return "waveform"
        case .click: return "metronome"
        case .vocals: return "mic"
        case .instrument: return "music.note"
        case .drums: return "circle.hexagongrid.fill"
        case .bass: return "waveform.path"
        case .guitar: return "guitars"
        case .keys: return "pianokeys"
        case .strings: return "music.quarternote.3"
        case .other: return "waveform.circle"
        }
    }

    var color: Color {
        switch self {
        case .backing: return .blue
        case .click: return .orange
        case .vocals: return .purple
        case .instrument: return .green
        case .drums: return .red
        case .bass: return .cyan
        case .guitar: return .yellow
        case .keys: return .pink
        case .strings: return .mint
        case .other: return .gray
        }
    }
}

enum AudioFormat: String, Codable, CaseIterable {
    case mp3 = "MP3"
    case m4a = "M4A"
    case wav = "WAV"
    case aiff = "AIFF"
    case caf = "CAF"
    case flac = "FLAC"

    var fileExtension: String {
        rawValue.lowercased()
    }

    var mimeType: String {
        switch self {
        case .mp3: return "audio/mpeg"
        case .m4a: return "audio/mp4"
        case .wav: return "audio/wav"
        case .aiff: return "audio/aiff"
        case .caf: return "audio/x-caf"
        case .flac: return "audio/flac"
        }
    }
}

// MARK: - Audio Marker

/// Marker/cue point in audio track
struct AudioMarker: Identifiable, Codable {
    var id: UUID
    var name: String
    var position: TimeInterval // Position in track
    var type: MarkerType
    var color: String // Hex color
    var action: MarkerAction?
    var sectionName: String? // Link to song section

    init(
        id: UUID = UUID(),
        name: String,
        position: TimeInterval,
        type: MarkerType = .cue,
        color: String = "#FF0000",
        action: MarkerAction? = nil,
        sectionName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.position = position
        self.type = type
        self.color = color
        self.action = action
        self.sectionName = sectionName
    }

    var formattedPosition: String {
        let minutes = Int(position) / 60
        let seconds = Int(position) % 60
        let milliseconds = Int((position.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

enum MarkerType: String, Codable, CaseIterable {
    case cue = "Cue"
    case section = "Section"
    case warning = "Warning"
    case ending = "Ending"
    case loop = "Loop Point"
    case sync = "Sync Point"

    var icon: String {
        switch self {
        case .cue: return "flag.fill"
        case .section: return "music.note.list"
        case .warning: return "exclamationmark.triangle.fill"
        case .ending: return "stop.fill"
        case .loop: return "repeat"
        case .sync: return "arrow.triangle.2.circlepath"
        }
    }
}

enum MarkerAction: String, Codable {
    case jumpToSection = "Jump to Section"
    case showMessage = "Show Message"
    case triggerMIDI = "Trigger MIDI"
    case changeDisplay = "Change Display"
    case advanceSong = "Advance Song"
    case blankScreen = "Blank Screen"
}

// MARK: - Mixer Settings

/// Per-song mixer configuration
struct MixerSettings: Codable {
    var masterVolume: Float // 0.0 - 1.0
    var masterMute: Bool
    var trackSettings: [UUID: TrackMixerSettings] // Track ID -> Settings

    init(
        masterVolume: Float = 0.8,
        masterMute: Bool = false,
        trackSettings: [UUID: TrackMixerSettings] = [:]
    ) {
        self.masterVolume = masterVolume
        self.masterMute = masterMute
        self.trackSettings = trackSettings
    }
}

struct TrackMixerSettings: Codable {
    var volume: Float
    var pan: Float
    var mute: Bool
    var solo: Bool

    init(
        volume: Float = 0.8,
        pan: Float = 0.0,
        mute: Bool = false,
        solo: Bool = false
    ) {
        self.volume = volume
        self.pan = pan
        self.mute = mute
        self.solo = solo
    }
}

// MARK: - EQ Settings

struct EQSettings: Codable {
    var isEnabled: Bool
    var bass: Float // -12 to +12 dB
    var mid: Float
    var treble: Float
    var frequency: Float // Center frequency for mid

    init(
        isEnabled: Bool = false,
        bass: Float = 0,
        mid: Float = 0,
        treble: Float = 0,
        frequency: Float = 1000 // 1kHz
    ) {
        self.isEnabled = isEnabled
        self.bass = bass
        self.mid = mid
        self.treble = treble
        self.frequency = frequency
    }

    static var flat: EQSettings {
        EQSettings()
    }

    static var bassBoost: EQSettings {
        EQSettings(isEnabled: true, bass: 6, mid: 0, treble: -2)
    }

    static var trebleBoost: EQSettings {
        EQSettings(isEnabled: true, bass: -2, mid: 0, treble: 6)
    }

    static var vocal: EQSettings {
        EQSettings(isEnabled: true, bass: -3, mid: 3, treble: 2)
    }
}

// MARK: - Compression Settings

struct CompressionSettings: Codable {
    var isEnabled: Bool
    var threshold: Float // dB
    var ratio: Float // 1:1 to 20:1
    var attack: TimeInterval // seconds
    var release: TimeInterval // seconds
    var makeupGain: Float // dB

    init(
        isEnabled: Bool = false,
        threshold: Float = -20,
        ratio: Float = 4.0,
        attack: TimeInterval = 0.003,
        release: TimeInterval = 0.1,
        makeupGain: Float = 0
    ) {
        self.isEnabled = isEnabled
        self.threshold = threshold
        self.ratio = ratio
        self.attack = attack
        self.release = release
        self.makeupGain = makeupGain
    }

    static var gentle: CompressionSettings {
        CompressionSettings(isEnabled: true, threshold: -15, ratio: 2.0)
    }

    static var moderate: CompressionSettings {
        CompressionSettings(isEnabled: true, threshold: -20, ratio: 4.0)
    }

    static var heavy: CompressionSettings {
        CompressionSettings(isEnabled: true, threshold: -25, ratio: 8.0)
    }
}

// MARK: - Audio Routing

/// Audio routing configuration
struct AudioRoutingConfig: Codable {
    var mainOutput: AudioOutputDevice
    var clickOutput: AudioOutputDevice? // Separate output for click track
    var enableMultiRouting: Bool
    var routingMap: [AudioTrackType: String] // Track type -> Output device ID

    init(
        mainOutput: AudioOutputDevice = .defaultOutput,
        clickOutput: AudioOutputDevice? = nil,
        enableMultiRouting: Bool = false,
        routingMap: [AudioTrackType: String] = [:]
    ) {
        self.mainOutput = mainOutput
        self.clickOutput = clickOutput
        self.enableMultiRouting = enableMultiRouting
        self.routingMap = routingMap
    }
}

enum AudioOutputDevice: Codable {
    case defaultOutput
    case builtInSpeaker
    case headphones
    case bluetooth(name: String)
    case airPlay(name: String)
    case usb(name: String)
    case custom(id: String, name: String)

    var displayName: String {
        switch self {
        case .defaultOutput: return "Default Output"
        case .builtInSpeaker: return "Built-in Speaker"
        case .headphones: return "Headphones"
        case .bluetooth(let name): return "Bluetooth: \(name)"
        case .airPlay(let name): return "AirPlay: \(name)"
        case .usb(let name): return "USB: \(name)"
        case .custom(_, let name): return name
        }
    }

    var icon: String {
        switch self {
        case .defaultOutput: return "speaker.wave.2"
        case .builtInSpeaker: return "iphone.radiowaves.left.and.right"
        case .headphones: return "headphones"
        case .bluetooth: return "beats.headphones"
        case .airPlay: return "airplayaudio"
        case .usb: return "cable.connector"
        case .custom: return "speaker.2"
        }
    }
}

// MARK: - Playback State

/// Playback state for UI
enum PlaybackState: String, Codable {
    case stopped = "Stopped"
    case playing = "Playing"
    case paused = "Paused"
    case loading = "Loading"
    case error = "Error"

    var icon: String {
        switch self {
        case .stopped: return "stop.fill"
        case .playing: return "play.fill"
        case .paused: return "pause.fill"
        case .loading: return "arrow.clockwise"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .stopped: return .gray
        case .playing: return .green
        case .paused: return .orange
        case .loading: return .blue
        case .error: return .red
        }
    }
}

// MARK: - Audio Session Configuration

struct AudioSessionConfig: Codable {
    var category: AudioSessionCategory
    var allowsBluetoothA2DP: Bool
    var allowsAirPlay: Bool
    var mixWithOthers: Bool
    var duckOthers: Bool

    init(
        category: AudioSessionCategory = .playback,
        allowsBluetoothA2DP: Bool = true,
        allowsAirPlay: Bool = true,
        mixWithOthers: Bool = false,
        duckOthers: Bool = false
    ) {
        self.category = category
        self.allowsBluetoothA2DP = allowsBluetoothA2DP
        self.allowsAirPlay = allowsAirPlay
        self.mixWithOthers = mixWithOthers
        self.duckOthers = duckOthers
    }
}

enum AudioSessionCategory: String, Codable {
    case playback = "Playback"
    case playAndRecord = "Play and Record"
    case record = "Record"
    case multiRoute = "Multi-Route"

    var avCategory: AVAudioSession.Category {
        switch self {
        case .playback: return .playback
        case .playAndRecord: return .playAndRecord
        case .record: return .record
        case .multiRoute: return .multiRoute
        }
    }
}

// MARK: - Crossfade Settings

struct CrossfadeSettings: Codable {
    var isEnabled: Bool
    var duration: TimeInterval // seconds
    var curve: CrossfadeCurve

    init(
        isEnabled: Bool = false,
        duration: TimeInterval = 2.0,
        curve: CrossfadeCurve = .equalPower
    ) {
        self.isEnabled = isEnabled
        self.duration = duration
        self.curve = curve
    }
}

enum CrossfadeCurve: String, Codable {
    case linear = "Linear"
    case equalPower = "Equal Power"
    case exponential = "Exponential"
    case sCurve = "S-Curve"
}

// MARK: - Notifications

extension Notification.Name {
    static let audioTrackLoaded = Notification.Name("audioTrackLoaded")
    static let audioPlaybackStateChanged = Notification.Name("audioPlaybackStateChanged")
    static let audioPositionChanged = Notification.Name("audioPositionChanged")
    static let audioMarkerReached = Notification.Name("audioMarkerReached")
    static let audioTrackEnded = Notification.Name("audioTrackEnded")
    static let audioMixerChanged = Notification.Name("audioMixerChanged")
    static let audioRoutingChanged = Notification.Name("audioRoutingChanged")
}
