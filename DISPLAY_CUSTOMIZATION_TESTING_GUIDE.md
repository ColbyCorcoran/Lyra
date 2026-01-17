# Display Customization Testing Guide

## Quick Test (2 minutes)

### Basic Customization Flow

1. **Open Song**
   - Navigate to any song in library
   - Song opens in SongDisplayView
   - ✅ Displays with default settings

2. **Open Display Settings**
   - Tap "AA" button in toolbar
   - ✅ DisplaySettingsSheet appears
   - ✅ Current settings shown

3. **Change Font Size**
   - Move slider to 20
   - ✅ Preview text updates immediately
   - ✅ Value shows "20 pt"

4. **Change Chord Color**
   - Tap Red color swatch
   - ✅ Swatch shows checkmark
   - ✅ Preview chords turn red

5. **Apply Changes**
   - Tap "Done"
   - ✅ Song display updates
   - ✅ Chords are red, text is 20pt
   - ✅ Changes persist on back/reopen

---

## Comprehensive Testing

### Test 1: Font Size Slider

**Steps:**
1. Open song
2. Tap "AA" button
3. Move font size slider from 12 to 28
4. Observe preview and value label

**Expected Results:**
- ✅ Slider moves smoothly
- ✅ Value updates: "12 pt" → "28 pt"
- ✅ Preview text changes size immediately
- ✅ Both chord and lyrics preview scale
- ✅ No lag or stutter

**Edge Cases:**
- Minimum (12pt): ✅ Can't go lower
- Maximum (28pt): ✅ Can't go higher
- Steps: ✅ Increments by 1pt
- Reset: ✅ "Reset to Defaults" returns to 16pt

---

### Test 2: Chord Color Selection

**Steps:**
1. Open DisplaySettingsSheet
2. Tap each chord color preset
3. Observe selection and preview

**Expected Results:**
- ✅ 8 color swatches displayed
- ✅ Current color has checkmark
- ✅ Tapping changes selection
- ✅ Preview chord color updates
- ✅ Only one selected at a time

