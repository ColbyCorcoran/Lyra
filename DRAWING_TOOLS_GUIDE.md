# Drawing Tools Guide

## Overview

Lyra's drawing tools bring the power of PencilKit to your chord charts. Mark up songs with freehand drawings, underlines, circles, arrows, and highlights using Apple Pencil or your finger. Perfect for practice sessions, rehearsal notes, and visual cues that enhance your performance.

## What are Drawing Tools?

Drawing tools let you create freehand annotations directly on your chord charts:
- **Pen**: Solid lines for circling chords, drawing arrows, underlining lyrics
- **Highlighter**: Semi-transparent marker for emphasizing sections
- **Eraser**: Remove individual strokes precisely

**Key Benefits**:
- Natural, freehand drawing experience
- Apple Pencil support with pressure and tilt sensitivity
- Finger drawing for quick annotations
- Undo/redo with 100 levels
- Auto-save on every stroke
- Non-destructive: drawings overlay the song without changing it

**Example Use Cases**:
- Circle chord changes that are tricky
- Underline important lyrics
- Highlight entire sections (chorus, bridge)
- Draw arrows for navigation cues
- Add dynamic markings (crescendo lines)
- Mark timing with visual beats

## Entering Drawing Mode

### Starting Drawing

1. Open any song in text mode
2. Tap the drawing icon (✏️) in the toolbar
3. Drawing mode activates:
   - Scrolling is disabled
   - Drawing toolbar appears at bottom
   - Green indicator on toolbar icon
4. Start drawing immediately with default pen tool

### Exiting Drawing

**Method 1**: Tap "Done" button in drawing toolbar
**Method 2**: Tap drawing icon (✏️) in main toolbar again

Your drawings are automatically saved - no manual save needed.

## Drawing Tools

### Pen Tool

**Purpose**: Solid lines for precise annotations

**Best For**:
- Circling specific chords
- Underlining important words
- Drawing arrows between sections
- Adding written notes or symbols
- Connecting related elements

**Colors Available**:
- Black: General annotations
- Red: Important/urgent markings
- Blue: Informational notes
- Green: Positive indicators
- Yellow: Caution/attention (less visible on white)
- Orange: Emphasis

**Line Thickness**:
- Thin (2pt): Fine details, small annotations
- Medium (5pt): Standard readable lines
- Thick (10pt): Bold emphasis, large circles

**Pro Tips**:
- Use thin pen for precise chord circles
- Use thick pen for section boundaries
- Match color to purpose (red=urgent, blue=info)

### Highlighter Tool

**Purpose**: Semi-transparent marking for emphasis without obscuring content

**Best For**:
- Highlighting entire lines or sections
- Color-coding song structure
- Marking repetitions
- Emphasizing chord progressions
- Quick visual scanning during performance

**Colors Available**: Same as pen, but rendered semi-transparent
- Yellow: Classic highlight color
- Orange: Warm emphasis
- Green: Positive/go sections
- Blue: Cool/calm sections
- Pink (via Red): Important sections

**Line Thickness**:
- Thin: Narrow highlights for single words
- Medium: Standard line highlighting
- Thick: Wide swaths covering multiple lines

**Pro Tips**:
- Highlighter doesn't obscure text underneath
- Use different colors for verse/chorus/bridge
- Layer highlighters for color mixing
- Thick highlighter great for entire section backgrounds

### Eraser Tool

**Purpose**: Remove individual drawing strokes

**How It Works**:
- Vector eraser: Removes entire strokes
- Touch any part of a stroke to delete it
- Doesn't erase text - only your drawings
- Precise control over what gets removed

**Usage**:
1. Select eraser from toolbar
2. Touch or drag across strokes to remove
3. Each stroke is removed entirely
4. Switch back to pen/highlighter to continue drawing

**Pro Tips**:
- Eraser removes whole strokes, not partial
- If you want to modify a stroke, erase and redraw
- Use undo instead of eraser for recent mistakes
- Eraser is selection-based, not brush-based

## Drawing Toolbar

When in drawing mode, the toolbar at the bottom provides all controls:

### Tool Selection (Left Section)

**Pen** | **Highlighter** | **Eraser**
- Current tool highlighted in blue
- Tap to switch tools
- Tool persists between drawing sessions

### Color Palette (Center-Left)

