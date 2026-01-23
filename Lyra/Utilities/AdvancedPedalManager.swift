//
//  AdvancedPedalManager.swift
//  Lyra
//
//  Advanced pedal manager with multi-pedal, expression, and gesture support
//

import Foundation
import SwiftUI
import AVFoundation
import Observation

@Observable
class AdvancedPedalManager {
    static let shared = AdvancedPedalManager()

    // MARK: - Properties

    /// Connected pedal devices
    private(set) var connectedDevices: [PedalDevice] = []

    /// Active pedal profile
    var activeProfile: AdvancedPedalProfile?

    /// Saved profiles
    private(set) var savedProfiles: [AdvancedPedalProfile] = []

    /// Current pedal mode
    var currentMode: PedalMode = .performance {
        didSet {
            NotificationCenter.default.post(name: .pedalModeChanged, object: self)
        }
    }

    /// Multi-pedal setup
    var multiPedalSetup: MultiPedalSetup?

    /// Press state tracking for gestures
    private var pressStates: [Int: PedalPressState] = [:]

    /// Sequence tracking
    private var sequenceBuffer: [Int] = []
    private var lastSequenceTime: Date?

    /// Expression pedal state
    private var expressionValue: Double = 0.0
    private var smoothedExpressionValue: Double = 0.0

    /// Audio feedback player
    private var audioPlayer: AVAudioPlayer?

    /// Visual feedback state
    var lastPressedPedal: Int?
    var feedbackTrigger: UUID = UUID() // For triggering UI updates

    /// Enabled state
    var isEnabled: Bool = true

    /// Test mode
    var testMode: Bool = false

    // MARK: - Action Callbacks

    var onAction: ((AdvancedPedalAction) -> Void)?
    var onExpressionValueChanged: ((Double) -> Void)?
    var onModeChanged: ((PedalMode) -> Void)?

    // MARK: - Timers

    private var longPressTimer: Timer?
    private var sequenceTimer: Timer?

    // MARK: - Initialization

    private init() {
        loadSettings()
        loadSavedProfiles()
        setupAudioSession()
    }

    // MARK: - Device Management

    func addDevice(_ device: PedalDevice) {
        if !connectedDevices.contains(where: { $0.id == device.id }) {
            connectedDevices.append(device)
            saveSettings()

            NotificationCenter.default.post(
                name: .pedalDeviceConnected,
                object: self,
                userInfo: ["device": device]
            )
        }
    }

    func removeDevice(_ deviceId: UUID) {
        connectedDevices.removeAll { $0.id == deviceId }
        saveSettings()

        NotificationCenter.default.post(
            name: .pedalDeviceDisconnected,
            object: self,
            userInfo: ["deviceId": deviceId.uuidString]
        )
    }

    func updateDevice(_ device: PedalDevice) {
        if let index = connectedDevices.firstIndex(where: { $0.id == device.id }) {
            connectedDevices[index] = device
            saveSettings()
        }
    }

    /// Auto-detect pedal model from device name
    func detectPedalModel(fromName name: String) -> PedalModel {
        let lowercaseName = name.lowercased()

        for model in PedalModel.allCases {
            for keyword in model.detectionKeywords {
                if lowercaseName.contains(keyword.lowercased()) {
                    return model
                }
            }
        }

        return .generic
    }

    // MARK: - Pedal Input Handling

