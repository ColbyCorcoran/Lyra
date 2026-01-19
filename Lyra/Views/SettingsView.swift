//
//  SettingsView.swift
//  Lyra
//
//  Global app settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("globalFontSize") private var globalFontSize: Double = 16
    @AppStorage("globalChordColor") private var globalChordColor: String = "#007AFF"
    @AppStorage("globalLyricsColor") private var globalLyricsColor: String = "#000000"
    @AppStorage("globalSpacing") private var globalSpacing: Double = 8

    @State private var showLibraryStats: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Library Section
                Section {
                    Button {
                        showLibraryStats = true
                    } label: {
                        HStack {
                            Label("Library Statistics", systemImage: "chart.bar.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Label("Library", systemImage: "books.vertical")
                }

                // Display Defaults Section
                Section {
                    // Font Size
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Default Font Size")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(globalFontSize)) pt")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $globalFontSize, in: 12...28, step: 1)

                        // Preview
                        VStack(alignment: .leading, spacing: 4) {
                            Text("[G]Sample chord")
                                .font(.system(size: globalFontSize, design: .monospaced))
                                .foregroundStyle(Color(hex: globalChordColor) ?? .blue)

                            Text("Sample lyrics text")
                                .font(.system(size: globalFontSize))
                                .foregroundStyle(Color(hex: globalLyricsColor) ?? .primary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Chord Color
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Chord Color")
                            .font(.subheadline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(DisplaySettings.chordColorPresets, id: \.hex) { preset in
                                ColorSwatch(
                                    name: preset.name,
                                    hex: preset.hex,
                                    isSelected: globalChordColor == preset.hex
                                ) {
                                    globalChordColor = preset.hex
                                    saveGlobalSettings()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    // Lyrics Color
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Lyrics Color")
                            .font(.subheadline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(DisplaySettings.lyricsColorPresets, id: \.hex) { preset in
                                ColorSwatch(
                                    name: preset.name,
                                    hex: preset.hex,
                                    isSelected: globalLyricsColor == preset.hex
                                ) {
                                    globalLyricsColor = preset.hex
                                    saveGlobalSettings()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    // Spacing
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Default Chord/Lyrics Spacing")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(globalSpacing)) pt")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $globalSpacing, in: 4...16, step: 1)

                        // Preview spacing
                        VStack(alignment: .leading, spacing: globalSpacing) {
                            Text("[G]Chord above")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(Color(hex: globalChordColor) ?? .blue)

                            Text("Lyrics below")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: globalLyricsColor) ?? .primary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Reset button
                    Button(role: .destructive) {
                        resetToDefaults()
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                } header: {
                    Label("Display Defaults", systemImage: "textformat")
                } footer: {
                    Text("These settings apply to all new songs. Individual songs can override these defaults.")
                }

                // App Information Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }

                // Support Section
                Section {
                    Link(destination: URL(string: "https://github.com/yourusername/lyra")!) {
                        HStack {
                            Label("GitHub Repository", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://github.com/yourusername/lyra/issues")!) {
                        HStack {
                            Label("Report an Issue", systemImage: "exclamationmark.triangle")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Support", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("Settings")
            .onChange(of: globalFontSize) { _, _ in
                saveGlobalSettings()
            }
            .onChange(of: globalSpacing) { _, _ in
                saveGlobalSettings()
            }
            .sheet(isPresented: $showLibraryStats) {
                LibraryStatsView()
            }
        }
    }

    // MARK: - Actions

    private func saveGlobalSettings() {
        let settings = DisplaySettings(
            fontSize: globalFontSize,
            chordColor: globalChordColor,
            lyricsColor: globalLyricsColor,
            spacing: globalSpacing
        )
        UserDefaults.standard.globalDisplaySettings = settings
    }

    private func resetToDefaults() {
        globalFontSize = 16
        globalChordColor = "#007AFF"
        globalLyricsColor = "#000000"
        globalSpacing = 8
        saveGlobalSettings()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
