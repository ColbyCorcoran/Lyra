//
//  FolderPickerField.swift
//  Lyra
//
//  Folder picker with create new functionality
//

import SwiftUI
import SwiftData

struct FolderPickerField: View {
    @Binding var selectedFolder: String?
    @Environment(\.modelContext) private var modelContext

    @State private var showPicker = false
    @State private var newFolderName = ""
    @State private var showNewFolderField = false
    @State private var availableFolders: [String] = []

    var body: some View {
        Button {
            loadFolders()
            showPicker = true
        } label: {
            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)

                if let folder = selectedFolder, !folder.isEmpty {
                    Text(folder)
                        .foregroundStyle(.primary)
                } else {
                    Text("Select Folder")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            folderPickerSheet
        }
    }

    private var folderPickerSheet: some View {
        NavigationStack {
            List {
                // Create new folder section
                Section {
                    if showNewFolderField {
                        HStack {
                            TextField("New Folder Name", text: $newFolderName)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()

                            Button {
                                createNewFolder()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button {
                                showNewFolderField = false
                                newFolderName = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    } else {
                        Button {
                            showNewFolderField = true
                        } label: {
                            Label("Create New Folder", systemImage: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("Create")
                }

                // Existing folders section
                if !availableFolders.isEmpty {
                    Section {
                        // None option
                        Button {
                            selectedFolder = nil
                            HapticManager.shared.selection()
                            showPicker = false
                        } label: {
                            HStack {
                                Image(systemName: "folder.badge.minus")
                                    .foregroundStyle(.secondary)

                                Text("None")
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedFolder == nil || selectedFolder?.isEmpty == true {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Existing folders
                        ForEach(Array(availableFolders.enumerated()), id: \.element) { index, folder in
                            Button {
                                selectedFolder = folder
                                HapticManager.shared.selection()
                                showPicker = false
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(.blue)

                                    Text(folder)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selectedFolder == folder {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Existing Folders")
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showPicker = false
                        showNewFolderField = false
                        newFolderName = ""
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func loadFolders() {
        availableFolders = FolderManager.getAllFolders(from: modelContext)
    }

    private func createNewFolder() {
        let folderName = FolderManager.createFolder(newFolderName)

        guard !folderName.isEmpty else {
            return
        }

        // Check if folder already exists
        if FolderManager.folderExists(folderName, in: modelContext) {
            // Folder already exists, just select it
            selectedFolder = folderName
        } else {
            // New folder - will be created when set is saved
            selectedFolder = folderName
        }

        HapticManager.shared.success()
        newFolderName = ""
        showNewFolderField = false
        loadFolders()
        showPicker = false
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedFolder: String? = nil

        var body: some View {
            Form {
                Section {
                    FolderPickerField(selectedFolder: $selectedFolder)
                } header: {
                    Text("Folder")
                }

                if let folder = selectedFolder {
                    Section {
                        Text("Selected: \(folder)")
                    }
                }
            }
            .modelContainer(PreviewContainer.shared.container)
        }
    }

    return PreviewWrapper()
}
