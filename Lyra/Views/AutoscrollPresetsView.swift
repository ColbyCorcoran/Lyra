//
//  AutoscrollPresetsView.swift
//  Lyra
//
//  Manage and apply autoscroll presets
//

import SwiftUI
import SwiftData

struct AutoscrollPresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song
    @ObservedObject var autoscrollManager: AutoscrollManager

    @State private var presets: [AutoscrollPreset] = []
    @State private var activePresetId: UUID? = nil
    @State private var showCreatePreset: Bool = false
    @State private var presetName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Active Preset Section
                if let activeId = activePresetId, let preset = presets.first(where: { $0.id == activeId }) {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.name)
                                    .font(.headline)

                                Text("Currently Active")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                deactivatePreset()
                            } label: {
                                Text("Deactivate")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    } header: {
                        Text("Active Preset")
                    }
                }

                // Presets List
                if presets.isEmpty {
                    Section {
                        emptyState
                    }
                } else {
                    Section {
                        ForEach(presets) { preset in
                            presetRow(preset)
                        }
                        .onDelete(perform: deletePresets)
                    } header: {
                        Text("Saved Presets")
                    } footer: {
                        Text("Tap a preset to apply it. Long press for more options.")
                    }
                }

                // Create Preset
                Section {
                    Button {
                        showCreatePreset = true
                    } label: {
                        Label("Save Current as Preset", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                } footer: {
                    Text("Save your current autoscroll configuration (speed zones, timeline, markers) as a preset for quick access.")
                }

                // Info
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                                .foregroundStyle(.blue)
                            Text("Speed zones for each section")
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "waveform")
                                .foregroundStyle(.blue)
                            Text("Recorded timeline patterns")
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle")
                                .foregroundStyle(.blue)
                            Text("Smart pause markers")
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.blue)
                            Text("Default duration and speed")
                        }
                    }
                    .font(.caption)
                } header: {
                    Text("What's Included in a Preset")
                }
            }
            .navigationTitle("Autoscroll Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPresets()
            }
            .alert("Save Preset", isPresented: $showCreatePreset) {
                TextField("Preset Name", text: $presetName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    createPreset()
                }
            } message: {
                Text("Give this preset a memorable name")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 60))
                .foregroundStyle(.purple)

            VStack(spacing: 8) {
                Text("No Saved Presets")
                    .font(.headline)

                Text("Save your autoscroll configuration as a preset for quick access later")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Preset Row

    @ViewBuilder
    private func presetRow(_ preset: AutoscrollPreset) -> some View {
        Button {
            applyPreset(preset)
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(preset.id == activePresetId ? Color.green.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 40, height: 40)

                    Image(systemName: preset.id == activePresetId ? "checkmark.circle.fill" : "square.stack.3d.up")
                        .foregroundStyle(preset.id == activePresetId ? .green : .secondary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        if !preset.sectionConfigs.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "gauge.with.dots.needle.67percent")
                                    .font(.caption2)
                                Text("\(preset.sectionConfigs.count) zones")
                                    .font(.caption)
                            }
                        }

                        if preset.useTimeline, preset.timeline != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "waveform")
                                    .font(.caption2)
                                Text("Timeline")
                                    .font(.caption)
                            }
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(formatDuration(preset.defaultDuration))
                                .font(.caption)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .font(.caption2)
                            Text(String(format: "%.2fx", preset.defaultSpeed))
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                applyPreset(preset)
            } label: {
                Label("Apply Preset", systemImage: "checkmark")
            }

            Button {
                duplicatePreset(preset)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Button(role: .destructive) {
                if let index = presets.firstIndex(where: { $0.id == preset.id }) {
                    deletePresets(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func createPreset() {
        guard !presetName.isEmpty else { return }

        // Get current configuration
        var config = song.autoscrollConfiguration ?? AdvancedAutoscrollConfig()

        // Create preset from current settings
        let preset = AutoscrollPreset(
            name: presetName,
            defaultDuration: TimeInterval(song.autoscrollDuration ?? 180),
            defaultSpeed: autoscrollManager.speedMultiplier,
            sectionConfigs: config.sectionConfigs,
            timeline: nil, // Timeline would be selected separately
            useTimeline: false,
            loopAtEnd: false
        )

        presets.append(preset)
        presetName = ""
        savePresets()

        HapticManager.shared.success()
    }

    private func applyPreset(_ preset: AutoscrollPreset) {
        // Get or create configuration
        var config = song.autoscrollConfiguration ?? AdvancedAutoscrollConfig()

        // Set active preset
        config.activePresetId = preset.id
        activePresetId = preset.id

        // Apply preset settings to song
        song.autoscrollDuration = Int(preset.defaultDuration)
        config.sectionConfigs = preset.sectionConfigs

        // Apply to manager
        autoscrollManager.setSpeed(preset.defaultSpeed)

        if preset.useTimeline, let timeline = preset.timeline {
            autoscrollManager.configureTimeline(timeline, enabled: true)
        }

        // Save
        song.autoscrollConfiguration = config
        song.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("Failed to apply preset: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func deactivatePreset() {
        var config = song.autoscrollConfiguration ?? AdvancedAutoscrollConfig()
        config.activePresetId = nil
        activePresetId = nil

        song.autoscrollConfiguration = config

        do {
            try modelContext.save()
            HapticManager.shared.notification(.warning)
        } catch {
            print("Failed to deactivate preset: \(error)")
        }
    }

    private func duplicatePreset(_ preset: AutoscrollPreset) {
        var duplicate = preset
        duplicate = AutoscrollPreset(
            name: "\(preset.name) Copy",
            defaultDuration: preset.defaultDuration,
            defaultSpeed: preset.defaultSpeed,
            sectionConfigs: preset.sectionConfigs,
            timeline: preset.timeline,
            useTimeline: preset.useTimeline,
            loopAtEnd: preset.loopAtEnd
        )

        presets.append(duplicate)
        savePresets()

        HapticManager.shared.success()
    }

    private func deletePresets(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        savePresets()

        HapticManager.shared.notification(.warning)
    }

    // MARK: - Persistence

    private func loadPresets() {
        guard let config = song.autoscrollConfiguration else { return }
        presets = config.presets
        activePresetId = config.activePresetId
    }

    private func savePresets() {
        var config = song.autoscrollConfiguration ?? AdvancedAutoscrollConfig()
        config.presets = presets

        song.autoscrollConfiguration = config
        song.modifiedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Failed to save presets: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!
    let manager = AutoscrollManager()

    return AutoscrollPresetsView(song: song, autoscrollManager: manager)
        .modelContainer(container)
}
