//
//  IntelligentSyncTimingEngine.swift
//  Lyra
//
//  Phase 7.12: Intelligent Sync Timing
//  Determines optimal sync timing based on user behavior and device state
//

import Foundation
import SwiftData
import UIKit

/// Determines optimal sync timing using on-device learning
@MainActor
class IntelligentSyncTimingEngine {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Sync Timing Decision

    /// Determines if now is a good time to sync
    func shouldSyncNow(userID: String = "default") async -> SyncTimingDecision {
        let deviceContext = await getCurrentDeviceContext()
        let activityLevel = await getCurrentActivityLevel(userID: userID)
        let editingStatus = await getEditingStatus()

        // Decision factors
        var score: Float = 100.0
        var blockers: [String] = []
        var reasons: [String] = []

        // 1. Check device state
        if deviceContext.isLowPowerMode {
            score -= 40
            blockers.append("Low power mode active")
        }

        if deviceContext.batteryLevel < 0.2 && !deviceContext.isCharging {
            score -= 30
            blockers.append("Low battery (<20%)")
        }

        if deviceContext.thermalState == .serious || deviceContext.thermalState == .critical {
            score -= 50
            blockers.append("Device thermal warning")
        }

        // 2. Check network
        switch deviceContext.networkType {
        case .offline:
            return SyncTimingDecision(
                shouldSync: false,
                confidence: 1.0,
                reason: "No network connection",
                blockers: ["Offline"],
                nextRecommendedTime: nil
            )
        case .cellular:
            if !CloudSyncManager.shared.allowCellularSync {
                return SyncTimingDecision(
                    shouldSync: false,
                    confidence: 1.0,
                    reason: "Cellular sync disabled",
                    blockers: ["Cellular only"],
                    nextRecommendedTime: nil
                )
            }
            score -= 20
            reasons.append("On cellular network")
        case .wifi:
            score += 10
            reasons.append("On WiFi")
        }

        if deviceContext.networkQuality == .poor {
            score -= 30
            blockers.append("Poor network quality")
        }

        // 3. Check user activity
        if activityLevel > 0.7 {
            score -= 40
            blockers.append("High user activity")
        } else if activityLevel < 0.3 {
            score += 20
            reasons.append("Low usage period")
        }

        // 4. Check editing status
        if editingStatus.isEditing {
            score -= 50
            blockers.append("User currently editing")
        } else if editingStatus.timeSinceLastEdit < 30 {
            score -= 20
            blockers.append("Recently edited (<30s ago)")
        } else if editingStatus.timeSinceLastEdit > 300 {
            score += 15
            reasons.append("Editing session likely complete")
        }

        // 5. Check performance mode
        if await isInPerformanceMode() {
            score -= 100  // Never sync during performance!
            blockers.append("Performance mode active")
        }

        // 6. Optimal timing bonus
        if await isOptimalSyncTime(userID: userID) {
            score += 25
            reasons.append("Optimal sync time based on patterns")
        }

        // 7. Charging bonus
        if deviceContext.isCharging && deviceContext.batteryLevel > 0.5 {
            score += 15
            reasons.append("Device charging")
        }

        // Make decision
        let shouldSync = score >= 50 && blockers.isEmpty
        let confidence = min(score / 100.0, 1.0)

        let mainReason: String
        if !shouldSync {
            mainReason = blockers.first ?? "Conditions not optimal"
        } else {
            mainReason = reasons.joined(separator: ", ")
        }

        let nextTime = shouldSync ? nil : await predictNextOptimalTime(userID: userID)

        return SyncTimingDecision(
            shouldSync: shouldSync,
            confidence: confidence,
            reason: mainReason,
            blockers: blockers,
            nextRecommendedTime: nextTime
        )
    }

    // MARK: - Activity Detection

    /// Gets current user activity level (0.0-1.0)
    private func getCurrentActivityLevel(userID: String) async -> Float {
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-300)

