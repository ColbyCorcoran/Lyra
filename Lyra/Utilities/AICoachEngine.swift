//
//  AICoachEngine.swift
//  Lyra
//
//  Engine for AI-powered coaching, tips, and guidance
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for providing AI-powered coaching and guidance
@MainActor
class AICoachEngine {

    // MARK: - Properties

    private let modelContext: ModelContext
    private var messageHistory: [CoachMessage] = []

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Daily Tips

    /// Get daily practice tip
    func getDailyTip() -> CoachMessage {
        let tips = [
            "Start each session with a warm-up of simple chord progressions.",
            "Practice chord transitions slowly at first - speed will come with muscle memory.",
            "Use a metronome to improve your rhythm and timing consistency.",
            "Take short breaks every 20 minutes to prevent hand fatigue.",
            "Focus on one challenging section at a time rather than running through the whole song.",
            "Record yourself playing to identify areas that need improvement.",
            "Practice the same chord progression in different keys to improve versatility.",
            "Keep your fingernails trimmed short for better fretting.",
            "Maintain a relaxed grip - tension slows you down and causes fatigue.",
            "Listen to the original song while practicing to internalize the rhythm.",
            "Practice difficult chord changes in isolation before putting them in context.",
            "Use visualization - imagine playing the song correctly before you start.",
            "Set specific, achievable goals for each practice session.",
            "Consistency is key - short daily sessions beat long occasional ones.",
            "Don't rush - quality practice is better than quantity."
        ]

        let randomTip = tips.randomElement() ?? tips[0]

        return CoachMessage(
            type: .tip,
            message: randomTip,
            actionable: true,
            timestamp: Date(),
            priority: .medium
        )
    }

    // MARK: - Performance Feedback

    /// Generate performance-based feedback
    func generateFeedback(session: PracticeSession, skillMetrics: SkillMetrics) -> CoachMessage {
        var messages: [String] = []

        // Analyze chord change speed
        if skillMetrics.chordChangeSpeed < 10 {
            messages.append("Your chord changes are developing. Try practicing transitions slowly, focusing on accuracy before speed.")
        } else if skillMetrics.chordChangeSpeed < 15 {
            messages.append("Good progress on chord changes! Keep practicing to build muscle memory.")
        } else if skillMetrics.chordChangeSpeed >= 20 {
            messages.append("Excellent chord change speed! You're developing solid technique.")
        }

        // Analyze rhythm accuracy
        if skillMetrics.rhythmAccuracy < 0.7 {
            messages.append("Work on your timing with a metronome. Start slow and gradually increase speed.")
        } else if skillMetrics.rhythmAccuracy >= 0.85 {
            messages.append("Great rhythm accuracy! Your timing is really improving.")
        }

        // Analyze memorization
        if skillMetrics.memorizationLevel >= 0.8 {
            messages.append("Impressive memory recall! You're really internalizing this song.")
        }

        // Analyze completion rate
        if session.completionRate >= 0.9 {
            messages.append("Fantastic completion rate! You're showing great focus and endurance.")
        } else if session.completionRate < 0.5 {
            messages.append("Try breaking the song into smaller sections and mastering each one individually.")
        }

        // Analyze difficulties
        if session.difficulties.count > 5 {
            messages.append("You encountered several challenges today - that means you're pushing yourself. Keep at it!")
        }

        let finalMessage = messages.isEmpty ? "Keep up the good practice!" : messages.joined(separator: " ")

        return CoachMessage(
            type: .feedback,
            message: finalMessage,
            context: "Session performance analysis",
            actionable: true,
            timestamp: Date(),
            relatedSongID: session.songID,
            priority: .high
        )
    }

    // MARK: - Technique Suggestions

    /// Get technique suggestions for specific difficulties
    func suggestTechnique(difficulty: PracticeDifficulty.DifficultyType, chord: String? = nil) -> CoachMessage {
        let (message, context) = getTechniqueAdvice(for: difficulty, chord: chord)

        return CoachMessage(
            type: .technique,
            message: message,
            context: context,
            actionable: true,
            timestamp: Date(),
            priority: .high
        )
    }

