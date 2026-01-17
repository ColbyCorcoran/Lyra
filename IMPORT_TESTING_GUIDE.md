# ChordPro Import Testing Guide

## Quick Test (2 minutes)

### Create Test File

1. Open Notes or TextEdit on Mac/iPad
2. Create file: `test_song.cho`
3. Add content:
```chordpro
{title: Test Song}
{artist: Test Artist}
{key: G}

{verse}
[G]Hello [C]world [D]of [G]music
```
4. Save to Files app or iCloud Drive

### Import Test

1. Open Lyra
2. Go to Library → All Songs
3. Tap "Import" button (top-left)
4. Select `test_song.cho`
5. ✅ Success alert appears
6. Tap "View Song"
7. ✅ Song displays correctly
8. Go back
9. ✅ "Test Song" appears in song list

---

## Comprehensive Testing

### Test 1: Perfect ChordPro File

**Create File:** `amazing_grace.chordpro`

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

{start_of_chorus}
[C]My chains are [G]gone, I've been set [Em]free
My God, my [C]Savior has ransomed [G]me
{end_of_chorus}
```

**Expected Results:**
- ✅ Import successful
- ✅ Title: "Amazing Grace"
- ✅ Artist: "John Newton"
- ✅ Key: G
- ✅ Tempo: 90
- ✅ Time: 3/4
- ✅ Capo: 0
- ✅ 2 sections (verse + chorus)
- ✅ Chords align properly
- ✅ Sticky header shows metadata

---

### Test 2: Minimal ChordPro File

**Create File:** `simple.txt`

```chordpro
{verse}
[C]Line one
[F]Line two
```

**Expected Results:**
- ✅ Import successful
- ✅ Title: "simple" (from filename)
- ✅ No artist, key, tempo
- ✅ 1 verse section
- ✅ 2 lines with chords

---

### Test 3: Plain Text (No ChordPro)

**Create File:** `lyrics.txt`

```
Amazing grace how sweet the sound
That saved a wretch like me
I once was lost but now am found
Was blind but now I see
```

**Expected Results:**
- ⚠️ Warning alert: "Import completed with warnings"
- ✅ Title: "lyrics"
- ✅ Content saved as plain text
- ✅ No chords parsed
- ✅ Can view in SongDisplayView
- ✅ "No content available" or plain text shown

---

### Test 4: Shorthand Metadata

**Create File:** `shorthand.cho`

```chordpro
{t: Short Title}
{st: Subtitle Here}
{a: Artist Name}
{k: D}

{sov}
[D]Test [A]line
{eov}
```

**Expected Results:**
- ✅ Title: "Short Title"
- ✅ Subtitle: "Subtitle Here" (in header)
- ✅ Artist: "Artist Name"
- ✅ Key: D
- ✅ Shorthand directives recognized

---

### Test 5: Multiple File Extensions

Create identical content in files with different extensions:

**Files:**
- `song.txt`
- `song.cho`
- `song.chordpro`
- `song.chopro`
- `song.crd`

**Expected Results:**
- ✅ All file types importable
- ✅ All show in file picker
- ✅ All import successfully
- ✅ Same result for all

---

### Test 6: Special Characters in Filename

**Create Files:**
- `C'est Si Bon.cho`
- `Für Elise.txt`
- `Song #1.chordpro`
- `My_Song-2024.cho`

**Expected Results:**
- ✅ All filenames handled correctly
- ✅ Title extracted properly
- ✅ Special chars preserved or removed safely
- ✅ No crashes

---

### Test 7: Very Long Filename

**Create File:** `This_Is_A_Very_Long_Song_Title_That_Should_Still_Work_Correctly_Even_Though_It_Is_Extremely_Long.cho`

**Expected Results:**
- ✅ Import successful
- ✅ Title extracted (may truncate in UI)
- ✅ originalFilename stored fully
- ✅ No crashes or layout issues

---

### Test 8: Empty File

**Create File:** `empty.txt`

**Content:** (completely empty)

**Expected Results:**
- ❌ Error alert: "The file is empty"
- ❌ Not imported
- ✅ Recovery message shown
- ✅ Can try again with different file

