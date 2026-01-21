//
//  TimelineRecordingView.swift
//  Lyra
//
//  Record and playback custom autoscroll timelines
//

import SwiftUI
import SwiftData

struct TimelineRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song
    @ObservedObject var autoscrollManager: AutoscrollManager

    @State private var isRecording: Bool = false
    @State private var recordedTimelines: [AutoscrollTimeline] = []
    @State private var selectedTimeline: AutoscrollTimeline? = nil
    @State private var showNamePrompt: Bool = false
    @State private var timelineName: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                if isRecording || autoscrollManager.isRecording {
                    recordingHeader
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Timeline List
                Form {
                    if recordedTimelines.isEmpty {
                        Section {
                            emptyState
                        }
                    } else {
                        Section {
                            ForEach(recordedTimelines) { timeline in
                                timelineRow(timeline)
                            }
                            .onDelete(perform: deleteTimelines)
                        } header: {
                            Text("Recorded Timelines")
                        } footer: {
                            Text("Tap a timeline to use it for autoscroll. Swipe to delete.")
                        }
                    }

                    // How it Works
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "1.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Start recording while viewing the song")
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "2.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Manually scroll at your own pace")
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "3.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Stop recording to save the pattern")
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "4.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Play back the exact scroll pattern anytime")
                            }
                        }
                        .font(.caption)
                    } header: {
                        Text("How It Works")
                    }
                }
            }
            .navigationTitle("Timeline Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if isRecording || autoscrollManager.isRecording {
                        Button {
                            stopRecording()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.circle.fill")
                                Text("Stop")
                            }
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                        }
                    } else {
                        Button {
                            startRecording()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "record.circle")
                                Text("Record")
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
            .onAppear {
                loadTimelines()
            }
            .alert("Name Timeline", isPresented: $showNamePrompt) {
                TextField("Timeline Name", text: $timelineName)
                Button("Cancel", role: .cancel) {
                    autoscrollManager.cancelRecording()
                }
                Button("Save") {
                    saveRecording()
                }
            } message: {
                Text("Give this timeline a memorable name")
            }
        }
    }

    // MARK: - Recording Header

    private var recordingHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Recording indicator
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .opacity(isRecording ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)

                Text("Recording in Progress")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }

            Text("Manually scroll the song at your desired pace. Your scroll pattern will be recorded and can be replayed later.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemGray6))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("No Recorded Timelines")
                    .font(.headline)

                Text("Record your own scroll patterns for perfect performance every time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timeline Row

    @ViewBuilder
    private func timelineRow(_ timeline: AutoscrollTimeline) -> some View {
        Button {
            selectTimeline(timeline)
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(selectedTimeline?.id == timeline.id ? Color.blue.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 40, height: 40)

                    Image(systemName: selectedTimeline?.id == timeline.id ? "waveform.circle.fill" : "waveform")
                        .foregroundStyle(selectedTimeline?.id == timeline.id ? .blue : .secondary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeline.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(formatDuration(timeline.duration))
                                .font(.caption)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.caption2)
                            Text("\(timeline.keyframes.count) keyframes")
                                .font(.caption)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(formatDate(timeline.createdAt))
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedTimeline?.id == timeline.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startRecording() {
        isRecording = true
        autoscrollManager.startRecording()
        HapticManager.shared.success()

        // Dismiss to show song view
        dismiss()
    }

    private func stopRecording() {
        isRecording = false
        timelineName = "Timeline \(recordedTimelines.count + 1)"
        showNamePrompt = true
    }

    private func saveRecording() {
        guard let timeline = autoscrollManager.stopRecording(name: timelineName) else {
            return
        }

        recordedTimelines.append(timeline)
        saveTimelines()

        HapticManager.shared.success()
    }

    private func selectTimeline(_ timeline: AutoscrollTimeline) {
        if selectedTimeline?.id == timeline.id {
            selectedTimeline = nil
            autoscrollManager.configureTimeline(nil, enabled: false)
        } else {
            selectedTimeline = timeline
            autoscrollManager.configureTimeline(timeline, enabled: true)
        }

        HapticManager.shared.selection()
    }

    private func deleteTimelines(at offsets: IndexSet) {
        recordedTimelines.remove(atOffsets: offsets)
        saveTimelines()
        HapticManager.shared.notification(.warning)
    }

    // MARK: - Persistence

    private func loadTimelines() {
        guard let config = song.autoscrollConfiguration else { return }
        recordedTimelines = config.recordedTimelines

        // Check if a timeline is active
        if let preset = config.activePreset(), preset.useTimeline, let timeline = preset.timeline {
            selectedTimeline = timeline
        }
    }

    private func saveTimelines() {
        var config = song.autoscrollConfiguration ?? AdvancedAutoscrollConfig()
        config.recordedTimelines = recordedTimelines

        song.autoscrollConfiguration = config
        song.modifiedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Failed to save timelines: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!
    let manager = AutoscrollManager()

    return TimelineRecordingView(song: song, autoscrollManager: manager)
        .modelContainer(container)
}
