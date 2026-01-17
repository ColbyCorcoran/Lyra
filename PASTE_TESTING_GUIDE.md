# Paste Song Testing Guide

## Quick Test (30 seconds)

### Basic Paste Flow

1. **Copy ChordPro Content**
   - Open Safari or Notes
   - Copy this text:
   ```
   {title: Test Song}
   {artist: Test Artist}
   {key: G}

   {verse}
   [G]Hello [C]world
   ```

2. **Paste in Lyra**
   - Open Lyra → Library → All Songs
   - Tap Paste button (📋 clipboard icon)
   - ✅ Toast appears: "Pasted \"Test Song\""
   - ✅ Song opens automatically
   - ✅ Title, artist, key displayed correctly

3. **Verify**
   - Go back to song list
   - ✅ "Test Song" appears in list
   - ✅ Can tap to view again

---

## Comprehensive Testing

### Test 1: Perfect ChordPro

**Setup:**
Copy this ChordPro content:

```chordpro
{title: Amazing Grace}
{artist: John Newton}
{key: G}
{tempo: 90}
{time: 3/4}
{capo: 0}

{start_of_verse}
[G]Amazing [G7]grace, how [C]sweet the [G]sound
That saved a wretch like [D]me
[G]I once was [G7]lost, but [C]now am [G]found
Was [Em]blind but [D]now I [G]see
{end_of_verse}
```

**Steps:**
1. Copy content above
2. Open Lyra → All Songs
3. Tap Paste button
4. Observe toast
5. View song
6. Go back to list

**Expected Results:**
- ✅ Paste button enabled (not grayed)
- ✅ Toast: "Pasted \"Amazing Grace\""
- ✅ Toast appears at top
- ✅ Toast has green checkmark
- ✅ Toast auto-dismisses after 2 seconds
- ✅ Song opens automatically at 0.5 seconds
- ✅ Title: "Amazing Grace"
- ✅ Artist: "John Newton"
- ✅ Key: G, Tempo: 90, Time: 3/4, Capo: 0
- ✅ Content displays correctly
- ✅ Song appears in list
- ✅ importSource: "Clipboard" (check in database)

---

### Test 2: ChordPro Without Title Tag

**Setup:**
Copy this content (no {title:} tag):

```chordpro
{artist: Unknown Artist}
{key: C}

{verse}
[C]Hello [G]world [Am]of [F]music
This is the second line
```

**Steps:**
1. Copy content
2. Paste in Lyra
3. Observe result

**Expected Results:**
- ✅ Title: "Hello world of music" (first line)
- ✅ Artist: "Unknown Artist"
- ✅ Key: C
- ✅ Toast: "Pasted \"Hello world of music\""
- ✅ Song opens automatically

---

### Test 3: Plain Text (No ChordPro)

**Setup:**
Copy plain lyrics:

```
Amazing grace how sweet the sound
That saved a wretch like me
I once was lost but now am found
Was blind but now I see
```

**Steps:**
1. Copy plain text
2. Paste in Lyra
3. View song

**Expected Results:**
- ✅ Title: "Amazing grace how sweet the sound" (first line)
- ✅ No artist, key, or metadata
- ✅ Content: Plain text saved
- ✅ Toast: "Pasted \"Amazing grace how sweet the sound\""
- ✅ No chords displayed (plain text)
- ⚠️ May show parsing warnings (no sections)

---

### Test 4: Only Directives (No Lyrics)

**Setup:**
Copy metadata only:

```chordpro
{title: Metadata Only Song}
{artist: Test Artist}
{key: D}
{tempo: 120}
```

**Steps:**
1. Copy directives
2. Paste in Lyra
3. View song

**Expected Results:**
- ✅ Title: "Metadata Only Song" (from tag)
- ✅ Artist, key, tempo extracted
- ✅ Content: Directive text saved
- ✅ Toast shows title
- ✅ Song opens
- ⚠️ No sections parsed (no content to display)

---

### Test 5: First Line as Title

**Setup:**
Copy content without title tag:

```
Wonderful Song Title Here
{key: G}

{verse}
[G]Some lyrics [C]here
```

**Steps:**
1. Copy content
2. Paste in Lyra
3. Check title

**Expected Results:**
- ✅ Title: "Wonderful Song Title Here" (first line)
- ✅ Key: G
- ✅ Toast: "Pasted \"Wonderful Song Title Here\""
- ✅ Content includes title line

---

### Test 6: Empty First Lines (Skip to Real Content)

**Setup:**
Copy with blank lines at start:

```


{key: C}

First real line of content
{verse}
[C]Test
```

**Expected Results:**
- ✅ Title: "First real line of content" (skips blanks)
- ✅ Blank lines ignored
- ✅ Extracts first meaningful line

---

