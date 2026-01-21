# Advanced Autoscroll Features Guide

## Overview

Lyra's advanced autoscroll features provide professional-grade control over automatic scrolling during live performance. These tools are designed for demanding scenarios like complex song arrangements, multi-section performances, and recordings.

## Features

### 1. Speed Zones

Configure different scroll speeds for each section of your song.

#### Use Cases
- **Faster Verses**: Speed up during verses to spend more time on choruses
- **Slower Bridges**: Slow down for technically difficult sections
- **Pause at Transitions**: Auto-pause when entering key sections

#### How to Use

1. **Open Speed Zones**
   - View a song in text mode
   - Tap the menu button (⋯) → Advanced Autoscroll → Speed Zones

2. **Configure Sections**
   - Each section (Verse, Chorus, Bridge, etc.) is listed
   - Tap a section to configure:
     - **Speed Multiplier**: 0.5x to 2.0x (stacks with global speed)
     - **Pause at Start**: Auto-pause when entering section
     - **Auto-resume Duration**: Resume after N seconds or manual
     - **Enable/Disable**: Skip sections entirely

3. **Quick Presets**
   - **Uniform Speed**: Reset all to 1.0x
   - **Verses Faster**: Verses 1.25x, Chorus 0.9x
   - **Chorus Faster**: Chorus 1.25x, Verses 0.9x
   - **Pause at Chorus**: Auto-pause for 3 seconds at each chorus

#### Speed Multiplier Math
```
Effective Speed = Global Speed × Section Speed
Example: 1.5x global × 0.75x section = 1.125x effective
```

#### Tips
- Start with uniform speed and adjust sections that feel too fast/slow
- Use pause at start for difficult transitions or key changes
- Set short auto-resume durations (1-3s) for quick breath breaks
- Disable unused sections (intros, outros) to focus on main content

---

### 2. Timeline Recording

Record your exact scroll pattern and replay it perfectly every time.

#### Use Cases
- **Complex Arrangements**: Save scroll patterns for songs with varied pacing
- **Performance Consistency**: Replay the exact same scroll every time
- **Rehearsal Tool**: Record during practice, replay during performance

#### How to Use

1. **Start Recording**
   - View a song in text mode
   - Tap menu → Advanced Autoscroll → Timeline Recording
   - Tap "Record" button
   - The recording view will dismiss

2. **Record Your Pattern**
   - Manually scroll the song at your desired pace
   - The timeline captures your scroll position over time
   - Red recording indicator shows in the status bar

3. **Stop & Save**
   - Tap menu → Advanced Autoscroll → Timeline Recording
   - Tap "Stop" button
   - Enter a name for the timeline (e.g., "Performance Version")
   - Tap "Save"

4. **Use a Timeline**
   - In Timeline Recording view, tap a timeline to select it
   - Selected timeline will be used for autoscroll playback
   - Tap again to deselect and return to standard autoscroll

#### How It Works
- Records keyframes (time + position + speed) at regular intervals
- Interpolates smoothly between keyframes during playback
- Ignores global speed settings when timeline is active
- Can be included in presets

#### Tips
- Record at performance speed, not practice speed
- Use smooth, consistent scrolling motions
- Record multiple takes and keep the best one
- Name timelines descriptively ("Fast Version", "Slow Practice", etc.)

---

### 3. Smart Markers

Place intelligent pause points anywhere in your song.

#### Use Cases
- **Key Changes**: Pause before modulation to mentally prepare
- **Difficult Sections**: Stop before technically challenging parts
- **Page Turns**: Mimic physical page turn timing
- **Rehearsal Marks**: Follow printed sheet music rehearsal markers

#### How to Use

1. **Open Markers**
   - View a song in text mode
   - Tap menu → Advanced Autoscroll → Smart Markers

2. **Add a Marker**
   - Tap "Add Marker"
   - Configure:
     - **Name**: Descriptive label ("Key Change to D", "Bridge Entry")
     - **Position**: Where in song (0-100%, adjustable with slider)
     - **Action**: Pause, Speed Change, or Notification
     - **Auto-resume**: Manual or timer (1-10 seconds)

3. **Edit Markers**
   - Tap any marker to edit
   - Adjust position, action, or timing
   - Tap "Done" to save changes

4. **Delete Markers**
   - Swipe left on a marker → Delete
   - Or use the Edit button → Delete

#### Marker Actions

**Pause**
- Stops autoscroll at marker position
- Optional auto-resume after N seconds
- Haptic feedback when triggered
- Use for: Transitions, key changes, page turns

**Speed Change** (Visual indicator only)
- Marks point where speed changes
- Provides haptic feedback
- Use with speed zones for complex arrangements
- Use for: Tempo changes, dynamic shifts

