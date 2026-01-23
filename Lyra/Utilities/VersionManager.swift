//
//  VersionManager.swift
//  Lyra
//
//  Manages song version creation, retrieval, restoration, and lifecycle
//

import Foundation
import SwiftData
import UIKit

@MainActor
class VersionManager {
    static let shared = VersionManager()

    // MARK: - Configuration

    /// Maximum number of versions to keep per song (oldest versions are deleted)
    private let maxVersionsPerSong = 50

    /// Minimum content change threshold to trigger auto-save (characters changed)
    private let minChangeThreshold = 10

    /// Enable delta compression for storage optimization
    private let enableDeltaCompression = true

    /// Threshold for using delta compression (if version is >90% similar to previous)
    private let deltaCompressionThreshold = 0.9

    private init() {}

    // MARK: - Version Creation

    /// Creates a new version for a song
    func createVersion(
        for song: Song,
        modelContext: ModelContext,
        versionType: SongVersion.VersionType = .autoSave,
        changeDescription: String? = nil,
        changedByRecordID: String? = nil
    ) throws {
        // Get current version number (increment from last version)
        let versions = fetchVersions(for: song, context: modelContext)
        let nextVersionNumber = (versions.map { $0.versionNumber }.max() ?? 0) + 1

        // Get user identifier
        let changedBy = getCurrentUserName(recordID: changedByRecordID)

        // Create new version
        let newVersion = SongVersion(
            song: song,
            versionNumber: nextVersionNumber,
            changedBy: changedBy,
            changedByRecordID: changedByRecordID,
            changeDescription: changeDescription,
            versionType: versionType
        )

        // Apply delta compression if enabled and applicable
        if enableDeltaCompression, let previousVersion = versions.first {
            applyDeltaCompression(to: newVersion, from: previousVersion, allVersions: versions)
        }

        modelContext.insert(newVersion)
        try modelContext.save()

        // Cleanup old versions if exceeded limit
        try cleanupOldVersions(for: song, context: modelContext)

        // Post notification
        NotificationCenter.default.post(
            name: .versionCreated,
            object: nil,
            userInfo: ["songID": song.id, "version": newVersion]
        )
    }

    /// Checks if a new version should be created based on changes
    func shouldCreateVersion(for song: Song, previousContent: String?) -> Bool {
        guard let previous = previousContent else { return true }

        let currentContent = song.content
        let changes = calculateChanges(from: previous, to: currentContent)

        return changes >= minChangeThreshold
    }

    /// Creates a version manually with user-provided description
    func createManualVersion(
        for song: Song,
        modelContext: ModelContext,
        description: String,
        changedByRecordID: String? = nil
    ) throws {
        try createVersion(
            for: song,
            modelContext: modelContext,
            versionType: .manual,
            changeDescription: description,
            changedByRecordID: changedByRecordID
        )
    }

    // MARK: - Version Retrieval

    /// Fetches all versions for a song (sorted by version number, newest first)
    func fetchVersions(for song: Song, context: ModelContext) -> [SongVersion] {
        let songID = song.id
        let descriptor = FetchDescriptor<SongVersion>(
            sortBy: [SortDescriptor(\.versionNumber, order: .reverse)]
        )

        do {
            let allVersions = try context.fetch(descriptor)
            return allVersions.filter { $0.song?.id == songID }
        } catch {
            print("⚠️ Failed to fetch versions: \(error)")
            return []
        }
    }

    /// Fetches a specific version by version number
    func fetchVersion(
        for song: Song,
        versionNumber: Int,
        context: ModelContext
    ) -> SongVersion? {
        let versions = fetchVersions(for: song, context: context)
        return versions.first { $0.versionNumber == versionNumber }
    }

    /// Gets the latest version for a song
    func getLatestVersion(for song: Song, context: ModelContext) -> SongVersion? {
        return fetchVersions(for: song, context: context).first
    }

    // MARK: - Version Comparison

    /// Compares two versions and returns a diff result
    func compareVersions(
        version1: SongVersion,
        version2: SongVersion,
        allVersions: [SongVersion]
    ) -> DiffResult {
        let content1 = version1.reconstructContent(allVersions: allVersions)
        let content2 = version2.reconstructContent(allVersions: allVersions)

        return DiffAlgorithm.diff(original: content1, modified: content2)
    }

