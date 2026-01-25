//
//  CollaborationNotificationManager.swift
//  Lyra
//
//  Manages notifications for collaborative events
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
@Observable
class CollaborationNotificationManager {
    static let shared = CollaborationNotificationManager()

    // MARK: - Published Properties

    var pendingNotifications: [CollaborationNotification] = []
    var notificationSettings: NotificationSettings

    // MARK: - Private Properties

    private var subscriptions: Set<AnyCancellable> = []
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private init() {
        self.notificationSettings = NotificationSettings.load()
        setupNotificationObservers()
        requestNotificationPermissions()
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        // Listen for activity feed changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivityAdded),
            name: .memberActivityAdded,
            object: nil
        )

        // Listen for presence changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePresenceChange),
            name: .presenceDidChange,
            object: nil
        )
    }

    private func requestNotificationPermissions() {
        Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(
                    options: [.alert, .sound, .badge]
                )

                if granted {
                    print("✅ Notification permissions granted")
                } else {
                    print("⚠️ Notification permissions denied")
                }
            } catch {
                print("❌ Error requesting notification permissions: \(error)")
            }
        }
    }

    // MARK: - Notification Handling

    @objc private func handleActivityAdded(_ notification: Notification) {
        guard let activity = notification.userInfo?["activity"] as? MemberActivity else { return }

        // Check if we should notify for this activity
        if shouldNotify(for: activity) {
            sendNotification(for: activity)
        }
    }

    @objc private func handlePresenceChange(_ notification: Notification) {
        guard let presence = notification.userInfo?["presence"] as? UserPresence else { return }

        // Notify for editing events if enabled
        if notificationSettings.notifyOnEditing && presence.isEditing {
            sendEditingNotification(for: presence)
        }
    }

    // MARK: - Notification Logic

    private func shouldNotify(for activity: MemberActivity) -> Bool {
        // Don't notify if notifications are disabled
        guard notificationSettings.enabled else { return false }

        // Check if library is muted
        // This would need library ID from activity
        // if notificationSettings.mutedLibraries.contains(activity.libraryID) {
        //     return false
        // }

        // Check frequency settings
        switch notificationSettings.frequency {
        case .realTime:
            return true
        case .batched:
            // Would implement batching logic here
            return shouldSendBatchedNotification()
        case .digest:
            return false // Digest notifications sent on schedule
        case .off:
            return false
        }
    }

    private func shouldSendBatchedNotification() -> Bool {
        // Send notification every 5 minutes max
        // Implementation would track last notification time
        return true
    }

    // MARK: - Send Notifications

    private func sendNotification(for activity: MemberActivity) {
        let notification = CollaborationNotification(
            id: UUID(),
            type: .activityUpdate,
            title: activity.activityType.rawValue,
            body: activity.displayText,
            timestamp: activity.timestamp,
            relatedActivityID: activity.id,
            relatedSongID: activity.songID,
            relatedLibraryID: activity.libraryID
        )

        // Add to pending notifications for in-app display
        pendingNotifications.insert(notification, at: 0)

        // Keep only last 20 notifications
        if pendingNotifications.count > 20 {
            pendingNotifications = Array(pendingNotifications.prefix(20))
        }

        // Send push notification if app in background
        sendPushNotification(notification)
    }

    private func sendEditingNotification(for presence: UserPresence) {
        guard let songID = presence.currentSongID else { return }

        let notification = CollaborationNotification(
            id: UUID(),
            type: .userEditing,
            title: "Someone is editing",
            body: "\(presence.displayNameOrDefault) is editing a song",
            timestamp: Date(),
            relatedPresenceUserID: presence.userRecordID,
            relatedSongID: songID,
            relatedLibraryID: presence.currentLibraryID
        )

        pendingNotifications.insert(notification, at: 0)

        // Send push notification
        sendPushNotification(notification)
    }

    func sendVersionRestoreNotification(
        songID: UUID,
        songTitle: String,
        versionNumber: Int,
        libraryID: UUID,
        restoredBy: String
    ) {
        let notification = CollaborationNotification(
            id: UUID(),
            type: .versionRestored,
            title: "Version Restored",
            body: "\(restoredBy) restored \"\(songTitle)\" to version \(versionNumber)",
            timestamp: Date(),
            relatedSongID: songID,
            relatedLibraryID: libraryID
        )

        pendingNotifications.insert(notification, at: 0)

        // Keep only last 20 notifications
        if pendingNotifications.count > 20 {
            pendingNotifications = Array(pendingNotifications.prefix(20))
        }

        // Send push notification
        Task {
            await sendPushNotification(notification)
        }
    }

    func sendPushNotification(_ notification: CollaborationNotification) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default

        // Add category for actions
        content.categoryIdentifier = "COLLABORATION_NOTIFICATION"

        // Add user info for handling tap
        content.userInfo = [
            "notificationID": notification.id.uuidString,
            "type": notification.type.rawValue
        ]

        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("❌ Error sending notification: \(error)")
        }
    }

    // MARK: - In-App Banners

    func showInAppBanner(for notification: CollaborationNotification) {
        // Post notification to show banner
        NotificationCenter.default.post(
            name: .showCollaborationBanner,
            object: nil,
            userInfo: ["notification": notification]
        )
    }

    // MARK: - Notification Management

    func dismissNotification(_ notification: CollaborationNotification) {
        pendingNotifications.removeAll { $0.id == notification.id }

        // Remove from notification center
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: [notification.id.uuidString]
        )
    }

    func dismissAllNotifications() {
        pendingNotifications.removeAll()
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Settings

    func updateSettings(_ settings: NotificationSettings) {
        self.notificationSettings = settings
        settings.save()
    }

    func muteLibrary(_ libraryID: UUID) {
        notificationSettings.mutedLibraries.insert(libraryID)
        notificationSettings.save()
    }

    func unmuteLibrary(_ libraryID: UUID) {
        notificationSettings.mutedLibraries.remove(libraryID)
        notificationSettings.save()
    }
}

