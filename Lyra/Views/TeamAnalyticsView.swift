//
//  TeamAnalyticsView.swift
//  Lyra
//
//  Comprehensive analytics dashboard for team collaboration
//

import SwiftUI
import SwiftData

struct TeamAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let library: SharedLibrary

    @Query private var allSongs: [Song]
    @Query private var allComments: [Comment]

    @State private var analytics: TeamAnalytics?
    @State private var selectedTab: AnalyticsTab = .overview
    @State private var showingExportSheet = false
    @State private var showingInsights = false
    @State private var isLoading = true

    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case contributors = "Contributors"
        case health = "Health"
        case activity = "Activity"
        case popularity = "Popularity"

        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .contributors: return "person.3.fill"
            case .health: return "cross.case.fill"
            case .activity: return "calendar"
            case .popularity: return "star.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Analyzing collaboration data...")
                } else if let analytics = analytics {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Tab picker
                            Picker("Analytics Section", selection: $selectedTab) {
                                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                                    Label(tab.rawValue, systemImage: tab.icon)
                                        .tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            // Content based on selected tab
                            switch selectedTab {
                            case .overview:
                                OverviewSection(analytics: analytics)
                            case .contributors:
                                ContributorsSection(analytics: analytics)
                            case .health:
                                HealthSection(analytics: analytics)
                            case .activity:
                                ActivitySection(analytics: analytics)
                            case .popularity:
                                PopularitySection(analytics: analytics)
                            }
                        }
                        .padding(.bottom)
                    }
                } else {
                    ContentUnavailableView(
                        "No Analytics Available",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Start collaborating to see team analytics")
                    )
                }
            }
            .navigationTitle("Team Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingInsights = true
                        } label: {
                            Label("View Insights", systemImage: "lightbulb.fill")
                        }

                        Button {
                            showingExportSheet = true
                        } label: {
                            Label("Export Report", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            Task {
                                await loadAnalytics()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingInsights) {
                if let analytics = analytics {
                    InsightsSheet(insights: analytics.insights)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let analytics = analytics {
                    ExportReportSheet(library: library, analytics: analytics)
                }
            }
            .task {
                await loadAnalytics()
            }
        }
    }

    private func loadAnalytics() async {
        isLoading = true

        // Filter songs for this library
        let librarySongs = allSongs.filter { $0.sharedLibrary?.id == library.id }

        // Filter comments for songs in this library
        let songIDs = Set(librarySongs.map { $0.id })
        let libraryComments = allComments.filter { songIDs.contains($0.songID) }

        // Generate analytics
        analytics = TeamAnalyticsEngine.generateAnalytics(
            library: library,
            songs: librarySongs,
            comments: libraryComments
        )

        isLoading = false
    }
}

// MARK: - Overview Section

struct OverviewSection: View {
    let analytics: TeamAnalytics

    var body: some View {
        VStack(spacing: 16) {
            // Key metrics grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Total Songs",
                    value: "\(analytics.totalSongs)",
                    icon: "music.note.list",
                    color: .blue
                )

                MetricCard(
                    title: "Contributors",
                    value: "\(analytics.totalContributors)",
                    icon: "person.3.fill",
                    color: .green
                )

                MetricCard(
                    title: "This Week",
                    value: "\(analytics.songsAddedThisWeek)",
                    icon: "plus.circle.fill",
                    color: .orange
                )

                MetricCard(
                    title: "This Month",
                    value: "\(analytics.songsAddedThisMonth)",
                    icon: "calendar",
                    color: .purple
                )
            }
            .padding(.horizontal)

            // Most active contributors
            if !analytics.mostActiveContributors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Active Contributors")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(analytics.mostActiveContributors.prefix(5)) { contributor in
                            HStack {
                                Circle()
                                    .fill(Color.accentColor.gradient)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Text(contributor.displayName.prefix(1))
                                            .foregroundStyle(.white)
                                            .fontWeight(.semibold)
                                    }

                                VStack(alignment: .leading) {
                                    Text(contributor.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("\(contributor.activityCount) actions")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let lastActive = contributor.lastActiveAt {
                                    Text(lastActive, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Recent activity
            if !analytics.recentActivities.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(analytics.recentActivities.prefix(10)) { activity in
                            HStack(spacing: 12) {
                                Image(systemName: activity.icon)
                                    .foregroundStyle(colorForActivityType(activity.activityType))
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activity.displayText)
                                        .font(.subheadline)

                                    Text(activity.relativeTime)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func colorForActivityType(_ type: MemberActivity.ActivityType) -> Color {
        switch type {
        case .songCreated: return .green
        case .songEdited: return .blue
        case .songDeleted: return .red
        case .songViewed: return .purple
        case .memberJoined: return .green
        case .memberLeft: return .orange
        case .permissionChanged: return .yellow
        case .librarySettingsChanged: return .gray
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SharedLibrary.self, Song.self, Comment.self, configurations: config)

    let library = SharedLibrary(
        name: "Worship Team",
        description: "Main worship library",
        ownerRecordID: "owner123",
        ownerDisplayName: "John Doe"
    )
    container.mainContext.insert(library)

    return TeamAnalyticsView(library: library)
        .modelContainer(container)
}
