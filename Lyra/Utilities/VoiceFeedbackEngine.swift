//
//  VoiceFeedbackEngine.swift
//  Lyra
//
//  Provides audio feedback and text-to-speech responses
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import AVFoundation

/// Provides audio feedback for voice commands
@MainActor
class VoiceFeedbackEngine: NSObject, ObservableObject {

    // MARK: - Properties

    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var settings: VoiceSettings

    // MARK: - Initialization

    override init() {
        self.settings = VoiceSettings()
        super.init()
        self.synthesizer.delegate = self
    }

    init(settings: VoiceSettings) {
        self.settings = settings
        super.init()
        self.synthesizer.delegate = self
    }

    // MARK: - Feedback Methods

    /// Provide audio feedback for command result
    func provideFeedback(for result: CommandResult) {
        guard settings.audioFeedbackEnabled else { return }

        let message = generateFeedbackMessage(for: result)
        speak(message, verbosity: settings.feedbackVerbosity)
    }

    /// Speak confirmation message
    func speakConfirmation(_ action: CommandAction) {
        guard settings.audioFeedbackEnabled else { return }

        let message = generateConfirmationMessage(action)
        speak(message, verbosity: .normal)
    }

    /// Speak error message
    func speakError(_ message: String) {
        guard settings.audioFeedbackEnabled else { return }

        speak("Error: \(message)", verbosity: .normal)
    }

    /// Speak clarification request
    func speakClarification(_ message: String) {
        guard settings.audioFeedbackEnabled else { return }

        speak(message, verbosity: .detailed)
    }

    /// Speak success message
    func speakSuccess(_ message: String) {
        guard settings.audioFeedbackEnabled else { return }

        speak(message, verbosity: settings.feedbackVerbosity)
    }

    // MARK: - Text-to-Speech

    /// Speak text with given verbosity
    func speak(_ text: String, verbosity: VoiceSettings.FeedbackVerbosity) {
        // Adjust message based on verbosity
        let message: String

        switch verbosity {
        case .minimal:
            // Short confirmation sound or minimal text
            message = getMinimalResponse(text)
        case .normal:
            message = text
        case .detailed:
            message = text  // Could add more detail here
        }

        speakText(message)
    }

    /// Speak text directly
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)

        // Configure speech parameters
        utterance.voice = AVSpeechSynthesisVoice(language: settings.language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8

        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    /// Stop speaking
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    // MARK: - Message Generation

    /// Generate feedback message for command result
    private func generateFeedbackMessage(for result: CommandResult) -> String {
        switch result {
        case .success(let action):
            return generateSuccessMessage(action)
        case .needsConfirmation(let action, let reason):
            return "\(reason) Say yes to confirm or no to cancel."
        case .needsClarification(let options):
            return generateClarificationMessage(options)
        case .error(let message):
            return message
        case .notImplemented:
            return "This feature is not yet available."
        }
    }

    /// Generate success message for action
    private func generateSuccessMessage(_ action: CommandAction) -> String {
        switch action.intent {
        case .findSongs:
            return "Here are the songs I found."
        case .findByKey:
            if let key = action.parameters["key"] as? String {
                return "Showing songs in \(key)."
            }
            return "Here are the songs."

        case .transpose:
            if let key = action.parameters["key"] as? String {
                return "Transposed to \(key)."
            }
            return "Song transposed."

        case .setCapo:
            if let capo = action.parameters["capo"] as? Int {
                if capo == 0 {
                    return "Capo removed."
                }
                return "Capo set to position \(capo)."
            }
            return "Capo updated."

        case .startAutoscroll:
            return "Autoscroll started."
        case .stopAutoscroll:
            return "Autoscroll stopped."
        case .adjustScrollSpeed:
            if let direction = action.parameters["direction"] as? String {
                return "Scroll speed \(direction)."
            }
            return "Scroll speed adjusted."

        case .startMetronome:
            if let tempo = action.parameters["tempo"] as? Int {
                return "Metronome started at \(tempo) beats per minute."
            }
            return "Metronome started."
        case .stopMetronome:
            return "Metronome stopped."

        case .addToSet:
            return "Song added to set."
        case .removeFromSet:
            return "Song removed from set."
        case .createSet:
            if let name = action.parameters["setName"] as? String {
                return "Set '\(name)' created."
            }
            return "Set created."

        case .goToSong:
            return "Opening song."
        case .goToSet:
            return "Opening set."
        case .showNext:
            return "Showing next."
        case .showPrevious:
            return "Showing previous."

        default:
            return "Done."
        }
    }

    /// Generate clarification message
    private func generateClarificationMessage(_ options: [CommandOption]) -> String {
        if options.count == 2 {
            return "I found two matches. Say one or two to choose."
        } else if options.count > 2 {
            return "I found \(options.count) matches. Please be more specific."
        } else {
            return "I need more information to complete that action."
        }
    }

    /// Generate confirmation message
    private func generateConfirmationMessage(_ action: CommandAction) -> String {
        switch action.intent {
        case .deleteSong:
            return "Delete this song?"
        case .deleteSet:
            return "Delete this set?"
        case .transpose:
            if let key = action.parameters["key"] as? String {
                return "Transpose to \(key)?"
            }
            return "Confirm transpose?"
        default:
            return "Is this correct?"
        }
    }

    /// Get minimal response for text
    private func getMinimalResponse(_ text: String) -> String {
        // Map to short responses
        if text.contains("transposed") {
            return "Done"
        } else if text.contains("started") {
            return "On"
        } else if text.contains("stopped") {
            return "Off"
        } else if text.contains("added") {
            return "Added"
        } else if text.contains("removed") {
            return "Removed"
        } else if text.contains("created") {
            return "Created"
        } else {
            return "OK"
        }
    }

    // MARK: - Settings

    /// Update voice settings
    func updateSettings(_ newSettings: VoiceSettings) {
        self.settings = newSettings
    }

    // MARK: - Playback Control

    /// Pause speaking
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    /// Resume speaking
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }

    // MARK: - Audio Session

    /// Configure audio session for speech
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceFeedbackEngine: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}

// MARK: - Feedback Sounds

extension VoiceFeedbackEngine {

    /// Play success sound
    func playSuccessSound() {
        guard settings.audioFeedbackEnabled else { return }
        // Could play a system sound here
        // AudioServicesPlaySystemSound(SystemSoundID(1057))
    }

    /// Play error sound
    func playErrorSound() {
        guard settings.audioFeedbackEnabled else { return }
        // AudioServicesPlaySystemSound(SystemSoundID(1053))
    }

    /// Play confirmation sound
    func playConfirmationSound() {
        guard settings.audioFeedbackEnabled else { return }
        // AudioServicesPlaySystemSound(SystemSoundID(1104))
    }
}
