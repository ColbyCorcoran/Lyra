//
//  VoiceCommandEngine.swift
//  Lyra
//
//  Main orchestrator for voice command system
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import SwiftData

/// Main engine that orchestrates all voice command components
@MainActor
class VoiceCommandEngine: ObservableObject {

    // MARK: - Published Properties

    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var recognizedText: String = ""
    @Published var state: RecognitionState = .idle
    @Published var lastCommand: VoiceCommand?
    @Published var pendingConfirmation: CommandAction?

    // MARK: - Components

    private let speechRecognitionManager: SpeechRecognitionManager
    private let intentClassifier: IntentClassifier
    private let entityExtractor: EntityExtractor
    private let contextManager: ConversationContextManager
    private let commandExecutor: CommandExecutor
    private let feedbackEngine: VoiceFeedbackEngine
    private let learner: UserCommandLearner

    // MARK: - Properties

    private let modelContext: ModelContext
    private var settings: VoiceSettings
    private var executionContext: ExecutionContext?

    // MARK: - Initialization

    init(modelContext: ModelContext, settings: VoiceSettings = VoiceSettings()) {
        self.modelContext = modelContext
        self.settings = settings

        // Initialize components
        self.speechRecognitionManager = SpeechRecognitionManager(settings: settings)
        self.intentClassifier = IntentClassifier()
        self.entityExtractor = EntityExtractor()
        self.contextManager = ConversationContextManager(modelContext: modelContext)
        self.commandExecutor = CommandExecutor(
            modelContext: modelContext,
            contextManager: contextManager
        )
        self.feedbackEngine = VoiceFeedbackEngine(settings: settings)
        self.learner = UserCommandLearner(modelContext: modelContext)

        setupCallbacks()
    }

    // MARK: - Setup

    /// Setup callbacks for components
    private func setupCallbacks() {
        // Speech recognition callbacks
        speechRecognitionManager.onTextRecognized = { [weak self] text in
            Task { @MainActor in
                await self?.processRecognizedText(text)
            }
        }

        speechRecognitionManager.onPartialText = { [weak self] text in
            Task { @MainActor in
                self?.recognizedText = text
            }
        }

        speechRecognitionManager.onError = { [weak self] error in
            Task { @MainActor in
                self?.handleError(error)
            }
        }
    }

    // MARK: - Main Processing

    /// Process command from text
    func processCommand(_ text: String) async -> CommandResult {
        guard settings.isEnabled else {
            return .error("Voice commands are disabled")
        }

        // Update state
        state = .processing

        // Clean and normalize text
        let cleanedText = cleanText(text)

        // Classify intent
        let (intent, confidence) = intentClassifier.classifyIntent(cleanedText)

        // Extract entities
        let entities = entityExtractor.extractEntities(cleanedText, intent: intent)

        // Check confidence level
        if confidence < 0.5 {
            return await handleLowConfidence(text: cleanedText, intent: intent, confidence: confidence)
        }

        // Create voice command
        let command = VoiceCommand(
            rawText: text,
            processedText: cleanedText,
            intent: intent,
            entities: entities,
            confidence: confidence,
            contextID: contextManager.getContext().id,
            isFollowUp: contextManager.isFollowUpCommand(cleanedText)
        )

        modelContext.insert(command)
        contextManager.addCommand(command.id)
        lastCommand = command

        // Resolve context references
        let resolvedAction = await resolveAndCreateAction(command: command)

        // Execute command
        let result = await executeCommand(resolvedAction, command: command)

        // Provide feedback
        await provideFeedback(for: result)

        // Learn from execution
        if case .success(let action) = result {
            learner.learnFromSuccess(command: command, action: action)
            learner.recordCommand(intent: intent, success: true, confidence: confidence)
        } else {
            learner.recordCommand(intent: intent, success: false, confidence: confidence)
        }

        state = .idle
        return result
    }

    /// Process recognized text from speech
    private func processRecognizedText(_ text: String) async {
        recognizedText = text

        // Check for wake word if enabled
        if settings.wakeWordEnabled && !text.lowercased().contains(settings.wakeWord.lowercased()) {
            return
        }

        // Process the command
        let result = await processCommand(text)

        // Handle result
        await handleCommandResult(result)
    }

    // MARK: - Action Resolution

