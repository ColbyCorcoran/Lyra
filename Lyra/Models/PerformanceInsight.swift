//
//  PerformanceInsight.swift
//  Lyra
//
//  Data models for AI performance insights and analytics
//

import Foundation
import SwiftData

// MARK: - Performance Session

@Model
class PerformanceSession {
    var id: UUID = UUID()
    var setID: UUID?
    var setName: String
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval = 0
    var venue: String?
    var songPerformances: [SongPerformance] = []
    var audienceSize: Int?
    var audienceEngagement: Float? // 0.0-1.0
    var energyProfile: EnergyProfile?
    var notes: String?

    init(setID: UUID? = nil, setName: String, startTime: Date, venue: String? = nil) {
        self.setID = setID
        self.setName = setName
        self.startTime = startTime
        self.venue = venue
    }
}

// MARK: - Song Performance

struct SongPerformance: Codable, Identifiable {
    var id: UUID = UUID()
    var songID: UUID
    var songTitle: String
    var orderInSet: Int
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval = 0
    var plannedDuration: TimeInterval?

    // Performance metrics
    var autoscrollUsed: Bool = false
    var autoscrollAccuracy: Float = 1.0 // How well tempo matched
    var pauseCount: Int = 0
    var pauseLocations: [PauseLocation] = []
    var skipSections: [String] = []
    var problemSections: [ProblemSection] = []
    var tempoVariation: Float = 0 // Deviation from planned tempo

    // Audience feedback
    var audienceResponse: AudienceResponse?

    // Performer notes
    var performerDifficulties: [PerformanceDifficulty] = []
    var performerRating: Int? // 1-5 stars
    var notes: String?
}

// MARK: - Pause Location

struct PauseLocation: Codable {
    var timestamp: Date
    var section: String?
    var lineNumber: Int?
    var duration: TimeInterval
    var reason: PauseReason
}

enum PauseReason: String, Codable {
    case memoryLapse = "Memory Lapse"
    case chordDifficulty = "Chord Difficulty"
    case lyricForgotten = "Lyric Forgotten"
    case tempoAdjustment = "Tempo Adjustment"
    case technicalIssue = "Technical Issue"
    case intentionalBreak = "Intentional Break"
    case unknown = "Unknown"
}

// MARK: - Problem Section

struct ProblemSection: Codable, Identifiable {
    var id: UUID = UUID()
    var section: String
    var lineRange: ClosedRange<Int>?
    var chords: [String]
    var difficulty: ProblemDifficulty
    var occurrenceCount: Int = 1
    var lastOccurrence: Date
}

enum ProblemDifficulty: String, Codable {
    case minor = "Minor"
    case moderate = "Moderate"
    case major = "Major"
    case critical = "Critical"
}

// MARK: - Performance Difficulty

struct PerformanceDifficulty: Codable, Identifiable {
    var id: UUID = UUID()
    var type: DifficultyType
    var section: String?
    var chord: String?
    var timestamp: Date
    var severity: Float // 0.0-1.0
    var resolved: Bool = false
}

enum DifficultyType: String, Codable {
    case chordTransition = "Chord Transition"
    case tempo = "Tempo"
    case memory = "Memory"
    case technique = "Technique"
    case equipment = "Equipment"
    case coordination = "Coordination"
    case other = "Other"
}

// MARK: - Audience Response

struct AudienceResponse: Codable {
    var engagementLevel: Float // 0.0-1.0
    var energyMatch: Float // How well song energy matched audience
    var singAlongParticipation: Bool = false
    var applauseLevel: ApplauseLevel?
    var requests: Int = 0 // Number of times requested again
}

enum ApplauseLevel: String, Codable {
    case none = "None"
    case polite = "Polite"
    case enthusiastic = "Enthusiastic"
    case standingOvation = "Standing Ovation"
}

// MARK: - Energy Profile

struct EnergyProfile: Codable {
    var overallEnergy: Float // 0.0-1.0
    var energyProgression: [EnergyPoint] = []
    var fatigueMoments: [FatigueMoment] = []
    var peakEnergy: EnergyPoint?
    var lowestEnergy: EnergyPoint?
}

struct EnergyPoint: Codable {
    var timestamp: Date
    var songIndex: Int
    var energyLevel: Float // 0.0-1.0
    var performerEnergy: Float? // Self-reported
    var audienceEnergy: Float? // Observed
}

struct FatigueMoment: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date
    var songIndex: Int
    var severity: Float // 0.0-1.0
    var indicators: [FatigueIndicator]
}

enum FatigueIndicator: String, Codable {
    case tempoSlowing = "Tempo Slowing"
    case increasedErrors = "Increased Errors"
    case pauseFrequency = "Increased Pauses"
    case energyDrop = "Energy Drop"
    case focusLoss = "Focus Loss"
}

// MARK: - Performance Insight

struct PerformanceInsight: Identifiable, Codable {
    var id: UUID = UUID()
    var type: InsightType
    var category: InsightCategory
    var title: String
    var message: String
    var severity: InsightSeverity
    var actionable: Bool = false
    var action: String?
    var relatedSongID: UUID?
    var relatedSection: String?
    var confidence: Float // 0.0-1.0 (AI confidence)
    var timestamp: Date = Date()
}

enum InsightType: String, Codable {
    // Performance analysis
    case struggleWarning = "Struggle Warning"
    case problemSectionDetected = "Problem Section Detected"
    case autoscrollIssue = "Autoscroll Issue"

