//
//  VoiceRangeAnalysisEngine.swift
//  Lyra
//
//  Engine for analyzing vocal range compatibility with songs
//  Part of Phase 7.9: Transpose Intelligence
//

import Foundation

/// Engine responsible for voice range analysis and vocal matching
class VoiceRangeAnalysisEngine {

    // MARK: - Constants

    private let comfortZoneMargin = 2 // Semitones margin for comfort zone
    private let extremeNoteThreshold: Float = 0.3 // Penalty for extreme notes

    // MARK: - Song Range Analysis

    /// Analyze the note range of a song from its chord content
    /// - Parameter content: ChordPro formatted song content
    /// - Returns: Song range analysis with lowest and highest notes
    func analyzeSongRange(content: String) -> SongRangeAnalysis? {
        let chords = TransposeEngine.extractChords(from: content)
        guard !chords.isEmpty else { return nil }

        var allNotes: [MusicalNote] = []

        // Extract root notes from chords and estimate vocal melody range
        for chord in chords {
            if let components = TransposeEngine.parseChord(chord) {
                // Get the root note in MIDI
                let rootNote = noteToMusicalNote(components.root)
                allNotes.append(rootNote)

                // Estimate typical melody range based on chord
                // Most melodies span roughly an octave above the root
                let upperNote = MusicalNote(
                    note: rootNote.note,
                    octave: rootNote.octave + 1
                )
                allNotes.append(upperNote)
            }
        }

        guard !allNotes.isEmpty else { return nil }

        // Find lowest and highest notes
        let sortedNotes = allNotes.sorted { $0.midiNumber < $1.midiNumber }
        guard let lowestNote = sortedNotes.first,
              let highestNote = sortedNotes.last else { return nil }

        let rangeInSemitones = highestNote.midiNumber - lowestNote.midiNumber

        return SongRangeAnalysis(
            lowestNote: lowestNote,
            highestNote: highestNote,
            rangeInSemitones: rangeInSemitones
        )
    }

    // MARK: - Vocal Range Matching

    /// Match song range to user's vocal range
    /// - Parameters:
    ///   - songRange: Analyzed song note range
    ///   - vocalRange: User's vocal capabilities
    /// - Returns: Vocal range fit analysis
    func matchToVocalRange(
        songRange: SongRangeAnalysis,
        vocalRange: VocalRange
    ) -> VocalRangeFit {
        let songLow = songRange.lowestNote
        let songHigh = songRange.highestNote

        let userLow = vocalRange.lowestNote
        let userHigh = vocalRange.highestNote

        let comfortLow = vocalRange.comfortableLowest ?? userLow
        let comfortHigh = vocalRange.comfortableHighest ?? userHigh

        // Check if song fits within absolute range
        let fitsWithinRange = songLow.midiNumber >= userLow.midiNumber &&
                             songHigh.midiNumber <= userHigh.midiNumber

        // Check comfort zone
        let lowestIsComfortable = songLow.midiNumber >= comfortLow.midiNumber
        let highestIsComfortable = songHigh.midiNumber <= comfortHigh.midiNumber

        // Calculate gaps if out of range
        var semitonesBelowRange: Int? = nil
        var semitonesAboveRange: Int? = nil
        var optimalTransposition: Int? = nil

        if songLow.midiNumber < userLow.midiNumber {
            semitonesBelowRange = userLow.midiNumber - songLow.midiNumber
        }

        if songHigh.midiNumber > userHigh.midiNumber {
            semitonesAboveRange = songHigh.midiNumber - userHigh.midiNumber
        }

        // Calculate optimal transposition if needed
        if !fitsWithinRange {
            optimalTransposition = calculateOptimalTransposition(
                songRange: songRange,
                vocalRange: vocalRange
            )
        } else if !lowestIsComfortable || !highestIsComfortable {
            // Even if it fits, suggest transposition for comfort
            optimalTransposition = calculateOptimalTransposition(
                songRange: songRange,
                vocalRange: vocalRange
            )
        }

        return VocalRangeFit(
            fitsWithinRange: fitsWithinRange,
            lowestNoteInSong: songLow,
            highestNoteInSong: songHigh,
            lowestIsComfortable: lowestIsComfortable,
            highestIsComfortable: highestIsComfortable,
            semitonesBelowRange: semitonesBelowRange,
            semitonesAboveRange: semitonesAboveRange,
            optimalTransposition: optimalTransposition
        )
    }

    // MARK: - Optimal Key Finding

