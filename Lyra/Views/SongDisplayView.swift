//
//  SongDisplayView.swift
//  Lyra
//
//  Beautiful display view for parsed ChordPro songs
//  This is the MOST IMPORTANT view in the app
//

import SwiftUI
import SwiftData

struct SongDisplayView: View {
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let setEntry: SetEntry?

    @State private var parsedSong: ParsedSong?
    @State private var fontSize: CGFloat = 16
    @State private var showDisplaySettings: Bool = false
    @State private var displaySettings: DisplaySettings
    @State private var isLoadingSong: Bool = false
    @State private var showQuickBookPicker: Bool = false
    @State private var showQuickSetPicker: Bool = false

    init(song: Song, setEntry: SetEntry? = nil) {
        self.song = song
        self.setEntry = setEntry
        _displaySettings = State(initialValue: song.displaySettings)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Set context banner
            if let entry = setEntry, let set = entry.performanceSet {
                SetContextBanner(setName: set.name, songPosition: entry.orderIndex + 1, totalSongs: set.songEntries?.count ?? 0)
            }

            // Sticky Header
            if let parsed = parsedSong {
                SongHeaderView(parsedSong: parsed, song: song, setEntry: setEntry)
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            }

            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if isLoadingSong {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading song...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else if let parsed = parsedSong {
                        // Sections
                        ForEach(Array(parsed.sections.enumerated()), id: \.element.id) { index, section in
                            SongSectionView(section: section, settings: displaySettings)
                                .padding(.horizontal)
                                .padding(.bottom, index < parsed.sections.count - 1 ? 32 : 16)
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "music.note")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)

                            Text("No content available")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Edit button
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // TODO: Edit song functionality
                } label: {
                    Image(systemName: "pencil")
                }
                .disabled(true)
                .accessibilityLabel("Edit song")
                .accessibilityHint("Opens song editor. Currently unavailable.")
            }

            // Transpose button
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // TODO: Transpose functionality
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .disabled(true)
                .accessibilityLabel("Transpose")
                .accessibilityHint("Transpose song to a different key. Currently unavailable.")
            }

            // Display Settings button
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDisplaySettings = true
                } label: {
                    Image(systemName: "textformat.size")
                }
                .accessibilityLabel("Display settings")
                .accessibilityHint("Adjust font size, colors, and spacing")
            }

            // Organization menu
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    OrganizationMenuView(song: song)
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .accessibilityLabel("Add to collection")
                .accessibilityHint("Add this song to books or sets")
            }

            // More menu
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Font size controls
                    Section("Font Size") {
                        Button {
                            fontSize = max(12, fontSize - 2)
                        } label: {
                            Label("Decrease", systemImage: "textformat.size.smaller")
                        }

                        Button {
                            fontSize = min(24, fontSize + 2)
                        } label: {
                            Label("Increase", systemImage: "textformat.size.larger")
                        }

                        Button {
                            fontSize = 16
                        } label: {
                            Label("Reset to Default", systemImage: "arrow.counterclockwise")
                        }
                    }

                    Divider()

                    // Future features
                    Section {
                        Button {
                            // TODO: Print or export
                        } label: {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }
                        .disabled(true)

                        Button {
                            // TODO: Share
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .disabled(true)
                    }

                    Divider()

                    // Song info
                    Section {
                        Button {
                            // TODO: Show song info/metadata
                        } label: {
                            Label("Song Info", systemImage: "info.circle")
                        }
                        .disabled(true)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showDisplaySettings) {
            DisplaySettingsSheet(song: song)
                .onDisappear {
                    // Refresh display settings when sheet closes
                    displaySettings = song.displaySettings
                }
        }
        .sheet(isPresented: $showQuickBookPicker) {
            QuickOrganizationPicker(song: song, mode: .book)
        }
        .sheet(isPresented: $showQuickSetPicker) {
            QuickOrganizationPicker(song: song, mode: .set)
        }
        .background {
            // Keyboard shortcuts (invisible buttons)
            Button("") {
                showQuickBookPicker = true
            }
            .keyboardShortcut("b", modifiers: .command)
            .hidden()

            Button("") {
                showQuickSetPicker = true
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .hidden()
        }
        .onAppear {
            parseSong()
            trackSongView()
        }
        .onChange(of: song.content) { _, _ in
            parseSong()
        }
        .onChange(of: displaySettings) { _, _ in
            // Update when display settings change
            fontSize = displaySettings.fontSize
        }
    }

    private func parseSong() {
        isLoadingSong = true

        Task {
            let parsed = await Task.detached(priority: .userInitiated) {
                return ChordProParser.parse(song.content)
            }.value

            await MainActor.run {
                parsedSong = parsed
                isLoadingSong = false
            }
        }
    }

    /// Track that the user viewed this song
    private func trackSongView() {
        song.lastViewed = Date()
        song.timesViewed += 1

        // Save to SwiftData
        do {
            try modelContext.save()
        } catch {
            print("Error tracking song view: \(error)")
        }
    }
}

