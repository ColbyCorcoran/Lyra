//
//  ScanProcessingView.swift
//  Lyra
//
//  Post-scan processing with OCR
//

import SwiftUI
import SwiftData

enum ScanProcessingState {
    case reviewing
    case performingOCR
    case editingText
    case complete
}

struct ScanProcessingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let scannedImages: [UIImage]

    @State private var state: ScanProcessingState = .reviewing
    @State private var extractedText: String = ""
    @State private var ocrConfidence: Float = 0.0
    @State private var isProcessing: Bool = false
    @State private var ocrProgress: Double = 0.0
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var createdSong: Song?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch state {
                case .reviewing:
                    reviewingView
                case .performingOCR:
                    processingView
                case .editingText:
                    editingView
                case .complete:
                    completeView
                }
            }
            .navigationTitle("Scanned Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if state != .performingOCR {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                if state == .editingText {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            saveSong()
                        }
                        .fontWeight(.semibold)
                        .disabled(extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .alert("OCR Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Reviewing View

    @ViewBuilder
    private var reviewingView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview images
                VStack(spacing: 12) {
                    Text("Scanned Pages")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(scannedImages.indices, id: \.self) { index in
                                VStack(spacing: 8) {
                                    Image(uiImage: scannedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: Color.black.opacity(0.2), radius: 4)

                                    Text("Page \(index + 1)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Info
                VStack(spacing: 16) {
                    ScanInfoRow(icon: "doc.text", label: "Pages Scanned", value: "\(scannedImages.count)")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Action button
                Button {
                    startOCR()
                } label: {
                    HStack {
                        Image(systemName: "doc.text.viewfinder")
                        Text("Extract Text with OCR")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Processing View

    @ViewBuilder
    private var processingView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: ocrProgress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: ocrProgress)

                VStack(spacing: 4) {
                    Text("\(Int(ocrProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Status
            VStack(spacing: 8) {
                Text("Extracting Text...")
                    .font(.headline)

                Text("Using Vision framework to recognize text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Editing View

    @ViewBuilder
    private var editingView: some View {
        VStack(spacing: 0) {
            // OCR Quality Badge
            HStack(spacing: 12) {
                Image(systemName: ocrQuality.icon)
                    .foregroundStyle(Color(ocrQuality.color))

                VStack(alignment: .leading, spacing: 2) {
                    Text("OCR Quality: \(ocrQuality.description)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(Int(ocrConfidence * 100))% confidence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))

            // Text editor
            TextEditor(text: $extractedText)
                .font(.system(.body, design: .monospaced))
                .padding()

            // Help text
            Text("Review and edit the extracted text before saving. OCR may have missed some chords or formatting.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.systemGray6))
        }
    }

    // MARK: - Complete View

    @ViewBuilder
    private var completeView: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .padding(.top, 60)

            VStack(spacing: 16) {
                Text("Scan Complete")
                    .font(.title2)
                    .fontWeight(.bold)

                if let song = createdSong {
                    Text("Successfully saved \"\(song.title)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - OCR Quality

    private var ocrQuality: OCRProcessor.OCRQuality {
        OCRProcessor.shared.estimateQuality(OCRResult(
            text: extractedText,
            confidence: ocrConfidence,
            recognizedBlocks: []
        ))
    }

    // MARK: - Actions

    private func startOCR() {
        state = .performingOCR
        isProcessing = true

        Task {
            do {
                let result = try await OCRProcessor.shared.extractText(from: scannedImages) { progress in
                    ocrProgress = progress
                }

                await MainActor.run {
                    extractedText = OCRProcessor.shared.enhanceOCRResult(result.text)
                    ocrConfidence = result.confidence
                    state = .editingText
                    isProcessing = false
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    state = .reviewing
                    isProcessing = false
                    HapticManager.shared.operationFailed()
                }
            }
        }
    }

    private func saveSong() {
        // Parse the text to extract title
        let lines = extractedText.components(separatedBy: .newlines)
        let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? "Scanned Chart"

        // Create song
        let song = Song(
            title: firstLine.trimmingCharacters(in: .whitespaces),
            artist: nil,
            content: extractedText,
            contentFormat: .chordPro,
            originalKey: nil
        )

        song.importSource = "Camera Scan (OCR)"
        song.importedAt = Date()

        // Insert and save
        modelContext.insert(song)

        do {
            try modelContext.save()
            createdSong = song
            state = .complete
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to save song: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Info Row Component

private struct ScanInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - OCR Quality Extension

extension OCRProcessor.OCRQuality {
    var icon: String {
        switch self {
        case .excellent:
            return "checkmark.circle.fill"
        case .good:
            return "checkmark.circle"
        case .fair:
            return "exclamationmark.circle"
        case .poor:
            return "xmark.circle"
        }
    }
}

// MARK: - Preview

#Preview {
    ScanProcessingView(scannedImages: [UIImage(systemName: "doc.text")!])
        .modelContainer(PreviewContainer.shared.container)
}
