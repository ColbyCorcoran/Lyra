//
//  TeamAnalyticsEngine.swift
//  Lyra
//
//  Generate comprehensive analytics and insights for team collaboration
//

import Foundation
import SwiftUI

// MARK: - Analytics Models

struct TeamAnalytics {
    // Dashboard metrics
    var totalSongs: Int
    var totalContributors: Int
    var songsAddedThisWeek: Int
    var songsAddedThisMonth: Int
    var mostActiveContributors: [ContributorSummary]
    var recentActivities: [MemberActivity]

    // Contributor stats
    var contributorStats: [ContributorStats]

    // Library health
    var staleSongs: [SongHealth]
    var songsWithUnresolvedComments: [SongHealth]
    var songsWithConflicts: [SongHealth]
    var songsMissingMetadata: [SongHealth]
    var cleanupSuggestions: [CleanupSuggestion]

    // Activity data
    var activityHeatmap: [ActivityDay]
    var contributionTrends: [TrendPoint]

    // Song popularity
    var mostViewedSongs: [SongPopularity]
    var mostEditedSongs: [SongPopularity]
    var mostCommentedSongs: [SongPopularity]
    var mostPerformedSongs: [SongPopularity]

    // Insights
    var insights: [TeamInsight]
}

struct ContributorSummary: Identifiable {
    let id: String // userRecordID
    let displayName: String
    let activityCount: Int
    let lastActiveAt: Date?
}

struct ContributorStats: Identifiable {
    let id: String // userRecordID
    let displayName: String
    let songsAdded: Int
    let editsCount: Int
    let commentsCount: Int
    let mostCollaboratedSongs: [String] // Song titles
    let joinedAt: Date?
    let lastActiveAt: Date?
}

struct SongHealth: Identifiable {
    let id: UUID
    let title: String
    let issue: HealthIssue
    let daysSinceLastEdit: Int?
    let unresolvedCommentCount: Int?
    let missingFields: [String]?

    enum HealthIssue {
        case stale
        case unresolvedComments
        case conflict
        case missingMetadata
    }
}

