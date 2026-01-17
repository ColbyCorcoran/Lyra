# Lyra Phase 1 - Production Implementation Guide

## Overview

This guide provides specific implementation steps to make Lyra production-ready. Each section includes code examples and priority levels.

---

## Priority 1: Critical Improvements (Must Implement)

### 1.1 Add Haptic Feedback Throughout App

**Status:** ✅ HapticManager created
**Remaining:** Add to all interactive elements

#### AddSongView - Save Button
```swift
// In AddSongView.swift, saveSong() function
private func saveSong() {
    let chordProContent = createChordProContent()

    let newSong = Song(
        title: title,
        artist: artist.isEmpty ? nil : artist,
        content: chordProContent,
        originalKey: selectedKey
    )

    // ... set other properties ...

    modelContext.insert(newSong)

    do {
        try modelContext.save()
        HapticManager.shared.saveSuccess()  // ADD THIS
        dismiss()
    } catch {
        print("Error saving song: \(error)")
        HapticManager.shared.operationFailed()  // ADD THIS
    }
}
```

#### LibraryView - Import Success
```swift
// In LibraryView.swift, importFile() function
if result.hadParsingWarnings {
    HapticManager.shared.warning()  // ADD THIS
    showError(...)
} else {
    HapticManager.shared.success()  // ADD THIS
    showImportSuccess = true
}
```

#### LibraryView - Paste Success
```swift
// In LibraryView.swift, handlePaste() function
let result = try ClipboardManager.shared.pasteSongFromClipboard(to: modelContext)
pastedSong = result.song

HapticManager.shared.success()  // ADD THIS

pasteToastMessage = ...
```

#### DisplaySettingsSheet - Color Selection
```swift
// In DisplaySettingsSheet.swift, ColorSwatch action
Button(action: {
    HapticManager.shared.selection()  // ADD THIS
    action()
}) { ... }
```

#### SongListView - Delete Action
```swift
// In SongListView.swift, swipe action
Button(role: .destructive) {
    HapticManager.shared.swipeAction()  // ADD THIS
    deleteSong(song)
} label: {
    Label("Delete", systemImage: "trash")
}
```

---

### 1.2 Fix Error Handling - Remove Silent Failures

**Issue:** Many places use `try?` which swallows errors

#### SongDisplayView - Track Song View
```swift
// BEFORE (INCORRECT):
private func trackSongView() {
    song.lastViewed = Date()
    song.timesViewed += 1

    // Save to SwiftData
    do {
        try modelContext.save()
    } catch {
        print("Error tracking song view: \(error)")
    }
}

// AFTER (CORRECT):
private func trackSongView() {
    song.lastViewed = Date()
    song.timesViewed += 1

    do {
        try modelContext.save()
    } catch {
        // Log error but don't show to user (tracking is non-critical)
        print("⚠️ Error tracking song view: \(error.localizedDescription)")
        // Could add analytics/logging here
    }
}
```

#### Song Model - Display Settings Helpers
```swift
// In Song.swift
var displaySettings: DisplaySettings {
    get {
        if let data = displaySettingsData,
           let settings = try? JSONDecoder().decode(DisplaySettings.self, from: data) {
            return settings
        }
        return UserDefaults.standard.globalDisplaySettings
    }
    set {
        do {
            displaySettingsData = try JSONEncoder().encode(newValue)
        } catch {
            print("⚠️ Error encoding display settings: \(error.localizedDescription)")
            // Fall back to not saving (use global defaults)
            displaySettingsData = nil
        }
    }
}
```

#### Display Settings Sheet - Save Settings
```swift
// In DisplaySettingsSheet.swift
private func saveSettings() {
    song.displaySettings = settings

    do {
        try modelContext.save()
    } catch {
        // Show error to user since this is a user-initiated save
        print("❌ Error saving display settings: \(error.localizedDescription)")

        // TODO: Add error alert state
        // errorMessage = "Unable to save display settings"
        // showErrorAlert = true
    }
}
```

