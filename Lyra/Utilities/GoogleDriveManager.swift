//
//  GoogleDriveManager.swift
//  Lyra
//
//  Manages Google Drive authentication and file operations
//
//  SETUP REQUIRED:
//  1. Add GoogleSignIn via SPM: https://github.com/google/GoogleSignIn-iOS
//  2. Add GoogleAPIClientForREST via SPM: https://github.com/google/google-api-objectivec-client-for-rest
//  3. Add to Info.plist:
//     <key>CFBundleURLTypes</key>
//     <array>
//       <dict>
//         <key>CFBundleURLSchemes</key>
//         <array>
//           <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
//         </array>
//       </dict>
//     </array>
//  4. Configure GIDSignIn.sharedInstance.clientID = "YOUR_CLIENT_ID"
//

import Foundation
import Security

// NOTE: This code assumes GoogleSignIn and GoogleAPIClientForREST are installed
// Uncomment the following lines after adding the packages:
// import GoogleSignIn
// import GoogleAPIClientForREST

enum GoogleDriveError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case downloadFailed
    case listFailed
    case invalidFileID
    case quotaExceeded
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not connected to Google Drive"
        case .authenticationFailed:
            return "Google Drive authentication failed"
        case .downloadFailed:
            return "Failed to download file"
        case .listFailed:
            return "Failed to list files"
        case .invalidFileID:
            return "Invalid file ID"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Please connect your Google Drive account in Settings."
        case .authenticationFailed:
            return "Try signing in again."
        case .downloadFailed:
            return "Check your internet connection and try again."
        case .listFailed:
            return "Check your internet connection and try again."
        case .invalidFileID:
            return "The file may have been moved or deleted."
        case .quotaExceeded:
            return "You need to free up space in your Google Drive."
        case .networkError:
            return "Check your internet connection and try again."
        }
    }
}

struct GoogleDriveFile: Identifiable, Hashable {
    let id: String
    let name: String
    let mimeType: String
    let size: Int64?
    let modifiedTime: Date?
    let webViewLink: String?

    var isFolder: Bool {
        mimeType == "application/vnd.google-apps.folder"
    }

