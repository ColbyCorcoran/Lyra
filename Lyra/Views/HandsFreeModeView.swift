//
//  HandsFreeModeView.swift
//  Lyra
//
//  Hands-free mode with voice-only navigation
//  Part of Phase 7.11: Natural Language Processing
//

import SwiftUI
import SwiftData

/// Full hands-free mode interface optimized for voice-only control
struct HandsFreeModeView: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var voiceEngine: VoiceCommandEngine
    @State private var currentSong: Song?
    @State private var currentSet: PerformanceSet?
    @State private var isInPerformanceMode = false

    init(modelContext: ModelContext) {
        _voiceEngine = StateObject(wrappedValue: VoiceCommandEngine(modelContext: modelContext))
    }

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Status indicator
                statusIndicator

                // Current context
                contextDisplay

                // Audio waveform visualization
                if voiceEngine.isListening {
                    waveformView
                }

                Spacer()

                // Spoken feedback display
                if voiceEngine.isSpeaking {
                    feedbackDisplay
                }

                // Control indicator
                controlHints
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startHandsFreeMode()
        }
        .onDisappear {
            stopHandsFreeMode()
        }
    }

    // MARK: - Subviews

    private var statusIndicator: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(lineWidth: 4)
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: voiceEngine.isListening ? 1.0 : 0.0)
                    .stroke(lineWidth: 4)
                    .foregroundColor(.blue)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: voiceEngine.isListening)

                Image(systemName: voiceEngine.isListening ? "waveform" : "mic.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, isActive: voiceEngine.isListening)
            }

            Text(statusText)
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }

    private var contextDisplay: some View {
        VStack(spacing: 24) {
            if let song = currentSong {
                VStack(spacing: 8) {
                    Text("NOW PLAYING")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Text(song.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    if let artist = song.artist {
                        Text(artist)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let key = song.key {
                        HStack(spacing: 16) {
                            Label(key, systemImage: "music.note")

                            if let tempo = song.tempo {
                                Label("\(tempo) BPM", systemImage: "metronome")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            if let set = currentSet {
                VStack(spacing: 4) {
                    Text("SET")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Text(set.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }

    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 3, height: CGFloat.random(in: 20...80))
                    .animation(
                        .easeInOut(duration: 0.3)
                            .repeatForever()
                            .delay(Double(index) * 0.05),
                        value: voiceEngine.isListening
                    )
            }
        }
        .frame(height: 100)
    }

    private var feedbackDisplay: some View {
        VStack(spacing: 12) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.title)
                .foregroundColor(.green)

            Text("Speaking...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }

    private var controlHints: some View {
        VStack(spacing: 12) {
            Text("VOICE COMMANDS")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                commandHint("Next Song", icon: "forward.fill")
                commandHint("Previous", icon: "backward.fill")
                commandHint("Transpose", icon: "arrow.up.arrow.down")
                commandHint("What's Next", icon: "questionmark")
            }
        }
    }

    private func commandHint(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)

            Text(text)
                .font(.caption)
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }

    // MARK: - Computed Properties

    private var statusText: String {
        switch voiceEngine.state {
        case .idle:
            return "Voice commands ready"
        case .listening:
            return voiceEngine.recognizedText.isEmpty ? "Listening..." : voiceEngine.recognizedText
        case .processing:
            return "Processing command..."
        case .speaking:
            return "Speaking response..."
        case .error(let message):
            return "Error: \(message)"
        }
    }

    // MARK: - Methods

    private func startHandsFreeMode() {
        Task {
            try? await voiceEngine.startListening()

            // Enable continuous listening for hands-free
            var settings = VoiceSettings()
            settings.continuousListening = true
            settings.audioFeedbackEnabled = true
            settings.feedbackVerbosity = .detailed
            voiceEngine.updateSettings(settings)
        }
    }

    private func stopHandsFreeMode() {
        voiceEngine.stopListening()
    }
}

// MARK: - Hands-Free Tutorial View

struct HandsFreeTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection

                    commandsSection

                    tipsSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Hands-Free Mode")
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Voice Control")
                .font(.title)
                .fontWeight(.bold)

            Text("Control Lyra completely hands-free using voice commands. Perfect for performance situations.")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private var commandsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Commands")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                commandRow("Navigation", examples: [
                    "Next song",
                    "Previous song",
                    "Go to Amazing Grace",
                    "What's next in the set"
                ])

                commandRow("Editing", examples: [
                    "Transpose to C",
                    "Transpose up two steps",
                    "Set capo to 2"
                ])

                commandRow("Performance", examples: [
                    "Start autoscroll",
                    "Scroll faster",
                    "Start metronome at 120"
                ])

                commandRow("Search", examples: [
                    "Find songs in G",
                    "Show me slow songs",
                    "Search for hymns"
                ])
            }
        }
    }

    private func commandRow(_ category: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)

            ForEach(examples, id: \.self) { example in
                Text("• \(example)")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "mic.fill", text: "Speak clearly at normal volume")
                tipRow(icon: "speaker.wave.2.fill", text: "Listen for audio confirmation")
                tipRow(icon: "arrow.clockwise", text: "Say 'repeat' if you miss a response")
                tipRow(icon: "xmark.circle", text: "Say 'cancel' to abort an action")
            }
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.callout)
        }
    }
}
