//
//  FileValidationUtility.swift
//  Lyra
//
//  Comprehensive file validation and edge case handling for imports
//

import Foundation
import UniformTypeIdentifiers
import PDFKit

enum FileValidationError: LocalizedError {
    case fileTooSmall(size: Int64)
    case fileTooLarge(size: Int64, limit: Int64)
    case invalidCharactersInFilename(String)
    case unsupportedFileType(String)
    case corruptedFile
    case insufficientPermissions
    case pdfTooManyPages(pageCount: Int, limit: Int)
    case pdfCorrupted
    case emptyPDF
    case networkFileNotAccessible
    case invalidEncoding
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .fileTooSmall(let size):
            return "File is too small (\(formatFileSize(size)))"
        case .fileTooLarge(let size, let limit):
            return "File is too large (\(formatFileSize(size))). Maximum size is \(formatFileSize(limit))"
        case .invalidCharactersInFilename(let name):
            return "Invalid characters in filename: \"\(name)\""
        case .unsupportedFileType(let ext):
            return "Unsupported file type: .\(ext)"
        case .corruptedFile:
            return "File appears to be corrupted or incomplete"
        case .insufficientPermissions:
            return "Insufficient permissions to read file"
        case .pdfTooManyPages(let count, let limit):
            return "PDF has too many pages (\(count)). Maximum is \(limit) pages"
        case .pdfCorrupted:
            return "PDF file is corrupted or invalid"
        case .emptyPDF:
            return "PDF contains no content"
        case .networkFileNotAccessible:
            return "Network file is not accessible"
        case .invalidEncoding:
            return "File encoding is not supported"
        case .emptyContent:
            return "File contains no content"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileTooSmall:
            return "The file may be empty or corrupted. Please check the file and try again."
        case .fileTooLarge:
            return "Try compressing the file or splitting it into smaller parts."
        case .invalidCharactersInFilename:
            return "Rename the file to remove special characters and try again."
        case .unsupportedFileType:
            return "Supported formats: PDF, TXT, ChordPro (.cho), OnSong (.onsong)"
        case .corruptedFile:
            return "Try re-downloading or re-exporting the file."
        case .insufficientPermissions:
            return "Check file permissions or try selecting the file again."
        case .pdfTooManyPages:
            return "Consider splitting the PDF into smaller documents."
        case .pdfCorrupted:
            return "Try opening the PDF in another app to verify it's valid."
        case .emptyPDF:
            return "The PDF file contains no readable content."
        case .networkFileNotAccessible:
            return "Check your internet connection and try again."
        case .invalidEncoding:
            return "Try converting the file to UTF-8 encoding."
        case .emptyContent:
            return "The file contains no content. Please select a different file."
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct FileValidationResult {
    let isValid: Bool
    let warnings: [String]
    let error: FileValidationError?
    let fileSize: Int64
    let estimatedProcessingTime: TimeInterval?
    let requiresSpecialHandling: Bool

    var hasWarnings: Bool {
        !warnings.isEmpty
    }
}

class FileValidationUtility {
    static let shared = FileValidationUtility()

    // MARK: - Constants

    private let minFileSize: Int64 = 10 // 10 bytes minimum
    private let maxFileSize: Int64 = 100 * 1024 * 1024 // 100 MB
    private let maxInlinePDFSize: Int64 = 5 * 1024 * 1024 // 5 MB
    private let maxPDFPages: Int = 100
    private let warnLargePDFSize: Int64 = 20 * 1024 * 1024 // 20 MB warning
    private let warnManyPDFPages: Int = 50

    private let supportedExtensions = [
        "txt", "text",
        "cho", "chordpro", "chopro", "crd",
        "pdf",
        "onsong",
        "rtf", "xml"
    ]

    // Characters that may cause issues on some systems
    private let problematicCharacters = CharacterSet(charactersIn: "<>:\"|?*\\/")

    private init() {}

    // MARK: - Main Validation

