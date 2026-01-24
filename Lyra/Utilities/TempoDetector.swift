//
//  TempoDetector.swift
//  Lyra
//
//  Tempo and beat detection for audio files
//  Part of Phase 7: Audio Intelligence
//

import Foundation
import AVFoundation
import Accelerate

/// Detects tempo (BPM), beats, and time signature from audio
class TempoDetector {

    // MARK: - Properties

    private let minBPM: Float = 60
    private let maxBPM: Float = 180
    private let sampleRate: Double = 44100.0

    // MARK: - Public API

    /// Detect tempo from an audio file
    func detectTempo(from url: URL) async throws -> TempoDetectionResult {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat

        // Read entire file (or sample if too large)
        let maxDuration: TimeInterval = 60.0 // Analyze first 60 seconds max
        let framesToRead = min(
            AVAudioFrameCount(format.sampleRate * maxDuration),
            AVAudioFrameCount(audioFile.length)
        )

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: framesToRead
        ) else {
            throw TempoDetectionError.invalidAudioFormat
        }

        try audioFile.read(into: buffer)

        // Detect onset events (transients that mark beats)
        let onsets = detectOnsets(in: buffer)

        // Estimate BPM from onset intervals
        let bpm = estimateBPM(from: onsets)

        // Detect beat positions
        let beats = alignBeats(onsets: onsets, bpm: bpm, duration: TimeInterval(audioFile.length) / format.sampleRate)

        // Estimate time signature
        let timeSignature = estimateTimeSignature(from: beats, bpm: bpm)

        // Calculate bar lines
        let barLines = calculateBarLines(beats: beats, timeSignature: timeSignature)

        // Calculate confidence based on onset regularity
        let confidence = calculateTempoConfidence(onsets: onsets, bpm: bpm)

        return TempoDetectionResult(
            bpm: bpm,
            confidence: confidence,
            beatPositions: beats,
            timeSignature: timeSignature,
            barLines: barLines
        )
    }

    // MARK: - Onset Detection

    /// Detect onset events (sudden energy increases) in audio
    private func detectOnsets(in buffer: AVAudioPCMBuffer) -> [TimeInterval] {
        guard let channelData = buffer.floatChannelData else { return [] }

        let frameLength = Int(buffer.frameLength)
        let channel = channelData[0]

        // Parameters
        let hopSize = 512
        let windowSize = 2048
        var onsets: [TimeInterval] = []

        // Calculate energy for each window
        var previousEnergy: Float = 0
        let threshold: Float = 1.5 // Onset threshold multiplier

        for i in stride(from: 0, to: frameLength - windowSize, by: hopSize) {
            let window = Array(UnsafeBufferPointer(start: channel + i, count: windowSize))

            // Calculate RMS energy
            var energy: Float = 0
            vDSP_rmsqv(window, 1, &energy, vDSP_Length(windowSize))

            // Detect onset (significant energy increase)
            if energy > previousEnergy * threshold && energy > 0.01 {
                let timestamp = Double(i) / buffer.format.sampleRate
                onsets.append(timestamp)
            }

            previousEnergy = energy
        }

        return onsets
    }

    // MARK: - BPM Estimation

    /// Estimate BPM from onset intervals
    private func estimateBPM(from onsets: [TimeInterval]) -> Float {
        guard onsets.count > 2 else { return 120.0 } // Default

        // Calculate intervals between onsets
        var intervals: [TimeInterval] = []
        for i in 1..<onsets.count {
            intervals.append(onsets[i] - onsets[i - 1])
        }

        // Filter outliers
        intervals = intervals.filter { $0 > 0.2 && $0 < 2.0 }

        guard !intervals.isEmpty else { return 120.0 }

        // Calculate median interval
        let sortedIntervals = intervals.sorted()
        let medianInterval = sortedIntervals[sortedIntervals.count / 2]

        // Convert interval to BPM
        var bpm = Float(60.0 / medianInterval)

        // Adjust if outside typical range
        while bpm < minBPM {
            bpm *= 2
        }
        while bpm > maxBPM {
            bpm /= 2
        }

        return bpm
    }

    // MARK: - Beat Alignment

    /// Align beats based on detected onsets and estimated BPM
    private func alignBeats(onsets: [TimeInterval], bpm: Float, duration: TimeInterval) -> [TimeInterval] {
        guard !onsets.isEmpty else { return [] }

        let beatInterval = 60.0 / Double(bpm)
        var beats: [TimeInterval] = []

        // Start from first onset
        var currentBeat = onsets.first ?? 0.0

        while currentBeat < duration {
            beats.append(currentBeat)
            currentBeat += beatInterval
        }

        return beats
    }

    // MARK: - Time Signature Estimation

    /// Estimate time signature from beat patterns
    private func estimateTimeSignature(from beats: [TimeInterval], bpm: Float) -> String {
        guard beats.count > 4 else { return "4/4" }

        // Analyze accent patterns
        // This is a simplified implementation
        // In practice, you'd analyze amplitude variations at beat positions

        // For now, default to common time signatures
        // Could be enhanced with actual accent detection

        return "4/4" // Most common in popular music
    }

    // MARK: - Bar Lines

    /// Calculate bar line positions based on time signature
    private func calculateBarLines(beats: [TimeInterval], timeSignature: String?) -> [TimeInterval] {
        guard !beats.isEmpty else { return [] }

        // Parse time signature
        let beatsPerBar: Int
        if let ts = timeSignature, let numerator = Int(ts.split(separator: "/").first ?? "4") {
            beatsPerBar = numerator
        } else {
            beatsPerBar = 4
        }

        var barLines: [TimeInterval] = []
        for (index, beat) in beats.enumerated() {
            if index % beatsPerBar == 0 {
                barLines.append(beat)
            }
        }

        return barLines
    }

    // MARK: - Confidence Calculation

    /// Calculate confidence score for tempo detection
    private func calculateTempoConfidence(onsets: [TimeInterval], bpm: Float) -> Float {
        guard onsets.count > 2 else { return 0.0 }

        let expectedInterval = 60.0 / Double(bpm)

        // Calculate how regular the onsets are
        var deviations: [Double] = []
        for i in 1..<onsets.count {
            let actualInterval = onsets[i] - onsets[i - 1]
            let deviation = abs(actualInterval - expectedInterval) / expectedInterval
            deviations.append(deviation)
        }

        // Average deviation
        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)

        // Convert to confidence (lower deviation = higher confidence)
        let confidence = max(0.0, 1.0 - Float(averageDeviation * 2.0))

        return confidence
    }

    // MARK: - Helper Methods

    /// Find the most prominent BPM from multiple candidates
    private func findMostProminentBPM(candidates: [Float]) -> Float {
        guard !candidates.isEmpty else { return 120.0 }

        // Create histogram of BPM candidates (rounded to nearest integer)
        var histogram: [Int: Int] = [:]

        for bpm in candidates {
            let rounded = Int(round(bpm))
            histogram[rounded, default: 0] += 1
        }

        // Find most common BPM
        let mostCommon = histogram.max { $0.value < $1.value }
        return Float(mostCommon?.key ?? 120)
    }
}

// MARK: - Errors

enum TempoDetectionError: LocalizedError {
    case invalidAudioFormat
    case noOnsetDetected
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidAudioFormat:
            return "Invalid audio format"
        case .noOnsetDetected:
            return "No beat onsets detected in audio"
        case .unknown(let error):
            return "Tempo detection error: \(error.localizedDescription)"
        }
    }
}
