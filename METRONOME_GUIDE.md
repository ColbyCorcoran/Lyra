# Metronome Guide

## Overview

Lyra includes a professional-grade built-in metronome for practice and performance. With accurate timing, visual feedback, and comprehensive controls, the metronome helps you maintain perfect tempo whether you're learning a new song or performing on stage.

## Quick Start

### Opening the Metronome

1. Open any song in text mode
2. Look for the floating metronome button (⏱) in the bottom-right corner
3. Tap the button to open metronome controls

### Starting the Metronome

1. Tap the large green **Play** button in the center
2. Metronome starts immediately with current settings
3. Visual indicator pulses with each beat
4. Audio clicks sound (unless Visual Only mode is enabled)

### Stopping the Metronome

1. Tap the large red **Stop** button (replaces Play when running)
2. Metronome stops immediately
3. Beat counter resets to beginning

## Metronome Interface

### Visual Metronome (Top)

Large pulsing circle that provides visual feedback:

- **Color**:
  - **Orange**: Downbeat (first beat of measure)
  - **Blue**: Other beats
  - **Gray**: Metronome stopped

- **Size**: Pulses larger on downbeat, smaller on other beats
- **BPM Display**: Shows current tempo in center

### BPM Controls

#### Large BPM Display
Shows current tempo in large, easy-to-read numbers (30-300 BPM)

#### Tempo Adjustment Buttons
- **-10**: Decrease tempo by 10 BPM (quick coarse adjustment)
- **-1**: Decrease tempo by 1 BPM (fine tuning)
- **+1**: Increase tempo by 1 BPM (fine tuning)
- **+10**: Increase tempo by 10 BPM (quick coarse adjustment)

#### BPM Slider
- Drag to set any tempo from 30 to 300 BPM
- Precise control over full range
- Updates tempo in real-time

### Tap Tempo

**Button**: Purple "Tap Tempo" button

**Purpose**: Set tempo by tapping rhythmically

**How to Use**:
1. Tap button in rhythm (at least 2 taps)
2. Metronome calculates average tempo
3. Tempo updates automatically
4. Tap multiple times (up to 8) for more accuracy

**Pro Tips**:
- Tap at least 4 times for best accuracy
- Taps older than 3 seconds are ignored
- Restart tapping if you make a mistake

**Use Cases**:
- Matching tempo of recorded song
- Setting tempo from band rehearsal
- Quick tempo adjustments during practice

### Time Signature

**Picker**: Segmented control showing time signature options

**Available Signatures**:
- **2/4**: March, polka (2 beats per measure)
- **3/4**: Waltz (3 beats per measure)
- **4/4**: Common time, most popular songs (4 beats per measure) - Default
- **5/4**: Unusual time signature, progressive rock (5 beats per measure)
- **6/8**: Compound meter (6 beats per measure)
- **7/8**: Unusual time signature, folk, progressive (7 beats per measure)
- **9/8**: Compound meter (9 beats per measure)
- **12/8**: Slow blues, ballads (12 beats per measure)

**Behavior**:
- First beat of each measure is accented (orange visual, different sound)
- Beat counter resets at end of each measure
- Visual indicator distinguishes downbeat clearly

### Subdivisions

**Picker**: None, 8th Notes, 16th Notes

**Purpose**: Add click subdivisions between main beats

**Options**:
- **None**: Only main beats (default)
- **8th Notes**: 2 clicks per beat (useful for fast tempos)
- **16th Notes**: 4 clicks per beat (useful for precision timing)

**Visual Feedback**: Subdivision clicks are lighter/smaller than main beats

**Use Cases**:
- **None**: Simple timing, ballads, slow songs
- **8th Notes**: Medium tempo songs, practicing eighth note patterns
- **16th Notes**: Fast songs, intricate rhythms, technical practice

### Volume

**Slider**: Speaker icon on left, high volume icon on right

**Range**: 0% (silent) to 100% (maximum)

**Default**: 70%

**Percentage Display**: Shows current volume as percentage

**Pro Tips**:
- Lower volume (30-50%) for quiet practice
- Higher volume (70-100%) for band rehearsal
- Adjust based on environment noise level

### Sound Type

**Picker**: Click, Beep, Drum, Woodblock

