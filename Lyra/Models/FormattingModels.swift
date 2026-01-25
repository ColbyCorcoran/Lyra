//
//  FormattingModels.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Data models for AI-powered song formatting system
//
//  Created by Claude AI on 1/24/26.
//

import Foundation
import SwiftData

// MARK: - Formatting Result

/// Complete result of song formatting analysis and transformation
struct FormattingResult: Identifiable, Codable {
    var id: UUID = UUID()
    var originalText: String
    var formattedText: String
    var detectedStructure: FormattingSongStructure
    var detectedPattern: ChordPattern
    var extractedChords: [String]
    var extractedMetadata: FormattingSongMetadata
    var qualityScore: QualityScore
    var suggestions: [FormattingSuggestion]
    var changes: [FormattingChange]
    var timestamp: Date = Date()
}

// MARK: - Song Structure

/// Detected song structure with sections and patterns - for formatting analysis
struct FormattingSongStructure: Codable {
    var sections: [FormattedSongSection]
    var repeatedSections: [SectionRepetition]
    var sectionOrder: [String]
    var confidence: Float

    init(sections: [FormattedSongSection] = [],
         repeatedSections: [SectionRepetition] = [],
         sectionOrder: [String] = [],
         confidence: Float = 0.0) {
        self.sections = sections
        self.repeatedSections = repeatedSections
        self.sectionOrder = sectionOrder
        self.confidence = confidence
    }
}

/// Individual song section (verse, chorus, bridge, etc.) - for formatting analysis
struct FormattedSongSection: Identifiable, Codable {
    var id: UUID = UUID()
    var type: FormattingSectionType
    var label: String
    var lines: [String]
    var startLine: Int
    var endLine: Int
    var confidence: Float
    var isInstrumental: Bool

    init(type: FormattingSectionType,
         label: String,
         lines: [String],
         startLine: Int,
         endLine: Int,
         confidence: Float = 0.0,
         isInstrumental: Bool = false) {
        self.type = type
        self.label = label
        self.lines = lines
        self.startLine = startLine
        self.endLine = endLine
        self.confidence = confidence
        self.isInstrumental = isInstrumental
    }
}

/// Section types for formatting intelligence
enum FormattingSectionType: String, Codable, CaseIterable {
    case intro = "Intro"
    case verse = "Verse"
    case preChorus = "Pre-Chorus"
    case chorus = "Chorus"
    case bridge = "Bridge"
    case outro = "Outro"
    case instrumental = "Instrumental"
    case tag = "Tag"
    case unknown = "Unknown"

    var displayName: String {
        rawValue
    }

    var color: String {
        switch self {
        case .intro: return "blue"
        case .verse: return "green"
        case .preChorus: return "yellow"
        case .chorus: return "orange"
        case .bridge: return "purple"
        case .outro: return "gray"
        case .instrumental: return "cyan"
        case .tag: return "pink"
        case .unknown: return "secondary"
        }
    }
}

/// Section repetition information
struct SectionRepetition: Codable {
    var sectionType: FormattingSectionType
    var label: String
    var occurrences: [Int]      // Line numbers where section occurs
    var similarity: Float        // How similar the repetitions are (0.0-1.0)

    init(sectionType: FormattingSectionType,
         label: String,
         occurrences: [Int],
         similarity: Float) {
        self.sectionType = sectionType
        self.label = label
        self.occurrences = occurrences
        self.similarity = similarity
    }
}

// MARK: - Chord Pattern

/// Detected chord notation pattern
enum ChordPattern: String, Codable, CaseIterable {
    case chordOverLyric = "Chord Over Lyric"
    case inlineBrackets = "Inline Brackets"
    case chordPro = "ChordPro"
    case nashville = "Nashville Numbers"
    case mixed = "Mixed Patterns"
    case unknown = "Unknown"

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .chordOverLyric:
            return "Chords on line above lyrics"
        case .inlineBrackets:
            return "[C]word format"
        case .chordPro:
            return "{c:C}word format"
        case .nashville:
            return "Nashville number system (1, 4, 5)"
        case .mixed:
            return "Multiple patterns detected"
        case .unknown:
            return "Pattern not recognized"
        }
    }

    var example: String {
        switch self {
        case .chordOverLyric:
            return "    C       Am\nAmazing grace"
        case .inlineBrackets:
            return "[C]Amazing [Am]grace"
        case .chordPro:
            return "{c:C}Amazing {c:Am}grace"
        case .nashville:
            return "    1       6m\nAmazing grace"
        case .mixed:
            return "Multiple formats"
        case .unknown:
            return "No pattern detected"
        }
    }
}

