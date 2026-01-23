//
//  MIDIMonitorView.swift
//  Lyra
//
//  Real-time MIDI message monitoring and visualization
//

import SwiftUI

struct MIDIMonitorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var midiManager = MIDIManager.shared

    @State private var filterType: MIDIMessageType?
    @State private var isPaused = false
    @State private var showHex = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
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
                            FilterChip(
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
        }
    }

    private var filteredMessages: [MIDIMessage] {
        guard !isPaused else { return midiManager.recentMessages }

        if let filterType = filterType {
            return midiManager.recentMessages.filter { $0.type == filterType }
        }
        return midiManager.recentMessages
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
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

// MARK: - Preview

#Preview {
    MIDIMonitorView()
}
