//
//  SongwritingAssistantManager.swift
//  Lyra
//
//  Phase 7.14: AI Songwriting Assistance - Central Orchestrator
//  Coordinates all 8 songwriting intelligence engines
//

import Foundation
import SwiftData

/// Central manager coordinating all songwriting assistance features
/// Orchestrates the 8 specialized engines (100% on-device)
@MainActor
class SongwritingAssistantManager: ObservableObject {

    // MARK: - Shared Instance
    static let shared = SongwritingAssistantManager()

    // MARK: - Engine References

    private let chordProgressionEngine = ChordProgressionEngine.shared
    private let lyricSuggestionEngine = LyricSuggestionEngine.shared
    private let melodyHintEngine = MelodyHintEngine.shared
    private let songStructureEngine = SongStructureEngine.shared
    private let collaborationEngine = CollaborationEngine.shared
    private let styleTransferEngine = StyleTransferEngine.shared
    private let learningEngine = LearningEngine.shared

    // MARK: - State

    @Published var isEnabled: Bool = true
    @Published var currentMode: AssistantMode = .suggest
    @Published var activeFeatures: Set<AssistantFeature> = Set(AssistantFeature.allCases)

    // MARK: - Comprehensive Songwriting Workflow

    /// Generate a complete song starter
    func generateSongStarter(
        genre: String,
        key: String,
        mood: String,
        theme: String
    ) -> SongStarter {

        // 1. Generate chord progression
        let progression = chordProgressionEngine.generateProgression(
            in: key,
            style: genre,
            length: 8,
            isMinor: mood.lowercased().contains("sad") || mood.lowercased().contains("melancholy")
        )

        // 2. Suggest song structure
        let structure = songStructureEngine.suggestStructure(
            for: genre,
            targetLength: 64,
            mood: mood
        )

        // 3. Generate theme-based phrases
        let themePhrases = lyricSuggestionEngine.generateThemePhrase(
            theme: theme,
            mood: mood,
            count: 3
        )

        // 4. Create melody hints
        let melodyHints = progression.chords.prefix(4).map { chord in
            melodyHintEngine.suggestMelody(
                for: chord,
                in: key,
                style: .stepwise,
                length: 4
            )
        }

        // 5. Get personalized tempo from learning
        let suggestedTempo = learningEngine.getPersonalizedTempo()

        return SongStarter(
            genre: genre,
            key: key,
            tempo: suggestedTempo,
            mood: mood,
            theme: theme,
            chordProgression: progression,
            structure: structure,
            lyricIdeas: themePhrases,
            melodyHints: Array(melodyHints),
            timestamp: Date()
        )
    }

    /// Get contextual assistance for current songwriting task
    func getContextualAssistance(
        currentChords: [String],
        currentLyrics: String,
        key: String,
        genre: String
    ) -> ContextualAssistance {

        var suggestions: [String] = []
        var quickActions: [QuickAction] = []

        // 1. Chord continuation suggestions
        let nextChords = chordProgressionEngine.suggestNextChord(
            after: currentChords,
            in: key,
            count: 3
        )

        suggestions.append("Next chord suggestions: \(nextChords.map { $0.chord }.joined(separator: ", "))")

        quickActions.append(QuickAction(
            title: "Add Next Chord",
            icon: "music.note",
            action: .addChord(nextChords.first?.chord ?? "C")
        ))

        // 2. Lyric suggestions
        if !currentLyrics.isEmpty {
            let words = currentLyrics.split(separator: " ")
            if let lastWord = words.last {
                let rhymes = lyricSuggestionEngine.suggestRhymes(for: String(lastWord), count: 3)

                if !rhymes.isEmpty {
                    suggestions.append("Rhymes: \(rhymes.map { $0.word }.joined(separator: ", "))")

                    quickActions.append(QuickAction(
                        title: "Get Rhymes",
                        icon: "text.bubble",
                        action: .showRhymes
                    ))
                }
            }
        }

        // 3. Structure recommendations
        let structureAnalysis = songStructureEngine.analyzeStructure(["Verse", "Chorus"])

        if !structureAnalysis.suggestions.isEmpty {
            suggestions.append("Structure: \(structureAnalysis.suggestions.first!)")

            quickActions.append(QuickAction(
                title: "Improve Structure",
                icon: "square.grid.2x2",
                action: .improveStructure
            ))
        }

        // 4. Style suggestions
        quickActions.append(QuickAction(
            title: "Try Different Style",
            icon: "wand.and.stars",
            action: .changeStyle
        ))

        return ContextualAssistance(
            suggestions: suggestions,
            quickActions: quickActions,
            confidence: 0.8
        )
    }

