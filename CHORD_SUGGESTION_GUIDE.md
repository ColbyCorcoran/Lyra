# AI Chord Suggestion & Correction Guide

## Overview

Lyra's AI Chord Suggestion system provides intelligent autocomplete, error detection, and correction for chord progressions. This feature makes chord entry faster and more accurate while teaching music theory in the process.

## Phase 7.2: Chord Analysis Intelligence

This feature is part of **Phase 7: Intelligence System** and implements on-device chord analysis using rule-based music theory algorithms for 100% offline processing.

### Key Technologies

- **Pure Swift**: Rule-based music theory engine
- **On-Device Processing**: No internet required, complete privacy
- **Music Theory Database**: Common progressions and patterns
- **Levenshtein Distance**: Typo detection algorithm

## Features

### 1. Smart Autocomplete

Intelligent chord suggestions as you type:

- **Context-aware**: Suggests chords based on previous chords in the progression
- **Key-aware**: Prioritizes diatonic chords in the current key
- **Recently used**: Remembers chords you've used recently
- **Common patterns**: Recognizes and suggests from common progressions
- **Typo correction**: "Did you mean...?" suggestions for mistyped chords

#### How It Works

1. Start typing a chord (e.g., "C")
2. See instant suggestions appear
3. Suggestions are sorted by:
   - **Confidence** (0-100%)
   - **Relevance** (in-key chords first)
   - **Context** (what makes sense after previous chords)
4. Tap to select or keep typing

#### Suggestion Types

| Icon | Reason | Example |
|------|--------|---------|
| 🔑 | In Current Key | "C" suggested in key of C Major |
| 📊 | Common Progression | "G" after "C" (I→V) |
| 🔄 | Recently Used | Chords from your recent songs |
| ✅ | Typo Correction | "Csus4" when you typed "Csus" |
| ≈ | Enharmonic | "Db" instead of "C#" |
| ↔️ | Substitution | "Dm7" instead of "Dm" |

### 2. Error Detection

Automatic detection of chord progression issues:

#### Error Types

**Out of Key** (⚠️ Warning)
- Chord is not diatonic to the current key
- Example: "F#" in key of C Major
- Note: May be intentional (modal interchange, secondary dominants)

**Unlikely Progression** (ℹ️ Info)
- Unusual chord movement
- Example: Random jumps with no harmonic logic
- Suggests more common alternatives

**Possible Typo** (❌ Error)
- Detected via similarity to valid chords
- Example: "Csus" → "Csus4"
- Common typos recognized automatically

**Invalid Syntax** (🛑 Error)
- Chord doesn't match expected format
- Example: Starting with lowercase, invalid characters
- Must be corrected before proceeding

**Missing Quality** (ℹ️ Info)
- Chord might benefit from added quality
- Example: "C" could be "C7" or "Cmaj7"
- Contextual suggestions provided

**Enharmonic Issue** (ℹ️ Info)
- Wrong enharmonic spelling for key
- Example: "C#" in key of Db
- Suggests "Db" for consistency

#### Error Severity

- 🔴 **Error**: Must be fixed (invalid syntax)
- 🟠 **Warning**: Should review (out of key)
- 🔵 **Info**: Optional (suggestions for improvement)

### 3. Chord Theory Helper

Educational information about any chord:

#### Information Provided

**Basic Info**
- Root note
- Chord quality (major, minor, 7th, etc.)
- Description (e.g., "Major triad - happy, bright sound")

**Formula & Notes**
- Interval formula (e.g., "1-3-5")
- Actual notes in the chord (e.g., "C - E - G")
- Scale degrees explained

**Related Chords**
- Parallel (same root, different quality)
- Relative (shares notes)
- Dominant (V chord)
- Subdominant (IV chord)
- Extended versions (with 7ths, 9ths, etc.)
- Tritone substitutions (for jazz)

**Common Progressions**
- Shows progressions using this chord
- Examples from popular songs
- Typical harmonic contexts

#### Example: C Major

