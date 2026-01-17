# SongListView Testing Guide

## Quick Visual Comparison

### Before Enhancement
```
┌──────────────────────────┐
│ Amazing Grace            │
│ Traditional              │
│ [G]                      │
└──────────────────────────┘

Features:
- Basic text layout
- Simple key badge
- No icon
- No chevron
- No search
- No sort
- No swipe actions
```

### After Enhancement
```
┌────────────────────────────────────┐
│ 🎵  Amazing Grace             >    │
│     Traditional                    │
│     [🎵 G] [🎸 Capo 2]            │
└────────────────────────────────────┘

Features:
✅ Music icon in circle
✅ Bold title
✅ Gray artist
✅ Key & capo badges
✅ Right chevron
✅ Search bar
✅ Sort menu (5 options)
✅ Swipe to delete
✅ Swipe to edit (disabled)
✅ Enhanced empty state
```

## Testing Checklist

### Part 1: Initial Setup

1. **Create Test Songs**
   Create these songs using AddSongView:

   | Title | Artist | Key | Capo |
   |-------|--------|-----|------|
   | Amazing Grace | John Newton | G | 0 |
   | Blessed Assurance | Fanny Crosby | D | 2 |
   | How Great Thou Art | Carl Boberg | C | 0 |
   | It Is Well | Horatio Spafford | C | 0 |
   | What A Friend | Joseph Scriven | G | 3 |

2. **Verify Initial Display**
   - [ ] All 5 songs appear in list
   - [ ] Each row shows music icon
   - [ ] Titles are bold
   - [ ] Artists are gray (smaller)
   - [ ] Key badges show correctly
   - [ ] Capo badges only on songs with capo > 0
   - [ ] Right chevron on all rows

---

### Part 2: Row Design

1. **Visual Elements**
   - [ ] Music icon is in blue circle (44x44pt)
   - [ ] Icon is centered in circle
   - [ ] Title is 17pt, semibold
   - [ ] Artist is 15pt, regular
   - [ ] Badges use capsule shape
   - [ ] Spacing looks balanced

2. **Key Badges**
   - [ ] Show blue background
   - [ ] Include music note icon
   - [ ] Text is readable
   - [ ] Example: "🎵 G", "🎵 D", "🎵 C"

3. **Capo Badges**
   - [ ] Show orange background
   - [ ] Include guitar icon
   - [ ] Text shows "Capo N"
   - [ ] Only appear when capo > 0
   - [ ] Example: "🎸 Capo 2", "🎸 Capo 3"

4. **Chevron**
   - [ ] Right-pointing arrow
   - [ ] Tertiary color (light gray)
   - [ ] Aligned to right edge

---

### Part 3: Search Functionality

1. **Basic Search**
   - [ ] Tap search bar at top
   - [ ] Keyboard appears
   - [ ] Type "Grace"
   - [ ] List filters to "Amazing Grace"
   - [ ] Other songs disappear
   - [ ] Search is case-insensitive

2. **Artist Search**
   - [ ] Clear search (tap X)
   - [ ] Type "Newton"
   - [ ] Only "Amazing Grace" shows (artist: John Newton)
   - [ ] Verify artist search works

3. **Partial Match**
   - [ ] Clear search
   - [ ] Type "great"
   - [ ] "How Great Thou Art" appears
   - [ ] Partial word matching works

4. **No Results**
   - [ ] Clear search
   - [ ] Type "xyz123"
   - [ ] List shows empty (no matches)
   - [ ] Clear search
   - [ ] All songs return

5. **Clear Search**
   - [ ] Enter search text
   - [ ] Tap X button in search bar
   - [ ] Search clears
   - [ ] All songs reappear
   - [ ] Keyboard dismisses

---

### Part 4: Sort Options

1. **Access Sort Menu**
   - [ ] Look for sort icon (↕️) in top-right
   - [ ] Tap sort icon
   - [ ] Menu appears with 5 options
   - [ ] Current selection has checkmark

2. **Title (A-Z)** - Default
   - [ ] Select "Title (A-Z)"
   - [ ] List shows:
     1. Amazing Grace
     2. Blessed Assurance
     3. How Great Thou Art
     4. It Is Well
     5. What A Friend
   - [ ] Alphabetically sorted ✓

