//
//  ProgressionAnalyzer.swift
//  Lyra
//
//  Analyzes chord progressions and provides Roman numeral analysis
//  Part of Phase 7.2: Chord Analysis Intelligence
//

import Foundation

/// Analyzes chord progressions for harmonic structure
class ProgressionAnalyzer {

    // MARK: - Properties

    private let theoryEngine: MusicTheoryEngine
    private let database: ChordDatabase

    // Roman numeral templates for major and minor keys
    private let majorNumerals = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
    private let minorNumerals = ["i", "ii°", "III", "iv", "v", "VI", "VII"]

    // MARK: - Initialization

    init() {
        self.theoryEngine = MusicTheoryEngine()
        self.database = ChordDatabase()
    }

    // MARK: - Progression Analysis

    /// Analyze a chord progression
    func analyzeProgression(_ chords: [String]) -> ProgressionAnalysis {
        guard !chords.isEmpty else {
            return ProgressionAnalysis(chords: [])
        }

        // Detect key
        let keyResult = theoryEngine.detectKey(from: chords)
        let key = keyResult?.key
        let scale = keyResult?.scale

        // Generate Roman numerals
        let romanNumerals = generateRomanNumerals(for: chords, in: key, scale: scale)

        // Identify progression type
        let (progressionType, commonName) = identifyProgressionType(chords, romanNumerals: romanNumerals)

        // Generate variations
        let variations = generateVariations(for: chords, key: key)

        return ProgressionAnalysis(
            chords: chords,
            key: key,
            scale: scale,
            romanNumerals: romanNumerals,
            progressionType: progressionType,
            commonName: commonName,
            variations: variations,
            confidence: keyResult?.confidence ?? 0.5
        )
    }

    // MARK: - Roman Numerals

    /// Generate Roman numeral analysis for chords
    private func generateRomanNumerals(for chords: [String], in key: String?, scale: ScaleType?) -> [RomanNumeral] {
        guard let key = key, let scale = scale else {
            return chords.map { chord in
                RomanNumeral(
                    chord: chord,
                    numeral: "?",
                    function: .chromatic,
                    isDiatonic: false
                )
            }
        }

        let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        guard let keyIndex = chromaticScale.firstIndex(of: key) else {
            return []
        }

        return chords.map { chord in
            let chordRoot = theoryEngine.extractChordRoot(chord)
            guard let chordIndex = chromaticScale.firstIndex(of: chordRoot) else {
                return RomanNumeral(chord: chord, numeral: "?", function: .chromatic, isDiatonic: false)
            }

            // Calculate scale degree
            let degree = (chordIndex - keyIndex + 12) % 12
            let quality = theoryEngine.getChordQuality(chord)

            // Get numeral based on scale degree and scale type
            let numerals = scale == .major ? majorNumerals : minorNumerals
            var numeral: String
            var function: HarmonicFunction
            var isDiatonic = true

            switch degree {
            case 0: // Tonic
                numeral = numerals[0]
                function = .tonic
            case 2: // Supertonic
                numeral = numerals[1]
                function = .subdominant
            case 4: // Mediant
                numeral = numerals[2]
                function = .tonic
            case 5: // Subdominant
                numeral = numerals[3]
                function = .subdominant
            case 7: // Dominant
                numeral = numerals[4]
                function = .dominant
            case 9: // Submediant
                numeral = numerals[5]
                function = .tonic
            case 11: // Leading tone
                numeral = numerals[6]
                function = .dominant
            default:
                // Chromatic chord
                numeral = "♭\(romanFromDegree(degree))"
                function = .chromatic
                isDiatonic = false
            }

            // Append quality modifiers
            numeral = appendQualityToNumeral(numeral, quality: quality, expectedQuality: getExpectedQuality(degree: degree, scale: scale))

            return RomanNumeral(
                chord: chord,
                numeral: numeral,
                function: function,
                isDiatonic: isDiatonic
            )
        }
    }

    /// Get Roman numeral from scale degree
    private func romanFromDegree(_ degree: Int) -> String {
        let romanNumerals = ["I", "II", "III", "IV", "V", "VI", "VII"]
        let scaleDegrees = [0, 2, 4, 5, 7, 9, 11]

        if let index = scaleDegrees.firstIndex(of: degree) {
            return romanNumerals[index]
        }

        // For chromatic degrees
        return "?"
    }

    /// Get expected chord quality for a scale degree
    private func getExpectedQuality(degree: Int, scale: ScaleType) -> ChordQuality {
        if scale == .major {
            switch degree {
            case 0, 5, 7: return .major // I, IV, V
            case 2, 4, 9: return .minor // ii, iii, vi
            case 11: return .diminished // vii°
            default: return .major
            }
        } else { // Minor
            switch degree {
            case 4, 7: return .minor // iv, v
            case 0: return .minor // i
            case 5, 9, 11: return .major // III, VI, VII
            case 2: return .diminished // ii°
            default: return .minor
            }
        }
    }

