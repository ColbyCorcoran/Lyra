//
//  StageMonitorManager.swift
//  Lyra
//
//  Manager for stage monitor system with multi-monitor and network support
//

import Foundation
import UIKit
import SwiftUI
import Observation
import Network

/// Manager for stage monitors
@Observable
class StageMonitorManager {
    static let shared = StageMonitorManager()

    // MARK: - Properties

    /// Active monitor zones (local displays)
    private(set) var monitorZones: [MonitorZone] = []

    /// Physical display windows
    private var displayWindows: [UUID: UIWindow] = [:]

    /// Active multi-monitor setup
    var activeSetup: MultiMonitorSetup? {
        didSet {
            saveActiveSetup()
            if let setup = activeSetup {
                applyMultiMonitorSetup(setup)
            }
        }
    }

    /// Saved multi-monitor setups
    private(set) var savedSetups: [MultiMonitorSetup] = []

    /// Network configuration
    var networkConfig: StageNetworkConfiguration {
        didSet {
            saveNetworkConfig()
            if networkConfig.isEnabled {
                startNetworkService()
            } else {
                stopNetworkService()
            }
        }
    }

    /// Connected network devices
    private(set) var networkDevices: [NetworkMonitorDevice] = []

    /// Network service
    private var networkListener: NWListener?
    private var networkConnection: NWConnection?
    private var networkBrowser: NWBrowser?

    /// Leader mode enabled
    var isLeaderMode: Bool = true {
        didSet {
            saveLeaderMode()
        }
    }

    /// Current song content
    var currentParsedSong: ParsedSong?
    var currentSectionIndex: Int = 0 {
        didSet {
            broadcastSectionChange()
        }
    }

    /// All monitors blanked
    var areAllMonitorsBlanked: Bool = false {
        didSet {
            if areAllMonitorsBlanked {
                blankAllMonitors()
            } else {
                unblankAllMonitors()
            }
        }
    }

    // MARK: - Initialization

    private init() {
        self.networkConfig = StageNetworkConfiguration()
        loadSavedSetups()
        loadNetworkConfig()
        loadLeaderMode()
        setupNotificationObservers()
        scanForDisplays()
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        // Listen for display connection/disconnection
        NotificationCenter.default.addObserver(
            forName: UIScreen.didConnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.scanForDisplays()
        }

        NotificationCenter.default.addObserver(
            forName: UIScreen.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.scanForDisplays()
        }
    }

    // MARK: - Display Management

    private func scanForDisplays() {
        let externalScreens = UIScreen.screens.filter { $0 != UIScreen.main }

        // Auto-assign displays to monitor zones
        if let setup = activeSetup {
            for (index, screen) in externalScreens.enumerated() {
                if index < setup.monitors.count {
                    var zone = setup.monitors[index]
                    zone.displayIdentifier = "\(screen.hash)"
                    connectMonitorZone(zone, to: screen)
                }
            }
        }
    }

    private func connectMonitorZone(_ zone: MonitorZone, to screen: UIScreen) {
        // Create window for this zone
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen

        // Create stage monitor view
        if let parsedSong = currentParsedSong {
            let monitorView = StageMonitorView(
                parsedSong: parsedSong,
                currentSectionIndex: currentSectionIndex,
                configuration: zone.configuration
            )
            let hostingController = UIHostingController(rootView: monitorView)
            hostingController.view.backgroundColor = .clear

            window.rootViewController = hostingController
            window.isHidden = zone.isBlank
        }

        displayWindows[zone.id] = window
    }

    func disconnectMonitorZone(_ zoneId: UUID) {
        displayWindows[zoneId]?.isHidden = true
        displayWindows[zoneId] = nil
    }

    func disconnectAllMonitors() {
        for (_, window) in displayWindows {
            window.isHidden = true
        }
        displayWindows.removeAll()
    }

    // MARK: - Multi-Monitor Setup

    func applyMultiMonitorSetup(_ setup: MultiMonitorSetup) {
        // Disconnect existing monitors
        disconnectAllMonitors()

        // Store zones
        monitorZones = setup.monitors

        // Connect to physical displays
        scanForDisplays()

        NotificationCenter.default.post(
            name: .stageMonitorConfigurationChanged,
            object: self
        )
    }

