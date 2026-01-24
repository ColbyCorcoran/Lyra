//
//  SectionType.swift
//  Lyra
//
//  Section types for parsed song structure
//

import Foundation
import SwiftUI

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
    case coda = "Coda"
    case solo = "Solo"
    case unknown = "Unknown"

    var displayName: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .verse: return "text.alignleft"
        case .chorus: return "music.note.list"
        case .bridge: return "link"
        case .prechorus: return "arrow.right.to.line"
        case .instrumental: return "guitars"
        case .intro: return "arrow.forward.to.line"
        case .outro: return "arrow.backward.to.line"
        case .interlude: return "pause"
        case .tag: return "tag.fill"
        case .vamp: return "repeat"
        case .coda: return "chevron.right.2"
        case .solo: return "waveform"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .verse: return .blue
        case .chorus: return .green
        case .bridge: return .orange
        case .prechorus: return .purple
        case .instrumental: return .cyan
        case .intro: return .indigo
        case .outro: return .pink
        case .interlude: return .yellow
        case .tag: return .red
        case .vamp: return .mint
        case .coda: return .brown
        case .solo: return .teal
        case .unknown: return .gray
        }
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
        case "coda":
            return .coda
        case "solo":
            return .solo
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
