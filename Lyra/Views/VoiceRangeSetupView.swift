//
//  VoiceRangeSetupView.swift
//  Lyra
//
//  First-time setup for user's vocal range
//  Part of Phase 7.9: Transpose Intelligence
//

import SwiftUI

struct VoiceRangeSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var setupMethod: SetupMethod = .voiceType
    @State private var selectedVoiceType: VoiceType = .tenor
    @State private var customLowestNote: MusicalNote = MusicalNote(note: "C", octave: 3)
    @State private var customHighestNote: MusicalNote = MusicalNote(note: "C", octave: 5)
    @State private var showSuccess = false

    enum SetupMethod {
        case voiceType
        case custom
    }

    private let keyLearningEngine = KeyLearningEngine()

    var body: some View {
        NavigationStack {
            Form {
                // Setup Method Selection
                Section {
                    Picker("Setup Method", selection: $setupMethod) {
                        Label("Voice Type", systemImage: "person.fill")
                            .tag(SetupMethod.voiceType)
                        Label("Custom Range", systemImage: "slider.horizontal.3")
                            .tag(SetupMethod.custom)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("How would you like to set up?")
                } footer: {
                    Text(setupMethod == .voiceType ?
                         "Choose your voice type for typical ranges" :
                         "Manually specify your exact vocal range")
                }

                // Voice Type Setup
                if setupMethod == .voiceType {
                    voiceTypeSection
                } else {
                    customRangeSection
                }

                // Preview Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundStyle(.green)
                            Text("Your Vocal Range")
                                .font(.headline)
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lowest Note")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(previewRange.lowestNote.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }

                            Spacer()

                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Highest Note")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(previewRange.highestNote.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }

                        Text("Range: \(previewRange.rangeInSemitones) semitones")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }

                // Tips Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        tipRow(
                            icon: "lightbulb.fill",
                            title: "Warm up first",
                            description: "Find your range after warming up your voice"
                        )

                        tipRow(
                            icon: "music.note",
                            title: "Use a piano",
                            description: "Match your lowest and highest comfortable notes"
                        )

                        tipRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "You can change this",
                            description: "Update your range anytime in settings"
                        )
                    }
                } header: {
                    Text("Tips")
                }
            }
            .navigationTitle("Set Up Vocal Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVocalRange()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Vocal Range Saved", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your vocal range has been saved. You'll now get personalized key recommendations!")
            }
        }
    }

    // MARK: - Voice Type Section

    private var voiceTypeSection: some View {
        Section {
            Picker("Voice Type", selection: $selectedVoiceType) {
                ForEach(VoiceType.allCases, id: \.self) { voiceType in
                    HStack {
                        Text(voiceType.rawValue)
                        Spacer()
                        Text(voiceType.typicalRange.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(voiceType)
                }
            }
            .pickerStyle(.inline)
        } header: {
            Text("Select Your Voice Type")
        } footer: {
            Text("These are typical ranges. Everyone's voice is unique!")
        }
    }

    // MARK: - Custom Range Section

    private var customRangeSection: some View {
        Group {
            Section {
                notePicker(
                    label: "Lowest Note",
                    note: $customLowestNote,
                    range: 1...5
                )
            } header: {
                Text("Lowest Comfortable Note")
            } footer: {
                Text("The lowest note you can sing comfortably")
            }

            Section {
                notePicker(
                    label: "Highest Note",
                    note: $customHighestNote,
                    range: 3...7
                )
            } header: {
                Text("Highest Comfortable Note")
            } footer: {
                Text("The highest note you can sing comfortably")
            }
        }
    }

    // MARK: - Note Picker

    private func notePicker(label: String, note: Binding<MusicalNote>, range: ClosedRange<Int>) -> some View {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        return VStack(spacing: 12) {
            // Note selector
            Picker("Note", selection: Binding(
                get: { note.wrappedValue.note },
                set: { note.wrappedValue = MusicalNote(note: $0, octave: note.wrappedValue.octave) }
            )) {
                ForEach(notes, id: \.self) { noteName in
                    Text(noteName).tag(noteName)
                }
            }
            .pickerStyle(.menu)

            // Octave selector
            Picker("Octave", selection: Binding(
                get: { note.wrappedValue.octave },
                set: { note.wrappedValue = MusicalNote(note: note.wrappedValue.note, octave: $0) }
            )) {
                ForEach(Array(range), id: \.self) { octave in
                    Text("Octave \(octave)").tag(octave)
                }
            }
            .pickerStyle(.menu)

            // Current selection
            HStack {
                Text("Selected:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(note.wrappedValue.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Tip Row

    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Computed Properties

    private var previewRange: VocalRange {
        if setupMethod == .voiceType {
            return selectedVoiceType.typicalRange
        } else {
            return VocalRange(
                lowestNote: customLowestNote,
                highestNote: customHighestNote,
                comfortableLowest: customLowestNote,
                comfortableHighest: customHighestNote,
                voiceType: nil
            )
        }
    }

    // MARK: - Actions

    private func saveVocalRange() {
        let vocalRange: VocalRange

        if setupMethod == .voiceType {
            var range = selectedVoiceType.typicalRange
            range.voiceType = selectedVoiceType
            vocalRange = range
        } else {
            vocalRange = VocalRange(
                lowestNote: customLowestNote,
                highestNote: customHighestNote,
                comfortableLowest: customLowestNote,
                comfortableHighest: customHighestNote,
                voiceType: nil
            )
        }

        keyLearningEngine.updateVocalRange(vocalRange)
        showSuccess = true
    }
}

// MARK: - Preview

#Preview {
    VoiceRangeSetupView()
}