    var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    var isSupported: Bool {
        if isFolder { return true }

        // Check MIME types
        let supportedMimeTypes = [
            "text/plain",
            "application/pdf",
            "application/octet-stream"
        ]

        if supportedMimeTypes.contains(mimeType) {
            return true
        }

        // Check file extensions
        let supportedExtensions = ["txt", "cho", "chordpro", "chopro", "crd", "pdf", "onsong"]
        return supportedExtensions.contains(fileExtension)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GoogleDriveFile, rhs: GoogleDriveFile) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class GoogleDriveManager: ObservableObject {
    static let shared = GoogleDriveManager()

    @Published var isAuthenticated: Bool = false
    @Published var userEmail: String?
    @Published var usedSpace: Int64 = 0
    @Published var totalSpace: Int64 = 0

    private var driveService: Any? // GTLRDriveService in production

    private init() {
        // Check if we have stored credentials
        checkAuthentication()
    }

    // MARK: - Authentication

    /// Check if user is already authenticated
    func checkAuthentication() {
        // TODO: Uncomment after adding GoogleSignIn
        /*
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                Task { @MainActor in
                    if let user = user, error == nil {
                        self.handleSignIn(user: user)
                    } else {
                        self.isAuthenticated = false
                    }
                }
            }
        }
        */
    }

    /// Start OAuth authentication flow
    func authenticate(presentingViewController: UIViewController) {
        // TODO: Uncomment after adding GoogleSignIn
        /*
        let scopes = [
            "https://www.googleapis.com/auth/drive.readonly",
            "https://www.googleapis.com/auth/drive.file"
        ]

        let signInConfig = GIDConfiguration(clientID: GIDSignIn.sharedInstance.clientID!)

        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController,
            hint: nil,
            additionalScopes: scopes
        ) { signInResult, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ Google Sign-In error: \(error.localizedDescription)")
                    self.isAuthenticated = false
                    return
                }

                guard let user = signInResult?.user else {
                    self.isAuthenticated = false
                    return
                }

                self.handleSignIn(user: user)
            }
        }
        */
    }

    /// Handle successful sign-in
    private func handleSignIn(user: Any) {
        // TODO: Uncomment after adding GoogleSignIn
        /*
        guard let gidUser = user as? GIDGoogleUser else { return }

        self.isAuthenticated = true
        self.userEmail = gidUser.profile?.email

        // Initialize Drive service
        let service = GTLRDriveService()
        service.authorizer = gidUser.fetcherAuthorizer
        self.driveService = service

        // Fetch quota information
        Task {
            await self.fetchQuotaInfo()
        }
        */
    }

    /// Handle OAuth callback
    func handleAuthCallback(url: URL) -> Bool {
        // TODO: Uncomment after adding GoogleSignIn
        /*
        return GIDSignIn.sharedInstance.handle(url)
        */
        return false
    }

    /// Sign out and remove credentials
    func signOut() {
        // TODO: Uncomment after adding GoogleSignIn
        /*
        GIDSignIn.sharedInstance.signOut()
        */

        isAuthenticated = false
        userEmail = nil
        usedSpace = 0
        totalSpace = 0
        driveService = nil
    }

    /// Fetch quota information
    func fetchQuotaInfo() async {
        // TODO: Uncomment after adding GoogleAPIClientForREST
        /*
        guard let service = driveService as? GTLRDriveService else { return }

        let query = GTLRDriveQuery_AboutGet.query()
        query.fields = "storageQuota"

        do {
            let about = try await withCheckedThrowingContinuation { continuation in
                service.executeQuery(query) { ticket, about, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let about = about as? GTLRDrive_About {
                        continuation.resume(returning: about)
                    }
                }
            }

            await MainActor.run {
                if let quota = about.storageQuota {
                    self.usedSpace = quota.usage?.int64Value ?? 0
                    self.totalSpace = quota.limit?.int64Value ?? 0
                }
            }
        } catch {
            print("❌ Error fetching quota: \(error)")
        }
        */
    }

    // MARK: - File Operations

    /// List files in a folder
    func listFiles(in folderId: String? = nil) async throws -> [GoogleDriveFile] {
        guard isAuthenticated else {
            throw GoogleDriveError.notAuthenticated
        }

        // TODO: Uncomment after adding GoogleAPIClientForREST
        /*
        guard let service = driveService as? GTLRDriveService else {
            throw GoogleDriveError.notAuthenticated
        }

        let query = GTLRDriveQuery_FilesList.query()

        // Build query string
        var queryString = "trashed = false"
        if let folderId = folderId {
            queryString += " and '\(folderId)' in parents"
        } else {
            queryString += " and 'root' in parents"
        }

        query.q = queryString
        query.fields = "files(id,name,mimeType,size,modifiedTime,webViewLink)"
        query.pageSize = 100
        query.orderBy = "folder,name"

        return try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { ticket, fileList, error in
                if let error = error {
                    continuation.resume(throwing: GoogleDriveError.networkError(error))
                    return
                }

                guard let list = fileList as? GTLRDrive_FileList,
                      let files = list.files else {
                    continuation.resume(returning: [])
                    return
                }

                let driveFiles = files.compactMap { file -> GoogleDriveFile? in
                    guard let id = file.identifier,
                          let name = file.name,
                          let mimeType = file.mimeType else {
                        return nil
                    }

                    return GoogleDriveFile(
                        id: id,
                        name: name,
                        mimeType: mimeType,
                        size: file.size?.int64Value,
                        modifiedTime: file.modifiedTime?.date,
                        webViewLink: file.webViewLink
                    )
                }

                continuation.resume(returning: driveFiles)
            }
        }
        */

        // Mock data for development
        return []
    }

    /// Download a file
    func downloadFile(
        fileId: String,
        progress: @escaping (Double) -> Void
    ) async throws -> Data {
        guard isAuthenticated else {
            throw GoogleDriveError.notAuthenticated
        }

        // TODO: Uncomment after adding GoogleAPIClientForREST
        /*
        guard let service = driveService as? GTLRDriveService else {
            throw GoogleDriveError.notAuthenticated
        }

        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileId)

        return try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { ticket, file, error in
                if let error = error {
                    continuation.resume(throwing: GoogleDriveError.networkError(error))
                    return
                }

                guard let data = (file as? GTLRDataObject)?.data else {
                    continuation.resume(throwing: GoogleDriveError.downloadFailed)
                    return
                }

                continuation.resume(returning: data)
            }
        }
        */

        throw GoogleDriveError.downloadFailed
    }

    /// Search files in Google Drive
    func searchFiles(query searchQuery: String) async throws -> [GoogleDriveFile] {
        guard isAuthenticated else {
            throw GoogleDriveError.notAuthenticated
        }

        // TODO: Uncomment after adding GoogleAPIClientForREST
        /*
        guard let service = driveService as? GTLRDriveService else {
            throw GoogleDriveError.notAuthenticated
        }

        let query = GTLRDriveQuery_FilesList.query()
        query.q = "name contains '\(searchQuery)' and trashed = false"
        query.fields = "files(id,name,mimeType,size,modifiedTime,webViewLink)"
        query.pageSize = 100

        return try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { ticket, fileList, error in
                if let error = error {
                    continuation.resume(throwing: GoogleDriveError.networkError(error))
                    return
                }

                guard let list = fileList as? GTLRDrive_FileList,
                      let files = list.files else {
                    continuation.resume(returning: [])
                    return
                }

                let driveFiles = files.compactMap { file -> GoogleDriveFile? in
                    guard let id = file.identifier,
                          let name = file.name,
                          let mimeType = file.mimeType else {
                        return nil
                    }

                    return GoogleDriveFile(
                        id: id,
                        name: name,
                        mimeType: mimeType,
                        size: file.size?.int64Value,
                        modifiedTime: file.modifiedTime?.date,
                        webViewLink: file.webViewLink
                    )
                }

                continuation.resume(returning: driveFiles)
            }
        }
        */

        return []
    }

    /// List shared drives
    func listSharedDrives() async throws -> [(id: String, name: String)] {
        guard isAuthenticated else {
            throw GoogleDriveError.notAuthenticated
        }

        // TODO: Uncomment after adding GoogleAPIClientForREST
        /*
        guard let service = driveService as? GTLRDriveService else {
            throw GoogleDriveError.notAuthenticated
        }

        let query = GTLRDriveQuery_DrivesList.query()
        query.fields = "drives(id,name)"

        return try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { ticket, driveList, error in
                if let error = error {
                    continuation.resume(throwing: GoogleDriveError.networkError(error))
                    return
                }

                guard let list = driveList as? GTLRDrive_DriveList,
                      let drives = list.drives else {
                    continuation.resume(returning: [])
                    return
                }

                let sharedDrives = drives.compactMap { drive -> (id: String, name: String)? in
                    guard let id = drive.identifier,
                          let name = drive.name else {
                        return nil
                    }
                    return (id: id, name: name)
                }

                continuation.resume(returning: sharedDrives)
            }
        }
        */

        return []
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

    func getIconName(for file: GoogleDriveFile) -> String {
        if file.isFolder {
            return "folder.fill"
        }

        switch file.fileExtension {
        case "pdf":
            return "doc.fill"
        case "txt", "cho", "chordpro", "chopro", "crd":
            return "doc.text.fill"
        case "onsong":
            return "music.note"
        default:
            return "doc.fill"
        }
    }

    func getIconColor(for file: GoogleDriveFile) -> String {
        if file.isFolder {
            return "blue"
        }

        switch file.fileExtension {
        case "pdf":
            return "red"
        case "txt", "cho", "chordpro", "chopro", "crd":
            return "blue"
        case "onsong":
            return "purple"
        default:
            return "gray"
        }
    }
}
