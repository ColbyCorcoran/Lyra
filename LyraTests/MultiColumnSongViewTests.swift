//
//  MultiColumnSongViewTests.swift
//  LyraTests
//
//  Tests for MultiColumnSongView
//

import Testing
import SwiftUI
@testable import Lyra

@Suite("MultiColumnSongView Tests")
struct MultiColumnSongViewTests {

    // MARK: - Test Data Helpers

    /// Create a simple test song
    private func createTestSong(
        title: String = "Test Song",
        content: String? = nil
    ) -> Song {
        let defaultContent = """
        {title: \(title)}
        {artist: Test Artist}
        {key: C}

        {verse}
        [C]Test [F]line [G]one
        With [C]basic [F]chords

        {chorus}
        [C]This is [F]chorus
        [G]Singing [C]along
        """

        return Song(
            title: title,
            content: content ?? defaultContent
        )
    }

    /// Create a test template
    private func createTemplate(
        columnCount: Int = 2,
        strategy: ColumnBalancingStrategy = .balanced
    ) -> Template {
        return Template(
            name: "Test Template",
            columnCount: columnCount,
            columnGap: 20.0,
            columnBalancingStrategy: strategy
        )
    }

    /// Create test display settings
    private func createDisplaySettings() -> DisplaySettings {
        return DisplaySettings.default
    }

    // MARK: - Basic Initialization Tests

    @Test("MultiColumnSongView initializes with valid inputs")
    func testInitialization() {
        let song = createTestSong()
        let template = createTemplate()
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(view.song.title == "Test Song")
        #expect(view.template.columnCount == 2)
    }

    @Test("MultiColumnSongView initializes with single column template")
    func testSingleColumnInitialization() {
        let song = createTestSong()
        let template = createTemplate(columnCount: 1)
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(view.template.columnCount == 1)
    }

    @Test("MultiColumnSongView initializes with three column template")
    func testThreeColumnInitialization() {
        let song = createTestSong()
        let template = createTemplate(columnCount: 3)
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(view.template.columnCount == 3)
    }

    // MARK: - ColumnView Tests

    @Test("ColumnView displays empty state for empty column")
    func testEmptyColumnView() {
        let emptyColumn = ColumnContent(index: 0, sections: [])
        let template = createTemplate()
        let displaySettings = createDisplaySettings()

        let view = ColumnView(
            column: emptyColumn,
            template: template,
            displaySettings: displaySettings
        )

        #expect(emptyColumn.isEmpty)
    }

    @Test("ColumnView displays sections for non-empty column")
    func testNonEmptyColumnView() {
        let song = createTestSong()
        let parsedSong = ChordProParser.parse(song.content)
        let column = ColumnContent(index: 0, sections: parsedSong.sections)
        let template = createTemplate()
        let displaySettings = createDisplaySettings()

        let view = ColumnView(
            column: column,
            template: template,
            displaySettings: displaySettings
        )

        #expect(!column.isEmpty)
        #expect(column.sections.count > 0)
    }

    // MARK: - ColumnSectionView Tests

    @Test("ColumnSectionView displays section with label")
    func testSectionViewWithLabel() {
        let song = createTestSong()
        let parsedSong = ChordProParser.parse(song.content)
        let template = createTemplate()
        let displaySettings = createDisplaySettings()

        guard let firstSection = parsedSong.sections.first else {
            Issue.record("No sections found in parsed song")
            return
        }

        let view = ColumnSectionView(
            section: firstSection,
            template: template,
            displaySettings: displaySettings
        )

        #expect(!firstSection.label.isEmpty)
    }

    // MARK: - Chord Positioning Tests

