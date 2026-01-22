//
//  ActivityFeedView.swift
//  Lyra
//
//  Shows recent collaborative activities grouped by time periods
//

import SwiftUI
import SwiftData

struct ActivityFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemberActivity.timestamp, order: .reverse) private var allActivities: [MemberActivity]

    @State private var selectedFilter: ActivityFilter = .all
    @State private var selectedUser: String?
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                filterBar

                // Activity list
                if filteredActivities.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
            .navigationTitle("Activity Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            clearOldActivities()
                        } label: {
                            Label("Clear Old Activities", systemImage: "trash")
                        }

                        Button {
                            exportActivities()
                        } label: {
                            Label("Export Activity Log", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search activities")
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ActivityFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Activity List

    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedActivities.keys.sorted(), id: \.self) { period in
                    Section {
                        ForEach(groupedActivities[period] ?? []) { activity in
                            ActivityRow(activity: activity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleActivityTap(activity)
                                }
                        }
                    } header: {
                        SectionHeader(title: period.displayName)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("No Activity Yet")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Collaborative activities will appear here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredActivities: [MemberActivity] {
        var activities = allActivities

        // Apply search filter
        if !searchText.isEmpty {
            activities = activities.filter { activity in
                activity.displayText.localizedCaseInsensitiveContains(searchText) ||
                (activity.songTitle?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .songs:
            activities = activities.filter {
                [.songCreated, .songEdited, .songDeleted, .songViewed].contains($0.activityType)
            }
        case .members:
            activities = activities.filter {
                [.memberJoined, .memberLeft, .permissionChanged].contains($0.activityType)
            }
        case .settings:
            activities = activities.filter {
                $0.activityType == .librarySettingsChanged
            }
        }

        // Apply user filter
        if let selectedUser = selectedUser {
            activities = activities.filter { $0.userRecordID == selectedUser }
        }

        return activities
    }

    private var groupedActivities: [TimePeriod: [MemberActivity]] {
        Dictionary(grouping: filteredActivities) { activity in
            TimePeriod.from(date: activity.timestamp)
        }
    }

    // MARK: - Actions

    private func handleActivityTap(_ activity: MemberActivity) {
        // Navigate to related content
        if let songID = activity.songID {
            // Post notification to navigate to song
            NotificationCenter.default.post(
                name: .navigateToSong,
                object: nil,
                userInfo: ["songID": songID]
            )
        }
    }

    private func clearOldActivities() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        let oldActivities = allActivities.filter { $0.timestamp < thirtyDaysAgo }

        for activity in oldActivities {
            modelContext.delete(activity)
        }

        try? modelContext.save()
    }

    private func exportActivities() {
        // Export activity log as CSV or JSON
        let csvContent = generateCSV(from: filteredActivities)

        // Share sheet
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("activity_log_\(Date().timeIntervalSince1970).csv")

        try? csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

        // Share using UIActivityViewController wrapper
        // (Implementation would use a UIViewControllerRepresentable)
    }

    private func generateCSV(from activities: [MemberActivity]) -> String {
        var csv = "Timestamp,User,Activity,Song,Details\n"

        for activity in activities {
            let row = [
                ISO8601DateFormatter().string(from: activity.timestamp),
                activity.displayName ?? "Unknown",
                activity.activityType.rawValue,
                activity.songTitle ?? "",
                activity.details ?? ""
            ].map { "\"\($0)\"" }.joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: MemberActivity

    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            Circle()
                .fill(Color(activity.color).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: activity.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(activity.color))
                }

            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text(activity.relativeTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let details = activity.details {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Material.thin)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.blue : Color(.systemGray6)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Types

enum ActivityFilter: CaseIterable {
    case all
    case songs
    case members
    case settings

    var title: String {
        switch self {
        case .all: return "All"
        case .songs: return "Songs"
        case .members: return "Members"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .songs: return "music.note"
        case .members: return "person.2"
        case .settings: return "gearshape"
        }
    }
}

enum TimePeriod: Comparable {
    case today
    case yesterday
    case thisWeek
    case lastWeek
    case thisMonth
    case older

    static func from(date: Date) -> TimePeriod {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return .today
        } else if calendar.isDateInYesterday(date) {
            return .yesterday
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return .thisWeek
        } else if let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now),
                  calendar.isDate(date, equalTo: weekAgo, toGranularity: .weekOfYear) {
            return .lastWeek
        } else if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return .thisMonth
        } else {
            return .older
        }
    }

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "This Week"
        case .lastWeek: return "Last Week"
        case .thisMonth: return "This Month"
        case .older: return "Older"
        }
    }

    static func < (lhs: TimePeriod, rhs: TimePeriod) -> Bool {
        let order: [TimePeriod] = [.today, .yesterday, .thisWeek, .lastWeek, .thisMonth, .older]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Color Extension

extension Color {
    init(_ colorName: String) {
        switch colorName.lowercased() {
        case "red": self = .red
        case "green": self = .green
        case "blue": self = .blue
        case "orange": self = .orange
        case "yellow": self = .yellow
        case "purple": self = .purple
        case "pink": self = .pink
        case "gray": self = .gray
        default: self = .blue
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let navigateToSong = Notification.Name("navigateToSong")
}

// MARK: - Preview

#Preview {
    ActivityFeedView()
        .modelContainer(for: [MemberActivity.self], inMemory: true)
}