---

### 1.3 Add Loading States

#### ImportManager - Add Progress Callback
```swift
// In ImportManager.swift, add callback parameter
func importFile(
    from url: URL,
    to modelContext: ModelContext,
    progress: ((Double) -> Void)? = nil
) throws -> ImportResult {
    progress?(0.1)  // Starting

    guard url.startAccessingSecurityScopedResource() else {
        throw ImportError.fileNotReadable
    }
    defer { url.stopAccessingSecurityScopedResource() }

    progress?(0.3)  // File accessed

    // Read file contents
    let content: String
    do {
        content = try String(contentsOf: url, encoding: .utf8)
    } catch {
        // ... encoding fallback ...
    }

    progress?(0.5)  // File read

    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw ImportError.emptyContent
    }

    progress?(0.7)  // Parsing

    let parsed = ChordProParser.parse(content)

    progress?(0.9)  // Creating song

    // ... rest of import ...

    progress?(1.0)  // Complete

    return ImportResult(...)
}
```

#### LibraryView - Show Import Progress
```swift
// In LibraryView.swift, add state
@State private var importProgress: Double = 0.0
@State private var isImporting: Bool = false

private func importFile(from url: URL) {
    isImporting = true
    importProgress = 0.0

    do {
        let result = try ImportManager.shared.importFile(
            from: url,
            to: modelContext,
            progress: { progress in
                importProgress = progress
            }
        )

        importedSong = result.song
        isImporting = false

        if result.hadParsingWarnings {
            HapticManager.shared.warning()
            showError(...)
        } else {
            HapticManager.shared.success()
            showImportSuccess = true
        }

    } catch let error as ImportError {
        isImporting = false
        failedImportURL = url
        HapticManager.shared.operationFailed()
        showError(...)
    } catch {
        isImporting = false
        HapticManager.shared.operationFailed()
        showError(...)
    }
}

// Add overlay
.overlay {
    if isImporting {
        ZStack {
            Color.black.opacity(0.3)
            VStack(spacing: 16) {
                ProgressView(value: importProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                Text("Importing...")
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 8)
            )
        }
        .ignoresSafeArea()
    }
}
```

#### SongDisplayView - Async Parsing
```swift
// In SongDisplayView.swift
@State private var isLoadingSong: Bool = false

private func parseSong() {
    isLoadingSong = true

    Task {
        let parsed = await Task.detached(priority: .userInitiated) {
            return ChordProParser.parse(song.content)
        }.value

        await MainActor.run {
            parsedSong = parsed
            isLoadingSong = false
        }
    }
}

// Show loading state
var body: some View {
    VStack(spacing: 0) {
        if isLoadingSong {
            VStack {
                ProgressView()
                Text("Loading song...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // ... existing content ...
        }
    }
}
```

---

## Priority 2: Important Improvements

### 2.1 Accessibility - VoiceOver Labels

#### SongListView - Enhanced Row Labels
```swift
// In SongListView.swift, EnhancedSongRowView
NavigationLink(destination: SongDisplayView(song: song)) {
    EnhancedSongRowView(song: song)
}
.accessibilityElement(children: .combine)
.accessibilityLabel(makeAccessibilityLabel(for: song))
.accessibilityHint("Double tap to view song")

// Helper function
private func makeAccessibilityLabel(for song: Song) -> String {
    var parts: [String] = [song.title]

    if let artist = song.artist {
        parts.append("by \(artist)")
    }

    if let key = song.originalKey {
        parts.append("in key of \(key)")
    }

    if let capo = song.capo, capo > 0 {
        parts.append("capo \(capo)")
    }

    return parts.joined(separator: ", ")
}
```

#### DisplaySettingsSheet - Slider Labels
```swift
// In DisplaySettingsSheet.swift
Slider(value: $settings.fontSize, in: 12...28, step: 1)
    .accessibilityLabel("Font size")
    .accessibilityValue("\(Int(settings.fontSize)) points")
    .onChange(of: settings.fontSize) { _, _ in
        hasChanges = true
    }
```

