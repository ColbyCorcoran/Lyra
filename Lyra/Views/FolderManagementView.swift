//
//  FolderManagementView.swift
//  Lyra
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct FolderManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PerformanceSet.createdAt) private var allSets: [PerformanceSet]

    @State private var folders: [String] = []
    @State private var editingFolder: String?
    @State private var newFolderName: String = ""
    @State private var showDeleteConfirmation: Bool = false
    @State private var folderToDelete: String?
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if folders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No Folders")
                            .font(.headline)

                        Text("Folders will appear here as you create sets with folder names")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(folders, id: \.self) { folder in
                            if editingFolder == folder {
                                // Edit mode
                                HStack {
                                    TextField("Folder name", text: $newFolderName)
                                        .textFieldStyle(.roundedBorder)

                                    Button("Save") {
                                        saveRename(oldName: folder, newName: newFolderName)
                                    }
                                    .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)

                                    Button("Cancel") {
                                        editingFolder = nil
                                        newFolderName = ""
                                    }
                                }
                            } else {
                                // Display mode
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(.blue)
                                    Text(folder)

                                    Spacer()

                                    Text("\(setCount(for: folder))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        folderToDelete = folder
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        editingFolder = folder
                                        newFolderName = folder
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadFolders()
            }
            .alert("Delete Folder", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    folderToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let folder = folderToDelete {
                        deleteFolder(folder)
                    }
                }
            } message: {
                if let folder = folderToDelete {
                    Text("This will remove '\(folder)' from all sets. The sets will remain, but they will no longer be in this folder.")
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Helpers

    private func loadFolders() {
        let uniqueFolders = Set(allSets.compactMap { $0.folder })
        folders = Array(uniqueFolders).sorted()
    }

    private func setCount(for folder: String) -> Int {
        allSets.filter { $0.folder == folder }.count
    }

    private func saveRename(oldName: String, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Folder name cannot be empty"
            showErrorAlert = true
            return
        }

        guard trimmedName != oldName else {
            editingFolder = nil
            newFolderName = ""
            return
        }

        // Check if new name already exists
        if folders.contains(trimmedName) {
            errorMessage = "A folder with this name already exists"
            showErrorAlert = true
            return
        }

        do {
            // Update all sets with this folder
            let setsToUpdate = allSets.filter { $0.folder == oldName }

            for set in setsToUpdate {
                set.folder = trimmedName
                set.modifiedAt = Date()
            }

            try modelContext.save()

            editingFolder = nil
            newFolderName = ""
            loadFolders()

            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to rename folder: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func deleteFolder(_ folder: String) {
        do {
            // Remove folder from all sets that use it
            let setsWithFolder = allSets.filter { $0.folder == folder }

            for set in setsWithFolder {
                set.folder = nil
                set.modifiedAt = Date()
            }

            try modelContext.save()

            folderToDelete = nil
            loadFolders()

            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to delete folder: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

#Preview {
    FolderManagementView()
        .modelContainer(for: PerformanceSet.self, inMemory: true)
}
