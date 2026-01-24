//
//  ChordDatabase.swift
//  Lyra
//
//  Database of common chord progressions and patterns
//  Part of Phase 7.2: Chord Analysis Intelligence
//

import Foundation

/// Database of common chord progressions
class ChordDatabase {

    // MARK: - Properties

    private var progressions: [CommonProgression] = []

    // MARK: - Initialization

    init() {
        loadCommonProgressions()
    }

    // MARK: - Database Loading

    private func loadCommonProgressions() {
        // Pop/Rock Progressions
        progressions.append(CommonProgression(
            name: "I-V-vi-IV (Axis Progression)",
            chords: ["C", "G", "Am", "F"],
            type: .oneFiveSixFour,
            genre: ["Pop", "Rock"],
            examples: ["Let It Be - Beatles", "Don't Stop Believin' - Journey", "With Or Without You - U2"],
            popularity: 1.0
        ))

        progressions.append(CommonProgression(
            name: "I-IV-V (Basic Rock)",
            chords: ["C", "F", "G"],
            type: .oneFourFiveOne,
            genre: ["Rock", "Country", "Pop"],
            examples: ["Twist and Shout - Beatles", "Wild Thing - The Troggs"],
            popularity: 0.95
        ))

        progressions.append(CommonProgression(
            name: "I-vi-IV-V (50s Progression)",
            chords: ["C", "Am", "F", "G"],
            type: .oneSixFourFive,
            genre: ["Doo-wop", "Pop", "Rock"],
            examples: ["Stand By Me - Ben E. King", "Every Breath You Take - The Police"],
            popularity: 0.9
        ))

        progressions.append(CommonProgression(
            name: "vi-IV-I-V (Sensitive Progression)",
            chords: ["Am", "F", "C", "G"],
            type: .sixFourOneFive,
            genre: ["Pop", "Alternative"],
            examples: ["Grenade - Bruno Mars", "Apologize - OneRepublic"],
            popularity: 0.85
        ))

        // Jazz Progressions
        progressions.append(CommonProgression(
            name: "ii-V-I (Jazz Standard)",
            chords: ["Dm7", "G7", "Cmaj7"],
            type: .fiftysTwoFiveOne,
            genre: ["Jazz", "Standards"],
            examples: ["All The Things You Are", "Autumn Leaves"],
            popularity: 0.95
        ))

        progressions.append(CommonProgression(
            name: "I-vi-ii-V (Rhythm Changes)",
            chords: ["Cmaj7", "Am7", "Dm7", "G7"],
            type: .jazz,
            genre: ["Jazz", "Bebop"],
            examples: ["I Got Rhythm - Gershwin", "Oleo - Sonny Rollins"],
            popularity: 0.8
        ))

        // Blues Progressions
        progressions.append(CommonProgression(
            name: "12-Bar Blues (Basic)",
            chords: ["C7", "C7", "C7", "C7", "F7", "F7", "C7", "C7", "G7", "F7", "C7", "G7"],
            type: .blues,
            genre: ["Blues", "Rock", "Jazz"],
            examples: ["Sweet Home Chicago", "Crossroads - Cream"],
            popularity: 0.9
        ))

        // Gospel Progressions
        progressions.append(CommonProgression(
            name: "I-IV-I-V (Gospel)",
            chords: ["C", "F", "C", "G"],
            type: .gospel,
            genre: ["Gospel", "Soul", "R&B"],
            examples: ["Amazing Grace", "Oh Happy Day"],
            popularity: 0.75
        ))

        // Andalusian Cadence
        progressions.append(CommonProgression(
            name: "i-VII-VI-V (Andalusian)",
            chords: ["Am", "G", "F", "E"],
            type: .andalusian,
            genre: ["Flamenco", "Rock", "Metal"],
            examples: ["Hit The Road Jack", "Sultans of Swing - Dire Straits"],
            popularity: 0.7
        ))

        // More Pop Progressions
        progressions.append(CommonProgression(
            name: "I-IV-vi-V",
            chords: ["C", "F", "Am", "G"],
            type: .pop,
            genre: ["Pop", "Indie"],
            examples: ["Someone Like You - Adele", "Let Her Go - Passenger"],
            popularity: 0.85
        ))

        progressions.append(CommonProgression(
            name: "vi-V-IV-V",
            chords: ["Am", "G", "F", "G"],
            type: .pop,
            genre: ["Pop", "Rock"],
            examples: ["Zombie - The Cranberries"],
            popularity: 0.65
        ))

        // Minor Key Progressions
        progressions.append(CommonProgression(
            name: "i-VI-III-VII (Minor Pop)",
            chords: ["Am", "F", "C", "G"],
            type: .pop,
            genre: ["Pop", "Rock"],
            examples: ["Losing My Religion - R.E.M.", "7 Years - Lukas Graham"],
            popularity: 0.8
        ))

        progressions.append(CommonProgression(
            name: "i-iv-VII-VI (Minor Rock)",
            chords: ["Am", "Dm", "G", "F"],
            type: .pop,
            genre: ["Rock", "Alternative"],
            examples: ["Stairway to Heaven - Led Zeppelin (verse)"],
            popularity: 0.7
        ))
    }

