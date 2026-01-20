# Attachments Guide

This guide explains how to manage multiple versions and arrangements of chord charts using Lyra's attachment system.

## Overview

Lyra's attachment system allows you to keep multiple versions of the same song - original charts, transposed versions, simplified arrangements, lead sheets, and more. Each song can have unlimited attachments with metadata, version names, and notes.

## Key Features

- **Multiple versions per song**: Keep original, transposed, simplified versions
- **Version naming**: Label each attachment ("Original", "Transposed to C", "With Capo 2")
- **Default attachment**: Mark one as primary for quick access
- **Multiple sources**: Import from Files, Camera, Photos, Dropbox, Google Drive
- **File types**: PDF, images (JPG, PNG, HEIC), audio (future support)
- **Storage management**: Monitor storage, compress large PDFs, cleanup orphaned files
- **Metadata**: Notes field to describe each version
- **Quick switching**: Easily switch between versions during practice

## Viewing Attachments

### From Song Detail View

1. Open any song
2. Scroll to the **Attachments** section
3. See preview of first 3 attachments
4. Tap **View All** to see complete list

### Attachments List

The attachments list shows:
- File icon with color coding:
  - **PDF**: Red document icon
  - **Images**: Blue photo icon
  - **Audio**: Purple waveform icon
- Display name (version name or filename)
- **★** badge for default attachment
- File size
- Source indicator (Files, Dropbox, Camera, etc.)
- Version name badge (if set)

## Adding Attachments

### Add from Files

1. Open song → **View All** attachments
2. Tap **+** button
3. Choose **Files**
4. Select PDF or image
5. Enter version name (optional)
   - Examples: "Original", "Transposed to C", "Simplified"
6. Tap **Save**

### Add from Camera

1. Open song → **View All** attachments
2. Tap **+** button
3. Choose **Camera**
4. Grant camera permission (if first time)
5. Scan document or take photo
6. Review scan quality
7. Enter version name
8. Tap **Save**

Creates PDF from scanned images automatically.

### Add from Photos

1. Open song → **View All** attachments
2. Tap **+** button
3. Choose **Photos**
4. Select image from library
5. Enter version name
6. Tap **Save**

### Add from Cloud (Dropbox/Drive)

1. Open song → **View All** attachments
2. Tap **+** button
3. Choose **Dropbox** or **Google Drive**
4. Authenticate if needed
5. Browse and select file
6. Enter version name
7. Tap **Save**

## Managing Attachments

### View Attachment

- **Tap** any attachment to view in Quick Look
- Swipe through pages (PDFs)
- Pinch to zoom
- Share from Quick Look

### Set as Default

The default attachment is shown first and used for quick access:

**Method 1: Swipe**
1. Swipe attachment from left to right
2. Tap **Set Default** (yellow star icon)

**Method 2: Details**
1. Tap attachment → swipe for **Details**
2. Toggle **Default Attachment** switch

**Method 3: Context Menu**
1. Long-press attachment
2. Tap **Set as Default**

### Rename Attachment

1. Swipe attachment → **Details**
2. Scroll to **Actions**
3. Tap **Rename**
4. Enter new filename
5. Tap **Save**

### Update Version Name

Version names help identify different arrangements:

1. Swipe attachment → **Details**
2. Tap **Version Name** row
3. Enter descriptive name:
   - "Original"
   - "Transposed to C"
   - "Simplified Version"
   - "With Capo 2"
   - "Lead Sheet"
   - "Chord Sheet Only"
4. Tap **Save**

### Add Notes

Notes describe what makes this version different:

1. Swipe attachment → **Details**
2. Tap **Notes** row
3. Enter notes:
   - "Use this version for Sunday morning"
   - "Simplified for beginners"
   - "Original arrangement from worship leader"
   - "Transposed for our singer's range"
4. Tap **Save**

### Replace File

Keep the same metadata but update the file:

1. Swipe attachment → **Details**
2. Tap **Replace File**
3. Select new file
4. File content updated, metadata preserved

Useful for:
- Updating a chart while keeping version name/notes
- Fixing errors in an existing version
- Replacing a scan with better quality

### Duplicate Attachment

Create a copy to create a new version:

1. Long-press attachment
2. Tap **Duplicate**
3. Creates "Copy of [name]"
4. Edit the copy as needed

