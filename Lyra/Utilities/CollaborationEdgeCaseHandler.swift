//
//  CollaborationEdgeCaseHandler.swift
//  Lyra
//
//  Handles edge cases, race conditions, and permission validation in collaboration
//

import Foundation
import SwiftData
import CloudKit

// MARK: - Collaboration Edge Case Handler

@MainActor
class CollaborationEdgeCaseHandler {
    static let shared = CollaborationEdgeCaseHandler()

    // MARK: - State

    private var activeEditors: [UUID: Set<String>] = [:] // entityID -> set of userRecordIDs
    private var entityLocks: [UUID: EntityLock] = [:]
    private var permissionCache: [String: LibraryPermission] = [:]
    private var cacheExpiration: [String: Date] = [:]

    private init() {
        setupNotifications()
    }

    // MARK: - Setup

    private func setupNotifications() {
        // Listen for library deletion
        NotificationCenter.default.addObserver(
            forName: .libraryDeleted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let libraryID = notification.userInfo?["libraryID"] as? UUID else { return }
            self?.handleLibraryDeleted(libraryID)
        }

        // Listen for user removal
        NotificationCenter.default.addObserver(
            forName: .userRemovedFromLibrary,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userID = notification.userInfo?["userRecordID"] as? String,
                  let libraryID = notification.userInfo?["libraryID"] as? UUID else { return }
            self?.handleUserRemoved(userID: userID, from: libraryID)
        }
    }

    // MARK: - Permission Validation

    /// Validates user permission before allowing action
    func validatePermission(
        userRecordID: String,
        library: SharedLibrary,
        requiredPermission: LibraryPermission
    ) async -> PermissionValidationResult {
        // Check permission cache first
        let cacheKey = "\(userRecordID):\(library.id)"

        if let cachedPermission = getCachedPermission(for: cacheKey),
           cachedPermission >= requiredPermission {
            return .allowed
        }

        // Fetch fresh permission from CloudKit
        guard let currentPermission = await fetchFreshPermission(
            userRecordID: userRecordID,
            library: library
        ) else {
            return .denied(reason: "Unable to verify permissions")
        }

        // Cache the permission
        cachePermission(currentPermission, for: cacheKey)

        // Validate
        if currentPermission >= requiredPermission {
            return .allowed
        } else {
            return .denied(reason: "You need \(requiredPermission.rawValue) permission for this action")
        }
    }

    /// Validates multiple permissions atomically
    func validateBulkPermissions(
        userRecordID: String,
        operations: [(library: SharedLibrary, permission: LibraryPermission)]
    ) async -> BulkPermissionResult {
        var deniedOperations: [(SharedLibrary, String)] = []

        for (library, requiredPermission) in operations {
            let result = await validatePermission(
                userRecordID: userRecordID,
                library: library,
                requiredPermission: requiredPermission
            )

            if case .denied(let reason) = result {
                deniedOperations.append((library, reason))
            }
        }

        if deniedOperations.isEmpty {
            return .allAllowed
        } else {
            return .partiallyDenied(deniedOperations)
        }
    }

    private func fetchFreshPermission(userRecordID: String, library: SharedLibrary) async -> LibraryPermission? {
        // In production, query CloudKit share for current permission
        // For now, use library's local permission
        return library.currentUserPermission(userRecordID: userRecordID)
    }

    private func getCachedPermission(for key: String) -> LibraryPermission? {
        guard let expiration = cacheExpiration[key],
              Date() < expiration else {
            // Cache expired
            permissionCache.removeValue(forKey: key)
            cacheExpiration.removeValue(forKey: key)
            return nil
        }

        return permissionCache[key]
    }

    private func cachePermission(_ permission: LibraryPermission, for key: String) {
        permissionCache[key] = permission
        cacheExpiration[key] = Date().addingTimeInterval(300) // 5 minute cache
    }

    // MARK: - Concurrent Edit Detection

    /// Registers user as actively editing an entity
    func registerEditor(userRecordID: String, for entityID: UUID) {
        if activeEditors[entityID] == nil {
            activeEditors[entityID] = []
        }
        activeEditors[entityID]?.insert(userRecordID)

        // Notify other editors
        notifyOtherEditors(entityID: entityID, newEditor: userRecordID)
    }

    /// Unregisters user from editing an entity
    func unregisterEditor(userRecordID: String, from entityID: UUID) {
        activeEditors[entityID]?.remove(userRecordID)

        if activeEditors[entityID]?.isEmpty == true {
            activeEditors.removeValue(forKey: entityID)
        }

        // Notify other editors
        notifyEditingEnded(entityID: entityID, editor: userRecordID)
    }

    /// Checks if multiple users are editing the same entity
    func detectConcurrentEdits(for entityID: UUID) -> [String] {
        Array(activeEditors[entityID] ?? [])
    }

