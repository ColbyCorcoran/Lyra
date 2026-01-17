import SwiftData
import Foundation

@Model
final class SetEntry {
    var id: UUID

    var song: Song?

    var performanceSet: PerformanceSet?

    var orderIndex: Int // Position in set

    // Per-set overrides (different from song defaults)
    var keyOverride: String? // Different key for this set
    var capoOverride: Int?
    var tempoOverride: Int?
    var autoscrollDurationOverride: Int?
    var notes: String? // Notes specific to this performance

    init(song: Song, orderIndex: Int) {
        self.id = UUID()
        self.song = song
        self.orderIndex = orderIndex
    }
}
