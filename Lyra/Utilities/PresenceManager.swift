//
//  PresenceManager.swift
//  Lyra
//
//  Manages real-time presence tracking and synchronization for collaboration
//

import Foundation
import SwiftData
import CloudKit
import Combine

@MainActor
@Observable
class PresenceManager {
    static let shared = PresenceManager()

    // MARK: - Published Properties

    var currentUserPresence: UserPresence?
    var activeUsers: [UserPresence] = []
    var presenceEvents: [PresenceEvent] = []

    // MARK: - Private Properties

    private let container = CKContainer.default()
    private lazy var sharedDatabase = container.sharedCloudDatabase
    private var presenceUpdateTimer: Timer?
    private var subscriptions: Set<AnyCancellable> = []
    private var currentUserRecordID: String?

    // Update frequency (30 seconds as requested)
    private let updateInterval: TimeInterval = 30.0

    private init() {
        setupPresenceTracking()
    }

    // MARK: - Setup

    private func setupPresenceTracking() {
        // Get current user record ID
        Task {
            do {
                let userRecordID = try await container.userRecordID()
                self.currentUserRecordID = userRecordID.recordName

                // Create initial presence
                await createInitialPresence()

                // Start periodic updates
                startPresenceUpdates()

                // Subscribe to presence changes
                await subscribeToPresenceChanges()
            } catch {
                print("❌ Error setting up presence: \(error)")
            }
        }

        // Handle app lifecycle
        setupLifecycleObservers()
    }

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    // MARK: - Presence Management

    private func createInitialPresence() async {
        guard let userRecordID = currentUserRecordID else { return }

        let deviceType: String
        #if os(iOS)
        deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        #elseif os(macOS)
        deviceType = "Mac"
        #else
        deviceType = "iOS"
        #endif

        currentUserPresence = UserPresence(
            userRecordID: userRecordID,
            displayName: await getCurrentUserDisplayName(),
            deviceType: deviceType
        )

        currentUserPresence?.markOnline()

        // Sync to CloudKit
        await syncPresenceToCloudKit()
    }

    private func getCurrentUserDisplayName() async -> String? {
        do {
            let userRecordID = try await container.userRecordID()
            let userIdentity = try await container.userIdentity(forUserRecordID: userRecordID)
            return userIdentity.nameComponents?.formatted()
        } catch {
            return nil
        }
    }

