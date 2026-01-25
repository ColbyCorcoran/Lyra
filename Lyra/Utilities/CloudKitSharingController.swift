//
//  CloudKitSharingController.swift
//  Lyra
//
//  SwiftUI wrapper for CloudKit's native sharing UI (UICloudSharingController)
//

import SwiftUI
import CloudKit
import UIKit

/// SwiftUI wrapper for UICloudSharingController
struct CloudKitSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let library: SharedLibrary

    var onDismiss: (() -> Void)?
    var onError: ((Error) -> Void)?

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(
            share: share,
            container: container
        )

        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowPublic, .allowPrivate, .allowReadWrite, .allowReadOnly]

        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            library: library,
            onDismiss: onDismiss,
            onError: onError
        )
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let library: SharedLibrary
        let onDismiss: (() -> Void)?
        let onError: ((Error) -> Void)?

        init(
            library: SharedLibrary,
            onDismiss: (() -> Void)?,
            onError: ((Error) -> Void)?
        ) {
            self.library = library
            self.onDismiss = onDismiss
            self.onError = onError
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("❌ Failed to save share: \(error)")
            onError?(error)
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            library.name
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // Could return library icon as image data
            nil
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("✅ Share saved successfully")
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("🛑 Stopped sharing")
            library.isShared = false
            library.shareRecordName = nil
            library.shareURL = nil
        }
    }
}

/// Helper to present CloudKit sharing UI
@MainActor
class CloudKitSharingHelper {

    /// Presents native CloudKit sharing UI
    static func presentSharingController(
        for library: SharedLibrary,
        share: CKShare,
        from viewController: UIViewController
    ) {
        let container = CKContainer.default()
        let sharingController = UICloudSharingController(share: share, container: container)

        sharingController.availablePermissions = [
            .allowPublic,
            .allowPrivate,
            .allowReadWrite,
            .allowReadOnly
        ]

        sharingController.delegate = SharingControllerDelegate.shared

        viewController.present(sharingController, animated: true)
    }

    /// Generates a share URL for a library
    static func generateShareURL(for library: SharedLibrary) -> URL? {
        guard let shareURL = library.shareURL else { return nil }
        return URL(string: shareURL)
    }

    /// Parses share metadata from URL
    static func parseShareMetadata(from url: URL) async throws -> CKShare.Metadata {
        let container = CKContainer.default()
        return try await container.shareMetadata(for: url)
    }
}

/// Singleton delegate for sharing controller
class SharingControllerDelegate: NSObject, UICloudSharingControllerDelegate {
    static let shared = SharingControllerDelegate()

    private override init() {
        super.init()
    }

    func cloudSharingController(
        _ csc: UICloudSharingController,
        failedToSaveShareWithError error: Error
    ) {
        print("❌ Failed to save share: \(error)")

        // Show error to user
        NotificationCenter.default.post(
            name: .sharingError,
            object: nil,
            userInfo: ["error": error]
        )
    }

    func itemTitle(for csc: UICloudSharingController) -> String? {
        "Shared Library"
    }

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("✅ Share saved")

        NotificationCenter.default.post(
            name: .sharingSaved,
            object: nil
        )
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("🛑 Stopped sharing")

        NotificationCenter.default.post(
            name: .sharingStopped,
            object: nil
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let sharingError = Notification.Name("cloudKitSharingError")
    static let sharingSaved = Notification.Name("cloudKitSharingSaved")
    static let sharingStopped = Notification.Name("cloudKitSharingStopped")
}

// MARK: - Share Link Generator

struct ShareLinkGenerator {

    /// Generates multiple sharing options for a library
    static func generateSharingOptions(for library: SharedLibrary) -> [SharingOption] {
        guard let shareURL = library.shareURL else { return [] }

        var options: [SharingOption] = []

        // Direct link
        options.append(SharingOption(
            type: .link,
            title: "Share Link",
            icon: "link",
            content: shareURL
        ))

        // Email
        let emailSubject = "Join my \(library.name) library on Lyra"
        let emailBody = """
        I'd like to invite you to collaborate on my \(library.name) library in Lyra.

        Tap this link to join:
        \(shareURL)

        About the library:
        \(library.libraryDescription ?? "A collaborative music library")
        """

        options.append(SharingOption(
            type: .email,
            title: "Send via Email",
            icon: "envelope",
            content: emailBody,
            metadata: ["subject": emailSubject]
        ))

        // Message
        let messageText = "Join my \(library.name) library on Lyra: \(shareURL)"

        options.append(SharingOption(
            type: .message,
            title: "Send via Message",
            icon: "message",
            content: messageText
        ))

        // QR Code
        if library.qrCodeData != nil {
            options.append(SharingOption(
                type: .qrCode,
                title: "Show QR Code",
                icon: "qrcode",
                content: shareURL
            ))
        }

        return options
    }
}

struct SharingOption: Identifiable {
    let id = UUID()
    let type: SharingType
    let title: String
    let icon: String
    let content: String
    var metadata: [String: String] = [:]

    enum SharingType {
        case link
        case email
        case message
        case qrCode
        case airdrop
    }
}
