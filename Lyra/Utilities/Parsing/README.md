# ChordPro Parser

A comprehensive ChordPro format parser for Lyra that converts chord chart text into structured, renderable data.

## Overview

The ChordPro parser takes text formatted in the ChordPro standard and converts it into a structured `ParsedSong` object that can be easily rendered in SwiftUI with proper chord positioning.

## Components

### Models

1. **ParsedSong** - Top-level container for a parsed song
   - Metadata (title, artist, key, tempo, etc.)
   - Array of sections (verses, choruses, etc.)
   - Computed properties for common queries

2. **SongSection** - A section of the song (verse, chorus, bridge, etc.)
   - Section type and label
   - Array of lines
   - Index for numbering (Verse 1, Verse 2, etc.)

3. **SongLine** - A single line within a section
   - Array of line segments
   - Line type (lyrics, chords-only, blank, comment)
   - Text extraction utilities

4. **LineSegment** - A piece of text with an optional chord
   - Text content
   - Optional chord above the text
   - Position for rendering alignment

### Enums

- **SectionType** - verse, chorus, bridge, prechorus, instrumental, intro, outro, etc.
- **LineType** - lyrics, chordsOnly, blank, comment, directive

## Usage

### Basic Parsing

```swift
let chordProText = """
{title: Amazing Grace}
{artist: John Newton}
{key: G}

{start_of_verse}
[G]Amazing [G7]grace, how [C]sweet the [G]sound
That saved a wretch like [D]me
{end_of_verse}
"""

let parsedSong = ChordProParser.parse(chordProText)

print(parsedSong.title)  // "Amazing Grace"
print(parsedSong.key)    // "G"
print(parsedSong.sections.count)  // 1 (one verse)
```

### Accessing Sections

```swift
// Get all verses
let verses = parsedSong.verses

// Get all choruses
let choruses = parsedSong.choruses

// Get sections of a specific type
let bridges = parsedSong.sections(ofType: .bridge)

// Iterate through all sections
for section in parsedSong.sections {
    print("\(section.label):")
    for line in section.lines {
        print("  \(line.text)")
    }
}
```

### Working with Chords

```swift
// Get all unique chords
let chords = parsedSong.uniqueChords  // Set<String>

// Get chords in order of appearance
let allChords = parsedSong.allChords  // [String]

// Get chords from a specific line
let line = parsedSong.sections[0].lines[0]
let lineChords = line.chords  // ["G", "G7", "C", "G"]
```

### Rendering Lines with Chords

```swift
let line = parsedSong.sections[0].lines[0]

for segment in line.segments {
    if let chord = segment.displayChord {
        // Render chord above text
        print(chord)
    }
    print(segment.text)
}
```

### Integration with Song Model

```swift
// Parse a song's content
let song = Song(title: "Amazing Grace", content: chordProText)
let parsed = song.parsedContent()

// Update song metadata from ChordPro directives
song.updateMetadataFromContent()
```

## Supported ChordPro Directives

### Metadata Directives

- `{title: Song Title}` or `{t: Song Title}`
- `{artist: Artist Name}` or `{a: Artist Name}`
- `{album: Album Name}`
- `{key: G}` or `{k: G}`
- `{tempo: 120}`
- `{time: 4/4}` or `{time_signature: 4/4}`
- `{capo: 2}`
- `{year: 2023}`
- `{copyright: Copyright Info}` or `{c: Copyright Info}`
- `{ccli: 1234567}` or `{ccli_number: 1234567}`
- `{composer: Composer Name}`
- `{lyricist: Lyricist Name}`
- `{arranger: Arranger Name}`

### Section Directives

- `{start_of_verse}` / `{end_of_verse}` or `{sov}` / `{eov}`
- `{start_of_chorus}` / `{end_of_chorus}` or `{soc}` / `{eoc}`
- `{start_of_bridge}` / `{end_of_bridge}` or `{sob}` / `{eob}`
- `{verse}`, `{chorus}`, `{bridge}` (implicit section starts)
- Supported sections: verse, chorus, bridge, prechorus, instrumental, intro, outro, interlude, tag, vamp

### Chord Notation

Chords are enclosed in square brackets and can appear anywhere in the text:

```
[G]Amazing grace        # Chord at start of line
Amazing [C]grace        # Chord mid-word
Amazing grace [D]       # Chord at end of line
[G]  [C]  [D]          # Chords-only line
```

### Comments

Lines starting with `#` are treated as comments:

```
# This is a comment
# TODO: Add bridge section
```

## Example ChordPro Document

```chordpro
{title: Amazing Grace}
{artist: John Newton}
{key: G}
{tempo: 90}
{time: 4/4}
{capo: 0}

{start_of_verse}
[G]Amazing [G7]grace, how [C]sweet the [G]sound
That saved a wretch like [D]me
[G]I once was [G7]lost, but [C]now am [G]found
Was [Em]blind but [D]now I [G]see
{end_of_verse}

{start_of_chorus}
[C]My chains are [G]gone, I've been set [Em]free
My God, my [C]Savior has ransomed [G]me
{end_of_chorus}
```

## SwiftUI Rendering Example

```swift
struct ChordLineView: View {
    let line: SongLine

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Chords row
            HStack(spacing: 0) {
                ForEach(line.segments) { segment in
                    VStack(alignment: .leading, spacing: 2) {
                        if let chord = segment.displayChord {
                            Text(chord)
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text(" ")
                                .font(.caption)
                        }
                    }
                    .frame(minWidth: CGFloat(segment.text.count) * 8)
                }
            }

            // Lyrics row
            Text(line.text)
                .font(.body)
        }
    }
}
```

## Notes

- The parser preserves the original ChordPro text in `ParsedSong.rawText`
- Blank lines are preserved to maintain song formatting
- Section numbering is automatic (Verse 1, Verse 2, etc.)
- Unknown section types default to `.unknown`
- The parser is lenient and will handle malformed input gracefully
