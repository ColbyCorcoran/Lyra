//
//  DisplaySettingsSheet.swift
//  Lyra
//
//  Sheet for customizing song display settings
//

import SwiftUI
import SwiftData

struct DisplaySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song

    @State private var settings: DisplaySettings
    @State private var hasChanges: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    init(song: Song) {
        self.song = song
        // Initialize with current song settings
        _settings = State(initialValue: song.displaySettings)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Font Size Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Font Size")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(settings.fontSize)) pt")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Slider(value: $settings.fontSize, in: 12...28, step: 1)
                            .accessibilityLabel("Font size")
                            .accessibilityValue("\(Int(settings.fontSize)) points")
                            .onChange(of: settings.fontSize) { _, _ in
                                hasChanges = true
                            }

                        // Preview text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("[G]Sample chord")
                                .font(.system(size: settings.fontSize, design: .monospaced))
                                .foregroundStyle(settings.chordColorValue())

                            Text("Sample lyrics text")
                                .font(.system(size: settings.fontSize))
                                .foregroundStyle(settings.lyricsColorValue())
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } header: {
                    Label("Text Size", systemImage: "textformat.size")
                }

                // Chord Color Section
                Section {
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
                                isSelected: settings.chordColor == preset.hex
                            ) {
                                settings.chordColor = preset.hex
                                hasChanges = true
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Chord Color", systemImage: "paintpalette")
                } footer: {
                    Text("Chords will be displayed in the selected color")
                }

                // Lyrics Color Section
                Section {
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
                                isSelected: settings.lyricsColor == preset.hex
                            ) {
                                settings.lyricsColor = preset.hex
                                hasChanges = true
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Lyrics Color", systemImage: "textformat")
                } footer: {
                    Text("Lyrics will be displayed in the selected color")
                }

                // Spacing Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Chord/Lyrics Spacing")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(settings.spacing)) pt")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Slider(value: $settings.spacing, in: 4...16, step: 1)
                            .accessibilityLabel("Chord lyrics spacing")
                            .accessibilityValue("\(Int(settings.spacing)) points")
                            .onChange(of: settings.spacing) { _, _ in
                                hasChanges = true
                            }

                        // Preview spacing
                        VStack(alignment: .leading, spacing: settings.spacing) {
                            Text("[G]Chord above")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(settings.chordColorValue())

                            Text("Lyrics below")
                                .font(.system(size: 14))
                                .foregroundStyle(settings.lyricsColorValue())
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Label("Spacing", systemImage: "arrow.up.and.down")
                } footer: {
                    Text("Adjust vertical space between chords and lyrics")
                }

                // Actions Section
                Section {
                    Button(role: .destructive) {
                        resetToDefaults()
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }

                    Button {
                        setAsGlobalDefault()
                    } label: {
                        Label("Set as Default for All Songs", systemImage: "star")
                            .frame(maxWidth: .infinity)
                    }

                    if song.hasCustomDisplaySettings {
                        Button(role: .destructive) {
                            clearCustomSettings()
                        } label: {
                            Label("Remove Custom Settings", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Display Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .alert("Error Saving Settings", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Actions

    private func saveSettings() {
        song.displaySettings = settings

        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving display settings: \(error.localizedDescription)")
            errorMessage = "Unable to save display settings. Please try again."
            showErrorAlert = true
        }
    }

    private func resetToDefaults() {
        settings = .default
        hasChanges = true
    }

    private func setAsGlobalDefault() {
        UserDefaults.standard.globalDisplaySettings = settings
        hasChanges = true
    }

    private func clearCustomSettings() {
        song.clearCustomDisplaySettings()
        settings = UserDefaults.standard.globalDisplaySettings

        do {
            try modelContext.save()
        } catch {
            print("❌ Error clearing custom settings: \(error.localizedDescription)")
            errorMessage = "Unable to clear custom settings. Please try again."
            showErrorAlert = true
        }

        hasChanges = true
    }
}

// MARK: - Color Swatch

struct ColorSwatch: View {
    let name: String
    let hex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 44, height: 44)

                    if isSelected {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }

                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DisplaySettingsSheet(song: Song(
        title: "Test Song",
        artist: "Test Artist",
        content: "{verse}\n[G]Test [C]lyrics",
        originalKey: "G"
    ))
    .modelContainer(PreviewContainer.shared.container)
}
