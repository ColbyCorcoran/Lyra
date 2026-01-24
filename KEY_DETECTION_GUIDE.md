# Intelligent Key Detection & Recommendation Guide

## Overview

Lyra's Intelligent Key Detection & Recommendation system automatically analyzes songs to detect their key, recommends optimal keys based on vocal range, and helps musicians make smart key choices for better performance. This feature takes the guesswork out of key selection and makes music more accessible and enjoyable.

## Phase 7.3: Key Intelligence Implementation

This feature is part of **Phase 7: Intelligence System** and provides intelligent key analysis, recommendations, and educational features.

### Key Technologies

- **MusicTheoryEngine**: Advanced key detection from chord progressions
- **VocalRangeAnalyzer**: Audio-based vocal range detection using FFT
- **KeyRecommendationEngine**: Multi-factor key recommendation system
- **KeyCompatibilityAnalyzer**: Circle of fifths analysis for setlists
- **KeyLearningEngine**: Personalization based on usage patterns
- **On-Device Processing**: 100% offline, completely private

## Features

### 1. Automatic Key Detection

- **Intelligent analysis** of chord progressions
- **Modal ambiguity detection**: Identifies relative major/minor possibilities
- **Confidence scoring**: Shows certainty of key detection
- **Alternative key suggestions**: Lists other possible keys
- **Diatonic chord counting**: Explains why key was chosen
- **Non-diatonic chord identification**: Highlights borrowed chords

### 2. Vocal Range Analysis

- **Record your singing**: Analyze vocal range from audio
- **Voice type classification**: Soprano, Alto, Tenor, Baritone, Bass
- **Comfortable vs. extreme range**: Distinguishes sustainable notes
- **Frequency-to-note conversion**: Precise musical note detection
- **Range visualization**: Clear display of lowest to highest notes
- **Semitone span calculation**: Shows total vocal range width

### 3. Key Recommendations

- **Multi-factor analysis**: Considers chords, vocal range, preferences
- **Vocal range fit scoring**: Ensures song fits your voice
- **Guitar-friendly keys**: Prioritizes open chord keys
- **Capo suggestions**: Recommends capo for easier fingering
- **Modally stable keys**: Prefers keys with clear tonality
- **Personal preference learning**: Adapts to your habits over time

### 4. Capo Intelligence

- **Smart capo suggestions**: Converts difficult keys to easy ones
- **Open chord optimization**: Maximizes use of common chords
- **Transposition visualization**: Shows how capo affects key
- **Difficulty comparison**: Explains how capo makes song easier
- **Alternative capo positions**: Multiple options with trade-offs

### 5. Key Compatibility Analysis

- **Setlist optimization**: Analyzes key relationships in set
- **Smooth transitions**: Identifies compatible key changes
- **Circle of fifths distance**: Measures harmonic distance
- **Relative key detection**: Finds shared-note relationships
- **Flow score**: Rates overall setlist key flow
- **Modulation suggestions**: Recommends pivot chord transitions

### 6. Learning & Personalization

- **Usage tracking**: Records which keys you use most
- **Vocal range memory**: Saves your recorded vocal range
- **Capo preference learning**: Learns if you prefer capo usage
- **Difficulty adaptation**: Tracks your comfort level
- **Favorite key insights**: Shows your most-used keys
- **Personalized recommendations**: Boosts keys you tend to choose

### 7. Educational Features

- **Key signature visualization**: Shows sharps/flats in key
- **Circle of fifths display**: Interactive key relationship wheel
- **Mode explanations**: Teaches Ionian, Dorian, Phrygian, etc.
- **Scale degree visualization**: Shows I-VII with note names
- **Common progressions**: Displays popular patterns in each key
- **Related key suggestions**: Explains dominant, subdominant, relative keys
- **Theory insights**: Explains why key was detected

## How to Use

### Automatic Key Detection

#### From Song Chords

1. Open any song with chords
2. Tap **"Detect Key"** button
3. View detected key with confidence score
4. See explanation of why key was chosen
5. Review alternative key possibilities

The system analyzes:
- **Diatonic chords**: Chords that fit the key
- **Tonic presence**: How often the I chord appears
- **Dominant presence**: Strength of V chord
- **Non-diatonic chords**: Borrowed or chromatic chords
- **Modal stability**: Clarity of major vs. minor tonality