Workflow for creating variations:
1. Import original chart
2. Duplicate it
3. Rename duplicate to "Transposed to D"
4. Replace file with transposed version

### Delete Attachment

**Method 1: Swipe**
1. Swipe attachment from right to left
2. Tap **Delete** (red)
3. Confirm deletion

**Method 2: Details**
1. Swipe attachment → **Details**
2. Scroll to **Danger Zone**
3. Tap **Delete Attachment**
4. Confirm deletion

**Note**: Deletion is permanent. The file is removed from storage.

## Version Control

### Organizing Multiple Versions

Best practices for managing multiple arrangements:

1. **Name consistently**:
   - "Original" for source material
   - "Transposed to [Key]" for key changes
   - "Simplified" for easier arrangements
   - "Advanced" for complex versions
   - "Capo [Number]" for capo variations

2. **Set default wisely**:
   - Mark most-used version as default
   - Default shows first in list
   - Easy to switch when needed

3. **Add context in notes**:
   - When to use this version
   - Who it's for (beginners, advanced)
   - Special instructions (capo placement, etc.)

### Quick Switching Workflow

During practice or performance:

1. Open song
2. View attachments (3-tap workflow)
3. See all versions at a glance
4. Tap to open different version
5. Switch versions as needed

### Example: Managing Transpositions

Song: "Amazing Grace"

1. Import original chart (Key of G)
   - Filename: "Amazing Grace.pdf"
   - Version: "Original - Key of G"
   - Set as default
   - Notes: "Original arrangement"

2. Add transposed version
   - Duplicate original
   - Replace with transposed file
   - Version: "Transposed to C"
   - Notes: "Transposed for our vocalist"

3. Add simplified version
   - Import simplified chart
   - Version: "Simplified"
   - Notes: "Easier chords for beginners"

4. Add capo version
   - Duplicate original
   - Version: "Capo 2"
   - Notes: "Play in G with capo on 2nd fret"

Result: 4 versions, easy to switch between

## Storage Management

### View Storage Statistics

1. Go to **Settings**
2. Tap **Attachment Storage**

Statistics shown:
- **Total Storage**: All attachments combined
- **Total Attachments**: Number of files
- **Songs with Attachments**: Songs that have files
- **Average Size**: Typical file size
- **Inline vs File Storage**: Storage method breakdown
- **Largest Attachment**: Biggest single file
- **Top Storage Users**: Songs using most storage

### Storage Methods

**Inline Storage** (< 500KB):
- Stored in SwiftData database
- Faster access
- Good for small files
- Included in database backups

**File Storage** (> 500KB):
- Stored in Documents folder
- Better for large files
- Doesn't bloat database
- Separate file management

Automatically determined based on file size.

### Compress PDFs

Large PDFs can be compressed to save space:

**Compress Single PDF**:
1. Open attachment details
2. Tap **Compress PDF** (if > 1MB)
3. Choose quality:
   - Low (50%): Smallest size
   - Medium (70%): Balanced
   - High (85%): Best quality
4. Compression happens
5. Shows bytes saved

**Compress All PDFs**:
1. Settings → **Attachment Storage**
2. See **Compressible PDFs** size
3. Tap **Compress All Large PDFs**
4. Uses medium quality (70%)
5. Shows progress
6. Reports total savings

### Clean Up Orphaned Files

Orphaned files = files in storage folder but not in database.

Can happen after:
- App crashes during delete
- Incomplete import operations
- Database restore

To clean up:
1. Settings → **Attachment Storage**
2. Tap **Clean Up Orphaned Files**
3. Confirms count of files
4. Deletes unused files
5. Reports files deleted

Safe operation - only removes unreferenced files.

## Supported File Types

### PDF Documents

- **Extension**: .pdf
- **Best for**: Chord charts, sheet music, lead sheets
- **Features**: Multi-page support, compression available
- **Viewing**: Full Quick Look support with zoom/scroll

### Images

- **Extensions**: .jpg, .jpeg, .png, .heic, .gif
- **Best for**: Photos of charts, scanned pages
- **Features**: Can be combined into PDFs via camera scan
- **Viewing**: Pinch to zoom, pan

### Audio (Future)

- **Extensions**: .mp3, .m4a, .wav, .aac
- **Best for**: Reference recordings, backing tracks
- **Status**: File type supported, playback UI coming soon

## Use Cases

### 1. Multiple Key Signatures

