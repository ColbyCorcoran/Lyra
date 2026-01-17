//
//  ClipboardManager.swift
//  Lyra
//
//  Handles pasting ChordPro songs from clipboard
//

import Foundation
import SwiftData
import UIKit

enum ClipboardError: LocalizedError {
    case emptyClipboard
    case invalidContent
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .emptyClipboard:
            return "Clipboard is empty"
        case .invalidContent:
            return "No text found in clipboard"
        case .saveFailed:
            return "Failed to save song"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyClipboard:
            return "Copy some ChordPro content and try again."
        case .invalidContent:
            return "Copy text content and try again."
        case .saveFailed:
            return "Please try again."
        }
    }
}

struct PasteResult {
    let song: Song
    let hadParsingWarnings: Bool
    let wasUntitled: Bool
}

@MainActor
class ClipboardManager {
    static let shared = ClipboardManager()

    private init() {}

    /// Paste song from clipboard
    func pasteSongFromClipboard(to modelContext: ModelContext) throws -> PasteResult {
        // Get clipboard content
        guard UIPasteboard.general.hasStrings else {
            throw ClipboardError.emptyClipboard
        }

        guard let clipboardText = UIPasteboard.general.string else {
            throw ClipboardError.invalidContent
        }

        // Trim whitespace
        let content = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !content.isEmpty else {
            throw ClipboardError.emptyClipboard
        }

        // Parse ChordPro content
        let parsed = ChordProParser.parse(content)

        // Extract title with fallback priority:
        // 1. {title:} tag from parsed content
        // 2. First non-empty line
        // 3. "Untitled Song"
        let title: String
        let wasUntitled: Bool

        if let parsedTitle = parsed.title, !parsedTitle.isEmpty {
            title = parsedTitle
            wasUntitled = false
        } else if let firstLine = extractFirstLine(from: content) {
            title = firstLine
            wasUntitled = false
        } else {
            title = "Untitled Song"
            wasUntitled = true
        }

        // Create Song object
        let song = Song(
            title: title,
            artist: parsed.artist,
            content: content,
            contentFormat: .chordPro,
            originalKey: parsed.key
        )

        // Set additional metadata
        song.tempo = parsed.tempo
        song.timeSignature = parsed.timeSignature
        song.capo = parsed.capo
        song.copyright = parsed.copyright
        song.ccliNumber = parsed.ccliNumber
        song.album = parsed.album
        song.year = parsed.year

        // Set import metadata
        song.importSource = "Clipboard"
        song.importedAt = Date()

        // Insert into SwiftData
        modelContext.insert(song)

        do {
            try modelContext.save()
        } catch {
            throw ClipboardError.saveFailed
        }

        // Check for parsing warnings
        let hadWarnings = parsed.sections.isEmpty && !content.isEmpty

        return PasteResult(
            song: song,
            hadParsingWarnings: hadWarnings,
            wasUntitled: wasUntitled
        )
    }

    /// Check if clipboard has text content
    func hasClipboardContent() -> Bool {
        return UIPasteboard.general.hasStrings
    }

    // MARK: - Helper Methods

    /// Extract first non-empty line from content
    private func extractFirstLine(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and ChordPro directives
            if !trimmed.isEmpty && !trimmed.hasPrefix("{") {
                // Limit to 60 characters for title
                let titleLine = String(trimmed.prefix(60))
                return titleLine
            }
        }

        return nil
    }
}
