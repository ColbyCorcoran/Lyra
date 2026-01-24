//
//  KeyRecommendation.swift
//  Lyra
//
//  Models for intelligent key detection and recommendation
//  Part of Phase 7.3: Key Intelligence
//

import Foundation
import SwiftUI

// MARK: - Key Recommendation

/// A recommended key for a song with reasoning
struct KeyRecommendation: Identifiable, Codable {
    var id: UUID
    var key: String
    var scale: ScaleType
    var confidence: Float // 0.0 - 1.0
    var reasons: [RecommendationReason]
    var vocalRangeFit: VocalRangeFit?
    var capoDifficulty: CapoDifficulty?
    var transpositionSteps: Int // Semitones from original

    init(
        id: UUID = UUID(),
        key: String,
        scale: ScaleType,
        confidence: Float,
        reasons: [RecommendationReason] = [],
        vocalRangeFit: VocalRangeFit? = nil,
        capoDifficulty: CapoDifficulty? = nil,
        transpositionSteps: Int = 0
    ) {
        self.id = id
        self.key = key
        self.scale = scale
        self.confidence = confidence
        self.reasons = reasons
        self.vocalRangeFit = vocalRangeFit
        self.capoDifficulty = capoDifficulty
        self.transpositionSteps = transpositionSteps
    }

    var fullKeyName: String {
        "\(key) \(scale.rawValue)"
    }
}

enum RecommendationReason: String, Codable {
    case detectedFromChords = "Detected from chord progression"
    case vocalRangeOptimal = "Perfect for your vocal range"
    case easyGuitarKey = "Easy guitar key"
    case capoAvailable = "Capo position available"
    case userPreference = "Matches your preferences"
    case commonKey = "Common, well-known key"
    case setCompatibility = "Compatible with other songs in set"
    case modallyStable = "Clear tonal center"

    var icon: String {
        switch self {
        case .detectedFromChords: return "music.note.list"
        case .vocalRangeOptimal: return "mic.fill"
        case .easyGuitarKey: return "guitars"
        case .capoAvailable: return "bookmark.fill"
        case .userPreference: return "person.fill"
        case .commonKey: return "star.fill"
        case .setCompatibility: return "list.bullet"
        case .modallyStable: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .detectedFromChords: return .blue
        case .vocalRangeOptimal: return .green
        case .easyGuitarKey: return .orange
        case .capoAvailable: return .purple
        case .userPreference: return .pink
        case .commonKey: return .yellow
        case .setCompatibility: return .cyan
        case .modallyStable: return .indigo
        }
    }
}

// MARK: - Vocal Range

/// User's vocal range
struct VocalRange: Codable {
    var lowestNote: MusicalNote
    var highestNote: MusicalNote
    var comfortableLowest: MusicalNote?
    var comfortableHighest: MusicalNote?
    var voiceType: VoiceType?
    var dateRecorded: Date

    init(
        lowestNote: MusicalNote,
        highestNote: MusicalNote,
        comfortableLowest: MusicalNote? = nil,
        comfortableHighest: MusicalNote? = nil,
        voiceType: VoiceType? = nil,
        dateRecorded: Date = Date()
    ) {
        self.lowestNote = lowestNote
        self.highestNote = highestNote
        self.comfortableLowest = comfortableLowest
        self.comfortableHighest = comfortableHighest
        self.voiceType = voiceType
        self.dateRecorded = dateRecorded
    }

    var rangeInSemitones: Int {
        highestNote.midiNumber - lowestNote.midiNumber
    }

    var description: String {
        "\(lowestNote.name) to \(highestNote.name) (\(rangeInSemitones) semitones)"
    }
}

struct MusicalNote: Codable, Equatable {
    var note: String // e.g., "C", "D#"
    var octave: Int // 0-8

    var name: String {
        "\(note)\(octave)"
    }

    var midiNumber: Int {
        let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        guard let noteIndex = chromaticScale.firstIndex(of: note) else { return 0 }
        return (octave + 1) * 12 + noteIndex
    }

    static func fromMIDI(_ midiNumber: Int) -> MusicalNote {
        let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteIndex = midiNumber % 12
        let octave = (midiNumber / 12) - 1
        return MusicalNote(note: chromaticScale[noteIndex], octave: octave)
    }
}

enum VoiceType: String, Codable, CaseIterable {
    case soprano = "Soprano"
    case mezzo = "Mezzo-Soprano"
    case alto = "Alto"
    case tenor = "Tenor"
    case baritone = "Baritone"
    case bass = "Bass"

