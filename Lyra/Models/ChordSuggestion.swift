//
//  ChordSuggestion.swift
//  Lyra
//
//  Models for AI chord suggestions and corrections
//  Part of Phase 7.2: Chord Analysis Intelligence
//

import Foundation
import SwiftUI

// MARK: - Chord Suggestion

/// A suggested chord with confidence score
struct ChordSuggestion: Identifiable, Codable {
    var id: UUID
    var chord: String
    var confidence: Float // 0.0 - 1.0
    var reason: SuggestionReason
    var context: String? // Optional explanation

    init(
        id: UUID = UUID(),
        chord: String,
        confidence: Float,
        reason: SuggestionReason,
        context: String? = nil
    ) {
        self.id = id
        self.chord = chord
        self.confidence = confidence
        self.reason = reason
        self.context = context
    }
}

enum SuggestionReason: String, Codable {
    case inKey = "In Current Key"
    case commonProgression = "Common Progression"
    case recentlyUsed = "Recently Used"
    case typoCorrection = "Typo Correction"
    case enharmonic = "Enharmonic Equivalent"
    case substitution = "Chord Substitution"
    case reharmonization = "Reharmonization"
    case autocomplete = "Autocomplete"

    var icon: String {
        switch self {
        case .inKey: return "key.fill"
        case .commonProgression: return "chart.bar.fill"
        case .recentlyUsed: return "clock.arrow.circlepath"
        case .typoCorrection: return "text.badge.checkmark"
        case .enharmonic: return "equal.circle"
        case .substitution: return "arrow.left.arrow.right"
        case .reharmonization: return "sparkles"
        case .autocomplete: return "text.cursor"
        }
    }

    var color: Color {
        switch self {
        case .inKey: return .blue
        case .commonProgression: return .green
        case .recentlyUsed: return .orange
        case .typoCorrection: return .red
        case .enharmonic: return .purple
        case .substitution: return .cyan
        case .reharmonization: return .pink
        case .autocomplete: return .gray
        }
    }
}

// MARK: - Chord Error

/// Detected error in chord progression
struct ChordError: Identifiable {
    var id: UUID
    var chordIndex: Int
    var chord: String
    var errorType: ChordErrorType
    var severity: ErrorSeverity
    var suggestions: [ChordSuggestion]
    var explanation: String

    init(
        id: UUID = UUID(),
        chordIndex: Int,
        chord: String,
        errorType: ChordErrorType,
        severity: ErrorSeverity = .warning,
        suggestions: [ChordSuggestion] = [],
        explanation: String
    ) {
        self.id = id
        self.chordIndex = chordIndex
        self.chord = chord
        self.errorType = errorType
        self.severity = severity
        self.suggestions = suggestions
        self.explanation = explanation
    }
}

enum ChordErrorType: String, Codable {
    case outOfKey = "Out of Key"
    case unlikelyProgression = "Unlikely Progression"
    case typo = "Possible Typo"
    case invalidSyntax = "Invalid Syntax"
    case missingQuality = "Missing Quality"
    case enharmonicIssue = "Enharmonic Issue"

    var icon: String {
        switch self {
        case .outOfKey: return "exclamationmark.triangle.fill"
        case .unlikelyProgression: return "questionmark.circle.fill"
        case .typo: return "text.badge.xmark"
        case .invalidSyntax: return "xmark.octagon.fill"
        case .missingQuality: return "ellipsis.circle.fill"
        case .enharmonicIssue: return "arrow.triangle.2.circlepath"
        }
    }
}

enum ErrorSeverity: String, Codable {
    case info = "Info"
    case warning = "Warning"
    case error = "Error"

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Chord Theory Info

/// Theoretical information about a chord
struct ChordTheoryInfo: Identifiable {
    var id: UUID
    var chord: String
    var root: String
    var quality: ChordQuality
    var intervals: [Int] // Semitones from root
    var notes: [String] // Actual note names
    var formula: String // e.g., "1-3-5" or "1-♭3-5"
    var description: String
    var relatedChords: [RelatedChord]
    var commonProgressions: [String] // Common progressions using this chord

    init(
        id: UUID = UUID(),
        chord: String,
        root: String,
        quality: ChordQuality,
        intervals: [Int],
        notes: [String],
        formula: String,
        description: String,
        relatedChords: [RelatedChord] = [],
        commonProgressions: [String] = []
    ) {
        self.id = id
        self.chord = chord
        self.root = root
        self.quality = quality
        self.intervals = intervals
        self.notes = notes
        self.formula = formula
        self.description = description
        self.relatedChords = relatedChords
        self.commonProgressions = commonProgressions
    }
}

struct RelatedChord: Identifiable {
    var id: UUID
    var chord: String
    var relationship: ChordRelationship
    var substitutionContext: String?

    init(
        id: UUID = UUID(),
        chord: String,
        relationship: ChordRelationship,
        substitutionContext: String? = nil
    ) {
        self.id = id
        self.chord = chord
        self.relationship = relationship
        self.substitutionContext = substitutionContext
    }
}

enum ChordRelationship: String {
    case parallel = "Parallel"
    case relative = "Relative"
    case dominant = "Dominant"
    case subdominant = "Subdominant"
    case tritoneSubstitution = "Tritone Sub"
    case secondary = "Secondary Dominant"
    case extended = "Extended Version"
    case simplified = "Simplified Version"
}

// MARK: - Progression Analysis

/// Analysis of a chord progression
struct ProgressionAnalysis: Identifiable {
    var id: UUID
    var chords: [String]
    var key: String?
    var scale: ScaleType?
    var romanNumerals: [RomanNumeral]
    var progressionType: ProgressionType?
    var commonName: String?
    var variations: [ProgressionVariation]
    var confidence: Float

