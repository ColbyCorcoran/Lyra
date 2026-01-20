//
//  FormatConverter.swift
//  Lyra
//
//  Utility for converting various file formats to ChordPro
//

import Foundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Errors that can occur during format conversion
enum FormatConversionError: LocalizedError {
    case unsupportedFormat
    case invalidXML
    case unableToReadFile
    case noContentFound
    case conversionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported file format"
        case .invalidXML:
            return "Invalid XML structure"
        case .unableToReadFile:
            return "Unable to read file"
        case .noContentFound:
            return "No content found in file"
        case .conversionFailed(let reason):
            return "Conversion failed: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unsupportedFormat:
            return "Try converting the file to .txt or .cho format first"
        case .invalidXML:
            return "Check that the XML file is properly formatted"
        case .unableToReadFile:
            return "Check file permissions and encoding"
        case .noContentFound:
            return "The file appears to be empty"
        case .conversionFailed:
            return "Try importing as plain text instead"
        }
    }
}

/// Format detection result
struct DetectedFormat {
    let type: FormatType
    let confidence: Double // 0.0 to 1.0

    enum FormatType {
        case chordPro
        case openSong
        case chordsOverLyrics // Traditional format with chords on separate lines
        case inlineChords // [C]word format
        case plainText
        case rtf
        case word
    }
}

class FormatConverter {
    static let shared = FormatConverter()

    private init() {}

    // MARK: - Main Conversion Entry Point

