//
//  EditSongView.swift
//  Lyra
//
//  Form for editing an existing song's metadata and content
//

import SwiftUI
import SwiftData
import Combine

enum EditTab: String, CaseIterable {
    case metadata = "Info"
    case content = "Content"
}

struct EditSongView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song

    @State private var selectedTab: EditTab = .metadata
    @State private var title: String
    @State private var artist: String
    @State private var originalKey: String
    @State private var capo: Int
    @State private var tempo: Int
    @State private var timeSignature: String
    @State private var notes: String
    @State private var content: String
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    // Collaboration tracking
    @State private var activeEditors: [UserPresence] = []
    @State private var isTrackingPresence: Bool = false
    @State private var presenceUpdateTimer: Timer?

    // Version history
    @State private var showVersionHistory = false
    @State private var previousContent: String

    private let presenceManager = PresenceManager.shared
    private let versionManager = VersionManager.shared

    init(song: Song) {
        self.song = song
        _title = State(initialValue: song.title)
        _artist = State(initialValue: song.artist ?? "")
        _originalKey = State(initialValue: song.originalKey ?? "")
        _capo = State(initialValue: song.capo ?? 0)
        _tempo = State(initialValue: song.tempo ?? 0)
        _timeSignature = State(initialValue: song.timeSignature ?? "")
        _notes = State(initialValue: song.notes ?? "")
        _content = State(initialValue: song.content)
        _previousContent = State(initialValue: song.content)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Live editing banner (if others are editing)
                if !activeEditors.isEmpty {
                    LiveEditingBanner(
                        editors: activeEditors,
                        currentSongID: song.id
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Tab picker
                Picker("Edit Mode", selection: $selectedTab) {
                    ForEach(EditTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                Group {
                    if selectedTab == .metadata {
                        metadataEditor
                    } else {
                        contentEditor
                    }
                }
            }
            .navigationTitle("Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Button {
                        showVersionHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSong()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showVersionHistory) {
                VersionHistoryView(song: song)
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await startPresenceTracking()

                // Listen for presence changes
                NotificationCenter.default.addObserver(
                    forName: .presenceDidChange,
                    object: nil,
                    queue: .main
                ) { _ in
                    Task {
                        await fetchActiveEditors()
                    }
                }
            }
            .onDisappear {
                Task {
                    await stopPresenceTracking()
                }
            }
            .onChange(of: selectedTab) { oldTab, newTab in
                // Update presence when switching to content editor
                Task {
                    let isEditing = newTab == .content
                    await presenceManager.updatePresence(
                        libraryID: song.sharedLibrary?.id,
                        songID: song.id,
                        isEditing: isEditing
                    )
                }
            }
            .onChange(of: content) { oldValue, newValue in
                // Track content changes for activity feed
                if selectedTab == .content && isTrackingPresence {
                    // Update cursor position (approximate based on content length)
                    let lineCount = newValue.components(separatedBy: .newlines).count
                    Task {
                        await presenceManager.updateCursor(position: lineCount)
                    }
                }
            }
        }
    }

    // MARK: - Tab Views

    @ViewBuilder
    private var metadataEditor: some View {
        Form {
            basicInfoSection
            musicalDetailsSection
            notesSection
        }
    }

    @ViewBuilder
    private var contentEditor: some View {
        VStack(spacing: 0) {
            // Help text
            VStack(alignment: .leading, spacing: 8) {
                Text("Edit ChordPro Content")
                    .font(.headline)

                Text("Format: [Chord]Lyrics. Example: [G]Amazing [C]grace, how [G]sweet the sound")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))

            // Content editor
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
                .padding(8)
        }
    }

    // MARK: - Form Sections

    @ViewBuilder
    private var basicInfoSection: some View {
        Section {
            TextField("Title", text: $title)
                .autocorrectionDisabled()

            TextField("Artist (optional)", text: $artist)
                .autocorrectionDisabled()
        } header: {
            Text("Basic Information")
        } footer: {
            Text("The song title is required")
        }
    }

    @ViewBuilder
    private var musicalDetailsSection: some View {
        Section {
            TextField("Key (optional)", text: $originalKey)
                .autocorrectionDisabled()

            Stepper("Capo: \(capo == 0 ? "None" : "Fret \(capo)")", value: $capo, in: 0...12)

            HStack {
                Text("Tempo")
                Spacer()
                TextField("BPM", value: $tempo, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            TextField("Time Signature (optional)", text: $timeSignature)
                .autocorrectionDisabled()
        } header: {
            Text("Musical Details")
        } footer: {
            Text("Enter musical details like key, capo position, tempo, and time signature")
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
        } header: {
            Text("Notes")
        } footer: {
            Text("Add any notes or reminders about this song")
        }
    }

    // MARK: - Presence Tracking

    private func startPresenceTracking() async {
        isTrackingPresence = true

        // Update presence to indicate viewing this song
        await presenceManager.updatePresence(
            libraryID: song.sharedLibrary?.id,
            songID: song.id,
            isEditing: selectedTab == .content
        )

        // Fetch other editors
        await fetchActiveEditors()

        // Set up periodic refresh
        presenceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { @MainActor in
                await fetchActiveEditors()
            }
        }
    }

    private func stopPresenceTracking() async {
        isTrackingPresence = false

        // Stop timer
        presenceUpdateTimer?.invalidate()
        presenceUpdateTimer = nil

        // Update presence to indicate no longer viewing this song
        await presenceManager.updatePresence(
            libraryID: nil,
            songID: nil,
            isEditing: false
        )

        // Clear active editors
        activeEditors = []
    }

    private func fetchActiveEditors() async {
        let editors = await presenceManager.fetchEditorsForSong(song.id)

        await MainActor.run {
            withAnimation(.spring(response: 0.3)) {
                activeEditors = editors
            }
        }
    }

    // MARK: - Actions

    private func saveSong() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Song title cannot be empty"
            showErrorAlert = true
            return
        }

        // Check if we should create a version
        let shouldCreateVersion = versionManager.shouldCreateVersion(for: song, previousContent: previousContent)

        // Update song properties
        song.title = trimmedTitle
        song.artist = artist.isEmpty ? nil : artist
        song.originalKey = originalKey.isEmpty ? nil : originalKey.uppercased()
        song.capo = capo == 0 ? nil : capo
        song.tempo = tempo == 0 ? nil : tempo
        song.timeSignature = timeSignature.isEmpty ? nil : timeSignature
        song.notes = notes.isEmpty ? nil : notes
        song.content = content
        song.modifiedAt = Date()

        do {
            // Create version if needed (before saving changes)
            if shouldCreateVersion {
                // Temporarily revert to capture old state
                let tempContent = song.content
                song.content = previousContent

                try versionManager.createVersion(
                    for: song,
                    modelContext: modelContext,
                    versionType: .autoSave,
                    changedByRecordID: presenceManager.currentUserPresence?.userRecordID
                )

                // Restore new content
                song.content = tempContent
            }

            try modelContext.save()

            // Log activity if this is a shared song
            if let library = song.sharedLibrary {
                await logEditActivity(libraryID: library.id)
            }

            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func logEditActivity(libraryID: UUID) async {
        guard let currentPresence = presenceManager.currentUserPresence else { return }

        let activity = MemberActivity(
            userRecordID: currentPresence.userRecordID,
            displayName: currentPresence.displayName,
            activityType: .songEdited,
            libraryID: libraryID,
            songID: song.id,
            songTitle: song.title
        )

        modelContext.insert(activity)
        try? modelContext.save()

        // Post notification for activity feed
        NotificationCenter.default.post(
            name: .memberActivityAdded,
            object: nil,
            userInfo: ["activity": activity]
        )
    }
}

// MARK: - Preview

#Preview {
    let song = Song(title: "Amazing Grace", artist: "John Newton")
    song.originalKey = "G"
    song.capo = 2
    song.tempo = 120
    song.timeSignature = "4/4"
    song.notes = "Play softly in the verses"

    return EditSongView(song: song)
        .modelContainer(PreviewContainer.shared.container)
}
