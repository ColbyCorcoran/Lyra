//
//  GoogleDriveAuthView.swift
//  Lyra
//
//  Google Drive authentication and account management view
//

import SwiftUI

struct GoogleDriveAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var driveManager = GoogleDriveManager.shared

    @State private var isAuthenticating: Bool = false
    @State private var showSignOutConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            if driveManager.isAuthenticated {
                connectedView
            } else {
                notConnectedView
            }
        }
    }

    // MARK: - Not Connected View

    @ViewBuilder
    private var notConnectedView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Google Drive icon
                ZStack {
                    // Multi-color background (Google colors)
                    LinearGradient(
                        colors: [Color.blue, Color.green, Color.yellow, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    Image(systemName: "internaldrive")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .padding(.top, 60)
                .accessibilityHidden(true)

                // Title and description
                VStack(spacing: 16) {
                    Text("Connect to Google Drive")
                        .font(.title)
                        .fontWeight(.bold)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

                    Text("Import your chord charts and song files directly from Google Drive")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }

                // Features list
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "folder",
                        title: "Browse Files",
                        description: "Navigate your Drive folders and files"
                    )

                    FeatureRow(
                        icon: "person.2",
                        title: "Shared Drives",
                        description: "Access shared drives and team folders"
                    )

                    FeatureRow(
                        icon: "doc.on.doc",
                        title: "Import Multiple Files",
                        description: "Select and import many files at once"
                    )

                    FeatureRow(
                        icon: "magnifyingglass",
                        title: "Search",
                        description: "Find files quickly with powerful search"
                    )

                    FeatureRow(
                        icon: "checkmark.shield",
                        title: "Secure",
                        description: "OAuth 2.0 authentication, read-only access"
                    )
                }
                .padding(.horizontal, 24)

                // Connect button
                Button {
                    connectToGoogleDrive()
                } label: {
                    HStack(spacing: 12) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "link")
                                .font(.system(size: 18, weight: .semibold))
                        }

                        Text(isAuthenticating ? "Connecting..." : "Connect to Google Drive")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isAuthenticating ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .accessibilityLabel(isAuthenticating ? "Connecting to Google Drive" : "Connect to Google Drive")

                Spacer()
            }
        }
        .navigationTitle("Google Drive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Connected View

    @ViewBuilder
    private var connectedView: some View {
        List {
            // Account section
            Section {
                if let email = driveManager.userEmail {
                    HStack(spacing: 12) {
                        // Google "G" icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: .black.opacity(0.1), radius: 2)

                            Text("G")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .green, .yellow, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connected")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(email)
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Connected as \(email)")
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Text("Connected to Google Drive")
                            .font(.body)
                    }
                }
            } header: {
                Text("Account")
            }

            // Storage section
            Section {
                if driveManager.totalSpace > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(.blue)

                            Text("Storage")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()

                            Text(driveManager.formatUsage())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Storage bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width * (Double(driveManager.usedSpace) / Double(driveManager.totalSpace)),
                                        height: 8
                                    )
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text(driveManager.formatBytes(driveManager.usedSpace))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(driveManager.formatBytes(driveManager.totalSpace))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Storage: \(driveManager.formatUsage())")
                } else {
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundStyle(.blue)

                        Text("Loading storage info...")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Storage")
            }

            // Actions section
            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Sign Out")
                    }
                }
                .accessibilityLabel("Sign out of Google Drive")
            }
        }
        .navigationTitle("Google Drive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                driveManager.signOut()
            }
        } message: {
            Text("You will need to reconnect to import files from Google Drive.")
        }
        .task {
            await driveManager.fetchQuotaInfo()
        }
    }

    // MARK: - Actions

    private func connectToGoogleDrive() {
        isAuthenticating = true
        HapticManager.shared.selection()

        // Get the presenting view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            isAuthenticating = false
            return
        }

        // Start OAuth flow
        driveManager.authenticate(presentingViewController: rootViewController)

        // Reset state after delay (actual auth happens via callback)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isAuthenticating = false
        }
    }
}

// MARK: - Preview

#Preview("Not Connected") {
    GoogleDriveAuthView()
}

#Preview("Connected") {
    let manager = GoogleDriveManager.shared
    manager.isAuthenticated = true
    manager.userEmail = "user@gmail.com"
    manager.usedSpace = 8_000_000_000
    manager.totalSpace = 15_000_000_000

    return GoogleDriveAuthView()
}