    /// Complete songwriting session with full AI assistance
    func assistWithCompleteSong(
        initialIdea: String,
        genre: String,
        goal: String
    ) async -> CompleteSongAssistance {

        // 1. Start collaboration session
        let session = collaborationEngine.startSession(
            songID: UUID(),
            initialContent: initialIdea,
            goal: goal
        )

        // 2. Analyze initial idea
        let key = "C" // In production, detect from initial idea
        let tempo = learningEngine.getPersonalizedTempo()

        // 3. Generate comprehensive suggestions
        let chordProgression = chordProgressionEngine.generateProgression(
            in: key,
            style: genre,
            length: 16
        )

        let structure = songStructureEngine.suggestStructure(for: genre, targetLength: 80)

        let lyricThemes = lyricSuggestionEngine.generateThemePhrase(theme: goal, count: 5)

        let melodyIdeas = melodyHintEngine.suggestMelodyVariations(
            for: chordProgression.chords.first ?? "C",
            in: key,
            count: 3
        )

        // 4. Provide style alternatives
        let styleVariations = styleTransferEngine.suggestArrangement(for: genre)

        // 5. Learn from this session
        learningEngine.learnFromSong(
            chords: chordProgression.chords,
            key: key,
            tempo: tempo,
            genre: genre,
            structure: structure.sections
        )

        return CompleteSongAssistance(
            sessionID: session.id,
            chordProgression: chordProgression,
            structure: structure,
            lyricIdeas: lyricThemes,
            melodyIdeas: melodyIdeas,
            arrangementIdeas: styleVariations,
            estimatedCompletionSteps: 5
        )
    }

    /// Get feature-specific help
    func getFeatureHelp(for feature: AssistantFeature) -> FeatureHelp {
        switch feature {
        case .chordProgression:
            return FeatureHelp(
                feature: feature,
                description: "Generate chord progressions and suggest next chords",
                capabilities: [
                    "Generate progressions in any key",
                    "Suggest next chord with music theory reasoning",
                    "Create variations of existing progressions"
                ],
                examples: [
                    "Generate a pop progression in C major",
                    "Suggest next chord after C-Am-F",
                    "Create variations with passing chords"
                ]
            )

        case .lyrics:
            return FeatureHelp(
                feature: feature,
                description: "Assist with lyric writing, rhymes, and word choices",
                capabilities: [
                    "Find rhyming words",
                    "Suggest word alternatives",
                    "Generate theme-based phrases",
                    "Complete partial lines"
                ],
                examples: [
                    "Find rhymes for 'love'",
                    "Suggest alternatives for 'happy'",
                    "Generate phrases about hope"
                ]
            )

        case .melody:
            return FeatureHelp(
                feature: feature,
                description: "Create melodic patterns and hints",
                capabilities: [
                    "Generate singable melodies",
                    "Suggest melodic continuations",
                    "Create catchy hooks",
                    "Provide melody variations"
                ],
                examples: [
                    "Generate melody for C major chord",
                    "Continue melody from previous phrase",
                    "Create a memorable hook"
                ]
            )

        case .structure:
            return FeatureHelp(
                feature: feature,
                description: "Design song structure and arrangement",
                capabilities: [
                    "Suggest song structures by genre",
                    "Analyze existing structure",
                    "Recommend section lengths",
                    "Create arrangement variations"
                ],
                examples: [
                    "Suggest pop song structure",
                    "Analyze my current structure",
                    "How long should my verse be?"
                ]
            )

        case .collaboration:
            return FeatureHelp(
                feature: feature,
                description: "Co-write with AI assistance",
                capabilities: [
                    "Iterative refinement",
                    "Create variations",
                    "A/B comparison",
                    "Track version history"
                ],
                examples: [
                    "Refine my chorus",
                    "Create 3 variations",
                    "Compare two versions"
                ]
            )

        case .styleTransfer:
            return FeatureHelp(
                feature: feature,
                description: "Transform songs between genres and styles",
                capabilities: [
                    "Convert between genres",
                    "Reharmonize progressions",
                    "Suggest arrangements",
                    "Apply style transformations"
                ],
                examples: [
                    "Make this sound like jazz",
                    "Reharmonize with jazz chords",
                    "Arrange for worship style"
                ]
            )

        case .learning:
            return FeatureHelp(
                feature: feature,
                description: "Personalized suggestions based on your style",
                capabilities: [
                    "Learn your preferences",
                    "Track your progress",
                    "Provide personalized suggestions",
                    "Identify improvement areas"
                ],
                examples: [
                    "What's my writing style?",
                    "Show my progress",
                    "Give me personalized chord suggestions"
                ]
            )
        }
    }

