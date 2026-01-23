# Professional Setup Guide for Lyra

## For Worship Services, Concerts, and Live Performance

This guide covers professional setup and integration for high-pressure live situations.

---

## Quick Start: Professional Setup

### Minimum Professional Setup
1. iPad Pro (recommended) or iPad Air
2. External display (HDMI adapter)
3. Foot pedal (Bluetooth or USB)
4. Optional: MIDI controller, backing track audio interface

### Full Professional Setup
1. iPad Pro 12.9" (M1 or newer)
2. 4K External Display (HDMI 2.0)
3. AirTurn DIGIT III or PageFlip Firefly foot pedals
4. USB-C hub with HDMI + USB-A
5. MIDI keyboard/controller
6. Audio interface (USB or Lightning)
7. Reliable WiFi network (for team sync)
8. Power supply (keep iPad charged)

---

## Hardware Integration

### 1. External Display Setup

**Connection:**
```
iPad → USB-C to HDMI adapter → HDMI cable → Display/Projector
```

**Best Practices:**
- ✓ Use Apple's official adapter (most reliable)
- ✓ Test connection before service
- ✓ Set display to "Lyrics Only" mode
- ✓ Increase font size for large venues
- ✓ Use high contrast for visibility
- ✓ Test from back of room

**Configuration:**
1. Connect display before opening Lyra
2. Open song in Lyra
3. Tap external display icon
4. Select profile (Worship Service / Concert)
5. Adjust font size for venue
6. Test visibility from audience

**Troubleshooting:**
- No display? Reconnect adapter, restart app
- Wrong resolution? Check display settings
- Lag? Reduce font size, disable blur effects
- Blank? Check mode (not set to "Blank")

### 2. MIDI Device Integration

**Supported Devices:**
- MIDI keyboards (via USB or Bluetooth)
- MIDI controllers (Akai, Novation, etc.)
- MIDI foot controllers
- Multi-instrument MIDI systems

**Connection:**
```
MIDI Device → USB adapter → iPad
OR
MIDI Device (Bluetooth) → iPad (pair in Settings)
```

**Setup:**
1. Connect MIDI device
2. Settings > MIDI > Scan for Devices
3. Select device from list
4. Configure MIDI mapping
5. Test all controls
6. Save as preset

**MIDI Mapping:**
- **Note On**: Trigger actions (next song, start/stop)
- **Control Change**: Adjust values (tempo, volume)
- **Program Change**: Switch songs/sets
- **Pitch Bend**: Transpose (if enabled)

**Best Practices:**
- ✓ Map essential controls only
- ✓ Use dedicated MIDI channels (avoid conflicts)
- ✓ Test before performance
- ✓ Have backup foot pedal
- ✓ Disable MIDI learn during performance

### 3. Foot Pedal Integration

**Recommended Models:**
- **AirTurn DIGIT III**: Bluetooth, 6 pedals, reliable
- **PageFlip Firefly**: Bluetooth, 4 pedals, compact
- **iRig BlueTurn**: Bluetooth, 2 pedals, affordable
- **Generic USB pedals**: Via USB adapter

**Connection:**
1. Turn on foot pedal
2. iPad Settings > Bluetooth
3. Pair foot pedal
4. Open Lyra > Settings > Foot Pedals
5. Select device
6. Configure actions
7. Test all pedals

**Optimal Configuration:**

**Worship Leader:**
```
Pedal 1: Previous Song
Pedal 2: Next Song
Pedal 3: Blank External Display
Pedal 4: Toggle Autoscroll
Long Press 1+2: Mark as Performed
```

**Solo Performer:**
```
Pedal 1: Toggle Autoscroll
Pedal 2: Next Section
Pedal 3: Transpose Up
Pedal 4: Transpose Down
```

**Rehearsal:**
```
Pedal 1: Play/Pause Backing Track
Pedal 2: Restart Backing Track
Pedal 3: Toggle Metronome
Pedal 4: Tap Tempo
```

### 4. Audio Interface Integration

**Supported Interfaces:**
- Focusrite Scarlett series (USB)
- PreSonus AudioBox (USB)
- Behringer UMC series (USB)
- Any Core Audio compatible interface

**Connection:**
```
Audio Interface → USB-C adapter → iPad
Outputs:
- Main L/R → FOH (Front of House)
- Headphone → Personal monitor
- AUX sends → Stage monitors (if supported)
```

**Configuration:**
1. Connect interface
2. Settings > Audio > Select Interface
3. Configure output routing:
   - Main: Backing tracks
   - Headphone: Metronome + tracks
4. Set buffer size (128 or 256 frames)
5. Test all outputs
6. Set appropriate levels