```
Chord: C
Root: C
Quality: Major
Formula: 1-3-5
Notes: C - E - G
Description: Major triad - happy, bright sound

Related Chords:
- Cm (Parallel minor)
- Am (Relative minor)
- G7 (Dominant)
- F (Subdominant)
- Cmaj7 (Extended version)

Common Progressions:
- C → G → Am → F (I-V-vi-IV)
- C → Am → F → G (I-vi-IV-V)
- C → F → G → C (I-IV-V-I)
```

### 4. Progression Analyzer

Comprehensive analysis of chord progressions:

#### Features

**Roman Numeral Analysis**
- Shows harmonic function of each chord
- Color-coded by function:
  - 🟢 Green: Tonic (stable, home)
  - 🔵 Blue: Subdominant (away from home)
  - 🔴 Red: Dominant (tension, wants to resolve)
  - 🟠 Orange: Secondary dominants
  - 🟣 Purple: Modal interchange
  - ⚫ Gray: Chromatic

**Progression Identification**
- Recognizes common progressions
- Matches against database of famous progressions
- Shows song examples using same progression

**Key & Scale Detection**
- Automatically determines song key
- Identifies major vs minor
- Confidence scoring

**Progression Type**
- I-V-vi-IV (Axis Progression)
- I-IV-V (Basic Rock)
- ii-V-I (Jazz Standard)
- 12-Bar Blues
- And many more...

#### Example Analysis

```
Progression: C - G - Am - F
Key: C Major
Scale: Major
Type: I-V-vi-IV (Axis Progression)
Common Name: "Axis Progression"
Confidence: 95%

Roman Numerals:
I   - C  (Tonic)
V   - G  (Dominant)
vi  - Am (Tonic)
IV  - F  (Subdominant)

Famous Songs:
- "Let It Be" - Beatles
- "Don't Stop Believin'" - Journey
- "With Or Without You" - U2
```

### 5. Progression Variations

Generate alternative versions of your progression:

#### Variation Types

**Simpler** (🟢 Beginner)
- Basic triads only
- Remove extensions
- Remove passing chords
- Power chords for rock

**More Complex** (🔴 Advanced)
- Add 7th chords
- Add 9th, 11th, 13th extensions
- Add passing chords

**Jazz Reharmonization** (🔴 Advanced)
- ii-V substitutions
- Tritone substitutions
- Secondary dominants
- Extended chords

**Chord Substitutions** (🟠 Intermediate)
- Replace with related chords
- Sus chords for tension
- Add6, add9 chords

**With Inversions** (🟠 Intermediate)
- Slash chords
- Smoother bass movement
- Better voice leading

**With Extensions** (🟠 Intermediate)
- 7ths for richer harmony
- Added tone chords
- Suspended chords

#### Example: C-G-Am-F Variations

```
Original: C - G - Am - F

Simpler (Beginner):
Power Chords: C5 - G5 - A5 - F5

More Complex (Advanced):
With 7ths: Cmaj7 - G7 - Am7 - Fmaj7

Jazz Reharmonization (Advanced):
With ii-V: Dm7 - G7 - Cmaj7 - Em7 - A7 - Dm7 - Gm7 - C7 - Fmaj7

With Extensions (Intermediate):
Extended: Cadd9 - G6 - Am7 - Fadd9
```

### 6. Reharmonization Engine

Generate completely new harmonic interpretations:

#### Styles

**Simpler**
- Beginner-friendly versions
- Basic triads
- Fewer chords
- Power chords

**Jazzier**
- Complex jazz harmonies
- Tritone subs
- Secondary dominants
- Extended chords (9ths, 11ths, 13ths)

**Colorful**
- Sus chords
- Add6, add9 chords
- Inversions
- 7ths for richness

**Balanced**
- Mix of all styles
- Multiple options
- Various difficulty levels

### 7. Common Progressions Database

Built-in database of famous progressions:

#### Categories

- **Pop/Rock**: I-V-vi-IV, I-vi-IV-V, vi-IV-I-V
- **Jazz**: ii-V-I, I-vi-ii-V (Rhythm Changes)
- **Blues**: 12-bar blues, 8-bar blues
- **Gospel**: I-IV-I-V, I-IV-vi-V
- **Andalusian**: i-VII-VI-V
- **Custom**: User progressions

#### Database Contents

- 15+ common progressions
- Song examples for each
- Genre classifications
- Popularity ratings
- Transposable to any key

