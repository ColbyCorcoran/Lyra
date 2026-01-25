//
//  BandProfilesView.swift
//  Lyra
//
//  Manage band member profiles for multi-instrument optimization
//  Part of Phase 7.9: Transpose Intelligence
//

import SwiftUI
import SwiftData

struct BandProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BandMemberProfile.name) private var bandMembers: [BandMemberProfile]

    @State private var showAddMember = false

    var body: some View {
        List {
            if bandMembers.isEmpty {
                emptyStateSection
            } else {
                ForEach(bandMembers) { member in
                    memberRow(member)
                }
                .onDelete(perform: deleteMembers)
            }
        }
        .navigationTitle("Band Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddMember = true
                } label: {
                    Label("Add Member", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showAddMember) {
            AddBandMemberView()
        }
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("No Band Members")
                        .font(.headline)

                    Text("Add musicians to optimize keys for everyone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    showAddMember = true
                } label: {
                    Label("Add First Member", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Member Row

    private func memberRow(_ member: BandMemberProfile) -> some View {
        NavigationLink(destination: EditBandMemberView(member: member)) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(member.isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: instrumentIcon(member.instrument))
                        .font(.title3)
                        .foregroundStyle(member.isActive ? .blue : .gray)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Text(member.instrument)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let vocalRange = member.vocalRange {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.caption2)
                                Text(vocalRange.description)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    Text("Skill: \(member.skillLevel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Active indicator
                if !member.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundStyle(.gray)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helper Methods

    private func instrumentIcon(_ instrument: String) -> String {
        let lowercased = instrument.lowercased()
        if lowercased.contains("guitar") {
            return "guitars"
        } else if lowercased.contains("vocal") || lowercased.contains("singer") {
            return "mic.fill"
        } else if lowercased.contains("piano") || lowercased.contains("keyboard") {
            return "pianokeys"
        } else if lowercased.contains("drum") {
            return "music.note.list"
        } else if lowercased.contains("bass") {
            return "waveform"
        } else {
            return "music.note"
        }
    }

    private func deleteMembers(at offsets: IndexSet) {
        for index in offsets {
            let member = bandMembers[index]
            modelContext.delete(member)
        }
    }
}

// MARK: - Add Band Member View

struct AddBandMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var instrument = ""
    @State private var hasVocalRange = false
    @State private var vocalRangeLow = MusicalNote(note: "C", octave: 3)
    @State private var vocalRangeHigh = MusicalNote(note: "C", octave: 5)
    @State private var skillLevel: SkillLevel = .intermediate

    private let commonInstruments = ["Vocals", "Guitar", "Bass", "Keyboard", "Drums", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)

                    Picker("Instrument", selection: $instrument) {
                        ForEach(commonInstruments, id: \.self) { inst in
                            Text(inst).tag(inst)
                        }
                    }
                } header: {
                    Text("Basic Info")
                }

                Section {
                    Picker("Skill Level", selection: $skillLevel) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                } header: {
                    Text("Skill Level")
                }

                Section {
                    Toggle("Has Vocal Range", isOn: $hasVocalRange)

                    if hasVocalRange {
                        VStack(spacing: 12) {
                            notePickerRow(label: "Lowest Note", note: $vocalRangeLow)
                            notePickerRow(label: "Highest Note", note: $vocalRangeHigh)
                        }
                    }
                } header: {
                    Text("Vocal Range")
                } footer: {
                    Text("Set vocal range for singers or backing vocals")
                }
            }
            .navigationTitle("Add Band Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMember()
                    }
                    .disabled(name.isEmpty || instrument.isEmpty)
                }
            }
        }
    }

    private func notePickerRow(label: String, note: Binding<MusicalNote>) -> some View {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        return HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            Picker("Note", selection: Binding(
                get: { note.wrappedValue.note },
                set: { note.wrappedValue = MusicalNote(note: $0, octave: note.wrappedValue.octave) }
            )) {
                ForEach(notes, id: \.self) { n in
                    Text(n).tag(n)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)

            Picker("Octave", selection: Binding(
                get: { note.wrappedValue.octave },
                set: { note.wrappedValue = MusicalNote(note: note.wrappedValue.note, octave: $0) }
            )) {
                ForEach(1...7, id: \.self) { octave in
                    Text("\(octave)").tag(octave)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 60)
        }
    }

    private func saveMember() {
        let vocalRange: VocalRange? = hasVocalRange ?
            VocalRange(
                lowestNote: vocalRangeLow,
                highestNote: vocalRangeHigh
            ) : nil

        let member = BandMemberProfile(
            name: name,
            instrument: instrument,
            vocalRange: vocalRange,
            skillLevel: skillLevel
        )

        modelContext.insert(member)
        dismiss()
    }
}

