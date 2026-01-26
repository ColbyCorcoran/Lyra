//
//  MIDIManager.swift
//  Lyra
//
//  Manages MIDI devices, input/output, and message handling
//

import Foundation
import CoreMIDI
import Combine

// MARK: - MIDI Manager

@MainActor
@Observable
class MIDIManager {
    static let shared = MIDIManager()

    // MARK: - State

    var isEnabled: Bool = false
    var isConnected: Bool = false

    var inputDevices: [MIDIDevice] = []
    var outputDevices: [MIDIDevice] = []
    var selectedInputDevice: MIDIDevice?
    var selectedOutputDevice: MIDIDevice?

    var selectedChannel: UInt8 = 1 // 1-16

    var recentMessages: [MIDIMessage] = []
    var isMonitoring: Bool = false
    var maxRecentMessages: Int = 100

    // Activity indicators
    var lastInputActivity: Date?
    var lastOutputActivity: Date?

    // MARK: - CoreMIDI References

    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var outputPort: MIDIPortRef = 0

    // MARK: - Initialization

    private init() {
        loadSettings()
    }

    // MARK: - Setup

    func setup() async {
        guard !isConnected else { return }

        do {
            try setupMIDIClient()
            try setupPorts()
            await scanDevices()
            isConnected = true
            print("✅ MIDI setup complete")
        } catch {
            print("❌ MIDI setup failed: \(error)")
            isConnected = false
        }
    }

    private func setupMIDIClient() throws {
        var client: MIDIClientRef = 0

        let status = MIDIClientCreateWithBlock("LyraMIDIClient" as CFString, &client) { notificationPtr in
            // Handle MIDI notifications (device added/removed)
            Task { @MainActor in
                await self.handleMIDINotification(notificationPtr)
            }
        }

        guard status == noErr else {
            throw MIDIError.clientCreationFailed
        }

        self.midiClient = client
    }

    private func setupPorts() throws {
        // Create input port
        var inPort: MIDIPortRef = 0
        let inputStatus = MIDIInputPortCreateWithProtocol(
            midiClient,
            "LyraMIDIInput" as CFString,
            ._1_0,
            &inPort
        ) { [weak self] eventList, srcConnRefCon in
            Task { @MainActor in
                await self?.handleMIDIInput(eventList: eventList)
            }
        }

        guard inputStatus == noErr else {
            throw MIDIError.portCreationFailed
        }

        self.inputPort = inPort

        // Create output port
        var outPort: MIDIPortRef = 0
        let outputStatus = MIDIOutputPortCreate(
            midiClient,
            "LyraMIDIOutput" as CFString,
            &outPort
        )

        guard outputStatus == noErr else {
            throw MIDIError.portCreationFailed
        }

        self.outputPort = outPort
    }

    // MARK: - Device Scanning

    func scanDevices() async {
        let previousInputCount = inputDevices.count
        let previousOutputCount = outputDevices.count
        let previousDeviceNames = Set(inputDevices.map { $0.name } + outputDevices.map { $0.name })

        var newInputDevices: [MIDIDevice] = []
        var newOutputDevices: [MIDIDevice] = []

        // Scan sources (input devices)
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let endpoint = MIDIGetSource(i)
            if let device = createDevice(from: endpoint, isInput: true) {
                newInputDevices.append(device)
            }
        }

        // Scan destinations (output devices)
        let destCount = MIDIGetNumberOfDestinations()
        for i in 0..<destCount {
            let endpoint = MIDIGetDestination(i)
            if let device = createDevice(from: endpoint, isInput: false) {
                newOutputDevices.append(device)
            }
        }

        let newDeviceNames = Set(newInputDevices.map { $0.name } + newOutputDevices.map { $0.name })

        inputDevices = newInputDevices
        outputDevices = newOutputDevices

        print("📡 Found \(inputDevices.count) input devices, \(outputDevices.count) output devices")

        // Detect device additions
        let addedDevices = newDeviceNames.subtracting(previousDeviceNames)
        for deviceName in addedDevices {
            NotificationCenter.default.post(
                name: .midiDeviceConnected,
                object: nil,
                userInfo: ["deviceName": deviceName]
            )
        }