// MARK: - Quality Score

/// Multi-dimensional formatting quality score
struct QualityScore: Codable {
    var overall: Float              // 0.0 - 1.0 (0-100%)
    var spacing: Float              // Consistent spacing
    var alignment: Float            // Chord alignment
    var structure: Float            // Section organization
    var chordFormat: Float          // Chord consistency
    var metadata: Float             // Metadata completeness
    var issues: [QualityIssue]

    init(overall: Float = 0.0,
         spacing: Float = 0.0,
         alignment: Float = 0.0,
         structure: Float = 0.0,
         chordFormat: Float = 0.0,
         metadata: Float = 0.0,
         issues: [QualityIssue] = []) {
        self.overall = overall
        self.spacing = spacing
        self.alignment = alignment
        self.structure = structure
        self.chordFormat = chordFormat
        self.metadata = metadata
        self.issues = issues
    }

    var grade: String {
        switch overall {
        case 0.9...1.0: return "A"
        case 0.8..<0.9: return "B"
        case 0.7..<0.8: return "C"
        case 0.6..<0.7: return "D"
        default: return "F"
        }
    }

    var percentage: Int {
        Int(overall * 100)
    }
}

/// Quality issue detected in formatting
struct QualityIssue: Identifiable, Codable {
    var id: UUID = UUID()
    var type: IssueType
    var severity: IssueSeverity
    var description: String
    var lineNumber: Int?
    var suggestion: String
    var autoFixable: Bool

    init(type: IssueType,
         severity: IssueSeverity,
         description: String,
         lineNumber: Int? = nil,
         suggestion: String,
         autoFixable: Bool = false) {
        self.type = type
        self.severity = severity
        self.description = description
        self.lineNumber = lineNumber
        self.suggestion = suggestion
        self.autoFixable = autoFixable
    }
}

/// Issue types
enum IssueType: String, Codable, CaseIterable {
    case inconsistentSpacing = "Inconsistent Spacing"
    case misalignedChords = "Misaligned Chords"
    case missingSection = "Missing Section Labels"
    case duplicateBlankLines = "Duplicate Blank Lines"
    case inconsistentChordFormat = "Inconsistent Chord Format"
    case missingMetadata = "Missing Metadata"
    case invalidChord = "Invalid Chord"
    case mixedPatterns = "Mixed Chord Patterns"

    var displayName: String {
        rawValue
    }
}

/// Issue severity levels
enum IssueSeverity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }

    var icon: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.circle"
        case .critical: return "xmark.octagon"
        }
    }
}

// MARK: - Formatting Suggestion

/// Suggested formatting improvement
struct FormattingSuggestion: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var impact: String
    var autoApplicable: Bool

    init(title: String,
         description: String,
         impact: String,
         autoApplicable: Bool = false) {
        self.title = title
        self.description = description
        self.impact = impact
        self.autoApplicable = autoApplicable
    }
}

// MARK: - Formatting Change

/// Log of formatting changes made
struct FormattingChange: Identifiable, Codable {
    var id: UUID = UUID()
    var type: ChangeType
    var description: String
    var lineNumber: Int?
    var before: String
    var after: String

    init(type: ChangeType,
         description: String,
         lineNumber: Int? = nil,
         before: String,
         after: String) {
        self.type = type
        self.description = description
        self.lineNumber = lineNumber
        self.before = before
        self.after = after
    }
}

