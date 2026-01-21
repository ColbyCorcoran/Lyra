//
//  SectionSpeedZoneEditorView.swift
//  Lyra
//
//  Visual editor for section-specific autoscroll speed zones
//

import SwiftUI
import SwiftData

struct SectionSpeedZoneEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let parsedSong: ParsedSong

    @State private var sectionConfigs: [UUID: SectionAutoscrollConfig] = [:]
    @State private var hasChanges: Bool = false

    init(song: Song, parsedSong: ParsedSong) {
        self.song = song
        self.parsedSong = parsedSong

        // Load existing configurations
        var configs: [UUID: SectionAutoscrollConfig] = [:]
        if let advancedConfig = song.autoscrollConfiguration {
            for config in advancedConfig.sectionConfigs {
                configs[config.sectionId] = config
            }
        }
        _sectionConfigs = State(initialValue: configs)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Overview Section
                Section {
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .foregroundStyle(.blue)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Speed Zones")
                                .font(.headline)

                            Text("Configure playback speed for each section")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Overview")
                }

                // Sections List
                Section {
                    ForEach(Array(parsedSong.sections.enumerated()), id: \.element.id) { index, section in
                        sectionConfigRow(section: section, index: index)
                    }
                } header: {
                    Text("Sections")
                } footer: {
                    Text("Adjust speed and pause behavior for each section. Speed multipliers stack with global speed settings.")
                }

                // Quick Presets
                Section {
                    Button {
                        applyPreset(.uniform)
                    } label: {
                        HStack {
                            Image(systemName: "equal.square")
                            Text("Uniform Speed")
                            Spacer()
                            Text("1.0x all sections")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        applyPreset(.versesFaster)
                    } label: {
                        HStack {
                            Image(systemName: "hare")
                            Text("Verses Faster")
                            Spacer()
                            Text("Verses 1.25x, Chorus 0.9x")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        applyPreset(.chorusFaster)
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                            Text("Chorus Faster")
                            Spacer()
                            Text("Chorus 1.25x, Verses 0.9x")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        applyPreset(.pauseAtChorus)
                    } label: {
                        HStack {
                            Image(systemName: "pause.circle")
                            Text("Pause at Chorus")
                            Spacer()
                            Text("Auto-resume after 3s")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Quick Presets")
                }

                // Reset
                Section {
                    Button(role: .destructive) {
                        resetAllConfigs()
                    } label: {
                        Label("Reset All Sections", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Speed Zones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfigs()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
        }
    }

    // MARK: - Section Config Row

    @ViewBuilder
    private func sectionConfigRow(section: SongSection, index: Int) -> some View {
        NavigationLink {
            SectionConfigDetailView(
                section: section,
                config: Binding(
                    get: { getOrCreateConfig(for: section) },
                    set: { updateConfig($0, for: section) }
                )
            )
        } label: {
            HStack(spacing: 12) {
                // Section icon
                ZStack {
                    Circle()
                        .fill(sectionColor(for: section.type).opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(sectionAbbreviation(for: section.type))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(sectionColor(for: section.type))
                }

                // Section info
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.label)
                        .font(.body)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        let config = getOrCreateConfig(for: section)

                        // Speed indicator
                        HStack(spacing: 4) {
                            Image(systemName: speedIcon(for: config.speedMultiplier))
                                .font(.caption2)

                            Text(String(format: "%.2fx", config.speedMultiplier))
                                .font(.caption)
                                .monospacedDigit()
                        }
                        .foregroundStyle(speedColor(for: config.speedMultiplier))

                        // Pause indicator
                        if config.pauseAtStart {
                            HStack(spacing: 4) {
                                Image(systemName: "pause.circle.fill")
                                    .font(.caption2)

                                if let duration = config.pauseDuration {
                                    Text("\(Int(duration))s")
                                        .font(.caption)
                                } else {
                                    Text("Manual")
                                        .font(.caption)
                                }
                            }
                            .foregroundStyle(.orange)
                        }

                        // Disabled indicator
                        if !config.isEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "slash.circle")
                                    .font(.caption2)
                                Text("Disabled")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Helper Methods

    private func getOrCreateConfig(for section: SongSection) -> SectionAutoscrollConfig {
        if let config = sectionConfigs[section.id] {
            return config
        }
        return SectionAutoscrollConfig(sectionId: section.id)
    }

    private func updateConfig(_ config: SectionAutoscrollConfig, for section: SongSection) {
        sectionConfigs[section.id] = config
        hasChanges = true
    }

    private func saveConfigs() {
        // Get or create advanced config
        var advancedConfig = song.autoscrollConfiguration ?? AdvancedAutoscrollConfig()

        // Update section configs
        advancedConfig.sectionConfigs = Array(sectionConfigs.values)

        // Save to song
        song.autoscrollConfiguration = advancedConfig
        song.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Failed to save section configs: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func resetAllConfigs() {
        sectionConfigs.removeAll()
        hasChanges = true

        HapticManager.shared.notification(.warning)
    }

    // MARK: - Presets

    enum SpeedPreset {
        case uniform
        case versesFaster
        case chorusFaster
        case pauseAtChorus
    }

    private func applyPreset(_ preset: SpeedPreset) {
        for section in parsedSong.sections {
            let config: SectionAutoscrollConfig

            switch preset {
            case .uniform:
                config = SectionAutoscrollConfig(
                    sectionId: section.id,
                    speedMultiplier: 1.0
                )

            case .versesFaster:
                let speed = section.type == .verse ? 1.25 : 0.9
                config = SectionAutoscrollConfig(
                    sectionId: section.id,
                    speedMultiplier: speed
                )

            case .chorusFaster:
                let speed = section.type == .chorus ? 1.25 : 0.9
                config = SectionAutoscrollConfig(
                    sectionId: section.id,
                    speedMultiplier: speed
                )

            case .pauseAtChorus:
                let shouldPause = section.type == .chorus
                config = SectionAutoscrollConfig(
                    sectionId: section.id,
                    pauseAtStart: shouldPause,
                    pauseDuration: shouldPause ? 3.0 : nil
                )
            }

            sectionConfigs[section.id] = config
        }

        hasChanges = true
        HapticManager.shared.success()
    }

    // MARK: - Visual Helpers

    private func sectionColor(for type: SectionType) -> Color {
        switch type {
        case .verse: return .blue
        case .chorus: return .purple
        case .bridge: return .orange
        case .prechorus: return .teal
        case .intro, .outro: return .green
        case .instrumental: return .pink
        default: return .gray
        }
    }

    private func sectionAbbreviation(for type: SectionType) -> String {
        switch type {
        case .verse: return "V"
        case .chorus: return "C"
        case .bridge: return "B"
        case .prechorus: return "PC"
        case .intro: return "I"
        case .outro: return "O"
        case .instrumental: return "♪"
        default: return "?"
        }
    }

    private func speedIcon(for multiplier: Double) -> String {
        if multiplier < 0.9 {
            return "tortoise"
        } else if multiplier > 1.1 {
            return "hare"
        } else {
            return "equal"
        }
    }

    private func speedColor(for multiplier: Double) -> Color {
        if multiplier < 0.9 {
            return .orange
        } else if multiplier > 1.1 {
            return .green
        } else {
            return .primary
        }
    }
}

// MARK: - Section Config Detail View

struct SectionConfigDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let section: SongSection
    @Binding var config: SectionAutoscrollConfig

    var body: some View {
        Form {
            // Section Info
            Section {
                HStack {
                    Text("Section")
                    Spacer()
                    Text(section.label)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Type")
                    Spacer()
                    Text(section.type.displayName)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Section Information")
            }

            // Speed Configuration
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Speed Multiplier")
                            .font(.subheadline)

                        Spacer()

                        Text(String(format: "%.2fx", config.speedMultiplier))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(.blue)
                    }

                    Slider(value: $config.speedMultiplier, in: 0.5...2.0, step: 0.05)

                    // Speed presets
                    HStack(spacing: 8) {
                        ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                            Button {
                                config.speedMultiplier = speed
                                HapticManager.shared.selection()
                            } label: {
                                Text("\(String(format: "%.2f", speed))x")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        abs(config.speedMultiplier - speed) < 0.01 ?
                                        Color.blue.opacity(0.2) : Color(.systemGray6)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                Text("Speed")
            } footer: {
                Text("Adjust playback speed for this section. This multiplies with the global speed setting.")
            }

            // Pause Configuration
            Section {
                Toggle("Pause at Start", isOn: $config.pauseAtStart)

                if config.pauseAtStart {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Auto-resume Duration")
                            .font(.subheadline)

                        Picker("Duration", selection: Binding(
                            get: { config.pauseDuration ?? -1 },
                            set: { config.pauseDuration = $0 >= 0 ? $0 : nil }
                        )) {
                            Text("Manual Resume").tag(-1.0)
                            Text("1 second").tag(1.0)
                            Text("2 seconds").tag(2.0)
                            Text("3 seconds").tag(3.0)
                            Text("5 seconds").tag(5.0)
                            Text("10 seconds").tag(10.0)
                        }
                        .pickerStyle(.menu)
                    }
                }
            } header: {
                Text("Pause Behavior")
            } footer: {
                Text("Automatically pause when entering this section. Choose manual resume or set an auto-resume duration.")
            }

            // Enable/Disable
            Section {
                Toggle("Enable Section", isOn: $config.isEnabled)
            } footer: {
                Text("Disabled sections will be skipped during autoscroll")
            }
        }
        .navigationTitle(section.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

    // Create sample parsed song
    let sections = [
        SongSection(type: .verse, lines: [], index: 1),
        SongSection(type: .chorus, lines: [], index: 1),
        SongSection(type: .verse, lines: [], index: 2),
        SongSection(type: .bridge, lines: [], index: 1)
    ]
    let parsedSong = ParsedSong(
        title: song.title,
        subtitle: nil,
        artist: song.artist,
        album: nil,
        key: song.originalKey,
        originalKey: song.originalKey,
        tempo: song.tempo,
        timeSignature: song.timeSignature,
        capo: song.capo,
        year: song.year,
        copyright: song.copyright,
        ccliNumber: song.ccliNumber,
        composer: nil,
        lyricist: nil,
        arranger: nil,
        sections: sections,
        rawText: song.content
    )

    return SectionSpeedZoneEditorView(song: song, parsedSong: parsedSong)
        .modelContainer(container)
}