**Currently**: All use synthesized click sounds with different frequencies

**Accent vs. Regular**:
- **Downbeat** (first beat): Higher frequency (1200 Hz), louder
- **Regular beats**: Medium frequency (800 Hz)
- **Subdivisions**: Lower frequency (600 Hz), shorter

**Future**: Different sound samples for each type

### Visual Only Mode

**Toggle**: "Visual Only (Silent)"

**Purpose**: Silent metronome with only visual feedback

**When Enabled**:
- ✅ Visual pulsing continues
- ✅ Haptic feedback continues
- ❌ Audio clicks disabled

**Use Cases**:
- Recording sessions (no metronome bleed)
- Quiet environments (library, late night)
- Performance with in-ear monitors
- Practicing with headphones playing track

**Icon Indicator**:
- Speaker icon when audio enabled
- Speaker with slash when visual only

### Presets

**Purpose**: Quick access to common tempo/time signature combinations

**Built-in Presets**:
1. **Slow Practice** - 60 BPM, 4/4
   - Learning new songs
   - Technical exercises
   - Building muscle memory

2. **Moderate** - 90 BPM, 4/4
   - Comfortable practice tempo
   - Medium speed songs
   - Warm-up exercises

3. **Standard** - 120 BPM, 4/4
   - Common song tempo
   - Moderate rock/pop
   - General practice

4. **Fast** - 160 BPM, 4/4
   - Upbeat songs
   - Punk, fast rock
   - Speed building

5. **Waltz** - 90 BPM, 3/4
   - Traditional waltzes
   - Triple meter songs
   - Oom-pah-pah patterns

6. **March** - 120 BPM, 2/4
   - Marches, polkas
   - Duple meter
   - Military cadences

**How to Use**:
- Tap any preset button
- Tempo and time signature update immediately
- Metronome continues running if already playing

## Floating Indicator

### Location
Bottom-right corner of song view (outside scrollable content)

### Appearance

**When Stopped**:
- Gray circle with metronome icon
- Subtle, non-distracting
- Always visible

**When Playing**:
- Pulsing colored circle (orange/blue)
- BPM number displayed
- "BPM" label

### Interaction
- Tap to open full metronome controls
- Does not interfere with scrolling or reading
- Remains visible during autoscroll

## Integration with Songs

### Auto-Load Tempo

**Behavior**: When opening a song, if the song has a tempo value, the metronome automatically loads it

**Example**:
- Song metadata shows "Tempo: 120 BPM"
- Open song → Metronome set to 120 BPM
- Start metronome → Plays at song tempo

**Manual Override**: You can always change tempo in metronome controls

### Saving Tempo to Song

**Current**: Tempo is not automatically saved back to song

**Future**: Option to save metronome tempo to song metadata

### Count-In (Future)

**Planned Feature**: Count-in bars before autoscroll starts
- Set number of bars (1, 2, 4)
- Metronome counts in
- Autoscroll starts on downbeat

### Sync with Autoscroll (Future)

**Planned Feature**: Lock autoscroll speed to metronome tempo
- Calculate scroll speed from BPM and song length
- Perfect synchronization
- Adjust autoscroll when tempo changes

## Use Cases

### Learning New Songs

**Workflow**:
1. Start with slow tempo (60-80 BPM)
2. Practice section repeatedly
3. Gradually increase tempo (+5 BPM increments)
4. Reach target tempo over multiple sessions

**Benefits**:
- Build muscle memory correctly
- Avoid rushing or dragging
- Track progress by tempo achieved

### Technical Practice

**Workflow**:
1. Set metronome to comfortable tempo
2. Enable subdivisions if needed (8th or 16th notes)
3. Practice scales, arpeggios, exercises
4. Increase tempo when mastered

**Benefits**:
- Perfect timing consistency
- Even note placement
- Quantifiable improvement

### Rehearsal with Band

**Workflow**:
1. Set metronome to agreed tempo
2. Enable Visual Only mode if audio causes issues
3. Band plays along with visual indicator
4. Maintain consistent tempo across song

**Benefits**:
- Prevents tempo drift
- Locks in groove
- Builds tight ensemble timing

### Recording Preparation

**Workflow**:
1. Practice song with metronome
2. Enable Visual Only mode
3. Record performance
4. No metronome bleed in recording