---

### Test 9: Whitespace-Only File

**Create File:** `whitespace.cho`

**Content:**
```




```

**Expected Results:**
- ❌ Error alert: "The file is empty"
- ❌ Not imported (whitespace trimmed)

---

### Test 10: Malformed ChordPro

**Create File:** `broken.cho`

```chordpro
{title: Broken Song
{artist: No closing brace
[Unclosed chord bracket
Random text here
{unknown_directive: value}
```

**Expected Results:**
- ⚠️ Warning or success with warnings
- ✅ Still imported
- ✅ Title: "Broken Song" (parsed despite malformation)
- ✅ Content saved
- ✅ Can view/edit later

---

### Test 11: Large File

**Create File:** `large.cho` (5000+ lines)

**Content:**
```chordpro
{title: Large Song}

{verse}
[C]Line 1
[repeat 5000 times...]
```

**Expected Results:**
- ✅ Import successful (may take 1-2 seconds)
- ✅ All content imported
- ✅ Scrolling smooth in SongDisplayView
- ✅ No memory issues

---

### Test 12: Unicode Characters

**Create File:** `unicode.cho`

```chordpro
{title: Café Song ☕}
{artist: François Müller}

{verse}
[C]Naïve résumé 中文 العربية
```

**Expected Results:**
- ✅ Import successful
- ✅ Unicode chars preserved
- ✅ Title: "Café Song ☕"
- ✅ All special chars display correctly

---

### Test 13: Import Then View

**Steps:**
1. Import any ChordPro file
2. Success alert appears
3. Tap "View Song"
4. SongDisplayView appears
5. Verify content
6. Go back to list

**Expected Results:**
- ✅ Navigation works
- ✅ Song displays correctly
- ✅ Back returns to list
- ✅ Song appears in list

---

### Test 14: Import Then Dismiss

**Steps:**
1. Import any ChordPro file
2. Success alert appears
3. Tap "OK" (dismiss)
4. Observe song list

**Expected Results:**
- ✅ Alert dismisses
- ✅ Song appears in list
- ✅ Can tap to view later

---

### Test 15: Import Cancellation

**Steps:**
1. Tap "Import" button
2. File picker appears
3. Tap "Cancel" in picker
4. Return to library

**Expected Results:**
- ✅ File picker dismisses
- ✅ No alert shown
- ✅ No song created
- ✅ Can import again

---

### Test 16: Import Failure Recovery

**Steps:**
1. Import broken/invalid file
2. Error alert appears
3. Tap "Import as Plain Text"
4. Check result

**Expected Results:**
- ✅ Plain text import succeeds
- ✅ Content saved as plainText format
- ✅ importSource: "Files (Plain Text)"
- ✅ Can still view song

---

### Test 17: Multiple Imports

**Steps:**
1. Import song A
2. View it
3. Go back
4. Import song B
5. View it
6. Go back
7. Check song list

**Expected Results:**
- ✅ Both songs in list
- ✅ Both viewable
- ✅ Both have correct metadata
- ✅ Import metadata set correctly

---

### Test 18: Import Same File Twice

**Steps:**
1. Import `test.cho`
2. Success
3. Import `test.cho` again
4. Success

**Expected Results:**
- ✅ Two songs created (no duplicate check yet)
- ✅ Both have same title
- ✅ Both exist in database
- ⚠️ Future: Add duplicate detection

---

### Test 19: Import From Different Sources

**Test each source:**
- iCloud Drive
- On My iPhone
- Dropbox (if installed)
- Google Drive (if installed)
- Other file providers

**Expected Results:**
- ✅ All sources appear in picker
- ✅ Files from all sources importable
- ✅ Same import process

---

### Test 20: Import During Search

**Steps:**
1. Go to song list
2. Search for "grace"
3. List filters
4. Tap "Import" button
5. Import song
6. Check list

**Expected Results:**
- ✅ Import works
- ✅ Search cleared (or maintained)
- ✅ New song appears in list
- ✅ Can search for it

---

### Test 21: Import During Sort

**Steps:**
1. Sort by "Recently Added"
2. Import new song
3. Check list order