        let descriptor = FetchDescriptor<EditingSession>(
            predicate: #Predicate<EditingSession> { session in
                session.startTime >= fiveMinutesAgo
            }
        )

        do {
            let recentSessions = try modelContext.fetch(descriptor)
            let activeEdits = recentSessions.filter { $0.endTime == nil }

            // Calculate activity based on active sessions and edit frequency
            if !activeEdits.isEmpty {
                return 1.0  // Currently editing
            }

            let editCount = recentSessions.reduce(0) { $0 + $1.editCount }
            return min(Float(editCount) / 20.0, 1.0)  // 20+ edits = high activity

        } catch {
            print("❌ Failed to fetch activity level: \(error)")
            return 0.5  // Assume medium activity on error
        }
    }

    /// Predicts if user has finished editing
    func isProbablyDoneEditing(sessionID: UUID) async -> Float {
        let descriptor = FetchDescriptor<EditingSession>(
            predicate: #Predicate<EditingSession> { session in
                session.id == sessionID
            }
        )

        do {
            guard let session = try modelContext.fetch(descriptor).first else {
                return 0.0
            }

            let timeSinceEdit = Date().timeIntervalSince(session.startTime)
            let editRate = Float(session.editCount) / Float(max(timeSinceEdit / 60, 1))

            // Pattern detection
            // High edit count followed by long pause = likely done
            if session.editCount > 5 && timeSinceEdit > 120 {
                return 0.9
            }

            // Low edit rate and long pause = likely done
            if editRate < 1 && timeSinceEdit > 180 {
                return 0.85
            }

            // Recent activity = not done
            if timeSinceEdit < 60 {
                return 0.1
            }

            // Medium pause = uncertain
            return 0.5

        } catch {
            print("❌ Failed to check editing status: \(error)")
            return 0.5
        }
    }

    // MARK: - Device Context

    /// Gets current device and network context
    private func getCurrentDeviceContext() async -> DeviceContext {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let batteryLevel = device.batteryLevel == -1 ? 1.0 : device.batteryLevel
        let isCharging = device.batteryState == .charging || device.batteryState == .full

        // Get network status from OfflineManager
        let networkType: NetworkType
        let networkQuality: NetworkQuality

        if OfflineManager.shared.isOnline {
            networkType = OfflineManager.shared.isOnWiFi ? .wifi : .cellular
            // Estimate quality (in production, use NWPathMonitor)
            networkQuality = .good
        } else {
            networkType = .offline
            networkQuality = .poor
        }

        // Get thermal state
        let thermalState: ThermalState
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            thermalState = .nominal
        case .fair:
            thermalState = .fair
        case .serious:
            thermalState = .serious
        case .critical:
            thermalState = .critical
        @unknown default:
            thermalState = .nominal
        }

        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        return DeviceContext(
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            networkType: networkType,
            networkQuality: networkQuality,
            isLowPowerMode: isLowPowerMode,
            thermalState: thermalState
        )
    }

    /// Gets current editing status
    private func getEditingStatus() async -> EditingStatus {
        let descriptor = FetchDescriptor<EditingSession>(
            sortBy: [SortDescriptor(\EditingSession.startTime, order: .reverse)]
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            let activeSessions = sessions.filter { $0.endTime == nil }

            if let lastSession = sessions.first {
                let timeSinceEdit = Date().timeIntervalSince(lastSession.startTime)
                return EditingStatus(
                    isEditing: !activeSessions.isEmpty,
                    timeSinceLastEdit: timeSinceEdit
                )
            }

            return EditingStatus(isEditing: false, timeSinceLastEdit: 3600)
        } catch {
            print("❌ Failed to get editing status: \(error)")
            return EditingStatus(isEditing: false, timeSinceLastEdit: 3600)
        }
    }

    // MARK: - Pattern Learning

    /// Checks if current time matches learned patterns
    private func isOptimalSyncTime(userID: String) async -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)

        let descriptor = FetchDescriptor<UserActivityPattern>(
            predicate: #Predicate<UserActivityPattern> { pattern in
                pattern.userID == userID &&
                pattern.hourOfDay == hour &&
                pattern.dayOfWeek == weekday
            }
        )

        do {
            let patterns = try modelContext.fetch(descriptor)
            if let pattern = patterns.first {
                // Low activity = good time to sync
                return pattern.averageActivityLevel < 0.3
            }
            return false
        } catch {
            print("❌ Failed to check optimal sync time: \(error)")
            return false
        }
    }

    /// Predicts next optimal sync time
    private func predictNextOptimalTime(userID: String) async -> Date? {
        let now = Date()
        let calendar = Calendar.current

        // Look ahead 24 hours for optimal window
        for hoursAhead in 1...24 {
            guard let futureTime = calendar.date(byAdding: .hour, value: hoursAhead, to: now) else {
                continue
            }

            let hour = calendar.component(.hour, from: futureTime)
            let weekday = calendar.component(.weekday, from: futureTime)

            let descriptor = FetchDescriptor<UserActivityPattern>(
                predicate: #Predicate<UserActivityPattern> { pattern in
                    pattern.userID == userID &&
                    pattern.hourOfDay == hour &&
                    pattern.dayOfWeek == weekday
                }
            )

            do {
                let patterns = try modelContext.fetch(descriptor)
                if let pattern = patterns.first, pattern.averageActivityLevel < 0.3 {
                    return futureTime
                }
            } catch {
                continue
            }
        }

        // Default: try in 1 hour
        return calendar.date(byAdding: .hour, value: 1, to: now)
    }

    /// Checks if app is in performance mode
    private func isInPerformanceMode() async -> Bool {
        // Check if there's an active performance session
        // In production, integrate with PerformanceManager
        return false  // TODO: Integrate with actual performance tracking
    }

    // MARK: - Learning

    /// Records user activity for pattern learning
    func recordActivity(userID: String = "default", activityLevel: Float) async {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)

        let descriptor = FetchDescriptor<UserActivityPattern>(
            predicate: #Predicate<UserActivityPattern> { pattern in
                pattern.userID == userID &&
                pattern.hourOfDay == hour &&
                pattern.dayOfWeek == weekday
            }
        )

        do {
            let patterns = try modelContext.fetch(descriptor)

            if let existing = patterns.first {
                // Update with exponential moving average
                let alpha: Float = 0.1  // Smoothing factor
                existing.averageActivityLevel = alpha * activityLevel + (1 - alpha) * existing.averageActivityLevel
                existing.lastUpdated = now
            } else {
                // Create new pattern
                let pattern = UserActivityPattern(
                    userID: userID,
                    hourOfDay: hour,
                    dayOfWeek: weekday,
                    averageActivityLevel: activityLevel,
                    lastUpdated: now
                )
                modelContext.insert(pattern)
            }

            try modelContext.save()
        } catch {
            print("❌ Failed to record activity pattern: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct SyncTimingDecision {
    let shouldSync: Bool
    let confidence: Float  // 0.0-1.0
    let reason: String
    let blockers: [String]
    let nextRecommendedTime: Date?
}

struct EditingStatus {
    let isEditing: Bool
    let timeSinceLastEdit: TimeInterval
}
