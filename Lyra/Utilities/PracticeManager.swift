//
//  PracticeManager.swift
//  Lyra
//
//  Central orchestrator for all practice intelligence features
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData
import Observation

/// Central manager that orchestrates all practice intelligence engines
@MainActor
@Observable
class PracticeManager {

    // MARK: - Properties

    private let modelContext: ModelContext

    // Engine instances
    private let trackingEngine: PracticeTrackingEngine
    private let assessmentEngine: SkillAssessmentEngine
    private let recommendationEngine: PracticeRecommendationEngine
    private let difficultyEngine: AdaptiveDifficultyEngine
    private let analyticsEngine: ProgressAnalyticsEngine
    private let modeEngine: PracticeModeEngine
    private let coachEngine: AICoachEngine

    // Current state
    var currentSession: PracticeSession?
    var currentConfiguration: PracticeModeConfiguration?
    var isSessionActive: Bool = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Initialize engines
        self.trackingEngine = PracticeTrackingEngine(modelContext: modelContext)
        self.assessmentEngine = SkillAssessmentEngine(modelContext: modelContext)
        self.recommendationEngine = PracticeRecommendationEngine(
            modelContext: modelContext,
            trackingEngine: trackingEngine,
            assessmentEngine: assessmentEngine
        )
        self.difficultyEngine = AdaptiveDifficultyEngine(
            modelContext: modelContext,
            assessmentEngine: assessmentEngine
        )
        self.analyticsEngine = ProgressAnalyticsEngine(
            modelContext: modelContext,
            trackingEngine: trackingEngine
        )
        self.modeEngine = PracticeModeEngine()
        self.coachEngine = AICoachEngine(modelContext: modelContext)
    }

    // MARK: - Session Management

    /// Start a practice session
    func startSession(songID: UUID, mode: PracticeMode = .normal) -> PracticeSession {
        let session = trackingEngine.startSession(songID: songID, mode: mode)
        currentSession = session
        isSessionActive = true

        // Set up mode configuration if needed
        if mode != .normal {
            setupModeConfiguration(sessionID: session.id, mode: mode)
        }

        return session
    }

    /// End the current practice session
    func endSession(completionRate: Float) {
        guard let session = currentSession else { return }

        trackingEngine.endSession(session, completionRate: completionRate)

        // Generate coach feedback
        if let metrics = session.skillMetrics {
            let feedback = coachEngine.generateFeedback(session: session, skillMetrics: metrics)
            // Could save or display feedback here
        }

        // Check for milestones
        checkForMilestones(session: session)

        // Clean up
        if let sessionID = currentSession?.id {
            modeEngine.endMode(sessionID: sessionID)
        }

        currentSession = nil
        currentConfiguration = nil
        isSessionActive = false
    }

    /// Pause the current session
    func pauseSession() {
        guard let session = currentSession else { return }
        trackingEngine.pauseSession(session)
        isSessionActive = false
    }

    /// Resume the paused session
    func resumeSession() {
        guard let session = currentSession else { return }
        trackingEngine.resumeSession(session)
        isSessionActive = true
    }

    /// Cancel the current session
    func cancelSession() {
        guard let session = currentSession else { return }
        trackingEngine.cancelSession(session)

        if let sessionID = currentSession?.id {
            modeEngine.endMode(sessionID: sessionID)
        }

        currentSession = nil
        currentConfiguration = nil
        isSessionActive = false
    }

    // MARK: - Difficulty Logging

    /// Log a difficulty encountered during practice
    func logDifficulty(
        type: PracticeDifficulty.DifficultyType,
        chord: String? = nil,
        section: String? = nil,
        severity: Float,
        notes: String? = nil
    ) {
        guard let session = currentSession else { return }

        trackingEngine.logDifficulty(
            session: session,
            type: type,
            chord: chord,
            section: section,
            severity: severity,
            notes: notes
        )
    }

    // MARK: - Practice Modes

    /// Setup mode configuration
    private func setupModeConfiguration(sessionID: UUID, mode: PracticeMode) {
        switch mode {
        case .slowMo:
            currentConfiguration = modeEngine.startSlowMoMode(
                sessionID: sessionID,
                tempoMultiplier: 0.75
            )

        case .loop:
            // Would need section details from caller
            break

        case .hideChords:
            currentConfiguration = modeEngine.startHideChordsMode(
                sessionID: sessionID,
                revealAfterSeconds: 3.0
            )

        case .quiz:
            let skillLevel = getCurrentSkillLevel()
            currentConfiguration = modeEngine.startChordQuiz(
                sessionID: sessionID,
                difficulty: skillLevel,
                questionCount: 10
            )

        default:
            break
        }
    }

    /// Start slow-mo mode
    func startSlowMoMode(tempoMultiplier: Float) {
        guard let sessionID = currentSession?.id else { return }
        currentConfiguration = modeEngine.startSlowMoMode(
            sessionID: sessionID,
            tempoMultiplier: tempoMultiplier
        )
    }

    /// Start loop mode
    func startLoopMode(
        sectionName: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        repetitions: Int
    ) {
        guard let sessionID = currentSession?.id else { return }
        currentConfiguration = modeEngine.startLoopMode(
            sessionID: sessionID,
            sectionName: sectionName,
            startTime: startTime,
            endTime: endTime,
            repetitions: repetitions
        )
    }

    /// Start hide chords mode
    func startHideChordsMode(revealDelay: TimeInterval) {
        guard let sessionID = currentSession?.id else { return }
        currentConfiguration = modeEngine.startHideChordsMode(
            sessionID: sessionID,
            revealAfterSeconds: revealDelay
        )
    }

    // MARK: - Recommendations

    /// Get weekly practice recommendations
    func getWeeklyRecommendations(
        allSongs: [SongData]
    ) -> [PracticeRecommendation] {
        let history = trackingEngine.getRecentSessions(limit: 100)
        let skillLevel = getCurrentSkillLevel()

        return recommendationEngine.generateWeeklyRecommendations(
            allSongs: allSongs,
            practiceHistory: history,
            userSkillLevel: skillLevel
        )
    }

    /// Get smart recommendations based on context
    func getSmartRecommendations(
        allSongs: [SongData],
        availableTime: TimeInterval
    ) -> [PracticeRecommendation] {
        let history = trackingEngine.getRecentSessions(limit: 100)
        let skillLevel = getCurrentSkillLevel()

        return recommendationEngine.getSmartRecommendations(
            allSongs: allSongs,
            practiceHistory: history,
            userSkillLevel: skillLevel,
            availableTime: availableTime
        )
    }

    /// Generate practice schedule
    func generatePracticeSchedule(
        availableTime: TimeInterval,
        allSongs: [SongData]
    ) -> PracticeSchedule {
        let recommendations = getWeeklyRecommendations(allSongs: allSongs)

        return recommendationEngine.generatePracticeSchedule(
            availableTime: availableTime,
            recommendations: recommendations
        )
    }

    // MARK: - Analytics

    /// Get practice analytics
    func getAnalytics(timeRange: TimeRange = .last30Days) -> PracticeAnalytics {
        return analyticsEngine.getPracticeAnalytics(timeRange: timeRange)
    }

    /// Get improvement chart data
    func getImprovementData(
        metric: MetricType,
        timeRange: TimeRange
    ) -> [ImprovementDataPoint] {
        return analyticsEngine.calculateImprovement(
            metric: metric,
            timeRange: timeRange
        )
    }

    /// Get mastery timeline
    func getMasteryTimeline() -> [MasteryTimelinePoint] {
        return analyticsEngine.getMasteryTimeline()
    }

    /// Get practice patterns
    func getPracticePatterns() -> PracticePatternAnalysis {
        return analyticsEngine.analyzePracticePatterns()
    }

    // MARK: - Skill Assessment

    /// Get current skill level
    func getCurrentSkillLevel() -> SkillLevel {
        let history = trackingEngine.getRecentSessions(limit: 50)
        return assessmentEngine.estimateSkillLevel(history: history)
    }

    /// Analyze weaknesses
    func analyzeWeaknesses() -> WeaknessAnalysis {
        let history = trackingEngine.getRecentSessions(limit: 100)
        return assessmentEngine.analyzeWeaknesses(history: history)
    }

    /// Analyze strengths
    func analyzeStrengths() -> StrengthAnalysis {
        let history = trackingEngine.getRecentSessions(limit: 100)
        return assessmentEngine.analyzeStrengths(history: history)
    }

    /// Track skill improvement
    func trackSkillImprovement() -> SkillProgressTracking {
        let history = trackingEngine.getRecentSessions(limit: 100)
        return assessmentEngine.trackSkillImprovement(history: history)
    }

    /// Predict next skill level
    func predictNextSkillLevel() -> SkillLevelPrediction? {
        let history = trackingEngine.getRecentSessions(limit: 100)
        return assessmentEngine.predictNextSkillLevel(history: history)
    }

    // MARK: - Learning Path

    /// Generate learning path
    func generateLearningPath(
        allSongs: [SongAnalysisData],
        goals: [LearningPath.LearningGoal]
    ) -> LearningPath {
        let skillLevel = getCurrentSkillLevel()
        let history = trackingEngine.getRecentSessions(limit: 100)

        return difficultyEngine.generateLearningPath(
            allSongs: allSongs,
            skillLevel: skillLevel,
            goals: goals,
            practiceHistory: history
        )
    }

    /// Assess song difficulty
    func assessSongDifficulty(song: SongAnalysisData) -> DifficultyAssessment {
        return difficultyEngine.assessSongDifficulty(song: song)
    }

    // MARK: - AI Coaching

    /// Get daily tip
    func getDailyTip() -> CoachMessage {
        return coachEngine.getDailyTip()
    }

    /// Get technique suggestion
    func getTechniqueSuggestion(
        for difficulty: PracticeDifficulty.DifficultyType,
        chord: String? = nil
    ) -> CoachMessage {
        return coachEngine.suggestTechnique(difficulty: difficulty, chord: chord)
    }

    /// Get encouragement
    func getEncouragement() -> CoachMessage {
        let analytics = getAnalytics()

        return coachEngine.generateEncouragement(
            currentSkillLevel: getCurrentSkillLevel(),
            improvementRate: analytics.improvementRate,
            practiceStreak: analytics.currentStreak,
            sessionCount: analytics.totalSessions
        )
    }

    /// Get theory lesson
    func getTheoryLesson(topic: TheoryTopic) -> CoachMessage {
        let skillLevel = getCurrentSkillLevel()
        return coachEngine.getTheoryLesson(topic: topic, skillLevel: skillLevel)
    }

    /// Get smart practice suggestion
    func getSmartSuggestion(
        timeAvailable: TimeInterval,
        energyLevel: EnergyLevel
    ) -> CoachMessage {
        let weaknesses = analyzeWeaknesses().primaryWeaknesses

        return coachEngine.getSmartSuggestion(
            weaknesses: weaknesses,
            timeAvailable: timeAvailable,
            energy: energyLevel
        )
    }

    // MARK: - Milestones

    /// Check for and celebrate milestones
    private func checkForMilestones(session: PracticeSession) {
        let analytics = getAnalytics()

        // Check for first song mastered
        if analytics.songsMastered == 1 {
            createMilestone(
                type: .firstSongMastered,
                songID: session.songID,
                value: 1,
                description: "First song mastered!"
            )
        }

        // Check for streak milestones
        if analytics.currentStreak == 7 || analytics.currentStreak == 30 || analytics.currentStreak == 100 {
            createMilestone(
                type: .streakAchieved,
                value: Float(analytics.currentStreak),
                description: "\(analytics.currentStreak)-day practice streak!"
            )
        }

        // Check for perfect session
        if session.difficulties.isEmpty && session.completionRate >= 0.95 {
            createMilestone(
                type: .perfectSession,
                songID: session.songID,
                value: session.completionRate,
                description: "Perfect practice session!"
            )
        }
    }

    /// Create a milestone
    private func createMilestone(
        type: ProgressMilestone.MilestoneType,
        songID: UUID? = nil,
        value: Float,
        description: String
    ) {
        let milestone = ProgressMilestone(
            type: type,
            songID: songID,
            metric: "achievement",
            value: value,
            description: description
        )

        modelContext.insert(milestone)
        try? modelContext.save()

        // Generate celebration message
        let celebration = coachEngine.celebrateMilestone(milestone: milestone)
        // Could display or save celebration message
    }

    /// Get recent milestones
    func getRecentMilestones(limit: Int = 10) -> [ProgressMilestone] {
        let descriptor = FetchDescriptor<ProgressMilestone>(
            sortBy: [SortDescriptor(\.achievedDate, order: .reverse)]
        )

        do {
            let milestones = try modelContext.fetch(descriptor)
            return Array(milestones.prefix(limit))
        } catch {
            print("Error fetching milestones: \(error)")
            return []
        }
    }

    // MARK: - Practice History

    /// Get practice history for a song
    func getPracticeHistory(songID: UUID, limit: Int = 20) -> [PracticeSession] {
        return trackingEngine.getPracticeHistory(songID: songID, limit: limit)
    }

    /// Get recent sessions
    func getRecentSessions(limit: Int = 10) -> [PracticeSession] {
        return trackingEngine.getRecentSessions(limit: limit)
    }

    /// Get total practice time for a song
    func getTotalPracticeTime(songID: UUID) -> TimeInterval {
        return trackingEngine.getTotalPracticeTime(songID: songID)
    }

    /// Get most practiced songs
    func getMostPracticedSongs(limit: Int = 10) -> [(songID: UUID, sessionCount: Int, totalTime: TimeInterval)] {
        return trackingEngine.getMostPracticedSongs(limit: limit)
    }
}
