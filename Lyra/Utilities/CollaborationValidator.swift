//
//  CollaborationValidator.swift
//  Lyra
//
//  Validates collaboration operations and provides security checks
//

import Foundation
import SwiftData
import CloudKit

// MARK: - Collaboration Validator

class CollaborationValidator {
    static let shared = CollaborationValidator()

    // MARK: - Input Validation

    /// Validates user input for malicious content
    func validateInput(_ input: String, maxLength: Int = 50000) -> ValidationResult {
        // Check length
        if input.count > maxLength {
            return .invalid(reason: "Content exceeds maximum length of \(maxLength) characters")
        }

        // Check for null bytes
        if input.contains("\0") {
            return .invalid(reason: "Invalid characters detected")
        }

        // Check for excessive special characters (potential injection)
        let specialCharCount = input.filter { $0.isSymbol || $0.isPunctuation }.count
        let ratio = Double(specialCharCount) / Double(max(input.count, 1))

        if ratio > 0.5 {
            return .warning(reason: "Unusually high number of special characters")
        }

        return .valid
    }

    /// Validates song title
    func validateSongTitle(_ title: String) -> ValidationResult {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(reason: "Title cannot be empty")
        }

        guard title.count <= 200 else {
            return .invalid(reason: "Title cannot exceed 200 characters")
        }

        return validateInput(title, maxLength: 200)
    }

    /// Validates song content
    func validateSongContent(_ content: String) -> ValidationResult {
        // ChordPro files can be large, allow up to 50KB
        return validateInput(content, maxLength: 50000)
    }

    // MARK: - Operation Validation

    /// Validates if operation can be performed given current state
    func validateOperation(
        _ operation: CollaborationOperation,
        userRecordID: String,
        library: SharedLibrary
    ) async -> OperationValidationResult {
        // Check permission
        let permission = library.currentUserPermission(userRecordID: userRecordID)

        guard let permission = permission else {
            return .denied(reason: "You don't have access to this library")
        }

        // Validate based on operation type
        switch operation {
        case .createSong:
            if !permission.canEdit {
                return .denied(reason: "You need Editor permission to create songs")
            }

        case .editSong(let songID):
            if !permission.canEdit {
                return .denied(reason: "You need Editor permission to edit songs")
            }

            // Check if song exists
            guard await songExists(songID) else {
                return .invalid(reason: "Song no longer exists")
            }

            // Check for concurrent edits
            let editors = CollaborationEdgeCaseHandler.shared.detectConcurrentEdits(for: songID)
            if editors.count > 1 {
                return .warning(reason: "\(editors.count) users are editing this song")
            }

        case .deleteSong:
            if !permission.canEdit {
                return .denied(reason: "You need Editor permission to delete songs")
            }

        case .addMember:
            if !permission.canAddMembers {
                return .denied(reason: "You need Admin permission to add members")
            }

            // Check seat limit
            if library.isAtMemberLimit {
                return .denied(reason: "Library has reached member limit")
            }

        case .removeMember:
            if !permission.canRemoveMembers {
                return .denied(reason: "You need Admin permission to remove members")
            }

        case .changePermission:
            if !permission.canChangePermissions {
                return .denied(reason: "You need Admin permission to change permissions")
            }

        case .deleteLibrary:
            if !permission.canDeleteLibrary {
                return .denied(reason: "Only the library owner can delete it")
            }
        }

        return .allowed
    }

    /// Validates bulk operations
    func validateBulkOperation(
        operations: [CollaborationOperation],
        userRecordID: String,
        library: SharedLibrary
    ) async -> BulkOperationValidationResult {
        var deniedOperations: [(CollaborationOperation, String)] = []
        var warningOperations: [(CollaborationOperation, String)] = []

        for operation in operations {
            let result = await validateOperation(operation, userRecordID: userRecordID, library: library)

            switch result {
            case .denied(let reason):
                deniedOperations.append((operation, reason))
            case .warning(let reason):
                warningOperations.append((operation, reason))
            case .allowed, .invalid:
                break
            }
        }

        if !deniedOperations.isEmpty {
            return .partiallyDenied(denied: deniedOperations, warnings: warningOperations)
        } else if !warningOperations.isEmpty {
            return .allowedWithWarnings(warnings: warningOperations)
        } else {
            return .allAllowed
        }
    }

    // MARK: - Security Checks

    /// Checks if user can access entity
    func canAccessEntity(
        userRecordID: String,
        entityID: UUID,
        requiredPermission: LibraryPermission
    ) async -> Bool {
        // In production, query CloudKit to verify access
        // For now, assume access is granted if user has valid session
        return true
    }

    /// Validates CloudKit record before saving
    func validateCloudKitRecord(_ record: CKRecord) -> ValidationResult {
        // Check record size (CloudKit has 1MB limit per record)
        let estimatedSize = estimateRecordSize(record)

        if estimatedSize > 900_000 { // Leave buffer below 1MB limit
            return .invalid(reason: "Record too large for CloudKit (limit: 1MB)")
        }

        // Validate required fields
        guard record["title"] != nil else {
            return .invalid(reason: "Missing required field: title")
        }

        return .valid
    }

    /// Estimates CloudKit record size
    private func estimateRecordSize(_ record: CKRecord) -> Int {
        var size = 0

        for key in record.allKeys() {
            if let value = record[key] as? String {
                size += value.utf8.count
            } else if let value = record[key] as? Data {
                size += value.count
            } else if let value = record[key] as? NSNumber {
                size += 8 // Approximate
            } else if let value = record[key] as? Date {
                size += 8
            }
        }

        return size
    }

    // MARK: - Rate Limiting

    private var operationCounts: [String: Int] = [:]
    private var operationTimestamps: [String: Date] = [:]

    /// Checks if operation is rate limited
    func checkRateLimit(
        userRecordID: String,
        operation: String,
        limit: Int = 100,
        window: TimeInterval = 60
    ) -> RateLimitResult {
        let key = "\(userRecordID):\(operation)"

        // Reset if window expired
        if let timestamp = operationTimestamps[key],
           Date().timeIntervalSince(timestamp) > window {
            operationCounts[key] = 0
            operationTimestamps[key] = Date()
        }

        // Check count
        let count = operationCounts[key] ?? 0

        if count >= limit {
            let timeRemaining = window - Date().timeIntervalSince(operationTimestamps[key] ?? Date())
            return .limited(retryAfter: max(0, timeRemaining))
        }

        // Increment count
        operationCounts[key] = count + 1
        if operationTimestamps[key] == nil {
            operationTimestamps[key] = Date()
        }

        return .allowed
    }

    // MARK: - Helper Methods

    private func songExists(_ songID: UUID) async -> Bool {
        // In production, query SwiftData to check if song exists
        return true
    }
}

