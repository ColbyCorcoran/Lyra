//
//  OrganizationManager.swift
//  Lyra
//
//  Manages organization operations including CloudKit sync and member management
//

import Foundation
import CloudKit
import SwiftData
import Combine

@MainActor
class OrganizationManager: ObservableObject {
    static let shared = OrganizationManager()

    @Published var currentOrganization: Organization?
    @Published var userOrganizations: [Organization] = []
    @Published var isLoading = false
    @Published var error: OrganizationError?

    private let container: CKContainer
    private let database: CKDatabase

    private init() {
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
    }

    // MARK: - Organization Creation

    func createOrganization(
        name: String,
        description: String?,
        type: OrganizationType,
        ownerRecordID: String,
        ownerDisplayName: String?,
        modelContext: ModelContext
    ) async throws -> Organization {
        isLoading = true
        defer { isLoading = false }

        // Create local organization
        let organization = Organization(
            name: name,
            description: description,
            organizationType: type,
            ownerRecordID: ownerRecordID,
            ownerDisplayName: ownerDisplayName
        )

        // Apply default settings based on type
        switch type {
        case .church, .worshipTeam:
            organization.settings = TeamSettings.churchPreset()
        case .therapyPractice:
            organization.settings = TeamSettings.therapyPracticePreset()
        case .school:
            organization.settings = TeamSettings.schoolPreset()
        case .band:
            organization.settings = TeamSettings.bandPreset()
        default:
            organization.settings = TeamSettings()
        }

        // Save to SwiftData
        modelContext.insert(organization)
        try modelContext.save()

        // Add audit log entry
        let auditEntry = AuditLogEntry(
            actorRecordID: ownerRecordID,
            actorDisplayName: ownerDisplayName,
            action: .organizationCreated,
            details: "Created organization '\(name)'",
            targetID: organization.id.uuidString,
            targetName: name
        )
        organization.addAuditLogEntry(auditEntry)
        try modelContext.save()

        // Sync to CloudKit (async)
        Task {
            try? await syncOrganizationToCloudKit(organization)
        }

        return organization
    }

    // MARK: - Member Management

    func addMember(
        to organization: Organization,
        userRecordID: String,
        displayName: String?,
        email: String?,
        role: OrganizationRole,
        invitedBy: String,
        modelContext: ModelContext
    ) async throws -> OrganizationMember {
        // Check seat limit
        guard organization.canAddMoreMembers else {
            throw OrganizationError.seatLimitReached
        }

        // Check if member already exists
        if organization.member(for: userRecordID) != nil {
            throw OrganizationError.memberAlreadyExists
        }

        // Create member
        let member = OrganizationMember(
            userRecordID: userRecordID,
            displayName: displayName,
            role: role,
            invitedBy: invitedBy
        )
        member.email = email
        member.invitationSentAt = Date()

        // Add to organization
        organization.addMember(member)

        // Add audit log
        let auditEntry = AuditLogEntry(
            actorRecordID: invitedBy,
            actorDisplayName: nil,
            action: .memberInvited,
            details: "Invited \(displayName ?? email ?? "member") as \(role.rawValue)",
            targetID: userRecordID,
            targetName: displayName
        )
        organization.addAuditLogEntry(auditEntry)

        try modelContext.save()

        // TODO: Send invitation email/notification

        return member
    }

    func removeMember(
        _ member: OrganizationMember,
        from organization: Organization,
        removedBy: String,
        modelContext: ModelContext
    ) async throws {
        // Cannot remove owner
        if member.userRecordID == organization.ownerRecordID {
            throw OrganizationError.cannotRemoveOwner
        }

        // Remove from organization
        organization.removeMember(member)

        // Add audit log
        let auditEntry = AuditLogEntry(
            actorRecordID: removedBy,
            actorDisplayName: nil,
            action: .memberRemoved,
            details: "Removed \(member.displayNameOrEmail)",
            targetID: member.userRecordID,
            targetName: member.displayName
        )
        organization.addAuditLogEntry(auditEntry)

        // Delete member
        modelContext.delete(member)
        try modelContext.save()
    }

