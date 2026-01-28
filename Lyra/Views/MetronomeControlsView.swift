//
//  MetronomeControlsView.swift
//  Lyra
//
//  UI controls for metronome with tempo, time signature, and settings
//

import SwiftUI

struct MetronomeControlsView: View {
    @Bindable var metronome: MetronomeManager
    let onDismiss: () -> Void

    @State private var showPresets: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Metronome")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial)

            ScrollView {
                VStack(spacing: 24) {
                    // Visual Metronome
                    visualMetronome

                    // BPM Display and Controls
                    bpmControls

                    // Tap Tempo
                    tapTempoButton

                    // Time Signature
                    timeSignaturePicker

                    // Subdivisions
                    subdivisionsSection

                    // Volume
                    volumeSection

                    // Sound Type
                    soundTypeSection

                    // Visual Only Mode
                    visualOnlyToggle

                    // Presets
                    presetsSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Visual Metronome

    private var visualMetronome: some View {
        GeometryReader { geometry in
            ZStack {
                // Background circle
                Circle()
                    .stroke(lineWidth: 4)
                    .foregroundStyle(Color.secondary.opacity(0.3))

                // Pulsing circle
                Circle()
                    .fill(currentBeatColor)
                    .scaleEffect(pulseScale)
                    .animation(.easeOut(duration: 0.1), value: metronome.currentBeat)

                // BPM text
                Text("\(Int(metronome.currentBPM))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: min(geometry.size.width, 200), height: min(geometry.size.width, 200))
            .frame(maxWidth: .infinity)
        }
        .frame(height: 200)
    }

    private var currentBeatColor: Color {
        guard metronome.isPlaying else { return .gray.opacity(0.3) }

        let beatInMeasure = (metronome.currentBeat / Int(metronome.subdivisions.divisor)) % metronome.timeSignature.beatsPerMeasure

        return beatInMeasure == 0 ? .orange : .blue
    }

    private var pulseScale: CGFloat {
        guard metronome.isPlaying else { return 0.6 }

        let beatInMeasure = (metronome.currentBeat / Int(metronome.subdivisions.divisor)) % metronome.timeSignature.beatsPerMeasure

        return beatInMeasure == 0 ? 0.8 : 0.6
    }

    // MARK: - BPM Controls

    private var bpmControls: some View {
        VStack(spacing: 16) {
            // Large BPM Display
            HStack(spacing: 8) {
                Text("\(Int(metronome.currentBPM))")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("BPM")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .offset(y: 12)
            }

            // Fine adjustment buttons
            HStack(spacing: 12) {
                adjustButton(delta: -10, label: "-10")
                adjustButton(delta: -1, label: "-1")

                Spacer()

                // Play/Stop button
                Button {
                    metronome.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(metronome.isPlaying ? Color.red : Color.green)
                            .frame(width: 60, height: 60)

                        Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }

                Spacer()

                adjustButton(delta: 1, label: "+1")
                adjustButton(delta: 10, label: "+10")
            }

            // BPM Slider
            VStack(spacing: 8) {
                Slider(value: $metronome.currentBPM, in: 30...300, step: 1)
                    .tint(.blue)

                HStack {
                    Text("30")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("300")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    @ViewBuilder
    private func adjustButton(delta: Double, label: String) -> some View {
        Button {
            metronome.adjustBPM(by: delta)
            HapticManager.shared.selection()
        } label: {
            Text(label)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 60, height: 44)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Tap Tempo

    private var tapTempoButton: some View {
        Button {
            metronome.tapTempo()
        } label: {
            HStack {
                Image(systemName: "hand.tap")
                    .font(.title3)

                Text("Tap Tempo")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.purple.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Time Signature

    private var timeSignaturePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Signature")
                .font(.headline)

            Picker("Time Signature", selection: $metronome.timeSignature) {
                ForEach(MetronomeTimeSignature.allCases) { signature in
                    Text(signature.displayName).tag(signature)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Subdivisions

    private var subdivisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subdivisions")
                .font(.headline)

            Picker("Subdivisions", selection: $metronome.subdivisions) {
                ForEach(SubdivisionOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Volume

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Volume")
                    .font(.headline)

                Spacer()

                Text("\(Int(metronome.volume * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.1")
                    .foregroundStyle(.secondary)

                Slider(value: $metronome.volume, in: 0...1)
                    .tint(.blue)

                Image(systemName: "speaker.wave.3")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Sound Type

    private var soundTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sound")
                .font(.headline)

            Picker("Sound Type", selection: $metronome.soundType) {
                ForEach(MetronomeSoundType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Visual Only

    private var visualOnlyToggle: some View {
        Toggle(isOn: $metronome.visualOnly) {
            HStack {
                Image(systemName: metronome.visualOnly ? "speaker.slash" : "speaker.wave.2")
                    .foregroundStyle(metronome.visualOnly ? .orange : .blue)

                Text("Visual Only (Silent)")
                    .font(.headline)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MetronomePreset.common) { preset in
                    presetButton(preset)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    @ViewBuilder
    private func presetButton(_ preset: MetronomePreset) -> some View {
        Button {
            metronome.setBPM(preset.bpm)
            metronome.timeSignature = preset.timeSignature
            HapticManager.shared.selection()
        } label: {
            VStack(spacing: 4) {
                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Text("\(Int(preset.bpm))")
                        .font(.caption)

                    Text(preset.timeSignature.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MetronomeControlsView(
        metronome: MetronomeManager(),
        onDismiss: {}
    )
}
