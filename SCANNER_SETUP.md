# Camera Scanner Setup Guide

This guide explains how to set up and use the camera scanner feature in Lyra for digitizing paper chord charts.

## Prerequisites

1. iOS device with camera (iPhone or iPad)
2. iOS 13+ (for VNDocumentCameraViewController)
3. Camera permissions granted

## Required Info.plist Entries

Add the following to your `Info.plist` file (or in Xcode project settings under Info):

```xml
<key>NSCameraUsageDescription</key>
<string>Lyra needs camera access to scan paper chord charts and digitize them for your library.</string>
```

**In Xcode**:
1. Select your project in the navigator
2. Select your target
3. Go to the "Info" tab
4. Add new entry: `Privacy - Camera Usage Description`
5. Value: "Lyra needs camera access to scan paper chord charts and digitize them for your library."

## Features

### Document Scanner

- **Auto Edge Detection**: Automatically detects document edges
- **Perspective Correction**: Corrects perspective distortion
- **Multi-Page Scanning**: Scan multiple pages as one song
- **Review Before Save**: Review scanned pages before accepting

### OCR (Optical Character Recognition)

- **Vision Framework**: Uses Apple's Vision framework for text recognition
- **Accurate Recognition**: Uses `.accurate` recognition level
- **Music Terminology**: Custom word list for chord recognition
- **Quality Assessment**: Shows confidence level (Excellent, Good, Fair, Poor)
- **Text Editing**: Review and edit extracted text before saving
- **Format Conversion**: Automatically converts to ChordPro format

### PDF Creation

- **Multi-Page PDF**: All scanned pages saved as single PDF
- **Letter Size**: Standard 8.5" x 11" at 72 DPI
- **Aspect Fit**: Images scaled to fit page while maintaining aspect ratio
- **Metadata**: Includes creator and author information

## Usage Flow

### 1. Start Scanning

From the Library view:
1. Tap **Import** button in toolbar
2. Select **Scan Paper Chart**
3. Grant camera permission if prompted
4. Document scanner opens

### 2. Scan Pages

In the scanner:
1. Point camera at chord chart
2. Wait for auto edge detection (yellow border)
3. Tap capture button or wait for auto-capture
4. Review the scan:
   - Tap "Retake" to scan again
   - Tap "Keep Scan" to accept
5. Add more pages if needed
6. Tap "Save" when done

### 3. Post-Scan Processing

After scanning:

**Option A: Extract Text with OCR**
1. Tap "Extract Text with OCR"
2. Wait for processing (shows progress)
3. Review extracted text
4. Edit if needed (chords, lyrics, formatting)
5. Tap "Save" to create song

**Option B: Save as PDF Only**
1. Tap "Save as PDF Only"
2. Song created with PDF attachment
3. No text extraction performed

### 4. Review Result

After saving:
- Song appears in library
- PDF viewable via attachment
- Text searchable (if OCR was used)
- Can edit metadata (title, artist, key)

## OCR Quality Indicators

The scanner shows OCR quality with confidence levels:

| Quality | Confidence | Icon | Recommendation |
|---------|-----------|------|----------------|
| Excellent | 90%+ | ✓ Green | Ready to use |
| Good | 70-89% | ✓ Blue | Minor review recommended |
| Fair | 50-69% | ⚠️ Orange | Review recommended |
| Poor | <50% | ✗ Red | Manual review required |

### Improving OCR Quality

**Lighting**:
- Use bright, even lighting
- Avoid shadows and glare
- Natural light works best

**Document Quality**:
- Clean, unwrinkled pages
- Clear, printed text (not faded)
- High contrast (black text on white)

**Camera Technique**:
- Hold steady or use tripod
- Frame entire page
- Let scanner auto-detect edges
- Ensure good focus

**Content**:
- Printed charts work better than handwritten
- Clear chord notation
- Good spacing between lyrics

## Technical Details

### OCR Pre-Processing

1. **Grayscale Conversion**: Converts to grayscale for better recognition
2. **Contrast Enhancement**: Improves text visibility
3. **Edge Detection**: Auto-crops to document bounds

