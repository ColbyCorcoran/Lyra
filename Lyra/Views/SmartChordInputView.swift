//
//  SmartChordInputView.swift
//  Lyra
//
//  Smart chord input with AI-powered autocomplete and suggestions
//  Part of Phase 7.2: Chord Analysis Intelligence
//

import SwiftUI

struct SmartChordInputView: View {

    // MARK: - Properties

    @State private var chordText: String = ""
    @State private var suggestions: [ChordSuggestion] = []
    @State private var showSuggestions: Bool = false
    @State private var showTheoryInfo: Bool = false
    @State private var selectedChordInfo: ChordTheoryInfo?

    let previousChords: [String]
    let currentKey: String?
    let onChordSelected: (String) -> Void

    @State private var suggestionEngine = ChordSuggestionEngine()
    @State private var theoryHelper = ChordTheoryHelper()

    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Input field
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)

                TextField("Enter chord...", text: $chordText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isInputFocused)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: chordText) { _, newValue in
                        updateSuggestions(for: newValue)
                    }
                    .onSubmit {
                        submitChord()
                    }

                if !chordText.isEmpty {
                    Button {
                        chordText = ""
                        suggestions = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                // Theory info button
                if !chordText.isEmpty {
                    Button {
                        showTheoryInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isInputFocused ? Color.blue : Color(.separator), lineWidth: 1)
            )

            // Suggestions dropdown
            if showSuggestions && !suggestions.isEmpty {
                suggestionsView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Theory info card
            if showTheoryInfo, !chordText.isEmpty {
                theoryInfoCard
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSuggestions)
        .animation(.easeInOut(duration: 0.2), value: showTheoryInfo)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Suggestions View

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions.prefix(5)) { suggestion in
                Button {
                    selectSuggestion(suggestion)
                } label: {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: suggestion.reason.icon)
                            .font(.caption)
                            .foregroundStyle(suggestion.reason.color)
                            .frame(width: 24)

                        // Chord
                        Text(suggestion.chord)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        // Reason
                        if let context = suggestion.context {
                            Text(context)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Confidence
                        ConfidenceBadge(confidence: suggestion.confidence)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(Color(.systemBackground))

                if suggestion.id != suggestions.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.top, 4)
    }

    // MARK: - Theory Info Card

    private var theoryInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let info = selectedChordInfo {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.chord)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(info.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        showTheoryInfo = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Notes and Formula
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(info.notes.joined(separator: " - "))
                            .font(.headline)
                    }

                    HStack {
                        Text("Formula:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(info.formula)
                            .font(.headline)
                    }
                }

                // Related Chords
                if !info.relatedChords.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Chords")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(info.relatedChords.prefix(3)) { related in
                            HStack {
                                Text(related.chord)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text("(\(related.relationship.rawValue))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    chordText = related.chord
                                    updateTheoryInfo()
                                } label: {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func updateSuggestions(for text: String) {
        guard !text.isEmpty else {
            suggestions = []
            showSuggestions = false
            return
        }

        let context = AutocompleteContext(
            partialChord: text,
            previousChords: previousChords,
            currentKey: currentKey,
            recentChords: []
        )

        suggestions = suggestionEngine.getAutocompleteSuggestions(for: context)
        showSuggestions = !suggestions.isEmpty

        // Update theory info if showing
        if showTheoryInfo {
            updateTheoryInfo()
        }
    }

    private func selectSuggestion(_ suggestion: ChordSuggestion) {
        chordText = suggestion.chord
        suggestions = []
        showSuggestions = false
        submitChord()
    }

    private func submitChord() {
        guard !chordText.isEmpty else { return }

        onChordSelected(chordText)
        suggestionEngine.addToRecentChords(chordText)

        // Reset
        chordText = ""
        suggestions = []
        showSuggestions = false
        showTheoryInfo = false
    }

    private func updateTheoryInfo() {
        guard !chordText.isEmpty else {
            selectedChordInfo = nil
            return
        }

        selectedChordInfo = theoryHelper.getChordInfo(chordText)
    }
}

// MARK: - Preview

#Preview {
    SmartChordInputView(
        previousChords: ["C", "F"],
        currentKey: "C",
        onChordSelected: { chord in
            print("Selected: \(chord)")
        }
    )
    .padding()
}
