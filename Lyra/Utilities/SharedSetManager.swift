//
//  SharedSetManager.swift
//  Lyra
//
//  Manages shared performance sets with team collaboration
//

import Foundation
import SwiftData
import CloudKit

@MainActor
class SharedSetManager {
    static let shared = SharedSetManager()

    private init() {}

    // MARK: - Set Sharing

    /// Creates a shared performance set
    func createSharedSet(
        for performanceSet: PerformanceSet,
        modelContext: ModelContext,
        ownerRecordID: String,
        ownerDisplayName: String,
        defaultPermission: SetPermissionLevel = .viewer
    ) throws -> SharedPerformanceSet {
        // Check if already shared
        if performanceSet.isShared {
            throw SharedSetError.alreadyShared
        }

        // Create shared set
        let sharedSet = SharedPerformanceSet(
            performanceSet: performanceSet,
            ownerRecordID: ownerRecordID,
            ownerDisplayName: ownerDisplayName,
            defaultPermission: defaultPermission
        )

        modelContext.insert(sharedSet)

        // Initialize readiness for all songs
        if let entries = performanceSet.sortedSongEntries {
            for entry in entries {
                guard let song = entry.song else { continue }

                let readiness = SetSongReadiness(
                    songID: song.id,
                    setEntryID: entry.id
                )
                readiness.sharedSet = sharedSet
                modelContext.insert(readiness)
            }
        }

        try modelContext.save()

        // Post notification
        NotificationCenter.default.post(
            name: .setShared,
            object: nil,
            userInfo: ["setID": performanceSet.id]
        )

        return sharedSet
    }

    /// Stops sharing a performance set
    func stopSharing(
        _ sharedSet: SharedPerformanceSet,
        modelContext: ModelContext
    ) throws {
        modelContext.delete(sharedSet)
        try modelContext.save()

        NotificationCenter.default.post(
            name: .setSharingEnded,
            object: nil,
            userInfo: ["setID": sharedSet.performanceSet?.id ?? UUID()]
        )
    }

    // MARK: - Member Management

    /// Adds a member to a shared set
    func addMember(
        to sharedSet: SharedPerformanceSet,
        userRecordID: String,
        displayName: String,
        permission: SetPermissionLevel,
        modelContext: ModelContext
    ) throws {
        // Check if member already exists
        if sharedSet.members?.contains(where: { $0.userRecordID == userRecordID }) == true {
            throw SharedSetError.memberAlreadyExists
        }

        let member = SetMember(
            userRecordID: userRecordID,
            displayName: displayName,
            permission: permission
        )
        member.sharedSet = sharedSet
        modelContext.insert(member)

        try modelContext.save()

        // Notify team
        await notifyMemberAdded(
            sharedSet: sharedSet,
            memberName: displayName
        )
    }

    /// Updates member permission
    func updateMemberPermission(
        member: SetMember,
        newPermission: SetPermissionLevel,
        modelContext: ModelContext
    ) throws {
        member.permission = newPermission
        try modelContext.save()
    }

    /// Removes a member from a shared set
    func removeMember(
        _ member: SetMember,
        from sharedSet: SharedPerformanceSet,
        modelContext: ModelContext
    ) throws {
        sharedSet.removeMember(userRecordID: member.userRecordID)
        modelContext.delete(member)
        try modelContext.save()
    }

    // MARK: - Role Management

    /// Assigns a role to a member for a song
    func assignRole(
        to userRecordID: String,
        displayName: String,
        role: MemberRole,
        songID: UUID,
        setEntryID: UUID,
        sharedSet: SharedPerformanceSet,
        modelContext: ModelContext
    ) throws {
        let roleAssignment = SetMemberRole(
            userRecordID: userRecordID,
            displayName: displayName,
            songID: songID,
            setEntryID: setEntryID,
            role: role
        )
        roleAssignment.sharedSet = sharedSet
        modelContext.insert(roleAssignment)

        try modelContext.save()

        // Notify member of assignment
        await notifyRoleAssigned(
            memberName: displayName,
            role: role,
            sharedSet: sharedSet
        )
    }

    /// Removes a role assignment
    func removeRole(
        _ roleAssignment: SetMemberRole,
        modelContext: ModelContext
    ) throws {
        modelContext.delete(roleAssignment)
        try modelContext.save()
    }

    /// Gets roles for a specific song and user
    func getRoles(
        for userRecordID: String,
        songID: UUID,
        sharedSet: SharedPerformanceSet
    ) -> [SetMemberRole] {
        return sharedSet.roleAssignments?.filter {
            $0.userRecordID == userRecordID && $0.songID == songID
        } ?? []
    }

