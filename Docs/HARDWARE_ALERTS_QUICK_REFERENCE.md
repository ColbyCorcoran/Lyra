# Hardware Alerts Quick Reference

## Critical Alerts During Live Performance

*Quick action guide for hardware notifications in Lyra*

**Last Updated: January 2026**

---

## Alert Types

### 🟢 Success (Green)
- Device connected successfully
- System ready
- Auto-dismiss after 3 seconds

### 🔵 Info (Blue)
- Non-critical status update
- Audio routing changed
- Auto-dismiss after 5 seconds

### 🟠 Warning (Orange)
- Device disconnected
- Performance degraded
- **Requires attention**

### 🔴 Error (Red)
- Critical failure
- System malfunction
- **Immediate action required**

---

## Common Alerts & Quick Fixes

### External Display Alerts

#### ⚠️ "External Display Disconnected"
**Cause:** HDMI cable unplugged or adapter failure

**Immediate Actions:**
1. Tap "Reconnect" button in alert
2. Check HDMI cable connections
3. Verify adapter is seated properly
4. Try different HDMI cable if available

**Fallback:** Lyrics continue on iPad screen

**Prevention:** Secure all cables before performance

---

#### ✅ "External Display Connected"
**Meaning:** Projection is active

**Verify:**
- Check that lyrics appear on projector/TV
- Confirm correct resolution
- Verify content is readable from audience distance

---

### MIDI Device Alerts

#### ⚠️ "MIDI Device Disconnected"
**Cause:** USB cable loose, Bluetooth disconnect, or device power off

**Immediate Actions:**
1. Check USB connection (if wired)
2. For Bluetooth: Check device is powered on
3. Re-pair if necessary (Settings > MIDI)

**Fallback:** Touch controls and shortcuts still work

**Prevention:**
- Use wired connections when possible
- Check Bluetooth battery before performance

---

#### ⚠️ "MIDI Message Flooding"
**Cause:** Too many MIDI messages (>100/sec)

**Immediate Actions:**
1. Tap "MIDI Panic" in alert
2. Reduce controller sensitivity
3. Disconnect problematic MIDI device if needed

**What's Happening:** Lyra auto-throttles to prevent lag

**Fix Later:** Check MIDI device settings, update firmware

---

#### ✅ "[Device Name] Connected"
**Meaning:** MIDI control is active

**Verify:**
- Test a mapped control
- Check LED indicators on device
- Verify correct MIDI channel

---

### Audio Alerts

#### ⚠️ "Audio Device Disconnected"
**Cause:** Audio interface unplugged or Bluetooth audio disconnect

**Immediate Actions:**
1. Check USB/Lightning connection
2. For Bluetooth: Verify device is on
3. Continue using iPad speakers temporarily

**Fallback:** Audio automatically routes to iPad speakers

**Impact:** Metronome, backing tracks still play (lower quality)

**Prevention:** Use wired audio interface for critical performances

---

#### 🔵 "Audio Device Connected"
**Meaning:** Audio routing updated

**Verify:**
- Play metronome or backing track
- Check volume levels
- Confirm correct output selected

---

### Foot Pedal Alerts

#### ⚠️ "Foot Pedal Battery Low"
**Cause:** Bluetooth pedal battery <20%

**Immediate Actions:**
1. Replace batteries during break
2. Switch to touch/MIDI controls if needed
3. Keep spare batteries nearby

**Fallback:** Touch and MIDI controls available

**Prevention:** Check battery before each performance

---

### Performance Alerts

#### ⚠️ "Low Frame Rate"
**Detail:** "FPS below 30"

**Immediate Actions:**
1. Close background apps
2. Disable visual effects temporarily
3. Reduce autoscroll speed if active

**Fallback:** Core functions still work

**Fix Later:** Check Performance Monitor, optimize settings

---

#### ⚠️ "High Memory Usage"
**Detail:** "Memory usage >400 MB"

**Immediate Actions:**
1. Close unused set lists
2. Avoid loading very large PDFs during performance
3. Restart app during break if possible

**Fallback:** iOS manages memory automatically

**Fix Later:** Review library for optimization opportunities

---

#### ⚠️ "Low Battery"
**Detail:** "Battery <30%"

**Immediate Actions:**
1. Connect to power immediately
2. Enable Low Power Mode (iOS Settings)
3. Reduce screen brightness
4. Disable non-essential features

**Fallback:** Continue on battery, but plan to wrap up

**Prevention:** Start performance at 100%, bring charger

---

## Alert Dismissal

### Auto-Dismiss
- **Success alerts:** 3 seconds
- **Info alerts:** 5 seconds
- **Warning/Error alerts:** Manual dismiss only

### Manual Dismiss
- Tap ❌ button on alert
- Swipe alert away
- Tap "Dismiss All" in Hardware Health Check

---

## Pre-Performance Health Check

### How to Run
1. Settings > Hardware Health Check
2. Tap "Run Check"
3. Review results

### Grades

**Excellent** 🟢
- All systems optimal
- No warnings
- Ready for performance

**Good** 🔵
- 1-2 minor warnings
- Safe to perform
- Monitor warnings

**Fair** 🟠
- 3+ warnings
- Performance may be affected
- Address warnings before critical use