    /// Convert any supported format to ChordPro
    func convertToChordPro(from url: URL) throws -> String {
        let fileExtension = url.pathExtension.lowercased()

        switch fileExtension {
        case "rtf":
            return try convertRTFToChordPro(from: url)
        case "doc", "docx":
            return try convertWordToChordPro(from: url)
        case "xml":
            return try convertOpenSongToChordPro(from: url)
        case "txt", "cho", "chordpro", "chopro", "crd", "onsong":
            // Read as text and detect format
            guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                throw FormatConversionError.unableToReadFile
            }
            return try convertTextToChordPro(content)
        default:
            throw FormatConversionError.unsupportedFormat
        }
    }

    /// Detect the format of text content
    func detectFormat(_ content: String) -> DetectedFormat {
        let lines = content.components(separatedBy: .newlines)

        // Check for ChordPro
        if content.contains("{title:") || content.contains("{t:") ||
           content.contains("{start_of_chorus}") || content.contains("{soc}") {
            return DetectedFormat(type: .chordPro, confidence: 1.0)
        }

        // Check for OpenSong XML
        if content.contains("<song>") && content.contains("</song>") {
            return DetectedFormat(type: .openSong, confidence: 1.0)
        }

        // Check for inline chords [C]word
        let inlineChordPattern = #"\[[A-G][#b]?(?:m|maj|dim|aug|sus)?[0-9]?\]"#
        if let regex = try? NSRegularExpression(pattern: inlineChordPattern, options: []) {
            let matches = regex.numberOfMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
            if matches > 0 {
                let confidence = min(Double(matches) / Double(lines.count), 1.0)
                return DetectedFormat(type: .inlineChords, confidence: confidence)
            }
        }

        // Check for chords over lyrics
        var chordLineCount = 0
        for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            if isChordLine(line) {
                chordLineCount += 1
            }
        }

        if chordLineCount > 0 {
            let confidence = Double(chordLineCount) / Double(lines.count)
            return DetectedFormat(type: .chordsOverLyrics, confidence: min(confidence * 2, 1.0))
        }

        return DetectedFormat(type: .plainText, confidence: 0.5)
    }

    // MARK: - RTF Conversion

    func convertRTFToChordPro(from url: URL) throws -> String {
        #if canImport(UIKit)
        guard let attributedString = try? NSAttributedString(
            url: url,
            options: [.documentType: NSAttributedString.DocumentType.rtf as Any],
            documentAttributes: nil
        ) else {
            throw FormatConversionError.unableToReadFile
        }
        #elseif canImport(AppKit)
        guard let attributedString = try? NSAttributedString(
            url: url,
            documentAttributes: nil
        ) else {
            throw FormatConversionError.unableToReadFile
        }
        #else
        throw FormatConversionError.unableToReadFile
        #endif

        let plainText = attributedString.string
        return try convertTextToChordPro(plainText)
    }

    // MARK: - Word Document Conversion

    func convertWordToChordPro(from url: URL) throws -> String {
        // For .docx (which is actually a ZIP file with XML)
        if url.pathExtension.lowercased() == "docx" {
            return try convertDocxToChordPro(from: url)
        }

        // For .doc (older binary format), try reading as RTF or plain text
        // This is a best-effort approach
        #if canImport(UIKit) || canImport(AppKit)
        if let attributedString = try? NSAttributedString(
            url: url,
            documentAttributes: nil
        ) {
            let plainText = attributedString.string
            return try convertTextToChordPro(plainText)
        }
        #endif

        throw FormatConversionError.unableToReadFile
    }

    private func convertDocxToChordPro(from url: URL) throws -> String {
        // .docx is a ZIP file containing XML files
        // The main content is in word/document.xml
        // Note: NSAttributedString doesn't support .docx on iOS
        // This is a simplified fallback that attempts to read as plain text

        // Try to read as plain text (won't preserve formatting)
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            // Clean up XML if present
            if content.contains("<?xml") {
                // Extract text between XML tags (very basic)
                let cleanedContent = content.replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
                    .replacingOccurrences(of: "\n\n+", with: "\n\n", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return try convertTextToChordPro(cleanedContent)
            }
            return try convertTextToChordPro(content)
        }

        throw FormatConversionError.unableToReadFile
    }

    // MARK: - OpenSong XML Conversion

    func convertOpenSongToChordPro(from url: URL) throws -> String {
        guard let xmlData = try? Data(contentsOf: url) else {
            throw FormatConversionError.unableToReadFile
        }

        guard let xmlString = String(data: xmlData, encoding: .utf8) else {
            throw FormatConversionError.unableToReadFile
        }

        return try parseOpenSongXML(xmlString)
    }

    private func parseOpenSongXML(_ xmlString: String) throws -> String {
        var chordProLines: [String] = []

        // Extract title
        if let title = extractXMLTag("title", from: xmlString) {
            chordProLines.append("{title: \(title)}")
        }

        // Extract author/artist
        if let author = extractXMLTag("author", from: xmlString) {
            chordProLines.append("{artist: \(author)}")
        }

        // Extract key
        if let key = extractXMLTag("key", from: xmlString) {
            chordProLines.append("{key: \(key)}")
        }

        // Extract tempo
        if let tempo = extractXMLTag("tempo", from: xmlString) {
            chordProLines.append("{tempo: \(tempo)}")
        }

        // Extract capo
        if let capo = extractXMLTag("capo", from: xmlString) {
            chordProLines.append("{capo: \(capo)}")
        }

        chordProLines.append("")

        // Extract and convert lyrics
        if let lyrics = extractXMLTag("lyrics", from: xmlString) {
            let convertedLyrics = convertOpenSongLyrics(lyrics)
            chordProLines.append(convertedLyrics)
        } else {
            throw FormatConversionError.noContentFound
        }

        return chordProLines.joined(separator: "\n")
    }

    private func convertOpenSongLyrics(_ lyrics: String) -> String {
        var result: [String] = []
        let lines = lyrics.components(separatedBy: .newlines)

        var inChorus = false
        var inVerse = false
        var inBridge = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Handle section markers
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let section = trimmed.dropFirst().dropLast().lowercased()

                // End previous section
                if inChorus {
                    result.append("{end_of_chorus}")
                    inChorus = false
                } else if inVerse {
                    inVerse = false
                } else if inBridge {
                    result.append("{end_of_bridge}")
                    inBridge = false
                }

                // Start new section
                if section.contains("chorus") {
                    result.append("{start_of_chorus}")
                    inChorus = true
                } else if section.contains("bridge") {
                    result.append("{start_of_bridge}")
                    inBridge = true
                } else if section.contains("verse") {
                    inVerse = true
                    result.append("{comment: \(section.capitalized)}")
                } else {
                    result.append("{comment: \(trimmed)}")
                }
                result.append("")
                continue
            }

            // Convert OpenSong chord notation to ChordPro
            // OpenSong uses . for chord markers: .C.Am.F.G
            let convertedLine = convertOpenSongChords(trimmed)
            result.append(convertedLine)
        }

        // Close any open sections
        if inChorus {
            result.append("{end_of_chorus}")
        } else if inBridge {
            result.append("{end_of_bridge}")
        }

        return result.joined(separator: "\n")
    }

    private func convertOpenSongChords(_ line: String) -> String {
        // OpenSong format: .C.Am.F.G with words
        // Convert to ChordPro: [C]word [Am]word [F]word [G]word

        var result = ""
        var currentIndex = line.startIndex
        var nextChord: String?

        while currentIndex < line.endIndex {
            let char = line[currentIndex]

            if char == "." {
                // Found a chord marker
                var chordEndIndex = line.index(after: currentIndex)

                // Collect chord characters
                while chordEndIndex < line.endIndex {
                    let nextChar = line[chordEndIndex]
                    if nextChar == "." || nextChar == " " {
                        break
                    }
                    chordEndIndex = line.index(after: chordEndIndex)
                }

                let chord = String(line[line.index(after: currentIndex)..<chordEndIndex])
                if !chord.isEmpty {
                    nextChord = chord
                }

                currentIndex = chordEndIndex
                continue
            }

            // If we have a pending chord and hit a non-space character
            if let chord = nextChord, !char.isWhitespace {
                result += "[\(chord)]"
                nextChord = nil
            }

            result.append(char)
            currentIndex = line.index(after: currentIndex)
        }

        // If line ends with a chord, add it
        if let chord = nextChord {
            result += "[\(chord)]"
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    private func extractXMLTag(_ tag: String, from xml: String) -> String? {
        let pattern = "<\(tag)>(.*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }

        let nsString = xml as NSString
        guard let match = regex.firstMatch(in: xml, range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }

        guard match.numberOfRanges > 1 else { return nil }
        let range = match.range(at: 1)
        let value = nsString.substring(with: range)

        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Text to ChordPro Conversion

    func convertTextToChordPro(_ content: String) throws -> String {
        let format = detectFormat(content)

        switch format.type {
        case .chordPro:
            // Already in ChordPro format
            return content

        case .openSong:
            return try parseOpenSongXML(content)

        case .inlineChords:
            return convertInlineChordsToChordPro(content)

        case .chordsOverLyrics:
            return convertChordsOverLyricsToChordPro(content)

        case .plainText, .rtf, .word:
            // Best effort: treat as plain text, look for title in first line
            return convertPlainTextToChordPro(content)
        }
    }

    // MARK: - Inline Chords Conversion

    private func convertInlineChordsToChordPro(_ content: String) -> String {
        var lines = content.components(separatedBy: .newlines)

        // Try to extract title from first line if it looks like a title
        if let firstLine = lines.first?.trimmingCharacters(in: .whitespaces),
           !firstLine.isEmpty,
           !firstLine.contains("["),
           firstLine.count < 100 {
            lines[0] = "{title: \(firstLine)}"
            lines.insert("", at: 1)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Chords Over Lyrics Conversion

    private func convertChordsOverLyricsToChordPro(_ content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var result: [String] = []

        var i = 0
        while i < lines.count {
            let currentLine = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines
            if currentLine.isEmpty {
                result.append("")
                i += 1
                continue
            }

            // Check if this is the first line (potential title)
            if i == 0 && !isChordLine(currentLine) && currentLine.count < 100 {
                result.append("{title: \(currentLine)}")
                result.append("")
                i += 1
                continue
            }

            // Check if this is a chord line
            if isChordLine(currentLine) {
                // Look ahead for the lyrics line
                if i + 1 < lines.count {
                    let nextLine = lines[i + 1]
                    let mergedLine = mergeChordsWithLyrics(chords: currentLine, lyrics: nextLine)
                    result.append(mergedLine)
                    i += 2 // Skip both lines
                    continue
                } else {
                    // Chord line at end of file
                    result.append("{comment: \(currentLine)}")
                    i += 1
                    continue
                }
            }

            // Regular lyric line without chords above
            result.append(currentLine)
            i += 1
        }

        return result.joined(separator: "\n")
    }

    private func isChordLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Empty line is not a chord line
        if trimmed.isEmpty {
            return false
        }

        // Split by spaces and check each word
        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Need at least one word
        guard !words.isEmpty else { return false }

        // Check what percentage of words are chords
        let chordCount = words.filter { isChord($0) }.count
        let percentage = Double(chordCount) / Double(words.count)

        // If >70% of words are chords, it's likely a chord line
        return percentage > 0.7
    }

    private func isChord(_ word: String) -> Bool {
        // Remove common punctuation
        let cleaned = word.trimmingCharacters(in: CharacterSet(charactersIn: "()[]{}|"))

        // Check if it matches chord pattern
        let chordPattern = #"^[A-G][#b]?(m|maj|min|dim|aug|sus)?[0-9]?(/[A-G][#b]?)?$"#

        return cleaned.range(of: chordPattern, options: .regularExpression) != nil
    }

    private func mergeChordsWithLyrics(chords: String, lyrics: String) -> String {
        var result = ""
        var chordIndex = chords.startIndex
        var lyricIndex = lyrics.startIndex

        var currentChord = ""
        var inChord = false

        // Parse chords by position
        while chordIndex < chords.endIndex || lyricIndex < lyrics.endIndex {
            // Get current position
            let position = chords.distance(from: chords.startIndex, to: chordIndex)

            // Collect chord at this position
            if chordIndex < chords.endIndex {
                let char = chords[chordIndex]
                if char.isWhitespace {
                    if !currentChord.isEmpty {
                        inChord = false
                    }
                } else {
                    currentChord.append(char)
                    inChord = true
                }
                chordIndex = chords.index(after: chordIndex)
            }

            // Add chord to result at lyric position
            if !currentChord.isEmpty && !inChord && lyricIndex < lyrics.endIndex {
                let lyricChar = lyrics[lyricIndex]
                if !lyricChar.isWhitespace {
                    result += "[\(currentChord)]"
                    currentChord = ""
                }
            }

            // Add lyric character if we're at the right position
            if lyricIndex < lyrics.endIndex {
                let lyricPosition = lyrics.distance(from: lyrics.startIndex, to: lyricIndex)
                if lyricPosition >= position {
                    result.append(lyrics[lyricIndex])
                    lyricIndex = lyrics.index(after: lyricIndex)
                }
            }
        }

        // Add any remaining chord
        if !currentChord.isEmpty {
            result += "[\(currentChord)]"
        }

        return result
    }

    // MARK: - Plain Text Conversion

    private func convertPlainTextToChordPro(_ content: String) -> String {
        let lines = content.components(separatedBy: .newlines)

        // Try to use first non-empty line as title
        if let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
           firstLine.count < 100 {
            var result = "{title: \(firstLine.trimmingCharacters(in: .whitespaces))}\n\n"

            // Add remaining lines
            let remainingLines = lines.dropFirst().joined(separator: "\n")
            result += remainingLines

            return result
        }

        return content
    }

    // MARK: - Helper Methods

    private func matches(of pattern: String, options: NSRegularExpression.Options, in string: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return 0
        }

        let range = NSRange(location: 0, length: string.utf16.count)
        return regex.numberOfMatches(in: string, range: range)
    }
}

// MARK: - String Extension

extension String {
    func matches(of pattern: String, options: NSRegularExpression.Options) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return 0
        }

        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.numberOfMatches(in: self, range: range)
    }
}
