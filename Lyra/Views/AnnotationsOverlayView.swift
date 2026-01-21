//
//  AnnotationsOverlayView.swift
//  Lyra
//
//  Manages and displays all annotations for a song
//

import SwiftUI
import SwiftData

struct AnnotationsOverlayView: View {
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let containerSize: CGSize
    let isAnnotationMode: Bool
    let onExitAnnotationMode: () -> Void

    @Query private var allAnnotations: [Annotation]
    @State private var editingAnnotation: Annotation?
    @State private var showEditor: Bool = false
    @State private var annotationZOrder: [UUID] = []

    // Filter annotations for this song
    private var songAnnotations: [Annotation] {
        allAnnotations.filter { $0.song?.id == song.id && $0.type == .stickyNote }
    }

    // Sort annotations by z-order
    private var sortedAnnotations: [Annotation] {
        songAnnotations.sorted { annotation1, annotation2 in
            let index1 = annotationZOrder.firstIndex(of: annotation1.id) ?? Int.max
            let index2 = annotationZOrder.firstIndex(of: annotation2.id) ?? Int.max
            return index1 < index2
        }
    }

    var body: some View {
        ZStack {
            // Tap-to-place overlay (only in annotation mode)
            if isAnnotationMode {
                Color.black.opacity(0.1)
                    .allowsHitTesting(true)
                    .onTapGesture { location in
                        createAnnotation(at: location)
                    }
            }

            // Render all sticky notes
            ForEach(sortedAnnotations) { annotation in
                StickyNoteView(
                    annotation: annotation,
                    containerSize: containerSize,
                    onEdit: {
                        editingAnnotation = annotation
                        showEditor = true
                    },
                    onDelete: {
                        deleteAnnotation(annotation)
                    },
                    onDuplicate: {
                        duplicateAnnotation(annotation)
                    },
                    onBringToFront: {
                        bringToFront(annotation)
                    },
                    onSendToBack: {
                        sendToBack(annotation)
                    },
                    onPositionChange: { x, y in
                        updatePosition(annotation: annotation, x: x, y: y)
                    },
                    onScaleChange: { scale in
                        updateScale(annotation: annotation, scale: scale)
                    },
                    onRotationChange: { rotation in
                        updateRotation(annotation: annotation, rotation: rotation)
                    }
                )
            }

            // Annotation mode banner
            if isAnnotationMode {
                VStack {
                    annotationModeBanner
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let annotation = editingAnnotation {
                StickyNoteEditorView(
                    annotation: annotation,
                    onSave: {
                        // Annotation already saved in editor
                    },
                    onDelete: {
                        deleteAnnotation(annotation)
                    }
                )
            }
        }
        .onAppear {
            loadZOrder()
        }
    }

    private var annotationModeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "note.text.badge.plus")
                .font(.title3)
                .foregroundStyle(.white)

            Text("Tap anywhere to add a sticky note")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Spacer()

            Button {
                onExitAnnotationMode()
            } label: {
                Text("Done")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.9), Color.orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Annotation Management

    private func createAnnotation(at location: CGPoint) {
        // Convert tap location to percentage
        let xPercent = location.x / containerSize.width
        let yPercent = location.y / containerSize.height

        // Create new annotation
        let annotation = Annotation(
            song: song,
            type: .stickyNote,
            x: max(0.0, min(1.0, xPercent)),
            y: max(0.0, min(1.0, yPercent))
        )

        // Set default values
        annotation.text = ""
        annotation.noteColor = StickyNoteColor.yellow.hexColor
        annotation.textColor = StickyNoteColor.yellow.textColor.toHex()
        annotation.fontSize = 14
        annotation.rotation = 0
        annotation.scale = 1.0

        // Insert into database
        modelContext.insert(annotation)

        // Add to z-order (on top)
        annotationZOrder.append(annotation.id)

        do {
            try modelContext.save()

            // Open editor immediately
            editingAnnotation = annotation
            showEditor = true

            HapticManager.shared.success()
        } catch {
            print("Error creating annotation: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func deleteAnnotation(_ annotation: Annotation) {
        // Remove from z-order
        annotationZOrder.removeAll { $0 == annotation.id }

        // Delete from database
        modelContext.delete(annotation)

        do {
            try modelContext.save()
            HapticManager.shared.notification(.warning)
        } catch {
            print("Error deleting annotation: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func duplicateAnnotation(_ annotation: Annotation) {
        // Create duplicate with slight offset
        let newAnnotation = Annotation(
            song: song,
            type: .stickyNote,
            x: min(1.0, annotation.xPosition + 0.05),
            y: min(1.0, annotation.yPosition + 0.05)
        )

        // Copy properties
        newAnnotation.text = annotation.text
        newAnnotation.noteColor = annotation.noteColor
        newAnnotation.textColor = annotation.textColor
        newAnnotation.fontSize = annotation.fontSize
        newAnnotation.rotation = annotation.rotation
        newAnnotation.scale = annotation.scale

        // Insert into database
        modelContext.insert(newAnnotation)

        // Add to z-order (on top)
        annotationZOrder.append(newAnnotation.id)

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("Error duplicating annotation: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func updatePosition(annotation: Annotation, x: Double, y: Double) {
        annotation.xPosition = x
        annotation.yPosition = y
        annotation.modifiedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error updating annotation position: \(error)")
        }
    }

    private func updateScale(annotation: Annotation, scale: Double) {
        annotation.scale = scale
        annotation.modifiedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error updating annotation scale: \(error)")
        }
    }

    private func updateRotation(annotation: Annotation, rotation: Double) {
        annotation.rotation = rotation
        annotation.modifiedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error updating annotation rotation: \(error)")
        }
    }

    private func bringToFront(_ annotation: Annotation) {
        // Remove from current position
        annotationZOrder.removeAll { $0 == annotation.id }

        // Add to end (top)
        annotationZOrder.append(annotation.id)

        saveZOrder()
        HapticManager.shared.selection()
    }

    private func sendToBack(_ annotation: Annotation) {
        // Remove from current position
        annotationZOrder.removeAll { $0 == annotation.id }

        // Add to beginning (bottom)
        annotationZOrder.insert(annotation.id, at: 0)

        saveZOrder()
        HapticManager.shared.selection()
    }

    // MARK: - Z-Order Persistence

    private func loadZOrder() {
        // Load z-order from UserDefaults or use default order
        let key = "annotationZOrder_\(song.id.uuidString)"
        if let data = UserDefaults.standard.data(forKey: key),
           let order = try? JSONDecoder().decode([UUID].self, from: data) {
            annotationZOrder = order
        } else {
            // Default order: sorted by creation date
            annotationZOrder = songAnnotations
                .sorted { $0.createdAt < $1.createdAt }
                .map { $0.id }
        }
    }

    private func saveZOrder() {
        let key = "annotationZOrder_\(song.id.uuidString)"
        if let data = try? JSONEncoder().encode(annotationZOrder) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Gesture Extension

extension View {
    func onTapGesture(perform action: @escaping (CGPoint) -> Void) -> some View {
        self.overlay(
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let location = value.location
                                action(location)
                            }
                    )
            }
        )
    }
}
