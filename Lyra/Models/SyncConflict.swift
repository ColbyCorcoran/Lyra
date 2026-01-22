//
//  SyncConflict.swift
//  Lyra
//
//  Model representing sync conflicts that need user resolution
//

import Foundation
import SwiftData

/// Represents a sync conflict between local and remote versions
struct SyncConflict: Identifiable, Codable {
    let id: UUID = UUID()
    let conflictType: ConflictType
    let entityType: EntityType
    let entityID: UUID
    let localVersion: ConflictVersion
    let remoteVersion: ConflictVersion
    let detectedAt: Date
    var resolvedAt: Date?
    var resolution: ConflictResolution?

    enum ConflictType: String, Codable {
        case contentModification  // Both versions modified same content
        case deletion             // One version deleted, other modified
        case propertyConflict     // Specific properties differ
        case attachmentConflict   // Attachment differences
    }

    enum EntityType: String, Codable {
        case song
        case book
        case performanceSet
        case annotation
        case attachment
    }

    enum ConflictResolution: String, Codable {
        case keepLocal           // Keep local version
        case keepRemote          // Keep remote version
        case keepBoth            // Keep both as separate entities
        case merge               // Merge both versions
        case skipForNow          // User will decide later
    }

    var isResolved: Bool {
        resolution != nil && resolution != .skipForNow
    }

    var priority: ConflictPriority {
        switch conflictType {
        case .deletion:
            return .high
        case .contentModification:
            return .medium
        case .propertyConflict:
            return .low
        case .attachmentConflict:
            return .low
        }
    }

    enum ConflictPriority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2

        static func < (lhs: ConflictPriority, rhs: ConflictPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

/// Represents a version in a conflict (local or remote)
struct ConflictVersion: Codable, Hashable {
    let timestamp: Date
    let deviceName: String
    let data: ConflictData

    struct ConflictData: Codable, Hashable {
        // Song-specific data
        var title: String?
        var artist: String?
        var content: String?
        var key: String?

        // Book-specific data
        var bookName: String?
        var bookDescription: String?

        // Set-specific data
        var setName: String?
        var setOrder: [UUID]?

        // Common metadata
        var lastModified: Date?
        var modifiedBy: String?
        var tags: [String]?

        // Deletion flag
        var isDeleted: Bool = false

        // Changed properties
        var changedProperties: [String] = []
    }
}

// MARK: - Conflict Detection Helpers

extension SyncConflict {
    /// Determines if this is a simple conflict that can use last-write-wins
    var canUseLastWriteWins: Bool {
        // Simple conflicts: property changes without deletion
        switch conflictType {
        case .propertyConflict:
            return !localVersion.data.isDeleted && !remoteVersion.data.isDeleted
        case .attachmentConflict:
            return !localVersion.data.isDeleted && !remoteVersion.data.isDeleted
        default:
            return false
        }
    }

    /// Automatically resolves simple conflicts using last-write-wins
    func autoResolve() -> ConflictResolution {
        guard canUseLastWriteWins else { return .skipForNow }

        // Use last-write-wins: most recent version wins
        if localVersion.timestamp > remoteVersion.timestamp {
            return .keepLocal
        } else {
            return .keepRemote
        }
    }

    /// Determines if this conflict requires user input
    var requiresUserInput: Bool {
        switch conflictType {
        case .contentModification:
            // Content changes always require user review
            return true
        case .deletion:
            // Deletion conflicts always require user choice
            return true
        case .propertyConflict:
            // Property conflicts can auto-resolve if not critical
            let criticalProps = ["title", "content", "bookName", "setName"]
            let hasConflictingCriticalProps = localVersion.data.changedProperties.contains { prop in
                criticalProps.contains(prop) && remoteVersion.data.changedProperties.contains(prop)
            }
            return hasConflictingCriticalProps
        case .attachmentConflict:
            // Attachment conflicts usually don't need user input
            return false
        }
    }
}

// MARK: - Conflict Summary

extension SyncConflict {
    /// Human-readable summary of the conflict
    var summary: String {
        switch conflictType {
        case .contentModification:
            return "Song content modified on both devices"
        case .deletion:
            if localVersion.data.isDeleted {
                return "Deleted locally, but modified remotely"
            } else {
                return "Modified locally, but deleted remotely"
            }
        case .propertyConflict:
            let props = Set(localVersion.data.changedProperties)
                .intersection(Set(remoteVersion.data.changedProperties))
            return "Properties changed: \(props.joined(separator: ", "))"
        case .attachmentConflict:
            return "Attachment differences detected"
        }
    }

    /// Detailed description for user
    var detailedDescription: String {
        var description = summary + "\n\n"

        description += "Local version (modified \(localVersion.timestamp.formatted(.relative(presentation: .named)))):\n"
        description += "Device: \(localVersion.deviceName)\n"

        if let title = localVersion.data.title {
            description += "Title: \(title)\n"
        }

        description += "\nRemote version (modified \(remoteVersion.timestamp.formatted(.relative(presentation: .named)))):\n"
        description += "Device: \(remoteVersion.deviceName)\n"

        if let title = remoteVersion.data.title {
            description += "Title: \(title)\n"
        }

        return description
    }
}
