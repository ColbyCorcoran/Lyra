//
//  BatchOCREngine.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Engine 7
//  Batch processing for multiple images with progress tracking
//

import Foundation
import UIKit
import Combine

/// Engine for batch processing multiple OCR jobs
@MainActor
class BatchOCREngine: ObservableObject {

    // MARK: - Properties

    @Published var activeJobs: [BatchOCRJob] = []
    @Published var completedJobs: [BatchOCRJob] = []

    private let maxConcurrentOperations = 3
    private let maxBatchSize = 50

    // MARK: - Public API

    /// Process a batch of images with progress tracking
    /// - Parameters:
    ///   - images: Array of images to process
    ///   - processor: Closure to process each image
    ///   - progressHandler: Optional progress callback
    /// - Returns: Batch OCR job with results
    func processBatch(
        images: [UIImage],
        processor: @escaping (UIImage) async throws -> EnhancedOCRResult,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> BatchOCRJob {
        // Validate batch size
        guard images.count <= maxBatchSize else {
            throw BatchError.batchTooLarge(count: images.count, max: maxBatchSize)
        }

        // Create job
        var job = BatchOCRJob(
            images: images,
            status: .queued,
            progress: 0.0,
            results: [],
            errors: [],
            startTime: Date()
        )

        // Add to active jobs
        activeJobs.append(job)

        // Update status to processing
        job.status = .processing
        updateJob(job)

        // Process images in parallel with concurrency limit
        let results = try await processImagesInParallel(
            images: images,
            processor: processor,
            maxConcurrent: maxConcurrentOperations
        ) { progress in
            job.progress = progress
            self.updateJob(job)
            progressHandler?(progress)
        }

        // Update job with results
        job.results = results.compactMap { $0.result }
        job.errors = results.compactMap { $0.error }
        job.status = job.errors.isEmpty ? .completed : .failed
        job.progress = 1.0

        // Move to completed
        moveToCompleted(job)

        progressHandler?(1.0)

        return job
    }

    /// Track progress of a batch job
    /// - Parameter jobId: Job identifier
    /// - Returns: Current progress (0.0-1.0)
    func trackProgress(jobId: UUID) -> Double {
        if let job = activeJobs.first(where: { $0.id == jobId }) {
            return job.progress
        }
        if let job = completedJobs.first(where: { $0.id == jobId }) {
            return job.progress
        }
        return 0.0
    }

    /// Handle errors in batch processing
    /// - Parameters:
    ///   - job: The batch job
    ///   - error: The error that occurred
    ///   - imageIndex: Index of the image that failed
    /// - Returns: Whether error is recoverable
    func handleErrors(job: inout BatchOCRJob, error: Error, imageIndex: Int) -> Bool {
        let batchError = BatchOCRError(
            imageIndex: imageIndex,
            error: error.localizedDescription,
            recoverable: isRecoverable(error)
        )

        job.errors.append(batchError)

        // If error is recoverable, continue processing
        return batchError.recoverable
    }

    /// Cancel a batch job
    /// - Parameter jobId: Job identifier
    func cancelJob(jobId: UUID) {
        if let index = activeJobs.firstIndex(where: { $0.id == jobId }) {
            var job = activeJobs[index]
            job.status = .cancelled
            moveToCompleted(job)
        }
    }

    /// Queue management - prioritize jobs
    /// - Parameter jobId: Job to prioritize
    func prioritizeJob(jobId: UUID) {
        if let index = activeJobs.firstIndex(where: { $0.id == jobId }) {
            let job = activeJobs.remove(at: index)
            activeJobs.insert(job, at: 0)
        }
    }

    /// Enable background processing
    /// - Parameter job: Job to process in background
    /// - Returns: Updated job
    func enableBackgroundProcessing(for job: BatchOCRJob) -> BatchOCRJob {
        var updatedJob = job
        // In production, would configure background task
        // For now, just mark for background processing
        return updatedJob
    }

    // MARK: - Private Helper Methods

    /// Process images in parallel with concurrency limit
    private func processImagesInParallel(
        images: [UIImage],
        processor: @escaping (UIImage) async throws -> EnhancedOCRResult,
        maxConcurrent: Int
    ) async throws -> [(index: Int, result: EnhancedOCRResult?, error: BatchOCRError?)] {
        return try await withThrowingTaskGroup(of: (Int, EnhancedOCRResult?, BatchOCRError?).self) { group in
            var results: [(Int, EnhancedOCRResult?, BatchOCRError?)] = []
            var processedCount = 0

            // Submit initial batch of tasks
            for (index, image) in images.enumerated().prefix(maxConcurrent) {
                group.addTask {
                    do {
                        let result = try await processor(image)
                        return (index, result, nil)
                    } catch {
                        let batchError = BatchOCRError(
                            imageIndex: index,
                            error: error.localizedDescription,
                            recoverable: self.isRecoverable(error)
                        )
                        return (index, nil, batchError)
                    }
                }
            }

            // Process remaining images as tasks complete
            var nextIndex = maxConcurrent

            while let result = try await group.next() {
                results.append(result)
                processedCount += 1

                // Submit next task if available
                if nextIndex < images.count {
                    let index = nextIndex
                    let image = images[index]
                    nextIndex += 1

                    group.addTask {
                        do {
                            let result = try await processor(image)
                            return (index, result, nil)
                        } catch {
                            let batchError = BatchOCRError(
                                imageIndex: index,
                                error: error.localizedDescription,
                                recoverable: self.isRecoverable(error)
                            )
                            return (index, nil, batchError)
                        }
                    }
                }
            }

            // Sort by original index
            return results.sorted { $0.0 < $1.0 }
        }
    }

    /// Process images in parallel with progress updates
    private func processImagesInParallel(
        images: [UIImage],
        processor: @escaping (UIImage) async throws -> EnhancedOCRResult,
        maxConcurrent: Int,
        progressUpdate: @escaping (Double) -> Void
    ) async throws -> [(index: Int, result: EnhancedOCRResult?, error: BatchOCRError?)] {
        return try await withThrowingTaskGroup(of: (Int, EnhancedOCRResult?, BatchOCRError?).self) { group in
            var results: [(Int, EnhancedOCRResult?, BatchOCRError?)] = []
            var processedCount = 0

            // Submit initial batch of tasks
            for (index, image) in images.enumerated().prefix(maxConcurrent) {
                group.addTask {
                    do {
                        let result = try await processor(image)
                        return (index, result, nil)
                    } catch {
                        let batchError = BatchOCRError(
                            imageIndex: index,
                            error: error.localizedDescription,
                            recoverable: self.isRecoverable(error)
                        )
                        return (index, nil, batchError)
                    }
                }
            }

            // Process remaining images as tasks complete
            var nextIndex = maxConcurrent

            while let result = try await group.next() {
                results.append(result)
                processedCount += 1

                // Update progress
                let progress = Double(processedCount) / Double(images.count)
                await MainActor.run {
                    progressUpdate(progress)
                }

                // Submit next task if available
                if nextIndex < images.count {
                    let index = nextIndex
                    let image = images[index]
                    nextIndex += 1

                    group.addTask {
                        do {
                            let result = try await processor(image)
                            return (index, result, nil)
                        } catch {
                            let batchError = BatchOCRError(
                                imageIndex: index,
                                error: error.localizedDescription,
                                recoverable: self.isRecoverable(error)
                            )
                            return (index, nil, batchError)
                        }
                    }
                }
            }

            // Sort by original index
            return results.sorted { $0.0 < $1.0 }
        }
    }

    /// Check if error is recoverable
    private nonisolated func isRecoverable(_ error: Error) -> Bool {
        // Check error type to determine if recoverable
        if let ocrError = error as? OCRError {
            switch ocrError {
            case .noTextFound:
                return true // Can continue with other images
            case .invalidImage:
                return true // Can continue with other images
            case .processingFailed:
                return false // Might indicate system issue
            case .visionError:
                return false // Might indicate system issue
            }
        }
        return false
    }

    /// Update job in active jobs list
    private func updateJob(_ job: BatchOCRJob) {
        if let index = activeJobs.firstIndex(where: { $0.id == job.id }) {
            activeJobs[index] = job
        }
    }

    /// Move job to completed list
    private func moveToCompleted(_ job: BatchOCRJob) {
        if let index = activeJobs.firstIndex(where: { $0.id == job.id }) {
            activeJobs.remove(at: index)
        }
        completedJobs.append(job)
    }

    // MARK: - Queue Management

    /// Get current queue status
    func getQueueStatus() -> QueueStatus {
        return QueueStatus(
            activeCount: activeJobs.count,
            queuedCount: activeJobs.filter { $0.status == .queued }.count,
            processingCount: activeJobs.filter { $0.status == .processing }.count,
            completedCount: completedJobs.count
        )
    }

    /// Clear completed jobs
    func clearCompleted() {
        completedJobs.removeAll()
    }
}

// MARK: - Supporting Types

/// Queue status information
struct QueueStatus {
    let activeCount: Int
    let queuedCount: Int
    let processingCount: Int
    let completedCount: Int
}

/// Batch error types
enum BatchError: LocalizedError {
    case batchTooLarge(count: Int, max: Int)
    case processingFailed(reason: String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .batchTooLarge(let count, let max):
            return "Batch size \(count) exceeds maximum of \(max) images"
        case .processingFailed(let reason):
            return "Batch processing failed: \(reason)"
        case .cancelled:
            return "Batch processing was cancelled"
        }
    }
}
