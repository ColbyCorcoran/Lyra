# Manual Song Creation - Testing Guide

## How to Test AddSongView

### Setup
1. Build and run Lyra in the iOS Simulator or on device
2. Navigate to the Library tab
3. Ensure "All Songs" is selected
4. Tap the "+" button in top-right corner

### Test Case 1: Simple Song Creation

**Steps:**
1. Tap "+" button
2. Enter:
   - Title: "Row Row Row Your Boat"
   - Artist: "Traditional"
   - Key: C (default)
   - Leave tempo blank
   - Time: 4/4 (default)
   - Capo: No Capo (default)
   - Content:
     ```chordpro
     {verse}
     [C]Row, row, row your boat
     [G7]Gently down the [C]stream
     [C]Merrily, merrily, merrily, [G7]merrily
     Life is but a [C]dream
     ```
3. Observe character count updates
4. Tap "Save"

**Expected Results:**
- ✅ Save button enabled after entering title
- ✅ Character count shows ~140 characters
- ✅ No validation warning
- ✅ Sheet dismisses after save
- ✅ "Row Row Row Your Boat" appears in song list
- ✅ Tapping song shows it in SongDisplayView
- ✅ Chords display correctly above lyrics

---

### Test Case 2: Complete Metadata Song

**Steps:**
1. Tap "+" button
2. Enter:
   - Title: "Amazing Grace"
   - Artist: "John Newton"
   - Key: G
   - Tempo: 90
   - Time: 3/4
   - Capo: Fret 2
   - Content:
     ```chordpro
     {start_of_verse}
     [G]Amazing [G7]grace, how [C]sweet the [G]sound
     That saved a wretch like [D]me
     [G]I once was [G7]lost, but [C]now am [G]found
     Was [Em]blind but [D]now I [G]see
     {end_of_verse}

     {start_of_chorus}
     [C]My chains are [G]gone, I've been set [Em]free
     My God, my [C]Savior has ransomed [G]me
     And like a [C]flood His mercy [G]reigns
     Unending [Em]love, [D]amazing [G]grace
     {end_of_chorus}
     ```
3. Tap "Save"

**Expected Results:**
- ✅ All metadata fields populated
- ✅ Save successful
- ✅ SongDisplayView shows:
  - Title: "Amazing Grace" (bold)
  - Artist: "👤 John Newton"
  - Metadata card with:
    - 🎵 Key: G
    - ⏱️ Tempo: 90 BPM
    - 〰️ Time: 3/4
    - 🎸 Capo: 2
- ✅ Sections labeled "Verse 1" and "Chorus"
- ✅ Chords positioned correctly above lyrics

---

### Test Case 3: Minimal Song (Title Only)

**Steps:**
1. Tap "+" button
2. Enter:
   - Title: "Untitled Song"
   - Leave all other fields blank/default
   - Leave content empty
3. Tap "Save"

**Expected Results:**
- ✅ Save button enabled (title is filled)
- ✅ Song saves successfully
- ✅ SongDisplayView shows:
  - Title: "Untitled Song"
  - No artist shown
  - Metadata card shows only:
    - 🎵 Key: C (default)
    - 〰️ Time: 4/4 (default)
  - Empty content message: "No content available"

---

### Test Case 4: Validation Warning

**Steps:**
1. Tap "+" button
2. Enter:
   - Title: "Test Invalid Format"
   - Content: "Just some random text without any ChordPro formatting"
3. Observe footer area

**Expected Results:**
- ✅ Orange warning appears:
  - ⚠️ "Content may not be valid ChordPro format"
- ✅ Save button still enabled (warning, not error)
- ✅ Can still save song
- ✅ Song saved but displays poorly in SongDisplayView

---

### Test Case 5: Cancel Without Saving

**Steps:**
1. Tap "+" button
2. Enter:
   - Title: "Unsaved Song"
   - Artist: "Test Artist"
   - Content: "Some content here"
3. Tap "Cancel" button (top-left)

**Expected Results:**
- ✅ Sheet dismisses immediately
- ✅ No confirmation dialog
- ✅ Song NOT saved
- ✅ "Unsaved Song" does NOT appear in list

---

### Test Case 6: All Musical Keys

**Steps:**
1. Tap "+" button
2. Open Key picker
3. Scroll through all options

**Expected Results:**
- ✅ All 17 keys available:
  - C, C#, Db, D, D#, Eb, E, F, F#, Gb, G, G#, Ab, A, A#, Bb, B
- ✅ Both sharp and flat variants shown
- ✅ Can select any key
- ✅ Selected key shows in picker

---

### Test Case 7: Capo Positions

**Steps:**
1. Tap "+" button
2. Open Capo picker
3. Scroll through options

**Expected Results:**
- ✅ 12 options (0-11)
- ✅ Position 0: "No Capo"
- ✅ Position 1: "Fret 1"
- ✅ Position 11: "Fret 11"
- ✅ Can select any position

---

### Test Case 8: Time Signatures

**Steps:**
1. Tap "+" button
2. Open Time Signature picker
3. View all options

**Expected Results:**
- ✅ 7 time signatures:
  - 2/4, 3/4, 4/4, 5/4, 6/8, 9/8, 12/8
- ✅ Default: 4/4
- ✅ All selectable

---

### Test Case 9: Long Content

