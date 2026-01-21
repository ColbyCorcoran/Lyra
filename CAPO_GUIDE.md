# Capo Guide

## Overview

A capo is a device that clamps across the guitar fretboard to raise the pitch without changing chord shapes. Lyra's comprehensive capo support helps guitarists play in any key using familiar chord shapes.

## What is a Capo?

A capo (short for capotasto, Italian for "head of fretboard") allows you to:
- Play songs in different keys using the same chord shapes
- Avoid difficult barre chords
- Match your vocal range without learning new fingerings
- Get a brighter tone from open strings

**Example**: Song in G with Capo 2
- Play F chord shapes
- Sound comes out as G
- Much easier than playing G barre chord

## Accessing Capo Settings

1. Open any song in text mode
2. Tap the capo button (🎸) in the toolbar
3. The capo settings sheet appears with three tabs:
   - **Current**: Set capo position and display mode
   - **Suggestions**: Smart recommendations for easier chords
   - **Patterns**: Common capo positions for this key

## Setting Capo Position

### Visual Fret Selector

- 12 circles representing frets 0-11
- Tap any circle to set capo
- Current position highlighted in blue with guitar icon
- Position 0 = no capo

### +/- Buttons

- Quick adjustment without scrolling
- Decrement/increment by 1 fret
- Disabled at limits (0 and 11)

### Current Display

- **No Capo**: When fret = 0
- **Fret N**: Shows current capo position
- **Play X shapes**: Shows what chord shapes to use

### Remove Capo

- Button appears when capo > 0
- Instantly sets back to 0
- Confirms action with haptic feedback

## Display Modes

When capo is active, choose how chords are displayed:

### Actual Chords (Default)
- Shows the actual chords in the song
- Example: Song in G shows G, C, D chords
- Good for: Understanding the true harmony

### Capo Chords
- Shows the chord shapes to play with capo
- Example: Song in G with Capo 2 shows F, Bb, C
- Good for: Performance, following familiar shapes
- **Most useful mode for guitarists**

### Both (Dual Display)
- Shows both actual and capo chords together
- Format: `G (F with capo)`
- Good for: Learning, teaching, understanding relationships

**Toggle**: Use the display mode menu in the orange capo badge at top of song

## Capo Badge

When capo is active, an orange badge appears showing:
- **Capo Fret N**: Current position
- **Play X shapes**: What to finger
- **Display Mode Toggle**: Quick access to change view

## Key Information Card

Shows the relationship between:
- **Song Key**: The actual key (what it sounds like)
- **Play**: What chord shapes you finger with capo

**Example**:
```
Song Key: G  →  Play: F
```

## Capo Suggestions Tab

Lyra analyzes your song and suggests capo positions that make chords easier.

### How It Works

1. Extracts all chords from song
2. Calculates difficulty rating for each chord
3. Tests capo positions 1-7
4. Compares difficulty with and without capo
5. Suggests positions that significantly improve playability

### Suggestion Card Contains

- **Capo Fret N**: Recommended position
- **Reason**: Why it helps (e.g., "Much easier chords")
- **Improvement**: Percentage easier
- **Difficulty**: Overall difficulty rating
- **Sample Chords**: Preview of 4 main chords

### Difficulty Ratings

- **Very Easy**: C, Am, Em, G (open chords, no barre)
- **Easy**: D, A, E, Dm (simple open chords)
- **Moderate**: Mixed open and first position
- **Hard**: F, Bm, Bb (barre chords required)
- **Very Hard**: Complex extensions, unusual voicings

### Applying Suggestions

- Tap any suggestion card
- Automatically switches to Current tab
- Capo position set
- Ready to apply

## Common Patterns Tab

Shows traditional capo positions for the song's key.

### Pattern Card Contains

- **Capo Fret N**: Traditional position
- **Play X shapes**: What chord shapes to use
- **Reason**: Why this pattern is common

### Example Patterns

**Key of G**:
- Capo 0: Play G shapes (natural position)
- Capo 2: Play F shapes (simpler F-based chords)
- Capo 7: Play C shapes (easy C, Am, F, G)

**Key of F**:
- Capo 1: Play E shapes (avoid F barre)
- Capo 3: Play D shapes (easy open chords)
- Capo 5: Play C shapes (easiest fingerings)

## Capo + Transpose Interaction

Both features can work together. Here's how:

### The Relationship

1. **Transpose**: Changes the actual key of the song
2. **Capo**: Changes what chords you play to achieve that key

