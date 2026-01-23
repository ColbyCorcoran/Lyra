//
//  OrganizationSettingsView.swift
//  Lyra
//
//  Organization settings and configuration
//

import SwiftUI
import SwiftData

struct OrganizationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let organization: Organization

    @StateObject private var orgManager = OrganizationManager.shared

    @State private var settings: TeamSettings
    @State private var hasChanges = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Mock current user
    private let currentUserRecordID = "user_current"

    init(organization: Organization) {
        self.organization = organization
        _settings = State(initialValue: organization.settings)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Default Permissions
                Section("Default Permissions") {
                    Picker("Default Library Permission", selection: $settings.defaultLibraryPermission) {
                        Text("Viewer").tag("viewer")
                        Text("Editor").tag("editor")
                        Text("Admin").tag("admin")
                    }
                    .onChange(of: settings.defaultLibraryPermission) { _, _ in hasChanges = true }

                    Toggle("Require Member Approval", isOn: $settings.requireMemberApproval)
                        .onChange(of: settings.requireMemberApproval) { _, _ in hasChanges = true }

                    Toggle("Allow Member Library Creation", isOn: $settings.allowMemberLibraryCreation)
                        .onChange(of: settings.allowMemberLibraryCreation) { _, _ in hasChanges = true }

                    Toggle("Allow Member Invites", isOn: $settings.allowMemberInvites)
                        .onChange(of: settings.allowMemberInvites) { _, _ in hasChanges = true }
                }

                // Notifications
                Section("Notifications") {
                    Toggle("Email Notifications", isOn: $settings.emailNotificationsEnabled)
                        .onChange(of: settings.emailNotificationsEnabled) { _, _ in hasChanges = true }

                    Toggle("Push Notifications", isOn: $settings.pushNotificationsEnabled)
                        .onChange(of: settings.pushNotificationsEnabled) { _, _ in hasChanges = true }

                    Picker("Digest Frequency", selection: $settings.notificationDigestFrequency) {
                        Text("Never").tag("never")
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                    }
                    .onChange(of: settings.notificationDigestFrequency) { _, _ in hasChanges = true }
                }

                // Branding
                Section("Branding") {
                    Toggle("Custom Branding", isOn: $settings.useCustomBranding)
                        .onChange(of: settings.useCustomBranding) { _, _ in hasChanges = true }

                    if settings.useCustomBranding {
                        NavigationLink("Customize Appearance") {
                            BrandingCustomizationView(settings: $settings)
                        }
                    }
                }

                // Collaboration
                Section("Collaboration") {
                    Toggle("Real-time Collaboration", isOn: $settings.enableRealTimeCollaboration)
                        .onChange(of: settings.enableRealTimeCollaboration) { _, _ in hasChanges = true }

                    Toggle("Comments", isOn: $settings.allowComments)
                        .onChange(of: settings.allowComments) { _, _ in hasChanges = true }

                    Toggle("Version History", isOn: $settings.enableVersionHistory)
                        .onChange(of: settings.enableVersionHistory) { _, _ in hasChanges = true }

                    if settings.enableVersionHistory {
                        Stepper("Max Versions: \(settings.maxVersionsPerSong)", value: $settings.maxVersionsPerSong, in: 0...100)
                            .onChange(of: settings.maxVersionsPerSong) { _, _ in hasChanges = true }
                    }

                    Toggle("Presence Awareness", isOn: $settings.enablePresenceAwareness)
                        .onChange(of: settings.enablePresenceAwareness) { _, _ in hasChanges = true }
                }

                // Content
                Section("Content") {
                    Toggle("Require Song Metadata", isOn: $settings.requireSongMetadata)
                        .onChange(of: settings.requireSongMetadata) { _, _ in hasChanges = true }

                    Toggle("Allow Song Imports", isOn: $settings.allowSongImports)
                        .onChange(of: settings.allowSongImports) { _, _ in hasChanges = true }

                    Stepper("Max Song Size: \(String(format: "%.1f", settings.maxSongSizeMB)) MB", value: $settings.maxSongSizeMB, in: 1...50, step: 0.5)
                        .onChange(of: settings.maxSongSizeMB) { _, _ in hasChanges = true }
                }

                // Data & Privacy
                Section("Data & Privacy") {
                    Stepper("Data Retention: \(dataRetentionText)", value: $settings.dataRetentionDays, in: 0...3650, step: 30)
                        .onChange(of: settings.dataRetentionDays) { _, _ in hasChanges = true }

                    Toggle("Activity Tracking", isOn: $settings.enableActivityTracking)
                        .onChange(of: settings.enableActivityTracking) { _, _ in hasChanges = true }

                    Toggle("Audit Logging", isOn: $settings.enableAuditLogging)
                        .onChange(of: settings.enableAuditLogging) { _, _ in hasChanges = true }

                    Toggle("Allow Data Export", isOn: $settings.allowDataExport)
                        .onChange(of: settings.allowDataExport) { _, _ in hasChanges = true }
                }

                // Security
                Section("Security") {
                    Toggle("Require 2FA", isOn: $settings.require2FA)
                        .onChange(of: settings.require2FA) { _, _ in hasChanges = true }

                    Toggle("Allow External Sharing", isOn: $settings.allowExternalSharing)
                        .onChange(of: settings.allowExternalSharing) { _, _ in hasChanges = true }

                    if settings.allowExternalSharing {
                        Toggle("Require Password for Links", isOn: $settings.requirePasswordForSharedLinks)
                            .onChange(of: settings.requirePasswordForSharedLinks) { _, _ in hasChanges = true }

                        Stepper("Link Expiration: \(linkExpirationText)", value: $settings.sharedLinkExpirationDays, in: 0...365, step: 7)
                            .onChange(of: settings.sharedLinkExpirationDays) { _, _ in hasChanges = true }
                    }
                }

                // Presets
                Section("Quick Setup") {
                    Button("Apply Church Preset") {
                        settings = TeamSettings.churchPreset()
                        hasChanges = true
                    }

                    Button("Apply Therapy Practice Preset") {
                        settings = TeamSettings.therapyPracticePreset()
                        hasChanges = true
                    }

                    Button("Apply School Preset") {
                        settings = TeamSettings.schoolPreset()
                        hasChanges = true
                    }

                    Button("Apply Band Preset") {
                        settings = TeamSettings.bandPreset()
                        hasChanges = true
                    }
                }
            }
            .navigationTitle("Organization Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(!hasChanges || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var dataRetentionText: String {
        if settings.dataRetentionDays == 0 {
            return "Forever"
        } else if settings.dataRetentionDays < 365 {
            return "\(settings.dataRetentionDays) days"
        } else {
            let years = settings.dataRetentionDays / 365
            return "\(years) year\(years == 1 ? "" : "s")"
        }
    }

    private var linkExpirationText: String {
        if settings.sharedLinkExpirationDays == 0 {
            return "Never"
        } else if settings.sharedLinkExpirationDays < 30 {
            return "\(settings.sharedLinkExpirationDays) days"
        } else {
            let months = settings.sharedLinkExpirationDays / 30
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }

    private func saveSettings() {
        isSaving = true

        Task {
            do {
                try await orgManager.updateSettings(
                    for: organization,
                    settings: settings,
                    updatedBy: currentUserRecordID,
                    modelContext: modelContext
                )

                await MainActor.run {
                    isSaving = false
                    hasChanges = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Branding Customization View

struct BrandingCustomizationView: View {
    @Binding var settings: TeamSettings

    @State private var primaryColorHex: String
    @State private var secondaryColorHex: String

    init(settings: Binding<TeamSettings>) {
        self._settings = settings
        _primaryColorHex = State(initialValue: settings.wrappedValue.primaryColorHex ?? "#4A90E2")
        _secondaryColorHex = State(initialValue: settings.wrappedValue.secondaryColorHex ?? "#7B68EE")
    }

    var body: some View {
        Form {
            Section("Colors") {
                HStack {
                    Text("Primary Color")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: primaryColorHex) ?? .blue },
                        set: { color in
                            // Convert color to hex (simplified)
                            primaryColorHex = "#4A90E2"
                            settings.primaryColorHex = primaryColorHex
                        }
                    ))
                }

                HStack {
                    Text("Secondary Color")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: secondaryColorHex) ?? .purple },
                        set: { color in
                            // Convert color to hex (simplified)
                            secondaryColorHex = "#7B68EE"
                            settings.secondaryColorHex = secondaryColorHex
                        }
                    ))
                }
            }

            Section("Logo") {
                Button("Upload Logo") {
                    // TODO: Implement logo upload
                }

                if settings.logoURL != nil {
                    Button("Remove Logo", role: .destructive) {
                        settings.logoURL = nil
                    }
                }
            }

            Section("Icon") {
                TextField("SF Symbol Name", text: Binding(
                    get: { settings.iconName ?? "" },
                    set: { settings.iconName = $0.isEmpty ? nil : $0 }
                ))
            }
        }
        .navigationTitle("Branding")
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Organization.self, configurations: config)

    let org = Organization(
        name: "Test Church",
        organizationType: .church,
        ownerRecordID: "owner123",
        ownerDisplayName: "John Doe"
    )
    container.mainContext.insert(org)

    return OrganizationSettingsView(organization: org)
        .modelContainer(container)
}
