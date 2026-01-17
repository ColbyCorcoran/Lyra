//
//  SectionType.swift
//  Lyra
//
//  Section types for parsed song structure
//

import Foundation

enum SectionType: String, Codable, CaseIterable {
    case verse = "Verse"
    case chorus = "Chorus"
    case bridge = "Bridge"
    case prechorus = "Pre-Chorus"
    case instrumental = "Instrumental"
    case intro = "Intro"
    case outro = "Outro"
    case interlude = "Interlude"
    case tag = "Tag"
    case vamp = "Vamp"
    case unknown = "Unknown"

    var displayName: String {
        rawValue
    }

    /// Initialize from ChordPro directive names
    static func from(chordProDirective: String) -> SectionType {
        let directive = chordProDirective.lowercased()

        switch directive {
        case "verse", "v":
            return .verse
        case "chorus", "c", "refrain":
            return .chorus
        case "bridge", "b":
            return .bridge
        case "prechorus", "pre-chorus", "pc":
            return .prechorus
        case "instrumental", "i":
            return .instrumental
        case "intro":
            return .intro
        case "outro", "ending":
            return .outro
        case "interlude":
            return .interlude
        case "tag":
            return .tag
        case "vamp":
            return .vamp
        default:
            return .unknown
        }
    }
}

enum LineType: String, Codable {
    case lyrics         // Line with lyrics (may have chords)
    case chordsOnly     // Line with only chords, no lyrics
    case blank          // Empty line (for spacing)
    case comment        // Comment line (starts with #)
    case directive      // ChordPro directive line
}