    init(
        id: UUID = UUID(),
        chords: [String],
        key: String? = nil,
        scale: ScaleType? = nil,
        romanNumerals: [RomanNumeral] = [],
        progressionType: ProgressionType? = nil,
        commonName: String? = nil,
        variations: [ProgressionVariation] = [],
        confidence: Float = 0.0
    ) {
        self.id = id
        self.chords = chords
        self.key = key
        self.scale = scale
        self.romanNumerals = romanNumerals
        self.progressionType = progressionType
        self.commonName = commonName
        self.variations = variations
        self.confidence = confidence
    }
}

struct RomanNumeral: Identifiable {
    var id: UUID
    var chord: String
    var numeral: String // e.g., "I", "ii", "V7"
    var function: HarmonicFunction
    var isDiatonic: Bool

    init(
        id: UUID = UUID(),
        chord: String,
        numeral: String,
        function: HarmonicFunction,
        isDiatonic: Bool = true
    ) {
        self.id = id
        self.chord = chord
        self.numeral = numeral
        self.function = function
        self.isDiatonic = isDiatonic
    }
}

enum HarmonicFunction: String {
    case tonic = "Tonic"
    case subdominant = "Subdominant"
    case dominant = "Dominant"
    case secondary = "Secondary"
    case modal = "Modal Interchange"
    case chromatic = "Chromatic"

    var color: Color {
        switch self {
        case .tonic: return .green
        case .subdominant: return .blue
        case .dominant: return .red
        case .secondary: return .orange
        case .modal: return .purple
        case .chromatic: return .gray
        }
    }
}

enum ProgressionType: String, CaseIterable, Codable {
    case fiftysTwoFiveOne = "ii-V-I"
    case oneFourFiveOne = "I-IV-V-I"
    case oneFiveSixFour = "I-V-vi-IV"
    case oneSixFourFive = "I-vi-IV-V"
    case sixFourOneFive = "vi-IV-I-V"
    case blues = "12-Bar Blues"
    case jazz = "Jazz Standard"
    case pop = "Pop Progression"
    case gospel = "Gospel Progression"
    case andalusian = "Andalusian Cadence"
    case custom = "Custom"

    var description: String {
        switch self {
        case .fiftysTwoFiveOne: return "Classic jazz progression (ii-V-I)"
        case .oneFourFiveOne: return "Traditional pop/rock (I-IV-V)"
        case .oneFiveSixFour: return "Modern pop (I-V-vi-IV)"
        case .oneSixFourFive: return "50s progression (I-vi-IV-V)"
        case .sixFourOneFive: return "Sensitive progression (vi-IV-I-V)"
        case .blues: return "Standard 12-bar blues"
        case .jazz: return "Jazz standard changes"
        case .pop: return "Contemporary pop progression"
        case .gospel: return "Gospel/soul progression"
        case .andalusian: return "Flamenco/Spanish cadence"
        case .custom: return "Custom progression"
        }
    }
}

struct ProgressionVariation: Identifiable {
    var id: UUID
    var chords: [String]
    var variationType: VariationType
    var description: String
    var difficulty: Difficulty

    init(
        id: UUID = UUID(),
        chords: [String],
        variationType: VariationType,
        description: String,
        difficulty: Difficulty
    ) {
        self.id = id
        self.chords = chords
        self.variationType = variationType
        self.description = description
        self.difficulty = difficulty
    }
}

enum VariationType: String {
    case simpler = "Simpler"
    case moreComplex = "More Complex"
    case jazzReharmonization = "Jazz Reharmonization"
    case substitution = "Chord Substitution"
    case inversion = "With Inversions"
    case extensions = "With Extensions"
}

enum Difficulty: String {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Autocomplete Context

/// Context for chord autocomplete
struct AutocompleteContext {
    var partialChord: String
    var previousChords: [String]
    var currentKey: String?
    var recentChords: [String]

    init(
        partialChord: String,
        previousChords: [String] = [],
        currentKey: String? = nil,
        recentChords: [String] = []
    ) {
        self.partialChord = partialChord
        self.previousChords = previousChords
        self.currentKey = currentKey
        self.recentChords = recentChords
    }
}

// MARK: - Common Progressions Database

struct CommonProgression: Identifiable, Codable {
    var id: UUID
    var name: String
    var chords: [String] // In key of C for reference
    var type: ProgressionType
    var genre: [String] // e.g., ["Pop", "Rock"]
    var examples: [String] // Song examples
    var popularity: Float // 0.0 - 1.0

    init(
        id: UUID = UUID(),
        name: String,
        chords: [String],
        type: ProgressionType,
        genre: [String] = [],
        examples: [String] = [],
        popularity: Float = 0.5
    ) {
        self.id = id
        self.name = name
        self.chords = chords
        self.type = type
        self.genre = genre
        self.examples = examples
        self.popularity = popularity
    }
}
