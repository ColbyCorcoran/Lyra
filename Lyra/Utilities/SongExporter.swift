//
//  SongExporter.swift
//  Lyra
//
//  Created by Claude on 2026-01-29.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Utility class for exporting songs to various formats
@MainActor
class SongExporter {

    // MARK: - Export Formats

    /// Supported export formats
    enum ExportFormat: String, CaseIterable {
        case chordPro = "cho"
        case json = "json"
        case plainText = "txt"

        var displayName: String {
            switch self {
            case .chordPro: return "ChordPro"
            case .json: return "JSON"
            case .plainText: return "Plain Text"
            }
        }

        var utType: UTType {
            switch self {
            case .chordPro: return .plainText
            case .json: return .json
            case .plainText: return .plainText
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
                return "Choose a supported export format: ChordPro, JSON, or Plain Text."
            case .emptyContent:
                return "Add content to the song before exporting."
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

    // MARK: - Export to File

    /// Export a song to a file
    /// - Parameters:
    ///   - song: The song to export
    ///   - format: The export format
    ///   - url: The destination URL
    /// - Throws: SongExportError if export fails
    static func exportToFile(_ song: Song, format: ExportFormat, url: URL) throws {
        let content: String

        switch format {
        case .chordPro:
            content = try exportToChordPro(song)
        case .json:
            content = try exportToJSON(song)
        case .plainText:
            content = try exportToPlainText(song)
        }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw SongExportError.fileWriteFailed(error)
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

            try exportToFile(song, format: format, url: fileURL)
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
