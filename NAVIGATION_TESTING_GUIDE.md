# Navigation Testing Guide

## Quick Navigation Test

### Basic Flow (30 seconds)

1. **Navigate to Song**
   - Open Library → All Songs
   - Tap "Amazing Grace"
   - ✅ Song displays with sticky header
   - ✅ Nav bar shows "Amazing Grace"
   - ✅ Back button shows "< Library"

2. **Navigate Back**
   - Tap back button
   - ✅ Returns to song list
   - ✅ Search/sort state preserved
   - ✅ Smooth animation

3. **Toolbar Buttons**
   - Navigate to any song
   - ✅ Edit button (✎) visible but grayed
   - ✅ Transpose button (↕) visible but grayed
   - ✅ More menu (⋯) opens

---

## Comprehensive Testing

### Test 1: Basic Navigation

**Setup:**
- Have at least 3 songs in library

**Steps:**
1. Tap on first song in list
2. Wait for SongDisplayView to load
3. Observe navigation bar
4. Tap back button
5. Verify returned to list

**Expected Results:**
- ✅ Push animation smooth (slide from right)
- ✅ Song content displays correctly
- ✅ Nav bar title = song title
- ✅ Back button shows previous view name
- ✅ Pop animation smooth (slide to right)
- ✅ Returns to exact scroll position
- ✅ No errors in console

---

### Test 2: View Tracking

**Setup:**
- Create new song: "Test Tracking"
- Note current date/time

**Steps:**
1. Tap "Test Tracking" song
2. View for a few seconds
3. Go back to list
4. Sort by "Recently Viewed"
5. Tap "Test Tracking" again

**Expected Results:**
- ✅ Song appears at top of "Recently Viewed" sort
- ✅ First view: timesViewed = 1
- ✅ Second view: timesViewed = 2
- ✅ lastViewed timestamp updates both times
- ✅ No lag when opening song

**Verification (Optional):**
```swift
// In debugger or with print statement
print("Times viewed: \(song.timesViewed)")
print("Last viewed: \(song.lastViewed ?? Date())")
```

---

### Test 3: Toolbar Buttons

**Edit Button:**
1. Navigate to any song
2. Look at top-left of nav bar
3. See pencil icon (✎)
4. Tap edit button
5. Verify nothing happens (disabled)

**Expected:**
- ✅ Button visible
- ✅ Button grayed out
- ✅ No action on tap

**Transpose Button:**
1. Look at top-right of nav bar
2. See up/down arrow icon (↕)
3. Tap transpose button
4. Verify nothing happens (disabled)

**Expected:**
- ✅ Button visible
- ✅ Button grayed out
- ✅ No action on tap

**More Menu:**
1. Look for ⋯ icon (ellipsis.circle)
2. Tap more menu
3. Menu appears with sections

**Expected:**
- ✅ Menu opens
- ✅ "Font Size" section with 3 options
- ✅ Divider
- ✅ Export section (grayed)
- ✅ Divider
- ✅ "Song Info" section (grayed)

---

### Test 4: Font Size Controls

**Increase Font:**
1. Navigate to song
2. Tap more menu (⋯)
3. Tap "Increase"
4. Observe text size change
5. Tap "Increase" again
6. Continue until max (24pt)

**Expected:**
- ✅ Font increases by 2pt each tap
- ✅ Chord alignment maintained
- ✅ Sticky header unaffected
- ✅ Stops at 24pt (button may dim or show toast)

**Decrease Font:**
1. Tap more menu
2. Tap "Decrease" multiple times
3. Continue until min (12pt)

**Expected:**
- ✅ Font decreases by 2pt each tap
- ✅ Chord alignment maintained
- ✅ Stops at 12pt

**Reset Font:**
1. Adjust font to non-default (not 16pt)
2. Tap more menu
3. Tap "Reset to Default"
4. Font returns to 16pt

**Expected:**
- ✅ Font resets to 16pt immediately
- ✅ Works from any font size

---

### Test 5: Navigation with Search

**Setup:**
- Have 5+ songs
- Know partial title (e.g., "Grace")

**Steps:**
1. In song list, tap search bar
2. Type "Grace"
3. List filters to matching songs
4. Tap "Amazing Grace"
5. View song
6. Tap back button
7. Observe list state