## How to Use

### Smart Autocomplete

1. **Create or Edit Song**
2. **Add Chord Section**
3. **Start Typing Chord**
   - Suggestions appear instantly
   - Tap to select
   - Or keep typing to filter

4. **Review Suggestions**
   - Check confidence %
   - See reason for suggestion
   - Read context explanation

5. **Select Chord**
   - Tap suggestion
   - Or press Enter/Return to use typed chord

### Error Detection

Automatic - errors show inline:

1. **Out-of-key chords** highlighted in orange
2. **Invalid syntax** highlighted in red
3. **Tap error** to see:
   - Explanation
   - Suggested corrections
   - Confidence scores

4. **Apply correction**:
   - Tap suggested chord
   - Or manually edit
   - Or ignore (if intentional)

### Chord Theory Info

While typing or editing:

1. **Tap info button** (ⓘ) next to chord
2. **View details**:
   - Notes in chord
   - Formula
   - Related chords
   - Common progressions

3. **Explore related chords**:
   - Tap any related chord
   - See its theory info
   - Add to progression

### Progression Analysis

1. **Select chord progression** (or entire song)
2. **Tap "Analyze"** button
3. **Review analysis**:
   - Roman numerals
   - Key & scale
   - Progression type
   - Errors & warnings

4. **Explore variations**:
   - Tap variation to preview
   - Compare side-by-side
   - Apply to song

5. **Try reharmonization**:
   - Choose style (simpler, jazzier, etc.)
   - Preview options
   - Apply favorite

## Integration with Lyra

### Works With

- **ChordPro Editor**: Smart autocomplete while editing
- **Transpose Engine**: Maintains correctness when transposing
- **Capo Engine**: Suggests easier fingerings
- **Song Library**: Analyzes all songs
- **Performance Mode**: Quick fixes before performance

### Workflow Examples

#### Entering a New Song

1. Start typing first chord: "C"
2. Autocomplete suggests: C, Cmaj7, C7
3. Select "C"
4. Next chord: Type "G"
5. Autocomplete knows I→V is common, boosts "G" confidence
6. Continue building progression
7. Lyra detects key automatically
8. Suggestions get smarter based on key

#### Fixing Errors

1. Import song with typos
2. Lyra highlights "Csus" in red
3. Tap error to see: "Did you mean Csus4?"
4. Tap "Csus4" to apply
5. Error disappears
6. Continue reviewing other errors

#### Learning Music Theory

1. Type "Cmaj7"
2. Tap ⓘ for info
3. Learn: "1-3-5-7 formula"
4. See notes: C-E-G-B
5. Explore related: Dm7, G7 (ii-V)
6. Understand harmonic function

#### Reharmonizing for Jazz

1. Select simple progression: C-Am-F-G
2. Tap "Analyze"
3. Choose "Jazzier" reharmonization
4. Preview: Cmaj7-Em7-A7-Dm7-G7-Cmaj7
5. Compare side-by-side
6. Apply and hear the difference

## Technical Details

### Chord Recognition

**Supported Chord Types**:
- Major: C, D, E, etc.
- Minor: Cm, Dm, Em, etc.
- 7ths: C7, Dm7, Gmaj7, etc.
- Extended: C9, D11, E13, etc.
- Suspended: Csus2, Dsus4, etc.
- Augmented: Caug, D+
- Diminished: Cdim, D°
- Slash Chords: C/E, G/B
- Power Chords: C5, D5

### Autocomplete Algorithm

1. **Prefix Matching**: Find chords starting with input
2. **Context Analysis**: Check previous chords
3. **Key Analysis**: Prioritize diatonic chords
4. **Frequency Analysis**: Weight by common usage
5. **Typo Detection**: Levenshtein distance < 2
6. **Scoring**: Combine all factors
7. **Ranking**: Sort by confidence
8. **Limiting**: Top 5-10 suggestions

### Error Detection Algorithm

1. **Syntax Validation**: Regex pattern matching
2. **Key Validation**: Check diatonic scale membership
3. **Progression Validation**: Compare to common patterns
4. **Typo Detection**: Fuzzy string matching
5. **Enharmonic Check**: Verify spelling for key
6. **Quality Check**: Ensure complete chord syntax

