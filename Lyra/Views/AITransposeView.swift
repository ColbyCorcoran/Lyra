//
//  AITransposeView.swift
//  Lyra
//
//  Main AI-powered transpose intelligence interface
//  Part of Phase 7.9: Transpose Intelligence
//

import SwiftUI
import SwiftData

struct AITransposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let onTranspose: (Int, Bool, TransposeSaveMode) -> Void

    @State private var selectedTab: AITransposeTab = .smartTranspose
    @State private var manager: TransposeIntelligenceManager?
    @State private var recommendations: [TransposeRecommendation] = []
    @State private var isLoading = true
    @State private var showVoiceSetup = false
    @State private var expandedRecommendationID: UUID?

    enum AITransposeTab: String, CaseIterable {
        case smartTranspose = "Smart"
        case voiceMatch = "Voice"
        case difficulty = "Difficulty"
        case capo = "Capo"
        case band = "Band"
        case theory = "Theory"

        var icon: String {
            switch self {
            case .smartTranspose: return "wand.and.stars"
            case .voiceMatch: return "mic.fill"
            case .difficulty: return "chart.bar.fill"
            case .capo: return "guitars"
            case .band: return "person.3.fill"
            case .theory: return "book.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AITransposeTab.allCases, id: \.self) { tab in
                            tabButton(tab)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGray6))

                // Content
                if isLoading {
                    loadingView
                } else {
                    TabView(selection: $selectedTab) {
                        smartTransposeTab
                            .tag(AITransposeTab.smartTranspose)

                        voiceMatchTab
                            .tag(AITransposeTab.voiceMatch)

                        difficultyTab
                            .tag(AITransposeTab.difficulty)

                        capoTab
                            .tag(AITransposeTab.capo)

                        bandTab
                            .tag(AITransposeTab.band)

                        theoryTab
                            .tag(AITransposeTab.theory)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("AI Transpose Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await initializeManager()
            }
            .sheet(isPresented: $showVoiceSetup) {
                VoiceRangeSetupView()
            }
        }
    }

    // MARK: - Tab Button

    private func tabButton(_ tab: AITransposeTab) -> some View {
        Button {
            withAnimation {
                selectedTab = tab
            }
            HapticManager.shared.selection()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.title3)

                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .background(
                selectedTab == tab ?
                    Color.blue.opacity(0.2) : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(selectedTab == tab ? .blue : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Smart Transpose Tab

    private var smartTransposeTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if recommendations.isEmpty {
                    emptyState(
                        icon: "wand.and.stars",
                        title: "No Recommendations",
                        message: "Unable to generate transpose recommendations for this song."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(.blue)
                            Text("Top Recommendations")
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        Text("AI-powered analysis based on multiple factors")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    ForEach(recommendations.prefix(5)) { recommendation in
                        AITransposeSuggestionCard(
                            recommendation: recommendation,
                            isExpanded: expandedRecommendationID == recommendation.id,
                            onTap: {
                                withAnimation {
                                    expandedRecommendationID = expandedRecommendationID == recommendation.id ? nil : recommendation.id
                                }
                            },
                            onApply: {
                                applyRecommendation(recommendation)
                            }
                        )
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Voice Match Tab

    private var voiceMatchTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.green)
                        Text("Voice Range Matching")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    Text("Find keys that fit your vocal range")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                // Check if user has vocal range set
                if manager?.keyLearningEngine.getUserPreferences().vocalRange == nil {
                    setupVocalRangeCard
                } else {
                    voiceRecommendationsCard
                }
            }
            .padding(.vertical)
        }
    }

    private var setupVocalRangeCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("Set Up Your Vocal Range")
                .font(.headline)

            Text("Tell us your vocal range to get personalized key recommendations")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showVoiceSetup = true
            } label: {
                Label("Set Up Voice Range", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var voiceRecommendationsCard: some View {
        VStack(spacing: 12) {
            ForEach(recommendations.filter { $0.voiceRangeScore != nil }.prefix(5)) { rec in
                voiceMatchRow(rec)
            }

            if recommendations.filter({ $0.voiceRangeScore != nil }).isEmpty {
                Text("All recommendations displayed in Smart tab")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    private func voiceMatchRow(_ recommendation: TransposeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.targetKey)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let voiceScore = recommendation.voiceRangeScore {
                        HStack(spacing: 4) {
                            Image(systemName: voiceScore > 0.8 ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundStyle(voiceScore > 0.8 ? .green : .orange)
                            Text("Vocal Fit: \(Int(voiceScore * 100))%")
                                .font(.caption)
                        }
                    }
                }

                Spacer()

                Button {
                    applyRecommendation(recommendation)
                } label: {
                    Text("Apply")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Difficulty Tab

    private var difficultyTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(.orange)
                        Text("Chord Difficulty")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    Text("Find easier keys to play")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                ForEach(recommendations.sorted { $0.difficultyScore < $1.difficultyScore }.prefix(5)) { rec in
                    difficultyRow(rec)
                }
            }
            .padding(.vertical)
        }
    }

    private func difficultyRow(_ recommendation: TransposeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.targetKey)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 4) {
                        difficultyIndicator(recommendation.difficultyScore)
                        Text("Difficulty: \(String(format: "%.1f", recommendation.difficultyScore))/10")
                            .font(.caption)
                    }
                }

                Spacer()

                Button {
                    applyRecommendation(recommendation)
                } label: {
                    Text("Apply")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func difficultyIndicator(_ difficulty: Float) -> some View {
        let color: Color = {
            switch difficulty {
            case 0..<3.0: return .green
            case 3.0..<5.0: return .blue
            case 5.0..<7.0: return .orange
            default: return .red
            }
        }()

        return Image(systemName: "circle.fill")
            .foregroundStyle(color)
    }

    // MARK: - Capo Tab

    private var capoTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "guitars")
                            .foregroundStyle(.purple)
                        Text("Capo Optimization")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    Text("Find optimal capo positions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                ForEach(recommendations.filter { $0.suggestedCapo != nil }.prefix(5)) { rec in
                    capoRow(rec)
                }

                if recommendations.filter({ $0.suggestedCapo != nil }).isEmpty {
                    emptyState(
                        icon: "guitars",
                        title: "No Capo Suggestions",
                        message: "Current song already uses simple chord shapes."
                    )
                }
            }
            .padding(.vertical)
        }
    }

    private func capoRow(_ recommendation: TransposeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(recommendation.targetKey)
                            .font(.title2)
                            .fontWeight(.bold)

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

                    if let capoScore = recommendation.capoScore {
                        Text("Improvement: \(Int(capoScore * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    applyRecommendation(recommendation)
                } label: {
                    Text("Apply")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Band Tab

    private var bandTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundStyle(.cyan)
                        Text("Band Optimization")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    Text("Coming soon: Multi-musician key optimization")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                emptyState(
                    icon: "person.3.fill",
                    title: "Band Mode",
                    message: "Set up band member profiles to find compromise keys that work for everyone."
                )

                NavigationLink(destination: BandProfilesView()) {
                    Label("Manage Band Members", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Theory Tab

    private var theoryTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.indigo)
                        Text("Music Theory")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    Text("Understand why these keys work")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                if let topRec = recommendations.first,
                   let theory = topRec.theoryExplanation {
                    theoryExplanationCard(theory, for: topRec)
                }

                NavigationLink(destination: TransposeTheoryView(song: song)) {
                    Label("Learn More About Key Relationships", systemImage: "book.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func theoryExplanationCard(_ theory: TheoryExplanation, for recommendation: TransposeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(theory.summary)
                .font(.body)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Relationship")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(theory.keyRelationship.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Circle of Fifths")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(theory.circleOfFifthsDistance) steps")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Key Signature")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(theory.keySignature)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing transpose options...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Empty State

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
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

    private func initializeManager() async {
        let keyLearning = KeyLearningEngine()
        let skillEngine = SkillAssessmentEngine(modelContext: modelContext)

        manager = TransposeIntelligenceManager(
            modelContext: modelContext,
            keyLearningEngine: keyLearning,
            skillAssessmentEngine: skillEngine
        )

        // Get recommendations
        if let mgr = manager {
            let result = mgr.getSmartTransposeRecommendations(song: song)
            await MainActor.run {
                recommendations = result.recommendations
                isLoading = false
            }
        }
    }

    private func applyRecommendation(_ recommendation: TransposeRecommendation) {
        onTranspose(
            recommendation.semitones,
            true, // preferSharps
            .permanent
        )

        // Record in learning engine if available
        if let learningEngine = manager?.learningEngine {
            Task {
                await learningEngine.recordTranspose(
                    songID: song.id,
                    originalKey: song.currentKey ?? song.originalKey ?? "C",
                    newKey: recommendation.targetKey,
                    semitones: recommendation.semitones,
                    recommendationID: recommendation.id
                )
            }
        }

        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

    return AITransposeView(song: song) { semitones, preferSharps, saveMode in
        print("Apply transpose: \(semitones)")
    }
    .modelContainer(container)
}