**Expected:**
- ✅ Search bar still shows "Grace"
- ✅ List still filtered
- ✅ Can continue typing to refine
- ✅ Can tap X to clear search

---

### Test 6: Navigation with Sort

**Setup:**
- Have 5+ songs
- Vary creation dates

**Steps:**
1. Sort by "Recently Added"
2. Tap top song (newest)
3. View song
4. Go back
5. Verify sort preserved

**Expected:**
- ✅ Sort menu still shows "Recently Added"
- ✅ List still in correct order
- ✅ Can change sort option
- ✅ Newly viewed song may move (if sorting by "Recently Viewed")

---

### Test 7: Swipe-Back Gesture

**Steps:**
1. Navigate to any song
2. Place finger on left edge of screen
3. Swipe right slowly
4. Stop halfway
5. Swipe back left (cancel)
6. Try again, swipe all the way right

**Expected:**
- ✅ Partial swipe shows both views
- ✅ Can cancel mid-swipe
- ✅ Full swipe navigates back
- ✅ Interactive animation smooth
- ✅ Back button still works after canceled swipe

---

### Test 8: Multiple Navigation

**Steps:**
1. Tap Song A
2. View, go back
3. Tap Song B
4. View, go back
5. Tap Song C
6. View, go back
7. Sort by "Recently Viewed"

**Expected:**
- ✅ Song C at top (most recent)
- ✅ Song B second
- ✅ Song A third
- ✅ All lastViewed timestamps correct
- ✅ All timesViewed = 1

---

### Test 9: Rapid Navigation

**Steps:**
1. Tap song row quickly
2. Immediately tap back
3. Immediately tap another song
4. Repeat 5 times rapidly

**Expected:**
- ✅ No crashes
- ✅ No visual glitches
- ✅ Each navigation completes
- ✅ View tracking increments correctly

---

### Test 10: Long Song Title

**Setup:**
- Create song with title: "This Is A Very Long Song Title That Should Truncate In The Navigation Bar"

**Steps:**
1. Tap song
2. Observe navigation bar

**Expected:**
- ✅ Title truncates with "..." (ellipsis)
- ✅ Back button still visible
- ✅ Toolbar buttons still visible
- ✅ No layout overflow

---

### Test 11: Empty Song Content

**Setup:**
- Create song with title but no content

**Steps:**
1. Tap song
2. Observe display

**Expected:**
- ✅ Sticky header shows (title, artist, metadata)
- ✅ Content area shows "No content available"
- ✅ Music note icon displays
- ✅ Can still navigate back
- ✅ Toolbar buttons present

---

### Test 12: Navigation During Load

**Setup:**
- Create song with very large content (5000+ chars)

**Steps:**
1. Tap song
2. Immediately tap back before fully loaded
3. Observe behavior

**Expected:**
- ✅ Navigation cancels gracefully
- ✅ Returns to list
- ✅ No crashes
- ✅ Can navigate to song again

---

### Test 13: Back Button vs Swipe

**Steps:**
1. Navigate to song using tap
2. Go back using back button
3. Navigate to same song
4. Go back using swipe gesture
5. Navigate to same song
6. Go back using either method

**Expected:**
- ✅ Both methods work identically
- ✅ Same animation speed
- ✅ Same state preservation
- ✅ timesViewed increments each time (3 total)

---

### Test 14: Navigation Stack Depth

**Steps:**
1. LibraryView → SongListView (via tab)
2. SongListView → SongDisplayView (via tap)
3. Tap back
4. Should be at SongListView
5. Tap back again (if possible)

**Expected:**
- ✅ First back: SongDisplayView → SongListView
- ✅ Second back: Can't go back (root of stack)
- ✅ Navigation stack properly managed
- ✅ No memory leaks

---

### Test 15: Dark Mode Navigation

**Steps:**
1. Enable dark mode
2. Navigate to song
3. Observe colors
4. Toggle back to light mode
5. Navigate to song again

**Expected:**
- ✅ Nav bar adapts to mode
- ✅ Toolbar icons visible
- ✅ Back button visible
- ✅ Song content adapts
- ✅ No color contrast issues

---

