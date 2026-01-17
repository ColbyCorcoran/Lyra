# ChordPro File Import Feature Documentation

## Overview

Lyra supports importing ChordPro files from external sources like Files app, iCloud Drive, Dropbox, and other file providers. This is a critical feature for users who already have existing chord chart collections.

## Supported File Types

| Extension | Description | UTType |
|-----------|-------------|--------|
| `.txt` | Plain text files | `.plainText` |
| `.cho` | ChordPro files | Custom UTType |
| `.chordpro` | ChordPro files | Custom UTType |
| `.chopro` | ChordPro alternative | Custom UTType |
| `.crd` | Chord files | Custom UTType |
| Any text file | Generic text | `.text` |

## User Interface

### Import Button Location

```
┌────────────────────────────────────┐
│ Import  Library            +       │
│  (📥)    (Title)         (Add)     │
└────────────────────────────────────┘
```

**Position:** Top-left of navigation bar
**Visibility:** Only shown when "All Songs" tab is selected
**Icon:** Download arrow (square.and.arrow.down)
**Label:** "Import"

### Import Flow

1. **Trigger Import**
   - User taps "Import" button
   - File picker appears

2. **File Selection**
   - Native iOS file picker
   - Shows Files, iCloud Drive, and connected providers
   - Supports browse and search
   - Can only select one file at a time

3. **Import Processing**
   - File read and parsed
   - Song created in database
   - Success/error alert shown

4. **Post-Import**
   - Option to view imported song
   - Or dismiss and see song in list

## Implementation Details

### ImportManager.swift

#### Main Import Function

```swift
func importFile(from url: URL, to modelContext: ModelContext) throws -> ImportResult
```

**Process:**
1. Access security-scoped resource
2. Read file contents (UTF-8, with ASCII/ISO fallback)
3. Parse with ChordProParser
4. Extract metadata from ChordPro tags
5. Create Song object
6. Set import metadata
7. Save to SwiftData
8. Return ImportResult

**Metadata Extraction:**
- Title: From `{title:}` tag or filename
- Artist: From `{artist:}` tag
- Key: From `{key:}` tag
- Tempo: From `{tempo:}` tag
- Time Signature: From `{time:}` tag
- Capo: From `{capo:}` tag
- Copyright: From `{copyright:}` tag
- CCLI Number: From `{ccli:}` tag
- Album: From `{album:}` tag
- Year: From `{year:}` tag

**Import Metadata Set:**
- `importSource`: "Files"
- `importedAt`: Current date/time
- `originalFilename`: Original file name

#### Plain Text Fallback

```swift
func importAsPlainText(from url: URL, to modelContext: ModelContext) throws -> ImportResult
```

**When Used:**
- User chooses "Import as Plain Text" after ChordPro parsing fails
- File content imported without parsing
- `contentFormat` set to `.plainText`
- `importSource` set to "Files (Plain Text)"

### Error Handling

**Error Types:**

| Error | Description | User Message |
|-------|-------------|--------------|
| `fileNotReadable` | Can't access file | "Unable to read the file" |
| `emptyContent` | File is empty | "The file is empty" |
| `invalidEncoding` | Unsupported encoding | "The file encoding is not supported" |
| `parsingFailed` | ChordPro parse errors | "Unable to parse the ChordPro content" |
| `unknownError` | Other errors | "Import failed: {error}" |

**Recovery Suggestions:**

Each error provides helpful recovery text:
- **fileNotReadable**: "Make sure the file is a valid text file and try again."
- **emptyContent**: "The file contains no content. Please select a different file."
- **invalidEncoding**: "Try converting the file to UTF-8 encoding."
- **parsingFailed**: "The file may not be in ChordPro format. You can still import it as plain text."

### Alerts

#### Success Alert

```
┌─────────────────────────────┐
│  Import Successful          │
│                             │
│  Successfully imported      │
│  "Amazing Grace"            │
│                             │
│  [View Song]     [OK]       │
└─────────────────────────────┘
```

**Actions:**
- **View Song**: Navigates to SongDisplayView
- **OK**: Dismisses alert

