//
//  EnhancedOCRModels.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR with AI/ML - Data Models
//  Comprehensive models for advanced OCR processing
//

import Foundation
import SwiftUI
import SwiftData
import UIKit

// MARK: - Enhanced OCR Result

/// Comprehensive result from enhanced OCR processing pipeline
struct EnhancedOCRResult: Identifiable, Codable {
    var id: UUID = UUID()
    var originalImage: Data? // UIImage as PNG data
    var enhancedImage: Data? // Preprocessed image
    var rawOCRResult: OCRResult // From Vision/ML
    var correctedText: String // After context correction
    var layoutStructure: LayoutStructure
    var confidenceBreakdown: ConfidenceBreakdown
    var reviewItems: [ReviewItem] // Low-confidence blocks
    var processingMetadata: ProcessingMetadata
}

// MARK: - Layout Structure Models

/// Structure and layout information detected from the image
struct LayoutStructure: Codable {
    var layoutType: LayoutType // .chordOverLyric, .inline, .unknown
    var sections: [OCRSongSection]
    var chordPlacements: [ChordPlacement]
    var preservedSpacing: [SpacingRule]
}

/// Type of layout detected in the chord chart
enum LayoutType: String, Codable {
    case chordOverLyric // Chords above lyrics
    case inline // Chords in brackets [C]
    case nashville // Nashville numbers
    case tablature // Guitar tabs
    case unknown

    var description: String {
        switch self {
        case .chordOverLyric:
            return "Chord Over Lyric"
        case .inline:
            return "Inline Chords"
        case .nashville:
            return "Nashville Number"
        case .tablature:
            return "Tablature"
        case .unknown:
            return "Unknown Layout"
        }
    }
}

/// A section of a song detected from OCR (verse, chorus, bridge, etc.)
struct OCRSongSection: Identifiable, Codable {
    var id: UUID = UUID()
    var type: OCRSectionType
    var content: String
    var boundingBox: CGRect
    var pageNumber: Int
}

/// Section types for OCR detection
enum OCRSectionType: String, Codable {
    case verse
    case chorus
    case bridge
    case intro
    case outro
    case preChorus = "pre-chorus"
    case interlude
    case solo
    case instrumental
    case refrain
    case unknown

    var displayName: String {
        switch self {
        case .verse: return "Verse"
        case .chorus: return "Chorus"
        case .bridge: return "Bridge"
        case .intro: return "Intro"
        case .outro: return "Outro"
        case .preChorus: return "Pre-Chorus"
        case .interlude: return "Interlude"
        case .solo: return "Solo"
        case .instrumental: return "Instrumental"
        case .refrain: return "Refrain"
        case .unknown: return "Unknown"
        }
    }
}

/// Precise placement of a chord in the layout
struct ChordPlacement: Codable {
    var chord: String
    var position: CGPoint // Normalized coordinates
    var alignedWithLyric: String?
    var confidence: Float
}

/// Spacing and indentation rules to preserve structure
struct SpacingRule: Codable {
    var lineNumber: Int
    var indentation: Float
    var topSpacing: Float
}

// MARK: - Confidence and Quality Models

/// Breakdown of confidence scores from different processing stages
struct ConfidenceBreakdown: Codable {
    var imageQuality: Float // 0.0-1.0
    var ocrAccuracy: Float // From Vision/ML
    var contextValidation: Float // Theory validation
    var overallConfidence: Float // Weighted average

    /// Calculate overall confidence from components
    static func calculate(imageQuality: Float, ocrAccuracy: Float, contextValidation: Float) -> Float {
        // Weighted average: image 20%, OCR 50%, context 30%
        return imageQuality * 0.2 + ocrAccuracy * 0.5 + contextValidation * 0.3
    }

    /// Quality level based on overall confidence
    var qualityLevel: QualityLevel {
        if overallConfidence >= 0.9 {
            return .excellent
        } else if overallConfidence >= 0.7 {
            return .good
        } else if overallConfidence >= 0.5 {
            return .fair
        } else {
            return .poor
        }
    }

    enum QualityLevel {
        case excellent, good, fair, poor

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }

        var description: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair - Review Recommended"
            case .poor: return "Poor - Manual Review Required"
            }
        }
    }
}

/// Item flagged for user review
struct ReviewItem: Identifiable, Codable {
    var id: UUID = UUID()
    var originalText: String
    var suggestedCorrection: String?
    var boundingBox: CGRect
    var confidence: Float
    var correctionReason: String // "Low OCR confidence", "Invalid chord", etc.
    var userAccepted: Bool?
}

/// Metadata about the processing pipeline
struct ProcessingMetadata: Codable {
    var processingTime: TimeInterval
    var engineUsed: String // "ML" or "Vision"
    var enhancementsApplied: [String] // ["deskew", "denoise", etc.]
    var pageCount: Int
    var timestamp: Date
}

// MARK: - Image Quality Metrics

/// Detailed metrics about image quality
struct ImageQualityMetrics {
    var brightness: Float // 0.0-1.0
    var contrast: Float
    var sharpness: Float
    var skewAngle: Float // Degrees
    var noiseLevel: Float
    var overallScore: Float

