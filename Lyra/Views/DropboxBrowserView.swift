//
//  DropboxBrowserView.swift
//  Lyra
//
//  Browse and select files from Dropbox
//

import SwiftUI

struct DropboxBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dropboxManager = DropboxManager.shared

    @State private var currentPath: String = ""
    @State private var files: [DropboxFile] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var selectedFiles: Set<DropboxFile> = []
    @State private var showingImport: Bool = false
    @State private var pathComponents: [String] = ["Dropbox"]

    var onFilesSelected: (([DropboxFile]) -> Void)?

    private var filteredFiles: [DropboxFile] {
        if searchText.isEmpty {
            return files
        }
        return files.filter { file in
            file.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var supportedFiles: [DropboxFile] {
        filteredFiles.filter { $0.isSupported || $0.isFolder }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Path breadcrumb
                if !pathComponents.isEmpty {
                    breadcrumbView
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                }

                // Content
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if supportedFiles.isEmpty && !searchText.isEmpty {
                    emptySearchView
                } else if supportedFiles.isEmpty {
                    emptyFolderView
                } else {
                    fileListView
                }
            }
            .navigationTitle("Dropbox")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search files")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !pathComponents.dropFirst().isEmpty {
                        Button {
                            goBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !selectedFiles.isEmpty {
                        Button {
                            importSelectedFiles()
                        } label: {
                            Text("Import (\(selectedFiles.count))")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .onAppear {
                loadFiles()
            }
            .onChange(of: searchText) { oldValue, newValue in
                if !newValue.isEmpty && oldValue.isEmpty {
                    performSearch()
                }
            }
        }
    }

    // MARK: - Breadcrumb View

    @ViewBuilder
    private var breadcrumbView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        navigateToIndex(index)
                    } label: {
                        Text(component)
                            .font(.subheadline)
                            .fontWeight(index == pathComponents.count - 1 ? .semibold : .regular)
                            .foregroundStyle(index == pathComponents.count - 1 ? .primary : .blue)
                    }
                    .disabled(index == pathComponents.count - 1)
                }
            }
        }
    }

    // MARK: - File List View

    @ViewBuilder
    private var fileListView: some View {
        List(selection: $selectedFiles) {
            ForEach(supportedFiles) { file in
                FileRow(file: file, isSelected: selectedFiles.contains(file)) {
                    if file.isFolder {
                        openFolder(file)
                    } else {
                        toggleFileSelection(file)
                    }
                }
                .accessibilityLabel(accessibilityLabel(for: file))
                .accessibilityHint(file.isFolder ? "Double tap to open folder" : "Double tap to select for import")
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading files...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Text("Unable to Load Files")
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                loadFiles()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Empty Views

    @ViewBuilder
    private var emptyFolderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Supported Files")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("This folder doesn't contain any .txt, .cho, .pdf, or .onsong files")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Results")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("No files found matching \"\(searchText)\"")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadFiles() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedFiles = try await dropboxManager.listFolder(path: currentPath)
                await MainActor.run {
                    self.files = loadedFiles.sorted { file1, file2 in
                        if file1.isFolder != file2.isFolder {
                            return file1.isFolder
                        }
                        return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func openFolder(_ folder: DropboxFile) {
        currentPath = folder.path
        pathComponents.append(folder.name)
        selectedFiles.removeAll()
        HapticManager.shared.selection()
        loadFiles()
    }

    private func goBack() {
        guard pathComponents.count > 1 else { return }

        pathComponents.removeLast()

        // Reconstruct path from components
        if pathComponents.count == 1 {
            currentPath = ""
        } else {
            currentPath = "/" + pathComponents.dropFirst().joined(separator: "/")
        }

        selectedFiles.removeAll()
        HapticManager.shared.selection()
        loadFiles()
    }

    private func navigateToIndex(_ index: Int) {
        guard index < pathComponents.count - 1 else { return }

        let componentsToKeep = pathComponents.prefix(index + 1)
        pathComponents = Array(componentsToKeep)

        if pathComponents.count == 1 {
            currentPath = ""
        } else {
            currentPath = "/" + pathComponents.dropFirst().joined(separator: "/")
        }

        selectedFiles.removeAll()
        HapticManager.shared.selection()
        loadFiles()
    }

    private func toggleFileSelection(_ file: DropboxFile) {
        if selectedFiles.contains(file) {
            selectedFiles.remove(file)
        } else {
            selectedFiles.insert(file)
        }
        HapticManager.shared.selection()
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isSearching = true

        Task {
            do {
                let results = try await dropboxManager.searchFiles(query: searchText, path: currentPath)
                await MainActor.run {
                    self.files = results.sorted { file1, file2 in
                        if file1.isFolder != file2.isFolder {
                            return file1.isFolder
                        }
                        return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
                    }
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSearching = false
                }
            }
        }
    }

    private func importSelectedFiles() {
        onFilesSelected?(Array(selectedFiles))
        dismiss()
    }

    private func accessibilityLabel(for file: DropboxFile) -> String {
        if file.isFolder {
            return "Folder: \(file.name)"
        } else {
            var label = "File: \(file.name)"
            if let size = file.size {
                label += ". Size: \(dropboxManager.formatBytes(size))"
            }
            if selectedFiles.contains(file) {
                label += ". Selected"
            }
            return label
        }
    }
}

// MARK: - File Row Component

struct FileRow: View {
    let file: DropboxFile
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: file.isFolder ? "folder.fill" : fileIcon)
                    .font(.title2)
                    .foregroundStyle(file.isFolder ? .blue : iconColor)
                    .frame(width: 32)

                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let size = file.size, !file.isFolder {
                        Text(DropboxManager.shared.formatBytes(size))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let date = file.modifiedDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Selection indicator
                if !file.isFolder {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title3)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var fileIcon: String {
        switch file.fileExtension {
        case "pdf":
            return "doc.fill"
        case "txt", "cho", "chordpro", "chopro", "crd":
            return "doc.text.fill"
        case "onsong":
            return "music.note"
        default:
            return "doc.fill"
        }
    }

    private var iconColor: Color {
        switch file.fileExtension {
        case "pdf":
            return .red
        case "txt", "cho", "chordpro", "chopro", "crd":
            return .blue
        case "onsong":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    DropboxBrowserView()
}
