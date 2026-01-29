//
//  SongExporterTests.swift
//  LyraTests
//
//  Created by Claude on 2026-01-29.
//

import Testing
import Foundation
import SwiftData
import UniformTypeIdentifiers
@testable import Lyra

@Suite("SongExporter Tests")
@MainActor
struct SongExporterTests {
    var container: ModelContainer
    var context: ModelContext

    init() throws {
        let schema = Schema([Song.self, Book.self, Annotation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    // MARK: - Helper Methods

    func createTestSong(
        title: String = "Amazing Grace",
        artist: String? = "John Newton",
        album: String? = "Hymns of Faith",
        year: Int? = 1779,
        copyright: String? = "Public Domain",
        ccliNumber: String? = "22025",
        originalKey: String? = "G",
        tempo: Int? = 96,
        timeSignature: String? = "3/4",
        capo: Int? = 0,
        content: String = """
            {title:Amazing Grace}
            {artist:John Newton}
            {key:G}

            [Verse 1]
            [G]Amazing [G/B]grace, how [C]sweet the [G]sound
            That [G]saved a [D]wretch like [G]me
            I [G]once was [G/B]lost, but [C]now I'm [G]found
            Was [Em]blind, but [D]now I [G]see
            """,
        contentFormat: ContentFormat = .chordPro,
        notes: String? = "This is a classic hymn"
    ) -> Song {
        let song = Song(
            title: title,
            artist: artist,
            content: content,
            contentFormat: contentFormat,
            originalKey: originalKey
        )

        song.album = album
        song.year = year
        song.copyright = copyright
        song.ccliNumber = ccliNumber
        song.tempo = tempo
        song.timeSignature = timeSignature
        song.capo = capo
        song.notes = notes

        context.insert(song)
        return song
    }

    // MARK: - ChordPro Export Tests

    @Test("Export to ChordPro format")
    func testExportToChordPro() throws {
        let song = createTestSong()
        let output = try SongExporter.exportToChordPro(song)

        #expect(output.contains("{title:Amazing Grace}"))
        #expect(output.contains("{artist:John Newton}"))
        #expect(output.contains("{album:Hymns of Faith}"))
        #expect(output.contains("{year:1779}"))
        #expect(output.contains("{key:G}"))
        #expect(output.contains("{tempo:96}"))
        #expect(output.contains("{time:3/4}"))
        #expect(output.contains("{copyright:Public Domain}"))
        #expect(output.contains("{ccli:22025}"))
        #expect(output.contains("[Verse 1]"))
        #expect(output.contains("[G]Amazing"))
        #expect(output.contains("{comment:This is a classic hymn}"))
    }

    @Test("Export to ChordPro with minimal metadata")
    func testExportToChordProMinimal() throws {
        let song = createTestSong(
            title: "Simple Song",
            artist: nil,
            album: nil,
            year: nil,
            copyright: nil,
            ccliNumber: nil,
            originalKey: nil,
            tempo: nil,
            timeSignature: nil,
            capo: nil,
            content: "This is the song content",
            notes: nil
        )

        let output = try SongExporter.exportToChordPro(song)

        #expect(output.contains("{title:Simple Song}"))
        #expect(output.contains("This is the song content"))
        #expect(!output.contains("{artist:"))
        #expect(!output.contains("{album:"))
        #expect(!output.contains("{comment:"))
    }

    @Test("Export to ChordPro with capo")
    func testExportToChordProWithCapo() throws {
        let song = createTestSong(capo: 2)
        let output = try SongExporter.exportToChordPro(song)

        #expect(output.contains("{capo:2}"))
    }

    @Test("Export to ChordPro with zero capo excludes capo directive")
    func testExportToChordProZeroCapo() throws {
        let song = createTestSong(capo: 0)
        let output = try SongExporter.exportToChordPro(song)

        #expect(!output.contains("{capo:"))
    }

    @Test("Export to ChordPro throws error for empty title")
    func testExportToChordProEmptyTitle() throws {
        let song = createTestSong(title: "")

        #expect(throws: SongExporter.SongExportError.self) {
            try SongExporter.exportToChordPro(song)
        }
    }

    // MARK: - JSON Export Tests

    @Test("Export to JSON format")
    func testExportToJSON() throws {
        let song = createTestSong()
        let jsonString = try SongExporter.exportToJSON(song)

        #expect(jsonString.contains("\"title\" : \"Amazing Grace\""))
        #expect(jsonString.contains("\"artist\" : \"John Newton\""))
        #expect(jsonString.contains("\"album\" : \"Hymns of Faith\""))
        #expect(jsonString.contains("\"year\" : 1779"))
        #expect(jsonString.contains("\"copyright\" : \"Public Domain\""))
        #expect(jsonString.contains("\"ccliNumber\" : \"22025\""))
        #expect(jsonString.contains("\"originalKey\" : \"G\""))
        #expect(jsonString.contains("\"tempo\" : 96"))
        #expect(jsonString.contains("\"timeSignature\" : \"3/4\""))
        #expect(jsonString.contains("\"contentFormat\" : \"chordPro\""))
        #expect(jsonString.contains("\"notes\" : \"This is a classic hymn\""))
    }

    @Test("Export to JSON data")
    func testExportToJSONData() throws {
        let song = createTestSong()
        let data = try SongExporter.exportToJSONData(song)

        #expect(data.count > 0)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(SongExportData.self, from: data)

        #expect(exportData.title == "Amazing Grace")
        #expect(exportData.artist == "John Newton")
        #expect(exportData.album == "Hymns of Faith")
        #expect(exportData.year == 1779)
        #expect(exportData.copyright == "Public Domain")
        #expect(exportData.ccliNumber == "22025")
        #expect(exportData.originalKey == "G")
        #expect(exportData.tempo == 96)
        #expect(exportData.timeSignature == "3/4")
        #expect(exportData.contentFormat == "chordPro")
        #expect(exportData.notes == "This is a classic hymn")
    }

    @Test("Export to JSON with nil values")
    func testExportToJSONWithNilValues() throws {
        let song = createTestSong(
            title: "Simple Song",
            artist: nil,
            album: nil,
            year: nil,
            notes: nil
        )

        let data = try SongExporter.exportToJSONData(song)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(SongExportData.self, from: data)

        #expect(exportData.title == "Simple Song")
        #expect(exportData.artist == nil)
        #expect(exportData.album == nil)
        #expect(exportData.year == nil)
        #expect(exportData.notes == nil)
    }

    @Test("Export to JSON throws error for empty title")
    func testExportToJSONEmptyTitle() throws {
        let song = createTestSong(title: "")

        #expect(throws: SongExporter.SongExportError.self) {
            try SongExporter.exportToJSON(song)
        }
    }

    // MARK: - Plain Text Export Tests

    @Test("Export to plain text format")
    func testExportToPlainText() throws {
        let song = createTestSong()
        let output = try SongExporter.exportToPlainText(song)

        #expect(output.contains("AMAZING GRACE"))
        #expect(output.contains("Artist: John Newton"))
        #expect(output.contains("Album: Hymns of Faith"))
        #expect(output.contains("Year: 1779"))
        #expect(output.contains("Key: G"))
        #expect(output.contains("Tempo: 96 BPM"))
        #expect(output.contains("Time Signature: 3/4"))
        #expect(output.contains("Copyright: Public Domain"))
        #expect(output.contains("CCLI#: 22025"))
        #expect(output.contains("[Verse 1]"))
        #expect(output.contains("NOTES:"))
        #expect(output.contains("This is a classic hymn"))
    }

    @Test("Export to plain text with minimal metadata")
    func testExportToPlainTextMinimal() throws {
        let song = createTestSong(
            title: "Simple Song",
            artist: nil,
            album: nil,
            year: nil,
            copyright: nil,
            ccliNumber: nil,
            originalKey: nil,
            tempo: nil,
            timeSignature: nil,
            capo: nil,
            content: "This is the song content",
            notes: nil
        )

        let output = try SongExporter.exportToPlainText(song)

        #expect(output.contains("SIMPLE SONG"))
        #expect(output.contains("This is the song content"))
        #expect(!output.contains("Artist:"))
        #expect(!output.contains("NOTES:"))
    }

    @Test("Export to plain text with capo")
    func testExportToPlainTextWithCapo() throws {
        let song = createTestSong(capo: 3)
        let output = try SongExporter.exportToPlainText(song)

        #expect(output.contains("Capo: 3"))
    }

    @Test("Export to plain text throws error for empty content")
    func testExportToPlainTextEmptyContent() throws {
        let song = createTestSong(content: "")

        #expect(throws: SongExporter.SongExportError.self) {
            try SongExporter.exportToPlainText(song)
        }
    }

