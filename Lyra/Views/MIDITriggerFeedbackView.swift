//
//  MIDITriggerFeedbackView.swift
//  Lyra
//
//  Visual feedback when MIDI triggers song loading
//

import SwiftUI

struct MIDITriggerFeedbackView: View {
    let message: String
    let isVisible: Bool

    var body: some View {
        if isVisible {
            VStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.largeTitle)
                    .symbolEffect(.pulse)
                    .foregroundStyle(.blue)

                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("Triggered by MIDI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - MIDI Trigger Indicator

struct MIDITriggerIndicator: View {
    @State private var midiSongLoader = MIDISongLoader.shared

    var body: some View {
        ZStack {
            if midiSongLoader.showTriggerFlash,
               let message = midiSongLoader.triggerFeedbackMessage {
                MIDITriggerFeedbackView(
                    message: message,
                    isVisible: true
                )
            }
        }
        .animation(.spring(), value: midiSongLoader.showTriggerFlash)
    }
}

// MARK: - MIDI Status Badge

struct MIDIStatusBadge: View {
    @State private var midiManager = MIDIManager.shared
    @State private var midiSongLoader = MIDISongLoader.shared

    var body: some View {
        if midiSongLoader.isEnabled && midiManager.isConnected {
            HStack(spacing: 4) {
                Circle()
                    .fill(isActive ? .green : .gray)
                    .frame(width: 8, height: 8)

                Text("MIDI")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }

    private var isActive: Bool {
        if let lastActivity = midiManager.lastInputActivity {
            return Date().timeIntervalSince(lastActivity) < 2.0
        }
        return false
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        MIDITriggerFeedbackView(
            message: "🎵 Amazing Grace",
            isVisible: true
        )

        MIDIStatusBadge()
    }
    .padding()
}
