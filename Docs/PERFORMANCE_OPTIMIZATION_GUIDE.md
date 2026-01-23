# Performance Optimization Guide for Lyra

## Professional Performance Targets

Lyra is optimized for professional use with large libraries and demanding performance scenarios.

### Performance Targets

| Metric | Target | Minimum Acceptable |
|--------|--------|-------------------|
| Frame Rate | 60 FPS | 30 FPS |
| App Launch | <2 seconds | <5 seconds |
| Audio Latency | <10ms | <20ms |
| MIDI Latency | <5ms | <10ms |
| Display Latency | <16.67ms (60fps) | <33ms (30fps) |
| Network Sync | <100ms | <500ms |
| Memory Usage | <500 MB | <750 MB |
| CPU Usage (idle) | <5% | <15% |
| CPU Usage (active) | <60% | <80% |

---

## 1. Large Library Optimization

### Lazy Loading Strategy

**Implementation:**
- Use `LazyDataList` for all song lists
- Default page size: 50 items
- Preload distance: 10 items ahead
- Automatic pagination on scroll

```swift
LazyDataList(
    pageSize: 50,
    predicate: #Predicate<Song> { song in
        song.title.contains(searchQuery)
    },
    sortBy: [SortDescriptor(\.title)]
) { song in
    SongRow(song: song)
}
```

### Efficient Queries

**Optimized Fetch Descriptors:**
```swift
// For list views - fetch only needed properties
let descriptor = Song.fetchMinimalDescriptor(
    predicate: predicate,
    sortBy: [SortDescriptor(\.title)]
)

// For pagination
let descriptor = FetchDescriptor.paginated(
    for: Song.self,
    page: currentPage,
    pageSize: 50,
    predicate: predicate
)
```

**Count Queries:**
```swift
// Efficient count without loading objects
let count = try modelContext.fetchCount(
    for: Song.self,
    predicate: predicate
)
```

### Indexing Best Practices

**Indexed Properties:**
- title (text search)
- artist (text search)
- currentKey (filtering)
- dateAdded (sorting)
- dateModified (sorting)

**Compound Indexes:**
- (title, artist) for combined search
- (dateAdded, title) for chronological lists

### Search Optimization

**Efficient Search:**
```swift
let descriptor = Song.searchDescriptor(
    query: searchText,
    limit: 50
)
```

**Search Debouncing:**
- Minimum 300ms delay between searches
- Cancel pending searches on new input
- Show results only after 2+ characters

### Memory Management for Large Libraries

**Pagination:**
- Load 50 songs at a time
- Release previous pages when far from view
- Keep current + next page in memory

**Image Loading:**
- Lazy load thumbnails
- Use `ImageCache` for memory management
- Disk cache for 100MB max
- 7-day cache expiration

---

## 2. Latency Reduction

### Audio Latency

**Configuration:**
```swift
// Use lowest buffer size for minimum latency
let preferredBufferSize = 128 // frames
let preferredSampleRate = 48000.0 // Hz

// Theoretical latency: 128/48000 = 2.67ms
```

**Best Practices:**
- Use Audio HAL directly for metronome
- Avoid AVAudioEngine for time-critical audio
- Pre-allocate audio buffers
- Run audio on real-time priority thread

### MIDI Latency

**CoreMIDI Optimization:**
```swift
// Process MIDI immediately on receive
func handleMIDIPacket(_ packet: MIDIPacket) {
    // Target: <1ms processing time
    // Direct dispatch to handlers
    // No main thread dispatch
}
```

**MIDI Thread Priority:**
- Use real-time thread priority
- Minimize work in MIDI callback
- Pre-allocate MIDI buffers

### Display Latency

**60fps Rendering:**
- Use CADisplayLink for timing
- Maximum 16.67ms per frame
- Minimize work in draw cycle
- Offload to background threads

**Optimization Checklist:**
- ✓ Use view caching
- ✓ Minimize view hierarchy depth
- ✓ Avoid expensive draws in scrolling
- ✓ Use GPU acceleration where possible
- ✓ Profile with Instruments Time Profiler

### Network Sync Latency

**CloudKit Optimization:**
- Batch operations (max 400 records)
- Compress large payloads
- Use change tokens for incremental sync
- Background sync for non-urgent data

**Latency Targets:**
- Local sync: <10ms
- WiFi sync: <100ms
- Cellular sync: <500ms

---

## 3. Memory Management

### Memory Budget

| Component | Budget | Notes |
|-----------|--------|-------|
| App Code | 50 MB | Fixed overhead |
| SwiftData | 100 MB | Model objects |
| Images | 100 MB | Cached thumbnails |
| Audio | 50 MB | Audio buffers |
| Parsed Songs | 100 MB | Parsed ChordPro |
| UI Cache | 50 MB | View snapshots |
| Other | 50 MB | Temporary data |
| **Total** | **500 MB** | Target maximum |

### Image Loading

**Best Practices:**
```swift
// Use ImageCache
ImageCache.shared.load(url: imageURL) { image in
    // Image loaded and cached
}

// Memory cache: 100 MB, 100 images
// Disk cache: 100 MB, 7 days
```