    // MARK: - Query Methods

    /// Find progressions that contain the given chord sequence
    func findProgressionsContaining(chords: [String]) -> [CommonProgression] {
        guard !chords.isEmpty else { return [] }

        var matches: [CommonProgression] = []

        for progression in progressions {
            // Check if the progression contains this sequence
            if containsSequence(progression.chords, sequence: chords) {
                matches.append(progression)
            }

            // Also check transposed versions
            for semitones in 1...11 {
                let transposed = transposeProgression(progression.chords, by: semitones)
                if containsSequence(transposed, sequence: chords) {
                    var transposedProgression = progression
                    transposedProgression.chords = transposed
                    matches.append(transposedProgression)
                    break
                }
            }
        }

        return matches.sorted { $0.popularity > $1.popularity }
    }

    /// Get all progressions of a specific type
    func getProgressions(ofType type: ProgressionType) -> [CommonProgression] {
        return progressions.filter { $0.type == type }
    }

    /// Get progressions for a specific genre
    func getProgressions(forGenre genre: String) -> [CommonProgression] {
        return progressions.filter { $0.genre.contains(genre) }
    }

    /// Get most popular progressions
    func getMostPopularProgressions(limit: Int = 10) -> [CommonProgression] {
        return progressions
            .sorted { $0.popularity > $1.popularity }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Helper Methods

    /// Check if a progression contains a chord sequence
    private func containsSequence(_ progression: [String], sequence: [String]) -> Bool {
        guard sequence.count <= progression.count else { return false }

        for i in 0...(progression.count - sequence.count) {
            let slice = Array(progression[i..<(i + sequence.count)])
            if matchesSequence(slice, sequence) {
                return true
            }
        }

        return false
    }

    /// Check if two chord sequences match (ignoring exact root, just quality)
    private func matchesSequence(_ seq1: [String], _ seq2: [String]) -> Bool {
        guard seq1.count == seq2.count else { return false }

        for (c1, c2) in zip(seq1, seq2) {
            // Simplified comparison - could be more sophisticated
            if normalizeChord(c1) != normalizeChord(c2) {
                return false
            }
        }

        return true
    }

    /// Normalize chord for comparison (e.g., "C" and "D" both become "major")
    private func normalizeChord(_ chord: String) -> String {
        // Extract quality
        let root = extractRoot(chord)
        let suffix = chord.dropFirst(root.count)

        if suffix.isEmpty {
            return "major"
        } else if suffix.lowercased().contains("m7") {
            return "minor7"
        } else if suffix.lowercased().contains("maj7") {
            return "major7"
        } else if suffix.lowercased().contains("7") {
            return "dominant7"
        } else if suffix.lowercased().contains("m") {
            return "minor"
        } else {
            return String(suffix)
        }
    }

    /// Extract root note from chord
    private func extractRoot(_ chord: String) -> String {
        if chord.count >= 2 {
            let firstTwo = String(chord.prefix(2))
            if ["C#", "Db", "D#", "Eb", "F#", "Gb", "G#", "Ab", "A#", "Bb"].contains(firstTwo) {
                return firstTwo
            }
        }
        return String(chord.prefix(1))
    }

    /// Transpose a progression by semitones
    private func transposeProgression(_ chords: [String], by semitones: Int) -> [String] {
        let theory = MusicTheoryEngine()
        return chords.map { theory.transposeChord($0, by: semitones) }
    }
}

// MARK: - CommonProgression Extension

extension CommonProgression {
    /// Get the next chord in the progression after the given sequence
    func getNextChord(after sequence: [String]) -> String? {
        // Find where this sequence appears in the progression
        for i in 0..<(chords.count - sequence.count) {
            let slice = Array(chords[i..<(i + sequence.count)])
            if slice == sequence && i + sequence.count < chords.count {
                return chords[i + sequence.count]
            }
        }

        return nil
    }
}
