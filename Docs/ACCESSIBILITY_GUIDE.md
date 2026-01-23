# Accessibility Guide for Lyra

## Making Music Accessible to All

Lyra is designed to be fully accessible to musicians of all abilities. This guide covers all accessibility features and how to use them.

---

## Quick Start

**Access Accessibility Settings:**
1. Open Settings
2. Tap "Accessibility" in the Performance section
3. Configure features for your needs

**System Settings:**
- VoiceOver: Settings > Accessibility > VoiceOver
- Switch Control: Settings > Accessibility > Switch Control
- Voice Control: Settings > Accessibility > Voice Control

---

## VoiceOver Support

### Custom Rotors

Navigate songs efficiently with custom rotors:

**Section Rotor:**
- Swipe up/down with two fingers on the rotor
- Select "Sections"
- Swipe up/down to jump between verses, choruses, and bridges

**Chord Rotor:**
- Select "Chords" from rotor
- Navigate directly to each chord in the song
- Hear chord descriptions (e.g., "C major chord", "A minor seventh chord")

**How to Use Rotors:**
1. Enable VoiceOver in iOS Settings
2. Open a song in Lyra
3. Rotate two fingers on screen to select rotor
4. Choose "Sections" or "Chords"
5. Swipe up/down with one finger to navigate

### Chord Descriptions

Chords are spoken in musical terms:
- "C" → "C major chord"
- "Am" → "A minor chord"
- "G7" → "G major seventh chord"
- "Dsus4" → "D suspended fourth chord"

### Smart Element Grouping

Related elements are grouped together:
- Section headers group with their lyrics
- Chords group with their lyrics
- Metadata groups into a single card

**Enable/Disable:**
Settings > Accessibility > VoiceOver > Smart Element Grouping

### Announcements

Automatic announcements for:
- Section changes during autoscroll
- Song navigation (next/previous)
- Transposition changes
- Metronome status
- External display status

---

## Switch Control

### Scanning Modes

**Point Scanning:**
- Blue highlight scans across screen
- Tap switch to select location
- Configurable scan speed (0.5s - 3.0s)

**Item Scanning:**
- Highlight moves between UI elements
- Faster for familiar interfaces
- Adjustable speed

**Auto-Scanning:**
- Automatically moves to next item
- No need to manually advance
- Can be disabled for manual control

### Configuring Switches

**In Lyra:**
1. Settings > Accessibility > Switch Control
2. Adjust Point Scanning Speed
3. Adjust Item Scanning Speed
4. Toggle Auto-Scanning
5. Choose Scanning Highlight Color

**In iOS Settings:**
1. Settings > Accessibility > Switch Control
2. Tap "Switches"
3. Add your physical switch
4. Assign actions (Select Item, Move to Next Item)

### Optimized for Scanning

- Large tap targets (60px minimum)
- Clear visual highlights
- Logical scanning order
- Grouped related controls

---

## Voice Commands

### Siri Shortcuts

**Song Navigation:**
- "Hey Siri, play song" → Start autoscroll
- "Hey Siri, pause song" → Pause autoscroll
- "Hey Siri, next song" → Skip to next in set
- "Hey Siri, previous song" → Go to previous

**Transposition:**
- "Hey Siri, transpose up" → Transpose up one semitone
- "Hey Siri, transpose down" → Transpose down one semitone
- "Hey Siri, reset transposition" → Return to original key

**Metronome:**
- "Hey Siri, start metronome" → Begin click track
- "Hey Siri, stop metronome" → Stop click track
- "Hey Siri, set tempo to 120" → Change metronome BPM

**Display:**
- "Hey Siri, show chords" → Switch to text view
- "Hey Siri, blank display" → Blank external display

### Voice Control

**Basic Commands:**
- "Show numbers" → Display item numbers
- "Tap [number]" → Select numbered item
- "Scroll down/up" → Scroll page
- "Go back" → Navigate back
- "Go home" → Return to main screen

**Editing:**
- "Tap [field name]" → Focus on text field
- "Delete that" → Clear text
- "Select all" → Select all text

**Navigation:**
- "Show grid" → Display tap grid for precise control
- "Tap [coordinates]" → Tap specific location

---

## Braille Display Support

### Supported Displays

Lyra works with iOS-compatible Braille displays:
- Refreshable Braille displays via Bluetooth
- Displays with input keys for navigation
- Standard Braille output for text

### What's Shown

