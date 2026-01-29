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

    @State private var setName: String
    @State private var setDescription: String
    @State private var venue: String
    @State private var folder: String
    @State private var setDateNow: Bool = true
    @State private var scheduledDate: Date = Date()
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    // Autocomplete state
    @State private var showVenueSuggestions: Bool = false
    @State private var venueSuggestions: [String] = []
    @State private var showFolderSuggestions: Bool = false
    @State private var folderSuggestions: [String] = []

    // Recurrence state
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showRecurrenceBuilder: Bool = false

    // Browsing state
    @State private var showVenueBrowser: Bool = false
    @State private var showFolderBrowser: Bool = false

    init(originalSet: PerformanceSet) {
        self.originalSet = originalSet
        _setName = State(initialValue: originalSet.name)
        _setDescription = State(initialValue: originalSet.setDescription ?? "")
        _venue = State(initialValue: originalSet.venue ?? "")
        _folder = State(initialValue: originalSet.folder ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let songCount = originalSet.sortedSongEntries?.count {
                        Label("\(songCount) songs will be copied", systemImage: "music.note.list")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Duplicating Set")
                }

                Section {
                    TextField("Set Name", text: $setName)

                    TextField("Description (optional)", text: $setDescription, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Basic Information")
                }

                Section {
                    // Venue field
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                                .font(.title3)
                                .frame(width: 24)

                            TextField("Venue (optional)", text: $venue)
                                .onChange(of: venue) { _, newValue in
                                    updateVenueSuggestions(newValue)
                                }

                            Button {
                                showVenueBrowser = true
                            } label: {
                                Image(systemName: "list.bullet")
                                    .foregroundStyle(.blue)
                            }
                            .accessibilityLabel("Browse venues")
                        }

                        if showVenueSuggestions && !venueSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(venueSuggestions, id: \.self) { suggestion in
                                    Button {
                                        venue = suggestion
                                        showVenueSuggestions = false
                                    } label: {
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundStyle(.secondary)
                                                .font(.caption)
                                            Text(suggestion)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemGray6))
                                    }
                                    .buttonStyle(.plain)

                                    if suggestion != venueSuggestions.last {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.top, 4)
                            .padding(.leading, 36)
                        }
                    }

                    // Folder field
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
                                .frame(width: 24)

                            TextField("Folder (optional)", text: $folder)
                                .onChange(of: folder) { _, newValue in
                                    updateFolderSuggestions(newValue)
                                }

                            Button {
                                showFolderBrowser = true
                            } label: {
                                Image(systemName: "list.bullet")
                                    .foregroundStyle(.blue)
                            }
                            .accessibilityLabel("Browse folders")
                        }

                        if showFolderSuggestions && !folderSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(folderSuggestions, id: \.self) { suggestion in
                                    Button {
                                        folder = suggestion
                                        showFolderSuggestions = false
                                    } label: {
                                        HStack {
                                            Image(systemName: "folder.fill")
                                                .foregroundStyle(.secondary)
                                                .font(.caption)
                                            Text(suggestion)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemGray6))
                                    }
                                    .buttonStyle(.plain)

                                    if suggestion != folderSuggestions.last {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.top, 4)
                            .padding(.leading, 36)
                        }
                    }
                } header: {
                    Text("Event Details")
                } footer: {
                    Text("Tap the list icon to browse existing venues or folders")
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

                Section {
                    Button {
                        showRecurrenceBuilder = true
                    } label: {
                        HStack {
                            Label("Recurrence Pattern", systemImage: "repeat")
                            Spacer()
                            if recurrenceRule != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

                    if let rule = recurrenceRule {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recurrenceSummary(rule))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button("Remove Recurrence") {
                                recurrenceRule = nil
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Recurrence")
                } footer: {
                    Text("Make this duplicate a recurring set. The original set's recurrence pattern is not copied.")
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
                    .disabled(setName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showRecurrenceBuilder) {
                RecurrenceRuleBuilderView(recurrenceRule: $recurrenceRule)
            }
            .sheet(isPresented: $showVenueBrowser) {
                VenueBrowserSheet(selectedVenue: $venue, isPresented: $showVenueBrowser)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showFolderBrowser) {
                FolderBrowserSheet(selectedFolder: $folder, isPresented: $showFolderBrowser)
                    .environment(\.modelContext, modelContext)
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
            // Create new set with user-edited properties
            let duplicate = PerformanceSet(
                name: setName.trimmingCharacters(in: .whitespaces),
                scheduledDate: setDateNow ? scheduledDate : nil
            )

            // Set all the editable properties
            duplicate.setDescription = setDescription.isEmpty ? nil : setDescription
            duplicate.venue = venue.isEmpty ? nil : venue
            duplicate.folder = folder.isEmpty ? nil : folder
            duplicate.notes = originalSet.notes

            // Attach recurrence rule if set
            if let rule = recurrenceRule {
                duplicate.recurrenceRule = rule
                rule.templateSet = duplicate
            }

            modelContext.insert(duplicate)

            // Deep copy all song entries from original
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

    // MARK: - Autocomplete

    private func updateVenueSuggestions(_ searchText: String) {
        if searchText.isEmpty {
            showVenueSuggestions = false
            venueSuggestions = []
            return
        }

        venueSuggestions = RecurrenceManager.getVenueHistory(matching: searchText, context: modelContext)
        showVenueSuggestions = !venueSuggestions.isEmpty
    }

    private func updateFolderSuggestions(_ searchText: String) {
        if searchText.isEmpty {
            showFolderSuggestions = false
            folderSuggestions = []
            return
        }

        folderSuggestions = getFolderHistory(matching: searchText)
        showFolderSuggestions = !folderSuggestions.isEmpty
    }

    private func getFolderHistory(matching searchText: String) -> [String] {
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.folder != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let allSets = try? modelContext.fetch(descriptor) else { return [] }

        // Get unique folders
        let folders = Set(allSets.compactMap { $0.folder })

        // Filter by search text
        let filtered = searchText.isEmpty
            ? Array(folders)
            : folders.filter { $0.localizedCaseInsensitiveContains(searchText) }

        // Return top 5 matches, sorted alphabetically
        return Array(filtered.sorted().prefix(5))
    }

    // MARK: - Recurrence Summary

    private func recurrenceSummary(_ rule: RecurrenceRule) -> String {
        var summary = "Repeats "

        switch rule.frequency {
        case .daily:
            summary += rule.interval == 1 ? "daily" : "every \(rule.interval) days"

        case .weekly:
            if let days = rule.daysOfWeek, !days.isEmpty {
                let dayNames = days.sorted().map { dayNumber -> String in
                    let calendar = Calendar.current
                    return calendar.shortWeekdaySymbols[dayNumber - 1]
                }
                summary += "weekly on \(dayNames.joined(separator: ", "))"
            } else {
                summary += rule.interval == 1 ? "weekly" : "every \(rule.interval) weeks"
            }

        case .monthly:
            if let day = rule.dayOfMonth {
                summary += rule.interval == 1 ? "monthly on day \(day)" : "every \(rule.interval) months on day \(day)"
            } else {
                summary += rule.interval == 1 ? "monthly" : "every \(rule.interval) months"
            }

        case .yearly:
            if let month = rule.monthOfYear {
                let monthName = Calendar.current.monthSymbols[month - 1]
                summary += rule.interval == 1 ? "yearly in \(monthName)" : "every \(rule.interval) years in \(monthName)"
            } else {
                summary += rule.interval == 1 ? "yearly" : "every \(rule.interval) years"
            }
        }

        // Add end condition
        switch rule.endType {
        case .never:
            summary += ", never ends"
        case .afterDate:
            if let endDate = rule.endDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                summary += ", until \(formatter.string(from: endDate))"
            }
        case .afterOccurrences:
            if let count = rule.endAfterOccurrences {
                summary += ", for \(count) occurrences"
            }
        }

        return summary
    }
}

// MARK: - Venue Browser Sheet

struct VenueBrowserSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedVenue: String
    @Binding var isPresented: Bool

    @State private var allVenues: [String] = []

    var body: some View {
        NavigationStack {
            Group {
                if allVenues.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No Venues")
                            .font(.headline)

                        Text("You haven't used any venues yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(allVenues, id: \.self) { venue in
                            Button {
                                selectedVenue = venue
                                isPresented = false
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(venue)
                                    Spacer()
                                    if selectedVenue == venue {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                if !selectedVenue.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Clear") {
                            selectedVenue = ""
                            isPresented = false
                        }
                    }
                }
            }
            .onAppear {
                loadVenues()
            }
        }
    }

    private func loadVenues() {
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.venue != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let allSets = try? modelContext.fetch(descriptor) else { return }

        let uniqueVenues = Set(allSets.compactMap { $0.venue })
        allVenues = Array(uniqueVenues).sorted()
    }
}

// MARK: - Folder Browser Sheet

struct FolderBrowserSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedFolder: String
    @Binding var isPresented: Bool

    @State private var allFolders: [String] = []

    var body: some View {
        NavigationStack {
            Group {
                if allFolders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("No Folders")
                            .font(.headline)

                        Text("You haven't created any folders yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(allFolders, id: \.self) { folder in
                            Button {
                                selectedFolder = folder
                                isPresented = false
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(.blue)
                                    Text(folder)
                                    Spacer()
                                    if selectedFolder == folder {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                if !selectedFolder.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Clear") {
                            selectedFolder = ""
                            isPresented = false
                        }
                    }
                }
            }
            .onAppear {
                loadFolders()
            }
        }
    }

    private func loadFolders() {
        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.folder != nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let allSets = try? modelContext.fetch(descriptor) else { return }

        let uniqueFolders = Set(allSets.compactMap { $0.folder })
        allFolders = Array(uniqueFolders).sorted()
    }
}
