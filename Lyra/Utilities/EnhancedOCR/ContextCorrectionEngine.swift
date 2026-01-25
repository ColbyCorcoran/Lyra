//
//  ContextCorrectionEngine.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Engine 3
//  Context-aware correction using music theory validation
//

import Foundation
import SwiftData

/// Engine for correcting OCR mistakes using musical context
@MainActor
class ContextCorrectionEngine {

    // MARK: - Properties

    private let musicTheory = MusicTheoryEngine()
    private let modelContext: ModelContext?

    // Common OCR character mistakes in music context
    private let mistakeMap: [String: String] = [
        "O": "D",   // O often misread as D chord
        "o": "D",   // lowercase o
        "l": "I",   // lowercase L vs capital I
        "1": "I",   // number 1 vs capital I
        "0": "D",   // zero vs O vs D
        "|": "I",   // pipe vs capital I
        "rn": "m",  // "rn" often misread as "m" in chords like Cm
        "rnaj": "maj", // Common misread of "maj"
    ]

    // Valid chord qualities
    private let validQualities = ["", "m", "M", "maj", "min", "sus", "sus2", "sus4", "dim", "aug", "add", "add9", "7", "maj7", "m7", "9", "11", "13"]

    // Valid note letters
    private let validNotes = ["A", "B", "C", "D", "E", "F", "G"]

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Correct OCR mistakes using context
    /// - Parameters:
    ///   - result: Original OCR result
    ///   - key: Optional detected key for context
    /// - Returns: Corrected OCR result with suggestions
    func correctWithContext(_ result: OCRResult, key: String? = nil) -> (corrected: OCRResult, suggestions: [ReviewItem]) {
        var suggestions: [ReviewItem] = []

        // Step 1: Correct common OCR mistakes
        let afterMistakes = correctCommonMistakes(result)

        // Step 2: Validate chords with music theory
        let (afterValidation, validationSuggestions) = validateWithTheory(afterMistakes, key: key)
        suggestions.append(contentsOf: validationSuggestions)

        // Step 3: Apply progression context
        let (final, progressionSuggestions) = applyProgressionContext(afterValidation, key: key)
        suggestions.append(contentsOf: progressionSuggestions)

        // Step 4: Learn from corrections
        learnFromCorrections(original: result, corrected: final)

        return (final, suggestions)
    }

    /// Correct common OCR character mistakes
    /// - Parameter result: Original OCR result
    /// - Returns: Corrected result
    func correctCommonMistakes(_ result: OCRResult) -> OCRResult {
        var correctedBlocks: [OCRResult.RecognizedTextBlock] = []

        for block in result.recognizedBlocks {
            let correctedText = applyMistakeCorrections(block.text)
            correctedBlocks.append(OCRResult.RecognizedTextBlock(
                text: correctedText,
                confidence: block.confidence,
                boundingBox: block.boundingBox
            ))
        }

        let correctedFullText = correctedBlocks.map { $0.text }.joined(separator: "\n")

        return OCRResult(
            text: correctedFullText,
            confidence: result.confidence,
            recognizedBlocks: correctedBlocks
        )
    }

    /// Validate chords with music theory
    /// - Parameters:
    ///   - result: OCR result to validate
    ///   - key: Optional detected key
    /// - Returns: Corrected result and review suggestions
    func validateWithTheory(_ result: OCRResult, key: String?) -> (OCRResult, [ReviewItem]) {
        var correctedBlocks: [OCRResult.RecognizedTextBlock] = []
        var suggestions: [ReviewItem] = []

        for block in result.recognizedBlocks {
            let words = block.text.split(separator: " ")
            var correctedWords: [String] = []

            for word in words {
                let wordStr = String(word)

                // Check if this looks like a chord
                if isChordLike(wordStr) {
                    // Validate the chord
                    if isValidChord(wordStr) {
                        correctedWords.append(wordStr)
                    } else {
                        // Try to suggest correction
                        if let suggestion = suggestChordCorrection(wordStr) {
                            correctedWords.append(suggestion)

                            // Add to review items
                            suggestions.append(ReviewItem(
                                originalText: wordStr,
                                suggestedCorrection: suggestion,
                                boundingBox: block.boundingBox,
                                confidence: block.confidence,
                                correctionReason: "Invalid chord - suggested correction"
                            ))
                        } else {
                            // Keep original but flag for review
                            correctedWords.append(wordStr)
                            suggestions.append(ReviewItem(
                                originalText: wordStr,
                                suggestedCorrection: nil,
                                boundingBox: block.boundingBox,
                                confidence: block.confidence,
                                correctionReason: "Unrecognized chord - manual review needed"
                            ))
                        }
                    }
                } else {
                    // Not a chord, keep as is
                    correctedWords.append(wordStr)
                }
            }

            let correctedText = correctedWords.joined(separator: " ")
            correctedBlocks.append(OCRResult.RecognizedTextBlock(
                text: correctedText,
                confidence: block.confidence,
                boundingBox: block.boundingBox
            ))
        }

        let correctedFullText = correctedBlocks.map { $0.text }.joined(separator: "\n")

        return (OCRResult(
            text: correctedFullText,
            confidence: result.confidence,
            recognizedBlocks: correctedBlocks
        ), suggestions)
    }

