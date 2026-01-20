# Supported File Formats

Lyra supports a wide variety of chord chart file formats, making it easy to import your existing song library from virtually any source.

## Supported Formats

### Native Formats

#### ChordPro (.cho, .chordpro, .chopro, .crd)
**Support Level**: Native ✓

ChordPro is Lyra's native format. Files are imported directly without conversion.

**Features**:
- Metadata directives ({title:}, {artist:}, {key:}, etc.)
- Inline chord notation [C]word
- Section markers ({start_of_chorus}, {soc}, etc.)
- Comments and formatting
- Full preservation of all ChordPro features

**Example**:
```
{title: Amazing Grace}
{artist: John Newton}
{key: G}

{start_of_chorus}
A[G]mazing [G7]grace, how [C]sweet the [G]sound
{end_of_chorus}
```

### Document Formats

#### PDF Files (.pdf)
**Support Level**: Native ✓

PDF files are imported with full content preservation.

**Features**:
- Stored as attachments (inline for <5MB, external for larger)
- PDF viewer integration
- Optional OCR text extraction
- Searchable content

**Use Cases**:
- Scanned chord charts
- Published sheet music
- Professional arrangements

#### Rich Text Format (.rtf)
**Support Level**: Auto-Convert ✓

RTF files are automatically converted to ChordPro format.

**Conversion Process**:
1. Extract plain text from RTF
2. Detect chord format (chords over lyrics, inline, etc.)
3. Convert to ChordPro notation
4. Preserve title and basic structure

**Best Results**: Use RTF files with clear chord/lyric separation

#### Microsoft Word (.doc, .docx)
**Support Level**: Auto-Convert ✓

Word documents are automatically converted to ChordPro format.

**Conversion Process**:
1. Extract text content from Word document
2. Analyze text structure for chord patterns
3. Convert to ChordPro format
4. Extract title from first line or filename

**Supported Word Formats**:
- .docx (Word 2007+) - Full support
- .doc (Word 97-2003) - Best-effort conversion

**Tips for Best Results**:
- Use simple formatting (avoid tables, columns)
- Place chords on separate lines above lyrics
- Keep title on the first line
- Use standard chord notation (C, Am, G7, etc.)

### XML Formats

#### OpenSong Format (.xml)
**Support Level**: Auto-Convert ✓

OpenSong is a popular open-source worship software format.

**Conversion Process**:
1. Parse XML structure
2. Extract metadata (title, author, key, tempo, capo)
3. Convert chord notation from `.C.Am.F` to `[C]word [Am]word [F]word`
4. Map section markers ([Verse], [Chorus], [Bridge])
5. Generate ChordPro output

**Supported OpenSong Features**:
- Title, author/artist, key, tempo, capo
- Verse, chorus, and bridge sections
- Chord notation (`.` markers)
- Lyrics with formatting

**Example OpenSong**:
```xml
<song>
  <title>Amazing Grace</title>
  <author>John Newton</author>
  <key>G</key>
  <lyrics>
[Chorus]
.G    .G7       .C      .G
Amazing grace, how sweet the sound
  </lyrics>
</song>
```

**Converts to ChordPro**:
```
{title: Amazing Grace}
{artist: John Newton}
{key: G}

{start_of_chorus}
[G]Amazing [G7]grace, how [C]sweet the [G]sound
{end_of_chorus}
```

### Plain Text Formats

#### Plain Text (.txt)
**Support Level**: Smart Convert ✓

Plain text files are automatically analyzed and converted to ChordPro.

**Detected Formats**:

1. **Chords Over Lyrics**
   ```
   C       G       Am      F
   Amazing grace how sweet the sound
   ```

   Converts to: `[C]Amazing [G]grace how [Am]sweet the [F]sound`

2. **Inline Chords**
   ```
   [C]Amazing [G]grace how [Am]sweet the [F]sound
   ```

   Already ChordPro format - imported directly

3. **Plain Lyrics**
   ```
   Amazing grace how sweet the sound
   That saved a wretch like me
   ```

   Imported as-is with title extracted from first line

**Auto-Detection**:
- Lyra analyzes the file structure
- Detects chord patterns automatically
- Chooses the best conversion method
- Extracts title from first line when possible

#### OnSong Format (.onsong)
**Support Level**: Smart Convert ✓

OnSong is a popular iOS chord chart app format.

**Features**:
- Similar to ChordPro with some differences
- Auto-detected and converted
- Supports metadata and sections
- Chord notation preserved

### Format Detection

Lyra uses smart format detection to automatically determine the best way to import each file:

1. **File Extension**: Initial hint about format
2. **Content Analysis**: Examines file structure
3. **Pattern Matching**: Detects chord patterns
4. **Confidence Scoring**: Rates format likelihood
5. **Conversion**: Applies best conversion method

**Detection Confidence Levels**:
- **100%**: ChordPro directives, OpenSong XML structure
- **70%+**: Clear chord line patterns
- **50%**: Plain text (best effort)

## Format Conversion Examples

### Chords Over Lyrics → ChordPro

**Input**:
```
Amazing Grace

C       G       Am      F
Amazing grace how sweet the sound
G       C       F       C
That saved a wretch like me
```

