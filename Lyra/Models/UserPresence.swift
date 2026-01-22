//
//  UserPresence.swift
//  Lyra
//
//  Real-time presence tracking for collaboration awareness
//

import Foundation
import SwiftData
import CloudKit

/// Represents a user's current presence and activity in a shared library
@Model
final class UserPresence {
    // MARK: - Identifiers

    var id: UUID
    var timestamp: Date

    // MARK: - User Information

    /// CloudKit user record ID
    var userRecordID: String

    /// User's display name
    var displayName: String?

    /// User's avatar URL
    var avatarURL: String?

    /// User's assigned color for collaboration UI
    var colorHex: String

    // MARK: - Presence Status

    var status: PresenceStatus
    var lastSeenAt: Date
    var isOnline: Bool

    /// Device type (iPhone, iPad, Mac)
    var deviceType: String

    // MARK: - Current Activity

    /// Shared library the user is currently in
    var currentLibraryID: UUID?

    /// Song the user is currently viewing
    var currentSongID: UUID?

    /// Whether user is actively editing (vs just viewing)
    var isEditing: Bool

    /// Cursor position in content (for live editing indicators)
    var cursorPosition: Int?

    /// Selected text range (for live editing indicators)
    var selectionStart: Int?
    var selectionEnd: Int?

    // MARK: - Activity Type

    var currentActivity: ActivityType

    enum ActivityType: String, Codable {
        case viewing = "Viewing"
        case editing = "Editing"
        case idle = "Idle"
        case offline = "Offline"
    }

    enum PresenceStatus: String, Codable {
        case online = "Online"
        case away = "Away"
        case offline = "Offline"
        case doNotDisturb = "Do Not Disturb"
    }

    // MARK: - Initializer

    init(
        userRecordID: String,
        displayName: String? = nil,
        deviceType: String = "iPhone"
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.userRecordID = userRecordID
        self.displayName = displayName
        self.deviceType = deviceType
        self.status = .offline
        self.lastSeenAt = Date()
        self.isOnline = false
        self.isEditing = false
        self.currentActivity = .offline
        self.colorHex = Self.randomColor()
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        let thirtySecondsAgo = Date().addingTimeInterval(-30)
        return lastSeenAt > thirtySecondsAgo && isOnline
    }

    var isRecentlyActive: Bool {
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        return lastSeenAt > fiveMinutesAgo
    }

    var displayNameOrDefault: String {
        displayName ?? "Anonymous User"
    }

    var activityDescription: String {
        switch currentActivity {
        case .viewing:
            return "Viewing"
        case .editing:
            return "Editing"
        case .idle:
            return "Active"
        case .offline:
            return "Offline"
        }
    }

    var statusIcon: String {
        switch status {
        case .online: return "circle.fill"
        case .away: return "moon.fill"
        case .offline: return "circle"
        case .doNotDisturb: return "moon.zzz.fill"
        }
    }

    var statusColor: String {
        switch status {
        case .online: return "green"
        case .away: return "yellow"
        case .offline: return "gray"
        case .doNotDisturb: return "red"
        }
    }

    // MARK: - Methods

    /// Updates presence to indicate user is online
    func markOnline() {
        isOnline = true
        status = .online
        lastSeenAt = Date()
        timestamp = Date()
    }

    /// Updates presence to indicate user is offline
    func markOffline() {
        isOnline = false
        status = .offline
        currentActivity = .offline
        isEditing = false
        currentSongID = nil
        cursorPosition = nil
        timestamp = Date()
    }

    /// Updates current activity
    func updateActivity(
        libraryID: UUID?,
        songID: UUID?,
        isEditing: Bool,
        cursorPosition: Int? = nil
    ) {
        self.currentLibraryID = libraryID
        self.currentSongID = songID
        self.isEditing = isEditing
        self.cursorPosition = cursorPosition

        if isEditing {
            self.currentActivity = .editing
        } else if songID != nil {
            self.currentActivity = .viewing
        } else {
            self.currentActivity = .idle
        }

        self.lastSeenAt = Date()
        self.timestamp = Date()
    }

    /// Updates cursor position for live editing
    func updateCursor(position: Int, selectionStart: Int? = nil, selectionEnd: Int? = nil) {
        self.cursorPosition = position
        self.selectionStart = selectionStart
        self.selectionEnd = selectionEnd
        self.lastSeenAt = Date()
        self.timestamp = Date()
    }

