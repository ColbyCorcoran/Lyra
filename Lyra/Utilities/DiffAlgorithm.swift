//
//  DiffAlgorithm.swift
//  Lyra
//
//  Implements Myers diff algorithm for text comparison and conflict visualization
//

import Foundation

/// Represents a single line in a diff with its change type
struct DiffLine: Identifiable, Equatable {
    let id = UUID()
    let lineNumber: Int
    let content: String
    let type: DiffType
    let originalLineNumber: Int? // For tracking line origins

    enum DiffType: Equatable {
        case unchanged
        case added
        case removed
        case modified
    }
}

/// Result of a diff operation
struct DiffResult {
    let lines: [DiffLine]
    let addedCount: Int
    let removedCount: Int
    let modifiedCount: Int

    var hasChanges: Bool {
        addedCount > 0 || removedCount > 0 || modifiedCount > 0
    }
}

/// Myers diff algorithm implementation
struct DiffAlgorithm {

    // MARK: - Public Interface

    /// Compares two strings and returns line-by-line diff
    static func diff(original: String, modified: String) -> DiffResult {
        let originalLines = original.components(separatedBy: .newlines)
        let modifiedLines = modified.components(separatedBy: .newlines)

        return diffLines(original: originalLines, modified: modifiedLines)
    }

    /// Compares two arrays of lines
    static func diffLines(original: [String], modified: [String]) -> DiffResult {
        let operations = calculateDiff(original: original, modified: modified)

        var diffLines: [DiffLine] = []
        var addedCount = 0
        var removedCount = 0
        var modifiedCount = 0

        var originalIndex = 0
        var modifiedIndex = 0
        var lineNumber = 1

        for operation in operations {
            switch operation {
            case .keep(let line):
                diffLines.append(DiffLine(
                    lineNumber: lineNumber,
                    content: line,
                    type: .unchanged,
                    originalLineNumber: originalIndex
                ))
                originalIndex += 1
                modifiedIndex += 1
                lineNumber += 1

            case .insert(let line):
                diffLines.append(DiffLine(
                    lineNumber: lineNumber,
                    content: line,
                    type: .added,
                    originalLineNumber: nil
                ))
                modifiedIndex += 1
                lineNumber += 1
                addedCount += 1

            case .delete(let line):
                diffLines.append(DiffLine(
                    lineNumber: lineNumber,
                    content: line,
                    type: .removed,
                    originalLineNumber: originalIndex
                ))
                originalIndex += 1
                lineNumber += 1
                removedCount += 1

            case .modify(let oldLine, let newLine):
                // Show as removed + added for clarity
                diffLines.append(DiffLine(
                    lineNumber: lineNumber,
                    content: oldLine,
                    type: .removed,
                    originalLineNumber: originalIndex
                ))
                lineNumber += 1

                diffLines.append(DiffLine(
                    lineNumber: lineNumber,
                    content: newLine,
                    type: .added,
                    originalLineNumber: nil
                ))
                lineNumber += 1

                originalIndex += 1
                modifiedIndex += 1
                modifiedCount += 1
            }
        }

        return DiffResult(
            lines: diffLines,
            addedCount: addedCount,
            removedCount: removedCount,
            modifiedCount: modifiedCount
        )
    }

    // MARK: - Three-Way Merge

    /// Performs three-way merge with base version
    static func threeWayMerge(
        base: String,
        local: String,
        remote: String
    ) -> MergeResult {
        let baseLines = base.components(separatedBy: .newlines)
        let localLines = local.components(separatedBy: .newlines)
        let remoteLines = remote.components(separatedBy: .newlines)

        return threeWayMergeLines(base: baseLines, local: localLines, remote: remoteLines)
    }