**Notification** (Visual indicator only)
- Shows notification when passing marker
- No pause, just awareness
- Use for: Rehearsal marks, cues, reminders

#### Visual Timeline
- See all markers positioned on a timeline
- Color-coded by action type:
  - Orange: Pause
  - Blue: Speed Change
  - Green: Notification
- Drag markers to adjust position visually

#### Tips
- Use short auto-resume (1-3s) for breath marks
- Use manual resume for major transitions
- Place markers slightly before the actual point (reaction time)
- Combine with speed zones for maximum control

---

### 4. Presets

Save complete autoscroll configurations for instant recall.

#### What's Included
- Speed zones for all sections
- Timeline (if selected)
- Smart markers
- Default duration and speed

#### Use Cases
- **Multiple Arrangements**: Different setups for studio vs. live
- **Quick Setup**: One tap to configure everything
- **Experimentation**: Try different configurations without losing originals
- **Template**: Create base configurations for similar songs

#### How to Use

1. **Create a Preset**
   - Configure speed zones, timeline, and markers as desired
   - Tap menu → Advanced Autoscroll → Presets
   - Tap "Save Current as Preset"
   - Enter a name (e.g., "Performance Setup", "Practice Mode")
   - Tap "Save"

2. **Apply a Preset**
   - Open Presets view
   - Tap any preset to apply it immediately
   - All settings are loaded instantly
   - Green checkmark shows active preset

3. **Manage Presets**
   - **Duplicate**: Long press → Duplicate (create variations)
   - **Delete**: Swipe left → Delete
   - **Deactivate**: Tap "Deactivate" to return to manual configuration

#### Preset Information
Each preset shows:
- Number of configured speed zones
- Whether it includes a timeline
- Default duration
- Default speed multiplier

#### Tips
- Create presets for common scenarios:
  - "Fast Performance" - All sections 1.25x
  - "Slow Practice" - All sections 0.75x with pauses
  - "Live Recording" - Timeline from best take
- Name presets descriptively with context
- Duplicate and modify instead of starting from scratch
- Deactivate when experimenting so you can return easily

---

## Workflow Examples

### Example 1: Worship Song with Varying Dynamics

**Song Structure**: Verse 1, Chorus 1, Verse 2, Chorus 2, Bridge, Chorus 3

**Goal**: Spend more time on choruses, pause before bridge

**Setup**:
1. Open Speed Zones
2. Configure:
   - Verses: 1.2x (move through quickly)
   - Choruses: 0.9x (more time for congregation)
   - Bridge: 1.0x with "Pause at Start", 2s auto-resume
3. Save as preset: "Sunday Morning"

**Result**: Automatically adjusts pace and pauses before bridge.

---

### Example 2: Complex Jazz Arrangement

**Song Structure**: Intro, Head, Solo Section, Head, Outro

**Goal**: Perfect consistency for every performance

**Setup**:
1. During rehearsal, start Timeline Recording
2. Manually scroll through entire song at performance pace
3. Stop recording, name it "Performance Take 3"
4. In Presets, create "Jazz Standard" with this timeline
5. Add markers at key moments:
   - "Solo Entry" - Pause, 1s auto-resume
   - "Coda" - Notification

**Result**: Exact same scroll pattern every performance, with cue markers.

---

### Example 3: Practice vs. Performance Modes

**Goal**: Two different setups - slow for practice, fast for performance

**Setup**:

**Practice Mode**
1. Speed Zones: All sections 0.75x
2. Markers at difficult passages: Pause, manual resume
3. Save as preset: "Practice"

**Performance Mode**
1. Speed Zones: Uniform 1.0x
2. Remove pause markers (keep notifications only)
3. Save as preset: "Performance"

**Result**: Switch between modes with one tap in Presets view.

---

## Best Practices

### Speed Zones
- ✅ **DO**: Start simple, add complexity as needed
- ✅ **DO**: Test during full run-through before performance
- ✅ **DO**: Use section pauses for breath/transitions
- ❌ **DON'T**: Over-complicate with too many speed changes
- ❌ **DON'T**: Use extreme multipliers (> 1.5x or < 0.75x)

### Timeline Recording
- ✅ **DO**: Record multiple takes and keep the best
- ✅ **DO**: Scroll smoothly and consistently
- ✅ **DO**: Record at actual performance speed
- ❌ **DON'T**: Rush through recording
- ❌ **DON'T**: Use jerky, inconsistent scrolling
- ❌ **DON'T**: Record if you're still learning the song

### Smart Markers
- ✅ **DO**: Place markers slightly early (reaction time)
- ✅ **DO**: Use short auto-resume for quick pauses
- ✅ **DO**: Test marker timing during rehearsal
- ❌ **DON'T**: Overuse markers (too many interruptions)
- ❌ **DON'T**: Place at exact position (place before)
- ❌ **DON'T**: Forget to test with actual performance setup

