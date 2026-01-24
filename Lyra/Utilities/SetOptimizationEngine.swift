//
//  SetOptimizationEngine.swift
//  Lyra
//
//  Analyzes setlists for optimal flow, key transitions, and energy balance
//

import Foundation
import SwiftData

/// Engine for set optimization and flow analysis
class SetOptimizationEngine {
    static let shared = SetOptimizationEngine()

    // MARK: - Key Analysis

    /// Analyze key transitions in a set
    func analyzeKeyTransitions(songs: [(id: UUID, title: String, key: String?)]) -> [KeyTransition] {
        var transitions: [KeyTransition] = []

        for i in 0..<(songs.count - 1) {
            guard let fromKey = songs[i].key,
                  let toKey = songs[i + 1].key else { continue }

            let semitoneChange = calculateSemitoneChange(from: fromKey, to: toKey)
            let smoothness = calculateTransitionSmoothness(semitoneChange: semitoneChange)

            var suggestion: String?
            if smoothness < 0.5 {
                suggestion = "Consider transitioning through a common chord or adding a brief interlude"
            }

            let transition = KeyTransition(
                fromSongID: songs[i].id,
                toSongID: songs[i + 1].id,
                fromKey: fromKey,
                toKey: toKey,
                semitoneChange: semitoneChange,
                smoothness: smoothness,
                suggestion: suggestion
            )

            transitions.append(transition)
        }

        return transitions
    }

    /// Calculate semitone difference between two keys
    private func calculateSemitoneChange(from fromKey: String, to toKey: String) -> Int {
        let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        let fromRoot = extractRoot(from: fromKey)
        let toRoot = extractRoot(from: toKey)

        guard let fromIndex = chromaticScale.firstIndex(of: fromRoot),
              let toIndex = chromaticScale.firstIndex(of: toRoot) else {
            return 0
        }

        var semitones = toIndex - fromIndex
        if semitones > 6 {
            semitones -= 12 // Wrap around (closer to go down)
        } else if semitones < -6 {
            semitones += 12 // Wrap around (closer to go up)
        }

        return semitones
    }

    /// Extract root note from key signature (e.g., "Am" -> "A")
    private func extractRoot(from key: String) -> String {
        let cleanKey = key.replacingOccurrences(of: "m", with: "")
                          .replacingOccurrences(of: "maj", with: "")
                          .replacingOccurrences(of: "min", with: "")

        // Handle flats and sharps
        if cleanKey.contains("b") {
            // Convert flats to sharps for consistency
            let flatToSharp: [String: String] = [
                "Db": "C#", "Eb": "D#", "Gb": "F#", "Ab": "G#", "Bb": "A#"
            ]
            return flatToSharp[cleanKey] ?? cleanKey
        }

        return String(cleanKey.prefix(2)) // Handle sharps (e.g., "C#")
    }

    /// Calculate how smooth a key transition is (0.0 = jarring, 1.0 = smooth)
    private func calculateTransitionSmoothness(semitoneChange: Int) -> Float {
        switch abs(semitoneChange) {
        case 0: return 1.0 // Same key - perfect
        case 1: return 0.9 // Half step - very smooth
        case 2: return 0.8 // Whole step - smooth
        case 3, 4: return 0.6 // Minor/Major third - acceptable
        case 5: return 0.5 // Fourth - neutral
        case 6: return 0.3 // Tritone - jarring
        case 7: return 0.5 // Fifth - acceptable
        default: return 0.4 // Large jumps - challenging
        }
    }

    // MARK: - Energy Flow Analysis

    /// Analyze energy progression through a set
    func analyzeEnergyFlow(songs: [(id: UUID, title: String, tempo: Int?, energy: Float?)]) -> [Float] {
        return songs.map { song in
            // Calculate energy based on tempo and metadata
            if let energy = song.energy {
                return energy
            } else if let tempo = song.tempo {
                return estimateEnergyFromTempo(tempo)
            } else {
                return 0.5 // Default medium energy
            }
        }
    }

    /// Estimate song energy from tempo
    private func estimateEnergyFromTempo(_ tempo: Int) -> Float {
        switch tempo {
        case 0..<60: return 0.2 // Very slow
        case 60..<80: return 0.3 // Slow
        case 80..<100: return 0.5 // Medium
        case 100..<120: return 0.6 // Medium-fast
        case 120..<140: return 0.8 // Fast
        default: return 0.9 // Very fast
        }
    }

