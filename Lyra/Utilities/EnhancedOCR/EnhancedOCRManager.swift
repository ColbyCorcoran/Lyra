//
//  EnhancedOCRManager.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR with AI/ML
//  Main orchestration manager coordinating all 7 engines
//

import Foundation
import UIKit
import SwiftData
import Observation

/// Main manager for enhanced OCR operations
@MainActor
@Observable
class EnhancedOCRManager {

    // MARK: - Properties

    // Engines
    private let imageEnhancement = ImageEnhancementEngine()
    private let mlOCR: MLOCREngine
    private let handwritingRecognition: HandwritingRecognitionEngine
    private let contextCorrection: ContextCorrectionEngine
    private let layoutAnalysis = LayoutAnalysisEngine()
    private let multiPage = MultiPageEngine()
    private let batchOCR = BatchOCREngine()

    // State
    var isProcessing = false
    var currentProgress: Double = 0.0
    var lastResult: EnhancedOCRResult?

    // Cache
    private var processingCache: [String: (result: EnhancedOCRResult, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    // Model context for SwiftData
    private let modelContext: ModelContext?

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        self.mlOCR = MLOCREngine()
        self.handwritingRecognition = HandwritingRecognitionEngine(modelContext: modelContext)
        self.contextCorrection = ContextCorrectionEngine(modelContext: modelContext)
    }

    // MARK: - Public API

    /// Process single image with full enhanced OCR pipeline
    /// - Parameters:
    ///   - image: Image to process
    ///   - options: Processing options
    /// - Returns: Enhanced OCR result
    func processEnhancedOCR(image: UIImage, options: ProcessingOptions = .default) async throws -> EnhancedOCRResult {
        isProcessing = true
        currentProgress = 0.0
        defer { isProcessing = false }

        let startTime = Date()

        // Check cache
        if let cached = checkCache(for: image) {
            currentProgress = 1.0
            lastResult = cached
            return cached
        }

        // Stage 1: Image Enhancement (20%)
        currentProgress = 0.1
        let (enhancedImage, imageMetrics) = imageEnhancement.enhanceImage(image)
        currentProgress = 0.2

        // Stage 2: OCR Recognition (40%)
        currentProgress = 0.3
        let rawOCRResult: OCRResult
        if options.useHandwritingRecognition {
            rawOCRResult = try await handwritingRecognition.recognizeHandwriting(from: enhancedImage, userId: options.userId)
        } else {
            rawOCRResult = try await mlOCR.recognizeText(from: enhancedImage)
        }
        currentProgress = 0.4

        // Stage 3: Layout Analysis (60%)
        currentProgress = 0.5
        let layoutStructure = layoutAnalysis.analyzeLayout(rawOCRResult, pageNumber: 0)
        currentProgress = 0.6

        // Stage 4: Context Correction (80%)
        currentProgress = 0.7
        let (correctedOCR, reviewItems) = contextCorrection.correctWithContext(rawOCRResult, key: options.detectedKey)
        currentProgress = 0.8

        // Stage 5: Calculate Confidence (90%)
        currentProgress = 0.9
        let confidenceBreakdown = calculateConfidence(
            imageQuality: imageMetrics.overallScore,
            ocrAccuracy: correctedOCR.confidence,
            contextValidation: Float(reviewItems.isEmpty ? 1.0 : 0.7)
        )

        // Stage 6: Create Result (100%)
        let processingTime = Date().timeIntervalSince(startTime)
        let metadata = ProcessingMetadata(
            processingTime: processingTime,
            engineUsed: options.useHandwritingRecognition ? "Handwriting" : "ML/Vision",
            enhancementsApplied: imageMetrics.overallScore < 0.7 ? ["enhancement"] : [],
            pageCount: 1,
            timestamp: Date()
        )

        let result = EnhancedOCRResult(
            originalImage: image.pngData(),
            enhancedImage: enhancedImage.pngData(),
            rawOCRResult: rawOCRResult,
            correctedText: correctedOCR.text,
            layoutStructure: layoutStructure,
            confidenceBreakdown: confidenceBreakdown,
            reviewItems: reviewItems,
            processingMetadata: metadata
        )

        currentProgress = 1.0
        lastResult = result

        // Cache result
        cacheResult(result, for: image)

        return result
    }

    /// Process batch of images
    /// - Parameters:
    ///   - images: Array of images
    ///   - options: Processing options
    ///   - progressHandler: Progress callback
    /// - Returns: Batch OCR job
    func processBatchOCR(images: [UIImage], options: ProcessingOptions = .default, progressHandler: ((Double) -> Void)? = nil) async throws -> BatchOCRJob {
        return try await batchOCR.processBatch(images: images, processor: { image in
            return try await self.processEnhancedOCR(image: image, options: options)
        }, progressHandler: progressHandler)
    }

    /// Process multi-page document
    /// - Parameters:
    ///   - images: Array of page images
    ///   - options: Processing options
    /// - Returns: Combined multi-page result
    func processMultiPage(images: [UIImage], options: ProcessingOptions = .default) async throws -> EnhancedOCRResult {
        // Process each page
        var pageResults: [EnhancedOCRResult] = []

        for (index, image) in images.enumerated() {
            currentProgress = Double(index) / Double(images.count)
            let result = try await processEnhancedOCR(image: image, options: options)
            pageResults.append(result)
        }

        // Stitch pages together
        let stitched = multiPage.stitchPages(pageResults)
        currentProgress = 1.0

        return stitched
    }

    /// Review and correct OCR result interactively
    /// - Parameter result: Result to review
    /// - Returns: Result with user's review state
    func reviewResult(_ result: EnhancedOCRResult) -> EnhancedOCRResult {
        // Return result for UI to display review items
        return result
    }

    /// Apply user corrections to result
    /// - Parameters:
    ///   - result: Original result
    ///   - corrections: User corrections
    /// - Returns: Updated result
    func applyCorrections(_ result: EnhancedOCRResult, corrections: [String: String]) -> EnhancedOCRResult {
        var updated = result

        // Apply corrections to text
        var correctedText = result.correctedText
        for (original, correction) in corrections {
            correctedText = correctedText.replacingOccurrences(of: original, with: correction)

            // Learn from correction
            if let modelContext = modelContext {
                let history = OCRCorrectionHistory(
                    originalText: original,
                    correctedText: correction,
                    correctionType: CorrectionType.manualOverride.rawValue,
                    context: "user_correction",
                    accepted: true
                )
                modelContext.insert(history)
                try? modelContext.save()
            }
        }

        updated.correctedText = correctedText

        // Update review items to mark as accepted
        updated.reviewItems = result.reviewItems.map { item in
            var updatedItem = item
            if let correction = corrections[item.originalText] {
                updatedItem.suggestedCorrection = correction
                updatedItem.userAccepted = true
            }
            return updatedItem
        }

        return updated
    }

    /// Learn from handwriting sample
    /// - Parameters:
    ///   - original: Original recognized text
    ///   - corrected: User's correction
    ///   - userId: User ID
    func learnHandwriting(original: String, corrected: String, userId: String = "default") {
        handwritingRecognition.learnFromSample(
            originalText: original,
            correctedText: corrected,
            userId: userId
        )
    }

    // MARK: - Confidence Calculation

    /// Calculate overall confidence breakdown
    private func calculateConfidence(imageQuality: Float, ocrAccuracy: Float, contextValidation: Float) -> ConfidenceBreakdown {
        return ConfidenceBreakdown(
            imageQuality: imageQuality,
            ocrAccuracy: ocrAccuracy,
            contextValidation: contextValidation,
            overallConfidence: ConfidenceBreakdown.calculate(
                imageQuality: imageQuality,
                ocrAccuracy: ocrAccuracy,
                contextValidation: contextValidation
            )
        )
    }

    // MARK: - Caching

    /// Check cache for processed result
    private func checkCache(for image: UIImage) -> EnhancedOCRResult? {
        let imageHash = hashImage(image)

        // Clean expired cache entries
        cleanExpiredCache()

        // Check if cached and still valid
        if let cached = processingCache[imageHash] {
            if Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
                return cached.result
            }
        }

        // Check SwiftData cache
        if let modelContext = modelContext {
            let descriptor = FetchDescriptor<OCRProcessingCache>(
                predicate: #Predicate { $0.imageHash == imageHash }
            )

            if let cached = try? modelContext.fetch(descriptor).first {
                if cached.isValid {
                    // Decode result
                    if let result = try? JSONDecoder().decode(EnhancedOCRResult.self, from: cached.resultData) {
                        // Update in-memory cache
                        processingCache[imageHash] = (result, cached.timestamp)
                        return result
                    }
                }
            }
        }

        return nil
    }

