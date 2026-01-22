//
//  PerformanceModeManager.swift
//  Lyra
//
//  Manager for performance mode with session tracking and state management
//

import Foundation
import SwiftUI
import UIKit

@Observable
class PerformanceModeManager {
    // MARK: - State Properties

    var isActive: Bool = false
    var currentSession: PerformanceSession?
    var currentSongIndex: Int = 0
    var performedSongIndices: Set<Int> = []
    var showControls: Bool = true
    var showSetList: Bool = false
    var elapsedTime: TimeInterval = 0

    // Settings
    var keepScreenAwake: Bool = true
    var lockOrientation: Bool = true
    var autoHideControls: Bool = true
    var autoHideDelay: TimeInterval = 3.0
    var enableDoNotDisturb: Bool = true

    // Active preset
    var activePreset: PerformancePreset?

    // MARK: - Private Properties

    private var originalIdleTimerState: Bool = false
    private var controlsHideTimer: Timer?
    private var sessionTimer: Timer?
    private var sessionStartTime: Date?

    // MARK: - Initialization

    init() {
        loadSettings()
    }

    // MARK: - Performance Session Management

    func startPerformance(set: PerformanceSet, preset: PerformancePreset? = nil) {
        // Create new session
        let session = PerformanceSession(
            performanceSet: set,
            startTime: Date()
        )
        currentSession = session
        sessionStartTime = Date()

        // Apply preset if provided
        if let preset = preset {
            applyPreset(preset)
        }

        // Reset state
        currentSongIndex = 0
        performedSongIndices.removeAll()
        elapsedTime = 0
        showControls = true
        showSetList = false

        // Activate performance mode
        isActive = true

        // Configure device
        configureDeviceForPerformance()

        // Start session timer
        startSessionTimer()

        // Haptic feedback
        HapticManager.shared.impact(.heavy)
    }

    func endPerformance() {
        // Stop session timer
        stopSessionTimer()

        // Update session
        if let session = currentSession {
            session.endTime = Date()
            session.duration = elapsedTime
            session.completedSongCount = performedSongIndices.count

            // Save session to SwiftData (would need context injection)
            // For now, just track in memory
        }

        // Deactivate performance mode
        isActive = false

        // Restore device settings
        restoreDeviceSettings()

        // Clear state
        currentSession = nil
        sessionStartTime = nil
        currentSongIndex = 0
        performedSongIndices.removeAll()
        activePreset = nil

        // Haptic feedback
        HapticManager.shared.notification(.success)
    }

    // MARK: - Navigation

    func goToNextSong(totalSongs: Int) {
        guard currentSongIndex < totalSongs - 1 else { return }
        currentSongIndex += 1
        showControlsBriefly()
        HapticManager.shared.selection()
    }

    func goToPreviousSong() {
        guard currentSongIndex > 0 else { return }
        currentSongIndex -= 1
        showControlsBriefly()
        HapticManager.shared.selection()
    }

    func goToSong(index: Int, totalSongs: Int) {
        guard index >= 0 && index < totalSongs else { return }
        currentSongIndex = index
        showSetList = false
        showControlsBriefly()
        HapticManager.shared.selection()
    }

    func markSongAsPerformed(index: Int) {
        performedSongIndices.insert(index)

        // Auto-advance if this is the current song
        HapticManager.shared.notification(.success)
    }

    func isSongPerformed(index: Int) -> Bool {
        performedSongIndices.contains(index)
    }

    // MARK: - Controls Management

    func showControlsBriefly() {
        showControls = true

        if autoHideControls {
            resetHideTimer()
        }
    }

    func toggleControls() {
        showControls.toggle()

        if showControls && autoHideControls {
            resetHideTimer()
        } else {
            controlsHideTimer?.invalidate()
            controlsHideTimer = nil
        }

        HapticManager.shared.selection()
    }

    func toggleSetList() {
        showSetList.toggle()

        // Show controls when set list is visible
        if showSetList {
            showControls = true
            controlsHideTimer?.invalidate()
        } else if autoHideControls {
            resetHideTimer()
        }

        HapticManager.shared.selection()
    }

