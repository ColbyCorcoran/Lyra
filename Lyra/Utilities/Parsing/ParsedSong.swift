//
//  ParsedSong.swift
//  Lyra
//
//  Structured representation of a parsed song
//

import Foundation

struct ParsedSong: Codable {
    // MARK: - Metadata

    let title: String?
    let subtitle: String?
    let artist: String?
    let album: String?
    let key: String?
    let originalKey: String?
    let tempo: Int?
    let timeSignature: String?
    let capo: Int?
    let year: Int?
    let copyright: String?
    let ccliNumber: String?
    let composer: String?
    let lyricist: String?
    let arranger: String?

    // MARK: - Content

    let sections: [SongSection]
    let rawText: String // Original ChordPro text

    // MARK: - Computed Properties

    /// Get all unique chords used in the song
    var uniqueChords: Set<String> {
        var chords = Set<String>()
        for section in sections {
            chords.formUnion(section.uniqueChords)
        }
        return chords
    }

    /// Get all chords in the order they appear
    var allChords: [String] {
        var chords = [String]()
        for section in sections {
            for line in section.lines {
                chords.append(contentsOf: line.chords)
            }
        }
        return chords
    }

    /// Get sections of a specific type
    func sections(ofType type: SectionType) -> [SongSection] {
        sections.filter { $0.type == type }
    }

    /// Get all verses
    var verses: [SongSection] {
        sections(ofType: .verse)
    }

    /// Get all choruses
    var choruses: [SongSection] {
        sections(ofType: .chorus)
    }

    /// Get all bridges
    var bridges: [SongSection] {
        sections(ofType: .bridge)
    }

    /// Whether the song has any chords
    var hasChords: Bool {
        sections.contains { $0.hasChords }
    }

    /// Total number of lines in the song
    var totalLines: Int {
        sections.reduce(0) { $0 + $1.lines.count }
    }

    /// Get the song text without chords
    var lyricsOnly: String {
        sections.map { section in
            var text = section.label + "\n"
            text += section.text
            return text
        }.joined(separator: "\n\n")
    }
}

// MARK: - Metadata Structure

struct SongMetadata: Codable {
    var title: String?
    var subtitle: String?
    var artist: String?
    var album: String?
    var key: String?
    var originalKey: String?
    var tempo: Int?
    var timeSignature: String?
    var capo: Int?
    var year: Int?
    var copyright: String?
    var ccliNumber: String?
    var composer: String?
    var lyricist: String?
    var arranger: String?

    init() {}

    mutating func set(directive: String, value: String) {
        let normalizedDirective = directive.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalizedDirective {
        case "title", "t":
            title = value
        case "subtitle", "st":
            subtitle = value
        case "artist", "a":
            artist = value
        case "album":
            album = value
        case "key", "k":
            key = value
        case "original_key", "originalkey":
            originalKey = value
        case "tempo":
            tempo = Int(value)
        case "time", "time_signature", "timesignature":
            timeSignature = value
        case "capo":
            capo = Int(value)
        case "year":
            year = Int(value)
        case "copyright", "c":
            copyright = value
        case "ccli", "ccli_number", "cclinumber":
            ccliNumber = value
        case "composer":
            composer = value
        case "lyricist":
            lyricist = value
        case "arranger":
            arranger = value
        default:
            break
        }
    }
}