**Routing Setup:**

**Simple Setup:**
- Main Out L/R: Backing tracks → Mixer
- Headphone Out: Metronome + backing tracks → You

**Advanced Setup (with splitter):**
- Main Out L: Full mix → FOH
- Main Out R: Metronome only → Stage monitors
- Headphone: Personal monitor mix

---

## Professional Scenarios

### Scenario 1: Worship Service (Full Team)

**Equipment:**
- iPad Pro with Lyra
- External display (projector)
- Foot pedal (AirTurn)
- Audio interface (optional for backing tracks)

**Setup:**
1. **Before Service:**
   - Create set list for service
   - Configure external display (Worship Service profile)
   - Test projector connection
   - Pair foot pedal
   - Load backing tracks (if used)
   - Test from worship leader position

2. **Display Configuration:**
   - Mode: Lyrics Only
   - Font: 60pt (adjust for venue)
   - Colors: High contrast (white on dark blue)
   - Background: Solid color or subtle image
   - Show next line: ON

3. **Foot Pedal Setup:**
   - Pedal 1: Previous song
   - Pedal 2: Next song
   - Pedal 3: Blank display (for announcements)
   - Pedal 4: Toggle autoscroll

4. **During Service:**
   - Keep iPad in stand, visible to leader
   - Use foot pedals for navigation
   - Blank display during spoken parts
   - Monitor set progress
   - Mark songs as performed

5. **Backup Plan:**
   - Printed lyrics (first run-through)
   - Backup iPad with same set loaded
   - Know manual controls (in case pedal fails)

**Workflow:**
```
Pre-service → Connect display → Load set
↓
Start service → Navigate with pedals → Blank for speaking
↓
Between songs → Check next song → Ready display
↓
End service → Mark all performed → Export set notes
```

### Scenario 2: Concert with Backing Tracks

**Equipment:**
- iPad Pro with Lyra
- External display (optional, for lyrics)
- MIDI foot controller
- Audio interface (required)
- In-ear monitors or stage monitors

**Setup:**
1. **Before Concert:**
   - Import all backing tracks
   - Sync tracks to set list songs
   - Configure MIDI controller
   - Set up audio interface routing
   - Sound check all tracks
   - Test MIDI foot controller
   - Rehearse transitions

2. **Audio Routing:**
   ```
   Backing Tracks → Main Out L/R → Mixer → FOH
   Metronome → Headphone Out → In-Ear Monitors
   ```

3. **MIDI Controller Setup:**
   - CC 1: Start/Stop backing track
   - CC 2: Next song
   - CC 3: Previous song
   - CC 4: Toggle metronome
   - CC 5-8: Custom cues/markers

4. **During Concert:**
   - Load set list
   - Start first backing track with foot controller
   - Monitor track position
   - Use markers for cues
   - Transition smoothly between songs

5. **Critical Timing:**
   - Pre-load next track during current song
   - Use count-in for precise starts
   - Monitor track time remaining
   - Be ready for manual override

**Workflow:**
```
Pre-show → Sound check → Load set → Test MIDI
↓
Start show → Foot controller starts track → Monitor position
↓
Track playing → Watch for cues → Prepare next song
↓
End track → Auto-advance or manual next → Repeat
↓
End show → Export performance notes → Review
```

### Scenario 3: Rehearsal with Full Band

**Equipment:**
- iPad Pro with Lyra
- Metronome output to all musicians
- Optional: Individual MIDI devices per musician
- Network sync for team collaboration

**Setup:**
1. **Network Sync:**
   - All band members use Lyra
   - Leader shares set via CloudKit
   - Team receives updates in real-time
   - Each member customizes their view

2. **Individual Configurations:**
   - **Worship Leader**: Lyrics + chords, autoscroll
   - **Guitarist**: Chords only, large font
   - **Bassist**: Chord progression view
   - **Drummer**: Metronome + structure markers
   - **Keys**: Full view with dynamics

3. **Metronome Sharing:**
   - Leader controls master tempo
   - All devices receive tempo sync
   - Count-in before each song
   - Tempo trainer for challenging songs

4. **During Rehearsal:**
   - Leader navigates set
   - Team follows automatically
   - Make notes on songs
   - Adjust tempos collaboratively
   - Mark trouble spots

---

## Integration Testing

### Test 1: MIDI + Backing Tracks

**Setup:**
- MIDI foot controller connected
- Backing track loaded
- Audio interface configured

**Test Sequence:**
1. Start backing track via MIDI
2. Monitor sync timing
3. Stop backing track via MIDI
4. Restart from beginning
5. Skip to next marker via MIDI
6. Adjust volume via MIDI CC
7. Emergency stop via panic MIDI