3. **Title (Z-A)**
   - [ ] Select "Title (Z-A)"
   - [ ] List shows reverse order:
     1. What A Friend
     2. It Is Well
     3. How Great Thou Art
     4. Blessed Assurance
     5. Amazing Grace
   - [ ] Reverse alphabetical ✓

4. **Artist (A-Z)**
   - [ ] Select "Artist (A-Z)"
   - [ ] Songs sorted by artist name alphabetically
   - [ ] Songs with same artist maintain relative order

5. **Recently Added**
   - [ ] Add a new song (e.g., "Test Song")
   - [ ] Select "Recently Added"
   - [ ] "Test Song" appears at top
   - [ ] Older songs below in descending order
   - [ ] Most recent first ✓

6. **Recently Viewed**
   - [ ] Tap into "Amazing Grace" (view it)
   - [ ] Go back to list
   - [ ] Select "Recently Viewed"
   - [ ] "Amazing Grace" appears at top
   - [ ] Recently viewed songs first ✓

---

### Part 5: Swipe Actions

1. **Swipe to Delete (Trailing)**
   - [ ] Swipe left on any song row
   - [ ] Red delete button appears
   - [ ] Button shows trash icon
   - [ ] Tap delete
   - [ ] Song removed from list
   - [ ] Song deleted from database
   - [ ] List updates immediately

2. **Full Swipe Delete**
   - [ ] Swipe left fully on a song
   - [ ] Song deletes immediately (no button tap needed)
   - [ ] Full swipe delete works ✓

3. **Swipe to Edit (Leading - Disabled)**
   - [ ] Swipe right on any song row
   - [ ] Blue edit button appears
   - [ ] Button shows pencil icon
   - [ ] Button is grayed out (disabled)
   - [ ] Cannot tap (no action)
   - [ ] TODO: Will be enabled in future

4. **Cancel Swipe**
   - [ ] Swipe left partially
   - [ ] Delete button appears
   - [ ] Swipe back right (or tap elsewhere)
   - [ ] Button disappears
   - [ ] Song remains (not deleted)

---

### Part 6: Navigation

1. **Tap to View Song**
   - [ ] Tap any song row
   - [ ] NavigationLink triggers
   - [ ] SongDisplayView appears
   - [ ] Full chord chart shows
   - [ ] Metadata header visible
   - [ ] Chords align properly
   - [ ] Back button returns to list

2. **Navigation After Search**
   - [ ] Search for "Grace"
   - [ ] Tap "Amazing Grace"
   - [ ] Song displays correctly
   - [ ] Back returns to search results
   - [ ] Search text still in bar

3. **Navigation After Sort**
   - [ ] Sort by "Recently Added"
   - [ ] Tap top song
   - [ ] Song displays
   - [ ] Back returns to sorted list
   - [ ] Sort option preserved

---

### Part 7: Empty State

1. **Delete All Songs**
   - [ ] Swipe delete each song until none remain
   - [ ] Enhanced empty state appears
   - [ ] Shows gradient circle with icon
   - [ ] Icon is music note list
   - [ ] Title: "No Songs Yet"
   - [ ] Message about getting started
   - [ ] Button: "Add Your First Song"

2. **Icon Animation**
   - [ ] Tap "Add Your First Song" button
   - [ ] Icon bounces (animation)
   - [ ] AddSongView sheet opens

3. **Add First Song from Empty State**
   - [ ] Fill out song form
   - [ ] Tap Save
   - [ ] Sheet dismisses
   - [ ] Song appears in list
   - [ ] Empty state gone
   - [ ] List view shows

---

### Part 8: Combined Features

1. **Search + Sort**
   - [ ] Have 5+ songs in list
   - [ ] Search for "e" (finds multiple)
   - [ ] Change sort to "Title (Z-A)"
   - [ ] Filtered results re-sort
   - [ ] Both search and sort apply ✓

2. **Search + Delete**
   - [ ] Search for specific song
   - [ ] Swipe to delete
   - [ ] Song deleted
   - [ ] Search still active
   - [ ] Remaining results show

3. **Sort + Add**
   - [ ] Sort by "Recently Added"
   - [ ] Add new song via empty state button
   - [ ] New song appears at top
   - [ ] Sort maintained ✓

---

### Part 9: Edge Cases

1. **Song Without Artist**
   - [ ] Create song with no artist
   - [ ] Row shows only title
   - [ ] No artist line appears
   - [ ] Badges still show
   - [ ] Layout looks good