    func createMonitorZone(role: MonitorRole, priority: Int) -> MonitorZone {
        let config = StageMonitorConfiguration.forRole(role)
        return MonitorZone(
            role: role,
            priority: priority,
            configuration: config
        )
    }

    func updateMonitorZone(_ zone: MonitorZone) {
        if let index = monitorZones.firstIndex(where: { $0.id == zone.id }) {
            monitorZones[index] = zone

            // Update the display if connected
            if let window = displayWindows[zone.id],
               let parsedSong = currentParsedSong {
                let monitorView = StageMonitorView(
                    parsedSong: parsedSong,
                    currentSectionIndex: currentSectionIndex,
                    configuration: zone.configuration
                )
                let hostingController = UIHostingController(rootView: monitorView)
                window.rootViewController = hostingController
            }

            // Update active setup if needed
            if var setup = activeSetup {
                if let setupIndex = setup.monitors.firstIndex(where: { $0.id == zone.id }) {
                    setup.monitors[setupIndex] = zone
                    activeSetup = setup
                }
            }
        }
    }

    // MARK: - Content Updates

    func displaySong(_ parsedSong: ParsedSong, sectionIndex: Int = 0) {
        currentParsedSong = parsedSong
        currentSectionIndex = sectionIndex

        // Update all local monitors
        for (zoneId, window) in displayWindows {
            if let zone = monitorZones.first(where: { $0.id == zoneId }) {
                let monitorView = StageMonitorView(
                    parsedSong: parsedSong,
                    currentSectionIndex: sectionIndex,
                    configuration: zone.configuration
                )
                let hostingController = UIHostingController(rootView: monitorView)
                hostingController.view.backgroundColor = .clear
                window.rootViewController = hostingController
            }
        }

        // Broadcast to network devices
        broadcastContentUpdate()
    }

    func advanceSection() {
        guard let song = currentParsedSong else { return }
        if currentSectionIndex < song.sections.count - 1 {
            currentSectionIndex += 1
            displaySong(song, sectionIndex: currentSectionIndex)
        }
    }

    func previousSection() {
        guard let song = currentParsedSong else { return }
        if currentSectionIndex > 0 {
            currentSectionIndex -= 1
            displaySong(song, sectionIndex: currentSectionIndex)
        }
    }

    func goToSection(_ index: Int) {
        guard let song = currentParsedSong else { return }
        if index >= 0 && index < song.sections.count {
            currentSectionIndex = index
            displaySong(song, sectionIndex: currentSectionIndex)
        }
    }

    // MARK: - Leader Control

    func blankAllMonitors() {
        for (_, window) in displayWindows {
            window.isHidden = true
        }

        // Send blank command to network devices
        let command = LeaderMessage(command: .blankAll)
        broadcastLeaderCommand(command)
    }

    func unblankAllMonitors() {
        for (_, window) in displayWindows {
            window.isHidden = false
        }

        // Send unblank command to network devices
        let command = LeaderMessage(command: .unblankAll)
        broadcastLeaderCommand(command)
    }

    func blankMonitor(zoneId: UUID) {
        displayWindows[zoneId]?.isHidden = true

        if let index = monitorZones.firstIndex(where: { $0.id == zoneId }) {
            monitorZones[index].isBlank = true
        }

        let command = LeaderMessage(command: .blankMonitor, targetMonitorId: zoneId)
        broadcastLeaderCommand(command)
    }

    func unblankMonitor(zoneId: UUID) {
        displayWindows[zoneId]?.isHidden = false

        if let index = monitorZones.firstIndex(where: { $0.id == zoneId }) {
            monitorZones[index].isBlank = false
        }

        let command = LeaderMessage(command: .unblankMonitor, targetMonitorId: zoneId)
        broadcastLeaderCommand(command)
    }

    func sendMessageToMonitors(_ message: String) {
        let command = LeaderMessage(command: .sendMessage, message: message)
        broadcastLeaderCommand(command)
    }