**Expected Results:**
- ✓ Track starts immediately (<5ms latency)
- ✓ MIDI controls responsive
- ✓ No audio glitches or dropouts
- ✓ Clean starts and stops
- ✓ Accurate marker navigation

### Test 2: Multiple Displays + Network Sync

**Setup:**
- External display connected
- Network sync enabled
- Multiple devices in team

**Test Sequence:**
1. Connect external display
2. Enable network sync
3. Share set with team
4. Navigate through set on leader device
5. Verify team sees updates
6. Test display modes on external
7. Simulate network interruption
8. Verify graceful degradation

**Expected Results:**
- ✓ Display connects immediately
- ✓ Team receives updates <100ms
- ✓ No display lag or tearing
- ✓ Network interruption handled gracefully
- ✓ Reconnection automatic

### Test 3: Foot Pedals + MIDI + Autoscroll

**Setup:**
- Foot pedals paired
- MIDI controller connected
- Autoscroll enabled

**Test Sequence:**
1. Start autoscroll with foot pedal
2. Adjust tempo with MIDI CC
3. Next song with foot pedal
4. Stop autoscroll with MIDI
5. Transpose with MIDI while scrolling
6. Emergency stop all via foot pedal

**Expected Results:**
- ✓ All controls work simultaneously
- ✓ No conflicts or race conditions
- ✓ Smooth autoscroll during control changes
- ✓ Immediate response to all inputs
- ✓ No dropped commands

### Test 4: All Features Simultaneously

**Full Professional Load:**
- External display (lyrics projection)
- MIDI controller (keyboard)
- Foot pedals (AirTurn)
- Backing tracks playing
- Metronome active
- Network sync enabled
- Autoscroll running

**Test Sequence:**
1. Connect all hardware
2. Enable all features
3. Play through 10-song set
4. Use all controls during performance
5. Monitor for conflicts or issues
6. Check performance metrics

**Expected Results:**
- ✓ All features work together
- ✓ No performance degradation
- ✓ Smooth 60fps on displays
- ✓ <10ms audio latency
- ✓ <5ms MIDI latency
- ✓ No dropped frames or commands
- ✓ Stable for 2+ hour session

---

## Edge Case Handling

### Device Disconnection During Performance

**External Display Disconnect:**
```
Detection: Immediate via UIScreen notifications
Response:
1. Show alert on iPad (non-intrusive)
2. Continue normal operation
3. Log disconnection event
4. Auto-reconnect when available
5. Restore previous settings

Fallback: iPad screen shows full song view
Recovery: Automatic when display reconnected
```

**MIDI Device Disconnect:**
```
Detection: CoreMIDI disconnection notification
Response:
1. Disable MIDI controls gracefully
2. Revert to foot pedal/touch controls
3. Show subtle notification
4. Continue performance uninterrupted
5. Auto-reconnect when available

Fallback: Touch controls + foot pedals
Recovery: Automatic reconnection
```

**Foot Pedal Disconnect:**
```
Detection: Bluetooth connection loss
Response:
1. Show notification
2. Enable touch fallback
3. Log all pressed keys for recovery
4. Continue operation normally
5. Auto-pair when in range

Fallback: Touch controls + MIDI (if available)
Recovery: Automatic Bluetooth reconnection
```

**Audio Interface Disconnect:**
```
Detection: AVAudioSession route change
Response:
1. Immediately switch to device speakers
2. Notify user of change
3. Continue track playback
4. Reduce volume to safe level
5. Log disconnection

Fallback: iPad speakers (automatic)
Recovery: Manual reconnect required
```

### Multiple Hardware Conflicts

**MIDI Channel Conflicts:**
```
Problem: Two devices sending to same channel
Detection: Duplicate MIDI messages
Resolution:
1. Show conflict warning
2. Prompt to select primary device
3. Mute conflicting device
4. Suggest channel remapping

Prevention: Assign unique channels in setup
```

**Foot Pedal + MIDI Same Action:**
```
Problem: Both trigger same action simultaneously
Detection: Duplicate command in <50ms
Resolution:
1. Debounce: Only first command executes
2. Log conflict for user review
3. Suggest remapping in settings

Prevention: Clear action mapping
```

**Multiple Displays:**
```
Problem: iPad + 2 external displays connected
Detection: Multiple UIScreen instances
Resolution:
1. Use last connected display
2. Show picker in settings
3. Allow manual selection
4. Remember preference

Prevention: Single external display support
```

### Network Issues During Sync

