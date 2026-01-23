//
//  MIDISongLoader.swift
//  Lyra
//
//  Handles automatic song loading based on MIDI triggers
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// MARK: - MIDI Song Loader

@MainActor
@Observable
class MIDISongLoader {
    static let shared = MIDISongLoader()

    // MARK: - State

    var isEnabled: Bool = false
    var modelContext: ModelContext?

    var lastTriggeredSong: Song?
    var lastTriggerTime: Date?
    var lastTriggerMessage: MIDIMessage?

    // Visual feedback
    var showTriggerFlash: Bool = false
    var triggerFeedbackMessage: String?

    // Learn mode
    var isLearning: Bool = false
    var learningForSong: Song?
    var learnCallback: ((MIDITrigger) -> Void)?

    // Combination trigger state
    private var recentMessages: [MIDIMessage] = []
    private let combinationWindow: TimeInterval = 1.0 // 1 second window

    // MARK: - Initialization

    private init() {
        loadSettings()
        setupMIDINotifications()
    }

    // MARK: - Setup

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func setupMIDINotifications() {
        // Listen for MIDI Program Change
        NotificationCenter.default.addObserver(
            forName: .midiProgramChangeReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleProgramChange(notification: notification)
            }
        }

        // Listen for MIDI Control Change
        NotificationCenter.default.addObserver(
            forName: .midiControlChangeReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleControlChange(notification: notification)
            }
        }

        // Listen for MIDI Note On
        NotificationCenter.default.addObserver(
            forName: .midiNoteOnReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleNoteOn(notification: notification)
            }
        }

        // Listen for all MIDI messages (for learning)
        NotificationCenter.default.addObserver(
            forName: .midiMessageReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleMIDIMessage(notification: notification)
            }
        }
    }

    // MARK: - MIDI Message Handlers

    private func handleProgramChange(notification: Notification) async {
        guard isEnabled, let context = modelContext else { return }

        guard let program = notification.userInfo?["program"] as? UInt8,
              let channel = notification.userInfo?["channel"] as? UInt8 else {
            return
        }

        // Create message for matching
        let message = MIDIMessage(
            type: .programChange,
            channel: channel,
            data1: program
        )

        // Find matching song
        if let song = await findSongForTrigger(message: message, context: context) {
            await loadSong(song, triggeredBy: message)
        }
    }

    private func handleControlChange(notification: Notification) async {
        guard isEnabled, let context = modelContext else { return }

        guard let controller = notification.userInfo?["controller"] as? UInt8,
              let value = notification.userInfo?["value"] as? UInt8,
              let channel = notification.userInfo?["channel"] as? UInt8 else {
            return
        }

        let message = MIDIMessage(
            type: .controlChange,
            channel: channel,
            data1: controller,
            data2: value
        )

        if let song = await findSongForTrigger(message: message, context: context) {
            await loadSong(song, triggeredBy: message)
        }
    }

    private func handleNoteOn(notification: Notification) async {
        guard isEnabled, let context = modelContext else { return }

        guard let note = notification.userInfo?["note"] as? UInt8,
              let velocity = notification.userInfo?["velocity"] as? UInt8,
              let channel = notification.userInfo?["channel"] as? UInt8 else {
            return
        }

        let message = MIDIMessage(
            type: .noteOn,
            channel: channel,
            data1: note,
            data2: velocity
        )

        if let song = await findSongForTrigger(message: message, context: context) {
            await loadSong(song, triggeredBy: message)
        }
    }

    private func handleMIDIMessage(notification: Notification) async {
        guard let message = notification.userInfo?["message"] as? MIDIMessage else {
            return
        }

        // Store recent messages for combination triggers
        recentMessages.append(message)
        // Keep only messages within window
        let cutoff = Date().addingTimeInterval(-combinationWindow)
        recentMessages = recentMessages.filter { $0.timestamp > cutoff }

        // Learn mode handling
        if isLearning, let song = learningForSong {
            await handleLearnMode(message: message, song: song)
        }
    }

    // MARK: - Song Lookup

    private func findSongForTrigger(message: MIDIMessage, context: ModelContext) async -> Song? {
        // Fetch all songs
        let descriptor = FetchDescriptor<Song>()
        guard let songs = try? context.fetch(descriptor) else {
            return nil
        }

        // Find song with matching trigger
        for song in songs {
            let triggers = song.midiTriggers

            for trigger in triggers where trigger.enabled {
                if trigger.matches(message: message) {
                    // Check conditional requirements
                    if let requiresSet = trigger.requiresSet {
                        // TODO: Check if song is in required set
                        // For now, skip conditional triggers
                        continue
                    }

                    return song
                }
            }
        }

        return nil
    }

    // MARK: - Song Loading

    private func loadSong(_ song: Song, triggeredBy message: MIDIMessage) async {
        print("🎵 MIDI trigger: Loading '\(song.title)'")

        lastTriggeredSong = song
        lastTriggerTime = Date()
        lastTriggerMessage = message

        // Visual feedback
        await showTriggerFeedback(song: song, message: message)

        // Post notification for app to handle
        NotificationCenter.default.post(
            name: .midiTriggeredSongLoad,
            object: nil,
            userInfo: [
                "song": song,
                "message": message
            ]
        )

        // Send MIDI feedback if configured
        if song.midiFeedback.enabled {
            await sendMIDIFeedback(for: song)
        }
    }

    private func showTriggerFeedback(song: Song, message: MIDIMessage) async {
        triggerFeedbackMessage = "🎵 \(song.title)"
        showTriggerFlash = true

        // Auto-hide after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showTriggerFlash = false
        }
    }

    private func sendMIDIFeedback(for song: Song) async {
        let feedback = song.midiFeedback
        let midiManager = MIDIManager.shared

        // Send program change
        if feedback.sendProgramChange,
           let programNumber = song.midiTriggers.first?.programNumber {
            midiManager.sendProgramChange(
                program: programNumber,
                channel: feedback.programChangeChannel
            )
        }

        // Send key as MIDI note
        if feedback.sendKeyAsNote,
           let key = song.currentKey {
            if let noteNumber = keyToMIDINote(key) {
                midiManager.sendNoteOn(
                    note: noteNumber,
                    velocity: 100,
                    channel: feedback.keyNoteChannel
                )
            }
        }

        // Send custom CC
        if feedback.sendCustomCC {
            midiManager.sendControlChange(
                controller: feedback.customCCNumber,
                value: feedback.customCCValue,
                channel: feedback.programChangeChannel
            )
        }
    }

    // MARK: - Learn Mode

    func startLearning(for song: Song, callback: @escaping (MIDITrigger) -> Void) {
        isLearning = true
        learningForSong = song
        learnCallback = callback
        print("🎓 MIDI Learn mode active for '\(song.title)'")
    }

    func stopLearning() {
        isLearning = false
        learningForSong = nil
        learnCallback = nil
        print("🎓 MIDI Learn mode ended")
    }

    private func handleLearnMode(message: MIDIMessage, song: Song) async {
        // Only learn from specific message types
        guard message.type == .programChange ||
              message.type == .controlChange ||
              message.type == .noteOn else {
            return
        }

        print("🎓 Learned MIDI trigger: \(message.description)")

        // Create trigger from message
        var trigger: MIDITrigger?

        switch message.type {
        case .programChange:
            trigger = MIDITrigger(
                type: .programChange,
                channel: message.channel,
                programNumber: message.data1
            )

        case .controlChange:
            trigger = MIDITrigger(
                type: .controlChange,
                channel: message.channel,
                controllerNumber: message.data1,
                controllerValue: message.data2
            )

        case .noteOn:
            trigger = MIDITrigger(
                type: .noteOn,
                channel: message.channel,
                noteNumber: message.data1,
                noteVelocity: message.data2
            )

        default:
            break
        }

        if let trigger = trigger {
            learnCallback?(trigger)
            stopLearning()
        }
    }

    // MARK: - Mapping Presets

    func applyMappingPreset(
        _ preset: MIDIMappingPreset,
        to songs: [Song],
        channel: UInt8 = 1
    ) {
        switch preset {
        case .sequential:
            applySequentialMapping(to: songs, channel: channel)

        case .byKey:
            applyKeyBasedMapping(to: songs, channel: channel)

        case .byTempo:
            applyTempoBasedMapping(to: songs, channel: channel)

        case .bySetList:
            applySetListMapping(to: songs, channel: channel)

        case .custom:
            // No automatic mapping
            break
        }
    }

    private func applySequentialMapping(to songs: [Song], channel: UInt8) {
        for (index, song) in songs.enumerated() where index < 128 {
            let trigger = MIDITrigger(
                type: .programChange,
                channel: channel,
                programNumber: UInt8(index)
            )
            song.midiTriggers = [trigger]
        }

        print("✅ Applied sequential MIDI mapping to \(songs.count) songs")
    }

    private func applyKeyBasedMapping(to songs: [Song], channel: UInt8) {
        let keyGroups: [String: UInt8] = [
            "C": 0, "C#": 12, "Db": 12,
            "D": 24, "D#": 36, "Eb": 36,
            "E": 48,
            "F": 60, "F#": 72, "Gb": 72,
            "G": 84, "G#": 96, "Ab": 96,
            "A": 108, "A#": 120, "Bb": 120,
            "B": 12
        ]

        var keyCounters: [String: UInt8] = [:]

        for song in songs {
            guard let key = song.currentKey else { continue }

            let baseKey = key.prefix(while: { $0.isLetter || $0 == "#" || $0 == "b" })
            let keyStr = String(baseKey)

            guard let basePC = keyGroups[keyStr] else { continue }

            let offset = keyCounters[keyStr, default: 0]
            let programNumber = basePC + offset

            guard programNumber < 128 else { continue }

            let trigger = MIDITrigger(
                type: .programChange,
                channel: channel,
                programNumber: programNumber
            )
            song.midiTriggers = [trigger]

            keyCounters[keyStr] = offset + 1
        }

        print("✅ Applied key-based MIDI mapping to \(songs.count) songs")
    }

    private func applyTempoBasedMapping(to songs: [Song], channel: UInt8) {
        let tempoGroups: [ClosedRange<Int>: UInt8] = [
            0...60: 0,      // Very Slow
            61...80: 20,    // Slow
            81...100: 40,   // Medium Slow
            101...120: 60,  // Medium
            121...140: 80,  // Medium Fast
            141...160: 100, // Fast
            161...200: 120  // Very Fast
        ]

        var groupCounters: [UInt8: UInt8] = [:]

        for song in songs {
            guard let tempo = song.tempo else { continue }

            var basePC: UInt8 = 0
            for (range, pc) in tempoGroups {
                if range.contains(tempo) {
                    basePC = pc
                    break
                }
            }

            let offset = groupCounters[basePC, default: 0]
            let programNumber = basePC + offset

            guard programNumber < 128 else { continue }

            let trigger = MIDITrigger(
                type: .programChange,
                channel: channel,
                programNumber: programNumber
            )
            song.midiTriggers = [trigger]

            groupCounters[basePC] = offset + 1
        }

        print("✅ Applied tempo-based MIDI mapping to \(songs.count) songs")
    }

    private func applySetListMapping(to songs: [Song], channel: UInt8) {
        // Same as sequential for now
        applySequentialMapping(to: songs, channel: channel)
    }

    // MARK: - Utilities

    private func keyToMIDINote(_ key: String) -> UInt8? {
        let noteMap: [String: UInt8] = [
            "C": 60, "C#": 61, "Db": 61,
            "D": 62, "D#": 63, "Eb": 63,
            "E": 64,
            "F": 65, "F#": 66, "Gb": 66,
            "G": 67, "G#": 68, "Ab": 68,
            "A": 69, "A#": 70, "Bb": 70,
            "B": 71
        ]

        let baseKey = key.prefix(while: { $0.isLetter || $0 == "#" || $0 == "b" })
        return noteMap[String(baseKey)]
    }

    // MARK: - Settings

    func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "midiSongLoaderEnabled")
    }

    func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "midiSongLoaderEnabled")
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let midiTriggeredSongLoad = Notification.Name("midiTriggeredSongLoad")
}
