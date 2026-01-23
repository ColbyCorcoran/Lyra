# Advanced Foot Pedal System

Comprehensive guide to Lyra's best-in-class foot pedal support, going far beyond basic page turning.

## Overview

Lyra's advanced pedal system supports:
- **Multiple simultaneous pedals** with intelligent chaining
- **12+ popular pedal models** with auto-detection
- **Advanced gestures**: double press, long press, simultaneous, sequences
- **Expression pedals** for continuous control
- **Mode-based profiles** (Performance, Practice, Annotation, etc.)
- **Visual and audio feedback** with customization
- **Context-aware actions** that adapt to your workflow

## Supported Pedal Models

### AirTurn Series
- **BT-200**: 2 pedals, Bluetooth
- **BT-500**: 4 pedals, Bluetooth
- **QUAD**: 4 pedals, multi-mode
- **DUO**: 2 pedals, compact
- **PED**: 4 pedals + expression pedal
- **PED Pro**: 6 pedals + expression pedal

### PageFlip Series
- **Firefly**: 2 pedals, ultra-portable
- **Butterfly**: 4 pedals, rechargeable
- **Cicada**: 4 pedals, advanced features

### Other Brands
- **Donner Page Turner**: 2-4 pedals
- **iRig BlueTurn**: 2 pedals, compact
- **Generic Bluetooth**: Auto-detected
- **USB Pedals**: Mac support

Auto-detection identifies your specific model and configures optimal defaults.

## Quick Start

### 1. Connect Your Pedal

**Bluetooth Pedals:**
1. Turn on pedal
2. iOS Settings → Bluetooth
3. Select your pedal
4. Return to Lyra

**USB Pedals (Mac only):**
1. Plug in USB cable
2. Lyra detects automatically

### 2. Configure

1. Settings → Foot Pedals → Advanced
2. Select your pedal from detected devices
3. Choose a profile or create custom mapping
4. Test with "Test Mode"

### 3. Start Using

Pedals work immediately in:
- Song display view
- Performance view
- Set list view
- Editing view (if configured)

## Advanced Gesture System

### Press Types

#### Single Press
Quick tap releases immediately.
```
Use for: Most actions (next song, scroll, etc.)
```

#### Double Press
Two quick taps within 0.5 seconds.
```
Use for: Quick transpose, favorite toggle, mode switch
Example: Double-press pedal 1 = Transpose up
```

#### Long Press
Hold for 0.5+ seconds.
```
Use for: Jump actions, blank screen, reset functions
Example: Long-press pedal 2 = Jump to top
```

#### Triple Press
Three quick taps (advanced).
```
Use for: Rarely-used but important actions
Example: Triple-press = Switch profile
```

### Simultaneous Presses

Press multiple pedals at the same time for special actions.

**Examples:**
- Pedals 1+2 together = Start recording
- Pedals 3+4 together = Toggle fullscreen
- Pedals 1+3 together = Switch to annotation mode

**Configuration:**
```
1. Pedal Mapper → Select first pedal
2. Choose action
3. Enable "Requires Simultaneous"
4. Select additional pedal(s)
5. Save
```

### Pedal Sequences

Tap pedals in sequence for complex actions.

**Examples:**
- 1-2-3 = Switch to performance mode
- 4-3-2-1 = Reset all settings
- 1-1-2 = Emergency blank all displays

**Configuration:**
```
1. Pedal Mapper → "Add Sequence"
2. Enter sequence: [1, 2, 3]
3. Choose action
4. Set timeout (default: 2 seconds)
5. Save
```

## Multi-Pedal Support

### Connect Multiple Pedals

Connect up to 4 separate pedal devices simultaneously!

**Chain Modes:**

#### Independent Mode
Each pedal device has its own mappings.
```
AirTurn BT-200 (pedals 1-2): Song navigation
PageFlip Firefly (pedals 3-4): Scrolling
```

#### Sequential Mode
All pedals numbered sequentially.
```
Device 1: Pedals 1-2
Device 2: Pedals 3-4
Device 3: Pedals 5-6
Total: 6 pedals, all mappable
```