    func updateMemberRole(
        _ member: OrganizationMember,
        to newRole: OrganizationRole,
        in organization: Organization,
        changedBy: String,
        modelContext: ModelContext
    ) async throws {
        let oldRole = member.role

        // Cannot change owner role
        if member.userRecordID == organization.ownerRecordID {
            throw OrganizationError.cannotChangeOwnerRole
        }

        // Update role
        member.updateRole(newRole)

        // Update admin count
        if oldRole == .admin && newRole != .admin {
            organization.adminCount -= 1
        } else if oldRole != .admin && newRole == .admin {
            organization.adminCount += 1
        }

        // Add audit log
        let auditEntry = AuditLogEntry(
            actorRecordID: changedBy,
            actorDisplayName: nil,
            action: .memberRoleChanged,
            details: "Changed role from \(oldRole.rawValue) to \(newRole.rawValue)",
            targetID: member.userRecordID,
            targetName: member.displayName
        )
        organization.addAuditLogEntry(auditEntry)

        try modelContext.save()
    }

    func suspendMember(
        _ member: OrganizationMember,
        reason: String,
        suspendedBy: String,
        in organization: Organization,
        modelContext: ModelContext
    ) async throws {
        member.suspend(reason: reason)

        // Add audit log
        let auditEntry = AuditLogEntry(
            actorRecordID: suspendedBy,
            actorDisplayName: nil,
            action: .memberSuspended,
            details: reason,
            targetID: member.userRecordID,
            targetName: member.displayName
        )
        organization.addAuditLogEntry(auditEntry)

        try modelContext.save()
    }

    func unsuspendMember(
        _ member: OrganizationMember,
        unsuspendedBy: String,
        in organization: Organization,
        modelContext: ModelContext
    ) async throws {
        member.unsuspend()

        // Add audit log
        let auditEntry = AuditLogEntry(
            actorRecordID: unsuspendedBy,
            actorDisplayName: nil,
            action: .memberUnsuspended,
            targetID: member.userRecordID,
            targetName: member.displayName
        )
        organization.addAuditLogEntry(auditEntry)

        try modelContext.save()
    }

    // MARK: - Organization Management

    func updateOrganization(
        _ organization: Organization,
        name: String?,
        description: String?,
        icon: String?,
        colorHex: String?,
        updatedBy: String,
        modelContext: ModelContext
    ) async throws {
        var changes: [String] = []

        if let name = name, name != organization.name {
            organization.name = name
            changes.append("name")
        }

        if let description = description, description != organization.organizationDescription {
            organization.organizationDescription = description
            changes.append("description")
        }

        if let icon = icon, icon != organization.icon {
            organization.icon = icon
            changes.append("icon")
        }

        if let colorHex = colorHex, colorHex != organization.colorHex {
            organization.colorHex = colorHex
            changes.append("color")
        }

        if !changes.isEmpty {
            organization.modifiedAt = Date()

            // Add audit log
            let auditEntry = AuditLogEntry(
                actorRecordID: updatedBy,
                actorDisplayName: nil,
                action: .organizationUpdated,
                details: "Updated: \(changes.joined(separator: ", "))",
                targetID: organization.id.uuidString,
                targetName: organization.name
            )
            organization.addAuditLogEntry(auditEntry)

            try modelContext.save()

            // Sync to CloudKit
            Task {
                try? await syncOrganizationToCloudKit(organization)
            }
        }
    }