    // Predictive insights
    case difficultyPrediction = "Difficulty Prediction"
    case memoryRisk = "Memory Risk"
    case tempoChallenge = "Tempo Challenge"

    // Set optimization
    case keyTransitionIssue = "Key Transition Issue"
    case energyImbalance = "Energy Imbalance"
    case setFlowSuggestion = "Set Flow Suggestion"
    case songOrderRecommendation = "Song Order Recommendation"

    // Timing analysis
    case runningLong = "Running Long"
    case runningShort = "Running Short"
    case pacingIssue = "Pacing Issue"

    // Energy management
    case fatigueWarning = "Fatigue Warning"
    case breakNeeded = "Break Needed"
    case energyBoostOpportunity = "Energy Boost Opportunity"

    // Performance readiness
    case insufficientRehearsalTime = "Insufficient Rehearsal Time"
    case difficultTransition = "Difficult Transition"
    case complexSongUnprepared = "Complex Song Unprepared"

    // Post-performance
    case performanceImprovement = "Performance Improvement"
    case strengthIdentified = "Strength Identified"
    case improvementArea = "Improvement Area"
}

enum InsightCategory: String, Codable {
    case analysis = "Analysis"
    case prediction = "Prediction"
    case optimization = "Optimization"
    case readiness = "Readiness"
    case feedback = "Feedback"
}

enum InsightSeverity: String, Codable {
    case info = "Info"
    case suggestion = "Suggestion"
    case warning = "Warning"
    case critical = "Critical"

    var color: String {
        switch self {
        case .info: return "blue"
        case .suggestion: return "green"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .suggestion: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Set Analysis

struct SetAnalysis: Codable {
    var setID: UUID?
    var setName: String
    var totalDuration: TimeInterval
    var plannedDuration: TimeInterval?
    var songCount: Int

    // Flow analysis
    var keyTransitions: [KeyTransition] = []
    var difficultTransitions: [String] = []
    var energyFlow: [Float] = [] // Energy level per song
    var optimalOrder: [UUID]? // Suggested song order

    // Timing
    var averageSongDuration: TimeInterval
    var longestSong: UUID?
    var shortestSong: UUID?
    var pacingScore: Float // 0.0-1.0 (how well-paced)

    // Performance readiness
    var readinessScore: Float // 0.0-1.0
    var redFlags: [ReadinessFlag] = []
    var recommendations: [String] = []
}

struct KeyTransition: Codable, Identifiable {
    var id: UUID = UUID()
    var fromSongID: UUID
    var toSongID: UUID
    var fromKey: String
    var toKey: String
    var semitoneChange: Int
    var smoothness: Float // 0.0-1.0 (0=jarring, 1=smooth)
    var suggestion: String?
}

struct ReadinessFlag: Codable, Identifiable {
    var id: UUID = UUID()
    var type: ReadinessFlagType
    var songID: UUID
    var songTitle: String
    var severity: InsightSeverity
    var message: String
    var recommendation: String?
}

enum ReadinessFlagType: String, Codable {
    case insufficientPractice = "Insufficient Practice"
    case recentlyAdded = "Recently Added"
    case complexChords = "Complex Chords"
    case fastTempo = "Fast Tempo"
    case difficultKey = "Difficult Key"
    case longDuration = "Long Duration"
    case equipmentRequired = "Equipment Required"
}

// MARK: - Post-Performance Report

struct PostPerformanceReport: Codable, Identifiable {
    var id: UUID = UUID()
    var sessionID: UUID
    var performanceDate: Date
    var setName: String
    var venue: String?

    // Summary statistics
    var totalDuration: TimeInterval
    var songsPerformed: Int
    var songsCompleted: Int
    var averagePerformance: Float // 0.0-1.0

    // Performance metrics
    var overallScore: Float // 0.0-100
    var strengthAreas: [StrengthArea] = []
    var improvementAreas: [ImprovementArea] = []

    // Comparisons
    var comparisonToPrevious: PerformanceComparison?
    var personalBest: [String] = [] // Categories where this was best

    // Audience feedback
    var audienceRating: Float?
    var topSongs: [UUID] = [] // Best audience response
    var requestedSongs: [UUID] = []

    // Insights and recommendations
    var keyInsights: [PerformanceInsight] = []
    var practiceRecommendations: [String] = []
    var setlistRecommendations: [String] = []

    // Future goals
    var suggestedGoals: [PerformanceGoal] = []
}

struct StrengthArea: Codable, Identifiable {
    var id: UUID = UUID()
    var area: String
    var score: Float
    var description: String
    var examples: [String] = []
}

struct ImprovementArea: Codable, Identifiable {
    var id: UUID = UUID()
    var area: String
    var currentScore: Float
    var targetScore: Float
    var description: String
    var actionItems: [String] = []
}

struct PerformanceComparison: Codable {
    var previousDate: Date
    var scoreChange: Float // Positive = improvement
    var durationChange: TimeInterval
    var errorRateChange: Float
    var improvementPercentage: Float
    var significantChanges: [String] = []
}

struct PerformanceGoal: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var category: GoalCategory
    var targetDate: Date?
    var measurable: Bool
    var specificMetric: String?
    var targetValue: Float?
}

enum GoalCategory: String, Codable {
    case technical = "Technical"
    case repertoire = "Repertoire"
    case performance = "Performance"
    case audience = "Audience"
    case consistency = "Consistency"
}
