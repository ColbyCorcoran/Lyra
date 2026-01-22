//
//  ChordProParser.swift
//  Lyra
//
//  Parser for ChordPro formatted songs
//

import Foundation

class ChordProParser {

    // MARK: - Public Methods

    /// Parse ChordPro formatted text into a structured ParsedSong
    static func parse(_ text: String) -> ParsedSong {
        let lines = text.components(separatedBy: .newlines)
        var metadata = SongMetadata()
        var sections: [SongSection] = []
        var currentSectionType: SectionType = .verse
        var currentSectionLines: [SongLine] = []
        var sectionCounters: [SectionType: Int] = [:]
        var previousLineWasChordsOnly = false
        var chordsOnlyLine: SongLine?

        for (_, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines at the start
            if sections.isEmpty && currentSectionLines.isEmpty && trimmedLine.isEmpty {
                continue
            }

            // Handle ChordPro directives (inside curly braces)
            if let directive = parseDirective(trimmedLine) {
                // Handle comment directive
                if directive.name.lowercased() == "comment" || directive.name.lowercased() == "c" {
                    let commentLine = SongLine.comment(directive.value)
                    currentSectionLines.append(commentLine)
                    continue
                }

                metadata.set(directive: directive.name, value: directive.value)

                // Handle section markers
                if let sectionChange = handleSectionDirective(directive.name) {
                    // Save current section if it has content
                    if !currentSectionLines.isEmpty {
                        let sectionIndex = (sectionCounters[currentSectionType] ?? 0) + 1
                        sectionCounters[currentSectionType] = sectionIndex
                        let section = SongSection(
                            type: currentSectionType,
                            lines: currentSectionLines,
                            index: sectionIndex
                        )
                        sections.append(section)
                        currentSectionLines = []
                    }

                    currentSectionType = sectionChange
                }
                previousLineWasChordsOnly = false
                chordsOnlyLine = nil
                continue
            }

            // Handle comments
            if trimmedLine.hasPrefix("#") {
                let commentText = String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces)
                let commentLine = SongLine.comment(commentText)
                currentSectionLines.append(commentLine)
                previousLineWasChordsOnly = false
                chordsOnlyLine = nil
                continue
            }

            // Handle blank lines
            if trimmedLine.isEmpty {
                currentSectionLines.append(SongLine.blank())
                previousLineWasChordsOnly = false
                chordsOnlyLine = nil
                continue
            }

            // Parse line with chords
            let parsedLine = parseLine(trimmedLine)

            // Check if this is a chords-only line
            if parsedLine.type == .chordsOnly {
                // Save for potential merging with next line
                chordsOnlyLine = parsedLine
                previousLineWasChordsOnly = true
            } else if previousLineWasChordsOnly && chordsOnlyLine != nil {
                // Try to merge chords from previous line with this lyrics line
                let mergedLine = mergeChordLine(chordsOnlyLine!, with: parsedLine)
                currentSectionLines.append(mergedLine)
                previousLineWasChordsOnly = false
                chordsOnlyLine = nil
            } else {
                // Regular lyrics line or couldn't merge
                if let pendingChords = chordsOnlyLine {
                    // Add the chords-only line as-is
                    currentSectionLines.append(pendingChords)
                    chordsOnlyLine = nil
                }
                currentSectionLines.append(parsedLine)
                previousLineWasChordsOnly = false
            }
        }

        // Handle any remaining chords-only line
        if let pendingChords = chordsOnlyLine {
            currentSectionLines.append(pendingChords)
        }

        // Add final section
        if !currentSectionLines.isEmpty {
            let sectionIndex = (sectionCounters[currentSectionType] ?? 0) + 1
            let section = SongSection(
                type: currentSectionType,
                lines: currentSectionLines,
                index: sectionIndex
            )
            sections.append(section)
        }

