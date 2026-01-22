//
//  QuickActionMenu.swift
//  Lyra
//
//  Circular quick action menu for long-press gestures
//

import SwiftUI

struct QuickActionMenu: View {
    let position: CGPoint
    let actions: [QuickAction]
    let onSelect: (QuickAction) -> Void
    let onDismiss: () -> Void

    @State private var selectedAction: QuickAction?
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0

    private let menuRadius: CGFloat = 100
    private let buttonSize: CGFloat = 60

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Action buttons in circle
            ForEach(Array(actions.prefix(8).enumerated()), id: \.element.id) { index, action in
                let angle = angleForIndex(index, total: min(actions.count, 8))

                QuickActionButton(
                    action: action,
                    isSelected: selectedAction?.id == action.id
                )
                .position(
                    x: position.x + cos(angle) * menuRadius,
                    y: position.y + sin(angle) * menuRadius
                )
                .onTapGesture {
                    selectAction(action)
                }
            }

            // Center indicator
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 20, height: 20)
                .position(position)
                .overlay(
                    Circle()
                        .strokeBorder(Color.blue, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .position(position)
                )
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    private func angleForIndex(_ index: Int, total: Int) -> CGFloat {
        let startAngle: CGFloat = -.pi / 2 // Start at top
        let angleStep = (2 * .pi) / CGFloat(total)
        return startAngle + angleStep * CGFloat(index)
    }

    private func selectAction(_ action: QuickAction) {
        selectedAction = action
        HapticManager.shared.selection()

        // Delay slightly to show selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onSelect(action)
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            scale = 0.1
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let action: QuickAction
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                Image(systemName: action.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : .blue)
            }

            Text(action.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Gesture Shortcuts Manager

@Observable
class GestureShortcutsManager {
    var isEnabled: Bool = true
    var twoFingerSwipeEnabled: Bool = true
    var twoFingerTapEnabled: Bool = true
    var threeFingerTapEnabled: Bool = true

    // Action callbacks
    var onScrollToTop: (() -> Void)?
    var onScrollToBottom: (() -> Void)?
    var onToggleAutoscroll: (() -> Void)?
    var onToggleAnnotations: (() -> Void)?

    init() {
        loadSettings()
    }

    func handleTwoFingerSwipeUp() {
        guard isEnabled && twoFingerSwipeEnabled else { return }
        onScrollToTop?()
        HapticManager.shared.impact(.medium)
    }

    func handleTwoFingerSwipeDown() {
        guard isEnabled && twoFingerSwipeEnabled else { return }
        onScrollToBottom?()
        HapticManager.shared.impact(.medium)
    }

    func handleTwoFingerTap() {
        guard isEnabled && twoFingerTapEnabled else { return }
        onToggleAutoscroll?()
        HapticManager.shared.selection()
    }

    func handleThreeFingerTap() {
        guard isEnabled && threeFingerTapEnabled else { return }
        onToggleAnnotations?()
        HapticManager.shared.selection()
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        isEnabled = defaults.bool(forKey: "gestureShortcuts.isEnabled")
        if !defaults.bool(forKey: "gestureShortcuts.isEnabled.set") {
            isEnabled = true
            defaults.set(true, forKey: "gestureShortcuts.isEnabled.set")
        }

        twoFingerSwipeEnabled = defaults.bool(forKey: "gestureShortcuts.twoFingerSwipe")
        if !defaults.bool(forKey: "gestureShortcuts.twoFingerSwipe.set") {
            twoFingerSwipeEnabled = true
            defaults.set(true, forKey: "gestureShortcuts.twoFingerSwipe.set")
        }

        twoFingerTapEnabled = defaults.bool(forKey: "gestureShortcuts.twoFingerTap")
        if !defaults.bool(forKey: "gestureShortcuts.twoFingerTap.set") {
            twoFingerTapEnabled = true
            defaults.set(true, forKey: "gestureShortcuts.twoFingerTap.set")
        }

        threeFingerTapEnabled = defaults.bool(forKey: "gestureShortcuts.threeFingerTap")
        if !defaults.bool(forKey: "gestureShortcuts.threeFingerTap.set") {
            threeFingerTapEnabled = true
            defaults.set(true, forKey: "gestureShortcuts.threeFingerTap.set")
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isEnabled, forKey: "gestureShortcuts.isEnabled")
        defaults.set(twoFingerSwipeEnabled, forKey: "gestureShortcuts.twoFingerSwipe")
        defaults.set(twoFingerTapEnabled, forKey: "gestureShortcuts.twoFingerTap")
        defaults.set(threeFingerTapEnabled, forKey: "gestureShortcuts.threeFingerTap")
    }
}

// MARK: - Keyboard Shortcuts Cheat Sheet

struct KeyboardShortcutsCheatSheet: View {
    let shortcuts: [KeyboardShortcut]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(ShortcutCategory.allCases, id: \.self) { category in
                    let categoryShortcuts = shortcuts.filter { $0.category == category }

                    if !categoryShortcuts.isEmpty {
                        Section {
                            ForEach(categoryShortcuts) { shortcut in
                                HStack {
                                    // Key combination
                                    HStack(spacing: 4) {
                                        if let modifiers = shortcut.modifiers {
                                            Text(modifiers)
                                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color(.systemGray5))
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }

                                        Text(shortcut.key)
                                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.systemGray5))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }

                                    Spacer()

                                    // Action description
                                    Text(shortcut.action)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Text(category.rawValue)
                        }
                    }
                }

                // Gesture shortcuts section
                Section {
                    GestureShortcutRow(
                        gesture: "Two-finger swipe up",
                        action: "Scroll to top"
                    )
                    GestureShortcutRow(
                        gesture: "Two-finger swipe down",
                        action: "Scroll to bottom"
                    )
                    GestureShortcutRow(
                        gesture: "Two-finger tap",
                        action: "Toggle autoscroll"
                    )
                    GestureShortcutRow(
                        gesture: "Three-finger tap",
                        action: "Toggle annotations"
                    )
                    GestureShortcutRow(
                        gesture: "Long press",
                        action: "Show quick actions"
                    )
                } header: {
                    Text("Gesture Shortcuts")
                } footer: {
                    Text("Multi-finger gestures work on iPad and trackpad")
                }
            }
            .navigationTitle("Keyboard Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GestureShortcutRow: View {
    let gesture: String
    let action: String

    var body: some View {
        HStack {
            Image(systemName: "hand.tap")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(gesture)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(action)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Quick Action Menu") {
    let sampleActions = [
        QuickAction(id: "1", title: "Transpose", icon: "arrow.up.arrow.down", action: .toggleTranspose),
        QuickAction(id: "2", title: "Annotate", icon: "note.text", action: .toggleAnnotations),
        QuickAction(id: "3", title: "Metronome", icon: "metronome", action: .toggleMetronome),
        QuickAction(id: "4", title: "Autoscroll", icon: "play.circle", action: .toggleAutoscroll),
        QuickAction(id: "5", title: "Add to Set", icon: "music.note.list", action: .addToSet),
        QuickAction(id: "6", title: "Share", icon: "square.and.arrow.up", action: .share)
    ]

    return QuickActionMenu(
        position: CGPoint(x: 200, y: 400),
        actions: sampleActions,
        onSelect: { _ in },
        onDismiss: {}
    )
}

#Preview("Shortcuts Cheat Sheet") {
    let manager = ShortcutsManager()
    return KeyboardShortcutsCheatSheet(shortcuts: manager.allKeyboardShortcuts)
}