    /// Attempts to acquire exclusive lock on entity
    func acquireLock(for entityID: UUID, userRecordID: String) async -> LockResult {
        // Check if entity is already locked
        if let existingLock = entityLocks[entityID] {
            if existingLock.holderID == userRecordID {
                // User already holds the lock - extend it
                entityLocks[entityID] = EntityLock(
                    entityID: entityID,
                    holderID: userRecordID,
                    acquiredAt: existingLock.acquiredAt,
                    expiresAt: Date().addingTimeInterval(300) // Extend by 5 minutes
                )
                return .acquired
            } else if existingLock.isExpired {
                // Lock expired - take it
                entityLocks[entityID] = EntityLock(
                    entityID: entityID,
                    holderID: userRecordID,
                    acquiredAt: Date(),
                    expiresAt: Date().addingTimeInterval(300)
                )
                return .acquired
            } else {
                // Locked by another user
                return .denied(holder: existingLock.holderName ?? "Another user")
            }
        } else {
            // No existing lock - acquire it
            entityLocks[entityID] = EntityLock(
                entityID: entityID,
                holderID: userRecordID,
                acquiredAt: Date(),
                expiresAt: Date().addingTimeInterval(300)
            )
            return .acquired
        }
    }

    /// Releases lock on entity
    func releaseLock(for entityID: UUID, userRecordID: String) {
        if let lock = entityLocks[entityID], lock.holderID == userRecordID {
            entityLocks.removeValue(forKey: entityID)

            // Notify waiting users
            NotificationCenter.default.post(
                name: .lockReleased,
                object: nil,
                userInfo: ["entityID": entityID]
            )
        }
    }

    // MARK: - Deletion Handling

    /// Handles when library is deleted while user is viewing/editing
    func handleLibraryDeleted(_ libraryID: UUID) {
        print("⚠️ Library \(libraryID) was deleted")

        // Clear all locks for entities in this library
        entityLocks = entityLocks.filter { $0.value.entityID != libraryID }

        // Clear active editors
        // (In production, would need to map entities to libraries)

        // Notify UI to close library views
        NotificationCenter.default.post(
            name: .shouldCloseLibrary,
            object: nil,
            userInfo: ["libraryID": libraryID]
        )
    }

    /// Handles when user is removed from library
    func handleUserRemoved(userID: String, from libraryID: UUID) {
        print("⚠️ User \(userID) removed from library \(libraryID)")

        // Release all locks held by this user
        for (entityID, lock) in entityLocks where lock.holderID == userID {
            entityLocks.removeValue(forKey: entityID)
        }

        // Remove from active editors
        for (entityID, editors) in activeEditors {
            var updatedEditors = editors
            updatedEditors.remove(userID)
            activeEditors[entityID] = updatedEditors
        }

        // Clear permission cache
        let cacheKeys = permissionCache.keys.filter { $0.hasPrefix(userID) }
        for key in cacheKeys {
            permissionCache.removeValue(forKey: key)
            cacheExpiration.removeValue(forKey: key)
        }

        // Notify UI
        NotificationCenter.default.post(
            name: .userPermissionsChanged,
            object: nil,
            userInfo: ["userRecordID": userID, "libraryID": libraryID]
        )
    }

    // MARK: - Conflict Prevention

    /// Checks if operation would cause conflict
    func wouldCauseConflict(
        entityID: UUID,
        proposedChange: String,
        userRecordID: String
    ) async -> ConflictPrediction {
        // Check if others are editing
        let otherEditors = detectConcurrentEdits(for: entityID).filter { $0 != userRecordID }

        if otherEditors.isEmpty {
            return .safe
        }

        // Check if there's a lock
        if let lock = entityLocks[entityID], lock.holderID != userRecordID {
            return .conflict(reason: "Entity is locked by \(lock.holderName ?? "another user")")
        }

        // Predict based on edit patterns
        if otherEditors.count > 2 {
            return .highRisk(editors: otherEditors)
        } else if otherEditors.count > 0 {
            return .mediumRisk(editors: otherEditors)
        }

        return .safe
    }