    /// Detect energy imbalances in set
    func detectEnergyImbalances(energyFlow: [Float]) -> [PerformanceInsight] {
        var insights: [PerformanceInsight] = []

        // Check for too many low-energy songs in a row
        var lowEnergyStreak = 0
        for (index, energy) in energyFlow.enumerated() {
            if energy < 0.4 {
                lowEnergyStreak += 1
                if lowEnergyStreak >= 3 {
                    let insight = PerformanceInsight(
                        type: .energyImbalance,
                        category: .optimization,
                        title: "Energy Dip Detected",
                        message: "Three or more low-energy songs in a row (starting at song \(index - 2)). Consider adding a higher-energy song to maintain audience engagement.",
                        severity: .suggestion,
                        actionable: true,
                        action: "Reorder songs",
                        confidence: 0.8
                    )
                    insights.append(insight)
                    break // Only report once
                }
            } else {
                lowEnergyStreak = 0
            }
        }

        // Check for abrupt energy changes
        for i in 0..<(energyFlow.count - 1) {
            let change = abs(energyFlow[i + 1] - energyFlow[i])
            if change > 0.5 {
                let insight = PerformanceInsight(
                    type: .setFlowSuggestion,
                    category: .optimization,
                    title: "Abrupt Energy Change",
                    message: "Large energy jump between songs \(i + 1) and \(i + 2). Consider adding a transition song or brief interlude.",
                    severity: .suggestion,
                    actionable: true,
                    action: "Add transition",
                    confidence: 0.7
                )
                insights.append(insight)
            }
        }

        // Check for optimal energy arc (should peak mid-set)
        if energyFlow.count >= 5 {
            let midPoint = energyFlow.count / 2
            let earlyAvg = energyFlow.prefix(midPoint).reduce(0, +) / Float(midPoint)
            let midAvg = energyFlow[midPoint - 1...midPoint + 1].reduce(0, +) / 3.0
            let lateAvg = energyFlow.suffix(midPoint).reduce(0, +) / Float(midPoint)

            if earlyAvg > midAvg && earlyAvg > lateAvg {
                let insight = PerformanceInsight(
                    type: .setFlowSuggestion,
                    category: .optimization,
                    title: "Front-Loaded Energy",
                    message: "Your set peaks too early. Consider moving some high-energy songs toward the middle or end for better pacing.",
                    severity: .suggestion,
                    actionable: true,
                    action: "Reorder songs",
                    confidence: 0.75
                )
                insights.append(insight)
            }
        }

        return insights
    }

    // MARK: - Set Order Optimization

    /// Suggest optimal song order based on multiple factors
    func suggestOptimalOrder(
        songs: [(id: UUID, title: String, key: String?, tempo: Int?, energy: Float?, difficulty: Float?)]
    ) -> [UUID] {
        var scoredSongs: [(id: UUID, score: Float, index: Int)] = []

        for (index, song) in songs.enumerated() {
            var score: Float = 0

            // Position score (where in set this song works best)
            let positionInSet = Float(index) / Float(max(songs.count - 1, 1))

            // Energy consideration
            let energy = song.energy ?? estimateEnergyFromTempo(song.tempo ?? 100)
            let idealEnergyForPosition = calculateIdealEnergyForPosition(positionInSet)
            let energyScore = 1.0 - abs(energy - idealEnergyForPosition)

            // Difficulty consideration (easier songs early and late, harder in middle)
            let difficulty = song.difficulty ?? 0.5
            let idealDifficultyForPosition = calculateIdealDifficultyForPosition(positionInSet)
            let difficultyScore = 1.0 - abs(difficulty - idealDifficultyForPosition)

            // Combined score
            score = energyScore * 0.6 + difficultyScore * 0.4

            scoredSongs.append((id: song.id, score: score, index: index))
        }

        // Sort by score and return IDs in optimal order
        return scoredSongs.sorted { $0.score > $1.score }.map { $0.id }
    }

    /// Calculate ideal energy level for position in set
    private func calculateIdealEnergyForPosition(_ position: Float) -> Float {
        // Energy should build from low to high, peak in middle-late, then wind down
        // Parabolic curve with peak at ~70% through set
        let peakPosition: Float = 0.7
        if position < peakPosition {
            // Building phase: 0.4 -> 0.9
            return 0.4 + (position / peakPosition) * 0.5
        } else {
            // Wind-down phase: 0.9 -> 0.5
            let remaining = (1.0 - position) / (1.0 - peakPosition)
            return 0.9 - (1.0 - remaining) * 0.4
        }
    }

    /// Calculate ideal difficulty for position in set
    private func calculateIdealDifficultyForPosition(_ position: Float) -> Float {
        // Start easier (warm-up), peak difficulty in middle, easier at end (fatigue)
        // Bell curve centered at 50%
        let distance = abs(position - 0.5) * 2.0 // 0 at center, 1 at edges
        return 0.3 + (1.0 - distance) * 0.5 // Range: 0.3 (edges) to 0.8 (center)
    }