### Test 7: Very Long Title Line

**Setup:**
Copy with 100+ character first line:

```
This is an extremely long song title that goes on and on and should be truncated to sixty characters maximum for the title extraction algorithm
{key: G}
```

**Expected Results:**
- ✅ Title: "This is an extremely long song title that goes on and on a" (60 chars max)
- ✅ Truncated at 60 characters
- ✅ Full content still saved
- ✅ Toast may truncate display with "..."

---

### Test 8: Unicode and Special Characters

**Setup:**
Copy with special characters:

```chordpro
{title: Café Song ☕}
{artist: François Müller}

{verse}
[C]Naïve résumé 中文 العربية
```

**Expected Results:**
- ✅ Title: "Café Song ☕"
- ✅ Artist: "François Müller"
- ✅ Unicode preserved throughout
- ✅ Toast displays unicode correctly
- ✅ All special characters display

---

### Test 9: Empty Clipboard

**Setup:**
Clear clipboard (copy nothing or restart device)

**Steps:**
1. Ensure clipboard is empty
2. Open Lyra
3. Look at Paste button

**Expected Results:**
- ✅ Paste button grayed out (disabled)
- ✅ Cannot tap button
- ✅ Tooltip may show "No clipboard content"
- ✅ No error when button is disabled

---

### Test 10: Clipboard with Image Only

**Setup:**
Copy an image (not text)

**Steps:**
1. Copy photo from Photos app
2. Open Lyra
3. Check Paste button

**Expected Results:**
- ✅ Paste button disabled (no text content)
- ✅ ClipboardManager.hasClipboardContent() returns false
- ✅ No paste action possible

---

### Test 11: Clipboard with Mixed Content

**Setup:**
Copy rich text with formatting

**Steps:**
1. Copy formatted text from Notes (bold, italic)
2. Paste in Lyra
3. Check result

**Expected Results:**
- ✅ Paste succeeds
- ✅ Text extracted (formatting removed)
- ✅ Content saved as plain text
- ✅ No errors

---

### Test 12: Whitespace-Only Clipboard

**Setup:**
Copy only spaces and newlines:

```




```

**Steps:**
1. Copy whitespace
2. Try to paste

**Expected Results:**
- ❌ Error alert: "Clipboard is empty"
- ❌ Whitespace trimmed, detected as empty
- ❌ No song created
- ✅ Recovery suggestion shown

---

### Test 13: Multiple Pastes in Sequence

**Steps:**
1. Copy Song A, paste
2. Copy Song B, paste
3. Copy Song C, paste
4. Check song list

**Expected Results:**
- ✅ All 3 songs created
- ✅ All appear in list
- ✅ Each opened on paste
- ✅ Each has correct title
- ✅ All have importSource: "Clipboard"
- ✅ All have different importedAt times

---

### Test 14: Paste Same Content Twice

**Steps:**
1. Copy test song
2. Paste in Lyra
3. Go back to list
4. Paste again (same clipboard)
5. Check list

**Expected Results:**
- ✅ Two songs created (no duplicate check)
- ✅ Both have same title
- ✅ Both exist in database
- ✅ Different createdAt/importedAt timestamps
- ⚠️ Future: Add duplicate detection

---

### Test 15: Toast Notification Behavior

**Steps:**
1. Copy and paste song
2. Watch toast carefully
3. Time the display

**Expected Results:**
- ✅ Toast appears immediately (<100ms)
- ✅ Toast at top of screen (below nav bar)
- ✅ Green checkmark visible
- ✅ Song title in message
- ✅ Slide-down animation smooth
- ✅ Toast visible for 2 seconds
- ✅ Toast dismisses with slide-up animation
- ✅ Toast remains during navigation

---

### Test 16: Navigation Timing

**Steps:**
1. Paste song
2. Watch navigation timing
3. Measure with stopwatch

**Expected Results:**
- ✅ Toast appears at 0.0s
- ✅ Navigation occurs at 0.5s
- ✅ Song view loads smoothly
- ✅ Toast still visible during navigation
- ✅ Toast dismisses at 2.0s
- ✅ No jarring transitions

---

### Test 17: Paste Button State

**Test States:**
1. No clipboard content → Disabled
2. Text in clipboard → Enabled
3. Image in clipboard → Disabled
4. After paste → Enabled (if still in clipboard)

**Steps:**
1. Clear clipboard → Check button
2. Copy text → Check button
3. Copy image → Check button
4. Copy text and paste → Check button again

**Expected Results:**
- ✅ Button state updates correctly
- ✅ Disabled state clearly visible (grayed)
- ✅ Enabled state clearly tappable
- ✅ State reactive to clipboard changes

---

### Test 18: Error Handling - Save Failure

**Setup:**
Simulate database error (difficult without mocking)

