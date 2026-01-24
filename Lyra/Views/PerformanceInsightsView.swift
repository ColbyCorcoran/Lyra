//
//  PerformanceInsightsView.swift
//  Lyra
//
//  UI for displaying AI performance insights and recommendations
//

import SwiftUI
import SwiftData

struct PerformanceInsightsView: View {
    @State private var analyticsEngine = PerformanceAnalyticsEngine.shared
    @State private var selectedTab: InsightTab = .live
    @State private var showPostReport: Bool = false
    @State private var currentReport: PostPerformanceReport?
    @Query private var previousSessions: [PerformanceSession]

    enum InsightTab {
        case live, readiness, setOptimization, history
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Live").tag(InsightTab.live)
                    Text("Readiness").tag(InsightTab.readiness)
                    Text("Set Analysis").tag(InsightTab.setOptimization)
                    Text("History").tag(InsightTab.history)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .live:
                        LiveInsightsTab()
                    case .readiness:
                        ReadinessTab()
                    case .setOptimization:
                        SetOptimizationTab()
                    case .history:
                        PerformanceHistoryTab()
                    }
                }
            }
            .navigationTitle("Performance Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if analyticsEngine.isTracking {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("End Performance") {
                            if let session = analyticsEngine.endPerformanceSession() {
                                // Generate comprehensive report
                                currentReport = PostPerformanceReportEngine.shared.generateReport(
                                    session: session,
                                    previousSessions: previousSessions
                                        .sorted(by: { $0.startTime > $1.startTime })
                                )
                                showPostReport = true
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $showPostReport) {
                if let report = currentReport {
                    PostPerformanceReportView(report: report)
                } else {
                    Text("Report unavailable")
                }
            }
        }
    }
}

// MARK: - Live Insights Tab

struct LiveInsightsTab: View {
    @State private var analyticsEngine = PerformanceAnalyticsEngine.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if analyticsEngine.isTracking {
                    // Active performance tracking
                    activePerformanceView
                } else {
                    // Start performance prompt
                    startPerformancePrompt
                }

                // Live insights
                if !analyticsEngine.liveInsights.isEmpty {
                    insightsSection
                } else if analyticsEngine.isTracking {
                    emptyInsightsView
                }
            }
            .padding()
        }
    }

    private var activePerformanceView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance in Progress")
                        .font(.headline)

                    if let session = analyticsEngine.currentSession {
                        Text(session.setName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)

                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var startPerformancePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Start a Performance")
                .font(.title2)
                .fontWeight(.bold)

            Text("Begin tracking a performance session to receive real-time insights and coaching")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                // Start performance - would integrate with set selection
            } label: {
                Label("Start Performance Tracking", systemImage: "play.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding(.vertical, 40)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Insights")
                .font(.headline)
                .padding(.horizontal)

            ForEach(analyticsEngine.liveInsights) { insight in
                InsightCard(insight: insight) {
                    analyticsEngine.dismissInsight(insight.id)
                }
            }
        }
    }

    private var emptyInsightsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            Text("All Good!")
                .font(.headline)

            Text("No issues detected. Keep up the great performance!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Readiness Tab

struct ReadinessTab: View {
    @Query private var sets: [PerformanceSet]
    @State private var selectedSetID: UUID?
    @State private var readinessScore: Float = 0
    @State private var redFlags: [ReadinessFlag] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Set selector
                if !sets.isEmpty {
                    setSelector
                }

                // Readiness score
                if selectedSetID != nil {
                    readinessScoreCard
                }

                // Red flags
                if !redFlags.isEmpty {
                    redFlagsSection
                }

                // Checklist
                if selectedSetID != nil {
                    checklistSection
                }
            }
            .padding()
        }
    }

    private var setSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Set")
                .font(.headline)

            ForEach(sets) { set in
                Button {
                    selectedSetID = set.id
                    assessReadiness(for: set)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(set.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("\(set.songEntries?.count ?? 0) songs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedSetID == set.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(
                        selectedSetID == set.id ?
                        Color.blue.opacity(0.1) :
                        Color.secondary.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var readinessScoreCard: some View {
        VStack(spacing: 16) {
            // Score gauge
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(readinessScore))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(readinessScore * 100))%")
                        .font(.system(size: 32, weight: .bold))

                    Text("Ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(readinessMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scoreColor: Color {
        if readinessScore >= 0.8 {
            return .green
        } else if readinessScore >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }

    private var readinessMessage: String {
        if readinessScore >= 0.8 {
            return "You're well-prepared for this performance!"
        } else if readinessScore >= 0.6 {
            return "Some areas need attention. Review the flagged items below."
        } else {
            return "Significant preparation needed. See recommendations below."
        }
    }

    private var redFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Areas Needing Attention")
                .font(.headline)

            ForEach(redFlags) { flag in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: flag.severity.icon)
                            .foregroundStyle(Color(flag.severity.color))

                        Text(flag.songTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text(flag.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let recommendation = flag.recommendation {
                        Text("→ \(recommendation)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
                .background(Color(flag.severity.color).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pre-Performance Checklist")
                .font(.headline)

            // Would generate checklist items here
            Text("Review all songs in order")
                .font(.subheadline)
        }
    }

    private func assessReadiness(for set: PerformanceSet) {
        // Assess readiness using PerformanceReadinessEngine
        // This is a simplified version - real implementation would fetch actual data
        readinessScore = 0.75
        redFlags = []
    }
}

// MARK: - Set Optimization Tab

struct SetOptimizationTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Set Flow Analysis")
                    .font(.headline)

                Text("Select a set to analyze its flow, key transitions, and energy balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

// MARK: - Performance History Tab

struct PerformanceHistoryTab: View {
    @Query private var sessions: [PerformanceSession]

    var body: some View {
        if sessions.isEmpty {
            emptyHistoryView
        } else {
            historyList
        }
    }

    private var emptyHistoryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Performance History")
                .font(.headline)

            Text("Start tracking performances to see history and analytics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 60)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sessions.sorted(by: { $0.startTime > $1.startTime })) { session in
                    PerformanceSessionCard(session: session)
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct InsightCard: View {
    let insight: PerformanceInsight
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: insight.severity.icon)
                    .font(.title3)
                    .foregroundStyle(Color(insight.severity.color))

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(insight.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if insight.actionable, let action = insight.action {
                Button(action) {
                    // Perform action
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 8))
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(insight.severity.color).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(insight.severity.color).opacity(0.3), lineWidth: 1)
        )
    }
}

struct PerformanceSessionCard: View {
    let session: PerformanceSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.setName)
                        .font(.headline)

                    if let venue = session.venue {
                        Text(venue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(session.startTime.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label("\(session.songPerformances.count) songs", systemImage: "music.note")
                    .font(.caption)

                let duration = Int(session.duration / 60)
                Label("\(duration) min", systemImage: "clock")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Color Extension

extension Color {
    init(_ colorName: String) {
        switch colorName {
        case "blue": self = .blue
        case "green": self = .green
        case "orange": self = .orange
        case "red": self = .red
        default: self = .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    PerformanceInsightsView()
}
