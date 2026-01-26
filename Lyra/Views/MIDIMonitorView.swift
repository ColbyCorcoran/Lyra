//
//  MIDIMonitorView.swift
//  Lyra
//
//  Real-time MIDI message monitoring and visualization
//

import SwiftUI
import UniformTypeIdentifiers

struct MIDIMonitorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var midiManager = MIDIManager.shared

    @State private var filterType: MIDIMessageType?
    @State private var filterChannel: Int? // 0 = all channels, 1-16 = specific
    @State private var isPaused = false
    @State private var showHex = false
    @State private var showExportSheet = false
    @State private var exportedText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar - Message Types
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        MIDIFilterChip(
                            title: "All",
                            isSelected: filterType == nil,
                            count: midiManager.recentMessages.count
                        ) {
                            filterType = nil
                        }

                        ForEach([
                            MIDIMessageType.noteOn,
                            .noteOff,
                            .programChange,
                            .controlChange,
                            .pitchBend,
                            .systemExclusive
                        ], id: \.self) { type in
                            MIDIFilterChip(
                                title: type.rawValue,
                                icon: type.icon,
                                isSelected: filterType == type,
                                count: midiManager.recentMessages.filter { $0.type == type }.count
                            ) {
                                filterType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))

                // Filter Bar - Channels
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        MIDIFilterChip(
                            title: "All Channels",
                            isSelected: filterChannel == nil,
                            count: midiManager.recentMessages.count
                        ) {
                            filterChannel = nil
                        }

                        ForEach(1...16, id: \.self) { channel in
                            MIDIFilterChip(
                                title: "Ch \(channel)",
                                isSelected: filterChannel == channel,
                                count: midiManager.recentMessages.filter { $0.channel == channel }.count
                            ) {
                                filterChannel = channel
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))

                Divider()

                // Message List
                if filteredMessages.isEmpty {
                    ContentUnavailableView(
                        isPaused ? "Monitoring Paused" : "No MIDI Messages",
                        systemImage: isPaused ? "pause.circle" : "waveform",
                        description: Text(isPaused ? "Resume to see MIDI activity" : "MIDI messages will appear here")
                    )
                } else {
                    List {
                        ForEach(filteredMessages) { message in
                            MIDIMessageRow(message: message, showHex: showHex)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("MIDI Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            isPaused.toggle()
                        } label: {
                            Label(
                                isPaused ? "Resume" : "Pause",
                                systemImage: isPaused ? "play.fill" : "pause.fill"
                            )
                        }

                        Button {
                            showHex.toggle()
                        } label: {
                            Label(
                                showHex ? "Hide Hex" : "Show Hex",
                                systemImage: "number"
                            )
                        }

                        Divider()

                        Button {
                            exportMessages()
                        } label: {
                            Label("Export Log", systemImage: "square.and.arrow.up")
                        }
                        .disabled(filteredMessages.isEmpty)

                        Divider()

                        Button(role: .destructive) {
                            midiManager.recentMessages.removeAll()
                        } label: {
                            Label("Clear Messages", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(text: exportedText)
            }
        }
    }

    private var filteredMessages: [MIDIMessage] {
        guard !isPaused else { return midiManager.recentMessages }

        var messages = midiManager.recentMessages

        // Filter by type
        if let filterType = filterType {
            messages = messages.filter { $0.type == filterType }
        }

        // Filter by channel
        if let filterChannel = filterChannel {
            messages = messages.filter { $0.channel == filterChannel }
        }

        return messages
    }

    private func exportMessages() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        var output = "MIDI Message Log - Lyra\n"
        output += "Exported: \(dateFormatter.string(from: Date()))\n"
        output += "Total Messages: \(filteredMessages.count)\n"
        output += String(repeating: "=", count: 60) + "\n\n"

        for message in filteredMessages.reversed() {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss.SSS"
            let timeString = timeFormatter.string(from: message.timestamp)

            output += "[\(timeString)] "
            output += "Ch \(message.channel) | "
            output += "\(message.type.rawValue) | "
            output += message.description

            if showHex {
                output += " | Hex: \(message.hexString)"
            }

            if let deviceName = message.deviceName {
                output += " | Device: \(deviceName)"
            }

            output += "\n"
        }

        exportedText = output
        showExportSheet = true
    }
}

// MARK: - Filter Chip

private struct MIDIFilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.primary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - MIDI Message Row

struct MIDIMessageRow: View {
    let message: MIDIMessage
    let showHex: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: message.type.icon)
                    .font(.title3)
                    .foregroundStyle(colorForType(message.type))
                    .frame(width: 30)

                // Message Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.description)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        if let deviceName = message.deviceName {
                            Text(deviceName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(message.timestamp, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Hex representation
            if showHex {
                Text(message.hexString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 42)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForType(_ type: MIDIMessageType) -> Color {
        switch type {
        case .noteOn: return .green
        case .noteOff: return .red
        case .programChange: return .blue
        case .controlChange: return .orange
        case .pitchBend: return .purple
        case .aftertouch: return .pink
        case .systemExclusive: return .brown
        case .clock, .start, .stop, .continue_: return .gray
        case .unknown: return .secondary
        }
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let text: String

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("MIDI Log Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: text,
                        preview: SharePreview(
                            "MIDI Log",
                            image: Image(systemName: "waveform")
                        )
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MIDIMonitorView()
}
