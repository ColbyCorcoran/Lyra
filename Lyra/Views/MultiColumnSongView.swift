//
//  MultiColumnSongView.swift
//  Lyra
//
//  View for displaying song content in multiple columns using templates
//

import SwiftUI
import SwiftData

struct MultiColumnSongView: View {
    let song: Song
    let template: Template
    let parsedSong: ParsedSong
    let displaySettings: DisplaySettings

    @State private var containerSize: CGSize = .zero
    @State private var columns: [ColumnContent] = []

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack(alignment: .top, spacing: CGFloat(template.columnGap)) {
                    ForEach(columns) { column in
                        ColumnView(
                            column: column,
                            template: template,
                            displaySettings: displaySettings
                        )
                        .frame(width: columnWidth(for: column.index, totalWidth: geometry.size.width))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .onAppear {
                containerSize = geometry.size
                distributeContent(availableWidth: geometry.size.width)
            }
            .onChange(of: geometry.size) { _, newSize in
                containerSize = newSize
                distributeContent(availableWidth: newSize.width)
            }
            .onChange(of: parsedSong.sections) { _, _ in
                distributeContent(availableWidth: containerSize.width)
            }
            .onChange(of: template.columnCount) { _, _ in
                distributeContent(availableWidth: containerSize.width)
            }
            .onChange(of: template.columnBalancingStrategy) { _, _ in
                distributeContent(availableWidth: containerSize.width)
            }
        }
    }

    // MARK: - Helper Methods

    /// Distribute content across columns using ColumnLayoutEngine
    private func distributeContent(availableWidth: CGFloat) {
        guard availableWidth > 0 else { return }

        let horizontalPadding: CGFloat = 32
        let effectiveWidth = availableWidth - horizontalPadding

        columns = ColumnLayoutEngine.distributeContent(
            parsedSong.sections,
            template: template,
            availableWidth: effectiveWidth
        )
    }

    /// Calculate width for a specific column
    private func columnWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        let horizontalPadding: CGFloat = 32
        let effectiveWidth = totalWidth - horizontalPadding
        let columnWidths = template.effectiveColumnWidths(totalWidth: effectiveWidth)

        guard index < columnWidths.count else {
            return 0
        }

        return columnWidths[index]
    }
}

// MARK: - Column View

