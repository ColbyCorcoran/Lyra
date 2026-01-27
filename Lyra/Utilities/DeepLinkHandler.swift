//
//  DeepLinkHandler.swift
//  Lyra
//
//  Handles deep links and custom URL schemes for Lyra
//

import Foundation
import SwiftUI

@MainActor
@Observable
class DeepLinkHandler {
    static let shared = DeepLinkHandler()
    
    // MARK: - Deep Link Navigation
    
    var pendingDeepLink: DeepLink?
    
    private init() {}
    
    // MARK: - URL Scheme: lyra://
    
    /// Handles incoming URL from deep link
    func handle(url: URL) {
        guard url.scheme == "lyra" else { return }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = components?.host
        let path = components?.path
        let queryItems = components?.queryItems
        
        switch host {
        case "song":
            handleSongDeepLink(path: path, queryItems: queryItems)
            
        case "set":
            handleSetDeepLink(path: path, queryItems: queryItems)
            
        case "library":
            handleLibraryDeepLink(path: path, queryItems: queryItems)
            
        case "book":
            handleBookDeepLink(path: path, queryItems: queryItems)
            
        case "import":
            handleImportDeepLink(queryItems: queryItems)
            
        default:
            print("Unknown deep link host: \(host ?? "nil")")
        }
    }
    
    // MARK: - Deep Link Handlers
    
    private func handleSongDeepLink(path: String?, queryItems: [URLQueryItem]?) {
        // lyra://song/[song-id]
        // lyra://song?id=[song-id]
        
        var songID: UUID?
        
        if let path = path, !path.isEmpty, path != "/" {
            let idString = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            songID = UUID(uuidString: idString)
        } else if let queryItems = queryItems,
                  let idValue = queryItems.first(where: { $0.name == "id" })?.value {
            songID = UUID(uuidString: idValue)
        }
        
        if let songID = songID {
            pendingDeepLink = .song(id: songID)
            postDeepLinkNotification(.song(id: songID))
        }
    }
    
    private func handleSetDeepLink(path: String?, queryItems: [URLQueryItem]?) {
        // lyra://set/[set-id]
        
        var setID: UUID?
        
        if let path = path, !path.isEmpty, path != "/" {
            let idString = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            setID = UUID(uuidString: idString)
        } else if let queryItems = queryItems,
                  let idValue = queryItems.first(where: { $0.name == "id" })?.value {
            setID = UUID(uuidString: idValue)
        }
        
        if let setID = setID {
            pendingDeepLink = .performanceSet(id: setID)
            postDeepLinkNotification(.performanceSet(id: setID))
        }
    }
    
    private func handleLibraryDeepLink(path: String?, queryItems: [URLQueryItem]?) {
        // lyra://library/shared/[share-id]
        // lyra://library?type=shared&id=[share-id]
        
        if let path = path, path.hasPrefix("/shared/") {
            let shareID = path.replacingOccurrences(of: "/shared/", with: "")
            if let uuid = UUID(uuidString: shareID) {
                pendingDeepLink = .sharedLibrary(id: uuid)
                postDeepLinkNotification(.sharedLibrary(id: uuid))
            }
        } else if let queryItems = queryItems {
            let type = queryItems.first(where: { $0.name == "type" })?.value
            let idValue = queryItems.first(where: { $0.name == "id" })?.value
            
            if type == "shared", let idValue = idValue, let uuid = UUID(uuidString: idValue) {
                pendingDeepLink = .sharedLibrary(id: uuid)
                postDeepLinkNotification(.sharedLibrary(id: uuid))
            }
        }
    }
    
    private func handleBookDeepLink(path: String?, queryItems: [URLQueryItem]?) {
        // lyra://book/[book-id]
        
        var bookID: UUID?
        
        if let path = path, !path.isEmpty, path != "/" {
            let idString = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            bookID = UUID(uuidString: idString)
        } else if let queryItems = queryItems,
                  let idValue = queryItems.first(where: { $0.name == "id" })?.value {
            bookID = UUID(uuidString: idValue)
        }
        
        if let bookID = bookID {
            pendingDeepLink = .book(id: bookID)
            postDeepLinkNotification(.book(id: bookID))
        }
    }
    
