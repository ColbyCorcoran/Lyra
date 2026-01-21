//
//  EditSongView.swift
//  Lyra
//
//  Form for editing an existing song's metadata and content
//

import SwiftUI
import SwiftData

enum EditTab: String, CaseIterable {
    case metadata = "Info"
    case content = "Content"
}

struct EditSongView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song

    @State private var selectedTab: EditTab = .metadata
    @State private var title: String
    @State private var artist: String
    @State private var originalKey: String
    @State private var capo: Int
    @State private var tempo: Int
    @State private var timeSignature: String
    @State private var notes: String
    @State private var content: String
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    init(song: Song) {
        self.song = song
        _title = State(initialValue: song.title)
        _artist = State(initialValue: song.artist ?? "")
        _originalKey = State(initialValue: song.originalKey ?? "")
        _capo = State(initialValue: song.capo ?? 0)
        _tempo = State(initialValue: song.tempo ?? 0)
        _timeSignature = State(initialValue: song.timeSignature ?? "")
        _notes = State(initialValue: song.notes ?? "")
        _content = State(initialValue: song.content)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Edit Mode", selection: $selectedTab) {
                    ForEach(EditTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                Group {
                    if selectedTab == .metadata {
                        metadataEditor
                    } else {
                        contentEditor
                    }
                }
            }
            .navigationTitle("Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSong()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Tab Views

    @ViewBuilder
    private var metadataEditor: some View {
        Form {
            basicInfoSection
            musicalDetailsSection
            notesSection
        }
    }

    @ViewBuilder
    private var contentEditor: some View {
        VStack(spacing: 0) {
            // Help text
            VStack(alignment: .leading, spacing: 8) {
                Text("Edit ChordPro Content")
                    .font(.headline)

                Text("Format: [Chord]Lyrics. Example: [G]Amazing [C]grace, how [G]sweet the sound")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))

            // Content editor
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
                .padding(8)
        }
    }

    // MARK: - Form Sections

    @ViewBuilder
    private var basicInfoSection: some View {
        Section {
            TextField("Title", text: $title)
                .autocorrectionDisabled()

            TextField("Artist (optional)", text: $artist)
                .autocorrectionDisabled()
        } header: {
            Text("Basic Information")
        } footer: {
            Text("The song title is required")
        }
    }

    @ViewBuilder
    private var musicalDetailsSection: some View {
        Section {
            TextField("Key (optional)", text: $originalKey)
                .autocorrectionDisabled()

            Stepper("Capo: \(capo == 0 ? "None" : "Fret \(capo)")", value: $capo, in: 0...12)

            HStack {
                Text("Tempo")
                Spacer()
                TextField("BPM", value: $tempo, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            TextField("Time Signature (optional)", text: $timeSignature)
                .autocorrectionDisabled()
        } header: {
            Text("Musical Details")
        } footer: {
            Text("Enter musical details like key, capo position, tempo, and time signature")
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
        } header: {
            Text("Notes")
        } footer: {
            Text("Add any notes or reminders about this song")
        }
    }

    // MARK: - Actions

    private func saveSong() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Song title cannot be empty"
            showErrorAlert = true
            return
        }

        // Update song properties
        song.title = trimmedTitle
        song.artist = artist.isEmpty ? nil : artist
        song.originalKey = originalKey.isEmpty ? nil : originalKey.uppercased()
        song.capo = capo == 0 ? nil : capo
        song.tempo = tempo == 0 ? nil : tempo
        song.timeSignature = timeSignature.isEmpty ? nil : timeSignature
        song.notes = notes.isEmpty ? nil : notes
        song.content = content
        song.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace", artist: "John Newton")
    song.originalKey = "G"
    song.capo = 2
    song.tempo = 120
    song.timeSignature = "4/4"
    song.notes = "Play softly in the verses"

    return EditSongView(song: song)
        .modelContainer(PreviewContainer.shared.container)
}