        return ParsedSong(
            title: metadata.title,
            subtitle: metadata.subtitle,
            artist: metadata.artist,
            album: metadata.album,
            key: metadata.key,
            originalKey: metadata.originalKey,
            tempo: metadata.tempo,
            timeSignature: metadata.timeSignature,
            capo: metadata.capo,
            year: metadata.year,
            copyright: metadata.copyright,
            ccliNumber: metadata.ccliNumber,
            composer: metadata.composer,
            lyricist: metadata.lyricist,
            arranger: metadata.arranger,
            sections: sections,
            rawText: text
        )
    }

    // MARK: - Private Parsing Methods

    /// Parse a ChordPro directive from a line
    private static func parseDirective(_ line: String) -> (name: String, value: String)? {
        guard line.hasPrefix("{") && line.hasSuffix("}") else {
            return nil
        }

        let content = String(line.dropFirst().dropLast())

        // Handle directives with values: {title: Amazing Grace}
        if let colonIndex = content.firstIndex(of: ":") {
            let name = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            return (name, value)
        }

        // Handle directives without values: {start_of_chorus}
        return (content.trimmingCharacters(in: .whitespaces), "")
    }

    /// Handle section-related directives
    private static func handleSectionDirective(_ directive: String) -> SectionType? {
        let normalized = directive.lowercased().replacingOccurrences(of: "_", with: "")

        if normalized.hasPrefix("startof") {
            let sectionName = String(normalized.dropFirst("startof".count))
            return SectionType.from(chordProDirective: sectionName)
        }

        if normalized.hasPrefix("soc") { // start_of_chorus shorthand
            return .chorus
        }

        if normalized.hasPrefix("sov") { // start_of_verse shorthand
            return .verse
        }

        if normalized.hasPrefix("sob") { // start_of_bridge shorthand
            return .bridge
        }

        // Check if it's a section type name directly
        let sectionType = SectionType.from(chordProDirective: directive)
        if sectionType != .unknown {
            return sectionType
        }

        return nil
    }

    /// Parse a line with chords into segments
    private static func parseLine(_ line: String) -> SongLine {
        var segments: [LineSegment] = []
        var position = 0
        var currentText = ""
        var pendingChord: String?

        var i = line.startIndex
        while i < line.endIndex {
            let char = line[i]

            if char == "[" {
                // Found start of chord
                if !currentText.isEmpty || pendingChord != nil {
                    // Save current text with any pending chord
                    let segment = LineSegment(
                        text: currentText,
                        chord: pendingChord,
                        position: position
                    )
                    segments.append(segment)
                    position += currentText.count
                    currentText = ""
                    pendingChord = nil
                }

                // Extract chord
                var chordText = ""
                i = line.index(after: i)
                while i < line.endIndex && line[i] != "]" {
                    chordText.append(line[i])
                    i = line.index(after: i)
                }

                if i < line.endIndex && line[i] == "]" {
                    pendingChord = chordText
                    i = line.index(after: i)
                }
            } else {
                currentText.append(char)
                i = line.index(after: i)
            }
        }

        // Add final segment
        if !currentText.isEmpty || pendingChord != nil {
            let segment = LineSegment(
                text: currentText,
                chord: pendingChord,
                position: position
            )
            segments.append(segment)
        }

        // Determine line type
        let lineType: LineType
        if segments.isEmpty {
            lineType = .blank
        } else if segments.allSatisfy({ $0.text.trimmingCharacters(in: .whitespaces).isEmpty && $0.hasChord }) {
            lineType = .chordsOnly
        } else {
            lineType = .lyrics
        }

        return SongLine(segments: segments, type: lineType, rawText: line)
    }

    /// Merge a chords-only line with a lyrics line
    private static func mergeChordLine(_ chordsLine: SongLine, with lyricsLine: SongLine) -> SongLine {
        // Extract chords with their positions from the chords-only line
        var chordPositions: [(position: Int, chord: String)] = []

        for segment in chordsLine.segments {
            if let chord = segment.displayChord {
                chordPositions.append((position: segment.position, chord: chord))
            }
        }

        // If no chords found, just return the lyrics line
        if chordPositions.isEmpty {
            return lyricsLine
        }

        // Get the full lyrics text
        let lyricsText = lyricsLine.text

        // Create new segments by inserting chords at appropriate positions
        var newSegments: [LineSegment] = []
        var currentPosition = 0
        var chordIndex = 0

        // Sort chord positions
        chordPositions.sort { $0.position < $1.position }

        while currentPosition < lyricsText.count || chordIndex < chordPositions.count {
            if chordIndex < chordPositions.count {
                let chordPos = chordPositions[chordIndex]

                if chordPos.position <= currentPosition {
                    // Chord should be added at current or earlier position
                    // Find the segment at this position
                    if currentPosition < lyricsText.count {
                        let startIndex = lyricsText.index(lyricsText.startIndex, offsetBy: currentPosition)
                        var nextChordPos = lyricsText.count

                        if chordIndex + 1 < chordPositions.count {
                            nextChordPos = min(nextChordPos, chordPositions[chordIndex + 1].position)
                        }

                        let endIndex = lyricsText.index(lyricsText.startIndex, offsetBy: min(nextChordPos, lyricsText.count))
                        let text = String(lyricsText[startIndex..<endIndex])

                        let segment = LineSegment(
                            text: text,
                            chord: chordPos.chord,
                            position: currentPosition
                        )
                        newSegments.append(segment)
                        currentPosition += text.count
                    } else {
                        // Chord at end of line
                        let segment = LineSegment(
                            text: "",
                            chord: chordPos.chord,
                            position: currentPosition
                        )
                        newSegments.append(segment)
                    }
                    chordIndex += 1
                } else {
                    // Add text before next chord
                    let startIndex = lyricsText.index(lyricsText.startIndex, offsetBy: currentPosition)
                    let endIndex = lyricsText.index(lyricsText.startIndex, offsetBy: min(chordPos.position, lyricsText.count))
                    let text = String(lyricsText[startIndex..<endIndex])

                    let segment = LineSegment(
                        text: text,
                        chord: nil,
                        position: currentPosition
                    )
                    newSegments.append(segment)
                    currentPosition += text.count
                }
            } else {
                // No more chords, add remaining text
                let startIndex = lyricsText.index(lyricsText.startIndex, offsetBy: currentPosition)
                let text = String(lyricsText[startIndex...])

                let segment = LineSegment(
                    text: text,
                    chord: nil,
                    position: currentPosition
                )
                newSegments.append(segment)
                break
            }
        }

        return SongLine(segments: newSegments.isEmpty ? lyricsLine.segments : newSegments, type: .lyrics, rawText: lyricsLine.rawText)
    }
}