    /// Cache OCR result
    private func cacheResult(_ result: EnhancedOCRResult, for image: UIImage) {
        let imageHash = hashImage(image)

        // In-memory cache
        processingCache[imageHash] = (result, Date())

        // SwiftData cache
        if let modelContext = modelContext {
            if let encoded = try? JSONEncoder().encode(result) {
                let cache = OCRProcessingCache(
                    imageHash: imageHash,
                    resultData: encoded
                )
                modelContext.insert(cache)
                try? modelContext.save()
            }
        }
    }

    /// Clean expired cache entries
    private func cleanExpiredCache() {
        let now = Date()
        processingCache = processingCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < cacheTimeout
        }
    }

    /// Generate hash for image
    private func hashImage(_ image: UIImage) -> String {
        guard let data = image.pngData() else {
            return UUID().uuidString
        }
        return String(data.hashValue)
    }

    // MARK: - Statistics

    /// Get processing statistics
    func getStatistics() -> OCRStatistics {
        let cacheHitRate = Float(processingCache.count) / Float(max(processingCache.count + 1, 1))

        return OCRStatistics(
            totalProcessed: processingCache.count,
            cacheHitRate: cacheHitRate,
            averageProcessingTime: calculateAverageProcessingTime(),
            handwritingAccuracy: handwritingRecognition.getHandwritingAccuracy()
        )
    }

    /// Calculate average processing time from cache
    private func calculateAverageProcessingTime() -> TimeInterval {
        guard !processingCache.isEmpty else { return 0.0 }

        let times = processingCache.values.map { $0.result.processingMetadata.processingTime }
        return times.reduce(0, +) / Double(times.count)
    }
}

// MARK: - Supporting Types

/// Processing options for OCR
struct ProcessingOptions {
    var useHandwritingRecognition: Bool
    var userId: String
    var detectedKey: String?
    var enableCaching: Bool

    static let `default` = ProcessingOptions(
        useHandwritingRecognition: false,
        userId: "default",
        detectedKey: nil,
        enableCaching: true
    )
}

/// OCR processing statistics
struct OCRStatistics {
    let totalProcessed: Int
    let cacheHitRate: Float
    let averageProcessingTime: TimeInterval
    let handwritingAccuracy: Float
}
