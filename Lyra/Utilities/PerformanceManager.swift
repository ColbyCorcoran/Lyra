//
//  PerformanceManager.swift
//  Lyra
//
//  Comprehensive performance monitoring and optimization
//  Target: 60fps, <2s launch, efficient memory usage
//

import Foundation
import SwiftUI
import Observation
import os.signpost

/// Performance monitoring and optimization coordinator
@Observable
class PerformanceManager {
    static let shared = PerformanceManager()

    // MARK: - Performance Metrics

    /// Current frame rate (frames per second)
    var currentFPS: Double = 60.0

    /// Memory usage in megabytes
    var memoryUsageMB: Double = 0

    /// CPU usage percentage
    var cpuUsage: Double = 0

    /// Battery level
    var batteryLevel: Float = 1.0

    /// Battery state
    var batteryState: UIDevice.BatteryState = .unknown

    /// Network latency in milliseconds
    var networkLatency: TimeInterval = 0

    /// Audio latency in milliseconds
    var audioLatency: TimeInterval = 0

    /// Is low power mode enabled
    var isLowPowerModeEnabled: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled

    // MARK: - Performance Targets

    struct PerformanceTargets {
        static let targetFPS: Double = 60.0
        static let minAcceptableFPS: Double = 30.0
        static let maxMemoryMB: Double = 500.0
        static let maxCPUUsage: Double = 60.0
        static let maxAudioLatencyMS: TimeInterval = 10.0
        static let maxMIDILatencyMS: TimeInterval = 5.0
        static let maxDisplayLatencyMS: TimeInterval = 16.67 // 60fps
        static let maxNetworkLatencyMS: TimeInterval = 100.0
        static let targetLaunchTimeS: TimeInterval = 2.0
    }

    // MARK: - Optimization Settings

    /// Enable aggressive memory optimization
    var aggressiveMemoryOptimization: Bool = false

    /// Enable GPU acceleration
    var gpuAccelerationEnabled: Bool = true

    /// Enable image caching
    var imageCachingEnabled: Bool = true

    /// Enable lazy loading
    var lazyLoadingEnabled: Bool = true

    /// Pagination size for large lists
    var paginationSize: Int = 50

    /// Preload distance (items to load ahead)
    var preloadDistance: Int = 10

    // MARK: - Monitoring State

    private var displayLink: CADisplayLink?
    private var displayLinkTarget: DisplayLinkTarget?
    private var fpsCounter: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var memoryUpdateTimer: Timer?
    private var signpostLog: OSLog

    // MARK: - Performance History

    private var fpsHistory: [Double] = []
    private var memoryHistory: [Double] = []
    private var maxHistorySize: Int = 100

    // MARK: - Initialization

    private init() {
        signpostLog = OSLog(subsystem: "com.lyra.performance", category: .pointsOfInterest)
        setupMonitoring()
        registerNotifications()
    }

    // MARK: - Monitoring Setup

    private func setupMonitoring() {
        // Monitor FPS using CADisplayLink with helper target
        displayLinkTarget = DisplayLinkTarget { [weak self] in
            self?.updateFPS()
        }
        displayLink = CADisplayLink(target: displayLinkTarget!, selector: #selector(DisplayLinkTarget.handleDisplayLink))
        displayLink?.add(to: .main, forMode: .common)

        // Monitor memory usage
        memoryUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
            self?.updateCPUUsage()
        }

        // Monitor battery
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryInfo()
    }

    private func registerNotifications() {
        // Battery state changes
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBatteryInfo()
        }