    var typicalRange: VocalRange {
        switch self {
        case .soprano:
            return VocalRange(
                lowestNote: MusicalNote(note: "C", octave: 4),
                highestNote: MusicalNote(note: "C", octave: 6)
            )
        case .mezzo:
            return VocalRange(
                lowestNote: MusicalNote(note: "A", octave: 3),
                highestNote: MusicalNote(note: "A", octave: 5)
            )
        case .alto:
            return VocalRange(
                lowestNote: MusicalNote(note: "F", octave: 3),
                highestNote: MusicalNote(note: "F", octave: 5)
            )
        case .tenor:
            return VocalRange(
                lowestNote: MusicalNote(note: "C", octave: 3),
                highestNote: MusicalNote(note: "C", octave: 5)
            )
        case .baritone:
            return VocalRange(
                lowestNote: MusicalNote(note: "A", octave: 2),
                highestNote: MusicalNote(note: "A", octave: 4)
            )
        case .bass:
            return VocalRange(
                lowestNote: MusicalNote(note: "E", octave: 2),
                highestNote: MusicalNote(note: "E", octave: 4)
            )
        }
    }

    var color: Color {
        switch self {
        case .soprano: return .pink
        case .mezzo: return .purple
        case .alto: return .orange
        case .tenor: return .blue
        case .baritone: return .cyan
        case .bass: return .indigo
        }
    }
}

// MARK: - Vocal Range Fit

/// How well a key fits the user's vocal range
struct VocalRangeFit: Codable {
    var fitsWithinRange: Bool
    var lowestNoteInSong: MusicalNote
    var highestNoteInSong: MusicalNote
    var lowestIsComfortable: Bool
    var highestIsComfortable: Bool
    var semitonesBelowRange: Int? // If too low
    var semitonesAboveRange: Int? // If too high
    var optimalTransposition: Int? // Semitones to transpose for best fit

    var quality: FitQuality {
        if fitsWithinRange && lowestIsComfortable && highestIsComfortable {
            return .perfect
        } else if fitsWithinRange {
            return .good
        } else if let semitones = optimalTransposition, abs(semitones) <= 3 {
            return .needsMinorAdjustment
        } else {
            return .poor
        }
    }
}

enum FitQuality: String, Codable {
    case perfect = "Perfect Fit"
    case good = "Good Fit"
    case needsMinorAdjustment = "Needs Minor Adjustment"
    case poor = "Poor Fit"

    var color: Color {
        switch self {
        case .perfect: return .green
        case .good: return .blue
        case .needsMinorAdjustment: return .orange
        case .poor: return .red
        }
    }

    var icon: String {
        switch self {
        case .perfect: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .needsMinorAdjustment: return "exclamationmark.circle"
        case .poor: return "xmark.circle"
        }
    }
}

// MARK: - Capo Difficulty

/// Analysis of chord difficulty and capo suggestions
struct CapoDifficulty: Codable {
    var originalDifficulty: ChordDifficulty
    var suggestedCapo: Int? // 0-7
    var capoedDifficulty: ChordDifficulty?
    var beforeChords: [String]
    var afterChords: [String]
    var improvementScore: Float // 0.0 - 1.0

    var worthUsing: Bool {
        improvementScore > 0.3
    }
}

enum ChordDifficulty: String, Codable, CaseIterable {
    case veryEasy = "Very Easy"
    case easy = "Easy"
    case moderate = "Moderate"
    case difficult = "Difficult"
    case veryDifficult = "Very Difficult"

    var color: Color {
        switch self {
        case .veryEasy: return .green
        case .easy: return .blue
        case .moderate: return .yellow
        case .difficult: return .orange
        case .veryDifficult: return .red
        }
    }

    var score: Int {
        switch self {
        case .veryEasy: return 1
        case .easy: return 2
        case .moderate: return 3
        case .difficult: return 4
        case .veryDifficult: return 5
        }
    }
}

// MARK: - Key Detection Result

/// Result of auto key detection from chords
struct KeyDetectionResult: Identifiable {
    var id: UUID
    var possibleKeys: [DetectedKey]
    var mostLikelyKey: DetectedKey?
    var modalAmbiguity: Bool
    var explanation: String

    init(
        id: UUID = UUID(),
        possibleKeys: [DetectedKey],
        mostLikelyKey: DetectedKey? = nil,
        modalAmbiguity: Bool = false,
        explanation: String = ""
    ) {
        self.id = id
        self.possibleKeys = possibleKeys
        self.mostLikelyKey = mostLikelyKey
        self.modalAmbiguity = modalAmbiguity
        self.explanation = explanation
    }
}

