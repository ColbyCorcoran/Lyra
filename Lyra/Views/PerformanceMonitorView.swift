//
//  PerformanceMonitorView.swift
//  Lyra
//
//  Real-time performance monitoring for developers
//  Display FPS, memory, CPU, battery metrics
//

import SwiftUI
import Charts

struct PerformanceMonitorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var performanceManager = PerformanceManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // Performance Grade
                gradeSection

                // Real-Time Metrics
                metricsSection

                // Performance Charts
                chartsSection

                // Actions
                actionsSection

                // Recommendations
                recommendationsSection
            }
            .navigationTitle("Performance Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Grade Section

    private var gradeSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Grade")
                        .font(.headline)

                    Text("Overall system performance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(gradeColor.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(performanceManager.performanceScore) / 100)
                        .stroke(gradeColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text(performanceManager.performanceGrade)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(gradeColor)

                        Text("\(performanceManager.performanceScore)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var gradeColor: Color {
        let score = performanceManager.performanceScore
        switch score {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .yellow
        case 60..<70: return .orange
        default: return .red
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        Section("Real-Time Metrics") {
            MetricRow(
                icon: "speedometer",
                label: "Frame Rate",
                value: String(format: "%.1f FPS", performanceManager.currentFPS),
                target: String(format: "%.0f FPS", PerformanceManager.PerformanceTargets.targetFPS),
                isGood: performanceManager.currentFPS >= PerformanceManager.PerformanceTargets.minAcceptableFPS
            )

            MetricRow(
                icon: "memorychip",
                label: "Memory Usage",
                value: String(format: "%.0f MB", performanceManager.memoryUsageMB),
                target: String(format: "< %.0f MB", PerformanceManager.PerformanceTargets.maxMemoryMB),
                isGood: performanceManager.memoryUsageMB < PerformanceManager.PerformanceTargets.maxMemoryMB
            )

            MetricRow(
                icon: "cpu",
                label: "CPU Usage",
                value: String(format: "%.1f%%", performanceManager.cpuUsage),
                target: String(format: "< %.0f%%", PerformanceManager.PerformanceTargets.maxCPUUsage),
                isGood: performanceManager.cpuUsage < PerformanceManager.PerformanceTargets.maxCPUUsage
            )

            MetricRow(
                icon: "battery.100",
                label: "Battery",
                value: batteryDescription,
                target: batteryStateDescription,
                isGood: performanceManager.batteryLevel > 0.2
            )
        }
    }

    private var batteryDescription: String {
        if performanceManager.batteryLevel < 0 {
            return "Unknown"
        }
        return String(format: "%.0f%%", performanceManager.batteryLevel * 100)
    }

    private var batteryStateDescription: String {
        switch performanceManager.batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "On Battery"
        default: return "Unknown"
        }
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        Section("Performance History") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Frame Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Average: \(String(format: "%.1f", performanceManager.averageFPS)) FPS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Memory Usage")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Average: \(String(format: "%.0f", performanceManager.averageMemoryUsage)) MB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                performanceManager.clearCaches()
                HapticManager.shared.success()
            } label: {
                Label("Clear Caches", systemImage: "trash")
            }

            Button {
                performanceManager.clearAllCaches()
                HapticManager.shared.success()
            } label: {
                Label("Clear All Caches (Including Disk)", systemImage: "trash.fill")
            }

            Toggle("Aggressive Memory Optimization", isOn: $performanceManager.aggressiveMemoryOptimization)

            Toggle("GPU Acceleration", isOn: $performanceManager.gpuAccelerationEnabled)

            Toggle("Lazy Loading", isOn: $performanceManager.lazyLoadingEnabled)
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        Section("Recommendations") {
            if performanceManager.currentFPS < PerformanceManager.PerformanceTargets.minAcceptableFPS {
                RecommendationRow(
                    icon: "exclamationmark.triangle",
                    text: "Low frame rate detected. Try clearing caches or reducing visual effects.",
                    color: .orange
                )
            }

            if performanceManager.memoryUsageMB > PerformanceManager.PerformanceTargets.maxMemoryMB {
                RecommendationRow(
                    icon: "exclamationmark.triangle",
                    text: "High memory usage. Clear caches to free up memory.",
                    color: .red
                )
            }

            if performanceManager.cpuUsage > PerformanceManager.PerformanceTargets.maxCPUUsage {
                RecommendationRow(
                    icon: "exclamationmark.triangle",
                    text: "High CPU usage. Close background apps or enable Low Power Mode.",
                    color: .orange
                )
            }

            if performanceManager.isLowPowerModeEnabled {
                RecommendationRow(
                    icon: "info.circle",
                    text: "Low Power Mode is active. Some features are reduced to save battery.",
                    color: .blue
                )
            }

            if performanceManager.performanceScore >= 90 {
                RecommendationRow(
                    icon: "checkmark.circle",
                    text: "Performance is excellent. All systems operating optimally.",
                    color: .green
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let target: String
    let isGood: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isGood ? .green : .orange)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)

                Text("Target: \(target)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(isGood ? .primary : .orange)
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    PerformanceMonitorView()
}
