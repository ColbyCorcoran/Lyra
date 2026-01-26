//
//  BatchFormattingView.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Batch formatting interface for multiple songs
//
//  Created by Claude AI on 1/24/26.
//

import SwiftUI
import SwiftData
import Combine

/// Batch formatting interface with preview and progress tracking
struct BatchFormattingView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allSongs: [Song]

    @StateObject private var manager = FormattingManager()
    @State private var selectedSongs: Set<Song> = []
    @State private var options: FormattingOptions = .standard
    @State private var isProcessing = false
    @State private var showingReport = false
    @State private var batchResult: BatchFormattingResult?
    @State private var showingOptions = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isProcessing {
                    processingView
                } else if let result = batchResult, showingReport {
                    reportView(result: result)
                } else {
                    selectionView
                }
            }
            .navigationTitle("Batch Formatting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isProcessing && !showingReport {
                        HStack {
                            Button("Options") {
                                showingOptions = true
                            }

                            Button("Format All") {
                                startBatchFormatting()
                            }
                            .disabled(selectedSongs.isEmpty)
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingOptions) {
                FormattingOptionsView(options: $options)
            }
        }
    }

    // MARK: - Selection View

    private var selectionView: some View {
        VStack(spacing: 0) {
            // Selection Header
            HStack {
                Text("\(selectedSongs.count) songs selected")
                    .foregroundColor(.secondary)

                Spacer()

                Button(selectedSongs.count == allSongs.count ? "Deselect All" : "Select All") {
                    if selectedSongs.count == allSongs.count {
                        selectedSongs.removeAll()
                    } else {
                        selectedSongs = Set(allSongs)
                    }
                }
            }
            .padding()

            Divider()

            // Song List
            List {
                ForEach(allSongs) { song in
                    SongSelectionRow(
                        song: song,
                        isSelected: selectedSongs.contains(song)
                    ) {
                        if selectedSongs.contains(song) {
                            selectedSongs.remove(song)
                        } else {
                            selectedSongs.insert(song)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(manager.progress))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: manager.progress)

                Text("\(Int(manager.progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text("Formatting \(selectedSongs.count) songs...")
                .font(.headline)

            Text("This may take a few moments")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }

    // MARK: - Report View

    private func reportView(result: BatchFormattingResult) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Stats
                SummaryStatsView(result: result)

                Divider()

                // Individual Results
                VStack(alignment: .leading, spacing: 12) {
                    Text("Individual Results")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(result.results.keys), id: \.self) { songID in
                        if let formattingResult = result.results[songID],
                           let song = allSongs.first(where: { $0.id == songID }) {
                            FormattingResultRow(
                                song: song,
                                result: formattingResult
                            )
                        }
                    }
                }

                // Actions
                HStack(spacing: 16) {
                    Button("Undo All") {
                        undoAllFormatting()
                    }
                    .buttonStyle(.bordered)

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .padding(.vertical)
        }
    }

    // MARK: - Actions

    private func startBatchFormatting() {
        isProcessing = true

        Task {
            let songs = Array(selectedSongs)
            let result = await manager.batchFormat(songs, options: options) { progress in
                // Progress updates happen automatically via @Published
            }

            // Apply formatting to songs
            for (songID, formattingResult) in result.results {
                if let song = allSongs.first(where: { $0.id == songID }) {
                    song.content = formattingResult.formattedText
                }
            }

            try? modelContext.save()

            batchResult = result
            isProcessing = false
            showingReport = true
        }
    }

    private func undoAllFormatting() {
        guard let result = batchResult else { return }

        // Revert all songs to original text
        for (songID, formattingResult) in result.results {
            if let song = allSongs.first(where: { $0.id == songID }) {
                song.content = formattingResult.originalText
            }
        }

        try? modelContext.save()
        showingReport = false
        batchResult = nil
    }
}

// MARK: - Song Selection Row

struct SongSelectionRow: View {
    let song: Song
    let isSelected: Bool
    let action: () -> Void

    @StateObject private var manager = FormattingManager()
    @State private var qualityScore: QualityScore?

    var body: some View {
        HStack {
            // Selection Indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .secondary)
                .onTapGesture {
                    action()
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body)

                if let artist = song.artist {
                    Text(artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Quality Indicator
            if let score = qualityScore {
                QualityIndicator(score: score.overall)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .task {
            qualityScore = manager.getQualityScore(song.content)
        }
    }
}

// MARK: - Quality Indicator

struct QualityIndicator: View {
    let score: Float

    var color: Color {
        switch score {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .yellow
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(Int(score * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Summary Stats View

struct SummaryStatsView: View {
    let result: BatchFormattingResult

    var body: some View {
        VStack(spacing: 16) {
            Text("Formatting Complete")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                StatCard(
                    title: "Songs Formatted",
                    value: "\(result.successCount)",
                    icon: "music.note.list",
                    color: .blue
                )

                StatCard(
                    title: "Avg. Quality",
                    value: "\(Int(result.averageQualityImprovement * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )

                StatCard(
                    title: "Issues Fixed",
                    value: "\(result.totalIssuesFixed)",
                    icon: "checkmark.circle",
                    color: .orange
                )
            }

            if result.failureCount > 0 {
                Text("\(result.failureCount) songs failed to format")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Formatting Result Row

struct FormattingResultRow: View {
    let song: Song
    let result: FormattingResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                QualityIndicator(score: result.qualityScore.overall)
            }

            HStack(spacing: 16) {
                Label("\(result.changes.count) changes", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("\(result.qualityScore.issues.count) issues", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Formatting Options View

struct FormattingOptionsView: View {
    @Binding var options: FormattingOptions
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Pattern") {
                    Picker("Target Pattern", selection: $options.targetPattern) {
                        ForEach(ChordPattern.allCases, id: \.self) { pattern in
                            Text(pattern.displayName).tag(pattern)
                        }
                    }
                }

                Section("Formatting") {
                    Toggle("Remove Extra Blank Lines", isOn: $options.removeExtraBlankLines)
                    Toggle("Align Chords", isOn: $options.alignChords)
                    Toggle("Fix Spacing", isOn: $options.fixSpacing)
                }

                Section("Structure") {
                    Toggle("Auto-Label Sections", isOn: $options.autoLabelSections)
                }

                Section("Chords") {
                    Toggle("Standardize Chord Format", isOn: $options.standardizeChords)
                }

                Section("Metadata") {
                    Toggle("Extract Metadata", isOn: $options.extractMetadata)
                }

                Section("Presets") {
                    Button("Standard") {
                        options = .standard
                    }

                    Button("Minimal") {
                        options = .minimal
                    }

                    Button("Aggressive") {
                        options = .aggressive
                    }
                }
            }
            .navigationTitle("Formatting Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
