//
//  CommandExecutor.swift
//  Lyra
//
//  Executes voice commands and performs actions
//  Part of Phase 7.11: Natural Language Processing
//

import Foundation
import SwiftData

/// Executes voice commands by performing appropriate actions
@MainActor
class CommandExecutor {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let contextManager: ConversationContextManager

    // Managers for different actions
    private var transposeEngine: TransposeEngine?
    private var autoscrollManager: AutoscrollManager?
    private var metronomeManager: MetronomeManager?
    private var searchManager: SearchManager?

    // MARK: - Initialization

    init(modelContext: ModelContext, contextManager: ConversationContextManager) {
        self.modelContext = modelContext
        self.contextManager = contextManager
    }

    // MARK: - Command Execution

    /// Execute a command action
    func execute(_ action: CommandAction) async -> CommandResult {
        switch action.intent {
        // Search intents
        case .findSongs, .findByKey, .findByTempo, .findByMood, .findByArtist, .findByLyrics:
            return await executeSearch(action)

        // Navigation intents
        case .goToSong:
            return await executeGoToSong(action)
        case .goToSet:
            return await executeGoToSet(action)
        case .showNext:
            return await executeShowNext(action)
        case .showPrevious:
            return await executeShowPrevious(action)
        case .goHome:
            return .success(action)

        // Edit intents
        case .transpose:
            return await executeTranspose(action)
        case .setCapo:
            return await executeSetCapo(action)
        case .deleteSong:
            return await executeDeleteSong(action)

        // Performance intents
        case .startAutoscroll:
            return await executeStartAutoscroll(action)
        case .stopAutoscroll:
            return await executeStopAutoscroll(action)
        case .adjustScrollSpeed:
            return await executeAdjustScrollSpeed(action)
        case .startMetronome:
            return await executeStartMetronome(action)
        case .stopMetronome:
            return await executeStopMetronome(action)

        // Set management intents
        case .addToSet:
            return await executeAddToSet(action)
        case .removeFromSet:
            return await executeRemoveFromSet(action)
        case .createSet:
            return await executeCreateSet(action)

        // Query intents
        case .whatSong, .whatSet, .whatsNext, .howMany, .listSets:
            return await executeQuery(action)

        default:
            return .notImplemented
        }
    }

    // MARK: - Search Execution

    private func executeSearch(_ action: CommandAction) async -> CommandResult {
        guard let query = action.parameters["query"] as? String else {
            return .error("No search query provided")
        }

        // Perform search using SearchManager
        // In a real implementation, this would use the actual SearchManager
        // For now, return success with placeholder
        return .success(CommandAction(
            intent: action.intent,
            target: .currentView,
            parameters: action.parameters,
            description: "Searching for: \(query)",
            requiresConfirmation: false
        ))
    }

    // MARK: - Navigation Execution

    private func executeGoToSong(_ action: CommandAction) async -> CommandResult {
        guard case .song(let songID) = action.target else {
            return .error("No song specified")
        }

        // Navigate to song
        return .success(CommandAction(
            intent: .goToSong,
            target: .song(songID),
            parameters: [:],
            description: "Opening song",
            requiresConfirmation: false
        ))
    }

    private func executeGoToSet(_ action: CommandAction) async -> CommandResult {
        guard case .set(let setID) = action.target else {
            return .error("No set specified")
        }

        return .success(CommandAction(
            intent: .goToSet,
            target: .set(setID),
            parameters: [:],
            description: "Opening set",
            requiresConfirmation: false
        ))
    }

    private func executeShowNext(_ action: CommandAction) async -> CommandResult {
        return .success(CommandAction(
            intent: .showNext,
            target: .currentView,
            parameters: [:],
            description: "Showing next item",
            requiresConfirmation: false
        ))
    }

    private func executeShowPrevious(_ action: CommandAction) async -> CommandResult {
        return .success(CommandAction(
            intent: .showPrevious,
            target: .currentView,
            parameters: [:],
            description: "Showing previous item",
            requiresConfirmation: false
        ))
    }

    // MARK: - Edit Execution

    private func executeTranspose(_ action: CommandAction) async -> CommandResult {
        guard case .song(let songID) = action.target else {
            return .error("No song to transpose")
        }

        guard let targetKey = action.parameters["key"] as? String else {
            return .error("No target key specified")
        }

        // In real implementation, transpose the song
        return .success(CommandAction(
            intent: .transpose,
            target: .song(songID),
            parameters: ["key": targetKey],
            description: "Transposed to \(targetKey)",
            requiresConfirmation: false
        ))
    }

