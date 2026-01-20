//
//  PDFTextExtractor.swift
//  Lyra
//
//  Utility for extracting text from PDFs, including OCR for scanned documents
//

import Foundation
import PDFKit
import Vision
import UIKit

enum PDFExtractionError: LocalizedError {
    case noPDFDocument
    case noTextFound
    case ocrFailed
    case invalidPage

    var errorDescription: String? {
        switch self {
        case .noPDFDocument:
            return "Unable to process PDF"
        case .noTextFound:
            return "No text found in PDF"
        case .ocrFailed:
            return "Text recognition failed"
        case .invalidPage:
            return "Invalid page number"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noPDFDocument:
            return "The PDF file may be corrupted."
        case .noTextFound:
            return "This PDF may be a scanned image. Try using OCR."
        case .ocrFailed:
            return "OCR quality may be low. You can edit the results manually."
        case .invalidPage:
            return "Please select a valid page number."
        }
    }
}

struct PDFExtractionResult {
    let text: String
    let method: ExtractionMethod
    let pageCount: Int
    let isComplete: Bool // true if all pages processed

    enum ExtractionMethod {
        case embedded  // Text was embedded in PDF
        case ocr       // Text was extracted via OCR
        case mixed     // Some pages embedded, some OCR
    }
}

@MainActor
class PDFTextExtractor {

    /// Extract text from PDF document
    /// - Parameters:
    ///   - document: The PDF document
    ///   - useOCR: If true, use OCR even if embedded text exists
    ///   - pageLimit: Maximum number of pages to process (nil = all pages)
    ///   - progress: Progress callback (0.0 to 1.0)
    /// - Returns: Extraction result with text and metadata
    static func extractText(
        from document: PDFDocument,
        useOCR: Bool = false,
        pageLimit: Int? = nil,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> PDFExtractionResult {

        let pageCount = document.pageCount
        guard pageCount > 0 else {
            throw PDFExtractionError.noPDFDocument
        }

        progress?(0.0, "Starting extraction...")

        // Try embedded text first unless OCR is forced
        if !useOCR {
            if let embeddedText = document.string, !embeddedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Check if text is substantial (not just whitespace or minimal text)
                let meaningfulText = embeddedText.trimmingCharacters(in: .whitespacesAndNewlines)
                if meaningfulText.count > 50 { // At least 50 characters
                    progress?(1.0, "Text extracted successfully")
                    return PDFExtractionResult(
                        text: meaningfulText,
                        method: .embedded,
                        pageCount: pageCount,
                        isComplete: true
                    )
                }
            }
        }

        // Fall back to OCR
        progress?(0.1, "Preparing OCR...")

        let pagesToProcess = min(pageLimit ?? pageCount, pageCount)
        var extractedTexts: [String] = []

        for pageIndex in 0..<pagesToProcess {
            let pageProgress = Double(pageIndex) / Double(pagesToProcess)
            progress?(0.1 + (pageProgress * 0.9), "Processing page \(pageIndex + 1) of \(pagesToProcess)...")

            guard let page = document.page(at: pageIndex) else {
                continue
            }

            if let pageText = try await ocrPage(page) {
                extractedTexts.append(pageText)
            }
        }

        progress?(1.0, "Extraction complete")

        let combinedText = extractedTexts.joined(separator: "\n\n")

        guard !combinedText.isEmpty else {
            throw PDFExtractionError.noTextFound
        }

        return PDFExtractionResult(
            text: combinedText,
            method: .ocr,
            pageCount: pageCount,
            isComplete: pagesToProcess == pageCount
        )
    }