/// Types of formatting changes
enum ChangeType: String, Codable, CaseIterable {
    case addedSection = "Added Section Label"
    case removedBlankLines = "Removed Blank Lines"
    case alignedChords = "Aligned Chords"
    case fixedSpacing = "Fixed Spacing"
    case standardizedChords = "Standardized Chords"
    case extractedMetadata = "Extracted Metadata"
    case convertedPattern = "Converted Pattern"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .addedSection: return "tag"
        case .removedBlankLines: return "text.line.last.and.arrowtriangle.forward"
        case .alignedChords: return "align.horizontal.left"
        case .fixedSpacing: return "space"
        case .standardizedChords: return "music.note"
        case .extractedMetadata: return "doc.text.magnifyingglass"
        case .convertedPattern: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Extracted Metadata

/// Song metadata extracted from text - for formatting analysis
struct FormattingSongMetadata: Codable {
    var title: String?
    var artist: String?
    var key: String?
    var tempo: Int?
    var timeSignature: String?
    var capo: Int?
    var confidence: Float

    init(title: String? = nil,
         artist: String? = nil,
         key: String? = nil,
         tempo: Int? = nil,
         timeSignature: String? = nil,
         capo: Int? = nil,
         confidence: Float = 0.0) {
        self.title = title
        self.artist = artist
        self.key = key
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.capo = capo
        self.confidence = confidence
    }

    var isComplete: Bool {
        title != nil && artist != nil && key != nil
    }

    var completenessPercentage: Float {
        var count: Float = 0
        let total: Float = 6

        if title != nil { count += 1 }
        if artist != nil { count += 1 }
        if key != nil { count += 1 }
        if tempo != nil { count += 1 }
        if timeSignature != nil { count += 1 }
        if capo != nil { count += 1 }

        return count / total
    }
}

// MARK: - Formatting Options

/// Configuration options for formatting
struct FormattingOptions: Codable {
    var targetPattern: ChordPattern
    var removeExtraBlankLines: Bool
    var alignChords: Bool
    var autoLabelSections: Bool
    var standardizeChords: Bool
    var extractMetadata: Bool
    var fixSpacing: Bool

    static let standard = FormattingOptions(
        targetPattern: .chordPro,
        removeExtraBlankLines: true,
        alignChords: true,
        autoLabelSections: true,
        standardizeChords: true,
        extractMetadata: true,
        fixSpacing: true
    )

    static let minimal = FormattingOptions(
        targetPattern: .chordOverLyric,
        removeExtraBlankLines: true,
        alignChords: false,
        autoLabelSections: false,
        standardizeChords: false,
        extractMetadata: false,
        fixSpacing: true
    )

    static let aggressive = FormattingOptions(
        targetPattern: .chordPro,
        removeExtraBlankLines: true,
        alignChords: true,
        autoLabelSections: true,
        standardizeChords: true,
        extractMetadata: true,
        fixSpacing: true
    )
}

// MARK: - Batch Formatting Result

/// Result of batch formatting operation
struct BatchFormattingResult: Codable {
    var totalSongs: Int
    var successCount: Int
    var failureCount: Int
    var results: [UUID: FormattingResult]
    var averageQualityImprovement: Float
    var totalIssuesFixed: Int
    var timestamp: Date = Date()

    init(totalSongs: Int,
         successCount: Int,
         failureCount: Int,
         results: [UUID: FormattingResult],
         averageQualityImprovement: Float,
         totalIssuesFixed: Int) {
        self.totalSongs = totalSongs
        self.successCount = successCount
        self.failureCount = failureCount
        self.results = results
        self.averageQualityImprovement = averageQualityImprovement
        self.totalIssuesFixed = totalIssuesFixed
    }

    var successRate: Float {
        guard totalSongs > 0 else { return 0 }
        return Float(successCount) / Float(totalSongs)
    }
}

// MARK: - Formatting History

/// Historical record of formatting operations
@Model
class FormattingHistory {
    var id: UUID = UUID()
    var songID: UUID
    var timestamp: Date = Date()
    var originalQualityScore: Float
    var newQualityScore: Float
    var issuesFixed: Int
    var changesSummary: String

    init(songID: UUID,
         originalQualityScore: Float,
         newQualityScore: Float,
         issuesFixed: Int,
         changesSummary: String) {
        self.songID = songID
        self.originalQualityScore = originalQualityScore
        self.newQualityScore = newQualityScore
        self.issuesFixed = issuesFixed
        self.changesSummary = changesSummary
    }

    var improvement: Float {
        newQualityScore - originalQualityScore
    }
}
