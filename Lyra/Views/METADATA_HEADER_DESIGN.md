# Metadata Header Design Documentation

## Overview

The SongHeaderView has been completely redesigned to provide a professional, polished metadata display at the top of each song. The header now stays visible while scrolling (sticky behavior) and uses SF Symbols icons for visual clarity.

## Visual Design

### Layout Structure

```
┌─────────────────────────────────────────┐
│  Song Title (26pt, bold)                │
│  Subtitle (18pt, medium, secondary)     │
│  👤 Artist Name (16pt, medium)          │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ 🎵 Key: G      ⏱️ Tempo: 120 BPM  │ │
│  │ 〰️ Time: 4/4   🎸 Capo: 2        │ │
│  └───────────────────────────────────┘ │
│                                         │
│  © Copyright Info                       │
└─────────────────────────────────────────┘
```

### Color Scheme

- **Title**: Primary text color (adapts to light/dark mode)
- **Subtitle**: Secondary text color
- **Artist**: Secondary text color with person.fill icon
- **Metadata Card Background**: System Gray 6 (light gray)
- **Icons**: Blue accent color
- **Labels**: Secondary text color
- **Values**: Primary text color (bold)
- **Copyright**: Tertiary text color

## Components

### 1. SongHeaderView

Main container for all metadata display.

**Key Features:**
- Title section with optional subtitle
- Artist name with person icon
- Musical metadata card (only shown if metadata exists)
- Copyright notice with copyright icon
- Responsive layout (hides empty fields)

**Spacing:**
- 16pt between sections
- 6pt within title section
- 20pt horizontal padding
- 16pt vertical padding

### 2. MetadataItem

Individual metadata field with icon, label, and value.

**Structure:**
```swift
HStack {
    Image(systemName: icon)      // 16pt, blue, 20pt frame width
    Text(label)                  // 13pt, semibold, secondary
    Text(value)                  // 14pt, bold, primary
}
```

**Examples:**
- 🎵 Key: G
- ⏱️ Tempo: 120 BPM
- 〰️ Time: 4/4
- 🎸 Capo: 2

### 3. Metadata Card

Light gray background container for musical metadata.

**Styling:**
- Background: RoundedRectangle with 12pt corner radius
- Fill: Color(.systemGray6)
- Padding: 16pt all sides

**Layout:**
Two rows:
1. Key + Tempo
2. Time + Capo (only if capo > 0)

## SF Symbols Used

| Field | Icon | Symbol Name |
|-------|------|-------------|
| Artist | 👤 | `person.fill` |
| Key | 🎵 | `music.note` |
| Tempo | ⏱️ | `metronome` |
| Time | 〰️ | `waveform` |
| Capo | 🎸 | `guitar` |
| Copyright | © | `c.circle` |

## Sticky Header Behavior

The header remains visible while scrolling through song content:

**Implementation:**
```swift
VStack(spacing: 0) {
    // Sticky Header
    SongHeaderView(parsedSong: parsed)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)

    // Scrollable Content
    ScrollView {
        // Song sections...
    }
}
```

**Benefits:**
- Quick reference to key, tempo, capo while performing
- No need to scroll back to top to check metadata
- Professional app behavior (like Apple Music)

## Responsive Design

### Full Metadata Display
When all fields are present:
```
Title (bold)
Subtitle (if present)
👤 Artist

┌─────────────────────────┐
│ 🎵 Key: G    ⏱️ 120 BPM │
│ 〰️ Time: 4/4  🎸 Capo: 2 │
└─────────────────────────┘

© Copyright Info
```

### Minimal Display
When only title and artist are present:
```
Title (bold)
👤 Artist

(No metadata card shown)
```

### Partial Metadata
When some fields are missing:
```
Title (bold)
👤 Artist

┌─────────────────────────┐
│ 🎵 Key: G               │
│ 〰️ Time: 4/4             │
└─────────────────────────┘

(No tempo or capo shown)
```

## Code Organization

**File:** `/Lyra/Views/SongDisplayView.swift`