**Expected Results:**
- ✅ Import works
- ✅ New song at top (most recent)
- ✅ Sort maintained
- ✅ List reorders correctly

---

### Test 22: Import Metadata Fields

**Create File:** `metadata_test.cho`

```chordpro
{title: Metadata Test}
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

**Expected Results:**
- ✅ Title: "Metadata Test"
- ✅ Artist: "Test Artist"
- ✅ Album: "Test Album"
- ✅ Year: 2024
- ✅ Key: G
- ✅ Tempo: 120
- ✅ Time: 4/4
- ✅ Capo: 2
- ✅ Copyright: "Copyright 2024"
- ✅ CCLI: "1234567"
- ✅ importSource: "Files"
- ✅ importedAt: Current date
- ✅ originalFilename: "metadata_test.cho"

---

### Test 23: Import Button Visibility

**Steps:**
1. Open Library
2. Tap "All Songs" tab
3. Look for Import button
4. Tap "Books" tab
5. Look for Import button
6. Tap "Sets" tab
7. Look for Import button

**Expected Results:**
- ✅ Import button visible on "All Songs"
- ❌ Import button hidden on "Books"
- ❌ Import button hidden on "Sets"

---

### Test 24: Error Message Clarity

**Test each error type:**

1. **Empty File:**
   - ✅ "The file is empty"
   - ✅ Helpful suggestion shown

2. **Invalid Encoding:**
   - ✅ "The file encoding is not supported"
   - ✅ Suggests UTF-8 conversion

3. **File Not Readable:**
   - ✅ "Unable to read the file"
   - ✅ Suggests checking file validity

4. **Parsing Failed:**
   - ✅ "Unable to parse the ChordPro content"
   - ✅ Offers plain text import

---

## Edge Cases

### Test 25: App Backgrounded During Import

**Steps:**
1. Tap Import
2. Select file
3. Immediately switch to another app
4. Return to Lyra

**Expected Results:**
- ✅ Import completes (or fails gracefully)
- ✅ Alert shows when returning
- ✅ No crashes

---

### Test 26: Import Very Long Lines

**Create File:** `long_lines.cho`

```chordpro
{title: Long Lines Test}

{verse}
This is a very long line that contains many words and should test the text wrapping and layout handling capabilities of the import system and display view
```

**Expected Results:**
- ✅ Import successful
- ✅ Long lines wrap in display
- ✅ No truncation
- ✅ Readable

---

### Test 27: Import With Mixed Line Endings

**Create File:** `mixed_endings.cho`

**Content:** Mix of \n, \r\n, \r line endings

**Expected Results:**
- ✅ Import successful
- ✅ Line endings normalized
- ✅ Displays correctly

---

## Performance Tests

### Test 28: Import Speed

**Measure:**
- Small file (1 KB): < 100ms
- Medium file (10 KB): < 500ms
- Large file (100 KB): < 2s

**Method:**
1. Start timer when selecting file
2. Stop when success alert appears
3. Repeat 10 times
4. Average the results

---

### Test 29: Memory Usage

**Steps:**
1. Note baseline memory
2. Import 50 songs
3. Note peak memory
4. Delete all imported songs
5. Note final memory

**Expected Results:**
- ✅ Memory increase < 50 MB
- ✅ Memory released after deletion
- ✅ No memory leaks

---

## Success Criteria

All tests should pass with:

✅ Successful imports for valid files
✅ Clear error messages for invalid files
✅ Proper metadata extraction
✅ Correct database storage
✅ Smooth navigation flow
✅ No crashes or data loss
✅ Professional user experience

## Test File Resources

### Where to Find ChordPro Files

1. **Ultimate Guitar** (ultimate-guitar.com)
   - Search for songs
   - Export as ChordPro

2. **Songbook** (www.songbookpro.com)
   - Sample files available
   - Various formats

3. **ChordPro.org** (www.chordpro.org)
   - Example files
   - Format documentation

4. **Create Your Own**
   - Use templates from USAGE.md
   - Convert existing lyrics

This comprehensive test suite ensures the import feature works reliably across all scenarios!
