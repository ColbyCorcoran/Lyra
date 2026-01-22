//
//  SharedLibraryManager.swift
//  Lyra
//
//  Manages CloudKit sharing operations for shared libraries
//

import Foundation
import SwiftData
import CloudKit
import Combine

@MainActor
@Observable
class SharedLibraryManager {
    static let shared = SharedLibraryManager()

    // MARK: - Published Properties

    var sharedLibraries: [SharedLibrary] = []
    var isLoading: Bool = false
    var lastError: Error?

    // MARK: - Private Properties

    private let container = CKContainer.default()
    private lazy var privateDatabase = container.privateCloudDatabase
    private lazy var sharedDatabase = container.sharedCloudDatabase
    private var subscriptions: Set<AnyCancellable> = []

    private init() {
        setupNotifications()
    }

    // MARK: - Setup

    private func setupNotifications() {
        // Listen for CloudKit account changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountChange),
            name: .CKAccountChanged,
            object: nil
        )
    }

    @objc private func handleAccountChange(_ notification: Notification) {
        Task {
            await fetchSharedLibraries()
        }
    }

    // MARK: - Library Creation

    /// Creates a new shared library
    func createSharedLibrary(
        name: String,
        description: String?,
        privacy: LibraryPrivacy,
        modelContext: ModelContext
    ) async throws -> SharedLibrary {
        isLoading = true
        defer { isLoading = false }

        // Get current user info
        let userRecordID = try await getCurrentUserRecordID()

        // Create library in SwiftData
        let library = SharedLibrary(
            name: name,
            description: description,
            ownerRecordID: userRecordID,
            privacy: privacy
        )

        modelContext.insert(library)
        try modelContext.save()

        // If privacy requires sharing, create CloudKit share
        if privacy != .private {
            try await createCloudKitShare(for: library, modelContext: modelContext)
        }

        sharedLibraries.append(library)

        return library
    }

    // MARK: - CloudKit Sharing

    /// Creates a CloudKit share for the library
    func createCloudKitShare(
        for library: SharedLibrary,
        modelContext: ModelContext
    ) async throws {
        // Create CKShare
        let share = CKShare(rootRecord: try libraryToCKRecord(library))

        // Configure share
        share[CKShare.SystemFieldKey.title] = library.name as CKRecordValue
        share.publicPermission = library.privacy.ckSharePublicPermission

        // Save share to CloudKit
        try await privateDatabase.save(share)

        // Update library with share info
        library.isShared = true
        library.updateFromShare(share)
        library.generateQRCode()

        try modelContext.save()
    }

    /// Adds participants to a share
    func addParticipants(
        to library: SharedLibrary,
        emailAddresses: [String],
        permission: LibraryPermission
    ) async throws {
        guard let shareRecordName = library.shareRecordName else {
            throw SharingError.noShareFound
        }

        // Fetch the share
        let shareRecordID = CKRecord.ID(recordName: shareRecordName)
        let share = try await privateDatabase.record(for: shareRecordID) as? CKShare

        guard let share = share else {
            throw SharingError.noShareFound
        }

        // Add participants
        for email in emailAddresses {
            let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: email)
            let participant = CKShare.Participant()
            participant.permission = permission.ckShareParticipantPermission
            participant.role = permission.ckShareParticipantRole

            // Note: Actual implementation would use CKFetchShareParticipantsOperation
            // to lookup users first, then add them to the share
        }

        // Save updated share
        try await privateDatabase.save(share)

        // Update library
        library.updateFromShare(share)
    }

    /// Removes a participant from a share
    func removeParticipant(
        from library: SharedLibrary,
        userRecordID: String,
        modelContext: ModelContext
    ) async throws {
        guard let shareRecordName = library.shareRecordName else {
            throw SharingError.noShareFound
        }

        // Fetch the share
        let shareRecordID = CKRecord.ID(recordName: shareRecordName)
        let share = try await privateDatabase.record(for: shareRecordID) as? CKShare

        guard let share = share else {
            throw SharingError.noShareFound
        }

        // Find and remove participant
        if let participant = share.participants.first(where: {
            $0.userIdentity.userRecordID?.recordName == userRecordID
        }) {
            share.removeParticipant(participant)

            // Save updated share
            try await privateDatabase.save(share)

            // Update library
            if let member = library.member(for: userRecordID) {
                library.removeMember(member)
                modelContext.delete(member)
            }

            try modelContext.save()
        }
    }

    /// Updates participant permission
    func updateParticipantPermission(
        in library: SharedLibrary,
        userRecordID: String,
        newPermission: LibraryPermission,
        modelContext: ModelContext
    ) async throws {
        guard let shareRecordName = library.shareRecordName else {
            throw SharingError.noShareFound
        }

        // Fetch the share
        let shareRecordID = CKRecord.ID(recordName: shareRecordName)
        let share = try await privateDatabase.record(for: shareRecordID) as? CKShare

        guard let share = share else {
            throw SharingError.noShareFound
        }

        // Find and update participant
        if let participant = share.participants.first(where: {
            $0.userIdentity.userRecordID?.recordName == userRecordID
        }) {
            participant.permission = newPermission.ckShareParticipantPermission

            // Save updated share
            try await privateDatabase.save(share)

            // Update member
            if let member = library.member(for: userRecordID) {
                member.updatePermission(newPermission)
                try modelContext.save()
            }
        }
    }

    // MARK: - Invitation Handling

    /// Accepts a share invitation
    func acceptShareInvitation(
        shareMetadata: CKShare.Metadata,
        modelContext: ModelContext
    ) async throws -> SharedLibrary {
        // Accept the share
        let acceptedShare = try await container.accept(shareMetadata)

        // Fetch the shared library from shared database
        let rootRecordID = shareMetadata.rootRecordID
        let rootRecord = try await sharedDatabase.record(for: rootRecordID)

        // Convert to SharedLibrary
        let library = try libraryFromCKRecord(rootRecord)
        library.isShared = true
        library.updateFromShare(acceptedShare)

        // Save to local database
        modelContext.insert(library)
        try modelContext.save()

        sharedLibraries.append(library)

        return library
    }

    /// Declines a share invitation
    func declineShareInvitation(shareMetadata: CKShare.Metadata) async throws {
        // CloudKit doesn't have a specific "decline" API
        // Simply don't accept the share
        print("Share invitation declined")
    }

    // MARK: - Library Management

    /// Fetches all shared libraries user has access to
    func fetchSharedLibraries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch from shared database
            let query = CKQuery(recordType: "SharedLibrary", predicate: NSPredicate(value: true))
            let results = try await sharedDatabase.records(matching: query)

            var libraries: [SharedLibrary] = []

            for (_, result) in results.matchResults {
                if let record = try? result.get() {
                    if let library = try? libraryFromCKRecord(record) {
                        libraries.append(library)
                    }
                }
            }

            await MainActor.run {
                sharedLibraries = libraries
            }
        } catch {
            lastError = error
            print("❌ Error fetching shared libraries: \(error)")
        }
    }

    /// Deletes a shared library
    func deleteLibrary(
        _ library: SharedLibrary,
        modelContext: ModelContext
    ) async throws {
        // Delete from CloudKit if shared
        if library.isShared, let shareRecordName = library.shareRecordName {
            let shareRecordID = CKRecord.ID(recordName: shareRecordName)
            try await privateDatabase.deleteRecord(withID: shareRecordID)
        }

        // Delete from local database
        modelContext.delete(library)
        try modelContext.save()

        // Remove from array
        sharedLibraries.removeAll { $0.id == library.id }
    }

    // MARK: - Sync Operations

    /// Subscribes to changes in a shared library
    func subscribeToLibraryChanges(_ library: SharedLibrary) async throws {
        guard library.isShared else { return }

        let subscription = CKQuerySubscription(
            recordType: "Song",
            predicate: NSPredicate(format: "sharedLibrary == %@", library.id.uuidString),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        try await sharedDatabase.save(subscription)
    }

    /// Handles notification of shared record change
    func handleSharedRecordChange(notification: CKNotification) async {
        guard let queryNotification = notification as? CKQueryNotification else { return }

        // Fetch the changed record
        if let recordID = queryNotification.recordID {
            do {
                let record = try await sharedDatabase.record(for: recordID)
                print("Shared record changed: \(record)")

                // Notify app to refresh
                NotificationCenter.default.post(
                    name: .sharedLibraryDidChange,
                    object: nil,
                    userInfo: ["recordID": recordID]
                )
            } catch {
                print("❌ Error fetching changed record: \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    private func getCurrentUserRecordID() async throws -> String {
        let userRecordID = try await container.userRecordID()
        return userRecordID.recordName
    }

    private func libraryToCKRecord(_ library: SharedLibrary) throws -> CKRecord {
        let record = CKRecord(recordType: "SharedLibrary")
        record["name"] = library.name as CKRecordValue
        record["description"] = library.libraryDescription as? CKRecordValue
        record["ownerRecordID"] = library.ownerRecordID as CKRecordValue
        record["privacy"] = library.privacy.rawValue as CKRecordValue
        record["createdAt"] = library.createdAt as CKRecordValue
        return record
    }

    private func libraryFromCKRecord(_ record: CKRecord) throws -> SharedLibrary {
        let library = SharedLibrary(
            name: record["name"] as? String ?? "Untitled",
            description: record["description"] as? String,
            ownerRecordID: record["ownerRecordID"] as? String ?? "",
            privacy: LibraryPrivacy(rawValue: record["privacy"] as? String ?? "Private") ?? .private
        )

        if let createdAt = record["createdAt"] as? Date {
            library.createdAt = createdAt
        }

        return library
    }
}

// MARK: - Errors

enum SharingError: LocalizedError {
    case noShareFound
    case permissionDenied
    case userNotFound
    case networkError
    case invalidShareURL

    var errorDescription: String? {
        switch self {
        case .noShareFound:
            return "No share found for this library"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network error occurred"
        case .invalidShareURL:
            return "Invalid share URL"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let sharedLibraryDidChange = Notification.Name("sharedLibraryDidChange")
}
