//
//  TemplateImportView.swift
//  Lyra
//
//  Template import UI with document picker
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TemplateImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var templateName: String = ""
    @State private var selectedFormat: ImportFormat = .pdf
    @State private var isImporting: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var importProgress: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var errorRecoverySuggestion: String = ""
    @State private var importedTemplate: Template?
    @State private var showPreview: Bool = false

    private var canImport: Bool {
        !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isImporting
    }

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection

                formatSelectionSection

                importButtonSection

                if isImporting {
                    progressSection
                }
            }
            .navigationTitle("Import Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.selection()
                        dismiss()
                    }
                    .disabled(isImporting)
                }
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: allowedContentTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result)
            }
            .sheet(isPresented: $showPreview) {
                if let template = importedTemplate {
                    NavigationStack {
                        TemplateEditorView(template: template)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") {
                                        // Delete the template if user cancels
                                        modelContext.delete(template)
                                        try? modelContext.save()
                                        HapticManager.shared.selection()
                                        showPreview = false
                                        importedTemplate = nil
                                        dismiss()
                                    }
                                }

                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Import") {
                                        // Template is already saved, just dismiss
                                        HapticManager.shared.saveSuccess()
                                        showPreview = false
                                        importedTemplate = nil
                                        dismiss()
                                    }
                                }
                            }
                    }
                }
            }
            .alert("Import Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {
                    HapticManager.shared.selection()
                }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(errorMessage)
                    if !errorRecoverySuggestion.isEmpty {
                        Text(errorRecoverySuggestion)
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section {
            TextField("Template Name", text: $templateName)
                .autocorrectionDisabled()
                .disabled(isImporting)
        } header: {
            Text("Basic Information")
        } footer: {
            Text("Give your imported template a descriptive name.")
        }
    }

    private var formatSelectionSection: some View {
        Section {
            Picker("Import Format", selection: $selectedFormat) {
                ForEach(ImportFormat.allCases) { format in
                    HStack {
                        Image(systemName: format.iconName)
                        Text(format.displayName)
                    }
                    .tag(format)
                }
            }
            .pickerStyle(.menu)
            .disabled(isImporting)
        } header: {
            Text("Document Format")
        } footer: {
            Text(selectedFormat.description)
        }
    }

    private var importButtonSection: some View {
        Section {
            Button {
                initiateImport()
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "square.and.arrow.down")
                    Text("Choose Document")
                    Spacer()
                }
                .foregroundStyle(canImport ? .blue : .secondary)
            }
            .disabled(!canImport)
        } footer: {
            Text("Select a document to analyze and extract template settings.")
        }
    }

    private var progressSection: some View {
        Section {
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Importing Template")
                        .font(.headline)

                    if !importProgress.isEmpty {
                        Text(importProgress)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Computed Properties

    private var allowedContentTypes: [UTType] {
        switch selectedFormat {
        case .pdf:
            return [.pdf]
        case .word:
            return [.rtf, UTType(filenameExtension: "docx") ?? .data]
        case .plainText:
            return [.plainText, .text]
        }
    }

    // MARK: - Actions

    private func initiateImport() {
        HapticManager.shared.selection()
        showDocumentPicker = true
    }

    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                await performImport(from: url)
            }

        case .failure(let error):
            errorMessage = "Failed to select document"
            errorRecoverySuggestion = error.localizedDescription
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    @MainActor
    private func performImport(from url: URL) async {
        isImporting = true
        importProgress = "Analyzing document layout..."

        do {
            // Start accessing security-scoped resource
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)

            // Validate name uniqueness
            importProgress = "Validating template name..."
            let isValid = try TemplateManager.isValidTemplateName(trimmedName, excludingTemplate: nil, in: modelContext)

            guard isValid else {
                throw TemplateImportError.invalidLayout
            }

            // Perform import based on format
            let template: Template

            switch selectedFormat {
            case .pdf:
                importProgress = "Extracting layout from PDF..."
                template = try await TemplateImporter.importFromPDF(
                    url: url,
                    name: trimmedName,
                    context: modelContext
                )

            case .word:
                throw TemplateImportError.unsupportedFormat

            case .plainText:
                throw TemplateImportError.unsupportedFormat
            }

            importProgress = "Import complete"
            importedTemplate = template

            // Give user a moment to see the completion message
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            isImporting = false
            showPreview = true
            HapticManager.shared.saveSuccess()

        } catch let error as TemplateImportError {
            isImporting = false
            importProgress = ""
            errorMessage = error.errorDescription ?? "Import failed"
            errorRecoverySuggestion = error.recoverySuggestion ?? ""
            showErrorAlert = true
            HapticManager.shared.operationFailed()

        } catch {
            isImporting = false
            importProgress = ""
            errorMessage = "Unable to import template"
            errorRecoverySuggestion = error.localizedDescription
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Import Format Enum

enum ImportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case word = "Word Document"
    case plainText = "Plain Text"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .word:
            return "doc.richtext"
        case .plainText:
            return "doc.plaintext"
        }
    }

    var description: String {
        switch self {
        case .pdf:
            return "Import template settings from a PDF document. Column structure, fonts, and chord positioning will be automatically detected."
        case .word:
            return "Import from Word documents (.docx). Coming soon."
        case .plainText:
            return "Import from plain text files. Coming soon."
        }
    }

    var isSupported: Bool {
        switch self {
        case .pdf:
            return true
        case .word, .plainText:
            return false
        }
    }
}

// MARK: - Preview

#Preview("Template Import") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    return TemplateImportView()
        .modelContainer(container)
}

#Preview("Template Import - In Navigation") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    return NavigationStack {
        Text("Templates")
            .sheet(isPresented: .constant(true)) {
                TemplateImportView()
                    .modelContainer(container)
            }
    }
}