    func overrideMonitor(zoneId: UUID, configuration: StageMonitorConfiguration) {
        if let index = monitorZones.firstIndex(where: { $0.id == zoneId }) {
            monitorZones[index].configuration = configuration
            updateMonitorZone(monitorZones[index])
        }

        let command = LeaderMessage(
            command: .overrideMonitor,
            targetMonitorId: zoneId,
            configuration: configuration
        )
        broadcastLeaderCommand(command)
    }

    // MARK: - Setup Management

    func saveSetup(_ setup: MultiMonitorSetup) {
        if let index = savedSetups.firstIndex(where: { $0.id == setup.id }) {
            savedSetups[index] = setup
        } else {
            savedSetups.append(setup)
        }
        saveSavedSetups()
    }

    func deleteSetup(_ setupId: UUID) {
        savedSetups.removeAll { $0.id == setupId }
        saveSavedSetups()

        if activeSetup?.id == setupId {
            activeSetup = nil
        }
    }

    func loadSetup(_ setupId: UUID) {
        if let setup = savedSetups.first(where: { $0.id == setupId }) {
            activeSetup = setup
        }
    }

    // MARK: - Network Service

    private func startNetworkService() {
        guard networkConfig.isEnabled else { return }

        switch networkConfig.mode {
        case .local:
            // Local mode - no network needed
            break

        case .wifi, .bonjour:
            startBonjourService()

        case .cloud:
            startCloudSync()
        }
    }

    private func stopNetworkService() {
        networkListener?.cancel()
        networkListener = nil

        networkBrowser?.cancel()
        networkBrowser = nil

        networkConnection?.cancel()
        networkConnection = nil
    }

    private func startBonjourService() {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true

        // Setup Bonjour service
        let service = NWListener.Service(name: "Lyra Stage Monitor", type: "_lyra-stage._tcp")

        do {
            let listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: networkConfig.port))
            listener.service = service

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener.stateUpdateHandler = { [weak self] state in
                self?.handleListenerStateUpdate(state)
            }

            listener.start(queue: .main)
            networkListener = listener

