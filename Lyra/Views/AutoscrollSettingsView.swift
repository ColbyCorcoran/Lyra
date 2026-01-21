//
//  AutoscrollSettingsView.swift
//  Lyra
//
//  Global autoscroll settings and preferences
//

import SwiftUI

struct AutoscrollSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var settings: AutoscrollSettings = .load()

    @State private var defaultMinutes: Int
    @State private var defaultSeconds: Int

    init() {
        let loadedSettings = AutoscrollSettings.load()
        _settings = State(initialValue: loadedSettings)

        let duration = Int(loadedSettings.defaultDuration)
        _defaultMinutes = State(initialValue: duration / 60)
        _defaultSeconds = State(initialValue: duration % 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Default Duration
                Section {
                    Picker("Minutes", selection: $defaultMinutes) {
                        ForEach(0...15, id: \.self) { minute in
                            Text("\(minute) min").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)

                    Picker("Seconds", selection: $defaultSeconds) {
                        ForEach(0...59, id: \.self) { second in
                            Text("\(second) sec").tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                } header: {
                    Text("Default Duration")
                } footer: {
                    Text("New songs will use this duration: \(formattedDefaultDuration)")
                }

                // Default Speed
                Section {
                    Picker("Default Speed", selection: $settings.defaultSpeed) {
                        ForEach(AutoscrollManager.speedPresets, id: \.value) { preset in
                            Text(preset.label).tag(preset.value)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Default Speed")
                } footer: {
                    Text("Autoscroll will start at this speed")
                }

                // Behavior
                Section {
                    Toggle(isOn: $settings.autoStartOnOpen) {
                        Label("Auto-start on Open", systemImage: "play.circle")
                    }

                    Toggle(isOn: $settings.loopAtEnd) {
                        Label("Loop at End", systemImage: "repeat")
                    }

                    Toggle(isOn: $settings.hapticFeedback) {
                        Label("Haptic Feedback", systemImage: "waveform")
                    }
                } header: {
                    Text("Behavior")
                } footer: {
                    Text("Auto-start: Automatically begin autoscroll when opening a song\nLoop: Restart from top when reaching the end\nHaptic: Provide tactile feedback for controls")
                }

                // Tips
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TipRow(
                            icon: "hand.tap",
                            title: "Tap to Pause",
                            description: "Tap anywhere on the screen while autoscrolling to pause/resume"
                        )

                        Divider()

                        TipRow(
                            icon: "hand.draw",
                            title: "Manual Scroll Pauses",
                            description: "Manually scrolling will automatically pause autoscroll"
                        )

                        Divider()

                        TipRow(
                            icon: "gauge.with.dots.needle.67percent",
                            title: "Speed Adjustment",
                            description: "Use +/- buttons or swipe up/down to adjust speed mid-performance"
                        )

                        Divider()

                        TipRow(
                            icon: "arrow.up.to.line.compact",
                            title: "Jump to Top",
                            description: "Quickly return to the beginning with the jump button"
                        )
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Tips")
                }

                // Advanced Features
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundStyle(.yellow)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Advanced Features")
                                    .font(.headline)

                                Text("Professional autoscroll tools available per-song")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            AdvancedFeatureRow(
                                icon: "gauge.with.dots.needle.67percent",
                                title: "Speed Zones",
                                description: "Set different speeds for each section (verse, chorus, bridge)",
                                color: .blue
                            )

                            AdvancedFeatureRow(
                                icon: "waveform",
                                title: "Timeline Recording",
                                description: "Record and replay your exact scroll pattern",
                                color: .purple
                            )

                            AdvancedFeatureRow(
                                icon: "mappin.circle",
                                title: "Smart Markers",
                                description: "Auto-pause at specific points with optional auto-resume",
                                color: .orange
                            )

                            AdvancedFeatureRow(
                                icon: "square.stack.3d.up",
                                title: "Presets",
                                description: "Save complete configurations for quick access",
                                color: .green
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Professional Tools")
                } footer: {
                    Text("Access these features when viewing a song through the autoscroll menu. Each song can have its own configuration.")
                }

                // Performance Note
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Perfect for Performance")
                                .font(.headline)

                            Text("Autoscroll is designed for hands-free operation during live performance. Configure duration for each song to match your playing speed.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Autoscroll Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: defaultMinutes) { _, _ in
                updateDefaultDuration()
            }
            .onChange(of: defaultSeconds) { _, _ in
                updateDefaultDuration()
            }
        }
    }

    // MARK: - Computed Properties

    private var formattedDefaultDuration: String {
        let total = defaultMinutes * 60 + defaultSeconds
        return String(format: "%d:%02d", defaultMinutes, defaultSeconds)
    }

    // MARK: - Actions

    private func updateDefaultDuration() {
        settings.defaultDuration = TimeInterval(defaultMinutes * 60 + defaultSeconds)
    }

    private func saveSettings() {
        settings.save()
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Tip Row

struct TipRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Advanced Feature Row

struct AdvancedFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AutoscrollSettingsView()
}
