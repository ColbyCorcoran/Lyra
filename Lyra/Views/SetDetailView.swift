//
//  SetDetailView.swift
//  Lyra
//
//  Detail view for a set (placeholder)
//

import SwiftUI

struct SetDetailView: View {
    let performanceSet: PerformanceSet

    private var entries: [SetEntry] {
        (performanceSet.songEntries ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        List {
            // Set info section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if let date = performanceSet.scheduledDate {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(formatDate(date))
                        }
                    }

                    if let venue = performanceSet.venue, !venue.isEmpty {
                        HStack {
                            Image(systemName: "location")
                                .foregroundStyle(.secondary)
                            Text(venue)
                        }
                    }

                    if let notes = performanceSet.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(notes)
                                .font(.body)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Songs section
            Section("Songs (\(entries.count))") {
                if entries.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)

                            Text("No songs in this set")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(entries) { entry in
                        if let song = entry.song {
                            NavigationLink(destination: SongDetailView(song: song)) {
                                SetEntryRowView(entry: entry, song: song)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(performanceSet.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Set Entry Row View

struct SetEntryRowView: View {
    let entry: SetEntry
    let song: Song

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Order number
            Text("\(entry.orderIndex + 1)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)

                if let artist = song.artist {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Show overrides
                HStack(spacing: 8) {
                    if let keyOverride = entry.keyOverride {
                        Label(keyOverride, systemImage: "music.note")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else if let key = song.originalKey {
                        Label(key, systemImage: "music.note")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if let notes = entry.notes, !notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var performanceSet = {
        let performanceSet = PerformanceSet(name: "Sunday Morning Service", scheduledDate: Date())
        performanceSet.venue = "Main Sanctuary"
        performanceSet.notes = "Start with worship, end with hymn"

        let song1 = Song(title: "Amazing Grace", artist: "Traditional", originalKey: "G")
        let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg", originalKey: "C")

        let entry1 = SetEntry(song: song1, orderIndex: 0)
        entry1.performanceSet = performanceSet
        let entry2 = SetEntry(song: song2, orderIndex: 1)
        entry2.performanceSet = performanceSet
        entry2.keyOverride = "D"

        performanceSet.songEntries = [entry1, entry2]
        return performanceSet
    }()

    NavigationStack {
        SetDetailView(performanceSet: performanceSet)
    }
}
