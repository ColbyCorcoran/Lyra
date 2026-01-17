//
//  SongLine.swift
//  Lyra
//
//  Represents a line in a song with optional chords
//

import Foundation

struct SongLine: Identifiable, Codable {
    let id: UUID
    let segments: [LineSegment]
    let type: LineType
    let rawText: String? // Original text for reference

    init(segments: [LineSegment], type: LineType, rawText: String? = nil) {
        self.id = UUID()
        self.segments = segments
        self.type = type
        self.rawText = rawText
    }

    /// Convenience initializer for blank lines
    static func blank() -> SongLine {
        SongLine(segments: [], type: .blank, rawText: "")
    }

    /// Convenience initializer for comment lines
    static func comment(_ text: String) -> SongLine {
        let segment = LineSegment(text: text, chord: nil)
        return SongLine(segments: [segment], type: .comment, rawText: text)
    }

    /// Convenience initializer for directive lines
    static func directive(_ text: String) -> SongLine {
        let segment = LineSegment(text: text, chord: nil)
        return SongLine(segments: [segment], type: .directive, rawText: text)
    }

    /// Whether this line has any chords
    var hasChords: Bool {
        segments.contains { $0.hasChord }
    }

    /// Get all chords in this line
    var chords: [String] {
        segments.compactMap { $0.displayChord }
    }

    /// Get the full text of this line (without chords)
    var text: String {
        segments.map { $0.text }.joined()
    }

    /// Whether this is an empty line (blank or whitespace only)
    var isEmpty: Bool {
        type == .blank || text.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

extension SongLine: Equatable {
    static func == (lhs: SongLine, rhs: SongLine) -> Bool {
        lhs.segments == rhs.segments &&
        lhs.type == rhs.type
    }
}