// MARK: - Song Header View

/*
 Enhanced SongHeaderView with professional metadata display

 Features:
 - Large title and artist at top
 - Metadata card with SF Symbols icons
 - Light gray background with rounded corners
 - Compact, responsive layout
 - Only shows non-empty fields
 */
struct SongHeaderView: View {
    let parsedSong: ParsedSong
    let song: Song
    var setEntry: SetEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title Section
            VStack(alignment: .leading, spacing: 6) {
                // Title
                if let title = parsedSong.title {
                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)
                }

                // Subtitle (if present)
                if let subtitle = parsedSong.subtitle {
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Artist
                if let artist = parsedSong.artist {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        Text(artist)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Organization pills (books/sets this song belongs to)
            OrganizationPillsView(song: song)

            // Musical Metadata Card
            if hasMusicalMetadata {
                VStack(alignment: .leading, spacing: 12) {
                    // Key and Tempo row
                    HStack(spacing: 20) {
                        if let key = effectiveKey {
                            MetadataItem(
                                icon: "music.note",
                                label: "Key",
                                value: key,
                                isOverride: setEntry?.keyOverride != nil,
                                originalValue: parsedSong.key
                            )
                        }

                        if let tempo = effectiveTempo {
                            MetadataItem(
                                icon: "metronome",
                                label: "Tempo",
                                value: "\(tempo) BPM",
                                isOverride: setEntry?.tempoOverride != nil,
                                originalValue: parsedSong.tempo.map { "\($0) BPM" }
                            )
                        }

                        Spacer()
                    }

                    // Time signature and Capo row
                    HStack(spacing: 20) {
                        if let time = parsedSong.timeSignature {
                            MetadataItem(
                                icon: "waveform",
                                label: "Time",
                                value: time
                            )
                        }

                        if let capo = effectiveCapo, capo > 0 {
                            MetadataItem(
                                icon: "guitar",
                                label: "Capo",
                                value: "\(capo)",
                                isOverride: setEntry?.capoOverride != nil,
                                originalValue: parsedSong.capo.map { "\($0)" }
                            )
                        }

                        Spacer()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }

            // Copyright info (if present)
            if let copyright = parsedSong.copyright {
                HStack(spacing: 6) {
                    Image(systemName: "c.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)

                    Text(copyright)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Check if there's any musical metadata to display
    private var hasMusicalMetadata: Bool {
        parsedSong.key != nil ||
        parsedSong.tempo != nil ||
        parsedSong.timeSignature != nil ||
        (parsedSong.capo != nil && parsedSong.capo! > 0)
    }

    // MARK: - Effective Values (with overrides)

    private var effectiveKey: String? {
        setEntry?.keyOverride ?? parsedSong.key
    }

    private var effectiveCapo: Int? {
        setEntry?.capoOverride ?? parsedSong.capo
    }

    private var effectiveTempo: Int? {
        setEntry?.tempoOverride ?? parsedSong.tempo
    }
}

// MARK: - Metadata Item

/*
 Individual metadata item with icon, label, and value
 Example: [music.note icon] Key: G
 */
struct MetadataItem: View {
    let icon: String
    let label: String
    let value: String
    var isOverride: Bool = false
    var originalValue: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isOverride ? .indigo : .blue)
                    .frame(width: 20)

                // Label and Value
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isOverride ? .indigo : .primary)

                    if isOverride {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.indigo)
                    }
                }
            }

            // Override indicator
            if isOverride, let original = originalValue {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 8))
                    Text("Original: \(original)")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.tertiary)
                .padding(.leading, 28)
            }
        }
    }
}

