# Collaboration Testing Checklist

Comprehensive testing checklist for Phase 5 collaboration features in Lyra.

## 1. Sync Reliability Tests

### Network Conditions

- [ ] **Poor Network (Weak WiFi)**
  - Start sync with full WiFi
  - Switch to weak WiFi mid-sync
  - Verify retry logic kicks in
  - Verify sync completes successfully
  - Check error messages are helpful

- [ ] **Airplane Mode → Reconnect**
  - Edit songs while offline
  - Enable airplane mode
  - Verify "Offline Mode" banner appears
  - Make 5+ changes
  - Disable airplane mode
  - Verify all changes sync automatically
  - Check sync status indicator updates

- [ ] **Cellular Data**
  - Switch to cellular data
  - Verify sync respects "Sync over Cellular" setting
  - Test with setting ON
  - Test with setting OFF
  - Verify banner shows network type

### Large Library Sync

- [ ] **500+ Songs Sync**
  - Create library with 500+ songs
  - Clear local data
  - Perform full sync
  - Verify batching works (50 songs per batch)
  - Check progress indicator updates correctly
  - Verify no memory issues
  - Check all songs synced correctly
  - Test incremental sync after full sync

### Multi-Device Sync

- [ ] **3+ Devices**
  - Add same library to 3 devices (iPhone, iPad, Mac)
  - Make different changes on each device
  - Verify all changes propagate to all devices
  - Check sync timestamps are correct
  - Verify no data loss
  - Test sync order independence

### Concurrent Edits

- [ ] **Multiple Users, Different Songs**
  - 5 users in shared library
  - Each edits different song simultaneously
  - Verify no conflicts
  - Check all edits saved
  - Verify presence indicators show all editors

- [ ] **Multiple Users, Same Song**
  - 2+ users edit same song
  - Different sections edited
  - Verify conflict detection
  - Test auto-merge for non-overlapping changes
  - Check manual resolution UI appears for conflicts
  - Verify merged content is correct

## 2. Collaboration Scenarios

### Team Collaboration

- [ ] **5 Users in Library**
  - Create library with 5 members
  - Different permission levels (Viewer, Editor, Admin)
  - Each user performs actions within their permissions
  - Verify permission enforcement
  - Test activity feed shows all actions

### Simultaneous Editing

- [ ] **Edit Different Songs**
  - User A edits Song 1
  - User B edits Song 2
  - User C edits Song 3
  - All save simultaneously
  - Verify all changes saved
  - No conflicts detected

- [ ] **Edit Same Song**
  - User A edits verse 1
  - User B edits chorus
  - Both save simultaneously
  - Verify auto-merge works
  - Check "Others are editing" warning appears
  - Test active editors indicator

### Create/Delete Conflicts

- [ ] **Delete While Editing**
  - User A deletes song
  - User B editing same song
  - Verify User B sees "Song deleted" alert
  - Check User B's changes saved to drafts
  - Test recovery options

- [ ] **Create Duplicates**
  - User A creates song "Amazing Grace"
  - User B creates song "Amazing Grace"
  - Offline, then sync
  - Verify conflict handled gracefully
  - Check both songs preserved or merged

### Permission Edge Cases

- [ ] **Permission Downgrade During Edit**
  - User editing song as Editor
  - Admin changes permission to Viewer
  - Verify user can finish current edit
  - Next edit attempt shows permission error
  - Check graceful degradation

- [ ] **User Removed During Edit**
  - User actively editing song
  - Owner removes user from library
  - Verify user sees "Access removed" alert
  - Check local changes saved
  - Test read-only mode engaged

## 3. Error Handling

### Network Failures

- [ ] **Mid-Sync Network Loss**
  - Start sync
  - Kill network mid-way
  - Verify sync pauses gracefully
  - Restore network
  - Verify sync resumes automatically
  - Check retry with exponential backoff

- [ ] **CloudKit Server Down**
  - Simulate CloudKit unavailable
  - Verify error message: "CloudKit temporarily unavailable"
  - Check retry scheduled
  - Verify queued operations preserved

### Storage Limits

- [ ] **iCloud Storage Full**
  - Fill iCloud storage
  - Attempt to sync large song
  - Verify error: "iCloud Storage Full"
  - Check action button: "Manage Storage"
  - Test graceful degradation (local only)

- [ ] **CloudKit Quota Exceeded**
  - Exceed CloudKit quota
  - Verify error message shown
  - Check operations queued
  - Test retry after quota reset

### Permission Errors

- [ ] **Not Authenticated**
  - Sign out of iCloud
  - Attempt sync
  - Verify error: "iCloud Sign-In Required"
  - Check helpful message
  - Test Settings link

- [ ] **Permission Denied**
  - User tries to edit with Viewer permission
  - Verify error: "Editor permission required"
  - Check "Request Access" button
  - Test request flow

### Graceful Degradation

- [ ] **Offline Mode**
  - Work completely offline for 1 hour
  - Create 10 songs
  - Edit 20 songs
  - Delete 5 songs
  - Go online
  - Verify all changes sync correctly
  - Check conflict resolution for any overlaps

## 4. Performance

### CloudKit Query Optimization

- [ ] **Large Query Performance**
  - Query 1000+ songs
  - Verify batching (50 per query)
  - Check query time < 5 seconds
  - Test pagination works
  - Verify memory usage reasonable

### Batch Operations

- [ ] **Bulk Song Import**
  - Import 100 songs at once
  - Verify batched (50 per batch)
  - Check progress indicator
  - Test pause/resume
  - Verify all songs saved

- [ ] **Bulk Delete**
  - Select 50 songs
  - Delete all
  - Verify batched operation
  - Check undo capability
  - Test sync to CloudKit