    private func handleImportDeepLink(queryItems: [URLQueryItem]?) {
        // lyra://import?data=[base64-encoded-data]
        
        guard let queryItems = queryItems,
              let dataValue = queryItems.first(where: { $0.name == "data" })?.value,
              let data = Data(base64Encoded: dataValue) else {
            return
        }
        
        pendingDeepLink = .importData(data: data)
        postDeepLinkNotification(.importData(data: data))
    }
    
    // MARK: - Link Generation
    
    /// Generates a deep link URL for a song
    func generateDeepLink(for song: Song) -> URL? {
        var components = URLComponents()
        components.scheme = "lyra"
        components.host = "song"
        components.path = "/\(song.id.uuidString)"
        return components.url
    }
    
    /// Generates a deep link URL for a performance set
    func generateDeepLink(for set: PerformanceSet) -> URL? {
        var components = URLComponents()
        components.scheme = "lyra"
        components.host = "set"
        components.path = "/\(set.id.uuidString)"
        return components.url
    }
    
    /// Generates a deep link URL for a book
    func generateDeepLink(for book: Book) -> URL? {
        var components = URLComponents()
        components.scheme = "lyra"
        components.host = "book"
        components.path = "/\(book.id.uuidString)"
        return components.url
    }

    /// Generates an import deep link with encoded data
    func generateImportLink(data: Data) -> URL? {
        var components = URLComponents()
        components.scheme = "lyra"
        components.host = "import"
        components.queryItems = [
            URLQueryItem(name: "data", value: data.base64EncodedString())
        ]
        return components.url
    }
    
    // MARK: - Notifications
    
    private func postDeepLinkNotification(_ deepLink: DeepLink) {
        NotificationCenter.default.post(
            name: .deepLinkReceived,
            object: nil,
            userInfo: ["deepLink": deepLink]
        )
    }
    
    /// Clears the pending deep link
    func clearPendingDeepLink() {
        pendingDeepLink = nil
    }
}

// MARK: - Deep Link Types

enum DeepLink: Equatable {
    case song(id: UUID)
    case performanceSet(id: UUID)
    case book(id: UUID)
    case sharedLibrary(id: UUID)
    case importData(data: Data)
    
    var description: String {
        switch self {
        case .song(let id):
            return "Song: \(id)"
        case .performanceSet(let id):
            return "Performance Set: \(id)"
        case .book(let id):
            return "Book: \(id)"
        case .sharedLibrary(let id):
            return "Shared Library: \(id)"
        case .importData:
            return "Import Data"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
}

// MARK: - Universal Links Support

extension DeepLinkHandler {
    /// Handles universal links (https://lyra.app/...)
    func handleUniversalLink(url: URL) {
        // Universal links would be in the format: https://lyra.app/song/[id]
        // Convert to deep link format
        
        guard url.host == "lyra.app" || url.host == "www.lyra.app" else { return }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard !pathComponents.isEmpty else { return }
        
        let type = pathComponents[0]
        let id = pathComponents.count > 1 ? pathComponents[1] : nil
        
        var deepLinkURL: URL?
        
        switch type {
        case "song":
            if let id = id {
                var components = URLComponents()
                components.scheme = "lyra"
                components.host = "song"
                components.path = "/\(id)"
                deepLinkURL = components.url
            }
            
        case "set":
            if let id = id {
                var components = URLComponents()
                components.scheme = "lyra"
                components.host = "set"
                components.path = "/\(id)"
                deepLinkURL = components.url
            }
            
        case "book":
            if let id = id {
                var components = URLComponents()
                components.scheme = "lyra"
                components.host = "book"
                components.path = "/\(id)"
                deepLinkURL = components.url
            }
            
        case "library":
            if pathComponents.count > 2 && pathComponents[1] == "shared" {
                var components = URLComponents()
                components.scheme = "lyra"
                components.host = "library"
                components.path = "/shared/\(pathComponents[2])"
                deepLinkURL = components.url
            }
            
        default:
            break
        }
        
        if let deepLinkURL = deepLinkURL {
            handle(url: deepLinkURL)
        }
    }
}