**Network Interruption:**
```
Detection: CloudKit availability monitoring
Response:
1. Continue local operation
2. Queue changes for sync
3. Show offline indicator
4. No data loss
5. Sync when reconnected

Fallback: Fully functional offline
Recovery: Automatic background sync
```

**Sync Conflicts:**
```
Problem: Same song edited on two devices
Detection: CloudKit conflict resolution
Resolution:
1. Use server version (default)
2. Prompt user to review
3. Offer merge or manual selection
4. Save both versions locally

Prevention: Leader/follower role assignment
```

**Large Sync Queue:**
```
Problem: Many changes while offline
Detection: Queue size monitoring
Resolution:
1. Batch sync (400 records max)
2. Show progress indicator
3. Prioritize recent changes
4. Resume after interruption

Prevention: Incremental sync strategy
```

### MIDI Message Flooding

**High Message Rate:**
```
Problem: >1000 MIDI messages/second
Detection: Message rate monitoring
Response:
1. Throttle to 100 messages/second
2. Prioritize Note On/Off
3. Debounce CC messages
4. Drop redundant messages
5. Log flood event

Protection: Rate limiting + prioritization
```

**Stuck Notes:**
```
Problem: Note Off not received
Detection: Timeout monitoring (1 second)
Response:
1. Auto-send Note Off
2. Clean up hanging notes
3. Log stuck note event
4. Continue normally

Prevention: Panic button (all notes off)
```

**Invalid MIDI Data:**
```
Problem: Corrupted or malformed messages
Detection: MIDI validation
Response:
1. Drop invalid messages
2. Log for debugging
3. Continue processing valid data
4. No crash or hang

Protection: Strict message validation
```

---

## Performance Validation

### Audio Performance

**No Glitches Checklist:**
- ✓ Buffer size: 128 or 256 frames
- ✓ Sample rate: 48000 Hz
- ✓ No buffer underruns
- ✓ Real-time thread priority
- ✓ No allocations in audio callback
- ✓ Smooth playback for 2+ hours
- ✓ Clean starts and stops
- ✓ No pops or clicks

**Testing Procedure:**
1. Load complex backing track
2. Play for 30 minutes continuous
3. Monitor buffer fill level
4. Check for underruns
5. Verify clean start/stop
6. Test with MIDI activity
7. Check with all features active

**Expected Results:**
- Zero buffer underruns
- <10ms latency
- No audible glitches
- Stable CPU usage (<30%)

### MIDI Timing Accuracy

**Latency Test:**
```
Setup: MIDI keyboard → iPad → Audio interface
Test: Play note, measure time to sound
Target: <5ms total latency

Method:
1. Connect MIDI keyboard
2. Load simple synth
3. Play rapid notes
4. Measure with oscilloscope
5. Verify <5ms response
```

**Timing Precision:**
```
Test: Send 100 MIDI messages 10ms apart
Expected: All messages processed in order
Tolerance: <1ms jitter

Method:
1. MIDI controller sends sequence
2. Log timestamps
3. Analyze jitter
4. Verify order preservation
```

### Network Sync Reliability

**Sync Speed Test:**
```
Setup: Two iPads on same network
Test: Edit song on device A, measure sync time
Target: <100ms to device B

Procedure:
1. Edit song title
2. Start timer
3. Measure when change appears on B
4. Repeat 10 times
5. Average < 100ms
```

**Reliability Test:**
```
Duration: 8 hours continuous
Changes: 500 edits
Network: WiFi with occasional drops
Target: 100% sync success

Validation:
1. Make 500 edits over 8 hours
2. Simulate network drops
3. Verify all changes synced
4. Check for conflicts
5. No data loss
```

---

## Troubleshooting Quick Reference

### Display Issues

**Problem: External display not detected**
```
1. Check physical connection
2. Try different HDMI cable
3. Restart iPad
4. Try official Apple adapter
5. Check display power
```

**Problem: Display lag or stutter**
```
1. Reduce font size
2. Disable background blur
3. Use solid color background
4. Close other apps
5. Restart iPad
```

### MIDI Issues

**Problem: MIDI device not connecting**
```
1. Check USB connection
2. Try different USB port
3. Restart MIDI device
4. Restart Lyra
5. Check MIDI channel settings
```

**Problem: MIDI commands not working**
```
1. Check MIDI mapping
2. Verify MIDI channel
3. Test in MIDI monitor
4. Re-learn MIDI mapping
5. Reset MIDI configuration
```

### Foot Pedal Issues

**Problem: Foot pedal not pairing**
```
1. Turn pedal off, then on
2. Forget device in Bluetooth settings
3. Re-pair from scratch
4. Replace batteries (if wireless)
5. Try different pedal
```

