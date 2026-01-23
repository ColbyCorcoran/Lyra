# Stage Monitor System

Lyra's comprehensive stage monitor system allows band and team members to view customized information on monitors placed on stage during live performances.

## Overview

The stage monitor system provides:

- **Multiple layout options** for different viewing needs
- **Per-musician customization** with role-based presets
- **Multi-monitor support** for multiple physical displays
- **Network monitor mode** for wireless iPads/iPhones
- **Leader control** for managing all monitors from a single device
- **Monitor presets** for quick setup and configuration saving

## Monitor Layouts

### 1. Chords Only
- Extra large chord display
- Maximum readability from a distance
- Optional next section preview
- Perfect for guitarists and instrumentalists

### 2. Chords + Lyrics
- Chords aligned above lyrics
- Balanced layout for full context
- Configurable font sizes
- Ideal for keys, rhythm guitar, and vocalists who need chord reference

### 3. Current + Next Section
- Side-by-side view of current and upcoming sections
- 70/30 split layout
- Preview helps with transitions
- Great for leaders and tech booth

### 4. Song Structure Overview
- Full song outline with current section highlighted
- Shows all verses, choruses, bridges
- Progress indicator
- Perfect for drummers and those tracking song flow

### 5. Lyrics Only
- Large, centered lyrics
- Clean, distraction-free view
- Optimized for vocalists
- Maximum font size for readability

### 6. Custom Layout
- User-defined configurations
- Mix and match elements
- Save custom layouts per musician

## Monitor Roles

The system includes optimized presets for different band positions:

### Vocalist
- **Default Layout**: Lyrics Only
- **Features**: Extra large text, key and capo display
- **Color**: White text on black background

