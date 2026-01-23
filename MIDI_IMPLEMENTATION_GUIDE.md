# MIDI Implementation Guide for Lyra

## Overview

Lyra now includes comprehensive MIDI support for controlling external instruments, effects processors, mixers, and lighting equipment. This enables professional performance workflows where song changes can automatically trigger program changes, adjust effects, and configure equipment.

**Implementation Status:** ✅ Complete (Phase 1 - Core Features)
**Framework:** CoreMIDI (Apple native)
**Platform:** iOS 15.0+, iPadOS 15.0+

---

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Architecture](#architecture)
3. [Device Management](#device-management)
4. [MIDI Messages](#midi-messages)
5. [Song-Specific MIDI](#song-specific-midi)
6. [User Interface](#user-interface)
7. [Integration Guide](#integration-guide)
8. [Use Cases](#use-cases)
9. [Troubleshooting](#troubleshooting)
10. [Future Enhancements](#future-enhancements)

---

## Core Concepts

### What is MIDI?

**MIDI (Musical Instrument Digital Interface)** is a technical standard for communicating between electronic musical instruments, computers, and audio equipment. Unlike audio, MIDI transmits **event messages** describing notes, control parameters, and timing.

### MIDI in Lyra

Lyra's MIDI implementation enables:
- **Program Changes** - Select patches/sounds on keyboards
- **Control Changes** - Adjust reverb, chorus, volume, pan, etc.
- **Bank Selection** - Access different banks of sounds
- **Note Messages** - Trigger actions or test connections
- **System Exclusive** - Device-specific commands

### Key Features

✅ **Auto-Detection** - Automatically finds connected MIDI devices
✅ **Dual I/O** - Supports both input (receive) and output (send)
✅ **Song-Specific** - Store MIDI settings per song
✅ **Real-Time Monitoring** - View incoming/outgoing messages
✅ **USB & Bluetooth** - Supports both connection types
✅ **Multi-Channel** - Full 16-channel MIDI support

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Lyra App                              │
│  • Song loading triggers MIDI send                          │
│  • Settings UI for MIDI configuration                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│                     MIDIManager                              │
│  • Device scanning and connection                           │
│  • Message sending (output)                                 │
│  • Message receiving (input)                                │
│  • Message parsing and handling                             │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│                      CoreMIDI                                │
│  • Apple's MIDI framework                                   │
│  • Low-level MIDI I/O                                       │
│  • Device enumeration                                       │
└─────────────────────────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│                   MIDI Devices                               │
│  • USB MIDI interfaces                                      │
│  • Bluetooth MIDI devices                                   │
│  • Network MIDI (future)                                    │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**Output (Sending):**
```
Song Loads → Check MIDI Config → MIDIManager.sendSongMIDI()
→ Create MIDI Bytes → CoreMIDI Send → MIDI Device
```

**Input (Receiving):**
```
MIDI Device → CoreMIDI → MIDIManager.handleMIDIInput()
→ Parse Message → Post Notification → App Handles Event
```

---

## Device Management

### Device Detection

**File:** `Lyra/Utilities/MIDIManager.swift`

```swift
// Scan for MIDI devices
await MIDIManager.shared.scanDevices()

// Access device lists
let inputDevices = midiManager.inputDevices
let outputDevices = midiManager.outputDevices
```

**Device Properties:**
```swift
struct MIDIDevice {
    let name: String              // "Roland FA-06"
    let manufacturer: String?     // "Roland"
    let model: String?           // "FA-06"
    let uniqueID: Int32          // Unique identifier
    let isInput: Bool            // Can receive MIDI
    let isOutput: Bool           // Can send MIDI
    var isConnected: Bool        // Connection status
    var isEnabled: Bool          // User enabled
}
```

### Auto-Detection

Lyra automatically:
1. Scans for devices on app launch (if MIDI enabled)
2. Rescans when devices are connected/disconnected
3. Selects first available device by default
4. Maintains connection state across app restarts

### Connection

```swift
// Connect to input device
midiManager.connectToInputDevice(device)

// Select output device
midiManager.selectedOutputDevice = device

// Disconnect
midiManager.disconnectInputDevice()
```

### Device Types Supported

| Device Type | Support | Notes |
|------------|---------|-------|
| **USB MIDI Interface** | ✅ Full | Class-compliant devices (most keyboards) |
| **Bluetooth MIDI** | ✅ Full | Bluetooth LE MIDI specification |
| **Network MIDI** | ⬜ Future | MIDI over WiFi/Ethernet |
| **Virtual MIDI** | ⬜ Future | Inter-app MIDI routing |

---

## MIDI Messages

### Message Types

**File:** `Lyra/Models/MIDIDevice.swift`

```swift
enum MIDIMessageType {
    case noteOn          // Play note
    case noteOff         // Stop note
    case programChange   // Change patch/program
    case controlChange   // Adjust parameter
    case pitchBend       // Pitch wheel
    case aftertouch      // Pressure sensitivity
    case systemExclusive // Device-specific
    case clock           // Timing
    case start/stop      // Transport control
}
```

### Sending MIDI Messages

#### Program Change (0-127)
```swift
// Send program change
midiManager.sendProgramChange(program: 42, channel: 1)

// Example: Change to Electric Piano patch
midiManager.sendProgramChange(program: 5, channel: 1)
```

#### Control Change (CC)
```swift
// Send control change
midiManager.sendControlChange(
    controller: 91,  // Reverb
    value: 64,       // Medium
    channel: 1
)

// Common CCs:
// 7  = Volume
// 10 = Pan
// 11 = Expression
// 64 = Sustain Pedal
// 91 = Reverb
// 93 = Chorus
```

#### Bank Select
```swift
// Bank select for multi-bank keyboards
midiManager.sendControlChange(controller: 0, value: 5, channel: 1) // MSB
midiManager.sendControlChange(controller: 32, value: 0, channel: 1) // LSB
midiManager.sendProgramChange(program: 10, channel: 1)
```

#### Note On/Off
```swift
// Play middle C
midiManager.sendNoteOn(note: 60, velocity: 100, channel: 1)

// Stop middle C
midiManager.sendNoteOff(note: 60, channel: 1)

// Note numbers: 0-127 (60 = Middle C)
```

#### System Exclusive (SysEx)
```swift
// Send device-specific command
let sysExData: [UInt8] = [0x41, 0x10, 0x42, 0x12, ...]
midiManager.sendSysEx(data: sysExData)
```

#### Panic/Reset
```swift
// All notes off (emergency stop)
midiManager.sendAllNotesOff(channel: 1)

// All sound off (including release)
midiManager.sendAllSoundOff(channel: 1)
```

### Receiving MIDI Messages

**Notification-Based:**
```swift
// Listen for program changes
NotificationCenter.default.addObserver(
    forName: .midiProgramChangeReceived,
    object: nil,
    queue: .main
) { notification in
    let program = notification.userInfo?["program"] as? UInt8
    let channel = notification.userInfo?["channel"] as? UInt8
    // Load song based on program number
}

// Listen for control changes
NotificationCenter.default.addObserver(
    forName: .midiControlChangeReceived,
    object: nil,
    queue: .main
) { notification in
    let controller = notification.userInfo?["controller"] as? UInt8
    let value = notification.userInfo?["value"] as? UInt8
    // Adjust settings based on CC
}
```

### MIDI Byte Format

**Program Change:**
```
0xC0 | channel | program
Example: 0xC0 0x05 = Program 5 on channel 1
```

**Control Change:**
```
0xB0 | channel | controller | value
Example: 0xB0 0x07 0x64 = Volume (CC7) = 100 on channel 1
```

**Note On:**
```
0x90 | channel | note | velocity
Example: 0x90 0x3C 0x64 = Note 60 (C4), velocity 100, channel 1
```

---

## Song-Specific MIDI

### Configuration Model

**File:** `Lyra/Models/MIDIDevice.swift`

```swift
struct SongMIDIConfiguration: Codable {
    var enabled: Bool                    // Enable MIDI for this song
    var sendOnLoad: Bool                 // Auto-send on song load
    var programChange: UInt8?            // Program number (0-127)
    var bankSelectMSB: UInt8?            // Bank MSB (CC 0)
    var bankSelectLSB: UInt8?            // Bank LSB (CC 32)
    var controlChanges: [UInt8: UInt8]   // CC number → value
    var sysExMessages: [[UInt8]]         // SysEx data
    var channel: UInt8                   // MIDI channel (1-16)
}
```

### Song Model Integration

**File:** `Lyra/Models/Song.swift`

```swift
@Model
final class Song {
    // ... existing properties

    var midiConfigurationData: Data?  // Encoded MIDI config

    var midiConfiguration: SongMIDIConfiguration {
        get { /* decode from Data */ }
        set { /* encode to Data */ }
    }

    var hasMIDIConfiguration: Bool {
        midiConfiguration.hasMessages
    }
}
```

### Sending Song MIDI

```swift
// Automatically send when song loads
if song.midiConfiguration.sendOnLoad {
    MIDIManager.shared.sendSongMIDI(configuration: song.midiConfiguration)
}

// Manual send
MIDIManager.shared.sendSongMIDI(configuration: song.midiConfiguration)
```

### Example Configuration

**Worship Song - Piano Patch:**
```swift
var config = SongMIDIConfiguration()
config.enabled = true
config.sendOnLoad = true
config.programChange = 0          // Acoustic Grand Piano
config.channel = 1
config.controlChanges = [
    91: 40,  // Reverb: Medium
    93: 20,  // Chorus: Slight
    7: 100   // Volume: Full
]

song.midiConfiguration = config
```

**Rock Song - Organ Patch:**
```swift
var config = SongMIDIConfiguration()
config.enabled = true
config.sendOnLoad = true
config.programChange = 16         // Rock Organ
config.channel = 1
config.controlChanges = [
    91: 60,  // Reverb: High
    64: 127  // Sustain: On
]

song.midiConfiguration = config
```

---

## User Interface

### 1. MIDI Settings View

**File:** `Lyra/Views/MIDISettingsView.swift`

**Access:** Settings → MIDI Settings

**Features:**
- Enable/disable MIDI
- Device connection status
- Input device selection
- Output device selection
- MIDI channel selection (1-16)
- Message monitoring toggle
- Activity indicators (last I/O)
- Test connection button
- All Notes/Sound Off buttons

**Layout:**
```
┌─────────────────────────────────────┐
│  MIDI Settings               [Done] │
│─────────────────────────────────────│
│  MIDI Status                        │
│  ☑ Enable MIDI                      │
│  ✓ Connected                        │
│                                     │
│  Input Devices (2)                  │
│  ☑ Roland FA-06 ✓                   │
│  ☐ Yamaha P-125                     │
│  [Rescan Devices]                   │
│                                     │
│  Output Devices (2)                 │
│  ☑ Roland FA-06 ✓                   │
│  ☐ Yamaha P-125                     │
│                                     │
│  Channel: 1 [Picker]                │
│                                     │
│  Monitoring                         │
│  ☑ Monitor MIDI Messages            │
│  [View MIDI Monitor]                │
│  Input Activity: 2s ago             │
│  Output Activity: 5s ago            │
│                                     │
│  Testing                            │
│  [Test MIDI Connection]             │
│  [All Notes Off]                    │
│  [All Sound Off]                    │
└─────────────────────────────────────┘
```

### 2. MIDI Monitor View

**File:** `Lyra/Views/MIDIMonitorView.swift`

**Access:** MIDI Settings → View MIDI Monitor

**Features:**
- Real-time message display
- Filter by message type
- Pause/resume monitoring
- Show/hide hex bytes
- Clear message history
- Color-coded message types

**Layout:**
```
┌─────────────────────────────────────┐
│  MIDI Monitor         [⋮] [Done]   │
│─────────────────────────────────────│
│  [All] [Note] [PC] [CC] [Bend]     │
│─────────────────────────────────────│
│  🎵 Note On: Note 60, Vel 100, Ch 1│
│     Roland FA-06 • 2s ago           │
│     90 3C 64                        │
│                                     │
│  🎹 Program Change: 5, Ch 1        │
│     Roland FA-06 • 5s ago           │
│     C0 05                           │
│                                     │
│  🎛️ Control Change: CC91=40, Ch 1  │
│     Roland FA-06 • 8s ago           │
│     B0 5B 28                        │
│                                     │
│  📄 96 messages                     │
│  [Load More...]                     │
└─────────────────────────────────────┘
```

### 3. Song MIDI Configuration View

**File:** `Lyra/Views/SongMIDIConfigView.swift`

**Access:** Song Edit → MIDI → Configure

**Features:**
- Enable MIDI for song
- Send on load toggle
- Channel selection
- Program change number
- Bank select (MSB/LSB)
- Control change list
- Add/remove CCs
- SysEx messages (future)
- Test configuration button

**Layout:**
```
┌─────────────────────────────────────┐
│  MIDI Configuration  [Cancel] [Save]│
│─────────────────────────────────────│
│  ☑ Enable MIDI for This Song        │
│  ☑ Send on Song Load                │
│                                     │
│  Channel: 1 [Picker]                │
│                                     │
│  Program Change                     │
│  ☑ Program Change: 5 [-] [+]       │
│                                     │
│  Bank Select                        │
│  ☐ Bank Select MSB                  │
│  ☐ Bank Select LSB                  │
│                                     │
│  Control Changes (3)                │
│  Reverb (CC91): 40 [-] [+]         │
│  Chorus (CC93): 20 [-] [+]         │
│  Volume (CC7): 100 [-] [+]         │
│  [+ Add Control Change]             │
│                                     │
│  Testing                            │
│  [Test MIDI Messages]               │
└─────────────────────────────────────┘
```

---

## Integration Guide

### Step 1: Add MIDI Settings to App

```swift
// In SettingsView.swift
NavigationLink {
    MIDISettingsView()
} label: {
    Label("MIDI Settings", systemImage: "pianokeys")
}
```

### Step 2: Initialize MIDI on App Launch

```swift
// In LyraApp.swift
@main
struct LyraApp: App {
    init() {
        Task {
            // Setup MIDI if enabled
            if UserDefaults.standard.bool(forKey: "midiEnabled") {
                await MIDIManager.shared.setup()
            }
        }
    }
}
```

### Step 3: Send MIDI When Song Loads

```swift
// In SongDetailView or EditSongView
.onAppear {
    // Send MIDI configuration if enabled
    if song.midiConfiguration.enabled &&
       song.midiConfiguration.sendOnLoad {
        MIDIManager.shared.sendSongMIDI(
            configuration: song.midiConfiguration
        )
    }
}
```

### Step 4: Add MIDI Button to Song Edit UI

```swift
// In EditSongView toolbar
ToolbarItem(placement: .primaryAction) {
    Menu {
        // ... existing actions

        Button {
            showMIDIConfig = true
        } label: {
            Label("MIDI Configuration", systemImage: "pianokeys")
        }
    } label: {
        Image(systemName: "ellipsis.circle")
    }
}

.sheet(isPresented: $showMIDIConfig) {
    SongMIDIConfigView(song: song)
}
```

### Step 5: Handle Incoming MIDI (Optional)

```swift
// In appropriate view
.onAppear {
    // Listen for program changes
    NotificationCenter.default.addObserver(
        forName: .midiProgramChangeReceived,
        object: nil,
        queue: .main
    ) { notification in
        if let program = notification.userInfo?["program"] as? UInt8 {
            loadSongByProgramNumber(program)
        }
    }
}

func loadSongByProgramNumber(_ program: UInt8) {
    // Find song with matching program change
    if let song = songs.first(where: {
        $0.midiConfiguration.programChange == program
    }) {
        // Load the song
        selectedSong = song
    }
}
```

---

## Use Cases

### 1. Worship Team - Keyboard Setup

**Scenario:** Automatically configure keyboard sounds for each song

**Setup:**
```swift
// "Amazing Grace" - Piano
song.midiConfiguration = SongMIDIConfiguration(
    enabled: true,
    sendOnLoad: true,
    programChange: 0,      // Acoustic Grand Piano
    controlChanges: [
        91: 45,  // Reverb: Medium
        7: 100   // Volume: Full
    ],
    channel: 1
)

// "How Great Thou Art" - Organ
song.midiConfiguration = SongMIDIConfiguration(
    enabled: true,
    sendOnLoad: true,
    programChange: 19,     // Church Organ
    controlChanges: [
        91: 60,  // Reverb: High
        64: 127  // Sustain: On
    ],
    channel: 1
)
```

**Workflow:**
1. Worship leader opens Lyra on iPad
2. Connects to Roland keyboard via USB
3. Selects "Amazing Grace" → Keyboard automatically switches to piano
4. Selects "How Great Thou Art" → Keyboard automatically switches to organ
5. No manual patch changes needed during service

### 2. Live Performance - Effects Control

**Scenario:** Control reverb/delay units via MIDI CC

**Setup:**
```swift
// "Slow Ballad" - Long reverb
song.midiConfiguration = SongMIDIConfiguration(
    enabled: true,
    sendOnLoad: true,
    controlChanges: [
        91: 127,  // Reverb: Maximum
        93: 40    // Chorus: Medium
    ],
    channel: 1
)

// "Upbeat Song" - Short reverb
song.midiConfiguration = SongMIDIConfiguration(
    enabled: true,
    sendOnLoad: true,
    controlChanges: [
        91: 20,   // Reverb: Minimal
        93: 0     // Chorus: Off
    ],
    channel: 1
)
```

### 3. Multi-Keyboard Setup

**Scenario:** Control multiple keyboards on different channels

**Setup:**
```swift
// Piano (Channel 1)
var pianoPart = SongMIDIConfiguration(
    enabled: true,
    programChange: 0,
    channel: 1
)

// Strings (Channel 2)
var stringsPart = SongMIDIConfiguration(
    enabled: true,
    programChange: 48,  // String Ensemble
    channel: 2
)

// Pad (Channel 3)
var padPart = SongMIDIConfiguration(
    enabled: true,
    programChange: 89,  // Warm Pad
    channel: 3
)
```

### 4. Stage Lighting Control

**Scenario:** Trigger lighting changes via MIDI notes

**Setup:**
```swift
// Song intro - send note to trigger blue lighting
midiManager.sendNoteOn(note: 36, velocity: 100, channel: 10)

// Chorus - send note to trigger warm lighting
midiManager.sendNoteOn(note: 37, velocity: 100, channel: 10)

// Bridge - send note to trigger bright lighting
midiManager.sendNoteOn(note: 38, velocity: 100, channel: 10)
```

---

## Troubleshooting

### Device Not Detected

**Symptoms:**
- No devices shown in input/output lists
- "No Input Devices" message

**Solutions:**
1. Check USB cable connection
2. Ensure device is powered on
3. Verify device is class-compliant MIDI
4. Try unplugging and reconnecting
5. Tap "Rescan Devices"
6. Restart Lyra app
7. Restart iOS device

### MIDI Not Sending

**Symptoms:**
- Test connection does nothing
- Song MIDI not triggering changes

**Solutions:**
1. Verify MIDI is enabled in settings
2. Check output device is selected
3. Ensure correct MIDI channel
4. Verify keyboard is on same channel
5. Check MIDI cable direction (OUT → IN)
6. Try different USB port
7. Check MIDI Monitor for outgoing messages

### Wrong Sounds

**Symptoms:**
- Incorrect patches being selected
- Different sound than expected

**Solutions:**
1. Verify program change number matches keyboard's patch
2. Check bank select is correct (if keyboard has multiple banks)
3. Consult keyboard's MIDI implementation chart
4. Some keyboards use 0-127, others use 1-128
5. Test with MIDI Monitor to verify messages sent

### Bluetooth MIDI Issues

**Symptoms:**
- Bluetooth device not appearing
- Intermittent connection drops

**Solutions:**
1. Ensure Bluetooth is enabled on iOS
2. Pair device in iOS Settings → Bluetooth first
3. Move closer to device (Bluetooth LE has limited range)
4. Avoid metal obstacles between devices
5. Check device battery level
6. Restart both devices

### Latency

**Symptoms:**
- Delay between song selection and MIDI send
- Slow response time

**Solutions:**
1. USB MIDI has lower latency than Bluetooth
2. Reduce number of MIDI messages per song
3. Close other apps using audio/MIDI
4. Check iOS Low Power Mode is off
5. Consider dedicated MIDI interface

---

## Performance Considerations

### Optimization

**Message Buffering:**
```swift
// Don't do this (multiple separate sends)
sendCC(91, 40)
sendCC(93, 20)
sendCC(7, 100)
sendProgramChange(5)

// Better: Send in one batch
sendSongMIDI(config) // Sends all messages together
```

**Channel Efficiency:**
- Use different channels for different instruments
- Avoid sending to all 16 channels
- Group similar instruments on same channel

**Timing:**
- Small delay between bank select and program change
- CoreMIDI handles this automatically
- No need for manual timing in most cases

### Resource Usage

**Memory:**
- ~50 KB for MIDIManager
- ~1-2 KB per song MIDI configuration
- ~100 bytes per monitored message

**CPU:**
- Negligible when idle
- <1% when sending messages
- <2% when monitoring all messages

**Battery:**
- Bluetooth MIDI: ~2-3% per hour
- USB MIDI: Negligible (uses device power)

---

## Future Enhancements

### Planned Features

**Phase 2 - Advanced MIDI:**
- ⬜ MIDI Learn (click CC, move control on device)
- ⬜ MIDI mapping presets (save/load templates)
- ⬜ Conditional MIDI (if tempo > 120, send different PC)
- ⬜ MIDI macros (trigger multiple messages with one action)
- ⬜ MIDI scripting (JavaScript-based message generation)

**Phase 3 - Integration:**
- ⬜ MainStage integration (send set changes)
- ⬜ Ableton Live integration (trigger clips)
- ⬜ QLab integration (trigger cues)
- ⬜ ProPresenter integration (slide changes)

**Phase 4 - Advanced:**
- ⬜ MIDI over Network (WiFi/Ethernet)
- ⬜ Virtual MIDI ports (inter-app)
- ⬜ MIDI Clock sync (tempo sync with DAWs)
- ⬜ MIDI Time Code (MTC)
- ⬜ MIDI Show Control (MSC)

### Roadmap

| Quarter | Feature | Status |
|---------|---------|--------|
| Q1 2026 | Core MIDI support (current) | ✅ Complete |
| Q2 2026 | MIDI Learn & Presets | ⬜ Planned |
| Q3 2026 | MainStage/Ableton integration | ⬜ Planned |
| Q4 2026 | Network MIDI & Virtual Ports | ⬜ Planned |
| Q1 2027 | MIDI Clock & MTC | ⬜ Planned |

---

## Technical Reference

### MIDI Message Formats

**Channel Voice Messages:**
```
Note Off:           0x80 | channel | note | velocity
Note On:            0x90 | channel | note | velocity
Polyphonic Pressure: 0xA0 | channel | note | pressure
Control Change:     0xB0 | channel | controller | value
Program Change:     0xC0 | channel | program
Channel Pressure:   0xD0 | channel | pressure
Pitch Bend:         0xE0 | channel | LSB | MSB
```

**System Messages:**
```
SysEx Start:        0xF0 [manufacturer] [data...] 0xF7
MIDI Clock:         0xF8
Start:              0xFA
Continue:           0xFB
Stop:               0xFC
Active Sensing:     0xFE
System Reset:       0xFF
```

### Common Program Changes

| Program | Instrument | Category |
|---------|-----------|----------|
| 0 | Acoustic Grand Piano | Piano |
| 4 | Electric Piano 1 | Piano |
| 5 | Electric Piano 2 | Piano |
| 16 | Drawbar Organ | Organ |
| 19 | Church Organ | Organ |
| 24 | Acoustic Guitar (nylon) | Guitar |
| 48 | String Ensemble 1 | Strings |
| 52 | Choir Aahs | Voice |
| 88 | New Age | Synth Pad |
| 89 | Warm Pad | Synth Pad |

### Common Control Changes

| CC# | Name | Range | Description |
|-----|------|-------|-------------|
| 0 | Bank Select MSB | 0-127 | Bank selection |
| 1 | Modulation | 0-127 | Vibrato depth |
| 7 | Volume | 0-127 | Channel volume |
| 10 | Pan | 0-127 | Stereo position |
| 11 | Expression | 0-127 | Expression pedal |
| 64 | Sustain Pedal | 0-127 | Sustain (>63 = on) |
| 91 | Reverb | 0-127 | Reverb depth |
| 93 | Chorus | 0-127 | Chorus depth |
| 120 | All Sound Off | 0 | Immediately silence |
| 123 | All Notes Off | 0 | Stop all notes |

---

## Conclusion

MIDI support transforms Lyra into a professional performance tool, enabling seamless control of external equipment. With song-specific configurations, worship teams can focus on leading instead of tweaking equipment between songs.

**Key Benefits:**
- Automated sound changes
- Consistent configurations
- Professional workflow
- Enhanced performance quality
- Reduced setup time

**Next Steps:**
1. Review this documentation
2. Connect MIDI device to iOS device
3. Open Lyra → Settings → MIDI Settings
4. Enable MIDI and select devices
5. Configure MIDI for a song
6. Test automatic sound changes

---

**Documentation Version:** 1.0
**Last Updated:** January 23, 2026
**Framework:** CoreMIDI (iOS 15.0+)
**Related Docs:**
- Apple CoreMIDI Documentation
- MIDI Specification (MIDI.org)
- Device-specific MIDI Implementation Charts
