//
//  MIDIControlManager.swift
//  Lyra
//
//  Service for managing MIDI control mappings and executing actions
//

import Foundation
import SwiftUI
import Observation

/// Notification names for MIDI control events
extension Notification.Name {
    static let midiActionExecuted = Notification.Name("midiActionExecuted")
    static let midiLearnModeChanged = Notification.Name("midiLearnModeChanged")
    static let midiMappingAdded = Notification.Name("midiMappingAdded")
    static let midiMappingRemoved = Notification.Name("midiMappingRemoved")
    static let midiSceneExecuted = Notification.Name("midiSceneExecuted")
}

/// MIDI control manager for handling app function control via MIDI
@Observable
class MIDIControlManager {
    static let shared = MIDIControlManager()

    // MARK: - Properties

    /// Active control mappings
    private(set) var mappings: [MIDIControlMapping] = []

    /// Available mapping presets
    private(set) var presets: [MIDIControlMappingPreset] = []

    /// Active scenes library
    private(set) var sceneLibrary: MIDISceneLibrary = MIDISceneLibrary()

    /// Learn mode state
    private(set) var isLearning: Bool = false
    private(set) var learningAction: MIDIActionType?
    private(set) var learnedSource: MIDIControlSource?

    /// Last received MIDI message (for learning)
    private(set) var lastMessage: MIDIMessage?

    /// Activity tracking
    private(set) var lastActionTime: Date?
    private(set) var actionHistory: [(date: Date, action: MIDIActionType, value: Double?)] = []
    private let maxHistoryItems = 100

    /// Feedback state
    private(set) var feedbackEnabled: Bool = true
    private(set) var lastFeedbackSent: Date?

    // MARK: - Initialization

    private init() {
        loadMappings()
        loadPresets()
        loadScenes()
        setupNotificationObservers()
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        // Listen for MIDI messages
        NotificationCenter.default.addObserver(
            forName: .midiMessageReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let message = notification.userInfo?["message"] as? MIDIMessage else { return }
            self?.handleMIDIMessage(message)
        }
    }

    // MARK: - MIDI Message Handling

    private func handleMIDIMessage(_ message: MIDIMessage) {
        lastMessage = message

        // If in learn mode, capture the source
        if isLearning {
            captureLearnedSource(from: message)
            return
        }

        // Find matching mappings and execute actions
        let matchingMappings = mappings.filter { mapping in
            mapping.enabled && mapping.source.matches(message)
        }

        for mapping in matchingMappings {
            executeMapping(mapping, with: message)
        }
    }

    private func executeMapping(_ mapping: MIDIControlMapping, with message: MIDIMessage) {
        // Get the value from the message
        let value: Double?

        if mapping.action.acceptsContinuousValue {
            // Map continuous value
            let midiValue = message.value ?? 0
            value = mapping.mapValue(midiValue)
        } else if mapping.action.isToggle {
            // Handle toggle
            let midiValue = message.value ?? 0
            value = mapping.shouldToggle(midiValue) == true ? 1.0 : 0.0
        } else {
            // Trigger action (no value)
            value = nil
        }

        // Execute the action
        executeAction(mapping.action, value: value)

        // Record in history
        recordAction(mapping.action, value: value)

        // Send feedback if enabled
        if feedbackEnabled {
            sendFeedback(for: mapping, value: message.value)
        }
    }

    // MARK: - Action Execution

    func executeAction(_ action: MIDIActionType, value: Double? = nil) {
        let userInfo: [String: Any] = [
            "action": action,
            "value": value as Any
        ]

        NotificationCenter.default.post(
            name: .midiActionExecuted,
            object: self,
            userInfo: userInfo
        )

        lastActionTime = Date()
    }

    private func recordAction(_ action: MIDIActionType, value: Double?) {
        actionHistory.append((date: Date(), action: action, value: value))

        // Keep history bounded
        if actionHistory.count > maxHistoryItems {
            actionHistory.removeFirst(actionHistory.count - maxHistoryItems)
        }
    }

    // MARK: - Learn Mode

    func startLearning(for action: MIDIActionType) {
        isLearning = true
        learningAction = action
        learnedSource = nil

        NotificationCenter.default.post(
            name: .midiLearnModeChanged,
            object: self,
            userInfo: ["isLearning": true, "action": action]
        )
    }

