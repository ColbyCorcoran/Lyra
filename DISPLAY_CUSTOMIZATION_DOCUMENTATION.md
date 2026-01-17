# Display Customization Feature Documentation

## Overview

Lyra's display customization feature provides comprehensive control over song display appearance for optimal readability during live performance. Users can customize font size, chord colors, lyrics colors, and spacing both globally (for all songs) and per-song (for individual songs).

## Key Features

- **Per-Song Customization**: Each song can have its own display settings
- **Global Defaults**: Set default display preferences for all new songs
- **Real-Time Preview**: See changes immediately as you adjust settings
- **Color Presets**: Choose from 8 chord colors and 4 lyrics colors
- **Range Controls**: Font size (12-28pt), Spacing (4-16pt)
- **Reset Options**: Quickly revert to defaults or remove custom settings
- **Set as Default**: Save current song settings as global defaults

## User Interface

### Song Display Settings Sheet

**Access:** Tap the "AA" (textformat.size) button in SongDisplayView toolbar

```
┌────────────────────────────────────┐
│ ✎  Song Title         AA  ↕  ⋯    │
│                       ^^             │
│                 (Display Settings)   │
└────────────────────────────────────┘
```

**Sheet Contents:**

1. **Text Size Section**
   - Slider: 12-28 points
   - Live preview of sample chord and lyrics
   - Current value displayed

2. **Chord Color Section**
   - 8 color presets in 4x2 grid
   - Visual swatches with names
   - Selected color highlighted
   - Colors: Blue, Red, Green, Orange, Purple, Pink, Teal, Indigo

3. **Lyrics Color Section**
   - 4 color presets in grid
   - Visual swatches with names
   - Selected color highlighted
   - Colors: Black, Dark Gray, Gray, Brown

4. **Spacing Section**
   - Slider: 4-16 points
   - Live preview showing chord/lyrics spacing
   - Current value displayed

5. **Actions Section**
   - **Reset to Defaults**: Revert to global defaults
   - **Set as Default for All Songs**: Save current settings globally
   - **Remove Custom Settings**: (Only if song has custom settings) Clear per-song settings

### Global Settings (Settings Tab)

**Access:** Settings tab in main navigation

**Contents:**

1. **Display Defaults Section**
   - Same controls as per-song sheet
   - Sets defaults for all new songs
   - Footer: "These settings apply to all new songs..."

2. **About Section**
   - Version number
   - Build number

3. **Support Section**
   - GitHub Repository link
   - Report an Issue link

## Implementation Details

### DisplaySettings Model

```swift
struct DisplaySettings: Codable, Equatable {
    var fontSize: Double        // 12-28
    var chordColor: String      // Hex color
    var lyricsColor: String     // Hex color
    var spacing: Double         // 4-16

    static let `default` = DisplaySettings(
        fontSize: 16,
        chordColor: "#007AFF",  // iOS blue
        lyricsColor: "#000000",  // Black
        spacing: 8
    )
}
```

**Color Presets:**

Chord Colors:
- Blue: #007AFF (iOS default)
- Red: #FF3B30
- Green: #34C759
- Orange: #FF9500
- Purple: #AF52DE
- Pink: #FF2D55
- Teal: #5AC8FA
- Indigo: #5856D6

Lyrics Colors:
- Black: #000000 (adapts to dark mode)
- Dark Gray: #3A3A3C
- Gray: #8E8E93
- Brown: #A2845E

### Song Model Integration

```swift
@Model
final class Song {
    // ...
    var displaySettingsData: Data?  // Encoded DisplaySettings

    // Computed property
    var displaySettings: DisplaySettings {
        get {
            if let data = displaySettingsData,
               let settings = try? JSONDecoder().decode(DisplaySettings.self, from: data) {
                return settings
            }
            // Fall back to global defaults
            return UserDefaults.standard.globalDisplaySettings
        }
        set {
            displaySettingsData = try? JSONEncoder().encode(newValue)
        }
    }

    var hasCustomDisplaySettings: Bool {
        return displaySettingsData != nil
    }

    func clearCustomDisplaySettings() {
        displaySettingsData = nil
    }
}
```

### UserDefaults Extension

```swift
extension UserDefaults {
    var globalDisplaySettings: DisplaySettings {
        get {
            if let data = data(forKey: "globalDisplaySettings"),
               let settings = try? JSONDecoder().decode(DisplaySettings.self, from: data) {
                return settings
            }
            return .default
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: "globalDisplaySettings")
            }
        }
    }
}
```

### SongDisplayView Integration

**State Management:**

```swift
@State private var displaySettings: DisplaySettings
@State private var showDisplaySettings: Bool = false

init(song: Song) {
    self.song = song
    _displaySettings = State(initialValue: song.displaySettings)
}
```

**Toolbar Button:**

```swift
ToolbarItem(placement: .topBarTrailing) {
    Button {
        showDisplaySettings = true
    } label: {
        Image(systemName: "textformat.size")
    }
}
```

**Settings Sheet:**

