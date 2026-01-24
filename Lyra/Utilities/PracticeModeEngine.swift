//
//  PracticeModeEngine.swift
//  Lyra
//
//  Engine for specialized practice modes (slow-mo, loop, hide chords, quiz)
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for managing specialized practice modes
@MainActor
class PracticeModeEngine {

    // MARK: - Properties

    private var activeConfigurations: [UUID: PracticeModeConfiguration] = [:]

    // MARK: - Slow-Mo Mode

    /// Start slow-mo practice mode
    func startSlowMoMode(
        sessionID: UUID,
        tempoMultiplier: Float
    ) -> PracticeModeConfiguration {
        let config = PracticeModeConfiguration(
            mode: .slowMo,
            tempoMultiplier: max(0.25, min(tempoMultiplier, 1.0))
        )

        activeConfigurations[sessionID] = config
        return config
    }

    /// Adjust slow-mo tempo
    func adjustSlowMoTempo(sessionID: UUID, newMultiplier: Float) {
        guard var config = activeConfigurations[sessionID],
              config.mode == .slowMo else { return }

        config.tempoMultiplier = max(0.25, min(newMultiplier, 1.0))
        activeConfigurations[sessionID] = config
    }

    // MARK: - Loop Mode

    /// Start section loop mode
    func startLoopMode(
        sessionID: UUID,
        sectionName: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        repetitions: Int
    ) -> PracticeModeConfiguration {
        let loopSection = PracticeModeConfiguration.LoopSection(
            sectionName: sectionName,
            startTime: startTime,
            endTime: endTime,
            repetitions: repetitions,
            currentRepetition: 0
        )

        let config = PracticeModeConfiguration(
            mode: .loop,
            loopSection: loopSection
        )

        activeConfigurations[sessionID] = config
        return config
    }

    /// Record completion of a loop repetition
    func recordLoopRepetition(sessionID: UUID) -> Bool {
        guard var config = activeConfigurations[sessionID],
              var loopSection = config.loopSection else { return false }

        loopSection.currentRepetition += 1
        config.loopSection = loopSection
        activeConfigurations[sessionID] = config

        // Return true if all repetitions completed
        return loopSection.currentRepetition >= loopSection.repetitions
    }

    /// Get current loop progress
    func getLoopProgress(sessionID: UUID) -> (current: Int, total: Int)? {
        guard let config = activeConfigurations[sessionID],
              let loopSection = config.loopSection else { return nil }

        return (loopSection.currentRepetition, loopSection.repetitions)
    }

    // MARK: - Hide Chords Mode

    /// Start hide chords mode
    func startHideChordsMode(
        sessionID: UUID,
        revealAfterSeconds: TimeInterval,
        progressiveHiding: Bool = false,
        hidePercentage: Float = 1.0
    ) -> PracticeModeConfiguration {
        let settings = PracticeModeConfiguration.HideChordsSettings(
            revealAfterSeconds: revealAfterSeconds,
            progressiveHiding: progressiveHiding,
            hidePercentage: min(max(hidePercentage, 0.0), 1.0)
        )

        let config = PracticeModeConfiguration(
            mode: .hideChords,
            hideChordSettings: settings
        )

        activeConfigurations[sessionID] = config
        return config
    }

    /// Determine which chords should be hidden
    func getChordsToHide(
        sessionID: UUID,
        totalChords: Int,
        currentTime: TimeInterval
    ) -> [Int] {
        guard let config = activeConfigurations[sessionID],
              let settings = config.hideChordSettings else { return [] }

        let hideCount = Int(Float(totalChords) * settings.hidePercentage)

        if settings.progressiveHiding {
            // Gradually hide more chords over time
            let progressMultiplier = min(currentTime / settings.revealAfterSeconds, 1.0)
            let adjustedHideCount = Int(Float(hideCount) * Float(progressMultiplier))

            // Hide chords starting from the middle
            let startIndex = (totalChords - adjustedHideCount) / 2
            return Array(startIndex..<(startIndex + adjustedHideCount))
        } else {
            // Hide random chords
            return Array(0..<totalChords).shuffled().prefix(hideCount).sorted()
        }
    }

    // MARK: - Chord Quiz Mode

    /// Start chord quiz mode
    func startChordQuiz(
        sessionID: UUID,
        difficulty: SkillLevel,
        questionCount: Int,
        timeLimit: TimeInterval? = nil,
        showHints: Bool = false
    ) -> PracticeModeConfiguration {
        let chordPool = getChordPoolForDifficulty(difficulty: difficulty)

        let settings = PracticeModeConfiguration.QuizSettings(
            difficulty: difficulty,
            questionCount: questionCount,
            timeLimit: timeLimit,
            showHints: showHints,
            chordPool: chordPool
        )

        let config = PracticeModeConfiguration(
            mode: .quiz,
            quizSettings: settings
        )

        activeConfigurations[sessionID] = config
        return config
    }

    /// Generate quiz questions
    func generateQuizQuestions(sessionID: UUID) -> [ChordQuizQuestion] {
        guard let config = activeConfigurations[sessionID],
              let settings = config.quizSettings else { return [] }

        let chordPool = settings.chordPool ?? getChordPoolForDifficulty(difficulty: settings.difficulty)

        var questions: [ChordQuizQuestion] = []

        for i in 0..<settings.questionCount {
            let correctChord = chordPool.randomElement() ?? "C"

            // Generate wrong answers
            var options = [correctChord]
            while options.count < 4 {
                if let wrongChord = chordPool.randomElement(), !options.contains(wrongChord) {
                    options.append(wrongChord)
                }
            }

            options.shuffle()

            let question = ChordQuizQuestion(
                questionNumber: i + 1,
                chord: correctChord,
                options: options,
                hint: settings.showHints ? getChordHint(chord: correctChord) : nil,
                timeLimit: settings.timeLimit
            )

            questions.append(question)
        }

        return questions
    }

