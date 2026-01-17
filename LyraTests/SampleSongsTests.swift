//
//  SampleSongsTests.swift
//  LyraTests
//
//  Tests for all sample ChordPro songs
//

import XCTest
@testable import Lyra

final class SampleSongsTests: XCTestCase {

    func testParseAmazingGrace() {
        let parsed = ChordProParser.parse(SampleChordProSongs.amazingGrace)

        XCTAssertEqual(parsed.title, "Amazing Grace")
        XCTAssertEqual(parsed.artist, "John Newton")
        XCTAssertEqual(parsed.key, "G")
        XCTAssertEqual(parsed.tempo, 90)
        XCTAssertEqual(parsed.timeSignature, "3/4")

        XCTAssertEqual(parsed.sections.count, 3) // 2 verses + 1 chorus
        XCTAssertEqual(parsed.verses.count, 2)
        XCTAssertEqual(parsed.choruses.count, 1)
    }

    func testParseBlestBeTheTie() {
        let parsed = ChordProParser.parse(SampleChordProSongs.blestBeTheTie)

        XCTAssertEqual(parsed.title, "Blest Be the Tie")
        XCTAssertEqual(parsed.subtitle, "That Binds")
        XCTAssertEqual(parsed.artist, "John Fawcett")
        XCTAssertEqual(parsed.key, "D")
        XCTAssertEqual(parsed.capo, 0)

        XCTAssertEqual(parsed.verses.count, 2)
    }

    func testParseHowGreatThouArt() {
        let parsed = ChordProParser.parse(SampleChordProSongs.howGreatThouArt)

        XCTAssertEqual(parsed.title, "How Great Thou Art")
        XCTAssertEqual(parsed.artist, "Carl Boberg")
        XCTAssertEqual(parsed.key, "C")
        XCTAssertNotNil(parsed.copyright)

        XCTAssertGreaterThanOrEqual(parsed.sections.count, 2)
        XCTAssertTrue(parsed.hasChords)
    }

    func testParseInlineChords() {
        let parsed = ChordProParser.parse(SampleChordProSongs.inlineChords)

        XCTAssertEqual(parsed.title, "Inline Chord Test")

        // Check that inline chords are properly parsed
        for section in parsed.sections {
            for line in section.lines where line.type == .lyrics {
                // Verify segments are created
                XCTAssertGreaterThan(line.segments.count, 0)
            }
        }
    }

    func testParseSeparateChords() {
        let parsed = ChordProParser.parse(SampleChordProSongs.separateChordsExample)

        XCTAssertEqual(parsed.title, "Separate Chords Example")
        XCTAssertTrue(parsed.hasChords)

        // Should have parsed chords successfully
        XCTAssertGreaterThan(parsed.uniqueChords.count, 0)
    }

    func testParseComplexExample() {
        let parsed = ChordProParser.parse(SampleChordProSongs.complexExample)

        // Metadata
        XCTAssertEqual(parsed.title, "Complex Test Song")
        XCTAssertEqual(parsed.subtitle, "With All Features")
        XCTAssertEqual(parsed.artist, "Test Composer")
        XCTAssertEqual(parsed.album, "Test Album")
        XCTAssertEqual(parsed.key, "D")
        XCTAssertEqual(parsed.tempo, 120)
        XCTAssertEqual(parsed.timeSignature, "4/4")
        XCTAssertEqual(parsed.capo, 2)
        XCTAssertEqual(parsed.year, 2023)
        XCTAssertEqual(parsed.copyright, "Copyright 2023")
        XCTAssertEqual(parsed.ccliNumber, "7654321")

        // Sections
        XCTAssertGreaterThan(parsed.sections.count, 3)

        // Check for different section types
        let sectionTypes = Set(parsed.sections.map { $0.type })
        XCTAssertTrue(sectionTypes.contains(.verse))
        XCTAssertTrue(sectionTypes.contains(.chorus))

        // Comments should be preserved
        let commentLines = parsed.sections.flatMap { $0.lines }.filter { $0.type == .comment }
        XCTAssertGreaterThan(commentLines.count, 0)
    }

    func testParseMinimalExample() {
        let parsed = ChordProParser.parse(SampleChordProSongs.minimalExample)

        XCTAssertEqual(parsed.title, "Minimal Song")

        // Should still create sections even without chords
        XCTAssertGreaterThan(parsed.sections.count, 0)
        XCTAssertFalse(parsed.hasChords)
    }

    func testParseMalformedExample() {
        // Should handle malformed input gracefully without crashing
        let parsed = ChordProParser.parse(SampleChordProSongs.malformedExample)

        // Should still extract some valid content
        XCTAssertNotNil(parsed.sections)

        // Should still have parsed valid chords
        XCTAssertTrue(parsed.uniqueChords.contains("G") || parsed.uniqueChords.contains("C"))
    }

    func testAllSampleSongsParse() {
        // Ensure all sample songs parse without crashing
        for (name, chordPro) in SampleChordProSongs.all {
            let parsed = ChordProParser.parse(chordPro)
            XCTAssertNotNil(parsed, "Failed to parse: \(name)")
            XCTAssertNotNil(parsed.sections, "No sections found in: \(name)")
        }
    }

    func testRawTextPreservation() {
        let original = SampleChordProSongs.amazingGrace
        let parsed = ChordProParser.parse(original)

        XCTAssertEqual(parsed.rawText, original)
    }

    func testLyricsOnlyExtraction() {
        let parsed = ChordProParser.parse(SampleChordProSongs.inlineChords)

        let lyricsOnly = parsed.lyricsOnly

        // Should contain lyrics but not chord notation
        XCTAssertTrue(lyricsOnly.contains("Amazing"))
        XCTAssertFalse(lyricsOnly.contains("[G]"))
        XCTAssertFalse(lyricsOnly.contains("[C]"))
    }
}