**Problem: Pedal actions delayed**
```
1. Check battery level
2. Reduce Bluetooth interference
3. Move closer to iPad
4. Disable other Bluetooth devices
5. Use wired pedal if available
```

### Audio Issues

**Problem: No audio from backing tracks**
```
1. Check volume levels
2. Verify audio interface connection
3. Check output routing
4. Test with iPad speakers
5. Restart audio interface
```

**Problem: Audio glitches or dropouts**
```
1. Increase buffer size
2. Close other apps
3. Reduce CPU load
4. Check for ground loops
5. Try different USB port
```

### Sync Issues

**Problem: Changes not syncing**
```
1. Check WiFi connection
2. Verify iCloud login
3. Check iCloud storage
4. Force manual sync
5. Check network firewall
```

**Problem: Sync conflicts**
```
1. Review conflict resolution
2. Choose version to keep
3. Manually merge if needed
4. Document for team
5. Implement leader/follower roles
```

---

## Pre-Performance Checklist

### 1 Week Before

- [ ] Test all hardware connections
- [ ] Update Lyra to latest version
- [ ] Sync set list with team
- [ ] Import all backing tracks
- [ ] Configure MIDI devices
- [ ] Test external display at venue
- [ ] Verify network availability
- [ ] Create backup plan
- [ ] Print emergency lyrics
- [ ] Schedule rehearsal

### 1 Day Before

- [ ] Charge all devices fully
- [ ] Test foot pedals (replace batteries)
- [ ] Verify set list completeness
- [ ] Test autoscroll timing
- [ ] Configure display settings
- [ ] Load all backing tracks
- [ ] Test audio interface
- [ ] Check MIDI mappings
- [ ] Run through full set
- [ ] Note any issues

### 2 Hours Before

- [ ] Arrive early for setup
- [ ] Connect external display
- [ ] Pair foot pedals
- [ ] Connect MIDI devices
- [ ] Set up audio interface
- [ ] Test all hardware
- [ ] Sound check backing tracks
- [ ] Test from worship leader position
- [ ] Verify visibility from audience
- [ ] Run through 2-3 songs

### 30 Minutes Before

- [ ] Final connection check
- [ ] Load set list
- [ ] Test first song
- [ ] Verify display brightness
- [ ] Check volume levels
- [ ] Test foot pedal range
- [ ] Confirm team sync
- [ ] Review set order
- [ ] Silence notifications
- [ ] Keep iPad charged

### During Performance

- [ ] Monitor battery level
- [ ] Watch for hardware disconnects
- [ ] Use foot pedals primarily
- [ ] Mark songs as performed
- [ ] Note any issues
- [ ] Stay calm if issues arise
- [ ] Use backup plan if needed
- [ ] Keep performance flowing
- [ ] Monitor display from audience perspective

### After Performance

- [ ] Export set notes
- [ ] Document any issues
- [ ] Review performance metrics
- [ ] Share feedback with team
- [ ] Update troubleshooting notes
- [ ] Recharge all devices
- [ ] Store hardware safely
- [ ] Plan improvements

---

## Emergency Procedures

### Total Hardware Failure

**If all hardware fails:**
1. Switch to iPad screen only
2. Use touch controls
3. Continue with lyrics visible
4. Team can follow on their devices
5. Fall back to printed lyrics if needed

### Network Failure During Team Sync

**If network goes down:**
1. Continue with local operation
2. Leader manually coordinates
3. Use visual cues
4. Voice calls between team members
5. Queue syncs for later

### Backing Track Failure

**If track won't play:**
1. Try restarting track
2. Use metronome instead
3. Play acoustic version
4. Skip to next song
5. Return to track later

### Display Failure

**If projection fails:**
1. Announce words if needed
2. Team sings from memory
3. Use printed lyrics as backup
4. Fix during instrumental
5. Continue service/show

---

## Support Resources

**Documentation:**
- MIDI Setup Guide: /Docs/MIDI_GUIDE.md
- Hardware Compatibility: /Docs/HARDWARE_COMPATIBILITY.md
- Troubleshooting: This document

**Community:**
- Forums: https://community.lyraapp.com
- Discord: https://discord.gg/lyra
- Facebook Group: Lyra Users

**Direct Support:**
- Professional Support: pro@lyraapp.com
- Emergency Hotline: Available for enterprise customers
- Response Time: <4 hours for critical issues

**Training:**
- Video Tutorials: https://lyraapp.com/tutorials
- Webinars: Monthly for professional users
- On-site Training: Available for churches/venues

---

*This guide is updated regularly based on user feedback and real-world professional use.*

*Last Updated: January 2026*