    func handleKeyPress(_ key: String, pedalIndex: Int = 0) {
        guard isEnabled else { return }

        // Update press state
        if pressStates[pedalIndex] == nil {
            pressStates[pedalIndex] = PedalPressState(
                pedalIndex: pedalIndex,
                pressStartTime: Date(),
                lastPressTime: nil,
                pressCount: 0,
                isHeld: false
            )
        }

        pressStates[pedalIndex]?.recordPress()

        // Track for sequences
        addToSequence(pedalIndex)

        // Start long press timer
        startLongPressTimer(for: pedalIndex)

        // Update visual state
        lastPressedPedal = pedalIndex
        feedbackTrigger = UUID()

        // Test mode - just record the press
        if testMode {
            return
        }

        // Check for simultaneous presses (slight delay to catch multi-pedal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.processPedalPress(pedalIndex)
        }
    }

    func handleKeyRelease(_ key: String, pedalIndex: Int = 0) {
        pressStates[pedalIndex]?.recordRelease()
        longPressTimer?.invalidate()
    }

    private func processPedalPress(_ pedalIndex: Int) {
        guard let state = pressStates[pedalIndex],
              let profile = activeProfile else { return }

        // Get gestures for this pedal
        guard let gestures = profile.pedalMappings[pedalIndex] else { return }

        // Find matching gesture
        for gesture in gestures {
            if matchesGesture(gesture, state: state, pedalIndex: pedalIndex) {
                executeAction(gesture.action)
                triggerFeedback()
                break
            }
        }
    }

    private func matchesGesture(_ gesture: PedalGesture, state: PedalPressState, pedalIndex: Int) -> Bool {
        // Check press type
        if gesture.pressType != state.pressType {
            return false
        }

        // Check simultaneous requirement
        if let simultaneous = gesture.requiresSimultaneous {
            for otherPedal in simultaneous {
                if otherPedal == pedalIndex { continue }
                guard let otherState = pressStates[otherPedal],
                      otherState.isHeld else {
                    return false
                }
            }
        }

        // Check sequence requirement
        if let sequence = gesture.sequence {
            return sequenceBuffer.suffix(sequence.count) == sequence
        }

        return true
    }

    // MARK: - Long Press Handling

    private func startLongPressTimer(for pedalIndex: Int) {
        longPressTimer?.invalidate()

        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.handleLongPress(pedalIndex)
        }
    }

    private func handleLongPress(_ pedalIndex: Int) {
        guard let profile = activeProfile,
              let gestures = profile.pedalMappings[pedalIndex] else { return }

        // Find long press gesture
        for gesture in gestures where gesture.pressType == .longPress {
            if matchesGesture(gesture, state: pressStates[pedalIndex]!, pedalIndex: pedalIndex) {
                executeAction(gesture.action)
                triggerFeedback()
                break
            }
        }
    }

    // MARK: - Sequence Handling

    private func addToSequence(_ pedalIndex: Int) {
        let now = Date()

        // Reset sequence if too much time passed
        if let lastTime = lastSequenceTime, now.timeIntervalSince(lastTime) > 1.0 {
            sequenceBuffer.removeAll()
        }

        sequenceBuffer.append(pedalIndex)
        lastSequenceTime = now

        // Keep only last 10 presses
        if sequenceBuffer.count > 10 {
            sequenceBuffer.removeFirst()
        }

        // Reset after 2 seconds
        sequenceTimer?.invalidate()
        sequenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.sequenceBuffer.removeAll()
        }
    }

    // MARK: - Expression Pedal

    func handleExpressionValue(_ value: Double, deviceId: UUID) {
        guard let config = activeProfile?.expressionConfig,
              config.isEnabled else { return }

        // Update device state
        if let index = connectedDevices.firstIndex(where: { $0.id == deviceId }) {
            connectedDevices[index].expressionValue = value
        }

        // Apply curve
        let curvedValue = config.curve.apply(value: value)

        // Apply smoothing
        let smoothingFactor = config.smoothing
        smoothedExpressionValue = smoothedExpressionValue * smoothingFactor + curvedValue * (1 - smoothingFactor)

        // Map to parameter range
        let mappedValue = config.minValue + (config.maxValue - config.minValue) * smoothedExpressionValue

        // Trigger callback
        onExpressionValueChanged?(mappedValue)

        NotificationCenter.default.post(
            name: .expressionPedalValueChanged,
            object: self,
            userInfo: ["value": mappedValue, "target": config.targetParameter]
        )
    }

    // MARK: - Action Execution

    func executeAction(_ action: AdvancedPedalAction) {
        // Special actions handled internally
        switch action {
        case .switchMode:
            cyclePedalMode()
            return
        case .switchProfile:
            cycleProfile()
            return
        case .none:
            return
        default:
            break
        }

        // Trigger callback
        onAction?(action)

        NotificationCenter.default.post(
            name: .pedalPressed,
            object: self,
            userInfo: ["action": action]
        )
    }

    private func cyclePedalMode() {
        let allModes = PedalMode.allCases
        if let currentIndex = allModes.firstIndex(of: currentMode) {
            let nextIndex = (currentIndex + 1) % allModes.count
            currentMode = allModes[nextIndex]
            onModeChanged?(currentMode)

            // Load profile for new mode if available
            if let modeProfile = savedProfiles.first(where: { $0.mode == currentMode }) {
                activeProfile = modeProfile
            }
        }
    }

    private func cycleProfile() {
        guard !savedProfiles.isEmpty else { return }

        if let currentProfile = activeProfile,
           let currentIndex = savedProfiles.firstIndex(where: { $0.id == currentProfile.id }) {
            let nextIndex = (currentIndex + 1) % savedProfiles.count
            activeProfile = savedProfiles[nextIndex]
        } else {
            activeProfile = savedProfiles.first
        }

        NotificationCenter.default.post(name: .pedalProfileChanged, object: self)
    }

    // MARK: - Feedback

    private func triggerFeedback() {
        guard let profile = activeProfile else { return }

        // Visual feedback (handled by UI observing feedbackTrigger)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Audio feedback
        if profile.audioFeedbackEnabled {
            playFeedbackSound(profile.audioFeedbackSound)
        }
    }

    private func playFeedbackSound(_ sound: FeedbackSound) {
        guard let filename = sound.filename else { return }

        // In a real app, you'd load the sound file
        // For now, use system sounds
        switch sound {
        case .click, .tap:
            AudioServicesPlaySystemSound(1104) // Keyboard click
        case .beep:
            AudioServicesPlaySystemSound(1052) // Tink
        case .none:
            break
        }
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Profile Management

    func saveProfile(_ profile: AdvancedPedalProfile) {
        if let index = savedProfiles.firstIndex(where: { $0.id == profile.id }) {
            savedProfiles[index] = profile
        } else {
            savedProfiles.append(profile)
        }
        saveSavedProfiles()
    }

    func deleteProfile(_ profileId: UUID) {
        savedProfiles.removeAll { $0.id == profileId }
        saveSavedProfiles()

        if activeProfile?.id == profileId {
            activeProfile = savedProfiles.first
        }
    }

    func activateProfile(_ profileId: UUID) {
        if let profile = savedProfiles.first(where: { $0.id == profileId }) {
            activeProfile = profile
            currentMode = profile.mode
            saveSettings()
        }
    }

    // MARK: - Built-in Profiles

    func createBuiltInProfiles() -> [AdvancedPedalProfile] {
        var profiles: [AdvancedPedalProfile] = []

        // Performance Profile
        var performanceProfile = AdvancedPedalProfile(
            name: "Performance",
            description: "Live performance with set navigation",
            mode: .performance,
            isBuiltIn: true
        )
        performanceProfile.pedalMappings = [
            0: [PedalGesture(pressType: .singlePress, action: .previousSong)],
            1: [PedalGesture(pressType: .singlePress, action: .nextSong)],
            2: [PedalGesture(pressType: .singlePress, action: .scrollDown)],
            3: [PedalGesture(pressType: .singlePress, action: .scrollUp)],
            0: [PedalGesture(pressType: .longPress, action: .jumpToTop)],
            1: [PedalGesture(pressType: .longPress, action: .jumpToBottom)]
        ]
        profiles.append(performanceProfile)

        // Practice Profile
        var practiceProfile = AdvancedPedalProfile(
            name: "Practice",
            description: "Practice with section looping",
            mode: .practice,
            isBuiltIn: true
        )
        practiceProfile.pedalMappings = [
            0: [PedalGesture(pressType: .singlePress, action: .previousSection)],
            1: [PedalGesture(pressType: .singlePress, action: .nextSection)],
            2: [PedalGesture(pressType: .singlePress, action: .loopSection)],
            3: [PedalGesture(pressType: .singlePress, action: .toggleMetronome)]
        ]
        profiles.append(practiceProfile)

        // Annotation Profile
        var annotationProfile = AdvancedPedalProfile(
            name: "Annotation",
            description: "Quick note-taking during performance",
            mode: .annotation,
            isBuiltIn: true
        )
        annotationProfile.pedalMappings = [
            0: [PedalGesture(pressType: .singlePress, action: .addStickyNote)],
            1: [PedalGesture(pressType: .singlePress, action: .toggleAnnotations)],
            2: [PedalGesture(pressType: .singlePress, action: .scrollDown)],
            3: [PedalGesture(pressType: .singlePress, action: .scrollUp)]
        ]
        profiles.append(annotationProfile)

        return profiles
    }

    // MARK: - Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard

        isEnabled = defaults.bool(forKey: "advancedPedal.isEnabled")
        if !defaults.bool(forKey: "advancedPedal.isEnabled.set") {
            isEnabled = true
            defaults.set(true, forKey: "advancedPedal.isEnabled.set")
        }

        // Load devices
        if let devicesData = defaults.data(forKey: "advancedPedal.devices"),
           let devices = try? JSONDecoder().decode([PedalDevice].self, from: devicesData) {
            connectedDevices = devices
        }

        // Load multi-pedal setup
        if let setupData = defaults.data(forKey: "advancedPedal.multiPedalSetup"),
           let setup = try? JSONDecoder().decode(MultiPedalSetup.self, from: setupData) {
            multiPedalSetup = setup
        }

        // Load active profile
        if let profileData = defaults.data(forKey: "advancedPedal.activeProfile"),
           let profile = try? JSONDecoder().decode(AdvancedPedalProfile.self, from: profileData) {
            activeProfile = profile
            currentMode = profile.mode
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(isEnabled, forKey: "advancedPedal.isEnabled")

        // Save devices
        if let devicesData = try? JSONEncoder().encode(connectedDevices) {
            defaults.set(devicesData, forKey: "advancedPedal.devices")
        }

        // Save multi-pedal setup
        if let setup = multiPedalSetup,
           let setupData = try? JSONEncoder().encode(setup) {
            defaults.set(setupData, forKey: "advancedPedal.multiPedalSetup")
        }

        // Save active profile
        if let profile = activeProfile,
           let profileData = try? JSONEncoder().encode(profile) {
            defaults.set(profileData, forKey: "advancedPedal.activeProfile")
        }
    }

    private func loadSavedProfiles() {
        // Load built-in profiles
        savedProfiles = createBuiltInProfiles()

        // Load custom profiles
        let defaults = UserDefaults.standard
        if let profilesData = defaults.data(forKey: "advancedPedal.savedProfiles"),
           let customProfiles = try? JSONDecoder().decode([AdvancedPedalProfile].self, from: profilesData) {
            savedProfiles.append(contentsOf: customProfiles)
        }

        // Set first profile as active if none set
        if activeProfile == nil {
            activeProfile = savedProfiles.first
        }
    }

    private func saveSavedProfiles() {
        let customProfiles = savedProfiles.filter { !$0.isBuiltIn }

        let defaults = UserDefaults.standard
        if let profilesData = try? JSONEncoder().encode(customProfiles) {
            defaults.set(profilesData, forKey: "advancedPedal.savedProfiles")
        }
    }

    // MARK: - Utilities

    var hasExpressionPedal: Bool {
        connectedDevices.contains { $0.hasExpressionPedal }
    }

    var totalPedals: Int {
        connectedDevices.reduce(0) { $0 + $1.model.numberOfPedals }
    }

    func getPedalAtIndex(_ index: Int) -> (device: PedalDevice, localIndex: Int)? {
        var currentIndex = 0

        for device in connectedDevices.sorted(by: { $0.priority < $1.priority }) {
            let pedalCount = device.model.numberOfPedals
            if index < currentIndex + pedalCount {
                return (device, index - currentIndex)
            }
            currentIndex += pedalCount
        }

        return nil
    }
}