    /// Merges concurrent edits safely
    func mergeConcurrentEdits(
        base: String,
        local: String,
        remote: String
    ) -> MergeResult {
        // Use three-way merge algorithm
        let baseLines = base.components(separatedBy: .newlines)
        let localLines = local.components(separatedBy: .newlines)
        let remoteLines = remote.components(separatedBy: .newlines)

        var mergedLines: [String] = []
        var conflicts: [MergeConflict] = []

        let maxLength = max(baseLines.count, localLines.count, remoteLines.count)

        for i in 0..<maxLength {
            let baseLine = i < baseLines.count ? baseLines[i] : ""
            let localLine = i < localLines.count ? localLines[i] : ""
            let remoteLine = i < remoteLines.count ? remoteLines[i] : ""

            if localLine == remoteLine {
                // Both made same change - use either
                mergedLines.append(localLine)
            } else if localLine == baseLine {
                // Only remote changed - use remote
                mergedLines.append(remoteLine)
            } else if remoteLine == baseLine {
                // Only local changed - use local
                mergedLines.append(localLine)
            } else {
                // Both changed differently - conflict
                conflicts.append(MergeConflict(
                    lineNumber: i,
                    base: baseLine,
                    local: localLine,
                    remote: remoteLine
                ))

                // For now, prefer local (will need manual resolution)
                mergedLines.append(localLine)
            }
        }

        if conflicts.isEmpty {
            return .success(merged: mergedLines.joined(separator: "\n"))
        } else {
            return .conflicted(
                merged: mergedLines.joined(separator: "\n"),
                conflicts: conflicts
            )
        }
    }

    // MARK: - Presence Management

    /// Updates user's presence status
    func updatePresence(
        userRecordID: String,
        status: PresenceStatus,
        currentSong: UUID? = nil
    ) {
        let presence = UserPresence(
            userRecordID: userRecordID,
            status: status,
            currentSongID: currentSong,
            lastUpdateAt: Date()
        )

        // Broadcast to CloudKit
        Task {
            await broadcastPresence(presence)
        }
    }

    private func broadcastPresence(_ presence: UserPresence) async {
        // In production, save to CloudKit with short TTL
        print("📡 Broadcasting presence for \(presence.userRecordID)")
    }

    // MARK: - Notifications

    private func notifyOtherEditors(entityID: UUID, newEditor: String) {
        NotificationCenter.default.post(
            name: .editorJoined,
            object: nil,
            userInfo: ["entityID": entityID, "editorID": newEditor]
        )
    }

    private func notifyEditingEnded(entityID: UUID, editor: String) {
        NotificationCenter.default.post(
            name: .editorLeft,
            object: nil,
            userInfo: ["entityID": entityID, "editorID": editor]
        )
    }
}

// MARK: - Permission Validation Result

enum PermissionValidationResult {
    case allowed
    case denied(reason: String)
}

enum BulkPermissionResult {
    case allAllowed
    case partiallyDenied([(SharedLibrary, String)])
}

// MARK: - Lock Result

enum LockResult {
    case acquired
    case denied(holder: String)
}

// MARK: - Entity Lock

struct EntityLock {
    let entityID: UUID
    let holderID: String
    var holderName: String?
    let acquiredAt: Date
    var expiresAt: Date

    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - Conflict Prediction

enum ConflictPrediction {
    case safe
    case mediumRisk(editors: [String])
    case highRisk(editors: [String])
    case conflict(reason: String)

    var shouldWarn: Bool {
        switch self {
        case .safe:
            return false
        case .mediumRisk, .highRisk, .conflict:
            return true
        }
    }

    var warningMessage: String {
        switch self {
        case .safe:
            return ""
        case .mediumRisk(let editors):
            return "\(editors.count) other user\(editors.count == 1 ? " is" : "s are") editing this"
        case .highRisk(let editors):
            return "Warning: \(editors.count) users are editing - high conflict risk"
        case .conflict(let reason):
            return reason
        }
    }
}

// MARK: - Merge Result

enum MergeResult {
    case success(merged: String)
    case conflicted(merged: String, conflicts: [MergeConflict])
}

struct MergeConflict {
    let lineNumber: Int
    let base: String
    let local: String
    let remote: String
}

// MARK: - User Presence

struct UserPresence {
    let userRecordID: String
    let status: PresenceStatus
    let currentSongID: UUID?
    let lastUpdateAt: Date
}

enum PresenceStatus: String, Codable {
    case online = "Online"
    case away = "Away"
    case editing = "Editing"
    case offline = "Offline"

    var icon: String {
        switch self {
        case .online: return "circle.fill"
        case .away: return "moon.fill"
        case .editing: return "pencil.circle.fill"
        case .offline: return "circle"
        }
    }

    var color: String {
        switch self {
        case .online: return "green"
        case .away: return "orange"
        case .editing: return "blue"
        case .offline: return "gray"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let libraryDeleted = Notification.Name("libraryDeleted")
    static let userRemovedFromLibrary = Notification.Name("userRemovedFromLibrary")
    static let shouldCloseLibrary = Notification.Name("shouldCloseLibrary")
    static let userPermissionsChanged = Notification.Name("userPermissionsChanged")
    static let editorJoined = Notification.Name("editorJoined")
    static let editorLeft = Notification.Name("editorLeft")
    static let lockReleased = Notification.Name("lockReleased")
}
