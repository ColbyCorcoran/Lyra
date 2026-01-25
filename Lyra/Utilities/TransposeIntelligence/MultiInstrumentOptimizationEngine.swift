//
//  MultiInstrumentOptimizationEngine.swift
//  Lyra
//
//  Engine for optimizing transpose for multiple musicians
//  Part of Phase 7.9: Transpose Intelligence
//

import Foundation

/// Engine responsible for multi-musician transpose optimization
class MultiInstrumentOptimizationEngine {

    // MARK: - Dependencies

    private let voiceRangeEngine: VoiceRangeAnalysisEngine
    private let difficultyEngine: ChordDifficultyAnalysisEngine

    // MARK: - Initialization

    init(
        voiceRangeEngine: VoiceRangeAnalysisEngine,
        difficultyEngine: ChordDifficultyAnalysisEngine
    ) {
        self.voiceRangeEngine = voiceRangeEngine
        self.difficultyEngine = difficultyEngine
    }

    // MARK: - Band Optimization

    /// Find best compromise key for multiple musicians
    /// - Parameters:
    ///   - songContent: Song content to analyze
    ///   - currentKey: Current song key
    ///   - bandMembers: Array of band member profiles
    /// - Returns: Band optimization result
    func findBestCompromiseKey(
        songContent: String,
        currentKey: String?,
        bandMembers: [MusicianProfile]
    ) -> BandOptimizationResult {
        guard !bandMembers.isEmpty else {
            return BandOptimizationResult(
                recommendedKey: currentKey ?? "C",
                semitones: 0,
                bandFitnessScore: 0.0,
                memberFitness: [],
                conflicts: [],
                splitSolutions: []
            )
        }

        var bestOption: (semitones: Int, fitness: Float, memberScores: [MemberFitness]) = (0, 0.0, [])

        // Test all possible transpositions
        for semitones in -11...11 {
            let memberScores = bandMembers.map { member in
                evaluateMemberFitness(
                    songContent: songContent,
                    semitones: semitones,
                    member: member
                )
            }

            let overallFitness = scoreBandFitness(memberScores: memberScores)

            if overallFitness > bestOption.fitness {
                bestOption = (semitones, overallFitness, memberScores)
            }
        }

        // Identify conflicts
        let conflicts = analyzeConflicts(memberFitness: bestOption.memberScores)

        // Generate split solutions if there are conflicts
        let splitSolutions = conflicts.isEmpty ? [] :
            suggestSplitSolutions(
                songContent: songContent,
                currentKey: currentKey,
                bandMembers: bandMembers,
                conflicts: conflicts
            )

        let targetKey = TransposeEngine.transpose(
            currentKey ?? "C",
            by: bestOption.semitones,
            preferSharps: true
        )

        return BandOptimizationResult(
            recommendedKey: targetKey,
            semitones: bestOption.semitones,
            bandFitnessScore: bestOption.fitness,
            memberFitness: bestOption.memberScores,
            conflicts: conflicts,
            splitSolutions: splitSolutions
        )
    }

    // MARK: - Conflict Analysis

    /// Analyze conflicts between band members
    /// - Parameter memberFitness: Fitness scores for each member
    /// - Returns: Array of conflicts
    func analyzeConflicts(memberFitness: [MemberFitness]) -> [BandConflict] {
        var conflicts: [BandConflict] = []

        // Find members with poor fitness
        let poorFitMembers = memberFitness.filter { $0.overallScore < 0.5 }

        for poorMember in poorFitMembers {
            if let vocalScore = poorMember.vocalScore, vocalScore < 0.3 {
                conflicts.append(BandConflict(
                    memberName: poorMember.memberName,
                    conflictType: .vocalRangeMismatch,
                    severity: 1.0 - vocalScore,
                    description: "\(poorMember.memberName)'s vocal range doesn't fit this key"
                ))
            }

            if poorMember.difficultyScore > 7.0 {
                conflicts.append(BandConflict(
                    memberName: poorMember.memberName,
                    conflictType: .chordDifficulty,
                    severity: poorMember.difficultyScore / 10.0,
                    description: "Chords are too difficult for \(poorMember.memberName)"
                ))
            }
        }

        // Check for competing needs
        if memberFitness.count >= 2 {
            for i in 0..<memberFitness.count {
                for j in (i+1)..<memberFitness.count {
                    let member1 = memberFitness[i]
                    let member2 = memberFitness[j]

                    // Check if they need opposite transpositions
                    if let pref1 = member1.preferredSemitones,
                       let pref2 = member2.preferredSemitones,
                       abs(pref1 - pref2) > 6 {
                        conflicts.append(BandConflict(
                            memberName: "\(member1.memberName) vs \(member2.memberName)",
                            conflictType: .competingNeeds,
                            severity: Float(abs(pref1 - pref2)) / 12.0,
                            description: "Members need different key directions"
                        ))
                    }
                }
            }
        }

        return conflicts
    }

