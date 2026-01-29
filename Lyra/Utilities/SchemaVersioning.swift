//
//  SchemaVersioning.swift
//  Lyra
//
//  SwiftData schema versioning and migration support
//

import SwiftData
import Foundation

/// Current schema version for the Lyra app
enum SchemaVersioning {
    /// Expected model count in the schema
    static let expectedModelCount = 8

    /// Expected model names in the current schema
    static let expectedModelNames = [
        "Song",
        "Template",
        "Book",
        "PerformanceSet",
        "SetEntry",
        "Annotation",
        "UserSettings",
        "RecurrenceRule"
    ]

    /// Validate that a schema contains all required models
    static func validateSchema(_ schema: Schema) -> [String] {
        var missingModels: [String] = []

        for expectedName in expectedModelNames {
            if !schema.entities.contains(where: { $0.name == expectedName }) {
                missingModels.append(expectedName)
            }
        }

        return missingModels
    }

    /// Validate schema entity count matches expected
    static func validateEntityCount(_ schema: Schema) -> Bool {
        return schema.entities.count == expectedModelCount
    }
}

/// Errors that can occur during schema validation
enum SchemaValidationError: Error, LocalizedError {
    case noSchemasDefinied
    case missingBaseSchema
    case missingModels([String])
    case wrongEntityCount(expected: Int, actual: Int)

    var errorDescription: String? {
        switch self {
        case .noSchemasDefinied:
            return "No schema versions are defined in the migration plan"
        case .missingBaseSchema:
            return "Base schema (SchemaV1) is missing from migration plan"
        case .missingModels(let models):
            return "Schema is missing required models: \(models.joined(separator: ", "))"
        case .wrongEntityCount(let expected, let actual):
            return "Schema entity count mismatch. Expected: \(expected), Actual: \(actual)"
        }
    }
}