**Song Information:**
- Song title and artist
- Current section name
- Lyrics line-by-line
- Chord symbols (converted to Braille-friendly format)

**Chord Representation:**
- C → C
- C# → C♯
- Db → D♭
- Am → Am
- G7 → G7

### Navigation with Braille

**Braille Input Keys:**
- Space + Dot 4 → Next line
- Space + Dot 1 → Previous line
- Space + Dot 5 → Next section
- Space + Dot 2 → Previous section

### Setup

1. Pair Braille display via Bluetooth
2. iOS Settings > Accessibility > VoiceOver > Braille
3. Select your display
4. Open Lyra - text will appear automatically

---

## Visual Accessibility

### High Contrast Modes

**Standard High Contrast:**
- 1.5x contrast ratio
- Darker backgrounds, brighter text
- Increased color separation

**Ultra High Contrast:**
- 2.0x contrast ratio
- Maximum color differences
- Black/white with high-saturation accents
- Best for severe low vision

**Custom Color Schemes:**
- **High Contrast Dark:** White on black (21:1 ratio)
- **High Contrast Light:** Black on white (21:1 ratio)
- **Yellow on Black:** Traditional terminal style (19.5:1)
- **Green on Black:** Easy on eyes for long sessions (15:1)

### Bold Text Support

- Automatically increases font weight
- Slightly larger text size
- Better readability
- Works with Dynamic Type

### Reduce Transparency

- Removes frosted glass effects
- Solid backgrounds throughout
- Better for cognitive processing
- Improved performance

### Differentiate Without Color

- Adds shapes and patterns to color-coded items
- Icons in addition to colors
- Text labels for all states
- Never relies solely on color

### Invert Colors Support

- Smart invert mode compatible
- Images and media not inverted
- UI properly adapts
- Maintains usability in inverted mode

---

## Motion & Animations

### Reduce Motion

**System Setting (Recommended):**
- Settings > Accessibility > Reduce Motion
- Instantly disables all animations
- Static transitions only

**Custom Animation Speed:**
- 0% → Instant (like Reduce Motion)
- 25% → Very fast transitions
- 50% → Fast transitions
- 75% → Slower, gentler transitions
- 100% → Normal speed (default)

**What's Affected:**
- Page transitions
- Scrolling animations
- Button effects
- Alert presentations
- Menu expansions

---

## Cognitive Accessibility

### Simplified Mode

**What It Does:**
- Removes complex UI elements
- Larger, clearer buttons
- One primary action per screen
- Reduced information density
- Clearer visual hierarchy

**Ideal For:**
- Cognitive disabilities
- Learning disabilities
- Dementia/Alzheimer's patients
- Users who get overwhelmed easily
- First-time users

**How to Enable:**
Settings > Accessibility > Cognitive Accessibility > Simplified Mode

### Large Buttons Mode

- 60px minimum tap targets (vs 44px standard)
- Extra spacing between buttons
- Larger text labels
- Touch-friendly design

**Recommended For:**
- Motor impairments
- Tremor conditions
- Switch Control users
- Touch accuracy challenges

### Clear, Consistent UI

- Predictable navigation
- Consistent button placement
- Clear labeling
- No hidden gestures required
- Always visible controls

---

## Hearing Accessibility

### Visual Indicators

All audio feedback has visual alternatives:
- Metronome: Visual flash + haptic
- Alerts: Banner + haptic
- Notifications: Badge + visual alert

### Mono Audio Support

- Automatically detected
- Audio panned to center
- Equal sound in both ears
- No spatial audio requirements

### Captions

- Action descriptions
- Status updates
- Error messages
- All spoken content has text equivalent

---

## Haptic Feedback

### Strength Levels

**Off:**
- No haptic feedback
- Battery saving mode
- Silent operation

**Light:**
- Subtle taps
- Minimal vibration
- Gentle confirmations

**Medium (Default):**
- Standard iOS haptics
- Clear feedback
- Balanced intensity

**Strong:**
- Heavy vibrations
- Maximum tactile response
- Best for users with reduced sensation

### When Haptics Occur

- Button taps (confirmation)
- Section navigation (subtle tap)
- Errors (warning pattern)
- Success (success pattern)
- Long press (medium impact)

---

## Font Size Control

### System Dynamic Type

Lyra fully supports Dynamic Type:
1. iOS Settings > Accessibility > Display & Text Size
2. Drag "Larger Text" slider
3. Lyra automatically scales all text