        // Detect device removals
        let removedDevices = previousDeviceNames.subtracting(newDeviceNames)
        for deviceName in removedDevices {
            NotificationCenter.default.post(
                name: .midiDeviceDisconnected,
                object: nil,
                userInfo: ["deviceName": deviceName]
            )
        }

        // Auto-select first device if none selected
        if selectedInputDevice == nil, let first = inputDevices.first {
            selectedInputDevice = first
            connectToInputDevice(first)
        }

        if selectedOutputDevice == nil, let first = outputDevices.first {
            selectedOutputDevice = first
        }
    }

    private func createDevice(from endpoint: MIDIEndpointRef, isInput: Bool) -> MIDIDevice? {
        guard endpoint != 0 else { return nil }

        let name = getStringProperty(endpoint, kMIDIPropertyName) ?? "Unknown Device"
        let manufacturer = getStringProperty(endpoint, kMIDIPropertyManufacturer)
        let model = getStringProperty(endpoint, kMIDIPropertyModel)
        let uniqueID = getIntProperty(endpoint, kMIDIPropertyUniqueID) ?? 0

        return MIDIDevice(
            name: name,
            manufacturer: manufacturer,
            model: model,
            uniqueID: uniqueID,
            isInput: isInput,
            isOutput: !isInput,
            isConnected: true,
            isEnabled: true,
            endpointRef: endpoint
        )
    }

    private func getStringProperty(_ ref: MIDIObjectRef, _ property: CFString) -> String? {
        var value: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(ref, property, &value)
        guard status == noErr, let cfString = value?.takeRetainedValue() else {
            return nil
        }
        return cfString as String
    }

    private func getIntProperty(_ ref: MIDIObjectRef, _ property: CFString) -> Int32? {
        var value: Int32 = 0
        let status = MIDIObjectGetIntegerProperty(ref, property, &value)
        guard status == noErr else { return nil }
        return value
    }

    // MARK: - Device Connection

    func connectToInputDevice(_ device: MIDIDevice) {
        guard let endpoint = device.endpointRef else { return }

        // Disconnect previous device
        if let previous = selectedInputDevice?.endpointRef {
            MIDIPortDisconnectSource(inputPort, previous)
        }

        // Connect to new device
        let status = MIDIPortConnectSource(inputPort, endpoint, nil)
        if status == noErr {
            selectedInputDevice = device
            print("🔌 Connected to input: \(device.name)")
        } else {
            print("❌ Failed to connect to input: \(device.name)")
        }
    }

    func disconnectInputDevice() {
        guard let device = selectedInputDevice, let endpoint = device.endpointRef else {
            return
        }

        MIDIPortDisconnectSource(inputPort, endpoint)
        selectedInputDevice = nil
        print("🔌 Disconnected input device")
    }

    // MARK: - MIDI Input Handling

    private func handleMIDIInput(eventList: UnsafePointer<MIDIEventList>) {
        let packets = eventList.pointee

        var packet = packets.packet
        for _ in 0..<packets.numPackets {
            let bytes = withUnsafeBytes(of: packet.words) { buffer -> [UInt8] in
                let count = Int(packet.wordCount) * 4
                return Array(buffer.prefix(count))
            }

            if let message = MIDIMessage.parse(
                bytes: bytes,
                deviceName: selectedInputDevice?.name
            ) {
                handleIncomingMessage(message)
            }

            packet = MIDIEventPacketNext(&packet).pointee
        }
    }

    private func handleIncomingMessage(_ message: MIDIMessage) {
        // Update activity indicator
        lastInputActivity = Date()

        // Add to recent messages
        if isMonitoring {
            recentMessages.insert(message, at: 0)
            if recentMessages.count > maxRecentMessages {
                recentMessages = Array(recentMessages.prefix(maxRecentMessages))
            }
        }

        // Post notification for other components
        NotificationCenter.default.post(
            name: .midiMessageReceived,
            object: nil,
            userInfo: ["message": message]
        )

        // Handle specific message types
        switch message.type {
        case .programChange:
            handleProgramChange(program: message.data1, channel: message.channel)

        case .controlChange:
            handleControlChange(
                controller: message.data1,
                value: message.data2 ?? 0,
                channel: message.channel
            )

        case .noteOn:
            handleNoteOn(
                note: message.data1,
                velocity: message.data2 ?? 0,
                channel: message.channel
            )

        default:
            break
        }
    }

    private func handleProgramChange(program: UInt8, channel: UInt8) {
        print("🎹 Program Change: \(program) on channel \(channel)")
        // Could trigger song loading based on program number
        NotificationCenter.default.post(
            name: .midiProgramChangeReceived,
            object: nil,
            userInfo: ["program": program, "channel": channel]
        )
    }

    private func handleControlChange(controller: UInt8, value: UInt8, channel: UInt8) {
        print("🎛️ Control Change: CC\(controller) = \(value) on channel \(channel)")
        // Could adjust settings based on CC
        NotificationCenter.default.post(
            name: .midiControlChangeReceived,
            object: nil,
            userInfo: ["controller": controller, "value": value, "channel": channel]
        )
    }

    private func handleNoteOn(note: UInt8, velocity: UInt8, channel: UInt8) {
        guard velocity > 0 else { return } // Velocity 0 is note off

        print("🎵 Note On: \(note) velocity \(velocity) on channel \(channel)")
        // Could trigger actions based on specific notes
        NotificationCenter.default.post(
            name: .midiNoteOnReceived,
            object: nil,
            userInfo: ["note": note, "velocity": velocity, "channel": channel]
        )
    }

    // MARK: - MIDI Output Sending

    func sendProgramChange(program: UInt8, channel: UInt8? = nil) {
        let ch = (channel ?? selectedChannel) - 1 // Convert to 0-15
        let bytes: [UInt8] = [0xC0 | ch, program & 0x7F]
        sendMIDIBytes(bytes)
        print("📤 Sent Program Change: \(program) on channel \(channel ?? selectedChannel)")
    }

    func sendControlChange(controller: UInt8, value: UInt8, channel: UInt8? = nil) {
        let ch = (channel ?? selectedChannel) - 1 // Convert to 0-15
        let bytes: [UInt8] = [0xB0 | ch, controller & 0x7F, value & 0x7F]
        sendMIDIBytes(bytes)
        print("📤 Sent Control Change: CC\(controller) = \(value) on channel \(channel ?? selectedChannel)")
    }

    func sendNoteOn(note: UInt8, velocity: UInt8, channel: UInt8? = nil) {
        let ch = (channel ?? selectedChannel) - 1 // Convert to 0-15
        let bytes: [UInt8] = [0x90 | ch, note & 0x7F, velocity & 0x7F]
        sendMIDIBytes(bytes)
        print("📤 Sent Note On: \(note) velocity \(velocity) on channel \(channel ?? selectedChannel)")
    }

    func sendNoteOff(note: UInt8, velocity: UInt8 = 64, channel: UInt8? = nil) {
        let ch = (channel ?? selectedChannel) - 1 // Convert to 0-15
        let bytes: [UInt8] = [0x80 | ch, note & 0x7F, velocity & 0x7F]
        sendMIDIBytes(bytes)
        print("📤 Sent Note Off: \(note) on channel \(channel ?? selectedChannel)")
    }

    func sendSysEx(data: [UInt8]) {
        var bytes: [UInt8] = [0xF0] // SysEx start
        bytes.append(contentsOf: data)
        bytes.append(0xF7) // SysEx end
        sendMIDIBytes(bytes)
        print("📤 Sent SysEx: \(bytes.count) bytes")
    }

    func sendAllNotesOff(channel: UInt8? = nil) {
        sendControlChange(controller: 123, value: 0, channel: channel)
        print("📤 Sent All Notes Off on channel \(channel ?? selectedChannel)")
    }

    func sendAllSoundOff(channel: UInt8? = nil) {
        sendControlChange(controller: 120, value: 0, channel: channel)
        print("📤 Sent All Sound Off on channel \(channel ?? selectedChannel)")
    }

    private func sendMIDIBytes(_ bytes: [UInt8]) {
        guard isEnabled, isConnected else {
            print("⚠️ MIDI not enabled or connected")
            return
        }

        guard let device = selectedOutputDevice, let endpoint = device.endpointRef else {
            print("⚠️ No output device selected")
            return
        }

        // Create MIDI packet list
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)

        packet = MIDIPacketListAdd(
            &packetList,
            1024,
            packet,
            0,
            bytes.count,
            bytes
        )

        guard packet != nil else {
            print("❌ Failed to create MIDI packet")
            return
        }

        // Send packet
        let status = MIDISend(outputPort, endpoint, &packetList)
        if status == noErr {
            lastOutputActivity = Date()

            // Add to monitoring
            if isMonitoring, let message = MIDIMessage.parse(bytes: bytes, deviceName: device.name) {
                recentMessages.insert(message, at: 0)
                if recentMessages.count > maxRecentMessages {
                    recentMessages = Array(recentMessages.prefix(maxRecentMessages))
                }
            }
        } else {
            print("❌ Failed to send MIDI: \(status)")
        }
    }

    // MARK: - Song MIDI Configuration

    func sendSongMIDI(configuration: SongMIDIConfiguration) {
        guard configuration.enabled, isEnabled, isConnected else { return }

        print("🎵 Sending song MIDI configuration...")

        // Bank Select (if specified)
        if let msb = configuration.bankSelectMSB {
            sendControlChange(controller: 0, value: msb, channel: configuration.channel)
        }

        if let lsb = configuration.bankSelectLSB {
            sendControlChange(controller: 32, value: lsb, channel: configuration.channel)
        }

        // Program Change
        if let program = configuration.programChange {
            sendProgramChange(program: program, channel: configuration.channel)
        }

        // Control Changes
        for (controller, value) in configuration.controlChanges {
            sendControlChange(controller: controller, value: value, channel: configuration.channel)
        }

        // SysEx Messages
        for sysExData in configuration.sysExMessages {
            sendSysEx(data: sysExData)
        }

        print("✅ Song MIDI configuration sent")
    }

    // MARK: - Notifications

    private func handleMIDINotification(_ notificationPtr: UnsafePointer<MIDINotification>) {
        let notification = notificationPtr.pointee

        switch notification.messageID {
        case .msgObjectAdded, .msgObjectRemoved:
            print("🔔 MIDI device added/removed, rescanning...")
            Task {
                await scanDevices()
            }

        case .msgPropertyChanged:
            print("🔔 MIDI property changed")

        case .msgSetupChanged:
            print("🔔 MIDI setup changed, rescanning...")
            Task {
                await scanDevices()
            }

        default:
            break
        }
    }

    // MARK: - Settings

    func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "midiEnabled")
        selectedChannel = UInt8(UserDefaults.standard.integer(forKey: "midiChannel"))
        if selectedChannel == 0 {
            selectedChannel = 1
        }
        isMonitoring = UserDefaults.standard.bool(forKey: "midiMonitoring")
    }

    func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "midiEnabled")
        UserDefaults.standard.set(selectedChannel, forKey: "midiChannel")
        UserDefaults.standard.set(isMonitoring, forKey: "midiMonitoring")
    }

    // MARK: - Testing

    func testConnection() {
        print("🧪 Testing MIDI connection...")

        // Send test note
        sendNoteOn(note: 60, velocity: 100) // Middle C

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sendNoteOff(note: 60)
        }

        print("✅ Test complete - check for MIDI activity")
    }

    // MARK: - Cleanup

    func cleanup() {
        disconnectInputDevice()

        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }

        if outputPort != 0 {
            MIDIPortDispose(outputPort)
        }

        if midiClient != 0 {
            MIDIClientDispose(midiClient)
        }

        isConnected = false
        print("🧹 MIDI cleanup complete")
    }
}

// MARK: - MIDI Error

enum MIDIError: Error, LocalizedError {
    case clientCreationFailed
    case portCreationFailed
    case deviceNotFound
    case sendFailed

    var errorDescription: String? {
        switch self {
        case .clientCreationFailed:
            return "Failed to create MIDI client"
        case .portCreationFailed:
            return "Failed to create MIDI port"
        case .deviceNotFound:
            return "MIDI device not found"
        case .sendFailed:
            return "Failed to send MIDI message"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let midiMessageReceived = Notification.Name("midiMessageReceived")
    static let midiProgramChangeReceived = Notification.Name("midiProgramChangeReceived")
    static let midiControlChangeReceived = Notification.Name("midiControlChangeReceived")
    static let midiNoteOnReceived = Notification.Name("midiNoteOnReceived")
    static let midiDeviceConnected = Notification.Name("midiDeviceConnected")
    static let midiDeviceDisconnected = Notification.Name("midiDeviceDisconnected")
}