    /// Marks user as away (inactive for a while)
    func markAway() {
        status = .away
        currentActivity = .idle
        timestamp = Date()
    }

    // MARK: - CloudKit Conversion

    /// Converts to CloudKit record for syncing
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "UserPresence")
        record["userRecordID"] = userRecordID as CKRecordValue
        record["displayName"] = displayName as? CKRecordValue
        record["colorHex"] = colorHex as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["lastSeenAt"] = lastSeenAt as CKRecordValue
        record["isOnline"] = isOnline ? 1 : 0 as CKRecordValue
        record["deviceType"] = deviceType as CKRecordValue
        record["currentActivity"] = currentActivity.rawValue as CKRecordValue
        record["isEditing"] = isEditing ? 1 : 0 as CKRecordValue

        if let libraryID = currentLibraryID {
            record["currentLibraryID"] = libraryID.uuidString as CKRecordValue
        }

        if let songID = currentSongID {
            record["currentSongID"] = songID.uuidString as CKRecordValue
        }

        if let cursor = cursorPosition {
            record["cursorPosition"] = cursor as CKRecordValue
        }

        return record
    }

    /// Creates from CloudKit record
    static func fromCKRecord(_ record: CKRecord) -> UserPresence? {
        guard let userRecordID = record["userRecordID"] as? String else {
            return nil
        }

        let presence = UserPresence(
            userRecordID: userRecordID,
            displayName: record["displayName"] as? String,
            deviceType: record["deviceType"] as? String ?? "iPhone"
        )

        if let colorHex = record["colorHex"] as? String {
            presence.colorHex = colorHex
        }

        if let statusRaw = record["status"] as? String,
           let status = PresenceStatus(rawValue: statusRaw) {
            presence.status = status
        }

        if let lastSeen = record["lastSeenAt"] as? Date {
            presence.lastSeenAt = lastSeen
        }

        presence.isOnline = (record["isOnline"] as? Int) == 1

        if let activityRaw = record["currentActivity"] as? String,
           let activity = ActivityType(rawValue: activityRaw) {
            presence.currentActivity = activity
        }

        presence.isEditing = (record["isEditing"] as? Int) == 1

        if let libraryIDString = record["currentLibraryID"] as? String,
           let libraryID = UUID(uuidString: libraryIDString) {
            presence.currentLibraryID = libraryID
        }

        if let songIDString = record["currentSongID"] as? String,
           let songID = UUID(uuidString: songIDString) {
            presence.currentSongID = songID
        }

        if let cursor = record["cursorPosition"] as? Int {
            presence.cursorPosition = cursor
        }

        return presence
    }

    // MARK: - Color Generation

    private static func randomColor() -> String {
        let colors = [
            "#FF6B6B", // Red
            "#4ECDC4", // Teal
            "#45B7D1", // Blue
            "#FFA07A", // Orange
            "#98D8C8", // Mint
            "#F7DC6F", // Yellow
            "#BB8FCE", // Purple
            "#85C1E2", // Sky Blue
            "#F8B195", // Peach
            "#6C5CE7"  // Indigo
        ]
        return colors.randomElement() ?? "#4ECDC4"
    }
}

// MARK: - Presence Event

/// Represents a presence change event for real-time updates
struct PresenceEvent: Codable, Identifiable {
    let id: UUID
    let userRecordID: String
    let displayName: String?
    let eventType: EventType
    let libraryID: UUID?
    let songID: UUID?
    let timestamp: Date

    enum EventType: String, Codable {
        case userJoined = "Joined"
        case userLeft = "Left"
        case startedEditing = "Started Editing"
        case stoppedEditing = "Stopped Editing"
        case changedSong = "Changed Song"
        case wentOffline = "Went Offline"
        case cameOnline = "Came Online"
    }

    var displayText: String {
        let name = displayName ?? "Someone"
        return "\(name) \(eventType.rawValue.lowercased())"
    }

    var icon: String {
        switch eventType {
        case .userJoined, .cameOnline: return "person.badge.plus"
        case .userLeft, .wentOffline: return "person.badge.minus"
        case .startedEditing: return "pencil.circle"
        case .stoppedEditing: return "eye.circle"
        case .changedSong: return "music.note"
        }
    }
}