    // MARK: - Split Solutions

    /// Suggest split solutions for conflicts
    /// - Parameters:
    ///   - songContent: Song content
    ///   - currentKey: Current key
    ///   - bandMembers: Band members
    ///   - conflicts: Identified conflicts
    /// - Returns: Array of split solution suggestions
    func suggestSplitSolutions(
        songContent: String,
        currentKey: String?,
        bandMembers: [MusicianProfile],
        conflicts: [BandConflict]
    ) -> [SplitSolution] {
        var solutions: [SplitSolution] = []

        // Solution 1: Singer transposes, guitarist uses capo
        if let vocalist = bandMembers.first(where: { $0.instrument.lowercased().contains("vocal") || $0.instrument.lowercased().contains("singer") }),
           let guitarist = bandMembers.first(where: { $0.instrument.lowercased().contains("guitar") }) {

            // Find best key for vocalist
            if let vocalRange = vocalist.vocalRange {
                let vocalOptions = voiceRangeEngine.findOptimalKeyForVoice(
                    songContent: songContent,
                    currentKey: currentKey,
                    vocalRange: vocalRange
                )

                if let bestVocal = vocalOptions.first {
                    // Calculate capo for guitarist
                    let capoPosition = bestVocal.semitones > 0 ? 0 : abs(bestVocal.semitones)

                    solutions.append(SplitSolution(
                        description: "Transpose to \(TransposeEngine.transpose(currentKey ?? "C", by: bestVocal.semitones, preferSharps: true)) for vocalist, guitarist uses capo \(capoPosition)",
                        mainTranspose: bestVocal.semitones,
                        capoSuggestions: [(member: guitarist.name, capo: capoPosition)],
                        affectedMembers: [vocalist.name, guitarist.name],
                        feasibilityScore: bestVocal.score
                    ))
                }
            }
        }

        // Solution 2: Keep original key, use capo for all guitarists
        let guitarists = bandMembers.filter { $0.instrument.lowercased().contains("guitar") }
        if !guitarists.isEmpty {
            solutions.append(SplitSolution(
                description: "Keep original key, all guitarists use capo",
                mainTranspose: 0,
                capoSuggestions: guitarists.map { (member: $0.name, capo: 2) },
                affectedMembers: guitarists.map { $0.name },
                feasibilityScore: 0.7
            ))
        }

        return solutions
    }

    // MARK: - Band Fitness Scoring

    /// Score overall band fitness
    /// - Parameter memberScores: Individual member fitness scores
    /// - Returns: Overall band fitness (0.0-1.0)
    func scoreBandFitness(memberScores: [MemberFitness]) -> Float {
        guard !memberScores.isEmpty else { return 0.0 }

        // Calculate weighted average
        // Give more weight to members with poor scores (we want to help everyone)
        var totalScore: Float = 0.0
        var totalWeight: Float = 0.0

        for member in memberScores {
            let weight = member.overallScore < 0.5 ? 1.5 : 1.0 // Boost weight for struggling members
            totalScore += member.overallScore * weight
            totalWeight += weight
        }

        let averageScore = totalScore / totalWeight

        // Penalty if anyone has very low score (< 0.3)
        let worstScore = memberScores.map { $0.overallScore }.min() ?? 1.0
        let penalty = worstScore < 0.3 ? 0.2 : 0.0

        return max(0.0, averageScore - penalty)
    }

    // MARK: - Private Helper Methods

