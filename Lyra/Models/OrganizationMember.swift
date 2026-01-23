//
//  OrganizationMember.swift
//  Lyra
//
//  Represents a member of an organization with role-based access
//

import Foundation
import SwiftData
import CloudKit

@Model
final class OrganizationMember {
    // MARK: - Identifiers

    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - User Information

    /// CloudKit user record ID
    var userRecordID: String

    /// User's display name
    var displayName: String?

    /// User's email
    var email: String?

    /// User's phone number
    var phoneNumber: String?

    /// User's avatar URL
    var avatarURL: String?

    /// User's title/position
    var title: String?

    /// User's department
    var department: String?

    // MARK: - Role & Status

    /// Member's role in the organization
    var role: OrganizationRole

    /// Whether the member is currently active
    var isActive: Bool

    /// Whether the member is suspended
    var isSuspended: Bool

    /// Suspension reason
    var suspensionReason: String?

    /// Suspension date
    var suspendedAt: Date?

    /// Date when member joined
    var joinedAt: Date

    /// Date when member left (if applicable)
    var leftAt: Date?

    /// Who invited this member
    var invitedBy: String?

    // MARK: - Invitation

    /// Invitation status
    var invitationStatus: InvitationStatus

    /// Date when invitation was sent
    var invitationSentAt: Date?

    /// Date when invitation was accepted/declined
    var invitationRespondedAt: Date?

    /// Invitation token (for email invitations)
    var invitationToken: String?

    // MARK: - Activity Tracking

    /// Last login date
    var lastLoginAt: Date?

    /// Last activity date
    var lastActivityAt: Date?

    /// Number of libraries the member has access to
    var libraryAccessCount: Int

    /// Total number of edits made
    var totalEdits: Int

    /// Total number of songs added
    var totalSongsAdded: Int

    // MARK: - Preferences

    /// Notification preferences data
    var notificationPreferencesData: Data? // Encoded NotificationPreferences

    // MARK: - Relationship

    @Relationship(deleteRule: .cascade, inverse: \Organization.members)
    var organization: Organization?

    // MARK: - Initializer

    init(
        userRecordID: String,
        displayName: String? = nil,
        role: OrganizationRole = .member,
        invitedBy: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.role = role
        self.isActive = true
        self.isSuspended = false
        self.joinedAt = Date()
        self.invitedBy = invitedBy
        self.invitationStatus = .pending
        self.libraryAccessCount = 0
        self.totalEdits = 0
        self.totalSongsAdded = 0
    }

    // MARK: - Computed Properties

    var displayNameOrEmail: String {
        displayName ?? email ?? "Unknown User"
    }

    var initials: String {
        let name = displayNameOrEmail
        let components = name.split(separator: " ")

        if components.count >= 2 {
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return (first + last).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        } else {
            return "?"
        }
    }

    var statusText: String {
        if isSuspended {
            return "Suspended"
        } else if !isActive {
            return "Inactive"
        } else if invitationStatus != .accepted {
            return "Pending Invitation"
        } else {
            return "Active"
        }
    }

    var canAccessOrganization: Bool {
        isActive && !isSuspended && invitationStatus == .accepted
    }

    // MARK: - Methods

    func acceptInvitation() {
        invitationStatus = .accepted
        invitationRespondedAt = Date()
        lastLoginAt = Date()
        lastActivityAt = Date()
        modifiedAt = Date()
    }

    func declineInvitation(reason: String? = nil) {
        invitationStatus = .declined
        invitationRespondedAt = Date()
        if let reason = reason {
            suspensionReason = reason
        }
        modifiedAt = Date()
    }

    func suspend(reason: String) {
        isSuspended = true
        suspensionReason = reason
        suspendedAt = Date()
        modifiedAt = Date()
    }

    func unsuspend() {
        isSuspended = false
        suspensionReason = nil
        suspendedAt = nil
        modifiedAt = Date()
    }

    func updateRole(_ newRole: OrganizationRole) {
        role = newRole
        modifiedAt = Date()
    }

    func recordActivity() {
        lastActivityAt = Date()
        modifiedAt = Date()
    }

    func recordLogin() {
        lastLoginAt = Date()
        lastActivityAt = Date()
        modifiedAt = Date()
    }

    func incrementEdits() {
        totalEdits += 1
        lastActivityAt = Date()
        modifiedAt = Date()
    }

    func incrementSongsAdded() {
        totalSongsAdded += 1
        lastActivityAt = Date()
        modifiedAt = Date()
    }
}

// MARK: - Organization Role

enum OrganizationRole: String, Codable, CaseIterable, Comparable {
    case member = "Member"
    case editor = "Editor"
    case admin = "Admin"
    case owner = "Owner"

    // MARK: - Role Hierarchy

    var level: Int {
        switch self {
        case .member: return 0
        case .editor: return 1
        case .admin: return 2
        case .owner: return 3
        }
    }

    static func < (lhs: OrganizationRole, rhs: OrganizationRole) -> Bool {
        lhs.level < rhs.level
    }

    // MARK: - Capabilities

    var canViewLibraries: Bool {
        level >= OrganizationRole.member.level
    }

    var canEditContent: Bool {
        level >= OrganizationRole.editor.level
    }

    var canCreateLibraries: Bool {
        level >= OrganizationRole.editor.level
    }

    var canManageMembers: Bool {
        level >= OrganizationRole.admin.level
    }

    var canManageLibraries: Bool {
        level >= OrganizationRole.admin.level
    }

    var canChangeRoles: Bool {
        level >= OrganizationRole.admin.level
    }

    var canManageSettings: Bool {
        level >= OrganizationRole.admin.level
    }

    var canManageBilling: Bool {
        level >= OrganizationRole.owner.level
    }

    var canDeleteOrganization: Bool {
        self == .owner
    }

    var canTransferOwnership: Bool {
        self == .owner
    }

    var canViewAuditLog: Bool {
        level >= OrganizationRole.admin.level
    }

    // MARK: - Display

    var icon: String {
        switch self {
        case .member: return "person"
        case .editor: return "pencil"
        case .admin: return "star.circle"
        case .owner: return "crown.fill"
        }
    }

    var description: String {
        switch self {
        case .member:
            return "Can view content in shared libraries"
        case .editor:
            return "Can create and edit content"
        case .admin:
            return "Can manage members and libraries"
        case .owner:
            return "Full control of the organization"
        }
    }

    var color: String {
        switch self {
        case .member: return "gray"
        case .editor: return "blue"
        case .admin: return "purple"
        case .owner: return "yellow"
        }
    }
}

// MARK: - Invitation Status

enum InvitationStatus: String, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case expired = "Expired"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .accepted: return "checkmark.circle"
        case .declined: return "xmark.circle"
        case .expired: return "exclamationmark.triangle"
        case .cancelled: return "xmark.octagon"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .accepted: return "green"
        case .declined: return "red"
        case .expired: return "yellow"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var emailNotifications: Bool = true
    var pushNotifications: Bool = true
    var activityDigest: DigestFrequency = .weekly
    var notifyOnMemberJoin: Bool = true
    var notifyOnLibraryChange: Bool = true
    var notifyOnMentions: Bool = true

    enum DigestFrequency: String, Codable {
        case never = "Never"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
}
