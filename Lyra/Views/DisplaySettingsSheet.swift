//
//  DisplaySettingsSheet.swift
//  Lyra
//
//  Comprehensive sheet for customizing song display settings
//

import SwiftUI
import SwiftData

struct DisplaySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme

    let song: Song

    @State private var settings: DisplaySettings
    @State private var hasChanges: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedTab: SettingsTab = .fonts

    init(song: Song) {
        self.song = song
        _settings = State(initialValue: song.displaySettings)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Settings Section", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab Content
                TabView(selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        ScrollView {
                            VStack(spacing: 0) {
                                tabContent(for: tab)
                            }
                        }
                        .tag(tab)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
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
        .alert("Error Saving Settings", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(for tab: SettingsTab) -> some View {
        switch tab {
        case .fonts:
            fontsSection
        case .colors:
            colorsSection
        case .layout:
            layoutSection
        case .accessibility:
            accessibilitySection
        case .presets:
            presetsSection
        }
    }

    // MARK: - Fonts Section

    private var fontsSection: some View {
        Form {
            // Font Size
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Base Font Size")
                        Spacer()
                        Text("\(Int(settings.fontSize)) pt")
                            .fontWeight(.medium)
                    }
                    Slider(value: $settings.fontSize, in: 12...32, step: 1)
                        .onChange(of: settings.fontSize) { _, _ in hasChanges = true }
                }
            } header: {
                Text("Size")
            }

            // Font Weight
            Section {
                Picker("Weight", selection: $settings.fontWeight) {
                    ForEach(FontWeightOption.allCases) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }
                .onChange(of: settings.fontWeight) { _, _ in hasChanges = true }
            } header: {
                Text("Font Weight")
            }

            // Font Families
            Section {
                fontFamilyPicker("Title", selection: $settings.titleFontFamily)
                fontFamilyPicker("Metadata", selection: $settings.metadataFontFamily)
                fontFamilyPicker("Lyrics", selection: $settings.lyricsFontFamily)
                fontFamilyPicker("Chords", selection: $settings.chordsFontFamily)
            } header: {
                Text("Font Families")
            } footer: {
                Text("Choose different fonts for each text type")
            }

            // Preview
            Section {
                fontPreview
            } header: {
                Text("Preview")
            }
        }
    }

    @ViewBuilder
    private func fontFamilyPicker(_ label: String, selection: Binding<FontFamily>) -> some View {
        Picker(label, selection: selection) {
            ForEach(FontFamily.allCases) { family in
                Text(family.displayName).tag(family)
            }
        }
        .onChange(of: selection.wrappedValue) { _, _ in hasChanges = true }
    }

    private var fontPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amazing Grace")
                .font(settings.titleFont(size: 24))

            Text("Key: G | Tempo: 90 BPM")
                .font(settings.metadataFont())
                .foregroundStyle(settings.metadataColorValue())

            Text("[G]Sample chord")
                .font(settings.chordsFont())
                .foregroundStyle(settings.chordColorValue())

            Text("Sample lyrics text")
                .font(settings.lyricsFont())
                .foregroundStyle(settings.lyricsColorValue())
        }
        .padding()
        .background(settings.backgroundColorValue())
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Colors Section

    private var colorsSection: some View {
        Form {
            colorPickerSection("Chord Color", color: $settings.chordColor, presets: DisplaySettings.chordColorPresets)
            colorPickerSection("Lyrics Color", color: $settings.lyricsColor, presets: DisplaySettings.lyricsColorPresets)
            colorPickerSection("Section Labels", color: $settings.sectionLabelColor, presets: DisplaySettings.sectionLabelColorPresets)
            colorPickerSection("Metadata", color: $settings.metadataColor, presets: DisplaySettings.metadataColorPresets)
            colorPickerSection("Background", color: $settings.backgroundColor, presets: DisplaySettings.backgroundColorPresets)

            // Color Blind Friendly Presets
            Section {
                ForEach(DisplaySettings.colorBlindFriendlyPresets, id: \.name) { preset in
                    Button {
                        settings.chordColor = preset.chordHex
                        settings.lyricsColor = preset.lyricsHex
                        hasChanges = true
                        HapticManager.shared.selection()
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: preset.chordHex) ?? .blue)
                                .frame(width: 24, height: 24)
                            Circle()
                                .fill(Color(hex: preset.lyricsHex) ?? .black)
                                .frame(width: 24, height: 24)
                            Text(preset.name)
                            Spacer()
                        }
                    }
                }
            } header: {
                Text("Color Blind Friendly Presets")
            }
        }
    }

    @ViewBuilder
    private func colorPickerSection(_ title: String, color: Binding<String>, presets: [(name: String, hex: String)]) -> some View {
        Section {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(presets, id: \.hex) { preset in
                    ColorSwatch(
                        name: preset.name,
                        hex: preset.hex,
                        isSelected: color.wrappedValue == preset.hex
                    ) {
                        color.wrappedValue = preset.hex
                        hasChanges = true
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text(title)
        }
    }

    // MARK: - Layout Section

    private var layoutSection: some View {
        Form {
            // Line Spacing
            Section {
                Picker("Line Spacing", selection: $settings.lineSpacing) {
                    ForEach(LineSpacingOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .onChange(of: settings.lineSpacing) { _, _ in hasChanges = true }
            } header: {
                Text("Line Spacing")
            }

            // Chord-Lyrics Spacing
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Spacing")
                        Spacer()
                        Text("\(Int(settings.spacing)) pt")
                            .fontWeight(.medium)
                    }
                    Slider(value: $settings.spacing, in: 4...16, step: 1)
                        .onChange(of: settings.spacing) { _, _ in hasChanges = true }
                }
            } header: {
                Text("Chord-Lyrics Spacing")
            }

            // Section Spacing
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Spacing")
                        Spacer()
                        Text("\(Int(settings.sectionSpacing)) pt")
                            .fontWeight(.medium)
                    }
                    Slider(value: $settings.sectionSpacing, in: 16...64, step: 4)
                        .onChange(of: settings.sectionSpacing) { _, _ in hasChanges = true }
                }
            } header: {
                Text("Section Spacing")
            }

            // Margins
            Section {
                marginSlider("Left", value: $settings.leftMargin)
                marginSlider("Right", value: $settings.rightMargin)
                marginSlider("Top", value: $settings.topMargin)
                marginSlider("Bottom", value: $settings.bottomMargin)
            } header: {
                Text("Margins")
            }

            // Two Column Mode
            Section {
                Toggle("Two Column Layout", isOn: $settings.twoColumnMode)
                    .onChange(of: settings.twoColumnMode) { _, _ in hasChanges = true }
            } header: {
                Text("Layout Mode")
            } footer: {
                Text("Display lyrics in two columns on wide screens")
            }

            // Dark Mode
            Section {
                Picker("Dark Mode", selection: $settings.darkModePreference) {
                    ForEach(DarkModePreference.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .onChange(of: settings.darkModePreference) { _, _ in hasChanges = true }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Control when dark mode is used. 'Always Light' is recommended for stage performance.")
            }
        }
    }

    @ViewBuilder
    private func marginSlider(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue)) pt")
                    .fontWeight(.medium)
            }
            Slider(value: value, in: 0...48, step: 4)
                .onChange(of: value.wrappedValue) { _, _ in hasChanges = true }
        }
    }

    // MARK: - Dark Mode Section

    private var darkModeSection: some View {
        Form {
            Section {
                Picker("Dark Mode", selection: $settings.darkModePreference) {
                    ForEach(DarkModePreference.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .onChange(of: settings.darkModePreference) { _, _ in hasChanges = true }
            } header: {
                Text("Dark Mode Preference")
            } footer: {
                Text("Control when dark mode is used. 'Always Light' is recommended for stage performance.")
            }

            Section {
                VStack(alignment: .leading, spacing: 16) {
                    previewCard(title: "Light Mode Preview", scheme: .light)
                    previewCard(title: "Dark Mode Preview", scheme: .dark)
                }
            } header: {
                Text("Preview")
            }
        }
    }

    @ViewBuilder
    private func previewCard(title: String, scheme: ColorScheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Amazing Grace")
                    .font(settings.titleFont(size: 18))
                    .foregroundStyle(scheme == .dark ? .white : .black)

                Text("[G]How sweet [C]the sound")
                    .font(settings.chordsFont())
                    .foregroundStyle(settings.chordColorValue())

                Text("That saved a wretch like me")
                    .font(settings.lyricsFont())
                    .foregroundStyle(scheme == .dark ? .white : .black)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(scheme == .dark ? Color.black : settings.backgroundColorValue())
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Accessibility Section

    private var accessibilitySection: some View {
        Form {
            Section {
                Toggle("High Contrast Mode", isOn: $settings.highContrastMode)
                    .onChange(of: settings.highContrastMode) { _, _ in hasChanges = true }

                Toggle("Reduce Transparency", isOn: $settings.reduceTransparency)
                    .onChange(of: settings.reduceTransparency) { _, _ in hasChanges = true }

                Toggle("Bold Text", isOn: $settings.boldText)
                    .onChange(of: settings.boldText) { _, _ in hasChanges = true }

                Toggle("Color Blind Friendly", isOn: $settings.colorBlindFriendly)
                    .onChange(of: settings.colorBlindFriendly) { _, _ in hasChanges = true }
            } header: {
                Text("Visual Enhancements")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Minimum Font Size")
                        Spacer()
                        Text("\(Int(settings.minimumFontSize)) pt")
                            .fontWeight(.medium)
                    }
                    Slider(value: $settings.minimumFontSize, in: 12...24, step: 1)
                        .onChange(of: settings.minimumFontSize) { _, _ in hasChanges = true }
                }
            } header: {
                Text("Font Size Limits")
            } footer: {
                Text("Ensures text never becomes too small to read")
            }

            Section {
                accessibilityPreview
            } header: {
                Text("Preview with Accessibility Features")
            }
        }
    }

    private var accessibilityPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amazing Grace")
                .font(settings.titleFont(size: 24))
                .fontWeight(settings.boldText ? .bold : .regular)

            Text("[G]Sample [C]chord")
                .font(settings.chordsFont())
                .foregroundStyle(settings.chordColorValue())
                .fontWeight(settings.boldText ? .bold : .regular)

            Text("Sample lyrics with accessibility")
                .font(settings.lyricsFont())
                .foregroundStyle(settings.lyricsColorValue())
                .fontWeight(settings.boldText ? .bold : .regular)

            if settings.highContrastMode {
                Text("✓ High Contrast Active")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(settings.backgroundColorValue().opacity(settings.reduceTransparency ? 1.0 : 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        Form {
            Section {
                presetButton("Default", preset: .default)
                presetButton("Stage Performance", preset: .stagePerformance)
                presetButton("Practice", preset: .practice)
                presetButton("Large Print", preset: .largePrint)
            } header: {
                Text("Built-in Presets")
            } footer: {
                Text("Tap a preset to apply its settings")
            }

            Section {
                Button {
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
            } header: {
                Text("Actions")
            }
        }
    }

    @ViewBuilder
    private func presetButton(_ name: String, preset: DisplaySettings) -> some View {
        Button {
            settings = preset
            hasChanges = true
            HapticManager.shared.success()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)

                    Text(presetDescription(preset))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func presetDescription(_ preset: DisplaySettings) -> String {
        if preset == .default {
            return "Standard settings for general use"
        } else if preset == .stagePerformance {
            return "High visibility, bold text, always light mode"
        } else if preset == .practice {
            return "Comfortable reading with Charter font"
        } else if preset == .largePrint {
            return "Large text with accessibility features"
        }
        return ""
    }

    // MARK: - Actions

    private func saveSettings() {
        song.displaySettings = settings

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("❌ Error saving display settings: \(error.localizedDescription)")
            errorMessage = "Unable to save display settings. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func resetToDefaults() {
        settings = .default
        hasChanges = true
        HapticManager.shared.selection()
    }

    private func setAsGlobalDefault() {
        UserDefaults.standard.globalDisplaySettings = settings
        hasChanges = true
        HapticManager.shared.success()
    }

    private func clearCustomSettings() {
        song.clearCustomDisplaySettings()
        settings = UserDefaults.standard.globalDisplaySettings

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("❌ Error clearing custom settings: \(error.localizedDescription)")
            errorMessage = "Unable to clear custom settings. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }

        hasChanges = true
    }
}

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case fonts = "Fonts"
    case colors = "Colors"
    case layout = "Layout"
    case accessibility = "Access"
    case presets = "Presets"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fonts: return "textformat"
        case .colors: return "paintpalette"
        case .layout: return "rectangle.split.3x1"
        case .accessibility: return "accessibility"
        case .presets: return "star"
        }
    }
}
// MARK: - Preview

#Preview {
    DisplaySettingsSheet(song: Song(
        title: "Amazing Grace",
        artist: "John Newton",
        content: "{verse}\n[G]Amazing [C]grace",
        originalKey: "G"
    ))
    .modelContainer(PreviewContainer.shared.container)
}