    /// Get technique advice for specific difficulty type
    private func getTechniqueAdvice(
        for difficulty: PracticeDifficulty.DifficultyType,
        chord: String?
    ) -> (message: String, context: String) {
        switch difficulty {
        case .chordTransition:
            return (
                "For smoother chord transitions, keep your fingers close to the strings between changes. Practice the transition in isolation, going back and forth between the two chords slowly.",
                "Chord Transition Tips"
            )

        case .barreChord:
            if let chord = chord {
                return (
                    "For the \(chord) barre chord, ensure your index finger is straight and positioned close to the fret wire (not on top of it). Apply pressure with the side of your finger, not the pad. It takes time to build strength - practice for short periods and gradually increase.",
                    "Barre Chord Technique"
                )
            } else {
                return (
                    "For barre chords, position your index finger close to the fret wire and use the side of your finger. Build strength gradually with short practice sessions.",
                    "Barre Chord Technique"
                )
            }

        case .strummingPattern:
            return (
                "Break the strumming pattern into smaller parts and practice each part slowly. Use a metronome and focus on the down-up motion. Start with all downstrokes, then add upstrokes gradually.",
                "Strumming Pattern Tips"
            )

        case .fingerPicking:
            return (
                "For fingerpicking, assign each finger to a specific string (thumb on bass strings, index/middle/ring on treble strings). Practice the pattern very slowly, focusing on clean, even notes.",
                "Finger Picking Technique"
            )

        case .rhythmTiming:
            return (
                "Use a metronome and start at a slower tempo than feels comfortable. Focus on landing your chord changes exactly on the beat. Gradually increase speed only when you can play accurately.",
                "Rhythm and Timing Tips"
            )

        case .handPosition:
            return (
                "Check that your thumb is positioned behind the neck (not over the top). Your fretting hand should form a gentle 'C' shape. Keep your wrist straight and fingers arched.",
                "Hand Position Guidelines"
            )

        case .tempo:
            return (
                "Don't rush! Use a metronome and practice at 50-75% of the target tempo first. Focus on accuracy and clean chord changes. Speed will come naturally with consistent practice.",
                "Tempo Control Tips"
            )

        case .memory:
            return (
                "Practice in small sections and visualize the chord changes. Try playing without looking at the chart, then check your accuracy. Repeat sections multiple times to build muscle memory.",
                "Memory and Recall Tips"
            )

        case .technique:
            return (
                "Focus on clean, clear notes. Make sure each string rings out without buzzing. Position your fingers close to the fret wire and apply firm, consistent pressure.",
                "General Technique Tips"
            )

        case .other:
            return (
                "Break down the challenge into smaller, manageable parts. Practice slowly and deliberately, then gradually increase speed as you build confidence.",
                "General Practice Tips"
            )
        }
    }

    // MARK: - Encouragement

    /// Generate encouraging message based on progress
    func generateEncouragement(
        currentSkillLevel: SkillLevel,
        improvementRate: Float,
        practiceStreak: Int,
        sessionCount: Int
    ) -> CoachMessage {
        var messages: [String] = []

        // Streak-based encouragement
        if practiceStreak >= 30 {
            messages.append("🔥 Incredible 30+ day streak! Your dedication is truly inspiring.")
        } else if practiceStreak >= 14 {
            messages.append("🌟 Two weeks of consistent practice! You're building amazing habits.")
        } else if practiceStreak >= 7 {
            messages.append("✨ A full week streak! Consistency is the key to mastery.")
        } else if practiceStreak >= 3 {
            messages.append("👏 Great job maintaining your practice streak!")
        }

        // Improvement-based encouragement
        if improvementRate > 20 {
            messages.append("Your skills are improving rapidly - over 20% growth!")
        } else if improvementRate > 10 {
            messages.append("Solid progress! You're steadily improving.")
        }

        // Session count milestones
        if sessionCount >= 100 {
            messages.append("100+ practice sessions! You're truly committed to your growth.")
        } else if sessionCount >= 50 {
            messages.append("50 sessions completed! You're well on your way to mastery.")
        } else if sessionCount >= 25 {
            messages.append("Quarter century of practice sessions! Keep the momentum going.")
        }

        // Skill level encouragement
        switch currentSkillLevel {
        case .beginner:
            messages.append("Every expert was once a beginner. You're on the right path!")
        case .earlyIntermediate:
            messages.append("You've progressed beyond beginner - your hard work is paying off!")
        case .intermediate:
            messages.append("You're at an intermediate level - this is where real musicianship develops!")
        case .advanced:
            messages.append("Advanced skills! You're approaching professional-level playing.")
        case .expert:
            messages.append("Expert level achieved! Continue refining your craft.")
        }

        let finalMessage = messages.isEmpty ? "Keep practicing and stay motivated!" : messages.joined(separator: " ")

        return CoachMessage(
            type: .encouragement,
            message: finalMessage,
            actionable: false,
            timestamp: Date(),
            priority: .medium
        )
    }

    // MARK: - Theory Lessons

    /// Get music theory lesson
    func getTheoryLesson(topic: TheoryTopic, skillLevel: SkillLevel) -> CoachMessage {
        let (message, context) = getTheoryContent(topic: topic, level: skillLevel)

        return CoachMessage(
            type: .theory,
            message: message,
            context: context,
            actionable: false,
            timestamp: Date(),
            priority: .low
        )
    }