Six color circles:
- Black ● Red ● Blue ● Green ● Yellow ● Orange
- Current color has blue ring
- Only visible for pen and highlighter (not eraser)
- Tap to change color
- Color persists when switching between pen and highlighter

### Line Thickness (Center-Right)

Three thickness options with visual previews:
- **Thin**: Small circle preview
- **Medium**: Medium circle preview
- **Thick**: Large circle preview

Current thickness highlighted in blue background
Only visible for pen and highlighter (not eraser)

### Actions (Right Section)

**Undo** (←):
- Removes last stroke
- Grayed out when nothing to undo
- 100 levels of undo available

**Redo** (→):
- Restores last undone stroke
- Grayed out when nothing to redo
- Works after undo operations

**Clear** (🗑):
- Red trash icon
- Tap to clear all drawings
- Shows confirmation dialog
- "Clear All" or "Cancel"
- Permanent deletion (cannot undo after confirmation)

**Done**:
- Blue pill-shaped button
- Exits drawing mode
- Saves all drawings automatically
- Returns to normal song view

## Drawing Techniques

### Apple Pencil

**Advantages**:
- Pressure sensitivity: Press harder for thicker lines (if using variable thickness)
- Tilt sensitivity: Angle changes stroke appearance
- Palm rejection: Rest your hand naturally on screen
- Precision: Pixel-perfect control
- Double-tap: Switch between tools (if configured)

**Best Practices**:
- Hold Pencil naturally at comfortable angle
- Use light touch for thin lines
- Press firmly for emphasis
- Rest palm freely - no accidental touches
- Quick strokes for straight lines
- Slow strokes for curved shapes

### Finger Drawing

**Advantages**:
- Always available (no accessory needed)
- Quick annotations on the go
- Natural for broad strokes
- Good for highlighting large areas

**Best Practices**:
- Use fingertip for precision
- Broad strokes with side of finger for highlighting
- Zoom in for detailed work
- Keep finger movements smooth and controlled
- Use eraser liberally - easy to redraw

### Common Techniques

**Circling Chords**:
1. Select thin pen, black color
2. Draw circle around chord name
3. Keep motion smooth and continuous
4. If imperfect, undo and retry

**Underlining Lyrics**:
1. Select thin or medium pen
2. Draw straight line beneath text
3. Use quick, confident stroke
4. Multiple lines for emphasis

**Highlighting Sections**:
1. Select highlighter, choose color
2. Use thick thickness
3. Drag broadly across section
4. Overlap strokes for solid coverage

**Drawing Arrows**:
1. Select thin pen
2. Draw arrow shaft (line)
3. Add arrowhead (V shape)
4. Use for "repeat here", "jump to", etc.

**Section Brackets**:
1. Select medium pen
2. Draw [ shape on left side
3. Draw ] shape on right side
4. Label sections visually

## Persistence & Storage

### How Drawings Are Saved

- **Database**: SwiftData Annotation model
- **Type**: AnnotationType.drawing
- **Format**: PKDrawing data representation
- **Timing**: Auto-save after each stroke
- **Storage**: One drawing layer per song
- **Relationship**: Linked to specific Song

### Drawing Data

Each song has one drawing annotation that stores:
- All drawing strokes as PKDrawing data
- Creation timestamp
- Modification timestamp
- Relationship to parent Song

**Benefits**:
- Survives app restarts
- Persists across device sync (if iCloud enabled)
- Non-destructive to song content
- Loads instantly with song

### Performance

Optimized for complex drawings:
- Smooth rendering of hundreds of strokes
- Minimal memory footprint
- Fast load times
- Responsive during drawing
- No lag even with detailed annotations

## Use Cases

### Practice Sessions

**Scenario**: Learning a new song, need to mark trouble spots

**Solution**:
1. Enter drawing mode
2. Circle difficult chord changes in red
3. Underline lyrics you forget in blue
4. Highlight sections to repeat in yellow
5. Practice with visual reminders

### Rehearsal Markup

**Scenario**: Band rehearsal, need to track changes

**Solution**:
1. Draw arrows to indicate new arrangement flow
2. Cross out sections to skip
3. Write "2x" near repeats
4. Circle new chords added by band
5. Add visual cues for entrances

### Live Performance Preparation

**Scenario**: Preparing chart for live show

