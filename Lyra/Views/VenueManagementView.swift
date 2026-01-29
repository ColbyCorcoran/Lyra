//
//  VenueManagementView.swift
//  Lyra
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct VenueManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PerformanceSet.createdAt) private var allSets: [PerformanceSet]

    @State private var venues: [String] = []
    @State private var editingVenue: String?
    @State private var newVenueName: String = ""
    @State private var showDeleteConfirmation: Bool = false
    @State private var venueToDelete: String?
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if venues.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No Venues")
                            .font(.headline)

                        Text("Venues will appear here as you create sets with venue names")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(venues, id: \.self) { venue in
                            if editingVenue == venue {
                                // Edit mode
                                HStack {
                                    TextField("Venue name", text: $newVenueName)
                                        .textFieldStyle(.roundedBorder)

                                    Button("Save") {
                                        saveRename(oldName: venue, newName: newVenueName)
                                    }
                                    .disabled(newVenueName.trimmingCharacters(in: .whitespaces).isEmpty)

                                    Button("Cancel") {
                                        editingVenue = nil
                                        newVenueName = ""
                                    }
                                }
                            } else {
                                // Display mode
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(venue)

                                    Spacer()

                                    Text("\(setCount(for: venue))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        venueToDelete = venue
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        editingVenue = venue
                                        newVenueName = venue
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
            .navigationTitle("Manage Venues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadVenues()
            }
            .alert("Delete Venue", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    venueToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let venue = venueToDelete {
                        deleteVenue(venue)
                    }
                }
            } message: {
                if let venue = venueToDelete {
                    Text("This will remove '\(venue)' from all sets. The sets will remain, but they will no longer have this venue assigned.")
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

    private func loadVenues() {
        let uniqueVenues = Set(allSets.compactMap { $0.venue })
        venues = Array(uniqueVenues).sorted()
    }

    private func setCount(for venue: String) -> Int {
        allSets.filter { $0.venue == venue }.count
    }

    private func saveRename(oldName: String, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Venue name cannot be empty"
            showErrorAlert = true
            return
        }

        guard trimmedName != oldName else {
            editingVenue = nil
            newVenueName = ""
            return
        }

        // Check if new name already exists
        if venues.contains(trimmedName) {
            errorMessage = "A venue with this name already exists"
            showErrorAlert = true
            return
        }

        do {
            // Update all sets with this venue
            let setsToUpdate = allSets.filter { $0.venue == oldName }

            for set in setsToUpdate {
                set.venue = trimmedName
                set.modifiedAt = Date()
            }

            try modelContext.save()

            editingVenue = nil
            newVenueName = ""
            loadVenues()

            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to rename venue: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func deleteVenue(_ venue: String) {
        do {
            // Remove venue from all sets that use it
            let setsWithVenue = allSets.filter { $0.venue == venue }

            for set in setsWithVenue {
                set.venue = nil
                set.modifiedAt = Date()
            }

            try modelContext.save()

            venueToDelete = nil
            loadVenues()

            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to delete venue: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

#Preview {
    VenueManagementView()
        .modelContainer(for: PerformanceSet.self, inMemory: true)
}
