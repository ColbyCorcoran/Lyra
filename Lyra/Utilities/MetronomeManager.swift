//
//  MetronomeManager.swift
//  Lyra
//
//  High-precision metronome engine with AVAudioEngine
//

import Foundation
import AVFoundation
import Combine

@Observable
class MetronomeManager {
    // MARK: - State Properties

    var isPlaying: Bool = false
    var currentBeat: Int = 0
    var currentBPM: Double = 120
    var timeSignature: MetronomeTimeSignature = .fourFour
    var volume: Float = 0.7
    var soundType: MetronomeSoundType = .click
    var visualOnly: Bool = false
    var subdivisions: SubdivisionOption = .none

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var playerNodes: [AVAudioPlayerNode] = []
    private var timer: Timer?
    private var lastBeatTime: Date?
    private var tapTimes: [Date] = []

    // Audio buffers
    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?
    private var subdivisionBuffer: AVAudioPCMBuffer?

    // MARK: - Initialization

    init() {
        setupAudioEngine()
        loadSoundBuffers()
    }

    deinit {
        stop()
        audioEngine?.stop()
    }

    // MARK: - Public Methods

    func start() {
        guard !isPlaying else { return }

        isPlaying = true
        currentBeat = 0

        if !visualOnly {
            startAudioEngine()
        }

        startTimer()
        HapticManager.shared.selection()
    }

    func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        currentBeat = 0

        // Stop all player nodes
        for player in playerNodes {
            player.stop()
        }

        HapticManager.shared.selection()
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func setBPM(_ bpm: Double) {
        currentBPM = max(30, min(300, bpm))

        if isPlaying {
            // Restart with new tempo
            stop()
            start()
        }
    }

    func adjustBPM(by delta: Double) {
        setBPM(currentBPM + delta)
    }

    func tapTempo() {
        let now = Date()
        tapTimes.append(now)

        // Keep only last 8 taps
        if tapTimes.count > 8 {
            tapTimes.removeFirst()
        }

        // Need at least 2 taps to calculate tempo
        guard tapTimes.count >= 2 else {
            HapticManager.shared.selection()
            return
        }

        // Remove taps older than 3 seconds
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3.0 }

        guard tapTimes.count >= 2 else { return }

        // Calculate average interval
        var totalInterval: TimeInterval = 0
        for i in 1..<tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i-1])
        }
        let avgInterval = totalInterval / Double(tapTimes.count - 1)

        // Convert to BPM
        let bpm = 60.0 / avgInterval
        setBPM(bpm)

        HapticManager.shared.medium()
    }

    func resetTapTempo() {
        tapTimes.removeAll()
    }

    // MARK: - Private Methods

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()

        guard let engine = audioEngine else { return }

        // Create player nodes
        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            playerNodes.append(player)
        }
    }

    private func startAudioEngine() {
        guard let engine = audioEngine, !engine.isRunning else { return }

        do {
            // Configure audio session
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    private func loadSoundBuffers() {
        // Generate simple click sounds
        accentBuffer = generateClickBuffer(frequency: 1200, duration: 0.05)
        normalBuffer = generateClickBuffer(frequency: 800, duration: 0.05)
        subdivisionBuffer = generateClickBuffer(frequency: 600, duration: 0.03)
    }

    private func generateClickBuffer(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        guard let engine = audioEngine else { return nil }

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData else { return nil }

        let channelCount = Int(format.channelCount)

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let amplitude = Float(sin(2.0 * .pi * frequency * time)) * 0.3

            // Apply envelope (quick attack, exponential decay)
            let envelope = Float(exp(-time * 50))
            let sample = amplitude * envelope

            for channel in 0..<channelCount {
                channelData[channel][frame] = sample
            }
        }

        return buffer
    }

    private func startTimer() {
        let interval = 60.0 / currentBPM
        let subdivisionInterval = interval / subdivisions.divisor

        timer = Timer.scheduledTimer(withTimeInterval: subdivisionInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }

        // Fire immediately
        tick()
    }

    private func tick() {
        let beatsPerMeasure = timeSignature.beatsPerMeasure

        // Determine if this is a main beat or subdivision
        let isMainBeat: Bool
        switch subdivisions {
        case .none:
            isMainBeat = true
        case .eighthNotes:
            isMainBeat = currentBeat % 2 == 0
        case .sixteenthNotes:
            isMainBeat = currentBeat % 4 == 0
        }

        if isMainBeat {
            let mainBeatIndex = currentBeat / Int(subdivisions.divisor)
            let isDownbeat = (mainBeatIndex % beatsPerMeasure) == 0

            playSound(isDownbeat: isDownbeat, isSubdivision: false)

            // Visual feedback (always, even in audio mode)
            if isDownbeat {
                HapticManager.shared.medium()
            } else {
                HapticManager.shared.light()
            }
        } else {
            // Subdivision beat
            playSound(isDownbeat: false, isSubdivision: true)
        }

        currentBeat += 1

        // Reset beat counter at end of measure
        let totalBeatsInMeasure = beatsPerMeasure * Int(subdivisions.divisor)
        if currentBeat >= totalBeatsInMeasure {
            currentBeat = 0
        }
    }

    private func playSound(isDownbeat: Bool, isSubdivision: Bool) {
        guard !visualOnly else { return }
        guard let engine = audioEngine, engine.isRunning else { return }

        let buffer: AVAudioPCMBuffer?
        if isSubdivision {
            buffer = subdivisionBuffer
        } else if isDownbeat {
            buffer = accentBuffer
        } else {
            buffer = normalBuffer
        }

        guard let soundBuffer = buffer else { return }

        // Find available player node
        let player = playerNodes.first { !$0.isPlaying } ?? playerNodes[0]

        player.volume = volume
        player.scheduleBuffer(soundBuffer, at: nil, options: [], completionHandler: nil)

        if !player.isPlaying {
            player.play()
        }
    }
}

