# ChordPro Parser Usage Guide

## Quick Start

```swift
import Lyra

// Parse a ChordPro string
let chordPro = """
{title: Amazing Grace}
{artist: John Newton}
{key: G}

{start_of_verse}
[G]Amazing [C]grace how [G]sweet the [D]sound
That [G]saved a [C]wretch like [G]me
{end_of_verse}
"""

let parsedSong = ChordProParser.parse(chordPro)

// Access metadata
print(parsedSong.title)   // "Amazing Grace"
print(parsedSong.artist)  // "John Newton"
print(parsedSong.key)     // "G"

// Access sections
for section in parsedSong.sections {
    print("\(section.label):")
    for line in section.lines {
        print("  \(line.text)")
    }
}

// Get chords
let allChords = parsedSong.uniqueChords
// Set(["G", "C", "D"])
```

## Features Implemented

### ✅ Metadata Directives

All standard ChordPro metadata is supported:

```chordpro
{title: Song Title}         or {t: Song Title}
{subtitle: Subtitle}        or {st: Subtitle}
{artist: Artist Name}       or {a: Artist Name}
{album: Album Name}
{key: G}                    or {k: G}
{tempo: 120}
{time: 4/4}
{capo: 2}
{year: 2023}
{copyright: Copyright Info}
{ccli: 1234567}
{composer: Composer Name}
{lyricist: Lyricist Name}
{arranger: Arranger Name}
```

### ✅ Section Directives

```chordpro
{start_of_verse}...{end_of_verse}     or {sov}...{eov}
{start_of_chorus}...{end_of_chorus}   or {soc}...{eoc}
{start_of_bridge}...{end_of_bridge}   or {sob}...{eob}
{verse}                               # Implicit section start
{chorus}
{bridge}
{prechorus}
{intro}
{outro}
{interlude}
```

### ✅ Chord Notation

**Inline chords:**
```chordpro
[G]Amazing grace
Ama[G]zing gr[C]ace
Amazing grace[D]
```

**Chords on separate lines** (automatically merged):
```chordpro
[G]  [C]  [D]
Amazing grace how sweet
```

**Complex chords:**
```chordpro
[C#m7]  [Bb/D]  [Dsus4]  [G/B]
```

### ✅ Comments

```chordpro
# Line comment
{comment: Directive comment}
{c: Short comment}
```

## Parser API

### ChordProParser

```swift
class ChordProParser {
    static func parse(_ text: String) -> ParsedSong
}
```

### ParsedSong

```swift
struct ParsedSong {
    // Metadata
    let title: String?
    let subtitle: String?
    let artist: String?
    let key: String?
    let tempo: Int?
    let capo: Int?
    // ... and more

    // Content
    let sections: [SongSection]
    let rawText: String

    // Computed Properties
    var uniqueChords: Set<String>
    var allChords: [String]
    var hasChords: Bool
    var lyricsOnly: String
    var verses: [SongSection]
    var choruses: [SongSection]
    var bridges: [SongSection]
}
```

### SongSection

```swift
struct SongSection {
    let type: SectionType        // .verse, .chorus, etc.
    let label: String             // "Verse 1", "Chorus", etc.
    let lines: [SongLine]
    let index: Int                // Section number

    var hasChords: Bool
    var uniqueChords: Set<String>
    var text: String
}
```

### SongLine

```swift
struct SongLine {
    let segments: [LineSegment]
    let type: LineType           // .lyrics, .chordsOnly, .blank, .comment

    var hasChords: Bool
    var chords: [String]
    var text: String
}
```

### LineSegment

```swift
struct LineSegment {
    let text: String
    let chord: String?
    let position: Int

    var hasChord: Bool
    var displayChord: String?
}
```

## Common Usage Patterns

### Get All Chords

```swift
let parsed = ChordProParser.parse(chordPro)

// Unique chords (for chord chart)
let uniqueChords = parsed.uniqueChords
// Set(["G", "C", "D", "Em"])

// All chords in order (for analysis)
let allChords = parsed.allChords
// ["G", "C", "G", "D", "G", "C", ...]
```

### Iterate Through Sections

```swift
for section in parsed.sections {
    print("[\(section.label)]")

    for line in section.lines {
        switch line.type {
        case .lyrics:
            // Render with chords
            for segment in line.segments {
                if let chord = segment.displayChord {
                    print(chord, terminator: " ")
                }
                print(segment.text, terminator: "")
            }
            print()

        case .blank:
            print()

        case .comment:
            print("// \(line.text)")

        default:
            print(line.text)
        }
    }
}
```

### Filter Sections

```swift
// Get all verses
let verses = parsed.verses

// Get all choruses
let choruses = parsed.choruses

// Get specific section type
let bridges = parsed.sections(ofType: .bridge)
```

### Extract Lyrics Without Chords

```swift
let lyricsOnly = parsed.lyricsOnly
// Multi-line string with all lyrics, no chords
```

### Integrate with Song Model

```swift
var song = Song(title: "Amazing Grace", content: chordProText)

// Parse and auto-fill metadata
song.updateMetadataFromContent()

// Parse when needed
let parsed = song.parsedContent()
```

## Sample Songs

Use the provided sample songs for testing:

```swift
// Complete examples
SampleChordProSongs.amazingGrace
SampleChordProSongs.blestBeTheTie
SampleChordProSongs.howGreatThouArt

// Feature-specific examples
SampleChordProSongs.inlineChords
SampleChordProSongs.separateChordsExample
SampleChordProSongs.complexExample

// Edge cases
SampleChordProSongs.minimalExample
SampleChordProSongs.malformedExample

// Get all
let allSamples = SampleChordProSongs.all
```

## Testing

Run the comprehensive test suite:

```bash
# In Xcode
Cmd + U

# Or via command line
xcodebuild test -scheme Lyra
```

Test coverage includes:
- ✅ Metadata parsing (basic, shorthand, extended)
- ✅ Inline chord parsing
- ✅ Chords on separate lines
- ✅ Section parsing (explicit, shorthand, auto-numbering)
- ✅ Comment parsing (line and directive)
- ✅ Complete song parsing
- ✅ Edge cases and malformed input
- ✅ All sample songs

## Rendering Example

```swift
struct ChordLineView: View {
    let line: SongLine

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Chords row
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(line.segments) { segment in
                    VStack(alignment: .leading, spacing: 0) {
                        if let chord = segment.displayChord {
                            Text(chord)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        Text(segment.text)
                            .font(.body)
                    }
                }
            }
        }
    }
}
```

## Error Handling

The parser is robust and handles malformed input gracefully:

- Missing closing brackets: `[Unclosed` → treated as regular text
- Missing closing braces: `{incomplete` → ignored
- Unknown directives: `{unknown: value}` → ignored
- Empty content: Returns empty ParsedSong with no sections
- Invalid chord positions: Best-effort positioning

## Performance

- ✅ Fast parsing of typical songs (<1ms)
- ✅ Efficient memory usage
- ✅ No regex overhead (character-by-character parsing)
- ✅ Lazy evaluation where possible

## Next Steps

1. **Rendering** - Create SwiftUI views to display parsed songs
2. **Transposition** - Implement chord transposition using parsed data
3. **Search** - Index songs by chords, lyrics, metadata
4. **Export** - Convert back to ChordPro or other formats
5. **Editing** - Create ChordPro editor with syntax highlighting