**Thumbnail Strategy:**
- Generate thumbnails on import
- Store at 300x300 max
- JPEG compression 0.7 quality
- Lazy load on scroll

### Audio Buffer Management

**Efficient Buffers:**
- Reuse audio buffers (don't allocate per-use)
- Pool buffers for backing tracks
- Release immediately when done
- Use smallest viable buffer size

### Memory Pressure Handling

**Automatic Cleanup:**
```swift
// On memory warning:
1. Clear image cache
2. Clear parsed song cache
3. Release unused audio buffers
4. Force garbage collection hint
5. Notify other managers to reduce memory
```

**Manual Cleanup:**
- Clear caches on low memory
- Aggressive cleanup on memory warning
- Periodic cleanup (every 5 minutes idle)

---

## 4. Battery Optimization

### Low Power Mode Detection

**Adaptive Behavior:**
```swift
if PerformanceManager.shared.isLowPowerModeEnabled {
    // Reduce frame rate to 30fps
    // Disable GPU acceleration
    // Reduce background work
    // Minimize network activity
}
```

### CPU Usage Optimization

**Idle State (<5% CPU):**
- Stop display link when idle
- Suspend background sync
- Disable non-essential timers
- Reduce sensor polling

**Active State (<60% CPU):**
- Efficient rendering pipeline
- Minimize redundant calculations
- Use caching aggressively
- Offload to GPU where possible

### Background App Refresh

**Strategy:**
- Only sync changed data
- Use background task API properly
- Limit to 30 seconds max
- Batch all operations
- Exponential backoff on errors

### Power-Efficient Networking

**Best Practices:**
- Batch CloudKit operations
- Use WiFi when available
- Compress data transfers
- Avoid frequent polling
- Use push notifications

---

## 5. App Launch Optimization

### Cold Launch (<2 seconds)

**Critical Path:**
```
1. App initialization (200ms)
2. SwiftData setup (300ms)
3. UI initialization (500ms)
4. First frame render (500ms)
5. Ready for interaction (500ms)
Total: 2000ms
```

**Optimization Techniques:**
- Defer non-critical initialization
- Lazy load view controllers
- Background load user data
- Cache previous session state
- Optimize first view layout

### Warm Launch (<500ms)

**Strategy:**
- Restore previous state from cache
- Skip redundant initialization
- Reuse loaded resources
- Fast path for common scenarios

### Background to Foreground (<100ms)

**Quick Resume:**
- Preserve UI state
- Invalidate stale data only
- Refresh visible content first
- Defer background updates

### Deferred Loading

**Non-Critical:**
- CloudKit sync (defer 2s)
- Analytics (defer 5s)
- Remote config (defer 3s)
- Background refresh (defer 10s)

---

## 6. Rendering Performance

### 60fps Scrolling

**Techniques:**
- Use `List` with lazy loading
- Minimize view hierarchy depth
- Avoid expensive calculations in `body`
- Cache computed values
- Use `@State` and `@Binding` efficiently

**View Caching:**
```swift
// Cache expensive views
@State private var cachedView: some View

var body: some View {
    if cachedView == nil {
        cachedView = expensiveView()
    }
    return cachedView
}
```

### Smooth Autoscroll

**Implementation:**
- Use CADisplayLink for timing
- Calculate scroll position on GPU
- Minimize layout recalculations
- Pre-render upcoming content
- Use scrollTo with animation

**Performance Target:**
- Constant 60fps during scroll
- No frame drops or stutters
- Smooth acceleration/deceleration
- Immediate stop response

### PDF Rendering

**Optimization:**
```swift
// Render at appropriate resolution
let scale = UIScreen.main.scale
let size = CGSize(width: viewWidth * scale, height: viewHeight * scale)

// Cache rendered pages
PDFPageCache.shared.cache(page: pdfPage, size: size)

// Render off main thread
Task.detached(priority: .userInitiated) {
    let image = await renderPDFPage(page, size: size)
    await MainActor.run {
        display(image)
    }
}
```

**Page Cache:**
- Cache 5 pages (current + 2 ahead + 2 behind)
- Release distant pages
- Pre-render next page
- Use thumbnail for navigation

### GPU Acceleration

**When to Use:**
- Complex animations
- Blur effects (use UIVisualEffectView)
- Image scaling and filtering
- Video playback

**When to Avoid:**
- Simple views
- Text rendering
- Static content
- Low power mode

---

## 7. Network Efficiency

### CloudKit Optimization

**Batch Operations:**
```swift
// Batch up to 400 records
let batchSize = 400
let batches = records.chunked(into: batchSize)

for batch in batches {
    try await database.save(batch)
}
```

**Change Tokens:**
```swift
// Fetch only changes since last sync
let operation = CKFetchRecordZoneChangesOperation(
    recordZoneIDs: [zoneID],
    configurationsByRecordZoneID: [zoneID: config]
)

// Save server change token for next sync
```

**Query Optimization:**
- Use cursors for large result sets
- Limit results to needed fields
- Use zone subscriptions for updates
- Batch delete operations

### Data Compression

**When to Compress:**
- Song content >10KB
- Images >100KB
- Attachments >1MB

**Compression:**
```swift
// Use zlib compression
let compressed = try (data as NSData).compressed(using: .zlib)

// Typical compression: 60-80% size reduction
```

### Caching Strategy

**Cache Duration:**
- Song data: 1 hour
- Images: 7 days
- Metadata: 24 hours
- Search results: 5 minutes

**Cache Invalidation:**
- On user edit
- On remote update notification
- On explicit refresh
- On version mismatch

### Smart Sync Scheduling

**Priority Levels:**
1. **Immediate**: User-initiated changes
2. **High**: Recent edits (within 5 minutes)
3. **Medium**: Older edits (within 1 hour)
4. **Low**: Background sync (opportunistic)

**Network Conditions:**
- WiFi: Sync all priorities
- Cellular (unlimited): Sync high+ priorities
- Cellular (limited): Sync immediate only
- Airplane mode: Queue for later

---

## 8. Real-World Stress Testing

### Test Scenarios

**Large Library Test:**
- 1000 songs
- 50 books
- 100 sets
- Scroll through all
- Search frequently
- Monitor memory

**Long Performance Test:**
- 2-hour continuous use
- Play through 20-song set
- Use autoscroll
- Switch between songs
- Monitor for leaks

**Old Device Test:**
- iPhone 8 or older
- Run all scenarios
- Target 30fps minimum
- Monitor battery drain
- Check thermal throttling

### Instruments Profiling

**Key Tools:**
1. **Time Profiler**: CPU hotspots
2. **Allocations**: Memory usage and leaks
3. **Leaks**: Memory leak detection
4. **System Trace**: System-wide performance
5. **Energy Log**: Battery impact
6. **Network**: Network efficiency

**Profiling Checklist:**
- ✓ No memory leaks
- ✓ No retain cycles
- ✓ Efficient CPU usage
- ✓ No unnecessary allocations
- ✓ No blocking main thread
- ✓ Smooth 60fps rendering

### Memory Leak Detection

**Common Leaks:**
- Strong reference cycles
- Closure capture issues
- Notification observers
- Timer retention
- Delegate cycles

**Prevention:**
```swift
// Use weak self in closures
Task { [weak self] in
    await self?.doWork()
}

// Remove observers
NotificationCenter.default.removeObserver(self)

// Invalidate timers
timer?.invalidate()
```

### Performance Regression Testing

**Benchmarks:**
- App launch time
- Song parse time
- List scroll performance
- Search response time
- Sync duration

**Automated Tests:**
```swift
func testAppLaunchPerformance() {
    measure {
        // Launch app
        // Measure time to first frame
    }
}

func testSongParsePerformance() {
    measure {
        let parser = ChordProParser()
        _ = try? parser.parse(complexSongContent)
    }
}
```

---

## Performance Monitoring Dashboard

**Enable in Settings:**
Settings > Developer > Performance Monitor

**Metrics Displayed:**
- Current FPS
- Memory usage
- CPU usage
- Battery level
- Performance grade (A-F)

**Performance Alerts:**
- FPS drops below 30
- Memory exceeds 500 MB
- CPU exceeds 60%
- Battery critical (<10%)

---

## Best Practices Summary

### DO:
✓ Use lazy loading for large lists
✓ Cache aggressively
✓ Profile with Instruments regularly
✓ Test on old devices
✓ Monitor memory continuously
✓ Use background threads for heavy work
✓ Batch network operations
✓ Respond to low power mode

### DON'T:
✗ Load entire library at once
✗ Block main thread
✗ Allocate in tight loops
✗ Ignore memory warnings
✗ Use unnecessary animations
✗ Poll for updates
✗ Keep stale caches
✗ Ignore performance regressions

---

## Performance Grades

| Grade | FPS | Memory | CPU | Description |
|-------|-----|--------|-----|-------------|
| A | 55+ | <400MB | <50% | Excellent |
| B | 45-55 | 400-500MB | 50-60% | Good |
| C | 35-45 | 500-600MB | 60-70% | Acceptable |
| D | 30-35 | 600-700MB | 70-80% | Poor |
| F | <30 | >700MB | >80% | Unacceptable |

**Target: Maintain Grade A on all supported devices**

---

## Emergency Performance Recovery

If performance degrades:

1. **Clear All Caches**: Settings > Performance > Clear Caches
2. **Force Quit**: Swipe up in app switcher
3. **Restart Device**: Hold power button
4. **Reinstall App**: Delete and reinstall from App Store

For persistent issues:
- Check device storage (need 1GB free)
- Update to latest iOS version
- Report via Settings > Help

---

## Performance Contact

**Report Performance Issues:**
performance@lyraapp.com

**Include:**
- Device model
- iOS version
- Library size (# of songs)
- Steps to reproduce
- Performance monitor screenshots

**Priority Response:**
Performance issues fixed within 24 hours.

---

*Last Updated: January 2026*
