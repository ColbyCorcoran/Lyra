//
//  StyleTransferEngine.swift
//  Lyra
//
//  Phase 7.14: AI Songwriting Assistance - Style Transfer Intelligence
//  On-device genre and style transformation
//

import Foundation

/// Engine for transforming songs between genres and styles
/// Uses rule-based music theory transformations (100% on-device)
@MainActor
class StyleTransferEngine {

    // MARK: - Shared Instance
    static let shared = StyleTransferEngine()

    // MARK: - Genre Characteristics

    private let genreCharacteristics: [String: GenreProfile] = [
        "pop": GenreProfile(
            typicalTempo: 120,
            chordComplexity: .simple,
            rhythmFeel: .straight,
            commonProgressions: [[0, 5, 3, 4], [0, 3, 4, 0]],
            instrumentationStyle: "Clean, produced, emphasis on vocals",
            lyricThemes: ["love", "relationships", "personal growth"]
        ),
        "rock": GenreProfile(
            typicalTempo: 130,
            chordComplexity: .moderate,
            rhythmFeel: .driving,
            commonProgressions: [[0, 3, 4, 0], [0, 6, 3, 4]],
            instrumentationStyle: "Guitar-driven, powerful drums",
            lyricThemes: ["rebellion", "freedom", "authenticity"]
        ),
        "jazz": GenreProfile(
            typicalTempo: 100,
            chordComplexity: .complex,
            rhythmFeel: .swing,
            commonProgressions: [[0, 5, 1, 4], [1, 4, 0, 0]],
            instrumentationStyle: "Sophisticated harmony, improvisation",
            lyricThemes: ["romance", "city life", "nostalgia"]
        ),
        "folk": GenreProfile(
            typicalTempo: 90,
            chordComplexity: .simple,
            rhythmFeel: .relaxed,
            commonProgressions: [[0, 0, 4, 4], [0, 3, 0, 4]],
            instrumentationStyle: "Acoustic, intimate, storytelling",
            lyricThemes: ["nature", "tradition", "storytelling"]
        ),
        "country": GenreProfile(
            typicalTempo: 110,
            chordComplexity: .simple,
            rhythmFeel: .shuffle,
            commonProgressions: [[0, 3, 0, 4], [0, 0, 3, 4]],
            instrumentationStyle: "Twangy guitar, steel guitar, fiddle",
            lyricThemes: ["rural life", "heartbreak", "family"]
        ),
        "worship": GenreProfile(
            typicalTempo: 75,
            chordComplexity: .moderate,
            rhythmFeel: .flowing,
            commonProgressions: [[0, 5, 3, 4], [5, 3, 0, 4]],
            instrumentationStyle: "Anthemic, layered, building",
            lyricThemes: ["faith", "praise", "hope"]
        ),
        "blues": GenreProfile(
            typicalTempo: 80,
            chordComplexity: .moderate,
            rhythmFeel: .shuffle,
            commonProgressions: [[0, 0, 0, 0, 3, 3, 0, 0, 4, 3, 0, 4]],
            instrumentationStyle: "Guitar-centric, expressive, soulful",
            lyricThemes: ["hardship", "emotion", "life struggles"]
        )
    ]

    // MARK: - Style Transfer

    /// Transform song to different genre
    func transformToGenre(
        currentChords: [String],
        currentKey: String,
        targetGenre: String,
        intensity: TransformIntensity = .moderate
    ) -> StyleTransform {

        let targetProfile = genreCharacteristics[targetGenre.lowercased()] ?? genreCharacteristics["pop"]!

        var transformedChords = currentChords
        var appliedChanges: [String] = []

        // 1. Reharmonize based on genre
        if intensity == .moderate || intensity == .dramatic {
            transformedChords = reharmonizeForGenre(
                chords: currentChords,
                key: currentKey,
                genre: targetGenre
            )
            appliedChanges.append("Reharmonized to match \(targetGenre) chord patterns")
        }

        // 2. Adjust chord complexity
        if intensity == .dramatic {
            transformedChords = adjustChordComplexity(
                chords: transformedChords,
                targetComplexity: targetProfile.chordComplexity
            )
            appliedChanges.append("Adjusted chord complexity to \(targetProfile.chordComplexity.rawValue)")
        }

        // 3. Suggest tempo change
        let tempoSuggestion = targetProfile.typicalTempo
        appliedChanges.append("Suggested tempo: \(tempoSuggestion) BPM")

        // 4. Rhythm feel suggestion
        appliedChanges.append("Apply \(targetProfile.rhythmFeel.rawValue) rhythm feel")

        return StyleTransform(
            originalChords: currentChords,
            transformedChords: transformedChords,
            targetGenre: targetGenre,
            suggestedTempo: tempoSuggestion,
            rhythmFeel: targetProfile.rhythmFeel,
            appliedChanges: appliedChanges,
            intensity: intensity,
            arrangementSuggestions: generateArrangementSuggestions(for: targetProfile)
        )
    }