### Presets
- ✅ **DO**: Use descriptive names with context
- ✅ **DO**: Create presets for common scenarios
- ✅ **DO**: Duplicate and modify for variations
- ❌ **DON'T**: Create too many similar presets
- ❌ **DON'T**: Use generic names ("Preset 1", "Test")

---

## Troubleshooting

### Speed Zones Not Working

**Problem**: Section speeds aren't being applied

**Solutions**:
1. Verify song has been parsed correctly (check section labels)
2. Ensure section configs are saved (tap "Save" in Speed Zones)
3. Check if a timeline is active (timelines override speed zones)
4. Restart autoscroll to reload configuration

---

### Timeline Playback Issues

**Problem**: Timeline playback feels jerky or incorrect

**Solutions**:
1. Re-record timeline with smoother scrolling
2. Ensure you scrolled the entire song during recording
3. Check that timeline duration matches song duration
4. Verify timeline is selected (checkmark in Timeline Recording view)

---

### Markers Not Triggering

**Problem**: Autoscroll doesn't pause at markers

**Solutions**:
1. Verify markers are saved (tap "Save" in Markers view)
2. Check marker position is within song content (0-100%)
3. Ensure action is set to "Pause" not "Notification"
4. Restart autoscroll to reload markers

---

### Preset Not Applying

**Problem**: Tapping preset doesn't change settings

**Solutions**:
1. Check for active preset indicator (green checkmark)
2. Verify preset contains configurations (check counts)
3. Restart app if settings aren't persisting
4. Try duplicating preset and applying the duplicate

---

## Performance Tips

### For Live Performance
1. Test complete setup during soundcheck
2. Use presets for quick setup between songs
3. Keep speed zones simple (3-4 zones maximum)
4. Use short auto-resume durations (1-3s)
5. Have manual backup plan if autoscroll fails

### For Recording Sessions
1. Record timeline during best practice take
2. Use timeline playback for consistency
3. Add markers for producer cues
4. Create separate presets for takes vs. punch-ins

### For Music Therapy
1. Create patient-specific presets
2. Use slower speeds (0.75-0.85x) for accessibility
3. Add pause markers for patient participation
4. Keep configurations simple and predictable

### For Rehearsals
1. Use practice presets with slower speeds
2. Add markers at trouble spots
3. Use pause markers for section work
4. Create progression presets (slow → medium → fast)

---

## Keyboard Shortcuts & Accessibility

### Quick Actions During Playback
- **Tap Screen**: Pause/Resume
- **Swipe Up**: Increase speed
- **Swipe Down**: Decrease speed
- **Manual Scroll**: Auto-pause

### VoiceOver Support
All advanced features support VoiceOver:
- Speed zone configurations announced
- Marker positions and actions described
- Timeline playback progress spoken
- Preset names and contents detailed

---

## Technical Notes

### Section Detection
- Based on ChordPro section directives: `{start_of_verse}`, `{start_of_chorus}`, etc.
- OnSong format section headers also supported
- Manual sections work if song is properly formatted

### Timeline Storage
- Stored as keyframe data (timestamp + progress + speed)
- Interpolated linearly between keyframes
- Includes recording date for versioning

### Performance
- All features use 60fps CADisplayLink for smooth scrolling
- Section transitions are frame-perfect
- Marker checking is optimized for minimal overhead
- Timeline playback uses efficient interpolation

---

## FAQ

**Q: Can I use speed zones with timeline recording?**
A: Timeline recording overrides speed zones. If a preset has both, timeline takes priority when enabled.

**Q: How many markers can I add?**
A: No hard limit, but recommend 3-5 for optimal performance and usability.

**Q: Do presets work across different songs?**
A: No, each song has its own presets. However, you can manually recreate similar configurations.

**Q: Can I export/share presets?**
A: Not currently. Future versions may support preset sharing.

**Q: What happens if I edit song content after creating configurations?**
A: Speed zones and markers remain, but section IDs may change. Timelines remain valid but may not align perfectly.

**Q: Can I use advanced features with PDF attachments?**
A: No, advanced autoscroll only works with text mode (ChordPro/OnSong format).

**Q: Do markers work during timeline playback?**
A: Yes! Markers trigger based on progress, regardless of how that progress is generated.

**Q: Can I combine multiple presets?**
A: No, but you can duplicate a preset and manually add elements from another.

---

## Feedback & Support

Having issues or ideas for advanced autoscroll?
- Report bugs: [GitHub Issues](https://github.com/yourusername/lyra/issues)
- Feature requests: Use GitHub Discussions
- Documentation feedback: Submit a PR

---

**Version**: 1.1.0
**Last Updated**: January 2026
**Related Guides**: AUTOSCROLL_GUIDE.md, PERFORMANCE_TIPS.md