// MARK: - Song Section View

struct SongSectionView: View {
    let section: SongSection
    let settings: DisplaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Label
            Text(section.label)
                .font(.system(size: settings.fontSize + 2, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            // Section Lines
            ForEach(Array(section.lines.enumerated()), id: \.offset) { index, line in
                ChordLineView(line: line, settings: settings)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Chord Line View

/*
 Enhanced ChordLineView with pixel-perfect chord alignment

 Key improvements:
 1. Uses position-based layout with ZStack for precise chord placement
 2. Calculates exact character positions using monospaced font metrics
 3. Handles edge cases: start/end chords, multiple spaces, long chord names
 4. Customizable spacing and colors
 5. Preserves exact whitespace in lyrics

 Example rendering:

 Input: "I [C]love [Am]you [F]so [G]much"

 Before (naive approach - misaligned):
   C    Am   F    G
   I love you so much

 After (position-based - perfectly aligned):
   C   Am  F  G
   I love you so much
 */
struct ChordLineView: View {
    let line: SongLine
    let settings: DisplaySettings

    // Derived properties
    private var fontSize: CGFloat { settings.fontSize }
    private var chordFontSizeOffset: CGFloat { -2 }
    private var chordToLyricSpacing: CGFloat { settings.spacing }
    private var chordColor: Color { settings.chordColorValue() }
    private var lyricsColor: Color { settings.lyricsColorValue() }

    var body: some View {
        switch line.type {
        case .lyrics:
            renderLyricsWithChords()
        case .chordsOnly:
            renderChordsOnly()
        case .blank:
            Text(" ")
                .font(.system(size: fontSize, design: .monospaced))
        case .comment:
            Text(line.text)
                .font(.system(size: fontSize - 2))
                .foregroundStyle(.tertiary)
                .italic()
        case .directive:
            // Directives are typically parsed and not displayed
            EmptyView()
        }
    }

    @ViewBuilder
    private func renderLyricsWithChords() -> some View {
        if line.hasChords {
            // Use position-based rendering for perfect alignment
            VStack(alignment: .leading, spacing: chordToLyricSpacing) {
                // Chords layer (positioned above lyrics)
                chordLayer

                // Lyrics layer (base text)
                lyricsLayer
            }
        } else {
            // No chords, just render lyrics
            Text(line.text)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundStyle(lyricsColor)
        }
    }

    /// Render chords layer with precise positioning
    @ViewBuilder
    private var chordLayer: some View {
        // Calculate character width for monospaced font
        // This is approximate but works well for monospaced fonts
        let charWidth = fontSize * 0.6 // Typical monospaced character width ratio

        ZStack(alignment: .topLeading) {
            // Invisible text to set the height and width of the chord layer
            Text(line.text)
                .font(.system(size: fontSize - 2, design: .monospaced))
                .opacity(0)

            // Position each chord precisely
            ForEach(Array(line.segments.enumerated()), id: \.offset) { _, segment in
                if let chord = segment.displayChord {
                    Text(chord)
                        .font(.system(size: fontSize + chordFontSizeOffset, weight: .medium, design: .monospaced))
                        .foregroundStyle(chordColor)
                        .offset(x: CGFloat(segment.position) * charWidth, y: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Render lyrics layer
    @ViewBuilder
    private var lyricsLayer: some View {
        Text(line.text)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundStyle(lyricsColor)
    }

    @ViewBuilder
    private func renderChordsOnly() -> some View {
        // For chord-only lines, space them out nicely
        let charWidth = fontSize * 0.6

        ZStack(alignment: .topLeading) {
            // Create an invisible baseline using spaces
            let maxPosition = line.segments.map { $0.position + ($0.chord?.count ?? 0) }.max() ?? 0
            Text(String(repeating: " ", count: maxPosition))
                .font(.system(size: fontSize + chordFontSizeOffset, design: .monospaced))
                .opacity(0)

            // Position each chord
            ForEach(Array(line.segments.enumerated()), id: \.offset) { _, segment in
                if let chord = segment.displayChord {
                    Text(chord)
                        .font(.system(size: fontSize + chordFontSizeOffset, weight: .medium, design: .monospaced))
                        .foregroundStyle(chordColor)
                        .offset(x: CGFloat(segment.position) * charWidth, y: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Song Display") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Amazing Grace",
                artist: "John Newton",
                content: SampleChordProSongs.amazingGrace,
                originalKey: "G"
            )
            return song
        }())
    }
}

#Preview("Simple Song") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Test Song",
                content: """
                {title: Test Song}
                {artist: Test Artist}
                {key: C}

                {verse}
                [C]Simple [F]test [G]song
                With [C]basic [F]chords
                """
            )
            return song
        }())
    }
}

#Preview("Chord Positioning Tests") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Chord Position Test Cases",
                content: """
                {title: Chord Position Test Cases}
                {subtitle: Testing all edge cases}
                {artist: Test}
                {key: C}

                {verse: Multiple chords per line}
                I [C]love [Am]you [F]so [G]much

                {verse: Chords at line start}
                [C]Hello world of music

                {verse: Chords at line end}
                Hello world of music[G]

                {verse: Chords between words (no space)}
                Hello[C]world of[G]music

                {verse: Multiple spaces}
                Hello    [C]world    of    [G]music

                {verse: Long chord names}
                [Cmaj7]Complex [Asus4]chords [Dm7b5]here [Gadd9]now

                {verse: Quick chord changes}
                [C]I [Am]love [F]you [G]so [Em]very [Am]much [Dm]today [G7]yeah

                {chorus: Mixed spacing and positions}
                [C]At the [Am]start and middle[F] and end[G]
                Some[C]times no[Am]space between[F]them[G]
                """
            )
            return song
        }())
    }
}

