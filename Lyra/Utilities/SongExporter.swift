//
//  SongExporter.swift
//  Lyra
//
//  Created by Claude on 2026-01-29.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
import UIKit
import CoreText

/// Utility class for exporting songs to various formats
@MainActor
class SongExporter {

    // MARK: - Export Formats

    /// Supported export formats
    enum ExportFormat: String, CaseIterable {
        case chordPro = "cho"
        case pdf = "pdf"
        case plainText = "txt"
        case lyraBundle = "lyra"
        case json = "json"

        var displayName: String {
            switch self {
            case .chordPro: return "ChordPro"
            case .pdf: return "PDF"
            case .plainText: return "Plain Text"
            case .lyraBundle: return "Lyra Bundle"
            case .json: return "JSON"
            }
        }

        var utType: UTType {
            switch self {
            case .chordPro: return .plainText
            case .pdf: return .pdf
            case .plainText: return .plainText
            case .lyraBundle: return .json
            case .json: return .json
            }
        }

        var fileExtension: String {
            return rawValue
        }
    }

    // MARK: - Errors

    /// Errors that can occur during export
    enum SongExportError: LocalizedError {
        case invalidSongData
        case encodingFailed
        case fileWriteFailed(Error)
        case unsupportedFormat
        case emptyContent
        case pdfRenderingFailed

        var errorDescription: String? {
            switch self {
            case .invalidSongData:
                return "Invalid song data"
            case .encodingFailed:
                return "Failed to encode song data"
            case .fileWriteFailed(let error):
                return "Failed to write file: \(error.localizedDescription)"
            case .unsupportedFormat:
                return "Unsupported export format"
            case .emptyContent:
                return "Song has no content to export"
            case .pdfRenderingFailed:
                return "Failed to render PDF"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .invalidSongData:
                return "Ensure the song has valid data before exporting."
            case .encodingFailed:
                return "Check the song data for invalid characters or formatting."
            case .fileWriteFailed:
                return "Ensure you have write permissions to the destination folder."
            case .unsupportedFormat:
                return "Choose a supported export format."
            case .emptyContent:
                return "Add content to the song before exporting."
            case .pdfRenderingFailed:
                return "The song content could not be rendered as a PDF. Try a different format."
            }
        }
    }

    // MARK: - Export to String

    /// Export a song to ChordPro format string
    /// - Parameter song: The song to export
    /// - Returns: ChordPro formatted string
    /// - Throws: SongExportError if export fails
    static func exportToChordPro(_ song: Song) throws -> String {
        guard !song.title.isEmpty else {
            throw SongExportError.invalidSongData
        }

        var output = ""

        // Add title
        output += "{title:\(song.title)}\n"

        // Add artist
        if let artist = song.artist, !artist.isEmpty {
            output += "{artist:\(artist)}\n"
        }

        // Add album
        if let album = song.album, !album.isEmpty {
            output += "{album:\(album)}\n"
        }

        // Add year
        if let year = song.year {
            output += "{year:\(year)}\n"
        }

        // Add key
        if let key = song.originalKey, !key.isEmpty {
            output += "{key:\(key)}\n"
        }

        // Add tempo
        if let tempo = song.tempo {
            output += "{tempo:\(tempo)}\n"
        }

        // Add time signature
        if let timeSignature = song.timeSignature, !timeSignature.isEmpty {
            output += "{time:\(timeSignature)}\n"
        }

        // Add capo
        if let capo = song.capo, capo > 0 {
            output += "{capo:\(capo)}\n"
        }

        // Add copyright
        if let copyright = song.copyright, !copyright.isEmpty {
            output += "{copyright:\(copyright)}\n"
        }

        // Add CCLI number
        if let ccliNumber = song.ccliNumber, !ccliNumber.isEmpty {
            output += "{ccli:\(ccliNumber)}\n"
        }

        // Add blank line before content
        output += "\n"

        // Add content
        if song.contentFormat == .chordPro {
            // Content is already in ChordPro format
            output += song.content
        } else {
            // Convert plain text or OnSong to ChordPro-compatible format
            output += song.content
        }

        // Add notes as comment if present
        if let notes = song.notes, !notes.isEmpty {
            output += "\n\n{comment:\(notes)}\n"
        }

        return output
    }