#### Toolbar Buttons - Better Labels
```swift
// In SongDisplayView.swift
ToolbarItem(placement: .topBarLeading) {
    Button {
        // TODO: Edit song functionality
    } label: {
        Image(systemName: "pencil")
    }
    .disabled(true)
    .accessibilityLabel("Edit song")
    .accessibilityHint("Opens song editor. Currently unavailable.")
}

ToolbarItem(placement: .topBarTrailing) {
    Button {
        showDisplaySettings = true
    } label: {
        Image(systemName: "textformat.size")
    }
    .accessibilityLabel("Display settings")
    .accessibilityHint("Adjust font size, colors, and spacing")
}
```

---

### 2.2 Performance - Optimize SwiftData Queries

#### SongListView - Add Fetch Limits
```swift
// For very large libraries, add batch loading
@State private var fetchLimit: Int = 50
@State private var shouldLoadMore: Bool = false

// Initial query
@Query(
    sort: \Song.title,
    animation: .default
) private var allSongs: [Song]

// In view
private var displayedSongs: [Song] {
    if allSongs.count > fetchLimit {
        return Array(allSongs.prefix(fetchLimit))
    }
    return allSongs
}

// Add load more trigger
List {
    ForEach(filteredAndSortedSongs) { song in
        // ... song row ...

        if song == filteredAndSortedSongs.last {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    loadMoreIfNeeded()
                }
        }
    }
}

private func loadMoreIfNeeded() {
    guard fetchLimit < allSongs.count else { return }
    fetchLimit += 50
}
```

---

### 2.3 UI Polish - Consistent Spacing

#### Create Spacing Constants
```swift
// Create new file: Lyra/Utilities/LayoutConstants.swift
import SwiftUI

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

enum IconSize {
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

#### Apply Consistently
```swift
// Example in SongHeaderView
.padding(.horizontal, Spacing.lg)
.padding(.vertical, Spacing.md)

// Example in color card
.background(
    RoundedRectangle(cornerRadius: CornerRadius.md)
        .fill(Color(.systemGray6))
)
```

---

### 2.4 Better Animations

#### Toast Appearance
```swift
// In LibraryView.swift, ToastView modifier
.transition(.asymmetric(
    insertion: .move(edge: .top)
        .combined(with: .opacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7)),
    removal: .move(edge: .top)
        .combined(with: .opacity)
        .animation(.easeInOut(duration: 0.2))
))
```

#### Sheet Presentation
```swift
// In DisplaySettingsSheet presentation
.sheet(isPresented: $showDisplaySettings) {
    DisplaySettingsSheet(song: song)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .onDisappear {
            withAnimation(.easeInOut(duration: 0.2)) {
                displaySettings = song.displaySettings
            }
        }
}
```

#### List Updates
```swift
// In SongListView.swift
List {
    ForEach(filteredAndSortedSongs) { song in
        NavigationLink(destination: SongDisplayView(song: song)) {
            EnhancedSongRowView(song: song)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
}
.animation(.easeInOut(duration: 0.2), value: filteredAndSortedSongs)
```

---

## Priority 3: Nice to Have

### 3.1 Skeleton Loading Views

```swift
// Create new file: Lyra/Views/SkeletonViews.swift
struct SkeletonSongRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 17)
                    .frame(maxWidth: 200)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 15)
                    .frame(maxWidth: 150)
            }

            Spacer()
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}
```

---

## Implementation Schedule

### Day 1: Critical Haptics & Error Handling
- [ ] Add HapticManager calls throughout app
- [ ] Fix all `try?` silent failures
- [ ] Test haptic feedback on device

### Day 2: Loading States
- [ ] Add import progress indicator
- [ ] Add async song parsing
- [ ] Add paste loading state
- [ ] Test with large files

### Day 3: Accessibility
- [ ] Add VoiceOver labels
- [ ] Test with VoiceOver enabled
- [ ] Verify contrast ratios
- [ ] Test Dynamic Type

### Day 4: Performance & Polish
- [ ] Optimize SwiftData queries
- [ ] Add spacing constants
- [ ] Improve animations
- [ ] Profile memory usage

### Day 5: Testing & Fixes
- [ ] Run through entire checklist
- [ ] Fix any bugs found
- [ ] Test on multiple devices
- [ ] Final polish

---

## Testing After Implementation

### Manual Testing Flow

1. **Fresh Install Test**
   - Delete app
   - Reinstall
   - Complete first-time user flow
   - Verify empty state
   - Create first song
   - Import first song
   - Paste first song

2. **Heavy Usage Test**
   - Import 50 songs
   - Search extensively
   - Sort multiple times
   - Customize many songs
   - Monitor performance
   - Check memory usage

3. **Edge Cases Test**
   - Import very large file
   - Import malformed file
   - Paste empty clipboard
   - Delete all songs
   - Fill up library (100+ songs)

4. **Accessibility Test**
   - Enable VoiceOver
   - Complete all flows
   - Verify all labels
   - Test Dynamic Type (largest)

5. **Dark Mode Test**
   - Switch to dark mode
   - Visit every screen
   - Verify colors
   - Check contrast

---

## Code Quality Checks

### Before Committing

```bash
# 1. Check for force unwraps
grep -r "!" --include="*.swift" Lyra/

