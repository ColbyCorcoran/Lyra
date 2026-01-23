# Performance Quick Reference

## Performance Targets

| Metric | Target | Action if Exceeded |
|--------|--------|--------------------|
| FPS | 60 | Clear caches, reduce effects |
| Memory | <500MB | Clear caches immediately |
| CPU (idle) | <5% | Check background tasks |
| CPU (active) | <60% | Optimize rendering |
| Launch | <2s | Profile with Instruments |
| Audio Latency | <10ms | Reduce buffer size |
| MIDI Latency | <5ms | Check thread priority |

## Quick Diagnostics

### Low FPS (<30)
```
1. Check memory usage (Settings > Performance Monitor)
2. Clear caches (Settings > Performance > Clear Caches)
3. Close other apps
4. Reduce visual effects
5. Enable Low Power Mode
```

### High Memory (>500MB)
```
1. Clear all caches
2. Force quit app
3. Restart device
4. Check library size (reduce if >1000 songs)
```

### High CPU (>60%)
```
1. Check for runaway processes
2. Disable GPU acceleration
3. Reduce background sync
4. Profile with Instruments
```

### Slow Launch (>2s)
```
1. Clear caches on device
2. Reduce library size
3. Defer non-critical loads
4. Check device storage
```

## Performance Monitor

**Access:** Settings > Developer > Performance Monitor

**Metrics:**
- FPS (target: 60)
- Memory (target: <500MB)
- CPU (target: <60%)
- Battery level
- Performance grade (A-F)

## Optimization Switches

**In Performance Settings:**
- ☑ Lazy Loading (default: ON)
- ☑ Image Caching (default: ON)
- ☑ GPU Acceleration (default: ON)
- ☐ Aggressive Memory Optimization (default: OFF)

**Low Power Mode:**
- Reduces FPS to 30
- Disables GPU acceleration
- Reduces background work
- Automatically enabled at <20% battery

## Cache Management

**Memory Caches:**
- Images: 100 MB max
- Parsed Songs: 50 entries
- Auto-clear on memory warning

**Disk Caches:**
- Images: 100 MB, 7 days
- Thumbnails: 50 MB, 30 days
- Clear manually in Settings

**Clear Caches:**
Settings > Performance > Clear Caches

## Large Library Tips

**1000+ Songs:**
- Use search instead of scrolling
- Create smaller books/sets
- Enable lazy loading
- Increase pagination size
- Clear caches regularly

**Search Optimization:**
- Wait for 2+ characters
- 300ms debounce
- Limit results to 50
- Use indexed fields

## Rendering Performance

**60fps Checklist:**
- ✓ Minimize view hierarchy
- ✓ Use lazy loading
- ✓ Cache computed values
- ✓ Avoid expensive calculations in body
- ✓ Use background threads

**Autoscroll Smoothness:**
- Use CADisplayLink
- Pre-render upcoming content
- Minimize layout recalculations
- Target constant 60fps

## Network Efficiency

**CloudKit Optimization:**
- Batch operations (400 max)
- Use change tokens
- Compress data >10KB
- Smart sync scheduling

**Sync Priorities:**
1. User-initiated (immediate)
2. Recent edits (<5 min)
3. Older edits (<1 hour)
4. Background (opportunistic)

## Audio Performance

**Low Latency Settings:**
- Buffer size: 128 frames
- Sample rate: 48000 Hz
- Theoretical latency: 2.67ms

**Best Practices:**
- Pre-allocate buffers
- Real-time thread priority
- Avoid allocations in callback
- Use Audio HAL directly

## MIDI Performance

**Low Latency:**
- Process immediately on receive
- Real-time thread priority
- No main thread dispatch
- Pre-allocate buffers

**Target:** <5ms total latency

## Battery Optimization

**Power Saving:**
- Respond to Low Power Mode
- Reduce CPU when idle
- Efficient rendering
- Smart network scheduling

**Battery Usage:**
- Idle: <2%/hour
- Active: <10%/hour
- Performance: <15%/hour

## Memory Leak Prevention

**Common Issues:**
- Strong reference cycles
- Closure capture problems
- Notification observers
- Timer retention
- Delegate cycles

**Solutions:**
```swift
// Weak self in closures
Task { [weak self] in
    await self?.doWork()
}

// Remove observers
NotificationCenter.default.removeObserver(self)

// Invalidate timers
timer?.invalidate()
```

## Profiling with Instruments

**Key Tools:**
1. Time Profiler → CPU hotspots
2. Allocations → Memory usage
3. Leaks → Memory leaks
4. System Trace → Overall performance
5. Energy Log → Battery impact

**Quick Profile:**
1. Product > Profile (Cmd+I)
2. Choose template
3. Run scenario
4. Analyze results

## Performance Grades

| Grade | Description | Action |
|-------|-------------|--------|
| A | Excellent | Maintain |
| B | Good | Minor tweaks |
| C | Acceptable | Investigate |
| D | Poor | Optimize now |
| F | Unacceptable | Critical fix |

## Emergency Actions

**App Frozen:**
1. Force quit (swipe up)
2. Clear all caches
3. Restart device

**Memory Full:**
1. Clear all caches
2. Delete unused songs
3. Restart app

**Persistent Issues:**
1. Reinstall app
2. Check device storage
3. Update iOS
4. Contact support

## Support

**Performance Issues:**
performance@lyraapp.com

**Include:**
- Device model
- iOS version
- Library size
- Performance screenshots

**Response Time:**
Critical: 4 hours
High: 24 hours
Normal: 48 hours
