//
//  PerformanceView.swift
//  Lyra
//
//  Full-screen performance mode view with gesture navigation
//

import SwiftUI

struct PerformanceView: View {
    let performanceSet: PerformanceSet
    @Bindable var performanceManager: PerformanceModeManager

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var showQuickNote: Bool = false
    @State private var quickNoteText: String = ""
    @State private var showQuickActionMenu: Bool = false
    @State private var quickActionMenuPosition: CGPoint = .zero

    @StateObject private var shortcutsManager = ShortcutsManager()
    @StateObject private var footPedalManager = FootPedalManager()
    @StateObject private var gestureManager = GestureShortcutsManager()

    private var songs: [SetEntry] {
        performanceSet.sortedEntries
    }

    private var currentSong: Song? {
        guard performanceManager.currentSongIndex < songs.count else { return nil }
        return songs[performanceManager.currentSongIndex].song
    }

    private var currentSetEntry: SetEntry? {
        guard performanceManager.currentSongIndex < songs.count else { return nil }
        return songs[performanceManager.currentSongIndex]
    }

    // MARK: - Shortcuts and Gestures Setup

    private func setupShortcutsAndGestures() {
        // ShortcutsManager callbacks (performance-specific)
        shortcutsManager.onToggleAutoscroll = {
            // TODO: Toggle autoscroll on current song
        }
        shortcutsManager.onToggleMetronome = {
            // TODO: Toggle metronome on current song
        }
        shortcutsManager.onToggleAnnotations = {
            // TODO: Toggle annotations on current song
        }
        shortcutsManager.onToggleDrawing = {
            // TODO: Toggle drawing on current song
        }

        // FootPedalManager callbacks (performance-specific)
        footPedalManager.onNextSong = {
            performanceManager.goToNextSong(totalSongs: songs.count)
        }
        footPedalManager.onPreviousSong = {
            performanceManager.goToPreviousSong()
        }
        footPedalManager.onToggleAutoscroll = {
            // TODO: Toggle autoscroll on current song
        }
        footPedalManager.onToggleMetronome = {
            // TODO: Toggle metronome on current song
        }
        footPedalManager.onMarkSongPerformed = {
            performanceManager.markSongAsPerformed(index: performanceManager.currentSongIndex)
        }

        // GestureShortcutsManager callbacks
        gestureManager.onToggleAutoscroll = {
            // TODO: Toggle autoscroll on current song
        }
        gestureManager.onToggleAnnotations = {
            // TODO: Toggle annotations on current song
        }
    }

    // MARK: - Keyboard and Gesture Handlers

    private func handleKeyCommand(_ input: String, modifierFlags: UIKeyModifierFlags) {
        // Forward to both managers
        shortcutsManager.handleKeyCommand(input, modifierFlags: modifierFlags)
        footPedalManager.handleKeyCommand(input, modifierFlags: modifierFlags)
    }

    private func handleLongPress(at location: CGPoint) {
        quickActionMenuPosition = location
        showQuickActionMenu = true
        HapticManager.shared.impact(.medium)
    }

    var body: some View {
        ZStack {
            // Quick action menu overlay
            if showQuickActionMenu {
                QuickActionMenu(
                    position: quickActionMenuPosition,
                    actions: shortcutsManager.allQuickActions,
                    onSelect: { action in
                        shortcutsManager.executeQuickAction(action.action)
                        showQuickActionMenu = false
                    },
                    onDismiss: {
                        showQuickActionMenu = false
                    }
                )
                .zIndex(1000)
            }

            // Full-screen song display
            if let song = currentSong, let setEntry = currentSetEntry {
                SongDisplayView(song: song, setEntry: setEntry)
                    .id(performanceManager.currentSongIndex) // Force refresh on song change
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 100

                                if value.translation.width > threshold {
                                    // Swipe right - previous song
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        performanceManager.goToPreviousSong()
                                        dragOffset = 0
                                    }
                                } else if value.translation.width < -threshold {
                                    // Swipe left - next song
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        performanceManager.goToNextSong(totalSongs: songs.count)
                                        dragOffset = 0
                                    }
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }

                                isDragging = false
                            }
                    )
                    .onTapGesture {
                        performanceManager.toggleControls()
                    }
            } else {
                // No song available
                VStack(spacing: 20) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("No songs in set")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Button("End Performance") {
                        endPerformance()
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Performance controls overlay
            if performanceManager.showControls && !performanceManager.showSetList {
                PerformanceControlsOverlay(
                    performanceManager: performanceManager,
                    currentSongIndex: performanceManager.currentSongIndex,
                    totalSongs: songs.count,
                    onEndPerformance: {
                        endPerformance()
                    },
                    onShowSetList: {
                        performanceManager.toggleSetList()
                    },
                    onShowQuickNote: {
                        showQuickNote = true
                    }
                )
                .transition(.opacity)
            }

            // Set list overlay
            if performanceManager.showSetList {
                PerformanceSetListOverlay(
                    performanceManager: performanceManager,
                    performanceSet: performanceSet,
                    songs: songs,
                    onClose: {
                        performanceManager.toggleSetList()
                    },
                    onSelectSong: { index in
                        performanceManager.goToSong(index: index, totalSongs: songs.count)
                    }
                )
                .transition(.move(edge: .top))
            }

            // Timer display (top right)
            if performanceManager.showControls && !performanceManager.showSetList {
                VStack {
                    HStack {
                        Spacer()

                        VStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)

                            if let session = performanceManager.currentSession {
                                Text(session.formattedDuration)
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                    }

                    Spacer()
                }
                .transition(.opacity)
            }

            // Multi-finger gesture recognizer overlay
            MultiFingerGestureView(
                onLongPress: { location in
                    handleLongPress(at: location)
                },
                onTwoFingerSwipeUp: {
                    gestureManager.handleTwoFingerSwipeUp()
                },
                onTwoFingerSwipeDown: {
                    gestureManager.handleTwoFingerSwipeDown()
                },
                onTwoFingerTap: {
                    gestureManager.handleTwoFingerTap()
                },
                onThreeFingerTap: {
                    gestureManager.handleThreeFingerTap()
                }
            )
        }
        .background {
            // Keyboard event handler
            KeyboardEventHandler { input, modifierFlags in
                handleKeyCommand(input, modifierFlags: modifierFlags)
            }
            .frame(width: 0, height: 0)
        }
        .navigationBarHidden(true)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showQuickNote) {
            QuickNoteSheet(
                noteText: $quickNoteText,
                onSave: {
                    if !quickNoteText.isEmpty {
                        performanceManager.addNoteForCurrentSong(quickNoteText)
                        quickNoteText = ""
                    }
                    showQuickNote = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Inject model context for performance tracking
            performanceManager.modelContext = modelContext

            // Show controls briefly when entering
            performanceManager.showControlsBriefly()
            // Setup shortcuts and gestures
            setupShortcutsAndGestures()
        }
    }

    private func endPerformance() {
        performanceManager.endPerformance()
        dismiss()
    }
}

