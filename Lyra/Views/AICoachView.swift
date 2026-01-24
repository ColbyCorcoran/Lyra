//
//  AICoachView.swift
//  Lyra
//
//  AI coaching, tips, and guidance interface
//  Part of Phase 7.7: Practice Intelligence
//

import SwiftUI
import SwiftData

struct AICoachView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var manager: PracticeManager
    @State private var dailyTip: CoachMessage?
    @State private var encouragement: CoachMessage?
    @State private var selectedTheoryTopic: TheoryTopic = .chordConstruction
    @State private var theoryLesson: CoachMessage?
    @State private var showTheorySheet = false

    init(modelContext: ModelContext) {
        _manager = StateObject(wrappedValue: PracticeManager(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Coach Avatar
                    coachAvatarSection

                    // Daily Tip
                    if let tip = dailyTip {
                        TipCard(message: tip)
                    }

                    // Encouragement
                    if let encouragement = encouragement {
                        EncouragementCard(message: encouragement)
                    }

                    // Quick Actions
                    quickActionsSection

                    // Theory Lessons
                    theorySection

                    // Technique Suggestions
                    techniquesSection

                    // Smart Recommendations
                    smartRecommendationsSection
                }
                .padding()
            }
            .navigationTitle("AI Coach")
            .task {
                loadCoachContent()
            }
            .refreshable {
                loadCoachContent()
            }
            .sheet(isPresented: $showTheorySheet) {
                TheoryLessonSheet(lesson: theoryLesson)
            }
        }
    }

    // MARK: - Coach Avatar Section

    private var coachAvatarSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Your Practice Coach")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Personalized guidance to help you improve")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionButton(
                    icon: "lightbulb.fill",
                    title: "New Tip",
                    color: .yellow,
                    action: { dailyTip = manager.getDailyTip() }
                )

                QuickActionButton(
                    icon: "hand.thumbsup.fill",
                    title: "Encouragement",
                    color: .green,
                    action: { encouragement = manager.getEncouragement() }
                )

                QuickActionButton(
                    icon: "book.fill",
                    title: "Theory Lesson",
                    color: .purple,
                    action: { showTheoryPicker() }
                )

                QuickActionButton(
                    icon: "wrench.adjustable.fill",
                    title: "Technique Help",
                    color: .orange,
                    action: { showTechniqueHelp() }
                )
            }
        }
    }

    // MARK: - Theory Section

    private var theorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Music Theory")
                .font(.headline)

            Picker("Topic", selection: $selectedTheoryTopic) {
                Text("Chords").tag(TheoryTopic.chordConstruction)
                Text("Scales").tag(TheoryTopic.scales)
                Text("Keys").tag(TheoryTopic.keys)
                Text("Progressions").tag(TheoryTopic.progressions)
                Text("Rhythm").tag(TheoryTopic.rhythm)
                Text("Harmony").tag(TheoryTopic.harmony)
            }
            .pickerStyle(.menu)

            Button(action: {
                theoryLesson = manager.getTheoryLesson(topic: selectedTheoryTopic)
                showTheorySheet = true
            }) {
                Label("Learn About \(selectedTheoryTopic.displayName)", systemImage: "book.pages")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Techniques Section

    private var techniquesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Technique Guides")
                .font(.headline)

            ForEach(CommonTechniques.allCases, id: \.self) { technique in
                TechniqueRow(technique: technique, manager: manager)
            }
        }
    }

    // MARK: - Smart Recommendations

    private var smartRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalized Suggestions")
                .font(.headline)

            // Get smart suggestion based on current context
            let suggestion = manager.getSmartSuggestion(
                timeAvailable: 30 * 60,  // 30 minutes
                energyLevel: .medium
            )

            SuggestionCard(message: suggestion)

            // Show current weaknesses
            let weaknesses = manager.analyzeWeaknesses()

            if !weaknesses.primaryWeaknesses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Areas")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(weaknesses.primaryWeaknesses, id: \.self) { area in
                        HStack {
                            Image(systemName: "target")
                                .foregroundStyle(.orange)

                            Text(area.rawValue)
                                .font(.subheadline)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadCoachContent() {
        dailyTip = manager.getDailyTip()
        encouragement = manager.getEncouragement()
    }

    private func showTheoryPicker() {
        // Would show picker UI
    }

    private func showTechniqueHelp() {
        // Would show technique selection UI
    }
}

// MARK: - Supporting Views

struct TipCard: View {
    let message: CoachMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)

                Text("Daily Tip")
                    .font(.headline)

                Spacer()
            }

            Text(message.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EncouragementCard: View {
    let message: CoachMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundStyle(.green)

                Text("Encouragement")
                    .font(.headline)

                Spacer()
            }

            Text(message.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SuggestionCard: View {
    let message: CoachMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)

                Text("Suggestion")
                    .font(.headline)

                Spacer()
            }

            Text(message.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial)
            .cornerRadius(12)
        }
    }
}

struct TechniqueRow: View {
    let technique: CommonTechniques
    let manager: PracticeManager

    @State private var showDetail = false

    var body: some View {
        Button(action: { showDetail = true }) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(.orange)

                Text(technique.displayName)
                    .font(.subheadline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showDetail) {
            TechniqueDetailSheet(technique: technique, manager: manager)
        }
    }
}

struct TheoryLessonSheet: View {
    @Environment(\.dismiss) private var dismiss
    let lesson: CoachMessage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let lesson = lesson {
                        Text(lesson.context ?? "Music Theory")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(lesson.message)
                            .font(.body)

                        Spacer()
                    }
                }
                .padding()
            }
            .navigationTitle("Theory Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TechniqueDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let technique: CommonTechniques
    let manager: PracticeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let suggestion = manager.getTechniqueSuggestion(
                        for: technique.difficultyType
                    )

                    Text(suggestion.message)
                        .font(.body)

                    if let context = suggestion.context {
                        Text(context)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(technique.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum CommonTechniques: String, CaseIterable {
    case chordTransitions = "Chord Transitions"
    case barreChords = "Barre Chords"
    case strummingPatterns = "Strumming Patterns"
    case fingerPicking = "Finger Picking"
    case rhythmTiming = "Rhythm & Timing"

    var displayName: String { rawValue }

    var difficultyType: PracticeDifficulty.DifficultyType {
        switch self {
        case .chordTransitions: return .chordTransition
        case .barreChords: return .barreChord
        case .strummingPatterns: return .strummingPattern
        case .fingerPicking: return .fingerPicking
        case .rhythmTiming: return .rhythmTiming
        }
    }
}

extension TheoryTopic {
    var displayName: String {
        switch self {
        case .chordConstruction: return "Chord Construction"
        case .scales: return "Scales"
        case .keys: return "Keys"
        case .progressions: return "Progressions"
        case .rhythm: return "Rhythm"
        case .harmony: return "Harmony"
        }
    }
}