```swift
.sheet(isPresented: $showDisplaySettings) {
    DisplaySettingsSheet(song: song)
        .onDisappear {
            displaySettings = song.displaySettings
        }
}
```

**Change Handling:**

```swift
.onChange(of: displaySettings) { _, _ in
    fontSize = displaySettings.fontSize
}
```

### ChordLineView Customization

```swift
struct ChordLineView: View {
    let line: SongLine
    let settings: DisplaySettings

    private var fontSize: CGFloat { settings.fontSize }
    private var chordColor: Color { settings.chordColorValue() }
    private var lyricsColor: Color { settings.lyricsColorValue() }
    private var chordToLyricSpacing: CGFloat { settings.spacing }

    // ... rendering code uses these values
}
```

## User Workflows

### Workflow 1: Customize Individual Song

**Scenario:** User wants larger text for "Amazing Grace"

1. Open "Amazing Grace" in SongDisplayView
2. Tap "AA" button in toolbar
3. Slide font size to 24
4. Tap "Done"
5. Song now displays with 24pt font
6. Other songs unaffected

**Result:**
- Song has custom displaySettingsData
- Falls back to global defaults removed
- Settings persist across app restarts

### Workflow 2: Set Global Defaults

**Scenario:** User prefers green chords, 18pt font

1. Go to Settings tab
2. Scroll to "Display Defaults"
3. Slide font size to 18
4. Tap green color swatch
5. Changes save automatically

**Result:**
- All new songs use 18pt font, green chords
- Existing songs with custom settings unaffected
- Existing songs without custom settings use new defaults

### Workflow 3: Apply Song Settings Globally

**Scenario:** User likes current song's appearance

1. Customize song display (e.g., red chords, 20pt)
2. Tap "AA" button
3. Tap "Set as Default for All Songs"
4. Tap "Done"

**Result:**
- Global defaults updated to match current song
- Future songs use these settings
- Current song keeps its settings

### Workflow 4: Remove Custom Settings

**Scenario:** User wants song to use global defaults

1. Open song with custom settings
2. Tap "AA" button
3. Scroll to bottom
4. Tap "Remove Custom Settings"
5. Tap "Done"

**Result:**
- Song's displaySettingsData cleared
- Song now uses global defaults
- Settings change immediately

### Workflow 5: Reset to Defaults

**Scenario:** User experimented and wants to start over

**In Song Sheet:**
1. Tap "AA" button
2. Tap "Reset to Defaults"
3. Settings revert to DisplaySettings.default
4. Tap "Done" to save or "Cancel" to discard

**In Settings:**
1. Go to Settings tab
2. Scroll to Display Defaults
3. Tap "Reset to Defaults"
4. All global defaults reset to factory

## Settings Persistence

### Global Settings

**Storage:** UserDefaults
**Key:** "globalDisplaySettings"
**Format:** JSON-encoded DisplaySettings
**Fallback:** DisplaySettings.default

**Properties (AppStorage):**
- globalFontSize: 16
- globalChordColor: "#007AFF"
- globalLyricsColor: "#000000"
- globalSpacing: 8

**Sync:**
Changes in SettingsView immediately save to UserDefaults

### Per-Song Settings

**Storage:** SwiftData (Song.displaySettingsData)
**Format:** JSON-encoded DisplaySettings
**Fallback:** UserDefaults.globalDisplaySettings

**Lifecycle:**
1. Created: When user changes settings in DisplaySettingsSheet
2. Updated: When user modifies settings
3. Cleared: When user taps "Remove Custom Settings"
4. Read: Every time song opens

## Color System

### Hex Color Conversion

