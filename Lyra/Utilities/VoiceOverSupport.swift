//
//  VoiceOverSupport.swift
//  Lyra
//
//  Advanced VoiceOver support with custom rotors
//  Navigate by section, chord, or verse
//

import Foundation
import SwiftUI
import UIKit

/// VoiceOver rotor for navigating song sections
struct SongSectionRotor {
    let sections: [SongSection]

    func makeRotor() -> UIAccessibilityCustomRotor {
        return UIAccessibilityCustomRotor(name: "Sections") { predicate in
            return self.nextSection(predicate: predicate)
        }
    }

    private func nextSection(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        guard !sections.isEmpty else { return nil }

        let currentIndex = predicate.currentItem.targetRange?.location ?? 0
        let forward = predicate.searchDirection == .next

        let nextIndex = forward ?
            (currentIndex + 1) % sections.count :
            (currentIndex - 1 + sections.count) % sections.count

        guard nextIndex < sections.count else { return nil }

        let section = sections[nextIndex]
        let element = AccessibilityElement(
            label: section.label,
            value: section.lines.map { $0.text }.joined(separator: "\n")
        )

        return UIAccessibilityCustomRotorItemResult(
            targetElement: element,
            targetRange: NSRange(location: nextIndex, length: 1)
        )
    }
}

/// VoiceOver rotor for navigating chords
struct ChordRotor {
    let chords: [ChordOccurrence]

    func makeRotor() -> UIAccessibilityCustomRotor {
        return UIAccessibilityCustomRotor(name: "Chords") { predicate in
            return self.nextChord(predicate: predicate)
        }
    }

    private func nextChord(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        guard !chords.isEmpty else { return nil }

        let currentIndex = predicate.currentItem.targetRange?.location ?? 0
        let forward = predicate.searchDirection == .next

        let nextIndex = forward ?
            (currentIndex + 1) % chords.count :
            (currentIndex - 1 + chords.count) % chords.count

        guard nextIndex < chords.count else { return nil }

        let chord = chords[nextIndex]
        let element = AccessibilityElement(
            label: describeChord(chord.chord),
            value: "At position \(chord.position)"
        )

        return UIAccessibilityCustomRotorItemResult(
            targetElement: element,
            targetRange: NSRange(location: nextIndex, length: 1)
        )
    }

    /// Convert chord symbol to spoken description
    private func describeChord(_ chord: String) -> String {
        var description = ""

        // Root note
        let root = String(chord.prefix(1))
        description += root

        // Accidental
        if chord.contains("#") {
            description += " sharp"
        } else if chord.contains("b") {
            description += " flat"
        }

        // Quality
        let quality = chord.dropFirst()
        if quality.contains("m") && !quality.contains("maj") {
            description += " minor"
        } else if quality.contains("maj") {
            description += " major"
        }

        // Extensions
        if quality.contains("7") {
            description += " seventh"
        }
        if quality.contains("9") {
            description += " ninth"
        }
        if quality.contains("sus") {
            description += " suspended"
        }
        if quality.contains("dim") {
            description += " diminished"
        }
        if quality.contains("aug") {
            description += " augmented"
        }

        return description + " chord"
    }
}

/// Represents a chord occurrence in the song
struct ChordOccurrence {
    let chord: String
    let position: Int
    let section: String
}

/// Custom accessibility element
class AccessibilityElement: UIAccessibilityElement {
    var label: String
    var value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
        super.init(accessibilityContainer: UIView())

        self.accessibilityLabel = label
        self.accessibilityValue = value
        self.accessibilityTraits = .staticText
    }
}

/// Extract chords from parsed song for rotor
func extractChords(from parsedSong: ParsedSong) -> [ChordOccurrence] {
    var chords: [ChordOccurrence] = []
    var position = 0

    for section in parsedSong.sections {
        for line in section.lines {
            if case .lyrics = line.type {
                for chord in line.chords {
                    chords.append(ChordOccurrence(
                        chord: chord.chord,
                        position: position,
                        section: section.label
                    ))
                    position += 1
                }
            }
        }
    }

    return chords
}