**Fail** 🔴
- Critical issues detected
- Do NOT perform until fixed
- See issues list for details

---

## Emergency Procedures

### "Everything is Broken"

**Immediate Stabilization:**
1. Tap screen to bring up controls
2. Navigate songs manually (swipe or tap arrows)
3. Ignore external hardware temporarily
4. Use iPad screen if projector fails

**After Performance:**
1. Restart iPad
2. Reconnect hardware one at a time
3. Run Hardware Health Check
4. Review logs: Settings > Developer > Diagnostics

---

### "External Display Keeps Disconnecting"

**During Performance:**
1. Switch to iPad screen only
2. Position iPad so you can read lyrics
3. Continue performance

**Fix:**
1. Try different HDMI cable
2. Try different adapter
3. Test with different display
4. See TROUBLESHOOTING_PROFESSIONAL.md

---

### "MIDI Device Not Responding"

**During Performance:**
1. Use touch controls
2. Use foot pedal if available
3. Use keyboard shortcuts

**Fix:**
1. Restart MIDI device
2. Disconnect and reconnect
3. Check Settings > MIDI > MIDI Monitor
4. See MIDI_SETUP_GUIDE.md

---

### "Audio Crackling/Glitching"

**Immediate Actions:**
1. Stop backing tracks
2. Close background apps
3. Reduce buffer size: Settings > Audio
4. Use metronome only (lower CPU)

**Fix Later:**
1. Update iOS
2. Update audio interface firmware
3. Reduce simultaneous tracks
4. See TROUBLESHOOTING_PROFESSIONAL.md

---

## Alert Preferences

### Disable Notifications (Not Recommended)
Settings > Hardware Notifications > OFF

**Warning:** You will NOT be notified of disconnections during performance

**Only disable if:**
- You have backup monitoring (someone watching connections)
- You find alerts distracting
- You're in a controlled environment

---

### Notification Sounds
- Alerts use haptic feedback only (no sound)
- No audio interruption to performance
- Visual + haptic ensures you notice without disrupting flow

---

## Testing Alerts

### How to Test
1. Settings > Hardware Health Check
2. Connect/disconnect test device
3. Verify alert appears
4. Verify haptic feedback works
5. Practice dismissing alerts quickly

### Practice Scenarios
- Unplug HDMI mid-song → practice recovery
- Disconnect MIDI → switch to touch controls
- Low battery warning → connect power quickly

---

## Alert History

### View Recent Alerts
Settings > Developer > Performance Monitor > Alert Log

**Shows:**
- Last 50 alerts
- Timestamp
- Type
- Action taken
- Resolution time

**Use to:**
- Identify recurring issues
- Track hardware reliability
- Prepare for next performance

---

## Hardware Reliability Tips

### Before Every Performance
1. Run Hardware Health Check (Settings)
2. Test all connected devices
3. Verify backup controls work (touch, keyboard)
4. Know fallback plan for each device

### During Performance
1. Keep alerts visible (don't disable)
2. Acknowledge alerts quickly
3. Don't panic - fallbacks are built-in
4. Continue performing while addressing issue

### After Performance
1. Review alert log
2. Fix recurring issues
3. Replace unreliable hardware
4. Update firmware/drivers

---

## Support

**Alert not listed here?**
- See TROUBLESHOOTING_PROFESSIONAL.md for detailed guides
- Email: support@lyraapp.com
- Include: Alert screenshot, hardware list, iOS version

**Feature request?**
- Request new alert types
- Suggest alert improvements
- Report false positives

---

## Quick Reference Card (Print This)

```
┌─────────────────────────────────────────┐
│   LYRA HARDWARE ALERTS QUICK CARD      │
├─────────────────────────────────────────┤
│                                         │
│ 🟢 GREEN = Success (auto-dismiss)      │
│ 🔵 BLUE = Info (auto-dismiss)          │
│ 🟠 ORANGE = Warning (action needed)    │
│ 🔴 RED = Critical (fix immediately)    │
│                                         │
├─────────────────────────────────────────┤
│ DISPLAY DISCONNECTED:                   │
│   1. Tap "Reconnect"                   │
│   2. Check HDMI cable                  │
│   3. Use iPad screen if needed         │
│                                         │
│ MIDI DISCONNECTED:                      │
│   1. Check USB/Bluetooth               │
│   2. Use touch controls                │
│   3. Continue performance              │
│                                         │
│ LOW BATTERY:                            │
│   1. Connect power NOW                 │
│   2. Reduce brightness                 │
│   3. Enable Low Power Mode             │
│                                         │
│ MIDI FLOODING:                          │
│   1. Tap "MIDI Panic"                  │
│   2. Disconnect problematic device     │
│                                         │
├─────────────────────────────────────────┤
│ EMERGENCY: Everything Fails             │
│   → Use iPad screen + touch controls   │
│   → Navigate manually with swipes      │
│   → You can finish the performance!    │
│                                         │
└─────────────────────────────────────────┘
```

**Fold and keep with iPad during performances**

---

*This guide is designed for quick reference during live performances. For comprehensive troubleshooting, see TROUBLESHOOTING_PROFESSIONAL.md*

*Last Updated: January 2026*
