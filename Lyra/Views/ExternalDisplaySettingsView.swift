//
//  ExternalDisplaySettingsView.swift
//  Lyra
//
//  UI for external display settings and configuration
//

import SwiftUI

struct ExternalDisplaySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayManager = ExternalDisplayManager.shared

    @State private var showProfileSheet = false
    @State private var showAppearanceSheet = false
    @State private var showTestPattern = false

    var body: some View {
        NavigationStack {
            Form {
                // Connection Status
                connectionSection

                // Display Selection
                if displayManager.hasExternalDisplay {
                    displaySelectionSection
                }

                // Quick Profile Selection
                if displayManager.isExternalDisplayActive {
                    profileSection

                    // Display Mode
                    modeSection

                    // Quick Actions
                    quickActionsSection

                    // Advanced Settings
                    advancedSection
                }
            }
            .navigationTitle("External Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if displayManager.isExternalDisplayActive {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                showTestPattern = true
                            } label: {
                                Label("Test Pattern", systemImage: "checkerboard.rectangle")
                            }

                            Button {
                                displayManager.toggleBlank()
                            } label: {
                                Label("Toggle Blank", systemImage: "rectangle.fill")
                            }

                            Divider()

                            Button {
                                showAppearanceSheet = true
                            } label: {
                                Label("Appearance", systemImage: "paintbrush")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                DisplayProfilesView()
            }
            .sheet(isPresented: $showAppearanceSheet) {
                DisplayAppearanceView()
            }
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section {
            if displayManager.hasExternalDisplay {
                HStack {
                    Image(systemName: displayManager.isExternalDisplayActive ? "tv.fill" : "tv")
                        .foregroundStyle(displayManager.isExternalDisplayActive ? .green : .gray)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayManager.isExternalDisplayActive ? "Connected" : "Available")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("\(displayManager.displayCount) external display(s) detected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if displayManager.isDisplayingContent {
                        Image(systemName: "eye.fill")
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("No External Display", systemImage: "tv.slash")
                } description: {
                    Text("Connect an external display via HDMI or AirPlay")
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        } header: {
            Text("Status")
        } footer: {
            if !displayManager.hasExternalDisplay {
                Text("Connect an external display to project lyrics, chords, or confidence monitor content to your congregation or audience.")
            }
        }
    }

    // MARK: - Display Selection

    private var displaySelectionSection: some View {
        Section("Available Displays") {
            ForEach(displayManager.externalDisplays) { display in
                Button {
                    if displayManager.selectedDisplay?.id == display.id {
                        displayManager.disconnectDisplay()
                    } else {
                        displayManager.connectToDisplay(display)
                    }
                } label: {
                    DisplayInfoRow(
                        display: display,
                        isSelected: displayManager.selectedDisplay?.id == display.id
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            if let activeProfile = displayManager.activeProfile {
                HStack {
                    Image(systemName: activeProfile.icon)
                        .foregroundStyle(.blue)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activeProfile.name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(activeProfile.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Change") {
                        showProfileSheet = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else {
                Button {
                    showProfileSheet = true
                } label: {
                    Label("Select Profile", systemImage: "rectangle.stack")
                }
            }
        } header: {
            Text("Display Profile")
        } footer: {
            Text("Profiles provide quick presets for different scenarios like worship services, concerts, and rehearsals.")
        }
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        Section {
            Picker("Display Mode", selection: $displayManager.configuration.mode) {
                ForEach(ExternalDisplayMode.allCases, id: \.self) { mode in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: mode.icon)
                    }
                    .tag(mode)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Mode")
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        Section("Quick Actions") {
            Button {
                displayManager.blankDisplay()
            } label: {
                Label("Blank Display", systemImage: "rectangle.fill")
            }

            Button {
                displayManager.clearDisplay()
            } label: {
                Label("Clear Content", systemImage: "xmark.rectangle")
            }

            Button {
                showTestPattern = true
            } label: {
                Label("Show Test Pattern", systemImage: "checkerboard.rectangle")
            }
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        Section("Advanced") {
            NavigationLink {
                DisplayAppearanceView()
            } label: {
                Label("Appearance", systemImage: "paintbrush")
            }

            NavigationLink {
                DisplayBehaviorView()
            } label: {
                Label("Behavior", systemImage: "gearshape")
            }

            NavigationLink {
                DisplayProfilesView()
            } label: {
                Label("Manage Profiles", systemImage: "rectangle.stack")
            }
        }
    }
}

// MARK: - Display Info Row

struct DisplayInfoRow: View {
    let display: ExternalDisplayInfo
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tv")
                .font(.title3)
                .foregroundStyle(isSelected ? .blue : .gray)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(display.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                HStack(spacing: 12) {
                    Label(display.resolution, systemImage: "rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(display.aspectRatio, systemImage: "aspectratio")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if display.isPortrait {
                        Label("Portrait", systemImage: "rotate.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Display Appearance View

struct DisplayAppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayManager = ExternalDisplayManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // Colors
                Section("Colors") {
                    ColorPicker("Background", selection: Binding(
                        get: { Color(hex: displayManager.configuration.backgroundColor) ?? .black },
                        set: { displayManager.configuration.backgroundColor = $0.toHex() ?? "#000000" }
                    ))

                    ColorPicker("Text", selection: Binding(
                        get: { Color(hex: displayManager.configuration.textColor) ?? .white },
                        set: { displayManager.configuration.textColor = $0.toHex() ?? "#FFFFFF" }
                    ))
                }

                // Typography
                Section("Typography") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Font Size: \(Int(displayManager.configuration.fontSize))pt")
                        Slider(value: $displayManager.configuration.fontSize, in: 24...96, step: 4)
                    }

                    Picker("Text Alignment", selection: $displayManager.configuration.textAlignment) {
                        ForEach(ProjectionTextAlignment.allCases, id: \.self) { alignment in
                            Text(alignment.displayName).tag(alignment)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Line Spacing: \(Int(displayManager.configuration.lineSpacing))pt")
                        Slider(value: $displayManager.configuration.lineSpacing, in: 0...40, step: 2)
                    }
                }

                // Text Effects
                Section("Text Effects") {
                    Toggle("Shadow", isOn: $displayManager.configuration.shadowEnabled)

                    if displayManager.configuration.shadowEnabled {
                        ColorPicker("Shadow Color", selection: Binding(
                            get: { Color(hex: displayManager.configuration.shadowColor) ?? .black },
                            set: { displayManager.configuration.shadowColor = $0.toHex() ?? "#000000" }
                        ))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shadow Radius: \(Int(displayManager.configuration.shadowRadius))pt")
                            Slider(value: $displayManager.configuration.shadowRadius, in: 0...20, step: 1)
                        }
                    }

                    Toggle("Outline", isOn: $displayManager.configuration.outlineEnabled)

                    if displayManager.configuration.outlineEnabled {
                        ColorPicker("Outline Color", selection: Binding(
                            get: { Color(hex: displayManager.configuration.outlineColor) ?? .black },
                            set: { displayManager.configuration.outlineColor = $0.toHex() ?? "#000000" }
                        ))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Outline Width: \(Int(displayManager.configuration.outlineWidth))pt")
                            Slider(value: $displayManager.configuration.outlineWidth, in: 1...6, step: 0.5)
                        }
                    }
                }

                // Layout
                Section("Layout") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Horizontal Margin: \(Int(displayManager.configuration.horizontalMargin))pt")
                        Slider(value: $displayManager.configuration.horizontalMargin, in: 20...200, step: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vertical Margin: \(Int(displayManager.configuration.verticalMargin))pt")
                        Slider(value: $displayManager.configuration.verticalMargin, in: 20...200, step: 10)
                    }
                }

                // Preview
                Section {
                    PreviewCard()
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Display Behavior View

struct DisplayBehaviorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayManager = ExternalDisplayManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Content Display") {
                    Toggle("Show Section Titles", isOn: $displayManager.configuration.showSectionTitles)

                    Toggle("Auto-Advance Sections", isOn: $displayManager.configuration.autoAdvanceSections)

                    Toggle("Blank Between Songs", isOn: $displayManager.configuration.blankBetweenSongs)

                    Toggle("Sync Scroll with Device", isOn: $displayManager.configuration.syncScroll)
                }

                Section("Confidence Monitor") {
                    Toggle("Show Next Line", isOn: $displayManager.configuration.showNextLine)

                    Toggle("Show Timer", isOn: $displayManager.configuration.showTimer)

                    Toggle("Show Setlist", isOn: $displayManager.configuration.showSetlist)
                }
            }
            .navigationTitle("Behavior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Display Profiles View

struct DisplayProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayManager = ExternalDisplayManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in Profiles") {
                    ForEach(displayManager.profiles.filter { $0.isBuiltIn }) { profile in
                        ProfileRow(profile: profile) {
                            displayManager.applyProfile(profile)
                            dismiss()
                        }
                    }
                }

                let customProfiles = displayManager.profiles.filter { !$0.isBuiltIn }
                if !customProfiles.isEmpty {
                    Section("Custom Profiles") {
                        ForEach(customProfiles) { profile in
                            ProfileRow(profile: profile) {
                                displayManager.applyProfile(profile)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Display Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileRow: View {
    let profile: ExternalDisplayProfile
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: profile.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(profile.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Label(profile.configuration.mode.displayName, systemImage: profile.configuration.mode.icon)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Label("\(Int(profile.configuration.fontSize))pt", systemImage: "textformat.size")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Preview Card

struct PreviewCard: View {
    @State private var displayManager = ExternalDisplayManager.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(hex: displayManager.configuration.backgroundColor) ?? .black

                Text("Amazing Grace\nHow sweet the sound")
                    .font(.system(size: displayManager.configuration.fontSize / 4, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: displayManager.configuration.textColor) ?? .white)
                    .multilineTextAlignment(displayManager.configuration.textAlignment.textAlignment)
                    .lineSpacing(displayManager.configuration.lineSpacing / 4)
                    .shadow(
                        color: displayManager.configuration.shadowEnabled ?
                            (Color(hex: displayManager.configuration.shadowColor) ?? .black).opacity(0.8) :
                            .clear,
                        radius: displayManager.configuration.shadowRadius / 4
                    )
                    .padding(displayManager.configuration.horizontalMargin / 4)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ExternalDisplaySettingsView()
}
