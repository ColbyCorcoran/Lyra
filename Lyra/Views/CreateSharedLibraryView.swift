//
//  CreateSharedLibraryView.swift
//  Lyra
//
//  UI for creating a new shared library
//

import SwiftUI
import SwiftData

struct CreateSharedLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var libraryManager = SharedLibraryManager.shared
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedPrivacy: LibraryPrivacy = .private
    @State private var selectedCategory: LibraryCategory = .worship
    @State private var selectedIcon: String = "music.note.list"
    @State private var selectedColor: Color = .blue

    @State private var isCreating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let availableIcons = [
        "music.note.list",
        "music.mic",
        "guitars",
        "pianokeys",
        "hands.sparkles",
        "heart.text.square",
        "book.closed",
        "graduationcap",
        "person.2",
        "folder"
    ]

    private let availableColors: [Color] = [
        .blue, .purple, .pink, .red, .orange,
        .yellow, .green, .teal, .indigo, .brown
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Basic Information
                basicInformationSection

                // Category
                categorySection

                // Appearance
                appearanceSection

                // Privacy Settings
                privacySection

                // Preview
                previewSection
            }
            .navigationTitle("Create Shared Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createLibrary()
                    }
                    .disabled(!isValid || isCreating)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error Creating Library", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Basic Information Section

    private var basicInformationSection: some View {
        Section("Basic Information") {
            TextField("Library Name", text: $name)
                .textInputAutocapitalization(.words)

            TextField("Description (optional)", text: $description, axis: .vertical)
                .lineLimit(3...6)
        } footer: {
            Text("Give your library a descriptive name that reflects its purpose.")
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        Section("Category") {
            Picker("Type", selection: $selectedCategory) {
                ForEach(LibraryCategory.allCases, id: \.self) { category in
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedCategory) { _, newCategory in
                // Auto-set icon based on category
                selectedIcon = newCategory.suggestedIcon
            }
        } footer: {
            Text("Choose the category that best describes your library's use.")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("Appearance") {
            // Icon Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            IconButton(
                                icon: icon,
                                isSelected: selectedIcon == icon,
                                color: selectedColor
                            ) {
                                selectedIcon = icon
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Color Picker
            VStack(alignment: \.leading, spacing: 8) {
                Text("Color")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            ColorButton(
                                color: color,
                                isSelected: selectedColor == color
                            ) {
                                selectedColor = color
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } footer: {
            Text("Customize the visual appearance of your library.")
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section("Privacy") {
            Picker("Privacy Level", selection: $selectedPrivacy) {
                ForEach(LibraryPrivacy.allCases, id: \.self) { privacy in
                    HStack {
                        Image(systemName: privacy.icon)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(privacy.rawValue)
                            Text(privacy.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(privacy)
                }
            }
            .pickerStyle(.navigationLink)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedPrivacy.description)

                if selectedPrivacy != .private {
                    Text("⚠️ Creating a shared library will generate a CloudKit share.")
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        Section("Preview") {
            HStack(spacing: 16) {
                // Icon preview
                ZStack {
                    Circle()
                        .fill(selectedColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: selectedIcon)
                        .font(.title2)
                        .foregroundStyle(selectedColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(name.isEmpty ? "Library Name" : name)
                            .font(.headline)

                        if selectedPrivacy != .private {
                            Image(systemName: "person.2")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 12) {
                        Label(selectedCategory.rawValue, systemImage: selectedCategory.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label(selectedPrivacy.rawValue, systemImage: selectedPrivacy.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func createLibrary() {
        isCreating = true

        Task {
            do {
                let library = try await libraryManager.createSharedLibrary(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.isEmpty ? nil : description,
                    privacy: selectedPrivacy,
                    modelContext: modelContext
                )

                // Update appearance
                library.icon = selectedIcon
                library.colorHex = selectedColor.toHex()

                try modelContext.save()

                await MainActor.run {
                    HapticManager.shared.notification(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                    HapticManager.shared.notification(.error)
                }
            }
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? color.opacity(0.2) : Color(.systemGray6))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? color : .secondary)
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 3)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? .primary : .clear, lineWidth: 2)
                )
                .overlay(
                    isSelected ?
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    : nil
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: Double
        switch hex.count {
        case 6: // RGB
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0
            g = 0
            b = 0
        }

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    CreateSharedLibraryView()
        .modelContainer(for: [SharedLibrary.self])
}
