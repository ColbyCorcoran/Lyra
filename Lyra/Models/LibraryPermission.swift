//
//  LibraryPermission.swift
//  Lyra
//
//  Permission levels and access control for shared libraries
//

import Foundation
import CloudKit

/// Permission levels for shared library members
enum LibraryPermission: String, Codable, CaseIterable, Comparable {
    case viewer = "Viewer"
    case editor = "Editor"
    case admin = "Admin"
    case owner = "Owner"

    // MARK: - Permission Hierarchy

    var level: Int {
        switch self {
        case .viewer: return 0
        case .editor: return 1
        case .admin: return 2
        case .owner: return 3
        }
    }

    static func < (lhs: LibraryPermission, rhs: LibraryPermission) -> Bool {
        lhs.level < rhs.level
    }

    // MARK: - Capabilities

    var canView: Bool {
        level >= LibraryPermission.viewer.level
    }

    var canEdit: Bool {
        level >= LibraryPermission.editor.level
    }

    var canAddMembers: Bool {
        level >= LibraryPermission.admin.level
    }

    var canRemoveMembers: Bool {
        level >= LibraryPermission.admin.level
    }

    var canChangePermissions: Bool {
        level >= LibraryPermission.admin.level
    }

    var canDeleteLibrary: Bool {
        self == .owner
    }

    var canTransferOwnership: Bool {
        self == .owner
    }

    var canEditLibrarySettings: Bool {
        level >= LibraryPermission.admin.level
    }

    // MARK: - Display

    var icon: String {
        switch self {
        case .viewer: return "eye"
        case .editor: return "pencil"
        case .admin: return "star"
        case .owner: return "crown"
        }
    }

    var description: String {
        switch self {
        case .viewer:
            return "Can view songs, cannot edit"
        case .editor:
            return "Can view and edit songs"
        case .admin:
            return "Can edit and manage members"
        case .owner:
            return "Full control of the library"
        }
    }

    var color: String {
        switch self {
        case .viewer: return "gray"
        case .editor: return "blue"
        case .admin: return "purple"
        case .owner: return "yellow"
        }
    }

    // MARK: - CloudKit Mapping

    /// Maps to CloudKit share participant role
    var ckShareParticipantRole: CKShare.ParticipantRole {
        switch self {
        case .viewer, .editor, .admin:
            return .privateUser
        case .owner:
            return .owner
        }
    }

    /// Maps to CloudKit share participant permission
    var ckShareParticipantPermission: CKShare.ParticipantPermission {
        switch self {
        case .viewer:
            return .readOnly
        case .editor, .admin, .owner:
            return .readWrite
        }
    }

    /// Creates permission from CloudKit participant
    static func from(ckParticipant: CKShare.Participant) -> LibraryPermission {
        switch ckParticipant.role {
        case .owner:
            return .owner
        case .privateUser:
            switch ckParticipant.permission {
            case .readOnly:
                return .viewer
            case .readWrite:
                return .editor
            default:
                return .viewer
            }
        default:
            return .viewer
        }
    }
}

// MARK: - Permission Check Result

struct PermissionCheckResult {
    let hasPermission: Bool
    let requiredPermission: LibraryPermission
    let currentPermission: LibraryPermission?
    let errorMessage: String?

    var deniedMessage: String {
        if let current = currentPermission {
            return "This action requires \(requiredPermission.rawValue) permission. You have \(current.rawValue) permission."
        } else {
            return "This action requires \(requiredPermission.rawValue) permission."
        }
    }
}

// MARK: - Permission Helper

struct PermissionHelper {

    /// Checks if user has required permission
    static func checkPermission(
        required: LibraryPermission,
        current: LibraryPermission?
    ) -> PermissionCheckResult {
        guard let current = current else {
            return PermissionCheckResult(
                hasPermission: false,
                requiredPermission: required,
                currentPermission: nil,
                errorMessage: "You don't have access to this library."
            )
        }

        let hasPermission = current >= required

        return PermissionCheckResult(
            hasPermission: hasPermission,
            requiredPermission: required,
            currentPermission: current,
            errorMessage: hasPermission ? nil : "Insufficient permissions."
        )
    }

    /// Gets available permissions that can be assigned by current user
    static func assignablePermissions(by currentPermission: LibraryPermission) -> [LibraryPermission] {
        switch currentPermission {
        case .owner:
            // Owner can assign any permission except owner
            return [.viewer, .editor, .admin]
        case .admin:
            // Admin can assign viewer and editor
            return [.viewer, .editor]
        default:
            // Others cannot assign permissions
            return []
        }
    }

    /// Checks if user can modify another user's permission
    static func canModifyPermission(
        currentUserPermission: LibraryPermission,
        targetUserPermission: LibraryPermission,
        newPermission: LibraryPermission
    ) -> Bool {
        // Owner can modify anyone except themselves becoming non-owner
        if currentUserPermission == .owner {
            if targetUserPermission == .owner && newPermission != .owner {
                return false // Can't demote owner without transfer
            }
            return true
        }

        // Admin can modify viewer/editor
        if currentUserPermission == .admin {
            return targetUserPermission < .admin && newPermission < .admin
        }

        return false
    }
}

// MARK: - Library Privacy

enum LibraryPrivacy: String, Codable, CaseIterable {
    case `private` = "Private"
    case inviteOnly = "Invite Only"
    case publicReadOnly = "Public (Read-Only)"
    case publicReadWrite = "Public (Read-Write)"

    var icon: String {
        switch self {
        case .private: return "lock.fill"
        case .inviteOnly: return "person.badge.key"
        case .publicReadOnly: return "globe"
        case .publicReadWrite: return "globe.badge.chevron.backward"
        }
    }

    var description: String {
        switch self {
        case .private:
            return "Only you and invited members can access"
        case .inviteOnly:
            return "Anyone with the link can view, must be invited to edit"
        case .publicReadOnly:
            return "Anyone can view, only members can edit"
        case .publicReadWrite:
            return "Anyone can view and edit"
        }
    }

    var ckSharePublicPermission: CKShare.ParticipantPermission {
        switch self {
        case .private, .inviteOnly:
            return .none
        case .publicReadOnly:
            return .readOnly
        case .publicReadWrite:
            return .readWrite
        }
    }
}