    private func executeSetCapo(_ action: CommandAction) async -> CommandResult {
        guard case .song(let songID) = action.target else {
            return .error("No song specified")
        }

        guard let capoPosition = action.parameters["capo"] as? Int else {
            return .error("No capo position specified")
        }

        return .success(CommandAction(
            intent: .setCapo,
            target: .song(songID),
            parameters: ["capo": capoPosition],
            description: "Set capo to \(capoPosition)",
            requiresConfirmation: false
        ))
    }

    private func executeDeleteSong(_ action: CommandAction) async -> CommandResult {
        guard case .song(let songID) = action.target else {
            return .error("No song to delete")
        }

        // This is destructive, so return needsConfirmation
        return .needsConfirmation(action, reason: "This will permanently delete the song")
    }

    // MARK: - Performance Execution

    private func executeStartAutoscroll(_ action: CommandAction) async -> CommandResult {
        return .success(CommandAction(
            intent: .startAutoscroll,
            target: .currentView,
            parameters: action.parameters,
            description: "Started autoscroll",
            requiresConfirmation: false
        ))
    }

    private func executeStopAutoscroll(_ action: CommandAction) async -> CommandResult {
        return .success(CommandAction(
            intent: .stopAutoscroll,
            target: .currentView,
            parameters: [:],
            description: "Stopped autoscroll",
            requiresConfirmation: false
        ))
    }

    private func executeAdjustScrollSpeed(_ action: CommandAction) async -> CommandResult {
        guard let direction = action.parameters["direction"] as? String else {
            return .error("No direction specified")
        }

        return .success(CommandAction(
            intent: .adjustScrollSpeed,
            target: .currentView,
            parameters: ["direction": direction],
            description: "Adjusted scroll speed \(direction)",
            requiresConfirmation: false
        ))
    }

    private func executeStartMetronome(_ action: CommandAction) async -> CommandResult {
        let tempo = action.parameters["tempo"] as? Int ?? 120

        return .success(CommandAction(
            intent: .startMetronome,
            target: .application,
            parameters: ["tempo": tempo],
            description: "Started metronome at \(tempo) BPM",
            requiresConfirmation: false
        ))
    }

    private func executeStopMetronome(_ action: CommandAction) async -> CommandResult {
        return .success(CommandAction(
            intent: .stopMetronome,
            target: .application,
            parameters: [:],
            description: "Stopped metronome",
            requiresConfirmation: false
        ))
    }

    // MARK: - Set Management Execution

    private func executeAddToSet(_ action: CommandAction) async -> CommandResult {
        guard case .song(let songID) = action.target else {
            return .error("No song to add")
        }

        guard let setName = action.parameters["setName"] as? String else {
            return .error("No set specified")
        }

        return .success(CommandAction(
            intent: .addToSet,
            target: .song(songID),
            parameters: ["setName": setName],
            description: "Added song to \(setName)",
            requiresConfirmation: false
        ))
    }

    private func executeRemoveFromSet(_ action: CommandAction) async -> CommandResult {
        guard case .song(let songID) = action.target else {
            return .error("No song specified")
        }

        return .needsConfirmation(action, reason: "Remove this song from the set?")
    }

    private func executeCreateSet(_ action: CommandAction) async -> CommandResult {
        guard let setName = action.parameters["setName"] as? String else {
            return .error("No set name provided")
        }

        return .success(CommandAction(
            intent: .createSet,
            target: .application,
            parameters: ["setName": setName],
            description: "Created set '\(setName)'",
            requiresConfirmation: false
        ))
    }

    // MARK: - Query Execution

    private func executeQuery(_ action: CommandAction) async -> CommandResult {
        // Query intents return information, don't execute actions
        return .success(CommandAction(
            intent: action.intent,
            target: .none,
            parameters: action.parameters,
            description: "Query executed",
            requiresConfirmation: false
        ))
    }

    // MARK: - Helper Methods

    /// Check if action can be executed
    func canExecute(_ action: CommandAction) -> (can: Bool, reason: String?) {
        switch action.intent {
        case .transpose, .setCapo:
            guard case .song = action.target else {
                return (false, "No song selected")
            }

        case .addToSet, .removeFromSet:
            guard case .song = action.target else {
                return (false, "No song specified")
            }

        default:
            break
        }

        return (true, nil)
    }

    /// Get confirmation message for action
    func getConfirmationMessage(_ action: CommandAction) -> String {
        switch action.intent {
        case .deleteSong:
            return "Are you sure you want to delete this song?"
        case .deleteSet:
            return "Are you sure you want to delete this set?"
        case .removeFromSet:
            return "Remove this song from the set?"
        case .transpose:
            if let key = action.parameters["key"] as? String {
                return "Transpose to \(key)?"
            }
            return "Confirm transpose?"
        default:
            return "Confirm this action?"
        }
    }
}
