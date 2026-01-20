//
//  AttachmentManager.swift
//  Lyra
//
//  Manager for attachment storage, file operations, and statistics
//

import Foundation
import SwiftData
import UIKit
import PDFKit
import Combine

@MainActor
class AttachmentManager: ObservableObject {
    static let shared = AttachmentManager()

    // MARK: - Storage Constants

    private let maxInlineSize: Int = 500_000 // 500KB - store inline if smaller
    private let attachmentsDirectory = "Attachments"

    // MARK: - File Storage

    /// Save attachment data to file system
    func saveAttachment(
        _ attachment: Attachment,
        data: Data,
        storeInline: Bool = false
    ) throws -> URL {
        // For small files or if requested, store inline
        if data.count <= maxInlineSize || storeInline {
            attachment.fileData = data
            attachment.filePath = nil
            attachment.touch()
            return URL(fileURLWithPath: "") // Return empty URL for inline storage
        }

        // Create attachments directory if needed
        let attachmentsDir = try getAttachmentsDirectory()

        // Generate unique filename to avoid conflicts
        let uniqueFilename = "\(attachment.id.uuidString)_\(attachment.filename)"
        let fileURL = attachmentsDir.appendingPathComponent(uniqueFilename)

        // Write data to file
        try data.write(to: fileURL)

        // Update attachment
        attachment.filePath = uniqueFilename
        attachment.fileData = nil
        attachment.touch()

        return fileURL
    }

    /// Load attachment data from storage
    func loadAttachment(_ attachment: Attachment) throws -> Data {
        // Check if stored inline
        if let data = attachment.fileData {
            return data
        }

        // Load from file system
        guard let filePath = attachment.filePath else {
            throw AttachmentError.fileNotFound
        }

        let attachmentsDir = try getAttachmentsDirectory()
        let fileURL = attachmentsDir.appendingPathComponent(filePath)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AttachmentError.fileNotFound
        }

