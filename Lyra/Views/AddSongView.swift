//
//  AddSongView.swift
//  Lyra
//
//  Manual song creation form with ChordPro editor
//

import SwiftUI
import SwiftData

struct AddSongView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var selectedKey: String = "C"
    @State private var tempo: String = ""
    @State private var selectedTimeSignature: String = "4/4"
    @State private var selectedCapo: Int = 0
    @State private var content: String = ""

    // UI state
    @State private var showValidationWarning: Bool = false
    @State private var validationMessage: String = ""

    // Musical keys
    private let musicalKeys = [
        "C", "C#", "Db", "D", "D#", "Eb", "E", "F",
        "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"
    ]

    // Time signatures
    private let timeSignatures = [
        "2/4", "3/4", "4/4", "5/4", "6/8", "9/8", "12/8"
    ]

    // Capo positions
    private let capoPositions = Array(0...11)

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Song Title", text: $title)
                        .autocorrectionDisabled()

                    TextField("Artist (Optional)", text: $artist)
                        .autocorrectionDisabled()
                }

                // Musical Metadata Section
                Section("Musical Details") {
                    Picker("Key", selection: $selectedKey) {
                        ForEach(musicalKeys, id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }

                    HStack {
                        Text("Tempo (BPM)")
                        TextField("", text: $tempo)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    }

                    Picker("Time Signature", selection: $selectedTimeSignature) {
                        ForEach(timeSignatures, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }

                    Picker("Capo Position", selection: $selectedCapo) {
                        ForEach(capoPositions, id: \.self) { position in
                            Text(position == 0 ? "No Capo" : "Fret \(position)")
                                .tag(position)
                        }
                    }
                }

                // Content Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ChordPro Content")
                            .font(.headline)

                        TextEditor(text: $content)
                            .font(.system(size: 14, design: .monospaced))
                            .frame(minHeight: 250)
                            .overlay(
                                Group {
                                    if content.isEmpty {
                                        VStack {
                                            Text(placeholderText)
                                                .font(.system(size: 14, design: .monospaced))
                                                .foregroundStyle(.tertiary)
                                                .padding(.top, 8)
                                                .padding(.leading, 5)
                                            Spacer()
                                        }
                                        .allowsHitTesting(false)
                                    }
                                }
                            )
                            .onChange(of: content) { _, _ in
                                validateContent()
                            }

                        // Character count
                        HStack {
                            Spacer()
                            Text("\(content.count) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Song Content")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Use ChordPro format: {title: ...}, {artist: ...}, [C]lyrics")
                            .font(.caption)

                        if showValidationWarning {
                            Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .navigationTitle("New Song")
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
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Validation & Save

    /// Check if the form can be saved
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Validate ChordPro content
    private func validateContent() {
        guard !content.isEmpty else {
            showValidationWarning = false
            return
        }

        // Try to parse the content
        let parsed = ChordProParser.parse(content)

        // Show warning if parsing resulted in no sections
        if parsed.sections.isEmpty && !content.trimmingCharacters(in: .whitespaces).isEmpty {
            showValidationWarning = true
            validationMessage = "Content may not be valid ChordPro format"
        } else {
            showValidationWarning = false
        }
    }

    /// Save the song to SwiftData
    private func saveSong() {
        // Build ChordPro content with metadata directives
        var chordProContent = ""

        // Add metadata directives
        chordProContent += "{title: \(title)}\n"

        if !artist.isEmpty {
            chordProContent += "{artist: \(artist)}\n"
        }

        chordProContent += "{key: \(selectedKey)}\n"

        if let tempoValue = Int(tempo), tempoValue > 0 {
            chordProContent += "{tempo: \(tempoValue)}\n"
        }

        chordProContent += "{time: \(selectedTimeSignature)}\n"

        if selectedCapo > 0 {
            chordProContent += "{capo: \(selectedCapo)}\n"
        }

        chordProContent += "\n"

        // Append user content
        chordProContent += content

        // Create Song model
        let newSong = Song(
            title: title,
            artist: artist.isEmpty ? nil : artist,
            content: chordProContent,
            originalKey: selectedKey
        )

        // Set additional metadata
        if let tempoValue = Int(tempo), tempoValue > 0 {
            newSong.tempo = tempoValue
        }
        newSong.timeSignature = selectedTimeSignature
        newSong.capo = selectedCapo

        // Insert into SwiftData
        modelContext.insert(newSong)

        // Save context
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving song: \(error)")
        }
    }

    // MARK: - Placeholder

    private var placeholderText: String {
        """
        {verse}
        [C]Amazing [F]grace how [C]sweet the [G]sound
        That [C]saved a [F]wretch like [C]me

        {chorus}
        [F]My chains are [C]gone, I've been set [Am]free
        """
    }
}

// MARK: - Preview

#Preview("Add Song Form") {
    AddSongView()
        .modelContainer(PreviewContainer.shared.container)
}

#Preview("Add Song - In Navigation") {
    NavigationStack {
        Text("Library")
            .sheet(isPresented: .constant(true)) {
                AddSongView()
                    .modelContainer(PreviewContainer.shared.container)
            }
    }
}