// MARK: - Edit Band Member View

struct EditBandMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var member: BandMemberProfile

    @State private var hasVocalRange: Bool
    @State private var vocalRangeLow: MusicalNote
    @State private var vocalRangeHigh: MusicalNote

    init(member: BandMemberProfile) {
        self.member = member
        _hasVocalRange = State(initialValue: member.vocalRange != nil)
        _vocalRangeLow = State(initialValue: member.vocalRange?.lowestNote ?? MusicalNote(note: "C", octave: 3))
        _vocalRangeHigh = State(initialValue: member.vocalRange?.highestNote ?? MusicalNote(note: "C", octave: 5))
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $member.name)
                TextField("Instrument", text: $member.instrument)
            } header: {
                Text("Basic Info")
            }

            Section {
                Picker("Skill Level", selection: Binding(
                    get: { member.skillLevelEnum },
                    set: { member.skillLevel = $0.rawValue }
                )) {
                    ForEach(SkillLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            } header: {
                Text("Skill Level")
            }

            Section {
                Toggle("Has Vocal Range", isOn: $hasVocalRange)
                    .onChange(of: hasVocalRange) { _, newValue in
                        if newValue {
                            member.vocalRange = VocalRange(
                                lowestNote: vocalRangeLow,
                                highestNote: vocalRangeHigh
                            )
                        } else {
                            member.vocalRange = nil
                        }
                    }

                if hasVocalRange {
                    VStack(spacing: 12) {
                        notePickerRow(label: "Lowest Note", note: $vocalRangeLow)
                            .onChange(of: vocalRangeLow) { _, _ in
                                updateVocalRange()
                            }
                        notePickerRow(label: "Highest Note", note: $vocalRangeHigh)
                            .onChange(of: vocalRangeHigh) { _, _ in
                                updateVocalRange()
                            }
                    }
                }
            } header: {
                Text("Vocal Range")
            }

            Section {
                Toggle("Active Member", isOn: $member.isActive)
            } footer: {
                Text("Inactive members won't be considered in band optimization")
            }

            Section {
                Button(role: .destructive) {
                    deleteMember()
                } label: {
                    Label("Delete Member", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Edit Member")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func notePickerRow(label: String, note: Binding<MusicalNote>) -> some View {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        return HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            Picker("Note", selection: Binding(
                get: { note.wrappedValue.note },
                set: { note.wrappedValue = MusicalNote(note: $0, octave: note.wrappedValue.octave) }
            )) {
                ForEach(notes, id: \.self) { n in
                    Text(n).tag(n)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)

            Picker("Octave", selection: Binding(
                get: { note.wrappedValue.octave },
                set: { note.wrappedValue = MusicalNote(note: note.wrappedValue.note, octave: $0) }
            )) {
                ForEach(1...7, id: \.self) { octave in
                    Text("\(octave)").tag(octave)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 60)
        }
    }

    private func updateVocalRange() {
        member.vocalRange = VocalRange(
            lowestNote: vocalRangeLow,
            highestNote: vocalRangeHigh
        )
    }

    private func deleteMember() {
        modelContext.delete(member)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BandProfilesView()
    }
    .modelContainer(PreviewContainer.shared.container)
}