    /// Starts periodic presence updates
    private func startPresenceUpdates() {
        presenceUpdateTimer?.invalidate()

        presenceUpdateTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePresence()
            }
        }
    }

    /// Stops presence updates
    private func stopPresenceUpdates() {
        presenceUpdateTimer?.invalidate()
        presenceUpdateTimer = nil
    }

    /// Updates current user's presence
    func updatePresence(
        libraryID: UUID? = nil,
        songID: UUID? = nil,
        isEditing: Bool = false,
        cursorPosition: Int? = nil
    ) async {
        guard let presence = currentUserPresence else { return }

        presence.updateActivity(
            libraryID: libraryID,
            songID: songID,
            isEditing: isEditing,
            cursorPosition: cursorPosition
        )

        // Sync to CloudKit
        await syncPresenceToCloudKit()

        // Notify observers
        NotificationCenter.default.post(
            name: .presenceDidUpdate,
            object: nil,
            userInfo: ["presence": presence]
        )
    }

    /// Updates cursor position for live editing indicators
    func updateCursor(position: Int, selectionStart: Int? = nil, selectionEnd: Int? = nil) async {
        guard let presence = currentUserPresence else { return }

        presence.updateCursor(
            position: position,
            selectionStart: selectionStart,
            selectionEnd: selectionEnd
        )

        // Sync to CloudKit (throttled to avoid excessive updates)
        await syncPresenceToCloudKit(throttle: true)
    }

    /// Marks user as offline
    func markOffline() async {
        guard let presence = currentUserPresence else { return }

        presence.markOffline()

        // Sync to CloudKit
        await syncPresenceToCloudKit()

        // Stop updates
        stopPresenceUpdates()

        // Create presence event
        addPresenceEvent(.wentOffline, for: presence)
    }

    // MARK: - CloudKit Sync

    private var lastSyncTime: Date?
    private let throttleInterval: TimeInterval = 2.0 // Throttle cursor updates

    private func syncPresenceToCloudKit(throttle: Bool = false) async {
        guard let presence = currentUserPresence else { return }

        // Throttle if requested
        if throttle, let lastSync = lastSyncTime {
            let elapsed = Date().timeIntervalSince(lastSync)
            if elapsed < throttleInterval {
                return // Skip this update
            }
        }

        let record = presence.toCKRecord()

        do {
            _ = try await sharedDatabase.save(record)
            lastSyncTime = Date()
        } catch {
            print("❌ Error syncing presence: \(error)")
        }
    }

    /// Fetches active users in a shared library
    func fetchActiveUsers(in libraryID: UUID) async {
        let predicate = NSPredicate(
            format: "currentLibraryID == %@ AND isOnline == 1",
            libraryID.uuidString
        )

        let query = CKQuery(recordType: "UserPresence", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastSeenAt", ascending: false)]

        do {
            let results = try await sharedDatabase.records(matching: query)

            var users: [UserPresence] = []

            for (_, result) in results.matchResults {
                if let record = try? result.get(),
                   let presence = UserPresence.fromCKRecord(record) {
                    users.append(presence)
                }
            }

            // Filter out current user
            if let currentUserID = currentUserRecordID {
                users = users.filter { $0.userRecordID != currentUserID }
            }

            await MainActor.run {
                self.activeUsers = users
            }
        } catch {
            print("❌ Error fetching active users: \(error)")
        }
    }

    /// Fetches users editing a specific song
    func fetchEditorsForSong(_ songID: UUID) async -> [UserPresence] {
        let predicate = NSPredicate(
            format: "currentSongID == %@ AND isEditing == 1 AND isOnline == 1",
            songID.uuidString
        )

        let query = CKQuery(recordType: "UserPresence", predicate: predicate)

        do {
            let results = try await sharedDatabase.records(matching: query)

            var editors: [UserPresence] = []

            for (_, result) in results.matchResults {
                if let record = try? result.get(),
                   let presence = UserPresence.fromCKRecord(record),
                   presence.userRecordID != currentUserRecordID {
                    editors.append(presence)
                }
            }

            return editors
        } catch {
            print("❌ Error fetching editors: \(error)")
            return []
        }
    }

    // MARK: - Subscriptions

    private func subscribeToPresenceChanges() async {
        let subscription = CKQuerySubscription(
            recordType: "UserPresence",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            try await sharedDatabase.save(subscription)
        } catch {
            print("❌ Error subscribing to presence: \(error)")
        }
    }

    /// Handles presence change notification from CloudKit
    func handlePresenceChange(notification: CKNotification) async {
        guard let queryNotification = notification as? CKQueryNotification,
              let recordID = queryNotification.recordID else {
            return
        }

        do {
            let record = try await sharedDatabase.record(for: recordID)

            if let presence = UserPresence.fromCKRecord(record) {
                // Update active users list
                if let index = activeUsers.firstIndex(where: { $0.userRecordID == presence.userRecordID }) {
                    activeUsers[index] = presence
                } else if presence.isOnline {
                    activeUsers.append(presence)
                }

                // Remove offline users
                activeUsers.removeAll { !$0.isActive }

                // Create presence event
                determinePresenceEvent(for: presence)

                // Notify observers
                NotificationCenter.default.post(
                    name: .presenceDidChange,
                    object: nil,
                    userInfo: ["presence": presence]
                )
            }
        } catch {
            print("❌ Error fetching presence record: \(error)")
        }
    }

    // MARK: - Presence Events

    private func determinePresenceEvent(for presence: UserPresence) {
        // Determine what kind of event occurred
        let eventType: PresenceEvent.EventType

        if presence.isOnline && !activeUsers.contains(where: { $0.userRecordID == presence.userRecordID }) {
            eventType = .cameOnline
        } else if !presence.isOnline {
            eventType = .wentOffline
        } else if presence.isEditing {
            eventType = .startedEditing
        } else if presence.currentActivity == .viewing {
            eventType = .stoppedEditing
        } else {
            return // No significant event
        }

        addPresenceEvent(eventType, for: presence)
    }

    private func addPresenceEvent(_ eventType: PresenceEvent.EventType, for presence: UserPresence) {
        let event = PresenceEvent(
            id: UUID(),
            userRecordID: presence.userRecordID,
            displayName: presence.displayName,
            eventType: eventType,
            libraryID: presence.currentLibraryID,
            songID: presence.currentSongID,
            timestamp: Date()
        )

        presenceEvents.insert(event, at: 0)

        // Keep only last 50 events
        if presenceEvents.count > 50 {
            presenceEvents = Array(presenceEvents.prefix(50))
        }

        // Notify observers
        NotificationCenter.default.post(
            name: .presenceEventOccurred,
            object: nil,
            userInfo: ["event": event]
        )
    }

    // MARK: - Lifecycle Handlers

    @objc private func appWillResignActive() {
        Task {
            currentUserPresence?.markAway()
            await syncPresenceToCloudKit()
        }
    }

    @objc private func appDidBecomeActive() {
        Task {
            currentUserPresence?.markOnline()
            await syncPresenceToCloudKit()
            startPresenceUpdates()
        }
    }

    @objc private func appWillTerminate() {
        Task {
            await markOffline()
        }
    }

    // MARK: - Cleanup

    deinit {
        presenceUpdateTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let presenceDidUpdate = Notification.Name("presenceDidUpdate")
    static let presenceDidChange = Notification.Name("presenceDidChange")
    static let presenceEventOccurred = Notification.Name("presenceEventOccurred")
}
