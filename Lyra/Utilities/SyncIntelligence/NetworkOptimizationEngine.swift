//
//  NetworkOptimizationEngine.swift
//  Lyra
//
//  Phase 7.12: Network Optimization
//  Optimizes sync with compression, delta sync, and adaptive quality
//

import Foundation
import SwiftData
import Compression

/// Optimizes network usage during sync
@MainActor
class NetworkOptimizationEngine {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Compression

    /// Compresses data intelligently based on type and size
    func compressData(_ data: Data, recordType: String) async -> CompressionResult {
        let originalSize = Int64(data.count)

        // Skip compression for small data (< 1KB)
        if data.count < 1024 {
            return CompressionResult(
                originalSize: originalSize,
                compressedSize: originalSize,
                compressionRatio: 1.0,
                algorithm: "none"
            )
        }

        // Choose algorithm based on data type
        let algorithm: CompressionAlgorithm = recordType == "Song" ? .lzfse : .lz4

        guard let compressed = try? (data as NSData).compressed(using: algorithm) as Data else {
            return CompressionResult(
                originalSize: originalSize,
                compressedSize: originalSize,
                compressionRatio: 1.0,
                algorithm: "none"
            )
        }

        let compressedSize = Int64(compressed.count)
        let ratio = Float(compressedSize) / Float(originalSize)

        return CompressionResult(
            originalSize: originalSize,
            compressedSize: compressedSize,
            compressionRatio: ratio,
            algorithm: String(describing: algorithm)
        )
    }

    // MARK: - Delta Sync

    /// Calculates delta (changes only) for sync
    func calculateDelta(recordID: String, recordType: String, currentData: Data) async -> DeltaResult {
        // Get last synced version
        let descriptor = FetchDescriptor<DeltaSyncRecord>(
            predicate: #Predicate<DeltaSyncRecord> { record in
                record.recordID == recordID &&
                record.recordType == recordType
            },
            sortBy: [SortDescriptor(\DeltaSyncRecord.syncTime, order: .reverse)]
        )