    /// Quality level based on overall score
    var qualityLevel: QualityLevel {
        if overallScore >= 0.8 {
            return .excellent
        } else if overallScore >= 0.6 {
            return .good
        } else if overallScore >= 0.4 {
            return .fair
        } else {
            return .poor
        }
    }

    enum QualityLevel {
        case excellent, good, fair, poor

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
    }
}

// MARK: - Batch Processing Models

/// A batch OCR job with multiple images
struct BatchOCRJob: Identifiable {
    var id: UUID = UUID()
    var images: [UIImage]
    var status: BatchStatus
    var progress: Double // 0.0-1.0
    var results: [EnhancedOCRResult]
    var errors: [BatchOCRError]
    var startTime: Date
    var estimatedCompletion: Date?

    /// Current page being processed
    var currentPage: Int {
        return results.count + 1
    }

    /// Total pages in batch
    var totalPages: Int {
        return images.count
    }

    /// Is processing complete
    var isComplete: Bool {
        return status == .completed || status == .failed || status == .cancelled
    }
}

/// Status of a batch OCR job
enum BatchStatus: String, Codable {
    case queued
    case processing
    case completed
    case failed
    case cancelled

    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .queued: return "clock"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

/// Error that occurred during batch OCR processing
struct BatchOCRError: Identifiable {
    var id: UUID = UUID()
    var imageIndex: Int
    var error: String
    var recoverable: Bool
}

// MARK: - SwiftData Models

/// User-specific handwriting profile for personalized recognition
@Model
class HandwritingProfile {
    @Attribute(.unique) var id: UUID
    var userId: String
    var samplesData: Data // Encoded character samples
    var createdAt: Date
    var lastUpdated: Date
    var accuracyScore: Float

    init(id: UUID = UUID(), userId: String, samplesData: Data = Data(), createdAt: Date = Date(), lastUpdated: Date = Date(), accuracyScore: Float = 0.0) {
        self.id = id
        self.userId = userId
        self.samplesData = samplesData
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.accuracyScore = accuracyScore
    }
}

/// History of OCR corrections for learning
@Model
class OCRCorrectionHistory {
    @Attribute(.unique) var id: UUID
    var originalText: String
    var correctedText: String
    var correctionType: String // CorrectionType.rawValue
    var context: String
    var timestamp: Date
    var accepted: Bool // User confirmed correction

    init(id: UUID = UUID(), originalText: String, correctedText: String, correctionType: String, context: String, timestamp: Date = Date(), accepted: Bool = false) {
        self.id = id
        self.originalText = originalText
        self.correctedText = correctedText
        self.correctionType = correctionType
        self.context = context
        self.timestamp = timestamp
        self.accepted = accepted
    }
}

/// Cache of OCR processing results
@Model
class OCRProcessingCache {
    @Attribute(.unique) var imageHash: String
    var resultData: Data // Encoded EnhancedOCRResult
    var timestamp: Date

    init(imageHash: String, resultData: Data, timestamp: Date = Date()) {
        self.imageHash = imageHash
        self.resultData = resultData
        self.timestamp = timestamp
    }

    /// Check if cache entry is still valid (5 minutes)
    var isValid: Bool {
        return Date().timeIntervalSince(timestamp) < 300 // 5 minutes
    }
}

// MARK: - Correction Types

/// Types of corrections that can be applied
enum CorrectionType: String, Codable {
    case ocrMistake // Common OCR character misreads (O→D, l→I, etc.)
    case invalidChord // Chord doesn't exist in music theory
    case progressionContext // Chord doesn't fit progression context
    case handwritingLearning // User-specific handwriting correction
    case layoutCorrection // Structure/spacing correction
    case manualOverride // User manually corrected

    var displayName: String {
        switch self {
        case .ocrMistake: return "OCR Mistake"
        case .invalidChord: return "Invalid Chord"
        case .progressionContext: return "Progression Context"
        case .handwritingLearning: return "Handwriting Learning"
        case .layoutCorrection: return "Layout Correction"
        case .manualOverride: return "Manual Override"
        }
    }
}

// MARK: - Helper Extensions

extension CGRect: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin.x, forKey: .x)
        try container.encode(origin.y, forKey: .y)
        try container.encode(size.width, forKey: .width)
        try container.encode(size.height, forKey: .height)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(x: x, y: y, width: width, height: height)
    }
}

extension CGPoint: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
}

// MARK: - OCRResult Extension for Codability

extension OCRResult: Codable {
    enum CodingKeys: String, CodingKey {
        case text, confidence, recognizedBlocks
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(recognizedBlocks, forKey: .recognizedBlocks)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let text = try container.decode(String.self, forKey: .text)
        let confidence = try container.decode(Float.self, forKey: .confidence)
        let blocks = try container.decode([RecognizedTextBlock].self, forKey: .recognizedBlocks)
        self.init(text: text, confidence: confidence, recognizedBlocks: blocks)
    }
}

extension OCRResult.RecognizedTextBlock: Codable {
    enum CodingKeys: String, CodingKey {
        case text, confidence, boundingBox
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(boundingBox, forKey: .boundingBox)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let text = try container.decode(String.self, forKey: .text)
        let confidence = try container.decode(Float.self, forKey: .confidence)
        let boundingBox = try container.decode(CGRect.self, forKey: .boundingBox)
        self.init(text: text, confidence: confidence, boundingBox: boundingBox)
    }
}
