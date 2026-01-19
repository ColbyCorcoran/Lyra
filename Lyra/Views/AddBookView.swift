//
//  AddBookView.swift
//  Lyra
//
//  Form for creating a new book collection
//

import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var bookDescription: String = ""
    @State private var selectedColor: String = "#4A90E2" // Default blue
    @State private var selectedIcon: String? = nil
    @State private var showIconPicker: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    // Preset colors for books
    private let presetColors: [(name: String, hex: String)] = [
        ("Blue", "#4A90E2"),
        ("Purple", "#9B59B6"),
        ("Pink", "#E91E63"),
        ("Red", "#E74C3C"),
        ("Orange", "#F39C12"),
        ("Yellow", "#F1C40F"),
        ("Green", "#27AE60"),
        ("Teal", "#1ABC9C"),
        ("Indigo", "#3F51B5"),
        ("Brown", "#795548"),
        ("Gray", "#607D8B"),
        ("Black", "#2C3E50")
    ]

    // Popular SF Symbols for books
    private let presetIcons: [String] = [
        "book.fill",
        "books.vertical.fill",
        "music.note.list",
        "music.quarternote.3",
        "star.fill",
        "heart.fill",
        "flame.fill",
        "sparkles",
        "calendar",
        "flag.fill",
        "crown.fill",
        "cross.fill",
        "moon.stars.fill",
        "sun.max.fill",
        "leaf.fill",
        "globe",
        "hands.clap.fill",
        "gift.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Info Section

                Section {
                    TextField("Book Name", text: $name)
                        .autocorrectionDisabled()

                    ZStack(alignment: .topLeading) {
                        if bookDescription.isEmpty {
                            Text("Description (Optional)")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: $bookDescription)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("Book Information")
                }

                // MARK: - Appearance Section

                Section {
                    // Color picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(presetColors, id: \.hex) { colorOption in
                                ColorSwatch(
                                    name: colorOption.name,
                                    hex: colorOption.hex,
                                    isSelected: selectedColor == colorOption.hex,
                                    action: {
                                        HapticManager.shared.selection()
                                        selectedColor = colorOption.hex
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    // Icon picker
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Icon (Optional)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if selectedIcon != nil {
                                Button("Clear") {
                                    HapticManager.shared.selection()
                                    selectedIcon = nil
                                }
                                .font(.caption)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(presetIcons, id: \.self) { icon in
                                    IconButton(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        action: {
                                            HapticManager.shared.selection()
                                            selectedIcon = icon
                                        }
                                    )
                                }
                            }
                        }

                        // Preview
                        if selectedIcon != nil || !name.isEmpty {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: selectedColor)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: selectedIcon ?? "book.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color(hex: selectedColor) ?? .blue)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name.isEmpty ? "Book Name" : name)
                                        .font(.headline)
                                        .foregroundStyle(name.isEmpty ? .secondary : .primary)

                                    Text("Preview")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }

                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Appearance")
                }
            }
            .navigationTitle("New Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBook()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error Creating Book", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Actions

    private func saveBook() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a book name."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
            return
        }

        let newBook = Book(
            name: trimmedName,
            description: bookDescription.isEmpty ? nil : bookDescription
        )

        newBook.color = selectedColor
        newBook.icon = selectedIcon

        modelContext.insert(newBook)

        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error saving book: \(error.localizedDescription)")
            errorMessage = "Unable to save book. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                    .frame(width: 44, height: 44)

                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Add Book View") {
    AddBookView()
        .modelContainer(for: Book.self, inMemory: true)
}
