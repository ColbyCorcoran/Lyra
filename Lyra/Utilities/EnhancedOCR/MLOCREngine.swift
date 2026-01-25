//
//  MLOCREngine.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Engine 1
//  ML-based OCR with Vision fallback for chord chart recognition
//

import Foundation
import UIKit
import Vision
import CoreML

/// Engine for ML-based optical character recognition optimized for chord charts
@MainActor
class MLOCREngine {

    // MARK: - Properties

    private let fallbackProcessor = OCRProcessor.shared

    // Chord-specific custom words for better recognition
    private let chordVocabulary: [String] = [
        // Major chords
        "C", "D", "E", "F", "G", "A", "B",
        "C#", "D#", "E#", "F#", "G#", "A#", "B#",
        "Db", "Eb", "Fb", "Gb", "Ab", "Bb", "Cb",
        // Minor chords
        "Cm", "Dm", "Em", "Fm", "Gm", "Am", "Bm",
        "C#m", "D#m", "E#m", "F#m", "G#m", "A#m", "B#m",
        // 7th chords
        "C7", "D7", "E7", "F7", "G7", "A7", "B7",
        "Cmaj7", "Dmaj7", "Emaj7", "Fmaj7", "Gmaj7", "Amaj7", "Bmaj7",
        "Cm7", "Dm7", "Em7", "Fm7", "Gm7", "Am7", "Bm7",
        // Sus chords
        "Csus", "Dsus", "Esus", "Fsus", "Gsus", "Asus", "Bsus",
        "Csus2", "Dsus2", "Esus2", "Fsus2", "Gsus2", "Asus2", "Bsus2",
        "Csus4", "Dsus4", "Esus4", "Fsus4", "Gsus4", "Asus4", "Bsus4",
        // Add chords
        "Cadd9", "Dadd9", "Eadd9", "Fadd9", "Gadd9", "Aadd9", "Badd9",
        // Dim/Aug chords
        "Cdim", "Ddim", "Edim", "Fdim", "Gdim", "Adim", "Bdim",
        "Caug", "Daug", "Eaug", "Faug", "Gaug", "Aaug", "Baug",
        // Section labels
        "Verse", "Chorus", "Bridge", "Intro", "Outro", "Pre-Chorus",
        "Interlude", "Solo", "Instrumental", "Refrain",
        // Music terms
        "Capo", "Key", "Tempo", "BPM", "Time", "Signature"
    ]

    // MARK: - Public API

