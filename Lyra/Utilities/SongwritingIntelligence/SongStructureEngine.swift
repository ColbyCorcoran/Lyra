//
//  SongStructureEngine.swift
//  Lyra
//
//  Phase 7.14: AI Songwriting Assistance - Song Structure Intelligence
//  On-device song structure templates and arrangement suggestions
//

import Foundation
import SwiftData

/// Engine for suggesting song structures and section arrangements
/// Uses rule-based composition patterns (100% on-device)
@MainActor
class SongStructureEngine {

    // MARK: - Shared Instance
    static let shared = SongStructureEngine()

    // MARK: - Structure Templates

    /// Common song structures by genre
    private let structureTemplates: [String: [SongStructureTemplate]] = [
        "pop": [
            SongStructureTemplate(
                name: "Verse-Chorus",
                sections: ["Intro", "Verse 1", "Chorus", "Verse 2", "Chorus", "Bridge", "Chorus", "Outro"],
                sectionLengths: [8, 16, 16, 16, 16, 8, 16, 8],
                dynamics: [.soft, .medium, .loud, .medium, .loud, .soft, .loud, .soft],
                description: "Classic pop structure with verse-chorus alternation"
            ),
            SongStructureTemplate(
                name: "ABABCB",
                sections: ["Verse 1", "Chorus", "Verse 2", "Chorus", "Bridge", "Chorus"],
                sectionLengths: [16, 16, 16, 16, 8, 16],
                dynamics: [.medium, .loud, .medium, .loud, .soft, .loud],
                description: "Simple, radio-friendly structure"
            )
        ],
        "rock": [
            SongStructureTemplate(
                name: "Verse-Chorus-Solo",
                sections: ["Intro", "Verse 1", "Chorus", "Verse 2", "Chorus", "Solo", "Chorus", "Outro"],
                sectionLengths: [8, 16, 16, 16, 16, 16, 16, 8],
                dynamics: [.loud, .medium, .loud, .medium, .loud, .loud, .loud, .medium],
                description: "Rock structure with instrumental solo"
            )
        ],
        "folk": [
            SongStructureTemplate(
                name: "Simple Verse",
                sections: ["Intro", "Verse 1", "Verse 2", "Verse 3", "Verse 4", "Outro"],
                sectionLengths: [4, 16, 16, 16, 16, 4],
                dynamics: [.soft, .soft, .medium, .medium, .soft, .soft],
                description: "Traditional folk verse structure"
            )
        ],
        "worship": [
            SongStructureTemplate(
                name: "Verse-Chorus-Bridge",
                sections: ["Intro", "Verse 1", "Chorus", "Verse 2", "Chorus", "Bridge", "Chorus", "Chorus", "Outro"],
                sectionLengths: [8, 16, 16, 16, 16, 8, 16, 16, 8],
                dynamics: [.soft, .soft, .medium, .soft, .medium, .medium, .loud, .loud, .soft],
                description: "Worship build with repeated choruses"
            )
        ],
        "blues": [
            SongStructureTemplate(
                name: "12-Bar Blues",
                sections: ["Verse 1", "Verse 2", "Verse 3"],
                sectionLengths: [12, 12, 12],
                dynamics: [.medium, .medium, .medium],
                description: "Traditional 12-bar blues form"
            )
        ]
    ]

    // MARK: - Structure Generation

    /// Suggest song structure based on genre and length
    func suggestStructure(
        for genre: String,
        targetLength: Int? = nil,
        mood: String = "balanced"
    ) -> SongStructureTemplate {

        let templates = structureTemplates[genre.lowercased()] ?? structureTemplates["pop"]!

        // Filter by target length if specified
        if let targetLength = targetLength {
            let filtered = templates.filter { template in
                let totalBars = template.sectionLengths.reduce(0, +)
                return abs(totalBars - targetLength) <= 16
            }

            if let match = filtered.first {
                return match
            }
        }

        // Return first template or create custom
        return templates.first ?? createCustomStructure(genre: genre, bars: targetLength ?? 64, mood: mood)
    }

    /// Get multiple structure options
    func suggestStructureOptions(
        for genre: String,
        count: Int = 3
    ) -> [SongStructureTemplate] {

        let templates = structureTemplates[genre.lowercased()] ?? structureTemplates["pop"]!

        return Array(templates.prefix(count))
    }