    /// Returns a summary of metadata changes between versions
    func compareMetadata(version1: SongVersion, version2: SongVersion) -> [MetadataChange] {
        var changes: [MetadataChange] = []

        if version1.snapshotTitle != version2.snapshotTitle {
            changes.append(MetadataChange(
                field: "Title",
                oldValue: version1.snapshotTitle,
                newValue: version2.snapshotTitle
            ))
        }

        if version1.snapshotArtist != version2.snapshotArtist {
            changes.append(MetadataChange(
                field: "Artist",
                oldValue: version1.snapshotArtist ?? "",
                newValue: version2.snapshotArtist ?? ""
            ))
        }

        if version1.snapshotOriginalKey != version2.snapshotOriginalKey {
            changes.append(MetadataChange(
                field: "Key",
                oldValue: version1.snapshotOriginalKey ?? "",
                newValue: version2.snapshotOriginalKey ?? ""
            ))
        }

        if version1.snapshotTempo != version2.snapshotTempo {
            changes.append(MetadataChange(
                field: "Tempo",
                oldValue: version1.snapshotTempo != nil ? "\(version1.snapshotTempo!) BPM" : "",
                newValue: version2.snapshotTempo != nil ? "\(version2.snapshotTempo!) BPM" : ""
            ))
        }

        if version1.snapshotTimeSignature != version2.snapshotTimeSignature {
            changes.append(MetadataChange(
                field: "Time Signature",
                oldValue: version1.snapshotTimeSignature ?? "",
                newValue: version2.snapshotTimeSignature ?? ""
            ))
        }

        if version1.snapshotCapo != version2.snapshotCapo {
            changes.append(MetadataChange(
                field: "Capo",
                oldValue: version1.snapshotCapo != nil ? "Fret \(version1.snapshotCapo!)" : "None",
                newValue: version2.snapshotCapo != nil ? "Fret \(version2.snapshotCapo!)" : "None"
            ))
        }

        return changes
    }

    // MARK: - Version Restoration

    /// Restores a song to a specific version
    func restoreVersion(
        _ version: SongVersion,
        to song: Song,
        modelContext: ModelContext,
        createCopy: Bool = false,
        allVersions: [SongVersion],
        changedByRecordID: String? = nil
    ) throws -> Song {
        let restoredSong: Song

        if createCopy {
            // Create a new song with the version content
            restoredSong = Song(
                title: "\(version.snapshotTitle) (Restored)",
                artist: version.snapshotArtist,
                content: version.reconstructContent(allVersions: allVersions),
                contentFormat: version.snapshotContentFormat,
                originalKey: version.snapshotOriginalKey
            )
            restoredSong.tempo = version.snapshotTempo
            restoredSong.timeSignature = version.snapshotTimeSignature
            restoredSong.capo = version.snapshotCapo
            restoredSong.notes = version.snapshotNotes
            restoredSong.tags = version.snapshotTags

            modelContext.insert(restoredSong)
        } else {
            // Restore in place (create version of current state first)
            try createVersion(
                for: song,
                modelContext: modelContext,
                versionType: .autoSave,
                changeDescription: "Before restoring version \(version.versionNumber)",
                changedByRecordID: changedByRecordID
            )

            // Update song with version content
            song.title = version.snapshotTitle
            song.artist = version.snapshotArtist
            song.content = version.reconstructContent(allVersions: allVersions)
            song.contentFormat = version.snapshotContentFormat
            song.originalKey = version.snapshotOriginalKey
            song.tempo = version.snapshotTempo
            song.timeSignature = version.snapshotTimeSignature
            song.capo = version.snapshotCapo
            song.notes = version.snapshotNotes
            song.tags = version.snapshotTags
            song.modifiedAt = Date()

            restoredSong = song

            // Create restore version
            try createVersion(
                for: song,
                modelContext: modelContext,
                versionType: .restore,
                changeDescription: "Restored from version \(version.versionNumber)",
                changedByRecordID: changedByRecordID
            )
        }

        try modelContext.save()

        // Post notification
        NotificationCenter.default.post(
            name: .versionRestored,
            object: nil,
            userInfo: [
                "songID": song.id,
                "versionNumber": version.versionNumber,
                "createCopy": createCopy
            ]
        )

        // Notify collaborators if this is a shared song
        if let library = song.sharedLibrary, !createCopy {
            await notifyCollaboratorsOfRestore(
                song: song,
                version: version,
                libraryID: library.id,
                changedByRecordID: changedByRecordID
            )
        }

        return restoredSong
    }

    // MARK: - Version Management

    /// Deletes a specific version
    func deleteVersion(
        _ version: SongVersion,
        modelContext: ModelContext
    ) throws {
        modelContext.delete(version)
        try modelContext.save()
    }

