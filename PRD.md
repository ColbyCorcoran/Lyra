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

# Phase 2: Template Import System

## Overview

Enable users to import templates from existing documents (PDF, Word, Plain Text) to automatically extract layout characteristics and apply them to songs.

## Design Philosophy

**Approach**: Parse documents to extract structural and visual metadata, then map to Template model properties
**Priority**: PDF import (highest value) → Word import → Plain text import
**Validation**: All imported templates must pass `template.isValid` check before saving

---

## Phase 2A: PDF Template Import

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
  - [ ] Define `TemplateImporter` class with static import methods
  - [ ] Implement `importFromPDF(url:name:context:)` async method
  - [ ] Implement `analyzePDFLayout(_:)` to extract DocumentLayout
  - [ ] Implement `extractTextElements(from:)` using PDFPage API
  - [ ] Implement `detectColumnStructure(_:pageWidth:)` clustering algorithm
  - [ ] Implement `extractTypography(_:)` font size analysis
  - [ ] Implement `detectChordStyle(_:)` heuristic detection
  - [ ] Implement `mapToTemplate(layout:name:context:)` conversion
  - [ ] Define `DocumentLayout`, `TextElement`, `ColumnStructure`, `TypographyProfile` structs
  - [ ] Define `TemplateImportError` enum with localized descriptions

- [x] Create `/Lyra/Views/TemplateImportView.swift`
  - [ ] Define `TemplateImportView` SwiftUI view
  - [ ] Add template name TextField with validation
  - [ ] Add import format picker (PDF, Word, Plain Text)
  - [ ] Add document file picker button with fileImporter modifier
  - [ ] Implement `importTemplate()` async method
  - [ ] Add progress indicator during import
  - [ ] Add error alert for import failures
  - [ ] Add preview sheet to show imported template in TemplateEditorView
  - [ ] Add Cancel toolbar button

- [x] Create `/Lyra/Views/TemplateLibraryView.swift`
  - [ ] Define `TemplateLibraryView` with @Query for templates
  - [ ] Add search bar with searchable modifier
  - [ ] Add "Built-in Templates" section
  - [ ] Add "Custom Templates" section
  - [ ] Create `TemplateRowView` with template details
  - [ ] Add toolbar menu with "Create New" and "Import from Document" options
  - [ ] Add sheet presentations for import and editor views
  - [ ] Implement template selection and editing flow

- [ ] Modify `/Lyra/Models/Template.swift`
  - [ ] Add `importSource: ImportSource?` property
  - [ ] Add `importedFromURL: String?` property
  - [ ] Add `importedAt: Date?` property
  - [ ] Define `ImportSource` enum (pdf, word, plainText, inAppDesigner)

- [ ] Modify `/Lyra/Views/SettingsView.swift`
  - [ ] Add "Templates" section
  - [ ] Add NavigationLink to TemplateLibraryView
  - [ ] Add descriptive footer text

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

## Phase 2B: Word Import (Future Enhancement)

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

- [ ] Add `.docx` parsing to TemplateImporter
  - [ ] Implement `importFromWord(url:name:context:)` async method
  - [ ] Extract .docx ZIP archive
  - [ ] Parse `word/document.xml` with XMLParser
  - [ ] Parse `word/styles.xml` for font definitions
  - [ ] Extract column count from `<w:cols>` element
  - [ ] Extract font sizes from paragraph styles
  - [ ] Map Word styles to Template properties
  - [ ] Handle invalid/missing styles gracefully

---

## Phase 2C: Plain Text Import

### Implementation Strategy

**Approach**: Detect patterns in spacing and structure

**Detection Heuristics:**
- Multiple spaces (4+) may indicate columns
- Consistent vertical alignment suggests column structure
- Detect ChordPro markers `[chord]` for format detection

**Implementation Checklist:**

- [ ] Implement plain text import
  - [ ] Read file contents as String
  - [ ] Analyze whitespace patterns for column detection
  - [ ] Detect ChordPro format markers
  - [ ] Create sensible default template (likely single column)
  - [ ] Preserve detected format characteristics

---

# Phase 3: Export System

## Overview

Enable users to export songs in multiple formats while preserving template formatting or converting to portable formats.

## Export Formats

1. **ChordPro (.txt)** - Pure ChordPro format (strips template, universal compatibility)
2. **PDF** - Rendered with template applied (preserves visual formatting)
3. **Plain Text** - Lyrics only, no chords
4. **Lyra Bundle (.lyra)** - JSON bundle with content + template + settings

---

## Phase 3A: Export Infrastructure

### New Files to Create

#### 1. `/Lyra/Utilities/SongExporter.swift` (Priority: Critical)

**Export Engine with Format Support**

Features:
- `export(song:format:template:displaySettings:)` async method
- `exportChordPro(_:)` - Write song.content to .txt file
- `exportPDF(_:template:displaySettings:)` - Render to PDF with template applied
- `exportPlainText(_:)` - Extract lyrics only from ParsedSong
- `exportLyraBundle(_:template:displaySettings:)` - JSON bundle export
- `renderToPDF(song:template:displaySettings:)` - Use ImageRenderer for PDF generation

**PDF Generation Strategy:**
1. Use `ImageRenderer` to render MultiColumnSongView/SongDisplayView to image
2. Create PDF context with appropriate page size (US Letter: 612pt x 792pt)
3. Draw rendered image into PDF pages
4. Handle pagination for long songs

**Lyra Bundle Format:**
- JSON structure containing:
  - Song metadata (title, artist, key, tempo)
  - Song content (ChordPro text)
  - Template settings (if custom)
  - Display settings (if custom)
  - Version number for compatibility
  - Export timestamp

#### 2. `/Lyra/Views/ExportOptionsSheet.swift` (Priority: High)

