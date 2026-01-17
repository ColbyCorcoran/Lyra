//
//  SongSection.swift
//  Lyra
//
//  Represents a section of a song (verse, chorus, etc.)
//

import Foundation

struct SongSection: Identifiable, Codable {
    let id: UUID
    let type: SectionType
    let label: String
    let lines: [SongLine]
    let index: Int // Section number (e.g., Verse 1, Verse 2)

    init(type: SectionType, label: String? = nil, lines: [SongLine], index: Int = 1) {
        self.id = UUID()
        self.type = type
        self.index = index

        // Auto-generate label if not provided
        if let label = label {
            self.label = label
        } else {
            switch type {
            case .verse, .chorus, .bridge, .prechorus:
                self.label = index > 1 ? "\(type.displayName) \(index)" : type.displayName
            default:
                self.label = type.displayName
            }
        }

        self.lines = lines
    }

    /// Whether this section has any chords
    var hasChords: Bool {
        lines.contains { $0.hasChords }
    }

    /// Get all unique chords in this section
    var uniqueChords: Set<String> {
        var chords = Set<String>()
        for line in lines {
            for chord in line.chords {
                chords.insert(chord)
            }
        }
        return chords
    }

    /// Get the full text of this section (without chords)
    var text: String {
        lines.map { $0.text }.joined(separator: "\n")
    }

    /// Whether this section is empty (no lines or all blank lines)
    var isEmpty: Bool {
        lines.isEmpty || lines.allSatisfy { $0.isEmpty }
    }

    /// Get non-blank lines
    var nonBlankLines: [SongLine] {
        lines.filter { !$0.isEmpty }
    }
}

extension SongSection: Equatable {
    static func == (lhs: SongSection, rhs: SongSection) -> Bool {
        lhs.type == rhs.type &&
        lhs.label == rhs.label &&
        lhs.lines == rhs.lines &&
        lhs.index == rhs.index
    }
}