### Vision Framework Configuration

```swift
request.recognitionLevel = .accurate  // High accuracy mode
request.recognitionLanguages = ["en-US"]  // English
request.usesLanguageCorrection = false  // Don't change chord names
```

### Custom Music Terminology

The scanner includes custom words for better chord recognition:

**Chords**: Cmaj7, Dm7, Esus4, Fadd9, Gdim, Aaug, etc.
**Sections**: Chorus, Verse, Bridge, Intro, Outro, Pre-Chorus
**Terms**: Capo, Key, Tempo, Time Signature, BPM

### PDF Specifications

- **Format**: PDF/A standard
- **Page Size**: 8.5" x 11" (612 x 792 points)
- **Resolution**: Maintains original scan quality
- **Compression**: Automatic compression for file size
- **Metadata**: Creator: "Lyra", Author: "Scanned by Lyra"

## Multi-Page Handling

### Scanning Multiple Pages

1. Scan first page as normal
2. Tap "+ Add Page" in scanner
3. Scan additional pages
4. Review all pages in thumbnails
5. Tap "Save" when done

### Multi-Page Result

- **Combined PDF**: All pages in single PDF
- **Combined Text**: Text from all pages merged
- **Page Breaks**: `--- Page Break ---` markers in text
- **Navigation**: Page selector in PDF viewer

## Error Handling

### Camera Permission Denied

**Symptom**: "Camera Access Required" screen appears

**Solution**:
1. Tap "Open Settings"
2. Find Lyra in app list
3. Enable "Camera" permission
4. Return to Lyra and try again

### Poor OCR Results

**Symptom**: Low confidence, garbled text, missing chords

**Solutions**:
1. Rescan with better lighting
2. Use "Save as PDF Only" instead
3. Manually enter text after saving
4. Edit extracted text before saving

### Scanner Won't Detect Edges

**Symptom**: No yellow border appears, can't capture

**Solutions**:
1. Ensure good contrast (dark chart on light background)
2. Try manual capture (tap capture button)
3. Adjust lighting
4. Flatten paper (remove wrinkles)
5. Try different angle

### Scan Quality Issues

**Symptom**: Blurry scans, poor image quality

**Solutions**:
1. Hold camera steady
2. Ensure good focus (tap to focus)
3. Use auto-capture instead of manual
4. Clean camera lens
5. Improve lighting

## Best Practices

### Before Scanning

- [ ] Clean and flatten pages
- [ ] Ensure good lighting
- [ ] Remove staples/bindings if needed
- [ ] Close other apps for better performance

### During Scanning

- [ ] Use auto edge detection
- [ ] Let scanner stabilize before capturing
- [ ] Review each scan before continuing
- [ ] Scan multiple pages in one session

### After Scanning

- [ ] Review OCR quality indicator
- [ ] Edit text if confidence is low
- [ ] Add metadata (artist, key, etc.)
- [ ] Test song display and chords

## Troubleshooting

### "Scanner Not Available"

**Cause**: Device doesn't support VNDocumentCameraViewController

**Solution**:
- Requires iOS 13+
- Use file import instead
- Use external scanner app and import PDF

### Memory Issues with Large Scans

**Symptom**: App crashes or hangs with many pages

**Solution**:
- Limit to 10 pages per session
- Break into multiple songs
- Reduce image quality if possible

### OCR Hangs or Takes Too Long

**Symptom**: Processing stuck at certain percentage

**Solution**:
- Force quit and try again
- Use "Save as PDF Only" instead
- Report issue with scan details

### Text Formatting Issues

**Symptom**: Chords in wrong positions, broken layout

**Solution**:
- Use text editor to fix formatting
- Apply FormatConverter manually
- Import as plain text and edit

## Performance Considerations

### Memory Usage

- Each scan page: ~2-5 MB
- OCR processing: Additional 10-20 MB
- PDF creation: Compressed to ~500 KB per page

### Processing Time

- Single page OCR: 2-5 seconds
- Multi-page OCR: 2-5 seconds per page
- PDF creation: <1 second

