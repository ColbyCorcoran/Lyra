//
//  ImportManager.swift
//  Lyra
//
//  Handles importing ChordPro files from external sources
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

enum ImportError: LocalizedError {
    case fileNotReadable
    case emptyContent
    case invalidEncoding
    case parsingFailed
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotReadable:
            return "Unable to read the file"
        case .emptyContent:
            return "The file is empty"
        case .invalidEncoding:
            return "The file encoding is not supported"
        case .parsingFailed:
            return "Unable to parse the ChordPro content"
        case .unknownError(let error):
            return "Import failed: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotReadable:
            return "Make sure the file is a valid text file and try again."
        case .emptyContent:
            return "The file contains no content. Please select a different file."
        case .invalidEncoding:
            return "Try converting the file to UTF-8 encoding."
        case .parsingFailed:
            return "The file may not be in ChordPro format. You can still import it as plain text."
        case .unknownError:
            return "Please try again or contact support if the issue persists."
        }
    }
}

struct ImportResult {
    let song: Song
    let filename: String
    let hadParsingWarnings: Bool
}

@MainActor
class ImportManager {
    static let shared = ImportManager()

    /// Supported file types for import
    static let supportedTypes: [UTType] = [
        .plainText,           // .txt
        .text,                // Generic text
        UTType(filenameExtension: "cho") ?? .text,       // .cho
        UTType(filenameExtension: "chordpro") ?? .text,  // .chordpro
        UTType(filenameExtension: "chopro") ?? .text,    // .chopro (alternative)
        UTType(filenameExtension: "crd") ?? .text        // .crd (chord files)
    ]

    private init() {}

    /// Import a ChordPro file and create a Song
    func importFile(from url: URL, to modelContext: ModelContext) throws -> ImportResult {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileNotReadable
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Read file contents
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try alternative encodings
            if let altContent = try? String(contentsOf: url, encoding: .ascii) {
                content = altContent
            } else if let altContent = try? String(contentsOf: url, encoding: .isoLatin1) {
                content = altContent
            } else {
                throw ImportError.invalidEncoding
            }
        }

        // Check for empty content
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.emptyContent
        }

        // Get filename
        let filename = url.lastPathComponent

        // Parse ChordPro content
        let parsed = ChordProParser.parse(content)

        // Extract title (from parsed metadata or filename)
        let title = parsed.title ?? filenameWithoutExtension(filename)

        // Create Song object
        let song = Song(
            title: title,
            artist: parsed.artist,
            content: content,
            contentFormat: .chordPro,
            originalKey: parsed.key
        )

        // Set additional metadata from parsed content
        song.tempo = parsed.tempo
        song.timeSignature = parsed.timeSignature
        song.capo = parsed.capo
        song.copyright = parsed.copyright
        song.ccliNumber = parsed.ccliNumber
        song.album = parsed.album
        song.year = parsed.year

        // Set import metadata
        song.importSource = "Files"
        song.importedAt = Date()
        song.originalFilename = filename

        // Insert into SwiftData
        modelContext.insert(song)
        try modelContext.save()

        // Check for parsing warnings (no sections parsed)
        let hadWarnings = parsed.sections.isEmpty && !content.isEmpty

        return ImportResult(
            song: song,
            filename: filename,
            hadParsingWarnings: hadWarnings
        )
    }

    /// Import file as plain text (fallback for parsing errors)
    func importAsPlainText(from url: URL, to modelContext: ModelContext) throws -> ImportResult {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileNotReadable
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Read file contents
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ImportError.invalidEncoding
        }

        guard !content.isEmpty else {
            throw ImportError.emptyContent
        }

        let filename = url.lastPathComponent
        let title = filenameWithoutExtension(filename)

        // Create Song with plain text
        let song = Song(
            title: title,
            content: content,
            contentFormat: .plainText
        )

        song.importSource = "Files (Plain Text)"
        song.importedAt = Date()
        song.originalFilename = filename

        modelContext.insert(song)
        try modelContext.save()

        return ImportResult(
            song: song,
            filename: filename,
            hadParsingWarnings: true
        )
    }

    // MARK: - Helper Methods

    private func filenameWithoutExtension(_ filename: String) -> String {
        let url = URL(fileURLWithPath: filename)
        return url.deletingPathExtension().lastPathComponent
    }
}