### "What's Happening" Card

Appears when both are active, explaining:
- **Original Key**: Where the song started
- **Transposed To**: New key after transposition
- **Capo Fret**: Where capo is placed
- **Play Chords**: What shapes to finger
- **Sounds Like**: Final result

### Example Scenario

**Original**: Song in G
**Transpose**: Down 2 semitones → F
**Capo**: Fret 3
**Play**: D shapes
**Sounds Like**: F

**Explanation**: "Song transposed from G to F. With capo on fret 3, you play D shapes. It sounds in F."

### Why Use Both?

- **Transpose**: Match singer's range
- **Capo**: Keep easy chord shapes
- **Result**: Perfect key with comfortable fingerings

### Common Combinations

**Lower key, keep easy chords**:
- Transpose down 3 → E
- Capo 4 → Play C shapes
- Sound: E with easy chords

**Higher key, avoid barre**:
- Transpose up 1 → C#
- Capo 1 → Play C shapes
- Sound: C# with open chords

## Per-Set Capo Override

Different arrangements may need different capo positions.

### How It Works

- Each song has a default capo setting
- Performance set entries can override
- Override is specific to that set
- Original song unchanged

### Setting Override

1. Open song from within a set
2. Set capo in capo view
3. Override automatically applied to set entry
4. Badge shows when override is active

### When Override Is Active

- Capo badge shows override value
- Toolbar button indicator (orange dot)
- "What's Happening" card mentions set-specific setting

### Removing Override

- Set capo to same as song's default
- Or set to 0 if song has no default
- Override cleared automatically

## Use Cases

### Match Vocal Range

**Problem**: Song is too low/high for singer

**Solution**:
1. Find comfortable key (might need transpose)
2. Use capo to play familiar chord shapes
3. Example: Transpose G→F, Capo 3, play D shapes

### Avoid Barre Chords

**Problem**: Song requires difficult barre chords

**Solution**:
1. Check Suggestions tab
2. Apply recommended capo
3. Play easier open chord shapes

**Example**: Song in F (barre F chord)
- Capo 3 → Play D shapes
- All open chords, no barres

### Simplify Key Signature

**Problem**: Song in difficult key (many sharps/flats)

**Solution**:
1. Leave transpose at 0
2. Use capo to play in easier key
3. Sounds correct, easier to read

**Example**: Song in Db (5 flats)
- Capo 1 → Play C shapes
- Natural key signature

### Brighter Tone

**Problem**: Want more jangly, open sound

**Solution**:
1. Use higher capo positions
2. Utilize more open strings
3. Get brighter voicings

**Example**: Song in C
- Capo 5 → Play G shapes
- More open strings = brighter sound

### Multiple Guitarists

**Problem**: Two guitars playing same song

**Solution**:
1. Guitar 1: No capo, play song key
2. Guitar 2: Capo 5 or 7, play different shapes
3. Creates fuller harmony

**Example**: Song in G
- Guitar 1: Play G, C, D
- Guitar 2: Capo 7, play C, F, G shapes
- Same notes, different voicings

### Nashville Tuning

**Problem**: Want high, chimey sound

**Solution**:
1. Use Nashville tuning (high strings)
2. Add capo for key adjustment
3. Creates 12-string effect

## Tips & Best Practices

### Choosing Capo Position

✅ **DO**:
- Try suggestions for your skill level
- Experiment with different positions
- Consider what sounds best to you
- Match the song's vibe (low = darker, high = brighter)

❌ **DON'T**:
- Use capo above fret 7 unless necessary
- Ignore the key relationship
- Forget to tune after placing capo
- Over-tighten capo (damages strings)

### Display Modes

✅ **DO**:
- Use Capo Chords mode for performance
- Use Actual Chords for learning harmony
- Use Dual Display for teaching
- Switch modes as needed

❌ **DON'T**:
- Stick to one mode if confused
- Ignore the badge information
- Forget which mode you're in

### With Transpose

✅ **DO**:
- Transpose for singer first
- Then add capo for playability
- Read the "What's Happening" card
- Test before performance

❌ **DON'T**:
- Use both without understanding
- Forget which is active
- Skip testing the combination

### Per-Set Overrides

✅ **DO**:
- Use for specific arrangements
- Document why override is needed
- Test in context of full set
- Keep overrides reasonable

❌ **DON'T**:
- Override unnecessarily
- Create too many variations
- Forget overrides exist

## Troubleshooting

### Chords Don't Sound Right

