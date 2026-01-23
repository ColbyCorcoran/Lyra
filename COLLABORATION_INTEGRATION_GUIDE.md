# Collaboration Integration Guide

Guide for integrating polished collaboration features into existing Lyra codebase.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                       │
│  (SongEditView, LibraryView, CollaborationUIComponents)    │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│                   Collaboration Layer                        │
│  • CollaborationEdgeCaseHandler                             │
│  • CollaborationValidator                                   │
│  • EnhancedCloudKitSync                                     │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│                    Data Layer                                │
│  • SwiftData Models (Song, SharedLibrary)                   │
│  • CloudKit (CKDatabase, CKRecord)                          │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. EnhancedCloudKitSync

**Purpose**: Production-ready sync with retry logic and error recovery

**Features**:
- Exponential backoff retry (2s, 5s, 10s)
- Batch operations (50 records per batch)
- Incremental sync (only fetch changes)
- Metadata caching (5-minute expiration)
- Network monitoring integration

**Usage**:
```swift
// In your view
@State private var syncCoordinator = EnhancedCloudKitSync.shared

// Trigger sync
Task {
    try await syncCoordinator.performFullSync()
}

// Check status
if case .syncing(let progress) = syncCoordinator.syncState {
    // Show progress
}
```

### 2. CollaborationEdgeCaseHandler

**Purpose**: Handle edge cases and race conditions

**Features**:
- Permission validation with caching
- Concurrent edit detection
- Entity locking mechanism
- Library/user deletion handling
- Presence management

**Usage**:
```swift
let handler = CollaborationEdgeCaseHandler.shared

// Validate permission before action
let result = await handler.validatePermission(
    userRecordID: currentUser,
    library: library,
    requiredPermission: .editor
)

if case .allowed = result {
    // Proceed with action
} else {
    // Show permission error
}

// Register active editor
handler.registerEditor(userRecordID: currentUser, for: songID)

// Detect concurrent edits
let editors = handler.detectConcurrentEdits(for: songID)
if editors.count > 1 {
    // Show warning
}
```

### 3. CollaborationValidator

**Purpose**: Security and input validation

**Features**:
- Malicious input detection
- Operation validation
- Rate limiting
- CloudKit record size checking

**Usage**:
```swift
let validator = CollaborationValidator.shared

// Validate input
let result = validator.validateSongContent(content)
if !result.isValid {
    // Show error
}

// Validate operation
let operationResult = await validator.validateOperation(
    .editSong(songID),
    userRecordID: currentUser,
    library: library
)

// Check rate limit
let limitResult = validator.checkRateLimit(
    userRecordID: currentUser,
    operation: "editSong",
    limit: 100,
    window: 60
)
```

### 4. Sync Status Components

**UI Components for User Feedback**:

- `SyncStatusIndicator` - Top-level sync status
- `SyncDetailsView` - Detailed sync information
- `NetworkStatusBanner` - Offline mode indicator
- `SyncProgressView` - Progress during sync
- `SyncErrorAlert` - User-friendly error messages

**Usage**:
```swift
// In navigation bar
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        SyncStatusIndicator()
    }
}

// Show offline banner
VStack {
    NetworkStatusBanner()
    // Your content
}

// Show during sync
if case .syncing(let progress) = syncState {
    SyncProgressView(
        progress: progress,
        message: "Syncing library..."
    )
}
```

### 5. Collaboration UI Components

**Edge Case Handling UI**:

- `ConcurrentEditingWarning` - Warn about multiple editors
- `PermissionDeniedView` - Permission errors
- `ActiveEditorsIndicator` - Show who's editing
- `LibraryDeletedAlert` - Handle deletion
- `UserRemovedAlert` - Handle removal
- `ConflictResolutionDialog` - Resolve conflicts

## Integration Steps

### Step 1: Update App Initialization

```swift
// In LyraApp.swift
@main
struct LyraApp: App {
    @State private var syncCoordinator = EnhancedCloudKitSync.shared

    init() {
        // Initialize sync on app launch
        Task {
            try? await syncCoordinator.performIncrementalSync()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Setup background sync
                    setupBackgroundSync()
                }
        }
    }

    private func setupBackgroundSync() {
        // Register background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lyra.sync",
            using: nil
        ) { task in
            Task {
                await syncCoordinator.performBackgroundSync()
                task.setTaskCompleted(success: true)
            }
        }
    }
}
```

### Step 2: Add Sync Status to Navigation

```swift
// In MainTabView.swift or LibraryView.swift
var body: some View {
    NavigationStack {
        // Content
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncStatusIndicator()
            }
        }
        .overlay(alignment: .top) {
            NetworkStatusBanner()
        }
    }
}
```

### Step 3: Validate Permissions Before Actions

