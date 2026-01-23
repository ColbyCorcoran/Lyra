//
//  AnalyticsDashboardView.swift
//  Lyra
//
//  Comprehensive analytics dashboard showing performance statistics and insights
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Performance.performanceDate, order: .reverse) private var allPerformances: [Performance]
    @Query(sort: \SetPerformance.performanceDate, order: .reverse) private var allSetPerformances: [SetPerformance]
    @Query private var allSongs: [Song]
    @Query private var allSharedLibraries: [SharedLibrary]

    @State private var selectedTimeRange: TimeRange = .month
    @State private var showExportOptions: Bool = false
    @State private var showInsights: Bool = false
    @State private var selectedLibraryForAnalytics: SharedLibrary?
    @State private var showTeamAnalytics: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Team collaboration section (if there are shared libraries)
                    if !allSharedLibraries.isEmpty {
                        teamCollaborationSection
                    }

                    // Time range picker
                    timeRangePicker

                    if filteredPerformances.isEmpty {
                        emptyState
                    } else {
                        // Overview statistics
                        overviewSection

                        // Top performed songs
                        topSongsSection

                        // Key usage statistics
                        keyUsageSection

                        // Performance trends chart
                        performanceTrendsSection

                        // Set statistics
                        if !allSetPerformances.isEmpty {
                            setStatisticsSection
                        }

                        // Insights
                        insightsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showInsights = true
                        } label: {
                            Label("View Insights", systemImage: "lightbulb")
                        }

                        Button {
                            showExportOptions = true
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showInsights) {
                InsightsView(performances: filteredPerformances, songs: allSongs)
            }
            .sheet(isPresented: $showExportOptions) {
                PerformanceDataExportView(performances: filteredPerformances, setPerformances: filteredSetPerformances)
            }
            .sheet(isPresented: $showTeamAnalytics) {
                if let library = selectedLibraryForAnalytics {
                    TeamAnalyticsView(library: library)
                }
            }
        }
    }

    // MARK: - Team Collaboration Section

    private var teamCollaborationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.blue)
                Text("Team Collaboration")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(allSharedLibraries) { library in
                    Button {
                        selectedLibraryForAnalytics = library
                        showTeamAnalytics = true
                    } label: {
                        HStack {
                            Image(systemName: library.displayIcon)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.gradient)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(library.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                HStack(spacing: 12) {
                                    Label("\(library.memberCount) members", systemImage: "person.2.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Label("\(library.songCount) songs", systemImage: "music.note")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(.blue)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Performance Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Start performing songs in sets to see analytics and insights!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                OverviewCard(
                    title: "Total Performances",
                    value: "\(filteredPerformances.count)",
                    icon: "music.note",
                    color: .blue,
                    trend: performanceTrend
                )

                OverviewCard(
                    title: "Unique Songs",
                    value: "\(uniqueSongsCount)",
                    icon: "music.note.list",
                    color: .green
                )

                OverviewCard(
                    title: "Total Duration",
                    value: totalDuration,
                    icon: "clock",
                    color: .orange
                )

                OverviewCard(
                    title: "Avg per Song",
                    value: averageSongDuration,
                    icon: "timer",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Top Songs Section

    private var topSongsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Performed Songs")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Text("Last \(selectedTimeRange.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(Array(topSongs.prefix(10).enumerated()), id: \.element.song.id) { index, item in
                    TopSongRow(rank: index + 1, song: item.song, count: item.count)
                }
            }
        }
    }

    // MARK: - Key Usage Section

    private var keyUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Usage")
                .font(.title3)
                .fontWeight(.semibold)

            Chart(keyUsageData) { item in
                BarMark(
                    x: .value("Key", item.key),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(.blue.gradient)
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Performance Trends Section

    private var performanceTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trends")
                .font(.title3)
                .fontWeight(.semibold)

            Chart(performanceTrendData) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(.blue.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(.blue.gradient.opacity(0.3))
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Set Statistics Section

    private var setStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set Statistics")
                .font(.title3)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Sets Performed",
                    value: "\(filteredSetPerformances.count)",
                    icon: "music.note.list",
                    color: .blue
                )

                StatCard(
                    title: "Avg Set Duration",
                    value: averageSetDuration,
                    icon: "clock",
                    color: .green
                )

                StatCard(
                    title: "Completion Rate",
                    value: completionRate,
                    icon: "checkmark.circle",
                    color: .orange
                )

                StatCard(
                    title: "Avg Songs/Set",
                    value: averageSongsPerSet,
                    icon: "music.note",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Insights")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showInsights = true
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            VStack(spacing: 12) {
                ForEach(Array(quickInsights.prefix(3)), id: \.id) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredPerformances: [Performance] {
        let cutoffDate = selectedTimeRange.cutoffDate
        return allPerformances.filter { $0.performanceDate >= cutoffDate }
    }

    private var filteredSetPerformances: [SetPerformance] {
        let cutoffDate = selectedTimeRange.cutoffDate
        return allSetPerformances.filter { $0.performanceDate >= cutoffDate }
    }

    private var uniqueSongsCount: Int {
        Set(filteredPerformances.compactMap { $0.song?.id }).count
    }

    private var totalDuration: String {
        let total = filteredPerformances.compactMap { $0.duration }.reduce(0, +)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var averageSongDuration: String {
        let durations = filteredPerformances.compactMap { $0.duration }
        guard !durations.isEmpty else { return "N/A" }

        let avgSeconds = durations.reduce(0, +) / Double(durations.count)
        let minutes = Int(avgSeconds) / 60
        let seconds = Int(avgSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var averageSetDuration: String {
        let durations = filteredSetPerformances.compactMap { $0.duration }
        guard !durations.isEmpty else { return "N/A" }

        let avgSeconds = durations.reduce(0, +) / Double(durations.count)
        let minutes = Int(avgSeconds) / 60
        return "\(minutes)m"
    }

    private var completionRate: String {
        guard !filteredSetPerformances.isEmpty else { return "N/A" }

        let totalCompletion = filteredSetPerformances.map { $0.completionPercentage }.reduce(0, +)
        let avgCompletion = totalCompletion / Double(filteredSetPerformances.count)
        return String(format: "%.0f%%", avgCompletion * 100)
    }

    private var averageSongsPerSet: String {
        guard !filteredSetPerformances.isEmpty else { return "N/A" }

        let totalSongs = filteredSetPerformances.map { $0.songsPerformed }.reduce(0, +)
        let avg = Double(totalSongs) / Double(filteredSetPerformances.count)
        return String(format: "%.1f", avg)
    }

    private var performanceTrend: String? {
        guard filteredPerformances.count >= 2 else { return nil }

        let halfwayIndex = filteredPerformances.count / 2
        let recentCount = filteredPerformances.prefix(halfwayIndex).count
        let olderCount = filteredPerformances.suffix(filteredPerformances.count - halfwayIndex).count

        let change = ((Double(recentCount) - Double(olderCount)) / Double(olderCount)) * 100
        return String(format: "%+.0f%%", change)
    }

    private var topSongs: [(song: Song, count: Int)] {
        let songCounts = Dictionary(grouping: filteredPerformances.compactMap { $0.song }, by: { $0.id })
            .mapValues { $0.count }

        return songCounts.compactMap { (id, count) -> (Song, Int)? in
            guard let song = allSongs.first(where: { $0.id == id }) else { return nil }
            return (song, count)
        }
        .sorted { $0.1 > $1.1 }
    }

    private var keyUsageData: [(key: String, count: Int)] {
        let keys = filteredPerformances.compactMap { $0.key }
        let counts = Dictionary(grouping: keys, by: { $0 }).mapValues { $0.count }
        return counts.map { (key: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }

    private var performanceTrendData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let groupedByDate = Dictionary(grouping: filteredPerformances) { performance in
            calendar.startOfDay(for: performance.performanceDate)
        }

        return groupedByDate.map { (date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    private var quickInsights: [Insight] {
        InsightsEngine.generateInsights(
            performances: filteredPerformances,
            setPerformances: filteredSetPerformances,
            songs: allSongs
        )
    }
}

// MARK: - Overview Card

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var trend: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()

                if let trend = trend {
                    Text(trend)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(trend.hasPrefix("+") ? .green : .red)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Top Song Row

struct TopSongRow: View {
    let rank: Int
    let song: Song
    let count: Int

    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(rank)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(rankColor)
            }

            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let artist = song.artist {
                    Text(artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Count
            Text("\(count)")
                .font(.headline)
                .foregroundStyle(rankColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
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

// MARK: - Insight Card

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundStyle(insight.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    case allTime = "All Time"

    var id: String { rawValue }

    var cutoffDate: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            return Date.distantPast
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsDashboardView()
        .modelContainer(for: [Performance.self, SetPerformance.self, Song.self])
}
