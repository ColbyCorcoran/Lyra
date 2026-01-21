//
//  AutoscrollConfiguration.swift
//  Lyra
//
//  Advanced autoscroll configuration models
//

import Foundation
import SwiftData

// MARK: - Section Configuration

/// Configuration for how autoscroll behaves within a specific section
struct SectionAutoscrollConfig: Codable, Identifiable {
    let id: UUID
    let sectionId: UUID // References SongSection.id
    var speedMultiplier: Double // 0.5x to 2.0x speed for this section
    var pauseAtStart: Bool // Pause when entering this section
    var pauseDuration: TimeInterval? // Auto-resume after N seconds (nil = manual resume)
    var isEnabled: Bool // Skip this section if disabled

    init(
        sectionId: UUID,
        speedMultiplier: Double = 1.0,
        pauseAtStart: Bool = false,
        pauseDuration: TimeInterval? = nil,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.sectionId = sectionId
        self.speedMultiplier = max(0.5, min(2.0, speedMultiplier))
        self.pauseAtStart = pauseAtStart
        self.pauseDuration = pauseDuration
        self.isEnabled = isEnabled
    }
}

// MARK: - Timeline Recording

/// Recorded autoscroll pattern that can be played back
struct AutoscrollTimeline: Codable, Identifiable {
    let id: UUID
    var name: String
    var createdAt: Date
    var duration: TimeInterval
    var keyframes: [TimelineKeyframe]

    init(name: String, duration: TimeInterval, keyframes: [TimelineKeyframe] = []) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.duration = duration
        self.keyframes = keyframes.sorted { $0.timestamp < $1.timestamp }
    }

    /// Get progress at a specific time
    func progress(at time: TimeInterval) -> Double {
        guard !keyframes.isEmpty else { return 0 }

        // Before first keyframe
        if time <= keyframes.first!.timestamp {
            return keyframes.first!.progress
        }

        // After last keyframe
        if time >= keyframes.last!.timestamp {
            return keyframes.last!.progress
        }

        // Find surrounding keyframes and interpolate
        for i in 0..<(keyframes.count - 1) {
            let current = keyframes[i]
            let next = keyframes[i + 1]

            if time >= current.timestamp && time <= next.timestamp {
                let t = (time - current.timestamp) / (next.timestamp - current.timestamp)
                return current.progress + (next.progress - current.progress) * t
            }
        }

        return 0
    }
}

/// A recorded point in time during autoscroll
struct TimelineKeyframe: Codable, Identifiable {
    let id: UUID
    let timestamp: TimeInterval // Time from start (seconds)
    let progress: Double // Scroll progress 0.0 to 1.0
    let speedMultiplier: Double // Speed at this point

    init(timestamp: TimeInterval, progress: Double, speedMultiplier: Double = 1.0) {
        self.id = UUID()
        self.timestamp = timestamp
        self.progress = max(0, min(1, progress))
        self.speedMultiplier = max(0.5, min(2.0, speedMultiplier))
    }
}

// MARK: - Autoscroll Preset

/// Named preset for autoscroll settings that can be quickly applied
struct AutoscrollPreset: Codable, Identifiable {
    let id: UUID
    var name: String
    var createdAt: Date
    var defaultDuration: TimeInterval
    var defaultSpeed: Double
    var sectionConfigs: [SectionAutoscrollConfig]
    var timeline: AutoscrollTimeline?
    var useTimeline: Bool
    var loopAtEnd: Bool

    init(
        name: String,
        defaultDuration: TimeInterval = 180,
        defaultSpeed: Double = 1.0,
        sectionConfigs: [SectionAutoscrollConfig] = [],
        timeline: AutoscrollTimeline? = nil,
        useTimeline: Bool = false,
        loopAtEnd: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.defaultDuration = defaultDuration
        self.defaultSpeed = max(0.5, min(2.0, defaultSpeed))
        self.sectionConfigs = sectionConfigs
        self.timeline = timeline
        self.useTimeline = useTimeline
        self.loopAtEnd = loopAtEnd
    }
}

// MARK: - Song Extension

extension Song {
    /// Get advanced autoscroll configuration
    var autoscrollConfiguration: AdvancedAutoscrollConfig? {
        get {
            guard let data = autoscrollConfigData else { return nil }
            return try? JSONDecoder().decode(AdvancedAutoscrollConfig.self, from: data)
        }
        set {
            autoscrollConfigData = try? JSONEncoder().encode(newValue)
        }
    }
}

/// Complete advanced autoscroll configuration for a song
struct AdvancedAutoscrollConfig: Codable {
    var sectionConfigs: [SectionAutoscrollConfig]
    var presets: [AutoscrollPreset]
    var activePresetId: UUID?
    var recordedTimelines: [AutoscrollTimeline]
    var markers: [AutoscrollMarker]

    init(
        sectionConfigs: [SectionAutoscrollConfig] = [],
        presets: [AutoscrollPreset] = [],
        activePresetId: UUID? = nil,
        recordedTimelines: [AutoscrollTimeline] = [],
        markers: [AutoscrollMarker] = []
    ) {
        self.sectionConfigs = sectionConfigs
        self.presets = presets
        self.activePresetId = activePresetId
        self.recordedTimelines = recordedTimelines
        self.markers = markers
    }

    /// Get configuration for a specific section
    func config(for sectionId: UUID) -> SectionAutoscrollConfig? {
        sectionConfigs.first { $0.sectionId == sectionId }
    }

    /// Get active preset
    func activePreset() -> AutoscrollPreset? {
        guard let id = activePresetId else { return nil }
        return presets.first { $0.id == id }
    }
}

// MARK: - Marker

/// Smart pause marker that can be placed anywhere in the song
struct AutoscrollMarker: Codable, Identifiable {
    let id: UUID
    var name: String
    var progress: Double // Position in song 0.0 to 1.0
    var pauseDuration: TimeInterval? // Auto-resume after N seconds (nil = manual)
    var action: MarkerAction

    init(
        name: String,
        progress: Double,
        pauseDuration: TimeInterval? = nil,
        action: MarkerAction = .pause
    ) {
        self.id = UUID()
        self.name = name
        self.progress = max(0, min(1, progress))
        self.pauseDuration = pauseDuration
        self.action = action
    }
}

enum MarkerAction: String, Codable, CaseIterable {
    case pause = "Pause"
    case speedChange = "Speed Change"
    case notification = "Notification"

    var displayName: String {
        rawValue
    }
}