#### Mirrored Mode
All pedals execute same actions.
```
Useful for: Multiple performers sharing controls
Any pedal press = Next song (for example)
```

### Priority System

Set device priority for conflict resolution:
```
Priority 1 (Primary): Main pedal board
Priority 2: Backup pedal
Priority 3: Remote control pedal
```

Higher priority devices take precedence if same key pressed simultaneously.

## Pedal Modes

Different modes for different scenarios. Switch instantly with mode-switch combo.

### Performance Mode
**Focus:** Live performance, set navigation
**Default Actions:**
- Pedal 1: Previous song
- Pedal 2: Next song
- Pedal 3: Scroll down
- Pedal 4: Scroll up

**Advanced:**
- Long-press 1: Jump to first song
- Long-press 2: Jump to last song
- 1+2 together: Mark song performed

### Practice Mode
**Focus:** Section work, repetition
**Default Actions:**
- Pedal 1: Previous section
- Pedal 2: Next section
- Pedal 3: Loop current section
- Pedal 4: Toggle metronome

**Advanced:**
- Double-press 3: Clear loop
- Long-press 4: Metronome tempo adjust

### Annotation Mode
**Focus:** Adding notes during performance
**Default Actions:**
- Pedal 1: Add sticky note at current position
- Pedal 2: Toggle annotation visibility
- Pedal 3: Scroll down
- Pedal 4: Scroll up

**Advanced:**
- Long-press 1: Add drawing annotation
- Double-press 2: Delete last annotation

### Editing Mode
**Focus:** Song editing, field navigation
**Default Actions:**
- Pedal 1: Previous field
- Pedal 2: Next field
- Pedal 3: Save
- Pedal 4: Cancel

**Useful for:** Hands-free editing while playing instrument

### Teaching Mode
**Focus:** Lessons, instruction
**Default Actions:**
- Pedal 1: Decrease font size
- Pedal 2: Increase font size
- Pedal 3: Previous section
- Pedal 4: Next section

**Advanced:**
- Long-press 1/2: Reset font size
- 3+4 together: Toggle student view

### Recording Mode
**Focus:** Audio recording, playback
**Default Actions:**
- Pedal 1: Start recording
- Pedal 2: Stop recording
- Pedal 3: Play/pause playback
- Pedal 4: Loop section

### Mode Switching

**Method 1: Pedal Combo**
Set a specific pedal combination to cycle modes.
```
Example: Pedals 1+4 together = Next mode
```

**Method 2: Action Assignment**
Assign "Switch Mode" action to any pedal.
```
Example: Triple-press pedal 2 = Cycle through modes
```

**Method 3: Context-Aware (Auto)**
Lyra switches modes automatically based on current view.
```
In song display → Performance mode
In editor → Editing mode
In annotations view → Annotation mode
```

## Expression Pedal Support

Continuous input pedals (0-127 or 0-100%) for smooth, real-time control.

### Supported Pedals
- AirTurn PED (built-in expression)
- AirTurn PED Pro (built-in expression)
- Generic MIDI expression pedals
- USB expression pedals (Mac)

### Expression Targets

#### Scroll Position
Control scroll position with pedal movement.
```
Heel down (0%) = Top of song
Toe down (100%) = Bottom of song

Perfect for: Hands-free scrolling during performance
```

#### Autoscroll Speed
Adjust autoscroll speed in real-time.
```
Heel down = Slower
Toe down = Faster

Perfect for: Adapting to tempo changes mid-song
```

#### Volume
Control audio playback volume.
```
Useful for: Backing track volume, click track volume
```

#### Screen Brightness
Adjust display brightness on the fly.
```
Useful for: Adapting to stage lighting changes
```

#### Font Size
Dynamic font size adjustment.
```
Useful for: Quick readability adjustments
```

#### Metronome Volume
Control click track volume independently.
```
Useful for: Fading metronome in/out
```

### Expression Curves