struct ColumnView: View {
    let column: ColumnContent
    let template: Template
    let displaySettings: DisplaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: displaySettings.actualLineSpacing) {
            if column.isEmpty {
                EmptyColumnView()
            } else {
                ForEach(column.sections) { section in
                    ColumnSectionView(
                        section: section,
                        template: template,
                        displaySettings: displaySettings
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Column Section View

struct ColumnSectionView: View {
    let section: SongSection
    let template: Template
    let displaySettings: DisplaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: displaySettings.actualLineSpacing) {
            // Section Label
            Text(section.label)
                .font(.system(size: template.headingFontSize, weight: .bold))
                .foregroundStyle(displaySettings.sectionLabelColorValue())
                .padding(.bottom, 4)

            // Section Lines
            ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                ColumnChordLineView(
                    line: line,
                    template: template,
                    displaySettings: displaySettings
                )
            }
        }
        .padding(.bottom, CGFloat(template.sectionBreakBehavior == .spaceBefore ? 20 : 12))
    }
}

// MARK: - Column Chord Line View

struct ColumnChordLineView: View {
    let line: SongLine
    let template: Template
    let displaySettings: DisplaySettings

    var body: some View {
        switch line.type {
        case .lyrics:
            renderLyricsWithChords()
        case .chordsOnly:
            renderChordsOnly()
        case .blank:
            Text(" ")
                .font(.system(size: template.bodyFontSize))
        case .comment:
            Text(line.text)
                .font(.system(size: template.bodyFontSize - 2))
                .foregroundStyle(.tertiary)
                .italic()
        case .directive:
            EmptyView()
        }
    }

    @ViewBuilder
    private func renderLyricsWithChords() -> some View {
        if line.hasChords {
            switch template.chordPositioningStyle {
            case .chordsOverLyrics:
                renderChordsOverLyrics()
            case .inline:
                renderInlineChords()
            case .separateLines:
                renderSeparateLines()
            }
        } else {
            Text(line.text)
                .font(.system(size: template.bodyFontSize))
                .foregroundStyle(displaySettings.lyricsColorValue())
        }
    }

    @ViewBuilder
    private func renderChordsOverLyrics() -> some View {
        VStack(alignment: .leading, spacing: displaySettings.spacing) {
            chordLayer
            lyricsLayer
        }
    }

    @ViewBuilder
    private func renderInlineChords() -> some View {
        Text(buildInlineText())
            .font(.system(size: template.bodyFontSize))
            .foregroundStyle(displaySettings.lyricsColorValue())
    }

    @ViewBuilder
    private func renderSeparateLines() -> some View {
        VStack(alignment: .leading, spacing: displaySettings.spacing) {
            chordLayer
            lyricsLayer
        }
    }

    @ViewBuilder
    private var chordLayer: some View {
        let charWidth = template.chordFontSize * 0.6

        ZStack(alignment: .topLeading) {
            Text(line.text)
                .font(.system(size: template.chordFontSize, design: .monospaced))
                .opacity(0)

            ForEach(Array(line.segments.enumerated()), id: \.offset) { _, segment in
                if let chord = segment.displayChord {
                    Text(chord)
                        .font(.system(size: template.chordFontSize, weight: .medium, design: .monospaced))
                        .foregroundStyle(displaySettings.chordColorValue())
                        .offset(x: CGFloat(segment.position) * charWidth, y: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: alignmentForChords())
    }

    @ViewBuilder
    private var lyricsLayer: some View {
        Text(line.text)
            .font(.system(size: template.bodyFontSize))
            .foregroundStyle(displaySettings.lyricsColorValue())
    }

    @ViewBuilder
    private func renderChordsOnly() -> some View {
        let charWidth = template.chordFontSize * 0.6

        ZStack(alignment: .topLeading) {
            let maxPosition = line.segments.map { $0.position + ($0.chord?.count ?? 0) }.max() ?? 0
            Text(String(repeating: " ", count: maxPosition))
                .font(.system(size: template.chordFontSize, design: .monospaced))
                .opacity(0)

            ForEach(Array(line.segments.enumerated()), id: \.offset) { _, segment in
                if let chord = segment.displayChord {
                    Text(chord)
                        .font(.system(size: template.chordFontSize, weight: .medium, design: .monospaced))
                        .foregroundStyle(displaySettings.chordColorValue())
                        .offset(x: CGFloat(segment.position) * charWidth, y: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: alignmentForChords())
    }

    private func alignmentForChords() -> Alignment {
        switch template.chordAlignment {
        case .leftAligned:
            return .leading
        case .centered:
            return .center
        case .rightAligned:
            return .trailing
        }
    }

    private func buildInlineText() -> String {
        var result = ""
        for segment in line.segments {
            if let chord = segment.displayChord {
                result += "[\(chord)]"
            }
            result += segment.text
        }
        return result
    }
}

// MARK: - Empty Column View

struct EmptyColumnView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "music.note")
                    .font(.system(size: 32))
                    .foregroundStyle(.tertiary.opacity(0.3))
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Single Column Song") {
    let song = Song(
        title: "Test Song",
        content: """
        {title: Test Song}
        {artist: Test Artist}
        {key: C}

        {verse}
        [C]Simple [F]test [G]song
        With [C]basic [F]chords

        {chorus}
        [C]This is the [F]chorus
        [G]Singing [C]along
        """
    )

    let parsedSong = ChordProParser.parse(song.content)
    let template = Template.builtInSingleColumn()
    let displaySettings = DisplaySettings.default

    ScrollView {
        MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )
    }
    .frame(height: 600)
}

#Preview("Two Column Song") {
    let song = Song(
        title: "Amazing Grace",
        content: """
        {title: Amazing Grace}
        {artist: John Newton}
        {key: G}

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
    )

    let parsedSong = ChordProParser.parse(song.content)
    let template = Template.builtInTwoColumn()
    let displaySettings = DisplaySettings.default

    ScrollView {
        MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )
    }
    .frame(height: 600)
}

#Preview("Three Column Song") {
    let song = Song(
        title: "Long Song Example",
        content: """
        {title: Long Song Example}
        {key: C}

        {verse}
        [C]First verse [F]line one
        [G]Line two [C]continues

        {verse}
        [C]Second verse [F]line one
        [G]Line two [C]continues

        {chorus}
        [F]Chorus [C]section [G]here
        [F]Multiple [C]lines [G]flow

        {verse}
        [C]Third verse [F]appears
        [G]More content [C]here

        {verse}
        [C]Fourth verse [F]shows
        [G]Distribution [C]works

        {bridge}
        [Am]Bridge [F]section
        [G]Final [C]part
        """
    )

    let parsedSong = ChordProParser.parse(song.content)
    let template = Template.builtInThreeColumn()
    let displaySettings = DisplaySettings.default

    ScrollView {
        MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )
    }
    .frame(height: 600)
}

#Preview("Empty Columns") {
    let song = Song(
        title: "Short Song",
        content: """
        {title: Short Song}
        {key: C}

        {verse}
        [C]Just one [F]short verse
        """
    )

    let parsedSong = ChordProParser.parse(song.content)
    let template = Template.builtInThreeColumn()
    let displaySettings = DisplaySettings.default

    ScrollView {
        MultiColumnSongView(
            song: song,
            template: template,
            parsedSong: parsedSong,
            displaySettings: displaySettings
        )
    }
    .frame(height: 600)
}
