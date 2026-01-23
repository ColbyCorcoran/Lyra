//
//  MIDIActionExecutor.swift
//  Lyra
//
//  Executor for MIDI actions - integrates MIDI control with app state
//

import Foundation
import SwiftUI
import Observation

/// MIDI action executor - connects MIDI controls to app functionality
@Observable
class MIDIActionExecutor {
    static let shared = MIDIActionExecutor()

    // MARK: - State Properties (to be bound to app state)

    /// Autoscroll state
    var isAutoscrolling: Bool = false
    var autoscrollSpeed: Double = 1.0 // 0.0 to 2.0

    /// Scroll position
    var scrollPosition: Double = 0.0 // 0.0 to 1.0

    /// Transpose
    var transpose: Int = 0 // -12 to +12 semitones

    /// Volume controls
    var metronomeVolume: Double = 0.7 // 0.0 to 1.0
    var backingTrackVolume: Double = 0.7 // 0.0 to 1.0
    var masterVolume: Double = 1.0 // 0.0 to 1.0

    /// Audio state
    var isMetronomeEnabled: Bool = false
    var isBackingTrackPlaying: Bool = false

    /// Display settings
    var brightness: Double = 1.0 // 0.0 to 1.0
    var fontSize: Double = 16.0 // Font size in points
    var isFullscreen: Bool = false
    var isDarkMode: Bool = false

    /// UI state
    var showAnnotations: Bool = true

    /// Activity tracking
    private(set) var lastActionExecuted: (action: MIDIActionType, timestamp: Date)?
    private(set) var executionCount: [MIDIActionType: Int] = [:]

    // MARK: - Callbacks

