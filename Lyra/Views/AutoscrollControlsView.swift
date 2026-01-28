//
//  AutoscrollControlsView.swift
//  Lyra
//
//  Floating controls for autoscroll during performance
//

import SwiftUI

struct AutoscrollControlsView: View {
    @ObservedObject var autoscrollManager: AutoscrollManager

    let onJumpToTop: () -> Void

    @State private var showSpeedPicker: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at top
            if autoscrollManager.isScrolling {
                progressBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()

            // Main controls at bottom
            HStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    // Floating action button (main play/pause)
                    floatingActionButton

                    // Speed control
                    if autoscrollManager.isScrolling {
                        speedControl
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Additional controls
                    if autoscrollManager.isScrolling {
                        additionalControls
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: autoscrollManager.isScrolling)
        .sheet(isPresented: $showSpeedPicker) {
            speedPickerSheet
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 0) {
            // Progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color(.systemGray5))

                    // Progress fill
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * autoscrollManager.currentProgress)
                }
            }
            .frame(height: 4)

            // Time remaining
            HStack {
                Text(autoscrollManager.formattedElapsedTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)

                    Text(autoscrollManager.formattedRemainingTime)
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                .foregroundStyle(.primary)

                Spacer()

                Text(formatPercentage(autoscrollManager.currentProgress))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial)
        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        Button {
            if autoscrollManager.isScrolling {
                if autoscrollManager.isPaused {
                    autoscrollManager.resume()
                } else {
                    autoscrollManager.pause()
                }
            } else {
                autoscrollManager.start()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                Image(systemName: buttonIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
    }

    private var buttonIcon: String {
        if !autoscrollManager.isScrolling {
            return "play.fill"
        } else if autoscrollManager.isPaused {
            return "play.fill"
        } else {
            return "pause.fill"
        }
    }

    // MARK: - Speed Control

    private var speedControl: some View {
        VStack(spacing: 8) {
            // Speed display button
            Button {
                showSpeedPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.caption)

                    Text(autoscrollManager.currentSpeedLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            // Quick speed adjustment
            HStack(spacing: 8) {
                Button {
                    autoscrollManager.adjustSpeed(by: -0.25)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(Color.blue.opacity(0.9)))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(autoscrollManager.speedMultiplier <= 0.5)

                Button {
                    autoscrollManager.adjustSpeed(by: 0.25)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(Color.blue.opacity(0.9)))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(autoscrollManager.speedMultiplier >= 2.0)
            }
        }
    }

    // MARK: - Additional Controls

    private var additionalControls: some View {
        VStack(spacing: 8) {
            // Jump to top
            Button {
                onJumpToTop()
                autoscrollManager.jumpToTop()
            } label: {
                Image(systemName: "arrow.up.to.line.compact")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.gray.opacity(0.9)))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            // Stop
            Button {
                autoscrollManager.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.red.opacity(0.9)))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)

        }
    }

    // MARK: - Speed Picker Sheet

    private var speedPickerSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AutoscrollManager.speedPresets, id: \.value) { preset in
                        Button {
                            autoscrollManager.setSpeed(preset.value)
                            showSpeedPicker = false
                        } label: {
                            HStack {
                                Text(preset.label)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if abs(autoscrollManager.speedMultiplier - preset.value) < 0.01 {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Speed Presets")
                } footer: {
                    Text("Adjust playback speed. 1x is normal speed, 2x is twice as fast")
                }

                Section {
                    VStack(spacing: 16) {
                        Text("Custom Speed")
                            .font(.headline)

                        Slider(
                            value: Binding(
                                get: { autoscrollManager.speedMultiplier },
                                set: { autoscrollManager.setSpeed($0) }
                            ),
                            in: 0.5...2.0,
                            step: 0.05
                        )

                        Text(autoscrollManager.currentSpeedLabel)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Fine Tune")
                }
            }
            .navigationTitle("Autoscroll Speed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showSpeedPicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helper Methods

    private func formatPercentage(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }
}

// MARK: - Autoscroll Indicator

struct AutoscrollIndicatorView: View {
    @ObservedObject var autoscrollManager: AutoscrollManager

    var body: some View {
        if autoscrollManager.isScrolling {
            HStack(spacing: 6) {
                Image(systemName: autoscrollManager.isPaused ? "pause.fill" : "play.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))

                Text("Autoscroll")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                if !autoscrollManager.isPaused {
                    Text(autoscrollManager.currentSpeedLabel)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(autoscrollManager.isPaused ? Color.orange : Color.blue)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview("Controls") {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()

        AutoscrollControlsView(
            autoscrollManager: {
                let manager = AutoscrollManager()
                manager.isScrolling = true
                manager.currentProgress = 0.35
                manager.speedMultiplier = 1.0
                return manager
            }(),
            onJumpToTop: {}
        )
    }
}

#Preview("Indicator") {
    ZStack {
        Color(.systemGray6).ignoresSafeArea()

        VStack {
            AutoscrollIndicatorView(
                autoscrollManager: {
                    let manager = AutoscrollManager()
                    manager.isScrolling = true
                    manager.isPaused = false
                    return manager
                }()
            )
        }
    }
}
