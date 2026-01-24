//
//  ReharmonizationEngine.swift
//  Lyra
//
//  Engine for generating alternative chord progressions (reharmonization)
//  Part of Phase 7.2: Chord Analysis Intelligence
//

import Foundation

/// Generates alternative chord progressions and reharmonizations
class ReharmonizationEngine {

    // MARK: - Properties

    private let theoryEngine: MusicTheoryEngine
    private let analyzer: ProgressionAnalyzer

    // MARK: - Initialization

    init() {
        self.theoryEngine = MusicTheoryEngine()
        self.analyzer = ProgressionAnalyzer()
    }

    // MARK: - Reharmonization

    /// Generate reharmonization alternatives for a progression
    func reharmonize(_ chords: [String], style: ReharmonizationStyle = .balanced) -> [ProgressionVariation] {
        var variations: [ProgressionVariation] = []

        switch style {
        case .simpler:
            variations.append(contentsOf: generateSimpler(chords))

        case .jazzier:
            variations.append(contentsOf: generateJazzier(chords))

        case .colorful:
            variations.append(contentsOf: generateColorful(chords))

        case .balanced:
            // Mix of all styles
            variations.append(contentsOf: generateSimpler(chords))
            variations.append(contentsOf: generateJazzier(chords))
            variations.append(contentsOf: generateColorful(chords))
        }

        return variations
    }

    // MARK: - Simplification

    /// Generate simpler versions of the progression
    private func generateSimpler(_ chords: [String]) -> [ProgressionVariation] {
        var variations: [ProgressionVariation] = []

        // Remove all extensions - basic triads only
        let basicTriads = chords.map { simplifyToTriad($0) }
        if basicTriads != chords {
            variations.append(ProgressionVariation(
                chords: basicTriads,
                variationType: .simpler,
                description: "Basic triads only - easiest to play",
                difficulty: .beginner
            ))
        }

        // Remove passing chords
        let withoutPassing = removePassingChords(chords)
        if withoutPassing.count < chords.count {
            variations.append(ProgressionVariation(
                chords: withoutPassing,
                variationType: .simpler,
                description: "Simplified - removed passing chords",
                difficulty: .beginner
            ))
        }

        // Power chords for rock
        if chords.count <= 6 {
            let powerChords = chords.map { toPowerChord($0) }
            variations.append(ProgressionVariation(
                chords: powerChords,
                variationType: .simpler,
                description: "Power chords - great for rock/punk",
                difficulty: .beginner
            ))
        }

        return variations
    }

    // MARK: - Jazz Reharmonization

    /// Generate jazzier versions with substitutions
    private func generateJazzier(_ chords: [String]) -> [ProgressionVariation] {
        var variations: [ProgressionVariation] = []

        // Add ii-V substitutions
        let withTwoFives = addTwoFiveSubstitutions(chords)
        if withTwoFives.count > chords.count {
            variations.append(ProgressionVariation(
                chords: withTwoFives,
                variationType: .jazzReharmonization,
                description: "Add ii-V progressions before target chords",
                difficulty: .advanced
            ))
        }

        // Tritone substitutions on dominant chords
        let withTritone = applyTritoneSubstitutions(chords)
        if withTritone != chords {
            variations.append(ProgressionVariation(
                chords: withTritone,
                variationType: .jazzReharmonization,
                description: "Tritone substitution on dominant chords",
                difficulty: .advanced
            ))
        }

        // Add secondary dominants
        let withSecondaries = addSecondaryDominants(chords)
        if withSecondaries.count > chords.count {
            variations.append(ProgressionVariation(
                chords: withSecondaries,
                variationType: .jazzReharmonization,
                description: "Add secondary dominant chords",
                difficulty: .advanced
            ))
        }

        // Extended chords (9ths, 11ths, 13ths)
        let extended = addExtensions(chords)
        if extended != chords {
            variations.append(ProgressionVariation(
                chords: extended,
                variationType: .extensions,
                description: "Add 9th, 11th, and 13th extensions",
                difficulty: .advanced
            ))
        }

        return variations
    }

    // MARK: - Colorful Reharmonization

    /// Generate more colorful/interesting versions
    private func generateColorful(_ chords: [String]) -> [ProgressionVariation] {
        var variations: [ProgressionVariation] = []

        // Add 7ths and maj7s
        let with7ths = chords.map { add7th($0) }
        if with7ths != chords {
            variations.append(ProgressionVariation(
                chords: with7ths,
                variationType: .extensions,
                description: "Add 7th chords for richer harmony",
                difficulty: .intermediate
            ))
        }

        // Suspend chords (sus2, sus4)
        let suspended = addSuspensions(chords)
        if suspended != chords {
            variations.append(ProgressionVariation(
                chords: suspended,
                variationType: .substitution,
                description: "Add suspended chords for tension",
                difficulty: .intermediate
            ))
        }

        // Add6 and add9 chords
        let addedTone = addToneChords(chords)
        if addedTone != chords {
            variations.append(ProgressionVariation(
                chords: addedTone,
                variationType: .extensions,
                description: "Add6 and add9 chords",
                difficulty: .intermediate
            ))
        }

        // Slash chords (inversions)
        let withInversions = addInversions(chords)
        if withInversions != chords {
            variations.append(ProgressionVariation(
                chords: withInversions,
                variationType: .inversion,
                description: "Use inversions for smoother bass movement",
                difficulty: .intermediate
            ))
        }

        return variations
    }

