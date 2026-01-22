//
//  ShortcutsManager.swift
//  Lyra
//
//  Manager for keyboard shortcuts and quick actions
//

import Foundation
import SwiftUI
import UIKit

@Observable
class ShortcutsManager {
    // MARK: - State Properties

    var isEnabled: Bool = true
    var customQuickActions: [QuickAction] = []
    var showVisualFeedback: Bool = true

    // Action callbacks
    var onSearch: (() -> Void)?
    var onNewSong: (() -> Void)?
    var onEditSong: (() -> Void)?
    var onPrint: (() -> Void)?
    var onSave: (() -> Void)?
    var onToggleTranspose: (() -> Void)?
    var onToggleMetronome: (() -> Void)?
    var onToggleLowLight: (() -> Void)?
    var onToggleAnnotations: (() -> Void)?
    var onToggleDrawing: (() -> Void)?
    var onAddToSet: (() -> Void)?
    var onShare: (() -> Void)?
    var onScrollToTop: (() -> Void)?
    var onScrollToBottom: (() -> Void)?
    var onToggleAutoscroll: (() -> Void)?

    // MARK: - Initialization

    init() {
        loadSettings()
        loadCustomQuickActions()
    }

    // MARK: - Keyboard Shortcut Handling

    func handleKeyCommand(_ input: String, modifierFlags: UIKeyModifierFlags) {
        guard isEnabled else { return }

        // Handle modifier-based shortcuts
        if modifierFlags.contains(.command) {
            handleCommandShortcut(input)
        } else {
            handleSingleKeyShortcut(input)
        }

        // Haptic feedback
        if showVisualFeedback {
            HapticManager.shared.selection()
        }
    }

    private func handleCommandShortcut(_ input: String) {
        switch input {
        case "f", "F":
            onSearch?()
        case "n", "N":
            onNewSong?()
        case "e", "E":
            onEditSong?()
        case "p", "P":
            onPrint?()
        case "s", "S":
            onSave?()
        case "l", "L":
            onToggleLowLight?()
        default:
            break
        }
    }

    private func handleSingleKeyShortcut(_ input: String) {
        switch input.lowercased() {
        case "t":
            onToggleTranspose?()
        case "m":
            onToggleMetronome?()
        case "a":
            onToggleAnnotations?()
        case "d":
            onToggleDrawing?()
        case " ":
            onToggleAutoscroll?()
        default:
            break
        }
    }

    // MARK: - Quick Actions

    var defaultQuickActions: [QuickAction] {
        [
            QuickAction(
                id: "transpose",
                title: "Transpose",
                icon: "arrow.up.arrow.down",
                action: .toggleTranspose
            ),
            QuickAction(
                id: "annotate",
                title: "Annotate",
                icon: "note.text",
                action: .toggleAnnotations
            ),
            QuickAction(
                id: "metronome",
                title: "Metronome",
                icon: "metronome",
                action: .toggleMetronome
            ),
            QuickAction(
                id: "autoscroll",
                title: "Autoscroll",
                icon: "play.circle",
                action: .toggleAutoscroll
            ),
            QuickAction(
                id: "addToSet",
                title: "Add to Set",
                icon: "music.note.list",
                action: .addToSet
            ),
            QuickAction(
                id: "share",
                title: "Share",
                icon: "square.and.arrow.up",
                action: .share
            ),
            QuickAction(
                id: "lowLight",
                title: "Low Light",
                icon: "moon",
                action: .toggleLowLight
            ),
            QuickAction(
                id: "drawing",
                title: "Drawing",
                icon: "pencil.tip.crop.circle",
                action: .toggleDrawing
            )
        ]
    }

    var allQuickActions: [QuickAction] {
        defaultQuickActions + customQuickActions
    }

    func executeQuickAction(_ action: QuickActionType) {
        switch action {
        case .toggleTranspose:
            onToggleTranspose?()
        case .toggleAnnotations:
            onToggleAnnotations?()
        case .toggleMetronome:
            onToggleMetronome?()
        case .toggleAutoscroll:
            onToggleAutoscroll?()
        case .addToSet:
            onAddToSet?()
        case .share:
            onShare?()
        case .toggleLowLight:
            onToggleLowLight?()
        case .toggleDrawing:
            onToggleDrawing?()
        case .scrollToTop:
            onScrollToTop?()
        case .scrollToBottom:
            onScrollToBottom?()
        case .editSong:
            onEditSong?()
        case .search:
            onSearch?()
        }

        if showVisualFeedback {
            HapticManager.shared.selection()
        }
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard

        isEnabled = defaults.bool(forKey: "shortcuts.isEnabled")
        if !defaults.bool(forKey: "shortcuts.isEnabled.set") {
            isEnabled = true
            defaults.set(true, forKey: "shortcuts.isEnabled.set")
        }

        showVisualFeedback = defaults.bool(forKey: "shortcuts.showVisualFeedback")
        if !defaults.bool(forKey: "shortcuts.showVisualFeedback.set") {
            showVisualFeedback = true
            defaults.set(true, forKey: "shortcuts.showVisualFeedback.set")
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isEnabled, forKey: "shortcuts.isEnabled")
        defaults.set(showVisualFeedback, forKey: "shortcuts.showVisualFeedback")
    }