struct DetectedKey: Identifiable, Codable {
    var id: UUID
    var key: String
    var scale: ScaleType
    var confidence: Float
    var diatonicChordCount: Int
    var chromaticChordCount: Int
    var hasStrongCadences: Bool
    var reasons: [String]

    init(
        id: UUID = UUID(),
        key: String,
        scale: ScaleType,
        confidence: Float,
        diatonicChordCount: Int = 0,
        chromaticChordCount: Int = 0,
        hasStrongCadences: Bool = false,
        reasons: [String] = []
    ) {
        self.id = id
        self.key = key
        self.scale = scale
        self.confidence = confidence
        self.diatonicChordCount = diatonicChordCount
        self.chromaticChordCount = chromaticChordCount
        self.hasStrongCadences = hasStrongCadences
        self.reasons = reasons
    }

    var fullKeyName: String {
        "\(key) \(scale.rawValue)"
    }
}

// MARK: - Key Compatibility

/// Compatibility between two keys for set building
struct KeyCompatibility: Identifiable {
    var id: UUID
    var key1: String
    var key2: String
    var compatibilityScore: Float // 0.0 - 1.0
    var relationship: KeyRelationship
    var transitionDifficulty: TransitionDifficulty
    var suggestedModulation: String?

    init(
        id: UUID = UUID(),
        key1: String,
        key2: String,
        compatibilityScore: Float,
        relationship: KeyRelationship,
        transitionDifficulty: TransitionDifficulty,
        suggestedModulation: String? = nil
    ) {
        self.id = id
        self.key1 = key1
        self.key2 = key2
        self.compatibilityScore = compatibilityScore
        self.relationship = relationship
        self.transitionDifficulty = transitionDifficulty
        self.suggestedModulation = suggestedModulation
    }
}

enum KeyRelationship: String, Codable {
    case same = "Same Key"
    case relative = "Relative Major/Minor"
    case parallel = "Parallel Major/Minor"
    case circleOfFifths = "Circle of Fifths"
    case closeKeys = "Close Keys" // 1-2 semitones apart
    case distantKeys = "Distant Keys"

    var color: Color {
        switch self {
        case .same: return .green
        case .relative: return .blue
        case .parallel: return .cyan
        case .circleOfFifths: return .purple
        case .closeKeys: return .orange
        case .distantKeys: return .red
        }
    }
}

enum TransitionDifficulty: String, Codable {
    case veryEasy = "Very Easy"
    case easy = "Easy"
    case moderate = "Moderate"
    case difficult = "Difficult"

    var color: Color {
        switch self {
        case .veryEasy: return .green
        case .easy: return .blue
        case .moderate: return .orange
        case .difficult: return .red
        }
    }
}

// MARK: - User Key Preferences

/// Learned user preferences for keys
struct UserKeyPreferences: Codable {
    var favoriteKeys: [String: Int] // Key -> Usage count
    var vocalRange: VocalRange?
    var preferredVoiceType: VoiceType?
    var capoUsageFrequency: Float // 0.0 - 1.0
    var averageKeyDifficulty: ChordDifficulty
    var lastUpdated: Date

    init(
        favoriteKeys: [String: Int] = [:],
        vocalRange: VocalRange? = nil,
        preferredVoiceType: VoiceType? = nil,
        capoUsageFrequency: Float = 0.0,
        averageKeyDifficulty: ChordDifficulty = .moderate,
        lastUpdated: Date = Date()
    ) {
        self.favoriteKeys = favoriteKeys
        self.vocalRange = vocalRange
        self.preferredVoiceType = preferredVoiceType
        self.capoUsageFrequency = capoUsageFrequency
        self.averageKeyDifficulty = averageKeyDifficulty
        self.lastUpdated = lastUpdated
    }

    var mostUsedKey: String? {
        favoriteKeys.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Song Range Analysis

/// Analysis of note range in a song
struct SongRangeAnalysis: Identifiable {
    var id: UUID
    var lowestNote: MusicalNote
    var highestNote: MusicalNote
    var rangeInSemitones: Int
    var vocalRangeFit: VocalRangeFit?
    var suggestedTranspositions: [Int] // Semitones

    init(
        id: UUID = UUID(),
        lowestNote: MusicalNote,
        highestNote: MusicalNote,
        rangeInSemitones: Int,
        vocalRangeFit: VocalRangeFit? = nil,
        suggestedTranspositions: [Int] = []
    ) {
        self.id = id
        self.lowestNote = lowestNote
        self.highestNote = highestNote
        self.rangeInSemitones = rangeInSemitones
        self.vocalRangeFit = vocalRangeFit
        self.suggestedTranspositions = suggestedTranspositions
    }
}
