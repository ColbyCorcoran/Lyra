//
//  Performance.swift
//  Lyra
//
//  Track individual song performances with detailed metadata
//

import Foundation
import SwiftData

@Model
final class Performance {
    var id: UUID = UUID()
    var performanceDate: Date = Date()
    var duration: TimeInterval? // How long the song was displayed (in seconds)

    // Performance context
    var venue: String?
    var notes: String?

    // Song state during performance
    var usedAutoscroll: Bool = false
    var autoscrollDuration: Int? // Duration in seconds if autoscroll was used
    var transposeSemitones: Int = 0 // How much the song was transposed
    var capoFret: Int? // Capo position used
    var key: String? // Key performed in (after transpose/capo)
    var tempo: Int? // Tempo/BPM used

    // Relationships
    var song: Song?
    var setPerformance: SetPerformance? // If part of a set performance

    init(
        song: Song? = nil,
        performanceDate: Date = Date(),
        duration: TimeInterval? = nil,
        venue: String? = nil,
        notes: String? = nil,
        usedAutoscroll: Bool = false,
        autoscrollDuration: Int? = nil,
        transposeSemitones: Int = 0,
        capoFret: Int? = nil,
        key: String? = nil,
        tempo: Int? = nil
    ) {
        self.song = song
        self.performanceDate = performanceDate
        self.duration = duration
        self.venue = venue
        self.notes = notes
        self.usedAutoscroll = usedAutoscroll
        self.autoscrollDuration = autoscrollDuration
        self.transposeSemitones = transposeSemitones
        self.capoFret = capoFret
        self.key = key
        self.tempo = tempo
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: performanceDate)
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: performanceDate)
    }
}

@Model
final class SetPerformance {
    var id: UUID = UUID()
    var performanceDate: Date = Date()
    var duration: TimeInterval? // Total set duration

    // Performance context
    var venue: String?
    var notes: String?
    var audience: String? // e.g., "Wedding - 120 guests", "Church service", "Therapy session"

    // Relationships
    var performanceSet: PerformanceSet?
    @Relationship(deleteRule: .cascade, inverse: \Performance.setPerformance)
    var songPerformances: [Performance]? // Individual song performances

    // Metadata
    var totalSongsInSet: Int = 0
    var songsPerformed: Int = 0 // How many songs were actually performed
    var songsSkipped: Int = 0

    init(
        performanceSet: PerformanceSet? = nil,
        performanceDate: Date = Date(),
        duration: TimeInterval? = nil,
        venue: String? = nil,
        notes: String? = nil,
        audience: String? = nil
    ) {
        self.performanceSet = performanceSet
        self.performanceDate = performanceDate
        self.duration = duration
        self.venue = venue
        self.notes = notes
        self.audience = audience

        if let set = performanceSet {
            self.totalSongsInSet = set.songEntries?.count ?? 0
        }
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: performanceDate)
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: performanceDate)
    }

    var completionPercentage: Double {
        guard totalSongsInSet > 0 else { return 0 }
        return Double(songsPerformed) / Double(totalSongsInSet)
    }
}
