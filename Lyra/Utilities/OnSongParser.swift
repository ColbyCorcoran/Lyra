//
//  OnSongParser.swift
//  Lyra
//
//  Parser for OnSong backup files (.backup, .onsongarchive)
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - OnSong Import Result

struct OnSongImportResult {
    var songs: [Song] = []
    var books: [Book] = []
    var sets: [PerformanceSet] = []
    var errors: [ImportError] = []
    var skippedAttachments: Int = 0

    struct ImportError {
        let fileName: String
        let error: String
    }

    var totalImported: Int {
        songs.count + books.count + sets.count
    }
}

// MARK: - OnSong Parser

class OnSongParser {

    // MARK: - Public Methods

    /// Parse an OnSong backup file
    static func parseBackup(
        from url: URL,
        progressCallback: ((Double, String) -> Void)? = nil
    ) throws -> OnSongImportResult {
        var result = OnSongImportResult()

        progressCallback?(0.1, "Reading archive...")

        // Ensure we have access to the file
        guard url.startAccessingSecurityScopedResource() else {
            throw OnSongError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        progressCallback?(0.2, "Extracting archive...")

        // Extract ZIP archive
        try extractZip(from: url, to: tempDir)

        progressCallback?(0.3, "Parsing songs...")

        // Parse songs from .onsong files
        let songFiles = try findFiles(withExtension: "onsong", in: tempDir)
        let totalSongs = songFiles.count

        for (index, songFile) in songFiles.enumerated() {
            do {
                let song = try parseSongFile(at: songFile)
                result.songs.append(song)

                let progress = 0.3 + (Double(index + 1) / Double(totalSongs)) * 0.4
                progressCallback?(progress, "Parsing song \(index + 1) of \(totalSongs)...")
            } catch {
                result.errors.append(OnSongImportResult.ImportError(
                    fileName: songFile.lastPathComponent,
                    error: error.localizedDescription
                ))
            }
        }

        progressCallback?(0.7, "Parsing books...")

        // Parse books.xml if exists
        if let booksXML = try? findFile(named: "books.xml", in: tempDir) {
            do {
                let books = try parseBooks(from: booksXML, songs: result.songs)
                result.books = books
            } catch {
                result.errors.append(OnSongImportResult.ImportError(
                    fileName: "books.xml",
                    error: error.localizedDescription
                ))
            }
        }

        progressCallback?(0.85, "Parsing sets...")

        // Parse sets.xml if exists
        if let setsXML = try? findFile(named: "sets.xml", in: tempDir) {
            do {
                let sets = try parseSets(from: setsXML, songs: result.songs)
                result.sets = sets
            } catch {
                result.errors.append(OnSongImportResult.ImportError(
                    fileName: "sets.xml",
                    error: error.localizedDescription
                ))
            }
        }

        progressCallback?(0.95, "Counting attachments...")

        // Count PDF attachments (not imported in Phase 2)
        let pdfFiles = try findFiles(withExtension: "pdf", in: tempDir)
        result.skippedAttachments = pdfFiles.count

        progressCallback?(1.0, "Import complete!")

        return result
    }

    // MARK: - Private Methods

    private static func extractZip(from sourceURL: URL, to destinationURL: URL) throws {
        #if os(macOS)
        // Use FileManager to unzip on macOS
        let data = try Data(contentsOf: sourceURL)
        let tempZipFile = FileManager.default.temporaryDirectory.appendingPathComponent("temp.zip")
        try data.write(to: tempZipFile)

        // Try to use unzip command (macOS only)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", tempZipFile.path, "-d", destinationURL.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw OnSongError.archiveExtractionFailed
        }

        try? FileManager.default.removeItem(at: tempZipFile)
        #else
        // iOS implementation requires a third-party ZIP library like ZIPFoundation
        // For now, throw an error indicating this feature needs implementation
        // TODO: Integrate ZIPFoundation or similar library for iOS ZIP extraction
        throw OnSongError.archiveExtractionFailed
        #endif
    }

    private static func findFiles(withExtension ext: String, in directory: URL) throws -> [URL] {
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var files: [URL] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == ext {
                files.append(fileURL)
            }
        }

