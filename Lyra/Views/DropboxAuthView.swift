//
//  DropboxAuthView.swift
//  Lyra
//
//  Dropbox authentication and account management view
//

import SwiftUI

struct DropboxAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dropboxManager = DropboxManager.shared

    @State private var isAuthenticating: Bool = false
    @State private var showSignOutConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            if dropboxManager.isAuthenticated {
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
                // Icon
                Image(systemName: "cloud")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 60)
                    .accessibilityHidden(true)

                // Title and description
                VStack(spacing: 16) {
                    Text("Connect to Dropbox")
                        .font(.title)
                        .fontWeight(.bold)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

                    Text("Import your chord charts and song files directly from Dropbox")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }

                // Features list
                VStack(alignment: .leading, spacing: 20) {
                    DropboxFeatureRow(
                        icon: "folder",
                        title: "Browse Files",
                        description: "Navigate your Dropbox folders and files"
                    )

                    DropboxFeatureRow(
                        icon: "doc.on.doc",
                        title: "Import Multiple Files",
                        description: "Select and import many files at once"
                    )

                    DropboxFeatureRow(
                        icon: "magnifyingglass",
                        title: "Search",
                        description: "Find files quickly with search"
                    )

                    DropboxFeatureRow(
                        icon: "checkmark.shield",
                        title: "Secure",
                        description: "OAuth 2.0 authentication, no password stored"
                    )
                }
                .padding(.horizontal, 24)

                // Connect button
                Button {
                    connectToDropbox()
                } label: {
                    HStack(spacing: 12) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "link")
                                .font(.system(size: 18, weight: .semibold))
                        }

                        Text(isAuthenticating ? "Connecting..." : "Connect to Dropbox")
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
                .accessibilityLabel(isAuthenticating ? "Connecting to Dropbox" : "Connect to Dropbox")

                Spacer()
            }
        }
        .navigationTitle("Dropbox")
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
                if let email = dropboxManager.userEmail {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)

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

                        Text("Connected to Dropbox")
                            .font(.body)
                    }
                }
            } header: {
                Text("Account")
            }

            // Storage section
            Section {
                if dropboxManager.totalSpace > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(.blue)

                            Text("Storage")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()

                            Text(dropboxManager.formatUsage())
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
                                    .fill(Color.blue)
                                    .frame(
                                        width: geometry.size.width * (Double(dropboxManager.usedSpace) / Double(dropboxManager.totalSpace)),
                                        height: 8
                                    )
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text(dropboxManager.formatBytes(dropboxManager.usedSpace))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(dropboxManager.formatBytes(dropboxManager.totalSpace))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Storage: \(dropboxManager.formatUsage())")
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
                .accessibilityLabel("Sign out of Dropbox")
            }
        }
        .navigationTitle("Dropbox")
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
                dropboxManager.signOut()
            }
        } message: {
            Text("You will need to reconnect to import files from Dropbox.")
        }
        .task {
            await dropboxManager.fetchAccountInfo()
        }
    }

    // MARK: - Actions

    private func connectToDropbox() {
        isAuthenticating = true
        HapticManager.shared.selection()

        // Start OAuth flow
        dropboxManager.authenticate()

        // Note: The actual authentication happens via OAuth callback
        // The isAuthenticating state will be reset when the callback completes
        // For now, we'll reset it after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isAuthenticating = false
        }
    }
}

// MARK: - Feature Row Component

private struct DropboxFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}

// MARK: - Preview

#Preview("Not Connected") {
    DropboxAuthView()
}

#Preview("Connected") {
    let manager = DropboxManager.shared
    manager.isAuthenticated = true
    manager.userEmail = "user@example.com"
    manager.usedSpace = 5_000_000_000
    manager.totalSpace = 15_000_000_000

    return DropboxAuthView()
}
