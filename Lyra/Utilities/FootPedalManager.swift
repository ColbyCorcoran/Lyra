//
//  FootPedalManager.swift
//  Lyra
//
//  Manager for Bluetooth foot pedal support with keyboard event handling
//

import Foundation
import SwiftUI
import UIKit

@Observable
class FootPedalManager {
    // MARK: - State Properties

    var isEnabled: Bool = true
    var activeProfile: FootPedalProfile = .performance
    var customProfiles: [FootPedalProfile] = []
    var showVisualFeedback: Bool = true
    var lastPressedKey: String?
    var testMode: Bool = false

    // Action callbacks
    var onNextSong: (() -> Void)?
    var onPreviousSong: (() -> Void)?
    var onScrollDown: (() -> Void)?
    var onScrollUp: (() -> Void)?
    var onToggleAutoscroll: (() -> Void)?
    var onNextSection: (() -> Void)?
    var onPreviousSection: (() -> Void)?
    var onTransposeUp: (() -> Void)?
    var onTransposeDown: (() -> Void)?
    var onToggleMetronome: (() -> Void)?
    var onMarkSongPerformed: (() -> Void)?

    // MARK: - Initialization

    init() {
        loadSettings()
        loadCustomProfiles()
    }

    // MARK: - Key Command Handling

    func handleKeyCommand(_ input: String, modifierFlags: UIKeyModifierFlags) {
        guard isEnabled else { return }

        // Update last pressed key (for testing mode)
        lastPressedKey = input

        // Get action for this key from active profile
        guard let action = activeProfile.actionForKey(input) else { return }

        // Execute action
        executeAction(action)

        // Haptic feedback
        HapticManager.shared.selection()
    }

    func executeAction(_ action: FootPedalAction) {
        switch action {
        case .nextSong:
            onNextSong?()
        case .previousSong:
            onPreviousSong?()
        case .scrollDown:
            onScrollDown?()
        case .scrollUp:
            onScrollUp?()
        case .toggleAutoscroll:
            onToggleAutoscroll?()
        case .nextSection:
            onNextSection?()
        case .previousSection:
            onPreviousSection?()
        case .transposeUp:
            onTransposeUp?()
        case .transposeDown:
            onTransposeDown?()
        case .toggleMetronome:
            onToggleMetronome?()
        case .markSongPerformed:
            onMarkSongPerformed?()
        case .none:
            break
        }
    }

    // MARK: - Profile Management

    func setActiveProfile(_ profile: FootPedalProfile) {
        activeProfile = profile
        saveSettings()
        HapticManager.shared.selection()
    }

    func addCustomProfile(_ profile: FootPedalProfile) {
        customProfiles.append(profile)
        saveCustomProfiles()
    }

    func updateCustomProfile(_ profile: FootPedalProfile) {
        if let index = customProfiles.firstIndex(where: { $0.id == profile.id }) {
            customProfiles[index] = profile
            saveCustomProfiles()
        }
    }

    func deleteCustomProfile(_ profile: FootPedalProfile) {
        customProfiles.removeAll(where: { $0.id == profile.id })
        saveCustomProfiles()
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard

        isEnabled = defaults.bool(forKey: "footPedal.isEnabled")
        if !defaults.bool(forKey: "footPedal.isEnabled.set") {
            isEnabled = true
            defaults.set(true, forKey: "footPedal.isEnabled.set")
        }

        showVisualFeedback = defaults.bool(forKey: "footPedal.showVisualFeedback")
        if !defaults.bool(forKey: "footPedal.showVisualFeedback.set") {
            showVisualFeedback = true
            defaults.set(true, forKey: "footPedal.showVisualFeedback.set")
        }

        // Load active profile
        if let profileData = defaults.data(forKey: "footPedal.activeProfile"),
           let profile = try? JSONDecoder().decode(FootPedalProfile.self, from: profileData) {
            activeProfile = profile
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(isEnabled, forKey: "footPedal.isEnabled")
        defaults.set(showVisualFeedback, forKey: "footPedal.showVisualFeedback")

        // Save active profile
        if let profileData = try? JSONEncoder().encode(activeProfile) {
            defaults.set(profileData, forKey: "footPedal.activeProfile")
        }
    }

    private func loadCustomProfiles() {
        let defaults = UserDefaults.standard

        if let profilesData = defaults.data(forKey: "footPedal.customProfiles"),
           let profiles = try? JSONDecoder().decode([FootPedalProfile].self, from: profilesData) {
            customProfiles = profiles
        }
    }

    private func saveCustomProfiles() {
        let defaults = UserDefaults.standard

        if let profilesData = try? JSONEncoder().encode(customProfiles) {
            defaults.set(profilesData, forKey: "footPedal.customProfiles")
        }
    }
}

// MARK: - Foot Pedal Action

enum FootPedalAction: String, CaseIterable, Codable, Identifiable {
    case nextSong = "Next Song"
    case previousSong = "Previous Song"
    case scrollDown = "Scroll Down"
    case scrollUp = "Scroll Up"
    case toggleAutoscroll = "Toggle Autoscroll"
    case nextSection = "Next Section"
    case previousSection = "Previous Section"
    case transposeUp = "Transpose Up"
    case transposeDown = "Transpose Down"
    case toggleMetronome = "Toggle Metronome"
    case markSongPerformed = "Mark Song Performed"
    case none = "None"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .nextSong:
            return "chevron.right.circle"
        case .previousSong:
            return "chevron.left.circle"
        case .scrollDown:
            return "arrow.down.circle"
        case .scrollUp:
            return "arrow.up.circle"
        case .toggleAutoscroll:
            return "play.circle"
        case .nextSection:
            return "forward.end"
        case .previousSection:
            return "backward.end"
        case .transposeUp:
            return "arrow.up.arrow.down.circle"
        case .transposeDown:
            return "arrow.up.arrow.down.circle"
        case .toggleMetronome:
            return "metronome"
        case .markSongPerformed:
            return "checkmark.circle"
        case .none:
            return "xmark.circle"
        }
    }

    var description: String {
        switch self {
        case .nextSong:
            return "Advance to next song in set"
        case .previousSong:
            return "Return to previous song"
        case .scrollDown:
            return "Scroll content down"
        case .scrollUp:
            return "Scroll content up"
        case .toggleAutoscroll:
            return "Play/pause autoscroll"
        case .nextSection:
            return "Jump to next section"
        case .previousSection:
            return "Jump to previous section"
        case .transposeUp:
            return "Transpose song up 1 semitone"
        case .transposeDown:
            return "Transpose song down 1 semitone"
        case .toggleMetronome:
            return "Start/stop metronome"
        case .markSongPerformed:
            return "Mark current song as performed"
        case .none:
            return "No action"
        }
    }
}

