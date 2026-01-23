# MIDI Setup Guide for Lyra

## Complete MIDI Integration for Professional Use

### Table of Contents
1. [MIDI Basics](#midi-basics)
2. [Hardware Setup](#hardware-setup)
3. [MIDI Mapping](#midi-mapping)
4. [Advanced Features](#advanced-features)
5. [Troubleshooting](#troubleshooting)

---

## MIDI Basics

### What is MIDI?

MIDI (Musical Instrument Digital Interface) is a protocol that allows electronic musical instruments and computers to communicate.

**MIDI Messages:**
- **Note On/Off**: Trigger actions (like pressing a key)
- **Control Change (CC)**: Adjust continuous values (0-127)
- **Program Change**: Switch presets/songs
- **Pitch Bend**: Continuous pitch adjustment

### Why Use MIDI with Lyra?

**Benefits:**
- Hands-free song navigation
- Real-time control during performance
- Integration with existing MIDI setup
- Precise timing for backing tracks
- Professional workflow automation

**Common Uses:**
- Navigate songs with keyboard
- Control backing tracks with foot controller
- Sync tempo with master clock
- Trigger markers and cues
- Transpose on the fly

---

## Hardware Setup

### Supported MIDI Connections

#### 1. USB MIDI Devices

**Connection:**
```
MIDI Keyboard/Controller
    ↓ (USB cable)
USB Camera Adapter (Lightning to USB)
    ↓
iPad
```

**Supported Devices:**
- USB MIDI keyboards
- USB MIDI controllers
- USB MIDI foot controllers
- USB MIDI interfaces

**Setup:**
1. Connect USB adapter to iPad
2. Connect MIDI device to adapter
3. Open Lyra
4. Settings > MIDI
5. Device appears automatically

#### 2. Bluetooth MIDI Devices

**Connection:**
```
Bluetooth MIDI Device
    ↓ (Wireless)
iPad
```

**Supported Devices:**
- Bluetooth MIDI keyboards
- Bluetooth foot controllers
- Bluetooth MIDI adapters

**Setup:**
1. Turn on Bluetooth MIDI device
2. iPad Settings > Bluetooth
3. Wait for device to appear
4. Tap to pair
5. Open Lyra
6. Settings > MIDI
7. Select paired device

#### 3. Network MIDI (Advanced)

**Connection:**
```
Mac/PC with MIDI
    ↓ (Network)
iPad
```

**Setup:**
1. Mac: Audio MIDI Setup > MIDI Studio
2. Enable "Network Session"
3. iPad: Settings > Bluetooth
4. Connect to network
5. Lyra > Settings > MIDI
6. Select network session

### Recommended Hardware

#### Budget ($50-150)
- **Foot Controller**: iRig BlueTurn ($50)
- **Keyboard**: M-Audio Keystation Mini ($99)
- **Adapter**: Apple Lightning to USB Camera Adapter ($29)

#### Mid-Range ($150-400)
- **Foot Controller**: Logidy UMI3 ($150)
- **Keyboard**: Akai MPK Mini ($119)
- **Interface**: iConnectMIDI2+ ($200)

#### Professional ($400+)
- **Foot Controller**: Behringer FCB1010 ($250)
- **Keyboard**: Native Instruments Komplete Kontrol ($499)
- **Interface**: iConnectAUDIO4+ ($399)

---

## MIDI Mapping

### Quick Start Mapping

**Automatic Learning:**
1. Settings > MIDI > MIDI Learn
2. Select action to map
3. Press MIDI control
4. Mapping saved automatically
5. Repeat for all controls

### Default Mappings

#### Worship Leader Profile
```
CC 1  (Mod Wheel): Next Song
CC 2  (Breath):    Previous Song
CC 3:              Blank Display
CC 4:              Toggle Autoscroll
CC 5:              Start/Stop Backing Track
CC 6:              Toggle Metronome
CC 7  (Volume):    Master Volume
CC 64 (Sustain):   Mark Song Performed

Program Change:    Jump to Song # (0-127)
```

#### Solo Performer Profile
```
CC 1:  Toggle Autoscroll
CC 2:  Next Section
CC 3:  Transpose Up
CC 4:  Transpose Down
CC 5:  Reset Transpose
CC 6:  Toggle Metronome
CC 7:  Tempo Adjust
CC 8:  Loop Marker

Note On C3:   Previous Song
Note On D3:   Next Song
Note On E3:   Start Backing Track
Note On F3:   Stop Backing Track
```

#### Backing Track Controller Profile
```
CC 1:   Play/Pause Track
CC 2:   Stop Track
CC 3:   Restart Track
CC 4:   Next Marker
CC 5:   Previous Marker
CC 6:   Loop Section
CC 7:   Track Volume
CC 8:   Track Speed (0.5x - 2.0x)

PC 0-9: Jump to Marker 0-9
```

### Custom Mapping

**Create Your Own:**
1. Settings > MIDI > Custom Mapping
2. Tap "New Mapping"
3. Name your mapping
4. Add controls one by one:
   - Tap "Add Control"
   - Select MIDI message type
   - Learn or manually enter
   - Assign action
   - Set parameters
5. Save mapping
6. Activate for current session

**Actions Available:**
- **Navigation**: Next/Previous Song, Section, Page
- **Playback**: Play/Pause/Stop Autoscroll
- **Backing Tracks**: Control track playback
- **Metronome**: Start/Stop, Tap Tempo, Adjust BPM
- **Display**: Blank, Show Chords, Change Mode
- **Transpose**: Up/Down, Reset, Set Key
- **Markers**: Jump to Marker, Set Marker
- **Custom**: Execute Shortcut, Send MIDI Out

### MIDI Channels

**Channel Assignment:**
```
Channel 1:  Song Navigation
Channel 2:  Playback Control
Channel 3:  Backing Tracks
Channel 4:  Metronome
Channel 5:  Display Control
Channel 6:  Transpose
Channel 7:  Custom Actions
Channel 8-16: Reserved for future
```

**Best Practices:**
- Use different channels for different controllers
- Avoid channel conflicts
- Document your channel assignments
- Use omni mode (all channels) for simple setups

---

## Advanced Features

### MIDI Clock Sync

**Sync Lyra to External Clock:**
```
Purpose: Lock autoscroll to MIDI clock from DAW/drum machine
```

**Setup:**
1. Settings > MIDI > MIDI Clock
2. Enable "Sync to External Clock"
3. Select clock source
4. Set PPQN (Pulses Per Quarter Note)
5. Test sync

**Use Cases:**
- Sync to backing track DAW
- Lock to drummer's click
- Match to lighting controller
- Coordinate with video

### MIDI Out

**Send MIDI from Lyra:**
```
Purpose: Control other devices from Lyra
```

**Setup:**
1. Settings > MIDI > MIDI Out
2. Select output device
3. Configure messages:
   - On song change: Send PC
   - On section: Send CC
   - On marker: Send Note

**Use Cases:**
- Change lighting scenes per song
- Switch keyboard patches
- Control effects pedals
- Trigger video cues

### Program Change Song Selection

**Jump to Songs by Number:**
```
PC 0   → Song 1 in current set
PC 1   → Song 2 in current set
...
PC 127 → Song 128 in current set
```

**Setup:**
1. Load set list
2. Enable PC Navigation
3. Songs automatically numbered
4. Send PC from controller

**Tip:** Use with keyboard or foot controller for instant song access

### MIDI Panic

**All Notes Off:**
```
Emergency: Stuck notes or MIDI chaos
Action: CC 123 (All Notes Off) on all channels
```

**Triggers:**
1. Manual: Settings > MIDI > Panic
2. Automatic: On audio glitch
3. Foot Pedal: Map to long press
4. MIDI Command: CC 123

### SysEx Support

**System Exclusive Messages:**
```
Purpose: Device-specific advanced control
Support: Limited to non-real-time SysEx
```

**Use Cases:**
- Load custom presets
- Backup MIDI configuration
- Sync with specific hardware

---

## Troubleshooting

### Device Not Detected

**Problem:** MIDI device doesn't appear

**Solutions:**
1. **Check Connection:**
   - USB: Ensure adapter is official Apple
   - Bluetooth: Check device is in pairing mode
   - Network: Verify network session enabled

2. **Restart Sequence:**
   - Disconnect MIDI device
   - Close Lyra
   - Restart iPad
   - Reconnect MIDI device
   - Reopen Lyra

3. **Verify Compatibility:**
   - Check manufacturer's iOS compatibility
   - Update device firmware
   - Try different USB port

4. **Test in GarageBand:**
   - Open GarageBand
   - Check if MIDI device works there
   - If not, it's a hardware/iPad issue
   - If yes, it's a Lyra issue (contact support)

### Commands Not Responding

**Problem:** MIDI messages sent but no action

**Solutions:**
1. **Check Mapping:**
   - Settings > MIDI > View Mappings
   - Verify control is mapped
   - Re-learn if necessary

2. **Check MIDI Channel:**
   - Ensure device sending on correct channel
   - Try omni mode (all channels)
   - Check for channel conflicts

3. **Test MIDI Monitor:**
   - Settings > MIDI > MIDI Monitor
   - Send test message
   - Verify Lyra receives it
   - Check values (0-127 range)

4. **Action Conflicts:**
   - Disable conflicting actions
   - Check foot pedal mappings
   - Review shortcuts

### Latency Issues

**Problem:** Delay between MIDI and action

**Target:** <5ms latency

**Solutions:**
1. **Reduce Buffer Size:**
   - Settings > Audio > Buffer Size
   - Set to 128 frames (lowest)
   - Test for stability

2. **Close Background Apps:**
   - Double-click home
   - Swipe away unused apps
   - Reduce CPU load

3. **Disable Unnecessary Features:**
   - Turn off unused MIDI mappings
   - Reduce visual effects
   - Disable real-time sync

4. **Use Wired Connection:**
   - USB < Bluetooth for latency
   - Network MIDI has higher latency
   - Wired is most reliable

### MIDI Flooding

**Problem:** Too many MIDI messages

**Detection:** Settings > Performance > MIDI Rate

**Solutions:**
1. **Auto-Throttling:**
   - Lyra limits to 100 msg/sec
   - Automatic in current version
   - Prioritizes important messages

2. **Manual Fix:**
   - Reduce control sensitivity
   - Use discrete values (not continuous)
   - Debounce rapid messages
   - Avoid MIDI feedback loops

### Stuck Notes

**Problem:** Note won't turn off

**Solutions:**
1. **MIDI Panic:**
   - Settings > MIDI > Panic
   - Sends All Notes Off
   - Immediate resolution

2. **Automatic Cleanup:**
   - Lyra auto-releases after 1 second
   - Prevents hanging notes
   - Logged for review

3. **Prevention:**
   - Always send Note Off
   - Use MIDI Panic at song end
   - Map panic to foot pedal

### Channel Conflicts

**Problem:** Multiple devices on same channel

**Solutions:**
1. **Reassign Channels:**
   - Give each device unique channel
   - Document assignments
   - Use channel 1-8 for different roles

2. **Use MIDI Thru Carefully:**
   - Disable if not needed
   - Can cause message duplication
   - Check for MIDI loops

---

## Testing MIDI Setup

### Pre-Performance Test

**Complete Test Sequence:**

1. **Connection Test:**
   ```
   [ ] Device detected in Lyra
   [ ] Green indicator in MIDI settings
   [ ] No connection warnings
   ```

2. **Mapping Test:**
   ```
   [ ] Test each mapped control
   [ ] Verify correct action
   [ ] Check parameter ranges
   [ ] Test edge cases (0, 127)
   ```

3. **Latency Test:**
   ```
   [ ] Send rapid messages
   [ ] Measure response time
   [ ] Target: <5ms
   [ ] No dropped messages
   ```

4. **Stability Test:**
   ```
   [ ] Run for 10 minutes continuous
   [ ] Send various message types
   [ ] Monitor for errors
   [ ] Check for stuck notes
   ```

5. **Integration Test:**
   ```
   [ ] Use with foot pedals
   [ ] Combine with backing tracks
   [ ] Test with external display
   [ ] All features simultaneously
   ```

### MIDI Monitor Usage

**Real-Time Monitoring:**

1. Settings > MIDI > MIDI Monitor
2. Shows all incoming MIDI:
   - Message type
   - Channel
   - Value
   - Timestamp
3. Helps diagnose issues
4. Verify device is sending correctly

---

## Best Practices

### Setup
- ✓ Use wired connections when possible
- ✓ Assign unique MIDI channels
- ✓ Document all mappings
- ✓ Test before performance
- ✓ Have backup control method

### Mapping
- ✓ Keep mappings simple
- ✓ Use familiar controls (mod wheel, sustain)
- ✓ Group related actions
- ✓ Label physical controls
- ✓ Save custom presets

### Performance
- ✓ Test all controls before starting
- ✓ Have MIDI panic mapped
- ✓ Monitor for conflicts
- ✓ Keep spare batteries (wireless)
- ✓ Bring backup adapter

### Troubleshooting
- ✓ Use MIDI Monitor to diagnose
- ✓ Test in isolation first
- ✓ Document issues for support
- ✓ Keep firmware updated
- ✓ Know manual workarounds

---

## Example Setups

### Setup 1: Solo Acoustic with Foot Controller

**Hardware:**
- Logidy UMI3 MIDI foot controller
- iPad Pro
- USB-C to USB-A adapter

**Mapping:**
```
Pedal 1: Next Song
Pedal 2: Toggle Autoscroll
Pedal 3: Transpose Up
```

**Use Case:**
- Simple navigation
- Hands stay on guitar
- Minimal complexity

### Setup 2: Worship Team with Full MIDI

**Hardware:**
- MIDI keyboard (worship leader)
- Behringer FCB1010 (for tracks)
- iPad Pro
- USB MIDI interface

**Mapping:**
```
Keyboard:
  PC 0-9: Jump to songs 1-10
  CC 1: Blank display

Foot Controller:
  Pedal 1: Next song
  Pedal 2: Previous song
  Pedal 3: Play/Pause track
  Pedal 4: Stop track
```

**Use Case:**
- Complex worship service
- Multiple controllers
- Backing tracks integrated

### Setup 3: Concert with Lighting Sync

**Hardware:**
- MIDI keyboard
- MIDI foot controller
- iPad Pro
- MIDI interface (in/out)
- Lighting controller (receives MIDI)

**Mapping:**
```
MIDI In:
  Keyboard controls Lyra

MIDI Out:
  Song change → PC to lighting
  Marker → CC to lighting scenes
  Tempo → MIDI clock to lighting
```

**Use Case:**
- Synchronized lighting
- Professional concert
- Automated scene changes

---

## Support

**Need Help?**
- Email: midi@lyraapp.com
- Forums: https://community.lyraapp.com/midi
- Discord: #midi-help channel

**Include in Support Request:**
1. MIDI device make/model
2. Connection type (USB/Bluetooth/Network)
3. iOS version
4. Lyra version
5. Description of issue
6. MIDI Monitor screenshot

---

*Last Updated: January 2026*
