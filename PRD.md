# Multi-Column Support & Template System - Implementation Plan

## Overview

This PRD outlines the implementation of a **template-driven multi-column chord chart display system** for Lyra.

### Goals
- Utilize iPad space better with multi-column layouts
- Allow users to customize display style (fonts, columns, chord positioning)
- Preserve ChordPro format for compatibility
- Support PDF/print exports that preserve formatting

### Current Architecture

**Song Storage (Song.swift)**
- Songs stored with `content: String` field (raw text)
- `contentFormat: ContentFormat` enum (chordPro, onSong, plainText)
- `displaySettingsData: Data?` for per-song display customization

**Parsing & Display**
- **ChordProParser.swift**: Parses ChordPro format `[C]lyrics` into structured ParsedSong
- **SongDisplayView.swift**: Renders using DisplaySettings (line 38: `twoColumnMode: Bool` exists but currently unused/false)
- **DisplaySettings.swift**: Has fonts, colors, spacing, AND `twoColumnMode: Bool` flag

**Current Limitations**
1. App is "hyper-focused" on ChordPro format
2. Single-column rendering only (twoColumnMode exists but not implemented)
3. No template system - all songs use same format
4. Paste would convert multi-column to single column

---

## Core Design Decisions

**1. Template Storage: New SwiftData Model**
- Create separate `Template` model (not extending DisplaySettings)
- Clean separation: DisplaySettings = visual styling, Template = layout structure
- Supports persistence, versioning, import/export, sharing

**2. Song-Template Relationship**
- Optional per-song template selection with global default fallback
- Add `template: Template?` relationship to Song model
- Songs without template use global default (stored in UserDefaults)
- Built-in templates: Single Column, Two Column, Three Column

**3. Multi-Column Rendering Strategy**
- Section-aware line-based distribution with height balancing
- New `ColumnLayoutEngine` utility calculates content distribution
- Three balancing strategies: fillFirst, balanced, sectionBased
- Template specifies: column count (1-4), gap, width mode, balancing strategy

