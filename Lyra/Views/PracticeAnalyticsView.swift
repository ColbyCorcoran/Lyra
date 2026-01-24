//
//  PracticeAnalyticsView.swift
//  Lyra
//
//  Progress visualization and analytics dashboard
//  Part of Phase 7.7: Practice Intelligence
//

import SwiftUI
import SwiftData
import Charts

struct PracticeAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var manager: PracticeManager
    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedMetric: MetricType = .overallSkill
    @State private var analytics: PracticeAnalytics?

    init(modelContext: ModelContext) {
        _manager = StateObject(wrappedValue: PracticeManager(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Selector
                    timeRangePicker

                    // Overview Stats
                    if let analytics = analytics {
                        overviewSection(analytics: analytics)
                    }

                    // Improvement Chart
                    improvementChart

                    // Practice Calendar
                    practiceCalendar

                    // Milestones
                    milestonesSection

                    // Weak Areas
                    weakAreasSection
                }
                .padding()
            }
            .navigationTitle("Practice Analytics")
            .task {
                loadAnalytics()
            }
            .onChange(of: selectedTimeRange) { _, _ in
                loadAnalytics()
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            Text("7 Days").tag(TimeRange.last7Days)
            Text("30 Days").tag(TimeRange.last30Days)
            Text("90 Days").tag(TimeRange.last90Days)
            Text("1 Year").tag(TimeRange.lastYear)
            Text("All Time").tag(TimeRange.all)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Overview Section

    private func overviewSection(analytics: PracticeAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AnalyticsCard(
                    title: "Total Sessions",
                    value: "\(analytics.totalSessions)",
                    icon: "music.note.list"
                )

                AnalyticsCard(
                    title: "Practice Time",
                    value: formatTime(analytics.totalPracticeTime),
                    icon: "clock.fill"
                )

                AnalyticsCard(
                    title: "Songs Mastered",
                    value: "\(analytics.songsMastered)",
                    icon: "star.fill"
                )

                AnalyticsCard(
                    title: "Current Streak",
                    value: "\(analytics.currentStreak) days",
                    icon: "flame.fill",
                    color: .orange
                )

                AnalyticsCard(
                    title: "Skill Score",
                    value: String(format: "%.1f%%", analytics.averageSkillScore * 100),
                    icon: "chart.line.uptrend.xyaxis"
                )

                AnalyticsCard(
                    title: "Improvement",
                    value: String(format: "+%.1f%%", analytics.improvementRate),
                    icon: "arrow.up.right",
                    color: .green
                )
            }
        }
    }

    // MARK: - Improvement Chart

    private var improvementChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Improvement Over Time")
                .font(.headline)

            Picker("Metric", selection: $selectedMetric) {
                Text("Overall").tag(MetricType.overallSkill)
                Text("Chord Speed").tag(MetricType.chordChangeSpeed)
                Text("Rhythm").tag(MetricType.rhythmAccuracy)
                Text("Memory").tag(MetricType.memorization)
            }
            .pickerStyle(.segmented)

            let data = manager.getImprovementData(metric: selectedMetric, timeRange: selectedTimeRange)

            if !data.isEmpty {
                Chart(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .padding()
                .background(.thinMaterial)
                .cornerRadius(12)
            } else {
                Text("No data available for this time range")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Practice Calendar

    private var practiceCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Consistency")
                .font(.headline)

            // Simple grid representation of practice days
            Text("Calendar visualization would go here")
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .cornerRadius(12)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Milestones")
                .font(.headline)

            let milestones = manager.getRecentMilestones(limit: 5)

            if !milestones.isEmpty {
                ForEach(milestones) { milestone in
                    MilestoneRow(milestone: milestone)
                }
            } else {
                Text("No milestones yet - keep practicing!")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    // MARK: - Weak Areas Section

    private var weakAreasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Areas to Improve")
                .font(.headline)

            let weakness = manager.analyzeWeaknesses()

            if !weakness.primaryWeaknesses.isEmpty {
                ForEach(weakness.primaryWeaknesses, id: \.self) { area in
                    WeakAreaRow(area: area)
                }
            } else {
                Text("No specific weak areas identified")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    // MARK: - Helper Methods

    private func loadAnalytics() {
        analytics = manager.getAnalytics(timeRange: selectedTimeRange)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .accentColor

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}

struct MilestoneRow: View {
    let milestone: ProgressMilestone

    var body: some View {
        HStack {
            Image(systemName: iconForMilestone(milestone.type))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.description)
                    .font(.subheadline)

                Text(milestone.achievedDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(8)
    }

    private func iconForMilestone(_ type: ProgressMilestone.MilestoneType) -> String {
        switch type {
        case .firstSongMastered: return "star.fill"
        case .streakAchieved: return "flame.fill"
        case .skillLevelUp: return "arrow.up.circle.fill"
        case .speedImproved: return "speedometer"
        case .songCollectionComplete: return "checkmark.seal.fill"
        case .chordMastered: return "music.note"
        case .perfectSession: return "seal.fill"
        case .practiceGoalMet: return "target"
        }
    }
}

struct WeakAreaRow: View {
    let area: PracticeRecommendation.FocusArea

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(area.rawValue)
                .font(.subheadline)

            Spacer()

            Button(action: {}) {
                Text("Practice")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(8)
    }
}
