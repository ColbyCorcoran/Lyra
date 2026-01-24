//
//  KeyEducationView.swift
//  Lyra
//
//  Educational view explaining keys, modes, and music theory
//  Part of Phase 7.3: Key Intelligence
//

import SwiftUI

struct KeyEducationView: View {

    // MARK: - Properties

    let key: String
    let chords: [String]?
    let detectionReason: String?

    @State private var selectedTab: EducationTab = .overview
    @State private var theoryEngine = MusicTheoryEngine()

    @Environment(\.dismiss) private var dismiss

    // MARK: - Education Tabs

    enum EducationTab: String, CaseIterable {
        case overview = "Overview"
        case signature = "Signature"
        case circle = "Circle of 5ths"
        case modes = "Modes"
        case progressions = "Progressions"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Education Tab", selection: $selectedTab) {
                    ForEach(EducationTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .overview:
                            overviewSection
                        case .signature:
                            signatureSection
                        case .circle:
                            circleOfFifthsSection
                        case .modes:
                            modesSection
                        case .progressions:
                            progressionsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Key: \(key)")
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

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Key Detection Explanation
            if let reason = detectionReason {
                infoCard(
                    title: "Why \(key)?",
                    icon: "lightbulb.fill",
                    color: .orange
                ) {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Relative Major/Minor
            relativeKeyCard

            // Scale Notes
            scaleNotesCard

            // Key Characteristics
            characteristicsCard
        }
    }

    private var relativeKeyCard: some View {
        let isMinor = key.contains("m") && !key.contains("maj")
        let relativeKey = theoryEngine.getRelativeKey(key)

        return infoCard(
            title: isMinor ? "Relative Major" : "Relative Minor",
            icon: "arrow.left.arrow.right",
            color: .blue
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(key)
                        .font(.title3)
                        .fontWeight(.bold)

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)

                    Text(relativeKey ?? "Unknown")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }

                Text("These keys share the same notes but have different tonal centers. They're perfect for key changes within a song.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var scaleNotesCard: some View {
        let scale = getScale()

        return infoCard(
            title: "Scale Notes",
            icon: "music.note.list",
            color: .green
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Scale degree labels
                HStack(spacing: 0) {
                    ForEach(0..<scale.count, id: \.self) { index in
                        VStack(spacing: 4) {
                            Text(scale[index])
                                .font(.headline)
                                .fontWeight(.bold)

                            Text(scaleDegreeNames[index])
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Divider()

                Text("These are the seven notes that make up the \(key) scale. Songs in this key typically use these notes and chords built from them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var characteristicsCard: some View {
        let characteristics = getKeyCharacteristics()

        return infoCard(
            title: "Key Characteristics",
            icon: "star.fill",
            color: .purple
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(characteristics, id: \.title) { char in
                    HStack(alignment: .top) {
                        Image(systemName: char.icon)
                            .foregroundStyle(.purple)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(char.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(char.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Signature Section

    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            let signature = getKeySignature()

            infoCard(
                title: "Key Signature",
                icon: "number",
                color: .indigo
            ) {
                VStack(spacing: 16) {
                    // Sharps or Flats
                    if signature.count > 0 {
                        VStack(spacing: 8) {
                            Text(signature.contains("♯") ? "Sharps (♯)" : "Flats (♭)")
                                .font(.headline)

                            HStack(spacing: 16) {
                                ForEach(Array(signature.enumerated()), id: \.offset) { _, note in
                                    Text(note)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.indigo)
                                }
                            }

                            Text("\(signature.count) \(signature.contains("♯") ? "sharp" : "flat")\(signature.count != 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("No sharps or flats")
                                .font(.headline)

                            Text("Natural key (C major / A minor)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    Text("The key signature tells you which notes are sharp (♯) or flat (♭) throughout the piece. These alterations are applied automatically without writing them each time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Enharmonic equivalents
            if let enharmonic = getEnharmonicEquivalent() {
                infoCard(
                    title: "Enharmonic Equivalent",
                    icon: "equal",
                    color: .orange
                ) {
                    VStack(spacing: 8) {
                        HStack {
                            Text(key)
                                .font(.title3)
                                .fontWeight(.bold)

                            Image(systemName: "equal")
                                .foregroundStyle(.secondary)

                            Text(enharmonic)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }

                        Text("These keys sound identical but are written differently. Choosing between them depends on musical context and readability.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Circle of Fifths Section

    private var circleOfFifthsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            infoCard(
                title: "Circle of Fifths",
                icon: "circle.hexagongrid.fill",
                color: .teal
            ) {
                VStack(spacing: 16) {
                    // Simplified circle visualization
                    circleOfFifthsVisualization

                    Divider()

                    Text("The Circle of Fifths shows the relationship between keys. Keys next to each other share many notes, making modulation (key changes) sound smooth.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Related keys
            relatedKeysCard
        }
    }

    private var circleOfFifthsVisualization: some View {
        let majorKeys = ["C", "G", "D", "A", "E", "B", "F♯", "C♯", "A♭", "E♭", "B♭", "F"]
        let currentIndex = majorKeys.firstIndex(where: { $0 == key.replacingOccurrences(of: "m", with: "") }) ?? 0

        return VStack(spacing: 12) {
            // Top (12 o'clock - C)
            keyCircleButton(majorKeys[0], isCurrent: currentIndex == 0)

            HStack(spacing: 8) {
                // Left side
                VStack(spacing: 8) {
                    keyCircleButton(majorKeys[11], isCurrent: currentIndex == 11)
                    keyCircleButton(majorKeys[10], isCurrent: currentIndex == 10)
                    keyCircleButton(majorKeys[9], isCurrent: currentIndex == 9)
                }

                Spacer()

                // Right side
                VStack(spacing: 8) {
                    keyCircleButton(majorKeys[1], isCurrent: currentIndex == 1)
                    keyCircleButton(majorKeys[2], isCurrent: currentIndex == 2)
                    keyCircleButton(majorKeys[3], isCurrent: currentIndex == 3)
                }
            }

            HStack {
                keyCircleButton(majorKeys[8], isCurrent: currentIndex == 8)
                Spacer()
                keyCircleButton(majorKeys[4], isCurrent: currentIndex == 4)
            }

            HStack(spacing: 8) {
                keyCircleButton(majorKeys[7], isCurrent: currentIndex == 7)
                keyCircleButton(majorKeys[6], isCurrent: currentIndex == 6)
                keyCircleButton(majorKeys[5], isCurrent: currentIndex == 5)
            }
        }
        .padding()
    }

    private func keyCircleButton(_ keyName: String, isCurrent: Bool) -> some View {
        Text(keyName)
            .font(.caption)
            .fontWeight(isCurrent ? .bold : .regular)
            .foregroundStyle(isCurrent ? .white : .primary)
            .frame(width: 40, height: 40)
            .background(isCurrent ? Color.teal : Color(.systemGray5))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(isCurrent ? Color.teal : Color.clear, lineWidth: 2)
            )
    }

    private var relatedKeysCard: some View {
        let related = getRelatedKeys()

        return infoCard(
            title: "Related Keys",
            icon: "link",
            color: .blue
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(related, id: \.key) { relation in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(relation.key)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(relation.relationship)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        compatibilityBadge(relation.compatibility)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Modes Section

    private var modesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            infoCard(
                title: "What are Modes?",
                icon: "questionmark.circle.fill",
                color: .purple
            ) {
                Text("Modes are scales built from the same notes as a major scale, but starting on different degrees. Each mode has a unique character and emotional quality.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(modes, id: \.name) { mode in
                modeCard(mode)
            }
        }
    }

    private func modeCard(_ mode: Mode) -> some View {
        infoCard(
            title: mode.name,
            icon: "waveform",
            color: mode.color
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text(mode.character)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let example = mode.example {
                    Divider()

                    HStack {
                        Image(systemName: "music.note")
                            .foregroundStyle(mode.color)

                        Text(example)
                            .font(.caption)
                            .italic()
                    }
                }
            }
        }
    }

    // MARK: - Progressions Section

    private var progressionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            infoCard(
                title: "Common Progressions in \(key)",
                icon: "list.bullet",
                color: .green
            ) {
                Text("Here are some common chord progressions in this key. Try using these in your songs!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(getCommonProgressions(), id: \.name) { progression in
                progressionCard(progression)
            }
        }
    }

    private func progressionCard(_ progression: KeyProgression) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(progression.name)
                    .font(.headline)

                Spacer()

                if let genre = progression.genre {
                    Text(genre)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .cornerRadius(4)
                }
            }

            // Roman numerals
            HStack(spacing: 8) {
                ForEach(progression.romanNumerals, id: \.self) { numeral in
                    Text(numeral)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }

            // Actual chords
            HStack(spacing: 8) {
                ForEach(progression.chords, id: \.self) { chord in
                    Text(chord)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .cornerRadius(6)
                }
            }

            if let example = progression.example {
                Divider()

                HStack {
                    Image(systemName: "music.note")
                        .foregroundStyle(.green)

                    Text(example)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Views

    private func infoCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            content()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    private func compatibilityBadge(_ score: Float) -> some View {
        let color: Color = score > 0.8 ? .green : score > 0.5 ? .orange : .red
        let label = score > 0.8 ? "High" : score > 0.5 ? "Medium" : "Low"

        return Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }

    // MARK: - Helper Methods

    private func getScale() -> [String] {
        // Get the root note
        let root = key.replacingOccurrences(of: "m", with: "")
            .replacingOccurrences(of: "maj", with: "")
            .replacingOccurrences(of: "7", with: "")

        let isMinor = key.contains("m") && !key.contains("maj")

        // Chromatic scale
        let chromatic = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

        guard let rootIndex = chromatic.firstIndex(of: root) else {
            return []
        }

        // Major: W-W-H-W-W-W-H (whole and half steps)
        // Minor: W-H-W-W-H-W-W
        let intervals = isMinor ? [2, 1, 2, 2, 1, 2, 2] : [2, 2, 1, 2, 2, 2, 1]

        var scale: [String] = [root]
        var currentIndex = rootIndex

        for interval in intervals.dropLast() {
            currentIndex = (currentIndex + interval) % chromatic.count
            scale.append(chromatic[currentIndex])
        }

        return scale
    }

    private let scaleDegreeNames = ["I", "II", "III", "IV", "V", "VI", "VII"]

    private func getKeySignature() -> [String] {
        let root = key.replacingOccurrences(of: "m", with: "")
            .replacingOccurrences(of: "maj", with: "")

        let signatures: [String: [String]] = [
            "C": [],
            "G": ["F♯"],
            "D": ["F♯", "C♯"],
            "A": ["F♯", "C♯", "G♯"],
            "E": ["F♯", "C♯", "G♯", "D♯"],
            "B": ["F♯", "C♯", "G♯", "D♯", "A♯"],
            "F♯": ["F♯", "C♯", "G♯", "D♯", "A♯", "E♯"],
            "F": ["B♭"],
            "B♭": ["B♭", "E♭"],
            "E♭": ["B♭", "E♭", "A♭"],
            "A♭": ["B♭", "E♭", "A♭", "D♭"],
            "D♭": ["B♭", "E♭", "A♭", "D♭", "G♭"]
        ]

        return signatures[root] ?? []
    }

    private func getEnharmonicEquivalent() -> String? {
        let root = key.replacingOccurrences(of: "m", with: "")
        let isMinor = key.contains("m")

        let equivalents: [String: String] = [
            "C♯": "D♭",
            "D♭": "C♯",
            "D♯": "E♭",
            "E♭": "D♯",
            "F♯": "G♭",
            "G♭": "F♯",
            "G♯": "A♭",
            "A♭": "G♯",
            "A♯": "B♭",
            "B♭": "A♯"
        ]

        guard let equiv = equivalents[root] else {
            return nil
        }

        return isMinor ? equiv + "m" : equiv
    }

    private func getKeyCharacteristics() -> [KeyCharacteristic] {
        let isMinor = key.contains("m") && !key.contains("maj")

        var chars: [KeyCharacteristic] = []

        // Tonality
        chars.append(KeyCharacteristic(
            icon: "music.note",
            title: isMinor ? "Minor Key" : "Major Key",
            description: isMinor ? "Typically sounds sad, dark, or introspective" : "Typically sounds happy, bright, or uplifting"
        ))

        // Diatonic chords
        let chordCount = isMinor ? "i, ii°, III, iv, v, VI, VII" : "I, ii, iii, IV, V, vi, vii°"
        chars.append(KeyCharacteristic(
            icon: "list.bullet",
            title: "Diatonic Chords",
            description: "Seven natural chords: \(chordCount)"
        ))

        // Common usage
        if !isMinor {
            chars.append(KeyCharacteristic(
                icon: "star",
                title: "Popular Usage",
                description: "Major keys are used in most pop, rock, and country music"
            ))
        } else {
            chars.append(KeyCharacteristic(
                icon: "moon.stars",
                title: "Emotional Depth",
                description: "Minor keys are often used for ballads, emotional songs, and dramatic moments"
            ))
        }

        return chars
    }

    private func getRelatedKeys() -> [RelatedKey] {
        var related: [RelatedKey] = []

        // Relative major/minor
        if let relativeKey = theoryEngine.getRelativeKey(key) {
            related.append(RelatedKey(
                key: relativeKey,
                relationship: "Relative",
                compatibility: 1.0
            ))
        }

        // Parallel major/minor
        let isMinor = key.contains("m") && !key.contains("maj")
        let root = key.replacingOccurrences(of: "m", with: "")
        let parallelKey = isMinor ? root : root + "m"

        related.append(RelatedKey(
            key: parallelKey,
            relationship: "Parallel",
            compatibility: 0.8
        ))

        // Dominant (V)
        if let dominant = theoryEngine.getDominantKey(key) {
            related.append(RelatedKey(
                key: dominant,
                relationship: "Dominant (V)",
                compatibility: 0.9
            ))
        }

        // Subdominant (IV)
        if let subdominant = theoryEngine.getSubdominantKey(key) {
            related.append(RelatedKey(
                key: subdominant,
                relationship: "Subdominant (IV)",
                compatibility: 0.9
            ))
        }

        return related
    }

    private var modes: [Mode] {
        [
            Mode(
                name: "Ionian (Major)",
                character: "Happy, bright, consonant",
                description: "The standard major scale. Most common mode in Western music.",
                example: "C major scale: C-D-E-F-G-A-B-C",
                color: .blue
            ),
            Mode(
                name: "Dorian",
                character: "Jazzy, sophisticated, minor",
                description: "Like natural minor but with a raised 6th. Common in jazz and folk.",
                example: "\"Scarborough Fair\" by Simon & Garfunkel",
                color: .purple
            ),
            Mode(
                name: "Phrygian",
                character: "Spanish, exotic, dark",
                description: "Minor scale with a flat 2nd. Has a distinctive Spanish/flamenco flavor.",
                example: "\"White Rabbit\" by Jefferson Airplane",
                color: .red
            ),
            Mode(
                name: "Lydian",
                character: "Dreamy, ethereal, bright",
                description: "Major scale with a raised 4th. Sounds mystical and floating.",
                example: "\"Flying in a Blue Dream\" by Joe Satriani",
                color: .cyan
            ),
            Mode(
                name: "Mixolydian",
                character: "Bluesy, rock, dominant",
                description: "Major scale with a flat 7th. Very common in rock, blues, and folk.",
                example: "\"Sweet Child O' Mine\" by Guns N' Roses",
                color: .orange
            ),
            Mode(
                name: "Aeolian (Natural Minor)",
                character: "Sad, dark, serious",
                description: "The natural minor scale. Used for melancholic and emotional songs.",
                example: "\"Stairway to Heaven\" by Led Zeppelin",
                color: .indigo
            ),
            Mode(
                name: "Locrian",
                character: "Dissonant, unstable, dark",
                description: "The most dissonant mode. Rarely used except for tension.",
                example: "Rarely used in popular music",
                color: .gray
            )
        ]
    }

    private func getCommonProgressions() -> [KeyProgression] {
        let isMinor = key.contains("m") && !key.contains("maj")

        if isMinor {
            return getMinorProgressions()
        } else {
            return getMajorProgressions()
        }
    }

    private func getMajorProgressions() -> [KeyProgression] {
        let root = key.replacingOccurrences(of: "m", with: "")
        let scale = getScale()

        guard scale.count == 7 else { return [] }

        return [
            KeyProgression(
                name: "I-V-vi-IV (Pop Progression)",
                romanNumerals: ["I", "V", "vi", "IV"],
                chords: [root, scale[4], scale[5] + "m", scale[3]],
                genre: "Pop/Rock",
                example: "\"Let It Be\" - The Beatles"
            ),
            KeyProgression(
                name: "I-IV-V (Classic Rock)",
                romanNumerals: ["I", "IV", "V"],
                chords: [root, scale[3], scale[4]],
                genre: "Rock",
                example: "\"La Bamba\" - Ritchie Valens"
            ),
            KeyProgression(
                name: "I-vi-IV-V (50s Progression)",
                romanNumerals: ["I", "vi", "IV", "V"],
                chords: [root, scale[5] + "m", scale[3], scale[4]],
                genre: "Doo-wop",
                example: "\"Stand By Me\" - Ben E. King"
            ),
            KeyProgression(
                name: "I-V-vi-iii-IV-I-IV-V",
                romanNumerals: ["I", "V", "vi", "iii", "IV", "I", "IV", "V"],
                chords: [root, scale[4], scale[5] + "m", scale[2] + "m", scale[3], root, scale[3], scale[4]],
                genre: "Pop",
                example: "\"Don't Stop Believin'\" - Journey"
            )
        ]
    }

    private func getMinorProgressions() -> [KeyProgression] {
        let root = key.replacingOccurrences(of: "m", with: "")
        let scale = getScale()

        guard scale.count == 7 else { return [] }

        return [
            KeyProgression(
                name: "i-VII-VI-V",
                romanNumerals: ["i", "VII", "VI", "V"],
                chords: [root + "m", scale[6], scale[5], scale[4]],
                genre: "Rock",
                example: "\"Stairway to Heaven\" - Led Zeppelin"
            ),
            KeyProgression(
                name: "i-iv-VII-VI",
                romanNumerals: ["i", "iv", "VII", "VI"],
                chords: [root + "m", scale[3] + "m", scale[6], scale[5]],
                genre: "Rock/Metal",
                example: "\"Enter Sandman\" - Metallica"
            ),
            KeyProgression(
                name: "i-VI-III-VII",
                romanNumerals: ["i", "VI", "III", "VII"],
                chords: [root + "m", scale[5], scale[2], scale[6]],
                genre: "Pop",
                example: "\"Losing My Religion\" - R.E.M."
            )
        ]
    }
}

// MARK: - Supporting Types

struct KeyCharacteristic {
    var icon: String
    var title: String
    var description: String
}

struct RelatedKey {
    var key: String
    var relationship: String
    var compatibility: Float
}

struct Mode {
    var name: String
    var character: String
    var description: String
    var example: String?
    var color: Color
}

struct KeyProgression {
    var name: String
    var romanNumerals: [String]
    var chords: [String]
    var genre: String?
    var example: String?
}

// MARK: - Preview

#Preview {
    KeyEducationView(
        key: "C",
        chords: ["C", "G", "Am", "F"],
        detectionReason: "All chords are diatonic to C major. Strong presence of tonic (C) and dominant (G) chords."
    )
}