    /// Find optimal keys for the user's voice
    /// - Parameters:
    ///   - songContent: Original song content
    ///   - currentKey: Current key of the song
    ///   - vocalRange: User's vocal range
    /// - Returns: Array of semitone transpositions with scores
    func findOptimalKeyForVoice(
        songContent: String,
        currentKey: String?,
        vocalRange: VocalRange
    ) -> [(semitones: Int, score: Float)] {
        guard let songRange = analyzeSongRange(content: songContent) else {
            return []
        }

        var results: [(semitones: Int, score: Float)] = []

        // Test all possible transpositions (-11 to +11)
        for semitones in -11...11 {
            let transposedRange = transposeSongRange(songRange, by: semitones)
            let fit = matchToVocalRange(songRange: transposedRange, vocalRange: vocalRange)
            let score = calculateVoiceRangeScore(fit: fit)

            results.append((semitones: semitones, score: score))
        }

        // Sort by score (highest first)
        return results.sorted { $0.score > $1.score }
    }

    // MARK: - Vocal Strain Prediction

    /// Predict vocal strain for a given transposition
    /// - Parameters:
    ///   - songRange: Current song range
    ///   - vocalRange: User's vocal range
    ///   - semitones: Proposed transposition
    /// - Returns: Strain score (0.0 = no strain, 1.0 = extreme strain)
    func predictVocalStrain(
        songRange: SongRangeAnalysis,
        vocalRange: VocalRange,
        semitones: Int
    ) -> Float {
        let transposedRange = transposeSongRange(songRange, by: semitones)
        let fit = matchToVocalRange(songRange: transposedRange, vocalRange: vocalRange)

        var strainScore: Float = 0.0

        // Out of range = maximum strain
        if !fit.fitsWithinRange {
            if let below = fit.semitonesBelowRange {
                strainScore += Float(below) / 12.0 // Normalize to 0-1
            }
            if let above = fit.semitonesAboveRange {
                strainScore += Float(above) / 12.0
            }
            return min(strainScore, 1.0)
        }

        // In range but uncomfortable = moderate strain
        if !fit.lowestIsComfortable {
            let comfortLow = vocalRange.comfortableLowest ?? vocalRange.lowestNote
            let gap = comfortLow.midiNumber - fit.lowestNoteInSong.midiNumber
            strainScore += Float(gap) / 24.0 // Half weight
        }

        if !fit.highestIsComfortable {
            let comfortHigh = vocalRange.comfortableHighest ?? vocalRange.highestNote
            let gap = fit.highestNoteInSong.midiNumber - comfortHigh.midiNumber
            strainScore += Float(gap) / 24.0
        }

        return min(strainScore, 1.0)
    }

    // MARK: - Helper Methods

    /// Calculate voice range score (0.0-1.0) from fit
    private func calculateVoiceRangeScore(fit: VocalRangeFit) -> Float {
        // Perfect: fits and comfortable
        if fit.fitsWithinRange && fit.lowestIsComfortable && fit.highestIsComfortable {
            return 1.0
        }

        // Good: fits but not fully comfortable
        if fit.fitsWithinRange {
            var score: Float = 0.8

            // Small penalty for uncomfortable extremes
            if !fit.lowestIsComfortable {
                score -= 0.1
            }
            if !fit.highestIsComfortable {
                score -= 0.1
            }

            return max(score, 0.6)
        }

        // Needs adjustment: out of range
        if let optimalTranspose = fit.optimalTransposition {
            let distance = abs(optimalTranspose)
            if distance <= 3 {
                return 0.5 // Minor adjustment needed
            } else if distance <= 6 {
                return 0.3 // Moderate adjustment
            } else {
                return 0.1 // Major adjustment
            }
        }

        return 0.0 // Cannot fit
    }

    /// Calculate optimal transposition to center song in vocal range
    private func calculateOptimalTransposition(
        songRange: SongRangeAnalysis,
        vocalRange: VocalRange
    ) -> Int {
        // Calculate the center of both ranges
        let songCenter = (songRange.lowestNote.midiNumber + songRange.highestNote.midiNumber) / 2
        let vocalCenter = (vocalRange.lowestNote.midiNumber + vocalRange.highestNote.midiNumber) / 2

        // Calculate transposition to align centers
        let semitones = vocalCenter - songCenter

        // Clamp to reasonable range
        return max(-11, min(11, semitones))
    }

    /// Transpose a song range by semitones
    private func transposeSongRange(
        _ range: SongRangeAnalysis,
        by semitones: Int
    ) -> SongRangeAnalysis {
        let newLow = MusicalNote.fromMIDI(range.lowestNote.midiNumber + semitones)
        let newHigh = MusicalNote.fromMIDI(range.highestNote.midiNumber + semitones)

        return SongRangeAnalysis(
            lowestNote: newLow,
            highestNote: newHigh,
            rangeInSemitones: range.rangeInSemitones
        )
    }

    /// Convert note string to MusicalNote (assumes octave 4 for roots)
    private func noteToMusicalNote(_ noteString: String) -> MusicalNote {
        // Typical vocal range for most songs centers around octave 4
        return MusicalNote(note: noteString, octave: 4)
    }
}
