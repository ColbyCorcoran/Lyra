//
//  DuplicateSetView.swift
//  Lyra
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct DuplicateSetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let originalSet: PerformanceSet

    @State private var setDateNow: Bool = true
    @State private var scheduledDate: Date = Date()
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(originalSet.name)
                        .font(.headline)

                    if let venue = originalSet.venue, !venue.isEmpty {
                        Label(venue, systemImage: "mappin.circle")
                            .foregroundStyle(.secondary)
                    }

                    if let songCount = originalSet.sortedSongEntries?.count {
                        Label("\(songCount) songs", systemImage: "music.note.list")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Duplicating Set")
                }

                Section {
                    Toggle("Set Date Now", isOn: $setDateNow)

                    if setDateNow {
                        DatePicker(
                            "Date & Time",
                            selection: $scheduledDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    if !setDateNow {
                        Text("You can set the date later from the set details")
                    }
                }
            }
            .navigationTitle("Duplicate Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Duplicate") {
                        duplicateSet()
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Duplicate Logic

    private func duplicateSet() {
        do {
            // Create new set with same basic properties
            let duplicate = PerformanceSet(
                name: originalSet.name,
                scheduledDate: setDateNow ? scheduledDate : nil
            )

            duplicate.setDescription = originalSet.setDescription
            duplicate.venue = originalSet.venue
            duplicate.folder = originalSet.folder
            duplicate.notes = originalSet.notes

            // Important: DO NOT copy recurrence rule (duplicates are one-off)
            // DO NOT copy recurring instance properties

            modelContext.insert(duplicate)

            // Deep copy all song entries
            if let entries = originalSet.sortedSongEntries {
                for entry in entries {
                    guard let song = entry.song else { continue }

                    let newEntry = SetEntry(song: song, orderIndex: entry.orderIndex)
                    newEntry.performanceSet = duplicate

                    // Copy all overrides
                    newEntry.keyOverride = entry.keyOverride
                    newEntry.capoOverride = entry.capoOverride
                    newEntry.tempoOverride = entry.tempoOverride
                    newEntry.autoscrollDurationOverride = entry.autoscrollDurationOverride
                    newEntry.notes = entry.notes

                    modelContext.insert(newEntry)
                }
            }

            try modelContext.save()

            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = "Failed to duplicate set: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}
