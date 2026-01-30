//
//  ExportOptionsSheet.swift
//  Lyra
//
//  Sheet for selecting export format and options for songs
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportOptionsSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedFormat: SongExporter.ExportFormat = .chordPro
    @State private var includeMetadata: Bool = true
    @State private var includeNotes: Bool = true
    @State private var customFilename: String = ""
    @State private var useCustomFilename: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var isExporting: Bool = false
    @State private var exportedContent: String = ""
    @State private var showPreview: Bool = false

    // MARK: - Properties

    let song: Song
    let onExport: (URL) -> Void

    // MARK: - Initializer

    init(song: Song, onExport: @escaping (URL) -> Void) {
        self.song = song
        self.onExport = onExport
        _customFilename = State(initialValue: SongExporter.suggestedFilename(for: song, format: .chordPro))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                formatSection
                optionsSection
                filenameSection
                previewSection
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.buttonTap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        exportSong()
                    }
                    .fontWeight(.semibold)
                    .disabled(isExporting)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert("Export Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Sections

    private var formatSection: some View {
        Section {
            Picker("Format", selection: $selectedFormat) {
                ForEach(SongExporter.ExportFormat.allCases, id: \.self) { format in
                    HStack {
                        Text(format.displayName)
                        Spacer()
                        Text(".\(format.fileExtension)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(format)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: selectedFormat) { _, newValue in
                HapticManager.shared.selection()
                updateFilenameForFormat(newValue)
                if newValue == .pdf {
                    showPreview = false
                } else {
                    updatePreview()
                }
            }
        } header: {
            Text("Export Format")
        } footer: {
            Text(formatDescription)
        }
    }

    private var optionsSection: some View {
        Section {
            Toggle("Include Metadata", isOn: $includeMetadata)
                .onChange(of: includeMetadata) { _, _ in
                    HapticManager.shared.light()
                    updatePreview()
                }

            if song.notes != nil && !song.notes!.isEmpty {
                Toggle("Include Notes", isOn: $includeNotes)
                    .onChange(of: includeNotes) { _, _ in
                        HapticManager.shared.light()
                        updatePreview()
                    }
            }
        } header: {
            Text("Export Options")
        } footer: {
            if selectedFormat == .json || selectedFormat == .lyraBundle {
                Text("This format always includes all song data")
            } else if selectedFormat == .pdf {
                Text("PDF is rendered using the song's template layout")
            } else {
                Text("Choose what to include in the exported file")
            }
        }
    }

    private var filenameSection: some View {
        Section {
            Toggle("Custom Filename", isOn: $useCustomFilename)
                .onChange(of: useCustomFilename) { _, _ in
                    HapticManager.shared.light()
                }

            if useCustomFilename {
                TextField("Filename", text: $customFilename)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                HStack {
                    Text("Suggested Filename")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(suggestedFilename)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        } header: {
            Text("File Name")
        } footer: {
            if useCustomFilename {
                Text("Enter a custom filename without extension")
            } else {
                Text("Using default filename based on song title and artist")
            }
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        if selectedFormat != .pdf {
            Section {
                if showPreview {
                    ScrollView {
                        Text(exportedContent)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                    }
                    .frame(maxHeight: 200)
                } else {
                    Button {
                        generatePreview()
                    } label: {
                        Label("Show Preview", systemImage: "eye")
                    }
                }
            } header: {
                Text("Preview")
            } footer: {
                if showPreview {
                    Text("Preview of exported content")
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var formatDescription: String {
        switch selectedFormat {
        case .chordPro:
            return "ChordPro format is a standard format for chord charts with metadata directives."
        case .pdf:
            return "PDF preserves the visual layout with template formatting applied, ready for printing."
        case .plainText:
            return "Plain text format with human-readable metadata and lyrics."
        case .lyraBundle:
            return "Lyra Bundle includes the song, template, and settings for complete round-trip import/export."
        case .json:
            return "JSON format includes all song data in a structured, machine-readable format."
        }
    }

    private var suggestedFilename: String {
        return SongExporter.suggestedFilename(for: song, format: selectedFormat)
    }

    private var finalFilename: String {
        if useCustomFilename {
            let cleanedFilename = customFilename.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedFilename.isEmpty {
                return suggestedFilename
            }
            // Remove extension if user added one
            let filenameWithoutExt = cleanedFilename.hasSuffix(".\(selectedFormat.fileExtension)")
                ? String(cleanedFilename.dropLast(selectedFormat.fileExtension.count + 1))
                : cleanedFilename
            return "\(filenameWithoutExt).\(selectedFormat.fileExtension)"
        }
        return suggestedFilename
    }

    // MARK: - Actions

    private func exportSong() {
        isExporting = true
        HapticManager.shared.buttonTap()

        do {
            let url = try exportToTemporaryFile()
            onExport(url)
            HapticManager.shared.success()
            dismiss()
        } catch {
            handleExportError(error)
        }

        isExporting = false
    }

    private func exportToTemporaryFile() throws -> URL {
        let filename = finalFilename
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let template = song.effectiveTemplate(context: modelContext)

        switch selectedFormat {
        case .pdf:
            let pdfData = try SongExporter.exportToPDF(song, template: template)
            try pdfData.write(to: tempURL)

        case .lyraBundle:
            let content = try SongExporter.exportToLyraBundle(song, template: template)
            try content.write(to: tempURL, atomically: true, encoding: .utf8)

        default:
            let content = try generateExportContent()
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
        }

        return tempURL
    }

    private func generateExportContent() throws -> String {
        // For non-JSON/non-binary formats, handle metadata and notes options
        if selectedFormat != .json && selectedFormat != .lyraBundle && selectedFormat != .pdf {
            if !includeNotes {
                let content = try exportForFormat(selectedFormat, song: song)
                return removeNotesFromContent(content, format: selectedFormat)
            }

            if !includeMetadata {
                let content = try exportForFormat(selectedFormat, song: song)
                return removeMetadataFromContent(content, format: selectedFormat)
            }
        }

        return try exportForFormat(selectedFormat, song: song)
    }

    private func exportForFormat(_ format: SongExporter.ExportFormat, song: Song) throws -> String {
        switch format {
        case .chordPro:
            return try SongExporter.exportToChordPro(song)
        case .json:
            return try SongExporter.exportToJSON(song)
        case .plainText:
            return try SongExporter.exportToPlainText(song)
        case .lyraBundle:
            let template = song.effectiveTemplate(context: modelContext)
            return try SongExporter.exportToLyraBundle(song, template: template)
        case .pdf:
            // PDF is binary, not text - should use exportToTemporaryFile instead
            throw SongExporter.SongExportError.unsupportedFormat
        }
    }

    private func removeNotesFromContent(_ content: String, format: SongExporter.ExportFormat) -> String {
        switch format {
        case .chordPro:
            // Remove {comment:...} directives
            return content.components(separatedBy: "\n")
                .filter { !$0.contains("{comment:") }
                .joined(separator: "\n")
        case .plainText:
            // Remove NOTES section
            if let notesRange = content.range(of: "NOTES:", options: .caseInsensitive) {
                let beforeNotes = content[..<notesRange.lowerBound]
                // Also remove the separator line before notes
                let lines = beforeNotes.split(separator: "\n", omittingEmptySubsequences: false)
                let withoutLastSeparator = lines.dropLast(2).joined(separator: "\n")
                return withoutLastSeparator
            }
            return content
        case .json, .pdf, .lyraBundle:
            return content // These formats handle content inclusion internally
        }
    }

    private func removeMetadataFromContent(_ content: String, format: SongExporter.ExportFormat) -> String {
        switch format {
        case .chordPro:
            // Keep title but remove other metadata directives
            let lines = content.components(separatedBy: "\n")
            var result: [String] = []
            for line in lines {
                if line.hasPrefix("{title:") || !line.hasPrefix("{") {
                    result.append(line)
                }
            }
            return result.joined(separator: "\n")
        case .plainText:
            // Keep title but remove metadata lines
            let lines = content.components(separatedBy: "\n")
            var result: [String] = []
            var inMetadata = true
            var titleAdded = false

            for line in lines {
                if !titleAdded && !line.isEmpty {
                    // Add title and separator
                    result.append(line)
                    if let nextLine = lines.dropFirst(lines.firstIndex(of: line)! + 1).first {
                        if nextLine.allSatisfy({ $0 == "=" }) {
                            result.append(nextLine)
                        }
                    }
                    titleAdded = true
                    continue
                }

                if inMetadata {
                    // Check if we've reached the content separator or content
                    if line.allSatisfy({ $0 == "-" || $0.isWhitespace }) || (!line.isEmpty && !line.contains(":")) {
                        inMetadata = false
                        result.append(line)
                    }
                } else {
                    result.append(line)
                }
            }
            return result.joined(separator: "\n")
        case .json, .pdf, .lyraBundle:
            return content // These formats handle content inclusion internally
        }
    }

    private func updateFilenameForFormat(_ format: SongExporter.ExportFormat) {
        if !useCustomFilename {
            customFilename = SongExporter.suggestedFilename(for: song, format: format)
        }
    }

    private func generatePreview() {
        HapticManager.shared.light()
        do {
            exportedContent = try generateExportContent()
            showPreview = true
        } catch {
            handleExportError(error)
        }
    }

    private func updatePreview() {
        if showPreview {
            generatePreview()
        }
    }

    private func handleExportError(_ error: Error) {
        print("❌ Export error: \(error.localizedDescription)")

        if let exportError = error as? SongExporter.SongExportError {
            errorMessage = exportError.errorDescription ?? "An unknown error occurred"
            if let suggestion = exportError.recoverySuggestion {
                errorMessage += "\n\n\(suggestion)"
            }
        } else {
            errorMessage = "Failed to export song: \(error.localizedDescription)"
        }

        showErrorAlert = true
        HapticManager.shared.operationFailed()
    }
}

// MARK: - Preview

#Preview {
    ExportOptionsSheet(
        song: Song(
            title: "Amazing Grace",
            artist: "John Newton",
            content: "[G]Amazing grace, how [C]sweet the [G]sound\nThat saved a wretch like [D]me\n[G]I once was lost, but [C]now I'm [G]found\nWas [D]blind but now I [G]see",
            originalKey: "G"
        ),
        onExport: { url in
            print("Exported to: \(url.lastPathComponent)")
        }
    )
    .modelContainer(PreviewContainer.shared.container)
}
