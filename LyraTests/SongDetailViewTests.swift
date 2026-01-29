//
//  SongDetailViewTests.swift
//  LyraTests
//
//  Tests for SongDetailView export functionality
//

import Testing
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
@testable import Lyra

@Suite("SongDetailView Tests")
@MainActor
struct SongDetailViewTests {
    var container: ModelContainer
    var context: ModelContext

    init() throws {
        let schema = Schema([Song.self, Book.self, Annotation.self, Template.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    // MARK: - Helper Methods

    func createTestSong(
        title: String = "Amazing Grace",
        artist: String? = "John Newton",
        content: String = "[G]Amazing grace, how [C]sweet the [G]sound",
        originalKey: String? = "G"
    ) -> Song {
        let song = Song(
            title: title,
            artist: artist,
            content: content,
            originalKey: originalKey
        )
        context.insert(song)
        return song
    }

    // MARK: - Initialization Tests

    @Test("SongDetailView initializes with song")
    func testInitialization() {
        let song = createTestSong()
        let view = SongDetailView(song: song)

        #expect(view.song.title == "Amazing Grace")
        #expect(view.song.artist == "John Newton")
        #expect(view.song.originalKey == "G")
    }

    @Test("SongDetailView displays song with content")
    func testSongWithContent() {
        let song = createTestSong(content: "Test content")

        #expect(!song.content.isEmpty)
        #expect(song.content == "Test content")
    }

    @Test("SongDetailView displays song without content")
    func testSongWithoutContent() {
        let song = createTestSong(content: "")

        #expect(song.content.isEmpty)
    }

    @Test("SongDetailView displays song with metadata")
    func testSongWithMetadata() {
        let song = createTestSong()
        song.tempo = 120
        song.capo = 2
        song.originalKey = "G"

        #expect(song.tempo == 120)
        #expect(song.capo == 2)
        #expect(song.originalKey == "G")
    }

    @Test("SongDetailView displays song without optional metadata")
    func testSongWithoutOptionalMetadata() {
        let song = createTestSong(artist: nil, originalKey: nil)
        song.tempo = nil
        song.capo = nil

        #expect(song.artist == nil)
        #expect(song.tempo == nil)
        #expect(song.capo == nil)
    }

    // MARK: - Export Functionality Tests

    @Test("Export handler creates temporary file")
    func testExportHandlerCreatesFile() throws {
        let song = createTestSong()
        let view = SongDetailView(song: song)
        let content = "Test export content"
        let format = SongExporter.ExportFormat.chordPro

        // Test that suggested filename is generated correctly
        let filename = SongExporter.suggestedFilename(for: song, format: format)
        #expect(filename.contains("Amazing Grace"))
        #expect(filename.hasSuffix(".cho"))

        // Test that file can be written to temporary directory
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try content.write(to: tempURL, atomically: true, encoding: .utf8)

        // Verify file was created
        let fileExists = FileManager.default.fileExists(atPath: tempURL.path)
        #expect(fileExists)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Export handler handles different formats")
    func testExportHandlerSupportsMultipleFormats() throws {
        let song = createTestSong()

        // Test all export formats
        for format in SongExporter.ExportFormat.allCases {
            let filename = SongExporter.suggestedFilename(for: song, format: format)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            let content = try {
                switch format {
                case .chordPro:
                    return try SongExporter.exportToChordPro(song)
                case .json:
                    return try SongExporter.exportToJSON(song)
                case .plainText:
                    return try SongExporter.exportToPlainText(song)
                }
            }()

            try content.write(to: tempURL, atomically: true, encoding: .utf8)

            // Verify file was created
            let fileExists = FileManager.default.fileExists(atPath: tempURL.path)
            #expect(fileExists)

            // Verify content is not empty
            #expect(!content.isEmpty)

            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    @Test("URL extension conforms to Identifiable")
    func testURLIdentifiable() {
        let url = URL(string: "https://example.com/test")!
        let id: String = url.id

        #expect(id == "https://example.com/test")
        #expect(id == url.absoluteString)
    }

    @Test("Multiple URLs have unique identifiers")
    func testMultipleURLsHaveUniqueIds() {
        let url1 = URL(string: "https://example.com/test1")!
        let url2 = URL(string: "https://example.com/test2")!

        #expect(url1.id != url2.id)
        #expect(url1.id == "https://example.com/test1")
        #expect(url2.id == "https://example.com/test2")
    }

    // MARK: - Integration Tests

    @Test("SongDetailView can export song in all formats")
    func testExportInAllFormats() throws {
        let song = createTestSong(
            title: "Test Song",
            artist: "Test Artist",
            content: "[C]Test [G]content",
            originalKey: "C"
        )
        song.tempo = 100
        song.capo = 1

        for format in SongExporter.ExportFormat.allCases {
            let content = try {
                switch format {
                case .chordPro:
                    return try SongExporter.exportToChordPro(song)
                case .json:
                    return try SongExporter.exportToJSON(song)
                case .plainText:
                    return try SongExporter.exportToPlainText(song)
                }
            }()

            // Verify content contains essential information
            #expect(content.contains("Test Song"))

            // Format-specific validations
            switch format {
            case .chordPro:
                #expect(content.contains("{title:Test Song}"))
                #expect(content.contains("{key:C}"))
            case .json:
                #expect(content.contains("\"title\""))
                #expect(content.contains("\"artist\""))
            case .plainText:
                #expect(content.contains("TEST SONG"))
            }
        }
    }
}
