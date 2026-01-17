//
//  LineSegment.swift
//  Lyra
//
//  Represents a piece of text with an optional chord above it
//

import Foundation

struct LineSegment: Identifiable, Codable {
    let id: UUID
    let text: String
    let chord: String?
    let position: Int // Character position in the original line for rendering

    init(text: String, chord: String? = nil, position: Int = 0) {
        self.id = UUID()
        self.text = text
        self.chord = chord
        self.position = position
    }

    /// Whether this segment has a chord
    var hasChord: Bool {
        chord != nil && !(chord?.isEmpty ?? true)
    }

    /// The display chord (trimmed and non-empty)
    var displayChord: String? {
        guard let chord = chord?.trimmingCharacters(in: .whitespaces),
              !chord.isEmpty else {
            return nil
        }
        return chord
    }
}

extension LineSegment: Equatable {
    static func == (lhs: LineSegment, rhs: LineSegment) -> Bool {
        lhs.text == rhs.text &&
        lhs.chord == rhs.chord &&
        lhs.position == rhs.position
    }
}
