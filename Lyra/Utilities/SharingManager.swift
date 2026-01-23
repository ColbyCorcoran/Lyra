//
//  SharingManager.swift
//  Lyra
//
//  Enhanced sharing capabilities for songs, books, and sets
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class SharingManager {
    static let shared = SharingManager()
    
    private init() {}
    
    // MARK: - Quick Share
    
    /// Creates a share sheet for a song with multiple format options
    func shareSong(
        _ song: Song,
        formats: [ExportManager.ExportFormat] = [.pdf, .chordPro],
        sourceView: UIView? = nil
    ) -> UIActivityViewController {
        var items: [Any] = []
        
        for format in formats {
            do {
                let data = try ExportManager.shared.exportSong(song, format: format)
                let filename = ExportManager.shared.sanitizeFilename(song.title) + "." + format.fileExtension
                
                if let tempURL = saveToTempFile(data: data, filename: filename) {
                    items.append(tempURL)
                }
            } catch {
                print("Failed to export song in \(format.rawValue): \(error)")
            }
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = sourceView
        }
        
        return activityVC
    }
    
    /// Creates a share sheet for a performance set
    func sharePerformanceSet(
        _ set: PerformanceSet,
        format: ExportManager.ExportFormat = .pdf,
        sourceView: UIView? = nil
    ) -> UIActivityViewController {
        var items: [Any] = []
        
        do {
            let data = try ExportManager.shared.exportSet(set, format: format)
            let filename = ExportManager.shared.sanitizeFilename(set.name) + "." + format.fileExtension
            
            if let tempURL = saveToTempFile(data: data, filename: filename) {
                items.append(tempURL)
            }
        } catch {
            print("Failed to export set: \(error)")
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = sourceView
        }
        
        return activityVC
    }
    
    /// Creates a share sheet for a book
    func shareBook(
        _ book: Book,
        format: ExportManager.ExportFormat = .pdf,
        sourceView: UIView? = nil
    ) -> UIActivityViewController {
        var items: [Any] = []
        
        do {
            let data = try ExportManager.shared.exportBook(book, format: format)
            let filename = ExportManager.shared.sanitizeFilename(book.name) + "." + format.fileExtension
            
            if let tempURL = saveToTempFile(data: data, filename: filename) {
                items.append(tempURL)
            }
        } catch {
            print("Failed to export book: \(error)")
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = sourceView
        }
        
        return activityVC
    }
    
    // MARK: - Share with Preset
    
    /// Shares using a predefined preset
    func shareWithPreset(
        _ preset: SharePreset,
        song: Song,
        sourceView: UIView? = nil
    ) -> UIActivityViewController {
        return shareSong(song, formats: preset.formats, sourceView: sourceView)
    }
    
    // MARK: - Helper Methods
    
    private func saveToTempFile(data: Data, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write temp file: \(error)")
            return nil
        }
    }
}

// MARK: - Share Presets

struct SharePreset: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let formats: [ExportManager.ExportFormat]
    let icon: String
    
    init(
        name: String,
        description: String,
        formats: [ExportManager.ExportFormat],
        icon: String = "square.and.arrow.up"
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.formats = formats
        self.icon = icon
    }
    
    // MARK: - Built-in Presets
    
    static let onSongUsers = SharePreset(
        name: "Share for OnSong Users",
        description: "OnSong format for compatibility with OnSong app",
        formats: [.onSong],
        icon: "music.note.list"
    )
    
    static let pdfOnly = SharePreset(
        name: "Share as PDF",
        description: "PDF document for printing or viewing",
        formats: [.pdf],
        icon: "doc.richtext"
    )
    
    static let textOnly = SharePreset(
        name: "Share Minimal (Text Only)",
        description: "Plain text format for maximum compatibility",
        formats: [.plainText],
        icon: "doc.plaintext"
    )
    
    static let allFormats = SharePreset(
        name: "Share All Formats",
        description: "All available export formats",
        formats: ExportManager.ExportFormat.allCases,
        icon: "square.stack.3d.up"
    )
    
    static let chordProAndPDF = SharePreset(
        name: "ChordPro + PDF",
        description: "ChordPro text and formatted PDF",
        formats: [.chordPro, .pdf],
        icon: "doc.on.doc"
    )
    
    static let builtInPresets: [SharePreset] = [
        .onSongUsers,
        .pdfOnly,
        .textOnly,
        .chordProAndPDF,
        .allFormats
    ]
}
