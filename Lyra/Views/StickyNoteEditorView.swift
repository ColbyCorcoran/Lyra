//
//  StickyNoteEditorView.swift
//  Lyra
//
//  Editor for creating and modifying sticky note annotations
//

import SwiftUI
import SwiftData

struct StickyNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let annotation: Annotation
    let onSave: () -> Void
    let onDelete: (() -> Void)?

    @State private var noteText: String
    @State private var selectedColor: StickyNoteColor
    @State private var fontSize: StickyNoteFontSize
    @State private var rotation: Double

    init(annotation: Annotation, onSave: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.annotation = annotation
        self.onSave = onSave
        self.onDelete = onDelete

        _noteText = State(initialValue: annotation.text ?? "")
        _selectedColor = State(initialValue: StickyNoteColor.fromHex(annotation.noteColor ?? "#FFEB3B") ?? .yellow)
        _fontSize = State(initialValue: StickyNoteFontSize.fromInt(annotation.fontSize ?? 14))
        _rotation = State(initialValue: annotation.rotation ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Text Editor Section
                Section {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
                        .font(.system(size: fontSize.pointSize))
                } header: {
                    Text("Note Text")
                } footer: {
                    Text("Enter your performance notes, reminders, or annotations")
                }

                // Color Picker Section
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(StickyNoteColor.allCases) { color in
                            colorSwatch(color: color)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Note Color")
                }

                // Font Size Section
                Section {
                    Picker("Font Size", selection: $fontSize) {
                        ForEach(StickyNoteFontSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Text Size")
                }

                // Rotation Section
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Rotation")
                                .font(.subheadline)

                            Spacer()

                            Text("\(Int(rotation))°")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .frame(minWidth: 50)
                        }

                        Slider(value: $rotation, in: -45...45, step: 5)

                        HStack(spacing: 8) {
                            Button {
                                rotation = 0
                                HapticManager.shared.selection()
                            } label: {
                                Text("Reset")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } header: {
                    Text("Note Angle")
                } footer: {
                    Text("Rotate the note for a more natural, handwritten look")
                }

                // Preview Section
                Section {
                    HStack {
                        Spacer()

                        VStack(alignment: .leading, spacing: 8) {
                            Text(noteText.isEmpty ? "Preview" : noteText)
                                .font(.system(size: fontSize.pointSize))
                                .foregroundStyle(selectedColor.textColor)
                                .multilineTextAlignment(.leading)
                                .padding(12)
                        }
                        .frame(minWidth: 120, maxWidth: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedColor.backgroundColor)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                        )
                        .rotationEffect(.degrees(rotation))

                        Spacer()
                    }
                    .padding(.vertical, 20)
                } header: {
                    Text("Preview")
                }

                // Delete Section (only if editing existing note)
                if onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            onDelete?()
                            dismiss()
                        } label: {
                            Label("Delete Note", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(onDelete == nil ? "New Sticky Note" : "Edit Sticky Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAnnotation()
                    }
                    .fontWeight(.semibold)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func colorSwatch(color: StickyNoteColor) -> some View {
        Button {
            selectedColor = color
            HapticManager.shared.selection()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.backgroundColor)
                    .frame(height: 60)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)

                if selectedColor == color {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func saveAnnotation() {
        // Update annotation properties
        annotation.text = noteText
        annotation.noteColor = selectedColor.hexColor
        annotation.textColor = selectedColor.textColor.toHex()
        annotation.fontSize = fontSize.intValue
        annotation.rotation = rotation
        annotation.modifiedAt = Date()

        // Save to database
        do {
            try modelContext.save()
            onSave()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Error saving annotation: \(error)")
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Sticky Note Color

enum StickyNoteColor: String, CaseIterable, Identifiable {
    case yellow = "Yellow"
    case orange = "Orange"
    case pink = "Pink"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"

    var id: String { rawValue }

    var hexColor: String {
        switch self {
        case .yellow: return "#FFEB3B"
        case .orange: return "#FF9800"
        case .pink: return "#F48FB1"
        case .blue: return "#81D4FA"
        case .green: return "#A5D6A7"
        case .purple: return "#CE93D8"
        }
    }

    var backgroundColor: Color {
        Color(hex: hexColor) ?? .yellow
    }

    var textColor: Color {
        switch self {
        case .yellow, .orange, .green:
            return .black
        case .pink, .blue, .purple:
            return .white
        }
    }

    static func fromHex(_ hex: String) -> StickyNoteColor? {
        allCases.first { $0.hexColor == hex }
    }
}

// MARK: - Sticky Note Font Size

enum StickyNoteFontSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    var pointSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }

    var intValue: Int {
        Int(pointSize)
    }

    static func fromInt(_ size: Int) -> StickyNoteFontSize {
        switch size {
        case ...12: return .small
        case 13...14: return .medium
        default: return .large
        }
    }
}