    /// Gets all songs assigned to a user
    func getAssignedSongs(
        for userRecordID: String,
        sharedSet: SharedPerformanceSet
    ) -> Set<UUID> {
        let roles = sharedSet.roleAssignments?.filter { $0.userRecordID == userRecordID } ?? []
        return Set(roles.map { $0.songID })
    }

    // MARK: - Readiness Management

    /// Updates song readiness
    func updateReadiness(
        songID: UUID,
        level: ReadinessLevel,
        userRecordID: String,
        displayName: String,
        sharedSet: SharedPerformanceSet,
        modelContext: ModelContext
    ) throws {
        guard let readiness = sharedSet.songReadiness?.first(where: { $0.songID == songID }) else {
            throw SharedSetError.readinessNotFound
        }

        readiness.updateReadiness(to: level, by: userRecordID, displayName: displayName)
        try modelContext.save()

        // Notify team
        await notifyReadinessUpdated(
            sharedSet: sharedSet,
            songID: songID,
            level: level,
            userName: displayName
        )
    }

    /// Updates member-specific readiness
    func updateMemberReadiness(
        songID: UUID,
        userRecordID: String,
        displayName: String,
        level: ReadinessLevel,
        confidence: Double,
        sharedSet: SharedPerformanceSet,
        modelContext: ModelContext
    ) throws {
        guard let songReadiness = sharedSet.songReadiness?.first(where: { $0.songID == songID }) else {
            throw SharedSetError.readinessNotFound
        }

        // Find or create member readiness
        var memberReadiness = songReadiness.memberReadiness?.first(where: { $0.userRecordID == userRecordID })

        if memberReadiness == nil {
            memberReadiness = MemberReadiness(
                userRecordID: userRecordID,
                displayName: displayName
            )
            memberReadiness?.songReadiness = songReadiness
            if let mr = memberReadiness {
                modelContext.insert(mr)
            }
        }

        memberReadiness?.updateReadiness(level: level, confidence: confidence)
        try modelContext.save()
    }

    // MARK: - Rehearsal Management

    /// Creates a rehearsal session
    func createRehearsal(
        date: Date,
        location: String?,
        sharedSet: SharedPerformanceSet,
        modelContext: ModelContext
    ) throws -> SetRehearsal {
        let rehearsal = SetRehearsal(
            rehearsalDate: date,
            location: location
        )
        rehearsal.sharedSet = sharedSet
        modelContext.insert(rehearsal)

        // Create attendance records for all members
        if let members = sharedSet.members {
            for member in members {
                let attendance = RehearsalAttendance(
                    userRecordID: member.userRecordID,
                    displayName: member.displayName
                )
                attendance.rehearsal = rehearsal
                modelContext.insert(attendance)
            }
        }

        try modelContext.save()

        // Notify team
        await notifyRehearsalScheduled(sharedSet: sharedSet, date: date, location: location)

        return rehearsal
    }

    /// Marks a song as rehearsed
    func markSongRehearsed(
        songID: UUID,
        rehearsal: SetRehearsal,
        modelContext: ModelContext
    ) throws {
        rehearsal.markSongRehearsed(songID)
        try modelContext.save()
    }

    /// Adds a note to a rehearsal
    func addRehearsalNote(
        songID: UUID,
        noteType: RehearsalNoteType,
        content: String,
        authorRecordID: String,
        authorDisplayName: String,
        rehearsal: SetRehearsal,
        modelContext: ModelContext
    ) throws {
        let note = RehearsalSongNote(
            songID: songID,
            authorRecordID: authorRecordID,
            authorDisplayName: authorDisplayName,
            noteType: noteType,
            content: content
        )
        note.rehearsal = rehearsal
        modelContext.insert(note)

        try modelContext.save()
    }

    // MARK: - Set Locking

    /// Locks a set for performance (no more edits)
    func lockSet(
        _ sharedSet: SharedPerformanceSet,
        by userRecordID: String,
        displayName: String,
        modelContext: ModelContext
    ) throws {
        guard sharedSet.hasPermission(userRecordID, level: .admin) else {
            throw SharedSetError.insufficientPermissions
        }

        sharedSet.lock(by: userRecordID, displayName: displayName)
        try modelContext.save()

        // Notify team
        await notifySetLocked(sharedSet: sharedSet, lockedBy: displayName)
    }

