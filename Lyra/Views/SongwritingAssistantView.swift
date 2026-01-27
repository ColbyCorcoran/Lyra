//
//  SongwritingAssistantView.swift
//  Lyra
//
//  Phase 7.14: AI Songwriting Assistance - Main UI
//  User interface for AI songwriting features
//

import SwiftUI
import SwiftData

struct SongwritingAssistantView: View {

    @StateObject private var assistant = SongwritingAssistantManager.shared
    @State private var selectedTab: AssistantTab = .home
    @State private var showingHelp = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Status Bar
                statusBar

                // Main Content
                TabView(selection: $selectedTab) {
                    HomeTab()
                        .tag(AssistantTab.home)

                    ChordProgressionTab()
                        .tag(AssistantTab.chords)

                    LyricsTab()
                        .tag(AssistantTab.lyrics)

                    MelodyTab()
                        .tag(AssistantTab.melody)

                    StructureTab()
                        .tag(AssistantTab.structure)

                    CollaborationTab()
                        .tag(AssistantTab.collaborate)
                }
                .tabViewStyle(.automatic)
            }
            .navigationTitle("Songwriting Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
        }
    }

    private var statusBar: some View {
        HStack {
            Image(systemName: assistant.isEnabled ? "wand.and.stars" : "wand.and.stars.slash")
                .foregroundColor(assistant.isEnabled ? .blue : .gray)

            Text(assistant.isEnabled ? "AI Assistant Active" : "AI Assistant Paused")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Toggle("", isOn: $assistant.isEnabled)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
}

// MARK: - Home Tab

struct HomeTab: View {
    @State private var genre = "Pop"
    @State private var key = "C"
    @State private var mood = "Happy"
    @State private var theme = "Love"
    @State private var generatedStarter: SongStarter?
    @State private var isGenerating = false

    let genres = ["Pop", "Rock", "Folk", "Jazz", "Country", "Worship", "Blues"]
    let keys = ["C", "D", "E", "F", "G", "A", "B", "Db", "Eb", "Gb", "Ab", "Bb"]
    let moods = ["Happy", "Sad", "Energetic", "Calm", "Romantic", "Hopeful"]
    let themes = ["Love", "Hope", "Loss", "Joy", "Faith", "Journey", "Nature"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Quick Start Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Start")
                        .font(.headline)

                    Text("Generate a complete song starter with AI assistance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Picker("Genre", selection: $genre) {
                            ForEach(genres, id: \.self) { Text($0) }
                        }

                        Picker("Key", selection: $key) {
                            ForEach(keys, id: \.self) { Text($0) }
                        }
                    }

                    HStack {
                        Picker("Mood", selection: $mood) {
                            ForEach(moods, id: \.self) { Text($0) }
                        }

                        Picker("Theme", selection: $theme) {
                            ForEach(themes, id: \.self) { Text($0) }
                        }
                    }

                    Button(action: generateStarter) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "wand.and.stars")
                                Text("Generate Song Starter")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isGenerating)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Generated Content
                if let starter = generatedStarter {
                    GeneratedStarterView(starter: starter)
                }

                // Quick Features
                QuickFeaturesGrid()
            }
            .padding()
        }
    }

    private func generateStarter() {
        isGenerating = true

        Task {
            let starter = SongwritingAssistantManager.shared.generateSongStarter(
                genre: genre,
                key: key,
                mood: mood,
                theme: theme
            )

            await MainActor.run {
                generatedStarter = starter
                isGenerating = false
            }
        }
    }
}

// MARK: - Generated Starter View

struct GeneratedStarterView: View {
    let starter: SongStarter

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generated Song Starter")
                .font(.headline)