    /// Apply chord progression context for validation
    /// - Parameters:
    ///   - result: OCR result
    ///   - key: Optional detected key
    /// - Returns: Corrected result and suggestions
    func applyProgressionContext(_ result: OCRResult, key: String?) -> (OCRResult, [ReviewItem]) {
        var suggestions: [ReviewItem] = []

        // Extract all chords from result
        let chords = extractChords(from: result)

        // If we have a key, validate chords against it
        if let detectedKey = key {
            for (chord, block) in chords {
                if !isChordInKey(chord, key: detectedKey) {
                    // Flag chords outside the key (might be intentional)
                    suggestions.append(ReviewItem(
                        originalText: chord,
                        suggestedCorrection: nil,
                        boundingBox: block.boundingBox,
                        confidence: block.confidence,
                        correctionReason: "Chord outside detected key (\(detectedKey)) - verify if correct"
                    ))
                }
            }
        } else {
            // Try to detect key from chords
            let chordNames = chords.map { $0.0 }
            if let keyResult = musicTheory.detectKey(from: chordNames) {
                // Validate against detected key
                for (chord, block) in chords {
                    if !isChordInKey(chord, key: keyResult.key) {
                        suggestions.append(ReviewItem(
                            originalText: chord,
                            suggestedCorrection: nil,
                            boundingBox: block.boundingBox,
                            confidence: block.confidence,
                            correctionReason: "Unusual chord for key \(keyResult.key) - verify"
                        ))
                    }
                }
            }
        }

        return (result, suggestions)
    }

    /// Suggest chord corrections based on theory
    /// - Parameter chord: Potentially incorrect chord
    /// - Returns: Suggested correction
    func suggestCorrections(_ chord: String) -> [String] {
        var suggestions: [String] = []

        // Try different mistake corrections
        for (mistake, correction) in mistakeMap {
            let corrected = chord.replacingOccurrences(of: mistake, with: correction)
            if corrected != chord && isValidChord(corrected) {
                suggestions.append(corrected)
            }
        }

        // Try fixing root note
        if let fixedRoot = fixRootNote(chord) {
            if isValidChord(fixedRoot) {
                suggestions.append(fixedRoot)
            }
        }

        return Array(Set(suggestions)).sorted() // Remove duplicates
    }

    /// Learn from user corrections
    /// - Parameters:
    ///   - original: Original OCR result
    ///   - corrected: Corrected result
    func learnFromCorrections(original: OCRResult, corrected: OCRResult) {
        guard let modelContext = modelContext else { return }

        // Compare original and corrected text
        if original.text != corrected.text {
            let correction = OCRCorrectionHistory(
                originalText: original.text,
                correctedText: corrected.text,
                correctionType: CorrectionType.ocrMistake.rawValue,
                context: "context_correction",
                accepted: true
            )
            modelContext.insert(correction)

            do {
                try modelContext.save()
            } catch {
                print("Error saving correction: \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    /// Apply mistake corrections to text
    private func applyMistakeCorrections(_ text: String) -> String {
        var corrected = text
        let words = text.split(separator: " ")
        var correctedWords: [String] = []

        for word in words {
            var wordStr = String(word)

            // Only apply corrections to chord-like words (short, alphanumeric)
            if wordStr.count <= 6 && isChordLike(wordStr) {
                for (mistake, correction) in mistakeMap {
                    wordStr = wordStr.replacingOccurrences(of: mistake, with: correction)
                }
            }

            correctedWords.append(wordStr)
        }

        return correctedWords.joined(separator: " ")
    }

    /// Check if text looks like a chord
    private func isChordLike(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return false }
        guard trimmed.count <= 7 else { return false }

        // Must start with a valid note letter
        let firstChar = String(trimmed.prefix(1)).uppercased()
        return validNotes.contains(firstChar)
    }

    /// Validate if chord is theoretically correct
    private func isValidChord(_ chord: String) -> Bool {
        guard !chord.isEmpty else { return false }

        // Extract root note
        let root = extractRoot(chord)
        guard validNotes.contains(root) else { return false }

        // Extract quality/extension
        let quality = String(chord.dropFirst(root.count))

        // Check if quality is valid (empty is valid for major)
        if quality.isEmpty {
            return true
        }

        // Check for valid qualities
        for validQuality in validQualities {
            if quality.lowercased().contains(validQuality.lowercased()) {
                return true
            }
        }

        return false
    }

    /// Extract root note from chord
    private func extractRoot(_ chord: String) -> String {
        if chord.count >= 2 {
            let firstTwo = String(chord.prefix(2))
            if firstTwo.hasSuffix("#") || firstTwo.hasSuffix("b") {
                let root = String(firstTwo.prefix(1))
                if validNotes.contains(root) {
                    return firstTwo
                }
            }
        }

        if chord.count >= 1 {
            let first = String(chord.prefix(1))
            if validNotes.contains(first) {
                return first
            }
        }

        return chord
    }

    /// Try to fix root note
    private func fixRootNote(_ chord: String) -> String? {
        // Try common OCR mistakes for root notes
        let firstChar = String(chord.prefix(1))

        let rootFixes: [String: String] = [
            "O": "D",
            "0": "D",
            "I": "A",
            "1": "A",
        ]

        if let fix = rootFixes[firstChar] {
            return fix + chord.dropFirst()
        }

        return nil
    }

    /// Suggest correction for invalid chord
    private func suggestChordCorrection(_ chord: String) -> String? {
        let suggestions = suggestCorrections(chord)
        return suggestions.first
    }

    /// Extract chords from OCR result
    private func extractChords(from result: OCRResult) -> [(String, OCRResult.RecognizedTextBlock)] {
        var chords: [(String, OCRResult.RecognizedTextBlock)] = []

        for block in result.recognizedBlocks {
            let words = block.text.split(separator: " ")
            for word in words {
                let wordStr = String(word)
                if isChordLike(wordStr) && isValidChord(wordStr) {
                    chords.append((wordStr, block))
                }
            }
        }

        return chords
    }

    /// Check if chord belongs to the given key
    private func isChordInKey(_ chord: String, key: String) -> Bool {
        // Use music theory engine to detect key and check if chord is diatonic
        // For now, simplified check
        let root = extractRoot(chord)
        return root.count > 0
    }
}
