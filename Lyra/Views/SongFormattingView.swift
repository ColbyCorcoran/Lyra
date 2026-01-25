//
//  SongFormattingView.swift
//  Lyra
//
//  Phase 7.6: Song Formatting Intelligence
//  Single song formatting interface
//
//  Created by Claude AI on 1/24/26.
//

import SwiftUI

/// Single song formatting interface with preview and quality scoring
struct SongFormattingView: View {

    // MARK: - Properties

    @Binding var songText: String
    @Environment(\.dismiss) private var dismiss

    @State private var manager = FormattingManager()
    @State private var result: FormattingResult?
    @State private var showingPreview = false
    @State private var isAnalyzing = false
    @State private var selectedIssues: Set<UUID> = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let result = result {
                    // Quality Score Header
                    QualityScoreCard(score: result.qualityScore)
                        .padding()

                    Divider()

                    // Main Content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Preview Toggle
                            Toggle("Show Preview", isOn: $showingPreview)
                                .padding(.horizontal)

                            // Text Editor or Comparison
                            if showingPreview {
                                ComparisonView(
                                    original: result.originalText,
                                    formatted: result.formattedText
                                )
                                .frame(height: 300)
                            } else {
                                TextEditor(text: .constant(result.originalText))
                                    .frame(height: 300)
                                    .font(.system(.body, design: .monospaced))
                                    .border(Color.secondary.opacity(0.3))
                            }

                            // Issues List
                            if !result.qualityScore.issues.isEmpty {
                                IssuesList(
                                    issues: result.qualityScore.issues,
                                    selectedIssues: $selectedIssues
                                )
                            }

                            // Suggestions
                            if !result.suggestions.isEmpty {
                                SuggestionsSection(suggestions: result.suggestions)
                            }

                            // Changes
                            if !result.changes.isEmpty {
                                ChangesSection(changes: result.changes)
                            }
                        }
                        .padding(.vertical)
                    }
                } else if isAnalyzing {
                    VStack(spacing: 20) {
                        ProgressView("Analyzing formatting...")
                        Text("Detecting structure and quality")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Tap 'Analyze' to check formatting quality")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("Format Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if result != nil {
                            Button("Fix All") {
                                applyAllFixes()
                            }

                            Button("Apply") {
                                applySong()
                            }
                            .fontWeight(.semibold)
                        } else {
                            Button("Analyze") {
                                analyzeSong()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func analyzeSong() {
        isAnalyzing = true
        Task {
            let formattingResult = await manager.formatSong(songText)
            result = formattingResult
            isAnalyzing = false
            showingPreview = true
        }
    }

    private func applyAllFixes() {
        guard let result = result else { return }
        songText = result.formattedText
        dismiss()
    }

    private func applySong() {
        guard let result = result else { return }

        if selectedIssues.isEmpty {
            // Apply all formatting
            songText = result.formattedText
        } else {
            // Apply only selected fixes
            let selectedIssuesList = result.qualityScore.issues.filter { selectedIssues.contains($0.id) }
            songText = manager.applyFixes(songText, issues: selectedIssuesList)
        }

        dismiss()
    }
}

// MARK: - Quality Score Card

struct QualityScoreCard: View {
    let score: QualityScore

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                CircularProgressView(value: score.overall)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading) {
                    Text("\(score.percentage)%")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                    Text("Quality Score - Grade \(score.grade)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Metrics
            HStack(spacing: 12) {
                MetricBadge(label: "Spacing", value: score.spacing)
                MetricBadge(label: "Alignment", value: score.alignment)
                MetricBadge(label: "Structure", value: score.structure)
                MetricBadge(label: "Chords", value: score.chordFormat)
                MetricBadge(label: "Metadata", value: score.metadata)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let value: Float

    var color: Color {
        switch value {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .yellow
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: CGFloat(value))
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: value)
        }
    }
}

// MARK: - Metric Badge

struct MetricBadge: View {
    let label: String
    let value: Float?

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int((value ?? 0) * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Comparison View

struct ComparisonView: View {
    let original: String
    let formatted: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Original")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Formatted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)

            HStack(spacing: 1) {
                ScrollView {
                    Text(original)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color.red.opacity(0.1))

                Divider()

                ScrollView {
                    Text(formatted)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color.green.opacity(0.1))
            }
        }
        .border(Color.secondary.opacity(0.3))
    }
}

// MARK: - Issues List

struct IssuesList: View {
    let issues: [QualityIssue]
    @Binding var selectedIssues: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Issues (\(issues.count))")
                .font(.headline)
                .padding(.horizontal)

            ForEach(issues) { issue in
                IssueRow(issue: issue, isSelected: selectedIssues.contains(issue.id))
                    .onTapGesture {
                        if selectedIssues.contains(issue.id) {
                            selectedIssues.remove(issue.id)
                        } else {
                            selectedIssues.insert(issue.id)
                        }
                    }
            }
        }
    }
}

// MARK: - Issue Row

struct IssueRow: View {
    let issue: QualityIssue
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity Icon
            Image(systemName: issue.severity.icon)
                .foregroundColor(severityColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.description)
                    .font(.body)

                if let lineNumber = issue.lineNumber {
                    Text("Line \(lineNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(issue.suggestion)
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Spacer()

            if issue.autoFixable {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var severityColor: Color {
        switch issue.severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Suggestions Section

struct SuggestionsSection: View {
    let suggestions: [FormattingSuggestion]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestions")
                .font(.headline)
                .padding(.horizontal)

            ForEach(suggestions) { suggestion in
                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(suggestion.impact)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Changes Section

struct ChangesSection: View {
    let changes: [FormattingChange]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Changes (\(changes.count))")
                .font(.headline)
                .padding(.horizontal)

            ForEach(changes) { change in
                HStack(spacing: 12) {
                    Image(systemName: change.type.icon)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(change.description)
                            .font(.subheadline)

                        HStack {
                            Text(change.before)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(change.after)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}