    /// Enable/disable specific features
    func toggleFeature(_ feature: AssistantFeature) {
        if activeFeatures.contains(feature) {
            activeFeatures.remove(feature)
        } else {
            activeFeatures.insert(feature)
        }
    }

    /// Get overall assistant status
    func getAssistantStatus() -> AssistantStatus {
        let enabledFeatures = activeFeatures.count
        let totalFeatures = AssistantFeature.allCases.count

        return AssistantStatus(
            isEnabled: isEnabled,
            enabledFeatures: enabledFeatures,
            totalFeatures: totalFeatures,
            mode: currentMode,
            readyToAssist: isEnabled && enabledFeatures > 0
        )
    }

    // MARK: - Quick Actions

    func performQuickAction(_ action: AssistantAction) {
        // Handle quick actions
        switch action {
        case .addChord(let chord):
            print("Adding chord: \(chord)")

        case .showRhymes:
            print("Showing rhymes")

        case .improveStructure:
            print("Improving structure")

        case .changeStyle:
            print("Changing style")
        }
    }
}

// MARK: - Data Models

enum AssistantMode: String, Codable, CaseIterable {
    case suggest = "Suggest"
    case collaborate = "Collaborate"
    case learn = "Learn"
    case explore = "Explore"
}

enum AssistantFeature: String, Codable, CaseIterable {
    case chordProgression = "Chord Progression"
    case lyrics = "Lyrics"
    case melody = "Melody"
    case structure = "Structure"
    case collaboration = "Collaboration"
    case styleTransfer = "Style Transfer"
    case learning = "Learning"
}

enum AssistantAction {
    case addChord(String)
    case showRhymes
    case improveStructure
    case changeStyle
}

struct SongStarter: Identifiable, Codable {
    let id: UUID = UUID()
    let genre: String
    let key: String
    let tempo: Int
    let mood: String
    let theme: String
    let chordProgression: GeneratedProgression
    let structure: SongStructureTemplate
    let lyricIdeas: [ThemePhrase]
    let melodyHints: [MelodyHint]
    let timestamp: Date
}

struct ContextualAssistance: Codable {
    let suggestions: [String]
    let quickActions: [QuickAction]
    let confidence: Double
}

struct QuickAction: Identifiable, Codable {
    let id: UUID = UUID()
    let title: String
    let icon: String
    let action: String

    init(title: String, icon: String, action: AssistantAction) {
        self.title = title
        self.icon = icon

        // Convert action to string for Codable
        switch action {
        case .addChord(let chord):
            self.action = "addChord:\(chord)"
        case .showRhymes:
            self.action = "showRhymes"
        case .improveStructure:
            self.action = "improveStructure"
        case .changeStyle:
            self.action = "changeStyle"
        }
    }
}

struct CompleteSongAssistance: Identifiable, Codable {
    let id: UUID = UUID()
    let sessionID: UUID
    let chordProgression: GeneratedProgression
    let structure: SongStructureTemplate
    let lyricIdeas: [ThemePhrase]
    let melodyIdeas: [MelodyHint]
    let arrangementIdeas: [ArrangementIdea]
    let estimatedCompletionSteps: Int
}

struct FeatureHelp: Codable {
    let feature: AssistantFeature
    let description: String
    let capabilities: [String]
    let examples: [String]
}

struct AssistantStatus: Codable {
    let isEnabled: Bool
    let enabledFeatures: Int
    let totalFeatures: Int
    let mode: AssistantMode
    let readyToAssist: Bool
}
