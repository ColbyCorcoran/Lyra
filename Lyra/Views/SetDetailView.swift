//
//  SetDetailView.swift
//  Lyra
//
//  Detail view for a performance set showing all songs and management options
//

import SwiftUI
import SwiftData

private struct SetDetailShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct SetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode

    let performanceSet: PerformanceSet

    @State private var showSongPicker: Bool = false
    @State private var showEditSet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showOverrideEditor: Bool = false
    @State private var selectedEntry: SetEntry?
    @State private var cachedEntries: [SetEntry] = []
    @State private var showExportOptions: Bool = false
    @State private var shareItem: SetDetailShareItem?
    @State private var exportError: Error?
    @State private var showError: Bool = false
    @State private var showPerformanceMode: Bool = false
    @State private var showPresetPicker: Bool = false
    @State private var selectedPreset: PerformancePreset?
    @StateObject private var performanceManager = PerformanceModeManager()

    private var songCount: Int {
        cachedEntries.count
    }

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        listContent
    }

    @ViewBuilder
    private var listContent: some View {
        List {
            setInfoSection
            songsSection
        }
        .navigationTitle(performanceSet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showSongPicker) {
            SongPickerForSetView(performanceSet: performanceSet)
        }
        .sheet(isPresented: $showEditSet) {
            EditPerformanceSetView(performanceSet: performanceSet)
        }
        .sheet(isPresented: $showOverrideEditor) {
            if let entry = selectedEntry, let song = entry.song {
                SetEntryOverrideView(entry: entry, song: song)
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(
                exportType: .set(performanceSet),
                onExport: { format, configuration in
                    exportSet(format: format, configuration: configuration)
                }
            )
        }
        .sheet(item: $shareItem) { (item: SetDetailShareItem) in
            SetDetailShareSheet(activityItems: item.items)
        }
        .alert("Delete Set?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSet()
            }
        } message: {
            Text("This will permanently delete \"\(performanceSet.name)\". Songs will not be deleted.")
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = exportError {
                Text(error.localizedDescription)
            }
        }
        .fullScreenCover(isPresented: $showPerformanceMode) {
            PerformanceView(
                performanceSet: performanceSet,
                performanceManager: performanceManager
            )
        }
        .onAppear {
            refreshEntries()
        }
        .onChange(of: performanceSet.songEntries) { _, _ in
            refreshEntries()
        }
    }

    @ViewBuilder
    private var setInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                dateAndVenueRow
                folderAndCountRow
                descriptionView
                notesView

                // Start Performance button (only show if set has songs)
                if !cachedEntries.isEmpty {
                    startPerformanceButton
                        .padding(.top, 8)
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var startPerformanceButton: some View {
        VStack(spacing: 12) {
            Button {
                startPerformance()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start Performance")
                            .font(.headline)
                        Text("Full screen mode with song navigation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Preset quick picks
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PerformancePreset.allPresets) { preset in
                        Button {
                            selectedPreset = preset
                            startPerformance(with: preset)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: presetIcon(for: preset))
                                        .font(.system(size: 14))
                                    Text(preset.name)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.primary)

                                if let description = preset.description {
                                    Text(description)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .frame(width: 180, alignment: .leading)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var dateAndVenueRow: some View {
        HStack(spacing: 16) {
            if let date = performanceSet.scheduledDate {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formatDate(date))
                        .font(.subheadline)
                }
            }

            if let venue = performanceSet.venue, !venue.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(venue)
                        .font(.subheadline)
                }
            }
        }
    }

    @ViewBuilder
    private var folderAndCountRow: some View {
        HStack(spacing: 16) {
            if let folder = performanceSet.folder, !folder.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(folder)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "music.note.list")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("\(songCount) \(songCount == 1 ? "song" : "songs")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        if let description = performanceSet.setDescription, !description.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(description)
                    .font(.body)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var notesView: some View {
        if let notes = performanceSet.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(notes)
                    .font(.body)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var songsSection: some View {
        Section {
            if cachedEntries.isEmpty {
                SetEmptyStateView(showSongPicker: $showSongPicker)
            } else {
                ForEach(cachedEntries) { entry in
                    if let song = entry.song {
                        NavigationLink(destination: SongDisplayView(song: song, setEntry: entry)) {
                            SetEntryRowView(entry: entry, song: song, isEditing: isEditing)
                        }
                        .accessibilityLabel(accessibilityLabelForEntry(entry, song: song))
                        .accessibilityHint(isEditing ? "Swipe up or down to reorder" : "Tap to view song")
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                HapticManager.shared.selection()
                                selectedEntry = entry
                                showOverrideEditor = true
                            } label: {
                                Label("Override", systemImage: "music.note.list")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                HapticManager.shared.swipeAction()
                                removeEntry(entry)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                selectedEntry = entry
                                showOverrideEditor = true
                            } label: {
                                Label("Override Settings", systemImage: "music.note.list")
                            }

                            Divider()

                            Button(role: .destructive) {
                                removeEntry(entry)
                            } label: {
                                Label("Remove from Set", systemImage: "trash")
                            }
                        }
                    }
                }
                .onMove(perform: moveEntries)
            }
        } header: {
            Text("Songs")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !cachedEntries.isEmpty {
                EditButton()
                    .accessibilityLabel(isEditing ? "Done reordering" : "Reorder songs")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showSongPicker = true
                } label: {
                    Label("Add Songs", systemImage: "plus")
                }

                Button {
                    showEditSet = true
                } label: {
                    Label("Edit Set", systemImage: "pencil")
                }

                Divider()

                Button {
                    showExportOptions = true
                } label: {
                    Label("Export Set", systemImage: "square.and.arrow.up")
                }

                Button {
                    printSet()
                } label: {
                    Label("Print Set", systemImage: "printer")
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Set", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Set options")
        }
    }

    // MARK: - Actions

    private func refreshEntries() {
        withAnimation(.easeInOut(duration: 0.3)) {
            cachedEntries = (performanceSet.songEntries ?? []).sorted { $0.orderIndex < $1.orderIndex }
        }
    }

    private func removeEntry(_ entry: SetEntry) {
        guard var setEntries = performanceSet.songEntries else { return }

        // Remove the entry
        setEntries.removeAll(where: { $0.id == entry.id })

        // Reindex remaining entries
        for (index, remainingEntry) in setEntries.enumerated() {
            remainingEntry.orderIndex = index
        }

        performanceSet.songEntries = setEntries
        performanceSet.modifiedAt = Date()

        // Delete the entry from context
        modelContext.delete(entry)

        do {
            try modelContext.save()
            HapticManager.shared.success()
            refreshEntries()
        } catch {
            print("❌ Error removing song from set: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    private func deleteSet() {
        modelContext.delete(performanceSet)

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("❌ Error deleting set: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    private func moveEntries(from source: IndexSet, to destination: Int) {
        guard var setEntries = performanceSet.songEntries else { return }

        // Sort by orderIndex to ensure correct order
        setEntries.sort { $0.orderIndex < $1.orderIndex }

        // Move the entries
        setEntries.move(fromOffsets: source, toOffset: destination)

        // Reindex all entries to reflect new order
        for (index, entry) in setEntries.enumerated() {
            entry.orderIndex = index
        }

        performanceSet.songEntries = setEntries
        performanceSet.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.selection()
            refreshEntries()
        } catch {
            print("❌ Error reordering songs: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Tomorrow at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    private func accessibilityLabelForEntry(_ entry: SetEntry, song: Song) -> String {
        var label = "Song \(entry.orderIndex + 1): \(song.title)"

        if let artist = song.artist {
            label += " by \(artist)"
        }

        let hasOverrides = entry.keyOverride != nil || entry.capoOverride != nil || entry.tempoOverride != nil

        if hasOverrides {
            label += ". Has override settings"

            if let keyOverride = entry.keyOverride {
                label += ". Key overridden to \(keyOverride)"
            }
            if let capoOverride = entry.capoOverride {
                label += ". Capo overridden to \(capoOverride > 0 ? "fret \(capoOverride)" : "no capo")"
            }
            if let tempoOverride = entry.tempoOverride {
                label += ". Tempo overridden to \(tempoOverride) BPM"
            }
        } else {
            if let key = song.originalKey {
                label += ". Key: \(key)"
            }
            if let capo = song.capo, capo > 0 {
                label += ". Capo on fret \(capo)"
            }
        }

        return label
    }

    // MARK: - Performance Mode

    private func startPerformance(with preset: PerformancePreset? = nil) {
        performanceManager.startPerformance(set: performanceSet, preset: preset)
        showPerformanceMode = true
    }

    private func presetIcon(for preset: PerformancePreset) -> String {
        switch preset.name {
        case "Solo Performance":
            return "person.fill"
        case "With Band":
            return "music.note.list"
        case "Teaching":
            return "book.fill"
        case "Night Performance":
            return "moon.fill"
        default:
            return "star.fill"
        }
    }

    // MARK: - Export Actions

    private func exportSet(format: ExportManager.ExportFormat, configuration: PDFExporter.PDFConfiguration) {
        Task {
            do {
                let data = try ExportManager.shared.exportSet(performanceSet, format: format, configuration: configuration)
                let filename = "\(performanceSet.name).\(format.fileExtension)"

                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try data.write(to: tempURL)

                // Show share sheet
                await MainActor.run {
                    shareItem = SetDetailShareItem(items: [tempURL])
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showError = true
                    HapticManager.shared.operationFailed()
                }
            }
        }
    }

    private func printSet() {
        Task {
            do {
                let data = try ExportManager.shared.exportSet(performanceSet, format: .pdf)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(performanceSet.name).pdf")
                try data.write(to: tempURL)

                await MainActor.run {
                    let printController = UIPrintInteractionController.shared
                    printController.printingItem = tempURL

                    let printInfo = UIPrintInfo.printInfo()
                    printInfo.outputType = .general
                    printInfo.jobName = performanceSet.name
                    printController.printInfo = printInfo

                    printController.present(animated: true) { _, _, _ in }
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showError = true
                    HapticManager.shared.operationFailed()
                }
            }
        }
    }
}

// MARK: - Set Entry Row View

struct SetEntryRowView: View {
    let entry: SetEntry
    let song: Song
    var isEditing: Bool = false

    private var hasOverrides: Bool {
        entry.keyOverride != nil || entry.capoOverride != nil || entry.tempoOverride != nil || (entry.notes != nil && !entry.notes!.isEmpty)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Order number with styling
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(entry.orderIndex + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(song.title)
                        .font(.headline)

                    // Override indicator badge
                    if hasOverrides {
                        HStack(spacing: 3) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 9, weight: .semibold))
                            Text("OVERRIDE")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.indigo)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .accessibilityLabel("Has override settings")
                    }
                }

                if let artist = song.artist {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Show overrides or default values
                HStack(spacing: 6) {
                    if let keyOverride = entry.keyOverride {
                        OverrideBadge(
                            icon: "music.note",
                            text: keyOverride,
                            color: .blue,
                            isOverride: true,
                            originalValue: song.originalKey
                        )
                    } else if let key = song.originalKey {
                        SongMetadataBadge(
                            icon: "music.note",
                            text: key,
                            color: .blue
                        )
                    }

                    if let capoOverride = entry.capoOverride {
                        OverrideBadge(
                            icon: "guitars",
                            text: capoOverride > 0 ? "Capo \(capoOverride)" : "No Capo",
                            color: .orange,
                            isOverride: true,
                            originalValue: song.capo.map { "Capo \($0)" }
                        )
                    } else if let capo = song.capo, capo > 0 {
                        SongMetadataBadge(
                            icon: "guitars",
                            text: "Capo \(capo)",
                            color: .orange
                        )
                    }

                    if let tempoOverride = entry.tempoOverride {
                        OverrideBadge(
                            icon: "metronome",
                            text: "\(tempoOverride) BPM",
                            color: .purple,
                            isOverride: true,
                            originalValue: song.tempo.map { "\($0) BPM" }
                        )
                    }

                    if let notes = entry.notes, !notes.isEmpty {
                        SongMetadataBadge(
                            icon: "note.text",
                            text: "Notes",
                            color: .purple
                        )
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            // Show drag indicator when editing
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Set Empty State View

struct SetEmptyStateView: View {
    @Binding var showSongPicker: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Songs Yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Add songs to this set to build your performance lineup")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showSongPicker = true
            } label: {
                Label("Add Songs", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Override Badge

struct OverrideBadge: View {
    let icon: String
    let text: String
    let color: Color
    var isOverride: Bool = false
    var originalValue: String?

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))

            Text(text)
                .font(.system(size: 11, weight: .semibold))

            if isOverride {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 7, weight: .bold))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(isOverride ? color.opacity(0.25) : color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .overlay {
            if isOverride {
                Capsule()
                    .strokeBorder(color.opacity(0.5), lineWidth: 1)
            }
        }
    }
}

// MARK: - Share Sheet

private struct SetDetailShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Set with Songs") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, Song.self, SetEntry.self, configurations: config)

    let performanceSet = PerformanceSet(name: "Sunday Morning Service", scheduledDate: Date())
    performanceSet.venue = "Main Sanctuary"
    performanceSet.folder = "Church"
    performanceSet.notes = "Start with worship, end with hymn"
    performanceSet.setDescription = "Weekly Sunday morning worship service"

    let song1 = Song(title: "Amazing Grace", artist: "John Newton", originalKey: "G")
    song1.capo = 2
    let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg", originalKey: "C")
    let song3 = Song(title: "It Is Well", artist: "Horatio Spafford", originalKey: "D")
    song3.capo = 4

    let entry1 = SetEntry(song: song1, orderIndex: 0)
    entry1.performanceSet = performanceSet
    let entry2 = SetEntry(song: song2, orderIndex: 1)
    entry2.performanceSet = performanceSet
    entry2.keyOverride = "D"
    let entry3 = SetEntry(song: song3, orderIndex: 2)
    entry3.performanceSet = performanceSet

    performanceSet.songEntries = [entry1, entry2, entry3]

    container.mainContext.insert(performanceSet)
    container.mainContext.insert(song1)
    container.mainContext.insert(song2)
    container.mainContext.insert(song3)
    container.mainContext.insert(entry1)
    container.mainContext.insert(entry2)
    container.mainContext.insert(entry3)

    return NavigationStack {
        SetDetailView(performanceSet: performanceSet)
    }
    .modelContainer(container)
}

#Preview("Empty Set") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PerformanceSet.self, Song.self, SetEntry.self, configurations: config)

    let performanceSet = PerformanceSet(name: "New Set", scheduledDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()))
    performanceSet.venue = "Chapel"

    container.mainContext.insert(performanceSet)

    return NavigationStack {
        SetDetailView(performanceSet: performanceSet)
    }
    .modelContainer(container)
}
