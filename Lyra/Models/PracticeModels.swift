//
//  PracticeModels.swift
//  Lyra
//
//  Data models for AI-powered practice intelligence system
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData

// MARK: - Practice Session

/// A complete record of a practice session
@Model
class PracticeSession {
    @Attribute(.unique) var id: UUID
    var songID: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var completionRate: Float
    var difficulties: [PracticeDifficulty]
    var skillMetrics: SkillMetrics?
    var practiceMode: PracticeMode
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        songID: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        completionRate: Float = 0,
        difficulties: [PracticeDifficulty] = [],
        skillMetrics: SkillMetrics? = nil,
        practiceMode: PracticeMode = .normal,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.songID = songID
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.completionRate = completionRate
        self.difficulties = difficulties
        self.skillMetrics = skillMetrics
        self.practiceMode = practiceMode
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Skill Metrics

/// Performance metrics for a practice session
struct SkillMetrics: Codable {
    var chordChangeSpeed: Float      // Changes per minute
    var rhythmAccuracy: Float         // 0.0-1.0
    var memorizationLevel: Float      // 0.0-1.0
    var overallSkillLevel: SkillLevel
    var problemSections: [ProblemSection]
    var timestamp: Date

    init(
        chordChangeSpeed: Float = 0,
        rhythmAccuracy: Float = 0,
        memorizationLevel: Float = 0,
        overallSkillLevel: SkillLevel = .beginner,
        problemSections: [ProblemSection] = [],
        timestamp: Date = Date()
    ) {
        self.chordChangeSpeed = chordChangeSpeed
        self.rhythmAccuracy = rhythmAccuracy
        self.memorizationLevel = memorizationLevel
        self.overallSkillLevel = overallSkillLevel
        self.problemSections = problemSections
        self.timestamp = timestamp
    }

    /// Calculate overall skill score (0.0-1.0)
    var overallScore: Float {
        let speedScore = min(chordChangeSpeed / 30.0, 1.0)  // 30 CPM = expert
        return (speedScore + rhythmAccuracy + memorizationLevel) / 3.0
    }
}

// MARK: - Practice Difficulty

/// A specific difficulty encountered during practice
struct PracticeDifficulty: Identifiable, Codable {
    var id: UUID = UUID()
    var type: DifficultyType
    var section: String?
    var chord: String?
    var timestamp: Date
    var severity: Float  // 0.0-1.0
    var notes: String?

    enum DifficultyType: String, Codable, CaseIterable {
        case chordTransition = "Chord Transition"
        case barreChord = "Barre Chord"
        case strummingPattern = "Strumming Pattern"
        case fingerPicking = "Finger Picking"
        case rhythmTiming = "Rhythm/Timing"
        case handPosition = "Hand Position"
        case tempo = "Tempo"
        case memory = "Memory/Recall"
        case technique = "Technique"
        case other = "Other"
    }
}

// MARK: - Problem Section

/// A section of a song with difficulties
struct ProblemSection: Identifiable, Codable {
    var id: UUID = UUID()
    var sectionName: String
    var sectionType: SectionType
    var errorCount: Int
    var lastEncountered: Date
    var severity: Float  // 0.0-1.0

    enum SectionType: String, Codable {
        case verse = "Verse"
        case chorus = "Chorus"
        case bridge = "Bridge"
        case intro = "Intro"
        case outro = "Outro"
        case solo = "Solo"
        case prechorus = "Pre-Chorus"
        case other = "Other"
    }
}

// MARK: - Skill Level

/// Player skill level enumeration
enum SkillLevel: String, Codable, CaseIterable, Comparable {
    case beginner = "Beginner"
    case earlyIntermediate = "Early Intermediate"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"

    var description: String {
        switch self {
        case .beginner:
            return "Just starting with basic chords"
        case .earlyIntermediate:
            return "Comfortable with basic chords, learning transitions"
        case .intermediate:
            return "Multiple songs mastered, working on complex progressions"
        case .advanced:
            return "Advanced techniques and extended chords"
        case .expert:
            return "Professional-level proficiency"
        }
    }

    var numericValue: Int {
        switch self {
        case .beginner: return 0
        case .earlyIntermediate: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }

    static func < (lhs: SkillLevel, rhs: SkillLevel) -> Bool {
        lhs.numericValue < rhs.numericValue
    }
}

// MARK: - Practice Mode

/// Available practice modes
enum PracticeMode: String, Codable, CaseIterable {
    case normal = "Normal"
    case slowMo = "Slow Motion"
    case loop = "Loop Section"
    case hideChords = "Hide Chords"
    case quiz = "Chord Quiz"
    case progressive = "Progressive Difficulty"

    var icon: String {
        switch self {
        case .normal: return "music.note"
        case .slowMo: return "tortoise.fill"
        case .loop: return "repeat"
        case .hideChords: return "eye.slash.fill"
        case .quiz: return "questionmark.circle.fill"
        case .progressive: return "chart.line.uptrend.xyaxis"
        }
    }

