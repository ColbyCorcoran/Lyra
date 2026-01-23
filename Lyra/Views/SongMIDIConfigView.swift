//
//  SongMIDIConfigView.swift
//  Lyra
//
//  Configure MIDI messages to send when a song is loaded
//

import SwiftUI
import SwiftData

struct SongMIDIConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var song: Song

    @State private var midiManager = MIDIManager.shared
    @State private var config: SongMIDIConfiguration
    @State private var showAddCC = false
    @State private var newCCNumber: UInt8 = 7
    @State private var newCCValue: UInt8 = 64

    init(song: Song) {
        self.song = song
        self._config = State(initialValue: song.midiConfiguration)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Enable MIDI for this song
                Section {
                    Toggle("Enable MIDI for This Song", isOn: $config.enabled)

                    if config.enabled {
                        Toggle("Send on Song Load", isOn: $config.sendOnLoad)
                    }
                } footer: {
                    Text("Automatically send MIDI messages when this song is loaded")
                }

                if config.enabled {
                    // MIDI Channel
                    Section {
                        Picker("MIDI Channel", selection: $config.channel) {
                            ForEach(1...16, id: \.self) { channel in
                                Text("Channel \(channel)").tag(UInt8(channel))
                            }
                        }
                    } header: {
                        Text("Channel")
                    } footer: {
                        Text("MIDI channel for this song (1-16)")
                    }

                    // Program Change
                    Section {
                        HStack {
                            Toggle("Program Change", isOn: Binding(
                                get: { config.programChange != nil },
                                set: { enabled in
                                    config.programChange = enabled ? 0 : nil
                                }
                            ))

                            if config.programChange != nil {
                                Spacer()
                                Stepper(
                                    value: Binding(
                                        get: { Int(config.programChange ?? 0) },
                                        set: { config.programChange = UInt8($0) }
                                    ),
                                    in: 0...127
                                ) {
                                    Text("\(config.programChange ?? 0)")
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                    } header: {
                        Text("Program Change")
                    } footer: {
                        Text("Send program/patch number to keyboard (0-127)")
                    }

                    // Bank Select
                    Section {
                        HStack {
                            Toggle("Bank Select MSB", isOn: Binding(
                                get: { config.bankSelectMSB != nil },
                                set: { enabled in
                                    config.bankSelectMSB = enabled ? 0 : nil
                                }
                            ))

                            if config.bankSelectMSB != nil {
                                Spacer()
                                Stepper(
                                    value: Binding(
                                        get: { Int(config.bankSelectMSB ?? 0) },
                                        set: { config.bankSelectMSB = UInt8($0) }
                                    ),
                                    in: 0...127
                                ) {
                                    Text("\(config.bankSelectMSB ?? 0)")
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }

                        HStack {
                            Toggle("Bank Select LSB", isOn: Binding(
                                get: { config.bankSelectLSB != nil },
                                set: { enabled in
                                    config.bankSelectLSB = enabled ? 0 : nil
                                }
                            ))

                            if config.bankSelectLSB != nil {
                                Spacer()
                                Stepper(
                                    value: Binding(
                                        get: { Int(config.bankSelectLSB ?? 0) },
                                        set: { config.bankSelectLSB = UInt8($0) }
                                    ),
                                    in: 0...127
                                ) {
                                    Text("\(config.bankSelectLSB ?? 0)")
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                    } header: {
                        Text("Bank Select")
                    } footer: {
                        Text("Bank selection for multi-bank keyboards (CC 0/32)")
                    }

                    // Control Changes
                    Section {
                        ForEach(Array(config.controlChanges.keys.sorted()), id: \.self) { ccNumber in
                            HStack {
                                Text(ccNameForNumber(ccNumber))
                                    .font(.subheadline)

                                Spacer()

                                Stepper(
                                    value: Binding(
                                        get: { Int(config.controlChanges[ccNumber] ?? 0) },
                                        set: { config.controlChanges[ccNumber] = UInt8($0) }
                                    ),
                                    in: 0...127
                                ) {
                                    Text("CC\(ccNumber): \(config.controlChanges[ccNumber] ?? 0)")
                                        .font(.system(.caption, design: .monospaced))
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    config.controlChanges.removeValue(forKey: ccNumber)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }

                        Button {
                            showAddCC = true
                        } label: {
                            Label("Add Control Change", systemImage: "plus.circle")
                        }
                    } header: {
                        Text("Control Changes (\(config.controlChanges.count))")
                    } footer: {
                        Text("Control change messages (reverb, chorus, volume, etc.)")
                    }

                    // Test Section
                    Section {
                        Button {
                            testMIDIConfiguration()
                        } label: {
                            Label("Test MIDI Messages", systemImage: "waveform")
                        }
                        .disabled(!midiManager.isConnected || midiManager.selectedOutputDevice == nil)
                    } header: {
                        Text("Testing")
                    } footer: {
                        Text("Send MIDI messages to verify configuration")
                    }
                }
            }
            .navigationTitle("MIDI Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMIDIConfiguration()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddCC) {
                AddControlChangeView(
                    ccNumber: $newCCNumber,
                    ccValue: $newCCValue,
                    onAdd: {
                        config.controlChanges[newCCNumber] = newCCValue
                        showAddCC = false
                    }
                )
            }
        }
    }

    private func saveMIDIConfiguration() {
        song.midiConfiguration = config
        print("💾 Saved MIDI configuration for '\(song.title)'")
    }

    private func testMIDIConfiguration() {
        print("🧪 Testing MIDI configuration...")
        midiManager.sendSongMIDI(configuration: config)
    }

    private func ccNameForNumber(_ number: UInt8) -> String {
        if let cc = MIDIControlChange(rawValue: number) {
            return cc.name
        }
        return "CC \(number)"
    }
}

// MARK: - Add Control Change View

struct AddControlChangeView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var ccNumber: UInt8
    @Binding var ccValue: UInt8
    let onAdd: () -> Void

    @State private var selectedPreset: MIDIControlChange?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Control Change", selection: $selectedPreset) {
                        Text("Custom").tag(nil as MIDIControlChange?)

                        ForEach(MIDIControlChange.allCases, id: \.self) { cc in
                            Text(cc.name).tag(cc as MIDIControlChange?)
                        }
                    }
                    .onChange(of: selectedPreset) { _, newValue in
                        if let preset = newValue {
                            ccNumber = preset.rawValue
                        }
                    }

                    HStack {
                        Text("CC Number")
                        Spacer()
                        Stepper(value: $ccNumber, in: 0...127) {
                            Text("\(ccNumber)")
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    HStack {
                        Text("Value")
                        Spacer()
                        Stepper(value: $ccValue, in: 0...127) {
                            Text("\(ccValue)")
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                } header: {
                    Text("Control Change Settings")
                } footer: {
                    Text("CC Number: 0-127, Value: 0-127")
                }
            }
            .navigationTitle("Add Control Change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Song.self, configurations: config)

    let song = Song(title: "Amazing Grace", artist: "John Newton")
    container.mainContext.insert(song)

    return SongMIDIConfigView(song: song)
        .modelContainer(container)
}