    func stopLearning() {
        isLearning = false
        learningAction = nil
        learnedSource = nil

        NotificationCenter.default.post(
            name: .midiLearnModeChanged,
            object: self,
            userInfo: ["isLearning": false]
        )
    }

    private func captureLearnedSource(from message: MIDIMessage) {
        guard let action = learningAction else { return }

        // Create source from message
        let source: MIDIControlSource

        switch message.type {
        case .controlChange:
            guard let controller = message.controller else { return }
            source = .controlChange(controller: controller, channel: message.channel)

        case .noteOn, .noteOff:
            guard let note = message.note else { return }
            source = .note(note: note, channel: message.channel, velocitySensitive: true)

        case .pitchBend:
            source = .pitchBend(channel: message.channel)

        case .aftertouch:
            source = .aftertouch(channel: message.channel)

        case .programChange:
            source = .programChange(channel: message.channel)

        default:
            return
        }

        learnedSource = source

        // Auto-create mapping
        let mapping = createMapping(source: source, action: action)
        addMapping(mapping)

        // Exit learn mode
        stopLearning()
    }

    private func createMapping(source: MIDIControlSource, action: MIDIActionType) -> MIDIControlMapping {
        // Create a smart default mapping based on the action and source
        let name = "\(source.displayName) → \(action.displayName)"

        var minOutput = 0.0
        var maxOutput = 1.0
        var curve = MIDIValueCurve.linear

        // Smart defaults based on action type
        switch action {
        case .setTranspose:
            minOutput = -12.0
            maxOutput = 12.0
        case .setAutoscrollSpeed:
            minOutput = 0.0
            maxOutput = 2.0
        case .setMetronomeVolume, .setBackingTrackVolume, .setMasterVolume:
            curve = .exponential // Exponential for volume feels more natural
        case .setBrightness:
            curve = .sCurve // S-curve for brightness feels smooth
        default:
            break
        }

        return MIDIControlMapping(
            name: name,
            source: source,
            action: action,
            minOutput: minOutput,
            maxOutput: maxOutput,
            curve: curve
        )
    }

    // MARK: - Mapping Management

    func addMapping(_ mapping: MIDIControlMapping) {
        mappings.append(mapping)
        saveMappings()

        NotificationCenter.default.post(
            name: .midiMappingAdded,
            object: self,
            userInfo: ["mapping": mapping]
        )
    }

    func removeMapping(_ mapping: MIDIControlMapping) {
        mappings.removeAll { $0.id == mapping.id }
        saveMappings()

        NotificationCenter.default.post(
            name: .midiMappingRemoved,
            object: self,
            userInfo: ["mapping": mapping]
        )
    }

    func updateMapping(_ mapping: MIDIControlMapping) {
        if let index = mappings.firstIndex(where: { $0.id == mapping.id }) {
            var updatedMapping = mapping
            updatedMapping.dateModified = Date()
            mappings[index] = updatedMapping
            saveMappings()
        }
    }

    func removeAllMappings() {
        mappings.removeAll()
        saveMappings()
    }

    func applyPreset(_ preset: MIDIControlMappingPreset) {
        mappings.append(contentsOf: preset.mappings)
        saveMappings()
    }

    // MARK: - Preset Management

    func addPreset(_ preset: MIDIControlMappingPreset) {
        presets.append(preset)
        savePresets()
    }

    func removePreset(_ preset: MIDIControlMappingPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }

    func createPresetFromCurrentMappings(name: String, description: String) -> MIDIControlMappingPreset {
        let preset = MIDIControlMappingPreset(
            name: name,
            description: description,
            mappings: mappings
        )
        addPreset(preset)
        return preset
    }

    // MARK: - Scene Management

    func addScene(_ scene: MIDIScene, to categoryID: UUID? = nil) {
        sceneLibrary.addScene(scene, to: categoryID)
        saveScenes()
    }

    func removeScene(_ scene: MIDIScene) {
        sceneLibrary.removeScene(scene.id)
        saveScenes()
    }

    func updateScene(_ scene: MIDIScene) {
        if let index = sceneLibrary.scenes.firstIndex(where: { $0.id == scene.id }) {
            var updatedScene = scene
            updatedScene.dateModified = Date()
            sceneLibrary.scenes[index] = updatedScene
            saveScenes()
        }
    }

