//
//  TeamSettings.swift
//  Lyra
//
//  Organization-wide settings and preferences
//

import Foundation

struct TeamSettings: Codable {
    // MARK: - Default Permissions

    /// Default permission level for new library members
    var defaultLibraryPermission: String = "viewer" // LibraryPermission.viewer.rawValue

    /// Require approval for new library members
    var requireMemberApproval: Bool = true

    /// Allow members to create libraries
    var allowMemberLibraryCreation: Bool = false

    /// Allow members to invite others
    var allowMemberInvites: Bool = false

    // MARK: - Notifications

    /// Enable email notifications
    var emailNotificationsEnabled: Bool = true

    /// Enable push notifications
    var pushNotificationsEnabled: Bool = true

    /// Notification frequency
    var notificationDigestFrequency: String = "weekly"

    /// Notify admins of new members
    var notifyAdminsOnNewMember: Bool = true

    /// Notify admins of library changes
    var notifyAdminsOnLibraryChange: Bool = true

    // MARK: - Branding

    /// Organization primary color (hex)
    var primaryColorHex: String?

    /// Organization secondary color (hex)
    var secondaryColorHex: String?

    /// Organization logo URL
    var logoURL: String?

    /// Organization icon (SF Symbol)
    var iconName: String?

    /// Use custom branding
    var useCustomBranding: Bool = false

    // MARK: - Data & Privacy

    /// Data retention period in days (0 = forever)
    var dataRetentionDays: Int = 0

    /// Automatically delete inactive members after N days
    var autoDeleteInactiveMembersAfterDays: Int = 0

    /// Automatically archive old libraries after N days
    var autoArchiveLibrariesAfterDays: Int = 0

    /// Enable activity tracking
    var enableActivityTracking: Bool = true

    /// Enable audit logging
    var enableAuditLogging: Bool = true

    /// Allow data export
    var allowDataExport: Bool = true

    // MARK: - Collaboration

    /// Allow real-time collaboration
    var enableRealTimeCollaboration: Bool = true

    /// Allow comments on songs
    var allowComments: Bool = true

    /// Allow version history
    var enableVersionHistory: Bool = true

    /// Maximum version history per song (0 = unlimited)
    var maxVersionsPerSong: Int = 50

    /// Enable presence awareness
    var enablePresenceAwareness: Bool = true

    // MARK: - Content

    /// Require metadata for songs
    var requireSongMetadata: Bool = false

    /// Required metadata fields
    var requiredMetadataFields: [String] = []

    /// Allow song imports
    var allowSongImports: Bool = true

    /// Allowed import sources
    var allowedImportSources: [String] = ["files", "dropbox", "googledrive"]

    /// Maximum song size in MB
    var maxSongSizeMB: Double = 10.0

    // MARK: - Security

    /// Require two-factor authentication
    var require2FA: Bool = false

    /// Session timeout in minutes (0 = no timeout)
    var sessionTimeoutMinutes: Int = 0

    /// Allow external sharing
    var allowExternalSharing: Bool = true

    /// Require password for shared links
    var requirePasswordForSharedLinks: Bool = false

    /// Link expiration days (0 = never)
    var sharedLinkExpirationDays: Int = 0

    // MARK: - Organization Info

    /// Organization address
    var organizationAddress: String?

    /// Organization phone
    var organizationPhone: String?

    /// Organization website
    var organizationWebsite: String?

    /// Organization timezone
    var timezone: String = TimeZone.current.identifier

    /// Organization language
    var language: String = Locale.current.languageCode ?? "en"

    // MARK: - Advanced

    /// Enable API access
    var enableAPIAccess: Bool = false

    /// API rate limit per hour
    var apiRateLimitPerHour: Int = 1000

    /// Enable webhooks
    var enableWebhooks: Bool = false

    /// Webhook URL
    var webhookURL: String?

    /// Custom fields (extensible for future features)
    var customFields: [String: String] = [:]

    // MARK: - Initializer

    init() {
        // Default values already set
    }

    // MARK: - Validation

    func validate() -> [String] {
        var errors: [String] = []

        if dataRetentionDays < 0 {
            errors.append("Data retention days cannot be negative")
        }

        if maxSongSizeMB <= 0 {
            errors.append("Maximum song size must be greater than 0")
        }

        if sessionTimeoutMinutes < 0 {
            errors.append("Session timeout cannot be negative")
        }

        if apiRateLimitPerHour <= 0 && enableAPIAccess {
            errors.append("API rate limit must be greater than 0")
        }

        return errors
    }

    // MARK: - Presets

    static func churchPreset() -> TeamSettings {
        var settings = TeamSettings()
        settings.defaultLibraryPermission = "editor"
        settings.allowMemberLibraryCreation = true
        settings.allowMemberInvites = true
        settings.enableRealTimeCollaboration = true
        settings.enableVersionHistory = true
        settings.allowComments = true
        return settings
    }

    static func therapyPracticePreset() -> TeamSettings {
        var settings = TeamSettings()
        settings.defaultLibraryPermission = "viewer"
        settings.requireMemberApproval = true
        settings.allowExternalSharing = false
        settings.enableAuditLogging = true
        settings.dataRetentionDays = 2555 // 7 years for HIPAA
        return settings
    }

    static func schoolPreset() -> TeamSettings {
        var settings = TeamSettings()
        settings.defaultLibraryPermission = "viewer"
        settings.allowMemberLibraryCreation = false
        settings.requireMemberApproval = true
        settings.enableRealTimeCollaboration = true
        return settings
    }

    static func bandPreset() -> TeamSettings {
        var settings = TeamSettings()
        settings.defaultLibraryPermission = "editor"
        settings.allowMemberLibraryCreation = true
        settings.allowMemberInvites = true
        settings.allowExternalSharing = true
        return settings
    }
}