**4. View Architecture**
- Create new `MultiColumnSongView` (don't bloat existing SongDisplayView)
- Conditional rendering: if template.columnCount > 1, use MultiColumnSongView
- GeometryReader-based column width calculation
- Responsive to device rotation and size changes

---

## Phase 1 MVP - ✅ COMPLETE

Phase 1 has been successfully implemented with all core template system functionality.

**Phase 1 Files Created:**
1. `/Lyra/Models/Template.swift` - Template SwiftData model
2. `/Lyra/Utilities/TemplateManager.swift` - Template operations
3. `/Lyra/Utilities/ColumnLayoutEngine.swift` - Content distribution
4. `/Lyra/Views/MultiColumnSongView.swift` - Multi-column rendering
5. `/Lyra/Views/TemplateEditorView.swift` - Template editor UI
6. `/Lyra/Views/TemplateSelectionSheet.swift` - Template picker

**Phase 1 Files Modified:**
1. `/Lyra/Models/Song.swift` - Add template relationship
2. `/Lyra/Views/SongDisplayView.swift` - Integrate multi-column rendering
3. `/Lyra/LyraApp.swift` - Initialize template system
4. `/Lyra/Models/DisplaySettings.swift` - Deprecate twoColumnMode

---

# Phase 2: Template Import System - ✅ COMPLETE

## Overview

Enable users to import templates from existing documents (PDF, Word, Plain Text) to automatically extract layout characteristics and apply them to songs.

## Design Philosophy

**Approach**: Parse documents to extract structural and visual metadata, then map to Template model properties
**Priority**: PDF import (highest value) → Word import → Plain text import
**Validation**: All imported templates must pass `template.isValid` check before saving

---

## Phase 2A: PDF Template Import - ✅ COMPLETE

### New Files to Create

#### 1. `/Lyra/Utilities/TemplateImporter.swift` (Priority: Critical)

**PDF Analysis Engine** - Import templates from PDF/Word/Plain Text documents

**Key Implementation Details:**

1. **Column Detection Algorithm**:
   - Extract all text elements with positions from PDFPage
   - Sort by horizontal position (x coordinate)
   - Cluster elements into vertical bands (columns)
   - Identify gaps between clusters (whitespace > threshold = column separator)
   - Calculate gap widths and column width ratios
   - Map count (1-4) to Template.columnCount

2. **Typography Extraction**:
   - Group text elements by font size
   - Identify largest = title (map to titleFontSize)
   - Identify secondary large = heading (map to headingFontSize)
   - Identify primary body text (most frequent size = bodyFontSize)
   - Identify smallest = chords (map to chordFontSize)

3. **Chord Style Detection**:
   - Heuristics:
     - Short text (< 6 characters) + uppercase + contains musical symbols ([, ], #, b) = likely chord
     - If chords appear on separate lines above lyrics → `.separateLines`
     - If chords appear inline within text → `.inline`
     - If chords appear positioned above lyrics with offset → `.chordsOverLyrics` (default)

4. **Validation & Error Handling**:
   - Validate columnCount is 1-4
   - Validate all font sizes > 0
   - Validate gaps are positive
   - If detection fails, create sensible default (single column, current font sizes)

#### 2. `/Lyra/Views/TemplateImportView.swift` (Priority: High)

**Import UI with Document Picker**

Features:
- Template name input field
- Import format picker (PDF, Word, Plain Text)
- Document file picker
- Progress indicator during import
- Error alerts for failures
- Preview sheet showing imported template in TemplateEditorView
- Cancel/Import buttons

#### 3. `/Lyra/Views/TemplateLibraryView.swift` (Priority: Medium)

**Enhanced Template Management**

Features:
- Search bar for filtering templates
- "Built-in Templates" section
- "Custom Templates" section
- Template row view with details (column count, chord style)
- Toolbar menu with "Create New" and "Import from Document"
- Template selection opens TemplateEditorView
- Default template indicator (star icon)

### Files to Modify

#### 1. `/Lyra/Models/Template.swift`

Add import metadata properties:
- `importSource: ImportSource?` (pdf, word, plainText, inAppDesigner)
- `importedFromURL: String?` (original file path)
- `importedAt: Date?`

#### 2. `/Lyra/Views/SettingsView.swift`

Add "Templates" section with NavigationLink to TemplateLibraryView

---

### Implementation Checklist - Phase 2A (PDF Import)

- [x] Create `/Lyra/Utilities/TemplateImporter.swift`
  - [x] Define `TemplateImporter` class with static import methods
  - [x] Implement `importFromPDF(url:name:context:)` async method
  - [x] Implement `analyzePDFLayout(_:)` to extract DocumentLayout
  - [x] Implement `extractTextElements(from:)` using PDFPage API
  - [x] Implement `detectColumnStructure(_:pageWidth:)` clustering algorithm
  - [x] Implement `extractTypography(_:)` font size analysis
  - [x] Implement `detectChordStyle(_:)` heuristic detection
  - [x] Implement `mapToTemplate(layout:name:context:)` conversion
  - [x] Define `DocumentLayout`, `TextElement`, `ColumnStructure`, `TypographyProfile` structs
  - [x] Define `TemplateImportError` enum with localized descriptions

- [x] Create `/Lyra/Views/TemplateImportView.swift`
  - [x] Define `TemplateImportView` SwiftUI view
  - [x] Add template name TextField with validation
  - [x] Add import format picker (PDF, Word, Plain Text, Lyra Bundle)
  - [x] Add document file picker button with fileImporter modifier
  - [x] Implement `importTemplate()` async method
  - [x] Add progress indicator during import
  - [x] Add error alert for import failures
  - [x] Add preview sheet to show imported template in TemplateEditorView
  - [x] Add Cancel toolbar button

- [x] Create `/Lyra/Views/TemplateLibraryView.swift`
  - [x] Define `TemplateLibraryView` with @Query for templates
  - [x] Add search bar with searchable modifier
  - [x] Add "Built-in Templates" section
  - [x] Add "Custom Templates" section
  - [x] Create `TemplateRowView` with template details
  - [x] Add toolbar menu with "Create New" and "Import from Document" options
  - [x] Add sheet presentations for import and editor views
  - [x] Implement template selection and editing flow

- [x] Modify `/Lyra/Models/Template.swift`
  - [x] Add `importSource: ImportSource?` property
  - [x] Add `importedFromURL: String?` property
  - [x] Add `importedAt: Date?` property
  - [x] Define `ImportSource` enum (pdf, word, plainText, inAppDesigner)

- [x] Modify `/Lyra/Views/SettingsView.swift`
  - [x] Add "Templates" section
  - [x] Add NavigationLink to TemplateLibraryView
  - [x] Add descriptive footer text

### Testing - Phase 2A

- Import PDF with single column → detects 1 column
- Import PDF with two columns → detects 2 columns, calculates gap
- Import PDF with custom column widths → detects width ratios correctly
- Import PDF with large title → maps to titleFontSize
- Import PDF with chords over lyrics → detects chordsOverLyrics style
- Import PDF with separate chord lines → detects separateLines style
- Import malformed PDF → shows error alert with clear message
- Imported template appears in TemplateLibraryView custom section
- Imported template can be edited in TemplateEditorView
- Imported template can be set as default
- Imported template can be applied to songs
- Navigate to TemplateLibraryView from Settings

---

## Phase 2B: Word Import - ✅ COMPLETE

### Implementation Strategy

**Approach**: Parse .docx XML to extract styles and layout

**.docx Structure:**
- ZIP archive containing `word/document.xml`
- Styles in `word/styles.xml`
- Column configuration in `<w:cols>` elements
- Font sizes in `<w:sz>` elements

**Key Challenges:**
- XML parsing (use XMLParser or third-party library)
- Style inheritance resolution
- Column detection from section properties

**Implementation Checklist:**

- [x] Add `.docx` parsing to TemplateImporter
  - [x] Implement `importFromWord(url:name:context:)` async method
  - [x] Extract .docx ZIP archive
  - [x] Parse `word/document.xml` with XMLParser
  - [x] Parse `word/styles.xml` for font definitions
  - [x] Extract column count from `<w:cols>` element
  - [x] Extract font sizes from paragraph styles
  - [x] Map Word styles to Template properties
  - [x] Handle invalid/missing styles gracefully

> **Implementation Note:** DOCX import is fully implemented in `TemplateImporter.swift` using a custom `DOCXXMLParser` class (NSObject/XMLParserDelegate) for XML parsing.

---

## Phase 2C: Plain Text Import - ✅ COMPLETE

### Implementation Strategy

**Approach**: Detect patterns in spacing and structure

**Detection Heuristics:**
- Multiple spaces (4+) may indicate columns
- Consistent vertical alignment suggests column structure
- Detect ChordPro markers `[chord]` for format detection

**Implementation Checklist:**

- [x] Implement plain text import
  - [x] Read file contents as String
  - [x] Analyze whitespace patterns for column detection
  - [x] Detect ChordPro format markers
  - [x] Create sensible default template (likely single column)
  - [x] Preserve detected format characteristics

> **Implementation Note:** Plain text import is implemented in `TemplateImporter.swift` via the `importFromPlainText(url:name:context:)` method.

---

# Phase 3: Export System - ✅ COMPLETE

## Overview

Enable users to export songs in multiple formats while preserving template formatting or converting to portable formats.

## Export Formats

1. **ChordPro (.cho)** - Pure ChordPro format (strips template, universal compatibility) ✅
2. **PDF (.pdf)** - Rendered with template applied, multi-column support, ChordPro parsing ✅
3. **Plain Text (.txt)** - Lyrics only, no chords ✅
4. **Lyra Bundle (.lyra)** - JSON bundle with song + template + settings for round-trip import/export ✅
5. **JSON (.json)** - Structured song data export ✅

---

## Phase 3A: Export Infrastructure - ✅ COMPLETE

### New Files to Create

#### 1. `/Lyra/Utilities/SongExporter.swift` (Priority: Critical)

**Export Engine with Format Support**

Features:
- `exportToChordPro(_:)` - Write song.content to .cho file ✅
- `exportToPDF(_:template:)` - Render to PDF with template layout, multi-column, ChordPro parsing ✅
- `exportToPlainText(_:)` - Extract lyrics only from ParsedSong ✅
- `exportToLyraBundle(_:template:)` - JSON bundle with song + template data ✅
- `exportToJSON(_:)` / `exportToJSONData(_:)` - Structured JSON export ✅
- `exportToFile(_:format:url:template:)` - Write to directory (all formats) ✅
- `exportMultipleSongs(_:format:to:)` - Batch export ✅

#### 2. `/Lyra/Views/ExportOptionsSheet.swift` (Priority: High)

**Export UI with Format Selection**

Features:
- Export format picker (ChordPro, PDF, Plain Text, Lyra Bundle, JSON) ✅
- Include metadata toggle ✅
- Include notes toggle ✅
- Custom filename support ✅
- Preview section (text formats) ✅
- Cancel/Export buttons ✅

### Files to Modify

#### 1. `/Lyra/Views/SongDisplayView.swift`

Add export button to toolbar:
- Button with "square.and.arrow.up" icon
- State variable `showExportOptions: Bool`
- Sheet presentation for ExportOptionsSheet

#### 2. `/Lyra/Views/SongDetailView.swift` (if exists)

Add "Export Song" option to context menu

---

### Implementation Checklist - Phase 3A (Export)

- [x] Create `/Lyra/Utilities/SongExporter.swift`
  - [x] Define `SongExporter` class with static export method
  - [x] Define `ExportFormat` enum (chordPro, json, plainText)
  - [x] Implement `exportToChordPro(_:)` - write song.content to file
  - [x] Implement `exportToJSON(_:)` / `exportToJSONData(_:)` - structured JSON export
  - [x] Implement `exportToPlainText(_:)` - extract lyrics only from ParsedSong
  - [x] Implement `exportToFile(_:format:)` - write to temporary directory
  - [x] Implement `exportMultipleSongs(_:format:)` - batch export support
  - [x] Define `SongExportData` Codable struct for JSON serialization
  - [x] Define `SongExportError` enum with localized descriptions and recovery suggestions
  - [x] Handle file writing to temporary directory
  - [x] Add `suggestedFilename` and `sanitizeFilename` helpers
  - [x] Implement `exportToPDF(_:template:)` with UIGraphicsPDFRenderer
  - [x] Implement PDF rendering with multi-column support, ChordPro parsing, and pagination
  - [x] Implement `exportToLyraBundle(_:template:)` with JSON encoding
  - [x] Define `LyraBundleExport` Codable struct (backward-compatible with LyraBundle import struct)

- [x] Create `/Lyra/Views/ExportOptionsSheet.swift`
  - [x] Define `ExportOptionsSheet` SwiftUI view
  - [x] Add format picker (ChordPro, JSON, Plain Text)
  - [x] Add "Include Metadata" toggle
  - [x] Add "Include Notes" toggle
  - [x] Add custom filename support
  - [x] Add preview section
  - [x] Implement export handling with content filtering
  - [x] Add Cancel toolbar button

- [x] Modify `/Lyra/Views/SongDisplayView.swift`
  - [x] Add export button to toolbar (square.and.arrow.up icon)
  - [x] Add `@State private var showExportOptions: Bool` state
  - [x] Add `.sheet(isPresented: $showExportOptions)` with ExportOptionsSheet

- [x] Modify `/Lyra/Views/SongDetailView.swift`
  - [x] Add "Export Song" option to context menu
  - [x] Add sheet presentation for ExportOptionsSheet
  - [x] Add share sheet for exported files
  - [x] Implement `handleExport` method

### Testing - Phase 3A

- Export song as ChordPro → produces valid .txt file
- Export song as JSON → produces valid .json file with song data
- Export song as Plain Text → only lyrics, no chords
- Export handles songs with no content gracefully
- Export handles invalid templates gracefully
- Share sheet appears after successful export
- Error alerts show clear messages for failures

---

## Phase 3B: Import Lyra Bundles - ✅ COMPLETE

### Implementation Checklist

- [x] Add Lyra Bundle import to TemplateImporter
  - [x] Implement `importLyraBundle(url:context:)` method
  - [x] Parse JSON using JSONDecoder
  - [x] Extract LyraBundle struct
  - [x] Create Song from bundle content
  - [x] Create/reuse Template from bundle template
  - [x] Apply DisplaySettings from bundle
  - [x] Insert song into context
  - [x] Handle version compatibility

- [x] Add .lyra file import UI
  - [x] Add .lyra to file picker supported types
  - [x] Add "Import Lyra Bundle" option to library
  - [x] Show preview before importing
  - [x] Handle template name conflicts

> **Implementation Note:** Lyra Bundle import is fully implemented in `TemplateImporter.swift` with the `LyraBundle` and `TemplateData` structs for deserialization. The import UI in `TemplateImportView.swift` supports .lyra files as a selectable import format.

---

## Remaining Work

All planned phases (1-3) are now complete. The following items are future enhancements:

### Phase 4: Polish & Advanced Features (Future)
- Template marketplace
- Advanced column balancing algorithms
- Custom page breaks
- Template versioning

---

## Summary - All Phases

### Phase 1: Multi-Column Rendering + In-App Designer ✅ COMPLETE
- Template SwiftData model with column/typography/chord positioning settings
- TemplateManager for CRUD operations
- ColumnLayoutEngine for content distribution
- MultiColumnSongView for rendering
- TemplateEditorView for template creation/editing
- TemplateSelectionSheet for choosing templates
- Song-template relationship with global default fallback
- Built-in templates (1, 2, 3 columns)

### Phase 2: Template Import ✅ COMPLETE
- **2A (PDF Import)** ✅: Extract layout from PDF documents
  - Column detection algorithm
  - Typography extraction (font sizes)
  - Chord style detection (over/inline/separate)
  - TemplateImportView UI
  - TemplateLibraryView for management
  - Import metadata tracking (importSource, importedFromURL, importedAt on Template model)
  - SettingsView → TemplateLibraryView navigation
- **2B (Word Import)** ✅: Parse .docx XML for styles via DOCXXMLParser
- **2C (Plain Text Import)** ✅: Pattern detection in text files

### Phase 3: Export System ✅ COMPLETE
- **3A (Export Infrastructure)** ✅:
  - ChordPro export (universal compatibility) ✅
  - PDF export with template rendering (multi-column, ChordPro parsing, pagination) ✅
  - Plain text export (lyrics only) ✅
  - Lyra Bundle export (song + template round-trip) ✅
  - JSON export (structured song data) ✅
  - ExportOptionsSheet UI (5 format picker) ✅
  - Share sheet integration ✅
- **3B (Lyra Bundle Import)** ✅: Import from .lyra bundles fully working

### Phase 4: Polish & Advanced Features (Future)
- Template marketplace
- Advanced column balancing algorithms
- Custom page breaks
- Template versioning

---

## Files Summary

**Phase 2 New Files (3):**
1. `/Lyra/Utilities/TemplateImporter.swift` ✅
2. `/Lyra/Views/TemplateImportView.swift` ✅
3. `/Lyra/Views/TemplateLibraryView.swift` ✅

**Phase 3 New Files (2):**
4. `/Lyra/Utilities/SongExporter.swift` ✅
5. `/Lyra/Views/ExportOptionsSheet.swift` ✅

**Modified Files (4):**
1. `/Lyra/Models/Template.swift` - Import metadata ✅
2. `/Lyra/Views/SettingsView.swift` - Template library link ✅
3. `/Lyra/Views/SongDisplayView.swift` - Export button ✅
4. `/Lyra/Views/SongDetailView.swift` - Export menu ✅

**Test Files (14 template/export related):**
1. `LyraTests/TemplateTests.swift` ✅
2. `LyraTests/TemplateManagerTests.swift` ✅
3. `LyraTests/TemplateEditorViewTests.swift` ✅
4. `LyraTests/TemplateSelectionSheetTests.swift` ✅
5. `LyraTests/TemplateImporterTests.swift` ✅
6. `LyraTests/TemplateImportViewTests.swift` ✅
7. `LyraTests/TemplateLibraryViewTests.swift` ✅
8. `LyraTests/SongTemplateTests.swift` ✅
9. `LyraTests/SongDisplayViewTemplateTests.swift` ✅
10. `LyraTests/MultiColumnSongViewTests.swift` ✅
11. `LyraTests/ColumnLayoutEngineTests.swift` ✅
12. `LyraTests/SongExporterTests.swift` ✅
13. `LyraTests/ExportOptionsSheetTests.swift` ✅

---

## Architectural Trade-offs

### Decision: Separate Template Model
**Chosen**: Create new Template SwiftData model
**Rejected**: Extend DisplaySettings with column properties
**Rationale**: Clean separation of concerns, better scalability, supports template import/export/sharing

### Decision: Content Distribution Strategy
**Chosen**: Section-aware line-based with height balancing
**Rejected**: Simple line-by-line distribution
**Rationale**: Respects song structure (sections stay together), visual balance across columns

### Decision: Rendering Architecture
**Chosen**: Create new MultiColumnSongView, conditionally used
**Rejected**: Modify SongDisplayView directly
**Rationale**: Keeps SongDisplayView manageable (already 1500 lines), easier to test, can optimize separately

### Decision: MVP Scope
**Chosen**: Build in-app template designer first, defer document import to Phase 2
**Rejected**: Start with PDF/Word import
**Rationale**: Provides immediate value, full control, no complex parsing dependencies

### Decision: Storage Format
**Chosen**: Keep ChordPro as canonical format, template applied at render time
**Rejected**: Store rendered HTML or proprietary styled format
**Rationale**: Backward compatibility, can change templates without losing content, export to ChordPro always possible
