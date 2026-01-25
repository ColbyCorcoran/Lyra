//
//  CapoView.swift
//  Lyra
//
//  Comprehensive capo management interface
//

import SwiftUI
import SwiftData

struct CapoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let setEntry: SetEntry?
    let onCapoChange: (Int) -> Void

    @State private var capoFret: Int
    @State private var showCapoChords: Bool = true
    @State private var suggestions: [CapoSuggestion] = []
    @State private var commonPatterns: [CapoPattern] = []
    @State private var selectedTab: CapoTab = .current

    enum CapoTab: String, CaseIterable {
        case current = "Current"
        case suggestions = "Suggestions"
        case patterns = "Patterns"
        case aiOptimize = "AI Optimize"
    }

    init(song: Song, setEntry: SetEntry? = nil, onCapoChange: @escaping (Int) -> Void) {
        self.song = song
        self.setEntry = setEntry
        self.onCapoChange = onCapoChange

        // Initialize with current capo or set override
        let initialCapo = setEntry?.capoOverride ?? song.capo ?? 0
        _capoFret = State(initialValue: initialCapo)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    ForEach(CapoTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    currentCapoView
                        .tag(CapoTab.current)

                    suggestionsView
                        .tag(CapoTab.suggestions)

                    patternsView
                        .tag(CapoTab.patterns)

                    aiOptimizeView
                        .tag(CapoTab.aiOptimize)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Capo Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyCapo()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadSuggestions()
                loadCommonPatterns()
            }
        }
    }

    // MARK: - Current Capo View

    private var currentCapoView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Capo Position Picker
                VStack(spacing: 16) {
                    // Visual capo indicator
                    HStack(spacing: 4) {
                        ForEach(0..<12, id: \.self) { fret in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(fret == capoFret ? Color.blue : Color(.systemGray5))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("\(fret)")
                                            .font(.caption)
                                            .fontWeight(fret == capoFret ? .bold : .regular)
                                            .foregroundStyle(fret == capoFret ? .white : .secondary)
                                    )

                                if fret == capoFret {
                                    Image(systemName: "guitars")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .onTapGesture {
                                capoFret = fret
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Fret number display
                    HStack {
                        Button {
                            if capoFret > 0 {
                                capoFret -= 1
                                HapticManager.shared.selection()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(capoFret == 0)

                        VStack(spacing: 4) {
                            if capoFret == 0 {
                                Text("No Capo")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            } else {
                                Text("Fret \(capoFret)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                            }

                            if capoFret > 0, let key = song.currentKey {
                                let playKey = CapoEngine.writtenKey(soundingKey: key, capoFret: capoFret) ?? "?"
                                Text("Play \(playKey) shapes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(minWidth: 120)

                        Button {
                            if capoFret < 11 {
                                capoFret += 1
                                HapticManager.shared.selection()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(capoFret == 11)
                    }

                    if capoFret > 0 {
                        Button {
                            capoFret = 0
                            HapticManager.shared.warning()
                        } label: {
                            Label("Remove Capo", systemImage: "xmark.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Key Information
                if let key = song.currentKey {
                    keyInformationCard(key: key)
                }

                // Capo + Transpose Interaction
                if let key = song.currentKey, song.currentKey != song.originalKey || capoFret > 0 {
                    capoTransposeCard(key: key)
                }

                // Quick actions
                if capoFret == 0 && !suggestions.isEmpty {
                    suggestionsPreviewCard
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Suggestions View

    private var suggestionsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if suggestions.isEmpty {
                    emptyState(
                        icon: "lightbulb",
                        title: "No Suggestions",
                        message: "This song already has easy chords, or capo won't help much."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Easier Fingerings")
                            .font(.headline)
                            .padding(.horizontal)

                        Text("Try these capo positions for simpler chords")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    ForEach(suggestions) { suggestion in
                        suggestionCard(suggestion)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Patterns View

    private var patternsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if commonPatterns.isEmpty {
                    emptyState(
                        icon: "music.note.list",
                        title: "No Common Patterns",
                        message: "No standard capo patterns available for this key."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common Patterns")
                            .font(.headline)
                            .padding(.horizontal)

                        Text("Popular capo positions for \(song.currentKey ?? "this key")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    ForEach(commonPatterns) { pattern in
                        patternCard(pattern)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - AI Optimize View

    private var aiOptimizeView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.blue)
                        Text("AI-Powered Capo Optimization")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    Text("Intelligent capo suggestions based on chord difficulty and your skill level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                // Get skill level and generate recommendations
                if let aiRecommendations = getAICapoRecommendations() {
                    if aiRecommendations.isEmpty {
                        emptyState(
                            icon: "checkmark.circle.fill",
                            title: "Already Optimized",
                            message: "This song already uses simple chord shapes. No capo needed!"
                        )
                    } else {
                        ForEach(aiRecommendations) { rec in
                            aiCapoRecommendationCard(rec)
                        }
                    }
                } else {
                    ProgressView()
                        .padding()
                }

                // Educational tip
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("Pro Tip")
                            .font(.headline)
                    }

                    Text("Using a capo can make difficult songs much easier by allowing you to play simpler chord shapes while maintaining the original key.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func aiCapoRecommendationCard(_ recommendation: CapoRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Capo Fret \(recommendation.capoPosition)")
                            .font(.title2)
                            .fontWeight(.bold)

                        // Score badge
                        Text("\(Int(recommendation.overallScore * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(scoreColor(recommendation.overallScore).opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundStyle(scoreColor(recommendation.overallScore))
                    }

                    Text(recommendation.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer()

                Button {
                    capoFret = recommendation.capoPosition
                    selectedTab = .current
                    HapticManager.shared.success()
                } label: {
                    Text("Apply")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            // Benefits
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Difficulty")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(recommendation.difficultyDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                if recommendation.barreReduction > 0 {
                    Divider()
                        .frame(height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Barre Chords")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("-\(recommendation.barreReduction)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Improvement")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(recommendation.improvementDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func scoreColor(_ score: Float) -> Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        default: return .orange
        }
    }

    private func getAICapoRecommendations() -> [CapoRecommendation]? {
        // Get user's skill level (default to intermediate if not available)
        let skillLevel: SkillLevel = .intermediate // TODO: Get from SkillAssessmentEngine

        // Use CapoOptimizationEngine to get recommendations
        let difficultyEngine = ChordDifficultyAnalysisEngine()
        let capoOptimizer = CapoOptimizationEngine(difficultyEngine: difficultyEngine)

        let recommendations = capoOptimizer.findOptimalCapo(
            content: song.content,
            skillLevel: skillLevel
        )

        return recommendations
    }

    // MARK: - Card Views

    private func keyInformationCard(key: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Information", systemImage: "music.note")
                .font(.headline)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Song Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(key)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                if capoFret > 0 {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Play")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CapoEngine.writtenKey(soundingKey: key, capoFret: capoFret) ?? "?")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func capoTransposeCard(key: String) -> some View {
        let transpose = TransposeEngine.semitonesBetween(
            from: song.originalKey,
            to: song.currentKey
        )
        let explanation = CapoEngine.explainCapoTranspose(
            originalKey: song.originalKey,
            transpose: transpose,
            capo: capoFret
        )

        return VStack(alignment: .leading, spacing: 12) {
            Label("What's Happening", systemImage: "info.circle")
                .font(.headline)

            Divider()

            Text(explanation.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if transpose != 0 || capoFret > 0 {
                VStack(spacing: 8) {
                    if let original = song.originalKey, original != explanation.transposedKey {
                        infoRow(label: "Original Key", value: original)
                    }

                    if transpose != 0 {
                        infoRow(label: "Transposed To", value: explanation.transposedKey)
                    }

                    if capoFret > 0 {
                        infoRow(label: "Capo Fret", value: String(capoFret))
                        infoRow(label: "Play Chords", value: explanation.capoChords)
                        infoRow(label: "Sounds Like", value: explanation.soundingKey)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var suggestionsPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Try a Capo?", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)

                Spacer()

                Button {
                    withAnimation {
                        selectedTab = .suggestions
                    }
                } label: {
                    Text("View All")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            if let topSuggestion = suggestions.first {
                Text("Capo \(topSuggestion.fret) makes chords \(topSuggestion.improvementDescription)")
                    .font(.subheadline)

                Button {
                    capoFret = topSuggestion.fret
                    HapticManager.shared.success()
                } label: {
                    Label("Apply Capo \(topSuggestion.fret)", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func suggestionCard(_ suggestion: CapoSuggestion) -> some View {
        Button {
            capoFret = suggestion.fret
            selectedTab = .current
            HapticManager.shared.success()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capo Fret \(suggestion.fret)")
                            .font(.headline)

                        Text(suggestion.reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(suggestion.improvementDescription)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)

                        Text(suggestion.difficultyDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 8) {
                    Text("Sample chords:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(suggestion.sampleChords, id: \.self) { chord in
                        Text(chord)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func patternCard(_ pattern: CapoPattern) -> some View {
        Button {
            capoFret = pattern.capo
            selectedTab = .current
            HapticManager.shared.success()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Text("\(pattern.capo)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if pattern.capo == 0 {
                        Text("No Capo")
                            .font(.headline)
                    } else {
                        Text("Capo Fret \(pattern.capo)")
                            .font(.headline)
                    }

                    Text("Play \(pattern.plays) shapes")
                        .font(.subheadline)
                        .foregroundStyle(.blue)

                    Text(pattern.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Views

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func loadSuggestions() {
        suggestions = CapoEngine.suggestCapo(
            content: song.content,
            currentKey: song.currentKey
        )
    }

    private func loadCommonPatterns() {
        if let key = song.currentKey {
            commonPatterns = CapoEngine.commonCapoPositions(for: key)
        }
    }

    private func applyCapo() {
        onCapoChange(capoFret)
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

    return CapoView(song: song, setEntry: nil) { capo in
        print("Set capo to \(capo)")
    }
    .modelContainer(container)
}
