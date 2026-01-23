//
//  StageMonitorView.swift
//  Lyra
//
//  Main stage monitor view for band/team members
//

import SwiftUI

struct StageMonitorView: View {
    let parsedSong: ParsedSong
    let currentSectionIndex: Int
    let configuration: StageMonitorConfiguration

    var body: some View {
        ZStack {
            // Background
            Color(hex: configuration.backgroundColor)
                .ignoresSafeArea()

            // Content based on layout type
            VStack(spacing: 0) {
                // Metadata header (if enabled)
                if configuration.showSongMetadata {
                    metadataHeader
                        .padding(.horizontal, configuration.horizontalMargin)
                        .padding(.top, configuration.verticalMargin / 2)
                }

                // Main content area
                contentView
                    .padding(.horizontal, configuration.horizontalMargin)
                    .padding(.vertical, configuration.verticalMargin)
            }
        }
        .font(customFont(size: configuration.fontSize))
        .foregroundColor(Color(hex: configuration.textColor))
    }

    @ViewBuilder
    private var contentView: some View {
        switch configuration.layoutType {
        case .chordsOnly:
            ChordsOnlyLayout(
                parsedSong: parsedSong,
                currentSectionIndex: currentSectionIndex,
                configuration: configuration
            )

        case .chordsAndLyrics:
            ChordsAndLyricsLayout(
                parsedSong: parsedSong,
                currentSectionIndex: currentSectionIndex,
                configuration: configuration
            )

        case .currentAndNext:
            CurrentAndNextLayout(
                parsedSong: parsedSong,
                currentSectionIndex: currentSectionIndex,
                configuration: configuration
            )

        case .songStructure:
            SongStructureLayout(
                parsedSong: parsedSong,
                currentSectionIndex: currentSectionIndex,
                configuration: configuration
            )

        case .lyricsOnly:
            LyricsOnlyLayout(
                parsedSong: parsedSong,
                currentSectionIndex: currentSectionIndex,
                configuration: configuration
            )

        case .custom:
            CustomLayout(
                parsedSong: parsedSong,
                currentSectionIndex: currentSectionIndex,
                configuration: configuration
            )
        }
    }

    @ViewBuilder
    private var metadataHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and Artist
            if let title = parsedSong.title {
                Text(title)
                    .font(customFont(size: configuration.fontSize * 1.2, weight: .bold))
                    .foregroundColor(Color(hex: configuration.accentColor))
            }

            if let artist = parsedSong.artist {
                Text(artist)
                    .font(customFont(size: configuration.fontSize * 0.8))
                    .foregroundColor(Color(hex: configuration.textColor).opacity(0.8))
            }

            // Key, Tempo, Capo
            HStack(spacing: 20) {
                if let key = parsedSong.key, configuration.showTranspose {
                    Label(key, systemImage: "music.note")
                        .font(customFont(size: configuration.fontSize * 0.7))
                        .foregroundColor(Color(hex: configuration.chordColor))
                }

                if let tempo = parsedSong.tempo {
                    Label("\(tempo) BPM", systemImage: "metronome")
                        .font(customFont(size: configuration.fontSize * 0.7))
                }

                if let capo = parsedSong.capo, capo > 0, configuration.showCapo {
                    Label("Capo \(capo)", systemImage: "tuningfork")
                        .font(customFont(size: configuration.fontSize * 0.7))
                        .foregroundColor(Color(hex: configuration.accentColor))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func customFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if configuration.fontFamily == "System" {
            return .system(size: size, weight: weight, design: .default)
        } else if configuration.fontFamily == "Monospaced" {
            return .system(size: size, weight: weight, design: .monospaced)
        } else {
            return .custom(configuration.fontFamily, size: size)
        }
    }
}

// MARK: - Chords Only Layout

struct ChordsOnlyLayout: View {
    let parsedSong: ParsedSong
    let currentSectionIndex: Int
    let configuration: StageMonitorConfiguration