#### Error Alert

```
┌─────────────────────────────┐
│  Import Failed              │
│                             │
│  Unable to parse the        │
│  ChordPro content           │
│                             │
│  The file may not be in     │
│  ChordPro format...         │
│                             │
│  [Import as Plain Text]     │
│  [OK]                       │
└─────────────────────────────┘
```

**Actions:**
- **Import as Plain Text**: Retry import without parsing
- **OK**: Cancel import

#### Warning Alert

```
┌─────────────────────────────┐
│  Import Completed with      │
│  Warnings                   │
│                             │
│  The file was imported but  │
│  some ChordPro formatting   │
│  may not have been          │
│  recognized.                │
│                             │
│  [OK]                       │
└─────────────────────────────┘
```

Shown when:
- File imported successfully
- But parser found no sections (likely malformed ChordPro)

## Example Import Scenarios

### Scenario 1: Perfect ChordPro File

**File:** `amazing_grace.cho`

**Content:**
```chordpro
{title: Amazing Grace}
{artist: John Newton}
{key: G}
{tempo: 90}
{time: 3/4}

{start_of_verse}
[G]Amazing [G7]grace, how [C]sweet the [G]sound
That saved a wretch like [D]me
{end_of_verse}
```

**Result:**
- ✅ Title: "Amazing Grace"
- ✅ Artist: "John Newton"
- ✅ Key: G
- ✅ Tempo: 90
- ✅ Time: 3/4
- ✅ Content: Full ChordPro text
- ✅ Success alert shown
- ✅ Song appears in list

### Scenario 2: ChordPro Without Metadata

**File:** `song.txt`

**Content:**
```chordpro
{verse}
[C]Hello [G]world [Am]of [F]music
```

**Result:**
- ✅ Title: "song" (from filename)
- ✅ No artist, key, tempo, etc.
- ✅ Content: ChordPro text
- ✅ Parses one verse section
- ✅ Success alert shown

### Scenario 3: Plain Text File

**File:** `lyrics.txt`

**Content:**
```
Amazing grace how sweet the sound
That saved a wretch like me
```

**Result:**
- ⚠️ Warning alert (no sections parsed)
- ✅ Title: "lyrics"
- ✅ Content: Plain text
- ✅ Can still view in SongDisplayView
- ✅ No chords displayed

### Scenario 4: Malformed File

**File:** `broken.cho`

**Content:**
```
{title: Test
[Unclosed bracket
Random text
```

**Result:**
- ❌ Parsing warning alert
- ✅ Still imported
- ✅ Title: "Test" or "broken"
- ✅ Content: Raw text
- ✅ User can edit later

### Scenario 5: Import Failure

**File:** `image.jpg` (selected by mistake)

**Result:**
- ❌ Error alert: "The file encoding is not supported"
- ❌ Not imported
- ❌ No song created
- ✅ User can try again

## Code Flow

### 1. User Taps Import Button

```swift
Button {
    showFileImporter = true
} label: {
    Label("Import", systemImage: "square.and.arrow.down")
}
```

### 2. File Picker Appears

```swift
.fileImporter(
    isPresented: $showFileImporter,
    allowedContentTypes: ImportManager.supportedTypes,
    allowsMultipleSelection: false
) { result in
    handleFileImport(result: result)
}
```

### 3. Handle Import Result

```swift
private func handleFileImport(result: Result<[URL], Error>) {
    switch result {
    case .success(let urls):
        guard let url = urls.first else { return }
        importFile(from: url)
    case .failure(let error):
        showError(...)
    }
}
```

### 4. Import File

```swift
private func importFile(from url: URL) {
    do {
        let result = try ImportManager.shared.importFile(
            from: url,
            to: modelContext
        )
        importedSong = result.song

        if result.hadParsingWarnings {
            showError(...)  // Warning
        } else {
            showImportSuccess = true
        }
    } catch {
        showError(...)  // Error
    }
}
```

### 5. Show Result

**Success:**
```swift
.alert("Import Successful", isPresented: $showImportSuccess) {
    Button("View Song") {
        navigateToImportedSong = true
    }
    Button("OK", role: .cancel) {}
}
```