### Lead Guitar
- **Default Layout**: Chords Only
- **Features**: Extra large chords (72pt), green text
- **Color**: Green chords (#00FF00)

### Rhythm Guitar
- **Default Layout**: Chords Only
- **Features**: Large chords with section labels
- **Color**: Green chords

### Bass
- **Default Layout**: Chords Only
- **Features**: Chord roots and structure
- **Color**: Deep sky blue (#00BFFF)

### Keys/Piano
- **Default Layout**: Chords + Lyrics
- **Features**: Balanced chord and lyric display
- **Color**: Hot pink chords (#FF69B4)

### Drummer
- **Default Layout**: Song Structure Overview
- **Features**: Compact structure view, section tracking
- **Color**: Standard white

### Audience Display
- **Default Layout**: Lyrics Only
- **Features**: Large centered lyrics for congregation
- **Margins**: Extra wide for professional look

### Tech Booth
- **Default Layout**: Current + Next
- **Features**: Preview and metadata display
- **Purpose**: Monitor performance flow

## Multi-Monitor Setup

### Physical Displays

Connect multiple external displays via:
- HDMI adapters
- USB-C display connections
- AirPlay-enabled displays
- Hardware display switchers

The system automatically detects connected displays and assigns them to configured monitor zones based on priority order.

### Configuration Steps

1. **Create a Setup**
   - Navigate to Settings → Stage Monitors
   - Tap "New Setup"
   - Name your setup (e.g., "Full Band", "Worship Team")
   - Add description

2. **Add Monitors**
   - Tap "Add Monitor"
   - Select role (Vocalist, Lead, Bass, etc.)
   - System applies optimal defaults
   - Customize if needed

3. **Configure Individual Monitors**
   - Adjust font sizes (24-144pt)
   - Choose colors and themes
   - Set layout preferences
   - Configure metadata display

4. **Save and Activate**
   - Save your setup
   - Activate for current session
   - Setup persists across sessions

### Quick Presets

Pre-configured setups for common scenarios:

**Small Band (3-4 members)**
- Vocalist monitor (lyrics only)
- Lead guitar monitor (chords only)
- Bass monitor (chords only)
- Drummer monitor (song structure)

**Full Band (5-6 members)**
- Vocalist monitor
- Lead guitar monitor
- Rhythm guitar monitor
- Bass monitor
- Keys monitor
- Drummer monitor

**Worship Team**
- Vocalist monitor
- Keys monitor
- Lead guitar monitor
- Audience display (large lyrics)

## Network Monitor Mode

### Overview

Network mode allows iPads, iPhones, and other devices to connect wirelessly as stage monitors, eliminating the need for physical display connections.

### Network Modes

#### Local Mode
- Single device with multiple physical displays
- No network required
- Lowest latency

#### WiFi Mode
- Connect devices via WiFi network
- Manual IP address configuration
- Works on any WiFi network

#### Bonjour/Auto-Discovery
- Automatic device discovery on local network
- Zero-configuration setup
- Recommended for most users

#### Cloud Mode
- CloudKit-based synchronization
- Works across different networks
- Internet connection required

### Setting Up Network Monitors

1. **Enable Network Mode**
   - Settings → Stage Monitors → Network
   - Toggle "Enable Network Monitors"
   - Choose network mode (Bonjour recommended)

2. **Configure Security** (Optional)
   - Enable "Require Authentication"
   - Set passphrase
   - Prevents unauthorized connections

3. **Connect Devices**
   - On remote device: Open Lyra
   - Navigate to Stage Monitor → Join Session
   - Select leader device from list
   - Enter passphrase if required
   - Choose monitor role

4. **Configure Remote Monitor**
   - Each device can customize their view
   - Leader can override if needed
   - Settings persist per device

### Performance Settings

**Broadcast Interval**: 50-1000ms
- Lower = more responsive, higher bandwidth
- Default: 100ms provides <100ms latency
- Adjust based on network conditions

**Max Latency**: 50-500ms
- Connection drops if latency exceeds this
- Default: 100ms
- Increase for unstable networks

### Troubleshooting Network Monitors

**Devices not appearing:**
- Ensure all devices on same WiFi network
- Check firewall settings
- Verify Bonjour services enabled
- Restart network discovery

**High latency:**
- Reduce broadcast interval
- Move closer to WiFi router
- Switch to 5GHz WiFi band
- Reduce number of connected devices

**Connection drops:**
- Increase max latency setting
- Disable "Auto Reconnect" temporarily
- Check for WiFi interference
- Use wired connection for leader device

## Leader Control

### Overview

Leader mode allows one device to control all monitors (local and network) from a single interface.

### Leader Control Panel

Access: Open app → Stage Monitor → Leader Control

**Features:**

1. **Blank/Unblank All Monitors**
   - Instant blackout of all displays
   - Useful for transitions, announcements, breaks
   - One-tap restore

2. **Individual Monitor Control**
   - Blank specific monitors
   - Override monitor configuration
   - View connection status

3. **Send Messages**
   - Broadcast text messages to all monitors
   - Brief overlay display
   - Useful for quick communication

4. **Navigation Control**
   - Advance to next section
   - Go back to previous section
   - Jump to specific section
   - All monitors sync automatically

5. **Song Selection**
   - Change songs
   - Monitors update instantly
   - Maintains sync across all devices

### Leader Commands

#### Blank All
```
manager.areAllMonitorsBlanked = true
```
Hides content on all monitors while keeping connections active.

#### Send Message
```
manager.sendMessageToMonitors("5 minute break")
```
Displays message overlay on all monitors.

#### Override Monitor
```
manager.overrideMonitor(zoneId: id, configuration: config)
```
Temporarily changes a specific monitor's configuration.

#### Change Section
```
manager.goToSection(index)
```
Jumps all monitors to a specific section.

## Monitor Presets

### Saving Configurations

1. **Create Custom Configuration**
   - Configure a monitor exactly as desired
   - Settings → Stage Monitors → Active Setup
   - Tap monitor to edit
   - Adjust all settings

2. **Save Setup**
   - Name your configuration
   - Add description (optional)
   - Save

3. **Quick Recall**
   - Settings → Stage Monitors → Saved Setups
   - Tap setup to activate
   - All monitors reconfigure instantly

### Preset Management

**Export Presets** (Future feature)
- Share configurations with other devices
- Cloud sync via iCloud
- Team-wide standardization

**Per-Set Presets** (Future feature)
- Different monitor setups per performance set
- Automatic switching
- Role changes mid-performance

## Customization Options

### Font Settings

- **Font Size**: 24-120pt (general), 32-144pt (chords), 24-120pt (lyrics)
- **Font Family**: System, Monospaced, Georgia, Courier
- **Font Weight**: Light, Regular, Medium, Bold

### Color Settings

- **Background Color**: Any hex color (#000000 to #FFFFFF)
- **Text Color**: Primary text color
- **Chord Color**: Highlighted chord color
- **Accent Color**: Section labels, metadata
- **Theme**: Dark or Light
- **High Contrast Mode**: Enhanced visibility

### Layout Settings

- **Horizontal Margin**: 0-200pt
- **Vertical Margin**: 0-200pt
- **Line Spacing**: 0-40pt
- **Compact Mode**: Tighter spacing for more content
- **Text Alignment**: Left, Center, Right

### Content Options

- **Show Section Labels**: Display "Verse 1", "Chorus", etc.
- **Show Song Metadata**: Title, artist, key, tempo, capo
- **Show Next Section**: Preview upcoming section
- **Show Transpose**: Current key displayed
- **Show Capo**: Capo position if used

## Best Practices

### For Bands

1. **Pre-Performance Setup**
   - Test all monitors before performance
   - Verify network connections
   - Check visibility from stage positions
   - Save configuration as preset

2. **During Rehearsal**
   - Each musician fine-tunes their monitor
   - Test section transitions
   - Verify sync timing
   - Practice with leader control

3. **During Performance**
   - Leader controls navigation
   - Musicians focus on their monitors
   - Use blank function during breaks
   - Monitor network status

### For Tech Teams

1. **Display Setup**
   - Position monitors for optimal viewing angles
   - Use high-quality displays (1080p+ recommended)
   - Secure cables and connections
   - Label displays by role

2. **Network Setup**
   - Use dedicated WiFi network for monitors
   - 5GHz band preferred
   - Router positioned centrally
   - Wired connection for leader device

3. **Backup Plan**
   - Keep physical lyric sheets as backup
   - Have spare display cables
   - Test fail-over scenarios
   - Document setup for team

### Stage Lighting Considerations

- **Dark Stages**: Use light text on dark background
- **Bright Stages**: High contrast mode, increase brightness
- **Colored Lighting**: Adjust monitor colors to complement stage lights
- **Backlit Stages**: Position monitors to avoid glare

### Font Size Guidelines

**Distance-based recommendations:**

- **3-5 feet**: 40-60pt
- **5-10 feet**: 60-80pt
- **10-15 feet**: 80-120pt
- **15+ feet**: 120-144pt

Test from actual stage positions during setup.

## Troubleshooting

### Display Issues

**Monitor not showing content:**
- Check display connection
- Verify monitor is not blanked
- Confirm song is loaded
- Restart display connection

**Wrong content showing:**
- Check monitor role assignment
- Verify layout type
- Confirm active setup
- Review configuration

**Text too small/large:**
- Adjust font size in monitor settings
- Test visibility from performance position
- Save adjusted configuration

### Network Issues

**Device not connecting:**
- Verify same WiFi network
- Check authentication passphrase
- Restart network service
- Try manual IP connection

**Lag/delay:**
- Reduce broadcast interval
- Move closer to router
- Check network congestion
- Disable other network services

**Frequent disconnections:**
- Increase max latency setting
- Check WiFi signal strength
- Update device software
- Use wired connection for leader

### Configuration Issues

**Settings not saving:**
- Ensure setup is named
- Check storage permissions
- Verify not in demo mode
- Restart app

**Preset not loading:**
- Confirm preset exists
- Check for corrupted data
- Re-create configuration
- Contact support

## Technical Details

### System Requirements

- **iOS**: 17.0 or later
- **iPadOS**: 17.0 or later
- **Hardware**: A12 Bionic or later recommended
- **Display**: External display support via adapter
- **Network**: WiFi or Ethernet for network monitors

### Performance

- **Latency**: <100ms typical (network mode)
- **Refresh Rate**: 60Hz display output
- **Max Monitors**: Unlimited (practical limit ~20 network monitors)
- **Bandwidth**: ~10-50 KB/s per monitor

### Data Models

- `StageMonitorConfiguration`: Individual monitor settings
- `MonitorZone`: Physical or network monitor assignment
- `MultiMonitorSetup`: Collection of monitor zones
- `StageNetworkConfiguration`: Network settings
- `NetworkMonitorDevice`: Connected network device
- `LeaderMessage`: Control commands

### Managers

- `StageMonitorManager`: Main coordinator (singleton)
- `ExternalDisplayManager`: Legacy external display support
- Network services via Apple's Network framework

## API Integration

### For Developers

```swift
// Access the manager
let manager = StageMonitorManager.shared

// Display a song
manager.displaySong(parsedSong, sectionIndex: 0)

// Navigate sections
manager.advanceSection()
manager.previousSection()
manager.goToSection(index)

// Leader control
manager.blankAllMonitors()
manager.unblankAllMonitors()
manager.sendMessageToMonitors("Break time!")

// Configuration
let config = StageMonitorConfiguration.forRole(.lead)
let zone = MonitorZone(role: .lead, priority: 1, configuration: config)
manager.updateMonitorZone(zone)

// Setup management
let setup = MultiMonitorSetup.fullBand
manager.activeSetup = setup
```

### Notifications

```swift
// Listen for events
NotificationCenter.default.addObserver(
    forName: .stageMonitorConfigurationChanged,
    object: nil,
    queue: .main
) { notification in
    // Handle configuration change
}

// Available notifications
.stageMonitorConfigurationChanged
.stageMonitorNetworkDeviceConnected
.stageMonitorNetworkDeviceDisconnected
.stageMonitorLeaderCommandReceived
.stageMonitorContentUpdated
```

## Future Enhancements

### Planned Features

- **Remote Monitor App**: Standalone app for remote devices
- **Video Output**: Camera feed overlay on monitors
- **Timeline View**: Show performance timeline
- **MIDI Integration**: Trigger monitor changes via MIDI
- **Advanced Layouts**: Custom layout designer with drag-and-drop
- **Recording**: Save monitor views for review
- **Analytics**: Track which layouts work best
- **Team Sync**: Share configurations across team

### Community Requests

Submit feature requests and feedback:
- GitHub: [github.com/lyra-app/lyra/issues](https://github.com/lyra-app/lyra/issues)
- Email: support@lyra-app.com

## Support

For help with stage monitors:

1. **In-App Help**: Settings → Stage Monitors → Help & Documentation
2. **Video Tutorials**: [lyra-app.com/tutorials/stage-monitors](https://lyra-app.com/tutorials/stage-monitors)
3. **Community Forum**: [forum.lyra-app.com](https://forum.lyra-app.com)
4. **Email Support**: support@lyra-app.com

## Credits

Stage Monitor System developed for Lyra by the Lyra development team.

Special thanks to the beta testing community for feedback and feature requests.

---

*Last Updated: January 2026*
*Version: 1.0*
*Compatible with: Lyra 2.0+*
