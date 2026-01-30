//
//  ExportOptionsSheetTests.swift
//  LyraTests
//
//  Tests for ExportOptionsSheet
//

import Testing
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
@testable import Lyra

@Suite("ExportOptionsSheet Tests")
@MainActor
struct ExportOptionsSheetTests {
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
        notes: String? = "A classic hymn"
    ) -> Song {
        let song = Song(
            title: title,
            artist: artist,
            content: content,
            originalKey: "G"
        )
        song.notes = notes
        context.insert(song)
        return song
    }

    // MARK: - Initialization Tests

    @Test("ExportOptionsSheet initializes with song and callback")
    func testInitialization() {
        let song = createTestSong()
        var exportCalled = false

        let view = ExportOptionsSheet(song: song) { _ in
            exportCalled = true
        }

        #expect(view.song.title == "Amazing Grace")
        #expect(!exportCalled)
    }

    // MARK: - Format Tests

    @Test("All export formats are available")
    func testAllFormatsAvailable() {
        let formats = SongExporter.ExportFormat.allCases

        #expect(formats.count == 5)
        #expect(formats.contains(.chordPro))
        #expect(formats.contains(.pdf))
        #expect(formats.contains(.plainText))
        #expect(formats.contains(.lyraBundle))
        #expect(formats.contains(.json))
    }

    @Test("Song can have notes")
    func testSongWithNotes() {
        let song = createTestSong(notes: "These are notes")

        #expect(song.notes != nil)
        #expect(!song.notes!.isEmpty)
    }

    @Test("Song can be without notes")
    func testSongWithoutNotes() {
        let song = createTestSong(notes: nil)

        #expect(song.notes == nil)
    }

    // MARK: - Integration Tests - Using SongExporter Directly

    @Test("SongExporter exports ChordPro content correctly")
    func testSongExporterChordPro() throws {
        let song = createTestSong()

        let content = try SongExporter.exportToChordPro(song)

        #expect(content.contains("{title:Amazing Grace}"))
        #expect(content.contains("Amazing grace"))
    }

    @Test("SongExporter exports JSON content correctly")
    func testSongExporterJSON() throws {
        let song = createTestSong()

        let content = try SongExporter.exportToJSON(song)

        #expect(content.contains("\"title\""))
        #expect(content.contains("Amazing Grace"))
    }

    @Test("SongExporter exports Plain Text content correctly")
    func testSongExporterPlainText() throws {
        let song = createTestSong()

        let content = try SongExporter.exportToPlainText(song)

        #expect(content.contains("AMAZING GRACE"))
    }

    @Test("SongExporter generates correct filename")
    func testSongExporterFilename() {
        let song = createTestSong(title: "Test Song", artist: "Test Artist")

        let filename = SongExporter.suggestedFilename(for: song, format: .chordPro)

        #expect(filename.contains("Test Song"))
        #expect(filename.contains("Test Artist"))
        #expect(filename.hasSuffix(".cho"))
    }

    @Test("SongExporter exports PDF data")
    func testSongExporterPDF() throws {
        let song = createTestSong()

        let pdfData = try SongExporter.exportToPDF(song, template: nil)

        #expect(!pdfData.isEmpty)
        // PDF files start with %PDF
        let prefix = String(data: pdfData.prefix(4), encoding: .ascii)
        #expect(prefix == "%PDF")
    }

    @Test("SongExporter exports Lyra Bundle correctly")
    func testSongExporterLyraBundle() throws {
        let song = createTestSong()
        let template = Template.builtInTwoColumn()

        let content = try SongExporter.exportToLyraBundle(song, template: template)

        #expect(content.contains("\"version\""))
        #expect(content.contains("\"template\""))
        #expect(content.contains("\"song\""))
        #expect(content.contains("Amazing Grace"))
        #expect(content.contains("\"columnCount\" : 2"))
    }

    @Test("SongExporter PDF filename has correct extension")
    func testPDFFilenameExtension() {
        let song = createTestSong()
        let filename = SongExporter.suggestedFilename(for: song, format: .pdf)
        #expect(filename.hasSuffix(".pdf"))
    }

    @Test("SongExporter Lyra Bundle filename has correct extension")
    func testLyraBundleFilenameExtension() {
        let song = createTestSong()
        let filename = SongExporter.suggestedFilename(for: song, format: .lyraBundle)
        #expect(filename.hasSuffix(".lyra"))
    }
}
