//
//  SharedLibrary.swift
//  Lyra
//
//  Shared library model with CloudKit sharing support for team collaboration
//

import Foundation
import SwiftData
import CloudKit

@Model
final class SharedLibrary {
    // MARK: - Identifiers

    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Basic Information

    var name: String
    var libraryDescription: String?
    var icon: String? // SF Symbol name
    var colorHex: String? // Library color for visual distinction

    // MARK: - Ownership

    /// Owner's CloudKit user record ID
    var ownerRecordID: String

    /// Owner's display name
    var ownerDisplayName: String?

    // MARK: - Privacy & Sharing

    var privacy: LibraryPrivacy
    var isShared: Bool

    /// CloudKit share record name
    var shareRecordName: String?

    /// Share URL for invitations
    var shareURL: String?

    /// QR code data for easy sharing
    var qrCodeData: Data?

    // MARK: - Settings

    /// Allow members to invite others
    var allowMemberInvites: Bool

    /// Require approval for new members
    var requireApproval: Bool

    /// Maximum number of members (0 = unlimited)
    var maxMembers: Int

    /// Whether to track activity feed
    var enableActivityTracking: Bool

    // MARK: - Statistics

    var memberCount: Int
    var songCount: Int
    var totalEdits: Int
    var lastActivityAt: Date?

    // MARK: - Relationships

    /// Members of this shared library
    @Relationship(deleteRule: .cascade)
    var members: [LibraryMember]?

    /// Songs in this shared library
    @Relationship(deleteRule: .nullify, inverse: \Song.sharedLibrary)
    var songs: [Song]?

    /// Activity feed entries
    var activityFeedData: Data? // Encoded [MemberActivity]

    // MARK: - Initializer

    init(
        name: String,
        description: String? = nil,
        ownerRecordID: String,
        ownerDisplayName: String? = nil,
        privacy: LibraryPrivacy = .private
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.libraryDescription = description
        self.ownerRecordID = ownerRecordID
        self.ownerDisplayName = ownerDisplayName
        self.privacy = privacy
        self.isShared = false
        self.allowMemberInvites = false
        self.requireApproval = true
        self.maxMembers = 0
        self.enableActivityTracking = true
        self.memberCount = 1 // Owner counts as member
        self.songCount = 0
        self.totalEdits = 0
    }

    // MARK: - Computed Properties

    var displayIcon: String {
        icon ?? "music.note.list"
    }

    var memberCountText: String {
        let count = memberCount
        return count == 1 ? "1 member" : "\(count) members"
    }

    var songCountText: String {
        let count = songCount
        return count == 1 ? "1 song" : "\(count) songs"
    }

    var isAtMemberLimit: Bool {
        maxMembers > 0 && memberCount >= maxMembers
    }

    var canAddMoreMembers: Bool {
        !isAtMemberLimit
    }

    // MARK: - Activity Feed

    var activityFeed: [MemberActivity] {
        get {
            guard let data = activityFeedData,
                  let activities = try? JSONDecoder().decode([MemberActivity].self, from: data) else {
                return []
            }
            return activities.sorted { $0.timestamp > $1.timestamp }
        }
        set {
            activityFeedData = try? JSONEncoder().encode(newValue)
        }
    }

    func addActivity(_ activity: MemberActivity) {
        var feed = activityFeed
        feed.append(activity)

        // Keep only last 100 activities
        if feed.count > 100 {
            feed = Array(feed.suffix(100))
        }

        activityFeed = feed
        lastActivityAt = activity.timestamp
        modifiedAt = Date()
    }

    // MARK: - Member Management

    /// Gets member by user record ID
    func member(for userRecordID: String) -> LibraryMember? {
        members?.first { $0.userRecordID == userRecordID }
    }

    /// Gets current user's permission level
    func currentUserPermission(userRecordID: String) -> LibraryPermission? {
        // Owner has owner permission
        if userRecordID == ownerRecordID {
            return .owner
        }

        // Check members list
        return member(for: userRecordID)?.permissionLevel
    }

    /// Adds a new member
    func addMember(_ member: LibraryMember) {
        if members == nil {
            members = []
        }
        members?.append(member)
        memberCount = (members?.count ?? 0) + 1 // +1 for owner
        modifiedAt = Date()
    }

    /// Removes a member
    func removeMember(_ member: LibraryMember) {
        members?.removeAll { $0.id == member.id }
        memberCount = (members?.count ?? 0) + 1 // +1 for owner
        modifiedAt = Date()
    }

    /// Checks if user has required permission
    func checkPermission(userRecordID: String, required: LibraryPermission) -> PermissionCheckResult {
        let currentPermission = currentUserPermission(userRecordID: userRecordID)
        return PermissionHelper.checkPermission(required: required, current: currentPermission)
    }

    // MARK: - Song Management

    /// Adds a song to the library
    func addSong(_ song: Song) {
        if songs == nil {
            songs = []
        }
        songs?.append(song)
        songCount = songs?.count ?? 0
        modifiedAt = Date()
    }

    /// Removes a song from the library
    func removeSong(_ song: Song) {
        songs?.removeAll { $0.id == song.id }
        songCount = songs?.count ?? 0
        modifiedAt = Date()
    }

    // MARK: - CloudKit Integration

    /// Updates from CloudKit share
    func updateFromShare(_ share: CKShare) {
        shareRecordName = share.recordID.recordName
        shareURL = share.url?.absoluteString

        // Update members from participants
        var updatedMembers: [LibraryMember] = []

        for participant in share.participants {
            if participant.role == .owner {
                // Skip owner, already tracked
                continue
            }

            let existingMember = member(for: participant.userIdentity.userRecordID?.recordName ?? "")
            if let existing = existingMember {
                // Update existing member
                existing.invitationAccepted = participant.acceptanceStatus == .accepted
                updatedMembers.append(existing)
            } else {
                // Create new member
                let newMember = LibraryMember.from(ckParticipant: participant, invitedBy: ownerRecordID)
                updatedMembers.append(newMember)
            }
        }

        members = updatedMembers
        memberCount = updatedMembers.count + 1 // +1 for owner
        modifiedAt = Date()
    }

    /// Generates QR code for sharing
    func generateQRCode() {
        guard let shareURL = shareURL else { return }

        // QR code generation would be implemented here
        // Using CoreImage CIQRCodeGenerator filter

        let data = shareURL.data(using: .utf8)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("H", forKey: "inputCorrectionLevel")

            if let outputImage = filter.outputImage {
                // Convert to PNG data (simplified - actual implementation would be more robust)
                // qrCodeData = outputImage.pngData()
                print("QR code generated for \(shareURL)")
            }
        }
    }

    // MARK: - Statistics Updates

    func incrementEditCount() {
        totalEdits += 1
        modifiedAt = Date()
    }

    func updateLastActivity() {
        lastActivityAt = Date()
        modifiedAt = Date()
    }
}

// MARK: - Library Category

enum LibraryCategory: String, Codable, CaseIterable {
    case worship = "Worship"
    case therapy = "Music Therapy"
    case band = "Band"
    case personal = "Personal"
    case educational = "Educational"
    case other = "Other"

    var icon: String {
        switch self {
        case .worship: return "hands.sparkles"
        case .therapy: return "heart.text.square"
        case .band: return "music.mic"
        case .personal: return "person"
        case .educational: return "graduationcap"
        case .other: return "folder"
        }
    }

    var suggestedIcon: String {
        icon
    }
}