        return try Data(contentsOf: fileURL)
    }

    /// Delete attachment file from storage
    func deleteAttachment(_ attachment: Attachment) throws {
        // If stored inline, just clear data
        if attachment.fileData != nil {
            attachment.fileData = nil
            return
        }

        // Delete file from file system
        guard let filePath = attachment.filePath else { return }

        let attachmentsDir = try getAttachmentsDirectory()
        let fileURL = attachmentsDir.appendingPathComponent(filePath)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    /// Move attachment from temporary location to permanent storage
    func importAttachment(
        from sourceURL: URL,
        filename: String,
        fileType: String,
        versionName: String?,
        source: String
    ) throws -> Attachment {
        // Read data from source
        let data = try Data(contentsOf: sourceURL)

        // Create attachment
        let attachment = Attachment(
            filename: filename,
            fileType: fileType,
            fileSize: data.count,
            versionName: versionName,
            originalSource: source
        )

        // Save to storage
        _ = try saveAttachment(attachment, data: data)

        return attachment
    }

    // MARK: - Storage Management

    /// Calculate total storage used by all attachments
    func calculateTotalStorage(modelContext: ModelContext) -> Int64 {
        let descriptor = FetchDescriptor<Attachment>()
        guard let attachments = try? modelContext.fetch(descriptor) else {
            return 0
        }

        return attachments.reduce(0) { $0 + Int64($1.fileSize) }
    }

    /// Calculate storage for a specific song
    func calculateSongStorage(_ song: Song) -> Int64 {
        guard let attachments = song.attachments else { return 0 }
        return attachments.reduce(0) { $0 + Int64($1.fileSize) }
    }

    /// Get storage statistics
    func getStorageStats(modelContext: ModelContext) -> StorageStats {
        let descriptor = FetchDescriptor<Attachment>()
        guard let attachments = try? modelContext.fetch(descriptor) else {
            return StorageStats(
                totalSize: 0,
                attachmentCount: 0,
                inlineCount: 0,
                fileCount: 0,
                largestAttachment: nil
            )
        }

        let totalSize = attachments.reduce(0) { $0 + Int64($1.fileSize) }
        let inlineCount = attachments.filter { $0.fileData != nil }.count
        let fileCount = attachments.filter { $0.filePath != nil }.count
        let largest = attachments.max(by: { $0.fileSize < $1.fileSize })

        return StorageStats(
            totalSize: totalSize,
            attachmentCount: attachments.count,
            inlineCount: inlineCount,
            fileCount: fileCount,
            largestAttachment: largest
        )
    }

    // MARK: - PDF Compression

    /// Compress PDF if it's larger than threshold
    func compressPDF(attachment: Attachment, quality: PDFCompressionQuality = .medium) throws -> Int {
        guard attachment.fileType.lowercased() == "pdf" else {
            throw AttachmentError.invalidFileType
        }

        // Load PDF data
        let originalData = try loadAttachment(attachment)
        let originalSize = originalData.count

        // Only compress if larger than 1MB
        guard originalSize > 1_000_000 else {
            return originalSize
        }

        // Create PDF document
        guard let pdfDocument = PDFDocument(data: originalData) else {
            throw AttachmentError.compressionFailed
        }

        // Render PDF at lower quality
        let compressedData = renderPDFWithQuality(pdfDocument, quality: quality)

        // Only save if compression resulted in smaller file
        if compressedData.count < originalSize {
            _ = try saveAttachment(attachment, data: compressedData)
            attachment.fileSize = compressedData.count
            attachment.touch()
            return compressedData.count
        }

        return originalSize
    }

    private func renderPDFWithQuality(_ document: PDFDocument, quality: PDFCompressionQuality) -> Data {
        let pageCount = document.pageCount
        let pdfData = NSMutableData()

        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)

        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            let pageRect = page.bounds(for: .mediaBox)
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)

            guard let context = UIGraphicsGetCurrentContext() else { continue }

            // Apply quality scaling
            let scale = quality.scale
            context.scaleBy(x: scale, y: scale)

            // Render page
            page.draw(with: .mediaBox, to: context)
        }

        UIGraphicsEndPDFContext()

        return pdfData as Data
    }

    // MARK: - Version Management

    /// Get all versions for a song (attachments with version names)
    func getVersions(for song: Song) -> [Attachment] {
        guard let attachments = song.attachments else { return [] }
        return attachments.filter { $0.versionName != nil }
    }

    /// Switch default attachment (set new default, unset old)
    func setDefaultAttachment(_ attachment: Attachment, for song: Song, modelContext: ModelContext) throws {
        // Unset current default
        if let currentDefault = song.attachments?.first(where: { $0.isDefault }) {
            currentDefault.isDefault = false
        }

        // Set new default
        attachment.isDefault = true
        attachment.touch()

        try modelContext.save()
    }

    /// Rename attachment
    func renameAttachment(_ attachment: Attachment, newName: String) {
        attachment.filename = newName
        attachment.touch()
    }

    /// Update version name
    func updateVersionName(_ attachment: Attachment, versionName: String?) {
        attachment.versionName = versionName
        attachment.touch()
    }

    /// Replace attachment data
    func replaceAttachment(_ attachment: Attachment, with newData: Data) throws {
        // Delete old file if exists
        if attachment.filePath != nil {
            try? deleteAttachment(attachment)
        }

        // Save new data
        _ = try saveAttachment(attachment, data: newData)

        // Update size
        attachment.fileSize = newData.count
        attachment.touch()
    }

    // MARK: - Cleanup

    /// Remove orphaned files (files without corresponding attachments)
    func cleanupOrphanedFiles(modelContext: ModelContext) throws -> Int {
        let attachmentsDir = try getAttachmentsDirectory()
        let descriptor = FetchDescriptor<Attachment>()
        let attachments = try modelContext.fetch(descriptor)

        // Get all filenames from database
        let validFilenames = Set(attachments.compactMap { $0.filePath })

        // Get all files in attachments directory
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: attachmentsDir,
            includingPropertiesForKeys: nil
        )

        var deletedCount = 0

        for fileURL in fileURLs {
            let filename = fileURL.lastPathComponent

            // Skip if file is referenced by an attachment
            if validFilenames.contains(filename) {
                continue
            }

            // Delete orphaned file
            try FileManager.default.removeItem(at: fileURL)
            deletedCount += 1
        }

        return deletedCount
    }

    /// Calculate storage that could be freed by compression
    func calculateCompressibleSize(modelContext: ModelContext) -> Int64 {
        let descriptor = FetchDescriptor<Attachment>()
        guard let attachments = try? modelContext.fetch(descriptor) else {
            return 0
        }

        // Sum up PDF files larger than 1MB
        return attachments
            .filter { $0.fileType.lowercased() == "pdf" && $0.fileSize > 1_000_000 }
            .reduce(0) { $0 + Int64($1.fileSize) }
    }

    // MARK: - Helper Methods

    private func getAttachmentsDirectory() throws -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let attachmentsDir = documentsDir.appendingPathComponent(attachmentsDirectory)

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: attachmentsDir.path) {
            try FileManager.default.createDirectory(
                at: attachmentsDir,
                withIntermediateDirectories: true
            )
        }

        return attachmentsDir
    }

    /// Get file URL for attachment (for viewing)
    func getFileURL(for attachment: Attachment) throws -> URL {
        // If stored inline, create temporary file
        if let data = attachment.fileData {
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent(attachment.filename)
            try data.write(to: tempURL)
            return tempURL
        }

        // Return file URL
        guard let filePath = attachment.filePath else {
            throw AttachmentError.fileNotFound
        }

        let attachmentsDir = try getAttachmentsDirectory()
        return attachmentsDir.appendingPathComponent(filePath)
    }

    // MARK: - Errors

    enum AttachmentError: LocalizedError {
        case fileNotFound
        case invalidFileType
        case compressionFailed
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Attachment file not found"
            case .invalidFileType:
                return "Invalid file type for this operation"
            case .compressionFailed:
                return "Failed to compress file"
            case .saveFailed:
                return "Failed to save attachment"
            }
        }
    }
}

// MARK: - Storage Stats

struct StorageStats {
    let totalSize: Int64
    let attachmentCount: Int
    let inlineCount: Int
    let fileCount: Int
    let largestAttachment: Attachment?

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var averageSize: Int64 {
        guard attachmentCount > 0 else { return 0 }
        return totalSize / Int64(attachmentCount)
    }

    var formattedAverageSize: String {
        ByteCountFormatter.string(fromByteCount: averageSize, countStyle: .file)
    }
}

// MARK: - PDF Compression Quality

enum PDFCompressionQuality {
    case low
    case medium
    case high

    var scale: CGFloat {
        switch self {
        case .low: return 0.5
        case .medium: return 0.7
        case .high: return 0.85
        }
    }

    var description: String {
        switch self {
        case .low: return "Low Quality (50%)"
        case .medium: return "Medium Quality (70%)"
        case .high: return "High Quality (85%)"
        }
    }
}
