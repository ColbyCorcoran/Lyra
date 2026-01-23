//
//  SetRehearsal.swift
//  Lyra
//
//  Track rehearsals for performance sets with notes and attendance
//

import SwiftData
import Foundation

@Model
final class SetRehearsal {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Rehearsal Info
    var rehearsalDate: Date
    var startTime: Date?
    var endTime: Date?
    var location: String?

    @Relationship(deleteRule: .nullify, inverse: \SharedPerformanceSet.rehearsals)
    var sharedSet: SharedPerformanceSet?

    // MARK: - Attendance
    @Relationship(deleteRule: .cascade, inverse: \RehearsalAttendance.rehearsal)
    var attendance: [RehearsalAttendance]?

    // MARK: - Songs Rehearsed
    var songsRehearsed: [UUID] // Song IDs that were practiced
    var songsSkipped: [UUID] // Songs that weren't covered

    // MARK: - Notes
    var generalNotes: String?
    var accomplishments: String? // What went well
    var improvements: String? // What needs work
    var actionItems: String? // To-dos before next rehearsal

    // MARK: - Song-Specific Notes
    @Relationship(deleteRule: .cascade, inverse: \RehearsalSongNote.rehearsal)
    var songNotes: [RehearsalSongNote]?

    // MARK: - Recording
    var hasRecording: Bool
    var recordingURL: String? // Cloud storage URL if recorded

    // MARK: - Status
    var isCompleted: Bool
    var completedBy: String?

    init(
        rehearsalDate: Date,
        location: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.rehearsalDate = rehearsalDate
        self.location = location
        self.songsRehearsed = []
        self.songsSkipped = []
        self.hasRecording = false
        self.isCompleted = false
    }

    // MARK: - Computed Properties
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }

    var attendanceCount: Int {
        attendance?.filter { $0.didAttend }.count ?? 0
    }

    var attendanceRate: Double {
        guard let attendance = attendance, !attendance.isEmpty else { return 0 }
        let attended = attendance.filter { $0.didAttend }.count
        return Double(attended) / Double(attendance.count)
    }

    var songsRehearsedCount: Int {
        songsRehearsed.count
    }

    // MARK: - Methods
    func markSongRehearsed(_ songID: UUID) {
        if !songsRehearsed.contains(songID) {
            songsRehearsed.append(songID)
        }
        songsSkipped.removeAll { $0 == songID }
        modifiedAt = Date()
    }

    func markSongSkipped(_ songID: UUID) {
        if !songsSkipped.contains(songID) {
            songsSkipped.append(songID)
        }
        songsRehearsed.removeAll { $0 == songID }
        modifiedAt = Date()
    }

    func complete(by userRecordID: String) {
        isCompleted = true
        completedBy = userRecordID
        modifiedAt = Date()
    }
}

// MARK: - Rehearsal Attendance

@Model
final class RehearsalAttendance {
    var id: UUID

    var userRecordID: String
    var displayName: String

    var didAttend: Bool
    var arrivalTime: Date?
    var departureTime: Date?

    var reason: String? // If absent

    @Relationship(deleteRule: .nullify, inverse: \SetRehearsal.attendance)
    var rehearsal: SetRehearsal?

    init(
        userRecordID: String,
        displayName: String,
        didAttend: Bool = false
    ) {
        self.id = UUID()
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.didAttend = didAttend
    }

    func recordArrival() {
        didAttend = true
        arrivalTime = Date()
    }

    func recordDeparture() {
        departureTime = Date()
    }
}

// MARK: - Rehearsal Song Note

@Model
final class RehearsalSongNote {
    var id: UUID
    var createdAt: Date

    var songID: UUID

    var authorRecordID: String
    var authorDisplayName: String

    var noteType: RehearsalNoteType
    var content: String

    var timestamp: TimeInterval? // Time in rehearsal when noted

    @Relationship(deleteRule: .nullify, inverse: \SetRehearsal.songNotes)
    var rehearsal: SetRehearsal?

    init(
        songID: UUID,
        authorRecordID: String,
        authorDisplayName: String,
        noteType: RehearsalNoteType,
        content: String
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.songID = songID
        self.authorRecordID = authorRecordID
        self.authorDisplayName = authorDisplayName
        self.noteType = noteType
        self.content = content
    }
}

enum RehearsalNoteType: String, Codable, CaseIterable {
    case goodWork = "Good Work"
    case needsImprovement = "Needs Improvement"
    case technicalIssue = "Technical Issue"
    case arrangementChange = "Arrangement Change"
    case general = "General Note"

    var icon: String {
        switch self {
        case .goodWork: return "hand.thumbsup.fill"
        case .needsImprovement: return "arrow.up.circle.fill"
        case .technicalIssue: return "exclamationmark.triangle.fill"
        case .arrangementChange: return "music.note.list"
        case .general: return "note.text"
        }
    }

    var color: String {
        switch self {
        case .goodWork: return "green"
        case .needsImprovement: return "orange"
        case .technicalIssue: return "red"
        case .arrangementChange: return "blue"
        case .general: return "gray"
        }
    }
}