    /// Get theory content based on topic and skill level
    private func getTheoryContent(topic: TheoryTopic, level: SkillLevel) -> (message: String, context: String) {
        switch topic {
        case .chordConstruction:
            switch level {
            case .beginner:
                return (
                    "A chord is three or more notes played together. The most basic chords are triads, which have three notes: root, third, and fifth. For example, a C major chord contains C (root), E (third), and G (fifth).",
                    "Chord Construction Basics"
                )
            case .intermediate:
                return (
                    "Chords are built by stacking thirds. Major chords have a major third (4 semitones) then a minor third (3 semitones). Minor chords reverse this: minor third then major third. Seventh chords add another third on top.",
                    "Advanced Chord Construction"
                )
            default:
                return (
                    "Extended chords (9th, 11th, 13th) continue the pattern of stacked thirds. These add color and tension. Voice leading is key - consider how each note moves to the next chord.",
                    "Extended Chords and Voice Leading"
                )
            }

        case .scales:
            return (
                "The major scale follows the pattern: whole, whole, half, whole, whole, whole, half. This pattern of intervals gives the major scale its characteristic sound. All other scales are variations of this pattern.",
                "Scale Theory"
            )

        case .keys:
            return (
                "A key is a group of notes that sound good together, based on a scale. Songs in the key of C major use notes from the C major scale. The key signature tells you which notes are sharp or flat throughout the song.",
                "Understanding Keys"
            )

        case .progressions:
            return (
                "Common chord progressions follow patterns like I-IV-V-I (in C: C-F-G-C) or I-V-vi-IV (in C: C-G-Am-F). These progressions sound natural because they follow the relationships between chords in a key.",
                "Chord Progressions"
            )

        case .rhythm:
            return (
                "Rhythm is the pattern of strong and weak beats. The time signature tells you how many beats per measure (top number) and what note gets one beat (bottom number). 4/4 time has 4 quarter-note beats per measure.",
                "Rhythm Fundamentals"
            )

        case .harmony:
            return (
                "Harmony is the combination of different notes played together. Consonant intervals (3rds, 6ths) sound pleasant together. Dissonant intervals (2nds, 7ths) create tension that resolves to consonance.",
                "Harmony Basics"
            )
        }
    }

    // MARK: - Milestone Celebrations

    /// Generate milestone celebration message
    func celebrateMilestone(milestone: ProgressMilestone) -> CoachMessage {
        let message = generateMilestoneMessage(for: milestone)

        return CoachMessage(
            type: .milestone,
            message: message,
            actionable: false,
            timestamp: Date(),
            relatedSongID: milestone.songID,
            priority: .urgent
        )
    }

    /// Generate specific milestone message
    private func generateMilestoneMessage(for milestone: ProgressMilestone) -> String {
        switch milestone.type {
        case .firstSongMastered:
            return "🎉 Congratulations! You've mastered your first song! This is a huge achievement and the beginning of your musical journey."

        case .streakAchieved:
            let days = Int(milestone.value)
            return "🔥 Amazing! You've achieved a \(days)-day practice streak! Consistency like this leads to real progress."

        case .skillLevelUp:
            return "⭐ Level up! You've advanced to the next skill level. Your dedication is paying off!"

        case .speedImproved:
            return "⚡ Speed milestone! Your chord changes are getting faster. Keep building that muscle memory!"

        case .songCollectionComplete:
            return "🏆 Collection completed! You've mastered an entire set of songs. That's dedication!"

        case .chordMastered:
            return "✨ Chord mastered! You've conquered a challenging chord shape. Well done!"

        case .perfectSession:
            return "💯 Perfect session! You completed this practice with no difficulties logged. Excellent!"

        case .practiceGoalMet:
            return "🎯 Goal achieved! You met your practice time goal. Great discipline!"
        }
    }

    // MARK: - Smart Recommendations

    /// Get personalized practice suggestion
    func getSmartSuggestion(
        weaknesses: [PracticeRecommendation.FocusArea],
        timeAvailable: TimeInterval,
        energy: EnergyLevel
    ) -> CoachMessage {
        let suggestion = generateSmartSuggestion(
            weaknesses: weaknesses,
            time: timeAvailable,
            energy: energy
        )

        return CoachMessage(
            type: .tip,
            message: suggestion,
            actionable: true,
            timestamp: Date(),
            priority: .high
        )
    }

    /// Generate context-aware suggestion
    private func generateSmartSuggestion(
        weaknesses: [PracticeRecommendation.FocusArea],
        time: TimeInterval,
        energy: EnergyLevel
    ) -> String {
        if time < 10 * 60 {
            // Short session
            return "Quick 10-minute session: Focus on one specific chord transition or technique. Quality over quantity!"
        } else if time < 20 * 60 {
            // Medium session
            if let weakness = weaknesses.first {
                return "20-minute focused session: Spend this time working on \(weakness.rawValue.lowercased()). Break it into 5-minute segments with short breaks."
            }
        } else {
            // Full session
            if energy == .low {
                return "Full session with low energy: Start with familiar songs to warm up, then tackle one new challenge. End with something fun to keep motivation high."
            } else {
                return "Full practice session: Warm up (5 min), work on weaknesses (15 min), practice a challenging song (15 min), review mastered songs (10 min), cool down (5 min)."
            }
        }

        return "Make the most of your practice time - stay focused and practice with intention!"
    }
}

// MARK: - Supporting Types

/// Theory topic categories
enum TheoryTopic {
    case chordConstruction
    case scales
    case keys
    case progressions
    case rhythm
    case harmony
}

/// Energy level for practice
enum EnergyLevel {
    case low
    case medium
    case high
}