// MARK: - Time Signature

enum MetronomeTimeSignature: String, CaseIterable, Identifiable, Codable {
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case fiveFour = "5/4"
    case sixEight = "6/8"
    case sevenEight = "7/8"
    case nineEight = "9/8"
    case twelveEight = "12/8"

    var id: String { rawValue }

    var beatsPerMeasure: Int {
        switch self {
        case .twoFour: return 2
        case .threeFour: return 3
        case .fourFour: return 4
        case .fiveFour: return 5
        case .sixEight: return 6
        case .sevenEight: return 7
        case .nineEight: return 9
        case .twelveEight: return 12
        }
    }

    var displayName: String { rawValue }
}

// MARK: - Metronome Sound Type

enum MetronomeSoundType: String, CaseIterable, Identifiable, Codable {
    case click = "Click"
    case beep = "Beep"
    case drum = "Drum"
    case woodblock = "Woodblock"

    var id: String { rawValue }
}

// MARK: - Subdivision Option

enum SubdivisionOption: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case eighthNotes = "8th Notes"
    case sixteenthNotes = "16th Notes"

    var id: String { rawValue }

    var divisor: Double {
        switch self {
        case .none: return 1.0
        case .eighthNotes: return 2.0
        case .sixteenthNotes: return 4.0
        }
    }
}

// MARK: - Metronome Preset

struct MetronomePreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var bpm: Double
    var timeSignature: MetronomeTimeSignature

    init(name: String, bpm: Double, timeSignature: MetronomeTimeSignature) {
        self.id = UUID()
        self.name = name
        self.bpm = bpm
        self.timeSignature = timeSignature
    }

    // Common presets
    static let common: [MetronomePreset] = [
        MetronomePreset(name: "Slow Practice", bpm: 60, timeSignature: .fourFour),
        MetronomePreset(name: "Moderate", bpm: 90, timeSignature: .fourFour),
        MetronomePreset(name: "Standard", bpm: 120, timeSignature: .fourFour),
        MetronomePreset(name: "Fast", bpm: 160, timeSignature: .fourFour),
        MetronomePreset(name: "Waltz", bpm: 90, timeSignature: .threeFour),
        MetronomePreset(name: "March", bpm: 120, timeSignature: .twoFour)
    ]
}
