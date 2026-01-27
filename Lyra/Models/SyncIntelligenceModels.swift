//
//  SyncIntelligenceModels.swift
//  Lyra
//
//  Phase 7.12: AI-Powered Sync and Backup Intelligence
//  Created on January 27, 2026
//

import Foundation
import SwiftData

// MARK: - Sync Intelligence Models

/// User activity pattern for intelligent sync timing
@Model
final class UserActivityPattern {
    @Attribute(.unique) var id: UUID
    var userID: String
    var hourOfDay: Int  // 0-23
    var dayOfWeek: Int  // 1-7 (1=Sunday)
    var averageActivityLevel: Float  // 0.0-1.0
    var editingSessions: Int
    var performanceSessions: Int
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        userID: String,
        hourOfDay: Int,
        dayOfWeek: Int,
        averageActivityLevel: Float = 0.0,
        editingSessions: Int = 0,
        performanceSessions: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.hourOfDay = hourOfDay
        self.dayOfWeek = dayOfWeek
        self.averageActivityLevel = averageActivityLevel
        self.editingSessions = editingSessions
        self.performanceSessions = performanceSessions
        self.lastUpdated = lastUpdated
    }
}

/// Tracks editing session patterns
@Model
final class EditingSession {
    @Attribute(.unique) var id: UUID
    var songID: UUID
    var startTime: Date
    var endTime: Date?
    var editCount: Int
    var isComplete: Bool
    var deviceContext: DeviceContext

    init(
        id: UUID = UUID(),
        songID: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        editCount: Int = 0,
        isComplete: Bool = false,
        deviceContext: DeviceContext = DeviceContext()
    ) {
        self.id = id
        self.songID = songID
        self.startTime = startTime
        self.endTime = endTime
        self.editCount = editCount
        self.isComplete = isComplete
        self.deviceContext = deviceContext
    }
}

/// Device and network context for intelligent decisions
struct DeviceContext: Codable {
    var batteryLevel: Float  // 0.0-1.0
    var isCharging: Bool
    var networkType: NetworkType
    var networkQuality: NetworkQuality
    var isLowPowerMode: Bool
    var thermalState: ThermalState

    init(
        batteryLevel: Float = 1.0,
        isCharging: Bool = false,
        networkType: NetworkType = .wifi,
        networkQuality: NetworkQuality = .excellent,
        isLowPowerMode: Bool = false,
        thermalState: ThermalState = .nominal
    ) {
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.networkType = networkType
        self.networkQuality = networkQuality
        self.isLowPowerMode = isLowPowerMode
        self.thermalState = thermalState
    }
}

enum NetworkType: String, Codable {
    case wifi = "WiFi"
    case cellular = "Cellular"
    case offline = "Offline"
}

enum NetworkQuality: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
}

enum ThermalState: String, Codable {
    case nominal = "Nominal"
    case fair = "Fair"
    case serious = "Serious"
    case critical = "Critical"
}

// MARK: - Predictive Sync Models

/// Predicted songs that user will need
@Model
final class PredictedSongUsage {
    @Attribute(.unique) var id: UUID
    var songID: UUID
    var predictionScore: Float  // 0.0-1.0
    var predictionReason: String  // PredictionReason raw value
    var predictedTime: Date
    var isPrefetched: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        songID: UUID,
        predictionScore: Float,
        predictionReason: PredictionReason,
        predictedTime: Date,
        isPrefetched: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.songID = songID
        self.predictionScore = predictionScore
        self.predictionReason = predictionReason.rawValue
        self.predictedTime = predictedTime
        self.isPrefetched = isPrefetched
        self.createdAt = createdAt
    }
}

enum PredictionReason: String, Codable {
    case upcomingSet = "Upcoming Set"
    case recentlyEdited = "Recently Edited"
    case frequentlyUsed = "Frequently Used"
    case timePattern = "Time Pattern"
    case offlinePeriod = "Offline Period Predicted"
    case setSequence = "Part of Set Sequence"
}

// MARK: - Conflict Prevention Models

/// Tracks potential conflicts before they occur
@Model
final class ConflictDetection {
    @Attribute(.unique) var id: UUID
    var recordID: String
    var recordType: String
    var conflictRisk: ConflictRisk
    var detectionTime: Date
    var isResolved: Bool
    var resolutionStrategy: String?  // ConflictResolution raw value

    init(
        id: UUID = UUID(),
        recordID: String,
        recordType: String,
        conflictRisk: ConflictRisk,
        detectionTime: Date = Date(),
        isResolved: Bool = false,
        resolutionStrategy: String? = nil
    ) {
        self.id = id
        self.recordID = recordID
        self.recordType = recordType
        self.conflictRisk = conflictRisk
        self.detectionTime = detectionTime
        self.isResolved = isResolved
        self.resolutionStrategy = resolutionStrategy
    }
}

enum ConflictRisk: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

enum ConflictResolution: String, Codable {
    case lock = "Lock for Editing"
    case queue = "Queue Changes"
    case merge = "Auto-Merge"
    case notify = "Notify User"
}