    /// Recognize text from image using ML model (with Vision fallback)
    /// - Parameter image: Image to process
    /// - Returns: OCR result with recognized text and blocks
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        // For now, use Vision fallback as ML model is not yet trained
        // In future phases, this will attempt ML model first
        return try await fallbackToVision(image: image)
    }

    /// Recognize text with enhanced chord-specific vocabulary
    /// - Parameters:
    ///   - image: Image to process
    ///   - customWords: Additional custom words beyond default vocabulary
    /// - Returns: OCR result
    func recognizeText(from image: UIImage, customWords: [String] = []) async throws -> OCRResult {
        let allCustomWords = chordVocabulary + customWords
        return try await performVisionOCR(image: image, customWords: allCustomWords)
    }

    // MARK: - ML Model (Future Implementation)

    /// Attempt to use custom Core ML model for chord recognition
    /// - Parameter image: Image to process
    /// - Returns: OCR result if successful, nil if model unavailable
    private func tryMLModel(image: UIImage) async -> OCRResult? {
        // TODO: Implement when custom Core ML model is trained
        // This would load and use a custom model trained specifically for chord charts
        //
        // Steps for future implementation:
        // 1. Load MLModel from bundle
        // 2. Prepare image for model input
        // 3. Run inference
        // 4. Parse output into OCRResult format
        // 5. Return result with confidence scores
        //
        // For now, return nil to trigger fallback
        return nil
    }

    // MARK: - Vision Fallback

    /// Fallback to Vision framework OCR
    /// - Parameter image: Image to process
    /// - Returns: OCR result from Vision
    private func fallbackToVision(image: UIImage) async throws -> OCRResult {
        return try await performVisionOCR(image: image, customWords: chordVocabulary)
    }

    /// Perform Vision-based text recognition with custom vocabulary
    /// - Parameters:
    ///   - image: Image to process
    ///   - customWords: Custom vocabulary for recognition
    /// - Returns: OCR result
    private func performVisionOCR(image: UIImage, customWords: [String]) async throws -> OCRResult {
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

            // Configure for optimal chord chart recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = false // Don't auto-correct chord names
            request.customWords = customWords

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error))
            }
        }
    }

    // MARK: - Confidence Scoring

    /// Calculate confidence score for recognized text
    /// - Parameters:
    ///   - result: OCR result
    ///   - context: Optional music theory context for validation
    /// - Returns: Adjusted confidence score
    func calculateConfidence(_ result: OCRResult, context: String? = nil) -> Float {
        var confidence = result.confidence

        // Boost confidence if recognized text contains valid chords
        let words = result.text.split(separator: " ")
        var validChordCount = 0

        for word in words {
            if chordVocabulary.contains(String(word)) {
                validChordCount += 1
            }
        }

        if !words.isEmpty {
            let chordRatio = Float(validChordCount) / Float(words.count)
            // Boost up to 10% if many valid chords found
            confidence = min(1.0, confidence + chordRatio * 0.1)
        }

        return confidence
    }

    // MARK: - Post-Processing

    /// Post-process OCR result to fix common mistakes
    /// - Parameter result: Raw OCR result
    /// - Returns: Cleaned OCR result
    func postProcess(_ result: OCRResult) -> OCRResult {
        // Fix common OCR mistakes in chord recognition
        let correctedText = correctCommonMistakes(result.text)

        var correctedBlocks: [OCRResult.RecognizedTextBlock] = []
        for block in result.recognizedBlocks {
            let correctedBlockText = correctCommonMistakes(block.text)
            correctedBlocks.append(OCRResult.RecognizedTextBlock(
                text: correctedBlockText,
                confidence: block.confidence,
                boundingBox: block.boundingBox
            ))
        }

        return OCRResult(
            text: correctedText,
            confidence: result.confidence,
            recognizedBlocks: correctedBlocks
        )
    }

    /// Correct common OCR mistakes in chord recognition
    /// - Parameter text: Original text
    /// - Returns: Corrected text
    private func correctCommonMistakes(_ text: String) -> String {
        var corrected = text

        // Common OCR mistakes for chord symbols
        let corrections: [String: String] = [
            "O": "D",  // O often misread as D chord
            "l": "I",  // lowercase L vs capital I
            "1": "I",  // number 1 vs capital I
            "0": "O",  // zero vs O
            "|": "I",  // pipe vs capital I
            "rn": "m", // "rn" often misread as "m"
        ]

        // Apply word-boundary corrections only to preserve intended text
        for (mistake, correction) in corrections {
            // Only correct if it appears to be a chord symbol
            let words = corrected.split(separator: " ")
            var correctedWords: [String] = []

            for word in words {
                var wordStr = String(word)
                // If word is short (likely a chord), apply corrections
                if wordStr.count <= 6 {
                    for (m, c) in corrections {
                        wordStr = wordStr.replacingOccurrences(of: m, with: c)
                    }
                }
                correctedWords.append(wordStr)
            }

            corrected = correctedWords.joined(separator: " ")
        }

        return corrected
    }

    // MARK: - Helper Methods

    /// Check if OCR result likely contains chord chart content
    /// - Parameter result: OCR result to check
    /// - Returns: True if likely a chord chart
    func isLikelyChordChart(_ result: OCRResult) -> Bool {
        let words = result.text.split(separator: " ")
        guard !words.isEmpty else { return false }

        var chordCount = 0
        for word in words {
            if chordVocabulary.contains(String(word)) {
                chordCount += 1
            }
        }

        // If more than 20% of words are recognized chords, likely a chord chart
        return chordCount > words.count / 5
    }
}