Transform pedal input for natural feel:

**Linear** (Default)
Direct 1:1 mapping. Predictable, responsive.

**Exponential**
Slow at first, fast at end. More control in lower range.

**Logarithmic**
Fast at first, slow at end. More control in upper range.

**S-Curve**
Slow at extremes, fast in middle. Smooth transitions.

### Configuration

```
1. Pedal Mapper → Expression Pedal tab
2. Enable expression pedal
3. Select target parameter
4. Set min/max values
5. Choose response curve
6. Adjust smoothing (reduce jitter)
7. Test and fine-tune
```

### Smoothing

Reduces jitter and sudden jumps.
```
0% = No smoothing (immediate response)
50% = Balanced (default)
100% = Heavy smoothing (very gradual)
```

## All Available Actions

### Navigation (11 actions)
- Next Song
- Previous Song
- Jump to Top
- Jump to Bottom
- Toggle Set List
- Next Section
- Previous Section
- Loop Section
- Mark Song Performed
- Toggle Favorite
- Jump to Specific Song (advanced)

### Scrolling (5 actions)
- Scroll Down
- Scroll Up
- Jump to Top
- Jump to Bottom
- Toggle Autoscroll

### Display (8 actions)
- Toggle Chords
- Toggle Lyrics
- Increase Font Size
- Decrease Font Size
- Cycle Display Mode
- Toggle Fullscreen
- Blank Screen
- Toggle Annotations

### Transpose (4 actions)
- Transpose Up
- Transpose Down
- Change Capo
- Reset Transpose

### Audio (5 actions)
- Toggle Metronome
- Start Recording
- Stop Recording
- Toggle Playback
- Loop Section

### Annotations (2 actions)
- Add Sticky Note
- Toggle Annotations

### Advanced (6 actions)
- Switch Profile
- Switch Mode
- Send MIDI Message
- Trigger Custom Action
- External Display Control
- Sync with Band (network)

## Pedal Profiles

Save complete pedal configurations for instant recall.

### Built-in Profiles

**Performance**
Live gigs, set navigation focus.

**Practice**
Section work, looping, metronome.

**Annotation**
Quick note-taking during performance.

**Teaching**
Font control, section navigation for lessons.

**Recording**
Recording and playback control.

**Transpose**
Quick key changes during performance.

### Custom Profiles

Create unlimited custom profiles for specific scenarios:

**Example: "Worship Service"**
```
Pedal 1: Previous song
Pedal 2: Next song
Pedal 3: Blank external display (announcements)
Pedal 4: Toggle metronome
Long-press 3: Emergency blank all displays
```

**Example: "Solo Practice"**
```
Pedal 1: Loop section
Pedal 2: Metronome on/off
Pedal 3: Transpose down
Pedal 4: Transpose up
Double-press 3: Reset to original key
```

**Example: "Band Rehearsal"**
```
Pedal 1: Previous section
Pedal 2: Next section
Pedal 3: Start recording
Pedal 4: Stop recording
Pedal 1+2: Jump to chorus
```

### Per-Song Profiles (Advanced)

Assign specific profiles to individual songs or sets.

```
Song A: Uses "Transpose" profile (lots of key changes)
Song B: Uses "Performance" profile (straight through)
Song C: Uses custom "Loop Heavy" profile (practice)
```

Auto-switches when song loads!

### Profile Management

**Save Profile:**
```
1. Configure pedal mappings
2. Settings → Foot Pedals → Save Profile
3. Name it (e.g., "Sunday Morning")
4. Optional: Add description
5. Save
```

**Load Profile:**
```
1. Settings → Foot Pedals → Profiles
2. Tap desired profile
3. Active immediately
```

**Export/Import:**
```
Export: Share → Export Profile → AirDrop/Email
Import: Open .pedalprofile file → Adds to Lyra
```

**Cloud Sync:**
```
Enable iCloud sync to share profiles across devices.
Perfect for bands - everyone uses same mappings!
```

## Visual Feedback

See exactly which pedal was pressed and what action executed.

