//
//  MIDITriggerEditorView.swift
//  Lyra
//
//  Editor for MIDI triggers with Learn mode
//

import SwiftUI
import SwiftData

struct MIDITriggerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var song: Song

    @State private var triggers: [MIDITrigger]
    @State private var midiSongLoader = MIDISongLoader.shared
    @State private var midiManager = MIDIManager.shared

    @State private var showAddTrigger = false
    @State private var showMappingPresets = false
    @State private var isLearning = false
    @State private var learningMessage: String?

    init(song: Song) {
        self.song = song
        self._triggers = State(initialValue: song.midiTriggers)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Learn Mode Section
                Section {
                    if isLearning {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "waveform.circle.fill")
                                    .symbolEffect(.variableColor.iterative)
                                    .foregroundStyle(.blue)
                                    .font(.title)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Listening for MIDI...")
                                        .font(.headline)

                                    if let message = learningMessage {
                                        Text(message)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Play a note or send a MIDI message")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)

                            Button {
                                stopLearning()
                            } label: {
                                Label("Cancel Learning", systemImage: "xmark.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button {
                            startLearning()
                        } label: {
                            Label("Learn from MIDI", systemImage: "waveform.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!midiManager.isEnabled || !midiManager.isConnected)
                    }
                } header: {
                    Text("MIDI Learn")
                } footer: {
                    Text("Learn mode automatically assigns MIDI triggers by listening to your controller")
                }

                // Existing Triggers
                if !triggers.isEmpty {
                    Section {
                        ForEach(triggers) { trigger in
                            MIDITriggerRow(
                                trigger: trigger,
                                onToggle: { enabled in
                                    if let index = triggers.firstIndex(where: { $0.id == trigger.id }) {
                                        triggers[index].enabled = enabled
                                    }
                                },
                                onTest: {
                                    testTrigger(trigger)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    triggers.removeAll { $0.id == trigger.id }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text("Active Triggers (\(triggers.filter { $0.enabled }.count)/\(triggers.count))")
                    } footer: {
                        Text("This song will load when any of these MIDI messages are received")
                    }
                }

                // Add/Mapping Actions
                Section {
                    Button {
                        showAddTrigger = true
                    } label: {
                        Label("Add Trigger Manually", systemImage: "plus.circle")
                    }

                    Button {
                        showMappingPresets = true
                    } label: {
                        Label("Apply Mapping Preset", systemImage: "doc.on.doc")
                    }
                } footer: {
                    Text("Add triggers manually or use presets to assign triggers to multiple songs")
                }

                // Quick Actions
                if !triggers.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            triggers.removeAll()
                        } label: {
                            Label("Clear All Triggers", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("MIDI Triggers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTriggers()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddTrigger) {
                AddMIDITriggerView { newTrigger in
                    triggers.append(newTrigger)
                }
            }
            .sheet(isPresented: $showMappingPresets) {
                MIDIMappingPresetsView(song: song)
            }
        }
    }

    private func startLearning() {
        isLearning = true
        learningMessage = nil

        midiSongLoader.startLearning(for: song) { [self] trigger in
            triggers.append(trigger)
            learningMessage = "Learned: \(trigger.description)"
            isLearning = false
        }
    }

    private func stopLearning() {
        midiSongLoader.stopLearning()
        isLearning = false
        learningMessage = nil
    }

    private func testTrigger(_ trigger: MIDITrigger) {
        print("🧪 Testing trigger: \(trigger.description)")

        switch trigger.type {
        case .programChange:
            if let program = trigger.programNumber {
                midiManager.sendProgramChange(program: program, channel: trigger.channel)
            }

        case .controlChange:
            if let controller = trigger.controllerNumber,
               let value = trigger.controllerValue {
                midiManager.sendControlChange(
                    controller: controller,
                    value: value,
                    channel: trigger.channel
                )
            }

        case .noteOn:
            if let note = trigger.noteNumber {
                midiManager.sendNoteOn(
                    note: note,
                    velocity: trigger.noteVelocity ?? 100,
                    channel: trigger.channel
                )
            }

        case .combination:
            print("⚠️ Cannot test combination triggers")
        }
    }

    private func saveTriggers() {
        song.midiTriggers = triggers
        print("💾 Saved \(triggers.count) MIDI triggers for '\(song.title)'")
    }
}

// MARK: - MIDI Trigger Row

struct MIDITriggerRow: View {
    let trigger: MIDITrigger
    let onToggle: (Bool) -> Void
    let onTest: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trigger.type.icon)
                .font(.title3)
                .foregroundStyle(trigger.enabled ? .blue : .gray)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(trigger.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(trigger.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onTest()
            } label: {
                Image(systemName: "play.circle")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(
                get: { trigger.enabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add MIDI Trigger View

struct AddMIDITriggerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: MIDITriggerType = .programChange
    @State private var channel: UInt8 = 1
    @State private var programNumber: UInt8 = 0
    @State private var controllerNumber: UInt8 = 7
    @State private var controllerValue: UInt8 = 64
    @State private var noteNumber: UInt8 = 60
    @State private var noteVelocity: UInt8 = 100

    let onAdd: (MIDITrigger) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Trigger Type", selection: $selectedType) {
                        ForEach(MIDITriggerType.allCases.filter { $0 != .combination }, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(selectedType.description)
                }

                Section {
                    Picker("MIDI Channel", selection: $channel) {
                        Text("Any Channel").tag(UInt8(0))
                        ForEach(1...16, id: \.self) { ch in
                            Text("Channel \(ch)").tag(UInt8(ch))
                        }
                    }
                } header: {
                    Text("Channel")
                }

                // Type-specific settings
                switch selectedType {
                case .programChange:
                    Section {
                        HStack {
                            Text("Program Number")
                            Spacer()
                            Stepper(value: $programNumber, in: 0...127) {
                                Text("\(programNumber)")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    } header: {
                        Text("Program Change")
                    } footer: {
                        Text("Program number to trigger this song (0-127)")
                    }

                case .controlChange:
                    Section {
                        HStack {
                            Text("Controller Number")
                            Spacer()
                            Stepper(value: $controllerNumber, in: 0...127) {
                                Text("CC\(controllerNumber)")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }

                        HStack {
                            Text("Value")
                            Spacer()
                            Stepper(value: $controllerValue, in: 0...127) {
                                Text("\(controllerValue)")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    } header: {
                        Text("Control Change")
                    } footer: {
                        Text("CC message to trigger this song")
                    }

                case .noteOn:
                    Section {
                        HStack {
                            Text("Note Number")
                            Spacer()
                            Stepper(value: $noteNumber, in: 0...127) {
                                Text("\(noteName(noteNumber))")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }

                        HStack {
                            Text("Velocity")
                            Spacer()
                            Stepper(value: $noteVelocity, in: 0...127) {
                                Text("\(noteVelocity)")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    } header: {
                        Text("Note On")
                    } footer: {
                        Text("MIDI note to trigger this song")
                    }

                case .combination:
                    EmptyView()
                }
            }
            .navigationTitle("Add Trigger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTrigger()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addTrigger() {
        var trigger: MIDITrigger

        switch selectedType {
        case .programChange:
            trigger = MIDITrigger(
                type: .programChange,
                channel: channel,
                programNumber: programNumber
            )

        case .controlChange:
            trigger = MIDITrigger(
                type: .controlChange,
                channel: channel,
                controllerNumber: controllerNumber,
                controllerValue: controllerValue
            )

        case .noteOn:
            trigger = MIDITrigger(
                type: .noteOn,
                channel: channel,
                noteNumber: noteNumber,
                noteVelocity: noteVelocity
            )

        case .combination:
            trigger = MIDITrigger(
                type: .combination,
                channel: channel
            )
        }

        onAdd(trigger)
        dismiss()
    }

    private func noteName(_ number: UInt8) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(number) / 12 - 1
        let noteIndex = Int(number) % 12
        return "\(notes[noteIndex])\(octave)"
    }
}

// MARK: - MIDI Mapping Presets View

struct MIDIMappingPresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song

    @State private var selectedPreset: MIDIMappingPreset = .sequential
    @State private var channel: UInt8 = 1
    @State private var showConfirmation = false

    @Query private var allSongs: [Song]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mapping Preset", selection: $selectedPreset) {
                        ForEach(MIDIMappingPreset.allCases, id: \.self) { preset in
                            Label(preset.rawValue, systemImage: preset.icon).tag(preset)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Preset")
                } footer: {
                    Text(selectedPreset.description)
                }

                Section {
                    Picker("MIDI Channel", selection: $channel) {
                        ForEach(1...16, id: \.self) { ch in
                            Text("Channel \(ch)").tag(UInt8(ch))
                        }
                    }
                } header: {
                    Text("Channel")
                } footer: {
                    Text("All triggers will use this MIDI channel")
                }

                Section {
                    Text("This will apply MIDI triggers to **\(allSongs.count) songs** in your library")
                        .font(.subheadline)

                    Button {
                        showConfirmation = true
                    } label: {
                        Label("Apply to All Songs", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } footer: {
                    Text("Existing MIDI triggers will be replaced")
                }
            }
            .navigationTitle("Mapping Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Apply MIDI Mapping",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Apply to All Songs") {
                    applyMapping()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will replace existing MIDI triggers for \(allSongs.count) songs")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func applyMapping() {
        MIDISongLoader.shared.applyMappingPreset(
            selectedPreset,
            to: allSongs,
            channel: channel
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Song.self, configurations: config)

    let song = Song(title: "Amazing Grace", artist: "John Newton")
    container.mainContext.insert(song)

    return MIDITriggerEditorView(song: song)
        .modelContainer(container)
}
