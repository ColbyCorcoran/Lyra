//
//  ExportOptionsView.swift
//  Lyra
//
//  View for selecting export format and options
//

import SwiftUI
import SwiftData

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss

    let exportType: ExportType
    let onExport: (ExportManager.ExportFormat, PDFExporter.PDFConfiguration) -> Void

    @State private var selectedFormat: ExportManager.ExportFormat = .pdf
    @State private var isExporting: Bool = false
    @State private var exportError: Error?
    @State private var showError: Bool = false

    // PDF Configuration
    @State private var includeHeader: Bool = true
    @State private var includeFooter: Bool = true
    @State private var footerText: String = "Created with Lyra"

    enum ExportType {
        case song(Song)
        case set(PerformanceSet)
        case book(Book)
        case library(songs: [Song], books: [Book], sets: [PerformanceSet])

        var title: String {
            switch self {
            case .song: return "Export Song"
            case .set: return "Export Set"
            case .book: return "Export Book"
            case .library: return "Export Library"
            }
        }

        var icon: String {
            switch self {
            case .song: return "music.note"
            case .set: return "list.bullet.rectangle"
            case .book: return "book"
            case .library: return "square.stack.3d.up"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Format Selection
                Section {
                    ForEach(ExportManager.ExportFormat.allCases, id: \.self) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            HStack {
                                Image(systemName: format.icon)
                                    .foregroundStyle(selectedFormat == format ? .blue : .primary)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.rawValue)
                                        .foregroundStyle(selectedFormat == format ? .blue : .primary)
                                        .fontWeight(selectedFormat == format ? .semibold : .regular)

                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Export Format")
                } footer: {
                    Text("Choose the format for your exported file")
                }

                // PDF Configuration (only for PDF format)
                if selectedFormat == .pdf {
                    Section("PDF Options") {
                        Toggle(isOn: $includeHeader) {
                            Label("Include Header", systemImage: "text.insert")
                        }

                        Toggle(isOn: $includeFooter) {
                            Label("Include Footer", systemImage: "text.below.photo")
                        }

                        if includeFooter {
                            TextField("Footer Text", text: $footerText)
                        }
                    }
                }

                // Export Info
                Section {
                    HStack {
                        Image(systemName: exportType.icon)
                            .foregroundStyle(.blue)
                        Text("Type")
                        Spacer()
                        Text(exportType.title)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "doc")
                            .foregroundStyle(.blue)
                        Text("File Extension")
                        Spacer()
                        Text(".\(selectedFormat.fileExtension)")
                            .foregroundStyle(.secondary)
                            .monospaced()
                    }
                } header: {
                    Text("Export Info")
                }
            }
            .navigationTitle(exportType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        performExport()
                    }
                    .fontWeight(.semibold)
                    .disabled(isExporting)
                }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Actions

    private func performExport() {
        isExporting = true

        // Create PDF configuration
        var configuration = PDFExporter.PDFConfiguration()
        configuration.includeHeader = includeHeader
        configuration.includeFooter = includeFooter
        configuration.footerText = footerText

        // Call export handler
        onExport(selectedFormat, configuration)

        // Dismiss
        dismiss()
    }
}

// MARK: - Preview

#Preview("Export Song") {
    ExportOptionsView(
        exportType: .song(PreviewContainer.shared.context.fetchAll(Song.self).first!),
        onExport: { _, _ in }
    )
}

// MARK: - ModelContext Extension

extension ModelContext {
    func fetchAll<T: PersistentModel>(_ type: T.Type) -> [T] {
        let descriptor = FetchDescriptor<T>()
        return (try? fetch(descriptor)) ?? []
    }
}
