//
//  MemberActivity.swift
//  Lyra
//
//  Represents an activity performed by a member in a shared library
//

import Foundation
import SwiftData

/// Activity performed by a member in a shared library
@Model
final class MemberActivity {
    // MARK: - Identifiers

    var id: UUID
    var timestamp: Date

    // MARK: - User Information

    /// CloudKit user record ID
    var userRecordID: String

    /// User's display name
    var displayName: String?

    // MARK: - Activity Details

    var activityType: ActivityType
    var libraryID: UUID?
    var songID: UUID?
    var songTitle: String?

    /// Additional context for the activity
    var details: String?

    // MARK: - Activity Types

    enum ActivityType: String, Codable {
        case songCreated = "Created Song"
        case songEdited = "Edited Song"
        case songDeleted = "Deleted Song"
        case songViewed = "Viewed Song"
        case memberJoined = "Joined Library"
        case memberLeft = "Left Library"
        case permissionChanged = "Permission Changed"
        case librarySettingsChanged = "Library Settings Changed"
    }

    // MARK: - Initializer

    init(
        userRecordID: String,
        displayName: String?,
        activityType: ActivityType,
        libraryID: UUID? = nil,
        songID: UUID? = nil,
        songTitle: String? = nil,
        details: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.activityType = activityType
        self.libraryID = libraryID
        self.songID = songID
        self.songTitle = songTitle
        self.details = details
    }

    // MARK: - Computed Properties

    var displayText: String {
        let name = displayName ?? "Someone"
        let action = activityType.rawValue.lowercased()

        if let title = songTitle {
            return "\(name) \(action) '\(title)'"
        } else {
            return "\(name) \(action)"
        }
    }

    var icon: String {
        switch activityType {
        case .songCreated: return "plus.circle.fill"
        case .songEdited: return "pencil.circle.fill"
        case .songDeleted: return "trash.circle.fill"
        case .songViewed: return "eye.circle.fill"
        case .memberJoined: return "person.badge.plus.fill"
        case .memberLeft: return "person.badge.minus.fill"
        case .permissionChanged: return "lock.circle.fill"
        case .librarySettingsChanged: return "gearshape.circle.fill"
        }
    }

    var color: String {
        switch activityType {
        case .songCreated: return "green"
        case .songEdited: return "blue"
        case .songDeleted: return "red"
        case .songViewed: return "purple"
        case .memberJoined: return "green"
        case .memberLeft: return "orange"
        case .permissionChanged: return "yellow"
        case .librarySettingsChanged: return "gray"
        }
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
