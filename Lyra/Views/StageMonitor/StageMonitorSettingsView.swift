//
//  StageMonitorSettingsView.swift
//  Lyra
//
//  Main settings view for stage monitor system
//

import SwiftUI

struct StageMonitorSettingsView: View {
    @State private var manager = StageMonitorManager.shared
    @State private var showingNewSetupSheet = false
    @State private var showingNetworkSettings = false

    var body: some View {
        Form {
            // Status Overview
            Section("Status") {
                HStack {
                    Label("Physical Displays", systemImage: "tv")
                    Spacer()
                    Text("\(manager.availableDisplayCount)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Network Monitors", systemImage: "wifi")
                    Spacer()
                    Text("\(manager.connectedNetworkDeviceCount)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Total Monitors", systemImage: "rectangle.3.group")
                    Spacer()
                    Text("\(manager.totalMonitorCount)")
                        .font(.headline)
                }
            }

            // Active Setup
            Section {
                if let setup = manager.activeSetup {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(setup.name)
                                .font(.headline)

                            Spacer()

                            Button("Change") {
                                showingNewSetupSheet = true
                            }
                            .buttonStyle(.bordered)
                        }

                        if !setup.description.isEmpty {
                            Text(setup.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(setup.monitors.count) monitors configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        showingNewSetupSheet = true
                    } label: {
                        Label("Set Up Stage Monitors", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Active Setup")
            }

            // Saved Setups
            Section("Saved Setups") {
                if manager.savedSetups.isEmpty {
                    ContentUnavailableView(
                        "No Saved Setups",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("Create a custom monitor setup")
                    )
                } else {
                    ForEach(manager.savedSetups) { setup in
                        Button {
                            manager.loadSetup(setup.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(setup.name)
                                        .foregroundStyle(.primary)

                                    Text("\(setup.monitors.count) monitors")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if manager.activeSetup?.id == setup.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let setup = manager.savedSetups[index]
                            manager.deleteSetup(setup.id)
                        }
                    }
                }

                Button {
                    showingNewSetupSheet = true
                } label: {
                    Label("New Setup", systemImage: "plus")
                }
            }

            // Network Settings
            Section("Network") {
                Toggle("Enable Network Monitors", isOn: Binding(
                    get: { manager.networkConfig.isEnabled },
                    set: { newValue in
                        var config = manager.networkConfig
                        config.isEnabled = newValue
                        manager.networkConfig = config
                    }
                ))

                if manager.networkConfig.isEnabled {
                    Button {
                        showingNetworkSettings = true
                    } label: {
                        HStack {
                            Label("Network Settings", systemImage: "network")
                            Spacer()
                            Text(manager.networkConfig.mode.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Leader Mode
            Section {
                Toggle("Leader Mode", isOn: $manager.isLeaderMode)
            } footer: {
                Text("Leader mode allows you to control all monitors from this device")
            }

            // Quick Presets
            Section("Quick Presets") {
                Button {
                    manager.activeSetup = .smallBand
                } label: {
                    setupRow(
                        title: "Small Band (3-4)",
                        description: "Vocalist, lead, bass, drummer",
                        icon: "person.3"
                    )
                }

                Button {
                    manager.activeSetup = .fullBand
                } label: {
                    setupRow(
                        title: "Full Band (5-6)",
                        description: "Complete band with keys",
                        icon: "person.3.sequence"
                    )
                }

                Button {
                    manager.activeSetup = .worshipTeam
                } label: {
                    setupRow(
                        title: "Worship Team",
                        description: "Vocals, instruments, audience",
                        icon: "music.note.house"
                    )
                }
            }

            // Help
            Section {
                NavigationLink {
                    StageMonitorHelpView()
                } label: {
                    Label("Help & Documentation", systemImage: "questionmark.circle")
                }
            }
        }
        .navigationTitle("Stage Monitor Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewSetupSheet) {
            MultiMonitorSetupEditor(isPresented: $showingNewSetupSheet)
        }
        .sheet(isPresented: $showingNetworkSettings) {
            NetworkSettingsView()
        }
    }

    @ViewBuilder
    private func setupRow(title: String, description: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Multi-Monitor Setup Editor

struct MultiMonitorSetupEditor: View {
    @Binding var isPresented: Bool
    @State private var manager = StageMonitorManager.shared
    @State private var setupName = ""
    @State private var setupDescription = ""
    @State private var monitors: [MonitorZone] = []
    @State private var showingAddMonitor = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Setup Details") {
                    TextField("Name", text: $setupName)
                    TextField("Description", text: $setupDescription)
                }

                Section {
                    if monitors.isEmpty {
                        ContentUnavailableView(
                            "No Monitors",
                            systemImage: "tv.slash",
                            description: Text("Add monitors to this setup")
                        )
                    } else {
                        ForEach(monitors) { zone in
                            HStack {
                                Image(systemName: zone.role.icon)
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(zone.displayName)
                                        .font(.headline)

                                    Text(zone.configuration.layoutType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                NavigationLink {
                                    MonitorConfigurationView(zone: zone)
                                } label: {
                                    Text("Edit")
                                }
                            }
                        }
                        .onMove { from, to in
                            monitors.move(fromOffsets: from, toOffset: to)
                        }
                        .onDelete { indexSet in
                            monitors.remove(atOffsets: indexSet)
                        }
                    }

                    Button {
                        showingAddMonitor = true
                    } label: {
                        Label("Add Monitor", systemImage: "plus")
                    }
                } header: {
                    Text("Monitors (\(monitors.count))")
                }

                Section {
                    Button("Save Setup") {
                        saveSetup()
                    }
                    .disabled(setupName.isEmpty || monitors.isEmpty)
                }
            }
            .navigationTitle("New Monitor Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddMonitor) {
                AddMonitorSheet(monitors: $monitors, isPresented: $showingAddMonitor)
            }
        }
    }

    private func saveSetup() {
        let setup = MultiMonitorSetup(
            name: setupName,
            description: setupDescription,
            monitors: monitors
        )
        manager.saveSetup(setup)
        manager.activeSetup = setup
        isPresented = false
    }
}

// MARK: - Add Monitor Sheet

struct AddMonitorSheet: View {
    @Binding var monitors: [MonitorZone]
    @Binding var isPresented: Bool
    @State private var selectedRole: MonitorRole = .main

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Role") {
                    ForEach(MonitorRole.allCases) { role in
                        Button {
                            selectedRole = role
                        } label: {
                            HStack {
                                Image(systemName: role.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(role.displayName)
                                        .foregroundStyle(.primary)

                                    Text("Layout: \(role.preferredLayout.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if selectedRole == role {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Add Monitor") {
                        let config = StageMonitorConfiguration.forRole(selectedRole)
                        let zone = MonitorZone(
                            role: selectedRole,
                            priority: monitors.count + 1,
                            configuration: config
                        )
                        monitors.append(zone)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Add Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Network Settings View

struct NetworkSettingsView: View {
    @State private var manager = StageMonitorManager.shared
    @State private var config: StageNetworkConfiguration
    @Environment(\.dismiss) private var dismiss

    init() {
        let currentConfig = StageMonitorManager.shared.networkConfig
        self._config = State(initialValue: currentConfig)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Network Mode") {
                    Picker("Mode", selection: $config.mode) {
                        ForEach(StageNetworkMode.allCases, id: \.self) { mode in
                            Label(mode.displayName, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)

                    Text(config.mode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Connection Settings") {
                    Stepper("Port: \(config.port)", value: Binding(
                        get: { Int(config.port) },
                        set: { config.port = UInt16($0) }
                    ), in: 1024...65535, step: 1)

                    Toggle("Auto Reconnect", isOn: $config.autoReconnect)
                }

                Section("Security") {
                    Toggle("Require Authentication", isOn: $config.requireAuthentication)

                    if config.requireAuthentication {
                        SecureField("Passphrase", text: Binding(
                            get: { config.passphrase ?? "" },
                            set: { config.passphrase = $0 }
                        ))
                    }
                }

                Section("Performance") {
                    VStack(alignment: .leading) {
                        Text("Broadcast Interval: \(Int(config.broadcastInterval * 1000))ms")
                            .font(.caption)
                        Slider(value: $config.broadcastInterval, in: 0.05...1.0, step: 0.05)
                    }

                    VStack(alignment: .leading) {
                        Text("Max Latency: \(Int(config.maxLatency * 1000))ms")
                            .font(.caption)
                        Slider(value: $config.maxLatency, in: 0.05...0.5, step: 0.05)
                    }
                }

                Section("Permissions") {
                    Toggle("Allow Remote Control", isOn: $config.allowRemoteControl)
                } footer: {
                    Text("Allow network devices to control this device")
                }

                Section {
                    Button("Save Changes") {
                        manager.networkConfig = config
                        dismiss()
                    }
                }
            }
            .navigationTitle("Network Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Help View

struct StageMonitorHelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                Text("Stage monitors allow each band member to see customized information during performance.")
            }

            Section("Monitor Roles") {
                helpRow(
                    icon: "mic.fill",
                    title: "Vocalist",
                    description: "Large lyrics with key and capo information"
                )

                helpRow(
                    icon: "guitars.fill",
                    title: "Lead/Rhythm Guitar",
                    description: "Extra large chords with section preview"
                )

                helpRow(
                    icon: "waveform",
                    title: "Bass",
                    description: "Chord roots and structure"
                )

                helpRow(
                    icon: "pianokeys",
                    title: "Keys/Piano",
                    description: "Chords and lyrics together"
                )

                helpRow(
                    icon: "circle.hexagongrid.fill",
                    title: "Drummer",
                    description: "Song structure overview"
                )
            }

            Section("Network Monitors") {
                Text("Connect iPads and iPhones as wireless monitors using WiFi or Bonjour discovery.")
            }

            Section("Leader Control") {
                Text("Leader mode allows you to blank monitors, send messages, and override individual monitor configurations.")
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func helpRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StageMonitorSettingsView()
    }
}
