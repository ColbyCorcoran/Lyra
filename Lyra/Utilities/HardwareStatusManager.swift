//
//  HardwareStatusManager.swift
//  Lyra
//
//  Coordinator for hardware status monitoring and user notifications
//  Provides bulletproof professional hardware event handling
//

import Foundation
import SwiftUI
import Observation
import AVFoundation

/// Hardware status notification coordinator for professional use
@Observable
class HardwareStatusManager {
    static let shared = HardwareStatusManager()

    // MARK: - Hardware Status

    /// Current hardware alerts
    private(set) var activeAlerts: [HardwareAlert] = []

    /// Hardware connection states
    var externalDisplayConnected: Bool = false
    var midiDeviceConnected: Bool = false
    var audioInterfaceConnected: Bool = false
    var footPedalConnected: Bool = false

    /// Show user notifications for hardware changes
    var showHardwareNotifications: Bool = true

    /// Auto-dismiss alerts after duration (seconds)
    var autoDismissSuccess: TimeInterval = 3.0
    var autoDismissInfo: TimeInterval = 5.0

    // MARK: - Initialization

    private init() {
        setupHardwareMonitoring()
    }

    // MARK: - Setup

    private func setupHardwareMonitoring() {
        // Listen for external display events
        NotificationCenter.default.addObserver(
            forName: .externalDisplayConnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleExternalDisplayConnected()
        }

        NotificationCenter.default.addObserver(
            forName: .externalDisplayDisconnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleExternalDisplayDisconnected()
        }

        // Listen for MIDI events
        NotificationCenter.default.addObserver(
            forName: .midiDeviceConnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleMIDIDeviceConnected(notification)
        }

        NotificationCenter.default.addObserver(
            forName: .midiDeviceDisconnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleMIDIDeviceDisconnected(notification)
        }

        // Listen for audio routing changes
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioRouteChange(notification)
        }
    }

    // MARK: - Hardware Event Handlers

    private func handleExternalDisplayConnected() {
        externalDisplayConnected = true

        if showHardwareNotifications {
            let alert = HardwareAlert(
                id: UUID(),
                type: .externalDisplay,
                status: .connected,
                message: "External Display Connected",
                detail: "Projection is now active",
                severity: .success,
                timestamp: Date()
            )

            addAlert(alert, autoDismissAfter: autoDismissSuccess)

            // Haptic feedback
            HapticManager.shared.success()
        }
    }

    private func handleExternalDisplayDisconnected() {
        externalDisplayConnected = false

        if showHardwareNotifications {
            let alert = HardwareAlert(
                id: UUID(),
                type: .externalDisplay,
                status: .disconnected,
                message: "External Display Disconnected",
                detail: "Displaying on iPad screen",
                severity: .warning,
                timestamp: Date(),
                actionLabel: "Reconnect",
                action: { [weak self] in
                    self?.attemptExternalDisplayReconnection()
                }
            )

            addAlert(alert)

            // Strong haptic for critical event
            HapticManager.shared.warning()
        }
    }

    private func handleMIDIDeviceConnected(_ notification: Notification) {
        midiDeviceConnected = true

        if showHardwareNotifications {
            let deviceName = notification.userInfo?["deviceName"] as? String ?? "MIDI Device"

            let alert = HardwareAlert(
                id: UUID(),
                type: .midiDevice,
                status: .connected,
                message: "\(deviceName) Connected",
                detail: "MIDI control is active",
                severity: .success,
                timestamp: Date()
            )

            addAlert(alert, autoDismissAfter: autoDismissSuccess)
            HapticManager.shared.selection()
        }
    }

    private func handleMIDIDeviceDisconnected(_ notification: Notification) {
        midiDeviceConnected = false

        if showHardwareNotifications {
            let deviceName = notification.userInfo?["deviceName"] as? String ?? "MIDI Device"

            let alert = HardwareAlert(
                id: UUID(),
                type: .midiDevice,
                status: .disconnected,
                message: "\(deviceName) Disconnected",
                detail: "Touch controls still available",
                severity: .warning,
                timestamp: Date()
            )

            addAlert(alert)
            HapticManager.shared.warning()
        }
    }

    private func handleAudioRouteChange(_ notification: Notification) {
        guard let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let changeReason = AVAudioSession.RouteChangeReason(rawValue: reason) else {
            return
        }

        switch changeReason {
        case .newDeviceAvailable:
            audioInterfaceConnected = true

            if showHardwareNotifications {
                let alert = HardwareAlert(
                    id: UUID(),
                    type: .audioInterface,
                    status: .connected,
                    message: "Audio Device Connected",
                    detail: "Audio routing updated",
                    severity: .info,
                    timestamp: Date()
                )

                addAlert(alert, autoDismissAfter: autoDismissInfo)
            }

        case .oldDeviceUnavailable:
            audioInterfaceConnected = false

            if showHardwareNotifications {
                let alert = HardwareAlert(
                    id: UUID(),
                    type: .audioInterface,
                    status: .disconnected,
                    message: "Audio Device Disconnected",
                    detail: "Using iPad speakers",
                    severity: .warning,
                    timestamp: Date()
                )

                addAlert(alert)
                HapticManager.shared.warning()
            }

        default:
            break
        }
    }

    // MARK: - Alert Management

    func addAlert(_ alert: HardwareAlert, autoDismissAfter duration: TimeInterval? = nil) {
        activeAlerts.append(alert)

        // Auto-dismiss if duration specified
        if let duration = duration {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                dismissAlert(alert.id)
            }
        }
    }

    func dismissAlert(_ id: UUID) {
        activeAlerts.removeAll { $0.id == id }
    }

    func dismissAll() {
        activeAlerts.removeAll()
    }

    // MARK: - Manual Alerts

    func showMIDIFloodingWarning() {
        let alert = HardwareAlert(
            id: UUID(),
            type: .midiDevice,
            status: .error,
            message: "MIDI Message Flooding",
            detail: "Throttling to 100 msg/sec",
            severity: .warning,
            timestamp: Date(),
            actionLabel: "MIDI Panic",
            action: {
                Task { @MainActor in
                    await MIDIManager.shared.sendAllNotesOff()
                }
            }
        )

        addAlert(alert)
        HapticManager.shared.warning()
    }

    func showPerformanceWarning(_ message: String, detail: String) {
        let alert = HardwareAlert(
            id: UUID(),
            type: .performance,
            status: .warning,
            message: message,
            detail: detail,
            severity: .warning,
            timestamp: Date()
        )

        addAlert(alert, autoDismissAfter: 5.0)
    }

    func showFootPedalBatteryLow() {
        let alert = HardwareAlert(
            id: UUID(),
            type: .footPedal,
            status: .warning,
            message: "Foot Pedal Battery Low",
            detail: "Replace batteries soon",
            severity: .warning,
            timestamp: Date()
        )

        addAlert(alert)
    }

    // MARK: - Reconnection Attempts

    private func attemptExternalDisplayReconnection() {
        Task { @MainActor in
            ExternalDisplayManager.shared.scanForExternalDisplays()

            if let display = ExternalDisplayManager.shared.externalDisplays.first {
                ExternalDisplayManager.shared.connectToDisplay(display)

                let alert = HardwareAlert(
                    id: UUID(),
                    type: .externalDisplay,
                    status: .connected,
                    message: "Display Reconnected",
                    detail: "Projection resumed",
                    severity: .success,
                    timestamp: Date()
                )

                addAlert(alert, autoDismissAfter: autoDismissSuccess)
            } else {
                let alert = HardwareAlert(
                    id: UUID(),
                    type: .externalDisplay,
                    status: .error,
                    message: "No Display Found",
                    detail: "Check HDMI connection",
                    severity: .error,
                    timestamp: Date()
                )

                addAlert(alert)
            }
        }
    }

    // MARK: - Health Check

    /// Pre-performance hardware health check
    func performHealthCheck() -> HardwareHealthReport {
        var issues: [String] = []
        var warnings: [String] = []

        // Check external display
        if !externalDisplayConnected {
            warnings.append("No external display connected")
        }

        // Check MIDI
        if !midiDeviceConnected {
            warnings.append("No MIDI device connected")
        }

        // Check performance
        let perfManager = PerformanceManager.shared
        if perfManager.currentFPS < 30 {
            issues.append("Low frame rate: \(Int(perfManager.currentFPS)) fps")
        }

        if perfManager.memoryUsageMB > 400 {
            warnings.append("High memory usage: \(Int(perfManager.memoryUsageMB)) MB")
        }

        // Check battery
        if perfManager.batteryLevel < 0.2 {
            issues.append("Low battery: \(Int(perfManager.batteryLevel * 100))%")
        } else if perfManager.batteryLevel < 0.3 {
            warnings.append("Battery below 30%")
        }

        return HardwareHealthReport(
            timestamp: Date(),
            allSystemsGo: issues.isEmpty,
            criticalIssues: issues,
            warnings: warnings,
            connectedHardware: [
                "External Display": externalDisplayConnected,
                "MIDI Device": midiDeviceConnected,
                "Audio Interface": audioInterfaceConnected,
                "Foot Pedal": footPedalConnected
            ]
        )
    }
}

