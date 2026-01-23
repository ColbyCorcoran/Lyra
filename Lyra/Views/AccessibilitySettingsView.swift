//
//  AccessibilitySettingsView.swift
//  Lyra
//
//  Comprehensive accessibility settings
//  Configure VoiceOver, Switch Control, visual modes, and more
//

import SwiftUI

struct AccessibilitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var accessibilityManager = AccessibilityManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // System Status
                systemStatusSection

                // Visual Accessibility
                visualAccessibilitySection

                // VoiceOver Settings
                voiceOverSection

                // Switch Control Settings
                if accessibilityManager.isSwitchControlRunning {
                    switchControlSection
                }

                // Cognitive Accessibility
                cognitiveAccessibilitySection

                // Haptic & Audio Feedback
                feedbackSection

                // Motion & Animations
                motionSection

                // Braille Display
                if accessibilityManager.brailleDisplayConnected {
                    brailleSection
                }

                // Quick Actions
                quickActionsSection
            }
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        accessibilityManager.saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - System Status Section

    private var systemStatusSection: some View {
        Section {
            StatusRow(
                icon: "eye",
                title: "VoiceOver",
                isActive: accessibilityManager.isVoiceOverRunning,
                activeColor: .blue
            )

            StatusRow(
                icon: "switch.2",
                title: "Switch Control",
                isActive: accessibilityManager.isSwitchControlRunning,
                activeColor: .green
            )

            StatusRow(
                icon: "bold",
                title: "Bold Text",
                isActive: accessibilityManager.isBoldTextEnabled,
                activeColor: .purple
            )

            StatusRow(
                icon: "figure.walk.motion",
                title: "Reduce Motion",
                isActive: accessibilityManager.isReduceMotionEnabled,
                activeColor: .orange
            )

            StatusRow(
                icon: "circle.lefthalf.filled",
                title: "Increase Contrast",
                isActive: accessibilityManager.isDarkerSystemColorsEnabled,
                activeColor: .indigo
            )
        } header: {
            Text("System Settings")
        } footer: {
            Text("These settings are controlled in iOS Settings > Accessibility")
        }
    }

    // MARK: - Visual Accessibility Section

    private var visualAccessibilitySection: some View {
        Section {
            Picker("High Contrast Mode", selection: $accessibilityManager.highContrastMode) {
                ForEach(HighContrastMode.allCases, id: \.self) { mode in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.displayName)
                        Text(mode.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(mode)
                }
            }

            HStack {
                Text("Font Size Multiplier")
                Spacer()
                Text(String(format: "%.1fx", accessibilityManager.fontSizeMultiplier))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $accessibilityManager.fontSizeMultiplier,
                in: 0.8...2.0,
                step: 0.1
            ) {
                Text("Font Size")
            } minimumValueLabel: {
                Image(systemName: "textformat.size.smaller")
            } maximumValueLabel: {
                Image(systemName: "textformat.size.larger")
            }

            Toggle("Large Buttons Mode", isOn: $accessibilityManager.largeButtonsMode)
        } header: {
            Text("Visual Accessibility")
        } footer: {
            Text("Adjust contrast and text size for better visibility")
        }
    }

    // MARK: - VoiceOver Section

    private var voiceOverSection: some View {
        Section {
            Toggle("Custom Rotors", isOn: $accessibilityManager.customRotorsEnabled)

            Toggle("Smart Element Grouping", isOn: $accessibilityManager.smartElementGrouping)

            Toggle("Describe Chord Diagrams", isOn: $accessibilityManager.describeChordDiagrams)

            Toggle("Announce Section Changes", isOn: $accessibilityManager.announceSectionChanges)

            if accessibilityManager.isVoiceOverRunning {
                Button {
                    testVoiceOver()
                } label: {
                    Label("Test VoiceOver", systemImage: "speaker.wave.2")
                }
            }
        } header: {
            Text("VoiceOver")
        } footer: {
            Text("Custom rotors allow navigation by section or chord. Enable VoiceOver in iOS Settings to use these features.")
        }
    }

    // MARK: - Switch Control Section

    private var switchControlSection: some View {
        Section {
            HStack {
                Text("Point Scanning Speed")
                Spacer()
                Text(String(format: "%.1fs", accessibilityManager.pointScanningSpeed))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $accessibilityManager.pointScanningSpeed,
                in: 0.5...3.0,
                step: 0.1
            )

            HStack {
                Text("Item Scanning Speed")
                Spacer()
                Text(String(format: "%.1fs", accessibilityManager.itemScanningSpeed))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $accessibilityManager.itemScanningSpeed,
                in: 0.5...3.0,
                step: 0.1
            )

            Toggle("Auto-Scanning", isOn: $accessibilityManager.autoScanningEnabled)

            ColorPicker("Scanning Highlight", selection: $accessibilityManager.scanningHighlightColor)
        } header: {
            Text("Switch Control")
        } footer: {
            Text("Adjust scanning speed and behavior for Switch Control")
        }
    }

    // MARK: - Cognitive Accessibility Section

    private var cognitiveAccessibilitySection: some View {
        Section {
            Toggle("Simplified Mode", isOn: $accessibilityManager.simplifiedMode)

            Toggle("Large Buttons", isOn: $accessibilityManager.largeButtonsMode)

            if accessibilityManager.simplifiedMode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Simplified mode features:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 4) {
                        FeatureRow(icon: "checkmark.circle.fill", text: "Reduced visual complexity")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Larger tap targets")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Clearer button labels")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Less information density")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Cognitive Accessibility")
        } footer: {
            Text("Simplified mode reduces visual complexity and makes buttons easier to use")
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        Section {
            Toggle("Voice Feedback", isOn: $accessibilityManager.voiceFeedbackEnabled)

            Picker("Haptic Strength", selection: $accessibilityManager.hapticStrength) {
                ForEach(HapticStrength.allCases, id: \.self) { strength in
                    Text(strength.displayName).tag(strength)
                }
            }

            if accessibilityManager.hapticStrength != .off {
                Button {
                    testHaptics()
                } label: {
                    Label("Test Haptic Feedback", systemImage: "hand.tap")
                }
            }
        } header: {
            Text("Feedback")
        } footer: {
            Text("Voice feedback announces actions. Haptic feedback provides physical confirmation.")
        }
    }

    // MARK: - Motion Section

    private var motionSection: some View {
        Section {
            HStack {
                Image(systemName: "figure.walk.motion")
                    .foregroundStyle(accessibilityManager.isReduceMotionEnabled ? .orange : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Animation Speed")

                    if accessibilityManager.isReduceMotionEnabled {
                        Text("Controlled by Reduce Motion")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(animationSpeedDescription)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if !accessibilityManager.isReduceMotionEnabled {
                Slider(
                    value: $accessibilityManager.animationSpeed,
                    in: 0...1,
                    step: 0.25
                )
            }
        } header: {
            Text("Motion & Animations")
        } footer: {
            Text("Reduce Motion in iOS Settings > Accessibility disables animations entirely")
        }
    }

    // MARK: - Braille Section

    private var brailleSection: some View {
        Section {
            HStack {
                Image(systemName: "braille")
                    .foregroundStyle(.blue)

                Text("Braille Display Connected")

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Text("Songs and chords will be sent to your Braille display")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Braille Display")
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        Section {
            NavigationLink {
                VoiceCommandsGuideView()
            } label: {
                Label("Voice Commands Guide", systemImage: "mic")
            }

            NavigationLink {
                KeyboardShortcutsView()
            } label: {
                Label("Keyboard Shortcuts", systemImage: "keyboard")
            }

            Button {
                resetToDefaults()
            } label: {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Quick Actions")
        }
    }

    // MARK: - Helper Computed Properties

    private var animationSpeedDescription: String {
        if accessibilityManager.isReduceMotionEnabled {
            return "Instant"
        } else if accessibilityManager.animationSpeed == 0 {
            return "Instant"
        } else if accessibilityManager.animationSpeed == 0.25 {
            return "Very Fast"
        } else if accessibilityManager.animationSpeed == 0.5 {
            return "Fast"
        } else if accessibilityManager.animationSpeed == 0.75 {
            return "Slow"
        } else {
            return "Normal"
        }
    }

    // MARK: - Actions

    private func testVoiceOver() {
        accessibilityManager.announce("VoiceOver test. All systems functional.", priority: .high)
        HapticManager.shared.success()
    }

    private func testHaptics() {
        let generator = UIImpactFeedbackGenerator(style: accessibilityManager.hapticStrength.impactStyle)
        generator.prepare()
        generator.impactOccurred()
    }

    private func resetToDefaults() {
        accessibilityManager.highContrastMode = .off
        accessibilityManager.simplifiedMode = false
        accessibilityManager.largeButtonsMode = false
        accessibilityManager.fontSizeMultiplier = 1.0
        accessibilityManager.voiceFeedbackEnabled = false
        accessibilityManager.hapticStrength = .medium
        accessibilityManager.animationSpeed = 1.0
        accessibilityManager.customRotorsEnabled = true
        accessibilityManager.smartElementGrouping = true
        accessibilityManager.describeChordDiagrams = true
        accessibilityManager.announceSectionChanges = true
        accessibilityManager.pointScanningSpeed = 1.0
        accessibilityManager.itemScanningSpeed = 0.8
        accessibilityManager.autoScanningEnabled = true

        accessibilityManager.saveSettings()
        accessibilityManager.announce("Accessibility settings reset to defaults")
        HapticManager.shared.success()
    }
}

// MARK: - Supporting Views

struct StatusRow: View {
    let icon: String
    let title: String
    let isActive: Bool
    let activeColor: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isActive ? activeColor : .secondary)
                .frame(width: 30)

            Text(title)

            Spacer()

            if isActive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(activeColor)
                        .frame(width: 8, height: 8)

                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(activeColor)
                }
            } else {
                Text("Inactive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(isActive ? "Active" : "Inactive")")
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.green)

            Text(text)
        }
    }
}

