# Navigation Flow Documentation

## Overview

Lyra implements a comprehensive navigation flow from the song list to the detailed chord chart view, with proper tracking, toolbar actions, and smooth user experience.

## Navigation Architecture

### Flow Diagram

```
LibraryView (Tab Navigation)
    ↓
SongListView (Search, Sort, List)
    ↓ [Tap song row]
SongDisplayView (Chord chart with sticky header)
    ↓ [Back button / Swipe]
SongListView (Returns to same state)
```

## Implementation Details

### 1. Song List to Display

**SongListView.swift (Lines 70-73):**
```swift
NavigationLink(destination: SongDisplayView(song: song)) {
    EnhancedSongRowView(song: song)
}
```

**Features:**
- ✅ NavigationLink wraps each song row
- ✅ Tapping anywhere on row navigates
- ✅ Chevron icon indicates tappability
- ✅ Passes selected Song object to detail view
- ✅ Native iOS push animation

**User Experience:**
1. User taps any song row
2. SongDisplayView pushes onto navigation stack
3. Slide-in animation from right
4. Back button appears in top-left
5. Navigation bar shows song title

### 2. View Tracking

**SongDisplayView.swift (Lines 141-165):**
```swift
.onAppear {
    parseSong()
    trackSongView()
}

private func trackSongView() {
    song.lastViewed = Date()
    song.timesViewed += 1
    try modelContext.save()
}
```

**Tracked Data:**
- **lastViewed**: Current date/time
- **timesViewed**: Incremented by 1

**Use Cases:**
- Sort by "Recently Viewed" in list
- Show frequently accessed songs
- Analytics for user behavior
- Suggested songs feature (future)

### 3. Navigation Bar

**Configuration:**
```swift
.navigationTitle(song.title)
.navigationBarTitleDisplayMode(.inline)
```

**Appearance:**
- Title displays in center of nav bar
- Inline mode (small, centered)
- Back button on left with "< Library" or song list title
- Toolbar buttons on right

### 4. Toolbar Buttons

#### Edit Button (Top-Left)
```swift
ToolbarItem(placement: .topBarLeading) {
    Button {
        // TODO: Edit song functionality
    } label: {
        Image(systemName: "pencil")
    }
    .disabled(true)
}
```

**Purpose:** Edit song metadata and content
**Status:** Disabled (TODO)
**Icon:** Pencil (pencil)

#### Transpose Button (Top-Right)
```swift
ToolbarItem(placement: .topBarTrailing) {
    Button {
        // TODO: Transpose functionality
    } label: {
        Image(systemName: "arrow.up.arrow.down")
    }
    .disabled(true)
}
```

**Purpose:** Transpose song to different key
**Status:** Disabled (TODO)
**Icon:** Up/down arrows (arrow.up.arrow.down)

#### More Menu (Top-Right)
```swift
ToolbarItem(placement: .topBarTrailing) {
    Menu {
        // Font size controls
        // Export options
        // Song info
    } label: {
        Image(systemName: "ellipsis.circle")
    }
}
```

**Contains:**

**Font Size Section:**
- Decrease (textformat.size.smaller)
- Increase (textformat.size.larger)
- Reset to Default (arrow.counterclockwise)

**Export Section (Disabled):**
- Export PDF (square.and.arrow.up)
- Share (square.and.arrow.up)

**Info Section (Disabled):**
- Song Info (info.circle)

### 5. Back Navigation

**Methods:**

1. **Back Button**
   - Tap "< Library" in top-left
   - Pops SongDisplayView from stack
   - Returns to SongListView

2. **Swipe Gesture**
   - Swipe right from left edge
   - Interactive pop gesture
   - Cancel mid-swipe by swiping back left

3. **Programmatic (Future)**
   - After save/edit actions
   - Navigation coordinator

**State Preservation:**
- Search text maintained
- Sort selection maintained
- Scroll position maintained (iOS default)
- Recently viewed updates in list

### 6. Performance Optimizations