// MARK: - Models

struct HardwareAlert: Identifiable, Equatable {
    let id: UUID
    let type: HardwareType
    let status: HardwareStatus
    let message: String
    let detail: String
    let severity: AlertSeverity
    let timestamp: Date
    var actionLabel: String?
    var action: (() -> Void)?

    static func == (lhs: HardwareAlert, rhs: HardwareAlert) -> Bool {
        lhs.id == rhs.id
    }
}

enum HardwareType: String {
    case externalDisplay = "External Display"
    case midiDevice = "MIDI Device"
    case audioInterface = "Audio Interface"
    case footPedal = "Foot Pedal"
    case performance = "Performance"
}

enum HardwareStatus {
    case connected
    case disconnected
    case error
    case warning
    case info
}

enum AlertSeverity {
    case success
    case info
    case warning
    case error

    var color: Color {
        switch self {
        case .success: return .green
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct HardwareHealthReport {
    let timestamp: Date
    let allSystemsGo: Bool
    let criticalIssues: [String]
    let warnings: [String]
    let connectedHardware: [String: Bool]

    var grade: String {
        if !criticalIssues.isEmpty {
            return "Fail"
        } else if warnings.count >= 3 {
            return "Fair"
        } else if warnings.count >= 1 {
            return "Good"
        } else {
            return "Excellent"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let externalDisplayConnected = Notification.Name("externalDisplayConnected")
    static let externalDisplayDisconnected = Notification.Name("externalDisplayDisconnected")
    static let midiDeviceConnected = Notification.Name("midiDeviceConnected")
    static let midiDeviceDisconnected = Notification.Name("midiDeviceDisconnected")
}
