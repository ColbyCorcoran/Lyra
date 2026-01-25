//
//  BatchOCRView.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Batch Processing UI
//  Multi-image selection and batch processing
//

import SwiftUI
import PhotosUI
import SwiftData

struct BatchOCRView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var ocrManager: EnhancedOCRManager
    @State private var batchEngine = BatchOCREngine()
    @State private var selectedImages: [UIImage] = []
    @State private var currentJob: BatchOCRJob?
    @State private var showingImagePicker = false
    @State private var isProcessing = false

    init(modelContext: ModelContext) {
        _ocrManager = State(initialValue: EnhancedOCRManager(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let job = currentJob {
                    processingView(job)
                } else if selectedImages.isEmpty {
                    selectionView
                } else {
                    previewView
                }
            }
            .navigationTitle("Batch OCR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if !selectedImages.isEmpty && currentJob == nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Process") {
                            startBatchProcessing()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotosPicker(selection: $selectedImages)
            }
        }
    }

    // MARK: - Selection View

    private var selectionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            Text("Batch OCR Processing")
                .font(.title.bold())

            Text("Process multiple chord chart pages at once with progress tracking")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingImagePicker = true
            } label: {
                Label("Select Images", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "bolt.fill", title: "Parallel processing")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Real-time progress")
                FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Error recovery")
                FeatureRow(icon: "doc.badge.plus", title: "Up to 50 pages")
            }
            .padding()
            .background(.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    // MARK: - Preview View

    private var previewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(selectedImages.count) images selected")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(.black.opacity(0.6), in: Circle())
                                }
                                .padding(4)
                            }
                    }
                }
                .padding(.horizontal)

                Button {
                    showingImagePicker = true
                } label: {
                    Label("Add More Images", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.secondary.opacity(0.1))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Processing View

    private func processingView(_ job: BatchOCRJob) -> some View {
        VStack(spacing: 30) {
            // Status icon
            Image(systemName: job.status.icon)
                .font(.system(size: 60))
                .foregroundStyle(statusColor(job.status))

            // Title
            Text(job.status.displayName)
                .font(.title2.bold())

            // Progress
            if job.status == .processing {
                VStack(spacing: 12) {
                    ProgressView(value: job.progress, total: 1.0)
                        .progressViewStyle(.linear)

                    Text("Page \(job.currentPage) of \(job.totalPages)")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 40)
            }

            // Results
            if job.status == .completed {
                VStack(spacing: 12) {
                    Text("\(job.results.count) pages processed successfully")
                        .font(.headline)

                    if !job.errors.isEmpty {
                        Text("\(job.errors.count) errors")
                            .foregroundStyle(.orange)
                    }

                    Button {
                        saveResults(job)
                    } label: {
                        Label("Save All", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                }
            }

            // Errors
            if !job.errors.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Errors")
                            .font(.headline)

                        ForEach(job.errors) { error in
                            BatchErrorCard(error: error)
                        }
                    }
                    .padding()
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func startBatchProcessing() {
        Task {
            do {
                isProcessing = true
                let job = try await ocrManager.processBatchOCR(images: selectedImages) { progress in
                    // Update progress on main thread
                }
                currentJob = job
                isProcessing = false
            } catch {
                print("Batch processing error: \(error)")
                isProcessing = false
            }
        }
    }

    private func saveResults(_ job: BatchOCRJob) {
        // Save all results as songs
        for result in job.results {
            let song = Song(
                title: "Batch Scan",
                artist: "Unknown",
                content: result.correctedText
            )
            modelContext.insert(song)
        }

        try? modelContext.save()
        dismiss()
    }

    private func statusColor(_ status: BatchStatus) -> Color {
        switch status {
        case .queued: return .blue
        case .processing: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

struct BatchErrorCard: View {
    let error: BatchOCRError

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading) {
                Text("Page \(error.imageIndex + 1)")
                    .font(.headline)
                Text(error.error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if error.recoverable {
                Text("Skipped")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Photos Picker

struct PhotosPicker: UIViewControllerRepresentable {
    @Binding var selection: [UIImage]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotosPicker

        init(_ parent: PhotosPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selection.append(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