    /// Three-way merge for line arrays
    static func threeWayMergeLines(
        base: [String],
        local: [String],
        remote: [String]
    ) -> MergeResult {
        _ = calculateDiff(original: base, modified: local)
        _ = calculateDiff(original: base, modified: remote)

        var mergedLines: [String] = []
        var conflicts: [MergeConflict] = []

        var baseIndex = 0
        var localIndex = 0
        var remoteIndex = 0

        while baseIndex < base.count || localIndex < local.count || remoteIndex < remote.count {
            let baseLine = baseIndex < base.count ? base[baseIndex] : nil
            let localLine = localIndex < local.count ? local[localIndex] : nil
            let remoteLine = remoteIndex < remote.count ? remote[remoteIndex] : nil

            // Simple case: all lines match
            if baseLine == localLine && localLine == remoteLine {
                if let line = baseLine {
                    mergedLines.append(line)
                }
                baseIndex += 1
                localIndex += 1
                remoteIndex += 1
                continue
            }

            // Local changed, remote unchanged
            if localLine != baseLine && remoteLine == baseLine {
                if let line = localLine {
                    mergedLines.append(line)
                }
                localIndex += 1
                if remoteLine != nil { remoteIndex += 1 }
                if baseLine != nil { baseIndex += 1 }
                continue
            }

            // Remote changed, local unchanged
            if remoteLine != baseLine && localLine == baseLine {
                if let line = remoteLine {
                    mergedLines.append(line)
                }
                remoteIndex += 1
                if localLine != nil { localIndex += 1 }
                if baseLine != nil { baseIndex += 1 }
                continue
            }

            // Both changed - conflict
            if localLine != remoteLine {
                let conflict = MergeConflict(
                    lineNumber: mergedLines.count + 1,
                    baseLine: baseLine,
                    localLine: localLine,
                    remoteLine: remoteLine
                )
                conflicts.append(conflict)

                // Add conflict markers
                mergedLines.append("<<<<<<< LOCAL")
                if let line = localLine {
                    mergedLines.append(line)
                    localIndex += 1
                }
                mergedLines.append("=======")
                if let line = remoteLine {
                    mergedLines.append(line)
                    remoteIndex += 1
                }
                mergedLines.append(">>>>>>> REMOTE")

                if baseLine != nil { baseIndex += 1 }
            }
        }

        return MergeResult(
            merged: mergedLines.joined(separator: "\n"),
            conflicts: conflicts,
            hasConflicts: !conflicts.isEmpty
        )
    }

    // MARK: - Private Implementation

    private enum DiffOperation {
        case keep(String)
        case insert(String)
        case delete(String)
        case modify(old: String, new: String)
    }

    /// Calculates diff operations using simplified LCS algorithm
    private static func calculateDiff(original: [String], modified: [String]) -> [DiffOperation] {
        let lcs = longestCommonSubsequence(original, modified)

        var operations: [DiffOperation] = []
        var originalIndex = 0
        var modifiedIndex = 0
        var lcsIndex = 0

        while originalIndex < original.count || modifiedIndex < modified.count {
            if lcsIndex < lcs.count {
                let commonLine = lcs[lcsIndex]

                // Skip deleted lines
                while originalIndex < original.count && original[originalIndex] != commonLine {
                    operations.append(.delete(original[originalIndex]))
                    originalIndex += 1
                }

                // Skip inserted lines
                while modifiedIndex < modified.count && modified[modifiedIndex] != commonLine {
                    operations.append(.insert(modified[modifiedIndex]))
                    modifiedIndex += 1
                }

                // Add common line
                if originalIndex < original.count && modifiedIndex < modified.count {
                    operations.append(.keep(commonLine))
                    originalIndex += 1
                    modifiedIndex += 1
                    lcsIndex += 1
                }
            } else {
                // No more common lines - rest are changes
                if originalIndex < original.count {
                    operations.append(.delete(original[originalIndex]))
                    originalIndex += 1
                }
                if modifiedIndex < modified.count {
                    operations.append(.insert(modified[modifiedIndex]))
                    modifiedIndex += 1
                }
            }
        }

        return operations
    }

    /// Finds longest common subsequence using dynamic programming
    private static func longestCommonSubsequence(_ a: [String], _ b: [String]) -> [String] {
        let m = a.count
        let n = b.count

        // Create LCS table
        var table = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 1...m {
            for j in 1...n {
                if a[i - 1] == b[j - 1] {
                    table[i][j] = table[i - 1][j - 1] + 1
                } else {
                    table[i][j] = max(table[i - 1][j], table[i][j - 1])
                }
            }
        }

        // Backtrack to find LCS
        var lcs: [String] = []
        var i = m
        var j = n

        while i > 0 && j > 0 {
            if a[i - 1] == b[j - 1] {
                lcs.insert(a[i - 1], at: 0)
                i -= 1
                j -= 1
            } else if table[i - 1][j] > table[i][j - 1] {
                i -= 1
            } else {
                j -= 1
            }
        }

        return lcs
    }
}

// MARK: - Supporting Types

/// Represents a merge conflict requiring manual resolution
struct MergeConflict: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let baseLine: String?
    let localLine: String?
    let remoteLine: String?
}

/// Result of a three-way merge
struct MergeResult {
    let merged: String
    let conflicts: [MergeConflict]
    let hasConflicts: Bool
}
