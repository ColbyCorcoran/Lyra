//
//  Organization.swift
//  Lyra
//
//  Team/Organization model for managing multiple teams with shared libraries
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Organization {
    // MARK: - Identifiers

    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Basic Information

    var name: String
    var organizationDescription: String?
    var logoURL: String? // URL to organization logo
    var icon: String? // SF Symbol name for fallback
    var colorHex: String? // Organization brand color

    // MARK: - Ownership

    /// Owner's CloudKit user record ID
    var ownerRecordID: String

    /// Owner's display name
    var ownerDisplayName: String?

    // MARK: - Organization Type

    var organizationType: OrganizationType

    // MARK: - CloudKit Integration

    var cloudKitRecordName: String?
    var isCloudSynced: Bool

    // MARK: - Settings

    /// Organization-wide settings data
    var settingsData: Data? // Encoded TeamSettings

    // MARK: - Subscription & Billing (Future-Ready)

    var subscriptionTier: SubscriptionTier
    var maxSeats: Int // 0 = unlimited
    var currentSeats: Int
    var billingContactEmail: String?
    var subscriptionExpiresAt: Date?
    var trialEndsAt: Date?

    // MARK: - Statistics

    var memberCount: Int
    var adminCount: Int
    var libraryCount: Int
    var totalSongs: Int
    var lastActivityAt: Date?

    // MARK: - Relationships

    /// Members of this organization
    @Relationship(deleteRule: .cascade)
    var members: [OrganizationMember]?

    /// Shared libraries belonging to this organization
    @Relationship(deleteRule: .nullify)
    var libraries: [SharedLibrary]?

    /// Audit log entries
    var auditLogData: Data? // Encoded [AuditLogEntry]

    // MARK: - Initializer

    init(
        name: String,
        description: String? = nil,
        organizationType: OrganizationType = .team,
        ownerRecordID: String,
        ownerDisplayName: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.organizationDescription = description
        self.organizationType = organizationType
        self.ownerRecordID = ownerRecordID
        self.ownerDisplayName = ownerDisplayName
        self.isCloudSynced = false
        self.subscriptionTier = .free
        self.maxSeats = 5 // Default for free tier
        self.currentSeats = 1 // Owner
        self.memberCount = 1
        self.adminCount = 0
        self.libraryCount = 0
        self.totalSongs = 0
    }

    // MARK: - Computed Properties

    var displayIcon: String {
        icon ?? organizationType.defaultIcon
    }

    var displayColor: String {
        colorHex ?? organizationType.defaultColor
    }

    var isAtSeatLimit: Bool {
        maxSeats > 0 && currentSeats >= maxSeats
    }

    var availableSeats: Int {
        max(0, maxSeats - currentSeats)
    }

    var canAddMoreMembers: Bool {
        !isAtSeatLimit
    }

    var isTrialActive: Bool {
        guard let trialEnds = trialEndsAt else { return false }
        return Date() < trialEnds
    }

    var isSubscriptionActive: Bool {
        guard let expiresAt = subscriptionExpiresAt else {
            return subscriptionTier == .free
        }
        return Date() < expiresAt
    }

    var subscriptionStatus: SubscriptionStatus {
        if isTrialActive {
            return .trial
        } else if isSubscriptionActive {
            return .active
        } else if subscriptionExpiresAt != nil {
            return .expired
        } else {
            return .none
        }
    }

    // MARK: - Settings

    var settings: TeamSettings {
        get {
            guard let data = settingsData,
                  let decoded = try? JSONDecoder().decode(TeamSettings.self, from: data) else {
                return TeamSettings() // Return default settings
            }
            return decoded
        }
        set {
            settingsData = try? JSONEncoder().encode(newValue)
            modifiedAt = Date()
        }
    }

    // MARK: - Audit Log

    var auditLog: [AuditLogEntry] {
        get {
            guard let data = auditLogData,
                  let entries = try? JSONDecoder().decode([AuditLogEntry].self, from: data) else {
                return []
            }
            return entries.sorted { $0.timestamp > $1.timestamp }
        }
        set {
            auditLogData = try? JSONEncoder().encode(newValue)
        }
    }

    func addAuditLogEntry(_ entry: AuditLogEntry) {
        var log = auditLog
        log.append(entry)

        // Keep only last 500 entries
        if log.count > 500 {
            log = Array(log.suffix(500))
        }

        auditLog = log
        modifiedAt = Date()
    }

    // MARK: - Member Management

    func member(for userRecordID: String) -> OrganizationMember? {
        members?.first { $0.userRecordID == userRecordID }
    }

    func currentUserRole(userRecordID: String) -> OrganizationRole? {
        // Owner has owner role
        if userRecordID == ownerRecordID {
            return .owner
        }

        // Check members list
        return member(for: userRecordID)?.role
    }

    func addMember(_ member: OrganizationMember) {
        if members == nil {
            members = []
        }
        members?.append(member)
        memberCount = (members?.count ?? 0) + 1 // +1 for owner
        currentSeats = memberCount

        if member.role == .admin {
            adminCount += 1
        }

        modifiedAt = Date()
    }

    func removeMember(_ member: OrganizationMember) {
        if member.role == .admin {
            adminCount -= 1
        }

        members?.removeAll { $0.id == member.id }
        memberCount = (members?.count ?? 0) + 1 // +1 for owner
        currentSeats = memberCount
        modifiedAt = Date()
    }

    func checkRole(userRecordID: String, required: OrganizationRole) -> Bool {
        guard let currentRole = currentUserRole(userRecordID: userRecordID) else {
            return false
        }
        return currentRole >= required
    }

    // MARK: - Library Management

    func addLibrary(_ library: SharedLibrary) {
        if libraries == nil {
            libraries = []
        }
        libraries?.append(library)
        libraryCount = libraries?.count ?? 0
        modifiedAt = Date()
    }

    func removeLibrary(_ library: SharedLibrary) {
        libraries?.removeAll { $0.id == library.id }
        libraryCount = libraries?.count ?? 0
        modifiedAt = Date()
    }

    // MARK: - Statistics

    func updateStatistics() {
        memberCount = (members?.count ?? 0) + 1
        adminCount = members?.filter { $0.role == .admin }.count ?? 0
        libraryCount = libraries?.count ?? 0
        totalSongs = libraries?.reduce(0) { $0 + $1.songCount } ?? 0
        lastActivityAt = Date()
        modifiedAt = Date()
    }

    // MARK: - Subscription Management

    func upgradeTier(to newTier: SubscriptionTier) {
        subscriptionTier = newTier
        maxSeats = newTier.defaultMaxSeats

        // Add audit log entry
        let entry = AuditLogEntry(
            actorRecordID: ownerRecordID,
            actorDisplayName: ownerDisplayName,
            action: .subscriptionChanged,
            details: "Upgraded to \(newTier.rawValue)",
            targetID: nil,
            targetName: nil
        )
        addAuditLogEntry(entry)
    }

    func startTrial(duration: TimeInterval = 30 * 24 * 60 * 60) { // 30 days default
        trialEndsAt = Date().addingTimeInterval(duration)
        modifiedAt = Date()
    }
}

