# Sticky Notes Guide

## Overview

Lyra's sticky notes feature allows you to add visual annotations directly onto your chord charts. Perfect for performance notes, reminders, cues, and personalized markings that help you deliver flawless performances.

## What are Sticky Notes?

Sticky notes are colorful, draggable annotations that you can place anywhere on your song. They work like physical sticky notes, but with the power of digital:
- Color-coded for organization
- Rotatable for a natural, handwritten look
- Scalable to emphasize importance
- Persistent across sessions
- Easy to edit, duplicate, or delete

**Example Use Cases**:
- "Start soft here" for dynamics reminders
- "Capo to 3 after chorus" for mid-song changes
- "Watch conductor" for ensemble cues
- "Slow down" for tempo changes
- "Key change to D" for modulation notes

## Creating Sticky Notes

### Entering Annotation Mode

1. Open any song in text mode
2. Tap the note icon (📝) in the toolbar
3. The screen dims slightly with an orange banner at top
4. Banner reads: "Tap anywhere to add a sticky note"

### Placing a Sticky Note

1. While in annotation mode, tap any location on the song
2. The sticky note editor opens immediately
3. You're ready to add your content

### Quick Creation Tips

✅ **DO**:
- Place notes near relevant lyrics or chords
- Use annotation mode for rapid placement
- Exit mode when done to avoid accidental placements

❌ **DON'T**:
- Place too many notes - keep it essential
- Forget to exit annotation mode
- Overlap notes excessively

## Editing Sticky Notes

### Opening the Editor

**Method 1**: Tap any existing sticky note
**Method 2**: Long-press → Select "Edit" from context menu

### Editor Controls

#### Text Editor
- Multi-line text field
- Supports any length text
- Real-time preview
- Font size adjusts with selected size setting