    var currentSection: SongSection? {
        guard currentSectionIndex < parsedSong.sections.count else { return nil }
        return parsedSong.sections[currentSectionIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: configuration.lineSpacing) {
                if let section = currentSection {
                    // Section label
                    if configuration.showSectionLabels {
                        Text(section.label.uppercased())
                            .font(customFont(size: configuration.chordFontSize * 0.7, weight: .bold))
                            .foregroundColor(Color(hex: configuration.accentColor))
                            .padding(.bottom, 8)
                    }

                    // Chords
                    ForEach(section.lines) { line in
                        if line.hasChords {
                            HStack(spacing: 16) {
                                ForEach(line.segments.filter { $0.hasChord }) { segment in
                                    if let chord = segment.displayChord {
                                        Text(chord)
                                            .font(customFont(size: configuration.chordFontSize, weight: .bold))
                                            .foregroundColor(Color(hex: configuration.chordColor))
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Next section preview
                    if configuration.showNextSection, let nextSection = getNextSection() {
                        Divider()
                            .background(Color(hex: configuration.textColor).opacity(0.3))
                            .padding(.vertical, 20)

                        Text("NEXT: \(nextSection.label)")
                            .font(customFont(size: configuration.fontSize * 0.6, weight: .semibold))
                            .foregroundColor(Color(hex: configuration.accentColor).opacity(0.7))

                        if let firstLine = nextSection.lines.first(where: { $0.hasChords }) {
                            HStack(spacing: 12) {
                                ForEach(firstLine.segments.filter { $0.hasChord }.prefix(3)) { segment in
                                    if let chord = segment.displayChord {
                                        Text(chord)
                                            .font(customFont(size: configuration.chordFontSize * 0.6))
                                            .foregroundColor(Color(hex: configuration.chordColor).opacity(0.6))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func getNextSection() -> SongSection? {
        let nextIndex = currentSectionIndex + 1
        guard nextIndex < parsedSong.sections.count else { return nil }
        return parsedSong.sections[nextIndex]
    }

    private func customFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if configuration.fontFamily == "System" {
            return .system(size: size, weight: weight, design: .default)
        } else if configuration.fontFamily == "Monospaced" {
            return .system(size: size, weight: weight, design: .monospaced)
        } else {
            return .custom(configuration.fontFamily, size: size)
        }
    }
}

// MARK: - Chords and Lyrics Layout

struct ChordsAndLyricsLayout: View {
    let parsedSong: ParsedSong
    let currentSectionIndex: Int
    let configuration: StageMonitorConfiguration

    var currentSection: SongSection? {
        guard currentSectionIndex < parsedSong.sections.count else { return nil }
        return parsedSong.sections[currentSectionIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: configuration.lineSpacing) {
                if let section = currentSection {
                    // Section label
                    if configuration.showSectionLabels {
                        Text(section.label.uppercased())
                            .font(customFont(size: configuration.fontSize, weight: .bold))
                            .foregroundColor(Color(hex: configuration.accentColor))
                            .padding(.bottom, 12)
                    }

                    // Lines with chords and lyrics
                    ForEach(section.lines) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            // Chords line
                            if line.hasChords {
                                HStack(spacing: 0) {
                                    ForEach(line.segments) { segment in
                                        VStack(alignment: .leading, spacing: 2) {
                                            // Chord
                                            if let chord = segment.displayChord {
                                                Text(chord)
                                                    .font(customFont(size: configuration.chordFontSize, weight: .bold))
                                                    .foregroundColor(Color(hex: configuration.chordColor))
                                            } else {
                                                Text(" ")
                                                    .font(customFont(size: configuration.chordFontSize))
                                            }

                                            // Lyric
                                            Text(segment.text)
                                                .font(customFont(size: configuration.lyricsFontSize))
                                                .foregroundColor(Color(hex: configuration.textColor))
                                        }
                                    }
                                }
                            } else {
                                // Lyrics only (no chords on this line)
                                Text(line.text)
                                    .font(customFont(size: configuration.lyricsFontSize))
                                    .foregroundColor(Color(hex: configuration.textColor))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func customFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if configuration.fontFamily == "System" {
            return .system(size: size, weight: weight, design: .default)
        } else if configuration.fontFamily == "Monospaced" {
            return .system(size: size, weight: weight, design: .monospaced)
        } else {
            return .custom(configuration.fontFamily, size: size)
        }
    }
}

// MARK: - Current and Next Layout

struct CurrentAndNextLayout: View {
    let parsedSong: ParsedSong
    let currentSectionIndex: Int
    let configuration: StageMonitorConfiguration

    var currentSection: SongSection? {
        guard currentSectionIndex < parsedSong.sections.count else { return nil }
        return parsedSong.sections[currentSectionIndex]
    }

    var nextSection: SongSection? {
        let nextIndex = currentSectionIndex + 1
        guard nextIndex < parsedSong.sections.count else { return nil }
        return parsedSong.sections[nextIndex]
    }

    var body: some View {
        HStack(spacing: 40) {
            // Current section (70% width)
            VStack(alignment: .leading, spacing: configuration.lineSpacing) {
                Text("CURRENT")
                    .font(customFont(size: configuration.fontSize * 0.6, weight: .bold))
                    .foregroundColor(Color(hex: configuration.accentColor))

                if let section = currentSection {
                    sectionContent(section, fontSize: configuration.fontSize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(Color(hex: configuration.textColor).opacity(0.3))

            // Next section (30% width, smaller)
            VStack(alignment: .leading, spacing: configuration.lineSpacing * 0.7) {
                Text("NEXT")
                    .font(customFont(size: configuration.fontSize * 0.5, weight: .bold))
                    .foregroundColor(Color(hex: configuration.accentColor).opacity(0.7))

                if let section = nextSection {
                    sectionContent(section, fontSize: configuration.fontSize * 0.6)
                        .opacity(0.7)
                } else {
                    Text("(End of song)")
                        .font(customFont(size: configuration.fontSize * 0.5))
                        .foregroundColor(Color(hex: configuration.textColor).opacity(0.5))
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }

    @ViewBuilder
    private func sectionContent(_ section: SongSection, fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: configuration.lineSpacing * 0.8) {
            if configuration.showSectionLabels {
                Text(section.label.uppercased())
                    .font(customFont(size: fontSize * 0.8, weight: .bold))
                    .foregroundColor(Color(hex: configuration.accentColor))
            }

            ForEach(section.lines) { line in
                if line.hasChords {
                    HStack(spacing: 12) {
                        ForEach(line.segments.filter { $0.hasChord }) { segment in
                            if let chord = segment.displayChord {
                                Text(chord)
                                    .font(customFont(size: fontSize * 0.9, weight: .bold))
                                    .foregroundColor(Color(hex: configuration.chordColor))
                            }
                        }
                    }
                }

                if !line.text.isEmpty {
                    Text(line.text)
                        .font(customFont(size: fontSize * 0.7))
                        .foregroundColor(Color(hex: configuration.textColor))
                }
            }
        }
    }

    private func customFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if configuration.fontFamily == "System" {
            return .system(size: size, weight: weight, design: .default)
        } else if configuration.fontFamily == "Monospaced" {
            return .system(size: size, weight: weight, design: .monospaced)
        } else {
            return .custom(configuration.fontFamily, size: size)
        }
    }
}

// MARK: - Song Structure Layout

struct SongStructureLayout: View {
    let parsedSong: ParsedSong
    let currentSectionIndex: Int
    let configuration: StageMonitorConfiguration

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: configuration.lineSpacing) {
                ForEach(Array(parsedSong.sections.enumerated()), id: \.element.id) { index, section in
                    let isCurrent = index == currentSectionIndex

                    HStack(spacing: 16) {
                        // Current indicator
                        Circle()
                            .fill(isCurrent ? Color(hex: configuration.accentColor) : Color.clear)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: configuration.textColor).opacity(0.3), lineWidth: 2)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            // Section label
                            Text(section.label)
                                .font(customFont(
                                    size: isCurrent ? configuration.fontSize * 1.2 : configuration.fontSize * 0.9,
                                    weight: isCurrent ? .bold : .regular
                                ))
                                .foregroundColor(
                                    isCurrent ? Color(hex: configuration.accentColor) : Color(hex: configuration.textColor)
                                )

                            // Show chords for current section
                            if isCurrent && section.hasChords {
                                HStack(spacing: 12) {
                                    ForEach(Array(section.uniqueChords.sorted()), id: \.self) { chord in
                                        Text(chord)
                                            .font(customFont(size: configuration.chordFontSize * 0.8, weight: .bold))
                                            .foregroundColor(Color(hex: configuration.chordColor))
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        isCurrent ?
                        Color(hex: configuration.accentColor).opacity(0.1) :
                        Color.clear
                    )
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func customFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if configuration.fontFamily == "System" {
            return .system(size: size, weight: weight, design: .default)
        } else if configuration.fontFamily == "Monospaced" {
            return .system(size: size, weight: weight, design: .monospaced)
        } else {
            return .custom(configuration.fontFamily, size: size)
        }
    }
}

// MARK: - Lyrics Only Layout

struct LyricsOnlyLayout: View {
    let parsedSong: ParsedSong
    let currentSectionIndex: Int
    let configuration: StageMonitorConfiguration

    var currentSection: SongSection? {
        guard currentSectionIndex < parsedSong.sections.count else { return nil }
        return parsedSong.sections[currentSectionIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: configuration.compactMode ? .leading : .center, spacing: configuration.lineSpacing) {
                if let section = currentSection {
                    // Section label
                    if configuration.showSectionLabels {
                        Text(section.label.uppercased())
                            .font(customFont(size: configuration.fontSize * 0.8, weight: .bold))
                            .foregroundColor(Color(hex: configuration.accentColor))
                            .padding(.bottom, 12)
                    }

                    // Lyrics
                    ForEach(section.lines) { line in
                        if !line.isEmpty {
                            Text(line.text)
                                .font(customFont(size: configuration.lyricsFontSize))
                                .foregroundColor(Color(hex: configuration.textColor))
                                .multilineTextAlignment(configuration.compactMode ? .leading : .center)
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func customFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if configuration.fontFamily == "System" {
            return .system(size: size, weight: weight, design: .default)
        } else if configuration.fontFamily == "Monospaced" {
            return .system(size: size, weight: weight, design: .monospaced)
        } else {
            return .custom(configuration.fontFamily, size: size)
        }
    }
}

// MARK: - Custom Layout

struct CustomLayout: View {
    let parsedSong: ParsedSong
    let currentSectionIndex: Int
    let configuration: StageMonitorConfiguration

    var body: some View {
        // Placeholder for user-customizable layout
        // Can be extended to support drag-and-drop layout builder
        ChordsAndLyricsLayout(
            parsedSong: parsedSong,
            currentSectionIndex: currentSectionIndex,
            configuration: configuration
        )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    let sampleParsedSong = ParsedSong(
        title: "Amazing Grace",
        subtitle: nil,
        artist: "John Newton",
        album: nil,
        key: "G",
        originalKey: "G",
        tempo: 80,
        timeSignature: "3/4",
        capo: 0,
        year: nil,
        copyright: nil,
        ccliNumber: nil,
        composer: nil,
        lyricist: nil,
        arranger: nil,
        sections: [
            SongSection(
                type: .verse,
                label: "Verse 1",
                lines: [
                    SongLine(
                        segments: [
                            LineSegment(text: "Amazing ", chord: "G", position: 0),
                            LineSegment(text: "grace how ", chord: "C", position: 8),
                            LineSegment(text: "sweet the ", chord: "G", position: 17),
                            LineSegment(text: "sound", chord: "D", position: 27)
                        ],
                        type: .lyrics
                    )
                ],
                index: 1
            )
        ],
        rawText: ""
    )

    let config = StageMonitorConfiguration.forRole(.lead)

    StageMonitorView(
        parsedSong: sampleParsedSong,
        currentSectionIndex: 0,
        configuration: config
    )
}
