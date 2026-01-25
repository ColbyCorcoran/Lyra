//
//  ChordDetection.swift
//  Lyra
//
//  Models for AI-powered chord detection from audio files
//  Part of Phase 7: Audio Intelligence
//

import Foundation
import SwiftUI

// MARK: - Detected Chord

/// A chord detected at a specific time position in an audio file
struct DetectedChord: Identifiable, Codable {
    var id: UUID
    var chord: String // e.g., "C", "Dm", "G7", "Cmaj7"
    var position: TimeInterval // Position in audio file (seconds)
    var duration: TimeInterval // Duration until next chord change
    var confidence: Float // 0.0 - 1.0 confidence score
    var alternativeChords: [AlternativeChord] // Other possible chords
    var notes: [String] // Individual notes detected
    var isUserCorrected: Bool // User manually corrected this chord

    init(
        id: UUID = UUID(),
        chord: String,
        position: TimeInterval,
        duration: TimeInterval = 0,
        confidence: Float = 0.0,
        alternativeChords: [AlternativeChord] = [],
        notes: [String] = [],
        isUserCorrected: Bool = false
    ) {
        self.id = id
        self.chord = chord
        self.position = position
        self.duration = duration
        self.confidence = confidence
        self.alternativeChords = alternativeChords
        self.notes = notes
        self.isUserCorrected = isUserCorrected
    }

    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0..<0.5: return .low
        case 0.5..<0.75: return .medium
        case 0.75...1.0: return .high
        default: return .low
        }
    }

    var formattedPosition: String {
        let minutes = Int(position) / 60
        let seconds = Int(position) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDuration: String {
        String(format: "%.1fs", duration)
    }
}

// MARK: - Alternative Chord

/// Alternative chord suggestion with lower confidence
struct AlternativeChord: Identifiable, Codable {
    var id: UUID
    var chord: String
    var confidence: Float

    init(
        id: UUID = UUID(),
        chord: String,
        confidence: Float
    ) {
        self.id = id
        self.chord = chord
        self.confidence = confidence
    }
}

// MARK: - Confidence Level

enum ConfidenceLevel: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .red
        case .medium: return .orange
        case .high: return .green
        }
    }

    var icon: String {
        switch self {
        case .low: return "exclamationmark.triangle.fill"
        case .medium: return "checkmark.circle"
        case .high: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Detection Session

/// A chord detection session for an audio file
struct ChordDetectionSession: Identifiable, Codable {
    var id: UUID
    var audioFileURL: URL?
    var audioFileName: String
    var detectedChords: [DetectedChord]
    var tempo: Float? // BPM
    var timeSignature: String? // e.g., "4/4"
    var detectedKey: String? // e.g., "C major", "Am"
    var suggestedCapo: Int? // Capo position (0 = no capo)
    var sections: [DetectedSection]
    var quality: DetectionQuality
    var status: DetectionStatus
    var progress: Float // 0.0 - 1.0
    var dateCreated: Date
    var processingTime: TimeInterval? // How long analysis took

    init(
        id: UUID = UUID(),
        audioFileURL: URL? = nil,
        audioFileName: String,
        detectedChords: [DetectedChord] = [],
        tempo: Float? = nil,
        timeSignature: String? = nil,
        detectedKey: String? = nil,
        suggestedCapo: Int? = nil,
        sections: [DetectedSection] = [],
        quality: DetectionQuality = .balanced,
        status: DetectionStatus = .pending,
        progress: Float = 0.0,
        dateCreated: Date = Date(),
        processingTime: TimeInterval? = nil
    ) {
        self.id = id
        self.audioFileURL = audioFileURL
        self.audioFileName = audioFileName
        self.detectedChords = detectedChords
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.detectedKey = detectedKey
        self.suggestedCapo = suggestedCapo
        self.sections = sections
        self.quality = quality
        self.status = status
        self.progress = progress
        self.dateCreated = dateCreated
        self.processingTime = processingTime
    }

    var formattedTempo: String {
        guard let tempo = tempo else { return "Unknown" }
        return String(format: "%.0f BPM", tempo)
    }

    var formattedProcessingTime: String {
        guard let time = processingTime else { return "N/A" }
        return String(format: "%.1fs", time)
    }

    var averageConfidence: Float {
        guard !detectedChords.isEmpty else { return 0 }
        let total = detectedChords.reduce(0.0) { $0 + $1.confidence }
        return total / Float(detectedChords.count)
    }

    var lowConfidenceCount: Int {
        detectedChords.filter { $0.confidenceLevel == .low }.count
    }
}

// MARK: - Detected Section

/// A detected section in the song (verse, chorus, etc.)
struct DetectedSection: Identifiable, Codable {
    var id: UUID
    var type: SectionType
    var startPosition: TimeInterval
    var endPosition: TimeInterval
    var chordPattern: [String] // The chord progression
    var confidence: Float
    var isUserLabeled: Bool // User manually labeled this section

    init(
        id: UUID = UUID(),
        type: SectionType = .verse,
        startPosition: TimeInterval,
        endPosition: TimeInterval,
        chordPattern: [String] = [],
        confidence: Float = 0.0,
        isUserLabeled: Bool = false
    ) {
        self.id = id
        self.type = type
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.chordPattern = chordPattern
        self.confidence = confidence
        self.isUserLabeled = isUserLabeled
    }

    var duration: TimeInterval {
        endPosition - startPosition
    }

    var formattedDuration: String {
        String(format: "%.1fs", duration)
    }
}

// MARK: - Detection Quality

enum DetectionQuality: String, Codable, CaseIterable {
    case quickScan = "Quick Scan"
    case balanced = "Balanced"
    case detailed = "Detailed Analysis"

    var description: String {
        switch self {
        case .quickScan:
            return "Fast processing, lower accuracy. Good for previews."
        case .balanced:
            return "Balanced speed and accuracy. Recommended for most use cases."
        case .detailed:
            return "Highest accuracy, slower processing. Best for complex songs."
        }
    }

    var icon: String {
        switch self {
        case .quickScan: return "bolt.fill"
        case .balanced: return "scale.3d"
        case .detailed: return "sparkles"
        }
    }

    var analysisWindow: TimeInterval {
        switch self {
        case .quickScan: return 2.0 // 2 second windows
        case .balanced: return 1.0 // 1 second windows
        case .detailed: return 0.5 // 0.5 second windows
        }
    }

    var fftSize: Int {
        switch self {
        case .quickScan: return 2048
        case .balanced: return 4096
        case .detailed: return 8192
        }
    }
}

// MARK: - Detection Status

enum DetectionStatus: String, Codable {
    case pending = "Pending"
    case analyzing = "Analyzing..."
    case detectingChords = "Detecting Chords"
    case detectingTempo = "Detecting Tempo"
    case detectingSections = "Detecting Sections"
    case detectingKey = "Detecting Key"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .analyzing, .detectingChords, .detectingTempo, .detectingSections, .detectingKey:
            return "waveform.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .analyzing, .detectingChords, .detectingTempo, .detectingSections, .detectingKey:
            return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        }
    }
}