**Solution**:
1. Highlight each section in different color (verse=yellow, chorus=green)
2. Draw bracket around intro
3. Underline key change section
4. Circle capo reminder
5. Add dynamic markings with pen

### Teaching & Learning

**Scenario**: Teaching song to student

**Solution**:
1. Highlight chord progression pattern
2. Draw arrows showing harmonic movement
3. Circle chords to emphasize
4. Underline important lyrics
5. Add visual mnemonics

### Chord Chart Analysis

**Scenario**: Analyzing song structure

**Solution**:
1. Use different colors for each section type
2. Draw brackets grouping phrases
3. Circle chord families (I, IV, V)
4. Underline repeated patterns
5. Add Roman numeral analysis with pen

## Best Practices

### During Drawing

✅ **DO**:
- Use thin pen for precision work
- Use highlighter for large areas
- Choose colors with purpose
- Undo liberally - it's fast
- Save complex drawings incrementally
- Test visibility at performance distance

❌ **DON'T**:
- Over-annotate and clutter chart
- Use yellow pen on white (poor visibility)
- Draw over critical text completely
- Rush - take time for clean strokes
- Forget to exit drawing mode when done

### Color Strategy

✅ **DO**:
- Establish color meaning (red=important, blue=info)
- Use 2-3 colors maximum per song
- Choose high-contrast colors
- Consider performance lighting
- Match colors to urgency

❌ **DON'T**:
- Use all six colors randomly
- Mix too many colors in one area
- Rely solely on color (add shapes/arrows too)
- Use similar colors for different purposes

### Organization

✅ **DO**:
- Plan annotations before drawing
- Group related markings
- Use consistent stroke thickness
- Keep drawings purposeful
- Review and clean up periodically

❌ **DON'T**:
- Draw randomly without plan
- Mix annotation styles
- Change thickness frequently
- Keep obsolete markings
- Clutter with overlapping strokes

## Troubleshooting

### Drawing Not Appearing

**Problem**: Made strokes but nothing visible

**Possible Causes**:
1. Wrong tool selected (eraser active)
2. Color matches background
3. Thickness too thin to see
4. Drawing mode not active

**Solutions**:
- Verify pen/highlighter selected (not eraser)
- Change color to black or red
- Increase thickness to medium or thick
- Ensure drawing mode toolbar is visible

### Can't Scroll Song

**Problem**: Unable to scroll to see more content

**Cause**: Scrolling is disabled in drawing mode

**Solution**:
- Tap "Done" to exit drawing mode
- Scroll to desired location
- Re-enter drawing mode to continue
- Or: Draw in sections, exit, scroll, re-enter

### Apple Pencil Not Working

**Problem**: Apple Pencil doesn't draw

**Possible Causes**:
1. Pencil not paired with iPad
2. Pencil battery dead
3. Drawing mode not active
4. Different app active

**Solutions**:
- Check Pencil pairing in Settings
- Charge Apple Pencil
- Tap drawing icon to activate mode
- Ensure Lyra is foreground app

### Strokes Too Thick/Thin

**Problem**: Lines not the desired thickness

**Cause**: Wrong thickness setting

**Solution**:
- Check current thickness in toolbar
- Tap thin/medium/thick to adjust
- Thickness affects both pen and highlighter
- Test on margin before annotating

### Accidental Deletions

**Problem**: Erased drawings unintentionally

**Possible Causes**:
1. Eraser tool active
2. Cleared all drawings by accident
3. Undo pressed multiple times

**Solutions**:
- If recent: Use redo button
- If cleared all: Cannot recover (confirmation dialog prevents accidents)
- Switch away from eraser when not erasing
- Double-check before confirming "Clear All"

### Performance Issues

**Problem**: Drawing feels laggy or slow

**Possible Causes**:
1. Extremely complex drawing (1000+ strokes)
2. Device resource constraints
3. Large song with many elements

**Solutions**:
- Simplify drawings (fewer strokes)
- Clear unnecessary markings
- Restart app if persistent
- Consider using sticky notes for text annotations instead

## Tips & Tricks

### Quick Annotations

**Fast Circling**:
1. Select thin pen, black
2. Quick circular motion around target
3. Don't overthink perfection
4. Undo if needed, redraw

**Rapid Highlighting**:
1. Highlighter + thick thickness
2. One broad stroke across section
3. Overlap slightly for coverage
4. Multiple colors for sections