**Test Each Color:**
1. Blue (#007AFF): ✅ iOS default blue
2. Red (#FF3B30): ✅ Red shade
3. Green (#34C759): ✅ Green shade
4. Orange (#FF9500): ✅ Orange shade
5. Purple (#AF52DE): ✅ Purple shade
6. Pink (#FF2D55): ✅ Pink shade
7. Teal (#5AC8FA): ✅ Teal shade
8. Indigo (#5856D6): ✅ Indigo shade

---

### Test 3: Lyrics Color Selection

**Steps:**
1. Open DisplaySettingsSheet
2. Tap each lyrics color preset
3. Observe selection and preview

**Expected Results:**
- ✅ 4 color swatches displayed
- ✅ Current color has checkmark
- ✅ Tapping changes selection
- ✅ Preview lyrics color updates

**Test Each Color:**
1. Black (#000000): ✅ Black (inverts in dark mode)
2. Dark Gray (#3A3A3C): ✅ Dark gray shade
3. Gray (#8E8E93): ✅ Medium gray
4. Brown (#A2845E): ✅ Brown shade

---

### Test 4: Spacing Slider

**Steps:**
1. Open DisplaySettingsSheet
2. Scroll to Spacing section
3. Move slider from 4 to 16
4. Observe preview

**Expected Results:**
- ✅ Slider moves smoothly
- ✅ Value updates: "4 pt" → "16 pt"
- ✅ Preview spacing changes visually
- ✅ Chord and lyrics gap adjusts
- ✅ Smooth visual feedback

**Test Values:**
- 4pt: ✅ Minimal spacing
- 8pt: ✅ Default spacing
- 12pt: ✅ Comfortable spacing
- 16pt: ✅ Maximum spacing

---

### Test 5: Real-Time Preview

**Setup:** Open DisplaySettingsSheet

**Test Font Size:**
1. Move slider to 24
2. ✅ Preview "[G]Sample chord" is 24pt
3. ✅ Preview "Sample lyrics text" is 24pt
4. Move to 14
5. ✅ Both shrink to 14pt

**Test Colors:**
1. Select purple chords
2. ✅ Preview "[G]Sample chord" is purple
3. Select gray lyrics
4. ✅ Preview "Sample lyrics text" is gray

**Test Spacing:**
1. Move spacing to 4pt
2. ✅ Preview shows tight spacing
3. Move to 16pt
4. ✅ Preview shows wide spacing

---

### Test 6: Apply Settings to Song

**Steps:**
1. Open "Amazing Grace"
2. Tap "AA" button
3. Set: Font 22, Red chords, Black lyrics, Spacing 10
4. Tap "Done"
5. Observe song display

**Expected Results:**
- ✅ Sheet dismisses
- ✅ Song updates immediately
- ✅ All chords are red
- ✅ All lyrics are black
- ✅ Font is 22pt
- ✅ Spacing is 10pt between chords/lyrics

**Verify Persistence:**
1. Go back to song list
2. Reopen "Amazing Grace"
3. ✅ Settings preserved
4. ✅ Still red chords, 22pt font

---

### Test 7: Cancel Changes

**Steps:**
1. Open song with default settings
2. Tap "AA" button
3. Change font to 24, chords to green
4. Tap "Cancel"
5. Observe song

**Expected Results:**
- ✅ Sheet dismisses
- ✅ Song unchanged (still default)
- ✅ No settings saved
- ✅ Reopen sheet shows original settings

---

### Test 8: Reset to Defaults (Song)

**Steps:**
1. Customize song (Font 24, Green chords)
2. Tap "Done" and close
3. Reopen "AA" button
4. Tap "Reset to Defaults"
5. Observe preview

**Expected Results:**
- ✅ Font returns to 16pt
- ✅ Chords return to blue
- ✅ Lyrics return to black
- ✅ Spacing returns to 8pt
- ✅ Preview updates immediately

**After Tapping "Done":**
- ✅ Song uses reset values
- ✅ Still has custom settings (not global)

---

### Test 9: Set as Default for All Songs

**Steps:**
1. Customize song: Font 20, Purple chords, Spacing 12
2. Tap "Set as Default for All Songs"
3. Tap "Done"
4. Go to Settings tab
5. Check "Display Defaults"

**Expected Results:**
- ✅ Settings tab shows: Font 20, Purple, Spacing 12
- ✅ Global defaults updated
- ✅ Current song keeps its settings

**Create New Song:**
1. Add new song manually
2. Open in SongDisplayView
3. ✅ Uses new defaults (20pt, purple, 12pt spacing)

---

### Test 10: Remove Custom Settings

**Setup:** Song has custom settings

**Steps:**
1. Open song with custom settings
2. Tap "AA" button
3. Scroll to bottom
4. Tap "Remove Custom Settings"
5. Tap "Done"

**Expected Results:**
- ✅ Song reverts to global defaults
- ✅ Custom settings cleared from database
- ✅ Reopen sheet shows global defaults
- ✅ "Remove Custom Settings" button gone

---

### Test 11: Global Settings (Settings Tab)

**Steps:**
1. Go to Settings tab
2. Navigate to "Display Defaults" section
3. Observe controls

**Expected Results:**
- ✅ Font size slider (12-28)
- ✅ Chord color grid (8 colors)
- ✅ Lyrics color grid (4 colors)
- ✅ Spacing slider (4-16)
- ✅ Live preview of each setting
- ✅ "Reset to Defaults" button

**Test Changes:**
1. Change font to 18
2. ✅ Saves automatically
3. Select orange chords
4. ✅ Saves automatically
5. Change spacing to 10
6. ✅ Saves automatically

---

### Test 12: Global vs Per-Song Settings

**Setup:**
- Global: 16pt, Blue chords
- Song A: 24pt, Red chords (custom)
- Song B: No custom settings

**Test Song A:**
1. Open Song A
2. ✅ Shows 24pt, Red chords
3. ✅ Uses custom settings

**Test Song B:**
1. Open Song B
2. ✅ Shows 16pt, Blue chords
3. ✅ Uses global defaults

**Change Global:**
1. Go to Settings
2. Change to 20pt, Green chords
3. Return to song list

**Verify:**
- Song A: ✅ Still 24pt, Red (custom unaffected)
- Song B: ✅ Now 20pt, Green (follows global)

---

### Test 13: Dark Mode

**Steps:**
1. Enable dark mode (Settings → Display)
2. Open song with default settings
3. Observe display

**Expected Results:**
- ✅ Chord colors visible in dark mode
- ✅ Black lyrics invert to white
- ✅ Gray lyrics remain visible
- ✅ Color swatches visible in sheet

**Test Custom Colors:**
1. Open DisplaySettingsSheet
2. ✅ All color swatches visible
3. ✅ Selected color indicated
4. Select different colors
5. ✅ Changes visible in dark mode

**Toggle Dark Mode:**
1. Dark → Light → Dark
2. ✅ Colors adapt correctly
3. ✅ No color loss
4. ✅ Settings persist

---

### Test 14: Multiple Song Customizations

**Steps:**
1. Song A: 24pt, Red chords
2. Song B: 14pt, Green chords
3. Song C: 20pt, Purple chords
4. Song D: Default settings

**Verify Each:**
- Song A: ✅ 24pt, Red
- Song B: ✅ 14pt, Green
- Song C: ✅ 20pt, Purple
- Song D: ✅ Global defaults

**Rapid Switching:**
1. Open Song A → B → C → D → A
2. ✅ Each maintains correct settings
3. ✅ No mixing of settings
4. ✅ Fast loading

---

### Test 15: Extreme Values

**Minimum Settings:**
1. Font: 12pt
2. Spacing: 4pt
3. ✅ Readable but tight
4. ✅ No layout issues

**Maximum Settings:**
1. Font: 28pt
2. Spacing: 16pt
3. ✅ Very large but functional
4. ✅ May require scrolling
5. ✅ No overflow or clipping

**Mixed Extremes:**
1. Font: 28pt, Spacing: 4pt
2. ✅ Large text, tight spacing
3. Font: 12pt, Spacing: 16pt
4. ✅ Small text, wide spacing

---

### Test 16: Settings Persistence

**Setup:** Customize 3 songs, set global defaults

**Test App Restart:**
1. Force quit app
2. Relaunch
3. ✅ Global defaults preserved
4. ✅ Per-song settings preserved
5. Open each customized song
6. ✅ All settings intact

**Test Device Restart:**
1. Restart device
2. Open app
3. ✅ All settings preserved

---

### Test 17: Color Swatch UI

**Test Interaction:**
1. Open DisplaySettingsSheet
2. Tap color swatch
3. ✅ Checkmark appears instantly
4. ✅ Previous selection clears
5. ✅ Haptic feedback (if available)

**Test Grid Layout:**
- ✅ 4 columns
- ✅ Even spacing
- ✅ Swatches sized correctly
- ✅ Names visible
- ✅ No overlap

**Test Selection Indicator:**
- ✅ White checkmark on colored circle
- ✅ Blue border (accent color)
- ✅ Clearly visible
- ✅ Works in dark mode

---

### Test 18: Settings in Different Song Types

**Plain Text Song:**
1. Song with no chords
2. Customize settings
3. ✅ Font size applies to text
4. ✅ Lyrics color applies
5. ✅ Chord color irrelevant (no chords)

**ChordPro Song:**
1. Standard ChordPro
2. Customize settings
3. ✅ Font size applies to chords and lyrics
4. ✅ Chord color applies
5. ✅ Lyrics color applies
6. ✅ Spacing affects chord/lyric gaps

**Complex Song (Many Sections):**
1. Song with 10+ sections
2. Customize settings
3. ✅ All sections use same settings
4. ✅ Consistent throughout

---

### Test 19: Sheet Presentation

**Opening Animation:**
1. Tap "AA" button
2. ✅ Sheet slides up smoothly
3. ✅ Detent at full height
4. ✅ Drag indicator visible

**Dismissal:**
1. Swipe down on sheet
2. ✅ Sheet dismisses
3. ✅ Changes not saved (same as Cancel)

**Done Button:**
1. Tap "Done"
2. ✅ Sheet dismisses
3. ✅ Changes saved

**Cancel Button:**
1. Tap "Cancel"
2. ✅ Sheet dismisses
3. ✅ Changes discarded

---

### Test 20: Navigation During Settings

**Steps:**
1. Open song
2. Tap "AA" button (sheet appears)
3. While sheet is open:
   - Try to go back (back button)
   - Try to open another song
   - Try to navigate to different tab

**Expected Results:**
- ✅ Back button disabled/hidden
- ✅ Navigation blocked by sheet
- ✅ Must dismiss sheet first
- ✅ Modal presentation enforced

---

### Test 21: Accessibility - VoiceOver

**Enable VoiceOver:**

**Test Toolbar Button:**
1. Navigate to "AA" button
2. ✅ Announces: "Display Settings, button"
3. ✅ Double tap opens sheet

**Test Sliders:**
1. Navigate to font size slider
2. ✅ Announces: "Default Font Size, 16 points"
3. Swipe up/down
4. ✅ Adjusts value
5. ✅ Announces new value

**Test Color Swatches:**
1. Navigate to chord colors
2. ✅ Announces: "Blue, selected" or "Red, not selected"
3. Double tap
4. ✅ Selects color
5. ✅ Announces: "Blue, selected"

**Test Buttons:**
1. Navigate to "Reset to Defaults"
2. ✅ Announces: "Reset to Defaults, button"
3. ✅ Role indicated

---

### Test 22: Accessibility - Dynamic Type

**Enable Large Text:**
1. Settings → Accessibility → Display & Text Size
2. Set to largest size
3. Open Lyra

**Test Settings UI:**
- ✅ Section headers scale
- ✅ Button labels scale
- ✅ Color swatch names scale
- ✅ Value labels scale
- ✅ No text truncation
- ✅ No layout breakage

**Note:** Song display font size is independent (user controls via settings, not system)

---

### Test 23: Performance

**Large Song (1000+ lines):**
1. Open large song
2. Customize settings (Font 24, Red, Spacing 12)
3. Tap "Done"

**Expected Results:**
- ✅ Settings apply < 100ms
- ✅ No lag or stutter
- ✅ Smooth render
- ✅ Scrolling still smooth at 24pt

**Rapid Settings Changes:**
1. Open sheet
2. Move sliders rapidly
3. Tap colors quickly
4. ✅ No lag
5. ✅ Preview updates keep pace
6. ✅ No crashes

---

### Test 24: Memory & Storage

**Create 50 Songs with Custom Settings:**

**Memory Test:**
1. Open Activity Monitor
2. Note memory usage
3. Navigate through all 50 songs
4. ✅ Memory stable
5. ✅ No memory leaks
6. ✅ Settings load quickly

**Storage Test:**
1. Check app data size
2. ✅ Minimal increase (<10 KB for 50 songs)
3. Delete all songs
4. ✅ Storage reclaimed

---

### Test 25: Error Recovery

**Test Corrupted Settings:**
(Difficult to test without development tools)

**Simulate:**
1. Open song
2. Force quit app during settings save
3. Relaunch app
4. Open same song

**Expected Results:**
- ✅ Song opens without crash
- ✅ Either uses saved settings or falls back to defaults
- ✅ No data loss
- ✅ Can customize again

---

### Test 26: Import/Paste with Settings

**Import Song:**
1. Import ChordPro file
2. Open imported song
3. ✅ Uses global defaults
4. ✅ No custom settings yet

**Paste Song:**
1. Paste song from clipboard
2. Open pasted song
3. ✅ Uses global defaults

**Customize Imported:**
1. Customize imported song
2. ✅ Settings save correctly
3. ✅ Independent from import source

---

### Test 27: Cross-Feature Interaction

**With Search:**
1. Search for song
2. Open from results
3. ✅ Custom settings apply
4. Customize via "AA" button
5. ✅ Works normally

**With Sort:**
1. Sort by "Recently Viewed"
2. Open song, customize
3. Go back
4. ✅ Song still in correct sort order
5. ✅ Settings saved

**With Sets (Future):**
1. Add customized song to set
2. Play from set
3. ✅ Custom settings apply in set context

---

### Test 28: Settings Tab Comprehensive

**Test All Sections:**

**Display Defaults:**
1. ✅ All controls functional
2. ✅ Live preview works
3. ✅ Reset button works
4. ✅ Auto-save on change

**About:**
1. ✅ Version shown
2. ✅ Build shown
3. ✅ Information accurate

**Support:**
1. Tap GitHub link
2. ✅ Safari opens to repo
3. Tap Report Issue link
4. ✅ Safari opens to issues page

---

### Test 29: Edge Case - Empty Song

**Steps:**
1. Create song with no content
2. Open song
3. Shows "No content available"
4. Tap "AA" button

**Expected Results:**
- ✅ Sheet opens normally
- ✅ Can customize settings
- ✅ Settings save
- ✅ No errors

**When Content Added:**
1. Edit song, add content
2. ✅ Custom settings apply to new content

---

### Test 30: Real-World Scenarios

**Scenario 1: Stage Performance**

Setup: Bright stage lights, device 3 feet away

1. Font: 28pt
2. Chords: Orange (high visibility)
3. Lyrics: Black
4. Spacing: 12pt

Test: ✅ Readable from 3 feet, ✅ Chords stand out

**Scenario 2: Acoustic Circle**

Setup: Intimate setting, device 1 foot away

1. Font: 16pt
2. Chords: Blue
3. Lyrics: Black
4. Spacing: 8pt

Test: ✅ Comfortable reading, ✅ More content visible

**Scenario 3: Dark Venue**

Setup: Dark mode, low lighting

1. Font: 20pt
2. Chords: Teal (good in dark)
3. Lyrics: Gray (softer than white)
4. Spacing: 10pt

Test: ✅ Less eye strain, ✅ Chords visible

**Scenario 4: Outdoor Daylight**

Setup: Bright sunlight, light mode

1. Font: 24pt
2. Chords: Red (high contrast)
3. Lyrics: Black
4. Spacing: 10pt

Test: ✅ Visible in sunlight, ✅ High contrast helps

---

## Success Criteria

All tests should pass with:

✅ Font size changes apply correctly (12-28pt)
✅ Chord colors work (8 presets)
✅ Lyrics colors work (4 presets)
✅ Spacing adjusts properly (4-16pt)
✅ Real-time preview accurate
✅ Per-song settings save
✅ Global defaults save
✅ Settings persist across restarts
✅ Dark mode support
✅ Accessibility compliant
✅ Smooth performance
✅ No crashes or errors
✅ Professional UX

This comprehensive test suite ensures display customization is robust, user-friendly, and ready for live performance!
