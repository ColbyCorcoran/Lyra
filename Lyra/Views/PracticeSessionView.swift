//
//  PracticeSessionView.swift
//  Lyra
//
//  Active practice session interface with real-time tracking
//  Part of Phase 7.7: Practice Intelligence
//

import SwiftUI
import SwiftData

struct PracticeSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let song: Song  // Assumes Song model exists

    @StateObject private var manager: PracticeManager
    @State private var session: PracticeSession?
    @State private var isActive = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var completionRate: Float = 0.0
    @State private var selectedMode: PracticeMode = .normal
    @State private var showDifficultyLog = false
    @State private var sessionNotes = ""

    // Timer for elapsed time
    @State private var timer: Timer?

    init(song: Song, modelContext: ModelContext) {
        self.song = song
        _manager = StateObject(wrappedValue: PracticeManager(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Timer Display
                    timerSection

                    // Practice Controls
                    controlsSection

                    // Mode Selector
                    modeSection

                    // Quick Stats
                    if let session = session {
                        statsSection(session: session)
                    }

                    // Difficulty Logging
                    difficultySection
                }
                .padding()
            }
            .navigationTitle("Practice: \(song.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelPractice()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("End Session") {
                        endPractice()
                    }
                    .disabled(!isActive && elapsedTime == 0)
                }
            }
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: 8) {
            Text("Practice Time")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(timeString(from: elapsedTime))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(isActive ? "Recording..." : "Paused")
                .font(.caption)
                .foregroundStyle(isActive ? .green : .secondary)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 16) {
            if !isActive {
                Button(action: startOrResumePractice) {
                    Label(session == nil ? "Start" : "Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button(action: pausePractice) {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Mode")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PracticeMode.allCases, id: \.self) { mode in
                        ModeButton(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            action: {
                                selectedMode = mode
                                if isActive {
                                    applyMode(mode)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Stats Section

    private func statsSection(session: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Stats")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Completion", value: "\(Int(completionRate * 100))%")
                StatCard(title: "Difficulties", value: "\(session.difficulties.count)")

                if let metrics = session.skillMetrics {
                    StatCard(title: "Chord Speed", value: String(format: "%.1f/min", metrics.chordChangeSpeed))
                    StatCard(title: "Rhythm", value: "\(Int(metrics.rhythmAccuracy * 100))%")
                }
            }
        }
    }

    // MARK: - Difficulty Section

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log Difficulty")
                .font(.headline)

            Button(action: { showDifficultyLog = true }) {
                Label("Add Difficulty", systemImage: "exclamationmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!isActive)
        }
        .sheet(isPresented: $showDifficultyLog) {
            DifficultyLogView(manager: manager)
        }
    }

    // MARK: - Actions

    private func startOrResumePractice() {
        if session == nil {
            session = manager.startSession(songID: song.id, mode: selectedMode)
        } else {
            manager.resumeSession()
        }

        isActive = true
        startTimer()
    }

    private func pausePractice() {
        manager.pauseSession()
        isActive = false
        stopTimer()
    }

    private func endPractice() {
        stopTimer()
        manager.endSession(completionRate: completionRate)
        dismiss()
    }

    private func cancelPractice() {
        stopTimer()
        if session != nil {
            manager.cancelSession()
        }
        dismiss()
    }

    private func applyMode(_ mode: PracticeMode) {
        switch mode {
        case .slowMo:
            manager.startSlowMoMode(tempoMultiplier: 0.75)
        case .hideChords:
            manager.startHideChordsMode(revealDelay: 3.0)
        default:
            break
        }
    }

    // MARK: - Timer Management

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Supporting Views

struct ModeButton: View {
    let mode: PracticeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.title3)

                Text(mode.rawValue)
                    .font(.caption2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(8)
    }
}

struct DifficultyLogView: View {
    @Environment(\.dismiss) private var dismiss
    let manager: PracticeManager

    @State private var selectedType: PracticeDifficulty.DifficultyType = .chordTransition
    @State private var chord: String = ""
    @State private var section: String = ""
    @State private var severity: Float = 0.5
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Difficulty Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(PracticeDifficulty.DifficultyType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Details") {
                    TextField("Chord (Optional)", text: $chord)
                    TextField("Section (Optional)", text: $section)
                }

                Section("Severity") {
                    Slider(value: $severity, in: 0...1)
                    Text("Severity: \(Int(severity * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Log Difficulty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.logDifficulty(
                            type: selectedType,
                            chord: chord.isEmpty ? nil : chord,
                            section: section.isEmpty ? nil : section,
                            severity: severity,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Song Model

// This is a placeholder - assumes actual Song model exists in the project
struct Song {
    var id: UUID
    var title: String
}