**Arrow Shortcuts**:
- Draw line first
- Add V at end for arrowhead
- Or: Draw > shape for simple arrow
- Label with pen if needed

### Combining Tools

**Highlight + Circle**:
1. Highlighter for background
2. Pen to circle specific elements
3. Creates layered annotation
4. Excellent for emphasis

**Color Coding**:
- Yellow highlight: Verse
- Green highlight: Chorus
- Blue highlight: Bridge
- Red pen: Critical changes

**Text + Drawing**:
- Use sticky notes for text
- Use drawing for visual marks
- Combine for comprehensive annotations

### Workflow Optimization

**Practice Workflow**:
1. First pass: Highlight structure
2. Second pass: Circle trouble spots
3. Third pass: Add navigation arrows
4. Review: Clean up unnecessary marks

**Performance Prep**:
1. Minimal markings only
2. High-contrast colors (black, red)
3. Large, visible strokes
4. Test visibility from music stand distance

### Advanced Techniques

**Crescendo/Decrescendo**:
- Draw < or > shapes
- Extend across measure or section
- Use thin or medium pen

**Beat Markers**:
- Small vertical ticks above lyrics
- Thin pen, evenly spaced
- Helps with timing

**Chord Diagrams**:
- Draw fretboard grid
- Mark finger positions
- Label fret numbers

## Limitations & Future Features

### Current Limitations

- **One Drawing Layer**: Each song has one drawing layer (all strokes stored together)
- **No Layers**: Cannot separate drawing types into layers
- **No Selection**: Cannot select and move/copy strokes
- **No PDF Drawing**: Currently text mode only (PDF drawing planned)
- **No Text Tool**: Cannot add typed text via drawing (use sticky notes instead)

### Planned Enhancements

**Multiple Drawing Layers**:
- Separate practice vs. performance layers
- Toggle layers on/off
- Color code by layer purpose

**Selection Tool**:
- Lasso to select strokes
- Move selections
- Copy/paste drawings

**PDF Integration**:
- Draw directly on PDF attachments
- Annotate PDF chord charts
- Export PDF with drawings

**Shape Tools**:
- Perfect circles, rectangles
- Straight line tool
- Arrow tool with options

**Advanced Eraser**:
- Partial stroke erasing
- Brush-style eraser
- Erase by color/thickness

## FAQ

**Q: Can I use both sticky notes and drawings on the same song?**
A: Yes! They work great together. Use sticky notes for text annotations and drawings for visual marks.

**Q: Do drawings work with Apple Pencil on all iPads?**
A: Yes, any iPad that supports Apple Pencil works with Lyra's drawing tools.

**Q: Can I draw without Apple Pencil?**
A: Absolutely! Finger drawing works perfectly. Apple Pencil just adds pressure/tilt sensitivity.

**Q: How many strokes can I add before performance degrades?**
A: The system handles hundreds of strokes easily. If you exceed ~1000 strokes, consider simplifying.

**Q: Are drawings visible during autoscroll?**
A: Yes, drawings scroll with the content and remain visible.

**Q: Can I export songs with drawings included?**
A: Not yet. PDF export with drawings is planned for a future update.

**Q: Do drawings sync across devices?**
A: If using iCloud sync, drawings sync along with songs automatically.

**Q: Can I adjust opacity of highlighter?**
A: No, highlighter uses PencilKit's standard semi-transparent opacity. This cannot be customized currently.

**Q: What happens to drawings if I edit the song content?**
A: Drawings overlay the content, so they remain but may not align perfectly after major content changes. You may need to adjust them.

**Q: Can I lock drawings to prevent accidental changes?**
A: Not yet. Drawing lock is a planned feature. For now, simply exit drawing mode when not annotating.

**Q: Does the eraser erase sticky notes too?**
A: No, the eraser only removes drawing strokes. Sticky notes are managed separately.

## Keyboard Shortcuts

*Note: Keyboard shortcuts for drawing tools are not currently implemented but are planned for future release.*

**Planned**:
- P: Pen tool
- H: Highlighter tool
- E: Eraser tool
- Cmd+Z: Undo
- Cmd+Shift+Z: Redo
- Cmd+D: Toggle drawing mode

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Related Guides**: STICKY_NOTES_GUIDE.md, CHORDPRO_FORMAT.md
