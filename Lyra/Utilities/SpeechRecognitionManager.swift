//
//  SpeechRecognitionManager.swift
//  Lyra
//
//  Manages speech-to-text conversion and audio input
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import Speech
import AVFoundation

/// Manages speech recognition and converts audio to text
@MainActor
class SpeechRecognitionManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var recognizedText: String = ""
    @Published var partialText: String = ""
    @Published var isListening: Bool = false
    @Published var state: RecognitionState = .idle
    @Published var error: String?

    // MARK: - Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var settings: VoiceSettings
    private var wakeWordDetector: WakeWordDetector?
    private var continuousMode: Bool = false

    // Callbacks
    var onTextRecognized: ((String) -> Void)?
    var onPartialText: ((String) -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Initialization

    override init() {
        self.settings = VoiceSettings()

        // Initialize speech recognizer for user's locale
        let locale = Locale(identifier: settings.language)
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)

        super.init()

        self.speechRecognizer?.delegate = self

        if settings.wakeWordEnabled {
            self.wakeWordDetector = WakeWordDetector(wakeWord: settings.wakeWord)
        }
    }

    init(settings: VoiceSettings) {
        self.settings = settings

        let locale = Locale(identifier: settings.language)
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)

        super.init()

        self.speechRecognizer?.delegate = self

        if settings.wakeWordEnabled {
            self.wakeWordDetector = WakeWordDetector(wakeWord: settings.wakeWord)
        }
    }

    // MARK: - Permission Management

    /// Request microphone and speech recognition permissions
    func requestPermissions() async -> Bool {
        // Request microphone permission
        let audioAuthorized = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard audioAuthorized else {
            await updateError("Microphone access denied")
            return false
        }

        // Request speech recognition permission
        let speechAuthorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechAuthorized else {
            await updateError("Speech recognition access denied")
            return false
        }

        return true
    }

    /// Check if permissions are granted
    var hasPermissions: Bool {
        let audioPermission = AVAudioSession.sharedInstance().recordPermission == .granted
        let speechPermission = SFSpeechRecognizer.authorizationStatus() == .authorized
        return audioPermission && speechPermission
    }

    // MARK: - Recognition Control

    /// Start listening for speech
    func startListening(continuous: Bool = false) async throws {
        guard hasPermissions else {
            throw RecognitionError.permissionDenied
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw RecognitionError.recognizerUnavailable
        }

        // Stop any ongoing recognition
        stopListening()

        continuousMode = continuous

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw RecognitionError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true  // Privacy: on-device only

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let result = result {
                    let transcript = result.bestTranscription.formattedString

                    if result.isFinal {
                        self.recognizedText = transcript
                        self.partialText = ""
                        self.onTextRecognized?(transcript)

                        if !self.continuousMode {
                            self.stopListening()
                        } else {
                            // Reset for next utterance
                            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s pause
                            self.recognizedText = ""
                        }
                    } else {
                        self.partialText = transcript
                        self.onPartialText?(transcript)
                    }
                }

                if let error = error {
                    await self.handleRecognitionError(error)
                }
            }
        }

        await updateState(.listening)
        isListening = true
    }

    /// Stop listening for speech
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        Task { @MainActor in
            isListening = false
            await updateState(.idle)
        }
    }

    /// Pause listening temporarily
    func pauseListening() {
        if audioEngine.isRunning {
            audioEngine.pause()

            Task { @MainActor in
                isListening = false
                await updateState(.idle)
            }
        }
    }

    /// Resume listening
    func resumeListening() async throws {
        if !audioEngine.isRunning {
            try audioEngine.start()

            await updateState(.listening)
            isListening = true
        }
    }

    // MARK: - Wake Word Detection

    /// Start wake word listening mode
    func startWakeWordListening() async throws {
        guard settings.wakeWordEnabled, let detector = wakeWordDetector else {
            throw RecognitionError.wakeWordNotEnabled
        }

        detector.onWakeWordDetected = { [weak self] in
            Task { @MainActor in
                try? await self?.startListening(continuous: false)
            }
        }

        try await detector.startListening()
    }

    /// Stop wake word listening
    func stopWakeWordListening() {
        wakeWordDetector?.stopListening()
    }

    // MARK: - Settings

    /// Update voice settings
    func updateSettings(_ newSettings: VoiceSettings) {
        self.settings = newSettings

        // Update wake word detector if needed
        if newSettings.wakeWordEnabled && wakeWordDetector == nil {
            wakeWordDetector = WakeWordDetector(wakeWord: newSettings.wakeWord)
        } else if !newSettings.wakeWordEnabled {
            wakeWordDetector?.stopListening()
            wakeWordDetector = nil
        }
    }

    // MARK: - Audio Level Monitoring

    /// Get current audio input level (0.0 to 1.0)
    func getAudioLevel() -> Float {
        guard audioEngine.isRunning else { return 0.0 }

        let inputNode = audioEngine.inputNode
        let bus = 0

        guard let format = inputNode.outputFormat(forBus: bus) as AVAudioFormat? else {
            return 0.0
        }

        // This is a simplified implementation
        // In production, you'd analyze the buffer to get actual levels
        return audioEngine.isRunning ? 0.5 : 0.0
    }

    // MARK: - Private Helpers

    private func updateState(_ newState: RecognitionState) async {
        await MainActor.run {
            self.state = newState
        }
    }

    private func updateError(_ message: String) async {
        await MainActor.run {
            self.error = message
            self.state = .error(message)
            self.onError?(message)
        }
    }

    private func handleRecognitionError(_ error: Error) async {
        let message = error.localizedDescription
        await updateError(message)
        stopListening()
    }

    // MARK: - Cleanup

    deinit {
        stopListening()
        stopWakeWordListening()
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognitionManager: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(
        _ speechRecognizer: SFSpeechRecognizer,
        availabilityDidChange available: Bool
    ) {
        Task { @MainActor in
            if !available {
                await updateError("Speech recognizer became unavailable")
                stopListening()
            }
        }
    }
}

// MARK: - Wake Word Detector

/// Detects wake word to activate voice commands
class WakeWordDetector {

    private let wakeWord: String
    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var onWakeWordDetected: (() -> Void)?

    init(wakeWord: String) {
        self.wakeWord = wakeWord.lowercased()
        self.recognizer = SFSpeechRecognizer()
    }

    func startListening() async throws {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw RecognitionError.recognizerUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, _ in
            guard let self = self, let result = result else { return }

            let transcript = result.bestTranscription.formattedString.lowercased()

            if transcript.contains(self.wakeWord) {
                self.onWakeWordDetected?()
                self.stopListening()
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}

// MARK: - Recognition Errors

enum RecognitionError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case requestCreationFailed
    case wakeWordNotEnabled
    case audioEngineError

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone or speech recognition permission denied"
        case .recognizerUnavailable:
            return "Speech recognizer is not available"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .wakeWordNotEnabled:
            return "Wake word detection is not enabled"
        case .audioEngineError:
            return "Audio engine encountered an error"
        }
    }
}
