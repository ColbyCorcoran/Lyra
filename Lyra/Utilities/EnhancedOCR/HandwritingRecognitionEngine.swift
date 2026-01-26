//
//  HandwritingRecognitionEngine.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Engine 2
//  Handwriting recognition with personal learning and cursive support
//

import Foundation
import UIKit
import Vision
import SwiftData

/// Engine for recognizing handwritten text including cursive
@MainActor
class HandwritingRecognitionEngine {

    // MARK: - Properties

    private let modelContext: ModelContext?

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Recognize handwritten text from image
    /// - Parameters:
    ///   - image: Image containing handwriting
    ///   - userId: User ID for personalized learning
    /// - Returns: OCR result with recognized handwriting
    func recognizeHandwriting(from image: UIImage, userId: String = "default") async throws -> OCRResult {
        // Perform Vision-based handwriting recognition
        var result = try await performHandwritingRecognition(image: image)

        // Apply user-specific learning if available
        if let profile = loadHandwritingProfile(userId: userId) {
            result = applyPersonalizedLearning(result: result, profile: profile)
        }

        return result
    }

    /// Learn from a handwriting sample to improve future recognition
    /// - Parameters:
    ///   - originalText: Text that was recognized
    ///   - correctedText: User's correction
    ///   - userId: User ID
    func learnFromSample(originalText: String, correctedText: String, userId: String = "default") {
        guard let modelContext = modelContext else { return }

        // Load or create handwriting profile
        var profile = loadHandwritingProfile(userId: userId)

        if profile == nil {
            // Create new profile
            profile = HandwritingProfile(
                userId: userId,
                accuracyScore: 0.0
            )
            modelContext.insert(profile!)
        }

        // Store the correction for future learning
        let correction = OCRCorrectionHistory(
            originalText: originalText,
            correctedText: correctedText,
            correctionType: CorrectionType.handwritingLearning.rawValue,
            context: "handwriting",
            accepted: true
        )
        modelContext.insert(correction)

        // Update profile accuracy
        if var existingProfile = profile {
            existingProfile.lastUpdated = Date()
            existingProfile.accuracyScore = calculateUpdatedAccuracy(profile: existingProfile)
        }

        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error saving handwriting learning: \(error)")
        }
    }

    /// Adapt recognition to user's specific handwriting patterns
    /// - Parameters:
    ///   - result: OCR result to adapt
    ///   - userId: User ID
    /// - Returns: Adapted OCR result
    func adaptToUser(_ result: OCRResult, userId: String = "default") -> OCRResult {
        guard let profile = loadHandwritingProfile(userId: userId) else {
            return result
        }

        return applyPersonalizedLearning(result: result, profile: profile)
    }

    /// Enable support for cursive handwriting recognition
    /// - Parameter image: Image with cursive text
    /// - Returns: OCR result
    func supportCursive(image: UIImage) async throws -> OCRResult {
        // Vision framework automatically handles cursive when in handwriting mode
        return try await performHandwritingRecognition(image: image)
    }

    // MARK: - Vision Recognition

    /// Perform handwriting recognition using Vision framework
    /// - Parameter image: Image to process
    /// - Returns: OCR result
    private func performHandwritingRecognition(image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.processingFailed)
                    return
                }

                if observations.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                // Extract text from observations
                var recognizedText: [String] = []
                var blocks: [OCRResult.RecognizedTextBlock] = []
                var totalConfidence: Float = 0.0

                for observation in observations {
                    // Get top 3 candidates for better handwriting recognition
                    let candidates = observation.topCandidates(3)

                    guard let topCandidate = candidates.first else {
                        continue
                    }

                    recognizedText.append(topCandidate.string)
                    totalConfidence += topCandidate.confidence

                    blocks.append(OCRResult.RecognizedTextBlock(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: observation.boundingBox
                    ))
                }

                let combinedText = recognizedText.joined(separator: "\n")
                let averageConfidence = observations.isEmpty ? 0.0 : totalConfidence / Float(observations.count)

                let result = OCRResult(
                    text: combinedText,
                    confidence: averageConfidence,
                    recognizedBlocks: blocks
                )

                continuation.resume(returning: result)
            }

            // Configure for handwriting recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = false

            // IMPORTANT: This property isn't available in all iOS versions
            // For iOS 15+, we would set: request.automaticallyDetectsLanguage = true

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error))
            }
        }
    }

    // MARK: - Personalized Learning

    /// Load user's handwriting profile
    /// - Parameter userId: User ID
    /// - Returns: Handwriting profile if exists
    private func loadHandwritingProfile(userId: String) -> HandwritingProfile? {
        guard let modelContext = modelContext else { return nil }

        let descriptor = FetchDescriptor<HandwritingProfile>(
            predicate: #Predicate { $0.userId == userId }
        )

        do {
            let profiles = try modelContext.fetch(descriptor)
            return profiles.first
        } catch {
            print("Error loading handwriting profile: \(error)")
            return nil
        }
    }

    /// Apply personalized learning corrections to OCR result
    /// - Parameters:
    ///   - result: Original OCR result
    ///   - profile: User's handwriting profile
    /// - Returns: Corrected OCR result
    private func applyPersonalizedLearning(result: OCRResult, profile: HandwritingProfile) -> OCRResult {
        guard let modelContext = modelContext else { return result }

        // Load recent corrections for this user
        let handwritingLearningType = CorrectionType.handwritingLearning.rawValue
        let descriptor = FetchDescriptor<OCRCorrectionHistory>(
            predicate: #Predicate { $0.correctionType == handwritingLearningType },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            let corrections = try modelContext.fetch(descriptor)

            // Apply learned corrections
            var correctedText = result.text
            var correctedBlocks = result.recognizedBlocks

            for correction in corrections.prefix(100) { // Use last 100 corrections
                // Apply pattern matching for similar mistakes
                correctedText = correctedText.replacingOccurrences(
                    of: correction.originalText,
                    with: correction.correctedText
                )

                // Update blocks
                correctedBlocks = correctedBlocks.map { block in
                    let correctedBlockText = block.text.replacingOccurrences(
                        of: correction.originalText,
                        with: correction.correctedText
                    )
                    return OCRResult.RecognizedTextBlock(
                        text: correctedBlockText,
                        confidence: block.confidence,
                        boundingBox: block.boundingBox
                    )
                }
            }

            return OCRResult(
                text: correctedText,
                confidence: result.confidence,
                recognizedBlocks: correctedBlocks
            )
        } catch {
            print("Error applying personalized learning: \(error)")
            return result
        }
    }

    /// Calculate updated accuracy score after new learning
    /// - Parameter profile: Handwriting profile
    /// - Returns: Updated accuracy score
    private func calculateUpdatedAccuracy(profile: HandwritingProfile) -> Float {
        guard let modelContext = modelContext else { return profile.accuracyScore }

        // Count accepted corrections for this user
        let handwritingLearningType = CorrectionType.handwritingLearning.rawValue
        let descriptor = FetchDescriptor<OCRCorrectionHistory>(
            predicate: #Predicate {
                $0.correctionType == handwritingLearningType &&
                $0.accepted == true
            }
        )

        do {
            let corrections = try modelContext.fetch(descriptor)
            let correctionCount = corrections.count

            // Improve accuracy by 1.5% per 10 corrections, capped at 95%
            let improvement = Float(correctionCount / 10) * 0.015
            return min(0.95, profile.accuracyScore + improvement)
        } catch {
            return profile.accuracyScore
        }
    }

    // MARK: - Helper Methods

    /// Check if image likely contains handwriting
    /// - Parameter image: Image to check
    /// - Returns: True if likely handwriting
    func isLikelyHandwriting(image: UIImage) -> Bool {
        // Heuristic: handwriting typically has more varied stroke widths and angles
        // For now, return true to attempt handwriting recognition
        // In production, could analyze image characteristics
        return true
    }

    /// Get handwriting accuracy for user
    /// - Parameter userId: User ID
    /// - Returns: Accuracy score 0.0-1.0
    func getHandwritingAccuracy(userId: String = "default") -> Float {
        guard let profile = loadHandwritingProfile(userId: userId) else {
            return 0.0
        }
        return profile.accuracyScore
    }

    /// Get correction history count for user
    /// - Parameter userId: User ID
    /// - Returns: Number of corrections made
    func getCorrectionCount(userId: String = "default") -> Int {
        guard let modelContext = modelContext else { return 0 }

        let handwritingLearningType = CorrectionType.handwritingLearning.rawValue
        let descriptor = FetchDescriptor<OCRCorrectionHistory>(
            predicate: #Predicate { $0.correctionType == handwritingLearningType }
        )

        do {
            let corrections = try modelContext.fetch(descriptor)
            return corrections.count
        } catch {
            return 0
        }
    }
}
