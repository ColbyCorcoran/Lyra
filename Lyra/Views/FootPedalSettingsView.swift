//
//  FootPedalSettingsView.swift
//  Lyra
//
//  Settings view for configuring Bluetooth foot pedals
//

import SwiftUI

struct FootPedalSettingsView: View {
    @Bindable var footPedalManager: FootPedalManager
    @State private var showTestingView: Bool = false
    @State private var showProfileEditor: Bool = false
    @State private var editingProfile: FootPedalProfile?

    var body: some View {
        List {
            // Enable/Disable Section
            enableSection

            // Connection Instructions
            connectionSection

            // Active Profile
            activeProfileSection

            // Built-in Profiles
            builtInProfilesSection

            // Custom Profiles
            if !footPedalManager.customProfiles.isEmpty {
                customProfilesSection
            }

            // Testing
            testingSection

            // Visual Feedback
            feedbackSection
        }
        .navigationTitle("Foot Pedals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createCustomProfile()
                } label: {
                    Label("New Profile", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showTestingView) {
            FootPedalTestingView(footPedalManager: footPedalManager)
        }
        .sheet(item: $editingProfile) { profile in
            FootPedalProfileEditorView(
                profile: profile,
                onSave: { updatedProfile in
                    if updatedProfile.isBuiltIn {
                        // Can't edit built-in profiles
                    } else {
                        footPedalManager.updateCustomProfile(updatedProfile)
                    }
                    editingProfile = nil
                }
            )
        }
    }

    // MARK: - Enable Section

    @ViewBuilder
    private var enableSection: some View {
        Section {
            Toggle("Enable Foot Pedals", isOn: $footPedalManager.isEnabled)
                .onChange(of: footPedalManager.isEnabled) { _, _ in
                    footPedalManager.saveSettings()
                }
        } footer: {
            Text("Allow Bluetooth foot pedals to control Lyra during performances")
        }
    }

    // MARK: - Connection Section

    @ViewBuilder
    private var connectionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Pairing Instructions", systemImage: "info.circle")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    InstructionStep(number: 1, text: "Turn on your Bluetooth foot pedal")
                    InstructionStep(number: 2, text: "Open iOS Settings → Bluetooth")
                    InstructionStep(number: 3, text: "Select your pedal from the list")
                    InstructionStep(number: 4, text: "Return to Lyra and test below")
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Connection")
        } footer: {
            Text("Most foot pedals work as Bluetooth keyboards. Common brands: AirTurn, PageFlip, Donner")
        }
    }

    // MARK: - Active Profile Section

    @ViewBuilder
    private var activeProfileSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(footPedalManager.activeProfile.name)
                        .font(.headline)

                    if let description = footPedalManager.activeProfile.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
            .contentShape(Rectangle())
        } header: {
            Text("Active Profile")
        }
    }

    // MARK: - Built-in Profiles Section

    @ViewBuilder
    private var builtInProfilesSection: some View {
        Section {
            ForEach(FootPedalProfile.allBuiltInProfiles) { profile in
                Button {
                    footPedalManager.setActiveProfile(profile)
                } label: {
                    ProfileRow(
                        profile: profile,
                        isActive: profile.id == footPedalManager.activeProfile.id
                    )
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Built-in Profiles")
        } footer: {
            Text("Tap a profile to activate it. Long press to view key mappings.")
        }
    }

    // MARK: - Custom Profiles Section

    @ViewBuilder
    private var customProfilesSection: some View {
        Section {
            ForEach(footPedalManager.customProfiles) { profile in
                Button {
                    footPedalManager.setActiveProfile(profile)
                } label: {
                    ProfileRow(
                        profile: profile,
                        isActive: profile.id == footPedalManager.activeProfile.id
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        footPedalManager.deleteCustomProfile(profile)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        editingProfile = profile
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        } header: {
            Text("Custom Profiles")
        }
    }

    // MARK: - Testing Section

    @ViewBuilder
    private var testingSection: some View {
        Section {
            Button {
                showTestingView = true
            } label: {
                HStack {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Test Foot Pedal")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Check which pedals are detected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("Testing")
        } footer: {
            Text("Test your pedal before performing to ensure it's working correctly")
        }
    }

    // MARK: - Feedback Section

    @ViewBuilder
    private var feedbackSection: some View {
        Section {
            Toggle("Visual Feedback", isOn: $footPedalManager.showVisualFeedback)
                .onChange(of: footPedalManager.showVisualFeedback) { _, _ in
                    footPedalManager.saveSettings()
                }
        } footer: {
            Text("Show brief visual indicators when pedals are pressed during performance")
        }
    }

    // MARK: - Actions

    private func createCustomProfile() {
        var newProfile = FootPedalProfile(
            name: "Custom Profile",
            description: "My custom pedal mapping",
            keyMappings: [:],
            isBuiltIn: false
        )

        // Start with Performance profile mappings
        newProfile.keyMappings = FootPedalProfile.performance.keyMappings

        editingProfile = newProfile
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: FootPedalProfile
    let isActive: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.headline)

                    if profile.isBuiltIn {
                        Text("BUILT-IN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }

                if let description = profile.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Show key count
                Text("\(profile.keyMappings.count) keys mapped")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Instruction Step

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 24, height: 24)

                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.blue)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Foot Pedal Testing View

struct FootPedalTestingView: View {
    @Bindable var footPedalManager: FootPedalManager
    @Environment(\.dismiss) private var dismiss
    @State private var detectedKeys: [String] = []
    @State private var testingActive: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Status
                statusIndicator

                // Instructions
                instructionsCard

                // Detected Keys
                detectedKeysView

                // Active Profile Mapping
                activeMappingView

                Spacer()
            }
            .padding()
            .navigationTitle("Test Foot Pedal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        footPedalManager.testMode = false
                        dismiss()
                    }
                }
            }
            .onAppear {
                footPedalManager.testMode = true
                testingActive = true
            }
            .onDisappear {
                footPedalManager.testMode = false
                testingActive = false
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(testingActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: testingActive ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(testingActive ? .green : .gray)
            }

            Text(testingActive ? "Listening for Pedals..." : "Not Active")
                .font(.headline)
                .foregroundStyle(testingActive ? .primary : .secondary)
        }
    }

    @ViewBuilder
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How to Test", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("1. Press each pedal on your foot controller")
                Text("2. Watch for detected keys below")
                Text("3. Verify actions match your profile")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var detectedKeysView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Detected")
                .font(.subheadline)
                .fontWeight(.semibold)

            if let lastKey = footPedalManager.lastPressedKey {
                HStack {
                    Image(systemName: "keyboard")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(keyDisplayName(lastKey))
                            .font(.headline)

                        if let action = footPedalManager.activeProfile.actionForKey(lastKey) {
                            Label(action.rawValue, systemImage: action.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No action mapped")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Press a pedal to see detection")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private var activeMappingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Profile: \(footPedalManager.activeProfile.name)")
                .font(.subheadline)
                .fontWeight(.semibold)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(footPedalManager.activeProfile.keyMappings.keys.sorted()), id: \.self) { key in
                        if let action = footPedalManager.activeProfile.keyMappings[key] {
                            HStack {
                                Text(keyDisplayName(key))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Label(action.rawValue, systemImage: action.icon)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }

    private func keyDisplayName(_ key: String) -> String {
        switch key {
        case FootPedalProfile.arrowLeft:
            return "← Left Arrow"
        case FootPedalProfile.arrowRight:
            return "→ Right Arrow"
        case FootPedalProfile.arrowUp:
            return "↑ Up Arrow"
        case FootPedalProfile.arrowDown:
            return "↓ Down Arrow"
        case FootPedalProfile.pageUp:
            return "Page Up"
        case FootPedalProfile.pageDown:
            return "Page Down"
        case FootPedalProfile.space:
            return "Space"
        case FootPedalProfile.returnKey:
            return "Return"
        default:
            return key
        }
    }
}

// MARK: - Profile Editor View

struct FootPedalProfileEditorView: View {
    @State var profile: FootPedalProfile
    let onSave: (FootPedalProfile) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Profile Name", text: $profile.name)
                    TextField("Description", text: Binding(
                        get: { profile.description ?? "" },
                        set: { profile.description = $0.isEmpty ? nil : $0 }
                    ))
                }

                Section {
                    ForEach(Array(allPossibleKeys), id: \.self) { key in
                        HStack {
                            Text(keyDisplayName(key))
                                .font(.subheadline)

                            Spacer()

                            Picker("", selection: Binding(
                                get: { profile.keyMappings[key] ?? .none },
                                set: { profile.keyMappings[key] = $0 }
                            )) {
                                ForEach(FootPedalAction.allCases) { action in
                                    Label(action.rawValue, systemImage: action.icon)
                                        .tag(action)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                } header: {
                    Text("Key Mappings")
                } footer: {
                    Text("Assign actions to each pedal key")
                }
            }
            .navigationTitle(profile.isBuiltIn ? "View Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(profile)
                        dismiss()
                    }
                    .disabled(profile.name.isEmpty)
                }
            }
        }
    }

    private var allPossibleKeys: [String] {
        [
            FootPedalProfile.arrowLeft,
            FootPedalProfile.arrowRight,
            FootPedalProfile.arrowUp,
            FootPedalProfile.arrowDown,
            FootPedalProfile.pageUp,
            FootPedalProfile.pageDown,
            FootPedalProfile.space,
            FootPedalProfile.returnKey
        ]
    }

    private func keyDisplayName(_ key: String) -> String {
        switch key {
        case FootPedalProfile.arrowLeft:
            return "← Left"
        case FootPedalProfile.arrowRight:
            return "→ Right"
        case FootPedalProfile.arrowUp:
            return "↑ Up"
        case FootPedalProfile.arrowDown:
            return "↓ Down"
        case FootPedalProfile.pageUp:
            return "Page Up"
        case FootPedalProfile.pageDown:
            return "Page Down"
        case FootPedalProfile.space:
            return "Space"
        case FootPedalProfile.returnKey:
            return "Return"
        default:
            return key
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FootPedalSettingsView(footPedalManager: FootPedalManager())
    }
}