```swift
extension Color {
    init?(hex: String) {
        // Parse #RRGGBB to Color
        var hexSanitized = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

### Dark Mode Handling

**Chord Colors:**
- All colors are explicitly defined hex values
- No automatic dark mode adaptation
- User chooses appropriate colors for their environment

**Lyrics Colors:**
- Black (#000000) inverts to white in dark mode (iOS system behavior)
- Dark Gray, Gray provide alternatives
- Brown maintains consistency

## Performance

### Rendering

**Font Size Changes:**
- Instant re-render via SwiftUI state
- No layout calculation needed
- Smooth slider animation

**Color Changes:**
- Direct Color value update
- No parsing delay (pre-parsed hex values)
- Immediate visual feedback

**Spacing Changes:**
- VStack spacing parameter updates
- Native SwiftUI layout
- No manual calculations

### Memory

**DisplaySettings Structure:**
- Size: ~40 bytes
- Codable overhead: ~20 bytes
- Total per song: ~60 bytes

**100 Songs with Custom Settings:**
- 100 × 60 bytes = 6 KB
- Negligible memory impact

### Storage

**Per-Song Settings:**
- JSON-encoded: ~80-100 bytes per song
- SwiftData handles efficiently
- Compressed in database

**Global Settings:**
- UserDefaults: ~100 bytes total
- Cached in memory
- Fast access

## Edge Cases

### Case 1: No Global Settings

**Scenario:** First app launch, no settings saved

**Behavior:**
- UserDefaults returns DisplaySettings.default
- Songs use: 16pt font, blue chords, black lyrics, 8pt spacing
- User can customize via Settings tab

### Case 2: Corrupted Settings Data

**Scenario:** displaySettingsData corrupted in database

**Behavior:**
- JSON decode fails
- Falls back to global defaults
- No crash, graceful degradation

### Case 3: Old fontSize Property

**Scenario:** Song has legacy fontSize Int? property

**Behavior:**
- displaySettings computed property checks displaySettingsData first
- If nil, uses global defaults (not old fontSize)
- Legacy properties marked deprecated
- Can be removed in future version

### Case 4: Display Settings Sheet Canceled

**Scenario:** User changes settings then taps "Cancel"

**Behavior:**
- Sheet dismissed without saving
- Song.displaySettings unchanged
- SongDisplayView displaySettings unchanged
- No database write

### Case 5: Multiple Concurrent Edits

**Scenario:** User opens song, changes settings in sheet, another view modifies song

**Behavior:**
- DisplaySettingsSheet has its own State copy
- Only saves on "Done"
- SwiftData handles concurrent writes
- Last write wins (standard behavior)

## Accessibility

### VoiceOver

**Display Settings Button:**
- Label: "Display Settings"
- Hint: "Adjust font size, colors, and spacing"
- Tappable

**Sliders:**
- Value: Current setting (e.g., "16 points")
- Adjustable with swipe up/down
- Announces value changes

**Color Swatches:**
- Label: Color name + "selected/not selected"
- Hint: "Double tap to select"
- Grid navigation supported

### Dynamic Type

**Settings Respected:**
- All text scales with system dynamic type
- Preview text scales appropriately
- Button labels scale
- Color swatch names scale

**Limits:**
- Song display font size independent of system
- User's explicit choice takes precedence
- Allows larger sizes than system (up to 28pt)

## Future Enhancements

### Custom Color Picker

**Current:** 8 preset chord colors, 4 preset lyrics colors

**Future:**
- Full color picker with hex input
- Recent colors history
- Custom color palettes
- Save favorite combinations

### Font Family Selection

**Current:** System font only

**Future:**
- San Francisco (default)
- Georgia (serif)
- Courier (monospace alternative)
- Custom font upload

### Advanced Spacing

**Current:** Global chord/lyrics spacing

**Future:**
- Line spacing
- Section spacing
- Chord offset (horizontal)
- Paragraph margins

### Themes

**Current:** Individual settings per song

**Future:**
- Named themes ("Large Stage", "Acoustic Set", "Worship Night")
- Quick theme switching
- Import/export themes
- Community theme sharing

### Context-Aware Defaults

**Current:** Static global defaults

**Future:**
- Different defaults by time of day (bright colors at night)
- Different defaults by location (large text on stage)
- Different defaults by song type (hymns vs contemporary)
- ML-suggested settings based on usage

### Sync Across Devices

**Current:** Settings per device

**Future:**
- iCloud sync for global defaults
- iCloud sync for per-song settings
- Conflict resolution
- Offline-first design

## Testing

See `DISPLAY_CUSTOMIZATION_TESTING_GUIDE.md` for comprehensive test cases including:
- Font size changes
- Color selection
- Spacing adjustments
- Global/per-song interaction
- Reset functionality
- Dark mode
- Accessibility
- Performance

## Integration Points

### From Song Model

- `song.displaySettings` - Get current settings
- `song.hasCustomDisplaySettings` - Check if customized
- `song.clearCustomDisplaySettings()` - Remove customization

### From SongDisplayView

- Toolbar button opens DisplaySettingsSheet
- Settings applied to ChordLineView rendering
- Real-time updates on change

### From Settings Tab

- Global defaults editing
- Preview of settings
- Reset to factory defaults

### To ChordProParser

- Parser unchanged (no dependency on display settings)
- Display layer only

## Best Practices

### For Users

1. **Start with Global Defaults**
   - Set your preferred defaults in Settings
   - Most songs will look good with these
   - Only customize special cases

2. **Use Per-Song Settings Sparingly**
   - Reserve for songs with unique needs
   - Example: Extra large text for difficult song
   - Avoids management overhead

3. **Test in Performance Environment**
   - Use actual lighting conditions
   - Test distance from device
   - Consider audience sight lines

4. **Color Contrast**
   - Ensure chords visible against background
   - Test in both light and dark mode
   - High contrast for outdoor use

### For Developers

1. **Always Use displaySettings Computed Property**
   - Don't access displaySettingsData directly
   - Handles fallback logic automatically
   - Type-safe

2. **Pass Settings to Views**
   - Don't create DisplaySettings in child views
   - Pass from parent for consistency
   - Reduces lookups

3. **Handle nil Gracefully**
   - displaySettings never nil (returns default)
   - But check hasCustomDisplaySettings if needed
   - Fallback chain ensures robustness

4. **Save After Complete Change**
   - Don't save on every slider movement
   - Save on "Done" button only
   - Reduces database writes

This comprehensive display customization feature provides users with precise control over song appearance while maintaining ease of use and performance!
