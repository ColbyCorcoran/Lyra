//
//  VoiceCommandView.swift
//  Lyra
//
//  UI for voice command interaction
//  Part of Phase 7.11: Natural Language Processing
//

import SwiftUI
import SwiftData

/// Main voice command interface
struct VoiceCommandView: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var voiceEngine: VoiceCommandEngine
    @State private var showHistory = false
    @State private var showSettings = false

    init(modelContext: ModelContext) {
        _voiceEngine = StateObject(wrappedValue: VoiceCommandEngine(modelContext: modelContext))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView

            // Microphone button and status
            microphoneView

            // Recognized text display
            if !voiceEngine.recognizedText.isEmpty {
                recognizedTextView
            }

            // Pending confirmation
            if let action = voiceEngine.pendingConfirmation {
                confirmationView(action: action)
            }

            // Context summary
            contextView

            Spacer()

            // Command history
            if showHistory {
                historyView
            }

            // Quick command buttons
            quickCommandsView
        }
        .padding()
        .navigationTitle("Voice Commands")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showHistory.toggle()
                } label: {
                    Image(systemName: "clock")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            VoiceCommandSettingsView(voiceEngine: voiceEngine)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: voiceEngine.isListening ? "waveform" : "mic.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(voiceEngine.isListening ? .blue : .gray)
                .symbolEffect(.pulse, isActive: voiceEngine.isListening)

            Text(statusText)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var microphoneView: some View {
        Button {
            Task {
                try? await voiceEngine.toggleListening()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(voiceEngine.isListening ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)

                Image(systemName: voiceEngine.isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private var recognizedTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recognized:")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(voiceEngine.recognizedText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    private func confirmationView(action: CommandAction) -> some View {
        VStack(spacing: 16) {
            Text("Confirmation Required")
                .font(.headline)

            Text(action.description)
                .font(.body)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Button("Cancel") {
                    voiceEngine.cancelPendingAction()
                }
                .buttonStyle(.bordered)

                Button("Confirm") {
                    Task {
                        _ = await voiceEngine.confirmPendingAction()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }

    private var contextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Context")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(voiceEngine.getContextSummary())
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var historyView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("Recent Commands")
                    .font(.headline)
                    .padding(.bottom, 8)

                ForEach(voiceEngine.getCommandHistory(limit: 10), id: \.id) { command in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(command.rawText)
                            .font(.body)

                        HStack {
                            Text(command.getIntent().rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(5)

                            Text(String(format: "%.0f%%", command.confidence * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(command.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .frame(maxHeight: 300)
    }

    private var quickCommandsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Commands")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickCommandButton("Find Songs", systemImage: "magnifyingglass", command: "find songs")
                quickCommandButton("Transpose", systemImage: "music.note", command: "transpose to C")
                quickCommandButton("Start Scroll", systemImage: "arrow.down.circle", command: "start autoscroll")
                quickCommandButton("What's Next?", systemImage: "questionmark.circle", command: "what's next in the set")
            }
        }
        .padding()
    }

    private func quickCommandButton(
        _ title: String,
        systemImage: String,
        command: String
    ) -> some View {
        Button {
            Task {
                _ = await voiceEngine.processCommand(command)
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)

                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Properties

    private var statusText: String {
        switch voiceEngine.state {
        case .idle:
            return "Tap to start listening"
        case .listening:
            return "Listening..."
        case .processing:
            return "Processing..."
        case .speaking:
            return "Speaking..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - Voice Command Settings View

struct VoiceCommandSettingsView: View {
    @ObservedObject var voiceEngine: VoiceCommandEngine
    @Environment(\.dismiss) private var dismiss
    @State private var settings = VoiceSettings()

    var body: some View {
        NavigationView {
            Form {
                Section("General") {
                    Toggle("Enable Voice Commands", isOn: $settings.isEnabled)

                    Toggle("Continuous Listening", isOn: $settings.continuousListening)
                }

                Section("Wake Word") {
                    Toggle("Enable Wake Word", isOn: $settings.wakeWordEnabled)

                    if settings.wakeWordEnabled {
                        TextField("Wake Word", text: $settings.wakeWord)
                    }
                }

                Section("Feedback") {
                    Picker("Confirmation Level", selection: $settings.confirmationLevel) {
                        Text("None").tag(VoiceSettings.ConfirmationLevel.none)
                        Text("Destructive Only").tag(VoiceSettings.ConfirmationLevel.destructive)
                        Text("All Commands").tag(VoiceSettings.ConfirmationLevel.all)
                    }

                    Picker("Feedback Verbosity", selection: $settings.feedbackVerbosity) {
                        Text("Minimal").tag(VoiceSettings.FeedbackVerbosity.minimal)
                        Text("Normal").tag(VoiceSettings.FeedbackVerbosity.normal)
                        Text("Detailed").tag(VoiceSettings.FeedbackVerbosity.detailed)
                    }

                    Toggle("Audio Feedback", isOn: $settings.audioFeedbackEnabled)
                    Toggle("Haptic Feedback", isOn: $settings.hapticFeedbackEnabled)
                }

                Section("Learning") {
                    Toggle("Learn My Commands", isOn: $settings.learningEnabled)
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        voiceEngine.updateSettings(settings)
                        dismiss()
                    }
                }
            }
        }
    }
}