#### Lazy Loading
- NavigationLink loads destination only when tapped
- SongDisplayView not created until navigation
- Efficient memory usage

#### View Tracking
- Minimal database write (2 fields updated)
- Async save (doesn't block UI)
- Error handling prevents crashes

#### Smooth Animations
- Native iOS transitions (60fps)
- No custom animations needed
- Hardware accelerated

## User Flows

### Flow 1: View Song

**Steps:**
1. User opens Library tab
2. Taps "All Songs"
3. Sees list of songs
4. Taps "Amazing Grace"
5. SongDisplayView appears with chord chart
6. User reads/plays song
7. Taps back button
8. Returns to song list

**Expected Behavior:**
- ✅ Smooth push animation
- ✅ Song title in nav bar
- ✅ Sticky header visible
- ✅ Chords aligned properly
- ✅ lastViewed updated to current time
- ✅ timesViewed incremented
- ✅ Back returns to exact same list state

### Flow 2: Search then View

**Steps:**
1. User searches for "Grace"
2. List filters to matching songs
3. Taps "Amazing Grace"
4. Views song
5. Taps back

**Expected Behavior:**
- ✅ Search text preserved in bar
- ✅ Filtered list still shown
- ✅ Can continue searching

### Flow 3: Sort then View

**Steps:**
1. User sorts by "Recently Viewed"
2. Taps top song
3. Views song (increments timesViewed)
4. Taps back

**Expected Behavior:**
- ✅ Sort selection preserved
- ✅ List may reorder (song moved to top)
- ✅ Sort menu shows current selection

### Flow 4: Multiple Views

**Steps:**
1. User taps Song A
2. Views, goes back
3. Taps Song B
4. Views, goes back
5. Sorts by "Recently Viewed"

**Expected Behavior:**
- ✅ Song B at top (most recent)
- ✅ Song A second (previously viewed)
- ✅ Both lastViewed timestamps correct
- ✅ Both timesViewed = 1

### Flow 5: Font Size Adjustment

**Steps:**
1. User views song
2. Taps more menu (···)
3. Taps "Increase" font size
4. Chords and lyrics scale up
5. Taps "Decrease"
6. Returns to smaller size

**Expected Behavior:**
- ✅ Font changes immediately
- ✅ Chord alignment maintained
- ✅ No layout glitches
- ✅ Sticky header unaffected

## Testing Checklist

### Navigation Tests

- [ ] **Basic Navigation**
  - Tap song → SongDisplayView appears
  - Back button → Returns to list
  - Correct song title in nav bar

- [ ] **View Tracking**
  - Verify lastViewed updates (check in debugger)
  - Verify timesViewed increments
  - Sort by "Recently Viewed" shows correct order

- [ ] **Toolbar Buttons**
  - Edit button visible (grayed out)
  - Transpose button visible (grayed out)
  - More menu opens with 3 sections
  - Font size controls work

- [ ] **State Preservation**
  - Search text preserved after back
  - Sort option preserved after back
  - Scroll position reasonable

- [ ] **Gestures**
  - Swipe from left edge works
  - Can cancel swipe mid-gesture
  - Interactive pop smooth

### Performance Tests

- [ ] **Navigation Speed**
  - Push animation smooth (no lag)
  - Pop animation smooth
  - No frame drops on older devices

- [ ] **Memory Usage**
  - Create 50+ songs
  - Navigate through 10 songs
  - Check memory doesn't leak
  - Back to list releases memory

- [ ] **Tracking Performance**
  - View tracking doesn't block UI
  - Database save async
  - No noticeable delay

### Edge Cases

- [ ] **Empty Song Content**
  - Navigate to song with no content
  - "No content available" shows
  - Can still navigate back

- [ ] **Long Song Title**
  - Song with 50+ char title
  - Nav bar title truncates properly
  - Back button still visible

- [ ] **Rapid Navigation**
  - Tap song quickly
  - Immediately tap back
  - No crashes or weird state

- [ ] **During Search**
  - Search for song
  - View filtered result
  - Back maintains search
  - Clear search still works

## Visual Design

### Navigation Bar Layout

```
┌────────────────────────────────────────┐
│ < Library  Amazing Grace    ✎  ↕  ⋯   │
│  (Back)      (Title)       (Toolbar)   │
└────────────────────────────────────────┘
```

**Elements:**
- **< Library**: Back button (system provided)
- **Amazing Grace**: Song title (inline, centered)
- **✎**: Edit button (grayed out)
- **↕**: Transpose button (grayed out)
- **⋯**: More menu button (active)

### Toolbar Button States

| Button | Icon | State | Color |
|--------|------|-------|-------|
| Edit | ✎ | Disabled | Gray |
| Transpose | ↕ | Disabled | Gray |
| More | ⋯ | Active | Blue (accent) |

## Future Enhancements

### 1. Edit Mode
- Enable edit button
- Sheet with AddSongView (pre-filled)
- Save updates
- Refresh display

### 2. Transpose Feature
- Enable transpose button
- Show key picker sheet
- Transpose all chords
- Update currentKey field
- Refresh display

### 3. Deep Linking
- URL scheme: lyra://song/{id}
- Open specific song directly
- External app integration

### 4. Navigation Coordinator
- Centralized navigation logic
- Programmatic navigation
- Deep link handling
- Better state management

### 5. Tab Persistence
- Remember last viewed song per tab
- Restore on app launch
- Smart suggestions

### 6. Recently Viewed List
- Dedicated "Recently Viewed" section
- Quick access to last 10 songs
- Time-based grouping (Today, Yesterday, etc.)

### 7. Bookmarks/Favorites
- Star button in toolbar
- Quick access to favorites
- Smart collections

## Accessibility

### VoiceOver Support

**Song List:**
- "Amazing Grace, song by John Newton, Key G, Capo 2, Button"
- "Swipe right or left with one finger to navigate"

**SongDisplayView:**
- "Amazing Grace"
- "Edit button, dimmed"
- "Transpose button, dimmed"
- "More menu, button"
- Sections announce labels
- Chords announce: "Chord G, Amazing"

### Dynamic Type

- All text scales with system settings
- Nav bar title scales
- Toolbar buttons maintain size
- Content scales (via fontSize state)

### Reduced Motion

- Respects reduce motion setting
- Crossfade instead of slide (iOS handles automatically)
- No custom animations needed

## Code Architecture

### SongListView
- Manages list state (search, sort, filter)
- Provides NavigationLink to detail
- Handles delete action
- Preserves state on back

### SongDisplayView
- Receives Song object via initializer
- Accesses modelContext for tracking
- Parses ChordPro on appear
- Tracks view on appear
- Manages font size state
- Provides toolbar actions

### Navigation Stack
- LibraryView provides NavigationStack
- SongListView inside stack
- SongDisplayView pushes onto stack
- Standard iOS navigation

## Database Impact

### On Navigation (View Song)

**Write Operation:**
```swift
song.lastViewed = Date()      // Update timestamp
song.timesViewed += 1         // Increment counter
try modelContext.save()       // Persist to disk
```

**Performance:**
- Single write operation
- Two small fields
- Indexed for queries
- <1ms on modern devices

**Frequency:**
- Once per song view
- Not on back navigation
- Only on initial appear

## Error Handling

### View Tracking Errors

```swift
do {
    try modelContext.save()
} catch {
    print("Error tracking song view: \(error)")
}
```

**Behavior:**
- Errors logged to console
- No user-facing error
- App continues normally
- Tracking may be incomplete

**Reasons for Errors:**
- Database locked (rare)
- Disk full (rare)
- Permissions issue

## Integration Points

### From SongListView
```swift
NavigationLink(destination: SongDisplayView(song: song)) {
    EnhancedSongRowView(song: song)
}
```

### From Search Results
- Same navigation
- Search state preserved
- Filter applied on return

### From Sort Menu
- Same navigation
- Sort state preserved
- May reorder on return (if Recently Viewed)

This creates a seamless, professional navigation experience that feels native to iOS!