### Storage

- PDF only: ~500 KB per page
- PDF + OCR text: ~500 KB + text size
- Recommended: Regular cleanup of old scans

## Advanced Features

### Batch Scanning

For scanning entire songbooks:

1. Scan first song (all pages)
2. Complete and save
3. Immediately start new scan
4. Repeat for each song
5. Use bulk operations later to organize

### Integration with Bulk Import

Scanned songs work with all bulk import features:
- Duplicate detection (title/content matching)
- Quick organize (add to book/set)
- Error handling and retry

### Format Conversion

Scanned text automatically processed through FormatConverter:
- Detects chord patterns
- Converts to ChordPro format
- Preserves structure when possible

## Limitations

### Current Limitations

- **iOS 13+ Required**: VNDocumentCameraViewController not available on older iOS
- **Camera Required**: Doesn't work on devices without camera
- **OCR Accuracy**: Varies with source quality (70-95% typical)
- **Handwritten Charts**: OCR less accurate with handwriting
- **Non-English**: Optimized for English language
- **Complex Layouts**: Tables and columns may not convert well

### Not Supported

- Batch scanning (must scan one song at a time)
- Automatic orientation detection
- Color preservation (converts to grayscale)
- Background scanning
- Cloud sync during scan

## Future Enhancements

Planned improvements:
- [ ] Batch scanning workflow
- [ ] Enhanced chord detection
- [ ] Automatic section detection
- [ ] Cloud storage for scans
- [ ] Share scan before import
- [ ] Export scan as image
- [ ] Multiple language support
- [ ] Handwriting recognition tuning

## Privacy & Security

### Camera Access

- Used only for scanning documents
- No photos stored outside scans
- No cloud upload without permission
- Full control over scanned data

### Data Storage

- Scans stored locally on device
- Encrypted with device encryption
- Deleted when song is deleted
- No external access

## Testing Checklist

Before using in production, test:

- [ ] Single page scan with good lighting
- [ ] Multi-page scan (3+ pages)
- [ ] OCR with printed chart
- [ ] OCR with handwritten chart
- [ ] Poor lighting conditions
- [ ] Wrinkled/damaged page
- [ ] Permission denial flow
- [ ] Scanner cancellation
- [ ] Edit extracted text
- [ ] Save PDF only
- [ ] View scanned PDF
- [ ] Search scanned text
- [ ] Delete scanned song

## Support

For scanner issues:

1. Check this guide for solutions
2. Review error messages carefully
3. Try alternative import methods
4. Report persistent issues with:
   - Device model and iOS version
   - Scanner settings used
   - OCR quality indicator
   - Sample scan (if possible)

## Examples

### Example 1: Single Page Chart

```
1. Tap Import > Scan Paper Chart
2. Scanner opens
3. Point at printed chord chart
4. Wait for yellow border
5. Tap capture or wait for auto
6. Review scan, tap "Keep Scan"
7. Tap "Save"
8. Tap "Extract Text with OCR"
9. Wait for processing (3 seconds)
10. Review text (95% confidence - Excellent)
11. Tap "Save"
12. Song appears in library
```

### Example 2: Multi-Page Songbook

```
1. Open to first song in songbook
2. Tap Import > Scan Paper Chart
3. Scan first page
4. Tap "+ Add Page"
5. Turn page, scan second page
6. Repeat for all pages of song
7. Review all thumbnails
8. Tap "Save"
9. Tap "Extract Text with OCR"
10. Edit combined text if needed
11. Tap "Save"
12. Repeat for next song
```

### Example 3: Poor Quality Original

```
1. Scan faded/old chart
2. OCR shows "Fair" quality (65% confidence)
3. Review extracted text
4. Fix obvious errors (wrong chords, etc.)
5. Save with edited text
6. PDF attachment preserves original
7. Can re-run OCR later if needed
```

---

**Note**: The scanner feature requires iOS 13+ and a device with a camera. Make sure camera permissions are granted in Settings > Privacy > Camera > Lyra.
