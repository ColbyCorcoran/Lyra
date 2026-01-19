//
//  SetEntryOverrideView.swift
//  Lyra
//
//  Sheet for editing per-set overrides for a song in a performance set
//

import SwiftUI
import SwiftData

struct SetEntryOverrideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: SetEntry
    let song: Song

    @State private var keyOverride: String?
    @State private var capoOverride: Int?
    @State private var tempoOverride: Int?
    @State private var entryNotes: String
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    // All musical keys for the picker
    private let allKeys = [
        "C", "C#", "Db", "D", "D#", "Eb", "E", "F",
        "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B",
        "Cm", "C#m", "Dm", "D#m", "Ebm", "Em", "Fm",
        "F#m", "Gm", "G#m", "Am", "A#m", "Bbm", "Bm"
    ]

    init(entry: SetEntry, song: Song) {
        self.entry = entry
        self.song = song
        _keyOverride = State(initialValue: entry.keyOverride)
        _capoOverride = State(initialValue: entry.capoOverride)
        _tempoOverride = State(initialValue: entry.tempoOverride)
        _entryNotes = State(initialValue: entry.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Song Info Section

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(song.title)
                            .font(.headline)

                        if let artist = song.artist {
                            Text(artist)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Song")
                }

                // MARK: - Key Override Section

                Section {
                    HStack {
                        Text("Original Key")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(song.originalKey ?? "Not set")
                            .foregroundStyle(song.originalKey != nil ? .primary : .tertiary)
                    }

                    Toggle("Override Key", isOn: Binding(
                        get: { keyOverride != nil },
                        set: { isOn in
                            if isOn {
                                keyOverride = song.originalKey ?? "C"
                            } else {
                                keyOverride = nil
                            }
                        }
                    ))

                    if keyOverride != nil {
                        Picker("Key", selection: Binding(
                            get: { keyOverride ?? "C" },
                            set: { keyOverride = $0 }
                        )) {
                            ForEach(allKeys, id: \.self) { key in
                                Text(key).tag(key)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)

                        if let override = keyOverride, let original = song.originalKey, override != original {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                Text("Using \(override) instead of \(original)")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Key")
                } footer: {
                    if keyOverride != nil {
                        Text("This song will display in \(keyOverride!) when viewed from this set")
                    }
                }

                // MARK: - Capo Override Section

                Section {
                    HStack {
                        Text("Original Capo")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let capo = song.capo, capo > 0 {
                            Text("Fret \(capo)")
                                .foregroundStyle(.primary)
                        } else {
                            Text("None")
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Toggle("Override Capo", isOn: Binding(
                        get: { capoOverride != nil },
                        set: { isOn in
                            if isOn {
                                capoOverride = song.capo ?? 0
                            } else {
                                capoOverride = nil
                            }
                        }
                    ))

                    if capoOverride != nil {
                        Picker("Capo Fret", selection: Binding(
                            get: { capoOverride ?? 0 },
                            set: { capoOverride = $0 }
                        )) {
                            ForEach(0...11, id: \.self) { fret in
                                if fret == 0 {
                                    Text("No Capo").tag(fret)
                                } else {
                                    Text("Fret \(fret)").tag(fret)
                                }
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)

                        if let override = capoOverride, let original = song.capo, override != original {
                            HStack(spacing: 4) {
                                Image(systemName: "guitars")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text("Using capo \(override) instead of \(original)")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding(.vertical, 4)
                        } else if capoOverride == 0 && song.capo ?? 0 > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "guitars.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text("Removing capo for this set")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Capo")
                } footer: {
                    if let capo = capoOverride {
                        if capo > 0 {
                            Text("Capo will be set to fret \(capo) for this set")
                        } else {
                            Text("No capo will be used for this set")
                        }
                    }
                }

                // MARK: - Tempo Override Section

                Section {
                    HStack {
                        Text("Original Tempo")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let tempo = song.tempo {
                            Text("\(tempo) BPM")
                                .foregroundStyle(.primary)
                        } else {
                            Text("Not set")
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Toggle("Override Tempo", isOn: Binding(
                        get: { tempoOverride != nil },
                        set: { isOn in
                            if isOn {
                                tempoOverride = song.tempo ?? 120
                            } else {
                                tempoOverride = nil
                            }
                        }
                    ))

                    if tempoOverride != nil {
                        HStack {
                            Text("Tempo (BPM)")
                                .frame(width: 100, alignment: .leading)

                            Slider(
                                value: Binding(
                                    get: { Double(tempoOverride ?? 120) },
                                    set: { tempoOverride = Int($0) }
                                ),
                                in: 40...240,
                                step: 1
                            )

                            Text("\(tempoOverride ?? 120)")
                                .frame(width: 40, alignment: .trailing)
                                .fontWeight(.semibold)
                        }

                        if let override = tempoOverride, let original = song.tempo, override != original {
                            HStack(spacing: 4) {
                                Image(systemName: "metronome")
                                    .font(.caption2)
                                    .foregroundStyle(.purple)
                                Text("Using \(override) BPM instead of \(original) BPM")
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Tempo")
                } footer: {
                    if let tempo = tempoOverride {
                        Text("Tempo will be \(tempo) BPM for this set")
                    }
                }

                // MARK: - Notes Section

                Section {
                    ZStack(alignment: .topLeading) {
                        if entryNotes.isEmpty {
                            Text("Notes specific to this performance...")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: $entryNotes)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("Performance Notes")
                } footer: {
                    Text("These notes are specific to this song in this set and won't appear elsewhere")
                }

                // MARK: - Reset Section

                if hasAnyOverrides {
                    Section {
                        Button(role: .destructive) {
                            resetAllOverrides()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset All to Defaults")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Override Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveOverrides()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Error Saving Overrides", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Computed Properties

    private var hasAnyOverrides: Bool {
        keyOverride != nil || capoOverride != nil || tempoOverride != nil || !entryNotes.isEmpty
    }

    // MARK: - Actions

    private func saveOverrides() {
        // Update entry with overrides
        entry.keyOverride = keyOverride
        entry.capoOverride = capoOverride
        entry.tempoOverride = tempoOverride
        entry.notes = entryNotes.isEmpty ? nil : entryNotes

        // Update parent set's modified date
        entry.performanceSet?.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error saving overrides: \(error.localizedDescription)")
            errorMessage = "Unable to save overrides. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func resetAllOverrides() {
        HapticManager.shared.selection()
        keyOverride = nil
        capoOverride = nil
        tempoOverride = nil
        entryNotes = ""
    }
}

// MARK: - Preview

#Preview("Song with Defaults") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Song.self, SetEntry.self, PerformanceSet.self, configurations: config)

    let song = Song(title: "Amazing Grace", artist: "John Newton", originalKey: "G")
    song.capo = 2
    song.tempo = 90

    let performanceSet = PerformanceSet(name: "Sunday Service", scheduledDate: Date())
    let entry = SetEntry(song: song, orderIndex: 0)
    entry.performanceSet = performanceSet

    container.mainContext.insert(song)
    container.mainContext.insert(performanceSet)
    container.mainContext.insert(entry)

    return SetEntryOverrideView(entry: entry, song: song)
        .modelContainer(container)
}

#Preview("Song with Existing Overrides") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Song.self, SetEntry.self, PerformanceSet.self, configurations: config)

    let song = Song(title: "How Great Thou Art", artist: "Carl Boberg", originalKey: "C")
    song.capo = 0
    song.tempo = 80

    let performanceSet = PerformanceSet(name: "Evening Worship", scheduledDate: Date())
    let entry = SetEntry(song: song, orderIndex: 0)
    entry.performanceSet = performanceSet
    entry.keyOverride = "D"
    entry.capoOverride = 3
    entry.tempoOverride = 100
    entry.notes = "Slower intro for patient comfort"

    container.mainContext.insert(song)
    container.mainContext.insert(performanceSet)
    container.mainContext.insert(entry)

    return SetEntryOverrideView(entry: entry, song: song)
        .modelContainer(container)
}