### Progression Analysis Algorithm

1. **Key Detection**: Score all 24 major/minor keys
2. **Roman Numeral Mapping**: Map chords to scale degrees
3. **Function Analysis**: Classify as T, SD, D
4. **Pattern Matching**: Compare to database
5. **Confidence Scoring**: Based on diatonic percentage
6. **Variation Generation**: Apply transformations

## Performance Targets

- **Autocomplete**: < 50ms response time
- **Error Detection**: < 100ms for full song
- **Progression Analysis**: < 200ms for 8-chord progression
- **Reharmonization**: < 500ms for all variations
- **Database Queries**: < 10ms

## Privacy & Data

✅ **100% On-Device Processing**
- No chords uploaded to cloud
- No internet required
- No external APIs
- All analysis happens locally

✅ **No Subscription Costs**
- One-time purchase includes all features
- No ongoing costs
- No API fees

## Limitations

### Known Limitations

- **Atonal Music**: Works poorly without clear key center
- **Modal Jazz**: May misidentify modes
- **Experimental Harmony**: Limited to common Western harmony
- **Complex Jazz Chords**: Some extended chords not recognized
- **Slash Chords**: Basic support, complex inversions limited

### Not Supported

- **MIDI-based analysis** (Phase 7.1 has audio analysis)
- **Sheet music reading** (Phase 7: Vision Intelligence)
- **Real-time feedback** while playing (future feature)
- **Custom tunings** (standard tuning assumed)

## Troubleshooting

### Problem: Suggestions not appearing

**Solutions:**
- Ensure you're typing in chord input field
- Check if previous chords are set
- Try typing more characters (minimum 1-2)

### Problem: Wrong key detected

**Solutions:**
- Manually set key in song settings
- Ensure progression has enough chords (minimum 3-4)
- Check for out-of-key chords confusing analyzer

### Problem: Reharmonization sounds weird

**Solutions:**
- Try different style (simpler vs jazzier)
- Preview before applying
- Reharmonization is creative - may not always be "better"

### Problem: Too many error warnings

**Solutions:**
- Modal interchange and chromaticism trigger warnings
- Out-of-key chords may be intentional
- You can ignore warnings if harmonically correct

## Keyboard Shortcuts

- **Tab**: Accept first suggestion
- **↓/↑**: Navigate suggestions
- **Enter**: Use typed chord (ignore suggestions)
- **Esc**: Dismiss suggestions
- **⌘I**: Show chord theory info
- **⌘A**: Analyze progression

## Accessibility

- **VoiceOver**: Full support for chord suggestions
- **Voice Control**: Navigate and select by voice
- **Dynamic Type**: Scales with text size
- **Reduce Motion**: Disables suggestion animations

## Support

For issues:
1. Check autocomplete is enabled in settings
2. Verify key is set correctly
3. Ensure chords use valid syntax (A-G root)
4. Try simpler progressions first
5. Contact support with specific chord examples

## Quick Reference

### Autocomplete Triggers

| Input | Suggestions |
|-------|-------------|
| "C" | C, Cmaj7, C7, Cm, C9 |
| "Dm" | Dm, Dm7, Dmaj7, D |
| "G7" | G7, Gmaj7, G, G9 |
| "Am" | Am, Am7, A, Amaj7 |

### Common Progression Patterns

| Pattern | Name | Example |
|---------|------|---------|
| I-V-vi-IV | Axis | C-G-Am-F |
| I-IV-V | Rock | C-F-G |
| ii-V-I | Jazz | Dm7-G7-Cmaj7 |
| I-vi-IV-V | 50s | C-Am-F-G |
| vi-IV-I-V | Sensitive | Am-F-C-G |

### Error Icons

| Icon | Meaning |
|------|---------|
| ⚠️ | Warning (review) |
| ❌ | Error (must fix) |
| ℹ️ | Info (suggestion) |
| ✅ | Corrected |
| 🔑 | In-key suggestion |

---

**Remember**: AI suggestions are helpers, not rules! Music theory provides guidelines, but creativity often means breaking them. Use suggestions to learn and speed up entry, but trust your musical judgment.