    /// Append quality modifiers to Roman numeral
    private func appendQualityToNumeral(_ numeral: String, quality: ChordQuality, expectedQuality: ChordQuality) -> String {
        var result = numeral

        // If quality doesn't match expected, modify the numeral
        if quality != expectedQuality {
            switch quality {
            case .dominant7:
                result += "7"
            case .major7:
                result += "maj7"
            case .minor7:
                result += "7"
            case .diminished:
                if !result.contains("°") {
                    result += "°"
                }
            case .augmented:
                result += "+"
            default:
                break
            }
        } else {
            // Add common extensions
            switch quality {
            case .dominant7:
                result += "7"
            case .major7:
                result += "maj7"
            case .minor7:
                result += "7"
            default:
                break
            }
        }

        return result
    }

    // MARK: - Progression Identification

    /// Identify the type of progression
    private func identifyProgressionType(_ chords: [String], romanNumerals: [RomanNumeral]) -> (ProgressionType?, String?) {
        // Extract just the numeral strings
        let numeralStrings = romanNumerals.map { $0.numeral }

        // Check for common patterns
        if numeralStrings.contains(where: { $0.contains("ii") }) &&
           numeralStrings.contains(where: { $0.contains("V") }) &&
           numeralStrings.contains(where: { $0.contains("I") }) {
            return (.fiftysTwoFiveOne, "ii-V-I (Jazz Standard)")
        }

        if numeralStrings.prefix(4) == ["I", "V", "vi", "IV"] {
            return (.oneFiveSixFour, "I-V-vi-IV (Axis Progression)")
        }

        if numeralStrings.prefix(3) == ["I", "IV", "V"] {
            return (.oneFourFiveOne, "I-IV-V (Basic Rock)")
        }

        if numeralStrings.prefix(4) == ["I", "vi", "IV", "V"] {
            return (.oneSixFourFive, "I-vi-IV-V (50s Progression)")
        }

        if numeralStrings.prefix(4) == ["vi", "IV", "I", "V"] {
            return (.sixFourOneFive, "vi-IV-I-V (Sensitive)")
        }

        // Check against database
        let matchingProgressions = database.findProgressionsContaining(chords: chords)
        if let match = matchingProgressions.first {
            return (match.type, match.name)
        }

        return (nil, nil)
    }

    // MARK: - Variations

    /// Generate progression variations
    private func generateVariations(for chords: [String], key: String?) -> [ProgressionVariation] {
        var variations: [ProgressionVariation] = []

        // Simplified version (basic triads only)
        let simplified = chords.map { simplifyChord($0) }
        if simplified != chords {
            variations.append(ProgressionVariation(
                chords: simplified,
                variationType: .simpler,
                description: "Remove extensions for easier playing",
                difficulty: .beginner
            ))
        }

        // Add 7ths
        let with7ths = chords.map { add7th($0) }
        if with7ths != chords {
            variations.append(ProgressionVariation(
                chords: with7ths,
                variationType: .extensions,
                description: "Add 7th chords for richer harmony",
                difficulty: .intermediate
            ))
        }

        // Jazz reharmonization (add ii-V before each chord)
        if chords.count <= 4 {
            let jazzReharmonized = addJazzSubstitutions(to: chords, key: key)
            if jazzReharmonized.count > chords.count {
                variations.append(ProgressionVariation(
                    chords: jazzReharmonized,
                    variationType: .jazzReharmonization,
                    description: "Add ii-V substitutions for jazz flavor",
                    difficulty: .advanced
                ))
            }
        }

        // Tritone substitutions
        let tritoneSubbed = applyTritoneSubstitutions(to: chords)
        if tritoneSubbed != chords {
            variations.append(ProgressionVariation(
                chords: tritoneSubbed,
                variationType: .substitution,
                description: "Use tritone substitutions",
                difficulty: .advanced
            ))
        }

        return variations
    }

    /// Simplify a chord to basic triad
    private func simplifyChord(_ chord: String) -> String {
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
            return root
        }
    }

    /// Add 7th to a chord
    private func add7th(_ chord: String) -> String {
        let quality = theoryEngine.getChordQuality(chord)

        // Don't add if already has 7th
        if quality == .dominant7 || quality == .major7 || quality == .minor7 {
            return chord
        }

        // Add appropriate 7th
        switch quality {
        case .major:
            return "\(chord)7" // Dominant 7th for now
        case .minor:
            return "\(chord)7"
        default:
            return chord
        }
    }

    /// Add jazz ii-V substitutions
    private func addJazzSubstitutions(to chords: [String], key: String?) -> [String] {
        guard let key = key else { return chords }

        var result: [String] = []

        for chord in chords {
            // Add ii-V before each chord (simplified)
            if chord == key {
                // Add ii-V-I
                result.append("\(theoryEngine.transposeChord(key, by: 2))m7")
                result.append("\(theoryEngine.transposeChord(key, by: 7))7")
            }
            result.append(chord)
        }

        return result
    }

    /// Apply tritone substitutions to dominant chords
    private func applyTritoneSubstitutions(to chords: [String]) -> [String] {
        return chords.map { chord in
            let quality = theoryEngine.getChordQuality(chord)
            if quality == .dominant7 {
                // Tritone sub: transpose by 6 semitones
                return theoryEngine.transposeChord(chord, by: 6)
            }
            return chord
        }
    }
}