        // Battery level changes
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBatteryInfo()
        }

        // Low power mode changes
        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleLowPowerModeChange()
        }

        // Memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }

    // MARK: - FPS Monitoring

    private func updateFPS() {
        guard let displayLink = displayLink else { return }

        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }

        fpsCounter += 1

        let elapsed = displayLink.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            let fps = Double(fpsCounter) / elapsed
            currentFPS = fps
            fpsHistory.append(fps)

            if fpsHistory.count > maxHistorySize {
                fpsHistory.removeFirst()
            }

            fpsCounter = 0
            lastTimestamp = displayLink.timestamp

            // Check for performance issues
            if fps < PerformanceTargets.minAcceptableFPS {
                handleLowFrameRate(fps)
            }
        }
    }

    // MARK: - Memory Monitoring

    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            memoryUsageMB = usedMB
            memoryHistory.append(usedMB)

            if memoryHistory.count > maxHistorySize {
                memoryHistory.removeFirst()
            }

            // Check for memory issues
            if usedMB > PerformanceTargets.maxMemoryMB {
                handleHighMemoryUsage(usedMB)
            }
        }
    }

    private func updateCPUUsage() {
        var totalUsageOfCPU: Double = 0.0
        var threadsList = UnsafeMutablePointer<thread_act_t>(bitPattern: 0)
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }

        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<Int(threadsCount) {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }

                guard infoResult == KERN_SUCCESS else {
                    continue
                }

                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                }
            }

            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }

        cpuUsage = totalUsageOfCPU

        // Check for high CPU usage
        if totalUsageOfCPU > PerformanceTargets.maxCPUUsage {
            handleHighCPUUsage(totalUsageOfCPU)
        }
    }

    // MARK: - Battery Monitoring

    private func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }

    // MARK: - Performance Issue Handlers

    private func handleLowFrameRate(_ fps: Double) {
        os_signpost(.event, log: signpostLog, name: "Low FPS", "FPS: %.1f", fps)

        // Enable performance optimizations
        if !aggressiveMemoryOptimization {
            enableAggressiveOptimizations()
        }
    }

    private func handleHighMemoryUsage(_ memoryMB: Double) {
        os_signpost(.event, log: signpostLog, name: "High Memory", "Memory: %.1f MB", memoryMB)

        // Trigger memory cleanup
        clearCaches()
        releaseUnusedResources()
    }

    private func handleHighCPUUsage(_ usage: Double) {
        os_signpost(.event, log: signpostLog, name: "High CPU", "CPU: %.1f%%", usage)

        // Reduce background processing
        if !isLowPowerModeEnabled {
            reduceBackgroundProcessing()
        }
    }

    private func handleMemoryWarning() {
        os_signpost(.event, log: signpostLog, name: "Memory Warning")

        // Aggressive cleanup
        clearAllCaches()
        releaseUnusedResources()

        // Notify other managers
        NotificationCenter.default.post(name: .performanceMemoryWarning, object: nil)
    }

    private func handleLowPowerModeChange() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

        if isLowPowerModeEnabled {
            enableLowPowerOptimizations()
        } else {
            disableLowPowerOptimizations()
        }
    }

    // MARK: - Optimization Actions

    private func enableAggressiveOptimizations() {
        aggressiveMemoryOptimization = true
        clearCaches()
        reduceBackgroundProcessing()
    }

    private func enableLowPowerOptimizations() {
        // Reduce refresh rates
        displayLink?.preferredFramesPerSecond = 30

        // Disable non-essential features
        gpuAccelerationEnabled = false

        // Reduce background work
        reduceBackgroundProcessing()
    }

    private func disableLowPowerOptimizations() {
        // Restore normal refresh rate
        displayLink?.preferredFramesPerSecond = 60

        // Re-enable features
        gpuAccelerationEnabled = true
    }

    func clearCaches() {
        // Clear image cache
        ImageCache.shared.clearMemoryCache()

        // Clear parsed song cache
        SongParserCache.shared.clearOldEntries()
    }

    func clearAllCaches() {
        clearCaches()

        // Also clear disk cache
        ImageCache.shared.clearDiskCache()
    }

    private func releaseUnusedResources() {
        // Force garbage collection hint
        autoreleasepool {
            // Release any temporary objects
        }
    }

    private func reduceBackgroundProcessing() {
        // Reduce sync frequency
        NotificationCenter.default.post(name: .performanceReduceBackgroundWork, object: nil)
    }

    // MARK: - Signpost Helpers

    func beginSignpost(_ name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.begin, log: signpostLog, name: name, signpostID: id)
    }

    func endSignpost(_ name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.end, log: signpostLog, name: name, signpostID: id)
    }

    func eventSignpost(_ name: StaticString, _ message: String = "") {
        os_signpost(.event, log: signpostLog, name: name, "%{public}s", message)
    }

    // MARK: - Performance Metrics

    var averageFPS: Double {
        guard !fpsHistory.isEmpty else { return 0 }
        return fpsHistory.reduce(0, +) / Double(fpsHistory.count)
    }

    var averageMemoryUsage: Double {
        guard !memoryHistory.isEmpty else { return 0 }
        return memoryHistory.reduce(0, +) / Double(memoryHistory.count)
    }

    var performanceScore: Int {
        var score = 100

        // FPS penalty
        if averageFPS < PerformanceTargets.targetFPS {
            score -= Int((PerformanceTargets.targetFPS - averageFPS) / PerformanceTargets.targetFPS * 30)
        }

        // Memory penalty
        if averageMemoryUsage > PerformanceTargets.maxMemoryMB * 0.8 {
            score -= 20
        }

        // CPU penalty
        if cpuUsage > PerformanceTargets.maxCPUUsage * 0.8 {
            score -= 20
        }

        // Battery penalty
        if isLowPowerModeEnabled {
            score -= 10
        }

        return max(0, score)
    }

    var performanceGrade: String {
        let score = performanceScore
        switch score {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }

    // MARK: - Cleanup

    deinit {
        displayLink?.invalidate()
        memoryUpdateTimer?.invalidate()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let performanceMemoryWarning = Notification.Name("performanceMemoryWarning")
    static let performanceReduceBackgroundWork = Notification.Name("performanceReduceBackgroundWork")
    static let performanceLowFrameRate = Notification.Name("performanceLowFrameRate")
}

// MARK: - Image Cache

class ImageCache {
    static let shared = ImageCache()

    private var memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Set up cache
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        memoryCache.countLimit = 100 // 100 images

        // Get cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Clean old cache on startup
        cleanOldCache()
    }

    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func cleanOldCache() {
        // Remove cache files older than 7 days
        let maxAge: TimeInterval = 7 * 24 * 60 * 60
        let cutoffDate = Date().addingTimeInterval(-maxAge)

        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }

        for file in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                  let modificationDate = attributes[.modificationDate] as? Date else {
                continue
            }

            if modificationDate < cutoffDate {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

// MARK: - Song Parser Cache

class SongParserCache {
    static let shared = SongParserCache()

    private var cache: [UUID: CachedSong] = [:]
    private let maxCacheSize = 50
    private let maxAge: TimeInterval = 300 // 5 minutes

    struct CachedSong {
        let parsedSong: ParsedSong
        let timestamp: Date
    }

    func get(_ songID: UUID) -> ParsedSong? {
        guard let cached = cache[songID] else { return nil }

        // Check if expired
        if Date().timeIntervalSince(cached.timestamp) > maxAge {
            cache.removeValue(forKey: songID)
            return nil
        }

        return cached.parsedSong
    }

    func set(_ songID: UUID, parsedSong: ParsedSong) {
        cache[songID] = CachedSong(parsedSong: parsedSong, timestamp: Date())

        // Limit cache size
        if cache.count > maxCacheSize {
            clearOldEntries()
        }
    }

    func clearOldEntries() {
        let cutoffDate = Date().addingTimeInterval(-maxAge)

        cache = cache.filter { $0.value.timestamp > cutoffDate }

        // If still too large, remove oldest
        if cache.count > maxCacheSize {
            let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
            let toRemove = sorted.prefix(cache.count - maxCacheSize)
            toRemove.forEach { cache.removeValue(forKey: $0.key) }
        }
    }

    func clear() {
        cache.removeAll()
    }
}

// MARK: - DisplayLink Helper

/// Helper class to handle CADisplayLink callbacks since @Observable classes can't use @objc
private class DisplayLinkTarget: NSObject {
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
        super.init()
    }

    @objc func handleDisplayLink() {
        callback()
    }
}