**Supports all sizes:**
- XS through XXXL
- Accessibility sizes 1-5
- Custom sizes per-user

### Custom Font Multiplier

**Additional scaling in Lyra:**
- 0.8x → Compact mode
- 1.0x → Standard (default)
- 1.5x → Large
- 2.0x → Extra large

**Combined with Dynamic Type:**
- System XL + Lyra 1.5x = 2.25x total
- Maximum readability
- Maintains layout integrity

---

## Keyboard Navigation

### Full Keyboard Support

Navigate Lyra entirely with keyboard:
- Tab → Next element
- Shift+Tab → Previous element
- Space/Enter → Activate
- Arrows → Scroll/navigate lists
- Cmd+[Key] → Keyboard shortcuts

### External Keyboard Shortcuts

**Song View:**
- Cmd+E → Edit song
- Cmd+T → Transpose
- Cmd+G → Capo
- Cmd+P → Play/pause autoscroll
- Space → Toggle autoscroll
- Cmd+M → Toggle metronome

**Navigation:**
- Cmd+1 → Library
- Cmd+2 → Books
- Cmd+3 → Sets
- Cmd+, → Settings

### Focus Indicators

- Clear blue outline
- High contrast
- Follows keyboard navigation
- Never hidden

---

## Quick Tips

### For VoiceOver Users

1. **Learn the rotors:** Most efficient way to navigate songs
2. **Use section rotor:** Jump to specific verses/choruses quickly
3. **Enable announcements:** Get updates without interrupting flow
4. **Group elements:** Makes metadata easier to navigate

### For Switch Control Users

1. **Slow down scanning:** Start at 2s, adjust as comfortable
2. **Use item scanning:** Faster once you learn the interface
3. **Create custom groups:** Group frequently-used controls
4. **Enable auto-scanning:** Reduces switch presses needed

### For Low Vision Users

1. **Try ultra high contrast:** Maximum visibility
2. **Increase font size:** Use both system + Lyra multipliers
3. **Enable bold text:** Sharper, easier to read
4. **Use custom color schemes:** Find what works for your eyes

### For Cognitive Accessibility

1. **Enable simplified mode:** Reduces overwhelm
2. **Use large buttons:** Easier targeting
3. **Slow animations:** Gentler transitions
4. **One thing at a time:** Focus on current task

---

## Reporting Accessibility Issues

We're committed to making Lyra accessible to everyone.

**Found an accessibility problem?**
1. Open Settings > Help
2. Tap "Report Issue"
3. Select "Accessibility" category
4. Describe the issue
5. Include your assistive technology setup

**Priority Issues:**
- VoiceOver broken or unclear
- Keyboard navigation blocked
- Switch Control unreachable elements
- Contrast too low to read
- Essential features inaccessible

**We aim to fix accessibility issues within 48 hours.**

---

## Resources

### Apple Accessibility

- [Apple Accessibility Guide](https://www.apple.com/accessibility/)
- [VoiceOver User Guide](https://support.apple.com/guide/iphone/voiceover)
- [Switch Control Guide](https://support.apple.com/guide/iphone/switch-control)

### Learning VoiceOver

- Practice in Settings app first
- Use VoiceOver Practice mode
- Join VoiceOver user communities
- Watch Apple's tutorial videos

### Music Accessibility

- [Music and Braille](https://www.afb.org/blindness-and-low-vision/using-technology/assistive-technology-products/braille-music)
- [Accessible Music Technology](https://www.rnib.org.uk/music)

---

## Accessibility Statement

Lyra strives to meet WCAG 2.1 Level AAA standards where applicable to native iOS apps.

**We support:**
- ✓ VoiceOver screen reader
- ✓ Switch Control
- ✓ Voice Control
- ✓ Dynamic Type (all sizes)
- ✓ Braille displays
- ✓ Keyboard navigation
- ✓ Reduce Motion
- ✓ Increase Contrast
- ✓ Differentiate Without Color
- ✓ Haptic feedback (customizable)
- ✓ Guided Access
- ✓ AssistiveTouch

**Compliance:**
- WCAG 2.1 Level AA: ✓ Compliant
- Section 508: ✓ Compliant
- EN 301 549: ✓ Compliant

**Last Updated:** January 2026

---

## Thank You

Thank you for helping us make Lyra accessible to all musicians. Every musician deserves the joy of making music, regardless of ability.

**Questions?** accessibility@lyraapp.com