**Sections:**
1. `SongDisplayView` (lines 12-105)
   - Main view with sticky header structure
2. `SongHeaderView` (lines 107-231)
   - Complete header layout
3. `MetadataItem` (lines 233-264)
   - Reusable metadata field component

## Accessibility

### VoiceOver Support
Each metadata item announces:
- Icon description
- Label
- Value

Example: "Music note, Key, G"

### Dynamic Type
All text scales with system font size preferences:
- Title: 26pt base → scales up/down
- Subtitle: 18pt base → scales up/down
- Artist: 16pt base → scales up/down
- Metadata labels/values: 13-14pt base → scale up/down

### Color Contrast
- Uses system colors that adapt to light/dark mode
- Blue icons provide good contrast on gray background
- Text meets WCAG AA standards

## Testing Previews

### Preview 1: "Amazing Grace"
Full metadata with all fields populated.

### Preview 2: "Enhanced Metadata Header"
Dedicated preview showing all metadata fields:
- Title + Subtitle
- Artist
- Key, Tempo, Time, Capo
- Copyright

### Preview 3: "Minimal Metadata"
Song with only title and artist (no metadata card).

### Preview 4: "Simple Song"
Basic test case.

## Design Decisions

### Why SF Symbols?
- Native iOS icons
- Automatically adapt to light/dark mode
- Familiar to iOS users
- No custom assets needed
- Accessibility built-in

### Why Light Gray Background?
- Subtle visual separation from content
- Doesn't compete with song text
- Works in light and dark mode
- Professional appearance
- Easy to scan

### Why Sticky Header?
- Musicians need constant reference to key/tempo/capo
- Common in professional music apps
- Doesn't interrupt flow while reading
- Maximizes viewport for lyrics/chords

### Why Two-Row Layout?
- Compact vertical space usage
- Natural grouping: Key+Tempo (musical), Time+Capo (technical)
- Easy to scan left-to-right
- Mobile-friendly

## Comparison: Before vs After

### Before
```
Amazing Grace (large)
John Newton (gray)

Key | G  Tempo | 120 BPM  Capo | 2  Time | 4/4

Copyright info
```

**Issues:**
- No visual hierarchy
- No icons for quick scanning
- Metadata not visually grouped
- No separation from song content
- Scrolls away immediately

### After
```
Amazing Grace (large, bold)
👤 John Newton (medium, gray)

┌─────────────────────────────────┐
│ 🎵 Key: G        ⏱️ Tempo: 120 BPM │
│ 〰️ Time: 4/4      🎸 Capo: 2       │
└─────────────────────────────────┘

© Copyright 2026
```

**Improvements:**
✅ Clear visual hierarchy
✅ Icons for instant recognition
✅ Card groups related metadata
✅ Clean separation from song
✅ Stays visible when scrolling

## Future Enhancements

### Interactive Metadata
- Tap Key to transpose
- Tap Tempo to start metronome
- Tap Capo to remove/adjust
- Tap Time to hear click track

### Metadata Editing
- Long-press to edit any field
- Quick-edit mode in header
- Sync changes to ParsedSong and Song model

### Alternative Layouts
- Compact mode (single row)
- Expanded mode (with album, year, etc.)
- Custom layouts via user preferences

### Additional Icons
- Album art thumbnail
- Genre tag
- Difficulty level indicator
- Last played date

## Performance

- ✅ Minimal view hierarchy (3 levels deep max)
- ✅ No expensive calculations
- ✅ Efficient conditional rendering
- ✅ Smooth scroll with sticky header
- ✅ Fast layout updates

## Platform Compatibility

- ✅ iOS 17.0+
- ✅ iPadOS (responsive layout)
- ✅ iPhone (all sizes)
- ✅ Light/Dark mode
- ✅ Landscape orientation
- ✅ Dynamic Type
- ✅ VoiceOver

This creates a professional, polished metadata header that rivals commercial music apps like OnSong, Ultimate Guitar, and ChordPro Manager.