### Feedback Styles

**Flash** (Default)
Quick color flash at screen edge corresponding to pedal.
```
Pedal 1 = Left edge flash
Pedal 2 = Right edge flash
Pedal 3 = Bottom-left flash
Pedal 4 = Bottom-right flash
```

**Pulse**
Pulsing circle animation.

**Ripple**
Ripple effect from pedal position.

**None**
No visual feedback (performance mode).

### Customization

**Color:**
Choose any color for feedback (default: blue).

**Duration:**
0.1 - 2.0 seconds (default: 0.3s).

**Intensity:**
Subtle, Medium, Strong.

**Position:**
Edge, Center, Custom.

### Action Labels

Optionally show action name during feedback:
```
[Flash] "Next Song"
[Flash] "Transpose Up"
[Flash] "Loop Section"
```

Helps during learning/configuration phase.

## Audio Feedback

Hear pedal presses with customizable sounds.

### Sound Options
- **Click**: Subtle keyboard click
- **Beep**: Short beep tone
- **Tap**: Percussion tap sound
- **None**: Silent operation

### Volume Control
Separate volume control for pedal sounds (0-100%).

**Recommendation:** Keep at 20-30% for subtle confirmation without distraction.

### Context-Aware Volume
Auto-duck volume during:
- Active audio playback
- Recording sessions
- Performances (if enabled)

## Configuration UI: Pedal Mapper

Visual pedal configuration interface.

### Layout View

Shows pedals 1-12 in visual grid:
```
[1] [2]
[3] [4]
[5] [6]
```

### Configuration

**Tap Virtual Pedal:**
Opens action assignment screen for that pedal.

**Configure Action:**
1. Select press type (single/double/long/triple)
2. Choose action from categorized list
3. Optional: Add simultaneous requirement
4. Optional: Set as part of sequence
5. Save

**Test Mode:**
Press physical pedals to see which number lights up.

**Conflict Detection:**
Warns if multiple pedals assigned same action.

### Quick Actions

- **Clear All**: Remove all mappings
- **Reset to Default**: Load built-in profile defaults
- **Duplicate**: Copy current config to new profile
- **Export**: Share configuration

## Test Mode

Essential for verifying pedal setup before performance.

### Features

**Real-time Detection:**
Shows which pedal pressed, key code received.

**Action Preview:**
Displays action that would execute (without executing).

**Timing Display:**
Shows press duration, double-press timing.

**Multi-Pedal Detection:**
Highlights simultaneous pedal presses.

**Expression Value:**
Real-time expression pedal position (if present).

### Test Checklist

Before each performance:
1. ✓ All pedals detected
2. ✓ Actions execute correctly
3. ✓ No conflicts/errors
4. ✓ Expression pedal responsive (if used)
5. ✓ Visual feedback working
6. ✓ Audio feedback at correct volume
7. ✓ Profile loaded correctly

## Advanced Features

### Context-Aware Actions

Actions adapt based on current view/context:

**"Next" Action:**
- In set list → Next song
- In single song → Next section
- In annotations → Next note

**"Add" Action:**
- In performance → Add to setlist
- In annotations → Add sticky note
- In favorites → Add favorite

**"Toggle" Action:**
- Context-determines what toggles

Enable in profile settings: `contextAware: true`

### MIDI Integration

Pedals can trigger MIDI messages for external gear.

**Use Cases:**
- Switch patches on keyboard
- Control lighting
- Trigger loops on looper pedal
- Change amp channels

**Configuration:**
```
1. Assign "Send MIDI" action to pedal
2. Configure MIDI message:
   - Program Change
   - Control Change
   - Note On/Off
   - SysEx
3. Set channel, value
4. Test
```

### Network Sync

Sync pedal presses across devices on network.

**Scenario:** Band leader's pedal advances everyone's charts.

```
1. Enable network sync
2. Leader device becomes primary
3. Other devices receive pedal events
4. Perfect sync across band
```

### Emergency Functions

Special pedal combos for emergencies:

