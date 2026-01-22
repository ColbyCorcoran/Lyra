//
//  DropboxManager.swift
//  Lyra
//
//  Manages Dropbox authentication and file operations
//
//  SETUP REQUIRED:
//  1. Add SwiftyDropbox via SPM: https://github.com/dropbox/SwiftyDropbox
//  2. Add to Info.plist:
//     <key>CFBundleURLTypes</key>
//     <array>
//       <dict>
//         <key>CFBundleURLSchemes</key>
//         <array>
//           <string>db-YOUR_APP_KEY</string>
//         </array>
//         <key>CFBundleURLName</key>
//         <string></string>
//       </dict>
//     </array>
//  3. Add to Info.plist:
//     <key>LSApplicationQueriesSchemes</key>
//     <array>
//       <string>dbapi-2</string>
//       <string>dbapi-8-emm</string>
//     </array>
//  4. Initialize in App: DropboxClientsManager.setupWithAppKey("YOUR_APP_KEY")
//

import Foundation
import Security
import Combine

// NOTE: This code assumes SwiftyDropbox is installed
// Uncomment the following line after adding the package:
// import SwiftyDropbox

enum DropboxError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case downloadFailed
    case listFolderFailed
    case invalidPath
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not connected to Dropbox"
        case .authenticationFailed:
            return "Dropbox authentication failed"
        case .downloadFailed:
            return "Failed to download file"
        case .listFolderFailed:
            return "Failed to list folder contents"
        case .invalidPath:
            return "Invalid Dropbox path"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Please connect your Dropbox account in Settings."
        case .authenticationFailed:
            return "Try signing in again."
        case .downloadFailed:
            return "Check your internet connection and try again."
        case .listFolderFailed:
            return "Check your internet connection and try again."
        case .invalidPath:
            return "The file or folder may have been moved or deleted."
        case .networkError:
            return "Check your internet connection and try again."
        }
    }
}

struct DropboxFile: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let isFolder: Bool
    let size: Int64?
    let modifiedDate: Date?

    var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    var isSupported: Bool {
        ["txt", "cho", "chordpro", "chopro", "crd", "pdf", "onsong"].contains(fileExtension)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: DropboxFile, rhs: DropboxFile) -> Bool {
        lhs.path == rhs.path
    }
}

@MainActor
class DropboxManager: ObservableObject {
    static let shared = DropboxManager()

    @Published var isAuthenticated: Bool = false
    @Published var userEmail: String?
    @Published var usedSpace: Int64 = 0
    @Published var totalSpace: Int64 = 0

    private let keychainService = "com.lyra.dropbox"
    private let keychainAccount = "dropbox-token"

    private init() {
        // Check if we have a stored token
        if loadToken() != nil {
            isAuthenticated = true
            // In production, you would validate the token here
            // validateToken(token)
        }
    }

    // MARK: - Authentication

    /// Start OAuth authentication flow
    func authenticate() {
        // TODO: Uncomment after adding SwiftyDropbox
        /*
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            let scopeRequest = ScopeRequest(
                scopeType: .user,
                scopes: ["files.metadata.read", "files.content.read"],
                includeGrantedScopes: false
            )
            DropboxClientsManager.authorizeFromControllerV2(
                UIApplication.shared,
                controller: viewController,
                loadingStatusDelegate: nil,
                openURL: { (url: URL) -> Void in
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                },
                scopeRequest: scopeRequest
            )
        }
        */
    }

    /// Handle OAuth callback
    func handleAuthCallback(url: URL) -> Bool {
        // TODO: Uncomment after adding SwiftyDropbox
        /*
        let oauthCompletion: DropboxOAuthCompletion = { result in
            Task { @MainActor in
                switch result {
                case .success(let token):
                    self.saveToken(token.accessToken)
                    self.isAuthenticated = true
                    await self.fetchAccountInfo()
                case .error(let error, let description):
                    print("❌ Dropbox auth error: \(error) - \(description ?? "")")
                    self.isAuthenticated = false
                case .cancel:
                    print("ℹ️ Dropbox auth cancelled")
                    self.isAuthenticated = false
                }
            }
        }

        return DropboxClientsManager.handleRedirectURL(url, completion: oauthCompletion)
        */

        return false
    }

    /// Sign out and remove token
    func signOut() {
        // TODO: Uncomment after adding SwiftyDropbox
        // DropboxClientsManager.unlinkClients()

        deleteToken()
        isAuthenticated = false
        userEmail = nil
        usedSpace = 0
        totalSpace = 0
    }

