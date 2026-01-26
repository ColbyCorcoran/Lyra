//
//  SetTemplate.swift
//  Lyra
//
//  Reusable templates for performance sets
//

import SwiftData
import Foundation

@Model
final class SetTemplate {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Template Info
    var name: String
    var templateDescription: String?
    var category: TemplateCategory

    // MARK: - Creator
    var createdBy: String // User record ID
    var creatorDisplayName: String

    // MARK: - Sharing
    var isPublic: Bool // Can be used by other teams
    var useCount: Int // Track popularity

    // MARK: - Template Structure
    @Relationship(deleteRule: .cascade, inverse: \TemplateSection.template)
    var sections: [TemplateSection]?

    // MARK: - Metadata
    var tags: [String]?
    var estimatedDuration: Int? // Minutes
    var targetAudience: String? // e.g., "Sunday Service", "Youth Group"

    // MARK: - Default Settings
    var defaultRoles: [String]? // Suggested roles for this template

    init(
        name: String,
        category: TemplateCategory,
        createdBy: String,
        creatorDisplayName: String
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.category = category
        self.createdBy = createdBy
        self.creatorDisplayName = creatorDisplayName
        self.isPublic = false
        self.useCount = 0
    }

    // MARK: - Methods
    func incrementUseCount() {
        useCount += 1
        modifiedAt = Date()
    }

    var sortedSections: [TemplateSection]? {
        sections?.sorted { $0.orderIndex < $1.orderIndex }
    }

    var totalSlots: Int {
        sections?.reduce(0) { $0 + $1.songSlotCount } ?? 0
    }
}

// MARK: - Template Category

enum TemplateCategory: String, Codable, CaseIterable {
    case worship = "Worship Service"
    case concert = "Concert"
    case rehearsal = "Rehearsal"
    case practice = "Practice Session"
    case recording = "Recording Session"
    case event = "Special Event"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .worship: return "hands.sparkles.fill"
        case .concert: return "music.mic.circle.fill"
        case .rehearsal: return "music.note.list"
        case .practice: return "repeat.circle.fill"
        case .recording: return "recordingtape.circle.fill"
        case .event: return "star.circle.fill"
        case .custom: return "gearshape.fill"
        }
    }

    var description: String {
        switch self {
        case .worship: return "Templates for church worship services"
        case .concert: return "Concert and performance templates"
        case .rehearsal: return "Rehearsal session templates"
        case .practice: return "Practice session templates"
        case .recording: return "Recording session templates"
        case .event: return "Special events and occasions"
        case .custom: return "Custom templates"
        }
    }
}

// MARK: - Template Section

@Model
final class TemplateSection {
    var id: UUID
    var orderIndex: Int

    var sectionName: String
    var sectionDescription: String?

    var songSlotCount: Int // Number of songs in this section
    var suggestedDuration: Int? // Minutes

    // Section characteristics
    var suggestedTempo: TempoRange?
    var suggestedMood: String? // e.g., "Upbeat", "Reflective"
    var transitionNotes: String? // How to transition into this section

    @Relationship(deleteRule: .nullify)
    var template: SetTemplate?

    init(
        orderIndex: Int,
        sectionName: String,
        songSlotCount: Int = 1
    ) {
        self.id = UUID()
        self.orderIndex = orderIndex
        self.sectionName = sectionName
        self.songSlotCount = songSlotCount
    }
}

enum TempoRange: String, Codable, CaseIterable {
    case slow = "Slow (60-80 BPM)"
    case moderate = "Moderate (80-120 BPM)"
    case upbeat = "Upbeat (120-140 BPM)"
    case fast = "Fast (140+ BPM)"
    case any = "Any Tempo"

    var bpmRange: ClosedRange<Int> {
        switch self {
        case .slow: return 60...80
        case .moderate: return 80...120
        case .upbeat: return 120...140
        case .fast: return 140...200
        case .any: return 40...200
        }
    }
}

// MARK: - Common Template Presets

struct TemplatePreset {
    let name: String
    let category: TemplateCategory
    let description: String
    let sections: [(name: String, slots: Int, duration: Int?)]

    static let commonPresets: [TemplatePreset] = [
        TemplatePreset(
            name: "Sunday Worship Service",
            category: .worship,
            description: "Traditional Sunday morning worship flow",
            sections: [
                ("Opening/Welcome", 1, 4),
                ("Fast Worship", 2, 10),
                ("Transition", 1, 4),
                ("Slow Worship", 2, 10),
                ("Offering/Response", 1, 4),
                ("Closing", 1, 4)
            ]
        ),
        TemplatePreset(
            name: "Contemporary Worship",
            category: .worship,
            description: "Modern worship service format",
            sections: [
                ("Call to Worship", 1, 4),
                ("Celebration", 3, 12),
                ("Prayer & Reflection", 2, 8),
                ("Response", 1, 4)
            ]
        ),
        TemplatePreset(
            name: "Band Rehearsal",
            category: .rehearsal,
            description: "Standard band practice session",
            sections: [
                ("Warm-up", 2, 15),
                ("New Material", 3, 30),
                ("Polish Existing", 3, 30),
                ("Full Run-through", 1, 15)
            ]
        ),
        TemplatePreset(
            name: "Concert Setlist",
            category: .concert,
            description: "Full concert performance",
            sections: [
                ("Opening", 1, 5),
                ("High Energy Set", 4, 20),
                ("Mid-tempo Break", 2, 10),
                ("Peak Moment", 2, 10),
                ("Encore", 1, 5)
            ]
        ),
        TemplatePreset(
            name: "Youth Service",
            category: .worship,
            description: "High-energy youth worship",
            sections: [
                ("Energizer", 2, 8),
                ("Worship Set", 3, 12),
                ("Response", 1, 4)
            ]
        )
    ]
}

// MARK: - Template Application

struct TemplateApplication {
    let template: SetTemplate
    let targetSetID: UUID

    /// Apply template to create/modify a performance set
    func apply(to performanceSet: PerformanceSet, replacing: Bool = false) -> [TemplateSection] {
        // Returns sections that need songs to be assigned
        return template.sortedSections ?? []
    }
}