// MARK: - Foot Pedal Profile

struct FootPedalProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var keyMappings: [String: FootPedalAction]
    var isBuiltIn: Bool = false

    // Key identifiers
    static let arrowLeft = "UIKeyInputLeftArrow"
    static let arrowRight = "UIKeyInputRightArrow"
    static let arrowUp = "UIKeyInputUpArrow"
    static let arrowDown = "UIKeyInputDownArrow"
    static let pageUp = "UIKeyInputPageUp"
    static let pageDown = "UIKeyInputPageDown"
    static let space = " "
    static let returnKey = "\r"

    func actionForKey(_ key: String) -> FootPedalAction? {
        return keyMappings[key]
    }

    mutating func setAction(_ action: FootPedalAction, forKey key: String) {
        keyMappings[key] = action
    }

    // MARK: - Built-in Profiles

    static var performance: FootPedalProfile {
        FootPedalProfile(
            name: "Performance",
            description: "Optimized for live performances and sets",
            keyMappings: [
                arrowLeft: .previousSong,
                arrowRight: .nextSong,
                arrowDown: .scrollDown,
                arrowUp: .scrollUp,
                pageDown: .nextSong,
                pageUp: .previousSong,
                space: .toggleAutoscroll,
                returnKey: .markSongPerformed
            ],
            isBuiltIn: true
        )
    }

    static var practice: FootPedalProfile {
        FootPedalProfile(
            name: "Practice",
            description: "Optimized for practice sessions",
            keyMappings: [
                arrowLeft: .previousSection,
                arrowRight: .nextSection,
                arrowDown: .scrollDown,
                arrowUp: .scrollUp,
                pageDown: .scrollDown,
                pageUp: .scrollUp,
                space: .toggleAutoscroll,
                returnKey: .toggleMetronome
            ],
            isBuiltIn: true
        )
    }

    static var teaching: FootPedalProfile {
        FootPedalProfile(
            name: "Teaching",
            description: "Optimized for music lessons",
            keyMappings: [
                arrowLeft: .scrollUp,
                arrowRight: .scrollDown,
                arrowDown: .scrollDown,
                arrowUp: .scrollUp,
                pageDown: .nextSection,
                pageUp: .previousSection,
                space: .toggleAutoscroll,
                returnKey: .toggleMetronome
            ],
            isBuiltIn: true
        )
    }

    static var transpose: FootPedalProfile {
        FootPedalProfile(
            name: "Transpose",
            description: "Quick transposition during performance",
            keyMappings: [
                arrowLeft: .transposeDown,
                arrowRight: .transposeUp,
                arrowDown: .scrollDown,
                arrowUp: .scrollUp,
                pageDown: .nextSong,
                pageUp: .previousSong,
                space: .toggleAutoscroll
            ],
            isBuiltIn: true
        )
    }

    static var allBuiltInProfiles: [FootPedalProfile] {
        [performance, practice, teaching, transpose]
    }
}

// MARK: - Key Command Extensions

extension FootPedalManager {
    /// Create UIKeyCommand instances for all mapped keys
    func createKeyCommands(action: Selector) -> [UIKeyCommand] {
        var commands: [UIKeyCommand] = []

        // Arrow keys
        commands.append(UIKeyCommand(
            input: UIKeyCommand.inputLeftArrow,
            modifierFlags: [],
            action: action
        ))
        commands.append(UIKeyCommand(
            input: UIKeyCommand.inputRightArrow,
            modifierFlags: [],
            action: action
        ))
        commands.append(UIKeyCommand(
            input: UIKeyCommand.inputUpArrow,
            modifierFlags: [],
            action: action
        ))
        commands.append(UIKeyCommand(
            input: UIKeyCommand.inputDownArrow,
            modifierFlags: [],
            action: action
        ))

        // Page Up/Down
        commands.append(UIKeyCommand(
            input: UIKeyCommand.inputPageUp,
            modifierFlags: [],
            action: action
        ))
        commands.append(UIKeyCommand(
            input: UIKeyCommand.inputPageDown,
            modifierFlags: [],
            action: action
        ))

        // Space and Return
        commands.append(UIKeyCommand(
            input: " ",
            modifierFlags: [],
            action: action
        ))
        commands.append(UIKeyCommand(
            input: "\r",
            modifierFlags: [],
            action: action
        ))

        // Disable title display for all commands
        commands.forEach { $0.wantsPriorityOverSystemBehavior = true }

        return commands
    }
}
