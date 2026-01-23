//
//  LeaderControlPanel.swift
//  Lyra
//
//  Leader control panel for managing all stage monitors
//

import SwiftUI

struct LeaderControlPanel: View {
    @State private var manager = StageMonitorManager.shared
    @State private var showingBlankConfirmation = false
    @State private var customMessage = ""
    @State private var showingMessageSheet = false

    var body: some View {
        NavigationStack {
            List {
                // Quick Actions
                Section("Quick Actions") {
                    // Blank/Unblank All
                    HStack {
                        Label(
                            manager.areAllMonitorsBlanked ? "Unblank All Monitors" : "Blank All Monitors",
                            systemImage: manager.areAllMonitorsBlanked ? "eye" : "eye.slash"
                        )

                        Spacer()

                        Button(manager.areAllMonitorsBlanked ? "Unblank" : "Blank") {
                            if !manager.areAllMonitorsBlanked {
                                showingBlankConfirmation = true
                            } else {
                                manager.areAllMonitorsBlanked = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(manager.areAllMonitorsBlanked ? .green : .red)
                    }

                    // Send Message
                    Button {
                        showingMessageSheet = true
                    } label: {
                        Label("Send Message to All Monitors", systemImage: "bubble.left.and.bubble.right")
                    }

                    // Navigation Controls
                    HStack {
                        Button {
                            manager.previousSection()
                        } label: {
                            Label("Previous", systemImage: "chevron.left")
                        }
                        .disabled(manager.currentSectionIndex == 0)

                        Spacer()

                        if let song = manager.currentParsedSong {
                            Text("Section \(manager.currentSectionIndex + 1) of \(song.sections.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            manager.advanceSection()
                        } label: {
                            Label("Next", systemImage: "chevron.right")
                        }
                        .disabled(
                            manager.currentParsedSong == nil ||
                            manager.currentSectionIndex >= (manager.currentParsedSong?.sections.count ?? 0) - 1
                        )
                    }
                }

                // Individual Monitor Control
                Section {
                    if manager.monitorZones.isEmpty {
                        ContentUnavailableView(
                            "No Monitors Configured",
                            systemImage: "tv.slash",
                            description: Text("Set up monitors in the Stage Monitor settings")
                        )
                    } else {
                        ForEach(manager.monitorZones) { zone in
                            MonitorControlRow(zone: zone)
                        }
                    }
                } header: {
                    HStack {
                        Text("Local Monitors")
                        Spacer()
                        Text("\(manager.monitorZones.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                // Network Monitors
                if !manager.networkDevices.isEmpty {
                    Section {
                        ForEach(manager.networkDevices) { device in
                            NetworkMonitorRow(device: device)
                        }
                    } header: {
                        HStack {
                            Text("Network Monitors")
                            Spacer()
                            Text("\(manager.connectedNetworkDeviceCount)/\(manager.networkDevices.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Current Song Info
                if let song = manager.currentParsedSong {
                    Section("Current Song") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let title = song.title {
                                Text(title)
                                    .font(.headline)
                            }

                            if let artist = song.artist {
                                Text(artist)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                if let key = song.key {
                                    Label(key, systemImage: "music.note")
                                }

                                if let tempo = song.tempo {
                                    Label("\(tempo) BPM", systemImage: "metronome")
                                }

                                if let capo = song.capo, capo > 0 {
                                    Label("Capo \(capo)", systemImage: "tuningfork")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    // Section List
                    Section("Sections") {
                        ForEach(Array(song.sections.enumerated()), id: \.element.id) { index, section in
                            Button {
                                manager.goToSection(index)
                            } label: {
                                HStack {
                                    if index == manager.currentSectionIndex {
                                        Image(systemName: "play.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }

                                    Text(section.label)
                                        .foregroundStyle(
                                            index == manager.currentSectionIndex ? .blue : .primary
                                        )

                                    Spacer()

                                    if section.hasChords {
                                        Image(systemName: "music.note")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // Status
                Section("Status") {
                    LabeledContent("Leader Mode", value: manager.isLeaderMode ? "Active" : "Inactive")

                    LabeledContent("Total Monitors", value: "\(manager.totalMonitorCount)")

                    LabeledContent("Network Status", value: manager.networkConfig.isEnabled ? "Enabled" : "Disabled")
                }
            }
            .navigationTitle("Stage Monitor Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        StageMonitorSettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .confirmationDialog(
                "Blank All Monitors",
                isPresented: $showingBlankConfirmation,
                titleVisibility: .visible
            ) {
                Button("Blank All", role: .destructive) {
                    manager.areAllMonitorsBlanked = true
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will blank all monitors including network devices. Band members will not be able to see any content.")
            }
            .sheet(isPresented: $showingMessageSheet) {
                SendMessageSheet(message: $customMessage) {
                    manager.sendMessageToMonitors(customMessage)
                    customMessage = ""
                    showingMessageSheet = false
                }
            }
        }
    }
}

// MARK: - Monitor Control Row

struct MonitorControlRow: View {
    let zone: MonitorZone
    @State private var manager = StageMonitorManager.shared

    var body: some View {
        HStack {
            // Role Icon and Name
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: zone.role.icon)
                        .foregroundStyle(.blue)

                    Text(zone.displayName)
                        .font(.headline)
                }

                Text(zone.configuration.layoutType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Blank Toggle
            Button {
                if zone.isBlank {
                    manager.unblankMonitor(zoneId: zone.id)
                } else {
                    manager.blankMonitor(zoneId: zone.id)
                }
            } label: {
                Image(systemName: zone.isBlank ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(zone.isBlank ? .red : .green)
            }
            .buttonStyle(.borderless)

            // Configuration
            NavigationLink {
                MonitorConfigurationView(zone: zone)
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Network Monitor Row

struct NetworkMonitorRow: View {
    let device: NetworkMonitorDevice

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: deviceIcon)
                        .foregroundStyle(.blue)

                    Text(device.deviceName)
                        .font(.headline)
                }

                if let ipAddress = device.ipAddress {
                    Text(ipAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Connection Status
            HStack(spacing: 4) {
                Circle()
                    .fill(device.connectionStatus.color)
                    .frame(width: 8, height: 8)

                Text(device.connectionStatus.displayName)
                    .font(.caption)
            }

            // Latency
            if let latency = device.latency {
                Text("\(Int(latency * 1000))ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var deviceIcon: String {
        switch device.deviceType {
        case "iPhone": return "iphone"
        case "iPad": return "ipad"
        case "Mac": return "macbook"
        default: return "display"
        }
    }
}

// MARK: - Send Message Sheet

struct SendMessageSheet: View {
    @Binding var message: String
    let onSend: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Message to Display")
                } footer: {
                    Text("This message will be briefly displayed on all monitors")
                }

                Section {
                    Button("Send to All Monitors") {
                        onSend()
                    }
                    .disabled(message.isEmpty)
                }
            }
            .navigationTitle("Send Message")
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

// MARK: - Preview

#Preview {
    LeaderControlPanel()
}
