//
//  SettingsView.swift
//  Lyra
//
//  Global app settings and preferences
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("globalFontSize") private var globalFontSize: Double = 16
    @AppStorage("globalChordColor") private var globalChordColor: String = "#007AFF"
    @AppStorage("globalLyricsColor") private var globalLyricsColor: String = "#000000"
    @AppStorage("globalSpacing") private var globalSpacing: Double = 8

    @State private var showAutoscrollSettings: Bool = false
    @State private var showAccessibilitySettings: Bool = false
    @State private var showHelp: Bool = false
    @State private var showWhatsNew: Bool = false
    @State private var shareItem: SettingsShareItem?
    @State private var isExporting: Bool = false
    @State private var exportError: Error?
    @State private var showError: Bool = false
    @State private var showFolderManagement: Bool = false
    @State private var showVenueManagement: Bool = false
    @State private var showTemplateLibrary: Bool = false
    @State private var showBackupManagement: Bool = false
    @State private var showOnSongImport: Bool = false
    @State private var showBulkExport: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Song Display Section
                Section {
                    Button {
                        showAutoscrollSettings = true
                    } label: {
                        HStack {
                            Label("Autoscroll Settings", systemImage: "play.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

                    Button {
                        showAccessibilitySettings = true
                    } label: {
                        HStack {
                            Label("Accessibility", systemImage: "accessibility")
                            Spacer()
                            if AccessibilityManager.shared.isAccessibilityTechnologyActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Label("Song Display", systemImage: "music.note")
                } footer: {
                    Text("Configure autoscroll and accessibility features for viewing songs")
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

                // Templates Section
                Section {
                    Button {
                        showTemplateLibrary = true
                    } label: {
                        HStack {
                            Label("Template Library", systemImage: "rectangle.3.group")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Label("Templates", systemImage: "doc.richtext")
                } footer: {
                    Text("Manage column layouts, typography, and chord positioning templates for your songs.")
                }

                // Data Management Section
                Section {
                    Button {
                        showBackupManagement = true
                    } label: {
                        HStack {
                            Label("Backup & Restore", systemImage: "externaldrive")
                            Spacer()
                            if let lastBackup = BackupManager.shared.lastBackupDate {
                                Text(lastBackup, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

                    Button {
                        showOnSongImport = true
                    } label: {
                        HStack {
                            Label("Import from OnSong", systemImage: "arrow.down.doc")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

                    Button {
                        showBulkExport = true
                    } label: {
                        HStack {
                            Label("Export Library", systemImage: "square.and.arrow.up")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Label("Data Management", systemImage: "server.rack")
                } footer: {
                    Text("Backup your library, import OnSong files, or export your entire song collection.")
                }

                // Recurring Sets Section
                RecurringSetPreferencesSection()

                // Set Organization Section
                Section {
                    Button {
                        showFolderManagement = true
                    } label: {
                        HStack {
                            Label("Manage Folders", systemImage: "folder")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

                    Button {
                        showVenueManagement = true
                    } label: {
                        HStack {
                            Label("Manage Venues", systemImage: "mappin.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Label("Set Organization", systemImage: "list.bullet.rectangle")
                } footer: {
                    Text("Manage folder and venue names. Deleting a folder or venue will remove it from sets, but the sets themselves will remain.")
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
                    Button {
                        showHelp = true
                    } label: {
                        HStack {
                            Label("Help & Support", systemImage: "questionmark.circle.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

                    Button {
                        showWhatsNew = true
                    } label: {
                        HStack {
                            Label("What's New", systemImage: "sparkles")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

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
            .sheet(isPresented: $showAutoscrollSettings) {
                AutoscrollSettingsView()
            }
            .sheet(isPresented: $showAccessibilitySettings) {
                AccessibilitySettingsView()
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewView()
            }
            .sheet(isPresented: $showFolderManagement) {
                FolderManagementView()
            }
            .sheet(isPresented: $showVenueManagement) {
                VenueManagementView()
            }
            .sheet(isPresented: $showTemplateLibrary) {
                NavigationStack {
                    TemplateLibraryView()
                }
            }
            .sheet(isPresented: $showBackupManagement) {
                BackupManagementView()
            }
            .sheet(isPresented: $showOnSongImport) {
                OnSongImportView()
            }
            .sheet(isPresented: $showBulkExport) {
                BulkExportView()
            }
            .sheet(item: $shareItem) { (item: SettingsShareItem) in
                SettingsShareSheet(activityItems: item.items)
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Actions

    private func saveGlobalSettings() {
        var settings = UserDefaults.standard.globalDisplaySettings
        settings.fontSize = globalFontSize
        settings.chordColor = globalChordColor
        settings.lyricsColor = globalLyricsColor
        settings.spacing = globalSpacing
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

// MARK: - Share Sheet

private struct SettingsShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

private struct SettingsShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Recurring Set Preferences Section

struct RecurringSetPreferencesSection: View {
    @AppStorage("recurringInstanceGenerationMonths") private var recurringInstanceGenerationMonths: Int = 3

    var body: some View {
        Section {
            Picker("Generate Recurring Sets", selection: $recurringInstanceGenerationMonths) {
                Text("1 month ahead").tag(1)
                Text("2 months ahead").tag(2)
                Text("3 months ahead").tag(3)
                Text("6 months ahead").tag(6)
                Text("12 months ahead").tag(12)
            }
        } header: {
            Label("Recurring Sets", systemImage: "repeat")
        } footer: {
            Text("Controls how far in advance recurring set instances are generated. More months will create more instances but use more storage.")
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
