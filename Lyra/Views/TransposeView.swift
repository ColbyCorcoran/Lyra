//
//  TransposeView.swift
//  Lyra
//
//  Comprehensive transposition interface
//

import SwiftUI
import SwiftData

struct TransposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let onTranspose: (Int, Bool, TransposeSaveMode) -> Void

    @State private var originalKey: String
    @State private var targetKey: String
    @State private var semitones: Int = 0
    @State private var preferSharps: Bool = true
    @State private var saveMode: TransposeSaveMode = .temporary
    @State private var chordPreview: [(original: String, transposed: String)] = []
    @State private var showQuickIntervals: Bool = false
    @State private var showAIAssist: Bool = false

    init(song: Song, onTranspose: @escaping (Int, Bool, TransposeSaveMode) -> Void) {
        self.song = song
        self.onTranspose = onTranspose

        // Initialize with current or original key
        let key = song.currentKey ?? song.originalKey ?? "C"
        _originalKey = State(initialValue: key)
        _targetKey = State(initialValue: key)
        _preferSharps = State(initialValue: TransposeEngine.prefersSharps(key: key))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Key Information
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Key")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(originalKey)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Target Key")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(targetKey)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 8)

                    if semitones != 0 {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundStyle(.blue)

                            Text(formatTranspositionDescription())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if TransposeEngine.calculateCapo(for: semitones) > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "guitars")
                                        .font(.caption)
                                    Text("Capo \(TransposeEngine.calculateCapo(for: semitones))")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .clipShape(Capsule())
                                .foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    Text("Transposition")
                }

                // Target Key Selection
                Section {
                    Picker("Target Key", selection: $targetKey) {
                        ForEach(MusicalKey.commonKeys) { key in
                            Text(key.name).tag(key.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: targetKey) { _, newKey in
                        updateSemitones(from: originalKey, to: newKey)
                        updateChordPreview()
                    }
                } header: {
                    Text("Select Key")
                } footer: {
                    Text("Choose the key you want to transpose to")
                }

                // Semitone Slider
                Section {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Semitones")
                                .font(.subheadline)

                            Spacer()

                            HStack(spacing: 12) {
                                Button {
                                    adjustSemitones(by: -1)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                }
                                .disabled(semitones <= -11)

                                Text("\(semitones > 0 ? "+" : "")\(semitones)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                    .frame(minWidth: 40)

                                Button {
                                    adjustSemitones(by: 1)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                .disabled(semitones >= 11)
                            }
                        }

                        Slider(value: Binding(
                            get: { Double(semitones) },
                            set: { semitones = Int($0) }
                        ), in: -11...11, step: 1)
                        .onChange(of: semitones) { _, _ in
                            updateTargetKey()
                            updateChordPreview()
                        }

                        // Quick interval buttons
                        Button {
                            showQuickIntervals.toggle()
                        } label: {
                            HStack {
                                Image(systemName: showQuickIntervals ? "chevron.up" : "chevron.down")
                                Text("Quick Intervals")
                                Spacer()
                            }
                            .font(.subheadline)
                        }
                        .buttonStyle(.plain)

                        if showQuickIntervals {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach([
                                    TransposeEngine.TransposeInterval.halfStepUp,
                                    TransposeEngine.TransposeInterval.halfStepDown,
                                    TransposeEngine.TransposeInterval.wholeStepUp,
                                    TransposeEngine.TransposeInterval.wholeStepDown,
                                    TransposeEngine.TransposeInterval.fourthUp,
                                    TransposeEngine.TransposeInterval.fourthDown,
                                    TransposeEngine.TransposeInterval.fifthUp,
                                    TransposeEngine.TransposeInterval.fifthDown
                                ], id: \.rawValue) { interval in
                                    Button {
                                        semitones = interval.semitones
                                        updateTargetKey()
                                        updateChordPreview()
                                        HapticManager.shared.selection()
                                    } label: {
                                        Text(interval.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                semitones == interval.semitones ?
                                                Color.blue.opacity(0.2) : Color(.systemGray6)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Fine Tuning")
                } footer: {
                    Text("Adjust by semitones for precise control. Use quick intervals for common transpositions.")
                }

                // Sharp/Flat Preference
                Section {
                    Picker("Notation Preference", selection: $preferSharps) {
                        Text("Prefer Sharps (♯)").tag(true)
                        Text("Prefer Flats (♭)").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: preferSharps) { _, _ in
                        updateChordPreview()
                    }
                } header: {
                    Text("Enharmonic Spelling")
                } footer: {
                    Text("Choose whether to use sharps or flats for black keys (e.g., C# vs Db)")
                }

                // Chord Preview
                if !chordPreview.isEmpty {
                    Section {
                        ForEach(chordPreview.prefix(10), id: \.original) { pair in
                            HStack(spacing: 12) {
                                Text(pair.original)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .frame(minWidth: 60, alignment: .leading)

                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(pair.transposed)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(pair.original != pair.transposed ? .blue : .primary)
                                    .frame(minWidth: 60, alignment: .leading)

                                Spacer()
                            }
                        }

                        if chordPreview.count > 10 {
                            Text("+ \(chordPreview.count - 10) more chords")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Chord Changes Preview")
                    } footer: {
                        Text("Showing how chords will be transposed")
                    }
                }

                // Save Options
                Section {
                    Picker("Save Mode", selection: $saveMode) {
                        ForEach(TransposeSaveMode.allCases) { mode in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                    .font(.body)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("How to Save")
                } footer: {
                    Text(saveMode.detailedDescription)
                }

                // Reset
                if semitones != 0 {
                    Section {
                        Button(role: .destructive) {
                            resetTransposition()
                        } label: {
                            Label("Reset to Original Key", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Transpose Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Button {
                        showAIAssist = true
                    } label: {
                        Label("AI Assist", systemImage: "wand.and.stars")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyTransposition()
                    }
                    .fontWeight(.semibold)
                    .disabled(semitones == 0)
                }
            }
            .onAppear {
                updateChordPreview()
            }
            .sheet(isPresented: $showAIAssist) {
                AITransposeView(song: song, onTranspose: onTranspose)
            }
        }
    }

    // MARK: - Actions

    private func adjustSemitones(by amount: Int) {
        let newValue = semitones + amount
        if newValue >= -11 && newValue <= 11 {
            semitones = newValue
            updateTargetKey()
            updateChordPreview()
            HapticManager.shared.selection()
        }
    }

    private func updateSemitones(from: String, to: String) {
        semitones = TransposeEngine.semitonesBetween(from: from, to: to)
    }

    private func updateTargetKey() {
        targetKey = TransposeEngine.transpose(originalKey, by: semitones, preferSharps: preferSharps)
    }

    private func updateChordPreview() {
        chordPreview = TransposeEngine.previewTransposition(
            content: song.content,
            semitones: semitones,
            preferSharps: preferSharps
        )
    }

    private func resetTransposition() {
        semitones = 0
        targetKey = originalKey
        updateChordPreview()
        HapticManager.shared.warning()
    }

    private func applyTransposition() {
        guard semitones != 0 else { return }

        onTranspose(semitones, preferSharps, saveMode)
        HapticManager.shared.success()
        dismiss()
    }

    private func formatTranspositionDescription() -> String {
        let direction = semitones > 0 ? "up" : "down"
        let count = abs(semitones)
        let unit = count == 1 ? "semitone" : "semitones"
        return "\(count) \(unit) \(direction)"
    }
}

// MARK: - Save Mode

enum TransposeSaveMode: String, CaseIterable, Identifiable {
    case temporary = "Temporary"
    case permanent = "Permanent"
    case duplicate = "Save as New Song"

    var id: String { rawValue }

    var title: String {
        rawValue
    }

    var description: String {
        switch self {
        case .temporary:
            return "Session only"
        case .permanent:
            return "Update this song"
        case .duplicate:
            return "Create new copy"
        }
    }

    var detailedDescription: String {
        switch self {
        case .temporary:
            return "Changes will only apply during this session and won't be saved. Perfect for trying different keys."
        case .permanent:
            return "This song will be permanently transposed. The original key will be preserved in metadata."
        case .duplicate:
            return "Creates a new song with the transposed chords. The original song remains unchanged."
        }
    }

    var icon: String {
        switch self {
        case .temporary: return "clock"
        case .permanent: return "checkmark.circle"
        case .duplicate: return "doc.on.doc"
        }
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

    return TransposeView(song: song) { semitones, preferSharps, saveMode in
        print("Transpose by \(semitones), preferSharps: \(preferSharps), mode: \(saveMode)")
    }
    .modelContainer(container)
}