    /// Perform OCR on a single PDF page
    private static func ocrPage(_ page: PDFPage) async throws -> String? {
        // Render page to image
        let pageBounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0 // Higher resolution for better OCR
        let renderer = UIGraphicsImageRenderer(size: CGSize(
            width: pageBounds.width * scale,
            height: pageBounds.height * scale
        ))

        let image = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: renderer.format.bounds.size))

            context.cgContext.translateBy(x: 0, y: renderer.format.bounds.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }

        guard let cgImage = image.cgImage else {
            return nil
        }

        // Perform OCR using Vision
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let text = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: text.isEmpty ? nil : text)
            }

            // Configure for best accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Process extracted text into ChordPro format
    static func processToChordPro(_ text: String, title: String, artist: String? = nil) -> String {
        var lines = text.components(separatedBy: .newlines)
        var result: [String] = []

        // Add metadata directives
        result.append("{title: \(title)}")
        if let artist = artist {
            result.append("{artist: \(artist)}")
        }
        result.append("")

        // Process lines
        var currentSection: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines initially
            if trimmed.isEmpty {
                if !result.isEmpty && result.last != "" {
                    result.append("")
                }
                continue
            }

            // Detect section headers (Verse, Chorus, Bridge, etc.)
            if let section = detectSection(trimmed) {
                currentSection = section
                result.append("{\(section)}")
                continue
            }

            // Detect chords on their own line
            if isChordLine(trimmed) {
                result.append(formatChordLine(trimmed))
                continue
            }

            // Regular lyrics line
            result.append(trimmed)
        }

        return result.joined(separator: "\n")
    }

    /// Detect if a line is a section header
    private static func detectSection(_ line: String) -> String? {
        let lower = line.lowercased()

        // Common section patterns
        let patterns: [(pattern: String, section: String)] = [
            ("verse", "verse"),
            ("chorus", "chorus"),
            ("bridge", "bridge"),
            ("intro", "intro"),
            ("outro", "outro"),
            ("pre-chorus", "prechorus"),
            ("prechorus", "prechorus"),
            ("tag", "tag"),
            ("interlude", "interlude"),
            ("refrain", "chorus")
        ]

        for (pattern, section) in patterns {
            if lower.contains(pattern) {
                // Check if it's a standalone label (not part of lyrics)
                let words = line.split(separator: " ")
                if words.count <= 3 { // Short line, likely a label
                    return section
                }
            }
        }

        return nil
    }

    /// Detect if a line contains only chords
    private static func isChordLine(_ line: String) -> Bool {
        let words = line.split(separator: " ")

        // Need at least 2 words to be a chord line
        guard words.count >= 2 else { return false }

        // Check if majority are chord-like
        var chordCount = 0
        for word in words {
            if looksLikeChord(String(word)) {
                chordCount += 1
            }
        }

        // If 70% or more look like chords, it's a chord line
        return Double(chordCount) / Double(words.count) >= 0.7
    }

    /// Check if a string looks like a chord
    private static func looksLikeChord(_ str: String) -> Bool {
        // Common chord patterns
        let chordPattern = "^[A-G][#b]?(m|maj|min|dim|aug|sus)?[0-9]*(add|sus|dim|aug)?[0-9]*$"

        do {
            let regex = try NSRegularExpression(pattern: chordPattern, options: .caseInsensitive)
            let range = NSRange(str.startIndex..., in: str)
            return regex.firstMatch(in: str, options: [], range: range) != nil
        } catch {
            return false
        }
    }

    /// Format a chord line into ChordPro format
    private static func formatChordLine(_ line: String) -> String {
        let words = line.split(separator: " ")
        return words.map { "[\($0)]" }.joined(separator: " ")
    }

    /// Quick check if PDF has embedded text
    static func hasEmbeddedText(_ document: PDFDocument) -> Bool {
        guard let text = document.string else { return false }
        let meaningful = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return meaningful.count > 50
    }

    /// Estimate OCR time based on page count
    static func estimateOCRTime(pageCount: Int) -> String {
        let secondsPerPage = 3.0
        let totalSeconds = Double(pageCount) * secondsPerPage

        if totalSeconds < 60 {
            return "\(Int(totalSeconds)) seconds"
        } else {
            let minutes = Int(totalSeconds / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}
