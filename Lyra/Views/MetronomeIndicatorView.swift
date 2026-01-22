//
//  MetronomeIndicatorView.swift
//  Lyra
//
//  Minimal floating metronome indicator for song view
//

import SwiftUI

struct MetronomeIndicatorView: View {
    @Bindable var metronome: MetronomeManager
    let onTap: () -> Void

    @State private var pulseAnimation: Bool = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                // Pulsing indicator
                if metronome.isPlaying {
                    Circle()
                        .fill(currentBeatColor)
                        .frame(width: 48, height: 48)
                        .scaleEffect(pulseScale)
                        .animation(.easeOut(duration: 0.1), value: metronome.currentBeat)
                }

                // Icon or BPM
                VStack(spacing: 2) {
                    if metronome.isPlaying {
                        Text("\(Int(metronome.currentBPM))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("BPM")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    } else {
                        Image(systemName: "metronome")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var currentBeatColor: Color {
        let beatInMeasure = (metronome.currentBeat / Int(metronome.subdivisions.divisor)) % metronome.timeSignature.beatsPerMeasure

        return beatInMeasure == 0 ? .orange : .blue
    }

    private var pulseScale: CGFloat {
        let beatInMeasure = (metronome.currentBeat / Int(metronome.subdivisions.divisor)) % metronome.timeSignature.beatsPerMeasure

        return beatInMeasure == 0 ? 1.0 : 0.8
    }
}

#Preview {
    VStack {
        Spacer()

        HStack {
            Spacer()

            MetronomeIndicatorView(
                metronome: MetronomeManager(),
                onTap: {}
            )
            .padding()
        }
    }
}
