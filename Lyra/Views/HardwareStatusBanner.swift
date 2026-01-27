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

#Preview("Banner") {
    VStack {
        HardwareStatusBanner()
        Spacer()
    }
}
