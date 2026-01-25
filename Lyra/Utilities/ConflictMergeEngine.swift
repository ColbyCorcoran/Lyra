//
//  ConflictMergeEngine.swift
//  Lyra
//
//  Intelligent three-way merge engine for resolving sync conflicts
//

import Foundation
import SwiftData

/// Represents a field that has conflicting values
enum ConflictField: Identifiable, Equatable {
    case title(local: String, remote: String)
    case artist(local: String?, remote: String?)
    case album(local: String?, remote: String?)
    case key(local: String?, remote: String?)
    case tempo(local: Int?, remote: Int?)
    case timeSignature(local: String?, remote: String?)
    case content(localLines: [Int], remoteLines: [Int], mergedContent: String)
    case tags(local: [String]?, remote: [String]?)
    case notes(local: String?, remote: String?)

    var id: String {
        switch self {
        case .title: return "title"
        case .artist: return "artist"
        case .album: return "album"
        case .key: return "key"
        case .tempo: return "tempo"
        case .timeSignature: return "timeSignature"
        case .content: return "content"
        case .tags: return "tags"
        case .notes: return "notes"
        }
    }

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .artist: return "Artist"
        case .album: return "Album"
        case .key: return "Key"
        case .tempo: return "Tempo"
        case .timeSignature: return "Time Signature"
        case .content: return "Content"
        case .tags: return "Tags"
        case .notes: return "Notes"
        }
    }

    static func == (lhs: ConflictField, rhs: ConflictField) -> Bool {
        lhs.id == rhs.id
    }
}

/// Result of merge operation
struct SongMergeResult {
    let mergedData: ConflictVersion.ConflictData
    let manualResolutionNeeded: [ConflictField]
    let autoMergedFields: [String]

    var canAutoResolve: Bool {
        manualResolutionNeeded.isEmpty
    }
}

/// Engine for merging song conflicts
struct ConflictMergeEngine {

    // MARK: - Public Interface

    /// Performs three-way merge of song conflicts
    static func merge(
        local: ConflictVersion.ConflictData,
        remote: ConflictVersion.ConflictData,
        base: ConflictVersion.ConflictData?
    ) -> SongMergeResult {

        var mergedData = local
        var manualResolutionNeeded: [ConflictField] = []
        var autoMergedFields: [String] = []

        // Merge metadata fields
        mergeField(
            fieldName: "title",
            localValue: local.title,
            remoteValue: remote.title,
            baseValue: base?.title,
            mergedData: &mergedData,
            manualResolution: &manualResolutionNeeded,
            autoMerged: &autoMergedFields,
            conflictFactory: { ConflictField.title(local: $0, remote: $1) },
            setter: { mergedData.title = $0 }
        )

        mergeField(
            fieldName: "artist",
            localValue: local.artist,
            remoteValue: remote.artist,
            baseValue: base?.artist,
            mergedData: &mergedData,
            manualResolution: &manualResolutionNeeded,
            autoMerged: &autoMergedFields,
            conflictFactory: { ConflictField.artist(local: $0, remote: $1) },
            setter: { mergedData.artist = $0 }
        )

        mergeField(
            fieldName: "key",
            localValue: local.key,
            remoteValue: remote.key,
            baseValue: base?.key,
            mergedData: &mergedData,
            manualResolution: &manualResolutionNeeded,
            autoMerged: &autoMergedFields,
            conflictFactory: { ConflictField.key(local: $0, remote: $1) },
            setter: { mergedData.key = $0 }
        )

        // Merge content (most complex)
        if let localContent = local.content,
           let remoteContent = remote.content {
            let contentMerge = mergeContent(
                local: localContent,
                remote: remoteContent,
                base: base?.content
            )

            mergedData.content = contentMerge.merged

            if contentMerge.hasConflicts {
                let conflictingLines = contentMerge.conflicts.map { $0.lineNumber }
                manualResolutionNeeded.append(.content(
                    localLines: conflictingLines,
                    remoteLines: conflictingLines,
                    mergedContent: contentMerge.merged
                ))
            } else {
                autoMergedFields.append("content")
            }
        }

        // Merge tags (combine unique values)
        if let localTags = local.tags, let remoteTags = remote.tags {
            let baseTags = base?.tags ?? []

            // Combine all unique tags
            let allTags = Set(localTags).union(Set(remoteTags))
            let removedFromLocal = Set(baseTags).subtracting(Set(localTags))
            let removedFromRemote = Set(baseTags).subtracting(Set(remoteTags))

            // Only keep tags that weren't explicitly removed by both sides
            let mergedTags = allTags.subtracting(removedFromLocal.intersection(removedFromRemote))

            mergedData.tags = Array(mergedTags).sorted()
            autoMergedFields.append("tags")
        }

        return SongMergeResult(
            mergedData: mergedData,
            manualResolutionNeeded: manualResolutionNeeded,
            autoMergedFields: autoMergedFields
        )
    }