**Alternative Test:**
1. Fill device storage completely
2. Try to paste song

**Expected Results:**
- ❌ Error alert: "Failed to save song"
- ❌ Recovery suggestion shown
- ❌ No song created
- ❌ No toast shown
- ✅ Can try again

---

### Test 19: Paste During Search

**Steps:**
1. Go to song list
2. Search for "grace"
3. List filters
4. Tap Paste button
5. Paste song
6. Check list

**Expected Results:**
- ✅ Paste works during search
- ✅ Song created
- ✅ Navigation occurs
- ✅ Search cleared or maintained
- ✅ New song appears in list

---

### Test 20: Paste During Sort

**Steps:**
1. Sort by "Recently Added"
2. Paste new song
3. Go back to list
4. Check order

**Expected Results:**
- ✅ Paste works during sort
- ✅ New song at top (most recent)
- ✅ Sort maintained
- ✅ List reorders correctly

---

### Test 21: Paste with App Backgrounded

**Steps:**
1. Copy song
2. Tap Paste button
3. Immediately switch to another app
4. Return to Lyra

**Expected Results:**
- ✅ Paste completes in background
- ✅ Song created
- ✅ May or may not navigate (iOS background limits)
- ✅ No crashes
- ✅ Can find song in list

---

### Test 22: Paste from Different Apps

**Test Sources:**
1. Safari (copy from website)
2. Notes (copy from note)
3. Mail (copy from email)
4. Messages (copy from chat)
5. Files (copy from text preview)
6. Third-party apps

**Steps:**
For each source:
1. Copy ChordPro content
2. Switch to Lyra
3. Paste
4. Verify result

**Expected Results:**
- ✅ All sources work identically
- ✅ Text extracted correctly
- ✅ No source-specific issues
- ✅ Same paste experience

---

### Test 23: Rapid Paste

**Steps:**
1. Copy song A
2. Paste immediately
3. While navigating, go back
4. Copy song B
5. Paste immediately
6. Repeat 5 times quickly

**Expected Results:**
- ✅ All pastes succeed
- ✅ No crashes
- ✅ No visual glitches
- ✅ All songs created
- ✅ Navigation handles rapid changes

---

### Test 24: Paste vs Import vs Manual

**Setup:**
Same song content, three methods

**Method 1 - Paste:**
1. Copy content
2. Tap Paste
3. Count taps: 1

**Method 2 - Import:**
1. Save as file
2. Tap Import
3. Select file
4. Tap "View Song"
5. Count taps: 4

**Method 3 - Manual:**
1. Tap +
2. Enter title
3. Enter artist
4. Paste content
5. Tap Save
6. Count taps: 5+

**Expected Results:**
- ✅ Paste fastest (1 tap)
- ✅ Import moderate (4 taps)
- ✅ Manual slowest (5+ taps)
- ✅ All produce same result

---

### Test 25: Toast Message Variants

**Test Cases:**

1. **Song with title tag:**
   - Toast: "Pasted \"Amazing Grace\""

2. **Song with first line title:**
   - Toast: "Pasted \"Hello world of music\""

3. **Song defaulting to Untitled:**
   - Toast: "Song pasted as \"Untitled Song\""

**Steps:**
Test each variant, verify correct message

**Expected Results:**
- ✅ Title tag: Shows actual title
- ✅ First line: Shows extracted title
- ✅ Untitled: Shows special message
- ✅ All messages clear and helpful

---

### Test 26: Metadata Preservation

**Setup:**
Copy comprehensive metadata:

```chordpro
{title: Full Metadata Test}
{artist: Test Artist}
{album: Test Album}
{year: 2024}
{key: G}
{tempo: 120}
{time: 4/4}
{capo: 2}
{copyright: Copyright 2024}
{ccli: 1234567}

{verse}
[G]Test line
```

**Steps:**
1. Paste content
2. View song
3. Check all metadata

**Expected Results:**
- ✅ Title: "Full Metadata Test"
- ✅ Artist: "Test Artist"
- ✅ Album: "Test Album"
- ✅ Year: 2024
- ✅ Key: G
- ✅ Tempo: 120
- ✅ Time: 4/4
- ✅ Capo: 2
- ✅ Copyright: "Copyright 2024"
- ✅ CCLI: "1234567"
- ✅ importSource: "Clipboard"
- ✅ importedAt: Current time

---

### Test 27: View Tracking After Paste

**Steps:**
1. Paste new song
2. Song opens (first view)
3. Go back
4. Tap song to view again
5. Check tracking

**Expected Results:**
- ✅ First view (paste): timesViewed = 1
- ✅ Second view (tap): timesViewed = 2
- ✅ lastViewed updated both times
- ✅ Song appears in "Recently Viewed" sort

---

### Test 28: Paste in Different Library Sections

