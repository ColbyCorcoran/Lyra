//
//  AutoscrollDurationView.swift
//  Lyra
//
//  View for setting autoscroll duration with tap tempo
//

import SwiftUI
import SwiftData

struct AutoscrollDurationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song

    @State private var duration: TimeInterval
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var tapTempoTimes: [Date] = []
    @State private var estimatedDuration: TimeInterval?
    @State private var showTapTempoHint: Bool = true

    init(song: Song) {
        self.song = song
        let initialDuration = TimeInterval(song.autoscrollDuration ?? 180)
        _duration = State(initialValue: initialDuration)
        _minutes = State(initialValue: Int(initialDuration) / 60)
        _seconds = State(initialValue: Int(initialDuration) % 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Manual Duration Section
                Section {
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0...15, id: \.self) { minute in
                            Text("\(minute) min").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)

                    Picker("Seconds", selection: $seconds) {
                        ForEach(0...59, id: \.self) { second in
                            Text("\(second) sec").tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                } header: {
                    Text("Set Duration")
                } footer: {
                    Text("Total: \(formattedDuration)")
                        .font(.headline)
                }

                // Tap Tempo Section
                Section {
                    VStack(spacing: 16) {
                        if showTapTempoHint {
                            HStack(spacing: 12) {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tap to the beat")
                                        .font(.headline)

                                    Text("Tap 4 times at the song's tempo")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }

                        Button {
                            handleTapTempo()
                        } label: {
                            HStack {
                                Spacer()

                                VStack(spacing: 8) {
                                    Image(systemName: tapTempoTimes.isEmpty ? "metronome" : "metronome.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white)

                                    if let estimated = estimatedDuration {
                                        Text(formatDuration(estimated))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("Tap Tempo")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                    }

                                    Text("\(tapTempoTimes.count)/4 taps")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }

                                Spacer()
                            }
                            .padding(.vertical, 32)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)

                        if !tapTempoTimes.isEmpty {
                            HStack {
                                Spacer()

                                Button {
                                    resetTapTempo()
                                } label: {
                                    Label("Reset", systemImage: "arrow.counterclockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)

                                if estimatedDuration != nil {
                                    Button {
                                        applyEstimatedDuration()
                                    } label: {
                                        Label("Use This Duration", systemImage: "checkmark")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }

                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Tap Tempo")
                } footer: {
                    Text("Tap the button in rhythm with the song to estimate duration automatically")
                }

                // Common Durations
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(commonDurations, id: \.seconds) { preset in
                                Button {
                                    setDuration(preset.seconds)
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(preset.label)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Text(formatDuration(preset.seconds))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(currentDuration == preset.seconds ? Color.blue.opacity(0.2) : Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Common Durations")
                }

                // Enable Autoscroll Toggle
                Section {
                    Toggle(isOn: Binding(
                        get: { song.autoscrollEnabled },
                        set: { song.autoscrollEnabled = $0 }
                    )) {
                        Label("Enable Autoscroll", systemImage: "play.circle")
                    }
                } footer: {
                    Text("When enabled, autoscroll controls will appear when viewing this song")
                }
            }
            .navigationTitle("Autoscroll Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDuration()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: minutes) { _, _ in
                updateDurationFromPickers()
            }
            .onChange(of: seconds) { _, _ in
                updateDurationFromPickers()
            }
        }
    }

    // MARK: - Computed Properties

    private var currentDuration: TimeInterval {
        TimeInterval(minutes * 60 + seconds)
    }

    private var formattedDuration: String {
        formatDuration(currentDuration)
    }

    private let commonDurations: [(label: String, seconds: TimeInterval)] = [
        ("Short", 120),      // 2 min
        ("Medium", 180),     // 3 min
        ("Standard", 240),   // 4 min
        ("Long", 300),       // 5 min
        ("Extended", 420)    // 7 min
    ]

    // MARK: - Actions

    private func handleTapTempo() {
        let now = Date()

        // Add tap time
        tapTempoTimes.append(now)

        // Keep only last 4 taps
        if tapTempoTimes.count > 4 {
            tapTempoTimes.removeFirst()
        }

        // Hide hint after first tap
        if showTapTempoHint {
            showTapTempoHint = false
        }

        // Calculate duration if we have enough taps
        if tapTempoTimes.count >= 4 {
            calculateEstimatedDuration()
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func calculateEstimatedDuration() {
        guard tapTempoTimes.count >= 2 else { return }

        // Calculate intervals between taps
        var intervals: [TimeInterval] = []
        for i in 1..<tapTempoTimes.count {
            let interval = tapTempoTimes[i].timeIntervalSince(tapTempoTimes[i-1])
            intervals.append(interval)
        }

        // Average interval = beats per measure
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)

        // Assume 4/4 time, estimate measures
        // If tapping quarter notes: 1 tap = 1 beat
        // Typical song: 60-100 measures at ~2 seconds per measure

        // Simple heuristic: interval * number of expected measures
        // For a typical worship song: ~80 measures
        let estimatedMeasures = 80.0
        let measuresPerTap = 1.0 // Assuming tapping once per measure

        estimatedDuration = averageInterval * (estimatedMeasures / measuresPerTap)

        // Clamp to reasonable range (1-15 minutes)
        if var est = estimatedDuration {
            est = max(60, min(900, est))
            estimatedDuration = est
        }
    }

    private func applyEstimatedDuration() {
        guard let estimated = estimatedDuration else { return }

        setDuration(estimated)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func resetTapTempo() {
        tapTempoTimes = []
        estimatedDuration = nil
        showTapTempoHint = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func setDuration(_ seconds: TimeInterval) {
        let totalSeconds = Int(seconds)
        minutes = totalSeconds / 60
        self.seconds = totalSeconds % 60
    }

    private func updateDurationFromPickers() {
        duration = TimeInterval(minutes * 60 + seconds)
    }

    private func saveDuration() {
        let totalSeconds = minutes * 60 + seconds
        song.autoscrollDuration = totalSeconds

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Failed to save autoscroll duration: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

    return AutoscrollDurationView(song: song)
        .modelContainer(container)
}