#### Key Detection Results

After analysis, you'll see:

**Primary Key**
- Key name (e.g., "C Major")
- Confidence percentage (0-100%)
- Explanation of detection reasoning
- Modal stability indicator

**Alternative Keys**
- Up to 3 alternative possibilities
- Confidence score for each
- Explanation of why they're possible
- Quick button to apply alternative

**Detection Explanation**
- "5 of 6 chords are diatonic to C major"
- "Strong tonic (C) and dominant (G) presence"
- "No modal ambiguity detected"

### Vocal Range Recording

#### Step 1: Record Your Voice

1. Tap **"Vocal Range"** button
2. Tap **"Start Recording"**
3. Sing from your **lowest comfortable note**
4. Gradually ascend to your **highest comfortable note**
5. Tap **"Stop Recording"** (or auto-stops after 5 seconds)

**Tips for best results:**
- Sing clearly and steadily
- Start low, end high (full range)
- Use vowel sounds (ah, ee, oh)
- Stay in comfortable volume
- Record in quiet environment

#### Step 2: Review Detected Range

After analysis, you'll see:

**Range Summary**
- **Lowest Note**: E.g., "C3"
- **Highest Note**: E.g., "C5"
- **Range**: Total semitones (e.g., "24 semitones")
- **Voice Type**: Classification (e.g., "Tenor")

**Comfortable Range**
- Middle 80% of your range
- Notes you can sustain easily
- Recommended for song selection

**Voice Type Badge**
- Soprano: C4-C6 (highest female)
- Mezzo: A3-A5 (middle female)
- Alto: F3-F5 (lowest female)
- Tenor: C3-C5 (highest male)
- Baritone: A2-A4 (middle male)
- Bass: E2-E4 (lowest male)

#### Step 3: Save Range

1. Review detected range
2. Tap **"Save Range"** to store
3. Or tap **"Record Again"** to retry

Your vocal range is now saved and will be used for:
- Key recommendations
- Song suitability analysis
- Transposition suggestions

### Key Recommendations

#### Step 1: Request Recommendations

From a song, tap **"Recommend Keys"** to get intelligent suggestions.

#### Step 2: Review Recommendations

Each recommended key shows:

**Key Card**
- **Key name** (e.g., "D Major")
- **Overall score** (0-100%)
- **Vocal fit**: How well it matches your range
- **Guitar ease**: Open chord availability
- **Reason tags**: Why it's recommended

**Detailed Scores**
- **Chord Analysis**: Fit with song's chords
- **Vocal Range**: Compatibility with your voice
- **Guitar Ease**: Fingering difficulty
- **Capo Option**: Whether capo helps
- **Personal Preference**: Your usage history

**Capo Suggestion**
- Capo position (if applicable)
- Simplified key with capo
- Difficulty comparison

#### Step 3: Apply Recommendation

1. Review recommended keys
2. Tap a key card to see details
3. Tap **"Use This Key"** to apply
4. Song is instantly transposed

### Key Compatibility (Setlists)

#### Step 1: Analyze Setlist

1. Create or open a setlist
2. Tap **"Analyze Keys"**
3. View compatibility report

#### Step 2: Review Compatibility

**Flow Score**
- Overall setlist flow rating
- Color-coded (green = smooth, red = jarring)
- Explanation of transitions

**Song-to-Song Analysis**
- Each transition rated
- Harmonic distance shown
- Relationship explained (relative, dominant, etc.)
- Compatibility score

**Suggestions**
- Recommended key changes
- Better song order
- Pivot chord suggestions for modulations

#### Step 3: Optimize Setlist

Options to improve flow:
- **Reorder songs**: Move for better transitions
- **Transpose songs**: Change keys for compatibility
- **Add transitions**: Insert modulation chords

### Educational Features

#### Overview Tab

**Key Detection Explanation**
- Why this key was chosen
- Diatonic chord analysis
- Tonic and dominant presence

**Relative Major/Minor**
- Shows relative key
- Explains shared notes
- Suggests when to modulate

**Scale Notes**
- All 7 notes in the key
- Scale degree names (I, II, III, etc.)
- Helps understand chord construction

**Key Characteristics**
- Major vs. Minor tonality
- Emotional character
- Common usage contexts