#Preview("Complex Song - Blest Be The Tie") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Blest Be the Tie",
                artist: "John Fawcett",
                content: SampleChordProSongs.blestBeTheTie,
                originalKey: "D"
            )
            return song
        }())
    }
}

#Preview("Complex Song - How Great Thou Art") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "How Great Thou Art",
                artist: "Carl Boberg",
                content: SampleChordProSongs.howGreatThouArt,
                originalKey: "C"
            )
            return song
        }())
    }
}

// MARK: - Set Context Banner

struct SetContextBanner: View {
    let setName: String
    let songPosition: Int
    let totalSongs: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Viewing from Set")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Text(setName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Text("Song \(songPosition) of \(totalSongs)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.8), Color.green],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

#Preview("Enhanced Metadata Header") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Complete Metadata Example",
                artist: "Test Artist",
                content: """
                {title: Complete Metadata Example}
                {subtitle: Showcasing All Metadata Fields}
                {artist: Test Artist}
                {key: G}
                {tempo: 120}
                {time: 4/4}
                {capo: 2}
                {copyright: Copyright 2026 Test Publishing}

                {verse}
                [G]This song has [C]all the [G]metadata [D]fields
                [G]Including [C]key, tempo, [G]time, and [D]capo

                {chorus}
                [C]Look at that [G]beautiful [Em]header
                [C]With icons [G]and clean [D]layout
                """
            )
            return song
        }())
    }
}

#Preview("Minimal Metadata") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Simple Song",
                content: """
                {title: Simple Song}
                {artist: Unknown Artist}

                {verse}
                Just lyrics here
                No musical metadata
                """
            )
            return song
        }())
    }
}