    /// Fetch account information
    func fetchAccountInfo() async {
        // TODO: Uncomment after adding SwiftyDropbox
        /*
        guard let client = DropboxClientsManager.authorizedClient else { return }

        do {
            let account = try await withCheckedThrowingContinuation { continuation in
                client.users.getCurrentAccount().response { response, error in
                    if let account = response {
                        continuation.resume(returning: account)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    }
                }
            }

            await MainActor.run {
                self.userEmail = account.email
            }

            // Get space usage
            let spaceUsage = try await withCheckedThrowingContinuation { continuation in
                client.users.getSpaceUsage().response { response, error in
                    if let usage = response {
                        continuation.resume(returning: usage)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    }
                }
            }

            await MainActor.run {
                self.usedSpace = Int64(spaceUsage.used)
                self.totalSpace = Int64(spaceUsage.allocation.getAllocated?.allocated ?? 0)
            }
        } catch {
            print("❌ Error fetching account info: \(error)")
        }
        */
    }

    // MARK: - File Operations

    /// List files in a folder
    func listFolder(path: String = "") async throws -> [DropboxFile] {
        guard isAuthenticated else {
            throw DropboxError.notAuthenticated
        }

        // TODO: Uncomment after adding SwiftyDropbox
        /*
        guard let client = DropboxClientsManager.authorizedClient else {
            throw DropboxError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            client.files.listFolder(path: path.isEmpty ? "" : path)
                .response { response, error in
                    if let result = response {
                        let files = result.entries.compactMap { entry -> DropboxFile? in
                            switch entry {
                            case let folder as Files.FolderMetadata:
                                return DropboxFile(
                                    id: folder.id,
                                    name: folder.name,
                                    path: folder.pathDisplay ?? "",
                                    isFolder: true,
                                    size: nil,
                                    modifiedDate: nil
                                )
                            case let file as Files.FileMetadata:
                                return DropboxFile(
                                    id: file.id,
                                    name: file.name,
                                    path: file.pathDisplay ?? "",
                                    isFolder: false,
                                    size: Int64(file.size),
                                    modifiedDate: file.clientModified
                                )
                            default:
                                return nil
                            }
                        }
                        continuation.resume(returning: files)
                    } else if let error = error {
                        continuation.resume(throwing: DropboxError.networkError(error as Error))
                    }
                }
        }
        */

        // Mock data for development without SDK
        return []
    }

    /// Download a file
    func downloadFile(
        path: String,
        progress: @escaping (Double) -> Void
    ) async throws -> Data {
        guard isAuthenticated else {
            throw DropboxError.notAuthenticated
        }

        // TODO: Uncomment after adding SwiftyDropbox
        /*
        guard let client = DropboxClientsManager.authorizedClient else {
            throw DropboxError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            client.files.download(path: path)
                .progress { progressData in
                    let progressValue = Double(progressData.completedUnitCount) / Double(progressData.totalUnitCount)
                    Task { @MainActor in
                        progress(progressValue)
                    }
                }
                .response { response, error in
                    if let (metadata, data) = response {
                        continuation.resume(returning: data)
                    } else if let error = error {
                        continuation.resume(throwing: DropboxError.networkError(error as Error))
                    }
                }
        }
        */

        throw DropboxError.downloadFailed
    }

    /// Search files in Dropbox
    func searchFiles(query: String, path: String = "") async throws -> [DropboxFile] {
        guard isAuthenticated else {
            throw DropboxError.notAuthenticated
        }

        // TODO: Uncomment after adding SwiftyDropbox
        /*
        guard let client = DropboxClientsManager.authorizedClient else {
            throw DropboxError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            let options = Files.SearchOptions(
                path: path.isEmpty ? nil : path,
                maxResults: 100,
                fileStatus: .active,
                filenameOnly: false
            )

            client.files.searchV2(query: query, options: options)
                .response { response, error in
                    if let result = response {
                        let files = result.matches.compactMap { match -> DropboxFile? in
                            switch match.metadata {
                            case .metadata(let metadata):
                                switch metadata {
                                case let file as Files.FileMetadata:
                                    return DropboxFile(
                                        id: file.id,
                                        name: file.name,
                                        path: file.pathDisplay ?? "",
                                        isFolder: false,
                                        size: Int64(file.size),
                                        modifiedDate: file.clientModified
                                    )
                                case let folder as Files.FolderMetadata:
                                    return DropboxFile(
                                        id: folder.id,
                                        name: folder.name,
                                        path: folder.pathDisplay ?? "",
                                        isFolder: true,
                                        size: nil,
                                        modifiedDate: nil
                                    )
                                default:
                                    return nil
                                }
                            default:
                                return nil
                            }
                        }
                        continuation.resume(returning: files)
                    } else if let error = error {
                        continuation.resume(throwing: DropboxError.networkError(error as Error))
                    }
                }
        }
        */

        return []
    }

    // MARK: - Keychain Management

    private func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("❌ Error saving token to keychain: \(status)")
        }
    }

    private func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Helpers

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func formatUsage() -> String {
        guard totalSpace > 0 else { return "Unknown" }
        let usedGB = Double(usedSpace) / 1_000_000_000
        let totalGB = Double(totalSpace) / 1_000_000_000
        return String(format: "%.1f GB of %.1f GB used", usedGB, totalGB)
    }
}
