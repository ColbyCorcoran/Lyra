//
//  ExtractTextFromPDFView.swift
//  Lyra
//
//  View for extracting and converting PDF text to editable song content
//

import SwiftUI
import SwiftData
import PDFKit

enum ExtractionState {
    case initial
    case extracting
    case preview
    case error
}

struct ExtractTextFromPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let pdfDocument: PDFDocument
    let song: Song

    @State private var extractionState: ExtractionState = .initial
    @State private var extractedText: String = ""
    @State private var editedText: String = ""
    @State private var extractionProgress: Double = 0.0
    @State private var progressMessage: String = ""
    @State private var extractionMethod: PDFExtractionResult.ExtractionMethod = .embedded
    @State private var errorMessage: String = ""
    @State private var showOCROptions: Bool = false
    @State private var useOCR: Bool = false
    @State private var pageLimit: Int?
    @State private var isScannedPDF: Bool = false

    private var pageCount: Int {
        pdfDocument.pageCount
    }

    private var hasEmbeddedText: Bool {
        PDFTextExtractor.hasEmbeddedText(pdfDocument)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch extractionState {
                case .initial:
                    initialView
                case .extracting:
                    extractingView
                case .preview:
                    previewView
                case .error:
                    errorView
                }
            }
            .navigationTitle("Extract Text from PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if extractionState == .preview {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            saveTextToSong()
                        }
                        .fontWeight(.semibold)
                        .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .onAppear {
                checkPDFType()
            }
        }
    }

    // MARK: - Initial View

    @ViewBuilder
    private var initialView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 40)
                    .accessibilityHidden(true)

                // Title and description
                VStack(spacing: 12) {
                    Text("Extract Text from PDF")
                        .font(.title2)
                        .fontWeight(.bold)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

                    Text("Convert your PDF chord chart to editable text")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                .accessibilityElement(children: .combine)

                // Info cards
                VStack(spacing: 16) {
                    InfoCard(
                        icon: "doc.text",
                        title: hasEmbeddedText ? "Embedded Text Detected" : "No Embedded Text",
                        description: hasEmbeddedText
                            ? "This PDF has searchable text that can be extracted quickly."
                            : "This appears to be a scanned image. OCR will be used.",
                        color: hasEmbeddedText ? .green : .orange
                    )

                    InfoCard(
                        icon: "number",
                        title: "\(pageCount) Page\(pageCount == 1 ? "" : "s")",
                        description: pageCount == 1
                            ? "Single page document"
                            : "Multi-page document. You can extract all pages or just the first.",
                        color: .blue
                    )

                    if !hasEmbeddedText {
                        InfoCard(
                            icon: "clock",
                            title: "Estimated Time",
                            description: "OCR will take approximately \(PDFTextExtractor.estimateOCRTime(pageCount: pageLimit ?? pageCount))",
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal)

                // OCR Options (if needed)
                if !hasEmbeddedText || showOCROptions {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OCR Options")
                            .font(.headline)
                            .padding(.horizontal)

                        if pageCount > 1 {
                            Picker("Pages to Process", selection: $pageLimit) {
                                Text("First page only").tag(1 as Int?)
                                Text("First 3 pages").tag(min(3, pageCount) as Int?)
                                Text("All \(pageCount) pages").tag(nil as Int?)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                        }

                        if hasEmbeddedText {
                            Toggle("Force OCR (ignore embedded text)", isOn: $useOCR)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        startExtraction()
                    } label: {
                        HStack {
                            Image(systemName: hasEmbeddedText && !useOCR ? "text.magnifyingglass" : "viewfinder")
                            Text(hasEmbeddedText && !useOCR ? "Extract Text" : "Start OCR")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel(hasEmbeddedText && !useOCR ? "Extract embedded text" : "Start OCR text recognition")

                    if hasEmbeddedText && !showOCROptions {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showOCROptions = true
                                useOCR = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Use OCR Instead")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel("Use OCR instead of embedded text")
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Extracting View

    @ViewBuilder
    private var extractingView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: extractionProgress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: extractionProgress)

                VStack(spacing: 4) {
                    Text("\(Int(extractionProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)

                    Image(systemName: useOCR ? "viewfinder" : "doc.text")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Status message
            VStack(spacing: 8) {
                Text(useOCR ? "Recognizing Text..." : "Extracting Text...")
                    .font(.headline)

                Text(progressMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Preview View

    @ViewBuilder
    private var previewView: some View {
        VStack(spacing: 0) {
            // Extraction info banner
            HStack(spacing: 12) {
                Image(systemName: extractionMethod == .embedded ? "doc.text" : "viewfinder")
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(extractionMethod == .embedded ? "Embedded Text" : "OCR Text")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("Extracted successfully. Edit as needed.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()
            }
            .padding()
            .background(extractionMethod == .embedded ? Color.green : Color.blue)

            // Editable text area
            TextEditor(text: $editedText)
                .font(.system(size: 14, design: .monospaced))
                .padding(12)
                .accessibilityLabel("Extracted text editor")
                .accessibilityHint("Edit the extracted text before saving")

            // Character count
            HStack {
                Image(systemName: "character")
                    .font(.caption)
                Text("\(editedText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    reprocessText()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reformat")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Text("Extraction Failed")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                extractionState = .initial
                errorMessage = ""
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Try Again")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func checkPDFType() {
        isScannedPDF = !hasEmbeddedText
        if pageCount > 1 && !hasEmbeddedText {
            pageLimit = 1 // Default to first page for scanned multi-page PDFs
        }
    }

    private func startExtraction() {
        extractionState = .extracting
        extractionProgress = 0.0

        Task {
            do {
                let result = try await PDFTextExtractor.extractText(
                    from: pdfDocument,
                    useOCR: useOCR || !hasEmbeddedText,
                    pageLimit: pageLimit,
                    progress: { @MainActor progress, message in
                        self.extractionProgress = progress
                        self.progressMessage = message
                    }
                )

                await MainActor.run {
                    extractedText = result.text
                    extractionMethod = result.method

                    // Process to ChordPro format
                    editedText = PDFTextExtractor.processToChordPro(
                        result.text,
                        title: song.title,
                        artist: song.artist
                    )

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        extractionState = .preview
                    }

                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    extractionState = .error
                    HapticManager.shared.operationFailed()
                }
            }
        }
    }

    private func reprocessText() {
        editedText = PDFTextExtractor.processToChordPro(
            extractedText,
            title: song.title,
            artist: song.artist
        )
        HapticManager.shared.selection()
    }

    private func saveTextToSong() {
        // Update song content
        song.content = editedText
        song.contentFormat = .chordPro
        song.modifiedAt = Date()

        // Save to database
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("❌ Error saving extracted text: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
            errorMessage = "Failed to save text: \(error.localizedDescription)"
            extractionState = .error
        }
    }
}

// MARK: - Info Card Component

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}

// MARK: - Preview

#Preview("Embedded Text PDF") {
    ExtractTextFromPDFView(
        pdfDocument: createSamplePDF()!,
        song: Song(title: "Sample Song", artist: "Artist Name")
    )
    .modelContainer(PreviewContainer.shared.container)
}

private func createSamplePDF() -> PDFDocument? {
    let format = UIGraphicsPDFRendererFormat()
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

    let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

    let data = renderer.pdfData { context in
        context.beginPage()
        let title = "Sample Chord Chart"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        title.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)

        let content = """
        Verse 1:
        C              G
        Amazing grace how sweet the sound
        Am            F
        That saved a wretch like me
        """
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        ]
        content.draw(in: CGRect(x: 50, y: 100, width: 500, height: 600), withAttributes: contentAttributes)
    }

    return PDFDocument(data: data)
}