**Benefits**:
- Clean recording
- Perfect timing
- Professional results

### Live Performance

**Not Recommended**: Generally avoid using metronome during live performance

**Exception**: Some electronic/pop artists use click tracks in in-ear monitors

**Alternative**: Use metronome during rehearsal to internalize tempo

## Best Practices

### Setting Tempo

✅ **DO**:
- Start slower than target tempo
- Use tap tempo to match existing recordings
- Gradually increase tempo over practice sessions
- Take breaks when increasing tempo
- Listen to downbeat accent for timing reference

❌ **DON'T**:
- Practice only at full tempo
- Ignore tempo drift during practice
- Increase tempo too quickly
- Practice sloppily at high tempo
- Rely only on metronome (develop internal sense)

### Using Time Signatures

✅ **DO**:
- Match metronome to song's time signature
- Feel the downbeat emphasis
- Count along with metronome initially
- Internalize the measure length
- Use appropriate time signature for song

❌ **DON'T**:
- Always use 4/4 regardless of song
- Ignore downbeat accent
- Subdivide too much (unless necessary)
- Use wrong time signature for feel

### Volume Settings

✅ **DO**:
- Adjust volume for environment
- Use lower volume for quiet practice
- Test volume before starting session
- Save hearing with appropriate levels
- Balance with instrument volume

❌ **DON'T**:
- Max out volume unnecessarily
- Use volume too low to hear clearly
- Compete with band volume in rehearsal
- Ignore hearing fatigue

### Visual vs. Audio

✅ **DO**:
- Use audio for active practice
- Use visual for recording
- Use visual in quiet environments
- Combine visual and audio for learning
- Use haptic feedback as backup

❌ **DON'T**:
- Rely only on visual (less immediate)
- Ignore visual indicator completely
- Use audio in recording sessions
- Forget visual option exists

## Troubleshooting

### Metronome Won't Start

**Problem**: Tapping play button doesn't start metronome

**Possible Causes**:
1. Audio session permission denied
2. Device muted or silent mode
3. Audio output device disconnected

**Solutions**:
- Check device volume
- Disable silent mode
- Check Lyra audio permissions in Settings
- Restart app
- Try Visual Only mode

### Tempo Inaccurate

**Problem**: Metronome doesn't sound precise

**Possible Causes**:
1. Background processes consuming CPU
2. Low battery power
3. Audio buffer issues

**Solutions**:
- Close other apps
- Charge device
- Restart metronome
- Restart app if persistent
- Use faster device for critical timing

### Can't Hear Clicks

**Problem**: Metronome playing but no sound

**Possible Causes**:
1. Visual Only mode enabled
2. Volume set to 0%
3. Device muted
4. Audio output wrong (Bluetooth, etc.)

**Solutions**:
- Disable Visual Only mode
- Increase volume slider
- Check device volume
- Check audio output in iOS Settings
- Try wired headphones

### Clicks Sound Harsh

**Problem**: Metronome sound is unpleasant

**Current Limitation**: Sound synthesis is basic

**Solutions**:
- Lower volume
- Use different sound type (when available)
- Enable Visual Only mode
- Use external metronome for better sounds

**Future**: Higher quality sound samples

### Floating Button in the Way

**Problem**: Metronome indicator covers content

**Current**: Fixed position bottom-right

**Workaround**:
- Scroll content to avoid overlap
- Open metronome controls to access covered content
- Stop metronome if not needed

**Future**: Draggable indicator position

### Battery Drain

**Problem**: Metronome uses too much battery

**Cause**: AVAudioEngine and Timer running continuously

**Solutions**:
- Use Visual Only mode (disables audio engine)
- Stop metronome when not actively practicing
- Charge device during long sessions
- Reduce volume (minimal effect)

**Expected Usage**: Minimal impact for 1-2 hour sessions

## Tips & Tricks

### Progressive Tempo Training

**Method**: Gradually increase practice tempo

1. Start at comfortable tempo (e.g., 80 BPM)
2. Practice section/song 3-5 times perfectly
3. Increase tempo by 5 BPM
4. Repeat until reaching target tempo

**Benefits**: Builds speed without sacrificing accuracy