/// Edit lock to prevent concurrent modifications
@Model
final class EditLock {
    @Attribute(.unique) var id: UUID
    var recordID: String
    var recordType: String
    var deviceID: String
    var acquiredAt: Date
    var expiresAt: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        recordID: String,
        recordType: String,
        deviceID: String,
        acquiredAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(300),  // 5 min default
        isActive: Bool = true
    ) {
        self.id = id
        self.recordID = recordID
        self.recordType = recordType
        self.deviceID = deviceID
        self.acquiredAt = acquiredAt
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
}

// MARK: - Smart Backup Models

/// Backup snapshot with intelligent retention
@Model
final class IntelligentBackup {
    @Attribute(.unique) var id: UUID
    var backupType: String  // BackupType raw value
    var trigger: String  // BackupTrigger raw value
    var dataSize: Int64
    var recordCount: Int
    var importance: BackupImportance
    var createdAt: Date
    var retentionUntil: Date?
    var isCompressed: Bool
    var checksum: String

    init(
        id: UUID = UUID(),
        backupType: BackupType,
        trigger: BackupTrigger,
        dataSize: Int64,
        recordCount: Int,
        importance: BackupImportance,
        createdAt: Date = Date(),
        retentionUntil: Date? = nil,
        isCompressed: Bool = true,
        checksum: String = ""
    ) {
        self.id = id
        self.backupType = backupType.rawValue
        self.trigger = trigger.rawValue
        self.dataSize = dataSize
        self.recordCount = recordCount
        self.importance = importance
        self.createdAt = createdAt
        self.retentionUntil = retentionUntil
        self.isCompressed = isCompressed
        self.checksum = checksum
    }
}

enum BackupType: String, Codable {
    case full = "Full Backup"
    case incremental = "Incremental"
    case snapshot = "Snapshot"
}

enum BackupTrigger: String, Codable {
    case majorChange = "Major Change"
    case beforePerformance = "Before Performance"
    case scheduled = "Scheduled"
    case manual = "Manual"
    case preSync = "Pre-Sync"
}

enum BackupImportance: String, Codable, Comparable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    static func < (lhs: BackupImportance, rhs: BackupImportance) -> Bool {
        let order: [BackupImportance] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Data Integrity Models

/// Data integrity verification result
struct IntegrityCheckResult: Codable {
    var recordID: String
    var recordType: String
    var isValid: Bool
    var corruptionType: CorruptionType?
    var canAutoRepair: Bool
    var checkTime: Date
    var checksum: String

    init(
        recordID: String,
        recordType: String,
        isValid: Bool,
        corruptionType: CorruptionType? = nil,
        canAutoRepair: Bool = false,
        checkTime: Date = Date(),
        checksum: String = ""
    ) {
        self.recordID = recordID
        self.recordType = recordType
        self.isValid = isValid
        self.corruptionType = corruptionType
        self.canAutoRepair = canAutoRepair
        self.checkTime = checkTime
        self.checksum = checksum
    }
}

enum CorruptionType: String, Codable {
    case checksumMismatch = "Checksum Mismatch"
    case missingData = "Missing Data"
    case invalidFormat = "Invalid Format"
    case schemaViolation = "Schema Violation"
}

/// Stores integrity check history
@Model
final class IntegrityCheckHistory {
    @Attribute(.unique) var id: UUID
    var checkTime: Date
    var totalRecords: Int
    var validRecords: Int
    var corruptedRecords: Int
    var repairedRecords: Int
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        checkTime: Date = Date(),
        totalRecords: Int,
        validRecords: Int,
        corruptedRecords: Int,
        repairedRecords: Int,
        duration: TimeInterval
    ) {
        self.id = id
        self.checkTime = checkTime
        self.totalRecords = totalRecords
        self.validRecords = validRecords
        self.corruptedRecords = corruptedRecords
        self.repairedRecords = repairedRecords
        self.duration = duration
    }
}

// MARK: - Network Optimization Models

/// Delta sync tracking
@Model
final class DeltaSyncRecord {
    @Attribute(.unique) var id: UUID
    var recordID: String
    var recordType: String
    var lastSyncVersion: Int
    var deltaSize: Int64
    var fullSize: Int64
    var compressionRatio: Float
    var syncTime: Date

    init(
        id: UUID = UUID(),
        recordID: String,
        recordType: String,
        lastSyncVersion: Int,
        deltaSize: Int64,
        fullSize: Int64,
        compressionRatio: Float,
        syncTime: Date = Date()
    ) {
        self.id = id
        self.recordID = recordID
        self.recordType = recordType
        self.lastSyncVersion = lastSyncVersion
        self.deltaSize = deltaSize
        self.fullSize = fullSize
        self.compressionRatio = compressionRatio
        self.syncTime = syncTime
    }
}

// MARK: - Sync Insights Models

/// Overall sync health metrics
struct SyncHealthScore: Codable {
    var overallScore: Float  // 0.0-100.0
    var syncReliability: Float
    var dataIntegrity: Float
    var networkEfficiency: Float
    var backupCoverage: Float
    var conflictRate: Float
    var lastCalculated: Date

