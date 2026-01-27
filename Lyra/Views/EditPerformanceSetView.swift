//
//  EditPerformanceSetView.swift
//  Lyra
//
//  Form for editing an existing performance set's details
//

import SwiftUI
import SwiftData

struct EditPerformanceSetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let performanceSet: PerformanceSet

    @State private var name: String
    @State private var setDescription: String
    @State private var venue: String
    @State private var folder: String
    @State private var notes: String
    @State private var scheduledDate: Date
    @State private var hasScheduledDate: Bool
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    init(performanceSet: PerformanceSet) {
        self.performanceSet = performanceSet
        _name = State(initialValue: performanceSet.name)
        _setDescription = State(initialValue: performanceSet.setDescription ?? "")
        _venue = State(initialValue: performanceSet.venue ?? "")
        _folder = State(initialValue: performanceSet.folder ?? "")
        _notes = State(initialValue: performanceSet.notes ?? "")
        _scheduledDate = State(initialValue: performanceSet.scheduledDate ?? Date())
        _hasScheduledDate = State(initialValue: performanceSet.scheduledDate != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Info Section

                Section {
                    TextField("Set Name", text: $name)
                        .autocorrectionDisabled()

                    ZStack(alignment: .topLeading) {
                        if setDescription.isEmpty {
                            Text("Description (Optional)")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: $setDescription)
                            .frame(minHeight: 60)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("Set Information")
                }

                // MARK: - Event Details Section

                Section {
                    TextField("Venue", text: $venue)
                        .autocorrectionDisabled()

                    TextField("Folder/Category", text: $folder)
                        .autocorrectionDisabled()

                    // Date toggle and picker
                    Toggle("Schedule Date & Time", isOn: $hasScheduledDate)

                    if hasScheduledDate {
                        DatePicker(
                            "Date & Time",
                            selection: $scheduledDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                    }
                } header: {
                    Text("Event Details")
                } footer: {
                    if hasScheduledDate {
                        Text("The set will be organized by this scheduled date")
                    }
                }

                // MARK: - Notes Section

                Section {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Set notes (Optional)")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Overall notes for this performance set")
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error Saving Changes", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a set name."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
            return
        }

        // Update set properties
        performanceSet.name = trimmedName
        performanceSet.setDescription = setDescription.isEmpty ? nil : setDescription
        performanceSet.venue = venue.isEmpty ? nil : venue
        performanceSet.folder = folder.isEmpty ? nil : folder
        performanceSet.notes = notes.isEmpty ? nil : notes
        performanceSet.scheduledDate = hasScheduledDate ? scheduledDate : nil
        performanceSet.modifiedAt = Date()

        // Save to SwiftData
        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error saving set changes: \(error.localizedDescription)")
            errorMessage = "Unable to save changes. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Preview

#Preview("Edit Performance Set") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, configurations: config)

    let performanceSet = PerformanceSet(name: "Sunday Morning Worship", scheduledDate: Date())
    performanceSet.venue = "Main Sanctuary"
    performanceSet.folder = "Church"
    performanceSet.notes = "Start with worship, end with hymn"
    performanceSet.setDescription = "Weekly Sunday morning service"

    container.mainContext.insert(performanceSet)

    return EditPerformanceSetView(performanceSet: performanceSet)
        .modelContainer(container)
}
