//
//  DrawingToolbarView.swift
//  Lyra
//
//  Toolbar for drawing tools with PencilKit integration
//

import SwiftUI
import PencilKit

struct DrawingToolbarView: View {
    @Binding var selectedTool: DrawingTool
    @Binding var selectedColor: DrawingColor
    @Binding var lineThickness: DrawingThickness
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool

    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void
    let onDone: () -> Void

    @State private var showClearConfirmation: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Main toolbar
            HStack(spacing: 16) {
                // Drawing tools
                toolSection

                Divider()
                    .frame(height: 32)

                // Color palette (only for pen and highlighter)
                if selectedTool != .eraser {
                    colorSection

                    Divider()
                        .frame(height: 32)
                }

                // Line thickness (only for pen and highlighter)
                if selectedTool != .eraser {
                    thicknessSection

                    Divider()
                        .frame(height: 32)
                }

                // Actions
                actionSection

                Spacer()

                // Done button
                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .confirmationDialog("Clear all drawings?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) {
                onClear()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all drawings on this song. This cannot be undone.")
        }
    }

    // MARK: - Tool Section

    private var toolSection: some View {
        HStack(spacing: 12) {
            toolButton(
                tool: .pen,
                icon: "pencil.tip",
                label: "Pen"
            )

            toolButton(
                tool: .highlighter,
                icon: "highlighter",
                label: "Highlighter"
            )

            toolButton(
                tool: .eraser,
                icon: "eraser",
                label: "Eraser"
            )
        }
    }

    @ViewBuilder
    private func toolButton(tool: DrawingTool, icon: String, label: String) -> some View {
        Button {
            selectedTool = tool
            HapticManager.shared.selection()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(selectedTool == tool ? .blue : .primary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(selectedTool == tool ? .blue : .secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTool == tool ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(selectedTool == tool ? .isSelected : [])
    }

    // MARK: - Color Section

    private var colorSection: some View {
        HStack(spacing: 8) {
            ForEach(DrawingColor.allCases) { color in
                colorButton(color: color)
            }
        }
    }

    @ViewBuilder
    private func colorButton(color: DrawingColor) -> some View {
        Button {
            selectedColor = color
            HapticManager.shared.selection()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(uiColor: color.uiColor))
                    .frame(width: 32, height: 32)

                if selectedColor == color {
                    Circle()
                        .strokeBorder(Color.blue, lineWidth: 3)
                        .frame(width: 38, height: 38)
                }
            }
        }
        .accessibilityLabel(color.rawValue)
        .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
    }

    // MARK: - Thickness Section

    private var thicknessSection: some View {
        HStack(spacing: 8) {
            ForEach(DrawingThickness.allCases) { thickness in
                thicknessButton(thickness: thickness)
            }
        }
    }

    @ViewBuilder
    private func thicknessButton(thickness: DrawingThickness) -> some View {
        Button {
            lineThickness = thickness
            HapticManager.shared.selection()
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(selectedTool == .highlighter ? Color.primary.opacity(0.3) : Color.primary)
                    .frame(width: thickness.previewSize, height: thickness.previewSize)

                Text(thickness.rawValue)
                    .font(.caption2)
                    .foregroundStyle(lineThickness == thickness ? .blue : .secondary)
            }
            .frame(width: 50)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(lineThickness == thickness ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .accessibilityLabel("\(thickness.rawValue) thickness")
        .accessibilityAddTraits(lineThickness == thickness ? .isSelected : [])
    }

    // MARK: - Action Section

    private var actionSection: some View {
        HStack(spacing: 12) {
            // Undo button
            Button {
                onUndo()
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3)
                    .foregroundStyle(canUndo ? .primary : .secondary)
            }
            .disabled(!canUndo)
            .accessibilityLabel("Undo")

            // Redo button
            Button {
                onRedo()
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.title3)
                    .foregroundStyle(canRedo ? .primary : .secondary)
            }
            .disabled(!canRedo)
            .accessibilityLabel("Redo")

            // Clear button
            Button {
                showClearConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            .accessibilityLabel("Clear all drawings")
        }
    }
}

// MARK: - Drawing Tool

enum DrawingTool: String, CaseIterable, Identifiable {
    case pen = "Pen"
    case highlighter = "Highlighter"
    case eraser = "Eraser"

    var id: String { rawValue }

    var pkInkingToolType: PKInkingTool.InkType {
        switch self {
        case .pen:
            return .pen
        case .highlighter:
            return .marker
        case .eraser:
            return .pen // Not used, eraser is handled separately
        }
    }
}

// MARK: - Drawing Color

enum DrawingColor: String, CaseIterable, Identifiable {
    case black = "Black"
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case yellow = "Yellow"
    case orange = "Orange"

    var id: String { rawValue }

    var uiColor: UIColor {
        switch self {
        case .black:
            return .black
        case .red:
            return .systemRed
        case .blue:
            return .systemBlue
        case .green:
            return .systemGreen
        case .yellow:
            return .systemYellow
        case .orange:
            return .systemOrange
        }
    }
}

// MARK: - Drawing Thickness

enum DrawingThickness: String, CaseIterable, Identifiable {
    case thin = "Thin"
    case medium = "Medium"
    case thick = "Thick"

    var id: String { rawValue }

    var width: CGFloat {
        switch self {
        case .thin:
            return 2
        case .medium:
            return 5
        case .thick:
            return 10
        }
    }

    var previewSize: CGFloat {
        switch self {
        case .thin:
            return 4
        case .medium:
            return 8
        case .thick:
            return 12
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()

        DrawingToolbarView(
            selectedTool: .constant(.pen),
            selectedColor: .constant(.black),
            lineThickness: .constant(.medium),
            canUndo: .constant(true),
            canRedo: .constant(true),
            onUndo: {},
            onRedo: {},
            onClear: {},
            onDone: {}
        )
    }
}
