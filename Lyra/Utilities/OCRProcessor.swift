//
//  OCRProcessor.swift
//  Lyra
//
//  Utility for extracting text from images using Vision framework
//

import Foundation
import UIKit
import Vision

/// Errors that can occur during OCR processing
enum OCRError: LocalizedError {
    case noTextFound
    case processingFailed
    case invalidImage
    case visionError(Error)

    var errorDescription: String? {
        switch self {
        case .noTextFound:
            return "No text found in image"
        case .processingFailed:
            return "OCR processing failed"
        case .invalidImage:
            return "Invalid image"
        case .visionError(let error):
            return "Vision error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noTextFound:
            return "Try improving image quality or adjusting lighting"
        case .processingFailed:
            return "Try scanning the page again with better focus"
        case .invalidImage:
            return "Make sure the image is valid and not corrupted"
        case .visionError:
            return "Try again or use manual text entry"
        }
    }
}

/// Result of OCR processing
struct OCRResult {
    let text: String
    let confidence: Float
    let recognizedBlocks: [RecognizedTextBlock]

    struct RecognizedTextBlock {
        let text: String
        let confidence: Float
        let boundingBox: CGRect
    }
}

@MainActor
class OCRProcessor {
    static let shared = OCRProcessor()

    private init() {}

    // MARK: - Public Methods

    /// Extract text from an image using Vision framework
    func extractText(from image: UIImage, progressHandler: ((Double) -> Void)? = nil) async throws -> OCRResult {
        progressHandler?(0.1)

        // Pre-process image for better OCR results
        guard let processedImage = preprocessImage(image) else {
            throw OCRError.invalidImage
        }

        progressHandler?(0.3)

        // Perform text recognition
        let result = try await performTextRecognition(on: processedImage, progressHandler: progressHandler)

        progressHandler?(1.0)

        return result
    }

    /// Extract text from multiple images (e.g., multi-page scan)
    func extractText(from images: [UIImage], progressHandler: ((Double) -> Void)? = nil) async throws -> OCRResult {
        var allText: [String] = []
        var allBlocks: [OCRResult.RecognizedTextBlock] = []
        var totalConfidence: Float = 0.0

        for (index, image) in images.enumerated() {
            let progress = Double(index) / Double(images.count)
            progressHandler?(progress)

            let result = try await extractText(from: image)
            allText.append(result.text)
            allBlocks.append(contentsOf: result.recognizedBlocks)
            totalConfidence += result.confidence
        }

        progressHandler?(1.0)

        let combinedText = allText.joined(separator: "\n\n--- Page Break ---\n\n")
        let averageConfidence = totalConfidence / Float(images.count)

        return OCRResult(
            text: combinedText,
            confidence: averageConfidence,
            recognizedBlocks: allBlocks
        )
    }

    // MARK: - Private Methods

    private func preprocessImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // Convert to grayscale for better OCR
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return image // Return original if preprocessing fails
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let processedCGImage = context.makeImage() else {
            return image
        }

        return UIImage(cgImage: processedCGImage)
    }

    private func performTextRecognition(on image: UIImage, progressHandler: ((Double) -> Void)? = nil) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        progressHandler?(0.5)

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
                    guard let topCandidate = observation.topCandidates(1).first else {
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

            // Configure request for optimal chord chart recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = false // Don't auto-correct chord names

            // Custom words for music terminology (helps with chord recognition)
            request.customWords = [
                // Chords
                "Cmaj7", "Dmaj7", "Emaj7", "Fmaj7", "Gmaj7", "Amaj7", "Bmaj7",
                "Cm7", "Dm7", "Em7", "Fm7", "Gm7", "Am7", "Bm7",
                "Csus4", "Dsus4", "Esus4", "Fsus4", "Gsus4", "Asus4", "Bsus4",
                "Cadd9", "Dadd9", "Eadd9", "Fadd9", "Gadd9", "Aadd9", "Badd9",
                "Cdim", "Ddim", "Edim", "Fdim", "Gdim", "Adim", "Bdim",
                "Caug", "Daug", "Eaug", "Faug", "Gaug", "Aaug", "Baug",
                // Common sections
                "Chorus", "Verse", "Bridge", "Intro", "Outro", "Pre-Chorus",
                "Interlude", "Solo", "Instrumental", "Refrain",
                // Common music terms
                "Capo", "Key", "Tempo", "Time", "Signature", "BPM"
            ]

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error))
            }
        }
    }

    // MARK: - Helper Methods

    /// Enhance OCR result by applying format conversion
    func enhanceOCRResult(_ text: String) -> String {
        // Try to detect and convert to ChordPro if possible
        do {
            return try FormatConverter.shared.convertTextToChordPro(text)
        } catch {
            // If conversion fails, return original text
            return text
        }
    }

    /// Estimate the quality of OCR result
    func estimateQuality(_ result: OCRResult) -> OCRQuality {
        if result.confidence >= 0.9 {
            return .excellent
        } else if result.confidence >= 0.7 {
            return .good
        } else if result.confidence >= 0.5 {
            return .fair
        } else {
            return .poor
        }
    }

    enum OCRQuality {
        case excellent
        case good
        case fair
        case poor

        var description: String {
            switch self {
            case .excellent:
                return "Excellent"
            case .good:
                return "Good"
            case .fair:
                return "Fair"
            case .poor:
                return "Poor - Manual review recommended"
            }
        }

        var color: UIColor {
            switch self {
            case .excellent:
                return .systemGreen
            case .good:
                return .systemBlue
            case .fair:
                return .systemOrange
            case .poor:
                return .systemRed
            }
        }
    }
}