    init(
        overallScore: Float = 100.0,
        syncReliability: Float = 100.0,
        dataIntegrity: Float = 100.0,
        networkEfficiency: Float = 100.0,
        backupCoverage: Float = 100.0,
        conflictRate: Float = 0.0,
        lastCalculated: Date = Date()
    ) {
        self.overallScore = overallScore
        self.syncReliability = syncReliability
        self.dataIntegrity = dataIntegrity
        self.networkEfficiency = networkEfficiency
        self.backupCoverage = backupCoverage
        self.conflictRate = conflictRate
        self.lastCalculated = lastCalculated
    }

    var healthLevel: HealthLevel {
        switch overallScore {
        case 90...100: return .excellent
        case 70..<90: return .good
        case 50..<70: return .fair
        default: return .poor
        }
    }
}

enum HealthLevel: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
}

/// Sync optimization recommendations
struct SyncOptimizationTip: Codable, Identifiable {
    var id: UUID = UUID()
    var category: TipCategory
    var title: String
    var description: String
    var impact: ImpactLevel
    var actionable: Bool

    init(
        category: TipCategory,
        title: String,
        description: String,
        impact: ImpactLevel,
        actionable: Bool = true
    ) {
        self.category = category
        self.title = title
        self.description = description
        self.impact = impact
        self.actionable = actionable
    }
}

enum TipCategory: String, Codable {
    case storage = "Storage"
    case network = "Network"
    case timing = "Timing"
    case conflicts = "Conflicts"
    case backup = "Backup"
}

enum ImpactLevel: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

/// Sync statistics for insights
@Model
final class SyncStatistics {
    @Attribute(.unique) var id: UUID
    var period: Date  // Start of period (day/week/month)
    var totalSyncs: Int
    var successfulSyncs: Int
    var failedSyncs: Int
    var dataUploaded: Int64
    var dataDownloaded: Int64
    var conflictsDetected: Int
    var conflictsResolved: Int
    var averageSyncDuration: TimeInterval
    var backupCount: Int

    init(
        id: UUID = UUID(),
        period: Date,
        totalSyncs: Int = 0,
        successfulSyncs: Int = 0,
        failedSyncs: Int = 0,
        dataUploaded: Int64 = 0,
        dataDownloaded: Int64 = 0,
        conflictsDetected: Int = 0,
        conflictsResolved: Int = 0,
        averageSyncDuration: TimeInterval = 0,
        backupCount: Int = 0
    ) {
        self.id = id
        self.period = period
        self.totalSyncs = totalSyncs
        self.successfulSyncs = successfulSyncs
        self.failedSyncs = failedSyncs
        self.dataUploaded = dataUploaded
        self.dataDownloaded = dataDownloaded
        self.conflictsDetected = conflictsDetected
        self.conflictsResolved = conflictsResolved
        self.averageSyncDuration = averageSyncDuration
        self.backupCount = backupCount
    }
}

// MARK: - Recovery Intelligence Models

/// Data loss detection event
@Model
final class DataLossEvent {
    @Attribute(.unique) var id: UUID
    var detectionTime: Date
    var lossType: DataLossType
    var affectedRecords: [String]
    var severity: LossSeverity
    var canRecover: Bool
    var recoveryAttempted: Bool
    var recoverySuccessful: Bool
    var details: String

    init(
        id: UUID = UUID(),
        detectionTime: Date = Date(),
        lossType: DataLossType,
        affectedRecords: [String],
        severity: LossSeverity,
        canRecover: Bool,
        recoveryAttempted: Bool = false,
        recoverySuccessful: Bool = false,
        details: String = ""
    ) {
        self.id = id
        self.detectionTime = detectionTime
        self.lossType = lossType
        self.affectedRecords = affectedRecords
        self.severity = severity
        self.canRecover = canRecover
        self.recoveryAttempted = recoveryAttempted
        self.recoverySuccessful = recoverySuccessful
        self.details = details
    }
}

enum DataLossType: String, Codable {
    case deletion = "Accidental Deletion"
    case corruption = "Data Corruption"
    case syncFailure = "Sync Failure"
    case deviceFailure = "Device Failure"
}

enum LossSeverity: String, Codable {
    case minor = "Minor"
    case moderate = "Moderate"
    case major = "Major"
    case critical = "Critical"
}

/// Recovery action recommendation
struct RecoveryAction: Codable, Identifiable {
    var id: UUID = UUID()
    var actionType: RecoveryActionType
    var description: String
    var confidence: Float  // 0.0-1.0
    var estimatedRecovery: Float  // % of data recoverable
    var isAutomatic: Bool

    init(
        actionType: RecoveryActionType,
        description: String,
        confidence: Float,
        estimatedRecovery: Float,
        isAutomatic: Bool = false
    ) {
        self.actionType = actionType
        self.description = description
        self.confidence = confidence
        self.estimatedRecovery = estimatedRecovery
        self.isAutomatic = isAutomatic
    }
}

enum RecoveryActionType: String, Codable {
    case restoreBackup = "Restore from Backup"
    case mergeVersions = "Merge Versions"
    case rollback = "Rollback Changes"
    case repairData = "Repair Data"
    case contactSupport = "Contact Support"
}