**Steps:**
1. Tap "+" button
2. Enter:
   - Title: "Long Song"
   - Content: Copy/paste entire Amazing Grace sample (from SampleChordProSongs)
3. Scroll through content editor
4. Observe character count

**Expected Results:**
- ✅ Content scrolls smoothly
- ✅ Character count updates (shows ~800+ characters)
- ✅ No lag or performance issues
- ✅ Save works correctly
- ✅ Full content preserved

---

### Test Case 10: Placeholder Text

**Steps:**
1. Tap "+" button
2. Observe content editor (before typing)

**Expected Results:**
- ✅ Placeholder text visible:
  ```
  {verse}
  [C]Amazing [F]grace how [C]sweet the [G]sound
  That [C]saved a [F]wretch like [C]me

  {chorus}
  [F]My chains are [C]gone, I've been set [Am]free
  ```
- ✅ Placeholder in gray/tertiary color
- ✅ Placeholder disappears when typing
- ✅ Placeholder reappears if all text deleted

---

### Test Case 11: Character Count

**Steps:**
1. Tap "+" button
2. Type in content editor:
   - "Test" → 4 characters
   - "Test Song" → 9 characters
   - Delete "Song" → 4 characters

**Expected Results:**
- ✅ Character count updates in real-time
- ✅ Shows correct count at each step
- ✅ Displays as "N characters" (right-aligned)

---

### Test Case 12: Tempo Number Pad (iOS)

**Steps:**
1. Tap "+" button
2. Tap in Tempo field

**Expected Results (iOS only):**
- ✅ Number pad keyboard appears
- ✅ Only digits can be entered
- ✅ No letters or special characters
- ✅ Value saved correctly

---

### Test Case 13: Multiple Songs

**Steps:**
1. Create 3 songs with titles:
   - "Song A"
   - "Song B"
   - "Song C"
2. Check song list after each save

**Expected Results:**
- ✅ Each song appears immediately after save
- ✅ Songs listed alphabetically
- ✅ All 3 songs visible in list
- ✅ Can tap each song to view
- ✅ SwiftData persistence works

---

### Test Case 14: ChordPro Directives in Content

**Steps:**
1. Tap "+" button
2. Enter title: "Directive Test"
3. Enter content:
   ```chordpro
   {title: Override Title}
   {artist: Override Artist}
   {key: F}

   {verse}
   [C]Test content
   ```
4. Save and view song

**Expected Results:**
- ✅ Song saves with title "Directive Test" (form field takes precedence)
- ✅ Content includes all directives
- ✅ Parser reads directives from content
- ✅ Both form metadata and content directives preserved

---

### Test Case 15: Empty Fields Handling

**Steps:**
1. Tap "+" button
2. Enter only:
   - Title: "Minimal"
3. Leave all other fields at defaults
4. Save

**Expected Results:**
- ✅ Generated ChordPro includes:
  - {title: Minimal}
  - {key: C}
  - {time: 4/4}
- ✅ Does NOT include:
  - {artist: } (empty)
  - {tempo: } (empty)
  - {capo: } (0)
- ✅ Clean ChordPro output

---

## Quick Test Checklist

Use this for rapid testing:

- [ ] "+" button visible in LibraryView
- [ ] Tapping "+" shows AddSongView sheet
- [ ] All form fields present and labeled
- [ ] Title field required for saving
- [ ] Key picker shows all 17 keys
- [ ] Tempo accepts numbers only (iOS)
- [ ] Time signature picker shows 7 options
- [ ] Capo picker shows 0-11 (No Capo to Fret 11)
- [ ] Content editor shows placeholder
- [ ] Character count displays and updates
- [ ] Validation warning appears for invalid content
- [ ] Cancel button dismisses without saving
- [ ] Save button disabled when title empty
- [ ] Save button enabled when title filled
- [ ] Song appears in list after save
- [ ] Song displays correctly in SongDisplayView
- [ ] Metadata shows in sticky header
- [ ] Chords align properly above lyrics

## Expected Song List After Testing

After running all tests, your song list should contain:

1. Amazing Grace (with full metadata)
2. Long Song (large content)
3. Minimal (title only)
4. Row Row Row Your Boat (simple song)
5. Song A
6. Song B
7. Song C
8. Test Invalid Format (validation warning)
9. Untitled Song (minimal metadata)

Total: 9 songs

---

## Troubleshooting

### Save Button Stays Disabled
- ✅ Check that title field is not empty
- ✅ Try typing at least one character in title
- ✅ Check for whitespace-only title

### Song Doesn't Appear in List
- ✅ Check that you tapped "Save" (not Cancel)
- ✅ Verify you're on "All Songs" tab
- ✅ Try pulling down to refresh list
- ✅ Check Xcode console for save errors

### Validation Warning Doesn't Appear
- ✅ Type some non-ChordPro text in content
- ✅ Ensure content is not empty
- ✅ Warning only shows for content that can't be parsed

### Keyboard Doesn't Show Number Pad
- ✅ Only on iOS (not macOS/iPad in some cases)
- ✅ Tap directly in Tempo field
- ✅ Check device keyboard settings

### Sheet Doesn't Dismiss
- ✅ Tap "Save" or "Cancel" explicitly
- ✅ Can also swipe down from top
- ✅ Check for modal presentation settings

This comprehensive test suite ensures all AddSongView functionality works correctly!