    /// Resolve context and create action
    private func resolveAndCreateAction(command: VoiceCommand) async -> CommandAction {
        let intent = command.getIntent()
        let entities = command.getEntities()

        // Build parameters dictionary
        var parameters: [String: Any] = [:]
        var target: CommandAction.ActionTarget = .none

        // Extract parameters from entities
        for entity in entities {
            switch entity.type {
            case .musicalKey:
                parameters["key"] = entity.value
            case .tempo:
                parameters["tempo"] = Int(entity.value) ?? 120
            case .capoPosition:
                parameters["capo"] = Int(entity.value) ?? 0
            case .setName:
                parameters["setName"] = entity.value
            case .songTitle:
                parameters["songTitle"] = entity.value
            case .number:
                parameters["number"] = Int(entity.value) ?? 0
            case .direction:
                parameters["direction"] = entity.value
            default:
                break
            }
        }

        // Resolve target from context
        target = await resolveTarget(for: intent, parameters: parameters, command: command)

        // Create action
        let action = CommandAction(
            intent: intent,
            target: target,
            parameters: parameters,
            description: generateDescription(intent: intent, parameters: parameters),
            requiresConfirmation: intentClassifier.requiresConfirmation(intent)
        )

        return action
    }

    /// Resolve action target from context
    private func resolveTarget(
        for intent: CommandIntent,
        parameters: [String: Any],
        command: VoiceCommand
    ) async -> CommandAction.ActionTarget {
        // Check for explicit targets in parameters
        if let songTitle = parameters["songTitle"] as? String {
            // Search for song by title
            if let songID = await findSongByTitle(songTitle) {
                contextManager.updateContext(currentSong: songID)
                return .song(songID)
            }
        }

        if let setName = parameters["setName"] as? String {
            // Search for set by name
            if let setID = await findSetByName(setName) {
                contextManager.updateContext(currentSet: setID)
                return .set(setID)
            }
        }

        // Try to resolve from pronouns
        if contextManager.containsPronouns(command.rawText) {
            if let songID = contextManager.resolvePronoun("it") ?? contextManager.getReferencedSong() {
                return .song(songID)
            }

            if let setID = contextManager.getReferencedSet() {
                return .set(setID)
            }
        }

        // Default to context-based resolution
        switch intent.category {
        case .edit, .navigate:
            if let songID = contextManager.getReferencedSong() {
                return .song(songID)
            }
        case .manage:
            if let setID = contextManager.getReferencedSet() {
                return .set(setID)
            }
        default:
            break
        }

        return .currentView
    }

    // MARK: - Command Execution

    /// Execute command action
    private func executeCommand(_ action: CommandAction, command: VoiceCommand) async -> CommandResult {
        // Check if confirmation is needed
        if action.requiresConfirmation && settings.confirmationLevel != .none {
            pendingConfirmation = action
            return .needsConfirmation(action, reason: commandExecutor.getConfirmationMessage(action))
        }

        // Check if action can be executed
        let (canExecute, reason) = commandExecutor.canExecute(action)
        guard canExecute else {
            return .error(reason ?? "Cannot execute this action")
        }

        // Execute
        return await commandExecutor.execute(action)
    }

    /// Handle command result
    private func handleCommandResult(_ result: CommandResult) async {
        switch result {
        case .success(let action):
            // Update context
            if case .song(let songID) = action.target {
                contextManager.updateContext(currentSong: songID)
            } else if case .set(let setID) = action.target {
                contextManager.updateContext(currentSet: setID)
            }

        case .needsConfirmation:
            // Wait for user confirmation
            break

        case .needsClarification(let options):
            // Present options to user
            break

        case .error:
            // Error already handled by feedback
            break

        case .notImplemented:
            // Feature not yet implemented
            break
        }
    }

    // MARK: - Confirmation

    /// Confirm pending action
    func confirmPendingAction() async -> CommandResult {
        guard let action = pendingConfirmation else {
            return .error("No pending action to confirm")
        }

        pendingConfirmation = nil

        let result = await commandExecutor.execute(action)
        await provideFeedback(for: result)

        return result
    }

    /// Cancel pending action
    func cancelPendingAction() {
        pendingConfirmation = nil
        feedbackEngine.speakSuccess("Cancelled")
    }

    // MARK: - Listening Control

    /// Start listening for commands
    func startListening() async throws {
        guard settings.isEnabled else {
            throw VoiceCommandError.disabled
        }

        guard await requestPermissions() else {
            throw VoiceCommandError.permissionDenied
        }

        try await speechRecognitionManager.startListening(continuous: settings.continuousListening)
        isListening = true
    }

    /// Stop listening
    func stopListening() {
        speechRecognitionManager.stopListening()
        isListening = false
    }