// MARK: - Organization Type

enum OrganizationType: String, Codable, CaseIterable {
    case church = "Church"
    case worshipTeam = "Worship Team"
    case therapyPractice = "Music Therapy Practice"
    case school = "School"
    case band = "Band"
    case company = "Company"
    case other = "Other"

    var defaultIcon: String {
        switch self {
        case .church: return "building.columns"
        case .worshipTeam: return "hands.sparkles"
        case .therapyPractice: return "heart.text.square"
        case .school: return "graduationcap"
        case .band: return "music.mic"
        case .company: return "building.2"
        case .other: return "folder"
        }
    }

    var defaultColor: String {
        switch self {
        case .church: return "#7B68EE"
        case .worshipTeam: return "#FF6B6B"
        case .therapyPractice: return "#4ECDC4"
        case .school: return "#45B7D1"
        case .band: return "#F38181"
        case .company: return "#5F9EA0"
        case .other: return "#95A5A6"
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "Free"
    case starter = "Starter"
    case professional = "Professional"
    case enterprise = "Enterprise"

    var defaultMaxSeats: Int {
        switch self {
        case .free: return 5
        case .starter: return 15
        case .professional: return 50
        case .enterprise: return 0 // Unlimited
        }
    }

    var monthlyPrice: Double {
        switch self {
        case .free: return 0
        case .starter: return 29.99
        case .professional: return 99.99
        case .enterprise: return 299.99
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "Up to 5 members",
                "1 shared library",
                "Basic collaboration",
                "Community support"
            ]
        case .starter:
            return [
                "Up to 15 members",
                "5 shared libraries",
                "Team analytics",
                "Email support"
            ]
        case .professional:
            return [
                "Up to 50 members",
                "Unlimited libraries",
                "Advanced analytics",
                "Priority support",
                "Custom branding"
            ]
        case .enterprise:
            return [
                "Unlimited members",
                "Unlimited libraries",
                "Enterprise analytics",
                "Dedicated support",
                "Custom branding",
                "SSO integration",
                "API access"
            ]
        }
    }
}

enum SubscriptionStatus {
    case none
    case trial
    case active
    case expired
}
