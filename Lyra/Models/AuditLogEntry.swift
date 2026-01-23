//
//  AuditLogEntry.swift
//  Lyra
//
//  Audit log for tracking administrative actions in organizations
//

import Foundation

/// Represents an auditable action in an organization
struct AuditLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date

    // MARK: - Actor Information

    /// Who performed the action
    let actorRecordID: String

    /// Actor's display name
    let actorDisplayName: String?

    // MARK: - Action Details

    /// Type of action performed
    let action: AuditAction

    /// Additional details about the action
    let details: String?

    // MARK: - Target Information

    /// ID of the affected entity (member, library, etc.)
    let targetID: String?

    /// Name of the affected entity
    let targetName: String?

    // MARK: - Metadata

    /// IP address (if available)
    var ipAddress: String?

    /// Device type
    var deviceType: String?

    /// App version
    var appVersion: String?

    // MARK: - Initializer

    init(
        actorRecordID: String,
        actorDisplayName: String?,
        action: AuditAction,
        details: String? = nil,
        targetID: String? = nil,
        targetName: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.actorRecordID = actorRecordID
        self.actorDisplayName = actorDisplayName
        self.action = action
        self.details = details
        self.targetID = targetID
        self.targetName = targetName
    }

    // MARK: - Computed Properties

    var actorName: String {
        actorDisplayName ?? "Unknown User"
    }

    var displayText: String {
        var text = "\(actorName) \(action.verb)"

        if let targetName = targetName {
            text += " \(targetName)"
        }

        if let details = details {
            text += " - \(details)"
        }

        return text
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Audit Action

enum AuditAction: String, Codable {
    // Organization actions
    case organizationCreated = "Created Organization"
    case organizationUpdated = "Updated Organization"
    case organizationDeleted = "Deleted Organization"
    case organizationSettingsChanged = "Changed Settings"

    // Member actions
    case memberAdded = "Added Member"
    case memberRemoved = "Removed Member"
    case memberRoleChanged = "Changed Role"
    case memberSuspended = "Suspended Member"
    case memberUnsuspended = "Unsuspended Member"
    case memberInvited = "Invited Member"

    // Library actions
    case libraryCreated = "Created Library"
    case libraryDeleted = "Deleted Library"
    case libraryPermissionsChanged = "Changed Library Permissions"
    case librarySettingsChanged = "Changed Library Settings"
    case libraryTransferred = "Transferred Library"

    // Subscription actions
    case subscriptionChanged = "Changed Subscription"
    case subscriptionCancelled = "Cancelled Subscription"
    case subscriptionRenewed = "Renewed Subscription"
    case billingUpdated = "Updated Billing"

    // Ownership actions
    case ownershipTransferred = "Transferred Ownership"

    // Security actions
    case securitySettingsChanged = "Changed Security Settings"
    case apiKeyCreated = "Created API Key"
    case apiKeyRevoked = "Revoked API Key"

    var verb: String {
        switch self {
        case .organizationCreated, .libraryCreated, .apiKeyCreated:
            return "created"
        case .organizationUpdated, .billingUpdated:
            return "updated"
        case .organizationDeleted, .libraryDeleted:
            return "deleted"
        case .memberAdded:
            return "added"
        case .memberRemoved:
            return "removed"
        case .memberRoleChanged:
            return "changed role for"
        case .memberSuspended:
            return "suspended"
        case .memberUnsuspended:
            return "unsuspended"
        case .memberInvited:
            return "invited"
        case .organizationSettingsChanged, .librarySettingsChanged, .securitySettingsChanged:
            return "changed settings for"
        case .libraryPermissionsChanged:
            return "changed permissions for"
        case .libraryTransferred, .ownershipTransferred:
            return "transferred"
        case .subscriptionChanged:
            return "changed subscription"
        case .subscriptionCancelled:
            return "cancelled subscription"
        case .subscriptionRenewed:
            return "renewed subscription"
        case .apiKeyRevoked:
            return "revoked API key"
        }
    }

    var icon: String {
        switch self {
        case .organizationCreated, .libraryCreated:
            return "plus.circle.fill"
        case .organizationDeleted, .libraryDeleted:
            return "trash.fill"
        case .organizationUpdated, .organizationSettingsChanged, .librarySettingsChanged:
            return "gearshape.fill"
        case .memberAdded:
            return "person.badge.plus.fill"
        case .memberRemoved:
            return "person.badge.minus.fill"
        case .memberRoleChanged:
            return "arrow.triangle.2.circlepath"
        case .memberSuspended:
            return "hand.raised.fill"
        case .memberUnsuspended:
            return "checkmark.circle.fill"
        case .memberInvited:
            return "envelope.fill"
        case .libraryPermissionsChanged:
            return "lock.fill"
        case .libraryTransferred, .ownershipTransferred:
            return "arrow.right.circle.fill"
        case .subscriptionChanged, .subscriptionRenewed:
            return "creditcard.fill"
        case .subscriptionCancelled:
            return "xmark.circle.fill"
        case .billingUpdated:
            return "dollarsign.circle.fill"
        case .securitySettingsChanged:
            return "shield.fill"
        case .apiKeyCreated, .apiKeyRevoked:
            return "key.fill"
        }
    }

    var color: String {
        switch self {
        case .organizationCreated, .libraryCreated, .memberAdded, .memberInvited, .memberUnsuspended, .subscriptionRenewed:
            return "green"
        case .organizationDeleted, .libraryDeleted, .memberRemoved, .memberSuspended, .subscriptionCancelled, .apiKeyRevoked:
            return "red"
        case .memberRoleChanged, .libraryPermissionsChanged, .organizationSettingsChanged, .librarySettingsChanged:
            return "orange"
        case .subscriptionChanged, .billingUpdated, .organizationUpdated:
            return "blue"
        case .ownershipTransferred, .libraryTransferred:
            return "purple"
        case .securitySettingsChanged, .apiKeyCreated:
            return "yellow"
        }
    }

    var category: AuditCategory {
        switch self {
        case .organizationCreated, .organizationUpdated, .organizationDeleted, .organizationSettingsChanged:
            return .organization
        case .memberAdded, .memberRemoved, .memberRoleChanged, .memberSuspended, .memberUnsuspended, .memberInvited:
            return .members
        case .libraryCreated, .libraryDeleted, .libraryPermissionsChanged, .librarySettingsChanged, .libraryTransferred:
            return .libraries
        case .subscriptionChanged, .subscriptionCancelled, .subscriptionRenewed, .billingUpdated:
            return .billing
        case .ownershipTransferred:
            return .ownership
        case .securitySettingsChanged, .apiKeyCreated, .apiKeyRevoked:
            return .security
        }
    }
}

// MARK: - Audit Category

enum AuditCategory: String, Codable, CaseIterable {
    case all = "All"
    case organization = "Organization"
    case members = "Members"
    case libraries = "Libraries"
    case billing = "Billing"
    case ownership = "Ownership"
    case security = "Security"

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .organization: return "building.2"
        case .members: return "person.3"
        case .libraries: return "books.vertical"
        case .billing: return "creditcard"
        case .ownership: return "crown"
        case .security: return "shield"
        }
    }
}