**Output**:
```
{title: Amazing Grace}

[C]Amazing [G]grace how [Am]sweet the [F]sound
[G]That [C]saved a [F]wretch like [C]me
```

### OpenSong XML → ChordPro

**Input**:
```xml
<song>
  <title>How Great Thou Art</title>
  <author>Carl Boberg</author>
  <key>A</key>
  <capo>2</capo>
  <lyrics>
[Verse 1]
.A        .D      .A
O Lord my God, when I in awesome wonder
  </lyrics>
</song>
```

**Output**:
```
{title: How Great Thou Art}
{artist: Carl Boberg}
{key: A}
{capo: 2}

{comment: Verse 1}
[A]O Lord my [D]God, when [A]I in awesome wonder
```

## Import Process

### Automatic Conversion Flow

1. **File Selection**: User selects file(s) to import
2. **Format Detection**: Lyra identifies file type
3. **Conversion**: File converted to ChordPro (if needed)
4. **Parsing**: ChordPro content parsed for metadata
5. **Import**: Song created in database
6. **Verification**: Import success confirmed

### Error Handling

If conversion fails:
- Lyra attempts best-effort import
- Original content preserved
- User can edit after import
- Error details provided

**Common Issues**:
- Malformed XML (OpenSong)
- Unrecognized chord patterns
- Empty or corrupted files
- Unsupported text encoding

**Solutions**:
- Import as plain text
- Manual editing after import
- File format conversion externally

## Best Practices

### For Best Import Results

1. **Use Clear Formatting**
   - Chords on separate lines or in brackets
   - Consistent spacing
   - Standard chord notation

2. **Include Metadata**
   - Title on first line
   - Artist/author information
   - Key signature when known

3. **Simple Structure**
   - Avoid complex formatting
   - Plain text preferred over styled
   - Clear section breaks

4. **Test Small Batches**
   - Import a few files first
   - Verify conversion quality
   - Adjust source files if needed

### Preparing Files for Import

**Word Documents**:
- Use simple paragraph formatting
- Chords above lyrics, aligned by position
- Title in first line
- Save as .docx for best results

**RTF Files**:
- Similar to Word documents
- Avoid complex formatting
- Plain text with chord markers

**OpenSong Files**:
- Export from OpenSong software
- Valid XML structure required
- Standard OpenSong conventions

**Plain Text**:
- UTF-8 encoding preferred
- Clear chord/lyric separation
- Consistent notation style

## Bulk Import

All formats support bulk import:
- Import up to 100 files at once
- Automatic format detection per file
- Mixed format batches supported
- Progress tracking and error reporting

**See**: [BULK_IMPORT.md] for bulk import documentation

## Limitations

### Current Limitations

1. **Word Documents**:
   - Complex tables may not convert well
   - Multi-column layouts not fully supported
   - Embedded images ignored

2. **RTF Files**:
   - Formatting may be lost
   - Font information not preserved
   - Color coding not maintained

3. **OpenSong XML**:
   - Some advanced features may not convert
   - Custom tags may be ignored
   - Presentation order not preserved

4. **Plain Text**:
   - Ambiguous chord positions may need adjustment
   - Complex formatting lost
   - Manual review recommended

### Not Supported

- Music XML (.musicxml, .mxl)
- Guitar Pro (.gp, .gp5, .gpx)
- PowerPoint presentations (.ppt, .pptx)
- Excel spreadsheets (.xls, .xlsx)
- Proprietary worship software formats (with some exceptions)

## Troubleshooting

### Import Fails

**Issue**: File won't import or shows error

**Solutions**:
1. Check file is not corrupted
2. Verify file format is supported
3. Try converting to .txt externally
4. Check file encoding (UTF-8 recommended)
5. Simplify formatting in source document

### Poor Conversion Quality

**Issue**: Chords in wrong positions or missing

**Solutions**:
1. Review source file formatting
2. Ensure chords clearly aligned with lyrics
3. Use standard chord notation
4. Try manual editing after import
5. Convert to ChordPro format before import

### Missing Metadata

**Issue**: Title, artist, or key not detected

**Solutions**:
1. Ensure title is on first line
2. Use ChordPro directives when possible
3. Edit song after import to add metadata
4. Use consistent naming conventions

### Duplicate Detection

**Issue**: Files marked as duplicates during bulk import

**Note**: Lyra checks for duplicates by title, artist, and content similarity

**Options**:
1. Skip duplicate (default)
2. Import anyway (creates separate entry)
3. Review and merge manually

## Future Enhancements

Planned format additions:
- Music XML support
- Guitar Pro file parsing
- Ultimate Guitar tab import
- Web scraping integration (with permission)
- Live transposition during import

## Support

For format-specific questions or issues:
1. Check this documentation
2. Try test import with sample file
3. Review error messages carefully
4. Report issues with example files

## Technical Details

### Format Converter

All format conversions handled by `FormatConverter` utility:
- Smart format detection
- Levenshtein distance for chord matching
- ChordPro metadata extraction
- Error-tolerant parsing

### Supported Encodings

- UTF-8 (preferred)
- ASCII (fallback)
- ISO Latin-1 (fallback)

### File Size Limits

- Text files: No practical limit
- PDF files: <5MB inline, larger as external
- Word/RTF: No limit (conversion time may vary)

---

**Last Updated**: 2026-01-20