#### Signature Tab

**Key Signature Display**
- Number of sharps or flats
- Which notes are altered
- Natural keys (C/Am) indicated

**Enharmonic Equivalents**
- Alternative spellings (e.g., F♯ = G♭)
- When to use each
- Reading context

#### Circle of Fifths Tab

**Interactive Circle**
- All 12 major keys arranged
- Current key highlighted
- Clockwise: add sharps
- Counter-clockwise: add flats

**Related Keys**
- **Relative**: Shares all notes
- **Parallel**: Same root, different quality
- **Dominant (V)**: Perfect fifth up
- **Subdominant (IV)**: Perfect fourth up
- Compatibility score for each

#### Modes Tab

**Modal Explanations**
- **Ionian (Major)**: Happy, bright
- **Dorian**: Jazzy, sophisticated
- **Phrygian**: Spanish, exotic
- **Lydian**: Dreamy, ethereal
- **Mixolydian**: Bluesy, rock
- **Aeolian (Minor)**: Sad, dark
- **Locrian**: Dissonant, unstable

For each mode:
- Character description
- Scale formula
- Example songs
- Emotional quality

#### Progressions Tab

**Common Progressions in Key**
- I-V-vi-IV (Pop)
- I-IV-V (Rock)
- ii-V-I (Jazz)
- I-vi-IV-V (Doo-wop)

For each progression:
- Roman numeral notation
- Actual chord names
- Genre association
- Example songs
- Difficulty level

## Understanding Scores & Confidence

### Key Detection Confidence

- **90-100%**: Very high confidence, clear tonality
- **70-89%**: High confidence, some ambiguity
- **50-69%**: Moderate confidence, multiple possibilities
- **Below 50%**: Low confidence, unusual progressions

**Factors affecting confidence:**
- More diatonic chords = higher confidence
- Chromatic chords = lower confidence
- Clear tonic/dominant = higher confidence
- Modal ambiguity = lower confidence

### Vocal Range Fit Score

- **90-100%**: Perfect fit, all notes comfortable
- **70-89%**: Good fit, mostly comfortable
- **50-69%**: Moderate fit, some strain possible
- **Below 50%**: Poor fit, difficult to sing

**How it's calculated:**
- Song's lowest note vs. your lowest note
- Song's highest note vs. your highest note
- Percentage within comfortable range
- Extremes penalized more than center

### Key Compatibility Score

- **90-100%**: Seamless transition
- **70-89%**: Smooth transition
- **50-69%**: Noticeable but acceptable
- **30-49%**: Jarring transition
- **Below 30%**: Very difficult transition

**Relationships ranked:**
- Same key: 100%
- Relative major/minor: 100%
- Circle of fifths (adjacent): 90%
- Parallel major/minor: 80%
- Circle of fifths (2 steps): 70%
- Distant keys: 30-50%

## Tips & Best Practices

### For Accurate Key Detection

1. **Use complete progressions**: More chords = better accuracy
2. **Include tonic chord**: The I chord helps immensely
3. **Include dominant chord**: The V chord confirms key
4. **Watch for modulations**: Key may change mid-song
5. **Consider borrowed chords**: Non-diatonic ≠ wrong key

### For Vocal Range Recording

1. **Warm up first**: Don't record cold voice
2. **Use comfortable volume**: Not too soft or loud
3. **Sing cleanly**: Avoid vibrato or vocal fry
4. **Cover full range**: Lowest to highest
5. **Re-record periodically**: Voice changes over time

### For Key Selection

1. **Prioritize vocal fit**: Voice comfort is #1
2. **Consider guitar ease**: If you play guitar
3. **Check capo options**: May simplify fingering
4. **Trust the scores**: Algorithm considers many factors
5. **Override when needed**: You know your needs best

### For Setlist Building

1. **Check flow score**: Aim for 70%+ average
2. **Plan modulations**: Use pivot chords for key changes
3. **Group compatible keys**: Minimize difficult transitions
4. **Mix major/minor**: Emotional variety
5. **Energy arc**: Build from relaxed to energetic

## Technical Details

### Key Detection Algorithm

The system uses a **scoring-based approach**:

1. **Score all 24 major/minor keys** against chords
2. **Award points for**:
   - Diatonic chords (full points)
   - Root notes in scale (half points)
   - Tonic (I) chord presence (bonus)
   - Dominant (V) chord presence (bonus)
