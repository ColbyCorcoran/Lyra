//
//  ExternalDisplayControlView.swift
//  Lyra
//
//  Quick controls for external display during performance
//

import SwiftUI

/// Compact floating control for external display
struct ExternalDisplayControlWidget: View {
    @State private var displayManager = ExternalDisplayManager.shared
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedControls
            } else {
                compactControl
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10)
    }

    private var compactControl: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: displayManager.isExternalDisplayActive ? "tv.fill" : "tv")
                    .foregroundStyle(displayManager.isExternalDisplayActive ? .blue : .gray)

                if displayManager.isDisplayingContent {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }

                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var expandedControls: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("External Display")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Quick Actions
            HStack(spacing: 12) {
                DisplayQuickActionButton(
                    icon: "rectangle.fill",
                    label: "Blank",
                    color: .orange
                ) {
                    displayManager.blankDisplay()
                }

                DisplayQuickActionButton(
                    icon: "xmark.rectangle",
                    label: "Clear",
                    color: .red
                ) {
                    displayManager.clearDisplay()
                }

                DisplayQuickActionButton(
                    icon: "arrow.up",
                    label: "Next",
                    color: .blue
                ) {
                    displayManager.nextSection()
                }
                .disabled(!displayManager.isDisplayingContent)
            }

            // Mode Indicator
            if let profile = displayManager.activeProfile {
                HStack(spacing: 8) {
                    Image(systemName: profile.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(profile.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(displayManager.configuration.mode.displayName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .frame(width: 240)
    }
}

private struct DisplayQuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section-by-Section Display Control

struct SectionDisplayControlView: View {
    let sections: [String] // Song sections
    @State private var displayManager = ExternalDisplayManager.shared
    @State private var currentSectionIndex: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Section Display")
                    .font(.headline)

                Spacer()

                if displayManager.isExternalDisplayActive {
                    Image(systemName: "tv.fill")
                        .foregroundStyle(.green)
                }
            }

            // Section List
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                        SectionDisplayRow(
                            section: section,
                            index: index + 1,
                            isCurrentlyDisplayed: index == currentSectionIndex
                        ) {
                            displaySection(at: index)
                        }
                    }
                }
            }

            // Navigation Controls
            HStack(spacing: 16) {
                Button {
                    previousSection()
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                .disabled(currentSectionIndex == 0)

                Spacer()

                Button {
                    displayManager.blankDisplay()
                } label: {
                    Label("Blank", systemImage: "rectangle.fill")
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                Spacer()

                Button {
                    nextSection()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .buttonStyle(.bordered)
                .disabled(currentSectionIndex >= sections.count - 1)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }

    private func displaySection(at index: Int) {
        currentSectionIndex = index
        let section = sections[index]
        let nextSection = index < sections.count - 1 ? sections[index + 1] : nil

        displayManager.displaySection(section, nextSection: nextSection)
    }

    private func nextSection() {
        if currentSectionIndex < sections.count - 1 {
            displaySection(at: currentSectionIndex + 1)
        }
    }

    private func previousSection() {
        if currentSectionIndex > 0 {
            displaySection(at: currentSectionIndex - 1)
        }
    }
}

struct SectionDisplayRow: View {
    let section: String
    let index: Int
    let isCurrentlyDisplayed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Index
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isCurrentlyDisplayed ? .white : .secondary)
                    .frame(width: 30, height: 30)
                    .background(isCurrentlyDisplayed ? Color.blue : Color.secondary.opacity(0.2))
                    .clipShape(Circle())

                // Section preview
                Text(section.prefix(60))
                    .font(.subheadline)
                    .foregroundStyle(isCurrentlyDisplayed ? .primary : .secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Display indicator
                if isCurrentlyDisplayed {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            .padding()
            .background(isCurrentlyDisplayed ? Color.blue.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrentlyDisplayed ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confidence Monitor View

struct ConfidenceMonitorView: View {
    @State private var displayManager = ExternalDisplayManager.shared
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?

    let songDuration: TimeInterval
    let currentLine: String
    let nextLines: [String]
    let setlistItems: [String]
    let currentSetlistIndex: Int

    var body: some View {
        HStack(spacing: 20) {
            // Current Line
            VStack(alignment: .leading, spacing: 12) {
                Text("Current")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(currentLine)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Next Lines
            VStack(alignment: .leading, spacing: 12) {
                Text("Coming Up")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(nextLines.prefix(3).enumerated()), id: \.offset) { _, line in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 6, height: 6)

                            Text(line)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Timer & Setlist
            VStack(spacing: 16) {
                // Timer
                VStack(spacing: 8) {
                    Text("Time")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(formatTime(currentTime))
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(timeColor)

                    ProgressView(value: currentTime, total: songDuration)
                        .tint(timeColor)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Setlist
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setlist")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(setlistItems.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(index == currentSetlistIndex ? Color.green : Color.secondary.opacity(0.3))
                                    .frame(width: 6, height: 6)

                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(index == currentSetlistIndex ? .primary : .secondary)
                                    .fontWeight(index == currentSetlistIndex ? .semibold : .regular)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(width: 200)
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var timeColor: Color {
        let percentageRemaining = 1.0 - (currentTime / songDuration)
        if percentageRemaining > 0.3 {
            return .green
        } else if percentageRemaining > 0.1 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

#Preview("Control Widget") {
    VStack {
        Spacer()
        ExternalDisplayControlWidget()
            .padding()
    }
}

#Preview("Section Control") {
    SectionDisplayControlView(sections: [
        "Amazing Grace, how sweet the sound\nThat saved a wretch like me",
        "I once was lost, but now am found\nWas blind, but now I see",
        "'Twas grace that taught my heart to fear\nAnd grace my fears relieved",
        "How precious did that grace appear\nThe hour I first believed"
    ])
    .padding()
}

#Preview("Confidence Monitor") {
    ConfidenceMonitorView(
        songDuration: 240,
        currentLine: "Amazing Grace, how sweet the sound",
        nextLines: [
            "That saved a wretch like me",
            "I once was lost, but now am found",
            "Was blind, but now I see"
        ],
        setlistItems: [
            "Amazing Grace",
            "How Great Thou Art",
            "Blessed Assurance"
        ],
        currentSetlistIndex: 0
    )
    .padding()
}