// MARK: - Validation Result

enum ValidationResult {
    case valid
    case warning(reason: String)
    case invalid(reason: String)

    var isValid: Bool {
        switch self {
        case .valid, .warning:
            return true
        case .invalid:
            return false
        }
    }
}

// MARK: - Operation Validation Result

enum OperationValidationResult {
    case allowed
    case warning(reason: String)
    case denied(reason: String)
    case invalid(reason: String)

    var isAllowed: Bool {
        switch self {
        case .allowed, .warning:
            return true
        case .denied, .invalid:
            return false
        }
    }

    var message: String? {
        switch self {
        case .allowed:
            return nil
        case .warning(let reason), .denied(let reason), .invalid(let reason):
            return reason
        }
    }
}

enum BulkOperationValidationResult {
    case allAllowed
    case allowedWithWarnings(warnings: [(CollaborationOperation, String)])
    case partiallyDenied(denied: [(CollaborationOperation, String)], warnings: [(CollaborationOperation, String)])
}

// MARK: - Collaboration Operation

enum CollaborationOperation: Equatable {
    case createSong
    case editSong(UUID)
    case deleteSong
    case addMember
    case removeMember
    case changePermission
    case deleteLibrary

    var displayName: String {
        switch self {
        case .createSong:
            return "Create Song"
        case .editSong:
            return "Edit Song"
        case .deleteSong:
            return "Delete Song"
        case .addMember:
            return "Add Member"
        case .removeMember:
            return "Remove Member"
        case .changePermission:
            return "Change Permission"
        case .deleteLibrary:
            return "Delete Library"
        }
    }
}

// MARK: - Rate Limit Result

enum RateLimitResult {
    case allowed
    case limited(retryAfter: TimeInterval)

    var isAllowed: Bool {
        switch self {
        case .allowed:
            return true
        case .limited:
            return false
        }
    }
}