    /// Build custom structure
    func createCustomStructure(
        genre: String,
        bars: Int,
        mood: String = "balanced"
    ) -> SongStructureTemplate {

        var sections: [String] = []
        var lengths: [Int] = []
        var dynamics: [DynamicLevel] = []

        var remainingBars = bars

        // Always start with intro
        sections.append("Intro")
        lengths.append(8)
        dynamics.append(.soft)
        remainingBars -= 8

        // Add verses and choruses
        var sectionCount = 1

        while remainingBars >= 32 {
            // Verse
            sections.append("Verse \(sectionCount)")
            lengths.append(16)
            dynamics.append(sectionCount == 1 ? .soft : .medium)
            remainingBars -= 16

            // Chorus
            sections.append("Chorus")
            lengths.append(16)
            dynamics.append(.loud)
            remainingBars -= 16

            sectionCount += 1
        }

        // Add bridge if space
        if remainingBars >= 16 {
            sections.append("Bridge")
            lengths.append(8)
            dynamics.append(.medium)
            remainingBars -= 8

            // Final chorus
            sections.append("Chorus")
            lengths.append(16)
            dynamics.append(.loud)
            remainingBars -= 16
        }

        // Add outro
        if remainingBars >= 4 {
            sections.append("Outro")
            lengths.append(min(8, remainingBars))
            dynamics.append(.soft)
        }

        return SongStructureTemplate(
            name: "Custom \(genre.capitalized)",
            sections: sections,
            sectionLengths: lengths,
            dynamics: dynamics,
            description: "Custom \(bars)-bar structure for \(genre)"
        )
    }

    /// Suggest section arrangement modifications
    func suggestArrangementVariations(
        of template: SongStructureTemplate,
        count: Int = 3
    ) -> [SongStructureTemplate] {

        var variations: [SongStructureTemplate] = []

        // Variation 1: Add pre-chorus
        var withPreChorus = template
        var newSections: [String] = []
        var newLengths: [Int] = []
        var newDynamics: [DynamicLevel] = []

        for (index, section) in template.sections.enumerated() {
            newSections.append(section)
            newLengths.append(template.sectionLengths[index])
            newDynamics.append(template.dynamics[index])

            if section.contains("Verse") {
                newSections.append("Pre-Chorus")
                newLengths.append(8)
                newDynamics.append(.medium)
            }
        }

        withPreChorus.sections = newSections
        withPreChorus.sectionLengths = newLengths
        withPreChorus.dynamics = newDynamics
        withPreChorus.name = template.name + " with Pre-Chorus"
        variations.append(withPreChorus)

        // Variation 2: Double final chorus
        var doubleChorus = template
        if let lastChorusIndex = template.sections.lastIndex(of: "Chorus") {
            doubleChorus.sections.insert("Chorus", at: lastChorusIndex + 1)
            doubleChorus.sectionLengths.insert(16, at: lastChorusIndex + 1)
            doubleChorus.dynamics.insert(.loud, at: lastChorusIndex + 1)
            doubleChorus.name = template.name + " with Double Chorus"
            variations.append(doubleChorus)
        }

        // Variation 3: Add instrumental break
        var withBreak = template
        if template.sections.count >= 4 {
            let insertIndex = template.sections.count / 2
            withBreak.sections.insert("Instrumental", at: insertIndex)
            withBreak.sectionLengths.insert(16, at: insertIndex)
            withBreak.dynamics.insert(.medium, at: insertIndex)
            withBreak.name = template.name + " with Instrumental"
            variations.append(withBreak)
        }

        return Array(variations.prefix(count))
    }