**All Pedals Simultaneously:**
- Emergency stop all audio
- Blank all displays
- Pause performance

**Specific Combos:**
- 1+2+3+4 = Panic mode (stop everything)
- Long-press all = Reset to defaults

Configure in Advanced Settings.

## Troubleshooting

### Pedal Not Detected

**Check:**
1. Bluetooth enabled and paired
2. Pedal powered on
3. Battery level adequate
4. Not connected to another device

**Fix:**
1. Un-pair and re-pair Bluetooth
2. Restart pedal
3. Restart Lyra
4. Check iOS Bluetooth settings

### Wrong Actions Executing

**Causes:**
- Wrong profile active
- Key mapping mismatch
- Another app intercepting

**Fix:**
1. Verify active profile
2. Test in Test Mode
3. Check for conflicts
4. Reconfigure mappings

### Double Presses Not Working

**Causes:**
- Timeout too short
- Pedal hardware limitation

**Fix:**
1. Increase double-press window (Settings → Advanced → Timing)
2. Press faster
3. Verify pedal supports rapid presses

### Expression Pedal Jumpy

**Causes:**
- Low smoothing
- Electrical interference
- Worn potentiometer

**Fix:**
1. Increase smoothing (50-80%)
2. Calibrate expression pedal
3. Check connections
4. Replace pedal if worn

### Actions Delayed

**Causes:**
- Too much smoothing
- Low battery
- Bluetooth latency

**Fix:**
1. Reduce smoothing
2. Replace pedal battery
3. Move closer to device
4. Use wired connection if possible

## Best Practices

### For Live Performance

1. **Test Before Each Gig**
   Run Test Mode to verify all pedals working.

2. **Bring Backup Pedal**
   Always have spare, paired and configured.

3. **Keep It Simple**
   Don't over-complicate mappings. Muscle memory is key.

4. **Label Pedals**
   Physical labels on floor (tape) help in dark stages.

5. **Battery Check**
   Replace batteries before they run out mid-show.

### For Practice

1. **Use Loop Section**
   Map to easily-accessible pedal for repetition.

2. **Metronome Toggle**
   Quick on/off without hands.

3. **Transpose Pedals**
   Practice in multiple keys hands-free.

### For Teaching

1. **Font Size Control**
   Student pedals for font adjustment.

2. **Section Navigation**
   Teacher pedal to guide through song.

3. **Annotation Mode**
   Mark problem areas during lesson.

### Pedal Placement

**Single Musician:**
```
Place pedals directly in front, comfortable foot reach.
Pedal 1 (left) and Pedal 2 (right) most common.
```

**Band Setting:**
```
Each musician has own pedal setup.
Leader pedal can control all via network sync.
```

**Stage Setup:**
```
Secure pedals with velcro or cable ties.
Route cables safely to avoid tripping.
Keep spare batteries nearby.
```

## Appendix: Default Mappings

### 2-Pedal Setup
```
Pedal 1 (Left): Previous song / Previous section
Pedal 2 (Right): Next song / Next section
```

### 4-Pedal Setup
```
Pedal 1: Previous song
Pedal 2: Next song
Pedal 3: Scroll down
Pedal 4: Scroll up
```

### 6-Pedal Setup
```
Pedal 1: Previous song
Pedal 2: Next song
Pedal 3: Scroll down
Pedal 4: Scroll up
Pedal 5: Transpose down
Pedal 6: Transpose up
```

### With Expression Pedal
```
Pedals 1-4: As above
Expression: Scroll position control
```

## Support

### Resources
- **Video Tutorials**: lyra-app.com/pedals
- **Community Forum**: forum.lyra-app.com/pedals
- **Pedal Database**: lyra-app.com/pedals/compatibility

### Getting Help
1. In-app: Settings → Foot Pedals → Help
2. Email: pedal-support@lyra-app.com
3. Discord: discord.gg/lyra

---

**Make your foot pedals work for you!** 🎸👟

*Last Updated: January 2026*
*Compatible with: Lyra 2.0+*