    // MARK: - Helper Methods - Simplification

    private func simplifyToTriad(_ chord: String) -> String {
        let root = theoryEngine.extractChordRoot(chord)
        let quality = theoryEngine.getChordQuality(chord)

        switch quality {
        case .minor, .minor7:
            return "\(root)m"
        case .diminished:
            return "\(root)dim"
        case .augmented:
            return "\(root)aug"
        default:
            return root // Major triad
        }
    }

    private func removePassingChords(_ chords: [String]) -> [String] {
        // Very simplified - in real implementation, use harmonic analysis
        // For now, just remove every other chord if progression is long
        if chords.count > 6 {
            return chords.enumerated().compactMap { index, chord in
                index % 2 == 0 ? chord : nil
            }
        }
        return chords
    }

    private func toPowerChord(_ chord: String) -> String {
        let root = theoryEngine.extractChordRoot(chord)
        return "\(root)5" // Power chord notation
    }

    // MARK: - Helper Methods - Jazz

    private func addTwoFiveSubstitutions(_ chords: [String]) -> [String] {
        var result: [String] = []

        for (index, chord) in chords.enumerated() {
            // Before each chord, consider adding ii-V
            if index > 0 && chords.count <= 4 {
                let target = chord
                let targetRoot = theoryEngine.extractChordRoot(target)

                // Calculate ii and V relative to target
                let two = theoryEngine.transposeChord(targetRoot, by: 2)
                let five = theoryEngine.transposeChord(targetRoot, by: 7)

                // Add ii-V before target chord
                result.append("\(two)m7")
                result.append("\(five)7")
            }

            result.append(chord)
        }

        return result
    }

    private func applyTritoneSubstitutions(_ chords: [String]) -> [String] {
        return chords.map { chord in
            let quality = theoryEngine.getChordQuality(chord)

            // Only substitute dominant 7ths
            if quality == .dominant7 {
                // Tritone sub: up 6 semitones
                return theoryEngine.transposeChord(chord, by: 6)
            }

            return chord
        }
    }

    private func addSecondaryDominants(_ chords: [String]) -> [String] {
        var result: [String] = []

        for (index, chord) in chords.enumerated() {
            // Add secondary dominant before non-tonic chords
            if index > 0 && chords.count <= 4 {
                let targetRoot = theoryEngine.extractChordRoot(chord)
                let secondaryDominant = theoryEngine.transposeChord(targetRoot, by: 7)

                result.append("\(secondaryDominant)7")
            }

            result.append(chord)
        }

        return result
    }

    private func addExtensions(_ chords: [String]) -> [String] {
        return chords.map { chord in
            let quality = theoryEngine.getChordQuality(chord)
            let root = theoryEngine.extractChordRoot(chord)

            switch quality {
            case .dominant7:
                // Add 9th to dominant 7ths
                return "\(root)9"
            case .major7:
                // Add 9th to major 7ths
                return "\(root)maj9"
            case .minor7:
                // Add 9th or 11th to minor 7ths
                return "\(root)m11"
            default:
                return chord
            }
        }
    }

    // MARK: - Helper Methods - Colorful

    private func add7th(_ chord: String) -> String {
        let quality = theoryEngine.getChordQuality(chord)
        let root = theoryEngine.extractChordRoot(chord)

        // Already has 7th
        if quality == .dominant7 || quality == .major7 || quality == .minor7 {
            return chord
        }

        // Add appropriate 7th
        switch quality {
        case .major:
            return "\(root)maj7"
        case .minor:
            return "\(root)m7"
        default:
            return chord
        }
    }

    private func addSuspensions(_ chords: [String]) -> [String] {
        return chords.map { chord in
            let quality = theoryEngine.getChordQuality(chord)
            let root = theoryEngine.extractChordRoot(chord)

            // Add sus4 to major chords for color
            if quality == .major && arc4random_uniform(2) == 0 {
                return "\(root)sus4"
            }

            return chord
        }
    }

    private func addToneChords(_ chords: [String]) -> [String] {
        return chords.map { chord in
            let quality = theoryEngine.getChordQuality(chord)
            let root = theoryEngine.extractChordRoot(chord)

            if quality == .major {
                // Add6 or add9
                return arc4random_uniform(2) == 0 ? "\(root)add9" : "\(root)6"
            }

            return chord
        }
    }

    private func addInversions(_ chords: [String]) -> [String] {
        var result: [String] = []

        for (index, chord) in chords.enumerated() {
            let root = theoryEngine.extractChordRoot(chord)

            // Add slash chord for smoother bass movement
            if index > 0 {
                let previousChord = result[index - 1]
                let previousRoot = theoryEngine.extractChordRoot(previousChord)

                // Create slash chord with previous bass note
                result.append("\(chord)/\(previousRoot)")
            } else {
                result.append(chord)
            }
        }

        return result
    }
}

// MARK: - Reharmonization Style

enum ReharmonizationStyle {
    case simpler      // Easier to play
    case jazzier      // Jazz substitutions
    case colorful     // Add extensions and color
    case balanced     // Mix of all
}