        return files
    }

    private static func findFile(named name: String, in directory: URL) throws -> URL? {
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent.lowercased() == name.lowercased() {
                return fileURL
            }
        }

        return nil
    }

    private static func parseSongFile(at url: URL) throws -> Song {
        let content = try String(contentsOf: url, encoding: .utf8)

        // OnSong format is similar to ChordPro
        var title = url.deletingPathExtension().lastPathComponent
        var artist: String?
        var key: String?
        var tempo: Int?
        var capo: Int?
        var songContent = content

        // Parse OnSong metadata directives
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            if line.hasPrefix("Title:") {
                title = line.replacingOccurrences(of: "Title:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Artist:") {
                artist = line.replacingOccurrences(of: "Artist:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Key:") {
                key = line.replacingOccurrences(of: "Key:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Tempo:") {
                if let tempoValue = Int(line.replacingOccurrences(of: "Tempo:", with: "").trimmingCharacters(in: .whitespaces)) {
                    tempo = tempoValue
                }
            } else if line.hasPrefix("Capo:") {
                if let capoValue = Int(line.replacingOccurrences(of: "Capo:", with: "").trimmingCharacters(in: .whitespaces)) {
                    capo = capoValue
                }
            }
        }

        // Convert OnSong format to ChordPro if needed
        songContent = convertOnSongToChordPro(content)

        let song = Song(
            title: title,
            artist: artist,
            content: songContent,
            contentFormat: .chordPro,
            originalKey: key
        )

        song.tempo = tempo
        song.capo = capo
        song.importSource = "OnSong"
        song.importedAt = Date()
        song.originalFilename = url.lastPathComponent

        return song
    }

    private static func convertOnSongToChordPro(_ content: String) -> String {
        var chordProContent = content

        // Convert OnSong metadata to ChordPro directives
        chordProContent = chordProContent.replacingOccurrences(of: "Title:", with: "{title:")
            .replacingOccurrences(of: "Artist:", with: "{artist:")
            .replacingOccurrences(of: "Key:", with: "{key:")
            .replacingOccurrences(of: "Tempo:", with: "{tempo:")
            .replacingOccurrences(of: "Capo:", with: "{capo:")

        // Close directives with }
        let lines = chordProContent.components(separatedBy: .newlines)
        var convertedLines: [String] = []

        for line in lines {
            if line.hasPrefix("{") && !line.hasSuffix("}") && !line.contains("}") {
                convertedLines.append(line + "}")
            } else {
                convertedLines.append(line)
            }
        }

        return convertedLines.joined(separator: "\n")
    }

    private static func parseBooks(from url: URL, songs: [Song]) throws -> [Book] {
        let xmlData = try Data(contentsOf: url)
        let parser = XMLParser(data: xmlData)
        let delegate = BooksXMLParserDelegate(songs: songs)
        parser.delegate = delegate

        guard parser.parse() else {
            throw OnSongError.xmlParsingFailed
        }

        return delegate.books
    }

    private static func parseSets(from url: URL, songs: [Song]) throws -> [PerformanceSet] {
        let xmlData = try Data(contentsOf: url)
        let parser = XMLParser(data: xmlData)
        let delegate = SetsXMLParserDelegate(songs: songs)
        parser.delegate = delegate

        guard parser.parse() else {
            throw OnSongError.xmlParsingFailed
        }

        return delegate.sets
    }
}

// MARK: - Books XML Parser Delegate

class BooksXMLParserDelegate: NSObject, XMLParserDelegate {
    var books: [Book] = []
    private let songs: [Song]

    private var currentBook: Book?
    private var currentElement = ""
    private var currentValue = ""
    private var currentSongTitles: [String] = []

    init(songs: [Song]) {
        self.songs = songs
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentValue = ""

        if elementName == "book" {
            let name = attributeDict["name"] ?? "Untitled Book"
            currentBook = Book(name: name)
            currentSongTitles = []
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "song" && currentBook != nil {
            currentSongTitles.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
        } else if elementName == "book", let book = currentBook {
            // Match songs by title
            var bookSongs: [Song] = []
            for title in currentSongTitles {
                if let song = songs.first(where: { $0.title == title }) {
                    bookSongs.append(song)
                }
            }
            book.songs = bookSongs
            books.append(book)
            currentBook = nil
        }

        currentElement = ""
        currentValue = ""
    }
}

// MARK: - Sets XML Parser Delegate

class SetsXMLParserDelegate: NSObject, XMLParserDelegate {
    var sets: [PerformanceSet] = []
    private let songs: [Song]

    private var currentSet: PerformanceSet?
    private var currentElement = ""
    private var currentValue = ""
    private var currentSongTitles: [String] = []

    init(songs: [Song]) {
        self.songs = songs
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentValue = ""

        if elementName == "set" {
            let name = attributeDict["name"] ?? "Untitled Set"
            currentSet = PerformanceSet(name: name)
            currentSongTitles = []
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "song" && currentSet != nil {
            currentSongTitles.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
        } else if elementName == "set", let set = currentSet {
            // Create SetEntry objects
            var entries: [SetEntry] = []
            for (index, title) in currentSongTitles.enumerated() {
                if let song = songs.first(where: { $0.title == title }) {
                    let entry = SetEntry(song: song, orderIndex: index)
                    entry.performanceSet = set
                    entries.append(entry)
                }
            }
            set.songEntries = entries
            sets.append(set)
            currentSet = nil
        }

        currentElement = ""
        currentValue = ""
    }
}

// MARK: - OnSong Error

enum OnSongError: LocalizedError {
    case fileAccessDenied
    case archiveExtractionFailed
    case xmlParsingFailed
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Cannot access the backup file. Please check permissions."
        case .archiveExtractionFailed:
            return "Failed to extract the backup archive."
        case .xmlParsingFailed:
            return "Failed to parse XML data."
        case .invalidFormat:
            return "The file is not a valid OnSong backup."
        }
    }
}