    private func loadCustomQuickActions() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "shortcuts.customQuickActions"),
           let actions = try? JSONDecoder().decode([QuickAction].self, from: data) {
            customQuickActions = actions
        }
    }

    func saveCustomQuickActions() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(customQuickActions) {
            defaults.set(data, forKey: "shortcuts.customQuickActions")
        }
    }
}

// MARK: - Quick Action

struct QuickAction: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var icon: String
    var action: QuickActionType
    var isCustom: Bool = false
}

// MARK: - Quick Action Type

enum QuickActionType: String, Codable, CaseIterable, Identifiable {
    case toggleTranspose = "Toggle Transpose"
    case toggleAnnotations = "Toggle Annotations"
    case toggleMetronome = "Toggle Metronome"
    case toggleAutoscroll = "Toggle Autoscroll"
    case addToSet = "Add to Set"
    case share = "Share"
    case toggleLowLight = "Toggle Low Light"
    case toggleDrawing = "Toggle Drawing"
    case scrollToTop = "Scroll to Top"
    case scrollToBottom = "Scroll to Bottom"
    case editSong = "Edit Song"
    case search = "Search"

    var id: String { rawValue }

    var defaultIcon: String {
        switch self {
        case .toggleTranspose:
            return "arrow.up.arrow.down"
        case .toggleAnnotations:
            return "note.text"
        case .toggleMetronome:
            return "metronome"
        case .toggleAutoscroll:
            return "play.circle"
        case .addToSet:
            return "music.note.list"
        case .share:
            return "square.and.arrow.up"
        case .toggleLowLight:
            return "moon"
        case .toggleDrawing:
            return "pencil.tip.crop.circle"
        case .scrollToTop:
            return "arrow.up.to.line"
        case .scrollToBottom:
            return "arrow.down.to.line"
        case .editSong:
            return "pencil"
        case .search:
            return "magnifyingglass"
        }
    }
}

// MARK: - Keyboard Shortcut Info

struct KeyboardShortcut: Identifiable {
    let id = UUID()
    let key: String
    let modifiers: String?
    let action: String
    let category: ShortcutCategory
}

enum ShortcutCategory: String, CaseIterable {
    case navigation = "Navigation"
    case editing = "Editing"
    case performance = "Performance"
    case organization = "Organization"
}

extension ShortcutsManager {
    var allKeyboardShortcuts: [KeyboardShortcut] {
        [
            // Navigation
            KeyboardShortcut(key: "↑", modifiers: nil, action: "Scroll up", category: .navigation),
            KeyboardShortcut(key: "↓", modifiers: nil, action: "Scroll down", category: .navigation),
            KeyboardShortcut(key: "←", modifiers: nil, action: "Previous song", category: .navigation),
            KeyboardShortcut(key: "→", modifiers: nil, action: "Next song", category: .navigation),
            KeyboardShortcut(key: "Page Up", modifiers: nil, action: "Previous song", category: .navigation),
            KeyboardShortcut(key: "Page Down", modifiers: nil, action: "Next song", category: .navigation),

            // Editing
            KeyboardShortcut(key: "E", modifiers: "⌘", action: "Edit song", category: .editing),
            KeyboardShortcut(key: "N", modifiers: "⌘", action: "New song", category: .editing),
            KeyboardShortcut(key: "S", modifiers: "⌘", action: "Save", category: .editing),
            KeyboardShortcut(key: "F", modifiers: "⌘", action: "Search", category: .editing),

            // Performance
            KeyboardShortcut(key: "Space", modifiers: nil, action: "Play/pause autoscroll", category: .performance),
            KeyboardShortcut(key: "M", modifiers: nil, action: "Toggle metronome", category: .performance),
            KeyboardShortcut(key: "L", modifiers: "⌘", action: "Toggle low light", category: .performance),
            KeyboardShortcut(key: "A", modifiers: nil, action: "Toggle annotations", category: .performance),
            KeyboardShortcut(key: "D", modifiers: nil, action: "Toggle drawing", category: .performance),
            KeyboardShortcut(key: "T", modifiers: nil, action: "Toggle transpose", category: .performance),
            KeyboardShortcut(key: "P", modifiers: "⌘", action: "Print/Performance", category: .performance),

            // Organization
            KeyboardShortcut(key: "B", modifiers: "⌘", action: "Add to book", category: .organization),
            KeyboardShortcut(key: "S", modifiers: "⌘⇧", action: "Add to set", category: .organization)
        ]
    }
}
