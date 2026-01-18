//
//  SetDetailView.swift
//  Lyra
//
//  Detail view for a performance set showing all songs and management options
//

import SwiftUI
import SwiftData

struct SetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode

    let performanceSet: PerformanceSet

    @State private var showSongPicker: Bool = false
    @State private var showEditSet: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    private var entries: [SetEntry] {
        (performanceSet.songEntries ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    private var songCount: Int {
        entries.count
    }

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        List {
            // Set info section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Date and venue
                    HStack(spacing: 16) {
                        if let date = performanceSet.scheduledDate {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(formatDate(date))
                                    .font(.subheadline)
                            }
                        }

                        if let venue = performanceSet.venue, !venue.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "location")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(venue)
                                    .font(.subheadline)
                            }
                        }
                    }

                    // Folder and song count
                    HStack(spacing: 16) {
                        if let folder = performanceSet.folder, !folder.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text(folder)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "music.note.list")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("\(songCount) \(songCount == 1 ? "song" : "songs")")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Description
                    if let description = performanceSet.setDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(description)
                                .font(.body)
                        }
                        .padding(.top, 4)
                    }

                    // Notes
                    if let notes = performanceSet.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(notes)
                                .font(.body)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
            }

            // Songs section
            Section {
                if entries.isEmpty {
                    SetEmptyStateView(showSongPicker: $showSongPicker)
                } else {
                    ForEach(entries) { entry in
                        if let song = entry.song {
                            NavigationLink(destination: SongDisplayView(song: song)) {
                                SetEntryRowView(entry: entry, song: song, isEditing: isEditing)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    HapticManager.shared.swipeAction()
                                    removeEntry(entry)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .onMove(perform: moveEntries)
                }
            } header: {
                Text("Songs")
            }
        }
        .navigationTitle(performanceSet.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !entries.isEmpty {
                    EditButton()
                        .accessibilityLabel(isEditing ? "Done reordering" : "Reorder songs")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showSongPicker = true
                    } label: {
                        Label("Add Songs", systemImage: "plus")
                    }

                    Button {
                        showEditSet = true
                    } label: {
                        Label("Edit Set", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Set", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Set options")
            }
        }
        .sheet(isPresented: $showSongPicker) {
            SongPickerForSetView(performanceSet: performanceSet)
        }
        .sheet(isPresented: $showEditSet) {
            EditPerformanceSetView(performanceSet: performanceSet)
        }
        .alert("Delete Set?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSet()
            }
        } message: {
            Text("This will permanently delete \"\(performanceSet.name)\". Songs will not be deleted.")
        }
    }

    // MARK: - Actions

    private func removeEntry(_ entry: SetEntry) {
        guard var setEntries = performanceSet.songEntries else { return }

        // Remove the entry
        setEntries.removeAll(where: { $0.id == entry.id })

        // Reindex remaining entries
        for (index, remainingEntry) in setEntries.enumerated() {
            remainingEntry.orderIndex = index
        }

        performanceSet.songEntries = setEntries
        performanceSet.modifiedAt = Date()

        // Delete the entry from context
        modelContext.delete(entry)

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("❌ Error removing song from set: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    private func deleteSet() {
        modelContext.delete(performanceSet)

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("❌ Error deleting set: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    private func moveEntries(from source: IndexSet, to destination: Int) {
        guard var setEntries = performanceSet.songEntries else { return }

        // Sort by orderIndex to ensure correct order
        setEntries.sort { $0.orderIndex < $1.orderIndex }

        // Move the entries
        setEntries.move(fromOffsets: source, toOffset: destination)

        // Reindex all entries to reflect new order
        for (index, entry) in setEntries.enumerated() {
            entry.orderIndex = index
        }

        performanceSet.songEntries = setEntries
        performanceSet.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.selection()
        } catch {
            print("❌ Error reordering songs: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Tomorrow at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Set Entry Row View

struct SetEntryRowView: View {
    let entry: SetEntry
    let song: Song
    var isEditing: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Order number with styling
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(entry.orderIndex + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)

                if let artist = song.artist {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Show overrides or default values
                HStack(spacing: 6) {
                    if let keyOverride = entry.keyOverride {
                        SongMetadataBadge(
                            icon: "music.note",
                            text: keyOverride,
                            color: .blue
                        )
                    } else if let key = song.originalKey {
                        SongMetadataBadge(
                            icon: "music.note",
                            text: key,
                            color: .blue
                        )
                    }

                    if let capoOverride = entry.capoOverride {
                        SongMetadataBadge(
                            icon: "guitars",
                            text: "Capo \(capoOverride)",
                            color: .orange
                        )
                    } else if let capo = song.capo, capo > 0 {
                        SongMetadataBadge(
                            icon: "guitars",
                            text: "Capo \(capo)",
                            color: .orange
                        )
                    }

                    if let notes = entry.notes, !notes.isEmpty {
                        SongMetadataBadge(
                            icon: "note.text",
                            text: "Notes",
                            color: .purple
                        )
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            // Show drag indicator when editing
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Set Empty State View

struct SetEmptyStateView: View {
    @Binding var showSongPicker: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Songs Yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Add songs to this set to build your performance lineup")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showSongPicker = true
            } label: {
                Label("Add Songs", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview("Set with Songs") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, Song.self, SetEntry.self, configurations: config)

    let performanceSet = PerformanceSet(name: "Sunday Morning Service", scheduledDate: Date())
    performanceSet.venue = "Main Sanctuary"
    performanceSet.folder = "Church"
    performanceSet.notes = "Start with worship, end with hymn"
    performanceSet.setDescription = "Weekly Sunday morning worship service"

    let song1 = Song(title: "Amazing Grace", artist: "John Newton", originalKey: "G")
    song1.capo = 2
    let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg", originalKey: "C")
    let song3 = Song(title: "It Is Well", artist: "Horatio Spafford", originalKey: "D")
    song3.capo = 4

    let entry1 = SetEntry(song: song1, orderIndex: 0)
    entry1.performanceSet = performanceSet
    let entry2 = SetEntry(song: song2, orderIndex: 1)
    entry2.performanceSet = performanceSet
    entry2.keyOverride = "D"
    let entry3 = SetEntry(song: song3, orderIndex: 2)
    entry3.performanceSet = performanceSet

    performanceSet.songEntries = [entry1, entry2, entry3]

    container.mainContext.insert(performanceSet)
    container.mainContext.insert(song1)
    container.mainContext.insert(song2)
    container.mainContext.insert(song3)
    container.mainContext.insert(entry1)
    container.mainContext.insert(entry2)
    container.mainContext.insert(entry3)

    return NavigationStack {
        SetDetailView(performanceSet: performanceSet)
    }
    .modelContainer(container)
}

#Preview("Empty Set") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, Song.self, SetEntry.self, configurations: config)

    let performanceSet = PerformanceSet(name: "New Set", scheduledDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()))
    performanceSet.venue = "Chapel"

    container.mainContext.insert(performanceSet)

    return NavigationStack {
        SetDetailView(performanceSet: performanceSet)
    }
    .modelContainer(container)
}
