//
//  ScanProcessingView.swift
//  Lyra
//
//  Post-scan processing with OCR and PDF creation
//

import SwiftUI
import SwiftData
import PDFKit

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
                            ForEach(Array(scannedImages.enumerated()), id: \.offset) { index, image in
                                VStack(spacing: 8) {
                                    Image(uiImage: image)
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
                    InfoRow(icon: "doc.text", label: "Pages Scanned", value: "\(scannedImages.count)")

                    if scannedImages.count > 1 {
                        Text("Multi-page scan will be saved as a PDF attachment with combined text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Action buttons
                VStack(spacing: 12) {
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

                    Button {
                        savePDFOnly()
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.arrow.up")
                            Text("Save as PDF Only")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
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
                    // Enhance OCR result by applying format conversion
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

    private func savePDFOnly() {
        Task {
            do {
                // Create PDF from scanned images
                let pdfData = createPDF(from: scannedImages)

                // Create song with PDF attachment
                let song = Song(
                    title: "Scanned Chart \(Date().formatted(date: .abbreviated, time: .shortened))",
                    artist: nil,
                    content: "Scanned document - see PDF attachment",
                    contentFormat: .plainText,
                    originalKey: nil
                )

                song.importSource = "Camera Scan"
                song.importedAt = Date()

                // Create PDF attachment
                let attachment = Attachment(
                    fileName: "scanned-\(Date().timeIntervalSince1970).pdf",
                    fileSize: Int64(pdfData.count),
                    mimeType: "application/pdf",
                    data: pdfData
                )

                song.attachment = attachment
                modelContext.insert(song)
                try modelContext.save()

                await MainActor.run {
                    createdSong = song
                    state = .complete
                    HapticManager.shared.success()
                }

            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save PDF: \(error.localizedDescription)"
                    showError = true
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
            contentFormat: .chordPro, // Already converted by enhanceOCRResult
            originalKey: nil
        )

        song.importSource = "Camera Scan (OCR)"
        song.importedAt = Date()

        // Create PDF attachment from scanned images
        let pdfData = createPDF(from: scannedImages)
        let attachment = Attachment(
            fileName: "scanned-\(Date().timeIntervalSince1970).pdf",
            fileSize: Int64(pdfData.count),
            mimeType: "application/pdf",
            data: pdfData
        )

        song.attachment = attachment

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

    // MARK: - PDF Creation

    private func createPDF(from images: [UIImage]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Lyra",
            kCGPDFContextAuthor: "Scanned by Lyra"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        // Use letter size (8.5 x 11 inches at 72 DPI)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            for image in images {
                context.beginPage()

                // Calculate aspect-fit size
                let imageAspect = image.size.width / image.size.height
                let pageAspect = pageRect.width / pageRect.height

                var drawRect = pageRect
                if imageAspect > pageAspect {
                    // Image is wider - fit to width
                    let scaledHeight = pageRect.width / imageAspect
                    drawRect = CGRect(
                        x: 0,
                        y: (pageRect.height - scaledHeight) / 2,
                        width: pageRect.width,
                        height: scaledHeight
                    )
                } else {
                    // Image is taller - fit to height
                    let scaledWidth = pageRect.height * imageAspect
                    drawRect = CGRect(
                        x: (pageRect.width - scaledWidth) / 2,
                        y: 0,
                        width: scaledWidth,
                        height: pageRect.height
                    )
                }

                image.draw(in: drawRect)
            }
        }

        return data
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
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