// MARK: - Collaboration Notification

struct CollaborationNotification: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    let title: String
    let body: String
    let timestamp: Date
    var isRead: Bool = false

    // Optional related data IDs (store IDs instead of full objects for Codable)
    var relatedActivityID: UUID?
    var relatedPresenceUserID: String?
    var relatedSongID: UUID?
    var relatedLibraryID: UUID?

    enum NotificationType: String, Codable {
        case activityUpdate = "Activity Update"
        case userEditing = "User Editing"
        case userJoined = "User Joined"
        case songChanged = "Song Changed"
        case commentAdded = "Comment Added"
        case mentionedYou = "Mentioned You"
        case versionRestored = "Version Restored"
    }

    var icon: String {
        switch type {
        case .activityUpdate: return "bell.fill"
        case .userEditing: return "pencil.circle.fill"
        case .userJoined: return "person.badge.plus.fill"
        case .songChanged: return "music.note"
        case .commentAdded: return "bubble.left.fill"
        case .mentionedYou: return "at.circle.fill"
        case .versionRestored: return "clock.arrow.circlepath"
        }
    }

    var color: String {
        switch type {
        case .activityUpdate: return "blue"
        case .userEditing: return "orange"
        case .userJoined: return "green"
        case .songChanged: return "purple"
        case .commentAdded: return "teal"
        case .mentionedYou: return "red"
        case .versionRestored: return "indigo"
        }
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var enabled: Bool = true
    var frequency: NotificationFrequency = .realTime
    var notifyOnEditing: Bool = true
    var notifyOnChanges: Bool = true
    var notifyOnJoins: Bool = false
    var notifyOnComments: Bool = true
    var mutedLibraries: Set<UUID> = []
    var soundEnabled: Bool = true
    var badgeEnabled: Bool = true

    enum NotificationFrequency: String, Codable, CaseIterable {
        case realTime = "Real-time"
        case batched = "Batched (every 5 min)"
        case digest = "Daily Digest"
        case off = "Off"
    }

    // MARK: - Persistence

    private static let storageKey = "collaboration.notificationSettings"

    static func load() -> NotificationSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return NotificationSettings()
        }
        return settings
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
    }
}

// MARK: - Notification Actions

extension CollaborationNotificationManager {
    /// Sets up notification action categories
    func setupNotificationActions() {
        // Define actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: .destructive
        )

        // Define category
        let category = UNNotificationCategory(
            identifier: "COLLABORATION_NOTIFICATION",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([category])
    }

    /// Handles notification action
    func handleNotificationAction(response: UNNotificationResponse) {
        let notificationID = response.notification.request.identifier

        switch response.actionIdentifier {
        case "VIEW_ACTION":
            // Navigate to related content
            handleViewAction(notificationID: notificationID)

        case "DISMISS_ACTION", UNNotificationDismissActionIdentifier:
            // Just dismiss
            if let uuid = UUID(uuidString: notificationID),
               let notification = pendingNotifications.first(where: { $0.id == uuid }) {
                dismissNotification(notification)
            }

        default:
            break
        }
    }

    private func handleViewAction(notificationID: String) {
        // Find notification and navigate
        guard let uuid = UUID(uuidString: notificationID),
              let notification = pendingNotifications.first(where: { $0.id == uuid }) else {
            return
        }

        // Post navigation request
        NotificationCenter.default.post(
            name: .navigateToCollaborationItem,
            object: nil,
            userInfo: ["notification": notification]
        )

        // Mark as read
        if let index = pendingNotifications.firstIndex(where: { $0.id == uuid }) {
            pendingNotifications[index].isRead = true
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let showCollaborationBanner = Notification.Name("showCollaborationBanner")
    static let navigateToCollaborationItem = Notification.Name("navigateToCollaborationItem")
    static let memberActivityAdded = Notification.Name("memberActivityAdded")
}
