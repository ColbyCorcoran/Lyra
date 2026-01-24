//
//  AudioAnalyzer.swift
//  Lyra
//
//  FFT-based audio analysis for pitch detection and frequency spectrum extraction
//  Part of Phase 7: Audio Intelligence
//

import Foundation
import AVFoundation
import Accelerate

/// Analyzes audio data using FFT to detect pitches and frequencies
class AudioAnalyzer {

    // MARK: - Properties

    private let fftSize: Int
    private let sampleRate: Double
    private let hopSize: Int

    // FFT Setup
    private var fftSetup: vDSP_DFT_Setup?
    private var window: [Float]

    // Frequency bin resolution
    private var frequencyResolution: Double {
        sampleRate / Double(fftSize)
    }

    // MARK: - Note Frequencies

    /// Standard frequencies for musical notes (A4 = 440 Hz)
    private static let noteFrequencies: [(note: String, frequency: Float)] = [
        ("C", 16.35), ("C#", 17.32), ("D", 18.35), ("D#", 19.45),
        ("E", 20.60), ("F", 21.83), ("F#", 23.12), ("G", 24.50),
        ("G#", 25.96), ("A", 27.50), ("A#", 29.14), ("B", 30.87)
    ]

    // MARK: - Initialization

    init(fftSize: Int = 4096, sampleRate: Double = 44100.0) {
        self.fftSize = fftSize
        self.sampleRate = sampleRate
        self.hopSize = fftSize / 2

        // Create FFT setup
        self.fftSetup = vDSP_DFT_zrop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        )

