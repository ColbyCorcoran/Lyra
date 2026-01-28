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
    @State private var showEditRecurringAlert: Bool = false
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showRecurrenceBuilder: Bool = false
    @State private var showVenueSuggestions: Bool = false
    @State private var venueSuggestions: [String] = []

    init(performanceSet: PerformanceSet) {
        self.performanceSet = performanceSet
        _name = State(initialValue: performanceSet.name)
        _setDescription = State(initialValue: performanceSet.setDescription ?? "")
        _venue = State(initialValue: performanceSet.venue ?? "")
        _folder = State(initialValue: performanceSet.folder ?? "")
        _notes = State(initialValue: performanceSet.notes ?? "")
        _scheduledDate = State(initialValue: performanceSet.scheduledDate ?? Date())
        _hasScheduledDate = State(initialValue: performanceSet.scheduledDate != nil)
        _recurrenceRule = State(initialValue: performanceSet.recurrenceRule)
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
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Venue", text: $venue)
                            .autocorrectionDisabled()
                            .onChange(of: venue) { _, newValue in
                                updateVenueSuggestions(for: newValue)
                            }

                        if !venueSuggestions.isEmpty && !venue.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(venueSuggestions, id: \.self) { suggestion in
                                    Button {
                                        venue = suggestion
                                        venueSuggestions = []
                                    } label: {
                                        HStack {
                                            Image(systemName: "mappin.circle")
                                                .foregroundStyle(.secondary)
                                            Text(suggestion)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(.plain)

                                    if suggestion != venueSuggestions.last {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.top, 4)
                        }
                    }

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

                        // Only show recurrence for template sets, not instances
                        if !performanceSet.isRecurringInstance {
                            Button {
                                showRecurrenceBuilder = true
                            } label: {
                                HStack {
                                    Label("Recurrence", systemImage: "repeat")
                                    Spacer()
                                    if let rule = recurrenceRule {
                                        Text(rule.humanReadableDescription)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    } else {
                                        Text("None")
                                            .foregroundStyle(.secondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Event Details")
                } footer: {
                    if hasScheduledDate {
                        if performanceSet.isRecurringInstance {
                            Text("This is a recurring instance. Changes may affect this instance only or all future instances.")
                        } else if recurrenceRule != nil {
                            Text("This set will automatically create recurring instances")
                        } else {
                            Text("The set will be organized by this scheduled date")
                        }
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
            .alert("Edit Recurring Set", isPresented: $showEditRecurringAlert) {
                Button("Cancel", role: .cancel) {}
                Button("This One Only") {
                    saveChangesThisInstanceOnly()
                }
                Button("This and All Future") {
                    saveChangesTemplateAndFuture()
                }
            } message: {
                Text("This is a recurring set instance. Do you want to edit just this instance or all future instances?")
            }
            .sheet(isPresented: $showRecurrenceBuilder) {
                RecurrenceRuleBuilderView(recurrenceRule: $recurrenceRule)
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

        // Check if this is a recurring instance - if so, show alert
        if performanceSet.isRecurringInstance {
            showEditRecurringAlert = true
            return
        }

        // Not a recurring instance, save normally
        applyChanges(to: performanceSet)
        attachRecurrenceRule()

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

    private func saveChangesThisInstanceOnly() {
        do {
            try RecurrenceManager.updateSingleInstance(
                performanceSet,
                updateBlock: { set in
                    applyChanges(to: set)
                },
                context: modelContext
            )
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error saving instance changes: \(error.localizedDescription)")
            errorMessage = "Unable to save changes. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func saveChangesTemplateAndFuture() {
        do {
            try RecurrenceManager.updateTemplateAndFutureInstances(
                performanceSet,
                updateBlock: { set in
                    applyChanges(to: set)
                },
                context: modelContext
            )
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error saving template changes: \(error.localizedDescription)")
            errorMessage = "Unable to save changes. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func applyChanges(to set: PerformanceSet) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        set.name = trimmedName
        set.setDescription = setDescription.isEmpty ? nil : setDescription
        set.venue = venue.isEmpty ? nil : venue
        set.folder = folder.isEmpty ? nil : folder
        set.notes = notes.isEmpty ? nil : notes
        set.scheduledDate = hasScheduledDate ? scheduledDate : nil
        set.modifiedAt = Date()
    }

    private func attachRecurrenceRule() {
        if let rule = recurrenceRule {
            performanceSet.recurrenceRule = rule
        }
    }

    private func updateVenueSuggestions(for searchText: String) {
        venueSuggestions = RecurrenceManager.getVenueHistory(matching: searchText, context: modelContext)
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