    /// Export a song to JSON format string
    /// - Parameter song: The song to export
    /// - Returns: JSON string representation of the song
    /// - Throws: SongExportError if export fails
    static func exportToJSON(_ song: Song) throws -> String {
        let data = try exportToJSONData(song)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw SongExportError.encodingFailed
        }
        return jsonString
    }

    /// Export a song to JSON data
    /// - Parameter song: The song to export
    /// - Returns: JSON data representation of the song
    /// - Throws: SongExportError if export fails
    static func exportToJSONData(_ song: Song) throws -> Data {
        guard !song.title.isEmpty else {
            throw SongExportError.invalidSongData
        }

        let exportData = SongExportData(
            id: song.id,
            createdAt: song.createdAt,
            modifiedAt: song.modifiedAt,
            title: song.title,
            artist: song.artist,
            album: song.album,
            year: song.year,
            copyright: song.copyright,
            ccliNumber: song.ccliNumber,
            originalKey: song.originalKey,
            currentKey: song.currentKey,
            tempo: song.tempo,
            timeSignature: song.timeSignature,
            capo: song.capo,
            content: song.content,
            contentFormat: song.contentFormat.rawValue,
            notes: song.notes,
            tags: song.tags,
            customField1: song.customField1,
            customField2: song.customField2,
            customField3: song.customField3,
            autoscrollEnabled: song.autoscrollEnabled,
            autoscrollDuration: song.autoscrollDuration,
            importSource: song.importSource,
            importedAt: song.importedAt,
            originalFilename: song.originalFilename
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(exportData)
        } catch {
            throw SongExportError.encodingFailed
        }
    }

    /// Export a song to plain text format
    /// - Parameter song: The song to export
    /// - Returns: Plain text representation of the song
    /// - Throws: SongExportError if export fails
    static func exportToPlainText(_ song: Song) throws -> String {
        guard !song.title.isEmpty else {
            throw SongExportError.invalidSongData
        }

        var output = ""

        // Add title
        output += song.title.uppercased() + "\n"
        output += String(repeating: "=", count: song.title.count) + "\n\n"

        // Add metadata
        if let artist = song.artist, !artist.isEmpty {
            output += "Artist: \(artist)\n"
        }

        if let album = song.album, !album.isEmpty {
            output += "Album: \(album)\n"
        }

        if let year = song.year {
            output += "Year: \(year)\n"
        }

        if let key = song.originalKey, !key.isEmpty {
            output += "Key: \(key)\n"
        }

        if let tempo = song.tempo {
            output += "Tempo: \(tempo) BPM\n"
        }

        if let timeSignature = song.timeSignature, !timeSignature.isEmpty {
            output += "Time Signature: \(timeSignature)\n"
        }

        if let capo = song.capo, capo > 0 {
            output += "Capo: \(capo)\n"
        }

        if let copyright = song.copyright, !copyright.isEmpty {
            output += "Copyright: \(copyright)\n"
        }

        if let ccliNumber = song.ccliNumber, !ccliNumber.isEmpty {
            output += "CCLI#: \(ccliNumber)\n"
        }

        // Add separator
        if output.split(separator: "\n").count > 2 {
            output += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }

        // Add content
        guard !song.content.isEmpty else {
            throw SongExportError.emptyContent
        }

        output += song.content

        // Add notes if present
        if let notes = song.notes, !notes.isEmpty {
            output += "\n\n" + String(repeating: "-", count: 50) + "\n"
            output += "NOTES:\n\(notes)\n"
        }

        return output
    }

    // MARK: - PDF Export

    /// Export a song to PDF data
    /// - Parameters:
    ///   - song: The song to export
    ///   - template: Template for layout (uses single column default if nil)
    /// - Returns: PDF data
    /// - Throws: SongExportError if rendering fails
    static func exportToPDF(_ song: Song, template: Template?) throws -> Data {
        guard !song.title.isEmpty else {
            throw SongExportError.invalidSongData
        }
        guard !song.content.isEmpty else {
            throw SongExportError.emptyContent
        }

        let effectiveTemplate = template ?? Template.builtInSingleColumn()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let margin: CGFloat = 50
        let contentTop: CGFloat = margin
        let contentBottom: CGFloat = pageRect.height - margin
        let contentLeft: CGFloat = margin
        let contentWidth: CGFloat = pageRect.width - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let titleFont = UIFont.boldSystemFont(ofSize: CGFloat(effectiveTemplate.titleFontSize))
        let headingFont = UIFont.boldSystemFont(ofSize: CGFloat(effectiveTemplate.headingFontSize))
        let bodyFont = UIFont.monospacedSystemFont(ofSize: CGFloat(effectiveTemplate.bodyFontSize), weight: .regular)
        let chordFont = UIFont.monospacedSystemFont(ofSize: CGFloat(effectiveTemplate.chordFontSize), weight: .bold)
        let metaFont = UIFont.systemFont(ofSize: CGFloat(effectiveTemplate.bodyFontSize) * 0.85)

        let chordColor = UIColor.systemBlue
        let bodyColor = UIColor.label
        let metaColor = UIColor.secondaryLabel

        let data = renderer.pdfData { context in
            context.beginPage()
            var currentY = contentTop

            // --- Title ---
            let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: bodyColor]
            let titleStr = NSAttributedString(string: song.title, attributes: titleAttrs)
            titleStr.draw(at: CGPoint(x: contentLeft, y: currentY))
            currentY += titleFont.lineHeight + 4

            // --- Artist ---
            if let artist = song.artist, !artist.isEmpty {
                let artistAttrs: [NSAttributedString.Key: Any] = [.font: metaFont, .foregroundColor: metaColor]
                let artistStr = NSAttributedString(string: artist, attributes: artistAttrs)
                artistStr.draw(at: CGPoint(x: contentLeft, y: currentY))
                currentY += metaFont.lineHeight + 4
            }

            // --- Metadata line ---
            var metaParts: [String] = []
            if let key = song.originalKey, !key.isEmpty { metaParts.append("Key: \(key)") }
            if let tempo = song.tempo { metaParts.append("Tempo: \(tempo) BPM") }
            if let timeSignature = song.timeSignature, !timeSignature.isEmpty { metaParts.append("Time: \(timeSignature)") }
            if let capo = song.capo, capo > 0 { metaParts.append("Capo: \(capo)") }
            if !metaParts.isEmpty {
                let metaAttrs: [NSAttributedString.Key: Any] = [.font: metaFont, .foregroundColor: metaColor]
                let metaStr = NSAttributedString(string: metaParts.joined(separator: "  |  "), attributes: metaAttrs)
                metaStr.draw(at: CGPoint(x: contentLeft, y: currentY))
                currentY += metaFont.lineHeight + 8
            }

            // --- Separator ---
            let separatorPath = UIBezierPath()
            separatorPath.move(to: CGPoint(x: contentLeft, y: currentY))
            separatorPath.addLine(to: CGPoint(x: contentLeft + contentWidth, y: currentY))
            UIColor.separator.setStroke()
            separatorPath.lineWidth = 0.5
            separatorPath.stroke()
            currentY += 12

            // --- Content ---
            let columnCount = effectiveTemplate.columnCount
            let totalGap = CGFloat(max(columnCount - 1, 0)) * CGFloat(effectiveTemplate.columnGap)
            let columnWidth = (contentWidth - totalGap) / CGFloat(max(columnCount, 1))

            // Parse content into lines, filtering out metadata directives
            let rawLines = song.content.components(separatedBy: "\n")
            var contentLines: [(type: LineType, text: String)] = []

            for line in rawLines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    contentLines.append((.blank, ""))
                } else if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
                    let directive = String(trimmed.dropFirst().dropLast())
                    let lower = directive.lowercased()
                    if lower.hasPrefix("title:") || lower.hasPrefix("t:") ||
                       lower.hasPrefix("artist:") || lower.hasPrefix("key:") ||
                       lower.hasPrefix("tempo:") || lower.hasPrefix("time:") ||
                       lower.hasPrefix("capo:") || lower.hasPrefix("album:") ||
                       lower.hasPrefix("year:") || lower.hasPrefix("copyright:") ||
                       lower.hasPrefix("ccli:") {
                        continue // Skip metadata directives already rendered in header
                    } else if lower.hasPrefix("comment:") || lower.hasPrefix("c:") {
                        let commentText = directive.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                        contentLines.append((.comment, commentText))
                    } else if lower.hasPrefix("start_of_") || lower.hasPrefix("so") {
                        // Section start - extract label if present
                        let label = directive.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                        if !label.isEmpty {
                            contentLines.append((.heading, label))
                        }
                    } else if lower.hasPrefix("end_of_") || lower.hasPrefix("eo") {
                        contentLines.append((.blank, ""))
                    }
                } else {
                    contentLines.append((.chordLyric, trimmed))
                }
            }

            // Distribute lines across columns (simple balanced split)
            let linesPerColumn = max((contentLines.count + columnCount - 1) / columnCount, 1)

            for col in 0..<columnCount {
                let startIdx = col * linesPerColumn
                let endIdx = min(startIdx + linesPerColumn, contentLines.count)
                guard startIdx < contentLines.count else { continue }
                let columnLines = Array(contentLines[startIdx..<endIdx])

                let columnX = contentLeft + CGFloat(col) * (columnWidth + CGFloat(effectiveTemplate.columnGap))
                var lineY = currentY

                for lineInfo in columnLines {
                    // Page break check
                    if lineY + bodyFont.lineHeight * 2 > contentBottom {
                        context.beginPage()
                        lineY = contentTop
                    }

                    switch lineInfo.type {
                    case .blank:
                        lineY += bodyFont.lineHeight * 0.5

                    case .heading:
                        let headingAttrs: [NSAttributedString.Key: Any] = [.font: headingFont, .foregroundColor: bodyColor]
                        let headingStr = NSAttributedString(string: lineInfo.text, attributes: headingAttrs)
                        lineY += 4 // Extra space before headings
                        headingStr.draw(in: CGRect(x: columnX, y: lineY, width: columnWidth, height: headingFont.lineHeight + 4))
                        lineY += headingFont.lineHeight + 6

                    case .comment:
                        let commentFont = UIFont.italicSystemFont(ofSize: CGFloat(effectiveTemplate.bodyFontSize))
                        let commentAttrs: [NSAttributedString.Key: Any] = [.font: commentFont, .foregroundColor: metaColor]
                        let commentStr = NSAttributedString(string: lineInfo.text, attributes: commentAttrs)
                        commentStr.draw(in: CGRect(x: columnX, y: lineY, width: columnWidth, height: commentFont.lineHeight + 4))
                        lineY += commentFont.lineHeight + 4

                    case .chordLyric:
                        // Parse [chord] markers and render chords above lyrics
                        let parsed = parseChordLine(lineInfo.text)
                        if !parsed.chords.isEmpty {
                            // Draw chord line
                            let chordAttrs: [NSAttributedString.Key: Any] = [.font: chordFont, .foregroundColor: chordColor]
                            let chordStr = NSAttributedString(string: parsed.chordLine, attributes: chordAttrs)
                            chordStr.draw(in: CGRect(x: columnX, y: lineY, width: columnWidth, height: chordFont.lineHeight + 2))
                            lineY += chordFont.lineHeight + 1
                        }
                        // Draw lyrics line
                        let lyricAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: bodyColor]
                        let lyricStr = NSAttributedString(string: parsed.lyricLine, attributes: lyricAttrs)
                        lyricStr.draw(in: CGRect(x: columnX, y: lineY, width: columnWidth, height: bodyFont.lineHeight + 2))
                        lineY += bodyFont.lineHeight + 3
                    }
                }
            }
        }

        return data
    }

    // MARK: - Lyra Bundle Export

    /// Export a song as a Lyra Bundle (.lyra) JSON string
    /// - Parameters:
    ///   - song: The song to export
    ///   - template: Template to include (uses single column default if nil)
    /// - Returns: JSON string of the Lyra Bundle
    /// - Throws: SongExportError if export fails
    static func exportToLyraBundle(_ song: Song, template: Template?) throws -> String {
        guard !song.title.isEmpty else {
            throw SongExportError.invalidSongData
        }

        let effectiveTemplate = template ?? Template.builtInSingleColumn()

        let bundle = LyraBundleExport(
            version: "1.0",
            template: LyraBundle.TemplateData(
                name: effectiveTemplate.name,
                columnCount: effectiveTemplate.columnCount,
                columnGap: effectiveTemplate.columnGap,
                columnWidthMode: effectiveTemplate.columnWidthMode.rawValue,
                columnBalancingStrategy: effectiveTemplate.columnBalancingStrategy.rawValue,
                chordPositioningStyle: effectiveTemplate.chordPositioningStyle.rawValue,
                chordAlignment: effectiveTemplate.chordAlignment.rawValue,
                titleFontSize: effectiveTemplate.titleFontSize,
                headingFontSize: effectiveTemplate.headingFontSize,
                bodyFontSize: effectiveTemplate.bodyFontSize,
                chordFontSize: effectiveTemplate.chordFontSize,
                sectionBreakBehavior: effectiveTemplate.sectionBreakBehavior.rawValue,
                customColumnWidths: effectiveTemplate.customColumnWidths
            ),
            song: LyraBundleExport.SongData(
                title: song.title,
                artist: song.artist,
                content: song.content,
                contentFormat: song.contentFormat.rawValue,
                originalKey: song.originalKey,
                tempo: song.tempo,
                timeSignature: song.timeSignature,
                capo: song.capo,
                notes: song.notes
            ),
            exportedAt: ISO8601DateFormatter().string(from: Date())
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(bundle)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw SongExportError.encodingFailed
            }
            return jsonString
        } catch is SongExportError {
            throw SongExportError.encodingFailed
        } catch {
            throw SongExportError.encodingFailed
        }
    }

    // MARK: - Export to File

    /// Export a song to a file
    /// - Parameters:
    ///   - song: The song to export
    ///   - format: The export format
    ///   - url: The destination URL
    ///   - template: Template for PDF/Lyra Bundle formats (optional)
    /// - Throws: SongExportError if export fails
    static func exportToFile(_ song: Song, format: ExportFormat, url: URL, template: Template? = nil) throws {
        switch format {
        case .pdf:
            let pdfData = try exportToPDF(song, template: template)
            do {
                try pdfData.write(to: url)
            } catch {
                throw SongExportError.fileWriteFailed(error)
            }
        default:
            let content: String
            switch format {
            case .chordPro:
                content = try exportToChordPro(song)
            case .json:
                content = try exportToJSON(song)
            case .plainText:
                content = try exportToPlainText(song)
            case .lyraBundle:
                content = try exportToLyraBundle(song, template: template)
            case .pdf:
                return // Handled above
            }
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                throw SongExportError.fileWriteFailed(error)
            }
        }
    }

    /// Generate a suggested filename for exporting a song
    /// - Parameters:
    ///   - song: The song to export
    ///   - format: The export format
    /// - Returns: A sanitized filename with extension
    static func suggestedFilename(for song: Song, format: ExportFormat) -> String {
        var filename = song.title

        // Add artist if available
        if let artist = song.artist, !artist.isEmpty {
            filename += " - \(artist)"
        }

        // Sanitize filename
        filename = sanitizeFilename(filename)

        // Add extension
        filename += ".\(format.fileExtension)"

        return filename
    }

    /// Export multiple songs to a directory
    /// - Parameters:
    ///   - songs: Array of songs to export
    ///   - format: The export format
    ///   - directoryURL: The destination directory URL
    /// - Returns: Array of successfully exported file URLs
    /// - Throws: SongExportError if any export fails
    @discardableResult
    static func exportMultipleSongs(_ songs: [Song], format: ExportFormat, to directoryURL: URL) throws -> [URL] {
        var exportedURLs: [URL] = []

        for song in songs {
            let filename = suggestedFilename(for: song, format: format)
            let fileURL = directoryURL.appendingPathComponent(filename)

            try exportToFile(song, format: format, url: fileURL, template: song.template)
            exportedURLs.append(fileURL)
        }

        return exportedURLs
    }

    // MARK: - Helper Methods

    /// Sanitize a filename by removing invalid characters
    /// - Parameter filename: The filename to sanitize
    /// - Returns: A sanitized filename
    private static func sanitizeFilename(_ filename: String) -> String {
        // Invalid characters for filenames: / \ : * ? " < > |
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")

        return filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - PDF Helpers

/// Line type for PDF content rendering
private enum LineType {
    case blank
    case heading
    case comment
    case chordLyric
}

/// Parsed chord line with separate chord and lyric strings
private struct ParsedChordLine {
    let chordLine: String
    let lyricLine: String
    let chords: [(position: Int, chord: String)]
}

/// Parse a ChordPro line like "[G]Amazing [C]grace" into separate chord and lyric lines
private func parseChordLine(_ line: String) -> ParsedChordLine {
    var chords: [(position: Int, chord: String)] = []
    var lyricLine = ""
    var currentChord = ""
    var inChord = false

    for char in line {
        if char == "[" {
            inChord = true
            currentChord = ""
        } else if char == "]" {
            inChord = false
            chords.append((position: lyricLine.count, chord: currentChord))
        } else if inChord {
            currentChord.append(char)
        } else {
            lyricLine.append(char)
        }
    }

    // Build chord line with spacing to align above lyrics
    var chordLine = ""
    var lastPos = 0
    for (position, chord) in chords {
        let padding = max(position - lastPos, 0)
        chordLine += String(repeating: " ", count: padding) + chord
        lastPos = position + chord.count
    }

    return ParsedChordLine(chordLine: chordLine, lyricLine: lyricLine, chords: chords)
}

// MARK: - Lyra Bundle Export Structure

/// Export format for Lyra Bundle (backward-compatible with LyraBundle import struct)
struct LyraBundleExport: Codable {
    let version: String
    let template: LyraBundle.TemplateData
    let song: SongData
    let exportedAt: String

    struct SongData: Codable {
        let title: String
        let artist: String?
        let content: String
        let contentFormat: String
        let originalKey: String?
        let tempo: Int?
        let timeSignature: String?
        let capo: Int?
        let notes: String?
    }
}

// MARK: - Supporting Types

/// Codable representation of a Song for JSON export
struct SongExportData: Codable {
    let id: UUID
    let createdAt: Date
    let modifiedAt: Date
    let title: String
    let artist: String?
    let album: String?
    let year: Int?
    let copyright: String?
    let ccliNumber: String?
    let originalKey: String?
    let currentKey: String?
    let tempo: Int?
    let timeSignature: String?
    let capo: Int?
    let content: String
    let contentFormat: String
    let notes: String?
    let tags: [String]?
    let customField1: String?
    let customField2: String?
    let customField3: String?
    let autoscrollEnabled: Bool
    let autoscrollDuration: Int?
    let importSource: String?
    let importedAt: Date?
    let originalFilename: String?
}
