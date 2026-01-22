# CloudKit Testing Checklist for Lyra

Use this checklist to thoroughly test CloudKit sync functionality before releasing to production.

---

## 📱 Pre-Testing Setup

### Environment Setup
- [ ] Xcode project has iCloud capability enabled
- [ ] CloudKit container is created and selected
- [ ] Lyra.entitlements file is added to project
- [ ] App is code-signed with development team
- [ ] Background Modes capability is enabled
- [ ] Two iOS devices available for testing (iPhone/iPad)
- [ ] Both devices signed into same iCloud account
- [ ] Both devices have internet connection (Wi-Fi or cellular)

### CloudKit Dashboard Access
- [ ] Can access [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
- [ ] Can see Lyra's container
- [ ] Development environment is selected
- [ ] Can view Records, Schema, and Logs

---

## 🧪 Basic Sync Testing

### Single Device Tests

#### Initial Setup
- [ ] App launches successfully on device
- [ ] Navigate to Settings → Sync & Backup
- [ ] iCloud Sync toggle is OFF by default
- [ ] Enable iCloud Sync toggle
- [ ] Sync status shows "Syncing..." briefly
- [ ] Sync status changes to "Sync complete" or "Success"
- [ ] "Last Synced" timestamp appears and is recent

#### Song Creation & Sync
- [ ] Create a new song with title "Test Song 1"
- [ ] Add content (chord chart)
- [ ] Save the song
- [ ] Wait 5-10 seconds
- [ ] Check "Last Synced" timestamp updates
- [ ] Go to CloudKit Dashboard → Data → Records
- [ ] Search for Song records
- [ ] Verify "Test Song 1" appears in CloudKit

#### Song Editing & Sync
- [ ] Edit "Test Song 1" - change title to "Test Song Modified"
- [ ] Save changes
- [ ] Wait 5-10 seconds
- [ ] "Last Synced" timestamp updates
- [ ] CloudKit Dashboard shows updated title

#### Song Deletion & Sync
- [ ] Delete "Test Song Modified"
- [ ] Confirm deletion
- [ ] Wait 5-10 seconds
- [ ] CloudKit Dashboard no longer shows the song (or marked as deleted)

---

## 🔄 Multi-Device Sync Testing

### Two-Device Sync

#### Setup Device B
- [ ] Install Lyra on second device (Device B)
- [ ] Sign in with same iCloud account
- [ ] Launch app
- [ ] Enable iCloud Sync in Settings
- [ ] Wait for initial sync to complete

#### Create on Device A → Sync to Device B
- [ ] On Device A: Create "Multi-Device Song 1"
- [ ] Wait 10 seconds
- [ ] On Device B: Pull to refresh or wait
- [ ] Verify "Multi-Device Song 1" appears on Device B
- [ ] Open the song on Device B
- [ ] Verify all content is identical

#### Edit on Device B → Sync to Device A
- [ ] On Device B: Edit "Multi-Device Song 1" - change key from G to C
- [ ] Save changes
- [ ] Wait 10 seconds
- [ ] On Device A: Verify song key updated to C
- [ ] Verify "Last Synced" timestamp updated on both devices

#### Delete on Device A → Sync to Device B
- [ ] On Device A: Delete "Multi-Device Song 1"
- [ ] Wait 10 seconds
- [ ] On Device B: Verify song is deleted

---

## ⚡ Conflict Resolution Testing

### Simultaneous Edits

#### Setup Conflict Scenario
- [ ] On Device A: Create "Conflict Test Song"
- [ ] Wait for sync to both devices
- [ ] **Turn OFF Wi-Fi/Cellular on BOTH devices**

#### Create Conflict
- [ ] On Device A (offline): Edit title to "Conflict Version A"
- [ ] On Device A: Edit content - add verse 1
- [ ] Save on Device A
- [ ] On Device B (offline): Edit title to "Conflict Version B"
- [ ] On Device B: Edit content - add verse 2
- [ ] Save on Device B
- [ ] **Turn ON Wi-Fi/Cellular on BOTH devices**
- [ ] Wait 30 seconds for sync

#### Resolve Conflict
- [ ] Conflict banner appears on one or both devices
- [ ] Tap "Resolve Conflicts"
- [ ] Conflict Resolution View shows the conflict
- [ ] View shows "Conflict Version A" and "Conflict Version B"
- [ ] Select "View Content Diff" (if implemented)
- [ ] Verify diff shows changes clearly
- [ ] Choose resolution:
  - [ ] Test "Keep Local" - local version preserved
  - [ ] Test "Keep Remote" - remote version adopted
  - [ ] Test "Keep Both" - duplicate created with suffix
  - [ ] Test "Merge" - combined version created (if implemented)
- [ ] Verify resolution syncs to both devices
- [ ] Verify no duplicate conflicts remain

---

## 📴 Offline Mode Testing

### Offline Changes Queue

#### Go Offline on Device A
- [ ] Turn OFF Wi-Fi and Cellular on Device A
- [ ] Verify "Offline" indicator appears in Sync Settings
- [ ] Create "Offline Song 1"
- [ ] Create "Offline Song 2"
- [ ] Edit an existing song
- [ ] Delete an existing song

#### Queue Verification
- [ ] Sync Settings shows queued operations count
- [ ] "Last Synced" timestamp doesn't update
- [ ] Sync status shows "Waiting for connection" or similar

#### Come Back Online
- [ ] Turn ON Wi-Fi/Cellular
- [ ] Sync status changes to "Syncing..."
- [ ] Wait for sync to complete
- [ ] Verify all queued changes processed:
  - [ ] "Offline Song 1" created
  - [ ] "Offline Song 2" created
  - [ ] Edited song shows changes
  - [ ] Deleted song is removed
- [ ] On Device B: Verify all changes appear
- [ ] Queued operations count returns to 0

---

## 📦 Large Data & Attachments Testing

### Attachment Sync

#### PDF Attachment
- [ ] Create song "PDF Test"
- [ ] Add PDF attachment (chord chart)
- [ ] Save song
- [ ] Wait for sync
- [ ] On Device B: Open "PDF Test"
- [ ] Verify PDF attachment is present
- [ ] Open PDF - verify it loads correctly

#### Image Attachment
- [ ] Create song "Image Test"
- [ ] Add image attachment (photo of music sheet)
- [ ] Save song
- [ ] Wait for sync
- [ ] On Device B: Verify image attachment syncs
- [ ] Verify image displays correctly

#### Large Content Sync
- [ ] Create song with 1000+ lines of content
- [ ] Save and sync
- [ ] Verify sync completes without errors
- [ ] On Device B: Verify full content appears
- [ ] Performance: Content loads in <2 seconds

---

## 🗂️ Shared Library Testing

### Create Shared Library

#### Setup
- [ ] Device A: Create new Shared Library "Test Worship Team"
- [ ] Set privacy to "Invite Only"
- [ ] Choose category: Worship
- [ ] Customize icon and color
- [ ] Save library
- [ ] Verify CloudKit share is created

#### Add Songs to Library
- [ ] Add 3 songs to the shared library
- [ ] Verify songs have `sharedLibrary` relationship
- [ ] Verify `isShared` property is true

### Invite Member

#### Generate Invite
- [ ] Open shared library
- [ ] Tap "Invite Members"
- [ ] Generate share link
- [ ] Copy link to clipboard
- [ ] QR code appears (if implemented)

#### Accept Invitation on Device B
- [ ] Send share link to Device B (AirDrop, Message, etc.)
- [ ] On Device B: Tap share link
- [ ] Lyra opens to invitation screen
- [ ] Library details displayed correctly
- [ ] Tap "Accept"
- [ ] Library appears in shared libraries list
- [ ] All 3 songs appear

### Collaborate on Shared Library

#### Edit Shared Song on Device B
- [ ] On Device B: Open a song from shared library
- [ ] Verify permission allows editing (Editor role)
- [ ] Edit the song - change title
- [ ] Save changes
- [ ] Verify `lastEditedBy` is set to Device B user

#### View Changes on Device A
- [ ] On Device A: Open same song
- [ ] Verify title change appears
- [ ] Activity feed shows edit by Device B user (if implemented)
- [ ] "Last Synced" updated

### Permission Testing

#### Viewer Role (if implemented)
- [ ] Create shared library with Viewer permission for test user
- [ ] On viewer device: Open song from library
- [ ] Verify edit button is disabled
- [ ] Attempt to edit - error message appears
- [ ] "You don't have permission to edit" message shown

#### Admin Role
- [ ] Promote member to Admin
- [ ] Verify admin can:
  - [ ] Add new members
  - [ ] Remove members
  - [ ] Change member permissions
  - [ ] Edit library settings

### Leave/Remove from Library

#### Member Leaves
- [ ] On Device B: Leave shared library
- [ ] Confirm leave action
- [ ] Library removed from Device B
- [ ] Songs still accessible on Device A
- [ ] On Device A: Member list updated

#### Owner Removes Member
- [ ] On Device A: Open Members list
- [ ] Remove a member
- [ ] Confirm removal
- [ ] Member's access revoked immediately
- [ ] Member's device shows "Access revoked" or removes library

---

## 🔐 Security & Privacy Testing

### iCloud Account Changes

#### Switch Accounts
- [ ] On Device A: Sign out of iCloud
- [ ] Verify sync stops
- [ ] Verify local data remains intact
- [ ] Sign in with different iCloud account
- [ ] Verify no data from previous account appears
- [ ] Sign back in with original account
- [ ] Verify data reappears after sync

### Data Isolation
- [ ] Verify each iCloud account sees only their own data
- [ ] Shared libraries only visible to invited members
- [ ] Private libraries not visible to others

---

## ⚙️ Settings & Controls Testing

### Sync Settings UI

#### Toggle Controls
- [ ] Turn OFF iCloud Sync
- [ ] Verify sync stops
- [ ] Verify "Last Synced" timestamp preserved
- [ ] Turn ON iCloud Sync
- [ ] Verify sync resumes

#### Sync Scope
- [ ] Change sync scope to "Songs Only"
- [ ] Verify only songs sync (books/sets don't sync)
- [ ] Change to "Sets & Performances Only"
- [ ] Verify behavior changes accordingly
- [ ] Change back to "Everything"

#### Cellular Sync
- [ ] Turn OFF "Sync Over Cellular"
- [ ] Switch to cellular connection
- [ ] Make changes
- [ ] Verify changes don't sync
- [ ] Sync status shows "Waiting for Wi-Fi"
- [ ] Switch to Wi-Fi
- [ ] Verify changes sync immediately

### Manual Sync
- [ ] Tap "Sync Now" button
- [ ] Verify sync initiates immediately
- [ ] Progress indicator appears
- [ ] "Last Synced" updates when complete

---

## 🚨 Error Handling Testing

### Network Errors

#### Poor Connection
- [ ] Enable "Simulate Poor Network" in Settings (if available)
- [ ] Make changes to songs
- [ ] Verify retries happen automatically
- [ ] Verify eventual sync when connection improves

#### No Connection
- [ ] Turn OFF all connectivity
- [ ] Make changes
- [ ] Turn ON connectivity
- [ ] Verify automatic sync resumes

### CloudKit Errors

#### Account Issues
- [ ] In CloudKit Dashboard, temporarily suspend container (if possible)
- [ ] Verify error message appears in app
- [ ] Verify graceful degradation (app still works locally)

#### Quota Exceeded (simulated)
- [ ] Check app behavior if approaching CloudKit limits
- [ ] Verify user is notified
- [ ] Verify suggestions to free space

### App Lifecycle

#### Force Quit During Sync
- [ ] Start a large sync operation
- [ ] Force quit app mid-sync
- [ ] Relaunch app
- [ ] Verify sync resumes from where it stopped
- [ ] No data corruption

#### Background/Foreground
- [ ] Start sync
- [ ] Put app in background
- [ ] Verify sync continues (background mode)
- [ ] Bring app to foreground
- [ ] Verify sync status updated correctly

---

## 📊 Performance Testing

### Large Dataset Performance

#### 100 Songs
- [ ] Create 100 songs
- [ ] Initiate sync
- [ ] Measure time to complete
- [ ] Target: <60 seconds for full sync
- [ ] On Device B: Measure time to receive all songs
- [ ] Target: <90 seconds

#### 500 Songs (stress test)
- [ ] Import or create 500 songs
- [ ] Sync to CloudKit
- [ ] Monitor memory usage (should stay <200MB)
- [ ] Verify app remains responsive
- [ ] On Device B: Initial sync completes
- [ ] Target: <5 minutes

### UI Responsiveness
- [ ] During active sync, scroll through song list
- [ ] Verify smooth scrolling (60 FPS)
- [ ] Open song during sync
- [ ] Verify instant load
- [ ] Navigate between views during sync
- [ ] No lag or freezing

---

## 🔄 Background Sync Testing

### Background Refresh

#### Setup
- [ ] Enable Background App Refresh in device Settings
- [ ] Verify "Background fetch" enabled in Xcode capabilities

#### Test Background Sync
- [ ] On Device A: Make changes to a song
- [ ] On Device B: Put app in background
- [ ] Wait 15-30 minutes
- [ ] On Device B: Bring app to foreground
- [ ] Verify changes synced in background
- [ ] Push notification appeared (if implemented)

---

## 🎯 CloudKit Dashboard Verification

### Data Integrity

#### Record Count
- [ ] In Dashboard, count Song records
- [ ] Verify count matches number of songs in app
- [ ] Check for duplicate records
- [ ] Verify no orphaned records

#### Record Structure
- [ ] Open a Song record in Dashboard
- [ ] Verify all fields populated correctly:
  - [ ] title
  - [ ] artist
  - [ ] content
  - [ ] originalKey
  - [ ] createdAt
  - [ ] modifiedAt
  - [ ] sharedLibrary (if shared)
  - [ ] lastEditedBy (if shared)

#### Relationships
- [ ] Verify Song ↔ Book relationships intact
- [ ] Verify Song ↔ SharedLibrary relationships correct
- [ ] Verify SharedLibrary ↔ LibraryMember relationships correct

---

## ✅ Production Readiness Checklist

Before submitting to App Store:

### Functionality
- [ ] All basic sync tests pass
- [ ] Multi-device sync works flawlessly
- [ ] Conflict resolution works correctly
- [ ] Offline mode queues and syncs properly
- [ ] Attachments sync completely
- [ ] Shared libraries work end-to-end
- [ ] Permission system enforces correctly

### Performance
- [ ] Large datasets sync in reasonable time
- [ ] UI remains responsive during sync
- [ ] Memory usage stays under 200MB
- [ ] No crashes during extended testing
- [ ] Background sync works reliably

### User Experience
- [ ] Sync status is always clear to user
- [ ] Error messages are helpful and actionable
- [ ] "Last Synced" timestamp always accurate
- [ ] Conflict UI is intuitive
- [ ] No data loss scenarios

### Security & Privacy
- [ ] No data leaks between iCloud accounts
- [ ] Shared library permissions enforce correctly
- [ ] User can disable sync anytime
- [ ] Local data preserved when sync off

### TestFlight Testing
- [ ] App tested on TestFlight (Production environment)
- [ ] Multiple beta testers confirmed sync works
- [ ] No CloudKit errors in production
- [ ] Feedback from testers is positive

---

## 📝 Test Results Template

Use this template to document test results:

```markdown
## Test Session: [Date]

**Tester:** [Name]
**Devices:** [iPhone 14 Pro, iPad Air]
**iOS Version:** [iOS 17.2]
**App Version:** [1.0 (1)]

### Tests Performed:
- ✅ Basic sync: PASS
- ✅ Multi-device sync: PASS
- ⚠️ Conflict resolution: PARTIAL (see notes)
- ✅ Offline mode: PASS
- ✅ Large attachments: PASS
- ✅ Shared libraries: PASS

### Issues Found:
1. Conflict UI takes 3-4 seconds to load large diffs
2. Background sync sometimes delayed 20+ minutes
3. Cellular sync toggle doesn't immediately stop sync in progress

### Notes:
- Overall sync is reliable and fast
- Shared library collaboration works great
- Need to optimize diff view performance

### Recommendation:
🟢 Ready for TestFlight
🟡 Not quite ready (minor issues)
🔴 Needs more work (major issues)
```

---

## 🐛 Common Issues & Solutions

### "CloudKit Not Available"
- **Check:** Device signed into iCloud
- **Check:** Container exists in CloudKit Dashboard
- **Check:** Entitlements file correctly configured

### "Sync Stuck at 'Syncing...'"
- **Try:** Force quit app and relaunch
- **Try:** Toggle sync OFF then ON
- **Try:** Check CloudKit Dashboard logs for errors

### "Conflicts Not Appearing"
- **Check:** Conflict detection implemented in CloudKitSyncCoordinator
- **Check:** Both versions actually differ
- **Check:** Timestamps are different

### "Shared Library Not Appearing on Second Device"
- **Check:** Both devices signed into same iCloud account
- **Check:** Invitation was accepted
- **Check:** CloudKit share record exists in Dashboard
- **Try:** Force sync on receiving device

---

## 🎉 Testing Complete!

Once all tests pass:

1. ✅ Document all test results
2. ✅ Fix any issues found
3. ✅ Re-test failed scenarios
4. ✅ Get sign-off from stakeholders
5. ✅ Proceed to TestFlight beta
6. ✅ Monitor beta tester feedback
7. ✅ Submit to App Store when ready!

**Happy Testing! 🧪☁️**