2. **Song Without Key**
   - [ ] Create song with no key
   - [ ] Row shows title and artist
   - [ ] No key badge appears
   - [ ] Capo badge still shows (if present)

3. **Song Without Capo**
   - [ ] Create song with capo = 0
   - [ ] Capo badge does NOT appear
   - [ ] Key badge still shows
   - [ ] Layout correct

4. **Song With No Metadata**
   - [ ] Create song with only title
   - [ ] Row shows icon and title only
   - [ ] No artist, no badges
   - [ ] Chevron still present

5. **Very Long Title**
   - [ ] Create song with long title (50+ chars)
   - [ ] Title truncates with ellipsis (...)
   - [ ] Line limit = 1 enforced
   - [ ] Doesn't wrap or overflow

6. **Very Long Artist Name**
   - [ ] Create song with long artist (40+ chars)
   - [ ] Artist truncates
   - [ ] Single line maintained

7. **Special Characters**
   - [ ] Create song: "C'est Si Bon"
   - [ ] Create song: "Für Elise"
   - [ ] Special characters display correctly
   - [ ] Search works with special chars

---

### Part 10: Performance

1. **Large List Scrolling**
   - [ ] Create 20+ songs
   - [ ] Scroll quickly up and down
   - [ ] No lag or stuttering
   - [ ] Smooth 60fps scrolling
   - [ ] Icons load instantly

2. **Search Performance**
   - [ ] With 20+ songs, search for text
   - [ ] Filtering is instant (<100ms)
   - [ ] No typing lag
   - [ ] Results update smoothly

3. **Sort Performance**
   - [ ] With 20+ songs, change sort
   - [ ] Re-sorting is instant
   - [ ] List updates smoothly
   - [ ] No visible delay

---

### Part 11: Dark Mode

1. **Toggle Dark Mode**
   - [ ] Enable dark mode in iOS settings
   - [ ] Return to app
   - [ ] All colors adapt properly
   - [ ] Blue badges visible
   - [ ] Orange badges visible
   - [ ] Text readable
   - [ ] Icons visible

2. **Empty State Dark Mode**
   - [ ] View empty state in dark mode
   - [ ] Gradient circle visible
   - [ ] Icon contrasts well
   - [ ] Button looks good
   - [ ] Text readable

---

### Part 12: Accessibility

1. **VoiceOver**
   - [ ] Enable VoiceOver
   - [ ] Navigate through list
   - [ ] Each row announces title
   - [ ] Artist announced
   - [ ] Badges announced: "Key: G, Capo: 2"
   - [ ] Chevron announces "button"
   - [ ] Search bar labeled properly

2. **Dynamic Type**
   - [ ] Increase text size to largest
   - [ ] Return to app
   - [ ] All text scales
   - [ ] Layout remains usable
   - [ ] Icons maintain relationships
   - [ ] Badges still readable

---

## Expected Results Summary

After all tests pass, you should have:

✅ Beautiful row design with icon, title, artist, badges, chevron
✅ Working search that filters by title or artist
✅ 5 functional sort options
✅ Swipe left to delete (red)
✅ Swipe right to edit (blue, disabled)
✅ Enhanced empty state with gradient and button
✅ Smooth performance with many songs
✅ Dark mode support
✅ Accessibility support

## Common Issues & Solutions

### Songs Don't Appear
- ✅ Check SwiftData is configured
- ✅ Verify songs were saved (check AddSongView)
- ✅ Try pulling down to refresh (if implemented)

### Search Doesn't Work
- ✅ Check search text binding
- ✅ Verify filteredAndSortedSongs computed property
- ✅ Ensure case-insensitive comparison

### Sort Doesn't Change Order
- ✅ Verify selectedSort binding
- ✅ Check sort implementation in switch
- ✅ Ensure List observes filteredAndSortedSongs

### Swipe Delete Doesn't Work
- ✅ Check modelContext.delete() called
- ✅ Verify modelContext.save() called
- ✅ Ensure List observes @Query

### Empty State Doesn't Show
- ✅ Verify allSongs.isEmpty check
- ✅ Check if @Query is correct
- ✅ Ensure no filter hiding state

### Badges Don't Show
- ✅ Check if song has key/capo set
- ✅ Verify conditional rendering logic
- ✅ Check badge color/visibility

This comprehensive test suite ensures all SongListView features work perfectly!
