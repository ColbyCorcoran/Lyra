# Professional Troubleshooting Guide

## Quick Problem Resolution for Live Situations

**Emergency Support:** For critical issues during live performance, see [Emergency Procedures](#emergency-procedures) below.

---

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Display Issues](#display-issues)
3. [MIDI Issues](#midi-issues)
4. [Audio Issues](#audio-issues)
5. [Network/Sync Issues](#networksync-issues)
6. [Performance Issues](#performance-issues)
7. [Hardware Conflicts](#hardware-conflicts)
8. [Edge Cases](#edge-cases)
9. [Emergency Procedures](#emergency-procedures)

---

## Quick Diagnostics

### 30-Second Health Check

Run this before every performance:

```
1. Display Test
   [ ] External display connected
   [ ] Correct content showing
   [ ] Readable from back of room
   [ ] No lag or stuttering

2. Control Test
   [ ] Foot pedals responsive
   [ ] MIDI controls working
   [ ] Touch controls working
   [ ] No delay in actions

3. Audio Test
   [ ] Backing tracks play
   [ ] Metronome audible
   [ ] No clicks or pops
   [ ] Correct routing

4. Sync Test (if using)
   [ ] Network connected
   [ ] Team sees updates
   [ ] Changes sync quickly
   [ ] No conflicts

5. Battery/Power
   [ ] iPad charged >50%
   [ ] Pedals have power
   [ ] External devices powered
   [ ] Charger available
```

**If all green:** You're ready!
**If any red:** See relevant section below.

---

## Display Issues

### Display Not Detected

**Symptom:** External display doesn't show up

**Immediate Fix:**
1. Unplug HDMI cable
2. Wait 3 seconds
3. Plug back in
4. If no change, restart Lyra
5. If still no change, restart iPad

**Root Causes:**
- Loose cable connection
- Adapter not seated properly
- Display powered off
- Wrong input selected on display
- Adapter incompatible

**Prevention:**
- Use official Apple adapters
- Secure all connections with tape
- Test 30 minutes before performance
- Have backup adapter

### Display Showing Wrong Content

**Symptom:** Blank, mirrored, or incorrect view

**Immediate Fix:**
1. Tap display icon in Lyra
2. Select correct mode (Lyrics Only)
3. Adjust settings if needed
4. If frozen, disconnect and reconnect

**Root Causes:**
- Wrong display mode selected
- App crash/freeze
- Insufficient memory

**Prevention:**
- Set display mode before starting
- Close unnecessary apps
- Test display before performance

### Display Lag or Stuttering

**Symptom:** Delay or choppy display updates

**Immediate Fix:**
1. Settings > Performance > Clear Caches
2. Reduce font size
3. Use solid color background
4. Close other apps
5. Disable transparency effects

**Root Causes:**
- High memory usage
- Complex backgrounds
- Too many apps running
- Old iPad model

**Prevention:**
- Keep iPad storage >20% free
- Use simple backgrounds
- Disable non-essential features
- Test on actual performance hardware

### Display Resolution Wrong

**Symptom:** Text too small or letterboxed

**Immediate Fix:**
1. Check display native resolution
2. iPad Settings > Display
3. Adjust Lyra font size
4. Test from audience distance

**Root Causes:**
- Display not 16:9 aspect ratio
- 4K display with 1080p adapter
- Display scaling issues

**Prevention:**
- Know your display specs
- Use appropriate adapter
- Test at venue beforehand

---

## MIDI Issues

### MIDI Device Not Detected

**Symptom:** Device doesn't appear in MIDI settings

**Immediate Fix:**
1. **USB Devices:**
   - Check adapter connection
   - Try different USB port
   - Restart device
   - Replace USB cable

2. **Bluetooth Devices:**
   - Turn device off/on
   - Settings > Bluetooth > Forget Device
   - Re-pair from scratch
   - Check battery level

3. **Still Not Working:**
   - Test in GarageBand
   - Try different adapter
   - Update device firmware

**Root Causes:**
- Loose connection
- Dead battery
- Incompatible device
- Needs firmware update
- iOS pairing issue

**Prevention:**
- Test 1 hour before performance
- Fully charge wireless devices
- Bring spare batteries
- Verify compatibility

### MIDI Commands Not Responding

**Symptom:** Press MIDI control, nothing happens

**Immediate Fix:**
1. Settings > MIDI > View Mappings
2. Verify control is mapped
3. Check MIDI channel matches
4. Test in MIDI Monitor
5. Re-learn mapping if needed

**Debugging:**
```
Settings > MIDI > MIDI Monitor
Send test message
Watch for:
  - Message appears? (Device working)
  - Correct channel? (Match settings)
  - Correct CC/note? (Verify mapping)
  - Value changing? (Control working)
```

**Root Causes:**
- Incorrect mapping
- Wrong MIDI channel
- Control disabled
- Conflicting action

**Prevention:**
- Document all mappings
- Test each control
- Use unique channels
- Save mapping presets

### MIDI Latency/Delay

**Symptom:** Noticeable delay between action and response

**Immediate Fix:**
1. Close background apps
2. Settings > Audio > Buffer Size (reduce to 128)
3. Disable unnecessary MIDI mappings
4. Use wired instead of Bluetooth if possible

**Acceptable Latency:**
- USB MIDI: <5ms (imperceptible)
- Bluetooth MIDI: <20ms (acceptable)
- Network MIDI: <50ms (noticeable)

**Root Causes:**
- High CPU usage
- Large audio buffer
- Bluetooth interference
- Too many active mappings

**Prevention:**
- Use wired connections
- Minimize background processes
- Optimize buffer size
- Limit active mappings

### MIDI Flooding

**Symptom:** Too many messages, app becomes unresponsive

**Immediate Fix:**
1. Turn off flooding device
2. Settings > MIDI > Panic
3. Restart Lyra if needed
4. Reduce control sensitivity

**Detection:**
```
Settings > Performance > MIDI Rate
Normal: <100 messages/second
Flooding: >500 messages/second
```

**Auto-Protection:**
- Lyra limits to 100 msg/sec
- Prioritizes important messages
- Drops redundant data
- Automatic recovery

**Root Causes:**
- Mod wheel continuous data
- Malfunctioning controller
- MIDI feedback loop
- Expression pedal too sensitive

**Prevention:**
- Use discrete controls
- Disable MIDI thru
- Check for loops
- Test before performance

### Stuck MIDI Notes

**Symptom:** Note doesn't turn off, continuous sound

**Immediate Fix:**
1. Settings > MIDI > Panic (sends All Notes Off)
2. Restart MIDI device
3. Power cycle audio interface

**Auto-Recovery:**
- Lyra auto-releases after 1 second
- All notes off on song change
- Panic on audio glitch

**Root Causes:**
- Note Off not sent
- MIDI cable disconnected mid-note
- Device malfunction

**Prevention:**
- Map panic to foot pedal
- Always send Note Off
- Use quality MIDI cables
- Test device reliability

---

## Audio Issues

### No Audio from Backing Tracks

**Symptom:** Track plays but no sound

**Immediate Fix:**
1. Check iPad volume (not muted)
2. Check Lyra volume slider
3. Verify audio routing:
   - Settings > Audio > Output Device
4. Try iPad speakers first
5. Check audio interface connection

**Root Causes:**
- Volume muted
- Wrong output selected
- Audio interface disconnected
- Track file corrupted

**Prevention:**
- Test audio before performance
- Check volume levels
- Verify routing
- Test backup tracks

### Audio Glitches/Dropouts

**Symptom:** Clicks, pops, stutters, or silence

**Immediate Fix:**
1. Increase buffer size:
   - Settings > Audio > Buffer Size > 256 or 512
2. Close background apps
3. Restart track
4. Check CPU usage (Performance Monitor)

**Buffer Size Guide:**
```
128 frames: <3ms latency, high CPU (for MIDI)
256 frames: ~5ms latency, medium CPU (recommended)
512 frames: ~10ms latency, low CPU (for glitches)
```

**Root Causes:**
- Buffer too small
- High CPU usage
- Insufficient memory
- Corrupted track file

**Prevention:**
- Optimize buffer for your iPad
- Close unnecessary apps
- Monitor performance metrics
- Use quality audio files

### Audio Out of Sync

**Symptom:** Audio timing drifts from autoscroll or MIDI

**Immediate Fix:**
1. Stop and restart playback
2. Check sample rate (should be 48000 Hz)
3. Verify MIDI clock sync settings
4. Restart audio interface

**Root Causes:**
- Sample rate mismatch
- MIDI clock not syncing
- Drift accumulation
- Audio interface issue

**Prevention:**
- Use consistent sample rate
- Enable MIDI clock sync
- Monitor sync regularly
- Use quality interface

### Metronome Not Audible

**Symptom:** Can't hear metronome click

**Immediate Fix:**
1. Check metronome volume slider
2. Verify output routing:
   - Metronome should go to headphones
   - Not to main speakers (for click track)
3. Test with different sound
4. Check audio interface routing

**Root Causes:**
- Volume too low
- Sent to wrong output
- Muted in mixer
- Hardware routing issue

**Prevention:**
- Set clear metronome volume
- Document routing setup
- Test before performance
- Use dedicated metronome output

---

## Network/Sync Issues

### CloudKit Sync Not Working

**Symptom:** Changes don't sync to team

**Immediate Fix:**
1. Check WiFi connection
2. Settings > iCloud > Verify logged in
3. Force manual sync:
   - Pull to refresh in library
4. Check iCloud storage (not full)

**Network Requirements:**
- WiFi or cellular data
- iCloud account logged in
- iCloud Drive enabled
- Network not blocking CloudKit

**Root Causes:**
- No network connection
- Not logged into iCloud
- iCloud storage full
- Network firewall blocking

**Prevention:**
- Verify WiFi before start
- Check iCloud status
- Monitor storage
- Test sync beforehand

### Sync Conflicts

**Symptom:** "Conflict detected" message

**Immediate Fix:**
1. Review both versions
2. Choose:
   - Server version (default)
   - Local version
   - Manually merge
3. Resolve quickly to continue

**Conflict Scenarios:**
```
Scenario: Same song edited on two devices
Resolution:
  1. Leader version wins (set in team)
  2. OR manual merge
  3. Both versions saved locally

Scenario: Set order changed simultaneously
Resolution:
  1. Timestamp-based (newest wins)
  2. Leader override available
```

**Prevention:**
- Use leader/follower roles
- Communicate edits
- Edit one at a time
- Enable conflict warnings

### Slow Sync Speed

**Symptom:** Changes take >10 seconds to sync

**Immediate Fix:**
1. Check network speed
2. Reduce concurrent edits
3. Batch changes
4. Switch to cellular if WiFi slow

**Expected Sync Times:**
```
WiFi (good): <100ms
WiFi (poor): 1-3 seconds
Cellular: 1-5 seconds
No network: Queue for later
```

**Root Causes:**
- Slow network
- Many simultaneous changes
- Large attachments syncing
- CloudKit throttling

**Prevention:**
- Use reliable WiFi
- Minimize live edits
- Pre-load large changes
- Monitor network speed

### Team Member Not Seeing Updates

**Symptom:** One device not syncing

**Immediate Fix:**
1. That device: Pull to refresh
2. Check their network connection
3. Verify iCloud login
4. Force quit and reopen Lyra
5. Manual re-sync if needed

**Root Causes:**
- Network issue on their device
- Not logged into iCloud
- App backgrounded too long
- Sync paused

**Prevention:**
- All team check before start
- Keep apps active
- Good network for all
- Regular sync checks

---

## Performance Issues

### App Running Slow

**Symptom:** Laggy, stuttering, unresponsive

**Immediate Fix:**
1. Settings > Performance > Clear Caches
2. Close background apps
3. Restart Lyra
4. If critical, restart iPad

**Performance Monitor:**
```
Settings > Developer > Performance Monitor
Check:
  - FPS: Should be 45-60
  - Memory: Should be <500MB
  - CPU: Should be <60%

If any red, take action
```

**Root Causes:**
- High memory usage
- Too many apps running
- Large library loaded
- Low iPad storage

**Prevention:**
- Monitor performance regularly
- Clear caches weekly
- Keep storage >20% free
- Close unused apps

### Battery Draining Fast

**Symptom:** Battery percentage dropping quickly

**Immediate Fix:**
1. Enable Low Power Mode
2. Reduce screen brightness
3. Disable background sync
4. Close unnecessary features
5. Connect to power

**Battery Usage:**
```
Normal: 10-15%/hour active
Heavy: 15-25%/hour (all features)
Critical: >25%/hour (issue)
```

**Root Causes:**
- All features active
- High brightness
- Poor network (searching)
- Background processes
- Old battery

**Prevention:**
- Keep iPad charged
- Use Low Power Mode
- Monitor battery health
- Reduce brightness
- Bring charger always

### App Crashes

**Symptom:** App closes unexpectedly

**Immediate Fix:**
1. Reopen Lyra (state should be saved)
2. If crashes again:
   - Restart iPad
   - Update Lyra
   - Report crash

**Auto-Recovery:**
- Last view restored
- Set position saved
- Song progress preserved
- Changes auto-saved

**Root Causes:**
- Memory pressure
- iOS bug
- Corrupted data
- Incompatible feature combination

**Prevention:**
- Keep Lyra updated
- Monitor memory usage
- Report crashes promptly
- Keep iOS updated

---

## Hardware Conflicts

### Multiple Devices Same Channel

**Symptom:** MIDI controls interfering

**Immediate Fix:**
1. Assign unique channels:
   - Device A → Channel 1
   - Device B → Channel 2
2. Update mappings for each
3. Test isolation

**Best Practice:**
```
Channel 1: Navigation controls
Channel 2: Playback controls
Channel 3: Effects/misc
Channels 4-16: Reserved
```

**Prevention:**
- Plan channel assignments
- Document setup
- Test before adding new device

### Foot Pedal + MIDI Conflict

**Symptom:** Same action triggered twice

**Immediate Fix:**
1. Check action mappings
2. Disable redundant mapping
3. Use debouncing (automatic in Lyra)

**Debouncing:**
- Lyra ignores duplicate actions within 50ms
- First command executes
- Subsequent ignored
- Logs for review

**Prevention:**
- Map unique actions per device
- Avoid duplicate mappings
- Test combined usage

### Display + Performance Load

**Symptom:** Slow performance with display connected

**Immediate Fix:**
1. Reduce display font size
2. Use solid backgrounds
3. Lower display resolution if possible
4. Disable effects

**Resource Usage:**
```
External Display Impact:
  - CPU: +10-15%
  - Memory: +50MB
  - GPU: +20%

Optimization:
  - Simple backgrounds
  - Standard fonts
  - Disable transparency
```

**Prevention:**
- Test performance with display
- Optimize display settings
- Use appropriate iPad model

---

## Edge Cases

### Device Disconnection During Performance

#### External Display Disconnect

**Detection:** Immediate notification

**Auto-Response:**
1. Alert shown (non-intrusive)
2. iPad shows full view
3. Performance continues
4. Auto-reconnect when available

**Manual Recovery:**
1. Reconnect cable
2. Display resumes automatically
3. Previous settings restored

**Fallback:** iPad screen shows everything

#### MIDI Device Disconnect

**Detection:** CoreMIDI notification

**Auto-Response:**
1. Subtle notification
2. MIDI controls disabled
3. Touch/foot pedal still work
4. Auto-reconnect enabled

**Manual Recovery:**
1. Reconnect device
2. Auto-detection
3. Mappings restored

**Fallback:** Touch + foot pedals

#### Foot Pedal Disconnect

**Detection:** Bluetooth connection loss

**Auto-Response:**
1. Notification shown
2. Touch controls active
3. MIDI still works
4. Auto-pair when in range

**Manual Recovery:**
1. Check pedal power
2. Move closer if wireless
3. Manual re-pair if needed

**Fallback:** Touch + MIDI controls

#### Audio Interface Disconnect

**Detection:** Audio route change

**Auto-Response:**
1. Switch to iPad speakers
2. Notify user
3. Reduce volume (safe level)
4. Log disconnection

**Manual Recovery:**
1. Reconnect interface
2. Settings > Audio > Select device
3. Restore routing

**Fallback:** iPad speakers (automatic)

### Network Loss During Sync

**Scenario:** WiFi drops mid-performance

**Auto-Response:**
1. Local operation continues
2. Changes queued
3. Offline indicator shown
4. No data loss

**Recovery:**
1. Network returns
2. Auto-sync queued changes
3. Conflict resolution if needed
4. All data preserved

**Guarantee:** Zero data loss

### Multiple Simultaneous Issues

**Scenario:** Display + MIDI + Network all fail

**Priority Response:**
1. **Maintain playback** (most important)
2. Switch to iPad screen
3. Use touch controls
4. Continue performance
5. Fix during gap if possible

**Emergency Protocol:**
1. Keep music flowing
2. Use what works
3. Adapt on the fly
4. Fix systematically

### Power Loss Scenarios

**Scenario:** iPad battery critical during performance

**Auto-Response:**
1. Low Power Mode auto-enables
2. Non-essential features disabled
3. Extend runtime
4. Warn user early (20%)

**Manual Action:**
1. Connect to power immediately
2. Reduce screen brightness
3. Disable external display
4. Close background features

**Prevention:**
- Always bring charger
- Start at >50% battery
- Monitor battery level
- Have backup iPad

---

## Emergency Procedures

### Total System Failure

**If Lyra completely fails:**

1. **Immediate:**
   - Keep performing
   - Use memory/team
   - Printed lyrics if available

2. **Quick Recovery:**
   - Force quit Lyra (swipe up)
   - Reopen (state restored)
   - Resume from last position

3. **If Still Failing:**
   - Restart iPad (hold power button)
   - Takes 30 seconds
   - All state preserved

4. **Nuclear Option:**
   - Use backup iPad
   - Or switch to acoustic
   - Or use team's devices

### Hardware Cascade Failure

**If all hardware stops working:**

1. **Assess:**
   - What still works?
   - Can performance continue?
   - Need to pause?

2. **Prioritize:**
   - Keep audio going
   - Use manual controls
   - Fix one thing at a time

3. **Communicate:**
   - Signal to team
   - Keep audience engaged
   - Transition smoothly

4. **Recover:**
   - Fix during instrumental
   - Or between songs
   - Or use backup plan

### Live Performance Emergency Checklist

```
[ ] iPad charged and working
[ ] Backup control method ready
[ ] Team knows hand signals
[ ] Printed lyrics available
[ ] Know how to adapt
[ ] Backup iPad ready
[ ] Manual controls practiced
[ ] Emergency contact listed
```

### When to Call for Help

**During Performance:**
- Don't stop to troubleshoot
- Use fallbacks
- Fix during breaks
- Document for later

**After Performance:**
- Email: emergency@lyraapp.com
- Include: Error logs, screenshots, description
- For critical issues: Flag as "Live Performance Failure"
- Response: <4 hours for critical

**Critical Issues:**
- Complete app failure
- Data loss
- Sync failure losing changes
- Hardware damage

---

## Diagnostic Logs

### How to Collect Logs

**For Support Requests:**

1. Settings > Help > Export Logs
2. Include:
   - Device model
   - iOS version
   - Lyra version
   - Steps to reproduce
   - When it occurred
   - What you tried

3. Email to: support@lyraapp.com

4. Attach:
   - Log file
   - Screenshots
   - Performance metrics
   - MIDI monitor screenshots

### Performance Metrics Export

**To share performance data:**

1. Settings > Developer > Performance Monitor
2. Tap "Export Metrics"
3. Includes:
   - FPS history
   - Memory usage
   - CPU usage
   - Event log
   - MIDI activity
   - Network stats

### MIDI Monitor Export

**To debug MIDI issues:**

1. Settings > MIDI > MIDI Monitor
2. Tap "Record"
3. Reproduce issue
4. Tap "Stop"
5. Export log
6. Includes all MIDI messages with timestamps

---

## Prevention Checklist

### Before Every Performance

**Hardware:**
- [ ] All cables secure
- [ ] Batteries fresh/charged
- [ ] Connections tested
- [ ] Backups ready

**Software:**
- [ ] Lyra updated
- [ ] Set list loaded
- [ ] Features tested
- [ ] Caches cleared

**Network:**
- [ ] WiFi verified
- [ ] Sync tested
- [ ] Team connected
- [ ] Offline mode works

**Audio:**
- [ ] Tracks load
- [ ] Routing correct
- [ ] Levels set
- [ ] No glitches

**Backup:**
- [ ] Alternate controls work
- [ ] Printed lyrics available
- [ ] Backup iPad ready
- [ ] Manual workarounds known

### Monthly Maintenance

- [ ] Clear all caches
- [ ] Update firmware (devices)
- [ ] Check battery health
- [ ] Test all hardware
- [ ] Review mappings
- [ ] Update Lyra
- [ ] Backup library
- [ ] Review performance metrics

---

## Support Resources

### Documentation
- Professional Setup Guide: PROFESSIONAL_SETUP_GUIDE.md
- MIDI Setup: MIDI_SETUP_GUIDE.md
- Hardware Compatibility: HARDWARE_COMPATIBILITY.md

### Community
- Forums: community.lyraapp.com
- Discord: discord.gg/lyra
- Facebook: Lyra Professional Users

### Direct Support
- Email: support@lyraapp.com
- Emergency: emergency@lyraapp.com (live situations)
- Response: <4 hours critical, <24 hours normal

### Training
- Webinars: Monthly professional training
- Videos: lyraapp.com/tutorials
- On-site: Available for organizations

---

*This guide is continuously updated based on user reports and professional use cases.*

*Last Updated: January 2026*
