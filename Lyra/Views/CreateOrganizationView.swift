//
//  CreateOrganizationView.swift
//  Lyra
//
//  View for creating a new organization/team
//

import SwiftUI
import SwiftData

struct CreateOrganizationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var orgManager = OrganizationManager.shared

    @State private var organizationName = ""
    @State private var organizationDescription = ""
    @State private var organizationType: OrganizationType = .team
    @State private var selectedIcon: String?
    @State private var selectedColor: String?
    @State private var createInitialLibrary = true
    @State private var initialLibraryName = "Main Library"

    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Mock user info - in production, get from authentication
    private let currentUserRecordID = "user_\(UUID().uuidString)"
    private let currentUserDisplayName = "Current User"

    var body: some View {
        NavigationStack {
            Form {
                // Basic Information
                Section("Organization Details") {
                    TextField("Organization Name", text: $organizationName)
                        .autocorrectionDisabled()

                    TextField("Description (Optional)", text: $organizationDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Organization Type
                Section("Organization Type") {
                    Picker("Type", selection: $organizationType) {
                        ForEach(OrganizationType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.defaultIcon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: organizationType) { oldValue, newValue in
                        // Auto-update icon and color based on type
                        if selectedIcon == nil || selectedIcon == oldValue.defaultIcon {
                            selectedIcon = newValue.defaultIcon
                        }
                        if selectedColor == nil || selectedColor == oldValue.defaultColor {
                            selectedColor = newValue.defaultColor
                        }
                    }
                }

                // Appearance
                Section("Appearance") {
                    // Icon picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(organizationIcons, id: \.self) { icon in
                                    IconButton(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        color: Color(hex: selectedColor ?? organizationType.defaultColor) ?? .blue
                                    ) {
                                        selectedIcon = icon
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(organizationColors, id: \.self) { colorHex in
                                    ColorButton(
                                        color: Color(hex: colorHex) ?? .blue,
                                        isSelected: selectedColor == colorHex
                                    ) {
                                        selectedColor = colorHex
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                }

                // Initial Library
                Section {
                    Toggle("Create Initial Library", isOn: $createInitialLibrary)

                    if createInitialLibrary {
                        TextField("Library Name", text: $initialLibraryName)
                    }
                } header: {
                    Text("Setup")
                } footer: {
                    Text("We'll create a shared library to get you started")
                }

                // Plan Info
                Section("Subscription Plan") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "gift")
                                .foregroundStyle(.green)

                            Text("Free Plan")
                                .font(.headline)

                            Spacer()

                            Text("$0/month")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        ForEach(SubscriptionTier.free.features, id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)

                                Text(feature)
                                    .font(.caption)
                            }
                        }

                        Button {
                            // Navigate to subscription plans
                        } label: {
                            HStack {
                                Text("View All Plans")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Image(systemName: "arrow.right")
                                    .font(.caption)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Create Organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createOrganization()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || isCreating)
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Creating organization...")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isFormValid: Bool {
        !organizationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!createInitialLibrary || !initialLibraryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func createOrganization() async {
        isCreating = true

        do {
            let org = try await orgManager.createOrganization(
                name: organizationName,
                description: organizationDescription.isEmpty ? nil : organizationDescription,
                type: organizationType,
                ownerRecordID: currentUserRecordID,
                ownerDisplayName: currentUserDisplayName,
                modelContext: modelContext
            )

            // Set custom appearance
            if let icon = selectedIcon {
                org.icon = icon
            }
            if let color = selectedColor {
                org.colorHex = color
            }

            // Create initial library if requested
            if createInitialLibrary {
                let library = SharedLibrary(
                    name: initialLibraryName,
                    description: "Initial shared library for \(organizationName)",
                    ownerRecordID: currentUserRecordID,
                    ownerDisplayName: currentUserDisplayName
                )
                library.icon = selectedIcon ?? organizationType.defaultIcon
                library.colorHex = selectedColor ?? organizationType.defaultColor

                modelContext.insert(library)
                org.addLibrary(library)
            }

            try modelContext.save()

            await MainActor.run {
                isCreating = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isCreating = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Icon and Color Options

    private let organizationIcons = [
        "building.2",
        "building.columns",
        "hands.sparkles",
        "heart.text.square",
        "graduationcap",
        "music.mic",
        "music.note.list",
        "person.3",
        "star.circle",
        "folder"
    ]

    private let organizationColors = [
        "#7B68EE", // Medium Slate Blue
        "#FF6B6B", // Red
        "#4ECDC4", // Turquoise
        "#45B7D1", // Sky Blue
        "#F38181", // Light Red
        "#5F9EA0", // Cadet Blue
        "#DDA15E", // Brass
        "#BC6C25", // Brown
        "#606C38", // Olive Green
        "#95A5A6"  // Gray
    ]
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isSelected ? .white : color)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? color : color.opacity(0.2))
                )
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(color, lineWidth: 2)
                    }
                }
        }
    }
}

// MARK: - Color Button

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                        Circle()
                            .strokeBorder(color, lineWidth: 5)
                            .padding(-2)

                        Image(systemName: "checkmark")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    CreateOrganizationView()
        .modelContainer(for: [Organization.self, SharedLibrary.self], inMemory: true)
}