    /// Transform in the style of a specific artist/mood
    func transformToStyle(
        currentContent: String,
        targetStyle: String
    ) -> StyleTransform {

        // Map common artist styles to genre profiles
        let styleMapping: [String: String] = [
            "beatles": "rock",
            "taylor swift": "pop",
            "johnny cash": "country",
            "ella fitzgerald": "jazz",
            "bob dylan": "folk"
        ]

        let mappedGenre = styleMapping[targetStyle.lowercased()] ?? "pop"

        // Use genre transform as base, then apply style-specific tweaks
        // For now, delegate to genre transform
        // In production, add style-specific nuances

        let dummyChords = ["C", "Am", "F", "G"]

        return transformToGenre(
            currentChords: dummyChords,
            currentKey: "C",
            targetGenre: mappedGenre,
            intensity: .moderate
        )
    }

    /// Reharmonize existing progression
    func reharmonize(
        chords: [String],
        key: String,
        approach: ReharmonizationApproach
    ) -> ReharmonizationResult {

        var reharmonized: [String] = []
        var explanations: [String] = []

        switch approach {
        case .jazzSubstitutions:
            // Add 7ths, substitute dominants
            for chord in chords {
                let jazzified = addJazzExtensions(chord)
                reharmonized.append(jazzified)
                explanations.append("Added jazz extensions to \(chord)")
            }

        case .modalInterchange:
            // Borrow from parallel minor/major
            reharmonized = chords.map { chord in
                if Double.random(in: 0...1) > 0.7 {
                    return borrowFromParallel(chord, key: key)
                }
                return chord
            }
            explanations.append("Applied modal interchange (borrowing from parallel key)")

        case .secondaryDominants:
            // Add V/V, V/vi, etc.
            for chord in chords {
                reharmonized.append(chord)
                if Double.random(in: 0...1) > 0.6 {
                    let secondary = createSecondaryDominant(for: chord, in: key)
                    reharmonized.insert(secondary, at: reharmonized.count - 1)
                    explanations.append("Added secondary dominant before \(chord)")
                }
            }

        case .tritoneSubstitution:
            // Substitute dominants with tritone
            reharmonized = chords.map { chord in
                if chord.contains("7") && Double.random(in: 0...1) > 0.5 {
                    return tritoneSubstitute(chord)
                }
                return chord
            }
            explanations.append("Applied tritone substitutions on dominant chords")
        }

        return ReharmonizationResult(
            originalChords: chords,
            reharmonizedChords: reharmonized,
            approach: approach,
            explanations: explanations
        )
    }

    /// Suggest arrangement ideas
    func suggestArrangement(for genre: String) -> [ArrangementIdea] {
        let profile = genreCharacteristics[genre.lowercased()] ?? genreCharacteristics["pop"]!

        var ideas: [ArrangementIdea] = []

        ideas.append(ArrangementIdea(
            category: "Instrumentation",
            suggestion: profile.instrumentationStyle,
            priority: .high
        ))

        ideas.append(ArrangementIdea(
            category: "Tempo",
            suggestion: "Set tempo to \(profile.typicalTempo) BPM",
            priority: .medium
        ))

        ideas.append(ArrangementIdea(
            category: "Rhythm",
            suggestion: "Apply \(profile.rhythmFeel.rawValue) feel",
            priority: .high
        ))

        // Genre-specific ideas
        switch genre.lowercased() {
        case "rock":
            ideas.append(ArrangementIdea(
                category: "Guitar",
                suggestion: "Add power chord rhythm guitar and lead guitar solo",
                priority: .high
            ))

        case "jazz":
            ideas.append(ArrangementIdea(
                category: "Piano",
                suggestion: "Piano comping with walking bass line",
                priority: .high
            ))

        case "folk":
            ideas.append(ArrangementIdea(
                category: "Acoustic",
                suggestion: "Fingerstyle acoustic guitar with minimal percussion",
                priority: .high
            ))

        case "worship":
            ideas.append(ArrangementIdea(
                category: "Dynamics",
                suggestion: "Build from soft verses to powerful chorus",
                priority: .high
            ))

        default:
            break
        }

        return ideas
    }