    var description: String {
        switch self {
        case .normal:
            return "Standard practice mode"
        case .slowMo:
            return "Practice at a slower tempo"
        case .loop:
            return "Repeat difficult sections"
        case .hideChords:
            return "Test your memory"
        case .quiz:
            return "Random chord identification"
        case .progressive:
            return "Gradually increasing difficulty"
        }
    }
}

// MARK: - Practice Recommendation

/// AI-generated practice recommendation
struct PracticeRecommendation: Identifiable, Codable {
    var id: UUID = UUID()
    var songID: UUID
    var songTitle: String
    var reason: RecommendationReason
    var priority: Int  // 1-10, higher = more important
    var estimatedTime: TimeInterval  // in seconds
    var focusAreas: [FocusArea]
    var createdAt: Date
    var isCompleted: Bool = false

    enum RecommendationReason: String, Codable {
        case newSong = "New Song to Learn"
        case needsReview = "Needs Review"
        case skillMatch = "Matches Your Skill Level"
        case weaknessAlignment = "Addresses Weak Areas"
        case nextChallenge = "Next Challenge"
        case consistency = "Maintain Consistency"
        case masteryReinforcement = "Reinforce Mastery"
    }

    enum FocusArea: String, Codable, CaseIterable {
        case chordTransitions = "Chord Transitions"
        case strummingPatterns = "Strumming Patterns"
        case rhythmAccuracy = "Rhythm Accuracy"
        case memorization = "Memorization"
        case barreChords = "Barre Chords"
        case fingerPicking = "Finger Picking"
        case tempo = "Tempo Control"
        case overall = "Overall Proficiency"
    }
}

// MARK: - Learning Path

/// Adaptive learning progression path
struct LearningPath: Codable {
    var currentLevel: SkillLevel
    var masteredSongs: [UUID]
    var currentChallengeSongs: [UUID]
    var nextChallengeSongs: [UUID]
    var progressPercentage: Float  // 0.0-1.0
    var goals: [LearningGoal]
    var lastUpdated: Date

    enum LearningGoal: String, Codable, CaseIterable {
        case improveChordChanges = "Improve Chord Changes"
        case learnNewSongs = "Learn New Songs"
        case masterBarreChords = "Master Barre Chords"
        case increaseSpeed = "Increase Speed"
        case improveRhythm = "Improve Rhythm"
        case expandRepertoire = "Expand Repertoire"
        case learnFingerPicking = "Learn Finger Picking"
        case masterTheory = "Master Music Theory"
    }
}

// MARK: - Progress Milestone

/// Achievement or milestone reached
@Model
class ProgressMilestone {
    @Attribute(.unique) var id: UUID
    var type: MilestoneType
    var achievedDate: Date
    var songID: UUID?
    var metric: String
    var value: Float
    var description: String
    var isNotified: Bool = false

    init(
        id: UUID = UUID(),
        type: MilestoneType,
        achievedDate: Date = Date(),
        songID: UUID? = nil,
        metric: String,
        value: Float,
        description: String,
        isNotified: Bool = false
    ) {
        self.id = id
        self.type = type
        self.achievedDate = achievedDate
        self.songID = songID
        self.metric = metric
        self.value = value
        self.description = description
        self.isNotified = isNotified
    }

    enum MilestoneType: String, Codable {
        case firstSongMastered = "First Song Mastered"
        case streakAchieved = "Practice Streak"
        case skillLevelUp = "Skill Level Increased"
        case speedImproved = "Speed Improved"
        case songCollectionComplete = "Collection Mastered"
        case chordMastered = "Chord Mastered"
        case perfectSession = "Perfect Session"
        case practiceGoalMet = "Practice Goal Met"
    }
}

// MARK: - Coach Message

/// AI coach message or guidance
struct CoachMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var type: CoachMessageType
    var message: String
    var context: String?
    var actionable: Bool
    var timestamp: Date
    var relatedSongID: UUID?
    var priority: MessagePriority

    enum CoachMessageType: String, Codable {
        case tip = "Practice Tip"
        case encouragement = "Encouragement"
        case technique = "Technique Suggestion"
        case theory = "Music Theory"
        case feedback = "Performance Feedback"
        case milestone = "Milestone Celebration"
        case reminder = "Practice Reminder"
        case challenge = "Challenge"
    }

    enum MessagePriority: String, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
    }
}

// MARK: - Practice Analytics

/// Analytics data for practice progress
struct PracticeAnalytics: Codable {
    var totalSessions: Int
    var totalPracticeTime: TimeInterval
    var averageSessionDuration: TimeInterval
    var songsPracticed: Int
    var songsMastered: Int
    var currentStreak: Int
    var longestStreak: Int
    var averageSkillScore: Float
    var improvementRate: Float  // Percentage improvement
    var weakestAreas: [PracticeRecommendation.FocusArea]
    var strongestAreas: [PracticeRecommendation.FocusArea]
    var lastPracticeDate: Date?
    var practiceGoal: TimeInterval?  // Daily goal in seconds

