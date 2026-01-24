//
//  KeyRecommendationView.swift
//  Lyra
//
//  Main view for intelligent key detection and recommendation
//  Part of Phase 7.3: Key Intelligence
//

import SwiftUI

struct KeyRecommendationView: View {

    // MARK: - Properties

    let chords: [String]
    let currentKey: String?
    let onKeySelected: (String) -> Void

    @State private var recommendations: [KeyRecommendation] = []
    @State private var keyDetection: KeyDetectionResult?
    @State private var vocalRange: VocalRange?
    @State private var showVocalRangeInput = false
    @State private var showKeyEducation = false
    @State private var selectedKey: String?

    @State private var engine = KeyRecommendationEngine()
    @State private var learningEngine = KeyLearningEngine()

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Auto-detected key
                    if let detection = keyDetection {
                        autoDetectedKeySection(detection)
                    }

                    // Vocal range section
                    vocalRangeSection

                    // Recommendations
                    if !recommendations.isEmpty {
                        recommendationsSection
                    }

                    // Key education
                    educationButtonSection
                }
                .padding()
            }
            .navigationTitle("Find Best Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showVocalRangeInput) {
                VocalRangeInputView(onRangeDetected: { range in
                    vocalRange = range
                    learningEngine.updateVocalRange(range)
                    analyzeKeys()
                })
            }
            .sheet(isPresented: $showKeyEducation) {
                if let key = selectedKey {
                    KeyEducationView(key: key)
                }
            }
        }
        .onAppear {
            analyzeKeys()
        }
    }

    // MARK: - Auto-Detected Key Section

    private func autoDetectedKeySection(_ detection: KeyDetectionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Auto-Detected Key", systemImage: "waveform.circle.fill")
                    .font(.headline)
                Spacer()
            }

            if let mostLikely = detection.mostLikelyKey {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mostLikely.fullKeyName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(Int(mostLikely.confidence * 100))% Confidence")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        selectedKey = mostLikely.key
                        showKeyEducation = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

                if detection.modalAmbiguity {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Modal ambiguity detected - could also be \(detection.possibleKeys[1].fullKeyName)")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            Text(detection.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Vocal Range Section

    private var vocalRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Vocal Range", systemImage: "mic.fill")
                    .font(.headline)

                Spacer()

                if vocalRange == nil {
                    Button {
                        showVocalRangeInput = true
                    } label: {
                        Text("Record Range")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }

            if let range = vocalRange {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Range:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(range.description)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        if let voiceType = range.voiceType {
                            Text(voiceType.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(voiceType.color.opacity(0.2))
                                .foregroundStyle(voiceType.color)
                                .cornerRadius(4)
                        }
                    }

                    Button {
                        showVocalRangeInput = true
                    } label: {
                        Text("Update Range")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(8)
            } else {
                Text("Record your vocal range to get personalized key recommendations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Keys")
                .font(.headline)

            ForEach(recommendations.prefix(5)) { recommendation in
                recommendationCard(recommendation)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func recommendationCard(_ recommendation: KeyRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.fullKeyName)
                        .font(.title3)
                        .fontWeight(.bold)

                    if recommendation.transpositionSteps != 0 {
                        Text("Transpose \(abs(recommendation.transpositionSteps)) semitones \(recommendation.transpositionSteps > 0 ? "up" : "down")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                ConfidenceBadge(confidence: recommendation.confidence)
            }

            // Reasons
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                ForEach(recommendation.reasons, id: \.rawValue) { reason in
                    HStack(spacing: 4) {
                        Image(systemName: reason.icon)
                            .font(.caption)
                        Text(reason.rawValue)
                            .font(.caption)
                    }
                    .foregroundStyle(reason.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(reason.color.opacity(0.1))
                    .cornerRadius(4)
                }
            }

            // Vocal fit if available
            if let fit = recommendation.vocalRangeFit {
                HStack {
                    Image(systemName: fit.quality.icon)
                        .foregroundStyle(fit.quality.color)

                    Text(fit.quality.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(fit.quality.color)

                    Spacer()
                }
            }

            // Capo info
            if let capo = recommendation.capoDifficulty, capo.worthUsing {
                Divider()

                HStack {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.purple)

                    Text("Capo fret \(capo.suggestedCapo ?? 0)")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(Int(capo.improvementScore * 100))% easier")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // Action button
            Button {
                onKeySelected(recommendation.key)
                learningEngine.recordKeyUsage(recommendation.key)
                dismiss()
            } label: {
                Text("Use This Key")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }

    // MARK: - Education Button Section

    private var educationButtonSection: some View {
        Button {
            if let detected = keyDetection?.mostLikelyKey {
                selectedKey = detected.key
                showKeyEducation = true
            }
        } label: {
            HStack {
                Image(systemName: "graduationcap.fill")
                Text("Learn About Keys")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Actions

    private func analyzeKeys() {
        // Detect key from chords
        keyDetection = engine.detectKey(from: chords)

        // Get personalized preferences
        let prefs = learningEngine.getUserPreferences()

        // Find best keys
        recommendations = engine.findBestKey(
            chords: chords,
            vocalRange: vocalRange,
            userPreferences: prefs
        )
    }
}

// MARK: - Preview

#Preview {
    KeyRecommendationView(
        chords: ["C", "G", "Am", "F"],
        currentKey: nil,
        onKeySelected: { key in
            print("Selected: \(key)")
        }
    )
}