#### Color Picker
Six preset colors optimized for readability:
- **Yellow** (#FFEB3B): Classic sticky note (black text)
- **Orange** (#FF9800): Urgent/important (black text)
- **Pink** (#F48FB1): Reminders (white text)
- **Blue** (#81D4FA): Informational (white text)
- **Green** (#A5D6A7): Positive/go ahead (black text)
- **Purple** (#CE93D8): Special notes (white text)

**Tip**: Text color automatically adjusts for optimal contrast

#### Font Size
Three size options:
- **Small**: 12pt - for brief annotations
- **Medium**: 14pt - standard readable size
- **Large**: 16pt - emphasis and important notes

#### Rotation Slider
- Range: -45° to +45°
- Step: 5° increments
- Reset button for quick return to 0°
- Creates natural, hand-placed appearance

#### Preview Section
- Live preview of your note
- Shows exact appearance before saving
- Includes rotation and color

#### Save & Cancel
- **Save**: Commits changes to database
- **Cancel**: Discards all changes
- **Delete** (edit mode only): Removes note permanently

## Interacting with Sticky Notes

### Drag to Move

**How**: Touch and drag the note
**Result**: Note follows your finger
**On Release**: Position saves automatically
**Range**: Constrained to song boundaries

**Use Case**: Repositioning notes after song layout changes

### Pinch to Scale

**How**: Two-finger pinch gesture on note
**Result**: Note scales up or down
**Range**: 0.5× to 1.5× original size
**On Release**: Scale saves automatically

**Use Case**: Emphasize critical reminders

### Rotate

**How**: Two-finger rotation gesture
**Result**: Note rotates around center
**Range**: -45° to +45°
**On Release**: Rotation saves automatically

**Use Case**: Create varied, natural appearance

### Long-Press Menu

Hold note for 0.5 seconds to open context menu:

**Edit**: Opens editor for text/color/size changes
**Duplicate**: Creates copy with slight offset
**Bring to Front**: Moves note above all others
**Send to Back**: Moves note below all others
**Delete**: Removes note (confirmation via destructive style)

## Sticky Note Organization

### Z-Order Management

Notes can overlap. Use z-order controls to arrange:

**Bring to Front**:
- Places note on top layer
- Useful for most important notes
- Accessible via context menu

**Send to Back**:
- Places note on bottom layer
- Useful for background context
- Accessible via context menu

**Default Order**: Notes appear in creation order (oldest on bottom)

### Color Coding System

Develop your own system, or use these suggestions:

**By Priority**:
- 🟨 Yellow: Normal notes
- 🟧 Orange: Important
- 🟥 Pink: Critical

**By Type**:
- 🟦 Blue: Technical notes (chords, timing)
- 🟩 Green: Dynamic notes (volume, feel)
- 🟪 Purple: Performance cues (watch, wait)

**By Section**:
- One color per song section
- Easy visual scanning
- Quick identification

## Persistence & Storage

### How Annotations are Saved

- **Database**: SwiftData model (Annotation)
- **Position**: Percentage-based (0.0-1.0) for device independence
- **Timing**: Auto-save after each change
- **Relationship**: Linked to specific Song

### Position System

**Percentage-Based Coordinates**:
```
xPosition: 0.0 = left edge, 1.0 = right edge
yPosition: 0.0 = top edge, 1.0 = bottom edge
```

**Benefits**:
- Works on any screen size (iPad, iPhone)
- Scales with zoom level
- Maintains relative position

### Data Stored Per Note

- Text content
- Background color (hex)
- Text color (hex)
- Font size (points)
- Rotation (degrees)
- Scale factor
- X/Y position (percentages)
- Creation date
- Modified date

## Use Cases

### Performance Reminders

**Scenario**: Song has tricky transition

**Solution**:
1. Place orange sticky note at transition point
2. Write: "Slow down - let bass lead"
3. Rotate slightly for visibility
4. Scale up for emphasis

### Dynamic Markings

**Scenario**: Need volume cues throughout song

**Solution**:
1. Use green notes for crescendos
2. Pink notes for key dynamics
3. Brief text: "ff", "pp", "cresc."
4. Small size to avoid clutter

### Lyrics Corrections

**Scenario**: Incorrect lyrics in original chart

**Solution**:
1. Yellow note over incorrect lyrics
2. Write correct version
3. Keep rotation minimal for readability
4. Delete note after song is updated

### Capo/Transpose Reminders

**Scenario**: Song uses capo mid-performance

**Solution**:
1. Blue note at capo change point
2. "CAPO 3 HERE - Play G shapes"
3. Large size, no rotation
4. Bring to front for visibility

### Team Communication

**Scenario**: Multiple musicians sharing song

**Solution**:
1. Purple notes for band cues
2. "Guitar solo - 8 bars"
3. "Bass holds root on this chord"
4. Color code by instrument

### Song Structure Notes

**Scenario**: Complex arrangement with repeats

**Solution**:
1. Green notes for navigation
2. "Repeat chorus 2x"
3. "Bridge after solo"
4. "Tag ending"

## Best Practices

### Creating Notes

✅ **DO**:
- Be concise - notes should be glanceable
- Use color consistently
- Place near relevant content
- Test visibility at performance distance
- Update or delete outdated notes

❌ **DON'T**:
- Write paragraphs - keep it brief
- Use too many colors randomly
- Place notes far from context
- Clutter the chart excessively
- Leave obsolete notes

### Color Usage

✅ **DO**:
- Establish personal color system
- Use high-contrast combinations
- Stick to 2-3 colors per song
- Choose colors for note type

❌ **DON'T**:
- Use all colors on one song
- Ignore text color contrast
- Change system between songs
- Choose colors purely for aesthetics

### Positioning

✅ **DO**:
- Place near relevant content
- Leave space for readability
- Use rotation sparingly
- Test on target device
- Adjust after layout changes

❌ **DON'T**:
- Cover important lyrics/chords
- Cluster notes too tightly
- Rotate beyond readability
- Assume all devices look the same
- Forget about portrait/landscape

### Performance Usage

✅ **DO**:
- Review notes before performance
- Update based on rehearsal feedback
- Remove temporary practice notes
- Keep critical notes prominent
- Test visibility from music stand distance

❌ **DON'T**:
- Add notes during performance
- Rely on annotation mode during show
- Forget to exit annotation mode
- Leave test notes on performance chart
- Over-annotate and create distraction

## Tips & Tricks

### Quick Note Templates

**Dynamics**: "ff", "pp", "mf", "cresc.", "dim."
**Tempo**: "rit.", "accel.", "a tempo", "slower"
**Cues**: "watch", "listen", "wait", "go"
**Structure**: "repeat", "skip", "D.C.", "D.S."
**Reminders**: "capo", "tune", "pedal on", "mute"

### Efficient Workflow

1. **Review Mode**: Read through song, note what needs annotation
2. **Annotate Mode**: Enter annotation mode, place all notes
3. **Edit Mode**: Fine-tune text, colors, positions
4. **Test Mode**: View from performance distance
5. **Cleanup Mode**: Remove unnecessary notes

### Multi-Song Consistency

For songs in the same book/set:
1. Use same color system across all songs
2. Keep note sizes consistent
3. Position similar notes in similar locations
4. Use templates for common notes

### Device Switching

Notes adapt to different screen sizes:
- Position: Percentage-based (scales automatically)
- Size: Scales with overall layout
- Visibility: Test on smallest target device first

## Troubleshooting

### Note Doesn't Appear

**Problem**: Created note but can't see it

**Possible Causes**:
1. Note is behind other notes
2. Scrolled past note location
3. Wrong view mode (PDF vs text)
4. Annotation didn't save

**Solutions**:
- Use context menu → Bring to Front
- Scroll through entire song
- Switch to text mode
- Try creating note again

### Can't Move Note

**Problem**: Drag gesture not working

**Possible Causes**:
1. In annotation mode (mode blocks gestures)
2. Autoscroll is active
3. Note is very small
4. Touch target is too small

**Solutions**:
- Exit annotation mode
- Pause autoscroll
- Scale up note first
- Long-press → Edit → reposition

### Note Overlaps Content

**Problem**: Note covers important lyrics/chords

**Possible Causes**:
1. Poor initial placement
2. Song layout changed (font size, spacing)
3. Note too large

**Solutions**:
- Drag to new position
- Reduce note scale
- Use smaller font size
- Send to back if it's background context

### Colors Look Wrong

**Problem**: Can't read text on note

**Possible Causes**:
1. Wrong color chosen for content
2. Custom color system conflict
3. Display settings affecting contrast

**Solutions**:
- Use preset colors (auto-adjust text color)
- Choose high-contrast color
- Adjust device brightness
- Use different note color

### Lost Notes After Update

**Problem**: Notes disappeared after song edit

**Possible Causes**:
1. Notes are still there but song scrolled
2. Switched to PDF view
3. Song was duplicated, viewing wrong version

**Solutions**:
- Scroll to find notes
- Switch to text view
- Check original song, not duplicate
- Notes are tied to specific song ID

## Advanced Features

### Planned Enhancements

These features are planned for future releases:

**Annotation Library**:
- Save favorite notes as templates
- Reuse across songs
- Categories: dynamics, cues, reminders
- Quick insert from library

**Annotation Sharing**:
- Export annotations separately
- Import from other users
- Team annotation packs
- Genre-specific templates

**Advanced Controls**:
- Opacity adjustment
- Border styles
- Custom colors beyond presets
- Font family selection

**Performance Mode**:
- Hide/show all annotations toggle
- Annotation-free performance view
- Print without annotations option

## FAQ

**Q: How many sticky notes can I add to a song?**
A: No hard limit, but for readability, we recommend staying under 10-15 notes per song.

**Q: Do sticky notes work on PDF songs?**
A: Currently, sticky notes only work on text-mode songs (ChordPro format). PDF annotation support is planned.

**Q: Can I share sticky notes with other musicians?**
A: Not yet. Annotation sharing is planned for a future update.

**Q: Do sticky notes affect song export?**
A: Currently, exports show the song without annotations. Annotation export is planned.

**Q: Can I change the default yellow color?**
A: When creating a note, it starts as yellow, but you can immediately change it in the editor.

**Q: Will sticky notes survive song edits?**
A: Yes, notes maintain their position via percentage-based coordinates, even if song content changes.

**Q: Can I use sticky notes for drawings?**
A: Not yet. Drawing annotations (freehand with Apple Pencil) are planned for a future update.

**Q: Do sticky notes work with autoscroll?**
A: Yes, notes remain visible and scroll with the content. You can interact with them when autoscroll is paused.

**Q: Can I bulk delete all annotations?**
A: Not currently. You must delete notes individually via context menu or editor.

**Q: Do annotations sync across devices?**
A: If using iCloud sync for Lyra, annotations sync along with songs.

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Related Guides**: CHORDPRO_FORMAT.md, DISPLAY_CUSTOMIZATION_DOCUMENTATION.md