    /// Check if practice goal is met today
    func isGoalMetToday(todaysPracticeTime: TimeInterval) -> Bool {
        guard let goal = practiceGoal else { return false }
        return todaysPracticeTime >= goal
    }

    /// Calculate consistency score (0.0-1.0)
    func calculateConsistencyScore(daysActive: Int, totalDays: Int) -> Float {
        guard totalDays > 0 else { return 0 }
        return Float(daysActive) / Float(totalDays)
    }
}

// MARK: - Practice Schedule

/// Generated practice schedule
struct PracticeSchedule: Codable {
    var date: Date
    var recommendations: [PracticeRecommendation]
    var totalEstimatedTime: TimeInterval
    var focusOfTheDay: String
    var balanceScore: Float  // 0.0-1.0, how well balanced the schedule is

    /// Check if schedule is realistic for available time
    func isRealistic(availableTime: TimeInterval) -> Bool {
        return totalEstimatedTime <= availableTime * 1.2  // Allow 20% buffer
    }
}

// MARK: - Difficulty Assessment

/// Song difficulty assessment
struct DifficultyAssessment: Codable {
    var songID: UUID
    var overallDifficulty: DifficultyLevel
    var factors: DifficultyFactors
    var estimatedPracticeTime: TimeInterval
    var prerequisiteSkills: [String]
    var assessedAt: Date

    enum DifficultyLevel: String, Codable, CaseIterable {
        case veryEasy = "Very Easy"
        case easy = "Easy"
        case moderate = "Moderate"
        case challenging = "Challenging"
        case difficult = "Difficult"
        case veryDifficult = "Very Difficult"

        var numericValue: Float {
            switch self {
            case .veryEasy: return 1.0
            case .easy: return 2.0
            case .moderate: return 3.0
            case .challenging: return 4.0
            case .difficult: return 5.0
            case .veryDifficult: return 6.0
            }
        }
    }

    struct DifficultyFactors: Codable {
        var uniqueChords: Int
        var chordComplexity: Float  // 0.0-1.0
        var tempo: Int  // BPM
        var changeFrequency: Float  // Changes per measure
        var rhythmComplexity: Float  // 0.0-1.0
        var songLength: TimeInterval
        var hasBarreChords: Bool
        var hasExtendedChords: Bool
        var requiresFingerPicking: Bool
    }
}

// MARK: - Practice Mode Configuration

/// Configuration for specialized practice modes
struct PracticeModeConfiguration: Codable {
    var mode: PracticeMode
    var tempoMultiplier: Float?  // For slow-mo mode (0.25-1.0)
    var loopSection: LoopSection?  // For loop mode
    var hideChordSettings: HideChordsSettings?  // For hide chords mode
    var quizSettings: QuizSettings?  // For quiz mode

    struct LoopSection: Codable {
        var sectionName: String
        var startTime: TimeInterval
        var endTime: TimeInterval
        var repetitions: Int
        var currentRepetition: Int = 0
    }

    struct HideChordsSettings: Codable {
        var revealAfterSeconds: TimeInterval
        var progressiveHiding: Bool  // Hide more chords over time
        var hidePercentage: Float  // 0.0-1.0
    }

    struct QuizSettings: Codable {
        var difficulty: SkillLevel
        var questionCount: Int
        var timeLimit: TimeInterval?
        var showHints: Bool
        var chordPool: [String]?  // Specific chords to quiz on
    }
}

// MARK: - Practice Streak

/// Practice consistency tracking
struct PracticeStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastPracticeDate: Date?
    var streakStartDate: Date?
    var totalDaysPracticed: Int
    var missedDays: Int

    /// Check if streak is still active
    func isActive(today: Date = Date()) -> Bool {
        guard let lastDate = lastPracticeDate else { return false }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
        return daysSince <= 1
    }

    /// Update streak with new practice
    mutating func recordPractice(date: Date = Date()) {
        let calendar = Calendar.current

        if let lastDate = lastPracticeDate {
            let daysSince = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0

            if daysSince == 1 {
                // Consecutive day
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else if daysSince > 1 {
                // Streak broken
                missedDays += (daysSince - 1)
                currentStreak = 1
                streakStartDate = date
            }
            // Same day practice doesn't affect streak
        } else {
            // First practice
            currentStreak = 1
            longestStreak = 1
            streakStartDate = date
        }

        lastPracticeDate = date
        totalDaysPracticed += 1
    }
}

// MARK: - Session Summary

/// Summary of a completed practice session
struct SessionSummary: Identifiable, Codable {
    var id: UUID
    var sessionID: UUID
    var songTitle: String
    var duration: TimeInterval
    var completionRate: Float
    var skillScore: Float
    var improvementFromLast: Float?
    var difficultiesEncountered: Int
    var highlightedAchievements: [String]
    var coachFeedback: String
    var nextSteps: [String]
    var createdAt: Date
}