    /// Toggle listening
    func toggleListening() async throws {
        if isListening {
            stopListening()
        } else {
            try await startListening()
        }
    }

    // MARK: - Feedback

    /// Provide feedback for result
    private func provideFeedback(for result: CommandResult) async {
        feedbackEngine.provideFeedback(for: result)
        isSpeaking = feedbackEngine.isSpeaking
    }

    // MARK: - Low Confidence Handling

    /// Handle low confidence classification
    private func handleLowConfidence(
        text: String,
        intent: CommandIntent,
        confidence: Float
    ) async -> CommandResult {
        // Get possible intents
        let possibleIntents = intentClassifier.getPossibleIntents(text)

        if possibleIntents.count > 1 {
            // Create clarification options
            let options = possibleIntents.prefix(3).map { (intent, conf) in
                CommandOption(
                    title: intent.rawValue,
                    description: "Execute as \(intent.rawValue) command",
                    action: CommandAction(
                        intent: intent,
                        target: .currentView,
                        parameters: ["query": text],
                        description: "Execute with \(Int(conf * 100))% confidence",
                        requiresConfirmation: false
                    )
                )
            }

            return .needsClarification(Array(options))
        }

        // Try suggesting corrections
        let corrections = suggestCorrections(for: text)
        if !corrections.isEmpty {
            return .needsClarification([])  // Could create options from corrections
        }

        return .error("I didn't understand that command. Try rephrasing or say 'help' for available commands.")
    }

    // MARK: - Helpers

    /// Clean and normalize text
    private func cleanText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    /// Generate action description
    private func generateDescription(intent: CommandIntent, parameters: [String: Any]) -> String {
        switch intent {
        case .transpose:
            if let key = parameters["key"] as? String {
                return "Transpose to \(key)"
            }
            return "Transpose song"
        case .findSongs:
            return "Search for songs"
        case .addToSet:
            if let setName = parameters["setName"] as? String {
                return "Add to \(setName)"
            }
            return "Add to set"
        default:
            return intent.rawValue
        }
    }

    /// Find song by title
    private func findSongByTitle(_ title: String) async -> UUID? {
        let descriptor = FetchDescriptor<Song>(
            predicate: #Predicate { song in
                song.title.localizedStandardContains(title)
            }
        )

        return try? modelContext.fetch(descriptor).first?.id
    }

    /// Find set by name
    private func findSetByName(_ name: String) async -> UUID? {
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.name.localizedStandardContains(name)
            }
        )

        return try? modelContext.fetch(descriptor).first?.id
    }

    /// Suggest corrections
    private func suggestCorrections(for text: String) -> [String] {
        return learner.suggestCommands(for: text, limit: 3)
    }

    /// Handle error
    private func handleError(_ message: String) {
        state = .error(message)
        feedbackEngine.speakError(message)
    }

    /// Request permissions
    private func requestPermissions() async -> Bool {
        return await speechRecognitionManager.requestPermissions()
    }

    // MARK: - Settings

    /// Update settings
    func updateSettings(_ newSettings: VoiceSettings) {
        self.settings = newSettings
        speechRecognitionManager.updateSettings(newSettings)
        feedbackEngine.updateSettings(newSettings)
    }

    // MARK: - History

    /// Get command history
    func getCommandHistory(limit: Int = 20) -> [VoiceCommand] {
        let descriptor = FetchDescriptor<VoiceCommand>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let commands = try? modelContext.fetch(descriptor) else {
            return []
        }

        return Array(commands.prefix(limit))
    }

    /// Clear command history
    func clearHistory() {
        let descriptor = FetchDescriptor<VoiceCommand>()

        if let commands = try? modelContext.fetch(descriptor) {
            for command in commands {
                modelContext.delete(command)
            }
        }

        contextManager.clearContext()
    }

    // MARK: - Context

    /// Get current context summary
    func getContextSummary() -> String {
        return contextManager.getContextSummary()
    }

    /// Clear current context
    func clearContext() {
        contextManager.clearContext()
    }
}

// MARK: - Voice Command Errors

enum VoiceCommandError: LocalizedError {
    case disabled
    case permissionDenied
    case recognizerUnavailable
    case processingError

    var errorDescription: String? {
        switch self {
        case .disabled:
            return "Voice commands are disabled in settings"
        case .permissionDenied:
            return "Microphone or speech recognition permission denied"
        case .recognizerUnavailable:
            return "Speech recognizer is not available"
        case .processingError:
            return "Error processing command"
        }
    }
}