struct CleanupSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
    let actionCount: Int

    enum Priority: Int, Comparable {
        case low = 1
        case medium = 2
        case high = 3

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

struct ActivityDay: Identifiable {
    let id = UUID()
    let date: Date
    let activityCount: Int
    let contributors: Set<String> // userRecordIDs
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

struct SongPopularity: Identifiable {
    let id: UUID
    let title: String
    let count: Int
    let subtitle: String
}

struct TeamInsight: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let color: Color
    let type: InsightType
    let priority: Int

    enum InsightType {
        case achievement
        case trend
        case recommendation
        case alert
    }
}

// MARK: - Team Analytics Engine

class TeamAnalyticsEngine {

    /// Generate comprehensive team analytics for a shared library
    static func generateAnalytics(
        library: SharedLibrary,
        songs: [Song],
        comments: [Comment]
    ) -> TeamAnalytics {

        let activities = library.activityFeed
        let members = library.members ?? []

        return TeamAnalytics(
            // Dashboard metrics
            totalSongs: songs.count,
            totalContributors: members.count + 1, // +1 for owner
            songsAddedThisWeek: calculateSongsAddedInPeriod(activities: activities, days: 7),
            songsAddedThisMonth: calculateSongsAddedInPeriod(activities: activities, days: 30),
            mostActiveContributors: calculateMostActiveContributors(activities: activities, limit: 5),
            recentActivities: Array(activities.prefix(20)),

            // Contributor stats
            contributorStats: generateContributorStats(
                members: members,
                ownerRecordID: library.ownerRecordID,
                ownerDisplayName: library.ownerDisplayName,
                activities: activities,
                comments: comments
            ),

            // Library health
            staleSongs: findStaleSongs(songs: songs),
            songsWithUnresolvedComments: findSongsWithUnresolvedComments(songs: songs, comments: comments),
            songsWithConflicts: findSongsWithConflicts(songs: songs),
            songsMissingMetadata: findSongsMissingMetadata(songs: songs),
            cleanupSuggestions: generateCleanupSuggestions(songs: songs, comments: comments),

            // Activity data
            activityHeatmap: generateActivityHeatmap(activities: activities),
            contributionTrends: generateContributionTrends(activities: activities),

            // Song popularity
            mostViewedSongs: generateMostViewedSongs(songs: songs),
            mostEditedSongs: generateMostEditedSongs(songs: songs, activities: activities),
            mostCommentedSongs: generateMostCommentedSongs(songs: songs, comments: comments),
            mostPerformedSongs: generateMostPerformedSongs(songs: songs),

            // Insights
            insights: generateTeamInsights(
                library: library,
                activities: activities,
                songs: songs,
                comments: comments
            )
        )
    }

    // MARK: - Dashboard Metrics

    private static func calculateSongsAddedInPeriod(activities: [MemberActivity], days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return activities.filter { activity in
            activity.activityType == .songCreated && activity.timestamp >= cutoff
        }.count
    }

    private static func calculateMostActiveContributors(
        activities: [MemberActivity],
        limit: Int
    ) -> [ContributorSummary] {
        let grouped = Dictionary(grouping: activities, by: { $0.userRecordID })

        return grouped.map { (userID, userActivities) in
            ContributorSummary(
                id: userID,
                displayName: userActivities.first?.displayName ?? "Unknown",
                activityCount: userActivities.count,
                lastActiveAt: userActivities.map { $0.timestamp }.max()
            )
        }
        .sorted { $0.activityCount > $1.activityCount }
        .prefix(limit)
        .map { $0 }
    }

    // MARK: - Contributor Stats

    private static func generateContributorStats(
        members: [LibraryMember],
        ownerRecordID: String,
        ownerDisplayName: String?,
        activities: [MemberActivity],
        comments: [Comment]
    ) -> [ContributorStats] {
        var allContributors: [(id: String, name: String, joinedAt: Date?)] = []

        // Add owner
        allContributors.append((ownerRecordID, ownerDisplayName ?? "Owner", nil))

        // Add members
        for member in members {
            allContributors.append((member.userRecordID, member.displayName ?? "Unknown", member.joinedAt))
        }

        return allContributors.map { contributor in
            let userActivities = activities.filter { $0.userRecordID == contributor.id }
            let userComments = comments.filter { $0.authorRecordID == contributor.id }

            let songsAdded = userActivities.filter { $0.activityType == .songCreated }.count
            let editsCount = userActivities.filter { $0.activityType == .songEdited }.count

            // Find most collaborated songs (songs with most edits)
            let songEdits = userActivities.filter { $0.activityType == .songEdited }
            let songEditCounts = Dictionary(grouping: songEdits, by: { $0.songTitle ?? "" })
                .mapValues { $0.count }
            let topSongs = songEditCounts.sorted { $0.value > $1.value }
                .prefix(3)
                .map { $0.key }

            return ContributorStats(
                id: contributor.id,
                displayName: contributor.name,
                songsAdded: songsAdded,
                editsCount: editsCount,
                commentsCount: userComments.count,
                mostCollaboratedSongs: Array(topSongs),
                joinedAt: contributor.joinedAt,
                lastActiveAt: userActivities.map { $0.timestamp }.max()
            )
        }
        .sorted { $0.editsCount > $1.editsCount }
    }

    // MARK: - Library Health

    private static func findStaleSongs(songs: [Song]) -> [SongHealth] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -60, to: Date()) ?? Date()

        return songs.filter { song in
            // Check last modified or last viewed
            let lastActivity = song.modifiedAt ?? song.createdAt
            return lastActivity < cutoff
        }
        .map { song in
            let daysSince = calendar.dateComponents([.day], from: song.modifiedAt ?? song.createdAt, to: Date()).day ?? 0
            return SongHealth(
                id: song.id,
                title: song.title,
                issue: .stale,
                daysSinceLastEdit: daysSince,
                unresolvedCommentCount: nil,
                missingFields: nil
            )
        }
        .sorted { ($0.daysSinceLastEdit ?? 0) > ($1.daysSinceLastEdit ?? 0) }
    }

    private static func findSongsWithUnresolvedComments(songs: [Song], comments: [Comment]) -> [SongHealth] {
        let songCommentCounts = Dictionary(grouping: comments.filter { !$0.isResolved }, by: { $0.songID })
            .mapValues { $0.count }

        return songs.compactMap { song in
            guard let count = songCommentCounts[song.id], count > 0 else { return nil }
            return SongHealth(
                id: song.id,
                title: song.title,
                issue: .unresolvedComments,
                daysSinceLastEdit: nil,
                unresolvedCommentCount: count,
                missingFields: nil
            )
        }
        .sorted { ($0.unresolvedCommentCount ?? 0) > ($1.unresolvedCommentCount ?? 0) }
    }

    private static func findSongsWithConflicts(songs: [Song]) -> [SongHealth] {
        return songs.filter { $0.hasConflict }
            .map { song in
                SongHealth(
                    id: song.id,
                    title: song.title,
                    issue: .conflict,
                    daysSinceLastEdit: nil,
                    unresolvedCommentCount: nil,
                    missingFields: nil
                )
            }
    }

    private static func findSongsMissingMetadata(songs: [Song]) -> [SongHealth] {
        return songs.compactMap { song in
            var missing: [String] = []

            if song.artist.isEmpty { missing.append("Artist") }
            if song.originalKey == nil { missing.append("Key") }
            if (song.tempo ?? 0) == 0 { missing.append("Tempo") }
            if song.copyright.isEmpty { missing.append("Copyright") }

            guard !missing.isEmpty else { return nil }

            return SongHealth(
                id: song.id,
                title: song.title,
                issue: .missingMetadata,
                daysSinceLastEdit: nil,
                unresolvedCommentCount: nil,
                missingFields: missing
            )
        }
        .sorted { ($0.missingFields?.count ?? 0) > ($1.missingFields?.count ?? 0) }
    }

    private static func generateCleanupSuggestions(songs: [Song], comments: [Comment]) -> [CleanupSuggestion] {
        var suggestions: [CleanupSuggestion] = []

        // Stale songs suggestion
        let staleSongsCount = findStaleSongs(songs: songs).count
        if staleSongsCount > 0 {
            suggestions.append(CleanupSuggestion(
                title: "Review Stale Songs",
                description: "\(staleSongsCount) songs haven't been edited in 60+ days",
                priority: .medium,
                actionCount: staleSongsCount
            ))
        }

        // Unresolved comments suggestion
        let unresolvedCount = comments.filter { !$0.isResolved }.count
        if unresolvedCount > 0 {
            suggestions.append(CleanupSuggestion(
                title: "Resolve Comments",
                description: "\(unresolvedCount) comments are waiting for resolution",
                priority: .high,
                actionCount: unresolvedCount
            ))
        }

        // Conflicts suggestion
        let conflictsCount = songs.filter { $0.hasConflict }.count
        if conflictsCount > 0 {
            suggestions.append(CleanupSuggestion(
                title: "Resolve Conflicts",
                description: "\(conflictsCount) songs have sync conflicts",
                priority: .high,
                actionCount: conflictsCount
            ))
        }

        // Missing metadata suggestion
        let missingMetadataCount = findSongsMissingMetadata(songs: songs).count
        if missingMetadataCount > 0 {
            suggestions.append(CleanupSuggestion(
                title: "Complete Metadata",
                description: "\(missingMetadataCount) songs are missing key information",
                priority: .low,
                actionCount: missingMetadataCount
            ))
        }

        return suggestions.sorted { $0.priority > $1.priority }
    }

    // MARK: - Activity Heatmap

    private static func generateActivityHeatmap(activities: [MemberActivity]) -> [ActivityDay] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        // Group activities by day
        let grouped = Dictionary(grouping: activities.filter { $0.timestamp >= startDate }) { activity in
            calendar.startOfDay(for: activity.timestamp)
        }

        return grouped.map { (date, dayActivities) in
            ActivityDay(
                date: date,
                activityCount: dayActivities.count,
                contributors: Set(dayActivities.map { $0.userRecordID })
            )
        }
        .sorted { $0.date < $1.date }
    }

    private static func generateContributionTrends(activities: [MemberActivity]) -> [TrendPoint] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()

        // Group by week
        let grouped = Dictionary(grouping: activities.filter { $0.timestamp >= startDate }) { activity in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: activity.timestamp)
        }

        return grouped.compactMap { (components, weekActivities) -> TrendPoint? in
            guard let year = components.yearForWeekOfYear,
                  let week = components.weekOfYear,
                  let date = calendar.date(from: DateComponents(weekOfYear: week, yearForWeekOfYear: year)) else {
                return nil
            }

            return TrendPoint(
                date: date,
                value: Double(weekActivities.count),
                label: "Week \(week)"
            )
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Song Popularity

    private static func generateMostViewedSongs(songs: [Song]) -> [SongPopularity] {
        return songs
            .filter { $0.timesViewed > 0 }
            .sorted { $0.timesViewed > $1.timesViewed }
            .prefix(10)
            .map { song in
                SongPopularity(
                    id: song.id,
                    title: song.title,
                    count: song.timesViewed,
                    subtitle: "\(song.timesViewed) views"
                )
            }
    }

    private static func generateMostEditedSongs(songs: [Song], activities: [MemberActivity]) -> [SongPopularity] {
        let editCounts = Dictionary(grouping: activities.filter { $0.activityType == .songEdited }, by: { $0.songID })
            .mapValues { $0.count }

        return songs
            .compactMap { song -> SongPopularity? in
                guard let count = editCounts[song.id], count > 0 else { return nil }
                return SongPopularity(
                    id: song.id,
                    title: song.title,
                    count: count,
                    subtitle: "\(count) edits"
                )
            }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }

    private static func generateMostCommentedSongs(songs: [Song], comments: [Comment]) -> [SongPopularity] {
        let commentCounts = Dictionary(grouping: comments, by: { $0.songID })
            .mapValues { $0.count }

        return songs
            .compactMap { song -> SongPopularity? in
                guard let count = commentCounts[song.id], count > 0 else { return nil }
                return SongPopularity(
                    id: song.id,
                    title: song.title,
                    count: count,
                    subtitle: "\(count) comments"
                )
            }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }

    private static func generateMostPerformedSongs(songs: [Song]) -> [SongPopularity] {
        return songs
            .filter { $0.timesPerformed > 0 }
            .sorted { $0.timesPerformed > $1.timesPerformed }
            .prefix(10)
            .map { song in
                SongPopularity(
                    id: song.id,
                    title: song.title,
                    count: song.timesPerformed,
                    subtitle: "\(song.timesPerformed) performances"
                )
            }
    }

    // MARK: - Team Insights

    private static func generateTeamInsights(
        library: SharedLibrary,
        activities: [MemberActivity],
        songs: [Song],
        comments: [Comment]
    ) -> [TeamInsight] {
        var insights: [TeamInsight] = []

        // Songs added this month insight
        let songsThisMonth = calculateSongsAddedInPeriod(activities: activities, days: 30)
        if songsThisMonth > 0 {
            insights.append(TeamInsight(
                title: "Library Growth",
                message: "Your team added \(songsThisMonth) songs this month",
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                type: .achievement,
                priority: 8
            ))
        }

        // Most active contributor insight
        if let mostActive = calculateMostActiveContributors(activities: activities, limit: 1).first {
            insights.append(TeamInsight(
                title: "Top Contributor",
                message: "\(mostActive.displayName) is your most active contributor with \(mostActive.activityCount) actions",
                icon: "star.fill",
                color: .yellow,
                type: .achievement,
                priority: 7
            ))
        }

        // Metadata cleanup insight
        let missingMetadata = findSongsMissingMetadata(songs: songs).count
        if missingMetadata > 0 {
            insights.append(TeamInsight(
                title: "Needs Attention",
                message: "\(missingMetadata) songs need metadata updates",
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                type: .recommendation,
                priority: 6
            ))
        }

        // Conflicts insight
        let conflicts = songs.filter { $0.hasConflict }.count
        if conflicts > 0 {
            insights.append(TeamInsight(
                title: "Conflicts Detected",
                message: "\(conflicts) conflicts need resolution",
                icon: "exclamationmark.octagon.fill",
                color: .red,
                type: .alert,
                priority: 9
            ))
        }

        // Collaboration health insight
        let recentActivityCount = activities.filter {
            $0.timestamp >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }.count

        if recentActivityCount > 20 {
            insights.append(TeamInsight(
                title: "High Collaboration",
                message: "Your team made \(recentActivityCount) changes this week - great teamwork!",
                icon: "person.3.fill",
                color: .blue,
                type: .achievement,
                priority: 7
            ))
        } else if recentActivityCount == 0 {
            insights.append(TeamInsight(
                title: "Low Activity",
                message: "No activity this week - time to collaborate!",
                icon: "moon.fill",
                color: .gray,
                type: .recommendation,
                priority: 5
            ))
        }

        // Unresolved comments insight
        let unresolvedComments = comments.filter { !$0.isResolved }.count
        if unresolvedComments > 5 {
            insights.append(TeamInsight(
                title: "Pending Discussions",
                message: "\(unresolvedComments) comments are waiting for resolution",
                icon: "bubble.left.and.bubble.right.fill",
                color: .purple,
                type: .recommendation,
                priority: 6
            ))
        }

        // Team growth insight
        let membersThisMonth = activities.filter {
            $0.activityType == .memberJoined &&
            $0.timestamp >= Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        }.count

        if membersThisMonth > 0 {
            insights.append(TeamInsight(
                title: "Team Growing",
                message: "\(membersThisMonth) new members joined this month",
                icon: "person.badge.plus.fill",
                color: .green,
                type: .achievement,
                priority: 7
            ))
        }

        return insights.sorted { $0.priority > $1.priority }
    }
}