```swift
// In song editing view
func saveSong() async {
    let validator = CollaborationValidator.shared
    let handler = CollaborationEdgeCaseHandler.shared

    // Validate permission
    let permResult = await handler.validatePermission(
        userRecordID: currentUser,
        library: library,
        requiredPermission: .editor
    )

    guard case .allowed = permResult else {
        showPermissionError()
        return
    }

    // Validate input
    let inputResult = validator.validateSongContent(songContent)
    guard inputResult.isValid else {
        showInputError(inputResult)
        return
    }

    // Check for concurrent edits
    let editors = handler.detectConcurrentEdits(for: song.id)
    if editors.count > 1 {
        showConcurrentEditWarning(editors: editors)
    }

    // Proceed with save
    await performSave()
}
```

### Step 4: Handle Edge Cases

```swift
// In song editing view
class SongEditViewModel: ObservableObject {
    @Published var showLibraryDeletedAlert = false
    @Published var showUserRemovedAlert = false
    @Published var showConflictDialog = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotificationHandlers()
    }

    private func setupNotificationHandlers() {
        // Library deleted
        NotificationCenter.default.publisher(for: .shouldCloseLibrary)
            .sink { [weak self] notification in
                guard let libraryID = notification.userInfo?["libraryID"] as? UUID else { return }
                if libraryID == self?.library.id {
                    self?.showLibraryDeletedAlert = true
                }
            }
            .store(in: &cancellables)

        // User removed
        NotificationCenter.default.publisher(for: .userPermissionsChanged)
            .sink { [weak self] notification in
                guard let userID = notification.userInfo?["userRecordID"] as? String else { return }
                if userID == self?.currentUser {
                    self?.showUserRemovedAlert = true
                }
            }
            .store(in: &cancellables)
    }
}

// In view
.alert("Library Deleted", isPresented: $viewModel.showLibraryDeletedAlert) {
    Button("OK") {
        dismiss()
    }
} message: {
    Text("This library was deleted by its owner")
}
```

### Step 5: Add Active Editors Indicator

```swift
// In song editing toolbar
.toolbar {
    ToolbarItem(placement: .principal) {
        ActiveEditorsIndicator(
            editors: activeEditors,
            currentUserID: currentUser
        )
    }
}

// Update active editors
.onAppear {
    CollaborationEdgeCaseHandler.shared.registerEditor(
        userRecordID: currentUser,
        for: song.id
    )
}
.onDisappear {
    CollaborationEdgeCaseHandler.shared.unregisterEditor(
        userRecordID: currentUser,
        from: song.id
    )
}
```

### Step 6: Implement Conflict Resolution

```swift
// When conflict detected
if let conflict = ConflictResolutionManager.shared.unresolvedConflicts.first {
    showConflictResolution(conflict)
}

func showConflictResolution(_ conflict: SyncConflict) {
    // Show conflict resolution dialog
    ConflictResolutionDialog(
        conflict: conflict,
        onResolve: { resolution in
            Task {
                await resolveConflict(conflict, resolution: resolution)
            }
        },
        onDismiss: {
            // User cancelled
        }
    )
}

func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async {
    let sync = EnhancedCloudKitSync.shared

    switch resolution {
    case .useLocal:
        // Push local version
        try? await sync.forceUpdateRemote(conflict)
    case .useRemote:
        // Accept remote version
        try? await sync.acceptRemoteVersion(conflict)
    case .keepBoth:
        // Create duplicate
        try? await sync.createDuplicateRecord(conflict)
    case .merge(let data):
        // Apply merged data
        try? await sync.applyMergedData(conflict, data: data)
    }

    // Mark resolved
    ConflictResolutionManager.shared.markResolved(conflict)
}
```

## Error Handling Best Practices

### 1. Network Errors

```swift
do {
    try await syncCoordinator.performFullSync()
} catch SyncError.networkUnavailable {
    // User-friendly message
    showAlert(
        title: "Connection Lost",
        message: "Your changes are saved locally and will sync when you're back online."
    )
} catch SyncError.quotaExceeded {
    showAlert(
        title: "iCloud Storage Full",
        message: "Please free up space in iCloud Settings to continue syncing.",
        action: ("Open Settings", openSettings)
    )
}
```

### 2. Permission Errors

```swift
guard case .allowed = permissionResult else {
    if case .denied(let reason) = permissionResult {
        showPermissionDeniedView(
            reason: reason,
            onRequestAccess: {
                // Send request to admin
            }
        )
    }
    return
}
```

### 3. Graceful Degradation

```swift
if !OfflineManager.shared.isOnline {
    // Work in offline mode
    saveToLocalDatabase()
    queueForSync()
    showOfflineBanner()
} else {
    // Normal sync
    syncToCloudKit()
}
```

## Performance Optimization

### 1. Batch Operations

```swift
// Instead of saving one at a time
for song in songs {
    try await save(song) // ❌ Slow
}

// Batch save
try await saveInBatches(songs) // ✅ Fast
```

### 2. Incremental Sync

```swift
// Instead of full sync every time
try await performFullSync() // ❌ Slow for large libraries

// Incremental sync
try await performIncrementalSync() // ✅ Fast - only changed records
```