            // Start browser for discovery
            startBonjourBrowser()
        } catch {
            print("Failed to start network listener: \(error)")
        }
    }

    private func startBonjourBrowser() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_lyra-stage._tcp", domain: nil), using: parameters)

        browser.stateUpdateHandler = { state in
            print("Browser state: \(state)")
        }

        browser.browseResultsChangedHandler = { [weak self] results, changes in
            self?.handleBrowserResults(results, changes: changes)
        }

        browser.start(queue: .main)
        networkBrowser = browser
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            if state == .ready {
                self?.addNetworkDevice(from: connection)
            }
        }

        connection.start(queue: .main)
    }

    private func handleListenerStateUpdate(_ state: NWListener.State) {
        print("Listener state: \(state)")
    }

    private func handleBrowserResults(_ results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
        for change in changes {
            switch change {
            case .added(let result):
                print("Discovered device: \(result.endpoint)")

            case .removed(let result):
                print("Device disconnected: \(result.endpoint)")
                removeNetworkDevice(endpoint: result.endpoint)

            default:
                break
            }
        }
    }

    private func addNetworkDevice(from connection: NWConnection) {
        // Create network device
        let device = NetworkMonitorDevice(
            id: UUID(),
            deviceName: "Remote Monitor",
            deviceType: "Unknown",
            ipAddress: nil,
            role: .custom,
            configuration: StageMonitorConfiguration(),
            connectionStatus: .connected,
            lastSeen: Date(),
            latency: nil
        )

        networkDevices.append(device)

        NotificationCenter.default.post(
            name: .stageMonitorNetworkDeviceConnected,
            object: self,
            userInfo: ["device": device]
        )
    }

    private func removeNetworkDevice(endpoint: NWEndpoint) {
        // Remove device
        // TODO: Match by endpoint
        NotificationCenter.default.post(
            name: .stageMonitorNetworkDeviceDisconnected,
            object: self
        )
    }

    private func startCloudSync() {
        // Use CloudKit for remote sync
        // This would integrate with the existing CloudKitSyncCoordinator
        // TODO: Implement CloudKit-based monitor sync
    }

    // MARK: - Network Broadcasting

    private func broadcastContentUpdate() {
        guard networkConfig.isEnabled,
              let song = currentParsedSong else { return }

        // Create content update message
        let message: [String: Any] = [
            "type": "contentUpdate",
            "songTitle": song.title ?? "",
            "sectionIndex": currentSectionIndex,
            "timestamp": Date().timeIntervalSince1970
        ]

        broadcastMessage(message)

        NotificationCenter.default.post(
            name: .stageMonitorContentUpdated,
            object: self
        )
    }

    private func broadcastSectionChange() {
        guard networkConfig.isEnabled else { return }

        let message: [String: Any] = [
            "type": "sectionChange",
            "sectionIndex": currentSectionIndex,
            "timestamp": Date().timeIntervalSince1970
        ]

        broadcastMessage(message)
    }

    private func broadcastLeaderCommand(_ command: LeaderMessage) {
        guard networkConfig.isEnabled else { return }

        if let encoded = try? JSONEncoder().encode(command) {
            let message: [String: Any] = [
                "type": "leaderCommand",
                "data": String(data: encoded, encoding: .utf8) ?? "",
                "timestamp": Date().timeIntervalSince1970
            ]

            broadcastMessage(message)
        }

        NotificationCenter.default.post(
            name: .stageMonitorLeaderCommandReceived,
            object: self,
            userInfo: ["command": command]
        )
    }

    private func broadcastMessage(_ message: [String: Any]) {
        // Broadcast to all connected network devices
        // TODO: Implement actual network message sending
        print("Broadcasting message: \(message)")
    }

    // MARK: - Persistence

    private func loadSavedSetups() {
        // Load built-in setups
        savedSetups = [
            .smallBand,
            .fullBand,
            .worshipTeam
        ]

        // Load custom setups
        if let data = UserDefaults.standard.data(forKey: "stageMonitorSetups"),
           let decoded = try? JSONDecoder().decode([MultiMonitorSetup].self, from: data) {
            savedSetups.append(contentsOf: decoded)
        }

        // Load active setup
        if let setupId = UserDefaults.standard.string(forKey: "activeStageMonitorSetup"),
           let uuid = UUID(uuidString: setupId) {
            activeSetup = savedSetups.first { $0.id == uuid }
        }
    }

    private func saveSavedSetups() {
        if let encoded = try? JSONEncoder().encode(savedSetups) {
            UserDefaults.standard.set(encoded, forKey: "stageMonitorSetups")
        }
    }

    private func saveActiveSetup() {
        if let setupId = activeSetup?.id {
            UserDefaults.standard.set(setupId.uuidString, forKey: "activeStageMonitorSetup")
        }
    }

    private func loadNetworkConfig() {
        if let data = UserDefaults.standard.data(forKey: "stageNetworkConfig"),
           let decoded = try? JSONDecoder().decode(StageNetworkConfiguration.self, from: data) {
            networkConfig = decoded
        }
    }

    private func saveNetworkConfig() {
        if let encoded = try? JSONEncoder().encode(networkConfig) {
            UserDefaults.standard.set(encoded, forKey: "stageNetworkConfig")
        }
    }

    private func loadLeaderMode() {
        isLeaderMode = UserDefaults.standard.bool(forKey: "stageMonitorLeaderMode")
    }

    private func saveLeaderMode() {
        UserDefaults.standard.set(isLeaderMode, forKey: "stageMonitorLeaderMode")
    }

    // MARK: - Utilities

    var hasPhysicalDisplays: Bool {
        UIScreen.screens.count > 1
    }

    var availableDisplayCount: Int {
        UIScreen.screens.count - 1 // Exclude main screen
    }

    var totalMonitorCount: Int {
        monitorZones.count + networkDevices.count
    }

    var connectedNetworkDeviceCount: Int {
        networkDevices.filter { $0.connectionStatus == .connected }.count
    }
}
