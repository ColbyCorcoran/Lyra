//
//  SongPerformanceHistoryView.swift
//  Lyra
//
//  View showing performance history and statistics for a specific song
//

import SwiftUI
import SwiftData
import Charts

struct SongPerformanceHistoryView: View {
    let song: Song

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allPerformances: [Performance]

    var songPerformances: [Performance] {
        allPerformances.filter { $0.song?.id == song.id }
            .sorted { $0.performanceDate > $1.performanceDate }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if songPerformances.isEmpty {
                        emptyState
                    } else {
                        // Statistics section
                        statisticsSection

                        // Chart section
                        if songPerformances.count >= 2 {
                            performanceChartSection
                        }

                        // Performance history list
                        performanceHistorySection
                    }
                }
                .padding()
            }
            .navigationTitle("Performance History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Performances Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("This song hasn't been performed yet. Perform it as part of a set to start tracking!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Total Performances",
                    value: "\(songPerformances.count)",
                    icon: "music.note",
                    color: .blue
                )

                StatCard(
                    title: "Last Performed",
                    value: songPerformances.first?.shortDate ?? "Never",
                    icon: "calendar",
                    color: .green
                )

                StatCard(
                    title: "Avg Duration",
                    value: averageDuration,
                    icon: "clock",
                    color: .orange
                )

                StatCard(
                    title: "Most Common Key",
                    value: mostCommonKey,
                    icon: "music.note",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Chart Section

    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequency Over Time")
                .font(.title3)
                .fontWeight(.semibold)

            Chart(songPerformances.reversed()) { performance in
                BarMark(
                    x: .value("Date", performance.performanceDate, unit: .month),
                    y: .value("Count", 1)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Performance History Section

    private var performanceHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Performances")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(songPerformances) { performance in
                    PerformanceCard(performance: performance)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var averageDuration: String {
        let durations = songPerformances.compactMap { $0.duration }
        guard !durations.isEmpty else { return "N/A" }

        let avgSeconds = durations.reduce(0, +) / Double(durations.count)
        let minutes = Int(avgSeconds) / 60
        let seconds = Int(avgSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var mostCommonKey: String {
        let keys = songPerformances.compactMap { $0.key }
        guard !keys.isEmpty else { return "N/A" }

        let counts = Dictionary(grouping: keys, by: { $0 }).mapValues { $0.count }
        let mostCommon = counts.max(by: { $0.value < $1.value })
        return mostCommon?.key ?? "N/A"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Performance Card

struct PerformanceCard: View {
    let performance: Performance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and duration
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(performance.formattedDate)
                        .font(.headline)

                    if let duration = performance.formattedDuration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(duration)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let venue = performance.venue {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.title3)
                            .foregroundStyle(.blue)

                        Text(venue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Performance details
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let key = performance.key {
                    DetailItem(icon: "music.note", label: "Key", value: key)
                }

                if let tempo = performance.tempo {
                    DetailItem(icon: "metronome", label: "Tempo", value: "\(tempo) BPM")
                }

                if let capo = performance.capoFret, capo > 0 {
                    DetailItem(icon: "guitars", label: "Capo", value: "\(capo)")
                }

                if performance.transposeSemitones != 0 {
                    DetailItem(
                        icon: "arrow.up.arrow.down",
                        label: "Transpose",
                        value: "\(performance.transposeSemitones > 0 ? "+" : "")\(performance.transposeSemitones)"
                    )
                }

                if performance.usedAutoscroll {
                    DetailItem(icon: "play.circle", label: "Autoscroll", value: "Yes")
                }
            }

            // Notes
            if let notes = performance.notes, !notes.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption)
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.secondary)

                    Text(notes)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Detail Item

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace", artist: "John Newton")
    return SongPerformanceHistoryView(song: song)
        .modelContainer(for: [Song.self, Performance.self])
}