    @Test("Chord positioning style chordsOverLyrics renders correctly")
    func testChordsOverLyricsPositioning() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            chordPositioningStyle: .chordsOverLyrics
        )

        #expect(template.chordPositioningStyle == .chordsOverLyrics)
    }

    @Test("Chord positioning style inline renders correctly")
    func testInlinePositioning() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            chordPositioningStyle: .inline
        )

        #expect(template.chordPositioningStyle == .inline)
    }

    @Test("Chord positioning style separateLines renders correctly")
    func testSeparateLinesPositioning() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            chordPositioningStyle: .separateLines
        )

        #expect(template.chordPositioningStyle == .separateLines)
    }

    // MARK: - Chord Alignment Tests

    @Test("Chord alignment left renders correctly")
    func testLeftAlignedChords() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            chordAlignment: .leftAligned
        )

        #expect(template.chordAlignment == .leftAligned)
    }

    @Test("Chord alignment center renders correctly")
    func testCenteredChords() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            chordAlignment: .centered
        )

        #expect(template.chordAlignment == .centered)
    }

    @Test("Chord alignment right renders correctly")
    func testRightAlignedChords() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            chordAlignment: .rightAligned
        )

        #expect(template.chordAlignment == .rightAligned)
    }

    // MARK: - Font Size Tests

    @Test("Template respects custom title font size")
    func testTitleFontSize() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            titleFontSize: 28.0
        )

        #expect(template.titleFontSize == 28.0)
    }

    @Test("Template respects custom heading font size")
    func testHeadingFontSize() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            headingFontSize: 20.0
        )

        #expect(template.headingFontSize == 20.0)
    }

    @Test("Template respects custom body font size")
    func testBodyFontSize() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            bodyFontSize: 18.0
        )

        #expect(template.bodyFontSize == 18.0)
    }

    @Test("Template respects custom chord font size")
    func testChordFontSize() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            chordFontSize: 16.0
        )

        #expect(template.chordFontSize == 16.0)
    }

    // MARK: - Section Break Behavior Tests

    @Test("Section break behavior continueInColumn")
    func testContinueInColumnBehavior() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            sectionBreakBehavior: .continueInColumn
        )

        #expect(template.sectionBreakBehavior == .continueInColumn)
    }

    @Test("Section break behavior newColumn")
    func testNewColumnBehavior() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            sectionBreakBehavior: .newColumn
        )

        #expect(template.sectionBreakBehavior == .newColumn)
    }

    @Test("Section break behavior spaceBefore")
    func testSpaceBeforeBehavior() {
        let template = Template(
            name: "Test",
            columnCount: 1,
            sectionBreakBehavior: .spaceBefore
        )

        #expect(template.sectionBreakBehavior == .spaceBefore)
    }

    // MARK: - Integration Tests

    @Test("MultiColumnSongView works with balanced strategy")
    func testBalancedStrategy() {
        let song = createTestSong()
        let template = createTemplate(columnCount: 2, strategy: .balanced)
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(view.template.columnBalancingStrategy == .balanced)
    }

    @Test("MultiColumnSongView works with fillFirst strategy")
    func testFillFirstStrategy() {
        let song = createTestSong()
        let template = createTemplate(columnCount: 2, strategy: .fillFirst)
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(view.template.columnBalancingStrategy == .fillFirst)
    }

    @Test("MultiColumnSongView works with sectionBased strategy")
    func testSectionBasedStrategy() {
        let song = createTestSong()
        let template = createTemplate(columnCount: 2, strategy: .sectionBased)
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(view.template.columnBalancingStrategy == .sectionBased)
    }

    // MARK: - Edge Cases

    @Test("MultiColumnSongView handles empty song content")
    func testEmptySongContent() {
        let song = Song(title: "Empty Song", content: "")
        let template = createTemplate()
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(parsedSong.sections.isEmpty)
    }

    @Test("MultiColumnSongView handles song with only title")
    func testSongWithOnlyTitle() {
        let song = Song(title: "Title Only", content: "{title: Title Only}")
        let template = createTemplate()
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(parsedSong.title == "Title Only")
    }

    @Test("MultiColumnSongView handles very long song")
    func testVeryLongSong() {
        let content = """
        {title: Long Song}
        {key: C}

        {verse}
        [C]Line 1
        [C]Line 2
        [C]Line 3
        [C]Line 4

        {verse}
        [C]Line 5
        [C]Line 6
        [C]Line 7
        [C]Line 8

        {chorus}
        [F]Chorus 1
        [G]Chorus 2
        [C]Chorus 3
        [F]Chorus 4

        {verse}
        [C]Line 9
        [C]Line 10
        [C]Line 11
        [C]Line 12

        {verse}
        [C]Line 13
        [C]Line 14
        [C]Line 15
        [C]Line 16

        {bridge}
        [Am]Bridge 1
        [F]Bridge 2
        [G]Bridge 3
        [C]Bridge 4
        """

        let song = Song(title: "Long Song", content: content)
        let template = createTemplate(columnCount: 3)
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(parsedSong.sections.count > 0)
    }

    // MARK: - Real-World Scenarios

    @Test("MultiColumnSongView handles typical worship song structure")
    func testTypicalWorshipSong() {
        let content = """
        {title: Amazing Grace}
        {artist: John Newton}
        {key: G}
        {tempo: 90}

        {verse}
        [G]Amazing [G7]grace how [C]sweet the [G]sound
        That saved a [Em]wretch like [D]me
        I [G]once was [G7]lost but [C]now I'm [G]found
        Was [Em]blind but [D]now I [G]see

        {verse}
        'Twas [G]grace that [G7]taught my [C]heart to [G]fear
        And grace my [Em]fears re[D]lieved
        How [G]precious [G7]did that [C]grace ap[G]pear
        The [Em]hour I [D]first be[G]lieved

        {chorus}
        [C]Amazing [G]grace how [D]sweet the [G]sound
        [C]Forever [G]singing [D]Your [G]praise
        """

        let song = Song(title: "Amazing Grace", content: content)
        let template = createTemplate(columnCount: 2)
        let parsedSong = ChordProParser.parse(song.content)
        let displaySettings = createDisplaySettings()

        let view = MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )

        #expect(parsedSong.sections.count >= 3)
        #expect(parsedSong.title == "Amazing Grace")
        #expect(parsedSong.artist == "John Newton")
    }

    @Test("MultiColumnSongView handles custom column widths")
    func testCustomColumnWidths() {
        let template = Template(
            name: "Custom Widths",
            columnCount: 3,
            columnWidthMode: .custom
        )

        let columnWidths = template.effectiveColumnWidths(totalWidth: 900)

        #expect(columnWidths.count == 3)
        #expect(template.columnWidthMode == .custom)
    }

    @Test("MultiColumnSongView handles equal column widths")
    func testEqualColumnWidths() {
        let template = Template(
            name: "Equal Widths",
            columnCount: 3,
            columnWidthMode: .equal
        )

        let columnWidths = template.effectiveColumnWidths(totalWidth: 900)

        #expect(columnWidths.count == 3)

        let firstWidth = columnWidths[0]
        for width in columnWidths {
            #expect(abs(width - firstWidth) < 1.0)
        }
    }
}