**Scenario**: Song used in different services with different vocalists

**Solution**:
- Original in G
- Transposed to A (Version: "Capo 2" or "Key of A")
- Transposed to C (Version: "Easy Keys")
- Set default based on primary use
- Switch versions per service

### 2. Skill Levels

**Scenario**: Teaching song to band with varying skill levels

**Solution**:
- Original arrangement (Version: "Full Arrangement")
- Simplified chords (Version: "Simplified")
- Lead sheet only (Version: "Lead Sheet")
- Chord chart only (Version: "Chords Only")

### 3. Different Arrangements

**Scenario**: Song has multiple published versions

**Solution**:
- Original recording version
- Simplified worship version
- Acoustic arrangement
- Electric arrangement
- Notes field explains each use case

### 4. Progressive Learning

**Scenario**: Learning complex song gradually

**Solution**:
- Week 1: Simplified version (default during learning)
- Week 2: Intermediate version
- Week 3: Full version
- Week 4: Advanced version
- Change default as you progress

### 5. Team Collaboration

**Scenario**: Different team members need different charts

**Solution**:
- Lead sheet for vocalist
- Chord chart for rhythm guitar
- Tab arrangement for lead guitar
- Bass chart for bassist
- Drum chart for drummer
- Share specific versions with specific people

## Best Practices

### Organization

1. **Use version names consistently**
   - Makes finding versions easier
   - Helps team understand options
   - Professional appearance

2. **Add notes for context**
   - When to use each version
   - Differences from other versions
   - Special instructions

3. **Set logical defaults**
   - Most-used version = default
   - Update default as needed
   - Mark clearly with star

4. **Regular cleanup**
   - Delete unused versions
   - Compress large PDFs
   - Run orphan cleanup monthly

### File Management

1. **Name files descriptively before import**
   - "Amazing Grace - Original.pdf"
   - "Amazing Grace - Key of C.pdf"
   - Easier to identify later

2. **Use version names, not just filenames**
   - Version names show prominently
   - Filenames shown in details
   - Version names = user-facing

3. **Keep file sizes reasonable**
   - Compress large PDFs
   - Don't store ultra-high-res images
   - Balance quality vs size

### Workflow Efficiency

1. **Import all versions at once**
   - Get everything in one session
   - Name/tag immediately
   - Set default before you forget

2. **Duplicate then modify**
   - Faster than re-importing
   - Preserves metadata structure
   - Just update what changed

3. **Use camera scanning wisely**
   - Great for paper charts
   - Scan multiple pages as one PDF
   - Add version name immediately

## Troubleshooting

### Can't Open Attachment

**Symptom**: Tap attachment, nothing happens

**Solutions**:
1. Check file still exists in storage
2. Run **Clean Up Orphaned Files**
3. Try viewing from Details → View Attachment
4. Check available storage space
5. Restart app if needed

### Attachment Not Showing

**Symptom**: Attachment in database but not in list

**Solutions**:
1. Pull to refresh list
2. Check it's not filtered out
3. Verify song relationship intact
4. Check attachment wasn't accidentally deleted

### Storage Full

**Symptom**: Can't add more attachments

**Solutions**:
1. Check storage statistics
2. Compress large PDFs
3. Delete unused versions
4. Clean up orphaned files
5. Export/backup then delete old songs

### Compression Doesn't Help

**Symptom**: PDF compression saves minimal space

**Solutions**:
1. File may already be optimized
2. Try lower quality setting
3. Some PDFs don't compress well
4. Consider if compression is needed

### Lost Default After Update

**Symptom**: No default attachment marked

**Solutions**:
1. Open attachments list
2. Swipe desired attachment
3. Tap **Set Default**
4. Default restored

## Performance Considerations

### File Size Guidelines

- **Optimal**: < 5MB per file
- **Acceptable**: 5-20MB
- **Large**: 20-50MB (compress if possible)
- **Very Large**: > 50MB (consider splitting)

### Attachment Count Per Song

- **Light use**: 1-3 attachments
- **Moderate use**: 4-8 attachments
- **Heavy use**: 9-15 attachments
- **Maximum**: Unlimited, but consider organization

### Total Library Size

- **Small library**: < 100MB
- **Medium library**: 100MB - 1GB
- **Large library**: 1-5GB
- **Very large**: > 5GB (monitor closely)

### Storage Impact

