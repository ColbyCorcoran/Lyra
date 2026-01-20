//
//  ExportManager.swift
//  Lyra
//
//  Manager for coordinating all export operations
//

import Foundation
import SwiftData
import ZipArchive

@MainActor
class ExportManager: ObservableObject {
    static let shared = ExportManager()

    // MARK: - Export Formats

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case chordPro = "ChordPro"
        case plainText = "Plain Text"
        case onSong = "OnSong"
        case html = "HTML"

        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .chordPro: return "cho"
            case .plainText: return "txt"
            case .onSong: return "onsong"
            case .html: return "html"
            }
        }

        var mimeType: String {
            switch self {
            case .pdf: return "application/pdf"
            case .chordPro: return "text/plain"
            case .plainText: return "text/plain"
            case .onSong: return "text/plain"
            case .html: return "text/html"
            }
        }

        var icon: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .chordPro: return "text.badge.star"
            case .plainText: return "doc.plaintext"
            case .onSong: return "music.note.list"
            case .html: return "globe"
            }
        }

        var description: String {
            switch self {
            case .pdf: return "Formatted PDF with professional layout"
            case .chordPro: return "ChordPro format for chord chart apps"
            case .plainText: return "Plain text with chords and lyrics"
            case .onSong: return "OnSong format for OnSong app"
            case .html: return "HTML format for web viewing"
            }
        }
    }

    // MARK: - Export Methods

    /// Export a single song in the specified format
    func exportSong(
        _ song: Song,
        format: ExportFormat,
        configuration: PDFExporter.PDFConfiguration = PDFExporter.PDFConfiguration()
    ) throws -> Data {
        switch format {
        case .pdf:
            return try PDFExporter.exportSong(song, configuration: configuration)
        case .chordPro:
            return try exportSongAsChordPro(song)
        case .plainText:
            return try exportSongAsPlainText(song)
        case .onSong:
            return try exportSongAsOnSong(song)
        case .html:
            return try exportSongAsHTML(song)
        }
    }

    /// Export a performance set in the specified format
    func exportSet(
        _ set: PerformanceSet,
        format: ExportFormat,
        configuration: PDFExporter.PDFConfiguration = PDFExporter.PDFConfiguration()
    ) throws -> Data {
        switch format {
        case .pdf:
            return try PDFExporter.exportSet(set, configuration: configuration)
        case .chordPro, .plainText, .onSong, .html:
            return try exportSetAsCombinedFile(set, format: format)
        }
    }

    /// Export a book in the specified format
    func exportBook(
        _ book: Book,
        format: ExportFormat,
        configuration: PDFExporter.PDFConfiguration = PDFExporter.PDFConfiguration()
    ) throws -> Data {
        switch format {
        case .pdf:
            return try PDFExporter.exportBook(book, configuration: configuration)
        case .chordPro, .plainText, .onSong, .html:
            return try exportBookAsCombinedFile(book, format: format)
        }
    }

    /// Export entire library as compressed archive
    func exportLibrary(
        songs: [Song],
        books: [Book],
        sets: [PerformanceSet],
        format: ExportFormat
    ) throws -> URL {
        // Create temporary directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LyraExport_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Export songs
        let songsDir = tempDir.appendingPathComponent("Songs")
        try FileManager.default.createDirectory(at: songsDir, withIntermediateDirectories: true)

        for song in songs {
            let data = try exportSong(song, format: format)
            let filename = sanitizeFilename(song.title) + "." + format.fileExtension
            let fileURL = songsDir.appendingPathComponent(filename)
            try data.write(to: fileURL)
        }

        // Export books
        if !books.isEmpty {
            let booksDir = tempDir.appendingPathComponent("Books")
            try FileManager.default.createDirectory(at: booksDir, withIntermediateDirectories: true)

            for book in books {
                let data = try exportBook(book, format: format)
                let filename = sanitizeFilename(book.name) + "." + format.fileExtension
                let fileURL = booksDir.appendingPathComponent(filename)
                try data.write(to: fileURL)
            }
        }

        // Export sets
        if !sets.isEmpty {
            let setsDir = tempDir.appendingPathComponent("Sets")
            try FileManager.default.createDirectory(at: setsDir, withIntermediateDirectories: true)

            for set in sets {
                let data = try exportSet(set, format: format)
                let filename = sanitizeFilename(set.name) + "." + format.fileExtension
                let fileURL = setsDir.appendingPathComponent(filename)
                try data.write(to: fileURL)
            }
        }

        // Create README
        let readmeContent = """
        Lyra Library Export
        ===================

        Export Date: \(Date().formatted())
        Format: \(format.rawValue)

        Contents:
        - Songs: \(songs.count)
        - Books: \(books.count)
        - Sets: \(sets.count)

        This export was created by Lyra, a chord chart management app for iOS.
        """

        let readmeURL = tempDir.appendingPathComponent("README.txt")
        try readmeContent.write(to: readmeURL, atomically: true, encoding: .utf8)

        // Create zip archive
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Lyra_Export_\(Date().formatted(date: .numeric, time: .omitted)).zip")

        try SSZipArchive.createZipFile(atPath: zipURL.path, withContentsOfDirectory: tempDir.path)

        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)

        return zipURL
    }

    // MARK: - Format-Specific Export Methods

    private func exportSongAsChordPro(_ song: Song) throws -> Data {
        var content = ""

        // Add ChordPro directives
        content += "{title: \(song.title)}\n"

        if let artist = song.artist {
            content += "{artist: \(artist)}\n"
        }

        if let key = song.currentKey {
            content += "{key: \(key)}\n"
        }

        if let tempo = song.tempo {
            content += "{tempo: \(tempo)}\n"
        }

        if let timeSignature = song.timeSignature {
            content += "{time: \(timeSignature)}\n"
        }

        content += "\n"

        // Add song content (already in ChordPro format)
        content += song.content

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    private func exportSongAsPlainText(_ song: Song) throws -> Data {
        var content = ""

        // Add header
        content += "\(song.title)\n"
        content += String(repeating: "=", count: song.title.count) + "\n\n"

        if let artist = song.artist {
            content += "Artist: \(artist)\n"
        }

        if let key = song.currentKey {
            content += "Key: \(key)\n"
        }

        if let tempo = song.tempo {
            content += "Tempo: \(tempo) BPM\n"
        }

        if let timeSignature = song.timeSignature {
            content += "Time: \(timeSignature)\n"
        }

        content += "\n"

        // Convert ChordPro to plain text
        content += convertChordProToPlainText(song.content)

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    private func exportSongAsOnSong(_ song: Song) throws -> Data {
        var content = ""

        // OnSong metadata
        content += "Title: \(song.title)\n"

        if let artist = song.artist {
            content += "Artist: \(artist)\n"
        }

        if let key = song.currentKey {
            content += "Key: \(key)\n"
        }

        if let tempo = song.tempo {
            content += "Tempo: \(tempo)\n"
        }

        if let timeSignature = song.timeSignature {
            content += "Time Signature: \(timeSignature)\n"
        }

        content += "\n"

        // Convert ChordPro to OnSong format
        content += convertChordProToOnSong(song.content)

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    private func exportSongAsHTML(_ song: Song) throws -> Data {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(song.title)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                    max-width: 800px;
                    margin: 40px auto;
                    padding: 20px;
                    line-height: 1.6;
                }
                h1 {
                    color: #333;
                    border-bottom: 2px solid #007AFF;
                    padding-bottom: 10px;
                }
                .metadata {
                    color: #666;
                    margin-bottom: 30px;
                }
                .metadata span {
                    margin-right: 20px;
                }
                .song-content {
                    font-family: 'Monaco', 'Courier New', monospace;
                    white-space: pre-wrap;
                    background: #f8f8f8;
                    padding: 20px;
                    border-radius: 8px;
                }
                .chord {
                    color: #007AFF;
                    font-weight: bold;
                }
                .section {
                    color: #666;
                    font-weight: 600;
                    margin-top: 20px;
                    display: block;
                }
                .footer {
                    margin-top: 40px;
                    text-align: center;
                    color: #999;
                    font-size: 12px;
                }
            </style>
        </head>
        <body>
            <h1>\(song.title)</h1>
            <div class="metadata">
        """

        if let artist = song.artist {
            html += "<span><strong>Artist:</strong> \(artist)</span>"
        }
        if let key = song.currentKey {
            html += "<span><strong>Key:</strong> \(key)</span>"
        }
        if let tempo = song.tempo {
            html += "<span><strong>Tempo:</strong> \(tempo) BPM</span>"
        }
        if let timeSignature = song.timeSignature {
            html += "<span><strong>Time:</strong> \(timeSignature)</span>"
        }

        html += """
            </div>
            <div class="song-content">
        """

        html += convertChordProToHTML(song.content)

        html += """
            </div>
            <div class="footer">
                Created with Lyra • \(Date().formatted(date: .long, time: .omitted))
            </div>
        </body>
        </html>
        """

        guard let data = html.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    private func exportSetAsCombinedFile(_ set: PerformanceSet, format: ExportFormat) throws -> Data {
        var content = ""

        // Add set header
        switch format {
        case .chordPro:
            content += "{title: \(set.name)}\n"
            if let date = set.scheduledDate {
                content += "{subtitle: \(date.formatted(date: .long, time: .omitted))}\n"
            }
            if let venue = set.venue {
                content += "{subtitle: \(venue)}\n"
            }
            content += "\n"

        case .plainText:
            content += "\(set.name)\n"
            content += String(repeating: "=", count: set.name.count) + "\n"
            if let date = set.scheduledDate {
                content += "Date: \(date.formatted(date: .long, time: .omitted))\n"
            }
            if let venue = set.venue {
                content += "Venue: \(venue)\n"
            }
            content += "\n"

        case .html:
            content += "<!DOCTYPE html><html><head><title>\(set.name)</title></head><body>"
            content += "<h1>\(set.name)</h1>"
            if let date = set.scheduledDate {
                content += "<p>Date: \(date.formatted(date: .long, time: .omitted))</p>"
            }
            if let venue = set.venue {
                content += "<p>Venue: \(venue)</p>"
            }

        default:
            break
        }

        // Add each song
        guard let sortedEntries = set.sortedSongEntries else { throw ExportError.invalidData }

        for entry in sortedEntries {
            guard let song = entry.song else { continue }

            content += "\n\n"
            content += "--- Song \(entry.orderIndex + 1): \(song.title) ---\n\n"

            let songData = try exportSong(song, format: format)
            if let songContent = String(data: songData, encoding: .utf8) {
                content += songContent
            }
        }

        if format == .html {
            content += "</body></html>"
        }

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    private func exportBookAsCombinedFile(_ book: Book, format: ExportFormat) throws -> Data {
        var content = ""

        // Add book header
        switch format {
        case .chordPro:
            content += "{title: \(book.name)}\n"
            if let description = book.bookDescription {
                content += "{subtitle: \(description)}\n"
            }
            content += "\n"

        case .plainText:
            content += "\(book.name)\n"
            content += String(repeating: "=", count: book.name.count) + "\n"
            if let description = book.bookDescription {
                content += "\(description)\n"
            }
            content += "\n"

        case .html:
            content += "<!DOCTYPE html><html><head><title>\(book.name)</title></head><body>"
            content += "<h1>\(book.name)</h1>"
            if let description = book.bookDescription {
                content += "<p>\(description)</p>"
            }

        default:
            break
        }

        // Add each song
        guard let songs = book.songs?.sorted(by: { $0.title < $1.title }) else {
            throw ExportError.invalidData
        }

        for song in songs {
            content += "\n\n"
            content += "--- \(song.title) ---\n\n"

            let songData = try exportSong(song, format: format)
            if let songContent = String(data: songData, encoding: .utf8) {
                content += songContent
            }
        }

        if format == .html {
            content += "</body></html>"
        }

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    // MARK: - Format Conversion Helpers

    private func convertChordProToPlainText(_ content: String) -> String {
        var result = ""
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            var processedLine = line

            // Skip ChordPro directives
            if processedLine.hasPrefix("{") && processedLine.hasSuffix("}") {
                continue
            }

            // Convert chord notation [C] to plain
            let chordPattern = "\\[([^\\]]+)\\]"
            if let regex = try? NSRegularExpression(pattern: chordPattern) {
                processedLine = regex.stringByReplacingMatches(
                    in: processedLine,
                    range: NSRange(processedLine.startIndex..., in: processedLine),
                    withTemplate: "$1"
                )
            }

            result += processedLine + "\n"
        }

        return result
    }

    private func convertChordProToOnSong(_ content: String) -> String {
        var result = ""
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            var processedLine = line

            // Skip ChordPro directives (already in metadata)
            if processedLine.hasPrefix("{") && processedLine.hasSuffix("}") {
                continue
            }

            // Convert [Chord] to .Chord
            let chordPattern = "\\[([^\\]]+)\\]"
            if let regex = try? NSRegularExpression(pattern: chordPattern) {
                processedLine = regex.stringByReplacingMatches(
                    in: processedLine,
                    range: NSRange(processedLine.startIndex..., in: processedLine),
                    withTemplate: ".$1"
                )
            }

            result += processedLine + "\n"
        }

        return result
    }

    private func convertChordProToHTML(_ content: String) -> String {
        var result = ""
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            var processedLine = line

            // Skip ChordPro directives
            if processedLine.hasPrefix("{") && processedLine.hasSuffix("}") {
                continue
            }

            // Convert section markers [Verse] to HTML
            if processedLine.hasPrefix("[") && processedLine.hasSuffix("]") && !processedLine.contains(":") {
                let section = processedLine.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                result += "<span class=\"section\">\(section)</span>\n"
                continue
            }

            // Convert [Chord] to HTML span
            let chordPattern = "\\[([^\\]]+)\\]"
            if let regex = try? NSRegularExpression(pattern: chordPattern) {
                let range = NSRange(processedLine.startIndex..., in: processedLine)
                processedLine = regex.stringByReplacingMatches(
                    in: processedLine,
                    range: range,
                    withTemplate: "<span class=\"chord\">$1</span>"
                )
            }

            result += processedLine + "\n"
        }

        return result
    }

    // MARK: - Helpers

    private func sanitizeFilename(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }

    // MARK: - Errors

    enum ExportError: LocalizedError {
        case encodingFailed
        case invalidData
        case fileCreationFailed

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode content"
            case .invalidData:
                return "Invalid data for export"
            case .fileCreationFailed:
                return "Failed to create export file"
            }
        }
    }
}
