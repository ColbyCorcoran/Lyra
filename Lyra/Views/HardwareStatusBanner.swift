//
//  HardwareStatusBanner.swift
//  Lyra
//
//  Professional hardware status notifications for live performance
//  Displays critical hardware events with visual feedback
//

import SwiftUI

struct HardwareStatusBanner: View {
    @State private var hardwareManager = HardwareStatusManager.shared

    var body: some View {
        VStack(spacing: 8) {
            ForEach(hardwareManager.activeAlerts) { alert in
                alertBanner(for: alert)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hardwareManager.activeAlerts.count)
    }

    // MARK: - Alert Banner

    private func alertBanner(for alert: HardwareAlert) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: alert.severity.icon)
                .font(.title3)
                .foregroundStyle(alert.severity.color)
                .frame(width: 28)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(alert.message)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(alert.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action button (if provided)
            if let actionLabel = alert.actionLabel, let action = alert.action {
                Button {
                    action()
                    hardwareManager.dismissAlert(alert.id)
                } label: {
                    Text(actionLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(alert.severity.color)
                }
                .buttonStyle(.borderless)
            }

            // Dismiss button
            Button {
                withAnimation {
                    hardwareManager.dismissAlert(alert.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            alert.severity.color.opacity(0.15)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(alert.severity.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Hardware Health Check View

struct HardwareHealthCheckView: View {
    @State private var hardwareManager = HardwareStatusManager.shared
    @State private var performanceManager = PerformanceManager.shared
    @State private var healthReport: HardwareHealthReport?
    @State private var showDetails: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Pre-Performance Check")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Run Check") {
                    performCheck()
                }
                .buttonStyle(.borderedProminent)
            }

            // Results
            if let report = healthReport {
                VStack(spacing: 16) {
                    // Overall status
                    overallStatusCard(report: report)

                    // Critical issues
                    if !report.criticalIssues.isEmpty {
                        issuesSection(
                            title: "Critical Issues",
                            items: report.criticalIssues,
                            color: .red
                        )
                    }

                    // Warnings
                    if !report.warnings.isEmpty {
                        issuesSection(
                            title: "Warnings",
                            items: report.warnings,
                            color: .orange
                        )
                    }

                    // Hardware status
                    hardwareStatusSection(report: report)

                    // Performance metrics
                    if showDetails {
                        performanceMetricsSection()
                    }

                    Button {
                        withAnimation {
                            showDetails.toggle()
                        }
                    } label: {
                        Label(
                            showDetails ? "Hide Details" : "Show Details",
                            systemImage: showDetails ? "chevron.up" : "chevron.down"
                        )
                    }
                }
            } else {
                // Initial state
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Run a health check before your performance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Overall Status Card

    private func overallStatusCard(report: HardwareHealthReport) -> some View {
        VStack(spacing: 12) {
            // Grade indicator
            ZStack {
                Circle()
                    .fill(gradeColor(report.grade).opacity(0.2))
                    .frame(width: 100, height: 100)

                VStack(spacing: 4) {
                    Text(report.grade)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(gradeColor(report.grade))

                    if report.allSystemsGo {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                }
            }

            Text(report.allSystemsGo ? "All Systems Go" : "Issues Detected")
                .font(.headline)

            Text("Checked \(report.timestamp.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Issues Section

    private func issuesSection(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(color)

            ForEach(items, id: \.self) { item in
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(color)

                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Hardware Status

    private func hardwareStatusSection(report: HardwareHealthReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hardware Status")
                .font(.headline)

            ForEach(report.connectedHardware.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(value ? .green : .secondary)

                    Text(key)
                        .font(.subheadline)

                    Spacer()

                    Text(value ? "Connected" : "Not Connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Performance Metrics

    private func performanceMetricsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)

            HStack {
                metricRow(label: "FPS", value: "\(Int(performanceManager.currentFPS))", target: "60")
                metricRow(label: "Memory", value: "\(Int(performanceManager.memoryUsageMB)) MB", target: "<500")
            }

            HStack {
                metricRow(label: "CPU", value: "\(Int(performanceManager.cpuUsage))%", target: "<60%")
                metricRow(label: "Battery", value: "\(Int(performanceManager.batteryLevel * 100))%", target: ">30%")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metricRow(label: String, value: String, target: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)

            Text("Target: \(target)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .orange
        case "Fail": return .red
        default: return .gray
        }
    }

    private func performCheck() {
        withAnimation {
            healthReport = hardwareManager.performHealthCheck()
        }

        // Haptic feedback
        if healthReport?.allSystemsGo == true {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.warning()
        }
    }
}

// MARK: - Preview

#Preview("Banner") {
    VStack {
        HardwareStatusBanner()
            .onAppear {
                // Add sample alerts
                HardwareStatusManager.shared.addAlert(
                    HardwareAlert(
                        id: UUID(),
                        type: .externalDisplay,
                        status: .connected,
                        message: "External Display Connected",
                        detail: "Projection is now active",
                        severity: .success,
                        timestamp: Date()
                    )
                )

                HardwareStatusManager.shared.addAlert(
                    HardwareAlert(
                        id: UUID(),
                        type: .midiDevice,
                        status: .disconnected,
                        message: "MIDI Device Disconnected",
                        detail: "Touch controls still available",
                        severity: .warning,
                        timestamp: Date(),
                        actionLabel: "Reconnect",
                        action: {}
                    )
                )
            }

        Spacer()
    }
}

#Preview("Health Check") {
    HardwareHealthCheckView()
}