    @Test("Export to plain text throws error for empty title")
    func testExportToPlainTextEmptyTitle() throws {
        let song = createTestSong(title: "")

        #expect(throws: SongExporter.SongExportError.self) {
            try SongExporter.exportToPlainText(song)
        }
    }

    // MARK: - File Export Tests

    @Test("Export to file - ChordPro")
    func testExportToFileChordPro() throws {
        let song = createTestSong()
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_song.cho")

        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        try SongExporter.exportToFile(song, format: .chordPro, url: fileURL)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(content.contains("{title:Amazing Grace}"))
    }

    @Test("Export to file - JSON")
    func testExportToFileJSON() throws {
        let song = createTestSong()
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_song.json")

        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        try SongExporter.exportToFile(song, format: .json, url: fileURL)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(content.contains("\"title\" : \"Amazing Grace\""))
    }

    @Test("Export to file - Plain Text")
    func testExportToFilePlainText() throws {
        let song = createTestSong()
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_song.txt")

        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        try SongExporter.exportToFile(song, format: .plainText, url: fileURL)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(content.contains("AMAZING GRACE"))
    }

    // MARK: - Filename Generation Tests

    @Test("Suggested filename with artist")
    func testSuggestedFilenameWithArtist() {
        let song = createTestSong(title: "Amazing Grace", artist: "John Newton")
        let filename = SongExporter.suggestedFilename(for: song, format: .chordPro)

        #expect(filename == "Amazing Grace - John Newton.cho")
    }

    @Test("Suggested filename without artist")
    func testSuggestedFilenameWithoutArtist() {
        let song = createTestSong(title: "Amazing Grace", artist: nil)
        let filename = SongExporter.suggestedFilename(for: song, format: .json)

        #expect(filename == "Amazing Grace.json")
    }

    @Test("Suggested filename sanitizes invalid characters")
    func testSuggestedFilenameSanitization() {
        let song = createTestSong(title: "Song/With:Invalid*Characters?", artist: "Artist<Name>")
        let filename = SongExporter.suggestedFilename(for: song, format: .plainText)

        #expect(!filename.contains("/"))
        #expect(!filename.contains(":"))
        #expect(!filename.contains("*"))
        #expect(!filename.contains("?"))
        #expect(!filename.contains("<"))
        #expect(!filename.contains(">"))
        #expect(filename.contains("_"))
        #expect(filename.hasSuffix(".txt"))
    }

    @Test("Suggested filename for different formats")
    func testSuggestedFilenameFormats() {
        let song = createTestSong(title: "Test Song")

        let chordProFilename = SongExporter.suggestedFilename(for: song, format: .chordPro)
        #expect(chordProFilename.hasSuffix(".cho"))

        let jsonFilename = SongExporter.suggestedFilename(for: song, format: .json)
        #expect(jsonFilename.hasSuffix(".json"))

        let txtFilename = SongExporter.suggestedFilename(for: song, format: .plainText)
        #expect(txtFilename.hasSuffix(".txt"))
    }

    // MARK: - Multiple Songs Export Tests

    @Test("Export multiple songs")
    func testExportMultipleSongs() throws {
        let song1 = createTestSong(title: "Song 1", ccliNumber: "111")
        let song2 = createTestSong(title: "Song 2", ccliNumber: "222")
        let song3 = createTestSong(title: "Song 3", ccliNumber: "333")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_export_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let exportedURLs = try SongExporter.exportMultipleSongs(
            [song1, song2, song3],
            format: .chordPro,
            to: tempDir
        )

        #expect(exportedURLs.count == 3)

        for url in exportedURLs {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }

    @Test("Export multiple songs with different formats")
    func testExportMultipleSongsJSON() throws {
        let song1 = createTestSong(title: "Song A", ccliNumber: "AAA")
        let song2 = createTestSong(title: "Song B", ccliNumber: "BBB")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_export_json_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let exportedURLs = try SongExporter.exportMultipleSongs(
            [song1, song2],
            format: .json,
            to: tempDir
        )

        #expect(exportedURLs.count == 2)

        for url in exportedURLs {
            #expect(url.pathExtension == "json")
            let content = try String(contentsOf: url, encoding: .utf8)
            #expect(content.contains("\"title\""))
        }
    }

    // MARK: - Export Format Tests

    @Test("Export format display names")
    func testExportFormatDisplayNames() {
        #expect(SongExporter.ExportFormat.chordPro.displayName == "ChordPro")
        #expect(SongExporter.ExportFormat.json.displayName == "JSON")
        #expect(SongExporter.ExportFormat.plainText.displayName == "Plain Text")
    }

    @Test("Export format file extensions")
    func testExportFormatFileExtensions() {
        #expect(SongExporter.ExportFormat.chordPro.fileExtension == "cho")
        #expect(SongExporter.ExportFormat.json.fileExtension == "json")
        #expect(SongExporter.ExportFormat.plainText.fileExtension == "txt")
    }

    @Test("Export format UTType")
    func testExportFormatUTType() {
        #expect(SongExporter.ExportFormat.chordPro.utType == .plainText)
        #expect(SongExporter.ExportFormat.json.utType == .json)
        #expect(SongExporter.ExportFormat.plainText.utType == .plainText)
    }

    // MARK: - Error Handling Tests

    @Test("Error descriptions are present")
    func testErrorDescriptions() {
        let errors: [SongExporter.SongExportError] = [
            .invalidSongData,
            .encodingFailed,
            .fileWriteFailed(NSError(domain: "test", code: 0)),
            .unsupportedFormat,
            .emptyContent
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.recoverySuggestion != nil)
        }
    }

    // MARK: - Content Format Tests

    @Test("Export ChordPro content as-is")
    func testExportChordProContentFormat() throws {
        let chordProContent = "{title:Test}\n[Verse]\n[C]Content"
        let song = createTestSong(
            title: "Test",
            content: chordProContent,
            contentFormat: .chordPro
        )

        let output = try SongExporter.exportToChordPro(song)
        #expect(output.contains(chordProContent))
    }

    @Test("Export plain text content format")
    func testExportPlainTextContentFormat() throws {
        let plainContent = "This is plain text content"
        let song = createTestSong(
            title: "Test",
            content: plainContent,
            contentFormat: .plainText
        )

        let output = try SongExporter.exportToChordPro(song)
        #expect(output.contains(plainContent))
    }

    @Test("Export with tags in JSON")
    func testExportWithTags() throws {
        let song = createTestSong(title: "Tagged Song")
        song.tags = ["worship", "contemporary", "favorite"]

        let data = try SongExporter.exportToJSONData(song)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(SongExportData.self, from: data)

        #expect(exportData.tags?.count == 3)
        #expect(exportData.tags?.contains("worship") == true)
        #expect(exportData.tags?.contains("contemporary") == true)
        #expect(exportData.tags?.contains("favorite") == true)
    }

    @Test("Export with custom fields in JSON")
    func testExportWithCustomFields() throws {
        let song = createTestSong(title: "Custom Song")
        song.customField1 = "Custom Value 1"
        song.customField2 = "Custom Value 2"
        song.customField3 = "Custom Value 3"

        let data = try SongExporter.exportToJSONData(song)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(SongExportData.self, from: data)

        #expect(exportData.customField1 == "Custom Value 1")
        #expect(exportData.customField2 == "Custom Value 2")
        #expect(exportData.customField3 == "Custom Value 3")
    }
}
