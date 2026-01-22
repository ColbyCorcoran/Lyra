//
//  StickyNoteView.swift
//  Lyra
//
//  Renders and manages individual sticky note annotations
//

import SwiftUI

struct StickyNoteView: View {
    let annotation: Annotation
    let containerSize: CGSize
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onBringToFront: () -> Void
    let onSendToBack: () -> Void
    let onPositionChange: (Double, Double) -> Void
    let onScaleChange: (Double) -> Void
    let onRotationChange: (Double) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    @State private var showMenu: Bool = false

    // Sticky note colors
    private var noteBackgroundColor: Color {
        if let hexColor = annotation.noteColor {
            return Color(hex: hexColor) ?? .yellow
        }
        return .yellow
    }

    private var noteTextColor: Color {
        if let hexColor = annotation.textColor {
            return Color(hex: hexColor) ?? .black
        }
        return .black
    }

    private var baseFontSize: CGFloat {
        CGFloat(annotation.fontSize ?? 14)
    }

    private var baseScale: CGFloat {
        annotation.scale ?? 1.0
    }

    // Calculate position in points from percentage
    private var position: CGPoint {
        CGPoint(
            x: annotation.xPosition * containerSize.width,
            y: annotation.yPosition * containerSize.height
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(annotation.text ?? "")
                .font(.system(size: baseFontSize))
                .foregroundStyle(noteTextColor)
                .multilineTextAlignment(.leading)
                .padding(12)
        }
        .frame(minWidth: 120, maxWidth: 200)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(noteBackgroundColor)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
        )
        .scaleEffect(baseScale * currentScale)
        .rotationEffect(.degrees(annotation.rotation ?? 0) + currentRotation)
        .position(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    // Calculate new percentage-based position
                    let newX = (position.x + value.translation.width) / containerSize.width
                    let newY = (position.y + value.translation.height) / containerSize.height

                    // Clamp to 0.0-1.0 range
                    let clampedX = max(0.0, min(1.0, newX))
                    let clampedY = max(0.0, min(1.0, newY))

                    onPositionChange(clampedX, clampedY)
                    dragOffset = .zero
                    HapticManager.shared.selection()
                }
        )
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    currentScale = value
                }
                .onEnded { value in
                    let newScale = baseScale * value
                    let clampedScale = max(0.5, min(1.5, newScale))
                    onScaleChange(clampedScale)
                    currentScale = 1.0
                    HapticManager.shared.selection()
                }
        )
        .gesture(
            RotationGesture()
                .onChanged { value in
                    currentRotation = value
                }
                .onEnded { value in
                    let newRotation = (annotation.rotation ?? 0) + value.degrees
                    let clampedRotation = max(-45, min(45, newRotation))
                    onRotationChange(clampedRotation)
                    currentRotation = .zero
                    HapticManager.shared.selection()
                }
        )
        .onLongPressGesture {
            showMenu = true
            HapticManager.shared.success()
        }
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button {
                onBringToFront()
            } label: {
                Label("Bring to Front", systemImage: "square.3.layers.3d.top.filled")
            }

            Button {
                onSendToBack()
            } label: {
                Label("Send to Back", systemImage: "square.3.layers.3d.bottom.filled")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