    func executeScene(_ scene: MIDIScene) async {
        guard scene.enabled else { return }

        for message in scene.messages where message.enabled {
            // Send the MIDI message
            sendSceneMessage(message)

            // Wait for delay
            let delay = scene.delay + message.delayAfter
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        NotificationCenter.default.post(
            name: .midiSceneExecuted,
            object: self,
            userInfo: ["scene": scene]
        )
    }

    private func sendSceneMessage(_ message: MIDISceneMessage) {
        let manager = MIDIManager.shared

        switch message.type {
        case .programChange:
            if let program = message.data.first {
                manager.sendProgramChange(program: Int(program), channel: message.channel)
            }

        case .controlChange:
            if message.data.count >= 2 {
                manager.sendControlChange(
                    controller: Int(message.data[0]),
                    value: Int(message.data[1]),
                    channel: message.channel
                )
            }

        case .noteOn:
            if message.data.count >= 2 {
                manager.sendNoteOn(
                    note: Int(message.data[0]),
                    velocity: Int(message.data[1]),
                    channel: message.channel
                )
            }

        case .noteOff:
            if let note = message.data.first {
                manager.sendNoteOff(note: Int(note), channel: message.channel)
            }

        case .sysex:
            manager.sendSysEx(message.data)

        case .pitchBend, .aftertouch:
            // TODO: Implement if needed
            break
        }
    }

    // MARK: - Feedback

    func sendFeedback(for mapping: MIDIControlMapping, value: Int?) {
        guard let value = value else { return }

        switch mapping.source {
        case .controlChange(let controller, let channel):
            let outputChannel = channel == 0 ? 1 : channel
            MIDIManager.shared.sendControlChange(
                controller: controller,
                value: value,
                channel: outputChannel
            )

        case .note(let note, let channel, _):
            let outputChannel = channel == 0 ? 1 : channel
            if value > 0 {
                MIDIManager.shared.sendNoteOn(note: note, velocity: value, channel: outputChannel)
            } else {
                MIDIManager.shared.sendNoteOff(note: note, channel: outputChannel)
            }

        default:
            break
        }

        lastFeedbackSent = Date()
    }

    // MARK: - Persistence

    private func loadMappings() {
        if let data = UserDefaults.standard.data(forKey: "midiControlMappings"),
           let decoded = try? JSONDecoder().decode([MIDIControlMapping].self, from: data) {
            mappings = decoded
        }
    }

    private func saveMappings() {
        if let encoded = try? JSONEncoder().encode(mappings) {
            UserDefaults.standard.set(encoded, forKey: "midiControlMappings")
        }
    }

    private func loadPresets() {
        // Load built-in presets
        presets = [
            .standardCCPreset,
            .expressionPedalPreset,
            .footswitchPreset
        ]

        // Load custom presets
        if let data = UserDefaults.standard.data(forKey: "midiControlPresets"),
           let decoded = try? JSONDecoder().decode([MIDIControlMappingPreset].self, from: data) {
            presets.append(contentsOf: decoded.filter { !$0.isBuiltIn })
        }
    }

    private func savePresets() {
        let customPresets = presets.filter { !$0.isBuiltIn }
        if let encoded = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(encoded, forKey: "midiControlPresets")
        }
    }

    private func loadScenes() {
        if let data = UserDefaults.standard.data(forKey: "midiSceneLibrary"),
           let decoded = try? JSONDecoder().decode(MIDISceneLibrary.self, from: data) {
            sceneLibrary = decoded
        } else {
            // Initialize with default categories
            sceneLibrary.categories = [
                .lighting,
                .effects,
                .patches,
                .custom
            ]
        }
    }

    private func saveScenes() {
        if let encoded = try? JSONEncoder().encode(sceneLibrary) {
            UserDefaults.standard.set(encoded, forKey: "midiSceneLibrary")
        }
    }

    // MARK: - Utilities

    func clearHistory() {
        actionHistory.removeAll()
    }

    func mappings(for action: MIDIActionType) -> [MIDIControlMapping] {
        mappings.filter { $0.action == action }
    }

    func hasMapping(for source: MIDIControlSource) -> Bool {
        mappings.contains { $0.source == source }
    }

    var enabledMappingsCount: Int {
        mappings.filter { $0.enabled }.count
    }

    var activeScenesCount: Int {
        sceneLibrary.scenes.filter { $0.enabled }.count
    }
}
