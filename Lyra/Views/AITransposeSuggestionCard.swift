//
//  AITransposeSuggestionCard.swift
//  Lyra
//
//  Card component for displaying transpose recommendations
//  Part of Phase 7.9: Transpose Intelligence
//

import SwiftUI

struct AITransposeSuggestionCard: View {
    let recommendation: TransposeRecommendation
    let isExpanded: Bool
    let onTap: () -> Void
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recommendation.targetKey)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            HStack(spacing: 6) {
                                confidenceBadge
                                scoreBadge
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            semitonesBadge

                            if let capo = recommendation.suggestedCapo, capo > 0 {
                                Text("Capo \(capo)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.2))
                                    .clipShape(Capsule())
                                    .foregroundStyle(.purple)
                            }
                        }
                    }

                    // Benefits
                    if !recommendation.benefits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recommendation.benefits.prefix(3)) { benefit in
                                benefitRow(benefit)
                            }
                        }
                    }

                    // Warnings
                    if !recommendation.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recommendation.warnings) { warning in
                                warningRow(warning)
                            }
                        }
                    }

                    // Expand indicator
                    HStack {
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(isExpanded ? "Less" : "More Details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Apply button
            Divider()

            Button(action: onApply) {
                HStack {
                    Spacer()
                    Label("Apply This Transpose", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                    Spacer()
                }
                .padding()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Badges

    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
            Text("\(Int(recommendation.confidenceScore * 100))%")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.2))
        .clipShape(Capsule())
        .foregroundStyle(confidenceColor)
    }

    private var confidenceIcon: String {
        switch recommendation.confidenceScore {
        case 0.8...1.0: return "star.fill"
        case 0.6..<0.8: return "star.leadinghalf.filled"
        default: return "star"
        }
    }

    private var confidenceColor: Color {
        switch recommendation.confidenceScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        default: return .orange
        }
    }

    private var scoreBadge: some View {
        Text("\(Int(recommendation.overallScore))/100")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(scoreColor.opacity(0.2))
            .clipShape(Capsule())
            .foregroundStyle(scoreColor)
    }

    private var scoreColor: Color {
        switch recommendation.overallScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var semitonesBadge: some View {
        let direction = recommendation.semitones > 0 ? "↑" : "↓"
        let text = recommendation.semitones == 0 ? "No change" :
            "\(direction) \(abs(recommendation.semitones)) semitone\(abs(recommendation.semitones) == 1 ? "" : "s")"

        return Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Benefit Row

    private func benefitRow(_ benefit: TransposeBenefit) -> some View {
        HStack(spacing: 8) {
            Image(systemName: benefit.icon)
                .font(.caption)
                .foregroundStyle(benefit.category.color)
                .frame(width: 20)

            Text(benefit.description)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            impactIndicator(benefit.impact)
        }
        .padding(.vertical, 4)
    }

    private func impactIndicator(_ impact: Float) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Float(index) < impact * 3 ? Color.green : Color(.systemGray4))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Warning Row

    private func warningRow(_ warning: TransposeWarning) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: warning.severity.icon)
                .font(.caption)
                .foregroundStyle(warning.severity.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(warning.issue)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                if let mitigation = warning.mitigation {
                    Text(mitigation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(8)
        .background(warning.severity.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            // Score Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Score Breakdown")
                    .font(.headline)
                    .padding(.horizontal)

                if let voiceScore = recommendation.voiceRangeScore {
                    scoreBar(
                        label: "Vocal Fit",
                        score: voiceScore,
                        icon: "mic.fill",
                        color: .green
                    )
                }

                scoreBar(
                    label: "Chord Difficulty",
                    score: 1.0 - (recommendation.difficultyScore / 10.0),
                    icon: "guitars",
                    color: .orange
                )

                if let capoScore = recommendation.capoScore {
                    scoreBar(
                        label: "Capo Benefit",
                        score: capoScore,
                        icon: "bookmark.fill",
                        color: .purple
                    )
                }

                scoreBar(
                    label: "Your Preferences",
                    score: recommendation.userPreferenceScore,
                    icon: "person.fill",
                    color: .pink
                )

                if let bandScore = recommendation.bandFitnessScore {
                    scoreBar(
                        label: "Band Fit",
                        score: bandScore,
                        icon: "person.3.fill",
                        color: .cyan
                    )
                }
            }
            .padding(.vertical)

            // Theory Explanation
            if let theory = recommendation.theoryExplanation {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Music Theory")
                        .font(.headline)
                        .padding(.horizontal)

                    theorySection(theory)
                }
                .padding(.vertical)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Score Bar

    private func scoreBar(label: String, score: Float, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)

                Spacer()

                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(score), height: 8)
                }
                .clipShape(Capsule())
            }
            .frame(height: 8)
            .padding(.horizontal)
        }
    }

    // MARK: - Theory Section

    private func theorySection(_ theory: TheoryExplanation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(theory.summary)
                .font(.subheadline)
                .padding(.horizontal)

            HStack(spacing: 16) {
                theoryDetail(
                    label: "Relationship",
                    value: theory.keyRelationship.rawValue,
                    color: theory.keyRelationship.color
                )

                Divider()
                    .frame(height: 40)

                theoryDetail(
                    label: "Circle of Fifths",
                    value: "\(theory.circleOfFifthsDistance) steps",
                    color: .blue
                )
            }
            .padding(.horizontal)

            Text("Key Signature: \(theory.keySignature)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if !theory.educationalNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(theory.educationalNotes, id: \.self) { note in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                            Text(note)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }

    private func theoryDetail(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            AITransposeSuggestionCard(
                recommendation: TransposeRecommendation(
                    targetKey: "G",
                    semitones: 2,
                    confidenceScore: 0.85,
                    overallScore: 87,
                    voiceRangeScore: 0.9,
                    difficultyScore: 3.5,
                    capoScore: 0.7,
                    userPreferenceScore: 0.8,
                    bandFitnessScore: 0.75,
                    benefits: [
                        TransposeBenefit(
                            category: .vocalFit,
                            description: "Perfect for your vocal range",
                            impact: 0.9,
                            icon: "mic.fill"
                        ),
                        TransposeBenefit(
                            category: .easierChords,
                            description: "Simpler chord shapes",
                            impact: 0.7,
                            icon: "guitars"
                        )
                    ],
                    warnings: [
                        TransposeWarning(
                            severity: .info,
                            issue: "Minor change in song character",
                            mitigation: "Try playing it first"
                        )
                    ],
                    theoryExplanation: TheoryExplanation(
                        summary: "G major is a close key - smooth transition",
                        keyRelationship: .circleOfFifths,
                        circleOfFifthsDistance: 1,
                        keySignature: "1 sharp (F#)",
                        educationalNotes: ["Very common guitar key", "Easy open chords available"]
                    ),
                    suggestedCapo: nil
                ),
                isExpanded: true,
                onTap: {},
                onApply: {}
            )
        }
        .padding()
    }
}
