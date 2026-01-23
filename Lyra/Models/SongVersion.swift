//
//  SongVersion.swift
//  Lyra
//
//  Stores historical versions of songs for tracking changes and restoring previous states
//

import SwiftData
import Foundation

@Model
final class SongVersion {
    // MARK: - Identifiers
    var id: UUID
    var createdAt: Date

    // MARK: - Version Metadata
    var versionNumber: Int
    var changeDescription: String?

    // MARK: - Author Information
    var changedBy: String // User name or device name
    var changedByRecordID: String? // CloudKit user record ID if available

    // MARK: - Song Reference
    @Relationship(deleteRule: .nullify, inverse: \Song.versions)
    var song: Song?

    // MARK: - Snapshot Content
    // Core song data
    var snapshotTitle: String
    var snapshotArtist: String?
    var snapshotContent: String
    var snapshotContentFormat: ContentFormat

    // Musical information
    var snapshotOriginalKey: String?
    var snapshotTempo: Int?
    var snapshotTimeSignature: String?
    var snapshotCapo: Int?

    // Additional metadata
    var snapshotNotes: String?
    var snapshotTags: [String]?

    // MARK: - Storage Optimization
    /// Whether this version stores full content or a delta from previous version
    var isDelta: Bool

    /// For delta versions: reference to the base version
    var deltaBaseVersionNumber: Int?

    /// For delta versions: compressed diff data
    var deltaData: Data?

    /// Uncompressed size (for storage metrics)
    var uncompressedSize: Int

    /// Actual storage size (compressed if delta)
    var storageSize: Int

    // MARK: - Version Type
    enum VersionType: String, Codable {
        case manual // User explicitly saved a version
        case autoSave // Auto-saved on edit
        case restore // Created when restoring an old version
        case import // Created on initial import
    }

    var versionType: VersionType

    // MARK: - Initializer
    init(
        song: Song,
        versionNumber: Int,
        changedBy: String,
        changedByRecordID: String? = nil,
        changeDescription: String? = nil,
        versionType: VersionType = .autoSave,
        isDelta: Bool = false
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.song = song
        self.versionNumber = versionNumber
        self.changedBy = changedBy
        self.changedByRecordID = changedByRecordID
        self.changeDescription = changeDescription
        self.versionType = versionType
        self.isDelta = isDelta

        // Snapshot current song state
        self.snapshotTitle = song.title
        self.snapshotArtist = song.artist
        self.snapshotContent = song.content
        self.snapshotContentFormat = song.contentFormat
        self.snapshotOriginalKey = song.originalKey
        self.snapshotTempo = song.tempo
        self.snapshotTimeSignature = song.timeSignature
        self.snapshotCapo = song.capo
        self.snapshotNotes = song.notes
        self.snapshotTags = song.tags

        // Calculate storage size
        let contentSize = song.content.utf8.count
        let metadataSize = (song.title.utf8.count +
                           (song.artist?.utf8.count ?? 0) +
                           (song.notes?.utf8.count ?? 0))
        self.uncompressedSize = contentSize + metadataSize
        self.storageSize = self.uncompressedSize // Will be updated if delta compression is applied
    }

    // MARK: - Version Reconstruction

    /// Reconstructs the full song content from this version (handling deltas if needed)
    func reconstructContent(allVersions: [SongVersion]) -> String {
        if !isDelta {
            return snapshotContent
        }

        guard let deltaData = deltaData,
              let baseVersionNum = deltaBaseVersionNumber,
              let baseVersion = allVersions.first(where: { $0.versionNumber == baseVersionNum }) else {
            return snapshotContent
        }

        // Reconstruct from base + delta
        let baseContent = baseVersion.reconstructContent(allVersions: allVersions)

        do {
            let decompressed = try (deltaData as NSData).decompressed(using: .lzfse)
            if let deltaString = String(data: decompressed as Data, encoding: .utf8) {
                return applyDelta(base: baseContent, delta: deltaString)
            }
        } catch {
            print("⚠️ Failed to decompress delta: \(error)")
        }

        return snapshotContent
    }

    /// Applies a delta patch to base content
    private func applyDelta(base: String, delta: String) -> String {
        // Parse delta format: lines starting with + are additions, - are deletions, space are unchanged
        let baseLines = base.components(separatedBy: .newlines)
        let deltaLines = delta.components(separatedBy: .newlines)

        var result: [String] = []
        var baseIndex = 0

        for deltaLine in deltaLines {
            if deltaLine.hasPrefix("+") {
                // Addition
                let content = String(deltaLine.dropFirst())
                result.append(content)
            } else if deltaLine.hasPrefix("-") {
                // Deletion - skip this line in base
                baseIndex += 1
            } else if deltaLine.hasPrefix(" ") {
                // Unchanged - copy from base
                if baseIndex < baseLines.count {
                    result.append(baseLines[baseIndex])
                    baseIndex += 1
                }
            }
        }

        return result.joined(separator: "\n")
    }

    // MARK: - Helper Methods

    /// Returns a summary of changes in this version
    var changeSummary: String {
        if let description = changeDescription {
            return description
        }

        switch versionType {
        case .manual:
            return "Manual save"
        case .autoSave:
            return "Auto-saved changes"
        case .restore:
            return "Restored from version \(versionNumber)"
        case .import:
            return "Initial import"
        }
    }

    /// Returns storage efficiency percentage (for delta versions)
    var compressionRatio: Double {
        guard uncompressedSize > 0 else { return 0 }
        return (1.0 - Double(storageSize) / Double(uncompressedSize)) * 100.0
    }
}

// MARK: - Song Extension

extension Song {
    @Relationship(deleteRule: .cascade, inverse: \SongVersion.song)
    var versions: [SongVersion]? { get { nil } set { } }
}
