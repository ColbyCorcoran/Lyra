//
//  SetMemberRole.swift
//  Lyra
//
//  Role assignments for team members in performance sets
//

import SwiftData
import Foundation

@Model
final class SetMemberRole {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date

    // MARK: - Assignment
    var userRecordID: String
    var displayName: String

    var songID: UUID // Song in the set
    var setEntryID: UUID // Specific set entry

    var role: MemberRole

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \SharedPerformanceSet.roleAssignments)
    var sharedSet: SharedPerformanceSet?

    // MARK: - Personal Settings (per role)
    var personalKeyOverride: String? // User-specific key preference
    var personalCapoOverride: Int? // User-specific capo
    var personalNotes: String? // Private notes for this role

    init(
        userRecordID: String,
        displayName: String,
        songID: UUID,
        setEntryID: UUID,
        role: MemberRole
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.songID = songID
        self.setEntryID = setEntryID
        self.role = role
    }
}

// MARK: - Member Role

enum MemberRole: String, Codable, CaseIterable {
    // Leadership
    case leader = "Leader"
    case musicDirector = "Music Director"
    case worshipLeader = "Worship Leader"

    // Vocals
    case leadVocalist = "Lead Vocalist"
    case backupVocals = "Backup Vocals"
    case harmony = "Harmony"
    case choir = "Choir"

    // String Instruments
    case acousticGuitar = "Acoustic Guitar"
    case electricGuitar = "Electric Guitar"
    case bassGuitar = "Bass Guitar"
    case ukulele = "Ukulele"

    // Keys
    case piano = "Piano"
    case keyboard = "Keyboard"
    case organ = "Organ"
    case synthesizer = "Synthesizer"

    // Percussion
    case drums = "Drums"
    case cajon = "Cajon"
    case percussion = "Percussion"

    // Orchestral
    case violin = "Violin"
    case cello = "Cello"
    case flute = "Flute"
    case trumpet = "Trumpet"
    case saxophone = "Saxophone"

    // Tech
    case soundEngineer = "Sound Engineer"
    case lightingOperator = "Lighting Operator"
    case videoOperator = "Video Operator"

    // Other
    case other = "Other"

    var icon: String {
        switch self {
        case .leader, .musicDirector, .worshipLeader:
            return "person.fill.badge.plus"
        case .leadVocalist, .backupVocals, .harmony, .choir:
            return "mic.fill"
        case .acousticGuitar, .electricGuitar, .bassGuitar, .ukulele:
            return "guitars.fill"
        case .piano, .keyboard, .organ, .synthesizer:
            return "pianokeys.fill"
        case .drums, .cajon, .percussion:
            return "metronome.fill"
        case .violin, .cello, .flute, .trumpet, .saxophone:
            return "music.quarternote.3"
        case .soundEngineer, .lightingOperator, .videoOperator:
            return "slider.horizontal.3"
        case .other:
            return "music.note"
        }
    }

    var category: RoleCategory {
        switch self {
        case .leader, .musicDirector, .worshipLeader:
            return .leadership
        case .leadVocalist, .backupVocals, .harmony, .choir:
            return .vocals
        case .acousticGuitar, .electricGuitar, .bassGuitar, .ukulele:
            return .strings
        case .piano, .keyboard, .organ, .synthesizer:
            return .keys
        case .drums, .cajon, .percussion:
            return .percussion
        case .violin, .cello, .flute, .trumpet, .saxophone:
            return .orchestral
        case .soundEngineer, .lightingOperator, .videoOperator:
            return .tech
        case .other:
            return .other
        }
    }
}

enum RoleCategory: String, CaseIterable {
    case leadership = "Leadership"
    case vocals = "Vocals"
    case strings = "Strings"
    case keys = "Keys"
    case percussion = "Percussion"
    case orchestral = "Orchestral"
    case tech = "Technical"
    case other = "Other"

    var roles: [MemberRole] {
        MemberRole.allCases.filter { $0.category == self }
    }
}

// MARK: - Personal Set Settings

@Model
final class PersonalSetSettings {
    var id: UUID
    var modifiedAt: Date

    var userRecordID: String
    var performanceSetID: UUID

    // View Preferences
    var showOnlyMyRoles: Bool
    var highlightMySongs: Bool
    var sortOrder: SetSortOrder

    // Display Settings
    var defaultKeyOverride: String?
    var defaultCapoOverride: Int?
    var showReadinessIndicators: Bool

    // Notifications
    var notifyOnChanges: Bool
    var notifyOnRehearsals: Bool
    var notifyBeforePerformance: Bool
    var reminderHoursBefore: Int

    init(userRecordID: String, performanceSetID: UUID) {
        self.id = UUID()
        self.modifiedAt = Date()
        self.userRecordID = userRecordID
        self.performanceSetID = performanceSetID
        self.showOnlyMyRoles = false
        self.highlightMySongs = true
        self.sortOrder = .setOrder
        self.showReadinessIndicators = true
        self.notifyOnChanges = true
        self.notifyOnRehearsals = true
        self.notifyBeforePerformance = true
        self.reminderHoursBefore = 24
    }
}

enum SetSortOrder: String, Codable, CaseIterable {
    case setOrder = "Set Order"
    case myRolesFirst = "My Roles First"
    case readiness = "Readiness"
    case alphabetical = "Alphabetical"

    var icon: String {
        switch self {
        case .setOrder: return "list.number"
        case .myRolesFirst: return "person.fill"
        case .readiness: return "chart.bar.fill"
        case .alphabetical: return "textformat.abc"
        }
    }
}
