//
//  ProgressionAnalyzerView.swift
//  Lyra
//
//  View for analyzing chord progressions with Roman numeral analysis
//  Part of Phase 7.2: Chord Analysis Intelligence
//

import SwiftUI

struct ProgressionAnalyzerView: View {

    // MARK: - Properties

    let chords: [String]

    @State private var analysis: ProgressionAnalysis?
    @State private var errors: [ChordError] = []
    @State private var showReharmonization = false
    @State private var selectedVariation: ProgressionVariation?

    @State private var analyzer = ProgressionAnalyzer()
    @State private var suggestionEngine = ChordSuggestionEngine()
    @State private var reharmonizer = ReharmonizationEngine()

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let analysis = analysis {
                        // Analysis Summary
                        summaryCard(analysis)

                        // Roman Numeral Analysis
                        romanNumeralSection(analysis)

                        // Progression Type
                        if let type = analysis.progressionType {
                            progressionTypeCard(type, commonName: analysis.commonName)
                        }

                        // Errors & Suggestions
                        if !errors.isEmpty {
                            errorsSection
                        }

                        // Variations
                        if !analysis.variations.isEmpty {
                            variationsSection(analysis.variations)
                        }

                        // Reharmonization
                        reharmonizationSection
                    } else {
                        ProgressView("Analyzing progression...")
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Progression Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedVariation) { variation in
                variationDetailView(variation)
            }
        }
        .onAppear {
            analyzeProgression()
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ analysis: ProgressionAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Analysis", systemImage: "chart.bar.fill")
                    .font(.headline)

                Spacer()

                if analysis.confidence > 0 {
                    ConfidenceBadge(confidence: analysis.confidence)
                }
            }

            Divider()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                infoItem(title: "Chords", value: "\(chords.count)", icon: "music.quarternote.3")
                infoItem(title: "Key", value: analysis.key ?? "Unknown", icon: "key.fill")
                infoItem(title: "Scale", value: analysis.scale?.rawValue ?? "Unknown", icon: "music.note.list")
                infoItem(title: "Type", value: analysis.commonName ?? "Custom", icon: "waveform")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func infoItem(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Roman Numeral Section

    private func romanNumeralSection(_ analysis: ProgressionAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Roman Numeral Analysis")
                .font(.headline)

            ForEach(analysis.romanNumerals) { numeral in
                romanNumeralRow(numeral)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func romanNumeralRow(_ numeral: RomanNumeral) -> some View {
        HStack(spacing: 16) {
            // Roman Numeral
            Text(numeral.numeral)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(numeral.function.color)
                .frame(width: 60, alignment: .leading)

            // Chord
            Text(numeral.chord)
                .font(.headline)

            Spacer()

            // Function
            Text(numeral.function.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(numeral.function.color.opacity(0.15))
                .foregroundStyle(numeral.function.color)
                .cornerRadius(4)

            // Diatonic indicator
            if !numeral.isDiatonic {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }

    // MARK: - Progression Type Card

    private func progressionTypeCard(_ type: ProgressionType, commonName: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.green)

                Text("Recognized Progression")
                    .font(.headline)
            }

            Text(commonName ?? type.rawValue)
                .font(.title3)
                .fontWeight(.bold)

            Text(type.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Errors Section

    private var errorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Issues")
                .font(.headline)

            ForEach(errors) { error in
                errorCard(error)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func errorCard(_ error: ChordError) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: error.errorType.icon)
                    .foregroundStyle(error.severity.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.errorType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("\(error.chord) at position \(error.chordIndex + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(error.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !error.suggestions.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ForEach(error.suggestions.prefix(3)) { suggestion in
                        HStack {
                            Text(suggestion.chord)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(suggestion.reason.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            ConfidenceBadge(confidence: suggestion.confidence)
                        }
                    }
                }
            }
        }
        .padding()
        .background(error.severity.color.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Variations Section

    private func variationsSection(_ variations: [ProgressionVariation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Variations")
                .font(.headline)

            ForEach(variations.prefix(5)) { variation in
                Button {
                    selectedVariation = variation
                } label: {
                    variationCard(variation)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func variationCard(_ variation: ProgressionVariation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(variation.variationType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(variation.difficulty.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(variation.difficulty.color.opacity(0.15))
                    .foregroundStyle(variation.difficulty.color)
                    .cornerRadius(4)
            }

            Text(variation.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(variation.chords.joined(separator: " → "))
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }

    // MARK: - Reharmonization Section

    private var reharmonizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reharmonization")
                    .font(.headline)

                Spacer()

                Button {
                    showReharmonization.toggle()
                } label: {
                    Image(systemName: showReharmonization ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.blue)
                }
            }

            if showReharmonization {
                let variations = reharmonizer.reharmonize(chords, style: .balanced)

                ForEach(variations) { variation in
                    variationCard(variation)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Variation Detail View

    private func variationDetailView(_ variation: ProgressionVariation) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(variation.variationType.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(variation.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Difficulty:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(variation.difficulty.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(variation.difficulty.color)
                        }
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)

                    // Original vs New
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comparison")
                            .font(.headline)

                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Original")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach(chords, id: \.self) { chord in
                                    Text(chord)
                                        .font(.subheadline)
                                        .padding(.vertical, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Variation")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ForEach(variation.chords, id: \.self) { chord in
                                    Text(chord)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                        .padding(.vertical, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Variation Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedVariation = nil
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func analyzeProgression() {
        // Analyze progression
        analysis = analyzer.analyzeProgression(chords)

        // Detect errors
        errors = suggestionEngine.detectErrors(in: chords, key: analysis?.key)
    }
}

// MARK: - Preview

#Preview {
    ProgressionAnalyzerView(chords: ["C", "G", "Am", "F"])
}
