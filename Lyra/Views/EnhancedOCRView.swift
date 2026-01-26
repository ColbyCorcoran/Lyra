//
//  EnhancedOCRView.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Main OCR Interface
//  Camera/photo picker with real-time processing
//

import SwiftUI
import PhotosUI
import SwiftData

struct EnhancedOCRView: View {

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var ocrManager: EnhancedOCRManager
    @State private var selectedImage: UIImage?
    @State private var ocrResult: EnhancedOCRResult?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var showingReviewEditor = false
    @State private var useHandwriting = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        _ocrManager = State(initialValue: EnhancedOCRManager(modelContext: modelContext))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if let result = ocrResult {
                    resultView(result)
                } else {
                    initialView
                }

                if isProcessing {
                    processingOverlay
                }
            }
            .navigationTitle("Enhanced OCR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if ocrResult != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Review") {
                            showingReviewEditor = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                    .onDisappear {
                        if let image = selectedImage {
                            processImage(image)
                        }
                    }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
                    .onDisappear {
                        if let image = selectedImage {
                            processImage(image)
                        }
                    }
            }
            .sheet(isPresented: $showingReviewEditor) {
                if let result = ocrResult {
                    OCRReviewEditor(result: result) { corrected in
                        ocrResult = corrected
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Initial View

    private var initialView: some View {
        VStack(spacing: 30) {
            // Icon
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            // Title
            Text("Enhanced OCR")
                .font(.title.bold())

            Text("AI-powered chord chart recognition with handwriting support")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Options
            Toggle("Handwriting Recognition", isOn: $useHandwriting)
                .padding(.horizontal, 40)

            // Action Buttons
            VStack(spacing: 15) {
                Button {
                    showingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingImagePicker = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)

            // Features
            VStack(alignment: .leading, spacing: 12) {
                OCRFeatureRow(icon: "brain", title: "ML-based recognition")
                OCRFeatureRow(icon: "hand.draw", title: "Handwriting support")
                OCRFeatureRow(icon: "music.note.list", title: "Music theory validation")
                OCRFeatureRow(icon: "doc.on.doc", title: "Multi-page stitching")
            }
            .padding()
            .background(.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    // MARK: - Result View

    private func resultView(_ result: EnhancedOCRResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Confidence Indicator
                OCRQualityIndicator(confidence: result.confidenceBreakdown)
                    .padding(.horizontal)

                // Image Preview
                if let imageData = result.enhancedImage,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }

                // Recognized Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recognized Text")
                        .font(.headline)

                    Text(result.correctedText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)

                // Layout Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Layout")
                        .font(.headline)

                    HStack {
                        Label(result.layoutStructure.layoutType.description, systemImage: "text.alignleft")
                        Spacer()
                        Text("\(result.layoutStructure.sections.count) sections")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)

                // Review Items
                if !result.reviewItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review Required")
                            .font(.headline)

                        ForEach(result.reviewItems) { item in
                            ReviewItemCard(item: item)
                        }
                    }
                    .padding(.horizontal)
                }

                // Processing Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Processing Info")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        OCRInfoRow(label: "Engine", value: result.processingMetadata.engineUsed)
                        OCRInfoRow(label: "Time", value: String(format: "%.2fs", result.processingMetadata.processingTime))
                        OCRInfoRow(label: "Pages", value: "\(result.processingMetadata.pageCount)")
                        if !result.processingMetadata.enhancementsApplied.isEmpty {
                            OCRInfoRow(label: "Enhancements", value: result.processingMetadata.enhancementsApplied.joined(separator: ", "))
                        }
                    }
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showingReviewEditor = true
                    } label: {
                        Label("Review & Correct", systemImage: "pencil.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        saveSong(from: result)
                    } label: {
                        Label("Save as Song", systemImage: "music.note")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        // Start new scan
                        ocrResult = nil
                        selectedImage = nil
                    } label: {
                        Label("Scan Another", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView(value: processingProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 200)

                Text("Processing...")
                    .font(.headline)

                Text(processingStage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(30)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var processingStage: String {
        if processingProgress < 0.2 {
            return "Enhancing image..."
        } else if processingProgress < 0.4 {
            return "Recognizing text..."
        } else if processingProgress < 0.6 {
            return "Analyzing layout..."
        } else if processingProgress < 0.8 {
            return "Validating chords..."
        } else {
            return "Finalizing..."
        }
    }

    // MARK: - Helper Methods

    private func processImage(_ image: UIImage) {
        Task {
            isProcessing = true
            errorMessage = nil

            do {
                let options = ProcessingOptions(
                    useHandwritingRecognition: useHandwriting,
                    userId: "default",
                    detectedKey: nil,
                    enableCaching: true
                )

                // Process with progress updates
                let result = try await ocrManager.processEnhancedOCR(image: image, options: options)

                // Update UI on main thread
                await MainActor.run {
                    ocrResult = result
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }

    private func saveSong(from result: EnhancedOCRResult) {
        // Create new song from OCR result
        let newSong = Song(
            title: "Scanned Song",
            artist: "Unknown",
            chordProContent: result.correctedText,
            originalKey: nil
        )

        modelContext.insert(newSong)
        try? modelContext.save()

        dismiss()
    }
}

// MARK: - Supporting Views

private struct OCRFeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            Text(title)
                .font(.subheadline)
        }
    }
}

private struct OCRInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
        .font(.subheadline)
    }
}

struct ReviewItemCard: View {
    let item: ReviewItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.originalText)
                    .font(.headline)

                Text(item.correctionReason)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let suggestion = item.suggestedCorrection {
                    Text("Suggested: \(suggestion)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            Text("\(Int(item.confidence * 100))%")
                .font(.caption.bold())
                .foregroundStyle(item.confidence > 0.7 ? .green : .orange)
        }
        .padding()
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
