//
//  ShortcutsSettingsView.swift
//  Lyra
//
//  Settings view for keyboard shortcuts and gesture controls
//

import SwiftUI

struct ShortcutsSettingsView: View {
    @Bindable var shortcutsManager: ShortcutsManager
    @Bindable var gestureManager: GestureShortcutsManager
    @State private var showCheatSheet: Bool = false

    var body: some View {
        List {
            // Keyboard Shortcuts Section
            keyboardSection

            // Gesture Shortcuts Section
            gestureSection

            // Quick Actions Section
            quickActionsSection

            // Visual Feedback
            feedbackSection

            // Help Section
            helpSection
        }
        .navigationTitle("Shortcuts & Gestures")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCheatSheet) {
            KeyboardShortcutsCheatSheet(shortcuts: shortcutsManager.allKeyboardShortcuts)
        }
    }

    // MARK: - Keyboard Section

    @ViewBuilder
    private var keyboardSection: some View {
        Section {
            Toggle("Enable Keyboard Shortcuts", isOn: $shortcutsManager.isEnabled)
                .onChange(of: shortcutsManager.isEnabled) { _, _ in
                    shortcutsManager.saveSettings()
                }

            if shortcutsManager.isEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Common Shortcuts")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        ShortcutHint(key: "Space", action: "Play/pause autoscroll")
                        ShortcutHint(key: "←/→", action: "Previous/next song")
                        ShortcutHint(key: "T", action: "Toggle transpose")
                        ShortcutHint(key: "M", action: "Toggle metronome")
                        ShortcutHint(key: "⌘L", action: "Toggle low light")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Label("Keyboard Shortcuts", systemImage: "keyboard")
        } footer: {
            if shortcutsManager.isEnabled {
                Text("Use keyboard shortcuts to control Lyra without touching the screen")
            } else {
                Text("Enable to use keyboard shortcuts")
            }
        }
    }

    // MARK: - Gesture Section

    @ViewBuilder
    private var gestureSection: some View {
        Section {
            Toggle("Enable Gesture Shortcuts", isOn: $gestureManager.isEnabled)
                .onChange(of: gestureManager.isEnabled) { _, _ in
                    gestureManager.saveSettings()
                }

            if gestureManager.isEnabled {
                Toggle("Two-finger swipe (scroll to top/bottom)", isOn: $gestureManager.twoFingerSwipeEnabled)
                    .onChange(of: gestureManager.twoFingerSwipeEnabled) { _, _ in
                        gestureManager.saveSettings()
                    }

                Toggle("Two-finger tap (toggle autoscroll)", isOn: $gestureManager.twoFingerTapEnabled)
                    .onChange(of: gestureManager.twoFingerTapEnabled) { _, _ in
                        gestureManager.saveSettings()
                    }

                Toggle("Three-finger tap (toggle annotations)", isOn: $gestureManager.threeFingerTapEnabled)
                    .onChange(of: gestureManager.threeFingerTapEnabled) { _, _ in
                        gestureManager.saveSettings()
                    }
            }
        } header: {
            Label("Gesture Shortcuts", systemImage: "hand.tap")
        } footer: {
            if gestureManager.isEnabled {
                Text("Use multi-finger gestures for quick actions. Works best on iPad.")
            } else {
                Text("Enable to use gesture shortcuts")
            }
        }
    }

    // MARK: - Quick Actions Section

    @ViewBuilder
    private var quickActionsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Default Quick Actions")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(shortcutsManager.defaultQuickActions.prefix(8)) { action in
                        VStack(spacing: 6) {
                            Image(systemName: action.icon)
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())

                            Text(action.title)
                                .font(.system(size: 10))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Label("Quick Action Menu", systemImage: "circle.grid.3x3")
        } footer: {
            Text("Long-press on the screen to show quick actions menu with these shortcuts")
        }
    }

    // MARK: - Feedback Section

    @ViewBuilder
    private var feedbackSection: some View {
        Section {
            Toggle("Visual Feedback", isOn: $shortcutsManager.showVisualFeedback)
                .onChange(of: shortcutsManager.showVisualFeedback) { _, _ in
                    shortcutsManager.saveSettings()
                }
        } footer: {
            Text("Show brief visual and haptic feedback when shortcuts are triggered")
        }
    }

    // MARK: - Help Section

    @ViewBuilder
    private var helpSection: some View {
        Section {
            Button {
                showCheatSheet = true
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("View All Shortcuts")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Complete list of keyboard and gesture shortcuts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("Help")
        }
    }
}

// MARK: - Shortcut Hint

struct ShortcutHint: View {
    let key: String
    let action: String

    var body: some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(action)
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShortcutsSettingsView(
            shortcutsManager: ShortcutsManager(),
            gestureManager: GestureShortcutsManager()
        )
    }
}
