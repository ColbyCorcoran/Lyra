//
//  SetListView.swift
//  Lyra
//
//  List view for all sets
//

import SwiftUI
import SwiftData

struct SetListView: View {
    @Query(
        filter: #Predicate<PerformanceSet> { set in
            set.isArchived == false
        },
        sort: \PerformanceSet.scheduledDate,
        order: .reverse
    ) private var sets: [PerformanceSet]

    var body: some View {
        Group {
            if sets.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Sets Yet",
                    message: "Create a set to organize songs for your next performance or worship service"
                )
            } else {
                List {
                    ForEach(sets) { performanceSet in
                        NavigationLink(destination: SetDetailView(performanceSet: performanceSet)) {
                            SetRowView(performanceSet: performanceSet)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Set Row View

struct SetRowView: View {
    let performanceSet: PerformanceSet

    private var songCount: Int {
        performanceSet.songEntries?.count ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Set name
            Text(performanceSet.name)
                .font(.headline)
                .foregroundStyle(.primary)

            // Date and venue
            HStack(spacing: 8) {
                if let date = performanceSet.scheduledDate {
                    Label(
                        formatDate(date),
                        systemImage: "calendar"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                if let venue = performanceSet.venue, !venue.isEmpty {
                    Label(venue, systemImage: "location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // Song count
            Text("\(songCount) \(songCount == 1 ? "song" : "songs")")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        // Show "Today" or "Tomorrow" for recent dates
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            return formatter.string(from: date)
        }
    }
}

// MARK: - Previews

#Preview("Sets List with Data") {
    NavigationStack {
        SetListView()
    }
    .modelContainer(PreviewContainer.shared.container)
}

#Preview("Empty Sets List") {
    NavigationStack {
        SetListView()
    }
    .modelContainer(for: PerformanceSet.self, inMemory: true)
}

#Preview("Set Row") {
    @Previewable @State var performanceSet = {
        let performanceSet = PerformanceSet(name: "Sunday Morning Service", scheduledDate: Date())
        performanceSet.venue = "Main Sanctuary"

        // Create sample songs
        let song1 = Song(title: "Amazing Grace", artist: "Traditional")
        let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg")

        let entry1 = SetEntry(song: song1, orderIndex: 0)
        entry1.performanceSet = performanceSet
        let entry2 = SetEntry(song: song2, orderIndex: 1)
        entry2.performanceSet = performanceSet

        performanceSet.songEntries = [entry1, entry2]
        return performanceSet
    }()

    List {
        SetRowView(performanceSet: performanceSet)
    }
}