/// VoiceOver utility functions
struct VoiceOverUtils {
    /// Announce text immediately
    static func announce(_ text: String, priority: UIAccessibility.Announcement.Priority = .default) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }

    /// Announce screen change
    static func announceScreenChange(_ text: String) {
        UIAccessibility.post(notification: .screenChanged, argument: text)
    }

    /// Announce layout change
    static func announceLayoutChange(_ text: String? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: text)
    }

    /// Focus on specific element
    static func focus(on element: Any) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }

    /// Check if VoiceOver is running
    static var isRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// Describe song metadata for VoiceOver
    static func describeSongMetadata(song: Song) -> String {
        var description = "Song: \(song.title)"

        if let artist = song.artist {
            description += ", by \(artist)"
        }

        if let key = song.currentKey {
            description += ", in the key of \(key)"
        }

        if let tempo = song.tempo {
            description += ", tempo \(tempo) beats per minute"
        }

        if let timeSignature = song.timeSignature {
            description += ", \(timeSignature) time"
        }

        return description
    }

    /// Describe section for VoiceOver
    static func describeSection(_ section: SongSection) -> String {
        let lineCount = section.lines.count
        let hasChords = section.lines.contains { !$0.chords.isEmpty }

        var description = "\(section.label), \(lineCount) line"
        if lineCount != 1 {
            description += "s"
        }

        if hasChords {
            let chordCount = section.lines.reduce(0) { $0 + $1.chords.count }
            description += ", \(chordCount) chord"
            if chordCount != 1 {
                description += "s"
            }
        }

        return description
    }

    /// Describe autoscroll state
    static func describeAutoscrollState(isPlaying: Bool, speed: Int?) -> String {
        if isPlaying {
            if let speed = speed {
                return "Autoscroll playing at \(speed) seconds"
            } else {
                return "Autoscroll playing"
            }
        } else {
            return "Autoscroll paused"
        }
    }
}

/// SwiftUI View extension for accessibility
extension View {
    /// Add custom VoiceOver rotor
    func accessibilityRotor<EntryModel>(
        _ label: String,
        entries: [EntryModel],
        entryLabel: @escaping (EntryModel) -> String
    ) -> some View {
        self.accessibilityElement(children: .contain)
            .accessibilityLabel(label)
    }

    /// Mark as VoiceOver group
    func accessibilityGroup() -> some View {
        if AccessibilityManager.shared.smartElementGrouping {
            return self.accessibilityElement(children: .combine)
        } else {
            return self
        }
    }

    /// Add spoken hint for complex elements
    func accessibilitySpokenHint(_ hint: String) -> some View {
        self.accessibilityHint(Text(hint))
    }

    /// Announce when value changes
    func announceOnChange<V: Equatable>(of value: V, announcement: @escaping (V) -> String) -> some View {
        self.onChange(of: value) { oldValue, newValue in
            if AccessibilityManager.shared.isVoiceOverRunning {
                AccessibilityManager.shared.announce(announcement(newValue))
            }
        }
    }
}

/// Accessibility traits for music elements
extension AccessibilityTraits {
    static let musicNote: AccessibilityTraits = .isStaticText
    static let chord: AccessibilityTraits = .isStaticText
    static let section: AccessibilityTraits = .isHeader
    static let playbackControl: AccessibilityTraits = .isButton
}

/// Braille representation for chords
struct BrailleChordConverter {
    /// Convert chord symbol to Braille-friendly text
    static func toBraille(_ chord: String) -> String {
        var braille = ""

        // Root note
        let root = String(chord.prefix(1))
        braille += root

        // Accidental symbols
        let remaining = String(chord.dropFirst())
        braille += remaining
            .replacingOccurrences(of: "#", with: "♯")
            .replacingOccurrences(of: "b", with: "♭")

        return braille
    }

    /// Describe chord for Braille display
    static func describe(_ chord: String) -> String {
        // For Braille displays, use compact representation
        return toBraille(chord)
    }
}