**Problem**: Notes don't match expected pitch

**Possible Causes**:
1. Capo placed incorrectly
2. Guitar out of tune
3. Wrong display mode selected

**Solutions**:
- Check capo is on correct fret
- Tune guitar with capo in place
- Verify display mode matches what you're playing

### Suggestions Not Helpful

**Problem**: Suggested capo doesn't make chords easier

**Possible Causes**:
1. Song already has easy chords
2. Your skill level different than algorithm
3. Personal preference for certain shapes

**Solutions**:
- Try Common Patterns instead
- Manually test different positions
- Trust your instincts over suggestions

### Can't Find Good Capo Position

**Problem**: No capo position improves playability

**Possible Causes**:
1. Song has inherently difficult progression
2. Key doesn't lend itself to capo
3. Non-standard tuning

**Solutions**:
- Consider transpose instead
- Learn the difficult chords
- Try alternate voicings without capo

### Display Mode Confusing

**Problem**: Not sure which chords to play

**Possible Causes**:
1. Wrong display mode for situation
2. Not understanding capo concept
3. Both transpose and capo active

**Solutions**:
- Use Capo Chords mode (shows what to play)
- Read the badge "Play X shapes" text
- Check "What's Happening" card for explanation

## Music Theory

### How Capo Works

**Physics**:
- Capo shortens vibrating string length
- Shorter strings = higher pitch
- Each fret = 1 semitone higher
- Capo at fret N = transpose up N semitones

**Example**: Open E string = E note
- Capo fret 1: E string sounds F
- Capo fret 2: E string sounds F#/Gb
- Capo fret 3: E string sounds G

### Chord Shape Math

**Formula**:
```
Sound = Shape + Capo
```

**Examples**:
```
C shape + Capo 2 = D sound
G shape + Capo 3 = Bb sound
D shape + Capo 5 = G sound
```

### Reverse Math

To find what shape for a sounding note:
```
Shape = Sound - Capo
```

**Examples**:
```
Want G sound with Capo 2?
G - 2 semitones = F shape

Want A sound with Capo 5?
A - 5 semitones = E shape
```

### Nashville Number System

Capo works with number system:
```
Key of G: 1=G, 4=C, 5=D
Capo 2, play F shapes: 1=F, 4=Bb, 5=C
Still sounds as G: 1=G, 4=C, 5=D
```

### Circle of Fifths

Common capo movements:
- Capo 7 = 5 semitones down (backwards in circle)
- Capo 5 = 7 semitones down
- Easier to add 7 than subtract 5 (modulo 12)

## Advanced Techniques

### Partial Capo

Some capos don't cover all strings:
- Skip bass strings
- Creates open tuning effect
- Not currently supported in Lyra (displays as full capo)

### Capo with Alternate Tuning

If guitar is tuned differently:
- Capo still works mechanically
- Chord names won't match
- Use Actual Chords mode
- Manual calculation needed

### Switching Capo Mid-Song

For key changes:
1. Place second capo above first
2. Remove first capo
3. Slide second into position
4. Requires practice!

## FAQ

**Q: What's the highest capo position I should use?**
A: Fret 7 is practical maximum for most songs. Higher positions sound thin and are harder to finger.

**Q: Can I use capo with electric guitar?**
A: Yes, but less common. Electric guitars have longer scales and different tone goals.

**Q: Does capo work with 12-string guitar?**
A: Yes, specially designed 12-string capos are available.

**Q: What if my capo makes notes buzz?**
A: Place capo closer to fret wire (behind it, toward bridge). Ensure even pressure.

**Q: Should I retune after placing capo?**
A: Yes! Capo pressure can slightly detune strings. Quick check recommended.

**Q: Can I use capo with bass guitar?**
A: Technically yes, but very rare. Bass lines usually stay in root position.

**Q: Do professional musicians use capos?**
A: Absolutely! Especially in folk, country, worship, and singer-songwriter genres.

**Q: What's the best capo to buy?**
A: Kyser, Shubb, and G7th are popular. Spring-loaded for quick changes, screw-on for precision.

**Q: Does capo change the "feel" of the guitar?**
A: Yes, slightly. Tension changes, action may feel different. Part of the sound.

**Q: Can I achieve same result by learning transposed chords?**
A: Theoretically yes, but capo provides:
  - Open string resonance
  - Familiar fingerings
  - Quick key changes
  - Unique voicings

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Related Guides**: TRANSPOSITION_GUIDE.md, CHORDPRO_FORMAT.md