// MARK: - Audio Analysis Result

/// Result from FFT analysis of audio segment
struct AudioAnalysisResult {
    var timestamp: TimeInterval
    var frequencies: [Float] // Frequency values (Hz)
    var magnitudes: [Float] // Magnitude for each frequency
    var dominantFrequencies: [Float] // Top N frequencies
    var notes: [DetectedNote] // Detected musical notes

    init(
        timestamp: TimeInterval,
        frequencies: [Float] = [],
        magnitudes: [Float] = [],
        dominantFrequencies: [Float] = [],
        notes: [DetectedNote] = []
    ) {
        self.timestamp = timestamp
        self.frequencies = frequencies
        self.magnitudes = magnitudes
        self.dominantFrequencies = dominantFrequencies
        self.notes = notes
    }
}

// MARK: - Detected Note

/// A musical note detected in audio
struct DetectedNote: Identifiable {
    var id: UUID
    var note: String // e.g., "C", "D#", "Bb"
    var octave: Int
    var frequency: Float // Hz
    var magnitude: Float // Strength of the note
    var confidence: Float

    init(
        id: UUID = UUID(),
        note: String,
        octave: Int,
        frequency: Float,
        magnitude: Float,
        confidence: Float
    ) {
        self.id = id
        self.note = note
        self.octave = octave
        self.frequency = frequency
        self.magnitude = magnitude
        self.confidence = confidence
    }

    var fullNoteName: String {
        "\(note)\(octave)"
    }
}

// MARK: - Tempo Detection Result

struct TempoDetectionResult {
    var bpm: Float
    var confidence: Float
    var beatPositions: [TimeInterval] // Detected beat positions
    var timeSignature: String?
    var barLines: [TimeInterval] // Detected bar line positions

    init(
        bpm: Float,
        confidence: Float,
        beatPositions: [TimeInterval] = [],
        timeSignature: String? = nil,
        barLines: [TimeInterval] = []
    ) {
        self.bpm = bpm
        self.confidence = confidence
        self.beatPositions = beatPositions
        self.timeSignature = timeSignature
        self.barLines = barLines
    }
}

// MARK: - Key Detection Result

struct ChordBasedKeyDetection {
    var key: String // e.g., "C", "Am", "Eb"
    var scale: ScaleType // Major or Minor
    var confidence: Float
    var alternativeKeys: [(key: String, scale: ScaleType, confidence: Float)]

    init(
        key: String,
        scale: ScaleType,
        confidence: Float,
        alternativeKeys: [(key: String, scale: ScaleType, confidence: Float)] = []
    ) {
        self.key = key
        self.scale = scale
        self.confidence = confidence
        self.alternativeKeys = alternativeKeys
    }

    var fullKeyName: String {
        "\(key) \(scale.rawValue)"
    }
}

enum ScaleType: String, Codable {
    case major = "Major"
    case minor = "Minor"
}

// MARK: - Chord Inversion

enum ChordInversion: String, Codable {
    case root = "Root Position"
    case firstInversion = "1st Inversion"
    case secondInversion = "2nd Inversion"
    case thirdInversion = "3rd Inversion"

    var symbol: String {
        switch self {
        case .root: return ""
        case .firstInversion: return "/1"
        case .secondInversion: return "/2"
        case .thirdInversion: return "/3"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let chordDetectionStarted = Notification.Name("chordDetectionStarted")
    static let chordDetectionProgress = Notification.Name("chordDetectionProgress")
    static let chordDetectionCompleted = Notification.Name("chordDetectionCompleted")
    static let chordDetectionFailed = Notification.Name("chordDetectionFailed")
    static let chordCorrected = Notification.Name("chordCorrected")
}
