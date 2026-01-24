//
//  PracticeTrackingEngine.swift
//  Lyra
//
//  Engine for tracking practice sessions and metrics
//  Part of Phase 7.7: Practice Intelligence
//

import Foundation
import SwiftData

/// Engine responsible for tracking practice sessions and collecting metrics
@MainActor
class PracticeTrackingEngine {

    // MARK: - Properties

    private let modelContext: ModelContext
    private var activeSessions: [UUID: PracticeSession] = [:]
    private var sessionStartTimes: [UUID: Date] = [:]
    private var chordChangeTracking: [UUID: ChordChangeTracking] = [:]

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Session Management

    /// Start a new practice session
    func startSession(songID: UUID, mode: PracticeMode = .normal) -> PracticeSession {
        let session = PracticeSession(
            songID: songID,
            startTime: Date(),
            practiceMode: mode
        )

        activeSessions[session.id] = session
        sessionStartTimes[session.id] = Date()
        chordChangeTracking[session.id] = ChordChangeTracking()

        return session
    }

    /// End a practice session
    func endSession(_ session: PracticeSession, completionRate: Float) {
        session.endTime = Date()
        session.completionRate = completionRate

        // Calculate duration
        if let startTime = sessionStartTimes[session.id] {
            session.duration = Date().timeIntervalSince(startTime)
        }

        // Generate skill metrics
        session.skillMetrics = generateSkillMetrics(for: session)

        // Save to database
        modelContext.insert(session)
        try? modelContext.save()

        // Clean up
        activeSessions.removeValue(forKey: session.id)
        sessionStartTimes.removeValue(forKey: session.id)
        chordChangeTracking.removeValue(forKey: session.id)
    }

    /// Pause a practice session
    func pauseSession(_ session: PracticeSession) {
        if let startTime = sessionStartTimes[session.id] {
            session.duration += Date().timeIntervalSince(startTime)
            sessionStartTimes.removeValue(forKey: session.id)
        }
    }

    /// Resume a paused session
    func resumeSession(_ session: PracticeSession) {
        sessionStartTimes[session.id] = Date()
    }

    /// Cancel a practice session without saving
    func cancelSession(_ session: PracticeSession) {
        activeSessions.removeValue(forKey: session.id)
        sessionStartTimes.removeValue(forKey: session.id)
        chordChangeTracking.removeValue(forKey: session.id)
    }

    // MARK: - Difficulty Tracking

    /// Log a difficulty encountered during practice
    func logDifficulty(
        session: PracticeSession,
        type: PracticeDifficulty.DifficultyType,
        chord: String? = nil,
        section: String? = nil,
        severity: Float,
        notes: String? = nil
    ) {
        let difficulty = PracticeDifficulty(
            type: type,
            section: section,
            chord: chord,
            timestamp: Date(),
            severity: severity,
            notes: notes
        )

        session.difficulties.append(difficulty)

        // Update problem sections
        if let sectionName = section {
            updateProblemSection(
                session: session,
                sectionName: sectionName,
                severity: severity
            )
        }
    }

    /// Update problem section tracking
    private func updateProblemSection(
        session: PracticeSession,
        sectionName: String,
        severity: Float
    ) {
        guard var metrics = session.skillMetrics else { return }

        if let index = metrics.problemSections.firstIndex(where: { $0.sectionName == sectionName }) {
            metrics.problemSections[index].errorCount += 1
            metrics.problemSections[index].lastEncountered = Date()
            metrics.problemSections[index].severity = max(
                metrics.problemSections[index].severity,
                severity
            )
        } else {
            let problemSection = ProblemSection(
                sectionName: sectionName,
                sectionType: inferSectionType(from: sectionName),
                errorCount: 1,
                lastEncountered: Date(),
                severity: severity
            )
            metrics.problemSections.append(problemSection)
        }

        session.skillMetrics = metrics
    }

    /// Infer section type from section name
    private func inferSectionType(from name: String) -> ProblemSection.SectionType {
        let lowercased = name.lowercased()

        if lowercased.contains("verse") {
            return .verse
        } else if lowercased.contains("chorus") {
            return .chorus
        } else if lowercased.contains("bridge") {
            return .bridge
        } else if lowercased.contains("intro") {
            return .intro
        } else if lowercased.contains("outro") {
            return .outro
        } else if lowercased.contains("solo") {
            return .solo
        } else if lowercased.contains("pre") && lowercased.contains("chorus") {
            return .prechorus
        } else {
            return .other
        }
    }