    /// Callback closures for actions that need app-specific implementation
    var onNextSong: (() -> Void)?
    var onPreviousSong: (() -> Void)?
    var onNextSection: (() -> Void)?
    var onPreviousSection: (() -> Void)?
    var onScrollUp: (() -> Void)?
    var onScrollDown: (() -> Void)?
    var onScrollToTop: (() -> Void)?
    var onScrollToBottom: (() -> Void)?
    var onAddMarker: (() -> Void)?
    var onRemoveMarker: (() -> Void)?
    var onJumpToMarker: ((Int) -> Void)?
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?
    var onAddNote: (() -> Void)?
    var onLoadSetlist: ((String) -> Void)?
    var onNextInSetlist: (() -> Void)?
    var onPreviousInSetlist: (() -> Void)?

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .midiActionExecuted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let action = notification.userInfo?["action"] as? MIDIActionType,
                  let value = notification.userInfo?["value"] as? Double? else { return }
            self?.executeAction(action, value: value)
        }
    }

    // MARK: - Action Execution

    func executeAction(_ action: MIDIActionType, value: Double?) {
        // Record execution
        lastActionExecuted = (action, Date())
        executionCount[action, default: 0] += 1

        // Execute the action
        switch action {
        // Autoscroll
        case .toggleAutoscroll:
            isAutoscrolling.toggle()
            postStateChange(action: action, newValue: isAutoscrolling)

        case .startAutoscroll:
            isAutoscrolling = true
            postStateChange(action: action, newValue: true)

        case .stopAutoscroll:
            isAutoscrolling = false
            postStateChange(action: action, newValue: false)

        case .setAutoscrollSpeed:
            if let value = value {
                autoscrollSpeed = clamp(value, min: 0.0, max: 2.0)
                postStateChange(action: action, newValue: autoscrollSpeed)
            }

        case .increaseAutoscrollSpeed:
            autoscrollSpeed = min(2.0, autoscrollSpeed + 0.1)
            postStateChange(action: action, newValue: autoscrollSpeed)

        case .decreaseAutoscrollSpeed:
            autoscrollSpeed = max(0.0, autoscrollSpeed - 0.1)
            postStateChange(action: action, newValue: autoscrollSpeed)

        // Navigation
        case .scrollUp:
            onScrollUp?()

        case .scrollDown:
            onScrollDown?()

        case .scrollToTop:
            onScrollToTop?()

        case .scrollToBottom:
            onScrollToBottom?()

        case .setScrollPosition:
            if let value = value {
                scrollPosition = clamp(value, min: 0.0, max: 1.0)
                postStateChange(action: action, newValue: scrollPosition)
            }

        case .nextSong:
            onNextSong?()

        case .previousSong:
            onPreviousSong?()

        case .nextSection:
            onNextSection?()

        case .previousSection:
            onPreviousSection?()

        // Transpose
        case .transposeUp:
            transpose = min(12, transpose + 1)
            postStateChange(action: action, newValue: transpose)

        case .transposeDown:
            transpose = max(-12, transpose - 1)
            postStateChange(action: action, newValue: transpose)

        case .setTranspose:
            if let value = value {
                transpose = Int(clamp(value, min: -12.0, max: 12.0))
                postStateChange(action: action, newValue: transpose)
            }

        case .resetTranspose:
            transpose = 0
            postStateChange(action: action, newValue: 0)

        // Volume & Audio
        case .setMetronomeVolume:
            if let value = value {
                metronomeVolume = clamp(value, min: 0.0, max: 1.0)
                postStateChange(action: action, newValue: metronomeVolume)
            }

        case .setBackingTrackVolume:
            if let value = value {
                backingTrackVolume = clamp(value, min: 0.0, max: 1.0)
                postStateChange(action: action, newValue: backingTrackVolume)
            }

        case .setMasterVolume:
            if let value = value {
                masterVolume = clamp(value, min: 0.0, max: 1.0)
                postStateChange(action: action, newValue: masterVolume)
            }

        case .toggleMetronome:
            isMetronomeEnabled.toggle()
            postStateChange(action: action, newValue: isMetronomeEnabled)

        case .toggleBackingTrack:
            isBackingTrackPlaying.toggle()
            postStateChange(action: action, newValue: isBackingTrackPlaying)

        case .muteAll:
            masterVolume = 0.0
            postStateChange(action: action, newValue: 0.0)

        // Display & UI
        case .setBrightness:
            if let value = value {
                brightness = clamp(value, min: 0.0, max: 1.0)
                postStateChange(action: action, newValue: brightness)
                applyBrightness(brightness)
            }

        case .toggleFullscreen:
            isFullscreen.toggle()
            postStateChange(action: action, newValue: isFullscreen)

        case .toggleDarkMode:
            isDarkMode.toggle()
            postStateChange(action: action, newValue: isDarkMode)

        case .increaseFontSize:
            fontSize = min(32.0, fontSize + 2.0)
            postStateChange(action: action, newValue: fontSize)

        case .decreaseFontSize:
            fontSize = max(10.0, fontSize - 2.0)
            postStateChange(action: action, newValue: fontSize)

        case .setFontSize:
            if let value = value {
                fontSize = clamp(value, min: 10.0, max: 32.0)
                postStateChange(action: action, newValue: fontSize)
            }

        // Markers & Sections
        case .addMarker:
            onAddMarker?()

        case .removeMarker:
            onRemoveMarker?()

        case .jumpToMarker:
            if let value = value {
                onJumpToMarker?(Int(value))
            }

        case .toggleLoopSection:
            // TODO: Implement loop section
            break

        // Recording & Notes
        case .startRecording:
            onStartRecording?()

        case .stopRecording:
            onStopRecording?()

        case .addNote:
            onAddNote?()

        case .toggleAnnotations:
            showAnnotations.toggle()
            postStateChange(action: action, newValue: showAnnotations)

        // Setlist Management
        case .loadSetlist:
            // TODO: Implement with setlist ID
            break

        case .nextInSetlist:
            onNextInSetlist?()

        case .previousInSetlist:
            onPreviousInSetlist?()

        // MIDI & Control
        case .sendMIDIScene:
            // Handled by MIDIControlManager
            break

        case .toggleMIDIThru:
            // TODO: Implement MIDI thru
            break

        case .panicAllNotesOff:
            MIDIManager.shared.sendAllNotesOff()

        case .custom:
            // Custom actions handled by app-specific code
            break
        }
    }

    // MARK: - Helpers

    private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        return Swift.max(minValue, Swift.min(maxValue, value))
    }

    private func postStateChange(action: MIDIActionType, newValue: Any) {
        NotificationCenter.default.post(
            name: .midiActionStateChanged,
            object: self,
            userInfo: [
                "action": action,
                "newValue": newValue
            ]
        )
    }

    private func applyBrightness(_ brightness: Double) {
        DispatchQueue.main.async {
            UIScreen.main.brightness = CGFloat(brightness)
        }
    }

    // MARK: - Statistics

    func resetStatistics() {
        executionCount.removeAll()
        lastActionExecuted = nil
    }

    func executionCount(for action: MIDIActionType) -> Int {
        executionCount[action, default: 0]
    }

    var totalExecutions: Int {
        executionCount.values.reduce(0, +)
    }

    var mostUsedAction: MIDIActionType? {
        executionCount.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let midiActionStateChanged = Notification.Name("midiActionStateChanged")
}

// MARK: - Integration Helper

/// Helper for integrating MIDI actions with SwiftUI views
struct MIDIActionIntegration: ViewModifier {
    @State private var executor = MIDIActionExecutor.shared

    func body(content: Content) -> some View {
        content
            .onAppear {
                setupCallbacks()
            }
    }

    private func setupCallbacks() {
        // Setup callbacks based on your app structure
        // Example:
        // executor.onNextSong = { /* navigate to next song */ }
        // executor.onPreviousSong = { /* navigate to previous song */ }
    }
}

extension View {
    /// Integrate MIDI action execution with this view
    func integrateMAIDIActions() -> some View {
        modifier(MIDIActionIntegration())
    }
}