**Export UI with Format Selection**

Features:
- Export format picker (PDF, ChordPro, Plain Text, Lyra Bundle)
- "Include Template Formatting" toggle (for PDF/Lyra Bundle)
- Format description footer text
- Progress indicator during export
- Error alerts for failures
- Share sheet to share exported file
- Cancel/Export buttons

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

- [ ] Create `/Lyra/Utilities/SongExporter.swift`
  - [ ] Define `SongExporter` class with static export method
  - [ ] Define `ExportFormat` enum (chordPro, pdf, plainText, lyraBundle)
  - [ ] Implement `export(song:format:template:displaySettings:)` async method
  - [ ] Implement `exportChordPro(_:)` - write song.content to file
  - [ ] Implement `exportPDF(_:template:displaySettings:)` with rendering
  - [ ] Implement `exportPlainText(_:)` - extract lyrics only from ParsedSong
  - [ ] Implement `exportLyraBundle(_:template:displaySettings:)` with JSON encoding
  - [ ] Implement `renderToPDF(song:template:displaySettings:)` using ImageRenderer
  - [ ] Define `LyraBundle` Codable struct
  - [ ] Define `TemplateCodable` struct with Template initializer
  - [ ] Define `ExportError` enum with localized descriptions
  - [ ] Handle file writing to temporary directory
  - [ ] Add proper cleanup of temporary files

- [ ] Create `/Lyra/Views/ExportOptionsSheet.swift`
  - [ ] Define `ExportOptionsSheet` SwiftUI view
  - [ ] Add format picker with 4 options
  - [ ] Add "Include Template Formatting" toggle for PDF/Lyra exports
  - [ ] Add format description footer text
  - [ ] Implement `performExport()` async method
  - [ ] Add progress indicator during export
  - [ ] Add error alert for export failures
  - [ ] Add share sheet to share exported file
  - [ ] Add Cancel toolbar button

- [ ] Modify `/Lyra/Views/SongDisplayView.swift`
  - [ ] Add export button to toolbar (square.and.arrow.up icon)
  - [ ] Add `@State private var showExportOptions: Bool` state
  - [ ] Add `.sheet(isPresented: $showExportOptions)` with ExportOptionsSheet

- [ ] Modify `/Lyra/Views/SongDetailView.swift` (if exists)
  - [ ] Add "Export Song" option to context menu
  - [ ] Add sheet presentation for ExportOptionsSheet

### Testing - Phase 3A

- Export song as ChordPro → produces valid .txt file
- Export song as PDF with template → PDF has correct column layout
- Export song as PDF with 2 columns → columns are balanced
- Export song as Plain Text → only lyrics, no chords
- Export song as Lyra Bundle → produces valid .lyra JSON file
- Exported Lyra Bundle can be re-imported (Phase 3B)
- Export handles songs with no content gracefully
- Export handles invalid templates gracefully
- Share sheet appears after successful export
- Error alerts show clear messages for failures

---

## Phase 3B: Import Lyra Bundles

### Implementation Checklist

- [ ] Add Lyra Bundle import to TemplateImporter
  - [ ] Implement `importLyraBundle(url:context:)` method
  - [ ] Parse JSON using JSONDecoder
  - [ ] Extract LyraBundle struct
  - [ ] Create Song from bundle content
  - [ ] Create/reuse Template from bundle template
  - [ ] Apply DisplaySettings from bundle
  - [ ] Insert song into context
  - [ ] Handle version compatibility

- [x] Add .lyra file import UI
  - [ ] Add .lyra to file picker supported types
  - [ ] Add "Import Lyra Bundle" option to library
  - [ ] Show preview before importing
  - [ ] Handle template name conflicts

---

## Summary - All Phases

### Phase 1: Multi-Column Rendering + In-App Designer ✅
- Template SwiftData model with column/typography/chord positioning settings
- TemplateManager for CRUD operations
- ColumnLayoutEngine for content distribution
- MultiColumnSongView for rendering
- TemplateEditorView for template creation/editing
- TemplateSelectionSheet for choosing templates
- Song-template relationship with global default fallback
- Built-in templates (1, 2, 3 columns)

### Phase 2: Template Import
- **2A (PDF Import)**: Extract layout from PDF documents
  - Column detection algorithm
  - Typography extraction (font sizes)
  - Chord style detection (over/inline/separate)
  - TemplateImportView UI
  - TemplateLibraryView for management
  - Import metadata tracking
- **2B (Word Import)**: Parse .docx XML for styles
- **2C (Plain Text Import)**: Pattern detection in text files

### Phase 3: Export System
- **3A (Export Infrastructure)**:
  - ChordPro export (universal compatibility)
  - PDF export with template rendering
  - Plain text export (lyrics only)
  - Lyra Bundle export (complete preservation)
  - ExportOptionsSheet UI
  - Share sheet integration
- **3B (Lyra Bundle Import)**: Round-trip import/export

### Phase 4: Polish & Advanced Features (Future)
- Template marketplace
- Advanced column balancing algorithms
- Custom page breaks
- Template versioning

---

## Files Summary

**Phase 2 New Files (5):**
1. `/Lyra/Utilities/TemplateImporter.swift`
2. `/Lyra/Views/TemplateImportView.swift`
3. `/Lyra/Views/TemplateLibraryView.swift`

**Phase 3 New Files (2):**
4. `/Lyra/Utilities/SongExporter.swift`
5. `/Lyra/Views/ExportOptionsSheet.swift`

**Modified Files (4):**
1. `/Lyra/Models/Template.swift` - Import metadata
2. `/Lyra/Views/SettingsView.swift` - Template library link
3. `/Lyra/Views/SongDisplayView.swift` - Export button
4. `/Lyra/Views/SongDetailView.swift` - Export menu

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
