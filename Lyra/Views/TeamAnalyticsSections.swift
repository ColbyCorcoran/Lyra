//
//  TeamAnalyticsSections.swift
//  Lyra
//
//  Supporting views for team analytics dashboard sections
//

import SwiftUI

// MARK: - Contributors Section

struct ContributorsSection: View {
    let analytics: TeamAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contributor Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if analytics.contributorStats.isEmpty {
                ContentUnavailableView(
                    "No Contributors Yet",
                    systemImage: "person.3",
                    description: Text("Invite team members to start collaborating")
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(analytics.contributorStats) { contributor in
                        ContributorCard(contributor: contributor)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ContributorCard: View {
    let contributor: ContributorStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(contributor.displayName.prefix(1))
                            .foregroundStyle(.white)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(contributor.displayName)
                        .font(.headline)

                    if let lastActive = contributor.lastActiveAt {
                        Text("Last active \(lastActive, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let joined = contributor.joinedAt {
                        Text("Joined \(joined, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            Divider()

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatItem(
                    title: "Songs Added",
                    value: "\(contributor.songsAdded)",
                    icon: "plus.circle.fill",
                    color: .green
                )

                StatItem(
                    title: "Edits",
                    value: "\(contributor.editsCount)",
                    icon: "pencil.circle.fill",
                    color: .blue
                )

                StatItem(
                    title: "Comments",
                    value: "\(contributor.commentsCount)",
                    icon: "bubble.left.fill",
                    color: .purple
                )
            }

            // Most collaborated songs
            if !contributor.mostCollaboratedSongs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Most Collaborated Songs")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(contributor.mostCollaboratedSongs, id: \.self) { songTitle in
                        HStack {
                            Image(systemName: "music.note")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(songTitle)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Health Section

struct HealthSection: View {
    let analytics: TeamAnalytics

    @State private var selectedHealthCategory: HealthCategory = .stale

    enum HealthCategory: String, CaseIterable {
        case stale = "Stale"
        case comments = "Comments"
        case conflicts = "Conflicts"
        case metadata = "Metadata"

        var icon: String {
            switch self {
            case .stale: return "clock.arrow.circlepath"
            case .comments: return "bubble.left.and.bubble.right"
            case .conflicts: return "exclamationmark.octagon"
            case .metadata: return "info.circle"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Library Health")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            // Cleanup suggestions
            if !analytics.cleanupSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cleanup Suggestions")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(analytics.cleanupSuggestions) { suggestion in
                        CleanupSuggestionCard(suggestion: suggestion)
                    }
                    .padding(.horizontal)
                }
            }

            // Health category picker
            Picker("Health Category", selection: $selectedHealthCategory) {
                ForEach(HealthCategory.allCases, id: \.self) { category in
                    Label(category.rawValue, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Songs list based on selected category
            let songs: [SongHealth]
            switch selectedHealthCategory {
            case .stale:
                songs = analytics.staleSongs
            case .comments:
                songs = analytics.songsWithUnresolvedComments
            case .conflicts:
                songs = analytics.songsWithConflicts
            case .metadata:
                songs = analytics.songsMissingMetadata
            }

            if songs.isEmpty {
                ContentUnavailableView(
                    "All Clear",
                    systemImage: "checkmark.circle.fill",
                    description: Text("No issues in this category")
                )
                .foregroundStyle(.green)
            } else {
                VStack(spacing: 8) {
                    ForEach(songs) { song in
                        SongHealthCard(song: song)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CleanupSuggestionCard: View {
    let suggestion: CleanupSuggestion

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: priorityIcon)
                .font(.title2)
                .foregroundStyle(priorityColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(suggestion.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(suggestion.actionCount)")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(priorityColor)
                .clipShape(Capsule())
        }
        .padding()
        .background(priorityColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var priorityIcon: String {
        switch suggestion.priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        }
    }

    private var priorityColor: Color {
        switch suggestion.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct SongHealthCard: View {
    let song: SongHealth

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .foregroundStyle(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let days = song.daysSinceLastEdit {
                    Text("\(days) days since last edit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let count = song.unresolvedCommentCount {
                    Text("\(count) unresolved comments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let fields = song.missingFields {
                    Text("Missing: \(fields.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Activity Section

struct ActivitySection: View {
    let analytics: TeamAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity & Trends")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            // Activity heatmap
            if !analytics.activityHeatmap.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Heatmap (Last 90 Days)")
                        .font(.headline)
                        .padding(.horizontal)

                    ActivityHeatmapView(activityDays: analytics.activityHeatmap)
                        .padding(.horizontal)
                }
            }

            // Contribution trends
            if !analytics.contributionTrends.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contribution Trends")
                        .font(.headline)
                        .padding(.horizontal)

                    ContributionTrendsChart(trends: analytics.contributionTrends)
                        .frame(height: 200)
                        .padding(.horizontal)
                }
            }

            // Busiest days
            if !analytics.activityHeatmap.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Busiest Days")
                        .font(.headline)
                        .padding(.horizontal)

                    let busiestDays = analytics.activityHeatmap
                        .sorted { $0.activityCount > $1.activityCount }
                        .prefix(5)

                    VStack(spacing: 8) {
                        ForEach(busiestDays) { day in
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading) {
                                    Text(day.date, style: .date)
                                        .font(.subheadline)

                                    Text("\(day.activityCount) activities · \(day.contributors.count) contributors")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct ActivityHeatmapView: View {
    let activityDays: [ActivityDay]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(activityDays) { day in
                Rectangle()
                    .fill(colorForActivity(day.activityCount))
                    .frame(height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay {
                        if day.activityCount > 0 {
                            Text("\(day.activityCount)")
                                .font(.caption2)
                                .foregroundStyle(.white)
                        }
                    }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForActivity(_ count: Int) -> Color {
        switch count {
        case 0: return Color(.systemGray5)
        case 1...3: return .green.opacity(0.3)
        case 4...7: return .green.opacity(0.6)
        default: return .green
        }
    }
}

struct ContributionTrendsChart: View {
    let trends: [TrendPoint]

    var body: some View {
        GeometryReader { geometry in
            let maxValue = trends.map { $0.value }.max() ?? 1
            let xStep = geometry.size.width / CGFloat(max(trends.count - 1, 1))

            ZStack(alignment: .bottomLeading) {
                // Area fill
                Path { path in
                    guard !trends.isEmpty else { return }

                    path.move(to: CGPoint(x: 0, y: geometry.size.height))

                    for (index, point) in trends.enumerated() {
                        let x = CGFloat(index) * xStep
                        let y = geometry.size.height - (CGFloat(point.value / maxValue) * geometry.size.height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: CGFloat(trends.count - 1) * xStep, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                ))

                // Line
                Path { path in
                    guard !trends.isEmpty else { return }

                    for (index, point) in trends.enumerated() {
                        let x = CGFloat(index) * xStep
                        let y = geometry.size.height - (CGFloat(point.value / maxValue) * geometry.size.height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)

                // Points
                ForEach(Array(trends.enumerated()), id: \.offset) { index, point in
                    let x = CGFloat(index) * xStep
                    let y = geometry.size.height - (CGFloat(point.value / maxValue) * geometry.size.height)

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Popularity Section

struct PopularitySection: View {
    let analytics: TeamAnalytics

    @State private var selectedPopularityCategory: PopularityCategory = .viewed

    enum PopularityCategory: String, CaseIterable {
        case viewed = "Most Viewed"
        case edited = "Most Edited"
        case commented = "Most Commented"
        case performed = "Most Performed"

        var icon: String {
            switch self {
            case .viewed: return "eye.fill"
            case .edited: return "pencil.circle.fill"
            case .commented: return "bubble.left.fill"
            case .performed: return "music.mic"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Song Popularity")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            // Category picker
            Picker("Popularity Category", selection: $selectedPopularityCategory) {
                ForEach(PopularityCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Songs list
            let songs: [SongPopularity]
            switch selectedPopularityCategory {
            case .viewed:
                songs = analytics.mostViewedSongs
            case .edited:
                songs = analytics.mostEditedSongs
            case .commented:
                songs = analytics.mostCommentedSongs
            case .performed:
                songs = analytics.mostPerformedSongs
            }

            if songs.isEmpty {
                ContentUnavailableView(
                    "No Data Yet",
                    systemImage: selectedPopularityCategory.icon,
                    description: Text("Start using your library to see popular songs")
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                        SongPopularityCard(song: song, rank: index + 1)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SongPopularityCard: View {
    let song: SongPopularity
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(rankColor)
                .clipShape(Circle())

            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(song.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Count badge
            Text("\(song.count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(rankColor)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}