    /// Unlocks a set
    func unlockSet(
        _ sharedSet: SharedPerformanceSet,
        by userRecordID: String,
        modelContext: ModelContext
    ) throws {
        guard sharedSet.hasPermission(userRecordID, level: .admin) else {
            throw SharedSetError.insufficientPermissions
        }

        sharedSet.unlock()
        try modelContext.save()

        // Notify team
        await notifySetUnlocked(sharedSet: sharedSet)
    }

    // MARK: - Template Management

    /// Creates a template from a performance set
    func createTemplate(
        from performanceSet: PerformanceSet,
        name: String,
        description: String?,
        category: TemplateCategory,
        isPublic: Bool,
        createdBy: String,
        creatorDisplayName: String,
        modelContext: ModelContext
    ) throws -> SetTemplate {
        let template = SetTemplate(
            name: name,
            category: category,
            createdBy: createdBy,
            creatorDisplayName: creatorDisplayName
        )
        template.templateDescription = description
        template.isPublic = isPublic

        // Create sections based on set structure
        if let entries = performanceSet.sortedSongEntries {
            var currentSection: TemplateSection?
            var orderIndex = 0

            for (index, entry) in entries.enumerated() {
                // Simple approach: each song is its own slot
                let section = TemplateSection(
                    orderIndex: orderIndex,
                    sectionName: entry.song?.title ?? "Song \(index + 1)",
                    songSlotCount: 1
                )
                section.template = template
                modelContext.insert(section)
                orderIndex += 1
            }
        }

        modelContext.insert(template)
        try modelContext.save()

        return template
    }

    /// Applies a template to create a new performance set
    func applyTemplate(
        _ template: SetTemplate,
        name: String,
        modelContext: ModelContext
    ) throws -> PerformanceSet {
        let performanceSet = PerformanceSet(name: name)
        modelContext.insert(performanceSet)

        // Create empty entries based on template sections
        if let sections = template.sortedSections {
            var orderIndex = 0
            for section in sections {
                for _ in 0..<section.songSlotCount {
                    // Create placeholder entry (song will be assigned later)
                    let entry = SetEntry(song: Song(title: "Untitled"), orderIndex: orderIndex)
                    entry.performanceSet = performanceSet
                    modelContext.insert(entry)
                    orderIndex += 1
                }
            }
        }

        template.incrementUseCount()
        try modelContext.save()

        return performanceSet
    }

    // MARK: - Notifications

    private func notifyMemberAdded(sharedSet: SharedPerformanceSet, memberName: String) async {
        // Implementation for team notifications
    }

    private func notifyRoleAssigned(memberName: String, role: MemberRole, sharedSet: SharedPerformanceSet) async {
        // Implementation for role assignment notifications
    }

    private func notifyReadinessUpdated(sharedSet: SharedPerformanceSet, songID: UUID, level: ReadinessLevel, userName: String) async {
        // Implementation for readiness notifications
    }

    private func notifyRehearsalScheduled(sharedSet: SharedPerformanceSet, date: Date, location: String?) async {
        // Implementation for rehearsal notifications
    }

    private func notifySetLocked(sharedSet: SharedPerformanceSet, lockedBy: String) async {
        // Implementation for set locked notifications
    }

    private func notifySetUnlocked(sharedSet: SharedPerformanceSet) async {
        // Implementation for set unlocked notifications
    }
}

// MARK: - Errors

enum SharedSetError: LocalizedError {
    case alreadyShared
    case notShared
    case memberAlreadyExists
    case memberNotFound
    case readinessNotFound
    case insufficientPermissions
    case setLocked

    var errorDescription: String? {
        switch self {
        case .alreadyShared:
            return "This performance set is already shared"
        case .notShared:
            return "This performance set is not shared"
        case .memberAlreadyExists:
            return "This member is already part of the set"
        case .memberNotFound:
            return "Member not found"
        case .readinessNotFound:
            return "Readiness record not found for this song"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .setLocked:
            return "This set is locked for performance"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let setShared = Notification.Name("setShared")
    static let setSharingEnded = Notification.Name("setSharingEnded")
    static let setMemberAdded = Notification.Name("setMemberAdded")
    static let setMemberRemoved = Notification.Name("setMemberRemoved")
    static let setRoleAssigned = Notification.Name("setRoleAssigned")
    static let setReadinessUpdated = Notification.Name("setReadinessUpdated")
    static let setRehearsalScheduled = Notification.Name("setRehearsalScheduled")
    static let setLocked = Notification.Name("setLocked")
    static let setUnlocked = Notification.Name("setUnlocked")
}