    /// Evaluate fitness for a single member
    private func evaluateMemberFitness(
        songContent: String,
        semitones: Int,
        member: MusicianProfile
    ) -> MemberFitness {
        var vocalScore: Float? = nil
        var difficultyScore: Float = 5.0
        var preferredSemitones: Int? = nil

        // Evaluate vocal range if applicable
        if let vocalRange = member.vocalRange {
            if let songRange = voiceRangeEngine.analyzeSongRange(content: songContent) {
                // Transpose song range
                let transposedRange = transposeSongRange(songRange, by: semitones)
                let fit = voiceRangeEngine.matchToVocalRange(
                    songRange: transposedRange,
                    vocalRange: vocalRange
                )

                vocalScore = calculateVocalFitScore(fit: fit)
                preferredSemitones = fit.optimalTransposition
            }
        }

        // Evaluate chord difficulty for instrument
        let chords = TransposeEngine.extractChords(from: songContent)
        let transposedChords = chords.map { chord in
            TransposeEngine.transpose(chord, by: semitones, preferSharps: true)
        }
        difficultyScore = difficultyEngine.averageDifficulty(
            chords: transposedChords,
            skillLevel: member.skillLevel
        )

        // Calculate overall member score
        var overallScore: Float = 0.0
        var componentCount: Float = 0.0

        if let vocal = vocalScore {
            overallScore += vocal * 0.6 // Vocal fit is critical
            componentCount += 0.6
        }

        // Invert difficulty (lower difficulty = higher score)
        let difficultyComponent = 1.0 - (difficultyScore / 10.0)
        overallScore += difficultyComponent * 0.4
        componentCount += 0.4

        overallScore /= componentCount

        return MemberFitness(
            memberName: member.name,
            instrument: member.instrument,
            overallScore: overallScore,
            vocalScore: vocalScore,
            difficultyScore: difficultyScore,
            preferredSemitones: preferredSemitones
        )
    }

    /// Calculate vocal fit score from VocalRangeFit
    private func calculateVocalFitScore(fit: VocalRangeFit) -> Float {
        if fit.fitsWithinRange && fit.lowestIsComfortable && fit.highestIsComfortable {
            return 1.0
        } else if fit.fitsWithinRange {
            return 0.7
        } else {
            return 0.3
        }
    }

    /// Transpose song range
    private func transposeSongRange(
        _ range: SongRangeAnalysis,
        by semitones: Int
    ) -> SongRangeAnalysis {
        let newLow = MusicalNote.fromMIDI(range.lowestNote.midiNumber + semitones)
        let newHigh = MusicalNote.fromMIDI(range.highestNote.midiNumber + semitones)

        return SongRangeAnalysis(
            lowestNote: newLow,
            highestNote: newHigh,
            rangeInSemitones: range.rangeInSemitones
        )
    }
}

// MARK: - Supporting Types

/// Result of band optimization
struct BandOptimizationResult {
    var recommendedKey: String
    var semitones: Int
    var bandFitnessScore: Float // 0.0-1.0
    var memberFitness: [MemberFitness]
    var conflicts: [BandConflict]
    var splitSolutions: [SplitSolution]
}

/// Fitness score for an individual band member
struct MemberFitness: Identifiable {
    var id = UUID()
    var memberName: String
    var instrument: String
    var overallScore: Float // 0.0-1.0
    var vocalScore: Float? // 0.0-1.0 if vocalist
    var difficultyScore: Float // 0-10 chord difficulty
    var preferredSemitones: Int? // Their ideal transposition
}

/// A conflict between band members
struct BandConflict: Identifiable {
    var id = UUID()
    var memberName: String
    var conflictType: ConflictType
    var severity: Float // 0.0-1.0
    var description: String

    enum ConflictType: String, Codable {
        case vocalRangeMismatch = "Vocal Range Mismatch"
        case chordDifficulty = "Chord Difficulty"
        case competingNeeds = "Competing Needs"
    }
}

/// A split solution suggestion
struct SplitSolution: Identifiable {
    var id = UUID()
    var description: String
    var mainTranspose: Int
    var capoSuggestions: [(member: String, capo: Int)]
    var affectedMembers: [String]
    var feasibilityScore: Float // 0.0-1.0
}