### Tap Tempo from Recording

**Method**: Match metronome to recorded song

1. Play recorded song
2. Tap Tempo button along with beat
3. Tap 4-8 beats
4. Metronome locks to song tempo
5. Practice along

**Benefits**: Perfect synchronization with original

### Subdivisions for Precision

**Method**: Use subdivisions for complex rhythms

1. Set main tempo
2. Enable 8th or 16th note subdivisions
3. Practice with detailed clicks
4. Remove subdivisions when internalized

**Use**: Fast runs, intricate rhythms, precision timing

### Visual-Only Recording

**Method**: Record clean takes with timing

1. Enable Visual Only mode
2. Position indicator in peripheral vision
3. Record performance
4. Perfect timing, no metronome bleed

**Benefits**: Professional-quality recordings

### Waltz and Compound Time

**Method**: Practice triple-meter songs correctly

1. Select 3/4 for waltz feel
2. Or select 6/8 for compound meter
3. Feel the downbeat emphasis
4. Count "ONE two three" or "ONE two three FOUR five six"

**Benefit**: Authentic time signature feel

## Advanced Features

### Haptic Feedback

**What**: Device vibrates with each beat

**Behavior**:
- Medium intensity on downbeat
- Light intensity on other beats
- Works even in Visual Only mode

**Use Cases**:
- Silent practice with tactile cue
- Backup for audio feedback
- Accessibility for hearing impaired

### Audio Engine

**Technology**: AVAudioEngine for precise timing

**Benefits**:
- Sub-millisecond accuracy
- Professional-grade timing
- Low latency
- Multiple simultaneous sounds

**Configuration**: Automatic, no user setup needed

### Sound Synthesis

**Current**: Sine wave clicks with envelope

**Frequencies**:
- Downbeat: 1200 Hz
- Regular beat: 800 Hz
- Subdivision: 600 Hz

**Envelope**: Quick attack, exponential decay

**Future**: Recorded sound samples

## Keyboard Shortcuts

*Note: Keyboard shortcuts for metronome are not currently implemented but are planned for future release.*

**Planned**:
- M: Toggle metronome
- T: Open tap tempo
- +/-: Increase/decrease tempo
- Space: Play/Stop metronome
- V: Toggle visual only mode

## FAQ

**Q: Why is there a floating button in my song view?**
A: That's the metronome indicator. Tap it to open controls. It's always visible for quick access.

**Q: Can I save the metronome tempo back to my song?**
A: Not automatically yet. Future update will allow saving metronome tempo to song metadata.

**Q: Does the metronome work with autoscroll?**
A: Yes, but they're independent currently. Future update will sync autoscroll to metronome tempo.

**Q: Can I hide the metronome indicator?**
A: Not currently. It's designed to be minimal and non-intrusive. Future update may add hide option.

**Q: What's the most accurate tempo range?**
A: All tempos (30-300 BPM) are accurate. Higher tempos may challenge device audio processing.

**Q: Can I use the metronome with PDF songs?**
A: Yes, the indicator appears in text mode only, but you can use metronome with any view.

**Q: Why does tapping play/stop cause a delay?**
A: Audio engine initialization takes a moment. Subsequent starts are faster.

**Q: Can I use different sounds for different beats?**
A: Currently all use synthesized clicks. Future update will add sound sample selection.

**Q: Does the metronome drain battery?**
A: Minimal impact. Audio engine is efficient. Use Visual Only mode to reduce consumption further.

**Q: Can I count in bars before starting to play?**
A: Not yet. Count-in feature is planned for future release.

**Q: How do I practice gradually speeding up a song?**
A: Use the progressive tempo training method: start slow, practice perfectly, increase by 5 BPM increments.

**Q: Can I use the metronome during live performance?**
A: Possible, but not recommended unless you're used to playing with click tracks.

**Q: What's the difference between 3/4 and 6/8?**
A: 3/4 has 3 quarter-note beats per measure (waltz). 6/8 has 6 eighth-note beats (often felt as 2 groups of 3).

**Q: Why does tap tempo keep resetting?**
A: Taps older than 3 seconds are discarded. Tap consistently within 3-second window.

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Related Guides**: AUTOSCROLL_GUIDE.md, CHORDPRO_FORMAT.md