    /// Deletes old versions exceeding the retention limit
    private func cleanupOldVersions(
        for song: Song,
        context: ModelContext
    ) throws {
        let versions = fetchVersions(for: song, context: context)

        guard versions.count > maxVersionsPerSong else { return }

        // Sort by version number (oldest first) and delete excess
        let sortedVersions = versions.sorted { $0.versionNumber < $1.versionNumber }
        let versionsToDelete = sortedVersions.prefix(versions.count - maxVersionsPerSong)

        for version in versionsToDelete {
            // Don't delete manual versions unless absolutely necessary
            if version.versionType == .manual && versions.count < maxVersionsPerSong + 10 {
                continue
            }
            context.delete(version)
        }

        try context.save()
    }

    /// Returns storage statistics for a song's versions
    func getStorageStats(for song: Song, context: ModelContext) -> VersionStorageStats {
        let versions = fetchVersions(for: song, context: context)

        let totalUncompressed = versions.reduce(0) { $0 + $1.uncompressedSize }
        let totalStorage = versions.reduce(0) { $0 + $1.storageSize }
        let deltaVersions = versions.filter { $0.isDelta }.count

        return VersionStorageStats(
            versionCount: versions.count,
            totalUncompressedSize: totalUncompressed,
            totalStorageSize: totalStorage,
            deltaVersionCount: deltaVersions,
            compressionRatio: totalUncompressed > 0 ? (1.0 - Double(totalStorage) / Double(totalUncompressed)) * 100.0 : 0
        )
    }

    // MARK: - Private Helpers

    private func getCurrentUserName(recordID: String?) -> String {
        if let recordID = recordID,
           let presence = PresenceManager.shared.currentUserPresence {
            return presence.displayName
        }
        return UIDevice.current.name
    }

    private func calculateChanges(from old: String, to new: String) -> Int {
        let diff = DiffAlgorithm.diff(original: old, modified: new)
        return diff.addedCount + diff.removedCount + diff.modifiedCount
    }

    private func applyDeltaCompression(
        to newVersion: SongVersion,
        from previousVersion: SongVersion,
        allVersions: [SongVersion]
    ) {
        let previousContent = previousVersion.reconstructContent(allVersions: allVersions)
        let currentContent = newVersion.snapshotContent

        // Calculate similarity
        let similarity = calculateSimilarity(previousContent, currentContent)

        guard similarity >= deltaCompressionThreshold else { return }

        // Generate diff
        let diff = DiffAlgorithm.diff(original: previousContent, modified: currentContent)

        // Create delta representation
        var deltaLines: [String] = []
        for line in diff.lines {
            switch line.type {
            case .unchanged:
                deltaLines.append(" \(line.content)")
            case .added, .modified:
                deltaLines.append("+\(line.content)")
            case .removed:
                deltaLines.append("-\(line.content)")
            }
        }

        let deltaString = deltaLines.joined(separator: "\n")

        // Compress delta
        if let deltaData = deltaString.data(using: .utf8) {
            do {
                let compressed = try (deltaData as NSData).compressed(using: .lzfse)
                newVersion.isDelta = true
                newVersion.deltaBaseVersionNumber = previousVersion.versionNumber
                newVersion.deltaData = compressed as Data
                newVersion.storageSize = compressed.length

                print("✅ Delta compression: \(newVersion.uncompressedSize) → \(compressed.length) bytes (\(String(format: "%.1f", newVersion.compressionRatio))% saved)")
            } catch {
                print("⚠️ Delta compression failed: \(error)")
            }
        }
    }

    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let lines1 = Set(text1.components(separatedBy: .newlines))
        let lines2 = Set(text2.components(separatedBy: .newlines))

        let intersection = lines1.intersection(lines2).count
        let union = lines1.union(lines2).count

        return union > 0 ? Double(intersection) / Double(union) : 0
    }

    private func notifyCollaboratorsOfRestore(
        song: Song,
        version: SongVersion,
        libraryID: UUID,
        changedByRecordID: String?
    ) async {
        guard let currentPresence = PresenceManager.shared.currentUserPresence else { return }

        // Send notification via CollaborationNotificationManager
        let notificationManager = CollaborationNotificationManager.shared
        await notificationManager.sendVersionRestoreNotification(
            songID: song.id,
            songTitle: song.title,
            versionNumber: version.versionNumber,
            libraryID: libraryID,
            restoredBy: currentPresence.displayName
        )
    }
}

// MARK: - Supporting Types

struct MetadataChange: Identifiable {
    let id = UUID()
    let field: String
    let oldValue: String
    let newValue: String
}

struct VersionStorageStats {
    let versionCount: Int
    let totalUncompressedSize: Int
    let totalStorageSize: Int
    let deltaVersionCount: Int
    let compressionRatio: Double

    var formattedUncompressedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalUncompressedSize), countStyle: .file)
    }

    var formattedStorageSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalStorageSize), countStyle: .file)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let versionCreated = Notification.Name("versionCreated")
    static let versionRestored = Notification.Name("versionRestored")
}
