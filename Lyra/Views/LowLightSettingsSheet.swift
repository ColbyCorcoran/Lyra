//
//  LowLightSettingsSheet.swift
//  Lyra
//
//  Settings sheet for low light mode customization
//

import SwiftUI

struct LowLightSettingsSheet: View {
    @Bindable var lowLightManager: LowLightModeManager
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            Form {
                // Preview Section
                previewSection

                // Color Selection
                colorSection

                // Intensity
                intensitySection

                // Brightness Control
                brightnessSection

                // UI Elements
                uiElementsSection

                // Auto-Enable
                autoEnableSection

                // Information
                informationSection
            }
            .navigationTitle("Low Light Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        Section {
            VStack(spacing: 16) {
                Text("Preview")
                    .font(.headline)
                    .foregroundStyle(lowLightManager.isEnabled ? lowLightManager.textColor(for: .primary) : .primary)

                HStack {
                    Text("Song Title")
                        .font(.title2)
                        .foregroundStyle(lowLightManager.isEnabled ? lowLightManager.textColor(for: .primary) : .primary)

                    Spacer()

                    Text("120 BPM")
                        .font(.caption)
                        .foregroundStyle(lowLightManager.isEnabled ? lowLightManager.accentColor(for: .blue) : .blue)
                }

                Text("This is how your song content will appear in low light mode. The red/amber color scheme preserves night vision in dark environments.")
                    .font(.body)
                    .foregroundStyle(lowLightManager.isEnabled ? lowLightManager.textColor(for: .primary) : .primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(lowLightManager.isEnabled ? Color.black : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } header: {
            Text("Preview")
        }
    }

    // MARK: - Color Section

    private var colorSection: some View {
        Section {
            Picker("Color", selection: $lowLightManager.color) {
                ForEach(LowLightColor.allCases) { color in
                    HStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: 20, height: 20)

                        Text(color.displayName)
                    }
                    .tag(color)
                }
            }
            .pickerStyle(.inline)
        } header: {
            Text("Color Scheme")
        } footer: {
            Text("Red and amber colors preserve night vision better than blue light.")
        }
    }

    // MARK: - Intensity Section

    private var intensitySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Intensity")
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(lowLightManager.intensity * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundStyle(.secondary)

                    Slider(value: $lowLightManager.intensity, in: 0.3...1.0, step: 0.05)
                        .tint(lowLightManager.color.color)

                    Image(systemName: "circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Intensity")
        } footer: {
            Text("Higher intensity provides better visibility but may be too bright in very dark environments.")
        }
    }

    // MARK: - Brightness Section

    private var brightnessSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Screen Brightness")
                        .font(.subheadline)

                    Spacer()

                    if let override = lowLightManager.brightnessOverride {
                        Text("\(Int(override * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Auto")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "sun.min")
                        .foregroundStyle(.secondary)

                    Slider(
                        value: Binding(
                            get: { lowLightManager.brightnessOverride ?? (lowLightManager.intensity * 0.3) },
                            set: { lowLightManager.setBrightness($0) }
                        ),
                        in: 0.05...0.5,
                        step: 0.05
                    )
                    .tint(.orange)

                    Image(systemName: "sun.max")
                        .foregroundStyle(.secondary)
                }

                if lowLightManager.brightnessOverride != nil {
                    Button("Reset to Auto") {
                        lowLightManager.setBrightness(lowLightManager.intensity * 0.3)
                        lowLightManager.brightnessOverride = nil
                        HapticManager.shared.selection()
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
        } header: {
            Text("Brightness Control")
        } footer: {
            Text("Low light mode automatically reduces screen brightness. Adjust manually if needed.")
        }
    }

    // MARK: - UI Elements Section

    private var uiElementsSection: some View {
        Section {
            Toggle("Dim UI Elements", isOn: $lowLightManager.dimUIElements)
        } header: {
            Text("Interface")
        } footer: {
            Text("Dims toolbars, buttons, and other interface elements for a more immersive experience.")
        }
    }

    // MARK: - Auto-Enable Section

    private var autoEnableSection: some View {
        Section {
            Toggle("Auto-Enable by Time", isOn: $lowLightManager.autoEnableTime)

            if lowLightManager.autoEnableTime {
                HStack {
                    Text("Start Time")
                    Spacer()
                    Picker("Start Hour", selection: $lowLightManager.autoEnableStartHour) {
                        ForEach(0..<24) { hour in
                            Text(hourString(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("End Time")
                    Spacer()
                    Picker("End Hour", selection: $lowLightManager.autoEnableEndHour) {
                        ForEach(0..<24) { hour in
                            Text(hourString(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        } header: {
            Text("Auto-Enable")
        } footer: {
            if lowLightManager.autoEnableTime {
                Text("Low light mode will automatically enable between \(hourString(lowLightManager.autoEnableStartHour)) and \(hourString(lowLightManager.autoEnableEndHour)).")
            } else {
                Text("Automatically enable low light mode during specific hours.")
            }
        }
    }

    // MARK: - Information Section

    private var informationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                LowLightInfoRow(
                    icon: "eye",
                    title: "Night Vision",
                    description: "Red light preserves night vision better than white or blue light."
                )

                Divider()

                LowLightInfoRow(
                    icon: "moon.stars",
                    title: "Dark Environments",
                    description: "Ideal for stage performances, rehearsals, and late-night practice."
                )

                Divider()

                LowLightInfoRow(
                    icon: "battery.100",
                    title: "Battery Friendly",
                    description: "Reduced brightness saves battery during long sessions."
                )
            }
        } header: {
            Text("About Low Light Mode")
        }
    }

    // MARK: - Helper Methods

    private func hourString(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Info Row

private struct LowLightInfoRow: View {
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
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LowLightSettingsSheet(
        lowLightManager: LowLightModeManager(),
        onDismiss: {}
    )
}
