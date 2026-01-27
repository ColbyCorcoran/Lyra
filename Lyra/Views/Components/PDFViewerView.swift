//
//  PDFViewerView.swift
//  Lyra
//
//  PDF viewer using PDFKit for displaying PDF attachments
//

import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
#endif

struct PDFViewerView: View {
    let pdfDocument: PDFDocument
    let filename: String
    var lowLightManager: LowLightModeManager? = nil

    @State private var currentPage: Int = 0
    @State private var scaleMode: PDFDisplayMode = .singlePageContinuous
    @State private var showShareSheet: Bool = false
    @State private var pdfData: Data?

    @Environment(\.dismiss) private var dismiss

    private var pageCount: Int {
        pdfDocument.pageCount
    }

    var body: some View {
        VStack(spacing: 0) {
            // PDF View
            PDFKitView(
                document: pdfDocument,
                currentPage: $currentPage,
                scaleMode: $scaleMode,
                lowLightManager: lowLightManager
            )
            .edgesIgnoringSafeArea(.all)
            .background(lowLightManager?.isEnabled == true ? Color.black : Color.clear)

            // Page indicator and controls
            if pageCount > 1 {
                pageIndicator
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
            }
        }
        .navigationTitle(filename)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Zoom controls
                    Section("Zoom") {
                        Button {
                            scaleMode = .singlePageContinuous
                        } label: {
                            Label("Fit to Width", systemImage: "arrow.left.and.right")
                        }

                        Button {
                            scaleMode = .singlePage
                        } label: {
                            Label("Fit to Page", systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                    }

                    // Actions
                    Section {
                        Button {
                            preparePDFForSharing()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            printPDF()
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("PDF Options")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
    }

    // MARK: - Page Indicator

    @ViewBuilder
    private var pageIndicator: some View {
        HStack(spacing: 16) {
            // Previous page button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    goToPreviousPage()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .disabled(currentPage == 0)
            .opacity(currentPage == 0 ? 0.4 : 1.0)
            .accessibilityLabel("Previous page")

            // Page number
            Text("Page \(currentPage + 1) of \(pageCount)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .accessibilityLabel("Page \(currentPage + 1) of \(pageCount)")

            // Next page button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    goToNextPage()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .disabled(currentPage >= pageCount - 1)
            .opacity(currentPage >= pageCount - 1 ? 0.4 : 1.0)
            .accessibilityLabel("Next page")
        }
    }

    // MARK: - Actions

    private func goToPreviousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
        HapticManager.shared.selection()
    }

    private func goToNextPage() {
        guard currentPage < pageCount - 1 else { return }
        currentPage += 1
        HapticManager.shared.selection()
    }

    private func preparePDFForSharing() {
        pdfData = pdfDocument.dataRepresentation()
        showShareSheet = true
    }

    private func printPDF() {
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = filename

        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = pdfDocument.dataRepresentation()

        printController.present(animated: true) { _, success, error in
            if success {
                HapticManager.shared.success()
            } else if let error = error {
                print("❌ Print failed: \(error.localizedDescription)")
                HapticManager.shared.operationFailed()
            }
        }
    }
}

// MARK: - PDFKit UIView Wrapper

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var scaleMode: PDFDisplayMode
    var lowLightManager: LowLightModeManager? = nil

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Configure PDF view
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = scaleMode
        pdfView.displayDirection = .vertical

        // Apply low light mode if enabled
        if let manager = lowLightManager, manager.isEnabled {
            pdfView.backgroundColor = .black
            // Apply color filter to tint PDF content
            applyLowLightFilter(to: pdfView, manager: manager)
        } else {
            pdfView.backgroundColor = .systemBackground
        }

        // Enable interactions
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 4.0

        // Page change notification
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let page = pdfView.currentPage {
                let pageIndex = document.index(for: page)
                DispatchQueue.main.async {
                    currentPage = pageIndex
                }
            }
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update display mode if changed
        if pdfView.displayMode != scaleMode {
            pdfView.displayMode = scaleMode

            // Adjust scale based on mode
            if scaleMode == .singlePageContinuous {
                pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
            }
        }

        // Update current page if changed externally
        if let currentPDFPage = pdfView.currentPage {
            let currentIndex = document.index(for: currentPDFPage)
            if currentIndex != currentPage {
                if let targetPage = document.page(at: currentPage) {
                    pdfView.go(to: targetPage)
                }
            }
        }

        // Update low light mode
        if let manager = lowLightManager {
            if manager.isEnabled {
                pdfView.backgroundColor = .black
                applyLowLightFilter(to: pdfView, manager: manager)
            } else {
                pdfView.backgroundColor = .systemBackground
                removeLowLightFilter(from: pdfView)
            }
        }
    }

    private func applyLowLightFilter(to pdfView: PDFView, manager: LowLightModeManager) {
        // Apply low-light tint using background color
        let intensity = CGFloat(manager.intensity)
        pdfView.backgroundColor = manager.color.uiColor.withAlphaComponent(intensity * 0.3)
    }

    private func removeLowLightFilter(from pdfView: PDFView) {
        pdfView.backgroundColor = .systemBackground
    }
}

// MARK: - Share Sheet

#if canImport(UIKit)
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Preview

#Preview("PDF Viewer") {
    NavigationStack {
        if let samplePDF = createSamplePDF() {
            PDFViewerView(pdfDocument: samplePDF, filename: "Sample Chart.pdf")
        } else {
            Text("Unable to create sample PDF")
        }
    }
}

// Helper for preview
private func createSamplePDF() -> PDFDocument? {
    let format = UIGraphicsPDFRendererFormat()
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size

    let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

    let data = renderer.pdfData { context in
        // Page 1
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

        // Page 2
        context.beginPage()
        let page2Text = "Page 2 - Chorus"
        page2Text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
    }

    return PDFDocument(data: data)
}