    // MARK: - Field-Level Merge

    /// Generic field merge with three-way logic
    private static func mergeField<T: Equatable>(
        fieldName: String,
        localValue: T?,
        remoteValue: T?,
        baseValue: T?,
        mergedData: inout ConflictVersion.ConflictData,
        manualResolution: inout [ConflictField],
        autoMerged: inout [String],
        conflictFactory: (T, T) -> ConflictField,
        setter: (T?) -> Void
    ) {
        // No conflict if values are equal
        if localValue == remoteValue {
            setter(localValue)
            return
        }

        // Three-way merge logic
        if let base = baseValue {
            // Local changed, remote unchanged
            if localValue != base && remoteValue == base {
                setter(localValue)
                autoMerged.append(fieldName)
                return
            }

            // Remote changed, local unchanged
            if remoteValue != base && localValue == base {
                setter(remoteValue)
                autoMerged.append(fieldName)
                return
            }

            // Both changed - conflict
            if let local = localValue, let remote = remoteValue {
                manualResolution.append(conflictFactory(local, remote))
                setter(localValue) // Default to local until resolved
                return
            }
        }

        // No base version - need manual resolution
        if let local = localValue, let remote = remoteValue {
            manualResolution.append(conflictFactory(local, remote))
            setter(localValue) // Default to local until resolved
        } else {
            // One is nil - keep the non-nil value
            setter(localValue ?? remoteValue)
            autoMerged.append(fieldName)
        }
    }

    // MARK: - Content Merge

    /// Merges song content using diff algorithm
    private static func mergeContent(
        local: String,
        remote: String,
        base: String?
    ) -> MergeResult {
        if let base = base {
            // Three-way merge
            return DiffAlgorithm.threeWayMerge(
                base: base,
                local: local,
                remote: remote
            )
        } else {
            // No base - return simple diff
            let diff = DiffAlgorithm.diff(original: local, modified: remote)

            if diff.hasChanges {
                // Create conflict markers
                let merged = """
                <<<<<<< LOCAL
                \(local)
                =======
                \(remote)
                >>>>>>> REMOTE
                """

                return MergeResult(
                    merged: merged,
                    conflicts: [MergeConflict(
                        lineNumber: 1,
                        baseLine: nil,
                        localLine: local,
                        remoteLine: remote
                    )],
                    hasConflicts: true
                )
            } else {
                return MergeResult(
                    merged: local,
                    conflicts: [],
                    hasConflicts: false
                )
            }
        }
    }

    // MARK: - Field Selection Application

    /// Applies user's field-by-field choices to create final merged data
    static func applyFieldChoices(
        local: ConflictVersion.ConflictData,
        remote: ConflictVersion.ConflictData,
        choices: [String: FieldChoice]
    ) -> ConflictVersion.ConflictData {

        var merged = local

        for (field, choice) in choices {
            switch choice {
            case .local:
                // Already using local, no change needed
                continue

            case .remote:
                // Apply remote value for this field
                switch field {
                case "title":
                    merged.title = remote.title
                case "artist":
                    merged.artist = remote.artist
                case "content":
                    merged.content = remote.content
                case "key":
                    merged.key = remote.key
                case "tags":
                    merged.tags = remote.tags
                default:
                    break
                }

            case .custom(let value):
                // Apply custom value
                switch field {
                case "title":
                    merged.title = value
                case "artist":
                    merged.artist = value
                case "content":
                    merged.content = value
                case "key":
                    merged.key = value
                default:
                    break
                }
            }
        }

        return merged
    }
}

// MARK: - Field Choice

/// Represents user's choice for a conflicting field
enum FieldChoice: Equatable {
    case local
    case remote
    case custom(String)
}

// MARK: - Conflicting Field Data

/// Data structure for presenting field conflicts to user
struct ConflictingFieldData {
    let key: String
    let displayName: String
    let localValue: String?
    let remoteValue: String?
    let baseValue: String?
    let fieldType: FieldType

    enum FieldType {
        case text
        case number
        case date
        case boolean
        case array
    }
}
