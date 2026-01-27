//
//  SyncIntelligenceDashboard.swift
//  Lyra
//
//  Phase 7.12: Main dashboard for sync intelligence insights
//

import SwiftUI
import SwiftData

struct SyncIntelligenceDashboard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var syncManager: IntelligentSyncManager?
    @State private var healthScore: SyncHealthScore?
    @State private var optimizationTips: [SyncOptimizationTip] = []
    @State private var statistics: AggregatedStatistics?
    @State private var selectedPeriod: StatisticsPeriod = .week
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading sync insights...")
                            .padding()
                    } else {
                        // Health Score Card
                        if let score = healthScore {
                            healthScoreCard(score)
                        }

                        // Quick Actions
                        quickActionsSection

                        // Optimization Tips
                        if !optimizationTips.isEmpty {
                            optimizationTipsSection
                        }

                        // Statistics
                        if let stats = statistics {
                            statisticsSection(stats)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Sync Intelligence")
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    // MARK: - Health Score Card

    private func healthScoreCard(_ score: SyncHealthScore) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync Health")
                        .font(.headline)
                    Text(score.healthLevel.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.overallScore / 100))
                        .stroke(healthColor(score.overallScore), lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(String(format: "%.0f", score.overallScore))
                            .font(.title2)
                            .bold()
                        Text("/ 100")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Detailed metrics
            VStack(spacing: 12) {
                metricRow("Sync Reliability", value: score.syncReliability)
                metricRow("Data Integrity", value: score.dataIntegrity)
                metricRow("Network Efficiency", value: score.networkEfficiency)
                metricRow("Backup Coverage", value: score.backupCoverage)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func metricRow(_ title: String, value: Float) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(String(format: "%.0f%%", value))
                .font(.subheadline)
                .bold()
                .foregroundStyle(healthColor(value))
        }
    }

    private func healthColor(_ score: Float) -> Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .orange
        default: return .red
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                actionButton(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Sync Now",
                    color: .blue
                ) {
                    Task {
                        await performSync()
                    }
                }

                actionButton(
                    icon: "externaldrive.badge.timemachine",
                    title: "Backup",
                    color: .purple
                ) {
                    Task {
                        await createBackup()
                    }
                }

                actionButton(
                    icon: "checkmark.shield",
                    title: "Verify Data",
                    color: .green
                ) {
                    Task {
                        await verifyIntegrity()
                    }
                }

                actionButton(
                    icon: "arrow.down.circle",
                    title: "Prepare Offline",
                    color: .orange
                ) {
                    Task {
                        await prepareForOffline()
                    }
                }
            }
        }
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
    }

    // MARK: - Optimization Tips

    private var optimizationTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization Tips")
                .font(.headline)

            ForEach(optimizationTips) { tip in
                optimizationTipCard(tip)
            }
        }
    }

    private func optimizationTipCard(_ tip: SyncOptimizationTip) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForCategory(tip.category))
                .foregroundStyle(colorForImpact(tip.impact))
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tip.title)
                        .font(.subheadline)
                        .bold()

                    Spacer()

                    Text(tip.impact.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colorForImpact(tip.impact).opacity(0.2))
                        .cornerRadius(4)
                }

                Text(tip.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }

    private func iconForCategory(_ category: TipCategory) -> String {
        switch category {
        case .storage: return "internaldrive"
        case .network: return "wifi"
        case .timing: return "clock"
        case .conflicts: return "exclamationmark.triangle"
        case .backup: return "externaldrive"
        }
    }

    private func colorForImpact(_ impact: ImpactLevel) -> Color {
        switch impact {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    // MARK: - Statistics

    private func statisticsSection(_ stats: AggregatedStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statistics")
                    .font(.headline)

                Spacer()

                Picker("Period", selection: $selectedPeriod) {
                    Text("Day").tag(StatisticsPeriod.day)
                    Text("Week").tag(StatisticsPeriod.week)
                    Text("Month").tag(StatisticsPeriod.month)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            VStack(spacing: 16) {
                statRow(
                    "Total Syncs",
                    value: "\(stats.totalSyncs)",
                    icon: "arrow.triangle.2.circlepath"
                )

                statRow(
                    "Success Rate",
                    value: String(format: "%.1f%%", stats.successRate),
                    icon: "checkmark.circle"
                )

                statRow(
                    "Data Uploaded",
                    value: formatBytes(stats.dataUploaded),
                    icon: "arrow.up.circle"
                )

                statRow(
                    "Data Downloaded",
                    value: formatBytes(stats.dataDownloaded),
                    icon: "arrow.down.circle"
                )

                statRow(
                    "Conflicts Resolved",
                    value: "\(stats.conflictsResolved)/\(stats.conflictsDetected)",
                    icon: "exclamationmark.triangle"
                )

                statRow(
                    "Backups Created",
                    value: "\(stats.backupCount)",
                    icon: "externaldrive"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadStatistics()
            }
        }
    }

    private func statRow(_ label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .bold()
        }
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true

        if syncManager == nil {
            syncManager = IntelligentSyncManager(modelContext: modelContext)
        }

        if let manager = syncManager {
            healthScore = await manager.getSyncHealthScore()
            optimizationTips = await manager.getOptimizationTips()
            await loadStatistics()
        }

        isLoading = false
    }

    private func loadStatistics() async {
        if let manager = syncManager {
            statistics = await manager.getSyncStatistics(period: selectedPeriod)
        }
    }

    private func performSync() async {
        guard let manager = syncManager else { return }
        _ = await manager.performIntelligentSync()
        await loadData()
    }

    private func createBackup() async {
        guard let manager = syncManager else { return }
        _ = await manager.createManualBackup()
        await loadData()
    }

    private func verifyIntegrity() async {
        // TODO: Implement verify UI
    }

    private func prepareForOffline() async {
        guard let manager = syncManager else { return }
        _ = await manager.prepareForOffline(duration: 14400)  // 4 hours
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    SyncIntelligenceDashboard()
        .modelContainer(for: [
            SyncStatistics.self,
            IntelligentBackup.self,
            UserActivityPattern.self
        ])
}