    /// Get chord pool based on difficulty level
    private func getChordPoolForDifficulty(difficulty: SkillLevel) -> [String] {
        switch difficulty {
        case .beginner:
            return ["C", "G", "D", "Em", "Am", "F"]

        case .earlyIntermediate:
            return ["C", "G", "D", "Em", "Am", "F", "A", "E", "Dm", "C7", "G7", "D7"]

        case .intermediate:
            return ["C", "G", "D", "Em", "Am", "F", "A", "E", "Dm", "Bm", "F#m",
                    "C7", "G7", "D7", "A7", "E7", "B7", "Cmaj7", "Gmaj7", "Dmaj7"]

        case .advanced:
            return ["C", "G", "D", "Em", "Am", "F", "A", "E", "Dm", "Bm", "F#m", "Gm",
                    "C7", "G7", "D7", "A7", "E7", "B7", "F7",
                    "Cmaj7", "Gmaj7", "Dmaj7", "Amaj7", "Emaj7",
                    "Cm7", "Gm7", "Dm7", "Am7", "Em7",
                    "C9", "G9", "D9", "A9"]

        case .expert:
            return ["C", "G", "D", "Em", "Am", "F", "A", "E", "Dm", "Bm", "F#m", "Gm",
                    "C7", "G7", "D7", "A7", "E7", "B7", "F7",
                    "Cmaj7", "Gmaj7", "Dmaj7", "Amaj7", "Emaj7",
                    "Cm7", "Gm7", "Dm7", "Am7", "Em7",
                    "C9", "G9", "D9", "A9", "E9",
                    "C11", "G11", "D11", "A11",
                    "C13", "G13", "D13",
                    "Cdim", "Gdim", "Ddim",
                    "Caug", "Gaug", "Daug"]
        }
    }

    /// Get hint for a chord
    private func getChordHint(chord: String) -> String {
        // Remove quality indicators to get root note
        let root = chord.prefix(while: { $0.isLetter || $0 == "#" || $0 == "b" })

        if chord.contains("maj7") {
            return "Major 7th chord with root \(root)"
        } else if chord.contains("m7") {
            return "Minor 7th chord with root \(root)"
        } else if chord.contains("7") {
            return "Dominant 7th chord with root \(root)"
        } else if chord.contains("9") {
            return "9th chord with root \(root)"
        } else if chord.contains("11") {
            return "11th chord with root \(root)"
        } else if chord.contains("13") {
            return "13th chord with root \(root)"
        } else if chord.contains("dim") {
            return "Diminished chord with root \(root)"
        } else if chord.contains("aug") {
            return "Augmented chord with root \(root)"
        } else if chord.contains("m") {
            return "Minor chord with root \(root)"
        } else {
            return "Major chord with root \(root)"
        }
    }

    // MARK: - Progressive Difficulty Mode

    /// Start progressive difficulty mode
    func startProgressiveMode(
        sessionID: UUID,
        initialTempo: Float,
        targetTempo: Float,
        steps: Int
    ) -> PracticeModeConfiguration {
        let config = PracticeModeConfiguration(
            mode: .progressive,
            tempoMultiplier: initialTempo
        )

        activeConfigurations[sessionID] = config
        return config
    }

    /// Advance to next difficulty step
    func advanceProgressiveDifficulty(
        sessionID: UUID,
        initialTempo: Float,
        targetTempo: Float,
        currentStep: Int,
        totalSteps: Int
    ) -> Float {
        let progress = Float(currentStep) / Float(totalSteps)
        let newTempo = initialTempo + (targetTempo - initialTempo) * progress

        if var config = activeConfigurations[sessionID] {
            config.tempoMultiplier = newTempo
            activeConfigurations[sessionID] = config
        }

        return newTempo
    }

    // MARK: - Configuration Management

    /// Get active configuration for a session
    func getConfiguration(sessionID: UUID) -> PracticeModeConfiguration? {
        return activeConfigurations[sessionID]
    }

    /// End practice mode
    func endMode(sessionID: UUID) {
        activeConfigurations.removeValue(forKey: sessionID)
    }

    /// Update configuration
    func updateConfiguration(sessionID: UUID, configuration: PracticeModeConfiguration) {
        activeConfigurations[sessionID] = configuration
    }
}

// MARK: - Supporting Types

/// Chord quiz question
struct ChordQuizQuestion: Identifiable {
    var id = UUID()
    var questionNumber: Int
    var chord: String
    var options: [String]
    var hint: String?
    var timeLimit: TimeInterval?
    var isAnswered: Bool = false
    var selectedAnswer: String?

    var isCorrect: Bool {
        return selectedAnswer == chord
    }
}

/// Quiz result summary
struct QuizResultSummary {
    var totalQuestions: Int
    var correctAnswers: Int
    var wrongAnswers: Int
    var timeSpent: TimeInterval
    var averageTimePerQuestion: TimeInterval
    var score: Float

    var percentage: Float {
        guard totalQuestions > 0 else { return 0 }
        return Float(correctAnswers) / Float(totalQuestions) * 100.0
    }

    var grade: String {
        switch percentage {
        case 90...100:
            return "A"
        case 80..<90:
            return "B"
        case 70..<80:
            return "C"
        case 60..<70:
            return "D"
        default:
            return "F"
        }
    }
}