Each attachment uses:
- File size (actual PDF/image)
- Database overhead (< 1KB per attachment)
- Metadata (negligible)

Example song with 5 PDFs @ 3MB each = ~15MB

## Integration with Other Features

### Export

When exporting songs:
- Exports export the chord chart content
- Attachments are not included in exports
- To share attachments, use Quick Look share

### Sets

Performance sets reference songs:
- Songs in sets keep their attachments
- Set override settings don't affect attachments
- View attachments from set → song → attachments

### Books

Books contain songs:
- Songs in books keep their attachments
- Book organization doesn't affect attachments
- All versions remain accessible

### Import

When importing songs:
- Import creates song + content
- Add attachments separately
- Bulk import doesn't include attachments

## Advanced Features

### Metadata Fields

Full metadata tracked:
- **Created Date**: When attachment was added
- **Modified Date**: Last change to attachment or metadata
- **Filename**: Original or renamed filename
- **File Type**: Extension (pdf, jpg, etc.)
- **File Size**: Bytes, formatted for display
- **Version Name**: User-assigned version label
- **Notes**: User notes about this version
- **Original Source**: Where file came from
- **Is Default**: Boolean flag for default status
- **Cloud File ID**: For cloud-synced files (future)
- **Cloud Modified Date**: Last cloud modification (future)

### Storage Locations

Files stored in:
```
~/Documents/Attachments/
  ├── [UUID]_filename1.pdf
  ├── [UUID]_filename2.pdf
  └── ...
```

Small files (< 500KB) stored inline in SwiftData database.

### File Naming Convention

External files use format:
```
[UUID]_[Original Filename]
```

Example:
```
123e4567-e89b-12d3-a456-426614174000_Amazing Grace.pdf
```

Ensures unique filenames, prevents conflicts.

## Security & Privacy

### Data Storage

- **Local only**: All attachments stored on device
- **No cloud sync**: Not synced unless you use iCloud Drive
- **Private**: No external access
- **Secure**: iOS sandboxing protects files

### Sharing

When sharing attachments:
- Temporary copy created
- Shared via system share sheet
- Original remains protected
- You control all sharing

### Permissions

Required permissions:
- **Camera**: For document scanning (optional)
- **Photos**: For photo library access (optional)
- **Files**: For file import (granted by file picker)

No permissions needed for basic attachment viewing.

## Frequently Asked Questions

### How many attachments can one song have?

Unlimited. However, for organization and performance, keeping it under 15 attachments per song is recommended.

### Can I have the same file attached to multiple songs?

Yes, but each attachment is a separate copy. Changes to one don't affect the other.

### What happens to attachments when I delete a song?

Attachments are deleted with the song. The files are removed from storage.

### Can I export songs with their attachments?

Song exports contain chord chart content only. To share attachments, use the share feature from Quick Look or attach manually.

### Do attachments sync across devices?

Not automatically. If you use iCloud for the app's Documents folder, attachments will sync. Otherwise, they're device-local.

### Can I attach audio files?

The file type is supported, but playback UI is coming in a future update. You can attach audio files now and view metadata.

### How do I back up my attachments?

Use Settings → Export Library to create a ZIP with all content, or use iCloud/iTunes backup for your device.

### Can I password-protect attachments?

Not within Lyra. Use iOS file encryption or encrypted PDF files if protection is needed.

### What's the difference between version name and filename?

- **Filename**: Actual file name, shown in details
- **Version Name**: User-friendly label, shown prominently
- Use version names for display, filenames for file management

### Can I reorder attachments?

Attachments are sorted with default first, then by creation date (newest first). You can't manually reorder, but you can set default.

### How do I find which songs have attachments?

Settings → Attachment Storage shows "Songs with Attachments" count and top storage users.

### Can I batch-add attachments to multiple songs?

Not currently. Attachments are added per-song. However, you can use bulk import for songs, then add attachments individually.

## Support

For attachment-related issues:

1. Check this guide for solutions
2. Verify storage space available
3. Run cleanup operations (compress, orphan cleanup)
4. Check file formats are supported
5. Restart app if issues persist
6. Report persistent issues with:
   - File type and size
   - Source (Files, Camera, etc.)
   - Error message
   - Device model and iOS version

---

**Note**: Attachment features require iOS 15+ for full functionality. Some features (document scanning) require iOS 16+.