3. **Calculate confidence** from score distribution
4. **Check modal stability** (major vs. minor clarity)
5. **Return top result** with alternatives

### Vocal Range Detection Algorithm

Uses **FFT-based frequency analysis**:

1. **Analyze audio** in small windows (0.5s)
2. **Perform FFT** to get frequency spectrum
3. **Detect fundamental frequency** (pitch)
4. **Convert frequency to MIDI note**
5. **Filter by confidence threshold** (>50%)
6. **Find lowest/highest notes** detected
7. **Calculate comfortable range** (middle 80%)
8. **Classify voice type** from range boundaries

### Key Recommendation Algorithm

Uses **multi-factor weighted scoring**:

1. **Chord analysis** (30%):
   - How many chords fit key
   - Diatonic vs. chromatic ratio
2. **Vocal range fit** (35%):
   - Song range vs. your range
   - Comfortable vs. extreme notes
3. **Guitar ease** (15%):
   - Open chord availability
   - Barre chord count
4. **Capo options** (10%):
   - Simpler key with capo
   - Capo position reasonableness
5. **Personal preference** (10%):
   - Your key usage history
   - Learned patterns

Scores combined into **0-100% recommendation score**.

### Key Compatibility Algorithm

Uses **Circle of Fifths theory**:

1. **Calculate semitone distance** between keys
2. **Determine relationship**:
   - Same key: distance 0
   - Relative: distance 3 (minor 3rd)
   - Dominant: distance 7 (perfect 5th)
   - Subdominant: distance 5 (perfect 4th)
3. **Score based on relationship**:
   - Closer on circle = higher score
   - Relative keys = maximum score
4. **Average all transitions** for flow score

## Troubleshooting

### "Key Detection Uncertain"

**Possible causes:**
- Unusual chord progression
- Heavy use of chromatic chords
- Modal mixture (both major and minor)
- Song modulates between keys

**Solutions:**
- Check alternative key suggestions
- Manually select key if you know it
- Review non-diatonic chords
- Consider song may be modal or chromatic

### "Vocal Range Not Detected"

**Possible causes:**
- Recording too quiet
- Background noise
- Not enough pitch variation
- Recording too short

**Solutions:**
- Sing louder and clearer
- Record in quiet environment
- Sing full range (low to high)
- Record for at least 5 seconds
- Try multiple attempts

### "No Good Key Recommendations"

**Possible causes:**
- Vocal range doesn't fit song
- Song range too wide
- Unusual key of original song
- No saved vocal range

**Solutions:**
- Record your vocal range first
- Consider octave transposition
- Check if song is singable for you
- Manually select key and try it

### "Poor Setlist Compatibility"

**Possible causes:**
- Keys are distant on circle of fifths
- Many unrelated keys
- Random key selection

**Solutions:**
- Transpose songs to related keys
- Reorder songs for smoother flow
- Group songs in compatible keys
- Use pivot chord modulations

## Privacy & Data

All key detection and vocal range analysis happens **100% on-device**:

- ✅ **No internet required**
- ✅ **No cloud processing**
- ✅ **No data sent to servers**
- ✅ **Complete privacy**
- ✅ **Works offline**

Your vocal range and preferences are stored **locally on your device** using encrypted UserDefaults. This data:
- Never leaves your device
- Is not shared with anyone
- Can be deleted anytime
- Is backed up with iCloud (if enabled)

## Integration with Other Features

### Works with Chord Detection (Phase 7.1)

When you detect chords from audio:
1. Chords are automatically analyzed for key
2. Key detection runs on detected chords
3. Results shown in detection summary
4. Capo suggestions generated

### Works with Chord Suggestions (Phase 7.2)

Knowing the key enables:
1. Smarter autocomplete (in-key chords prioritized)
2. Better error detection (non-diatonic flagged)
3. Progression suggestions in current key
4. Roman numeral analysis

### Works with Transposition

Key recommendations can:
1. Instantly transpose to suggested key
2. Show before/after comparison
3. Preserve capo settings
4. Maintain relative chord quality

### Works with Setlists

For setlists:
1. Analyze all song keys
2. Recommend optimal order
3. Suggest transpositions for flow
4. Highlight difficult transitions

