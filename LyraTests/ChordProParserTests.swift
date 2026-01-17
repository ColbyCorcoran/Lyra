//
//  ChordProParserTests.swift
//  LyraTests
//
//  Comprehensive unit tests for ChordPro parser
//

import XCTest
@testable import Lyra

final class ChordProParserTests: XCTestCase {

    // MARK: - Metadata Parsing Tests

    func testParseBasicMetadata() {
        let chordPro = """
        {title: Amazing Grace}
        {artist: John Newton}
        {key: G}
        {tempo: 90}
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.title, "Amazing Grace")
        XCTAssertEqual(parsed.artist, "John Newton")
        XCTAssertEqual(parsed.key, "G")
        XCTAssertEqual(parsed.tempo, 90)
    }

    func testParseShorthandMetadata() {
        let chordPro = """
        {t: Test Song}
        {st: Subtitle Text}
        {a: Test Artist}
        {k: D}
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.title, "Test Song")
        XCTAssertEqual(parsed.subtitle, "Subtitle Text")
        XCTAssertEqual(parsed.artist, "Test Artist")
        XCTAssertEqual(parsed.key, "D")
    }

    func testParseExtendedMetadata() {
        let chordPro = """
        {title: Great Song}
        {album: Greatest Hits}
        {year: 2023}
        {copyright: Copyright 2023}
        {ccli: 1234567}
        {composer: Jane Doe}
        {time: 4/4}
        {capo: 2}
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.album, "Greatest Hits")
        XCTAssertEqual(parsed.year, 2023)
        XCTAssertEqual(parsed.copyright, "Copyright 2023")
        XCTAssertEqual(parsed.ccliNumber, "1234567")
        XCTAssertEqual(parsed.composer, "Jane Doe")
        XCTAssertEqual(parsed.timeSignature, "4/4")
        XCTAssertEqual(parsed.capo, 2)
    }

    // MARK: - Inline Chord Parsing Tests

    func testParseInlineChords() {
        let chordPro = """
        Ama[G]zing gr[C]ace how [G]sweet the [D]sound
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.sections.count, 1)
        let section = parsed.sections[0]
        XCTAssertEqual(section.lines.count, 1)

        let line = section.lines[0]
        XCTAssertTrue(line.hasChords)
        XCTAssertEqual(line.chords, ["G", "C", "G", "D"])
    }

    func testParseChordAtStartOfLine() {
        let chordPro = """
        [G]Amazing grace
        """

        let parsed = ChordProParser.parse(chordPro)
        let line = parsed.sections[0].lines[0]

        XCTAssertTrue(line.hasChords)
        XCTAssertEqual(line.segments.count, 1)
        XCTAssertEqual(line.segments[0].chord, "G")
        XCTAssertEqual(line.segments[0].text, "Amazing grace")
    }

    func testParseChordAtEndOfLine() {
        let chordPro = """
        Amazing grace[D]
        """

        let parsed = ChordProParser.parse(chordPro)
        let line = parsed.sections[0].lines[0]

        XCTAssertTrue(line.hasChords)
        XCTAssertEqual(line.chords.last, "D")
    }

    func testParseComplexChords() {
        let chordPro = """
        [G]Test [C#m7]complex [Bb/D]chords [Dsus4]here
        """

        let parsed = ChordProParser.parse(chordPro)
        let line = parsed.sections[0].lines[0]

        XCTAssertEqual(line.chords, ["G", "C#m7", "Bb/D", "Dsus4"])
    }

    // MARK: - Chords on Separate Lines Tests

    func testParseChordsAboveLyrics() {
        let chordPro = """
        [G]  [C]  [D]
        Amazing grace how sweet
        """

        let parsed = ChordProParser.parse(chordPro)
        let section = parsed.sections[0]

        // Should merge into one line
        XCTAssertGreaterThanOrEqual(section.lines.count, 1)
    }

    // MARK: - Section Parsing Tests

    func testParseExplicitSections() {
        let chordPro = """
        {start_of_verse}
        Line 1
        Line 2
        {end_of_verse}

        {start_of_chorus}
        Chorus line
        {end_of_chorus}
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.sections.count, 2)
        XCTAssertEqual(parsed.sections[0].type, .verse)
        XCTAssertEqual(parsed.sections[1].type, .chorus)
    }

    func testParseShorthandSections() {
        let chordPro = """
        {sov}
        Verse text
        {eov}

        {soc}
        Chorus text
        {eoc}
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.sections.count, 2)
        XCTAssertEqual(parsed.sections[0].type, .verse)
        XCTAssertEqual(parsed.sections[1].type, .chorus)
    }

    func testParseSectionLabels() {
        let chordPro = """
        {verse}
        First verse
        {verse}
        Second verse
        {chorus}
        Only chorus
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.sections.count, 3)
        XCTAssertEqual(parsed.sections[0].label, "Verse 1")
        XCTAssertEqual(parsed.sections[1].label, "Verse 2")
        XCTAssertEqual(parsed.sections[2].label, "Chorus")
    }

    func testParseBridge() {
        let chordPro = """
        {start_of_bridge}
        Bridge text here
        {end_of_bridge}
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.sections.count, 1)
        XCTAssertEqual(parsed.sections[0].type, .bridge)
    }

    // MARK: - Comment Parsing Tests

    func testParseLineComments() {
        let chordPro = """
        # This is a comment
        [G]Actual lyrics
        """

        let parsed = ChordProParser.parse(chordPro)
        let section = parsed.sections[0]

        XCTAssertEqual(section.lines.count, 2)
        XCTAssertEqual(section.lines[0].type, .comment)
    }

    func testParseDirectiveComments() {
        let chordPro = """
        {comment: This is a comment directive}
        [G]Lyrics here
        """

        let parsed = ChordProParser.parse(chordPro)
        let section = parsed.sections[0]

        XCTAssertEqual(section.lines[0].type, .comment)
    }

    func testParseShorthandComment() {
        let chordPro = """
        {c: Short comment}
        Lyrics
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.sections[0].lines[0].type, .comment)
    }

    // MARK: - Complete Song Tests

    func testParseCompleteSong() {
        let chordPro = """
        {title: Amazing Grace}
        {artist: John Newton}
        {key: G}
        {start_of_verse}
        Ama[G]zing gr[C]ace how [G]sweet the [D]sound
        That [G]saved a [C]wretch like [G]me[D]
        {end_of_verse}
        {start_of_chorus}
        [G]I once was [C]lost but [G]now am [D]found
        Was [G]blind but [C]now I [G]see
        {end_of_chorus}
        """

        let parsed = ChordProParser.parse(chordPro)

        // Check metadata
        XCTAssertEqual(parsed.title, "Amazing Grace")
        XCTAssertEqual(parsed.artist, "John Newton")
        XCTAssertEqual(parsed.key, "G")

        // Check sections
        XCTAssertEqual(parsed.sections.count, 2)
        XCTAssertEqual(parsed.sections[0].type, .verse)
        XCTAssertEqual(parsed.sections[1].type, .chorus)

        // Check chords
        XCTAssertTrue(parsed.hasChords)
        XCTAssertTrue(parsed.uniqueChords.contains("G"))
        XCTAssertTrue(parsed.uniqueChords.contains("C"))
        XCTAssertTrue(parsed.uniqueChords.contains("D"))
    }

    // MARK: - Blank Line Tests

    func testPreserveBlankLines() {
        let chordPro = """
        Line 1

        Line 2
        """

        let parsed = ChordProParser.parse(chordPro)
        let section = parsed.sections[0]

        XCTAssertEqual(section.lines.count, 3)
        XCTAssertEqual(section.lines[1].type, .blank)
    }

    // MARK: - Edge Case Tests

    func testParseEmptyString() {
        let parsed = ChordProParser.parse("")

        XCTAssertEqual(parsed.sections.count, 0)
    }

    func testParseMalformedChord() {
        let chordPro = """
        Test [Unclosed chord
        """

        let parsed = ChordProParser.parse(chordPro)

        // Should handle gracefully
        XCTAssertGreaterThanOrEqual(parsed.sections.count, 0)
    }

    func testParseMultipleWhitespace() {
        let chordPro = """
        {title:    Multiple   Spaces   }
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.title, "Multiple   Spaces")
    }

    func testParseWithoutExplicitSections() {
        let chordPro = """
        {title: Simple Song}
        [G]Line 1
        [C]Line 2
        [D]Line 3
        """

        let parsed = ChordProParser.parse(chordPro)

        // Should create default verse section
        XCTAssertGreaterThanOrEqual(parsed.sections.count, 1)
    }

    // MARK: - Helper Property Tests

    func testUniqueChords() {
        let chordPro = """
        [G]Test [C]test [G]again [D]test [C]more
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.uniqueChords.count, 3) // G, C, D
    }

    func testAllChords() {
        let chordPro = """
        [G]Test [C]test [G]again
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.allChords, ["G", "C", "G"])
    }

    func testVerses() {
        let chordPro = """
        {verse}
        Verse 1
        {verse}
        Verse 2
        {chorus}
        Chorus
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.verses.count, 2)
    }

    func testChoruses() {
        let chordPro = """
        {verse}
        Verse
        {chorus}
        Chorus 1
        {chorus}
        Chorus 2
        """

        let parsed = ChordProParser.parse(chordPro)

        XCTAssertEqual(parsed.choruses.count, 2)
    }
}