            // Chord Progression
            VStack(alignment: .leading, spacing: 8) {
                Text("Chord Progression")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack {
                    ForEach(starter.chordProgression.chords, id: \.self) { chord in
                        Text(chord)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }

            // Structure
            VStack(alignment: .leading, spacing: 8) {
                Text("Structure")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(starter.structure.sections.joined(separator: " → "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Lyric Ideas
            VStack(alignment: .leading, spacing: 8) {
                Text("Lyric Ideas")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(starter.lyricIdeas.prefix(3)) { phrase in
                    Text("• \(phrase.phrase)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Tempo
            Text("Suggested Tempo: \(starter.tempo) BPM")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Quick Features Grid

struct QuickFeaturesGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FeatureCard(icon: "music.note.list", title: "Chord Progressions", color: .blue)
                FeatureCard(icon: "text.bubble", title: "Lyrics", color: .green)
                FeatureCard(icon: "music.note", title: "Melody", color: .orange)
                FeatureCard(icon: "square.grid.2x2", title: "Structure", color: .purple)
                FeatureCard(icon: "person.2", title: "Collaborate", color: .pink)
                FeatureCard(icon: "wand.and.stars", title: "Style Transfer", color: .indigo)
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Chord Progression Tab

struct ChordProgressionTab: View {
    @State private var key = "C"
    @State private var genre = "Pop"
    @State private var generatedProgression: GeneratedProgression?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Chord Progression Generator")
                    .font(.headline)

                HStack {
                    Picker("Key", selection: $key) {
                        ForEach(["C", "D", "E", "F", "G", "A", "B"], id: \.self) { Text($0) }
                    }

                    Picker("Genre", selection: $genre) {
                        ForEach(["Pop", "Rock", "Jazz", "Folk"], id: \.self) { Text($0) }
                    }
                }

                Button("Generate Progression") {
                    generateProgression()
                }
                .buttonStyle(.borderedProminent)

                if let progression = generatedProgression {
                    ProgressionView(progression: progression)
                }
            }
            .padding()
        }
    }

    private func generateProgression() {
        generatedProgression = ChordProgressionEngine.shared.generateProgression(
            in: key,
            style: genre,
            length: 4
        )
    }
}

struct ProgressionView: View {
    let progression: GeneratedProgression

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(progression.chords.enumerated()), id: \.offset) { index, chord in
                HStack {
                    Text(progression.romanNumerals[index])
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40)

                    Text(chord)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Lyrics Tab

struct LyricsTab: View {
    @State private var searchWord = ""
    @State private var rhymes: [RhymeSuggestion] = []

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter a word to find rhymes", text: $searchWord)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button("Find Rhymes") {
                findRhymes()
            }
            .buttonStyle(.borderedProminent)

            List(rhymes) { rhyme in
                VStack(alignment: .leading) {
                    Text(rhyme.word)
                        .font(.headline)
                    Text(rhyme.rhymeType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func findRhymes() {
        rhymes = LyricSuggestionEngine.shared.suggestRhymes(for: searchWord, count: 10)
    }
}

// MARK: - Melody Tab

struct MelodyTab: View {
    @State private var chord = "C"
    @State private var key = "C"
    @State private var melodyHint: MelodyHint?

    var body: some View {
        VStack(spacing: 20) {
            Text("Melody Generator")
                .font(.headline)

            HStack {
                Picker("Chord", selection: $chord) {
                    ForEach(["C", "Dm", "Em", "F", "G", "Am"], id: \.self) { Text($0) }
                }

                Picker("Key", selection: $key) {
                    ForEach(["C", "D", "E", "F", "G", "A"], id: \.self) { Text($0) }
                }
            }
            .padding()

            Button("Generate Melody") {
                generateMelody()
            }
            .buttonStyle(.borderedProminent)

            if let hint = melodyHint {
                MelodyHintView(hint: hint)
            }

            Spacer()
        }
        .padding()
    }

    private func generateMelody() {
        melodyHint = MelodyHintEngine.shared.suggestMelody(
            for: chord,
            in: key,
            style: .stepwise,
            length: 8
        )
    }
}

struct MelodyHintView: View {
    let hint: MelodyHint

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated Melody")
                .font(.headline)

            Text(hint.notes.joined(separator: " - "))
                .font(.body)

            Text("Singability: \(Int(hint.singabilityScore * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Contour: \(hint.contour)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Structure Tab

struct StructureTab: View {
    @State private var genre = "Pop"
    @State private var structure: SongStructureTemplate?

    var body: some View {
        VStack(spacing: 20) {
            Picker("Genre", selection: $genre) {
                ForEach(["Pop", "Rock", "Folk", "Worship"], id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            Button("Suggest Structure") {
                suggestStructure()
            }
            .buttonStyle(.borderedProminent)

            if let template = structure {
                StructureTemplateView(template: template)
            }

            Spacer()
        }
        .padding()
    }

    private func suggestStructure() {
        structure = SongStructureEngine.shared.suggestStructure(for: genre)
    }
}

struct StructureTemplateView: View {
    let template: SongStructureTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(template.name)
                .font(.headline)

            ForEach(Array(template.sections.enumerated()), id: \.offset) { index, section in
                HStack {
                    Text(section)
                    Spacer()
                    Text("\(template.sectionLengths[index]) bars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Total: \(template.totalBars) bars (~\(template.estimatedDuration))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Collaboration Tab

struct CollaborationTab: View {
    var body: some View {
        VStack {
            Text("Collaboration Features")
                .font(.headline)

            Text("Start a co-writing session with AI")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Help View

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Getting Started") {
                    Text("The AI Songwriting Assistant helps you create songs with intelligent suggestions for chords, lyrics, melody, and structure.")
                }

                Section("Features") {
                    ForEach(AssistantFeature.allCases, id: \.self) { feature in
                        NavigationLink(feature.rawValue) {
                            FeatureHelpDetailView(feature: feature)
                        }
                    }
                }
            }
            .navigationTitle("Help")
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

struct FeatureHelpDetailView: View {
    let feature: AssistantFeature

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let help = SongwritingAssistantManager.shared.getFeatureHelp(for: feature)

                Text(help.description)
                    .font(.body)

                Text("Capabilities")
                    .font(.headline)

                ForEach(help.capabilities, id: \.self) { capability in
                    Text("• \(capability)")
                }

                Text("Examples")
                    .font(.headline)

                ForEach(help.examples, id: \.self) { example in
                    Text("• \(example)")
                        .italic()
                }
            }
            .padding()
        }
        .navigationTitle(feature.rawValue)
    }
}

// MARK: - Supporting Types

enum AssistantTab: String, CaseIterable {
    case home = "Home"
    case chords = "Chords"
    case lyrics = "Lyrics"
    case melody = "Melody"
    case structure = "Structure"
    case collaborate = "Collaborate"
}

// MARK: - Preview

#Preview {
    SongwritingAssistantView()
}