## Advanced Features

### Modal Analysis

Some songs don't fit traditional major/minor:

**Modal Songs**
- Use modes (Dorian, Mixolydian, etc.)
- May not have clear tonic
- Ambiguous major/minor tonality

**System handles this by:**
- Detecting modal ambiguity
- Showing lower confidence
- Suggesting both related keys
- Explaining the uncertainty

### Borrowed Chords

Songs often use chords outside the key:

**Common Examples**
- ♭VII in major keys (e.g., B♭ in C major)
- iv in major keys (minor subdominant)
- V in minor keys (major dominant)

**System identifies:**
- Which chords are borrowed
- Where they come from (parallel mode, etc.)
- Why they work harmonically
- Still detects key correctly

### Modulation Detection

Some songs change keys:

**Current Behavior:**
- Detects primary key (most chords)
- May show lower confidence
- Alternative keys may be modulation destinations

**Future Enhancement:**
- Identify exact modulation points
- Show multiple keys with timestamps
- Suggest pivot chords for transitions

### Voice Type Edge Cases

Vocal ranges may span multiple types:

**What happens:**
- System classifies by range center
- May fall between categories
- Simplified classification shown

**Voice types are guidelines:**
- Real voices vary widely
- Classification is approximate
- Use comfortable range primarily
- Voice type is secondary

## FAQ

**Q: Why does the key detection show low confidence?**

A: Low confidence means the chords fit multiple keys equally well. This happens with simple progressions (like I-V-vi-IV) that exist in many keys, or modal/chromatic songs. Check the alternative key suggestions.

**Q: Can I override the detected key?**

A: Yes! Tap the detected key and select a different key from the alternatives, or choose "Custom Key" to manually set any key.

**Q: How accurate is vocal range detection?**

A: Very accurate for clear recordings. Uses the same FFT technology as professional pitch detection. Accuracy depends on recording quality and singing clarity.

**Q: Will key recommendations work without vocal range?**

A: Yes! The system will still recommend keys based on chord analysis, guitar ease, and preferences. However, recommendations are much better with your vocal range saved.

**Q: How does the learning system work?**

A: Every time you use a key, it's recorded. Over time, the system notices patterns (favorite keys, capo preferences, difficulty level) and boosts recommendations accordingly. Learning is gradual and non-intrusive.

**Q: Can I delete my saved vocal range?**

A: Yes, in Settings → Intelligence → Clear Vocal Range. This also resets key preference learning.

**Q: Does this work for all instruments?**

A: Key detection and recommendations work for any instrument. However, "guitar ease" scoring and capo suggestions are guitar-specific. Other instrumentalists can ignore these factors.

**Q: What if a song uses multiple keys?**

A: Currently, the system detects the primary key. Future updates will support modulation detection with multiple keys per song.

**Q: Why does it recommend a key I can't sing?**

A: This shouldn't happen if you've recorded your vocal range. If it does, try re-recording your range or report it as a bug. The system should never suggest keys outside your range.

**Q: How do I improve setlist compatibility?**

A: Use the key compatibility analyzer to find problematic transitions, then either transpose songs to related keys or reorder the setlist. Aim for adjacent keys on the circle of fifths.

## Summary

Lyra's Intelligent Key Detection & Recommendation system:

✅ **Automatically detects song keys** from chord progressions
✅ **Analyzes your vocal range** from audio recordings
✅ **Recommends optimal keys** based on voice, guitar, and preferences
✅ **Suggests smart capo positions** for easier playing
✅ **Analyzes setlist compatibility** for smooth transitions
✅ **Learns your preferences** over time
✅ **Teaches music theory** with interactive educational features
✅ **Works 100% offline** with complete privacy

This feature makes key selection **intelligent instead of guesswork**, helping you choose the perfect key for your voice, instrument, and musical context.

---

**Need Help?**

If you encounter issues or have questions:
1. Review the Troubleshooting section above
2. Check the Educational features for theory help
3. Contact support with your specific question
4. Report bugs via the app's feedback form

**Phase 7 Intelligence System**
- ✅ Phase 7.1: AI Chord Detection
- ✅ Phase 7.2: AI Chord Suggestion
- ✅ Phase 7.3: Intelligent Key Detection (this feature)
- 🔄 More intelligence features coming soon...
