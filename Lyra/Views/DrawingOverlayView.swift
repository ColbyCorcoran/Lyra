//
//  DrawingOverlayView.swift
//  Lyra
//
//  PencilKit drawing overlay for song annotations
//

import SwiftUI
import PencilKit
import SwiftData

struct DrawingOverlayView: View {
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let containerSize: CGSize
    let isDrawingMode: Bool
    let onExitDrawingMode: () -> Void

    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: DrawingColor = .black
    @State private var lineThickness: DrawingThickness = .medium
    @State private var canUndo: Bool = false
    @State private var canRedo: Bool = false
    @State private var drawingAnnotation: Annotation?
    @State private var pkCanvasViewProxy: PKCanvasViewProxy?

    @Query private var allAnnotations: [Annotation]

    // Get drawing annotation for this song
    private var songDrawingAnnotation: Annotation? {
        allAnnotations.first { $0.song?.id == song.id && $0.type == .drawing }
    }

    var body: some View {
        ZStack {
            if isDrawingMode {
                // PencilKit Canvas
                PKCanvasViewWrapper(
                    drawing: Binding(
                        get: { loadDrawing() },
                        set: { saveDrawing($0) }
                    ),
                    tool: pkTool,
                    isDrawingMode: isDrawingMode,
                    canUndo: $canUndo,
                    canRedo: $canRedo,
                    proxy: $pkCanvasViewProxy
                )
                .allowsHitTesting(true)

                // Drawing toolbar (at bottom)
                VStack {
                    Spacer()

                    DrawingToolbarView(
                        selectedTool: $selectedTool,
                        selectedColor: $selectedColor,
                        lineThickness: $lineThickness,
                        canUndo: $canUndo,
                        canRedo: $canRedo,
                        onUndo: {
                            pkCanvasViewProxy?.undo()
                        },
                        onRedo: {
                            pkCanvasViewProxy?.redo()
                        },
                        onClear: {
                            clearAllDrawings()
                        },
                        onDone: {
                            onExitDrawingMode()
                        }
                    )
                }
            }
        }
        .onAppear {
            loadOrCreateDrawingAnnotation()
        }
    }

    // MARK: - Drawing Management

    private func loadOrCreateDrawingAnnotation() {
        if let existing = songDrawingAnnotation {
            drawingAnnotation = existing
        } else {
            // Create new drawing annotation
            let annotation = Annotation(
                song: song,
                type: .drawing,
                x: 0.0,
                y: 0.0
            )
            annotation.drawingData = PKDrawing().dataRepresentation()
            modelContext.insert(annotation)

            do {
                try modelContext.save()
                drawingAnnotation = annotation
            } catch {
                print("Error creating drawing annotation: \(error)")
            }
        }
    }

    private func loadDrawing() -> PKDrawing {
        guard let data = drawingAnnotation?.drawingData else {
            return PKDrawing()
        }

        do {
            return try PKDrawing(data: data)
        } catch {
            print("Error loading drawing: \(error)")
            return PKDrawing()
        }
    }

    private func saveDrawing(_ drawing: PKDrawing) {
        guard let annotation = drawingAnnotation else { return }

        annotation.drawingData = drawing.dataRepresentation()
        annotation.modifiedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error saving drawing: \(error)")
        }
    }

    private func clearAllDrawings() {
        guard let annotation = drawingAnnotation else { return }

        annotation.drawingData = PKDrawing().dataRepresentation()
        annotation.modifiedAt = Date()

        do {
            try modelContext.save()
            pkCanvasViewProxy?.setDrawing(PKDrawing())
            HapticManager.shared.notification(.warning)
        } catch {
            print("Error clearing drawings: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    // MARK: - PencilKit Tool Configuration

    private var pkTool: PKTool {
        if selectedTool == .eraser {
            return PKEraserTool(.vector)
        } else {
            let inkType = selectedTool.pkInkingToolType
            let color = UIColor(selectedColor.uiColor)
            let width = lineThickness.width

            return PKInkingTool(inkType, color: color, width: width)
        }
    }
}

// MARK: - PKCanvasView Wrapper

class PKCanvasViewProxy {
    weak var canvasView: PKCanvasView?

    func undo() {
        canvasView?.undoManager?.undo()
    }

    func redo() {
        canvasView?.undoManager?.redo()
    }

    func setDrawing(_ drawing: PKDrawing) {
        canvasView?.drawing = drawing
    }

    var canUndo: Bool {
        canvasView?.undoManager?.canUndo ?? false
    }

    var canRedo: Bool {
        canvasView?.undoManager?.canRedo ?? false
    }
}

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var tool: PKTool
    var isDrawingMode: Bool
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    @Binding var proxy: PKCanvasViewProxy?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()

        // Configure canvas
        canvasView.drawingPolicy = .anyInput // Support Apple Pencil and finger
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawing = drawing
        canvasView.tool = tool

        // Set up undo manager
        canvasView.undoManager?.levelsOfUndo = 100

        // Add observer for drawing changes
        canvasView.delegate = context.coordinator

        // Create and store proxy
        let canvasProxy = PKCanvasViewProxy()
        canvasProxy.canvasView = canvasView
        DispatchQueue.main.async {
            proxy = canvasProxy
        }

        // Start observing undo/redo state
        context.coordinator.startObserving(canvasView)

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        // Update tool
        canvasView.tool = tool

        // Update drawing if changed externally
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }

        // Update undo/redo state
        DispatchQueue.main.async {
            canUndo = canvasView.undoManager?.canUndo ?? false
            canRedo = canvasView.undoManager?.canRedo ?? false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PKCanvasViewWrapper
        private var undoObserver: Any?
        private var redoObserver: Any?

        init(_ parent: PKCanvasViewWrapper) {
            self.parent = parent
        }

        func startObserving(_ canvasView: PKCanvasView) {
            guard let undoManager = canvasView.undoManager else { return }

            // Observe undo/redo changes
            undoObserver = NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidUndoChange,
                object: undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.updateUndoRedoState(canvasView)
            }

            redoObserver = NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidRedoChange,
                object: undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.updateUndoRedoState(canvasView)
            }
        }

        private func updateUndoRedoState(_ canvasView: PKCanvasView) {
            DispatchQueue.main.async {
                self.parent.canUndo = canvasView.undoManager?.canUndo ?? false
                self.parent.canRedo = canvasView.undoManager?.canRedo ?? false
            }
        }

        deinit {
            if let observer = undoObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = redoObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        // MARK: - PKCanvasViewDelegate

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Save drawing when it changes
            parent.drawing = canvasView.drawing

            // Update undo/redo state
            updateUndoRedoState(canvasView)

            // Haptic feedback
            HapticManager.shared.selection()
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var isDrawingMode = true

        var body: some View {
            ZStack {
                Color.white

                Text("Sample Song Content\nwith multiple lines\nfor drawing on")
                    .font(.system(size: 20))
                    .multilineTextAlignment(.center)

                DrawingOverlayView(
                    song: Song(title: "Test Song", content: "Test"),
                    containerSize: CGSize(width: 400, height: 600),
                    isDrawingMode: isDrawingMode,
                    onExitDrawingMode: {
                        isDrawingMode = false
                    }
                )
            }
        }
    }

    return PreviewWrapper()
        .modelContainer(for: [Song.self, Annotation.self])
}
