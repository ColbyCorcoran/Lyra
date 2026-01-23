//
//  MonitorConfigurationView.swift
//  Lyra
//
//  Configuration view for individual stage monitors
//

import SwiftUI

struct MonitorConfigurationView: View {
    let zone: MonitorZone
    @State private var configuration: StageMonitorConfiguration
    @State private var manager = StageMonitorManager.shared
    @Environment(\.dismiss) private var dismiss

    init(zone: MonitorZone) {
        self.zone = zone
        self._configuration = State(initialValue: zone.configuration)
    }

    var body: some View {
        Form {
            // Role and Layout
            Section("Monitor Setup") {
                Picker("Role", selection: $configuration.role) {
                    ForEach(MonitorRole.allCases) { role in
                        Label(role.displayName, systemImage: role.icon)
                            .tag(role)
                    }
                }

                Picker("Layout", selection: $configuration.layoutType) {
                    ForEach(StageMonitorLayoutType.allCases, id: \.self) { layout in
                        Label(layout.displayName, systemImage: layout.icon)
                            .tag(layout)
                    }
                }

                TextField("Custom Name", text: Binding(
                    get: { configuration.name },
                    set: { configuration.name = $0 }
                ))
            }

            // Display Settings
            Section("Display Settings") {
                VStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Font Size: \(Int(configuration.fontSize))pt")
                            .font(.caption)
                        Slider(value: $configuration.fontSize, in: 24...120, step: 4)
                    }

                    VStack(alignment: .leading) {
                        Text("Chord Font Size: \(Int(configuration.chordFontSize))pt")
                            .font(.caption)
                        Slider(value: $configuration.chordFontSize, in: 32...144, step: 4)
                    }

                    VStack(alignment: .leading) {
                        Text("Lyrics Font Size: \(Int(configuration.lyricsFontSize))pt")
                            .font(.caption)
                        Slider(value: $configuration.lyricsFontSize, in: 24...120, step: 4)
                    }
                }

                Picker("Font Family", selection: $configuration.fontFamily) {
                    Text("System").tag("System")
                    Text("Monospaced").tag("Monospaced")
                    Text("Georgia").tag("Georgia")
                    Text("Courier").tag("Courier")
                }
            }

            // Colors
            Section("Colors") {
                ColorPickerRow(title: "Background", color: $configuration.backgroundColor)
                ColorPickerRow(title: "Text", color: $configuration.textColor)
                ColorPickerRow(title: "Chords", color: $configuration.chordColor)
                ColorPickerRow(title: "Accent", color: $configuration.accentColor)

                Toggle("Dark Theme", isOn: $configuration.useDarkTheme)
                Toggle("High Contrast", isOn: $configuration.highContrast)
            }

            // Layout Options
            Section("Layout Options") {
                VStack(alignment: .leading) {
                    Text("Horizontal Margin: \(Int(configuration.horizontalMargin))pt")
                        .font(.caption)
                    Slider(value: $configuration.horizontalMargin, in: 0...200, step: 10)
                }

                VStack(alignment: .leading) {
                    Text("Vertical Margin: \(Int(configuration.verticalMargin))pt")
                        .font(.caption)
                    Slider(value: $configuration.verticalMargin, in: 0...200, step: 10)
                }

                VStack(alignment: .leading) {
                    Text("Line Spacing: \(Int(configuration.lineSpacing))pt")
                        .font(.caption)
                    Slider(value: $configuration.lineSpacing, in: 0...40, step: 2)
                }

                Toggle("Compact Mode", isOn: $configuration.compactMode)
            }

            // Content Options
            Section("Content Options") {
                Toggle("Show Section Labels", isOn: $configuration.showSectionLabels)
                Toggle("Show Song Metadata", isOn: $configuration.showSongMetadata)
                Toggle("Show Next Section", isOn: $configuration.showNextSection)
                Toggle("Show Transpose", isOn: $configuration.showTranspose)
                Toggle("Show Capo", isOn: $configuration.showCapo)
            }

            // Quick Presets
            Section("Quick Presets") {
                ForEach(MonitorRole.allCases.filter { $0 != .custom }, id: \.self) { role in
                    Button {
                        configuration = StageMonitorConfiguration.forRole(role)
                    } label: {
                        Label(role.displayName, systemImage: role.icon)
                    }
                }
            }

            // Save
            Section {
                Button("Apply Configuration") {
                    var updatedZone = zone
                    updatedZone.configuration = configuration
                    manager.updateMonitorZone(updatedZone)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Monitor Configuration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Color Picker Row

struct ColorPickerRow: View {
    let title: String
    @Binding var color: String

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            ColorPicker("", selection: Binding(
                get: { Color(hex: color) },
                set: { newColor in
                    // Convert Color back to hex
                    color = newColor.toHex() ?? color
                }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components[0]
        let g = components.count > 1 ? components[1] : components[0]
        let b = components.count > 2 ? components[2] : components[0]

        return String(format: "#%02lX%02lX%02lX",
                     lround(Double(r * 255)),
                     lround(Double(g * 255)),
                     lround(Double(b * 255)))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MonitorConfigurationView(
            zone: MonitorZone(
                role: .lead,
                priority: 1,
                configuration: .forRole(.lead)
            )
        )
    }
}