# 2. Check for try? (should be rare)
grep -r "try?" --include="*.swift" Lyra/

# 3. Check for print statements (should use proper logging)
grep -r "print(" --include="*.swift" Lyra/

# 4. Run SwiftLint (if configured)
swiftlint

# 5. Build for release
# Xcode: Product → Archive
```

### Code Review Checklist

- [ ] No force unwraps (`!`) in production code
- [ ] No silent failures (`try?` without comment)
- [ ] All user-facing strings are clear
- [ ] All public APIs documented
- [ ] Complex logic has comments
- [ ] No TODO comments (or tracked in issues)
- [ ] No debug print statements
- [ ] Memory-safe (no retain cycles)

---

## Post-Implementation Verification

### Automated Checks

```swift
// Add to test suite
func testNoForceUnwraps() {
    // Verify no force unwraps in production code
}

func testAllErrorsHandled() {
    // Verify all throws are caught
}

func testMemoryLeaks() {
    // Test for retain cycles
}
```

### Manual Verification

- [ ] Run Instruments - Leaks
- [ ] Run Instruments - Allocations
- [ ] Test on slowest supported device
- [ ] Test on smallest screen size
- [ ] Test with slow network (future)
- [ ] Test with interrupted operations

---

## Success Criteria

### Performance
- ✅ App launches in < 1 second
- ✅ Song list loads < 500ms (100 songs)
- ✅ Song display opens < 200ms
- ✅ Search filters in real-time
- ✅ Scrolling is 60fps smooth
- ✅ Memory usage < 100MB

### Quality
- ✅ Zero crashes in testing
- ✅ All errors have user feedback
- ✅ All actions have haptic feedback
- ✅ All loading operations show progress
- ✅ VoiceOver works throughout
- ✅ Dark mode fully supported

### User Experience
- ✅ App feels responsive and polished
- ✅ Error messages are helpful
- ✅ Animations are smooth
- ✅ Navigation is intuitive
- ✅ Ready for App Store

---

## Resources

### Apple Documentation
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Accessibility](https://developer.apple.com/accessibility/)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [UIFeedbackGenerator](https://developer.apple.com/documentation/uikit/uifeedbackgenerator)

### Tools
- Xcode Instruments (Performance)
- Accessibility Inspector
- SwiftLint (Code Quality)
- SF Symbols App

### Testing
- TestFlight for beta testing
- Physical devices for real-world testing
- Various iOS versions

---

This guide provides everything needed to make Lyra production-ready. Follow the priority order, test thoroughly after each phase, and use the checklist to verify completeness before release!
