//
//  FolderManager.swift
//  Lyra
//
//  Utility for managing PerformanceSet folders
//

import Foundation
import SwiftData

@MainActor
class FolderManager {

    /// Get all unique folder names from PerformanceSets
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Sorted array of unique folder names (excluding nil/empty)
    static func getAllFolders(from context: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<PerformanceSet>()

        guard let allSets = try? context.fetch(descriptor) else {
            return []
        }

        // Extract unique non-empty folders
        let folders = allSets.compactMap { set -> String? in
            guard let folder = set.folder,
                  !folder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return folder.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let uniqueFolders = Set(folders)

        // Return sorted alphabetically
        return uniqueFolders.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Create and validate a folder name
    /// - Parameter name: The proposed folder name
    /// - Returns: Validated and formatted folder name
    static func createFolder(_ name: String) -> String {
        // Trim whitespace
        var folderName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Title case each word
        folderName = folderName.capitalized

        return folderName
    }

    /// Check if a folder name already exists (case-insensitive)
    /// - Parameters:
    ///   - name: Folder name to check
    ///   - context: SwiftData ModelContext
    /// - Returns: True if folder already exists
    static func folderExists(_ name: String, in context: ModelContext) -> Bool {
        let existingFolders = getAllFolders(from: context)
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)

        return existingFolders.contains { folder in
            folder.localizedCaseInsensitiveCompare(normalized) == .orderedSame
        }
    }

    /// Get count of sets in a folder
    /// - Parameters:
    ///   - folderName: The folder name
    ///   - context: SwiftData ModelContext
    /// - Returns: Number of PerformanceSets in the folder
    static func getSetCount(for folderName: String?, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<PerformanceSet>()

        guard let allSets = try? context.fetch(descriptor) else {
            return 0
        }

        if let folderName = folderName {
            return allSets.filter { $0.folder == folderName }.count
        } else {
            // Count sets with no folder
            return allSets.filter { $0.folder == nil || $0.folder?.isEmpty == true }.count
        }
    }
}