    // MARK: - Chord Change Tracking

    /// Record a chord change
    func recordChordChange(session: PracticeSession, fromChord: String, toChord: String, duration: TimeInterval) {
        guard var tracking = chordChangeTracking[session.id] else { return }

        tracking.totalChanges += 1
        tracking.changeDurations.append(duration)
        tracking.chordPairs.append((fromChord, toChord))

        chordChangeTracking[session.id] = tracking
    }

    /// Get chord change speed for a session
    func getChordChangeSpeed(session: PracticeSession) -> Float {
        guard let tracking = chordChangeTracking[session.id] else { return 0 }

        let durationMinutes = max(session.duration / 60.0, 0.1)
        return Float(tracking.totalChanges) / Float(durationMinutes)
    }

    // MARK: - Metrics Generation

    /// Generate skill metrics for a session
    private func generateSkillMetrics(for session: PracticeSession) -> SkillMetrics {
        let chordSpeed = getChordChangeSpeed(session: session)
        let rhythmAccuracy = calculateRhythmAccuracy(session: session)
        let memorization = calculateMemorizationLevel(session: session)
        let skillLevel = estimateSkillLevel(
            chordSpeed: chordSpeed,
            rhythm: rhythmAccuracy,
            memorization: memorization
        )

        return SkillMetrics(
            chordChangeSpeed: chordSpeed,
            rhythmAccuracy: rhythmAccuracy,
            memorizationLevel: memorization,
            overallSkillLevel: skillLevel,
            problemSections: extractProblemSections(session: session)
        )
    }

    /// Calculate rhythm accuracy based on session data
    private func calculateRhythmAccuracy(session: PracticeSession) -> Float {
        // Count rhythm-related difficulties
        let rhythmDifficulties = session.difficulties.filter {
            $0.type == .rhythmTiming || $0.type == .tempo
        }

        // If no rhythm difficulties, assume good accuracy
        if rhythmDifficulties.isEmpty {
            return 0.85
        }

        // Calculate accuracy penalty based on difficulties
        let totalSeverity = rhythmDifficulties.reduce(0.0) { $0 + $1.severity }
        let averageSeverity = totalSeverity / Float(rhythmDifficulties.count)

        // Start with perfect score and deduct based on difficulties
        let baseAccuracy: Float = 1.0
        let penalty = averageSeverity * 0.4  // Max penalty of 40%

        return max(baseAccuracy - penalty, 0.3)  // Minimum 30% accuracy
    }

    /// Calculate memorization level
    private func calculateMemorizationLevel(session: PracticeSession) -> Float {
        // Check if hide chords mode was used
        if session.practiceMode == .hideChords {
            // Higher memorization score for hide chords mode
            let memoryDifficulties = session.difficulties.filter { $0.type == .memory }

            if memoryDifficulties.isEmpty {
                return 0.9  // Excellent memory
            } else {
                let averageSeverity = memoryDifficulties.reduce(0.0) { $0 + $1.severity } / Float(memoryDifficulties.count)
                return max(0.7 - averageSeverity * 0.3, 0.3)
            }
        } else {
            // Normal mode - estimate based on completion and difficulties
            let memoryDifficulties = session.difficulties.filter { $0.type == .memory }

            if memoryDifficulties.isEmpty {
                return min(session.completionRate * 0.7, 0.7)  // Moderate memory score
            } else {
                return 0.4  // Lower score if memory difficulties present
            }
        }
    }

    /// Estimate skill level based on metrics
    private func estimateSkillLevel(
        chordSpeed: Float,
        rhythm: Float,
        memorization: Float
    ) -> SkillLevel {
        let overallScore = (chordSpeed / 30.0 + rhythm + memorization) / 3.0

        switch overallScore {
        case 0..<0.3:
            return .beginner
        case 0.3..<0.5:
            return .earlyIntermediate
        case 0.5..<0.7:
            return .intermediate
        case 0.7..<0.85:
            return .advanced
        default:
            return .expert
        }
    }

