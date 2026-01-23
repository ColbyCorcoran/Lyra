# Organization Management Guide for Lyra

## Overview

Lyra's Organization Management system enables teams, churches, therapy practices, and bands to structure their collaboration with formal team hierarchies, subscription management, and centralized administration. This builds on the shared library foundation to provide enterprise-grade team features.

**Implementation Status:** ✅ Complete (Phase 4)
**Related Features:** Shared Libraries, Team Analytics, Audit Logging

---

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Architecture](#architecture)
3. [Data Models](#data-models)
4. [User Interface](#user-interface)
5. [Key Features](#key-features)
6. [Subscription Tiers](#subscription-tiers)
7. [Role Hierarchy](#role-hierarchy)
8. [Integration Guide](#integration-guide)
9. [Use Cases](#use-cases)
10. [Security](#security)
11. [Testing](#testing)

---

## Core Concepts

### What is an Organization?

An **Organization** in Lyra is a formal team structure that provides:
- Centralized member management
- Role-based access control
- Subscription/billing management
- Multiple shared libraries under one umbrella
- Audit logging for all administrative actions
- Team settings and branding

### Why Organizations?

**Without Organizations:**
- Each shared library managed independently
- No unified team structure
- No subscription management
- Manual tracking of members across libraries

**With Organizations:**
- Single team entity with multiple libraries
- Centralized member management
- Subscription tiers with seat limits
- Automatic audit logging
- Team-wide settings and branding
- Professional team directory

### Organization vs Shared Library

| Feature | Shared Library | Organization |
|---------|---------------|--------------|
| **Purpose** | Collaborate on songs | Formal team structure |
| **Members** | Invited per library | Centralized roster |
| **Permissions** | Library-specific | Role-based (organization-wide) |
| **Billing** | N/A | Subscription tiers |
| **Audit Log** | Basic activity feed | Comprehensive audit trail |
| **Settings** | Per-library | Organization-wide defaults |
| **Use Case** | Ad-hoc collaboration | Professional teams |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Organization Layer                      │
│  • Team structure                                           │
│  • Subscription management                                  │
│  • Centralized settings                                     │
│  • Audit logging                                            │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│                  Shared Libraries Layer                      │
│  • Multiple libraries per organization                      │
│  • Inherit org settings and permissions                     │
│  • Song collaboration                                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│                      Data Layer                              │
│  • SwiftData models                                         │
│  • CloudKit sync                                            │
└─────────────────────────────────────────────────────────────┘
```

### Component Hierarchy

```
Organization
├── OrganizationMember (many)
│   ├── User info
│   ├── Role (Member, Editor, Admin, Owner)
│   ├── Status (Active, Suspended, Invited)
│   └── Activity metrics
├── SharedLibrary (many)
│   ├── Songs
│   ├── Members
│   └── Settings
├── TeamSettings
│   ├── Default permissions
│   ├── Notification preferences
│   ├── Branding (colors, logo)
│   └── Organization info
├── AuditLogEntry (many)
│   ├── Action taken
│   ├── Actor
│   ├── Timestamp
│   └── Affected entity
└── Subscription
    ├── Tier (Free, Starter, Professional, Enterprise)
    ├── Seat limits
    ├── Billing info
    └── Usage tracking
```

---

## Data Models

### 1. Organization Model

**File:** `Lyra/Models/Organization.swift`

```swift
@Model
final class Organization {
    // Identity
    var id: UUID
    var name: String
    var tagline: String?
    var organizationType: OrganizationType

    // Visual Identity
    var icon: String // SF Symbol name
    var colorHex: String
    var logoURL: String?

    // Ownership
    var ownerUserRecordID: String
    var ownerDisplayName: String?

    // Subscription
    var subscriptionTier: SubscriptionTier
    var subscriptionStartDate: Date
    var subscriptionEndDate: Date?
    var maxSeats: Int
    var currentSeats: Int
    var billingEmail: String?
    var billingContactName: String?

    // Settings
    var settings: TeamSettings

    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool

    // CloudKit
    var cloudKitRecordName: String?
    var cloudKitShareRecordName: String?

    // Relationships
    @Relationship(deleteRule: .cascade)
    var members: [OrganizationMember]?

    @Relationship(deleteRule: .nullify)
    var libraries: [SharedLibrary]?

    @Relationship(deleteRule: .cascade)
    var auditLog: [AuditLogEntry]?
}
```

**Organization Types:**
```swift
enum OrganizationType: String, Codable {
    case church = "Church/Worship Team"
    case school = "School/Educational"
    case business = "Business"
    case nonprofit = "Non-Profit"
    case musicTherapy = "Music Therapy"
    case band = "Band/Music Group"
    case personal = "Personal"
    case other = "Other"
}
```

### 2. OrganizationMember Model

**File:** `Lyra/Models/OrganizationMember.swift`

```swift
@Model
final class OrganizationMember {
    // Identity
    var id: UUID
    var userRecordID: String
    var displayName: String?
    var email: String?
    var avatarURL: String?

    // Role & Status
    var role: OrganizationRole
    var status: MemberStatus
    var invitedBy: String?
    var invitedAt: Date?
    var joinedAt: Date?
    var suspendedAt: Date?
    var suspendedBy: String?
    var suspensionReason: String?

    // Activity
    var lastActiveAt: Date
    var totalLibrariesAccessed: Int
    var totalSongsCreated: Int
    var totalSongsEdited: Int
    var totalCommentsPosted: Int

    // Preferences
    var notificationPreferences: NotificationPreferences
    var customTitle: String?
    var bio: String?

    // Relationship
    @Relationship(inverse: \Organization.members)
    var organization: Organization?
}
```

**Roles:**
```swift
enum OrganizationRole: String, Codable, Comparable {
    case member = "Member"      // Basic access
    case editor = "Editor"      // Can create/edit content
    case admin = "Admin"        // Can manage members and settings
    case owner = "Owner"        // Full control

    var permissions: Set<Permission> {
        switch self {
        case .member:
            return [.viewLibraries, .viewSongs]
        case .editor:
            return [.viewLibraries, .viewSongs, .createSongs, .editSongs]
        case .admin:
            return [.viewLibraries, .viewSongs, .createSongs, .editSongs,
                    .manageMembers, .manageLibraries, .changeSettings]
        case .owner:
            return Permission.allCases.asSet
        }
    }
}
```

**Member Status:**
```swift
enum MemberStatus: String, Codable {
    case invited = "Invited"     // Invitation sent
    case active = "Active"       // Full access
    case suspended = "Suspended" // Temporarily blocked
    case removed = "Removed"     // Permanently removed
}
```

### 3. TeamSettings Model

**File:** `Lyra/Models/TeamSettings.swift`

```swift
@Model
final class TeamSettings {
    // General Settings
    var defaultLibraryPermission: LibraryPermission
    var requireApprovalForNewMembers: Bool
    var allowMemberInvites: Bool
    var autoArchiveInactiveSongs: Bool
    var inactivityThresholdDays: Int

    // Notification Settings
    var enableEmailNotifications: Bool
    var enablePushNotifications: Bool
    var notificationFrequency: NotificationFrequency
    var digestTime: String? // "09:00" for daily digest

    // Collaboration Settings
    var allowConcurrentEditing: Bool
    var showPresenceIndicators: Bool
    var enableComments: Bool
    var enableVersionHistory: Bool
    var versionHistoryRetentionDays: Int

    // Content Settings
    var defaultSongKey: String?
    var defaultTimeSignature: String?
    var defaultTempo: Int?
    var enableAIFeatures: Bool
    var enableAutoscroll: Bool

    // Privacy Settings
    var allowPublicSharing: Bool
    var allowExternalCollaboration: Bool
    var requireTwoFactorAuth: Bool // Enterprise only
    var sessionTimeoutMinutes: Int

    // Branding
    var primaryColorHex: String
    var secondaryColorHex: String
    var logoURL: String?
    var customDomain: String? // Enterprise only

    // Integration Settings
    var enablePlanningCenterSync: Bool // Future
    var enableSpotifyIntegration: Bool // Future
    var enableYouTubeIntegration: Bool // Future

    // Data Retention
    var auditLogRetentionDays: Int
    var activityFeedRetentionDays: Int
    var deletedItemsRetentionDays: Int
}
```

### 4. AuditLogEntry Model

**File:** `Lyra/Models/AuditLogEntry.swift`

```swift
@Model
final class AuditLogEntry {
    var id: UUID
    var timestamp: Date
    var actorUserRecordID: String
    var actorDisplayName: String?
    var action: AuditAction
    var category: AuditCategory
    var targetType: String? // "member", "library", "song", etc.
    var targetID: UUID?
    var targetName: String?
    var details: String?
    var metadata: [String: String]? // Additional context
    var ipAddress: String?
    var deviceType: String?

    // Relationship
    @Relationship(inverse: \Organization.auditLog)
    var organization: Organization?
}
```

**Audit Actions:**
```swift
enum AuditAction: String, Codable {
    // Member Actions
    case memberInvited = "Member Invited"
    case memberJoined = "Member Joined"
    case memberRemoved = "Member Removed"
    case memberSuspended = "Member Suspended"
    case memberReactivated = "Member Reactivated"
    case roleChanged = "Role Changed"

    // Library Actions
    case libraryCreated = "Library Created"
    case libraryDeleted = "Library Deleted"
    case libraryShared = "Library Shared"
    case libraryUnshared = "Library Unshared"
    case librarySettingsChanged = "Library Settings Changed"

    // Organization Actions
    case settingsChanged = "Settings Changed"
    case subscriptionUpgraded = "Subscription Upgraded"
    case subscriptionDowngraded = "Subscription Downgraded"
    case subscriptionCancelled = "Subscription Cancelled"
    case billingUpdated = "Billing Updated"

    // Security Actions
    case passwordChanged = "Password Changed"
    case twoFactorEnabled = "2FA Enabled"
    case twoFactorDisabled = "2FA Disabled"
    case loginAttempt = "Login Attempt"
    case logoutAll = "Logged Out All Devices"
}

enum AuditCategory: String, Codable {
    case members = "Members"
    case libraries = "Libraries"
    case settings = "Settings"
    case security = "Security"
    case billing = "Billing"
    case content = "Content"
}
```

---

## User Interface

### 1. CreateOrganizationView

**File:** `Lyra/Views/CreateOrganizationView.swift`

**Purpose:** Wizard-style flow for creating a new organization

**Steps:**
1. **Basic Information**
   - Organization name (required)
   - Tagline (optional)
   - Organization type selection

2. **Visual Identity**
   - Icon picker (SF Symbols)
   - Color selection (primary & secondary)
   - Logo upload (optional, Enterprise)

3. **Subscription Selection**
   - Display tier comparison
   - Feature matrix
   - Seat limits
   - Pricing

4. **Initial Setup**
   - Default permissions
   - Notification settings
   - Invite initial members

**UI Features:**
- Multi-step progress indicator
- Live preview of organization card
- Form validation with helpful error messages
- "Save as Draft" option
- "Skip and Configure Later" for optional steps

**Code Example:**
```swift
struct CreateOrganizationView: View {
    @State private var currentStep = 1
    @State private var organizationName = ""
    @State private var organizationType: OrganizationType = .church
    @State private var selectedIcon = "music.note.house"
    @State private var selectedColor = "#3B82F6"
    @State private var selectedTier: SubscriptionTier = .free

    var body: some View {
        NavigationStack {
            VStack {
                StepIndicator(currentStep: currentStep, totalSteps: 4)

                TabView(selection: $currentStep) {
                    BasicInfoStep(
                        name: $organizationName,
                        type: $organizationType
                    ).tag(1)

                    VisualIdentityStep(
                        icon: $selectedIcon,
                        color: $selectedColor
                    ).tag(2)

                    SubscriptionStep(
                        tier: $selectedTier
                    ).tag(3)

                    InitialSetupStep().tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                NavigationButtons(
                    currentStep: $currentStep,
                    onComplete: createOrganization
                )
            }
            .navigationTitle("Create Organization")
        }
    }

    private func createOrganization() async {
        let org = Organization(
            name: organizationName,
            organizationType: organizationType,
            icon: selectedIcon,
            colorHex: selectedColor,
            subscriptionTier: selectedTier
        )
        await OrganizationManager.shared.create(org)
    }
}
```

### 2. TeamDirectoryView

**File:** `Lyra/Views/TeamDirectoryView.swift`

**Purpose:** Browse and switch between organizations

**Layout:**
```
┌─────────────────────────────────────┐
│  Team Directory                  [+]│
│─────────────────────────────────────│
│  Search...                          │
│─────────────────────────────────────│
│  My Organizations (3)               │
│                                     │
│  ┌─────────────────────────────┐  │
│  │  🎵 First Church Worship    │  │
│  │  25 members • 3 libraries   │  │
│  │  Owner                      │  │
│  └─────────────────────────────┘  │
│                                     │
│  ┌─────────────────────────────┐  │
│  │  🎸 Indie Band Collective   │  │
│  │  6 members • 1 library      │  │
│  │  Admin                      │  │
│  └─────────────────────────────┘  │
│                                     │
│  Invitations (1)                    │
│                                     │
│  ┌─────────────────────────────┐  │
│  │  🏫 Music School            │  │
│  │  Invited by Jane Doe        │  │
│  │  [Accept] [Decline]         │  │
│  └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Features:**
- Card-based layout with organization info
- Search and filter
- Quick actions (View, Settings, Leave)
- Invitation management
- Create new organization button
- Role badge (Owner, Admin, Editor, Member)

### 3. OrganizationDetailView

**File:** `Lyra/Views/OrganizationDetailView.swift`

**Purpose:** Main hub for organization management

**Sections:**
```
┌─────────────────────────────────────┐
│  🎵 First Church Worship         [⚙️]│
│  "Glorifying God through music"     │
│  25 members • 3 libraries           │
│─────────────────────────────────────│
│  [Members] [Libraries] [Analytics]  │
│─────────────────────────────────────│
│  Recent Activity                    │
│  • John added "Amazing Grace"       │
│  • Sarah joined the team            │
│  • New library "Christmas 2026"     │
│─────────────────────────────────────│
│  Quick Actions                      │
│  [Invite Member] [Create Library]   │
│  [View Audit Log] [Settings]        │
└─────────────────────────────────────┘
```

**Tabs:**
1. **Overview** - Dashboard with key metrics
2. **Members** - Member list with management
3. **Libraries** - All organization libraries
4. **Analytics** - Team analytics dashboard
5. **Settings** - Organization configuration

### 4. OrganizationMembersView

**File:** `Lyra/Views/OrganizationMembersView.swift`

**Purpose:** Manage team members

**Layout:**
```
┌─────────────────────────────────────┐
│  Members (25/50)              [+]   │
│─────────────────────────────────────│
│  Search members...                  │
│  [All] [Active] [Invited] [Admins] │
│─────────────────────────────────────│
│  Owners (1)                         │
│  ┌─────────────────────────────┐  │
│  │  👤 John Doe               •│  │
│  │  john@example.com           │  │
│  │  Owner • Active             │  │
│  └─────────────────────────────┘  │
│                                     │
│  Admins (3)                         │
│  [Similar card layout...]           │
│                                     │
│  Editors (15)                       │
│  [Similar card layout...]           │
│                                     │
│  Members (6)                        │
│  [Similar card layout...]           │
└─────────────────────────────────────┘
```

**Member Actions Menu:**
- View Profile
- Change Role
- Suspend Member
- Remove from Organization
- View Activity
- Send Message

**Bulk Actions:**
- Select multiple members
- Change roles in bulk
- Export member list
- Send group notification

### 5. OrganizationSettingsView

**File:** `Lyra/Views/OrganizationSettingsView.swift`

**Purpose:** Configure organization settings

**Sections:**
1. **General**
   - Name, tagline, type
   - Icon and colors
   - Logo upload

2. **Members & Permissions**
   - Default library permission
   - Require approval for new members
   - Allow member invites
   - Role permissions

3. **Notifications**
   - Email notifications
   - Push notifications
   - Notification frequency
   - Digest time

4. **Collaboration**
   - Concurrent editing
   - Presence indicators
   - Comments
   - Version history

5. **Subscription**
   - Current plan
   - Seats used/available
   - Billing information
   - Upgrade/downgrade

6. **Audit & Security**
   - Audit log retention
   - Two-factor authentication
   - Session timeout
   - IP whitelisting (Enterprise)

7. **Danger Zone**
   - Transfer ownership
   - Delete organization

### 6. AuditLogView

**File:** `Lyra/Views/AuditLogView.swift`

**Purpose:** View all administrative actions

**Features:**
- Chronological timeline
- Filter by category (Members, Libraries, Settings, Security, Billing)
- Filter by action type
- Filter by actor
- Search by details
- Export to CSV
- Date range selector
- Auto-refresh (optional)

**Layout:**
```
┌─────────────────────────────────────┐
│  Audit Log                    [Export]│
│─────────────────────────────────────│
│  [All] [Members] [Libraries] [Security]│
│  Date: [Last 30 Days ▼]             │
│─────────────────────────────────────│
│  Today                              │
│  • 2:45 PM - John Doe               │
│    Member Invited                   │
│    Invited jane@example.com         │
│                                     │
│  • 1:30 PM - Sarah Smith            │
│    Settings Changed                 │
│    Updated notification preferences │
│                                     │
│  Yesterday                          │
│  • 4:15 PM - John Doe               │
│    Role Changed                     │
│    Promoted Sarah to Admin          │
│                                     │
│  [Load More...]                     │
└─────────────────────────────────────┘
```

---

## Key Features

### 1. Subscription Management

**Tiers:**

| Tier | Price/Month | Max Seats | Features |
|------|-------------|-----------|----------|
| **Free** | $0 | 5 | Basic collaboration, 1 library, 100 songs |
| **Starter** | $29.99 | 15 | Unlimited libraries, 1,000 songs, priority support |
| **Professional** | $99.99 | 50 | Analytics, audit log, version history, SSO ready |
| **Enterprise** | $299.99 | Unlimited | Custom branding, advanced security, dedicated support |

**Subscription Features:**

```swift
struct SubscriptionTier: Codable {
    case free
    case starter
    case professional
    case enterprise

    var features: [String] {
        switch self {
        case .free:
            return [
                "Up to 5 team members",
                "1 shared library",
                "100 songs per library",
                "Basic collaboration",
                "Community support"
            ]
        case .starter:
            return [
                "Up to 15 team members",
                "Unlimited libraries",
                "1,000 songs per library",
                "Real-time collaboration",
                "Priority support",
                "Offline access"
            ]
        case .professional:
            return [
                "Up to 50 team members",
                "Unlimited libraries & songs",
                "Team analytics dashboard",
                "Comprehensive audit log",
                "Version history (30 days)",
                "API access",
                "SSO ready",
                "Phone support"
            ]
        case .enterprise:
            return [
                "Unlimited team members",
                "Everything in Professional",
                "Custom branding",
                "Advanced security (2FA, IP whitelist)",
                "Custom domain",
                "Dedicated support",
                "SLA guarantee",
                "Migration assistance"
            ]
        }
    }
}
```

**Usage Tracking:**
```swift
class OrganizationManager {
    func trackUsage(for organization: Organization) -> UsageMetrics {
        return UsageMetrics(
            seatsUsed: organization.members?.count ?? 0,
            seatsAvailable: organization.maxSeats,
            librariesCreated: organization.libraries?.count ?? 0,
            totalSongs: calculateTotalSongs(organization),
            storageUsed: calculateStorageUsage(organization),
            apiCallsThisMonth: fetchAPICallCount(organization)
        )
    }
}
```

### 2. Role-Based Access Control (RBAC)

**Permission System:**

```swift
enum Permission: String, CaseIterable, Codable {
    // Read Permissions
    case viewLibraries = "View Libraries"
    case viewSongs = "View Songs"
    case viewMembers = "View Members"
    case viewAnalytics = "View Analytics"
    case viewAuditLog = "View Audit Log"

    // Write Permissions
    case createSongs = "Create Songs"
    case editSongs = "Edit Songs"
    case deleteSongs = "Delete Songs"
    case createLibraries = "Create Libraries"
    case editLibraries = "Edit Libraries"
    case deleteLibraries = "Delete Libraries"

    // Management Permissions
    case manageMembers = "Manage Members"
    case changeRoles = "Change Member Roles"
    case inviteMembers = "Invite Members"
    case removeMembers = "Remove Members"

    // Admin Permissions
    case changeSettings = "Change Settings"
    case manageBilling = "Manage Billing"
    case viewSensitiveData = "View Sensitive Data"
    case exportData = "Export Data"

    // Owner Permissions
    case transferOwnership = "Transfer Ownership"
    case deleteOrganization = "Delete Organization"
}
```

**Permission Enforcement:**
```swift
class OrganizationManager {
    func hasPermission(
        _ permission: Permission,
        user: OrganizationMember,
        in organization: Organization
    ) -> Bool {
        return user.role.permissions.contains(permission)
    }

    func requirePermission(
        _ permission: Permission,
        user: OrganizationMember,
        in organization: Organization
    ) throws {
        guard hasPermission(permission, user: user, in: organization) else {
            throw OrganizationError.insufficientPermissions(
                required: permission,
                userRole: user.role
            )
        }
    }
}
```

### 3. Comprehensive Audit Logging

**Auto-logged Actions:**
- All member changes (add, remove, role change, suspend)
- Library operations (create, delete, share)
- Settings modifications
- Security events (login, logout, 2FA changes)
- Billing updates

**Audit Log Features:**
```swift
class AuditLogger {
    func logAction(
        _ action: AuditAction,
        actor: OrganizationMember,
        organization: Organization,
        target: Any? = nil,
        details: String? = nil
    ) async {
        let entry = AuditLogEntry(
            timestamp: Date(),
            actorUserRecordID: actor.userRecordID,
            actorDisplayName: actor.displayName,
            action: action,
            category: action.category,
            targetID: extractID(target),
            targetName: extractName(target),
            details: details,
            ipAddress: getCurrentIPAddress(),
            deviceType: getCurrentDeviceType()
        )

        organization.auditLog?.append(entry)

        // Sync to CloudKit
        await syncAuditLog(entry, to: organization)

        // Notify admins if critical action
        if action.isCritical {
            await notifyAdmins(about: entry, in: organization)
        }
    }

    func exportAuditLog(
        for organization: Organization,
        format: ExportFormat = .csv
    ) async -> Data {
        let entries = organization.auditLog ?? []
        return formatEntries(entries, as: format)
    }
}
```

### 4. Team Settings Management

**Settings Inheritance:**
```
Organization Settings
        ↓ (defaults)
Shared Library Settings
        ↓ (overrides allowed)
Individual Song Settings
```

**Example:**
```swift
class TeamSettings {
    func applyDefaults(to library: SharedLibrary) {
        // Apply organization defaults
        library.defaultPermission = self.defaultLibraryPermission
        library.requireApproval = self.requireApprovalForNewMembers
        library.allowComments = self.enableComments
        library.enableVersionHistory = self.enableVersionHistory

        // Library can override these if needed
    }

    func validateSetting(_ setting: Setting, value: Any) throws {
        // Enforce tier restrictions
        switch setting {
        case .requireTwoFactorAuth:
            guard organization.subscriptionTier >= .enterprise else {
                throw SettingsError.featureNotAvailable(
                    feature: "Two-Factor Authentication",
                    requiredTier: .enterprise
                )
            }
        case .customDomain:
            guard organization.subscriptionTier >= .enterprise else {
                throw SettingsError.featureNotAvailable(
                    feature: "Custom Domain",
                    requiredTier: .enterprise
                )
            }
        default:
            break
        }
    }
}
```

---

## Integration Guide

### Step 1: Add Models to Schema

```swift
// LyraApp.swift
let schema = Schema([
    // ... existing models
    Organization.self,
    OrganizationMember.self,
    TeamSettings.self,
    AuditLogEntry.self
])
```

### Step 2: Initialize OrganizationManager

```swift
// LyraApp.swift
@main
struct LyraApp: App {
    @State private var organizationManager = OrganizationManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(organizationManager)
        }
    }
}
```

### Step 3: Add Team Directory to Navigation

```swift
// MainTabView.swift
TabView {
    LibraryView()
        .tabItem {
            Label("Library", systemImage: "music.note")
        }

    TeamDirectoryView()
        .tabItem {
            Label("Teams", systemImage: "person.3")
        }

    SettingsView()
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
}
```

### Step 4: Create Organization Flow

```swift
Button("Create Organization") {
    showCreateOrganization = true
}
.sheet(isPresented: $showCreateOrganization) {
    CreateOrganizationView()
}
```

### Step 5: Link Libraries to Organizations

```swift
// When creating a shared library within an organization
func createLibrary(in organization: Organization) async throws {
    let library = SharedLibrary(
        name: libraryName,
        organizationID: organization.id
    )

    // Apply organization defaults
    organization.settings.applyDefaults(to: library)

    // Add to organization
    organization.libraries?.append(library)

    // Create CloudKit share
    try await SharedLibraryManager.shared.createCloudKitShare(for: library)

    // Log action
    await AuditLogger.shared.logAction(
        .libraryCreated,
        actor: currentMember,
        organization: organization,
        target: library
    )
}
```

---

## Use Cases

### 1. Large Church Worship Team

**Setup:**
```swift
let organization = Organization(
    name: "First Community Church",
    organizationType: .church,
    subscriptionTier: .professional // 50 seats
)

// Invite team members
await organization.invite([
    OrganizationMember(email: "worship.leader@church.org", role: .admin),
    OrganizationMember(email: "pianist@church.org", role: .editor),
    OrganizationMember(email: "guitarist@church.org", role: .editor),
    // ... 20 more musicians as editors
    OrganizationMember(email: "soundtech@church.org", role: .member) // View only
])

// Create libraries
let sundayLibrary = SharedLibrary(name: "Sunday Services", in: organization)
let rehearsalLibrary = SharedLibrary(name: "Rehearsal Songs", in: organization)
let archiveLibrary = SharedLibrary(name: "Song Archive", in: organization)
```

**Usage:**
- Worship leader (Admin) plans setlists
- Musicians (Editors) add notes, transpose keys
- Sound tech (Member) views arrangements
- All changes logged in audit trail
- Team analytics show most-used songs

### 2. Music Therapy Practice

**Setup:**
```swift
let organization = Organization(
    name: "Healing Melodies Therapy",
    organizationType: .musicTherapy,
    subscriptionTier: .starter // 15 seats
)

// Invite therapists
await organization.invite([
    OrganizationMember(email: "director@therapy.com", role: .owner),
    OrganizationMember(email: "therapist1@therapy.com", role: .editor),
    OrganizationMember(email: "therapist2@therapy.com", role: .editor),
    OrganizationMember(email: "intern@therapy.com", role: .member)
])

// Create client-specific libraries
let clientALibrary = SharedLibrary(name: "Client A - Sessions", in: organization)
let clientBLibrary = SharedLibrary(name: "Client B - Sessions", in: organization)
let generalLibrary = SharedLibrary(name: "General Resources", in: organization)

// Configure privacy settings
organization.settings.allowPublicSharing = false
organization.settings.requireTwoFactorAuth = false // Not available on Starter tier
```

### 3. Professional Band

**Setup:**
```swift
let organization = Organization(
    name: "Indie Dreams Collective",
    organizationType: .band,
    subscriptionTier: .free // 5 seats
)

// Invite band members
await organization.invite([
    OrganizationMember(email: "lead@band.com", role: .owner),
    OrganizationMember(email: "guitar@band.com", role: .admin),
    OrganizationMember(email: "bass@band.com", role: .editor),
    OrganizationMember(email: "drums@band.com", role: .editor)
])

// Create libraries
let gigsLibrary = SharedLibrary(name: "Gig Setlists", in: organization)
let originalsSongs = SharedLibrary(name: "Original Songs", in: organization)

// Upgrade when needed
if bandGrows {
    await organization.upgrade(to: .starter) // 15 seats, unlimited libraries
}
```

---

## Security

### Access Control

**Permission Validation:**
```swift
// Before any administrative action
func performAction(
    _ action: OrganizationAction,
    by member: OrganizationMember,
    in organization: Organization
) async throws {
    // Validate role
    try OrganizationManager.shared.requirePermission(
        action.requiredPermission,
        user: member,
        in: organization
    )

    // Validate subscription tier
    if let tierRequirement = action.tierRequirement {
        guard organization.subscriptionTier >= tierRequirement else {
            throw OrganizationError.featureNotAvailable(
                feature: action.name,
                requiredTier: tierRequirement
            )
        }
    }

    // Execute action
    try await action.execute(in: organization)

    // Log action
    await AuditLogger.shared.logAction(
        action.auditAction,
        actor: member,
        organization: organization
    )
}
```

### Data Privacy

**Organization Data Boundaries:**
- Members can only see organizations they belong to
- Audit logs only visible to Admins and Owners
- Billing information only visible to Owner
- CloudKit shares enforce server-side permissions
- Sensitive data encrypted at rest

**GDPR Compliance:**
```swift
class OrganizationManager {
    // Export all user data
    func exportMemberData(
        for member: OrganizationMember,
        in organization: Organization
    ) async -> Data {
        let data = MemberDataExport(
            profile: member,
            activityLog: fetchMemberActivity(member),
            createdContent: fetchCreatedContent(member),
            auditLog: fetchAuditEntriesFor(member)
        )
        return try! JSONEncoder().encode(data)
    }

    // Delete all user data
    func deleteMemberData(
        for member: OrganizationMember,
        in organization: Organization
    ) async {
        // Remove from organization
        organization.members?.removeAll { $0.id == member.id }

        // Anonymize audit log entries
        for entry in organization.auditLog ?? [] {
            if entry.actorUserRecordID == member.userRecordID {
                entry.actorDisplayName = "Deleted User"
                entry.actorUserRecordID = "DELETED"
            }
        }

        // Transfer ownership if necessary
        if member.role == .owner {
            try await transferOwnership(organization, to: findNextAdmin())
        }
    }
}
```

---

## Testing

### Unit Tests

```swift
final class OrganizationTests: XCTestCase {
    func testCreateOrganization() async throws {
        let org = Organization(
            name: "Test Org",
            organizationType: .church,
            subscriptionTier: .free
        )

        XCTAssertEqual(org.name, "Test Org")
        XCTAssertEqual(org.currentSeats, 0)
        XCTAssertEqual(org.maxSeats, 5) // Free tier limit
    }

    func testRolePermissions() {
        let member = OrganizationMember(role: .member)
        let editor = OrganizationMember(role: .editor)
        let admin = OrganizationMember(role: .admin)
        let owner = OrganizationMember(role: .owner)

        XCTAssertTrue(member.role.permissions.contains(.viewSongs))
        XCTAssertFalse(member.role.permissions.contains(.editSongs))

        XCTAssertTrue(editor.role.permissions.contains(.editSongs))
        XCTAssertFalse(editor.role.permissions.contains(.manageMembers))

        XCTAssertTrue(admin.role.permissions.contains(.manageMembers))
        XCTAssertFalse(admin.role.permissions.contains(.deleteOrganization))

        XCTAssertTrue(owner.role.permissions.contains(.deleteOrganization))
    }

    func testSeatLimitEnforcement() async throws {
        let org = Organization(
            name: "Test Org",
            subscriptionTier: .free // 5 seats max
        )

        // Add 5 members
        for i in 1...5 {
            try await org.addMember(
                OrganizationMember(email: "user\\(i)@test.com", role: .member)
            )
        }

        XCTAssertEqual(org.currentSeats, 5)

        // Try to add 6th member
        XCTAssertThrowsError(
            try await org.addMember(
                OrganizationMember(email: "user6@test.com", role: .member)
            )
        ) { error in
            XCTAssertEqual(error as? OrganizationError, .seatLimitReached)
        }
    }
}
```

### Integration Tests

```swift
final class OrganizationIntegrationTests: XCTestCase {
    func testFullOrganizationFlow() async throws {
        // Create organization
        let org = try await OrganizationManager.shared.create(
            name: "Test Org",
            type: .church,
            tier: .starter
        )

        // Invite members
        try await org.invite(email: "user1@test.com", role: .editor)
        try await org.invite(email: "user2@test.com", role: .admin)

        // Accept invitations
        try await OrganizationManager.shared.acceptInvitation(
            to: org,
            from: "user1@test.com"
        )

        // Create library within organization
        let library = try await SharedLibraryManager.shared.createLibrary(
            name: "Test Library",
            in: org
        )

        XCTAssertEqual(org.libraries?.count, 1)
        XCTAssertEqual(library.organizationID, org.id)

        // Verify audit log
        XCTAssertEqual(org.auditLog?.count, 4) // Create, 2 invites, 1 library created

        // Cleanup
        try await OrganizationManager.shared.delete(org)
    }
}
```

### UI Tests

```swift
final class OrganizationUITests: XCTestCase {
    func testCreateOrganizationFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to team directory
        app.tabBars.buttons["Teams"].tap()

        // Tap create button
        app.buttons["Create Organization"].tap()

        // Fill in basic info
        let nameField = app.textFields["Organization Name"]
        nameField.tap()
        nameField.typeText("Test Church")

        app.buttons["Church/Worship Team"].tap()
        app.buttons["Next"].tap()

        // Select icon
        app.buttons["music.note.house"].tap()
        app.buttons["Next"].tap()

        // Select tier
        app.buttons["Starter Plan"].tap()
        app.buttons["Next"].tap()

        // Complete setup
        app.buttons["Create Organization"].tap()

        // Verify success
        XCTAssertTrue(app.staticTexts["Test Church"].waitForExistence(timeout: 5))
    }
}
```

---

## Roadmap

### Completed (Phase 4)
- ✅ Organization data models
- ✅ OrganizationMember with roles
- ✅ TeamSettings with 50+ options
- ✅ Comprehensive audit logging
- ✅ Subscription tier system
- ✅ UI components (all 6 views)
- ✅ OrganizationManager business logic

### In Progress
- 🔄 CloudKit sync for organizations
- 🔄 Billing integration (Stripe/RevenueCat)
- 🔄 Two-factor authentication
- 🔄 SSO integration

### Planned (Phase 5+)
- ⬜ API access (Professional+)
- ⬜ Custom branding (Enterprise)
- ⬜ Advanced analytics
- ⬜ Webhooks for integrations
- ⬜ Mobile device management
- ⬜ Advanced security features

---

## Conclusion

Organization Management provides the enterprise-grade features teams need for professional collaboration. With role-based access control, subscription management, comprehensive audit logging, and centralized administration, Lyra can serve teams of all sizes from small bands to large churches.

**Key Benefits:**
- Formal team structure
- Scalable subscription tiers
- Professional audit trail
- Centralized settings
- Enhanced security
- Better member management

**Next Steps:**
1. Review this documentation
2. Test organization creation flow
3. Configure subscription billing
4. Set up CloudKit sync for organizations
5. Deploy to TestFlight for team testing

---

**Documentation Version:** 1.0
**Last Updated:** January 23, 2026
**Related Docs:**
- SHARED_LIBRARIES_IMPLEMENTATION.md
- TEAM_ANALYTICS_GUIDE.md (see next doc)
- COLLABORATION_INTEGRATION_GUIDE.md
- COLLABORATION_TESTING_CHECKLIST.md
