//
//  QRCodeGenerator.swift
//  Lyra
//
//  Generates QR codes for offline sharing of songs, books, and sets
//

import Foundation
import UIKit
import CoreImage

@MainActor
class QRCodeGenerator {
    static let shared = QRCodeGenerator()
    
    private init() {}
    
    // MARK: - QR Code Generation
    
    /// Generates a QR code image for a song
    func generateQRCode(for song: Song, size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        do {
            let songData = try EncodedSongData(song: song)
            let jsonData = try JSONEncoder().encode(songData)
            
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
            }
            
            return generateQRCodeImage(from: jsonString, size: size)
        } catch {
            print("Failed to generate QR code for song: \(error)")
            return nil
        }
    }
    
    /// Generates a QR code image for a book
    func generateQRCode(for book: Book, songs: [Song], size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        do {
            let bookData = try EncodedBookData(book: book, songs: songs)
            let jsonData = try JSONEncoder().encode(bookData)
            
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
            }
            
            return generateQRCodeImage(from: jsonString, size: size)
        } catch {
            print("Failed to generate QR code for book: \(error)")
            return nil
        }
    }
    
    /// Generates a QR code image for a performance set
    func generateQRCode(for set: PerformanceSet, entries: [SetEntry], size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        do {
            let setData = try EncodedSetData(performanceSet: set, entries: entries)
            let jsonData = try JSONEncoder().encode(setData)
            
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
            }
            
            return generateQRCodeImage(from: jsonString, size: size)
        } catch {
            print("Failed to generate QR code for set: \(error)")
            return nil
        }
    }
    
    // MARK: - QR Code Scanning
    
    /// Decodes song data from a QR code string
    func decodeSongData(from qrString: String) throws -> EncodedSongData {
        guard let data = qrString.data(using: .utf8) else {
            throw QRCodeError.invalidData
        }
        
        return try JSONDecoder().decode(EncodedSongData.self, from: data)
    }
    
    /// Decodes book data from a QR code string
    func decodeBookData(from qrString: String) throws -> EncodedBookData {
        guard let data = qrString.data(using: .utf8) else {
            throw QRCodeError.invalidData
        }
        
        return try JSONDecoder().decode(EncodedBookData.self, from: data)
    }
    
    /// Decodes set data from a QR code string
    func decodeSetData(from qrString: String) throws -> EncodedSetData {
        guard let data = qrString.data(using: .utf8) else {
            throw QRCodeError.invalidData
        }
        
        return try JSONDecoder().decode(EncodedSetData.self, from: data)
    }
    
    // MARK: - Private Helpers
    
    private func generateQRCodeImage(from string: String, size: CGSize) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let ciImage = filter?.outputImage else { return nil }
        
        // Scale the QR code to desired size
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Encoded Data Structures

struct EncodedSongData: Codable {
    let type: String = "song"
    let version: String = "1.0"
    let title: String
    let artist: String?
    let content: String
    let contentFormat: String
    let originalKey: String?
    let tempo: Int?
    let timeSignature: String?
    let capo: Int?
    let notes: String?
    let tags: [String]?
    
    init(song: Song) {
        self.title = song.title
        self.artist = song.artist
        self.content = song.content
        self.contentFormat = song.contentFormat.rawValue
        self.originalKey = song.originalKey
        self.tempo = song.tempo
        self.timeSignature = song.timeSignature
        self.capo = song.capo
        self.notes = song.notes
        self.tags = song.tags
    }
    
    func toSong() -> Song {
        let song = Song(
            title: title,
            artist: artist,
            content: content,
            contentFormat: ContentFormat(rawValue: contentFormat) ?? .chordPro,
            originalKey: originalKey
        )
        song.tempo = tempo
        song.timeSignature = timeSignature
        song.capo = capo
        song.notes = notes
        song.tags = tags
        return song
    }
}

struct EncodedBookData: Codable {
    let type: String = "book"
    let version: String = "1.0"
    let name: String
    let bookDescription: String?
    let songs: [EncodedSongData]
    
    init(book: Book, songs: [Song]) throws {
        self.name = book.name
        self.bookDescription = book.bookDescription
        self.songs = songs.map { EncodedSongData(song: $0) }
    }
}

struct EncodedSetData: Codable {
    let type: String = "set"
    let version: String = "1.0"
    let name: String
    let scheduledDate: Date?
    let notes: String?
    let entries: [EncodedSetEntry]
    
    init(performanceSet: PerformanceSet, entries: [SetEntry]) throws {
        self.name = performanceSet.name
        self.scheduledDate = performanceSet.scheduledDate
        self.notes = performanceSet.notes
        
        self.entries = entries.compactMap { entry in
            guard let song = entry.song else { return nil }
            return EncodedSetEntry(entry: entry, song: song)
        }
    }
    
    struct EncodedSetEntry: Codable {
        let orderIndex: Int
        let song: EncodedSongData
        let keyOverride: String?
        let capoOverride: Int?
        let tempoOverride: Int?
        let notes: String?
        
        init(entry: SetEntry, song: Song) {
            self.orderIndex = entry.orderIndex
            self.song = EncodedSongData(song: song)
            self.keyOverride = entry.keyOverride
            self.capoOverride = entry.capoOverride
            self.tempoOverride = entry.tempoOverride
            self.notes = entry.notes
        }
    }
}

// MARK: - Errors

enum QRCodeError: LocalizedError {
    case invalidData
    case generationFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid QR code data"
        case .generationFailed:
            return "Failed to generate QR code"
        case .decodingFailed:
            return "Failed to decode QR code"
        }
    }
}