    private func resetHideTimer() {
        controlsHideTimer?.invalidate()

        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: autoHideDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // Don't hide if set list is showing
            if !self.showSetList {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.showControls = false
                }
            }
        }
    }

    // MARK: - Preset Management

    func applyPreset(_ preset: PerformancePreset) {
        activePreset = preset

        // Apply preset settings
        // This would interact with metronome, autoscroll, etc.
        // For now, just store the preset

        HapticManager.shared.selection()
    }

    // MARK: - Device Configuration

    private func configureDeviceForPerformance() {
        // Save original state
        originalIdleTimerState = UIApplication.shared.isIdleTimerDisabled

        // Keep screen awake
        if keepScreenAwake {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        // Lock orientation (would need to be handled at app level)
        // For now, just note the setting

        // Enable Do Not Disturb (iOS doesn't allow direct control)
        // User would need to enable manually or via Shortcuts
    }

    private func restoreDeviceSettings() {
        // Restore screen idle timer
        UIApplication.shared.isIdleTimerDisabled = originalIdleTimerState

        // Restore orientation lock
        // Would need app-level handling
    }

    // MARK: - Session Timer

    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.sessionStartTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
        }
    }

    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    // MARK: - Notes

    func addNoteForCurrentSong(_ note: String) {
        guard let session = currentSession else { return }

        // Add note to session
        let songNote = PerformanceSongNote(
            songIndex: currentSongIndex,
            note: note,
            timestamp: Date()
        )
        session.songNotes.append(songNote)
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard

        keepScreenAwake = defaults.bool(forKey: "performanceMode.keepScreenAwake")
        if !defaults.bool(forKey: "performanceMode.keepScreenAwake.set") {
            keepScreenAwake = true
            defaults.set(true, forKey: "performanceMode.keepScreenAwake.set")
        }

        lockOrientation = defaults.bool(forKey: "performanceMode.lockOrientation")
        if !defaults.bool(forKey: "performanceMode.lockOrientation.set") {
            lockOrientation = true
            defaults.set(true, forKey: "performanceMode.lockOrientation.set")
        }

        autoHideControls = defaults.bool(forKey: "performanceMode.autoHideControls")
        if !defaults.bool(forKey: "performanceMode.autoHideControls.set") {
            autoHideControls = true
            defaults.set(true, forKey: "performanceMode.autoHideControls.set")
        }

        autoHideDelay = defaults.double(forKey: "performanceMode.autoHideDelay")
        if autoHideDelay == 0 {
            autoHideDelay = 3.0
        }

        enableDoNotDisturb = defaults.bool(forKey: "performanceMode.enableDoNotDisturb")
        if !defaults.bool(forKey: "performanceMode.enableDoNotDisturb.set") {
            enableDoNotDisturb = true
            defaults.set(true, forKey: "performanceMode.enableDoNotDisturb.set")
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(keepScreenAwake, forKey: "performanceMode.keepScreenAwake")
        defaults.set(lockOrientation, forKey: "performanceMode.lockOrientation")
        defaults.set(autoHideControls, forKey: "performanceMode.autoHideControls")
        defaults.set(autoHideDelay, forKey: "performanceMode.autoHideDelay")
        defaults.set(enableDoNotDisturb, forKey: "performanceMode.enableDoNotDisturb")
    }

    // MARK: - Cleanup

    deinit {
        controlsHideTimer?.invalidate()
        sessionTimer?.invalidate()

        // Restore device settings if still active
        if isActive {
            restoreDeviceSettings()
        }
    }
}

// MARK: - Performance Session Model

@Observable
class PerformanceSession {
    var id: UUID = UUID()
    var performanceSet: PerformanceSet
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval = 0
    var completedSongCount: Int = 0
    var songNotes: [PerformanceSongNote] = []

    init(performanceSet: PerformanceSet, startTime: Date) {
        self.performanceSet = performanceSet
        self.startTime = startTime
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Performance Song Note

struct PerformanceSongNote: Identifiable, Codable {
    var id: UUID = UUID()
    var songIndex: Int
    var note: String
    var timestamp: Date
}

// MARK: - Performance Preset Model

struct PerformancePreset: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var description: String?

    // Feature settings
    var enableAutoscroll: Bool
    var enableMetronome: Bool
    var showAnnotations: Bool
    var enableLowLightMode: Bool
    var lowLightIntensity: Double

    // Display settings
    var fontSize: CGFloat
    var autoHideDelay: TimeInterval

    // Creation date
    var createdAt: Date = Date()

    // Predefined presets
    static var soloPerformance: PerformancePreset {
        PerformancePreset(
            name: "Solo Performance",
            description: "Autoscroll enabled, metronome off, standard visibility",
            enableAutoscroll: true,
            enableMetronome: false,
            showAnnotations: false,
            enableLowLightMode: false,
            lowLightIntensity: 0.7,
            fontSize: 16,
            autoHideDelay: 3.0
        )
    }

    static var withBand: PerformancePreset {
        PerformancePreset(
            name: "With Band",
            description: "Metronome on, manual scrolling, quick controls",
            enableAutoscroll: false,
            enableMetronome: true,
            showAnnotations: false,
            enableLowLightMode: false,
            lowLightIntensity: 0.7,
            fontSize: 18,
            autoHideDelay: 2.0
        )
    }

    static var teaching: PerformancePreset {
        PerformancePreset(
            name: "Teaching",
            description: "Slow autoscroll, annotations visible, larger font",
            enableAutoscroll: true,
            enableMetronome: true,
            showAnnotations: true,
            enableLowLightMode: false,
            lowLightIntensity: 0.7,
            fontSize: 20,
            autoHideDelay: 5.0
        )
    }

    static var nightPerformance: PerformancePreset {
        PerformancePreset(
            name: "Night Performance",
            description: "Low light mode enabled, minimal distractions",
            enableAutoscroll: true,
            enableMetronome: false,
            showAnnotations: false,
            enableLowLightMode: true,
            lowLightIntensity: 0.6,
            fontSize: 18,
            autoHideDelay: 4.0
        )
    }

    static var allPresets: [PerformancePreset] {
        [soloPerformance, withBand, teaching, nightPerformance]
    }
}
