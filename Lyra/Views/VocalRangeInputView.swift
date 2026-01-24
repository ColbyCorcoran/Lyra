//
//  VocalRangeInputView.swift
//  Lyra
//
//  View for recording and analyzing user's vocal range
//  Part of Phase 7.3: Key Intelligence
//

import SwiftUI
import AVFoundation

struct VocalRangeInputView: View {

    // MARK: - Properties

    let onRangeDetected: (VocalRange) -> Void

    @State private var isRecording = false
    @State private var recordingURL: URL?
    @State private var detectedRange: VocalRange?
    @State private var error: String?
    @State private var analyzer = VocalRangeAnalyzer()

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let range = detectedRange {
                    rangeResultView(range)
                } else {
                    recordingView
                }
            }
            .padding()
            .navigationTitle("Vocal Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(spacing: 24) {
            Image(systemName: isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(isRecording ? .red : .blue)
                .symbolEffect(.pulse, isActive: isRecording)

            Text(isRecording ? "Recording..." : "Ready to Record")
                .font(.title2)
                .fontWeight(.bold)

            Text("Sing from your lowest to highest comfortable note")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Range Result View

    private func rangeResultView(_ range: VocalRange) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Range Detected!")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                infoRow(label: "Lowest Note", value: range.lowestNote.name)
                infoRow(label: "Highest Note", value: range.highestNote.name)
                infoRow(label: "Range", value: "\(range.rangeInSemitones) semitones")

                if let voiceType = range.voiceType {
                    HStack {
                        Text("Voice Type:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(voiceType.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(voiceType.color.opacity(0.2))
                            .foregroundStyle(voiceType.color)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)

            Button {
                onRangeDetected(range)
                dismiss()
            } label: {
                Text("Save Range")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }

            Button {
                detectedRange = nil
                recordingURL = nil
            } label: {
                Text("Record Again")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Recording Actions

    private func startRecording() {
        // TODO: Implement actual audio recording
        isRecording = true

        // Simulate recording for 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isRecording {
                stopRecording()
            }
        }
    }

    private func stopRecording() {
        isRecording = false

        // Simulate vocal range detection
        // In real implementation, would analyze recorded audio
        detectedRange = VocalRange(
            lowestNote: MusicalNote(note: "C", octave: 3),
            highestNote: MusicalNote(note: "C", octave: 5),
            comfortableLowest: MusicalNote(note: "E", octave: 3),
            comfortableHighest: MusicalNote(note: "A", octave: 4),
            voiceType: .tenor
        )
    }
}

// MARK: - Preview

#Preview {
    VocalRangeInputView { range in
        print("Detected range: \(range.description)")
    }
}