    // MARK: - Helper Methods

    private func reharmonizeForGenre(chords: [String], key: String, genre: String) -> [String] {
        let profile = genreCharacteristics[genre.lowercased()] ?? genreCharacteristics["pop"]!

        // For simplicity, use one of the common progressions
        if let progression = profile.commonProgressions.first {
            return progression.map { degree in
                buildChordFromDegree(degree, key: key)
            }
        }

        return chords
    }

    private func adjustChordComplexity(chords: [String], targetComplexity: ChordComplexity) -> [String] {
        return chords.map { chord in
            switch targetComplexity {
            case .simple:
                return simplifyChord(chord)
            case .moderate:
                return chord
            case .complex:
                return addJazzExtensions(chord)
            }
        }
    }

    private func simplifyChord(_ chord: String) -> String {
        // Remove extensions, keep basic triad
        let root = String(chord.prefix(chord.contains("#") || chord.contains("b") ? 2 : 1))
        let isMinor = chord.contains("m") && !chord.contains("maj")

        return root + (isMinor ? "m" : "")
    }

    private func addJazzExtensions(_ chord: String) -> String {
        // Add 7th if not present
        if !chord.contains("7") {
            return chord + "7"
        }
        return chord
    }

    private func borrowFromParallel(_ chord: String, key: String) -> String {
        // Simplified modal interchange
        // In production, use proper parallel key borrowing
        return chord + "m"
    }

    private func createSecondaryDominant(for chord: String, in key: String) -> String {
        // Simplified secondary dominant
        return "D7"
    }

    private func tritoneSubstitute(_ chord: String) -> String {
        // Simplified tritone substitution
        let root = String(chord.prefix(1))
        return root + "b7"
    }

    private func buildChordFromDegree(_ degree: Int, key: String) -> String {
        let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let majorScaleIntervals = [0, 2, 4, 5, 7, 9, 11]
        let majorScaleQualities = ["", "m", "m", "", "", "m", "dim"]

        guard let rootIndex = chromaticScale.firstIndex(of: key.uppercased()) else {
            return key
        }

        let semitones = majorScaleIntervals[min(degree, 6)]
        let chordRootIndex = (rootIndex + semitones) % 12
        let chordRoot = chromaticScale[chordRootIndex]
        let quality = majorScaleQualities[min(degree, 6)]

        return chordRoot + quality
    }

    private func generateArrangementSuggestions(for profile: GenreProfile) -> [String] {
        return [
            profile.instrumentationStyle,
            "Use \(profile.rhythmFeel.rawValue) rhythm pattern",
            "Tempo around \(profile.typicalTempo) BPM",
            "Lyrics focused on: \(profile.lyricThemes.joined(separator: ", "))"
        ]
    }
}

// MARK: - Data Models

enum ChordComplexity: String, Codable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
}

enum RhythmFeel: String, Codable {
    case straight = "Straight"
    case swing = "Swing"
    case shuffle = "Shuffle"
    case driving = "Driving"
    case relaxed = "Relaxed"
    case flowing = "Flowing"
}

enum TransformIntensity: String, Codable {
    case subtle = "Subtle"
    case moderate = "Moderate"
    case dramatic = "Dramatic"
}

enum ReharmonizationApproach: String, Codable, CaseIterable {
    case jazzSubstitutions = "Jazz Substitutions"
    case modalInterchange = "Modal Interchange"
    case secondaryDominants = "Secondary Dominants"
    case tritoneSubstitution = "Tritone Substitution"
}

struct GenreProfile: Codable {
    let typicalTempo: Int
    let chordComplexity: ChordComplexity
    let rhythmFeel: RhythmFeel
    let commonProgressions: [[Int]]
    let instrumentationStyle: String
    let lyricThemes: [String]
}

struct StyleTransform: Identifiable, Codable {
    let id: UUID = UUID()
    let originalChords: [String]
    let transformedChords: [String]
    let targetGenre: String
    let suggestedTempo: Int
    let rhythmFeel: RhythmFeel
    let appliedChanges: [String]
    let intensity: TransformIntensity
    let arrangementSuggestions: [String]
}

struct ReharmonizationResult: Identifiable, Codable {
    let id: UUID = UUID()
    let originalChords: [String]
    let reharmonizedChords: [String]
    let approach: ReharmonizationApproach
    let explanations: [String]
}

enum ArrangementPriority: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct ArrangementIdea: Identifiable, Codable {
    let id: UUID = UUID()
    let category: String
    let suggestion: String
    let priority: ArrangementPriority
}
