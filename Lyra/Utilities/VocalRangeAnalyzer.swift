//
//  VocalRangeAnalyzer.swift
//  Lyra
//
//  Analyzes vocal recordings to determine user's vocal range
//  Part of Phase 7.3: Key Intelligence
//

import Foundation
import AVFoundation
import Accelerate

/// Analyzes vocal recordings to determine range
class VocalRangeAnalyzer {

    // MARK: - Properties

    private let audioAnalyzer: AudioAnalyzer
    private let minConfidence: Float = 0.5

    // MARK: - Initialization

    init() {
        self.audioAnalyzer = AudioAnalyzer(fftSize: 4096)
    }

    // MARK: - Vocal Range Detection

    /// Analyze an audio recording to detect vocal range
    func analyzeVocalRange(from url: URL) async throws -> VocalRange {
        // Analyze audio file
        let analysisResults = try await audioAnalyzer.analyzeAudioFile(
            url: url,
            windowDuration: 0.5
        ) { _ in }

        // Extract detected notes
        var allNotes: [DetectedNote] = []
        for result in analysisResults {
            allNotes.append(contentsOf: result.notes.filter { $0.confidence >= minConfidence })
        }

        guard !allNotes.isEmpty else {
            throw VocalRangeError.noNotesDetected
        }

        // Find lowest and highest notes
        let lowestMIDI = allNotes.map { $0.frequency }.min()!
        let highestMIDI = allNotes.map { $0.frequency }.max()!

        let lowestNote = frequencyToMusicalNote(lowestMIDI)
        let highestNote = frequencyToMusicalNote(highestMIDI)

        // Determine comfortable range (middle 80%)
        let sortedNotes = allNotes.sorted { $0.frequency < $1.frequency }
        let lowerBound = Int(Float(sortedNotes.count) * 0.1)
        let upperBound = Int(Float(sortedNotes.count) * 0.9)

        let comfortableLow = frequencyToMusicalNote(sortedNotes[lowerBound].frequency)
        let comfortableHigh = frequencyToMusicalNote(sortedNotes[upperBound].frequency)

        // Determine voice type
        let voiceType = classifyVoiceType(
            lowestNote: lowestNote,
            highestNote: highestNote
        )

        return VocalRange(
            lowestNote: lowestNote,
            highestNote: highestNote,
            comfortableLowest: comfortableLow,
            comfortableHighest: comfortableHigh,
            voiceType: voiceType
        )
    }

    // MARK: - Song Range Analysis

    /// Analyze the note range required for a song
    func analyzeSongRange(chords: [String], key: String?) -> SongRangeAnalysis {
        // Simplified estimation based on chords
        // In a real implementation, would analyze melody if available

        // Estimate range based on key and chord progression
        let estimatedLowest = MusicalNote(note: key ?? "C", octave: 3)
        let estimatedHighest = MusicalNote(note: key ?? "C", octave: 5)

        let rangeInSemitones = estimatedHighest.midiNumber - estimatedLowest.midiNumber

        return SongRangeAnalysis(
            lowestNote: estimatedLowest,
            highestNote: estimatedHighest,
            rangeInSemitones: rangeInSemitones
        )
    }

    // MARK: - Vocal Range Fit

    /// Check if a song fits within user's vocal range
    func checkVocalRangeFit(
        songRange: SongRangeAnalysis,
        vocalRange: VocalRange
    ) -> VocalRangeFit {
        let songLow = songRange.lowestNote.midiNumber
        let songHigh = songRange.highestNote.midiNumber
        let vocalLow = vocalRange.lowestNote.midiNumber
        let vocalHigh = vocalRange.highestNote.midiNumber

        let fitsWithinRange = songLow >= vocalLow && songHigh <= vocalHigh

        // Check comfortable range
        let comfortableLow = vocalRange.comfortableLowest?.midiNumber ?? vocalLow
        let comfortableHigh = vocalRange.comfortableHighest?.midiNumber ?? vocalHigh

        let lowestIsComfortable = songLow >= comfortableLow
        let highestIsComfortable = songHigh <= comfortableHigh

        // Calculate how far out of range
        var semitonesBelowRange: Int? = nil
        var semitonesAboveRange: Int? = nil

        if songLow < vocalLow {
            semitonesBelowRange = vocalLow - songLow
        }

        if songHigh > vocalHigh {
            semitonesAboveRange = songHigh - vocalHigh
        }

        // Calculate optimal transposition
        let optimalTransposition = calculateOptimalTransposition(
            songRange: songRange,
            vocalRange: vocalRange
        )

        return VocalRangeFit(
            fitsWithinRange: fitsWithinRange,
            lowestNoteInSong: songRange.lowestNote,
            highestNoteInSong: songRange.highestNote,
            lowestIsComfortable: lowestIsComfortable,
            highestIsComfortable: highestIsComfortable,
            semitonesBelowRange: semitonesBelowRange,
            semitonesAboveRange: semitonesAboveRange,
            optimalTransposition: optimalTransposition
        )
    }

