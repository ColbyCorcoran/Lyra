# Transposition Guide

## Overview

Lyra's transposition feature allows you to change the key of any song with a single tap. Whether you need to match a singer's vocal range, accommodate a capo position, or create alternate versions of a song, transposition makes it effortless.

## Accessing Transposition

1. Open any song in text mode
2. Tap the transpose button (↑↓) in the toolbar
3. The transpose sheet will appear with all options

## Transpose Interface

### Key Selection

**Current Key → Target Key**
- Left side shows your song's current key
- Right side shows the target key you're transposing to
- Semitone count and interval description displayed below

**Target Key Picker**
- Quick menu with all 12 common keys
- Automatically calculates semitones needed
- Shows both sharp and flat options (C#/Db, F#/Gb, etc.)

### Semitone Slider

**Fine-Tuning Control**
- Range: -11 to +11 semitones (full octave down to full octave up)
- +/- buttons for precise adjustment
- Real-time preview of chord changes
- Drag slider for smooth control

**Quick Intervals**
- Half Step Up/Down: ±1 semitone
- Whole Step Up/Down: ±2 semitones
- 4th Up/Down: ±5 semitones (common for key changes)
- 5th Up/Down: ±7 semitones (circle of fifths)

### Sharp vs Flat Preference

**Enharmonic Spelling**
- Choose whether to use sharps (♯) or flats (♭) for black keys
- Example: C# vs Db, F# vs Gb
- Automatically suggested based on target key
- Override for personal preference

**Why It Matters**
- Some keys naturally use sharps (G, D, A, E, B major)
- Other keys naturally use flats (F, Bb, Eb, Ab major)
- Correct spelling makes music easier to read

### Chord Preview

**Real-Time Changes**
- Shows how each chord will be transposed
- Original chord → Transposed chord
- Blue color highlights changed chords
- Preview up to 10 chords (+ count of remaining)
- Instant updates as you adjust settings

### Save Options

Three modes for saving transposition:

**1. Temporary (Session Only)**
- Changes apply only during current session
- Original song remains unchanged
- Perfect for trying different keys
- Resets when you close the song
- Visual indicator (blue dot) on transpose button

**2. Permanent (Update This Song)**
- Permanently transposes the song
- Updates song content and key metadata
- Preserves original key in metadata
- Automatic capo suggestion for down-transposition
- Cannot be undone (make a backup first!)

**3. Save as New Song (Create Copy)**
- Creates a duplicate song with transposed content
- Original song remains unchanged
- New song titled with target key: "Amazing Grace (D)"
- Copies all metadata (artist, tempo, notes, etc.)
- Copies display settings
- Perfect for maintaining multiple versions

## How Transposition Works

### Chord Recognition

Lyra recognizes and transposes all standard chord types:

**Basic Chords**
- Major: C, D, E, F, G, A, B
- Minor: Cm, Dm, Em, Am
- Diminished: Cdim, Bdim
- Augmented: Caug, G#aug

**7th Chords**
- Dominant: C7, G7, A7
- Major 7th: Cmaj7, Dmaj7
- Minor 7th: Am7, Dm7
- Minor major 7th: Cm(maj7)

**Extended Chords**
- 9ths: C9, Am9, Gmaj9
- 11ths: C11, Dm11
- 13ths: C13, Am13

**Suspended & Added**
- Suspended: Csus2, Dsus4, Gsus
- Added notes: Cadd9, Dadd11

**Altered Chords**
- Flat 5th: C7b5, Dm7b5
- Sharp 5th: C7#5, G#5
- Flat 9th: C7b9, Db9
- Sharp 9th: C7#9

**Slash Chords (Bass Notes)**
- C/G (C over G bass)
- Am/E (A minor over E bass)
- D/F# (D over F# bass)
- Both root and bass notes are transposed

### Transposition Algorithm

1. **Parse** - Extract all chords from ChordPro format: `[Chord]`
2. **Identify** - Separate root note, quality, and bass note
3. **Transpose** - Move root note by semitone offset
4. **Enharmonic** - Choose sharp or flat spelling
5. **Preserve** - Keep all chord modifiers intact
6. **Replace** - Update content with transposed chords

### Capo Calculation

When transposing down, Lyra automatically suggests a capo position:

**Example: Transpose from G to E**
- Difference: -3 semitones (down minor 3rd)
- Capo suggestion: 9 (play G chords, capo 9 = E)
- Formula: Capo = (12 + semitones) % 12

**Why Use Capo?**
- Keep familiar chord shapes
- Easier fingering for some keys
- Maintain open string resonance
- Common for guitar and banjo

## Use Cases

### Vocal Range Matching

**Problem**: Song is too high or low for singer

**Solution**:
1. Ask singer to hum along and find comfortable note
2. Calculate interval difference
3. Use Quick Intervals to transpose
4. Apply Temporary to test before committing

**Example**: "Amazing Grace" in G is too high
- Transpose down to E (-3 semitones)
- Or transpose to F (-2) for slightly lower

### Capo Adaptation

**Problem**: Want to play with capo but chords are difficult

**Solution**:
1. Decide capo position (usually 2-5)
2. Transpose down by capo amount
3. Play easier chords with capo

**Example**: Song in Bb (hard open chords)
- Transpose to G (-3 semitones)
- Play G chords with capo 3 = Bb
- Much easier fingering!

### Instrument Transposition

**Problem**: Playing with Bb or Eb instruments (saxophone, trumpet)

**Solution**:
1. Bb instruments: Transpose up 2 semitones (whole step)
2. Eb instruments: Transpose up 9 semitones (major 6th)

**Example**: Piano plays in C, Bb saxophone plays in D

### Alternate Versions

**Problem**: Need multiple arrangements of same song

**Solution**:
1. Use "Save as New Song" for each version
2. Create versions for different vocalists
3. Create versions for different instruments
4. Keep all versions organized by key in title

**Example**: "How Great Thou Art"
- Original in G (baritone)
- Transpose to C for soprano: "How Great Thou Art (C)"
- Transpose to Bb for instruments: "How Great Thou Art (Bb)"

### Key Signatures

**Problem**: Difficult key signature with many sharps/flats

**Solution**:
1. Transpose to easier key (C, G, D, F, or Bb)
2. Use capo to compensate
3. Toggle sharp/flat preference for readability

**Example**: Song in Db (5 flats)
- Transpose to C (-1 semitone)
- Simpler reading, play with capo 1

## Tips & Best Practices

### Before Transposing

✅ **DO**:
- Note the original key (it's preserved automatically)
- Test with Temporary mode first
- Check chord preview for accuracy
- Consider vocalist range carefully

❌ **DON'T**:
- Skip testing before permanent save
- Transpose without checking preview
- Forget to backup important arrangements
- Transpose if original key unknown

### Choosing Target Key

✅ **DO**:
- Use common keys when possible (C, G, D, F, Bb)
- Consider open string chords for guitar
- Match vocalist's comfortable range
- Think about band instrument keys

❌ **DON'T**:
- Choose unnecessarily difficult keys
- Transpose more than absolutely needed
- Ignore enharmonic spelling preference
- Forget about capo alternatives

### Sharp vs Flat

✅ **DO**:
- Use sharps for keys: G, D, A, E, B, F#, C#
- Use flats for keys: F, Bb, Eb, Ab, Db, Gb
- Follow traditional music theory
- Keep consistency throughout song

❌ **DON'T**:
- Mix sharps and flats unnecessarily
- Ignore the automatic suggestion
- Use double sharps/flats

### Save Mode Selection

**Use Temporary When:**
- Testing different keys
- Trying before committing
- One-time performance need
- Experimenting with vocal range

**Use Permanent When:**
- Key change is final
- Song was originally in wrong key
- Standardizing library to certain keys
- No need to keep original

**Use Duplicate When:**
- Need multiple versions
- Different vocalists perform same song
- Creating arrangements for different instruments
- Want to keep original untouched

## Troubleshooting

### Chords Not Transposing

**Problem**: Some chords remain unchanged

**Possible Causes**:
1. Chord not in ChordPro format: `[Chord]`
2. Unusual chord notation not recognized
3. Custom chord symbols

**Solutions**:
- Check ChordPro formatting: brackets around chords
- Use standard chord notation
- Manually edit non-standard chords after transposition

### Wrong Enharmonic Spelling

**Problem**: Seeing C# instead of Db (or vice versa)

**Solution**:
- Toggle the "Prefer Sharps" / "Prefer Flats" setting
- Choose based on target key's traditional spelling
- Re-apply transposition with new preference

### Preview Shows No Changes

**Problem**: Chord preview is empty or shows no differences

**Possible Causes**:
1. Semitones set to 0
2. Song has no chords
3. Chords not properly formatted

**Solutions**:
- Adjust semitone slider
- Check that song has ChordPro chords: `[C]`, `[Am]`, etc.
- Verify content format

### Temporary Transposition Not Working

**Problem**: Chords don't change in display

**Solution**:
- Check that song was parsed (not loading)
- Verify blue indicator on transpose button
- Re-open song if needed

## Advanced Features

### Keyboard Shortcuts

- **⌘T**: Open transpose (future feature)
- **↑**: Transpose up half step (future feature)
- **↓**: Transpose down half step (future feature)

### Integration with Other Features

**Display Settings**
- Transposition respects all display settings
- Font size, colors, and spacing maintained
- Custom per-song settings preserved

**Autoscroll**
- Works with transposed content
- All autoscroll features compatible
- Speed zones and markers unaffected

**Export**
- Transposed songs export correctly
- PDF export includes transposed chords
- ChordPro export maintains new key

**Attachments**
- Original PDF attachments preserved
- Can maintain both original and transposed PDFs
- Annotations carry over in duplicates

## Theory Background

### Semitones & Intervals

**Chromatic Scale** (12 semitones):
C - C#/Db - D - D#/Eb - E - F - F#/Gb - G - G#/Ab - A - A#/Bb - B - C

**Common Intervals**:
- Minor 2nd: 1 semitone (C to C#)
- Major 2nd: 2 semitones (C to D)
- Minor 3rd: 3 semitones (C to Eb)
- Major 3rd: 4 semitones (C to E)
- Perfect 4th: 5 semitones (C to F)
- Perfect 5th: 7 semitones (C to G)
- Octave: 12 semitones (C to C)

### Circle of Fifths

Moving clockwise = up 7 semitones = adds 1 sharp:
C → G → D → A → E → B → F# → C#

Moving counter-clockwise = down 7 semitones = adds 1 flat:
C → F → Bb → Eb → Ab → Db → Gb → Cb

### Key Signatures

**Sharp Keys**: G(1), D(2), A(3), E(4), B(5), F#(6), C#(7)
**Flat Keys**: F(1), Bb(2), Eb(3), Ab(4), Db(5), Gb(6), Cb(7)

## FAQ

**Q: Will transposition change the melody?**
A: No, only chord symbols are transposed. Melody stays the same unless you also transpose your instrument.

**Q: Can I transpose PDF attachments?**
A: No, PDF content cannot be automatically transposed. Only ChordPro text format supports transposition.

**Q: What happens to capo notation after transposition?**
A: For down-transposition, capo is automatically suggested. For up-transposition, existing capo is cleared.

**Q: Can I undo a permanent transposition?**
A: No, permanent transposition overwrites content. Use "Save as New Song" if you want to keep the original.

**Q: Do temporary transpositions affect other users?**
A: No, temporary transpositions are session-only and don't modify the database.

**Q: Can I transpose songs in setlists?**
A: Yes, each song in a setlist can be independently transposed.

**Q: What if I transpose to the same key?**
A: Nothing changes. The Apply button is disabled when semitones = 0.

**Q: Can I transpose minor keys?**
A: Yes, minor keys work exactly like major keys. All chord qualities are preserved.

**Q: How accurate is the chord recognition?**
A: Very accurate for standard notation. Unusual or custom chord symbols may not be recognized.

**Q: Can I transpose only certain sections?**
A: Not currently. All chords in the song are transposed uniformly.

## Technical Details

### Chord Parsing Regex

Pattern: `\[([A-G][#b]?(?:m|maj|min|dim|aug|sus)?[0-9]?(?:[#b]?[0-9])?(?:/[A-G][#b]?)?)\]`

Captures:
- Root: A-G
- Accidental: # or b (optional)
- Quality: m, maj, min, dim, aug, sus (optional)
- Extensions: numbers 7, 9, 11, 13 (optional)
- Alterations: #5, b5, #9, b9 (optional)
- Bass note: /X where X is another note (optional)

### Enharmonic Logic

**Algorithm**:
1. Check target key
2. If key is in sharpKeys set, prefer sharps
3. If key is in flatKeys set, prefer flats
4. For C major or unknown, default to sharps
5. User can override with toggle

**Example**:
- Transposing to D major (2 sharps)
- C# preferred over Db
- F# preferred over Gb

### Performance

- Parsing: O(n) where n = content length
- Transposition: O(m) where m = number of chords
- Typical song: < 100ms processing time
- Large songs (500+ chords): < 500ms

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Related Guides**: CHORDPRO_FORMAT.md, DISPLAY_CUSTOMIZATION_DOCUMENTATION.md