// MARK: - Voice Commands Guide

struct VoiceCommandsGuideView: View {
    var body: some View {
        List {
            Section {
                CommandRow(command: "Hey Siri, play song", description: "Start autoscroll")
                CommandRow(command: "Hey Siri, next song", description: "Skip to next song in set")
                CommandRow(command: "Hey Siri, transpose up", description: "Transpose song up one semitone")
                CommandRow(command: "Hey Siri, start metronome", description: "Begin metronome")
            } header: {
                Text("Siri Commands")
            }

            Section {
                CommandRow(command: "Show numbers", description: "Display item numbers for selection")
                CommandRow(command: "Tap [number]", description: "Tap numbered item")
                CommandRow(command: "Scroll down", description: "Scroll down the page")
                CommandRow(command: "Go back", description: "Navigate back")
            } header: {
                Text("Voice Control")
            } footer: {
                Text("Enable Voice Control in Settings > Accessibility > Voice Control")
            }
        }
        .navigationTitle("Voice Commands")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CommandRow: View {
    let command: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(command)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Keyboard Shortcuts View

struct KeyboardShortcutsView: View {
    let shortcuts = ShortcutsManager().allKeyboardShortcuts

    var body: some View {
        KeyboardShortcutsCheatSheet(shortcuts: shortcuts)
    }
}

// MARK: - Preview

#Preview {
    AccessibilitySettingsView()
}