    /// Validate a file before import
    func validateFile(at url: URL) -> FileValidationResult {
        var warnings: [String] = []
        var requiresSpecialHandling = false

        // Check if file exists and is accessible
        guard FileManager.default.fileExists(atPath: url.path) else {
            return FileValidationResult(
                isValid: false,
                warnings: [],
                error: .networkFileNotAccessible,
                fileSize: 0,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }

        // Get file attributes
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return FileValidationResult(
                isValid: false,
                warnings: [],
                error: .insufficientPermissions,
                fileSize: 0,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }

        // Validate file size
        if fileSize < minFileSize {
            return FileValidationResult(
                isValid: false,
                warnings: warnings,
                error: .fileTooSmall(size: fileSize),
                fileSize: fileSize,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }

        if fileSize > maxFileSize {
            return FileValidationResult(
                isValid: false,
                warnings: warnings,
                error: .fileTooLarge(size: fileSize, limit: maxFileSize),
                fileSize: fileSize,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }

        // Validate filename
        let filename = url.lastPathComponent
        if filename.rangeOfCharacter(from: problematicCharacters) != nil {
            warnings.append("Filename contains special characters that may cause issues")
            requiresSpecialHandling = true
        }

        // Check filename length
        if filename.count > 255 {
            warnings.append("Filename is very long and may be truncated")
        }

        // Validate file extension
        let ext = url.pathExtension.lowercased()
        guard !ext.isEmpty && supportedExtensions.contains(ext) else {
            return FileValidationResult(
                isValid: false,
                warnings: warnings,
                error: .unsupportedFileType(ext.isEmpty ? "none" : ext),
                fileSize: fileSize,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }

        // PDF-specific validation
        if ext == "pdf" {
            return validatePDF(at: url, fileSize: fileSize, existingWarnings: warnings)
        }

        // Text file validation
        let textValidation = validateTextFile(at: url, fileSize: fileSize)
        warnings.append(contentsOf: textValidation.warnings)

        if let error = textValidation.error {
            return FileValidationResult(
                isValid: false,
                warnings: warnings,
                error: error,
                fileSize: fileSize,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: requiresSpecialHandling
            )
        }

        // Estimate processing time based on file size
        let estimatedTime = estimateProcessingTime(for: fileSize, fileType: ext)

        // Large file warning
        if fileSize > 1024 * 1024 { // > 1 MB
            warnings.append("Large file may take longer to process")
            requiresSpecialHandling = true
        }

        return FileValidationResult(
            isValid: true,
            warnings: warnings,
            error: nil,
            fileSize: fileSize,
            estimatedProcessingTime: estimatedTime,
            requiresSpecialHandling: requiresSpecialHandling
        )
    }

    // MARK: - PDF Validation

    private func validatePDF(at url: URL, fileSize: Int64, existingWarnings: [String]) -> FileValidationResult {
        var warnings = existingWarnings
        var requiresSpecialHandling = false

        // Try to load PDF
        guard url.startAccessingSecurityScopedResource() else {
            return FileValidationResult(
                isValid: false,
                warnings: warnings,
                error: .insufficientPermissions,
                fileSize: fileSize,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let pdfDocument = PDFDocument(url: url) else {
            return FileValidationResult(
                isValid: false,
                warnings: warnings,
                error: .pdfCorrupted,
                fileSize: fileSize,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }

        let pageCount = pdfDocument.pageCount

        // Check for empty PDF
        guard pageCount > 0 else {
            return FileValidationResult(
                isValid: false,
                warnings: warnings,
                error: .emptyPDF,
                fileSize: fileSize,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }

        // Check page count limits
        if pageCount > maxPDFPages {
            return FileValidationResult(
                isValid: false,
                warnings: warnings,
                error: .pdfTooManyPages(pageCount: pageCount, limit: maxPDFPages),
                fileSize: fileSize,
                estimatedProcessingTime: nil,
                requiresSpecialHandling: false
            )
        }

        // Warnings for large PDFs
        if pageCount > warnManyPDFPages {
            warnings.append("PDF has \(pageCount) pages. Processing may take longer.")
            requiresSpecialHandling = true
        }

        if fileSize > warnLargePDFSize {
            warnings.append("Large PDF file. May require more memory to process.")
            requiresSpecialHandling = true
        }

        if fileSize > maxInlinePDFSize {
            warnings.append("PDF will be stored as external file (not embedded in database)")
            requiresSpecialHandling = true
        }

        // Check if PDF is encrypted/password protected
        if pdfDocument.isEncrypted {
            warnings.append("PDF is password-protected. Some features may not work.")
        }

        // Estimate processing time for PDF
        let estimatedTime = estimateProcessingTime(for: fileSize, fileType: "pdf", pageCount: pageCount)

        return FileValidationResult(
            isValid: true,
            warnings: warnings,
            error: nil,
            fileSize: fileSize,
            estimatedProcessingTime: estimatedTime,
            requiresSpecialHandling: requiresSpecialHandling
        )
    }

    // MARK: - Text File Validation

    private func validateTextFile(at url: URL, fileSize: Int64) -> (error: FileValidationError?, warnings: [String]) {
        var warnings: [String] = []

        guard url.startAccessingSecurityScopedResource() else {
            return (.insufficientPermissions, warnings)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Try to read file with UTF-8
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            // Try alternative encodings
            if let _ = try? String(contentsOf: url, encoding: .ascii) {
                warnings.append("File uses ASCII encoding (may have limited character support)")
                return (nil, warnings)
            } else if let _ = try? String(contentsOf: url, encoding: .isoLatin1) {
                warnings.append("File uses ISO Latin-1 encoding")
                return (nil, warnings)
            } else {
                return (.invalidEncoding, warnings)
            }
        }

        // Check for empty content
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (.emptyContent, warnings)
        }

        // Check for binary data indicators
        let binaryIndicators = ["\u{0000}", "\u{FFFD}"]
        for indicator in binaryIndicators {
            if content.contains(indicator) {
                return (.corruptedFile, warnings)
            }
        }

        // Check line count for very large files
        let lineCount = content.components(separatedBy: .newlines).count
        if lineCount > 10000 {
            warnings.append("File has \(lineCount) lines. Processing may take longer.")
        }

        return (nil, warnings)
    }

    // MARK: - Helper Methods

    /// Estimate processing time based on file characteristics
    private func estimateProcessingTime(for fileSize: Int64, fileType: String, pageCount: Int? = nil) -> TimeInterval {
        // Base time estimates (in seconds)
        let basePDFTime: TimeInterval = 0.5
        let baseTextTime: TimeInterval = 0.1

        if fileType == "pdf" {
            let pages = Double(pageCount ?? 1)
            let sizeFactor = Double(fileSize) / Double(1024 * 1024) // MB
            return basePDFTime + (pages * 0.2) + (sizeFactor * 0.3)
        } else {
            let sizeFactor = Double(fileSize) / Double(1024 * 100) // per 100 KB
            return baseTextTime + (sizeFactor * 0.05)
        }
    }

    /// Sanitize filename to remove problematic characters
    func sanitizeFilename(_ filename: String) -> String {
        var sanitized = filename

        // Replace problematic characters with underscores
        let problematicChars = "<>:\"|?*\\/"
        for char in problematicChars {
            sanitized = sanitized.replacingOccurrences(
                of: String(char),
                with: "_"
            )
        }

        // Limit length
        if sanitized.count > 255 {
            let ext = (sanitized as NSString).pathExtension
            let nameWithoutExt = (sanitized as NSString).deletingPathExtension
            let truncatedName = String(nameWithoutExt.prefix(250))
            sanitized = ext.isEmpty ? truncatedName : "\(truncatedName).\(ext)"
        }

        return sanitized
    }

    /// Check if filename contains duplicate indicators (e.g., "song (1).cho")
    func isDuplicateFilename(_ filename: String) -> Bool {
        // Common duplicate patterns: (1), (2), _copy, - Copy, etc.
        let patterns = [
            #"\(\d+\)"#,           // (1), (2), etc.
            #"_copy\d*"#,          // _copy, _copy2, etc.
            #" - Copy\d*"#,        // - Copy, - Copy 2, etc.
            #" Copy\d*"#           // Copy, Copy 2, etc.
        ]

        let nameWithoutExt = (filename as NSString).deletingPathExtension

        for pattern in patterns {
            if let _ = nameWithoutExt.range(of: pattern, options: .regularExpression, range: nil, locale: nil) {
                return true
            }
        }

        return false
    }

    /// Get a clean version of the filename (without duplicate indicators)
    func getCleanFilename(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension
        var nameWithoutExt = (filename as NSString).deletingPathExtension

        // Remove duplicate indicators
        nameWithoutExt = nameWithoutExt.replacingOccurrences(of: #"\(\d+\)$"#, with: "", options: .regularExpression)
        nameWithoutExt = nameWithoutExt.replacingOccurrences(of: #"_copy\d*$"#, with: "", options: .regularExpression)
        nameWithoutExt = nameWithoutExt.replacingOccurrences(of: #" - Copy\d*$"#, with: "", options: .regularExpression)
        nameWithoutExt = nameWithoutExt.replacingOccurrences(of: #" Copy\d*$"#, with: "", options: .regularExpression)

        nameWithoutExt = nameWithoutExt.trimmingCharacters(in: .whitespaces)

        return ext.isEmpty ? nameWithoutExt : "\(nameWithoutExt).\(ext)"
    }
}