        // Create Hann window for windowing audio data
        self.window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&self.window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }

    // MARK: - Audio File Analysis

    /// Analyze an audio file and extract frequency information over time
    func analyzeAudioFile(
        url: URL,
        windowDuration: TimeInterval = 1.0,
        progressCallback: ((Float) -> Void)? = nil
    ) async throws -> [AudioAnalysisResult] {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat

        // Calculate number of frames per analysis window
        let framesPerWindow = AVAudioFrameCount(format.sampleRate * windowDuration)
        let totalFrames = audioFile.length
        let numberOfWindows = Int(ceil(Double(totalFrames) / Double(framesPerWindow)))

        var results: [AudioAnalysisResult] = []

        for windowIndex in 0..<numberOfWindows {
            let startFrame = AVAudioFramePosition(windowIndex * Int(framesPerWindow))
            audioFile.framePosition = startFrame

            let framesToRead = min(framesPerWindow, AVAudioFrameCount(totalFrames - startFrame))
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: framesToRead
            ) else { continue }

            try audioFile.read(into: buffer)

            // Get timestamp for this window
            let timestamp = Double(startFrame) / format.sampleRate

            // Analyze this window
            if let result = analyzeBuffer(buffer, timestamp: timestamp) {
                results.append(result)
            }

            // Report progress
            let progress = Float(windowIndex + 1) / Float(numberOfWindows)
            progressCallback?(progress)
        }

        return results
    }

    // MARK: - Buffer Analysis

    /// Analyze a single audio buffer
    func analyzeBuffer(_ buffer: AVAudioPCMBuffer, timestamp: TimeInterval = 0) -> AudioAnalysisResult? {
        guard let channelData = buffer.floatChannelData else { return nil }

        let frameLength = Int(buffer.frameLength)
        let channel = channelData[0] // Use first channel (mono or left channel)

        // Prepare data for FFT
        var audioData = Array(UnsafeBufferPointer(start: channel, count: min(frameLength, fftSize)))

        // Pad with zeros if needed
        if audioData.count < fftSize {
            audioData.append(contentsOf: [Float](repeating: 0, count: fftSize - audioData.count))
        }

        // Perform FFT analysis
        guard let (frequencies, magnitudes) = performFFT(on: audioData) else {
            return nil
        }

        // Find dominant frequencies
        let dominantFreqs = findDominantFrequencies(frequencies: frequencies, magnitudes: magnitudes, count: 10)

        // Detect musical notes
        let notes = detectNotes(from: dominantFreqs, magnitudes: magnitudes, frequencies: frequencies)

        return AudioAnalysisResult(
            timestamp: timestamp,
            frequencies: frequencies,
            magnitudes: magnitudes,
            dominantFrequencies: dominantFreqs,
            notes: notes
        )
    }

    // MARK: - FFT Processing

    /// Perform FFT on audio data
    private func performFFT(on data: [Float]) -> (frequencies: [Float], magnitudes: [Float])? {
        guard let setup = fftSetup else { return nil }
        guard data.count >= fftSize else { return nil }

        // Apply window
        var windowedData = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(data, 1, window, 1, &windowedData, 1, vDSP_Length(fftSize))

        // Prepare split complex buffer
        var realPart = [Float](repeating: 0, count: fftSize / 2)
        var imagPart = [Float](repeating: 0, count: fftSize / 2)

        var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imagPart)

        // Convert to split complex format
        windowedData.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
            let complexBuffer = rawBuffer.bindMemory(to: DSPComplex.self)
            vDSP_ctoz(complexBuffer.baseAddress!, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
        }

        // Perform FFT
        vDSP_DFT_Execute(setup, splitComplex.realp, splitComplex.imagp, splitComplex.realp, splitComplex.imagp)

        // Calculate magnitudes
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))

        // Normalize magnitudes
        var normalizedMagnitudes = [Float](repeating: 0, count: fftSize / 2)
        var scaleFactor = Float(2.0 / Float(fftSize))
        vDSP_vsmul(magnitudes, 1, &scaleFactor, &normalizedMagnitudes, 1, vDSP_Length(fftSize / 2))

        // Generate frequency bins
        let frequencies = (0..<(fftSize / 2)).map { bin in
            Float(bin) * Float(frequencyResolution)
        }

        return (frequencies, normalizedMagnitudes)
    }

    // MARK: - Frequency Analysis

    /// Find the N most dominant frequencies
    private func findDominantFrequencies(
        frequencies: [Float],
        magnitudes: [Float],
        count: Int = 10
    ) -> [Float] {
        // Create array of (frequency, magnitude) pairs
        let pairs = zip(frequencies, magnitudes).map { (freq: $0, mag: $1) }

        // Sort by magnitude (descending) and take top N
        let topPairs = pairs
            .filter { $0.freq > 20 && $0.freq < 4000 } // Focus on musical range
            .sorted { $0.mag > $1.mag }
            .prefix(count)

        return topPairs.map { $0.freq }
    }

    /// Detect musical notes from frequencies
    private func detectNotes(
        from dominantFreqs: [Float],
        magnitudes: [Float],
        frequencies: [Float]
    ) -> [DetectedNote] {
        var notes: [DetectedNote] = []

        for frequency in dominantFreqs {
            guard let (note, octave) = frequencyToNote(frequency) else { continue }

            // Find magnitude for this frequency
            guard let index = frequencies.firstIndex(where: { abs($0 - frequency) < Float(frequencyResolution) }) else {
                continue
            }
            let magnitude = magnitudes[index]

            // Calculate confidence based on magnitude
            let maxMagnitude = magnitudes.max() ?? 1.0
            let confidence = min(1.0, magnitude / maxMagnitude)

            notes.append(DetectedNote(
                note: note,
                octave: octave,
                frequency: frequency,
                magnitude: magnitude,
                confidence: confidence
            ))
        }

        return notes
    }

    // MARK: - Note Conversion

    /// Convert frequency to musical note
    func frequencyToNote(_ frequency: Float) -> (note: String, octave: Int)? {
        guard frequency > 0 else { return nil }

        // A4 = 440 Hz is the reference
        let a4Frequency: Float = 440.0
        let semitonesFromA4 = 12.0 * log2(frequency / a4Frequency)
        let noteIndex = Int(round(semitonesFromA4))

        // Calculate octave (A4 is in octave 4)
        let octave = 4 + (noteIndex / 12)

        // Calculate note within the octave
        let noteInOctave = ((noteIndex % 12) + 12) % 12 // Ensure positive
        let noteNames = ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]
        let noteName = noteNames[noteInOctave]

        return (noteName, octave)
    }

    /// Convert note and octave to frequency
    func noteToFrequency(note: String, octave: Int) -> Float {
        let noteNames = ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]
        guard let noteIndex = noteNames.firstIndex(of: note) else { return 0 }

        let a4Frequency: Float = 440.0
        let semitonesFromA4 = noteIndex + (octave - 4) * 12

        return a4Frequency * pow(2.0, Float(semitonesFromA4) / 12.0)
    }

    // MARK: - Chord Detection from Notes

    /// Detect possible chords from a collection of notes
    func detectChordsFromNotes(_ notes: [DetectedNote]) -> [(chord: String, confidence: Float)] {
        // Extract unique note names (without octaves)
        let noteNames = Set(notes.map { $0.note })

        // Sort by magnitude to determine the likely root
        let sortedNotes = notes.sorted { $0.magnitude > $1.magnitude }

        var chordCandidates: [(chord: String, confidence: Float)] = []

        // Try each note as potential root
        for rootNote in sortedNotes.prefix(3) {
            let root = rootNote.note

            // Check for major chord (root, major third, perfect fifth)
            if containsInterval(noteNames, root: root, intervals: [0, 4, 7]) {
                let confidence = calculateChordConfidence(notes, chord: "\(root)")
                chordCandidates.append((chord: root, confidence: confidence))
            }

            // Check for minor chord (root, minor third, perfect fifth)
            if containsInterval(noteNames, root: root, intervals: [0, 3, 7]) {
                let confidence = calculateChordConfidence(notes, chord: "\(root)m")
                chordCandidates.append((chord: "\(root)m", confidence: confidence))
            }

            // Check for dominant 7th (root, major third, perfect fifth, minor seventh)
            if containsInterval(noteNames, root: root, intervals: [0, 4, 7, 10]) {
                let confidence = calculateChordConfidence(notes, chord: "\(root)7")
                chordCandidates.append((chord: "\(root)7", confidence: confidence))
            }

            // Check for major 7th (root, major third, perfect fifth, major seventh)
            if containsInterval(noteNames, root: root, intervals: [0, 4, 7, 11]) {
                let confidence = calculateChordConfidence(notes, chord: "\(root)maj7")
                chordCandidates.append((chord: "\(root)maj7", confidence: confidence))
            }

            // Check for minor 7th (root, minor third, perfect fifth, minor seventh)
            if containsInterval(noteNames, root: root, intervals: [0, 3, 7, 10]) {
                let confidence = calculateChordConfidence(notes, chord: "\(root)m7")
                chordCandidates.append((chord: "\(root)m7", confidence: confidence))
            }
        }

        // Sort by confidence
        return chordCandidates.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Helper Methods

    /// Check if note set contains specific intervals from root
    private func containsInterval(_ notes: Set<String>, root: String, intervals: [Int]) -> Bool {
        let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        guard let rootIndex = chromaticScale.firstIndex(of: root) else { return false }

        for interval in intervals {
            let targetIndex = (rootIndex + interval) % 12
            let targetNote = chromaticScale[targetIndex]
            if !notes.contains(targetNote) {
                return false
            }
        }

        return true
    }

    /// Calculate confidence score for a detected chord
    private func calculateChordConfidence(_ notes: [DetectedNote], chord: String) -> Float {
        // Simple confidence calculation based on average magnitude of chord tones
        let totalMagnitude = notes.reduce(0.0) { $0 + $1.magnitude }
        let averageMagnitude = totalMagnitude / Float(notes.count)

        // Normalize to 0-1 range (assuming max magnitude is around 1.0)
        return min(1.0, averageMagnitude * Float(notes.count) / 3.0)
    }

    // MARK: - Onset Detection

    /// Detect sudden changes in energy (potential chord changes)
    func detectOnsets(in results: [AudioAnalysisResult], threshold: Float = 0.3) -> [TimeInterval] {
        guard results.count > 1 else { return [] }

        var onsets: [TimeInterval] = []
        var previousEnergy: Float = 0

        for result in results {
            // Calculate total energy
            let energy = result.magnitudes.reduce(0, +)

            // Detect significant energy increase
            if energy > previousEnergy * (1.0 + threshold) {
                onsets.append(result.timestamp)
            }

            previousEnergy = energy
        }

        return onsets
    }
}

// MARK: - Extensions

extension AudioAnalyzer {
    /// Convenience method to get note name without octave
    func simplifyNoteName(_ fullNote: String) -> String {
        // Remove octave number from note name (e.g., "C4" -> "C")
        return fullNote.filter { !$0.isNumber }
    }
}
