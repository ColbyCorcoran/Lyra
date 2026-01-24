//
//  PostPerformanceReportView.swift
//  Lyra
//
//  Displays comprehensive post-performance report and analysis
//

import SwiftUI
import SwiftData

struct PostPerformanceReportView: View {
    let report: PostPerformanceReport
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ReportTab = .overview

    enum ReportTab {
        case overview, strengths, improvements, insights
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    performanceHeader

                    // Tab selector
                    tabSelector

                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case .overview:
                            overviewTab
                        case .strengths:
                            strengthsTab
                        case .improvements:
                            improvementsTab
                        case .insights:
                            insightsTab
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Performance Report")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    shareButton
                }
            }
        }
    }

    // MARK: - Header

    private var performanceHeader: some View {
        VStack(spacing: 12) {
            // Overall score
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 16)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(report.overallScore / 100.0))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(report.overallScore))")
                        .font(.system(size: 42, weight: .bold))

                    Text("Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top)

            // Performance details
            VStack(spacing: 8) {
                Text(report.setName)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let venue = report.venue {
                    Text(venue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(report.performanceDate.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Quick stats
            HStack(spacing: 24) {
                statBox(
                    icon: "music.note.list",
                    value: "\(report.songsPerformed)",
                    label: "Songs"
                )

                statBox(
                    icon: "clock",
                    value: formatDuration(report.totalDuration),
                    label: "Duration"
                )

                statBox(
                    icon: "checkmark.circle",
                    value: "\(report.songsCompleted)",
                    label: "Completed"
                )

                if let audienceRating = report.audienceRating {
                    statBox(
                        icon: "person.3",
                        value: "\(Int(audienceRating * 100))%",
                        label: "Audience"
                    )
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statBox(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var scoreColor: Color {
        if report.overallScore >= 80 {
            return .green
        } else if report.overallScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        Picker("View", selection: $selectedTab) {
            Text("Overview").tag(ReportTab.overview)
            Text("Strengths").tag(ReportTab.strengths)
            Text("Improvements").tag(ReportTab.improvements)
            Text("Insights").tag(ReportTab.insights)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Personal bests
            if !report.personalBest.isEmpty {
                personalBestsSection
            }

            // Comparison to previous
            if let comparison = report.comparisonToPrevious {
                comparisonSection(comparison: comparison)
            }

            // Top songs
            if !report.topSongs.isEmpty {
                topSongsSection
            }

            // Goals
            if !report.suggestedGoals.isEmpty {
                goalsSection
            }
        }
    }

    private var personalBestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)

                Text("Personal Bests")
                    .font(.headline)
            }

            ForEach(report.personalBest, id: \.self) { best in
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)

                    Text(best)
                        .font(.subheadline)

                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func comparisonSection(comparison: PerformanceComparison) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.blue)

                Text("vs Previous Performance")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                comparisonRow(
                    label: "Score Change",
                    value: formatChange(comparison.scoreChange),
                    positive: comparison.scoreChange >= 0
                )

                comparisonRow(
                    label: "Duration Change",
                    value: formatDurationChange(comparison.durationChange),
                    positive: abs(comparison.durationChange) < 300 // Within 5 minutes is good
                )

                comparisonRow(
                    label: "Error Rate",
                    value: formatChange(comparison.errorRateChange),
                    positive: comparison.errorRateChange <= 0
                )

                if !comparison.significantChanges.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    Text("Significant Changes:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(comparison.significantChanges, id: \.self) { change in
                        HStack {
                            Text("•")
                            Text(change)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func comparisonRow(label: String, value: String, positive: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(positive ? .green : .red)
        }
    }

    private var topSongsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)

                Text("Audience Favorites")
                    .font(.headline)
            }

            Text("Top \(report.topSongs.count) songs by audience engagement")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Would show actual song titles here by looking up UUIDs
            Text("Song lookup would display here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.purple)

                Text("Suggested Goals")
                    .font(.headline)
            }

            ForEach(report.suggestedGoals) { goal in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)

                        Text(goal.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        if goal.measurable {
                            Text("\(Int((goal.targetValue ?? 0) * 100))%")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }

                    Text(goal.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Strengths Tab

    private var strengthsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if report.strengthAreas.isEmpty {
                emptyStateView(
                    icon: "star",
                    title: "No Strengths Identified",
                    message: "Complete more performances to identify your strengths"
                )
            } else {
                ForEach(report.strengthAreas) { strength in
                    strengthCard(strength: strength)
                }
            }
        }
    }

    private func strengthCard(strength: StrengthArea) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.green)

                Text(strength.area)
                    .font(.headline)

                Spacer()

                Text("\(Int(strength.score * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            Text(strength.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !strength.examples.isEmpty {
                Divider()

                ForEach(strength.examples, id: \.self) { example in
                    HStack {
                        Text("✓")
                            .foregroundStyle(.green)

                        Text(example)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Improvements Tab

    private var improvementsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if report.improvementAreas.isEmpty {
                emptyStateView(
                    icon: "checkmark.circle",
                    title: "Excellent Performance!",
                    message: "No significant areas for improvement identified"
                )
            } else {
                ForEach(report.improvementAreas) { improvement in
                    improvementCard(improvement: improvement)
                }

                // Recommendations
                if !report.practiceRecommendations.isEmpty {
                    practiceRecommendationsSection
                }

                if !report.setlistRecommendations.isEmpty {
                    setlistRecommendationsSection
                }
            }
        }
    }

    private func improvementCard(improvement: ImprovementArea) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle")
                    .foregroundStyle(.orange)

                Text(improvement.area)
                    .font(.headline)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Current: \(Int(improvement.currentScore * 100))%")
                        .font(.caption2)

                    Text("Target: \(Int(improvement.targetScore * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Text(improvement.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Text("Action Items:")
                .font(.caption)
                .fontWeight(.medium)

            ForEach(improvement.actionItems, id: \.self) { action in
                HStack(alignment: .top) {
                    Text("→")
                        .foregroundStyle(.orange)

                    Text(action)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var practiceRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundStyle(.blue)

                Text("Practice Recommendations")
                    .font(.headline)
            }

            ForEach(report.practiceRecommendations, id: \.self) { recommendation in
                HStack(alignment: .top) {
                    Text("•")
                    Text(recommendation)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var setlistRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundStyle(.purple)

                Text("Setlist Recommendations")
                    .font(.headline)
            }

            ForEach(report.setlistRecommendations, id: \.self) { recommendation in
                HStack(alignment: .top) {
                    Text("•")
                    Text(recommendation)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Insights Tab

    private var insightsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if report.keyInsights.isEmpty {
                emptyStateView(
                    icon: "lightbulb",
                    title: "No Key Insights",
                    message: "Insights will appear as patterns are detected in your performances"
                )
            } else {
                ForEach(report.keyInsights) { insight in
                    InsightCard(insight: insight) {
                        // Dismiss is not available in report view
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }

    private func formatChange(_ change: Float) -> String {
        let formatted = String(format: "%+.1f", change)
        return formatted
    }

    private func formatDurationChange(_ change: TimeInterval) -> String {
        let minutes = Int(abs(change) / 60)
        let sign = change >= 0 ? "+" : "-"
        return "\(sign)\(minutes)m"
    }

    private var shareButton: some View {
        Button {
            shareReport()
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }

    private func shareReport() {
        // Generate shareable summary
        let summary = generateShareableText()

        let activityVC = UIActivityViewController(
            activityItems: [summary],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
    }

    private func generateShareableText() -> String {
        var text = """
        🎵 Performance Report - \(report.setName)
        📅 \(report.performanceDate.formatted(date: .long, time: .omitted))

        📊 Overall Score: \(Int(report.overallScore))/100
        🎼 Songs Performed: \(report.songsPerformed) (\(report.songsCompleted) completed)
        ⏱️ Duration: \(formatDuration(report.totalDuration))

        """

        if !report.strengthAreas.isEmpty {
            text += "\n💪 Strengths:\n"
            for strength in report.strengthAreas.prefix(3) {
                text += "  • \(strength.area)\n"
            }
        }

        if !report.personalBest.isEmpty {
            text += "\n🏆 Personal Bests:\n"
            for best in report.personalBest {
                text += "  • \(best)\n"
            }
        }

        text += "\n\nGenerated by Lyra"

        return text
    }
}

// MARK: - Preview

#Preview {
    PostPerformanceReportView(
        report: PostPerformanceReport(
            sessionID: UUID(),
            performanceDate: Date(),
            setName: "Sunday Morning Worship",
            venue: "Main Sanctuary",
            totalDuration: 3600,
            songsPerformed: 8,
            songsCompleted: 7,
            averagePerformance: 0.85,
            overallScore: 82,
            strengthAreas: [
                StrengthArea(
                    area: "Tempo Control",
                    score: 0.9,
                    description: "Excellent autoscroll accuracy",
                    examples: ["Average accuracy: 92%"]
                )
            ],
            improvementAreas: [],
            comparisonToPrevious: PerformanceComparison(
                previousDate: Date().addingTimeInterval(-604800),
                scoreChange: 5.2,
                durationChange: 120,
                errorRateChange: -0.3,
                improvementPercentage: 6.5,
                significantChanges: ["Fewer pauses/errors"]
            ),
            personalBest: ["Highest overall score"],
            audienceRating: 0.85,
            topSongs: [UUID()],
            requestedSongs: [],
            keyInsights: [],
            practiceRecommendations: [],
            setlistRecommendations: [],
            suggestedGoals: []
        )
    )
}
