//
//  SetSongReadiness.swift
//  Lyra
//
//  Track song preparation and readiness for performance sets
//

import SwiftData
import Foundation

@Model
final class SetSongReadiness {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Song Reference
    var songID: UUID
    var setEntryID: UUID

    @Relationship(deleteRule: .nullify)
    var sharedSet: SharedPerformanceSet?

    // MARK: - Overall Readiness
    var readinessLevel: ReadinessLevel
    var lastUpdatedBy: String?
    var lastUpdatedByDisplayName: String?

    // MARK: - Per-Member Readiness
    @Relationship(deleteRule: .cascade, inverse: \MemberReadiness.songReadiness)
    var memberReadiness: [MemberReadiness]?

    // MARK: - Preparation Checklist
    var lyricsLearned: Bool
    var chordsLearned: Bool
    var arrangementsFinalized: Bool
    var transitionsRehearsed: Bool
    var dynamicsPracticed: Bool

    // MARK: - Notes & Issues
    var preparationNotes: String?
    var knownIssues: String?
    var specialRequirements: String?

    // MARK: - Practice Tracking
    var practiceCount: Int
    var lastPracticedDate: Date?

    init(songID: UUID, setEntryID: UUID) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.songID = songID
        self.setEntryID = setEntryID
        self.readinessLevel = .notStarted
        self.lyricsLearned = false
        self.chordsLearned = false
        self.arrangementsFinalized = false
        self.transitionsRehearsed = false
        self.dynamicsPracticed = false
        self.practiceCount = 0
    }

    // MARK: - Checklist Progress
    var checklistProgress: Double {
        let items = [
            lyricsLearned,
            chordsLearned,
            arrangementsFinalized,
            transitionsRehearsed,
            dynamicsPracticed
        ]
        let completed = items.filter { $0 }.count
        return Double(completed) / Double(items.count)
    }

    var checklistItemsCompleted: Int {
        let items = [
            lyricsLearned,
            chordsLearned,
            arrangementsFinalized,
            transitionsRehearsed,
            dynamicsPracticed
        ]
        return items.filter { $0 }.count
    }

    // MARK: - Team Readiness
    var teamReadinessScore: Double {
        guard let members = memberReadiness, !members.isEmpty else {
            return 0
        }

        let totalScore = members.reduce(0.0) { $0 + $1.confidenceScore }
        return totalScore / Double(members.count)
    }

    // MARK: - Update Methods
    func updateReadiness(to level: ReadinessLevel, by userRecordID: String, displayName: String) {
        self.readinessLevel = level
        self.lastUpdatedBy = userRecordID
        self.lastUpdatedByDisplayName = displayName
        self.modifiedAt = Date()
    }

    func recordPractice() {
        self.practiceCount += 1
        self.lastPracticedDate = Date()
        self.modifiedAt = Date()
    }
}

// MARK: - Readiness Level

enum ReadinessLevel: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case needsReview = "Needs Review"
    case ready = "Ready"
    case performance = "Performance Ready"

    var emoji: String {
        switch self {
        case .notStarted: return "⚫️"
        case .inProgress: return "🟡"
        case .needsReview: return "🟠"
        case .ready: return "🟢"
        case .performance: return "🟢✨"
        }
    }

    var description: String {
        switch self {
        case .notStarted: return "Haven't started learning"
        case .inProgress: return "Currently learning"
        case .needsReview: return "Needs more practice"
        case .ready: return "Ready to perform"
        case .performance: return "Performance ready"
        }
    }

    var sortOrder: Int {
        switch self {
        case .notStarted: return 0
        case .inProgress: return 1
        case .needsReview: return 2
        case .ready: return 3
        case .performance: return 4
        }
    }
}

// MARK: - Member Readiness

@Model
final class MemberReadiness {
    var id: UUID
    var modifiedAt: Date

    var userRecordID: String
    var displayName: String

    @Relationship(deleteRule: .nullify)
    var songReadiness: SetSongReadiness?

    // Individual readiness
    var readinessLevel: ReadinessLevel
    var confidenceScore: Double // 0.0 to 1.0

    // Personal checklist
    var partLearned: Bool
    var rehearsedWithTeam: Bool
    var comfortableAtTempo: Bool

    // Notes
    var personalNotes: String?
    var needsHelp: Bool
    var helpNeededWith: String?

    init(
        userRecordID: String,
        displayName: String
    ) {
        self.id = UUID()
        self.modifiedAt = Date()
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.readinessLevel = .notStarted
        self.confidenceScore = 0.0
        self.partLearned = false
        self.rehearsedWithTeam = false
        self.comfortableAtTempo = false
        self.needsHelp = false
    }

    func updateReadiness(level: ReadinessLevel, confidence: Double) {
        self.readinessLevel = level
        self.confidenceScore = max(0.0, min(1.0, confidence))
        self.modifiedAt = Date()
    }
}

// MARK: - Checklist Item

struct ChecklistItem: Identifiable, Codable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var completedBy: String?
    var completedAt: Date?

    init(title: String) {
        self.title = title
        self.isCompleted = false
    }

    mutating func complete(by userDisplayName: String) {
        self.isCompleted = true
        self.completedBy = userDisplayName
        self.completedAt = Date()
    }

    mutating func uncomplete() {
        self.isCompleted = false
        self.completedBy = nil
        self.completedAt = nil
    }
}