### Metadata Caching

- [ ] **Shared Library Metadata**
  - Open shared library
  - Check metadata cached
  - Close and reopen
  - Verify loads from cache
  - Test cache expiration (5 minutes)
  - Check fresh fetch after expiration

### Network Call Reduction

- [ ] **Incremental Sync**
  - Full sync complete
  - Make 5 changes
  - Sync again
  - Verify only changed records fetched
  - Check network traffic < 100KB

## 5. UI/UX Polish

### Sync Status Indicators

- [ ] **Status Icon**
  - Verify shows: ✓ (synced), ↻ (syncing), ⏸ (paused), ⚠️ (error)
  - Check rotating animation while syncing
  - Test tap opens sync details
  - Verify color coding (green/blue/orange/red)

- [ ] **Progress Bar**
  - Shows during sync
  - Updates smoothly
  - Displays percentage
  - Shows current operation

### Error Messages

- [ ] **User-Friendly Errors**
  - Network error: "Connection lost - will retry"
  - Storage full: "iCloud storage full - free up space"
  - Permission: "You need Editor permission"
  - Rate limit: "Too many requests - retry in 30s"
  - All have actionable buttons

### Loading States

- [ ] **Skeleton Loading**
  - Opening library shows skeleton
  - Smooth transition to content
  - No flashing/jumping
  - Reasonable placeholders

- [ ] **Inline Loading**
  - Saving shows spinner
  - Deleting shows loading
  - All actions have feedback
  - No blocking dialogs for quick operations

### Offline Indicators

- [ ] **Offline Banner**
  - Appears immediately when offline
  - Orange color
  - Shows queued operations count
  - Dismissible but reappears
  - Auto-hides when online

### Smooth Animations

- [ ] **Sync Transitions**
  - Status changes animate smoothly
  - Progress bar smooth
  - Conflict alerts slide in
  - No jarring changes

## 6. Edge Cases

### Library Deletion

- [ ] **Viewing Deleted Library**
  - User viewing library
  - Owner deletes library
  - Verify user sees alert
  - Check graceful exit
  - Test local data preserved

- [ ] **Editing Deleted Song**
  - User editing song
  - Another user deletes song
  - Verify alert: "Song was deleted"
  - Check changes saved to drafts
  - Test restore option

### Permission Changes

- [ ] **Conflicting Permission Changes**
  - Admin A changes User C to Editor
  - Admin B changes User C to Viewer
  - Both offline, then sync
  - Verify conflict resolved (last write wins)
  - Check audit log

- [ ] **Permission Upgrade During Edit**
  - Viewer opens song (read-only)
  - Admin upgrades to Editor
  - Verify edit button appears
  - Check seamless transition

### Presence System

- [ ] **Presence Updates**
  - User A opens song
  - User B sees "User A viewing"
  - User A starts editing
  - User B sees "User A editing"
  - User A goes offline
  - User B sees "User A offline" after 30s timeout

- [ ] **Stale Presence**
  - User's app crashes
  - Presence shows "editing" for 5 minutes
  - Verify cleanup after timeout
  - Check other users can edit

## 7. Security

### Permission Enforcement

- [ ] **Client-Side Validation**
  - Viewer cannot edit (UI disabled)
  - Viewer cannot delete (UI hidden)
  - Editor cannot manage members
  - Admin cannot delete library

- [ ] **Server-Side Validation**
  - Force edit as Viewer via API
  - Verify rejected by CloudKit
  - Check error logged
  - Test all permission levels

### Malicious Input

- [ ] **SQL Injection Attempts**
  - Song title: `"; DROP TABLE songs; --`
  - Verify properly escaped
  - Check no database corruption

- [ ] **XSS Attempts**
  - Song content: `<script>alert('XSS')</script>`
  - Verify sanitized
  - Check renders as text

- [ ] **Path Traversal**
  - Filename: `../../etc/passwd`
  - Verify blocked
  - Check stays in sandbox

### Action Validation

- [ ] **Delete Own Library**
  - Owner can delete
  - Admin cannot delete
  - Editor cannot delete
  - Viewer cannot delete

- [ ] **Remove Owner**
  - Cannot remove library owner
  - Verify blocked
  - Check error message

### Unauthorized Access

- [ ] **Revoked Access**
  - User removed from library
  - User attempts to access via deep link
  - Verify blocked
  - Check error: "Access revoked"

## 8. Stress Tests

### High Concurrency

- [ ] **10 Users Editing**
  - 10 users in library
  - All edit different songs
  - All save simultaneously
  - Verify all changes saved
  - Check no data corruption

### Large Content

- [ ] **Huge Song File**
  - Song with 50,000 lines
  - Verify CloudKit size limit enforced
  - Check chunking if implemented
  - Test performance

### Rapid Actions

- [ ] **Rapid Fire Edits**
  - Edit song
  - Save
  - Edit again
  - Save
  - Repeat 20 times in 10 seconds
  - Verify all saves succeed
  - Check no race conditions

## Success Criteria

All tests must pass with:

- ✅ No data loss
- ✅ No crashes
- ✅ Helpful error messages
- ✅ Smooth user experience
- ✅ Correct conflict resolution
- ✅ Proper permission enforcement
- ✅ Reasonable performance (<3s for common operations)

## Testing Tools

- **Network Link Conditioner** (Xcode → Settings → Network)
- **CloudKit Dashboard** (monitor operations)
- **Console.app** (view logs)
- **Instruments** (memory/performance)
- **Multiple physical devices** (real-world testing)

## Automated Tests

Consider implementing:

- Unit tests for sync logic
- Integration tests for CloudKit operations
- UI tests for collaboration flows
- Performance tests for large libraries
- Chaos engineering tests (random network failures)
