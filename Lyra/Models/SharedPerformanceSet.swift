//
//  SharedPerformanceSet.swift
//  Lyra
//
//  Model for shared performance sets with team collaboration features
//

import SwiftData
import Foundation
import CloudKit

@Model
final class SharedPerformanceSet {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Performance Set Reference
    @Relationship(deleteRule: .nullify, inverse: \PerformanceSet.sharedSet)
    var performanceSet: PerformanceSet?

    // MARK: - Ownership & Sharing
    var ownerRecordID: String // CloudKit user record ID of owner
    var ownerDisplayName: String
    var shareRecordID: String? // CloudKit CKShare record ID

    // MARK: - Team Members
    @Relationship(deleteRule: .cascade, inverse: \SetMember.sharedSet)
    var members: [SetMember]?

    // MARK: - Permissions
    var defaultPermission: SetPermissionLevel

    // MARK: - Status
    var isLocked: Bool // Performance day - no more edits allowed
    var lockedAt: Date?
    var lockedBy: String?

    // MARK: - Performance Day
    var performanceDate: Date?
    var performanceStatus: PerformanceStatus

    // MARK: - Team Readiness
    /// Overall team readiness score (0-100)
    var teamReadinessScore: Int {
        guard let readiness = songReadiness, !readiness.isEmpty else { return 0 }
        let totalReady = readiness.filter { $0.readinessLevel == .ready }.count
        return Int((Double(totalReady) / Double(readiness.count)) * 100)
    }

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \SetMemberRole.sharedSet)
    var roleAssignments: [SetMemberRole]?

    @Relationship(deleteRule: .cascade, inverse: \SetSongReadiness.sharedSet)
    var songReadiness: [SetSongReadiness]?

    @Relationship(deleteRule: .cascade, inverse: \SetRehearsal.sharedSet)
    var rehearsals: [SetRehearsal]?

    @Relationship(deleteRule: .cascade, inverse: \SetComment.sharedSet)
    var comments: [SetComment]?

    // MARK: - Initialization
    init(
        performanceSet: PerformanceSet,
        ownerRecordID: String,
        ownerDisplayName: String,
        defaultPermission: SetPermissionLevel = .viewer
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.performanceSet = performanceSet
        self.ownerRecordID = ownerRecordID
        self.ownerDisplayName = ownerDisplayName
        self.defaultPermission = defaultPermission
        self.isLocked = false
        self.performanceStatus = .planning
    }

    // MARK: - Permission Checking
    func hasPermission(_ userRecordID: String, level: SetPermissionLevel) -> Bool {
        // Owner has all permissions
        if userRecordID == ownerRecordID {
            return true
        }

        // Check member-specific permission
        if let member = members?.first(where: { $0.userRecordID == userRecordID }) {
            return member.permission.rawValue >= level.rawValue
        }

        // Fall back to default permission
        return defaultPermission.rawValue >= level.rawValue
    }

    func canEdit(_ userRecordID: String) -> Bool {
        return !isLocked && hasPermission(userRecordID, level: .editor)
    }

    func canViewRoles(_ userRecordID: String) -> Bool {
        return hasPermission(userRecordID, level: .viewer)
    }

    // MARK: - Lock Management
    func lock(by userRecordID: String, displayName: String) {
        isLocked = true
        lockedAt = Date()
        lockedBy = displayName
        modifiedAt = Date()
    }

    func unlock() {
        isLocked = false
        lockedAt = nil
        lockedBy = nil
        modifiedAt = Date()
    }

    // MARK: - Member Management
    func addMember(_ member: SetMember) {
        if members == nil {
            members = []
        }
        members?.append(member)
        modifiedAt = Date()
    }

    func removeMember(userRecordID: String) {
        members?.removeAll { $0.userRecordID == userRecordID }
        modifiedAt = Date()
    }

    // MARK: - Readiness Summary
    var readinessSummary: (ready: Int, inProgress: Int, notStarted: Int) {
        guard let readiness = songReadiness else { return (0, 0, 0) }

        let ready = readiness.filter { $0.readinessLevel == .ready }.count
        let inProgress = readiness.filter { $0.readinessLevel == .inProgress }.count
        let notStarted = readiness.filter { $0.readinessLevel == .notStarted }.count

        return (ready, inProgress, notStarted)
    }
}

// MARK: - Supporting Types

enum SetPermissionLevel: Int, Codable, CaseIterable {
    case viewer = 0
    case contributor = 1 // Can mark readiness, add notes
    case editor = 2 // Can modify set, assign roles
    case admin = 3 // Can manage members, lock/unlock

    var displayName: String {
        switch self {
        case .viewer: return "Viewer"
        case .contributor: return "Contributor"
        case .editor: return "Editor"
        case .admin: return "Admin"
        }
    }

    var description: String {
        switch self {
        case .viewer:
            return "Can view set and assignments"
        case .contributor:
            return "Can update readiness and add notes"
        case .editor:
            return "Can modify set and assign roles"
        case .admin:
            return "Full control including member management"
        }
    }
}

enum PerformanceStatus: String, Codable, CaseIterable {
    case planning = "Planning"
    case rehearsing = "Rehearsing"
    case ready = "Ready"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .planning: return "calendar"
        case .rehearsing: return "music.note.list"
        case .ready: return "checkmark.circle.fill"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .planning: return "gray"
        case .rehearsing: return "orange"
        case .ready: return "green"
        case .inProgress: return "blue"
        case .completed: return "purple"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Set Member

@Model
final class SetMember {
    var id: UUID
    var joinedAt: Date

    var userRecordID: String
    var displayName: String
    var permission: SetPermissionLevel

    @Relationship(deleteRule: .nullify)
    var sharedSet: SharedPerformanceSet?

    // Member preferences
    var notificationsEnabled: Bool
    var showOnlyMyRoles: Bool // Filter to only show assigned songs

    init(
        userRecordID: String,
        displayName: String,
        permission: SetPermissionLevel
    ) {
        self.id = UUID()
        self.joinedAt = Date()
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.permission = permission
        self.notificationsEnabled = true
        self.showOnlyMyRoles = false
    }
}

// MARK: - Set Comment

@Model
final class SetComment {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    var authorRecordID: String
    var authorDisplayName: String

    var content: String
    var isResolved: Bool

    // Context
    var songID: UUID? // If comment is about a specific song
    var rehearsalID: UUID? // If comment is from a rehearsal

    @Relationship(deleteRule: .nullify)
    var sharedSet: SharedPerformanceSet?

    init(
        authorRecordID: String,
        authorDisplayName: String,
        content: String,
        songID: UUID? = nil,
        rehearsalID: UUID? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.authorRecordID = authorRecordID
        self.authorDisplayName = authorDisplayName
        self.content = content
        self.isResolved = false
        self.songID = songID
        self.rehearsalID = rehearsalID
    }
}

// Note: sharedSet and isShared are defined in PerformanceSet.swift