    /// Analyze and optimize existing structure
    func analyzeStructure(_ sections: [String]) -> StructureAnalysis {

        let totalSections = sections.count

        // Count section types
        let verseCount = sections.filter { $0.contains("Verse") }.count
        let chorusCount = sections.filter { $0.contains("Chorus") }.count
        let bridgeCount = sections.filter { $0.contains("Bridge") }.count

        // Analyze balance
        var strengths: [String] = []
        var weaknesses: [String] = []
        var suggestions: [String] = []

        // Check verse/chorus balance
        if chorusCount >= verseCount {
            strengths.append("Good chorus repetition for memorability")
        } else {
            weaknesses.append("Few chorus repetitions")
            suggestions.append("Consider adding one more chorus for impact")
        }

        // Check for bridge
        if bridgeCount > 0 {
            strengths.append("Bridge provides contrast")
        } else if totalSections >= 6 {
            weaknesses.append("No bridge for variety")
            suggestions.append("Add a bridge before the final chorus")
        }

        // Check intro/outro
        let hasIntro = sections.first?.contains("Intro") ?? false
        let hasOutro = sections.last?.contains("Outro") ?? false

        if !hasIntro {
            suggestions.append("Consider adding an intro")
        }

        if !hasOutro {
            suggestions.append("Consider adding an outro for smooth ending")
        }

        // Overall structure quality
        let qualityScore = Double(strengths.count) / Double(max(strengths.count + weaknesses.count, 1))

        return StructureAnalysis(
            totalSections: totalSections,
            verseCount: verseCount,
            chorusCount: chorusCount,
            bridgeCount: bridgeCount,
            strengths: strengths,
            weaknesses: weaknesses,
            suggestions: suggestions,
            qualityScore: qualityScore
        )
    }

    /// Get section length recommendations
    func recommendSectionLength(
        for sectionType: String,
        genre: String
    ) -> SectionLengthRecommendation {

        let recommendations: [String: (typical: Int, range: ClosedRange<Int>)] = [
            "Intro": (8, 4...16),
            "Verse": (16, 8...32),
            "Chorus": (16, 8...24),
            "Pre-Chorus": (8, 4...8),
            "Bridge": (8, 8...16),
            "Solo": (16, 16...32),
            "Instrumental": (16, 8...32),
            "Outro": (8, 4...16)
        ]

        let (typical, range) = recommendations[sectionType] ?? (16, 8...24)

        return SectionLengthRecommendation(
            sectionType: sectionType,
            typicalLength: typical,
            minimumLength: range.lowerBound,
            maximumLength: range.upperBound,
            reasoning: "Typical \(sectionType) length for \(genre)"
        )
    }

    /// Suggest dynamic arc for structure
    func suggestDynamicArc(for sections: [String]) -> [DynamicLevel] {

        var dynamics: [DynamicLevel] = []

        for (index, section) in sections.enumerated() {
            let position = Double(index) / Double(max(sections.count - 1, 1))

            if section.contains("Intro") {
                dynamics.append(.soft)
            } else if section.contains("Verse") {
                // Verses build gradually
                if index == 1 {
                    dynamics.append(.soft)
                } else {
                    dynamics.append(.medium)
                }
            } else if section.contains("Chorus") {
                // Choruses are louder, final one loudest
                if position > 0.8 {
                    dynamics.append(.loud)
                } else {
                    dynamics.append(.medium)
                }
            } else if section.contains("Bridge") {
                dynamics.append(.soft)
            } else if section.contains("Solo") {
                dynamics.append(.loud)
            } else if section.contains("Outro") {
                dynamics.append(.soft)
            } else {
                dynamics.append(.medium)
            }
        }

        return dynamics
    }
}

// MARK: - Data Models

enum DynamicLevel: String, Codable, CaseIterable {
    case soft = "Soft"
    case medium = "Medium"
    case loud = "Loud"

    var description: String {
        switch self {
        case .soft:
            return "Quiet, intimate, restrained"
        case .medium:
            return "Moderate, balanced energy"
        case .loud:
            return "Full, powerful, climactic"
        }
    }
}

struct SongStructureTemplate: Identifiable, Codable {
    let id: UUID = UUID()
    var name: String
    var sections: [String]
    var sectionLengths: [Int] // in bars
    var dynamics: [DynamicLevel]
    var description: String

    var totalBars: Int {
        sectionLengths.reduce(0, +)
    }

    var estimatedDuration: String {
        // Assuming 120 BPM, 4/4 time
        let totalBeats = totalBars * 4
        let seconds = Double(totalBeats) / 2.0 // 120 BPM = 2 beats per second
        let minutes = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))

        return "\(minutes):\(String(format: "%02d", secs))"
    }
}

struct StructureAnalysis: Codable {
    let totalSections: Int
    let verseCount: Int
    let chorusCount: Int
    let bridgeCount: Int
    let strengths: [String]
    let weaknesses: [String]
    let suggestions: [String]
    let qualityScore: Double
}

struct SectionLengthRecommendation: Codable {
    let sectionType: String
    let typicalLength: Int
    let minimumLength: Int
    let maximumLength: Int
    let reasoning: String
}
