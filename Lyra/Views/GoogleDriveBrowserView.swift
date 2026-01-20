//
//  GoogleDriveBrowserView.swift
//  Lyra
//
//  Browse and select files from Google Drive
//

import SwiftUI

struct GoogleDriveBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var driveManager = GoogleDriveManager.shared

    @State private var currentFolderId: String? = nil
    @State private var files: [GoogleDriveFile] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var selectedFiles: Set<GoogleDriveFile> = []
    @State private var navigationStack: [(id: String?, name: String)] = [(id: nil, name: "My Drive")]
    @State private var showSharedDrives: Bool = false
    @State private var sharedDrives: [(id: String, name: String)] = []

    var onFilesSelected: (([GoogleDriveFile]) -> Void)?

    private var filteredFiles: [GoogleDriveFile] {
        if searchText.isEmpty {
            return files
        }
        return files.filter { file in
            file.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var supportedFiles: [GoogleDriveFile] {
        filteredFiles.filter { $0.isSupported }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Navigation bar
                if !navigationStack.isEmpty {
                    navigationBar
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
            .navigationTitle("Google Drive")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search files")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if navigationStack.count > 1 {
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
                    Menu {
                        if !sharedDrives.isEmpty {
                            Section("Switch to") {
                                Button {
                                    navigateToMyDrive()
                                } label: {
                                    Label("My Drive", systemImage: "person")
                                }

                                ForEach(sharedDrives, id: \.id) { drive in
                                    Button {
                                        navigateToSharedDrive(drive)
                                    } label: {
                                        Label(drive.name, systemImage: "person.2")
                                    }
                                }
                            }
                        }

                        if !selectedFiles.isEmpty {
                            Section {
                                Button {
                                    importSelectedFiles()
                                } label: {
                                    Label("Import (\(selectedFiles.count))", systemImage: "arrow.down.circle")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadFiles()
                loadSharedDrives()
            }
            .onChange(of: searchText) { oldValue, newValue in
                if !newValue.isEmpty && oldValue.isEmpty {
                    performSearch()
                }
            }
        }
    }

    // MARK: - Navigation Bar

    @ViewBuilder
    private var navigationBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(navigationStack.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        navigateToIndex(index)
                    } label: {
                        HStack(spacing: 4) {
                            if index == 0 {
                                Image(systemName: "person")
                                    .font(.caption)
                            } else if index == navigationStack.count - 1 {
                                Image(systemName: "folder.fill")
                                    .font(.caption)
                            }

                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(index == navigationStack.count - 1 ? .semibold : .regular)
                                .lineLimit(1)
                        }
                        .foregroundStyle(index == navigationStack.count - 1 ? .primary : .blue)
                    }
                    .disabled(index == navigationStack.count - 1)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
        .background(Color(.systemGray6))
    }

    // MARK: - File List View

    @ViewBuilder
    private var fileListView: some View {
        List(selection: $selectedFiles) {
            ForEach(supportedFiles) { file in
                GoogleDriveFileRow(
                    file: file,
                    isSelected: selectedFiles.contains(file),
                    driveManager: driveManager
                ) {
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
                let loadedFiles = try await driveManager.listFiles(in: currentFolderId)
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

    private func loadSharedDrives() {
        Task {
            do {
                let drives = try await driveManager.listSharedDrives()
                await MainActor.run {
                    self.sharedDrives = drives
                }
            } catch {
                // Silently fail for shared drives
                print("❌ Error loading shared drives: \(error)")
            }
        }
    }

    private func openFolder(_ folder: GoogleDriveFile) {
        currentFolderId = folder.id
        navigationStack.append((id: folder.id, name: folder.name))
        selectedFiles.removeAll()
        HapticManager.shared.selection()
        loadFiles()
    }

    private func goBack() {
        guard navigationStack.count > 1 else { return }

        navigationStack.removeLast()
        currentFolderId = navigationStack.last?.id

        selectedFiles.removeAll()
        HapticManager.shared.selection()
        loadFiles()
    }

    private func navigateToIndex(_ index: Int) {
        guard index < navigationStack.count - 1 else { return }

        navigationStack = Array(navigationStack.prefix(index + 1))
        currentFolderId = navigationStack.last?.id

        selectedFiles.removeAll()
        HapticManager.shared.selection()
        loadFiles()
    }

    private func navigateToMyDrive() {
        navigationStack = [(id: nil, name: "My Drive")]
        currentFolderId = nil
        selectedFiles.removeAll()
        HapticManager.shared.selection()
        loadFiles()
    }

    private func navigateToSharedDrive(_ drive: (id: String, name: String)) {
        navigationStack = [(id: drive.id, name: drive.name)]
        currentFolderId = drive.id
        selectedFiles.removeAll()
        HapticManager.shared.selection()
        loadFiles()
    }

    private func toggleFileSelection(_ file: GoogleDriveFile) {
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
                let results = try await driveManager.searchFiles(query: searchText)
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

    private func accessibilityLabel(for file: GoogleDriveFile) -> String {
        if file.isFolder {
            return "Folder: \(file.name)"
        } else {
            var label = "File: \(file.name)"
            if let size = file.size {
                label += ". Size: \(driveManager.formatBytes(size))"
            }
            if selectedFiles.contains(file) {
                label += ". Selected"
            }
            return label
        }
    }
}

// MARK: - Google Drive File Row Component

struct GoogleDriveFileRow: View {
    let file: GoogleDriveFile
    let isSelected: Bool
    let driveManager: GoogleDriveManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: driveManager.getIconName(for: file))
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 32)

                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if let size = file.size, !file.isFolder {
                            Text(driveManager.formatBytes(size))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let modifiedTime = file.modifiedTime {
                            if !file.isFolder {
                                Text("•")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            Text(modifiedTime.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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

    private var iconColor: Color {
        let colorName = driveManager.getIconColor(for: file)
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "purple": return .purple
        case "green": return .green
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    GoogleDriveBrowserView()
}