    // MARK: - Set Analysis

    /// Perform comprehensive set analysis
    func analyzeSet(
        setID: UUID?,
        setName: String,
        songs: [(id: UUID, title: String, key: String?, tempo: Int?, energy: Float?, difficulty: Float?, duration: TimeInterval?)]
    ) -> SetAnalysis {
        // Calculate total and average durations
        let durations = songs.compactMap { $0.duration }
        let totalDuration = durations.reduce(0, +)
        let averageDuration = durations.isEmpty ? 0 : totalDuration / TimeInterval(durations.count)

        // Analyze key transitions
        let keyData = songs.map { (id: $0.id, title: $0.title, key: $0.key) }
        let keyTransitions = analyzeKeyTransitions(songs: keyData)

        // Find difficult transitions (smoothness < 0.5)
        let difficultTransitions = keyTransitions.filter { $0.smoothness < 0.5 }
                                                 .map { "\($0.fromKey) → \($0.toKey)" }

        // Analyze energy flow
        let energyData = songs.map { (id: $0.id, title: $0.title, tempo: $0.tempo, energy: $0.energy) }
        let energyFlow = analyzeEnergyFlow(songs: energyData)

        // Calculate pacing score
        let pacingScore = calculatePacingScore(
            energyFlow: energyFlow,
            keyTransitions: keyTransitions
        )

        // Suggest optimal order
        let optimalOrder = suggestOptimalOrder(songs: songs)

        // Find longest and shortest songs
        let longestSongIndex = durations.enumerated().max(by: { $0.element < $1.element })?.offset
        let shortestSongIndex = durations.enumerated().min(by: { $0.element < $1.element })?.offset

        return SetAnalysis(
            setID: setID,
            setName: setName,
            totalDuration: totalDuration,
            songCount: songs.count,
            keyTransitions: keyTransitions,
            difficultTransitions: difficultTransitions,
            energyFlow: energyFlow,
            optimalOrder: optimalOrder,
            averageSongDuration: averageDuration,
            longestSong: longestSongIndex.map { songs[$0].id },
            shortestSong: shortestSongIndex.map { songs[$0].id },
            pacingScore: pacingScore
        )
    }

    /// Calculate overall pacing score for a set
    private func calculatePacingScore(
        energyFlow: [Float],
        keyTransitions: [KeyTransition]
    ) -> Float {
        var score: Float = 1.0

        // Penalize for energy imbalances
        let energyVariance = calculateVariance(values: energyFlow)
        if energyVariance < 0.1 {
            score -= 0.2 // Too uniform
        } else if energyVariance > 0.4 {
            score -= 0.3 // Too chaotic
        }

        // Penalize for difficult key transitions
        let difficultCount = keyTransitions.filter { $0.smoothness < 0.5 }.count
        let transitionPenalty = Float(difficultCount) * 0.1
        score -= transitionPenalty

        // Reward optimal energy arc
        if energyFlow.count >= 3 {
            let midPoint = energyFlow.count / 2
            let midEnergy = energyFlow[midPoint]
            let avgEnergy = energyFlow.reduce(0, +) / Float(energyFlow.count)

            if midEnergy > avgEnergy {
                score += 0.2 // Good arc
            }
        }

        return max(0, min(1.0, score))
    }

    /// Calculate variance of values
    private func calculateVariance(values: [Float]) -> Float {
        guard !values.isEmpty else { return 0 }

        let mean = values.reduce(0, +) / Float(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Float(values.count)
    }

    // MARK: - Recommendations

    /// Generate set optimization recommendations
    func generateRecommendations(analysis: SetAnalysis) -> [String] {
        var recommendations: [String] = []

        // Pacing recommendations
        if analysis.pacingScore < 0.6 {
            recommendations.append("Consider reordering songs for better pacing and energy flow")
        }

        // Key transition recommendations
        if analysis.difficultTransitions.count > 2 {
            recommendations.append("Multiple difficult key transitions detected. Add brief interludes or reorder songs for smoother transitions")
        }

        // Duration recommendations
        if analysis.totalDuration < 1200 { // < 20 minutes
            recommendations.append("Set is relatively short (\(Int(analysis.totalDuration/60)) minutes). Consider adding 1-2 more songs")
        } else if analysis.totalDuration > 3600 { // > 60 minutes
            recommendations.append("Set is quite long (\(Int(analysis.totalDuration/60)) minutes). Consider splitting into two sets or removing songs to prevent fatigue")
        }

        // Energy flow recommendations
        let energyInsights = detectEnergyImbalances(energyFlow: analysis.energyFlow)
        if !energyInsights.isEmpty {
            recommendations.append("Energy imbalances detected. See detailed insights for specific suggestions")
        }

        return recommendations
    }
}