**Steps:**
1. Go to Books tab
2. Look for Paste button
3. Go to Sets tab
4. Look for Paste button
5. Go to All Songs tab
6. Look for Paste button

**Expected Results:**
- ❌ Paste button hidden on Books tab
- ❌ Paste button hidden on Sets tab
- ✅ Paste button visible on All Songs tab
- ✅ Same behavior as Import button

---

### Test 29: Accessibility

**VoiceOver Test:**
1. Enable VoiceOver
2. Navigate to Paste button
3. Hear description
4. Double-tap to paste
5. Hear toast announcement

**Expected Results:**
- ✅ Button announced as "Paste" button
- ✅ Disabled state announced when no clipboard
- ✅ Toast message read aloud
- ✅ Navigation announced
- ✅ Full accessibility support

---

### Test 30: Dark Mode

**Steps:**
1. Enable dark mode
2. Copy and paste song
3. Observe toast

**Expected Results:**
- ✅ Toast adapts to dark mode
- ✅ Text readable
- ✅ Shadow appropriate
- ✅ Checkmark visible
- ✅ Professional appearance

---

## Edge Cases

### Test 31: Untitled Song Detection

**Cases That Should Use "Untitled Song":**

1. **Only directives:**
   ```chordpro
   {key: G}
   {tempo: 120}
   ```

2. **Only blank lines:**
   ```



   ```

3. **Only ChordPro comments:**
   ```chordpro
   {comment: This is a comment}
   {c: Another comment}
   ```

**Expected:**
- ✅ All use "Untitled Song"
- ✅ Toast: "Song pasted as \"Untitled Song\""
- ✅ wasUntitled = true in result

---

### Test 32: Special Title Cases

**Test:**

1. **Title with emoji:**
   ```
   {title: Song 🎵}
   ```
   Expected: "Song 🎵"

2. **Title with quotes:**
   ```
   {title: "Amazing Grace"}
   ```
   Expected: "Amazing Grace" or "\"Amazing Grace\""

3. **Title with newline (malformed):**
   ```
   {title: Line 1
   Line 2}
   ```
   Expected: Parser handles gracefully

**Expected:**
- ✅ Emoji preserved
- ✅ Quotes handled
- ✅ Malformed tags don't crash

---

## Performance Testing

### Test 33: Paste Speed

**Setup:**
Prepare 5 different songs

**Steps:**
1. Start stopwatch
2. Paste song 1
3. Wait for toast
4. Stop timer
5. Repeat 5 times
6. Average results

**Expected:**
- ✅ Average paste time < 100ms
- ✅ Toast appears instantly
- ✅ Navigation at 500ms consistently
- ✅ No lag or delay

---

### Test 34: Large Content Paste

**Setup:**
Copy very large song (5000+ lines)

**Steps:**
1. Copy large ChordPro file
2. Paste in Lyra
3. Observe behavior

**Expected:**
- ✅ Paste succeeds
- ✅ May take 100-500ms
- ✅ Toast appears
- ✅ Navigation works
- ✅ No crashes
- ✅ Full content saved

---

### Test 35: Memory Usage

**Setup:**
Memory profiler open

**Steps:**
1. Note baseline memory
2. Paste 50 songs
3. Note peak memory
4. Delete all songs
5. Note final memory

**Expected:**
- ✅ Memory increase < 50 MB
- ✅ Memory released after deletion
- ✅ No memory leaks
- ✅ No performance degradation

---

## Success Criteria

All tests should pass with:

✅ Paste button works correctly
✅ Clipboard content detected
✅ Title extracted properly
✅ Metadata parsed correctly
✅ Toast notification appears
✅ Toast auto-dismisses
✅ Navigation automatic
✅ Song appears in list
✅ Error handling graceful
✅ No crashes
✅ Professional UX

## Real-World Test Sites

### ChordPro Content Sources

1. **ChordPro.org** (www.chordpro.org)
   - Example files
   - Format documentation
   - Test content

2. **Ultimate Guitar** (www.ultimate-guitar.com)
   - Thousands of songs
   - Export as ChordPro
   - Real-world content

3. **Worship Together** (www.worshiptogether.com)
   - Worship songs
   - Chord charts
   - Christian music

4. **WorshipChords** (www.worshipchords.com)
   - Free chord charts
   - ChordPro format
   - Weekly updates

### Quick Test Song

Copy and test with this:

```chordpro
{title: Amazing Grace}
{artist: John Newton}
{key: G}

{verse}
[G]Amazing [G7]grace, how [C]sweet the [G]sound
That saved a wretch like [D]me
[G]I once was [G7]lost, but [C]now am [G]found
Was [Em]blind but [D]now I [G]see
```

This comprehensive test suite ensures the paste feature is robust, fast, and professional!