// MARK: - Performance Controls Overlay

struct PerformanceControlsOverlay: View {
    @Bindable var performanceManager: PerformanceModeManager
    let currentSongIndex: Int
    let totalSongs: Int
    let onEndPerformance: () -> Void
    let onShowSetList: () -> Void
    let onShowQuickNote: () -> Void

    var body: some View {
        VStack {
            // Top bar
            HStack {
                // End performance button
                Button {
                    onEndPerformance()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                        Text("End")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.red.opacity(0.9))
                    .clipShape(Capsule())
                }
                .accessibilityLabel("End performance")

                Spacer()

                // Song counter
                Button {
                    onShowSetList()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 16))

                        Text("\(currentSongIndex + 1) of \(totalSongs)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Show set list")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            // Bottom controls
            HStack(spacing: 24) {
                // Previous song
                Button {
                    performanceManager.goToPreviousSong()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(currentSongIndex == 0)
                .opacity(currentSongIndex == 0 ? 0.4 : 1.0)
                .accessibilityLabel("Previous song")

                Spacer()

                // Mark as performed
                Button {
                    performanceManager.markSongAsPerformed(index: currentSongIndex)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: performanceManager.isSongPerformed(index: currentSongIndex) ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 44))
                            .foregroundStyle(performanceManager.isSongPerformed(index: currentSongIndex) ? .green : .white)

                        Text(performanceManager.isSongPerformed(index: currentSongIndex) ? "Done" : "Mark Done")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Mark song as performed")

                Spacer()

                // Quick note
                Button {
                    onShowQuickNote()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "note.text.badge.plus")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)

                        Text("Note")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Add quick note")

                Spacer()

                // Next song
                Button {
                    performanceManager.goToNextSong(totalSongs: totalSongs)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(currentSongIndex >= totalSongs - 1)
                .opacity(currentSongIndex >= totalSongs - 1 ? 0.4 : 1.0)
                .accessibilityLabel("Next song")
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Performance Set List Overlay

struct PerformanceSetListOverlay: View {
    @Bindable var performanceManager: PerformanceModeManager
    let performanceSet: PerformanceSet
    let songs: [SetEntry]
    let onClose: () -> Void
    let onSelectSong: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(performanceSet.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("\(performanceManager.performedSongIndices.count) of \(songs.count) performed")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Close set list")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)

            // Song list
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        ForEach(Array(songs.enumerated()), id: \.element.id) { index, entry in
                            Button {
                                onSelectSong(index)
                            } label: {
                                PerformanceSetListRow(
                                    entry: entry,
                                    index: index,
                                    isCurrentSong: index == performanceManager.currentSongIndex,
                                    isPerformed: performanceManager.isSongPerformed(index: index)
                                )
                            }
                            .id(index)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(performanceManager.currentSongIndex, anchor: .center)
                    }
                }
            }
            .background(Color.black.opacity(0.95))
        }
        .background(Color.black.opacity(0.95))
        .ignoresSafeArea()
    }
}

// MARK: - Performance Set List Row

struct PerformanceSetListRow: View {
    let entry: SetEntry
    let index: Int
    let isCurrentSong: Bool
    let isPerformed: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Song number
            ZStack {
                Circle()
                    .fill(isCurrentSong ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)

                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.song.title)
                    .font(.system(size: 18, weight: isCurrentSong ? .bold : .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let artist = entry.song.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                // Metadata
                HStack(spacing: 12) {
                    if let key = entry.keyOverride ?? entry.song.currentKey {
                        Label(key, systemImage: "music.note")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    if let tempo = entry.tempoOverride ?? entry.song.tempo {
                        Label("\(tempo) BPM", systemImage: "metronome")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }

            Spacer()

            // Performed checkmark
            if isPerformed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.green)
            }

            // Current song indicator
            if isCurrentSong {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(isCurrentSong ? Color.blue.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Quick Note Sheet

struct QuickNoteSheet: View {
    @Binding var noteText: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add a quick note about this song")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top)

                TextEditor(text: $noteText)
                    .frame(height: 150)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isTextFieldFocused)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(noteText.isEmpty)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    // Would need a sample PerformanceSet for preview
    Text("Performance View Preview")
}
