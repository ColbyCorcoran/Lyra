//
//  VoiceSearchView.swift
//  Lyra
//
//  Voice search interface using speech recognition
//  Part of Phase 7.4: Search Intelligence
//

import SwiftUI
import Speech
import Combine

struct VoiceSearchView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var transcription = ""
    @State private var isListening = false
    @State private var confidenceLevel: Float = 0.0
    @State private var errorMessage: String?
    @State private var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    // MARK: - Speech Recognition

    @StateObject private var speechRecognizer = SpeechRecognizer()

    // MARK: - Callbacks

    let onSearchSubmit: (String) -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Visual feedback
                voiceVisualization

                // Transcription display
                transcriptionDisplay

                // Confidence indicator
                if isListening && confidenceLevel > 0 {
                    confidenceIndicator
                }

                // Error message
                if let error = errorMessage {
                    errorView(message: error)
                }

                Spacer()

                // Controls
                controlsSection

                // Tips
                tipsSection
            }
            .padding()
            .navigationTitle("Voice Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        stopListening()
                        dismiss()
                    }
                }

                if !transcription.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Search") {
                            submitSearch()
                        }
                    }
                }
            }
            .onAppear {
                requestAuthorization()
            }
            .onDisappear {
                stopListening()
            }
        }
    }

    // MARK: - Voice Visualization

    private var voiceVisualization: some View {
        ZStack {
            // Pulsing circles
            if isListening {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.blue.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 100 + CGFloat(index) * 40, height: 100 + CGFloat(index) * 40)
                        .scaleEffect(isListening ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isListening
                        )
                }
            }

            // Microphone icon
            Image(systemName: isListening ? "mic.fill" : "mic")
                .font(.system(size: 50))
                .foregroundStyle(isListening ? .blue : .secondary)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10)
                )
        }
        .frame(height: 200)
    }

    // MARK: - Transcription Display

    private var transcriptionDisplay: some View {
        VStack(spacing: 8) {
            if transcription.isEmpty {
                Text(isListening ? "Listening..." : "Tap to start")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                Text(transcription)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .frame(minHeight: 100)
    }

    // MARK: - Confidence Indicator

    private var confidenceIndicator: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Confidence")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(confidenceLevel * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(confidenceColor)
            }

            ProgressView(value: confidenceLevel, total: 1.0)
                .tint(confidenceColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var confidenceColor: Color {
        if confidenceLevel > 0.8 {
            return .green
        } else if confidenceLevel > 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemOrange).opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: 20) {
            // Record button
            Button(action: toggleListening) {
                Label(
                    isListening ? "Stop" : "Start",
                    systemImage: isListening ? "stop.circle.fill" : "record.circle"
                )
                .font(.title3)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isListening ? Color.red : Color.blue)
                .cornerRadius(12)
            }
            .disabled(authorizationStatus != .authorized)

            // Clear button
            if !transcription.isEmpty {
                Button(action: clearTranscription) {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.secondary)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Tips

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Voice Search Tips", systemImage: "lightbulb")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "1.circle.fill", text: "Speak clearly and naturally")
                tipRow(icon: "2.circle.fill", text: "Try: \"Fast worship songs in C\"")
                tipRow(icon: "3.circle.fill", text: "Or: \"Songs by Hillsong with no capo\"")
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                authorizationStatus = status

                switch status {
                case .authorized:
                    startListening()
                case .denied:
                    errorMessage = "Speech recognition access denied. Please enable in Settings."
                case .restricted:
                    errorMessage = "Speech recognition restricted on this device."
                case .notDetermined:
                    errorMessage = "Speech recognition not authorized."
                @unknown default:
                    errorMessage = "Unknown authorization status."
                }
            }
        }
    }

    private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition not authorized."
            return
        }

        errorMessage = nil
        transcription = ""
        confidenceLevel = 0.0
        isListening = true

        speechRecognizer.startRecording { result in
            DispatchQueue.main.async {
                transcription = result.bestTranscription.formattedString
                confidenceLevel = calculateConfidence(result)
            }
        } onError: { error in
            DispatchQueue.main.async {
                errorMessage = error.localizedDescription
                isListening = false
            }
        }
    }

    private func stopListening() {
        isListening = false
        speechRecognizer.stopRecording()
    }

    private func clearTranscription() {
        transcription = ""
        confidenceLevel = 0.0
        errorMessage = nil
    }

    private func submitSearch() {
        guard !transcription.isEmpty else { return }

        stopListening()
        onSearchSubmit(transcription)
        dismiss()
    }

    private func calculateConfidence(_ result: SFSpeechRecognitionResult) -> Float {
        let segments = result.bestTranscription.segments

        guard !segments.isEmpty else { return 0.0 }

        let totalConfidence = segments.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Float(segments.count)
    }
}

// MARK: - Speech Recognizer

class SpeechRecognizer: ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func startRecording(
        onResult: @escaping (SFSpeechRecognitionResult) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onError(error)
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            onError(SpeechRecognitionError.recognitionRequestCreationFailed)
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            onError(error)
            return
        }

        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                onResult(result)

                if result.isFinal {
                    self.stopRecording()
                }
            }

            if let error = error {
                onError(error)
                self.stopRecording()
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil
    }
}

enum SpeechRecognitionError: Error {
    case recognitionRequestCreationFailed
    case audioEngineStartFailed
    case recognitionFailed

    var localizedDescription: String {
        switch self {
        case .recognitionRequestCreationFailed:
            return "Failed to create recognition request"
        case .audioEngineStartFailed:
            return "Failed to start audio engine"
        case .recognitionFailed:
            return "Speech recognition failed"
        }
    }
}

#Preview {
    VoiceSearchView { query in
        print("Search query: \(query)")
    }
}
