//
//  KeyCompatibilityAnalyzer.swift
//  Lyra
//
//  Analyzes key compatibility for set building and smooth transitions
//  Part of Phase 7.3: Key Intelligence
//

import Foundation

/// Analyzes key relationships and compatibility for setlists
class KeyCompatibilityAnalyzer {

    // MARK: - Properties

    private let theoryEngine: MusicTheoryEngine

    // Circle of fifths (clockwise)
    private let circleOfFifths = ["C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#", "F"]

    // MARK: - Initialization

    init() {
        self.theoryEngine = MusicTheoryEngine()
    }

    // MARK: - Compatibility Analysis

    /// Analyze compatibility between two keys
    func analyzeCompatibility(key1: String, key2: String) -> KeyCompatibility {
        // Same key
        if key1 == key2 {
            return KeyCompatibility(
                key1: key1,
                key2: key2,
                compatibilityScore: 1.0,
                relationship: .same,
                transitionDifficulty: .veryEasy
            )
        }

        // Check relationship
        let relationship = determineRelationship(key1: key1, key2: key2)
        let score = calculateCompatibilityScore(relationship: relationship)
        let difficulty = determineTransitionDifficulty(relationship: relationship)
        let modulation = suggestModulation(from: key1, to: key2, relationship: relationship)

        return KeyCompatibility(
            key1: key1,
            key2: key2,
            compatibilityScore: score,
            relationship: relationship,
            transitionDifficulty: difficulty,
            suggestedModulation: modulation
        )
    }

    /// Find compatible keys for setlist building
    func findCompatibleKeys(for key: String, count: Int = 5) -> [(key: String, compatibility: KeyCompatibility)] {
        var compatible: [(key: String, compatibility: KeyCompatibility)] = []

        // Check all keys
        let allKeys = ["C", "D", "E", "F", "G", "A", "B",
                       "Cm", "Dm", "Em", "Fm", "Gm", "Am", "Bm"]

        for otherKey in allKeys where otherKey != key {
            let compat = analyzeCompatibility(key1: key, key2: otherKey)
            if compat.compatibilityScore > 0.3 {
                compatible.append((key: otherKey, compatibility: compat))
            }
        }

        // Sort by compatibility
        compatible.sort { $0.compatibility.compatibilityScore > $1.compatibility.compatibilityScore }

        return Array(compatible.prefix(count))
    }

    /// Analyze an entire setlist for key flow
    func analyzeSetlist(keys: [String]) -> SetlistKeyAnalysis {
        guard !keys.isEmpty else {
            return SetlistKeyAnalysis(keys: [], transitions: [], overallFlow: 0)
        }

        var transitions: [KeyCompatibility] = []
        var flowScores: [Float] = []

        for i in 0..<(keys.count - 1) {
            let compat = analyzeCompatibility(key1: keys[i], key2: keys[i + 1])
            transitions.append(compat)
            flowScores.append(compat.compatibilityScore)
        }

        let overallFlow = flowScores.isEmpty ? 0 : flowScores.reduce(0, +) / Float(flowScores.count)

        return SetlistKeyAnalysis(
            keys: keys,
            transitions: transitions,
            overallFlow: overallFlow
        )
    }

    // MARK: - Private Methods

    /// Determine relationship between two keys
    private func determineRelationship(key1: String, key2: String) -> KeyRelationship {
        let root1 = theoryEngine.extractChordRoot(key1.replacingOccurrences(of: "m", with: ""))
        let root2 = theoryEngine.extractChordRoot(key2.replacingOccurrences(of: "m", with: ""))

        // Parallel major/minor
        if root1 == root2 {
            return .parallel
        }

        // Relative major/minor
        let relativeMajor1 = theoryEngine.transposeChord(root1, by: 3)
        let relativeMinor1 = theoryEngine.transposeChord(root1, by: 9)

        if root2 == relativeMajor1 || root2 == relativeMinor1 {
            return .relative
        }

        // Circle of fifths (adjacent keys)
        if let index1 = circleOfFifths.firstIndex(of: root1),
           let index2 = circleOfFifths.firstIndex(of: root2) {
            let distance = abs(index1 - index2)
            if distance == 1 || distance == 11 { // Adjacent in circle
                return .circleOfFifths
            }
        }

        // Close keys (1-2 semitones)
        let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        if let index1 = chromaticScale.firstIndex(of: root1),
           let index2 = chromaticScale.firstIndex(of: root2) {
            let distance = min(abs(index1 - index2), 12 - abs(index1 - index2))
            if distance <= 2 {
                return .closeKeys
            }
        }

        return .distantKeys
    }

    /// Calculate compatibility score based on relationship
    private func calculateCompatibilityScore(relationship: KeyRelationship) -> Float {
        switch relationship {
        case .same: return 1.0
        case .relative: return 0.9
        case .parallel: return 0.8
        case .circleOfFifths: return 0.7
        case .closeKeys: return 0.5
        case .distantKeys: return 0.3
        }
    }

    /// Determine transition difficulty
    private func determineTransitionDifficulty(relationship: KeyRelationship) -> TransitionDifficulty {
        switch relationship {
        case .same: return .veryEasy
        case .relative, .parallel: return .easy
        case .circleOfFifths, .closeKeys: return .moderate
        case .distantKeys: return .difficult
        }
    }

    /// Suggest modulation technique
    private func suggestModulation(from key1: String, to key2: String, relationship: KeyRelationship) -> String {
        switch relationship {
        case .same:
            return "No modulation needed (same key)"
        case .relative:
            return "Use pivot chord (shared chords between relative keys)"
        case .parallel:
            return "Direct modulation (parallel keys share tonic)"
        case .circleOfFifths:
            return "Use V-I cadence to new key"
        case .closeKeys:
            return "Chromatic modulation (half-step up/down)"
        case .distantKeys:
            return "Consider intermediate key or dramatic modulation"
        }
    }
}

// MARK: - Setlist Key Analysis

struct SetlistKeyAnalysis {
    var keys: [String]
    var transitions: [KeyCompatibility]
    var overallFlow: Float // 0.0 - 1.0

    var flowQuality: String {
        if overallFlow >= 0.8 {
            return "Excellent key flow"
        } else if overallFlow >= 0.6 {
            return "Good key flow"
        } else if overallFlow >= 0.4 {
            return "Moderate key flow"
        } else {
            return "Challenging key transitions"
        }
    }
}
