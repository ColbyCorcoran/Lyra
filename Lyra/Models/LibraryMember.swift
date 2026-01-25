//
//  LibraryMember.swift
//  Lyra
//
//  Represents a member of a shared library with their permission level
//

import Foundation
import SwiftData
import CloudKit

@Model
final class LibraryMember {
    // MARK: - Identifiers

    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - User Information

    /// CloudKit user record ID
    var userRecordID: String

    /// User's display name (from CloudKit)
    var displayName: String?

    /// User's email (if available)
    var email: String?

    /// User's avatar/profile image URL
    var avatarURL: String?

    // MARK: - Permission

    /// Member's permission level
    var permissionLevel: LibraryPermission

    /// Date when member was added
    var joinedAt: Date

    /// Date when permission was last changed
    var permissionChangedAt: Date?

    /// Who invited this member (user record ID)
    var invitedBy: String?

    // MARK: - Status

    /// Whether the invitation was accepted
    var invitationAccepted: Bool

    /// Date when invitation was sent
    var invitationSentAt: Date?

    /// Date when invitation was accepted/declined
    var invitationRespondedAt: Date?

    // MARK: - Activity Tracking

    /// Last time this member viewed the library
    var lastViewedAt: Date?

    /// Last time this member edited something
    var lastEditedAt: Date?

    /// Number of edits made by this member
    var editCount: Int

    // MARK: - Relationship

    /// The shared library this member belongs to
    @Relationship(deleteRule: .cascade, inverse: \SharedLibrary.members)
    var library: SharedLibrary?

    // MARK: - Initializer

    init(
        userRecordID: String,
        displayName: String? = nil,
        permissionLevel: LibraryPermission = .viewer,
        invitedBy: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.permissionLevel = permissionLevel
        self.joinedAt = Date()
        self.invitedBy = invitedBy
        self.invitationAccepted = false
        self.editCount = 0
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        invitationAccepted
    }

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

    var invitationStatus: InvitationStatus {
        if invitationAccepted {
            return .accepted
        } else if let sentAt = invitationSentAt {
            let daysSinceSent = Calendar.current.dateComponents([.day], from: sentAt, to: Date()).day ?? 0
            if daysSinceSent > 7 {
                return .expired
            }
            return .pending
        } else {
            return .notSent
        }
    }

    enum InvitationStatus {
        case notSent
        case pending
        case accepted
        case declined
        case expired
    }

    // MARK: - Methods

    /// Updates activity tracking when member views library
    func recordView() {
        lastViewedAt = Date()
        modifiedAt = Date()
    }

    /// Updates activity tracking when member edits
    func recordEdit() {
        lastEditedAt = Date()
        editCount += 1
        modifiedAt = Date()
    }

    /// Accepts the invitation
    func acceptInvitation() {
        invitationAccepted = true
        invitationRespondedAt = Date()
        modifiedAt = Date()
    }

    /// Updates permission level
    func updatePermission(_ newPermission: LibraryPermission) {
        permissionLevel = newPermission
        permissionChangedAt = Date()
        modifiedAt = Date()
    }

    /// Creates from CloudKit participant
    static func from(ckParticipant: CKShare.Participant, invitedBy: String? = nil) -> LibraryMember {
        let member = LibraryMember(
            userRecordID: ckParticipant.userIdentity.userRecordID?.recordName ?? "",
            displayName: ckParticipant.userIdentity.nameComponents?.formatted(),
            permissionLevel: LibraryPermission.from(ckParticipant: ckParticipant),
            invitedBy: invitedBy
        )

        // Update from participant
        member.invitationAccepted = ckParticipant.acceptanceStatus == .accepted
        member.email = ckParticipant.userIdentity.lookupInfo?.emailAddress

        return member
    }
}

// MARK: - Member Activity

/// Represents an activity performed by a library member
struct LibraryMemberActivity: Identifiable, Codable {
    let id: UUID
    let memberID: UUID
    let memberName: String
    let activityType: ActivityType
    let timestamp: Date
    let details: String?

    enum ActivityType: String, Codable {
        case joined = "Joined"
        case leftLibrary = "Left"
        case addedSong = "Added Song"
        case editedSong = "Edited Song"
        case deletedSong = "Deleted Song"
        case permissionChanged = "Permission Changed"
        case invitedMember = "Invited Member"
        case removedMember = "Removed Member"

        var icon: String {
            switch self {
            case .joined: return "person.badge.plus"
            case .leftLibrary: return "person.badge.minus"
            case .addedSong: return "plus.circle"
            case .editedSong: return "pencil.circle"
            case .deletedSong: return "trash.circle"
            case .permissionChanged: return "key"
            case .invitedMember: return "envelope"
            case .removedMember: return "person.crop.circle.badge.xmark"
            }
        }

        var color: String {
            switch self {
            case .joined, .invitedMember: return "green"
            case .leftLibrary, .deletedSong, .removedMember: return "red"
            case .addedSong, .editedSong: return "blue"
            case .permissionChanged: return "orange"
            }
        }
    }

    var displayText: String {
        var text = "\(memberName) \(activityType.rawValue.lowercased())"
        if let details = details {
            text += ": \(details)"
        }
        return text
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
