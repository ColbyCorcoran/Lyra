//
//  LibraryExportView.swift
//  Lyra
//
//  View for exporting entire library as archive
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

struct LibraryExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var songs: [Song]
    @Query private var books: [Book]
    @Query private var sets: [PerformanceSet]

    @State private var selectedFormat: ExportManager.ExportFormat = .pdf
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var exportStatus: String = ""
    @State private var shareItem: ShareItem?
    @State private var exportError: Error?
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                librarySummarySection
                formatSelectionSection
                archiveDetailsSection
                exportButtonSection
                emptyLibraryWarningSection
            }
            .navigationTitle("Export Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isExporting)
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(activityItems: item.items)
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

    // MARK: - View Components

    @ViewBuilder
    private var librarySummarySection: some View {
        Section {
            HStack {
                Image(systemName: "music.note")
                    .foregroundStyle(.blue)
                Text("Songs")
                Spacer()
                Text("\(songs.count)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "book")
                    .foregroundStyle(.blue)
                Text("Books")
                Spacer()
                Text("\(books.count)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(.blue)
                Text("Sets")
                Spacer()
                Text("\(sets.count)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Library Contents")
        } footer: {
            Text("All items will be exported and packaged as a compressed archive")
        }
    }

    @ViewBuilder
    private var formatSelectionSection: some View {
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
        }
    }

    @ViewBuilder
    private var archiveDetailsSection: some View {
        Section {
            HStack {
                Image(systemName: "archivebox")
                    .foregroundStyle(.blue)
                Text("Archive Type")
                Spacer()
                Text("ZIP")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                Text("Structure")
                Spacer()
                Text("Songs / Books / Sets")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.blue)
                Text("Includes")
                Spacer()
                Text("README.txt")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Archive Details")
        }
    }

    @ViewBuilder
    private var exportButtonSection: some View {
        if !isExporting {
            Section {
                Button {
                    startExport()
                } label: {
                    HStack {
                        Spacer()
                        Label("Export Library", systemImage: "arrow.down.doc.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(songs.isEmpty && books.isEmpty && sets.isEmpty)
            }
        } else {
            Section {
                VStack(spacing: 16) {
                    ProgressView(value: exportProgress)
                        .progressViewStyle(.linear)

                    HStack {
                        ProgressView()
                            .controlSize(.small)

                        Text(exportStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Exporting...")
            }
        }
    }

    @ViewBuilder
    private var emptyLibraryWarningSection: some View {
        if songs.isEmpty && books.isEmpty && sets.isEmpty {
            Section {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("Your library is empty. Add songs, books, or sets before exporting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Actions

    private func startExport() {
        isExporting = true
        exportProgress = 0.0
        exportStatus = "Preparing export..."

        Task {
            do {
                // Update progress
                await MainActor.run {
                    exportProgress = 0.2
                    exportStatus = "Exporting \(songs.count) songs..."
                }

                // Small delay for UI update
                try await Task.sleep(nanoseconds: 100_000_000)

                await MainActor.run {
                    exportProgress = 0.4
                    exportStatus = "Exporting \(books.count) books..."
                }

                try await Task.sleep(nanoseconds: 100_000_000)

                await MainActor.run {
                    exportProgress = 0.6
                    exportStatus = "Exporting \(sets.count) sets..."
                }

                try await Task.sleep(nanoseconds: 100_000_000)

                await MainActor.run {
                    exportProgress = 0.8
                    exportStatus = "Creating archive..."
                }

                // Perform export
                let zipURL = try ExportManager.shared.exportLibrary(
                    songs: songs,
                    books: books,
                    sets: sets,
                    format: selectedFormat
                )

                await MainActor.run {
                    exportProgress = 1.0
                    exportStatus = "Export complete!"
                }

                try await Task.sleep(nanoseconds: 500_000_000)

                // Show share sheet
                await MainActor.run {
                    shareItem = ShareItem(items: [zipURL])
                    isExporting = false
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showError = true
                    isExporting = false
                    HapticManager.shared.operationFailed()
                }
            }
        }
    }
}

// MARK: - Share Sheet

private struct ShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

#if canImport(UIKit)
private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Preview

#Preview("Library Export") {
    LibraryExportView()
        .modelContainer(PreviewContainer.shared.container)
}