## Performance Testing

### Test 16: Navigation Speed

**Setup:**
- Have 20+ songs
- Stopwatch or timer

**Steps:**
1. Tap song
2. Time until fully loaded
3. Tap back
4. Time until list appears
5. Repeat 10 times

**Expected:**
- ✅ Average load time < 100ms
- ✅ No noticeable delay
- ✅ Consistent speed
- ✅ No progressive slowdown

---

### Test 17: Memory Usage

**Setup:**
- Xcode memory profiler open
- 50+ songs created

**Steps:**
1. Note baseline memory
2. Navigate through 20 songs
3. Go back to list
4. Force close app
5. Reopen and check memory

**Expected:**
- ✅ Memory increases temporarily during navigation
- ✅ Memory released on back
- ✅ No memory leaks after 20 navigations
- ✅ App doesn't crash

---

### Test 18: Database Performance

**Setup:**
- 100+ songs
- Database monitoring tool

**Steps:**
1. Navigate through 10 songs quickly
2. Monitor database writes
3. Check write speed

**Expected:**
- ✅ Each view = 1 write operation
- ✅ Write completes < 10ms
- ✅ No write queuing issues
- ✅ No database locks

---

## Edge Cases

### Test 19: Song Deleted While Viewing

**Steps:**
1. Have 2 devices or simulator instances
2. Device A: Navigate to "Test Song"
3. Device B: Delete "Test Song"
4. Device A: Try to navigate back

**Expected:**
- ✅ No crash
- ✅ Graceful handling
- ✅ Song no longer in list on Device A

---

### Test 20: Network Interruption (Future iCloud)

**Setup:**
- iCloud sync enabled (future feature)
- Navigate to song

**Steps:**
1. Disable network
2. Try to navigate
3. Re-enable network

**Expected:**
- ✅ Cached song still viewable
- ✅ No error messages
- ✅ Sync resumes when online

---

## Accessibility Testing

### Test 21: VoiceOver Navigation

**Steps:**
1. Enable VoiceOver
2. Navigate through song list
3. Double-tap to open song
4. Swipe to toolbar buttons
5. Navigate back

**Expected:**
- ✅ Song row announces title, artist, metadata
- ✅ "Button" announced for navigation
- ✅ Song content readable
- ✅ Toolbar buttons announced
- ✅ Back button findable and usable

---

### Test 22: Dynamic Type Navigation

**Steps:**
1. Set text size to largest
2. Navigate to song
3. Verify layout
4. Set text size to smallest
5. Navigate again

**Expected:**
- ✅ Nav bar title scales
- ✅ Toolbar buttons visible at all sizes
- ✅ Song content scales
- ✅ No layout breakage

---

## Issue Checklist

If any test fails, check:

### Navigation Doesn't Work
- ✅ Verify NavigationLink in SongListView
- ✅ Check NavigationStack in LibraryView
- ✅ Ensure destination: SongDisplayView(song:)

### Back Button Missing
- ✅ Verify NavigationStack present
- ✅ Check if multiple stacks (causes issues)
- ✅ Ensure .navigationBarBackButtonHidden not set

### Tracking Not Working
- ✅ Check modelContext injected
- ✅ Verify trackSongView() called
- ✅ Check try modelContext.save() succeeds
- ✅ Look for errors in console

### Toolbar Buttons Missing
- ✅ Verify .toolbar modifier present
- ✅ Check ToolbarItem placements
- ✅ Ensure not hidden by other modifiers

### Font Size Not Changing
- ✅ Verify fontSize state variable
- ✅ Check fontSize passed to SongSectionView
- ✅ Ensure min/max bounds (12-24)

### Swipe Back Not Working
- ✅ Check no .navigationBarBackButtonHidden(true)
- ✅ Verify no custom gesture conflicts
- ✅ Test on device (works better than simulator)

---

## Success Criteria

All tests should pass with:

✅ Smooth animations (60fps)
✅ Instant response to taps (<100ms)
✅ Proper state preservation
✅ Accurate view tracking
✅ All toolbar buttons visible
✅ Back navigation always works
✅ No crashes or errors
✅ Professional iOS feel

This comprehensive test suite ensures the navigation flow is robust and professional!
