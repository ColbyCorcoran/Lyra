//
//  AddPerformanceSetView.swift
//  Lyra
//
//  Form for creating a new performance set
//

import SwiftUI
import SwiftData

struct AddPerformanceSetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var setDescription: String = ""
    @State private var venue: String = ""
    @State private var folder: String = ""
    @State private var scheduledDate: Date = Date()
    @State private var hasScheduledDate: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

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

                // MARK: - Preview Section

                if !name.isEmpty {
                    Section {
                        SetPreviewRow(
                            name: name,
                            venue: venue,
                            scheduledDate: hasScheduledDate ? scheduledDate : nil,
                            songCount: 0
                        )
                    } header: {
                        Text("Preview")
                    }
                }
            }
            .navigationTitle("New Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSet()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error Creating Set", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Actions

    private func createSet() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a set name."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
            return
        }

        let newSet = PerformanceSet(
            name: trimmedName,
            scheduledDate: hasScheduledDate ? scheduledDate : nil
        )

        newSet.setDescription = setDescription.isEmpty ? nil : setDescription
        newSet.venue = venue.isEmpty ? nil : venue
        newSet.folder = folder.isEmpty ? nil : folder

        modelContext.insert(newSet)

        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error saving performance set: \(error.localizedDescription)")
            errorMessage = "Unable to save set. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Set Preview Row

struct SetPreviewRow: View {
    let name: String
    let venue: String
    let scheduledDate: Date?
    let songCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                if let date = scheduledDate {
                    Label(
                        formatDate(date),
                        systemImage: "calendar"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                if !venue.isEmpty {
                    Label(venue, systemImage: "location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text("\(songCount) \(songCount == 1 ? "song" : "songs")")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today at \(formatter.string(from: date).components(separatedBy: " at ").last ?? "")"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow at \(formatter.string(from: date).components(separatedBy: " at ").last ?? "")"
        } else {
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

#Preview("Add Performance Set") {
    AddPerformanceSetView()
        .modelContainer(for: PerformanceSet.self, inMemory: true)
}
