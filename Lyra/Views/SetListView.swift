//
//  SetListView.swift
//  Lyra
//
//  List view for all performance sets with grouping and filtering
//

import SwiftUI
import SwiftData

enum SetSortOption: String, CaseIterable {
    case date = "Date"
    case name = "Name"
    case modified = "Recently Modified"

    var icon: String {
        switch self {
        case .date: return "calendar"
        case .name: return "textformat.abc"
        case .modified: return "clock"
        }
    }
}

struct SetListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var allSets: [PerformanceSet]

    @State private var showAddSetSheet: Bool = false
    @State private var showArchived: Bool = false
    @State private var selectedSort: SetSortOption = .date
    @State private var searchText: String = ""

    private var filteredSets: [PerformanceSet] {
        var result = allSets

        // Apply archived filter
        result = result.filter { showArchived || !$0.isArchived }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { set in
                set.name.localizedCaseInsensitiveContains(searchText) ||
                (set.setDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (set.venue?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (set.folder?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result
    }

    private var sortedSets: [PerformanceSet] {
        var sets = filteredSets

        switch selectedSort {
        case .date:
            sets.sort { (set1, set2) in
                guard let date1 = set1.scheduledDate else { return false }
                guard let date2 = set2.scheduledDate else { return true }
                return date1 > date2
            }
        case .name:
            sets.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .modified:
            sets.sort { $0.modifiedAt > $1.modifiedAt }
        }

        return sets
    }

    private var upcomingSets: [PerformanceSet] {
        sortedSets.filter { set in
            guard let date = set.scheduledDate else { return false }
            return date >= Calendar.current.startOfDay(for: Date())
        }
    }

    private var pastSets: [PerformanceSet] {
        sortedSets.filter { set in
            guard let date = set.scheduledDate else { return true }
            return date < Calendar.current.startOfDay(for: Date())
        }
    }

    var body: some View {
        Group {
            if filteredSets.isEmpty {
                if showArchived && allSets.allSatisfy({ !$0.isArchived }) {
                    // No archived sets
                    VStack(spacing: 16) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No Archived Sets")
                            .font(.headline)

                        Text("Archived sets will appear here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    EnhancedSetEmptyStateView(showAddSetSheet: $showAddSetSheet)
                }
            } else {
                setListContent
            }
        }
        .searchable(text: $searchText, prompt: "Search sets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort By", selection: $selectedSort) {
                        ForEach(SetSortOption.allCases, id: \.self) { option in
                            Label(option.rawValue, systemImage: option.icon)
                                .tag(option)
                        }
                    }

                    Divider()

                    Toggle("Show Archived", isOn: $showArchived)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Sort and filter options")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSetSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add set")
                .accessibilityHint("Create a new performance set")
            }
        }
        .sheet(isPresented: $showAddSetSheet) {
            AddPerformanceSetView()
        }
    }

    // MARK: - Set List Content

    @ViewBuilder
    private var setListContent: some View {
        List {
            // Upcoming sets section
            if !upcomingSets.isEmpty {
                Section {
                    ForEach(upcomingSets) { performanceSet in
                        NavigationLink(destination: SetDetailView(performanceSet: performanceSet)) {
                            SetRowView(performanceSet: performanceSet)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !performanceSet.isArchived {
                                Button {
                                    HapticManager.shared.swipeAction()
                                    archiveSet(performanceSet)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.orange)
                            }

                            Button(role: .destructive) {
                                HapticManager.shared.swipeAction()
                                deleteSet(performanceSet)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Upcoming")
                }
            }

            // Past sets section
            if !pastSets.isEmpty {
                Section {
                    ForEach(pastSets) { performanceSet in
                        NavigationLink(destination: SetDetailView(performanceSet: performanceSet)) {
                            SetRowView(performanceSet: performanceSet)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !performanceSet.isArchived {
                                Button {
                                    HapticManager.shared.swipeAction()
                                    archiveSet(performanceSet)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.orange)
                            }

                            Button(role: .destructive) {
                                HapticManager.shared.swipeAction()
                                deleteSet(performanceSet)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(upcomingSets.isEmpty ? "Sets" : "Past")
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func archiveSet(_ set: PerformanceSet) {
        set.isArchived = true
        set.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("❌ Error archiving set: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    private func deleteSet(_ set: PerformanceSet) {
        modelContext.delete(set)

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("❌ Error deleting set: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Enhanced Set Empty State View

struct EnhancedSetEmptyStateView: View {
    @Binding var showAddSetSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: showAddSetSheet)
            }

            VStack(spacing: 12) {
                Text("No Sets Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create performance sets to organize songs for specific events, services, or gigs. Sets maintain song order and can include per-song overrides.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Create first set button
            Button {
                showAddSetSheet = true
            } label: {
                Label("Create Your First Set", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Set Row View

struct SetRowView: View {
    let performanceSet: PerformanceSet

    private var songCount: Int {
        performanceSet.songEntries?.count ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // Set name
                HStack(spacing: 8) {
                    Text(performanceSet.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if performanceSet.isArchived {
                        Image(systemName: "archivebox.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

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

                // Folder and song count
                HStack(spacing: 8) {
                    if let folder = performanceSet.folder, !folder.isEmpty {
                        Label(folder, systemImage: "folder")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Text("\(songCount) \(songCount == 1 ? "song" : "songs")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
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
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// MARK: - Previews

#Preview("Sets List with Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, Song.self, SetEntry.self, configurations: config)

    // Create upcoming set
    let upcomingSet = PerformanceSet(name: "Sunday Morning Worship", scheduledDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()))
    upcomingSet.venue = "Main Sanctuary"
    upcomingSet.folder = "Church"

    // Create past set
    let pastSet = PerformanceSet(name: "Christmas Service", scheduledDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()))
    pastSet.venue = "Chapel"

    container.mainContext.insert(upcomingSet)
    container.mainContext.insert(pastSet)

    return NavigationStack {
        SetListView()
    }
    .modelContainer(container)
}

#Preview("Empty Sets List") {
    NavigationStack {
        SetListView()
    }
    .modelContainer(for: PerformanceSet.self, inMemory: true)
}

#Preview("Set Row") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, Song.self, SetEntry.self, configurations: config)

    let performanceSet = PerformanceSet(name: "Sunday Morning Service", scheduledDate: Date())
    performanceSet.venue = "Main Sanctuary"
    performanceSet.folder = "Church"

    let song1 = Song(title: "Amazing Grace", artist: "Traditional")
    let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg")

    let entry1 = SetEntry(song: song1, orderIndex: 0)
    entry1.performanceSet = performanceSet
    let entry2 = SetEntry(song: song2, orderIndex: 1)
    entry2.performanceSet = performanceSet

    performanceSet.songEntries = [entry1, entry2]

    container.mainContext.insert(performanceSet)
    container.mainContext.insert(song1)
    container.mainContext.insert(song2)
    container.mainContext.insert(entry1)
    container.mainContext.insert(entry2)

    return List {
        SetRowView(performanceSet: performanceSet)
    }
    .modelContainer(container)
}
