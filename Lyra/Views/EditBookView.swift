//
//  EditBookView.swift
//  Lyra
//
//  Form for editing an existing book's details
//

import SwiftUI
import SwiftData

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let book: Book

    @State private var name: String
    @State private var bookDescription: String
    @State private var selectedColor: String
    @State private var selectedIcon: String?
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

    init(book: Book) {
        self.book = book
        _name = State(initialValue: book.name)
        _bookDescription = State(initialValue: book.bookDescription ?? "")
        _selectedColor = State(initialValue: book.color ?? "#4A90E2")
        _selectedIcon = State(initialValue: book.icon)
    }

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
            .navigationTitle("Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error Saving Changes", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a book name."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
            return
        }

        // Update book properties
        book.name = trimmedName
        book.bookDescription = bookDescription.isEmpty ? nil : bookDescription
        book.color = selectedColor
        book.icon = selectedIcon
        book.modifiedAt = Date()

        // Save to SwiftData
        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error saving book changes: \(error.localizedDescription)")
            errorMessage = "Unable to save changes. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Preview

#Preview("Edit Book") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, configurations: config)

    let book = Book(name: "Classic Hymns", description: "Traditional hymns and worship songs")
    book.color = "#4A90E2"
    book.icon = "music.note.list"

    container.mainContext.insert(book)

    return EditBookView(book: book)
        .modelContainer(container)
}