    // MARK: - Helper Methods

    /// Convert frequency to musical note
    private func frequencyToMusicalNote(_ frequency: Float) -> MusicalNote {
        // A4 = 440 Hz is the reference
        let a4Frequency: Float = 440.0
        let semitonesFromA4 = 12.0 * log2(frequency / a4Frequency)
        let midiNumber = Int(round(69 + semitonesFromA4)) // A4 is MIDI 69

        return MusicalNote.fromMIDI(midiNumber)
    }

    /// Classify voice type based on range
    private func classifyVoiceType(lowestNote: MusicalNote, highestNote: MusicalNote) -> VoiceType {
        let lowMIDI = lowestNote.midiNumber
        let highMIDI = highestNote.midiNumber

        // Simplified classification
        // Soprano: C4-C6
        if lowMIDI >= 60 && highMIDI >= 72 {
            return .soprano
        }
        // Alto: F3-F5
        else if lowMIDI >= 53 && highMIDI >= 65 && highMIDI < 72 {
            return .alto
        }
        // Tenor: C3-C5
        else if lowMIDI >= 48 && lowMIDI < 60 && highMIDI >= 60 {
            return .tenor
        }
        // Baritone: A2-A4
        else if lowMIDI >= 45 && lowMIDI < 53 {
            return .baritone
        }
        // Bass: E2-E4
        else if lowMIDI < 45 {
            return .bass
        }

        // Default to mezzo
        return .mezzo
    }

    /// Calculate optimal transposition to fit vocal range
    private func calculateOptimalTransposition(
        songRange: SongRangeAnalysis,
        vocalRange: VocalRange
    ) -> Int? {
        let songLow = songRange.lowestNote.midiNumber
        let songHigh = songRange.highestNote.midiNumber
        let vocalLow = vocalRange.lowestNote.midiNumber
        let vocalHigh = vocalRange.highestNote.midiNumber
        let songSpan = songHigh - songLow
        let vocalSpan = vocalHigh - vocalLow

        // If song range is larger than vocal range, can't fit perfectly
        if songSpan > vocalSpan {
            return nil
        }

        // Try to center the song in the vocal range
        let vocalCenter = vocalLow + (vocalSpan / 2)
        let songCenter = songLow + (songSpan / 2)

        let transposition = vocalCenter - songCenter

        // Limit transposition to reasonable range (-12 to +12 semitones)
        if abs(transposition) > 12 {
            return nil
        }

        return transposition
    }

    // MARK: - Vocal Exercise

    /// Generate vocal exercises for expanding range
    func generateVocalExercises(for range: VocalRange) -> [VocalExercise] {
        var exercises: [VocalExercise] = []

        // Warm-up exercise
        exercises.append(VocalExercise(
            name: "Warm-up Scales",
            description: "Sing up and down your comfortable range",
            startNote: range.comfortableLowest ?? range.lowestNote,
            endNote: range.comfortableHighest ?? range.highestNote,
            pattern: .scale
        ))

        // Range expansion (lower)
        let expandLow = MusicalNote.fromMIDI(range.lowestNote.midiNumber - 2)
        exercises.append(VocalExercise(
            name: "Lower Range Extension",
            description: "Gently explore lower notes",
            startNote: expandLow,
            endNote: range.lowestNote,
            pattern: .descending
        ))

        // Range expansion (upper)
        let expandHigh = MusicalNote.fromMIDI(range.highestNote.midiNumber + 2)
        exercises.append(VocalExercise(
            name: "Upper Range Extension",
            description: "Carefully reach for higher notes",
            startNote: range.highestNote,
            endNote: expandHigh,
            pattern: .ascending
        ))

        return exercises
    }
}

// MARK: - Vocal Exercise

struct VocalExercise: Identifiable {
    var id = UUID()
    var name: String
    var description: String
    var startNote: MusicalNote
    var endNote: MusicalNote
    var pattern: ExercisePattern

    enum ExercisePattern {
        case scale
        case ascending
        case descending
        case arpeggios
    }
}

// MARK: - Errors

enum VocalRangeError: LocalizedError {
    case noNotesDetected
    case recordingTooShort
    case audioFormatInvalid
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noNotesDetected:
            return "No vocal notes detected in recording. Try singing louder or clearer."
        case .recordingTooShort:
            return "Recording is too short. Please record for at least 5 seconds."
        case .audioFormatInvalid:
            return "Invalid audio format. Please use a supported format."
        case .unknown(let error):
            return "Vocal range analysis error: \(error.localizedDescription)"
        }
    }
}
