//
//  ImportPerformanceOptimizer.swift
//  Lyra
//
//  Performance optimization utilities for file imports
//

import Foundation
import PDFKit

/// Manages caching and performance optimization for imports
class ImportPerformanceOptimizer {
    static let shared = ImportPerformanceOptimizer()

    private let fileCache = NSCache<NSString, CachedFileData>()
    private let cloudListingCache = NSCache<NSString, CachedCloudListing>()
    private let processingQueue = DispatchQueue(label: "com.lyra.import.processing", qos: .userInitiated)

    // MARK: - Configuration

    private let maxCacheSize: Int = 50 * 1024 * 1024 // 50 MB
    private let cloudCacheDuration: TimeInterval = 300 // 5 minutes
    private let maxConcurrentOperations = 3

    private init() {
        fileCache.totalCostLimit = maxCacheSize
        cloudListingCache.countLimit = 100
    }

    // MARK: - File Caching

    /// Cache file data for repeated access
    func cacheFileData(_ data: Data, for url: URL) {
        let key = url.absoluteString as NSString
        let cost = data.count
        let cached = CachedFileData(data: data, timestamp: Date())
        fileCache.setObject(cached, forKey: key, cost: cost)
    }

    /// Retrieve cached file data
    func getCachedFileData(for url: URL) -> Data? {
        let key = url.absoluteString as NSString
        return fileCache.object(forKey: key)?.data
    }

    /// Clear file cache
    func clearFileCache() {
        fileCache.removeAllObjects()
    }

    // MARK: - Cloud Listing Cache

    /// Cache cloud folder listing
    func cacheCloudListing(_ files: [String], for path: String, provider: String) {
        let key = "\(provider):\(path)" as NSString
        let cached = CachedCloudListing(
            files: files,
            timestamp: Date(),
            expiresAt: Date().addingTimeInterval(cloudCacheDuration)
        )
        cloudListingCache.setObject(cached, forKey: key)
    }

    /// Get cached cloud listing if still valid
    func getCachedCloudListing(for path: String, provider: String) -> [String]? {
        let key = "\(provider):\(path)" as NSString
        guard let cached = cloudListingCache.object(forKey: key) else {
            return nil
        }

        // Check if expired
        if Date() > cached.expiresAt {
            cloudListingCache.removeObject(forKey: key)
            return nil
        }

        return cached.files
    }

    /// Clear cloud listing cache
    func clearCloudCache() {
        cloudListingCache.removeAllObjects()
    }

    // MARK: - Memory Management

    /// Process large PDF with memory management
    func processLargePDF(at url: URL, maxMemoryMB: Int = 100) -> PDFDocument? {
        let memoryLimit = maxMemoryMB * 1024 * 1024

        // Check available memory
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            // Fallback: just try to load
            return PDFDocument(url: url)
        }

        let usedMemory = Int(info.resident_size)

        // If we're using too much memory already, don't load
        if usedMemory > memoryLimit {
            print("⚠️ Memory limit exceeded. Deferring PDF load.")
            return nil
        }

        // Load PDF with autoreleasepool for better memory management
        return autoreleasepool {
            PDFDocument(url: url)
        }
    }

    /// Process large file in chunks to manage memory
    func processLargeTextFile(at url: URL, chunkSize: Int = 1024 * 1024) throws -> String {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            throw ImportError.fileNotReadable
        }
        defer { try? fileHandle.close() }

        var content = ""
        var hasMore = true

        while hasMore {
            autoreleasepool {
                if let chunk = try? fileHandle.read(upToCount: chunkSize),
                   let string = String(data: chunk, encoding: .utf8) {
                    content += string
                    hasMore = chunk.count == chunkSize
                } else {
                    hasMore = false
                }
            }
        }

        return content
    }

    // MARK: - Background Processing

    /// Process file in background thread
    func processInBackground<T>(_ operation: @escaping () throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    let result = try operation()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Batch process multiple files with concurrency control
    func batchProcess<T>(
        items: [URL],
        maxConcurrent: Int? = nil,
        operation: @escaping (URL) async throws -> T
    ) async throws -> [T] {
        let concurrent = maxConcurrent ?? maxConcurrentOperations

        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            var results = [T?](repeating: nil, count: items.count)
            var currentIndex = 0

            // Start initial batch
            for index in 0..<min(concurrent, items.count) {
                group.addTask {
                    let result = try await operation(items[index])
                    return (index, result)
                }
                currentIndex += 1
            }

            // Process remaining items as tasks complete
            while let (index, result) = try await group.next() {
                results[index] = result

                // Start next item if available
                if currentIndex < items.count {
                    let nextIndex = currentIndex
                    group.addTask {
                        let result = try await operation(items[nextIndex])
                        return (nextIndex, result)
                    }
                    currentIndex += 1
                }
            }

            return results.compactMap { $0 }
        }
    }

    // MARK: - Progress Estimation

    /// Estimate total import time for multiple files
    func estimateBatchImportTime(files: [URL]) -> TimeInterval {
        var totalTime: TimeInterval = 0
        let validator = FileValidationUtility.shared

        for url in files {
            let result = validator.validateFile(at: url)
            if result.isValid, let estimatedTime = result.estimatedProcessingTime {
                totalTime += estimatedTime
            } else {
                // Default estimate for invalid/unknown files
                totalTime += 1.0
            }
        }

        // Add overhead for batch processing
        let overhead = Double(files.count) * 0.1
        return totalTime + overhead
    }
}

// MARK: - Cache Data Structures

private class CachedFileData {
    let data: Data
    let timestamp: Date

    init(data: Data, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
}

private class CachedCloudListing {
    let files: [String]
    let timestamp: Date
    let expiresAt: Date

    init(files: [String], timestamp: Date, expiresAt: Date) {
        self.files = files
        self.timestamp = timestamp
        self.expiresAt = expiresAt
    }
}
