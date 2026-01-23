//
//  MIDISettingsView.swift
//  Lyra
//
//  User interface for MIDI configuration and device selection
//

import SwiftUI

struct MIDISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var midiManager = MIDIManager.shared
    @State private var controlManager = MIDIControlManager.shared

    @State private var showMonitor = false
    @State private var showControlMapping = false
    @State private var showScenes = false

    var body: some View {
        NavigationStack {
            Form {
                // Enable MIDI
                Section {
                    Toggle("Enable MIDI", isOpen: $midiManager.isEnabled)
                        .onChange(of: midiManager.isEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    await midiManager.setup()
                                }
                            }
                            midiManager.saveSettings()
                        }

                    if midiManager.isEnabled {
                        HStack {
                            Image(systemName: midiManager.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(midiManager.isConnected ? .green : .red)

                            Text(midiManager.isConnected ? "Connected" : "Not Connected")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("MIDI Status")
                } footer: {
                    Text("Enable MIDI to control external keyboards, effects, and equipment")
                }

                // Input Device
                if midiManager.isEnabled {
                    Section {
                        if midiManager.inputDevices.isEmpty {
                            ContentUnavailableView(
                                "No Input Devices",
                                systemImage: "pianokeys",
                                description: Text("Connect a MIDI device to get started")
                            )
                        } else {
                            ForEach(midiManager.inputDevices) { device in
                                Button {
                                    midiManager.connectToInputDevice(device)
                                } label: {
                                    MIDIDeviceRow(
                                        device: device,
                                        isSelected: midiManager.selectedInputDevice?.id == device.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            Task {
                                await midiManager.scanDevices()
                            }
                        } label: {
                            Label("Rescan Devices", systemImage: "arrow.clockwise")
                        }
                    } header: {
                        Text("Input Devices (\(midiManager.inputDevices.count))")
                    } footer: {
                        Text("Select a device to receive MIDI messages")
                    }

                    // Output Device
                    Section {
                        if midiManager.outputDevices.isEmpty {
                            ContentUnavailableView(
                                "No Output Devices",
                                systemImage: "pianokeys",
                                description: Text("Connect a MIDI device to send messages")
                            )
                        } else {
                            ForEach(midiManager.outputDevices) { device in
                                Button {
                                    midiManager.selectedOutputDevice = device
                                } label: {
                                    MIDIDeviceRow(
                                        device: device,
                                        isSelected: midiManager.selectedOutputDevice?.id == device.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("Output Devices (\(midiManager.outputDevices.count))")
                    } footer: {
                        Text("Select a device to send MIDI messages")
                    }

                    // Channel Selection
                    Section {
                        Picker("MIDI Channel", selection: $midiManager.selectedChannel) {
                            ForEach(1...16, id: \.self) { channel in
                                Text("Channel \(channel)").tag(UInt8(channel))
                            }
                        }
                        .onChange(of: midiManager.selectedChannel) { _, _ in
                            midiManager.saveSettings()
                        }
                    } header: {
                        Text("Channel")
                    } footer: {
                        Text("Default MIDI channel for sending messages (1-16)")
                    }

                    // MIDI Control Features
                    Section {
                        NavigationLink {
                            MIDIControlMappingView()
                        } label: {
                            HStack {
                                Label("Control Mapping", systemImage: "slider.horizontal.3")
                                Spacer()
                                if controlManager.enabledMappingsCount > 0 {
                                    Text("\(controlManager.enabledMappingsCount)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        NavigationLink {
                            MIDISceneView()
                        } label: {
                            HStack {
                                Label("MIDI Scenes", systemImage: "wand.and.stars")
                                Spacer()
                                if controlManager.activeScenesCount > 0 {
                                    Text("\(controlManager.activeScenesCount)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("MIDI Control")
                    } footer: {
                        Text("Map MIDI controls to Lyra functions and create scenes for lighting and effects")
                    }

                    // Monitoring
                    Section {
                        Toggle("Monitor MIDI Messages", isOn: $midiManager.isMonitoring)
                            .onChange(of: midiManager.isMonitoring) { _, _ in
                                midiManager.saveSettings()
                            }

                        if midiManager.isMonitoring {
                            Button {
                                showMonitor = true
                            } label: {
                                Label("View MIDI Monitor", systemImage: "waveform")
                            }

                            ActivityIndicatorRow(
                                title: "Input Activity",
                                lastActivity: midiManager.lastInputActivity,
                                icon: "arrow.down.circle.fill",
                                color: .blue
                            )

                            ActivityIndicatorRow(
                                title: "Output Activity",
                                lastActivity: midiManager.lastOutputActivity,
                                icon: "arrow.up.circle.fill",
                                color: .green
                            )
                        }
                    } header: {
                        Text("Monitoring")
                    } footer: {
                        Text("View incoming and outgoing MIDI messages for debugging")
                    }

                    // Testing
                    Section {
                        Button {
                            midiManager.testConnection()
                        } label: {
                            Label("Test MIDI Connection", systemImage: "checkmark.circle")
                        }
                        .disabled(!midiManager.isConnected || midiManager.selectedOutputDevice == nil)

                        Button {
                            midiManager.sendAllNotesOff()
                        } label: {
                            Label("All Notes Off", systemImage: "speaker.slash")
                        }
                        .disabled(!midiManager.isConnected || midiManager.selectedOutputDevice == nil)

                        Button {
                            midiManager.sendAllSoundOff()
                        } label: {
                            Label("All Sound Off", systemImage: "speaker.wave.2.fill")
                        }
                        .disabled(!midiManager.isConnected || midiManager.selectedOutputDevice == nil)
                    } header: {
                        Text("Testing")
                    } footer: {
                        Text("Test sends a middle C note to verify connection")
                    }
                }
            }
            .navigationTitle("MIDI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMonitor) {
                MIDIMonitorView()
            }
            .task {
                if midiManager.isEnabled && !midiManager.isConnected {
                    await midiManager.setup()
                }
            }
        }
    }
}

// MARK: - MIDI Device Row

struct MIDIDeviceRow: View {
    let device: MIDIDevice
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.icon)
                .font(.title3)
                .foregroundStyle(device.isConnected ? .blue : .gray)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                HStack(spacing: 8) {
                    if let manufacturer = device.manufacturer {
                        Text(manufacturer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(device.typeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Activity Indicator Row

struct ActivityIndicatorRow: View {
    let title: String
    let lastActivity: Date?
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isActive ? color : .gray)

            Text(title)

            Spacer()

            if let lastActivity = lastActivity {
                Text(lastActivity, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No activity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var isActive: Bool {
        guard let lastActivity = lastActivity else { return false }
        return Date().timeIntervalSince(lastActivity) < 2.0
    }
}

// MARK: - Preview

#Preview {
    MIDISettingsView()
}