        do {
            guard let lastSync = try modelContext.fetch(descriptor).first else {
                // No previous version - send full data
                return DeltaResult(
                    isDelta: false,
                    deltaSize: Int64(currentData.count),
                    fullSize: Int64(currentData.count),
                    savings: 0
                )
            }

            // TODO: Implement actual delta calculation
            // For now: simulate with simple size comparison
            let estimatedDeltaSize = Int64(Float(currentData.count) * 0.3)  // Assume 30% change

            // Create new delta record
            let newDelta = DeltaSyncRecord(
                recordID: recordID,
                recordType: recordType,
                lastSyncVersion: lastSync.lastSyncVersion + 1,
                deltaSize: estimatedDeltaSize,
                fullSize: Int64(currentData.count),
                compressionRatio: Float(estimatedDeltaSize) / Float(currentData.count)
            )
            modelContext.insert(newDelta)
            try modelContext.save()

            let savings = Int64(currentData.count) - estimatedDeltaSize

            return DeltaResult(
                isDelta: true,
                deltaSize: estimatedDeltaSize,
                fullSize: Int64(currentData.count),
                savings: savings
            )

        } catch {
            print("❌ Failed to calculate delta: \(error)")
            return DeltaResult(
                isDelta: false,
                deltaSize: Int64(currentData.count),
                fullSize: Int64(currentData.count),
                savings: 0
            )
        }
    }

    // MARK: - Adaptive Quality

    /// Adjusts sync quality based on network speed
    func determineAdaptiveQuality(networkSpeed: NetworkSpeed) async -> SyncQuality {
        switch networkSpeed {
        case .excellent:
            return .full  // Full quality, all data

        case .good:
            return .high  // High quality, minor optimizations

        case .moderate:
            return .medium  // Medium quality, delta sync

        case .poor:
            return .low  // Low quality, essential only

        case .veryPoor:
            return .essential  // Bare minimum
        }
    }

    /// Estimates network speed
    func estimateNetworkSpeed() async -> NetworkSpeed {
        // TODO: Implement actual network speed test
        // For now: return based on network type

        if OfflineManager.shared.isOnWiFi {
            return .excellent
        } else {
            return .moderate
        }
    }

    // MARK: - Background Downloads

    /// Schedules background download
    func scheduleBackgroundDownload(recordIDs: [String], priority: DownloadPriority) async {
        print("📥 Scheduling background download for \(recordIDs.count) records")

        // TODO: Use URLSession background configuration
        // For now: simulate scheduling
        for recordID in recordIDs {
            print("  - Queued: \(recordID) (Priority: \(priority.rawValue))")
        }
    }

    /// Manages download queue based on network conditions
    func optimizeDownloadQueue() async {
        let networkSpeed = await estimateNetworkSpeed()
        let quality = await determineAdaptiveQuality(networkSpeed: networkSpeed)

        print("📊 Network speed: \(networkSpeed.rawValue), Quality: \(quality.rawValue)")

        // Adjust queue based on quality
        switch quality {
        case .full, .high:
            // Process all pending downloads
            break

        case .medium:
            // Process high-priority only
            break

        case .low:
            // Process essential only
            break

        case .essential:
            // Pause non-critical downloads
            break
        }
    }

    // MARK: - Bandwidth Management

    /// Calculates optimal batch size based on network
    func calculateOptimalBatchSize(networkSpeed: NetworkSpeed) -> Int {
        switch networkSpeed {
        case .excellent:
            return 50  // Large batches

        case .good:
            return 30

        case .moderate:
            return 15

        case .poor:
            return 5

        case .veryPoor:
            return 1  // One at a time
        }
    }

    /// Estimates data usage for sync operation
    func estimateDataUsage(recordCount: Int, averageRecordSize: Int64) -> DataUsageEstimate {
        let uncompressedSize = Int64(recordCount) * averageRecordSize
        let compressedSize = Int64(Float(uncompressedSize) * 0.4)  // Assume 60% compression

        return DataUsageEstimate(
            recordCount: recordCount,
            uncompressedSize: uncompressedSize,
            compressedSize: compressedSize,
            estimatedTime: calculateEstimatedTime(dataSize: compressedSize)
        )
    }

    private func calculateEstimatedTime(dataSize: Int64) -> TimeInterval {
        let networkSpeed = OfflineManager.shared.isOnWiFi ? 1_000_000 : 100_000  // bytes/sec
        return Double(dataSize) / Double(networkSpeed)
    }

    // MARK: - Statistics

    /// Tracks bandwidth savings from optimizations
    func calculateBandwidthSavings(period: TimeInterval) async -> BandwidthSavings {
        let since = Date().addingTimeInterval(-period)

        let descriptor = FetchDescriptor<DeltaSyncRecord>(
            predicate: #Predicate<DeltaSyncRecord> { record in
                record.syncTime >= since
            }
        )

        do {
            let records = try modelContext.fetch(descriptor)

            let totalDeltaSize = records.reduce(0) { $0 + $1.deltaSize }
            let totalFullSize = records.reduce(0) { $0 + $1.fullSize }
            let savings = totalFullSize - totalDeltaSize

            return BandwidthSavings(
                period: period,
                totalDataSent: totalDeltaSize,
                dataSaved: savings,
                savingsPercentage: totalFullSize > 0 ? Float(savings) / Float(totalFullSize) * 100 : 0
            )

        } catch {
            print("❌ Failed to calculate bandwidth savings: \(error)")
            return BandwidthSavings(period: period, totalDataSent: 0, dataSaved: 0, savingsPercentage: 0)
        }
    }
}

// MARK: - Supporting Types

struct CompressionResult {
    let originalSize: Int64
    let compressedSize: Int64
    let compressionRatio: Float
    let algorithm: String

    var savedBytes: Int64 {
        originalSize - compressedSize
    }

    var savingsPercentage: Float {
        guard originalSize > 0 else { return 0 }
        return (1 - compressionRatio) * 100
    }
}

struct DeltaResult {
    let isDelta: Bool
    let deltaSize: Int64
    let fullSize: Int64
    let savings: Int64

    var savingsPercentage: Float {
        guard fullSize > 0 else { return 0 }
        return Float(savings) / Float(fullSize) * 100
    }
}

enum NetworkSpeed: String {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"
    case veryPoor = "Very Poor"
}

enum SyncQuality: String {
    case full = "Full Quality"
    case high = "High Quality"
    case medium = "Medium Quality"
    case low = "Low Quality"
    case essential = "Essential Only"
}

enum DownloadPriority: String {
    case critical = "Critical"
    case high = "High"
    case normal = "Normal"
    case low = "Low"
}

struct DataUsageEstimate {
    let recordCount: Int
    let uncompressedSize: Int64
    let compressedSize: Int64
    let estimatedTime: TimeInterval
}

struct BandwidthSavings {
    let period: TimeInterval
    let totalDataSent: Int64
    let dataSaved: Int64
    let savingsPercentage: Float
}