### 3. Metadata Caching

```swift
// Check cache first
if let cached = getCachedMetadata(for: libraryID) {
    return cached // ✅ Instant
}

// Fetch from CloudKit
let metadata = try await fetchMetadata(libraryID) // Only if needed
cacheMetadata(metadata, for: libraryID)
```

## Testing Integration

### Unit Tests

```swift
func testSyncRetryLogic() async throws {
    let sync = EnhancedCloudKitSync.shared

    // Simulate network failure
    mockNetworkFailure()

    // Attempt sync
    try await sync.performFullSync()

    // Verify retry attempted
    XCTAssertEqual(retryCount, 3)
    XCTAssertEqual(retryDelays, [2.0, 5.0, 10.0])
}

func testPermissionValidation() async throws {
    let validator = CollaborationValidator.shared

    // Test denied permission
    let result = await validator.validateOperation(
        .deleteSong,
        userRecordID: viewerUser,
        library: library
    )

    XCTAssertEqual(result, .denied)
}
```

### Integration Tests

```swift
func testConcurrentEditing() async throws {
    // User A edits verse 1
    await editSong(userA, section: "verse1")

    // User B edits chorus
    await editSong(userB, section: "chorus")

    // Both save
    try await save(userA)
    try await save(userB)

    // Verify both changes present
    let merged = await fetchSong()
    XCTAssertTrue(merged.contains("verse1 changes"))
    XCTAssertTrue(merged.contains("chorus changes"))
}
```

### UI Tests

```swift
func testOfflineModeUI() throws {
    let app = XCUIApplication()

    // Enable airplane mode
    enableAirplaneMode()

    // Verify banner appears
    XCTAssertTrue(app.staticTexts["You're Offline"].exists)

    // Make changes
    app.textViews.firstMatch.tap()
    app.textViews.firstMatch.typeText("Offline edit")

    // Save
    app.buttons["Save"].tap()

    // Disable airplane mode
    disableAirplaneMode()

    // Verify sync happens
    wait(for: app.staticTexts["Syncing..."], timeout: 5)
    wait(for: app.staticTexts["Up to date"], timeout: 10)
}
```

## Monitoring & Debugging

### 1. Sync Logging

```swift
// Enable detailed logging
UserDefaults.standard.set(true, forKey: "enableSyncLogging")

// Logs will show:
// 📡 Fetching remote changes...
// 📤 Pushing batch 1/5 (50 records)
// ✅ Full sync completed successfully
// ❌ Sync error: Network unavailable
```

### 2. Error History

```swift
// View error history in sync details
let errors = syncCoordinator.errorHistory

// Export for debugging
let errorLog = errors.map { error in
    "\(error.timestamp): \(error.message)"
}.joined(separator: "\n")
```

### 3. Performance Metrics

```swift
// Track sync performance
let startTime = Date()
try await performFullSync()
let duration = Date().timeIntervalSince(startTime)

// Log if slow
if duration > 10 {
    print("⚠️ Slow sync: \(duration)s")
}
```

## Migration Guide

### From Old Sync to Enhanced Sync

```swift
// Old code
CloudKitSyncCoordinator.shared.performSync()

// New code
EnhancedCloudKitSync.shared.performIncrementalSync()

// Benefits:
// - Automatic retry on failure
// - Better error messages
// - Progress indication
// - Metadata caching
// - Rate limiting
```

### Adding Validation to Existing Code

```swift
// Old code
func saveSong() {
    song.save()
}

// New code with validation
func saveSong() async {
    let validator = CollaborationValidator.shared

    // Validate input
    let result = validator.validateSongContent(song.content)
    guard result.isValid else {
        showError(result)
        return
    }

    // Validate permission
    let permResult = await validatePermission()
    guard permResult.isAllowed else {
        showPermissionError()
        return
    }

    song.save()
}
```

## Troubleshooting

### Sync Not Working

1. Check network connection
2. Verify iCloud signed in
3. Check CloudKit dashboard for errors
4. Review error history
5. Try force full sync

### Conflicts Not Resolving

1. Check conflict resolution strategy
2. Verify both versions valid
3. Try manual resolution
4. Check audit log for changes

### Permission Errors

1. Verify user in library
2. Check permission level
3. Clear permission cache
4. Refresh from CloudKit

## Summary

Integration checklist:

- ✅ Add EnhancedCloudKitSync to app initialization
- ✅ Add SyncStatusIndicator to navigation
- ✅ Add NetworkStatusBanner to main views
- ✅ Validate permissions before actions
- ✅ Handle edge case notifications
- ✅ Add ActiveEditorsIndicator to editing views
- ✅ Implement conflict resolution UI
- ✅ Add comprehensive error handling
- ✅ Optimize with batching and caching
- ✅ Add comprehensive tests

Result: Rock-solid collaboration that users can trust! 🚀