**Error:**
```swift
.alert("Import Failed", isPresented: $showImportError) {
    if failedImportURL != nil {
        Button("Import as Plain Text") {
            importAsPlainText()
        }
    }
    Button("OK", role: .cancel) {}
}
```

### 6. Navigate (Optional)

```swift
.navigationDestination(isPresented: $navigateToImportedSong) {
    if let song = importedSong {
        SongDisplayView(song: song)
    }
}
```

## Security Considerations

### Security-Scoped Resources

**Why Needed:**
iOS sandbox restricts file access. User-selected files need explicit permission.

**Implementation:**
```swift
guard url.startAccessingSecurityScopedResource() else {
    throw ImportError.fileNotReadable
}
defer { url.stopAccessingSecurityScopedResource() }

// Read file...
```

**Important:**
- Always call `startAccessingSecurityScopedResource()` before reading
- Always call `stopAccessingSecurityScopedResource()` in defer
- Don't store URLs long-term (use bookmarks instead)

### Encoding Fallback

**Primary:** UTF-8 (most common)
**Fallback 1:** ASCII (basic English text)
**Fallback 2:** ISO Latin 1 (Western European)

**Code:**
```swift
do {
    content = try String(contentsOf: url, encoding: .utf8)
} catch {
    if let altContent = try? String(contentsOf: url, encoding: .ascii) {
        content = altContent
    } else if let altContent = try? String(contentsOf: url, encoding: .isoLatin1) {
        content = altContent
    } else {
        throw ImportError.invalidEncoding
    }
}
```

## Performance

### File Size Limits

**Recommended:** < 100 KB
**Typical ChordPro file:** 2-5 KB
**Maximum:** iOS handles up to several MB, but UI may lag

**Large File Handling:**
- Files load on main thread (intentional for simplicity)
- Very large files (>1MB) may cause brief UI freeze
- Future: Add async loading with progress indicator

### Memory Usage

**Per Import:**
- File contents: ~5 KB average
- Parsed structure: ~2 KB
- Song model: ~1 KB
- Total: ~8 KB per song

**100 Imports:**
- ~800 KB total
- Negligible impact on modern devices

## Future Enhancements

### Multiple File Selection

Currently: Single file only
Future: Allow selecting multiple files

**Implementation:**
```swift
.fileImporter(
    ...
    allowsMultipleSelection: true  // Change to true
)
```

**UI Changes:**
- Progress bar for batch import
- Summary: "Imported 15 of 20 songs"
- Skip duplicates option

### Dropbox/Google Drive Integration

**Direct Integration:**
- OAuth login
- Browse cloud folders
- Import without downloading

**Benefits:**
- No local storage needed
- Access larger libraries
- Sync across devices

### URL Scheme Import

**Example:** `lyra://import?url=...`

**Use Cases:**
- Import from web browser
- Share from other apps
- Deep linking

### Duplicate Detection

**Before Import:**
- Check if song with same title exists
- Offer to skip, replace, or create duplicate
- Smart matching (fuzzy title comparison)

### Import History

**Track:**
- Import date/time
- Source (Files, Dropbox, URL)
- Original filename
- Import success/failure

**UI:**
- "Recently Imported" smart list
- Import log in settings
- Re-import button

### Batch Metadata Editing

**After Import:**
- Select multiple imported songs
- Bulk edit artist, album, tags
- Useful for collections from same source

## Testing

See `IMPORT_TESTING_GUIDE.md` for comprehensive test cases including:
- Various file formats
- Different encodings
- Error scenarios
- Large files
- Edge cases
- Recovery paths

## Integration Points

### From LibraryView
- Import button in toolbar
- File picker presentation
- Alert handling
- Navigation to imported song

### To Song Model
- All metadata fields populated
- Import tracking fields set
- Content format specified

### With ChordProParser
- Automatic parsing on import
- Metadata extraction
- Error tolerance

This comprehensive import feature makes it easy for users to bring their existing chord chart collections into Lyra!