    func updateSettings(
        for organization: Organization,
        settings: TeamSettings,
        updatedBy: String,
        modelContext: ModelContext
    ) async throws {
        // Validate settings
        let errors = settings.validate()
        guard errors.isEmpty else {
            throw OrganizationError.invalidSettings(errors.joined(separator: ", "))
        }

        organization.settings = settings

        // Add audit log
        let auditEntry = AuditLogEntry(
            actorRecordID: updatedBy,
            actorDisplayName: nil,
            action: .organizationSettingsChanged,
            targetID: organization.id.uuidString,
            targetName: organization.name
        )
        organization.addAuditLogEntry(auditEntry)

        try modelContext.save()
    }

    func deleteOrganization(
        _ organization: Organization,
        deletedBy: String,
        modelContext: ModelContext
    ) async throws {
        // Only owner can delete
        guard deletedBy == organization.ownerRecordID else {
            throw OrganizationError.insufficientPermissions
        }

        // Delete from CloudKit if synced
        if organization.isCloudSynced, let recordName = organization.cloudKitRecordName {
            let recordID = CKRecord.ID(recordName: recordName)
            try? await database.deleteRecord(withID: recordID)
        }

        // Delete locally
        modelContext.delete(organization)
        try modelContext.save()
    }

    // MARK: - CloudKit Sync

    private func syncOrganizationToCloudKit(_ organization: Organization) async throws {
        let record: CKRecord

        if let recordName = organization.cloudKitRecordName {
            let recordID = CKRecord.ID(recordName: recordName)
            record = CKRecord(recordType: "Organization", recordID: recordID)
        } else {
            record = CKRecord(recordType: "Organization")
        }

        // Set record fields
        record["name"] = organization.name
        record["description"] = organization.organizationDescription
        record["type"] = organization.organizationType.rawValue
        record["ownerRecordID"] = organization.ownerRecordID
        record["createdAt"] = organization.createdAt
        record["modifiedAt"] = organization.modifiedAt

        // Save to CloudKit
        let savedRecord = try await database.save(record)
        organization.cloudKitRecordName = savedRecord.recordID.recordName
        organization.isCloudSynced = true
    }

    // MARK: - Fetch Organizations

    func fetchUserOrganizations(
        userRecordID: String,
        modelContext: ModelContext
    ) async throws -> [Organization] {
        // For now, fetch from local SwiftData
        // TODO: Implement CloudKit query for shared organizations

        let descriptor = FetchDescriptor<Organization>()
        let organizations = try modelContext.fetch(descriptor)

        // Filter to organizations user has access to
        let userOrgs = organizations.filter { org in
            org.ownerRecordID == userRecordID ||
            org.member(for: userRecordID) != nil
        }

        await MainActor.run {
            self.userOrganizations = userOrgs
        }

        return userOrgs
    }

    // MARK: - Utility

    func generateInvitationToken() -> String {
        return UUID().uuidString
    }

    func validateInvitationToken(_ token: String, for organization: Organization) -> OrganizationMember? {
        return organization.members?.first { $0.invitationToken == token }
    }
}

// MARK: - Organization Error

enum OrganizationError: LocalizedError {
    case seatLimitReached
    case memberAlreadyExists
    case memberNotFound
    case cannotRemoveOwner
    case cannotChangeOwnerRole
    case insufficientPermissions
    case invalidSettings(String)
    case syncFailed(Error)

    var errorDescription: String? {
        switch self {
        case .seatLimitReached:
            return "Organization has reached its member limit. Upgrade your plan to add more members."
        case .memberAlreadyExists:
            return "This user is already a member of the organization."
        case .memberNotFound:
            return "Member not found in this organization."
        case .cannotRemoveOwner:
            return "Cannot remove the organization owner. Transfer ownership first."
        case .cannotChangeOwnerRole:
            return "Cannot change the owner's role. Transfer ownership first."
        case .insufficientPermissions:
            return "You don't have permission to perform this action."
        case .invalidSettings(let message):
            return "Invalid settings: \(message)"
        case .syncFailed(let error):
            return "Failed to sync with iCloud: \(error.localizedDescription)"
        }
    }
}