    /// Extract problem sections from session difficulties
    private func extractProblemSections(session: PracticeSession) -> [ProblemSection] {
        var sectionMap: [String: ProblemSection] = [:]

        for difficulty in session.difficulties {
            guard let sectionName = difficulty.section else { continue }

            if var problemSection = sectionMap[sectionName] {
                problemSection.errorCount += 1
                problemSection.lastEncountered = difficulty.timestamp
                problemSection.severity = max(problemSection.severity, difficulty.severity)
                sectionMap[sectionName] = problemSection
            } else {
                let problemSection = ProblemSection(
                    sectionName: sectionName,
                    sectionType: inferSectionType(from: sectionName),
                    errorCount: 1,
                    lastEncountered: difficulty.timestamp,
                    severity: difficulty.severity
                )
                sectionMap[sectionName] = problemSection
            }
        }

        return Array(sectionMap.values).sorted { $0.severity > $1.severity }
    }

    // MARK: - History & Statistics

    /// Get practice history for a specific song
    func getPracticeHistory(songID: UUID, limit: Int = 20) -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.songID == songID },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            return Array(sessions.prefix(limit))
        } catch {
            print("Error fetching practice history: \(error)")
            return []
        }
    }

    /// Get all practice sessions within a date range
    func getSessions(from startDate: Date, to endDate: Date) -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { session in
                session.startTime >= startDate && session.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }

    /// Get total practice time for a song
    func getTotalPracticeTime(songID: UUID) -> TimeInterval {
        let sessions = getPracticeHistory(songID: songID, limit: 1000)
        return sessions.reduce(0.0) { $0 + $1.duration }
    }

    /// Get average session duration
    func getAverageSessionDuration() -> TimeInterval {
        let descriptor = FetchDescriptor<PracticeSession>()

        do {
            let sessions = try modelContext.fetch(descriptor)
            guard !sessions.isEmpty else { return 0 }

            let totalDuration = sessions.reduce(0.0) { $0 + $1.duration }
            return totalDuration / Double(sessions.count)
        } catch {
            print("Error calculating average duration: \(error)")
            return 0
        }
    }

    /// Get most practiced songs
    func getMostPracticedSongs(limit: Int = 10) -> [(songID: UUID, sessionCount: Int, totalTime: TimeInterval)] {
        let descriptor = FetchDescriptor<PracticeSession>()

        do {
            let sessions = try modelContext.fetch(descriptor)

            var songStats: [UUID: (count: Int, time: TimeInterval)] = [:]

            for session in sessions {
                if var stats = songStats[session.songID] {
                    stats.count += 1
                    stats.time += session.duration
                    songStats[session.songID] = stats
                } else {
                    songStats[session.songID] = (1, session.duration)
                }
            }

            return songStats
                .map { (songID: $0.key, sessionCount: $0.value.count, totalTime: $0.value.time) }
                .sorted { $0.sessionCount > $1.sessionCount }
                .prefix(limit)
                .map { $0 }
        } catch {
            print("Error getting most practiced songs: \(error)")
            return []
        }
    }

    /// Get recent sessions
    func getRecentSessions(limit: Int = 10) -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            return Array(sessions.prefix(limit))
        } catch {
            print("Error fetching recent sessions: \(error)")
            return []
        }
    }

    /// Calculate practice consistency (days practiced in last N days)
    func calculateConsistency(days: Int = 30) -> Float {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return 0
        }

        let sessions = getSessions(from: startDate, to: endDate)

        // Get unique practice dates
        var practiceDates = Set<Date>()
        for session in sessions {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: session.startTime)
            if let date = calendar.date(from: dateComponents) {
                practiceDates.insert(date)
            }
        }

        return Float(practiceDates.count) / Float(days)
    }
}

// MARK: - Supporting Types

/// Tracking data for chord changes within a session
private struct ChordChangeTracking {
    var totalChanges: Int = 0
    var changeDurations: [TimeInterval] = []
    var chordPairs: [(String, String)] = []

    var averageChangeDuration: TimeInterval {
        guard !changeDurations.isEmpty else { return 0 }
        return changeDurations.reduce(0.0, +) / Double(changeDurations.count)
    }
}
