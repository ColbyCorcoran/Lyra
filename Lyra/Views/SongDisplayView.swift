//
//  SongDisplayView.swift
//  Lyra
//
//  Beautiful display view for parsed ChordPro songs
//  This is the MOST IMPORTANT view in the app
//

import SwiftUI
import SwiftData
import PDFKit

enum SongViewMode {
    case text
    case pdf
}

struct SongDisplayView: View {
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let setEntry: SetEntry?

    @State private var parsedSong: ParsedSong?
    @State private var fontSize: CGFloat = 16
    @State private var showDisplaySettings: Bool = false
    @State private var displaySettings: DisplaySettings
    @State private var isLoadingSong: Bool = false
    @State private var showEditSongSheet: Bool = false
    @State private var showQuickBookPicker: Bool = false
    @State private var showQuickSetPicker: Bool = false
    @State private var viewMode: SongViewMode = .text
    @State private var showExtractText: Bool = false
    @State private var showAutoscrollDuration: Bool = false
    @State private var showSpeedZones: Bool = false
    @State private var showTimelineRecording: Bool = false
    @State private var showMarkers: Bool = false
    @State private var showPresets: Bool = false
    @State private var showTranspose: Bool = false
    @State private var temporaryTransposeSemitones: Int = 0
    @State private var temporaryTransposePreferSharps: Bool = true
    @State private var showCapo: Bool = false
    @State private var capoDisplayMode: CapoDisplayMode = .capo
    @State private var contentHeight: CGFloat = 0
    @State private var visibleHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isAnnotationMode: Bool = false
    @State private var isDrawingMode: Bool = false
    @State private var containerSize: CGSize = .zero

    @StateObject private var autoscrollManager = AutoscrollManager()

    /// Get the active capo position (from set override or song)
    private var activeCapo: Int {
        setEntry?.capoOverride ?? song.capo ?? 0
    }

    init(song: Song, setEntry: SetEntry? = nil) {
        self.song = song
        self.setEntry = setEntry
        _displaySettings = State(initialValue: song.displaySettings)
    }

    // MARK: - Computed Properties

    private var hasPDFAttachment: Bool {
        song.attachments?.contains(where: { $0.fileType.lowercased() == "pdf" }) ?? false
    }

    private var pdfAttachment: Attachment? {
        song.attachments?.first(where: { $0.fileType.lowercased() == "pdf" })
    }

    private var hasTextContent: Bool {
        !song.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showViewModePicker: Bool {
        hasPDFAttachment && hasTextContent
    }

    /// Get displayed content (with transpose and/or capo applied)
    private var displayedContent: String {
        var content = song.content

        // Step 1: Apply transpose if active
        if temporaryTransposeSemitones != 0 {
            content = TransposeEngine.transposeContent(
                content,
                by: temporaryTransposeSemitones,
                preferSharps: temporaryTransposePreferSharps
            )
        }

        // Step 2: Apply capo chords if in capo display mode
        if capoDisplayMode == .capo && activeCapo > 0 {
            content = CapoEngine.capoContent(
                content,
                capoFret: activeCapo,
                preferSharps: temporaryTransposePreferSharps
            )
        }

        return content
    }

    var body: some View {
        VStack(spacing: 0) {
            // Set context banner
            if let entry = setEntry, let set = entry.performanceSet {
                SetContextBanner(setName: set.name, songPosition: entry.orderIndex + 1, totalSongs: set.songEntries?.count ?? 0)
            }

            // View mode picker (if both PDF and text exist)
            if showViewModePicker {
                viewModePicker
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(.regularMaterial)
            }

            // Capo badge (when capo is active)
            if activeCapo > 0 && viewMode == .text {
                capoBadge
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
            }

            // Content based on view mode
            if viewMode == .pdf, let attachment = pdfAttachment {
                pdfContentView(attachment: attachment)
            } else {
                textContentView
            }
        }
        .background(displaySettings.backgroundColorValue())
        .preferredColorScheme(displaySettings.darkModePreference.colorScheme)
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Edit button (only for text view)
            if viewMode == .text {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showEditSongSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit song")
                    .accessibilityHint("Opens song metadata editor")
                }
            }

            // Transpose button (only for text view)
            if viewMode == .text {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTranspose = true
                    } label: {
                        ZStack {
                            Image(systemName: "arrow.up.arrow.down")

                            // Show indicator if temporarily transposed
                            if temporaryTransposeSemitones != 0 {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .accessibilityLabel("Transpose")
                    .accessibilityHint(temporaryTransposeSemitones != 0 ? "Currently transposed by \(temporaryTransposeSemitones) semitones" : "Transpose this song")
                }
            }

            // Capo button (only for text view)
            if viewMode == .text {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCapo = true
                    } label: {
                        ZStack {
                            Image(systemName: "guitars")

                            // Show indicator if capo is active
                            if activeCapo > 0 {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .accessibilityLabel("Capo")
                    .accessibilityHint(activeCapo > 0 ? "Capo on fret \(activeCapo)" : "Set capo position")
                }
            }

            // Display Settings button (only for text view)
            if viewMode == .text {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDisplaySettings = true
                    } label: {
                        Image(systemName: "textformat.size")
                    }
                    .accessibilityLabel("Display settings")
                    .accessibilityHint("Adjust font size, colors, and spacing")
                }
            }

            // Annotate button (only for text view)
            if viewMode == .text {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAnnotationMode.toggle()
                        if isAnnotationMode {
                            isDrawingMode = false // Exit drawing mode
                        }
                        HapticManager.shared.selection()
                    } label: {
                        ZStack {
                            Image(systemName: isAnnotationMode ? "note.text.badge.plus" : "note.text")

                            // Show indicator if annotation mode is active
                            if isAnnotationMode {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .accessibilityLabel("Annotations")
                    .accessibilityHint(isAnnotationMode ? "Exit annotation mode" : "Add sticky notes")
                }
            }

            // Draw button (only for text view)
            if viewMode == .text {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isDrawingMode.toggle()
                        if isDrawingMode {
                            isAnnotationMode = false // Exit annotation mode
                        }
                        HapticManager.shared.selection()
                    } label: {
                        ZStack {
                            Image(systemName: isDrawingMode ? "pencil.tip.crop.circle.badge.plus" : "pencil.tip.crop.circle")

                            // Show indicator if drawing mode is active
                            if isDrawingMode {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .accessibilityLabel("Drawing")
                    .accessibilityHint(isDrawingMode ? "Exit drawing mode" : "Draw on chart")
                }
            }

            // Extract Text button (only for PDF view)
            if viewMode == .pdf, hasPDFAttachment {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExtractText = true
                    } label: {
                        Image(systemName: "doc.text.magnifyingglass")
                    }
                    .accessibilityLabel("Extract text from PDF")
                    .accessibilityHint("Convert PDF to editable text")
                }
            }

            // Organization menu
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    OrganizationMenuView(song: song)
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .accessibilityLabel("Add to collection")
                .accessibilityHint("Add this song to books or sets")
            }

            // More menu
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Font size controls
                    Section("Font Size") {
                        Button {
                            fontSize = max(12, fontSize - 2)
                        } label: {
                            Label("Decrease", systemImage: "textformat.size.smaller")
                        }

                        Button {
                            fontSize = min(24, fontSize + 2)
                        } label: {
                            Label("Increase", systemImage: "textformat.size.larger")
                        }

                        Button {
                            fontSize = 16
                        } label: {
                            Label("Reset to Default", systemImage: "arrow.counterclockwise")
                        }
                    }

                    Divider()

                    // Autoscroll
                    if viewMode == .text {
                        Section("Autoscroll") {
                            Button {
                                showAutoscrollDuration = true
                            } label: {
                                Label("Configure Duration", systemImage: "timer")
                            }

                            Toggle(isOn: Binding(
                                get: { song.autoscrollEnabled },
                                set: { enabled in
                                    song.autoscrollEnabled = enabled
                                    try? modelContext.save()
                                }
                            )) {
                                Label("Enable Autoscroll", systemImage: song.autoscrollEnabled ? "play.circle.fill" : "play.circle")
                            }
                        }

                        Section("Advanced Autoscroll") {
                            Button {
                                showSpeedZones = true
                            } label: {
                                Label("Speed Zones", systemImage: "gauge.with.dots.needle.67percent")
                            }

                            Button {
                                showTimelineRecording = true
                            } label: {
                                Label("Timeline Recording", systemImage: "waveform")
                            }

                            Button {
                                showMarkers = true
                            } label: {
                                Label("Smart Markers", systemImage: "mappin.circle")
                            }

                            Button {
                                showPresets = true
                            } label: {
                                Label("Presets", systemImage: "square.stack.3d.up")
                            }
                        }
                    }

                    Divider()

                    // Future features
                    Section {
                        Button {
                            // TODO: Print or export
                        } label: {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }
                        .disabled(true)

                        Button {
                            // TODO: Share
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .disabled(true)
                    }

                    Divider()

                    // Song info
                    Section {
                        Button {
                            // TODO: Show song info/metadata
                        } label: {
                            Label("Song Info", systemImage: "info.circle")
                        }
                        .disabled(true)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showDisplaySettings) {
            DisplaySettingsSheet(song: song)
                .onDisappear {
                    // Refresh display settings when sheet closes
                    displaySettings = song.displaySettings
                }
        }
        .sheet(isPresented: $showEditSongSheet) {
            EditSongView(song: song)
        }
        .sheet(isPresented: $showQuickBookPicker) {
            QuickOrganizationPicker(song: song, mode: .book)
        }
        .sheet(isPresented: $showQuickSetPicker) {
            QuickOrganizationPicker(song: song, mode: .set)
        }
        .sheet(isPresented: $showExtractText) {
            if let attachment = pdfAttachment,
               let pdfData = attachment.fileData ?? loadPDFData(from: attachment),
               let pdfDocument = PDFDocument(data: pdfData) {
                ExtractTextFromPDFView(pdfDocument: pdfDocument, song: song)
                    .onDisappear {
                        // Refresh song content and switch to text view if extraction was successful
                        if hasTextContent {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewMode = .text
                            }
                            parseSong()
                        }
                    }
            }
        }
        .sheet(isPresented: $showAutoscrollDuration) {
            AutoscrollDurationView(song: song)
        }
        .sheet(isPresented: $showSpeedZones) {
            if let parsed = parsedSong {
                SectionSpeedZoneEditorView(song: song, parsedSong: parsed)
            }
        }
        .sheet(isPresented: $showTimelineRecording) {
            TimelineRecordingView(song: song, autoscrollManager: autoscrollManager)
        }
        .sheet(isPresented: $showMarkers) {
            AutoscrollMarkersView(song: song)
        }
        .sheet(isPresented: $showPresets) {
            AutoscrollPresetsView(song: song, autoscrollManager: autoscrollManager)
        }
        .sheet(isPresented: $showTranspose) {
            TransposeView(song: song) { semitones, preferSharps, saveMode in
                handleTransposition(semitones: semitones, preferSharps: preferSharps, saveMode: saveMode)
            }
        }
        .sheet(isPresented: $showCapo) {
            CapoView(song: song, setEntry: setEntry) { capoFret in
                handleCapoChange(capoFret: capoFret)
            }
        }
        .background {
            // Keyboard shortcuts (invisible buttons)
            Button("") {
                showQuickBookPicker = true
            }
            .keyboardShortcut("b", modifiers: .command)
            .hidden()

            Button("") {
                showQuickSetPicker = true
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .hidden()
        }
        .onAppear {
            parseSong()
            trackSongView()
            // Default to PDF view if no text content exists
            if hasPDFAttachment && !hasTextContent {
                viewMode = .pdf
            }
        }
        .onChange(of: song.content) { _, _ in
            parseSong()
        }
        .onChange(of: displaySettings) { _, _ in
            // Update when display settings change
            fontSize = displaySettings.fontSize
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var viewModePicker: some View {
        Picker("View Mode", selection: $viewMode) {
            if hasTextContent {
                Label("Text", systemImage: "text.alignleft")
                    .tag(SongViewMode.text)
            }
            if hasPDFAttachment {
                Label("PDF", systemImage: "doc.fill")
                    .tag(SongViewMode.pdf)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("View mode")
        .accessibilityHint("Switch between text and PDF views")
    }

    private var capoBadge: some View {
        HStack(spacing: 12) {
            // Capo indicator
            HStack(spacing: 6) {
                Image(systemName: "guitars")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Capo Fret \(activeCapo)")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let key = song.currentKey {
                        let playKey = CapoEngine.writtenKey(soundingKey: key, capoFret: activeCapo) ?? "?"
                        Text("Play \(playKey) shapes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Display mode toggle
            Menu {
                Picker("Display", selection: $capoDisplayMode) {
                    ForEach(CapoDisplayMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .onChange(of: capoDisplayMode) { _, _ in
                    parseSong()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: capoDisplayMode.icon)
                    Text(capoDisplayMode == .actual ? "Actual" : capoDisplayMode == .capo ? "Capo" : "Both")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func pdfContentView(attachment: Attachment) -> some View {
        Group {
            if let pdfData = attachment.fileData ?? loadPDFData(from: attachment),
               let pdfDocument = PDFDocument(data: pdfData) {
                PDFViewerView(pdfDocument: pdfDocument, filename: attachment.filename)
            } else {
                // PDF loading error
                VStack(spacing: 16) {
                    Image(systemName: "doc.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("Unable to load PDF")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("The PDF file may be corrupted or missing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if hasTextContent {
                        Button("View Text Version") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewMode = .text
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }

    @ViewBuilder
    private var textContentView: some View {
        ZStack {
            VStack(spacing: 0) {
                // Sticky Header
                if let parsed = parsedSong {
                    SongHeaderView(parsedSong: parsed, song: song, setEntry: setEntry)
                        .background(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                }

                // Scrollable Content with ScrollViewReader
                ScrollViewReader { proxy in
                    GeometryReader { geometryOuter in
                        ScrollView {
                            GeometryReader { geometryInner in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometryInner.frame(in: .named("scrollView")).minY)
                            }
                            .frame(height: 0)

                            VStack(alignment: .leading, spacing: 0) {
                                if isLoadingSong {
                                    // Loading state
                                    VStack(spacing: 16) {
                                        ProgressView()
                                        Text("Loading song...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding()
                                } else if let parsed = parsedSong {
                                    // Sections
                                    ForEach(Array(parsed.sections.enumerated()), id: \.element.id) { index, section in
                                        SongSectionView(section: section, settings: displaySettings)
                                            .padding(.horizontal)
                                            .padding(.bottom, index < parsed.sections.count - 1 ? 32 : 16)
                                            .id("section-\(index)")
                                    }
                                } else {
                                    // Empty state
                                    VStack(spacing: 16) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 48))
                                            .foregroundStyle(.secondary)

                                        Text("No content available")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)

                                        if hasPDFAttachment {
                                            Button("View PDF") {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    viewMode = .pdf
                                                }
                                            }
                                            .buttonStyle(.bordered)
                                            .padding(.top, 8)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding()
                                }
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                            .id("scrollContent")
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: ContentHeightPreferenceKey.self, value: geo.size.height)
                                }
                            )
                        }
                        .coordinateSpace(name: "scrollView")
                        .disabled(isDrawingMode) // Disable scrolling in drawing mode
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = -value
                            if scrollOffset > 0 {
                                autoscrollManager.handleManualScroll()
                            }
                        }
                        .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                            contentHeight = height
                            visibleHeight = geometryOuter.size.height
                            configureAutoscroll()
                        }
                        .onAppear {
                            configureAutoscroll()
                        }
                        .onTapGesture {
                            autoscrollManager.handleTap()
                        }
                    }
                    .onChange(of: autoscrollManager.isScrolling) { _, _ in
                        configureAutoscrollProxy(proxy: proxy)
                    }
                }
            }

            // Autoscroll controls overlay
            if song.autoscrollEnabled && viewMode == .text {
                AutoscrollControlsView(
                    autoscrollManager: autoscrollManager,
                    onJumpToTop: {
                        // Handled by manager
                    },
                    onConfigureDuration: {
                        showAutoscrollDuration = true
                    }
                )
            }

            // Autoscroll indicator
            if song.autoscrollEnabled && viewMode == .text {
                VStack {
                    HStack {
                        Spacer()
                        AutoscrollIndicatorView(autoscrollManager: autoscrollManager)
                            .padding(.top, 8)
                            .padding(.trailing, 12)
                    }
                    Spacer()
                }
            }

            // Annotations overlay
            GeometryReader { geometry in
                AnnotationsOverlayView(
                    song: song,
                    containerSize: geometry.size,
                    isAnnotationMode: isAnnotationMode,
                    onExitAnnotationMode: {
                        isAnnotationMode = false
                    }
                )
                .allowsHitTesting(isAnnotationMode || !song.autoscrollEnabled || !autoscrollManager.isScrolling)
                .onAppear {
                    containerSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    containerSize = newSize
                }
            }

            // Drawing overlay
            GeometryReader { geometry in
                DrawingOverlayView(
                    song: song,
                    containerSize: geometry.size,
                    isDrawingMode: isDrawingMode,
                    onExitDrawingMode: {
                        isDrawingMode = false
                    }
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func loadPDFData(from attachment: Attachment) -> Data? {
        guard let filePath = attachment.filePath else { return nil }

        // Construct full path in documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(filePath)

        do {
            return try Data(contentsOf: fileURL)
        } catch {
            print("❌ Error loading PDF from \(filePath): \(error.localizedDescription)")
            return nil
        }
    }

    private func parseSong() {
        isLoadingSong = true

        Task {
            // Capture displayed content (may be transposed)
            let contentToParse = displayedContent

            let parsed = await Task.detached(priority: .userInitiated) {
                return ChordProParser.parse(contentToParse)
            }.value

            await MainActor.run {
                parsedSong = parsed
                isLoadingSong = false
            }
        }
    }

    /// Track that the user viewed this song
    private func trackSongView() {
        song.lastViewed = Date()
        song.timesViewed += 1

        // Save to SwiftData
        do {
            try modelContext.save()
        } catch {
            print("Error tracking song view: \(error)")
        }
    }

    // MARK: - Transposition Methods

    /// Handle transposition based on save mode
    private func handleTransposition(semitones: Int, preferSharps: Bool, saveMode: TransposeSaveMode) {
        switch saveMode {
        case .temporary:
            // Apply temporary transposition (session only)
            temporaryTransposeSemitones = semitones
            temporaryTransposePreferSharps = preferSharps

            // Update parsed song with transposed content
            parseSong()

            HapticManager.shared.success()

        case .permanent:
            // Permanently transpose the song
            applyPermanentTransposition(semitones: semitones, preferSharps: preferSharps)

        case .duplicate:
            // Create a new song with transposed content
            duplicateSongWithTransposition(semitones: semitones, preferSharps: preferSharps)
        }
    }

    /// Apply permanent transposition to the song
    private func applyPermanentTransposition(semitones: Int, preferSharps: Bool) {
        // Preserve original key if not already set
        if song.originalKey == nil {
            song.originalKey = song.currentKey ?? "C"
        }

        // Transpose content
        song.content = TransposeEngine.transposeContent(
            song.content,
            by: semitones,
            preferSharps: preferSharps
        )

        // Update current key
        let oldKey = song.currentKey ?? song.originalKey ?? "C"
        song.currentKey = TransposeEngine.transpose(oldKey, by: semitones, preferSharps: preferSharps)

        // Update capo if transposing down
        if semitones < 0 {
            let suggestedCapo = TransposeEngine.calculateCapo(for: semitones)
            if suggestedCapo > 0 {
                song.capo = suggestedCapo
            }
        }

        // Reset temporary transposition
        temporaryTransposeSemitones = 0

        // Update timestamp
        song.modifiedAt = Date()

        // Save to database
        do {
            try modelContext.save()

            // Reparse song
            parseSong()

            HapticManager.shared.success()
        } catch {
            print("Error saving transposed song: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    /// Create a duplicate song with transposed content
    private func duplicateSongWithTransposition(semitones: Int, preferSharps: Bool) {
        // Create new song
        let newSong = Song(
            title: song.title,
            artist: song.artist,
            content: TransposeEngine.transposeContent(
                song.content,
                by: semitones,
                preferSharps: preferSharps
            ),
            contentFormat: song.contentFormat,
            originalKey: song.originalKey ?? song.currentKey
        )

        // Copy metadata
        newSong.album = song.album
        newSong.year = song.year
        newSong.copyright = song.copyright
        newSong.ccliNumber = song.ccliNumber
        newSong.tempo = song.tempo
        newSong.timeSignature = song.timeSignature
        newSong.notes = song.notes
        newSong.tags = song.tags

        // Set transposed key
        let oldKey = song.currentKey ?? song.originalKey ?? "C"
        newSong.currentKey = TransposeEngine.transpose(oldKey, by: semitones, preferSharps: preferSharps)

        // Set capo if transposing down
        if semitones < 0 {
            let suggestedCapo = TransposeEngine.calculateCapo(for: semitones)
            if suggestedCapo > 0 {
                newSong.capo = suggestedCapo
            }
        }

        // Copy display settings
        if song.hasCustomDisplaySettings {
            newSong.displaySettingsData = song.displaySettingsData
        }

        // Update title to indicate transposition
        let transposedKey = newSong.currentKey ?? "Unknown"
        newSong.title += " (\(transposedKey))"

        // Insert into database
        modelContext.insert(newSong)

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("Error creating duplicate song: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    // MARK: - Capo Methods

    /// Handle capo position change
    private func handleCapoChange(capoFret: Int) {
        if let entry = setEntry {
            // If viewing in a set, update the set-specific override
            entry.capoOverride = capoFret == 0 ? nil : capoFret
        } else {
            // Otherwise update the song's default capo
            song.capo = capoFret == 0 ? nil : capoFret
            song.modifiedAt = Date()
        }

        // Save to database
        do {
            try modelContext.save()

            // Reparse song with new capo settings
            parseSong()

            HapticManager.shared.success()
        } catch {
            print("Error saving capo: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    // MARK: - Autoscroll Methods

    private func configureAutoscroll() {
        let duration = TimeInterval(song.autoscrollDuration ?? 180)

        autoscrollManager.configure(
            duration: duration,
            contentHeight: contentHeight,
            visibleHeight: visibleHeight,
            onScrollToPosition: { _ in
                // Handled by proxy in configureAutoscrollProxy
            }
        )

        // Load advanced configuration (sections, timeline, markers)
        autoscrollManager.loadConfiguration(from: song, parsedSong: parsedSong)
    }

    private func configureAutoscrollProxy(proxy: ScrollViewProxy) {
        autoscrollManager.configure(
            duration: TimeInterval(song.autoscrollDuration ?? 180),
            contentHeight: contentHeight,
            visibleHeight: visibleHeight,
            onScrollToPosition: { position in
                withAnimation(.linear(duration: 0.016)) { // 60fps
                    proxy.scrollTo("scrollContent", anchor: UnitPoint(x: 0, y: min(1.0, position / contentHeight)))
                }
            }
        )
    }
}

// MARK: - Preference Keys

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Song Header View

/*
 Enhanced SongHeaderView with professional metadata display

 Features:
 - Large title and artist at top
 - Metadata card with SF Symbols icons
 - Light gray background with rounded corners
 - Compact, responsive layout
 - Only shows non-empty fields
 */
struct SongHeaderView: View {
    let parsedSong: ParsedSong
    let song: Song
    var setEntry: SetEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title Section
            VStack(alignment: .leading, spacing: 6) {
                // Title
                if let title = parsedSong.title {
                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary)
                }

                // Subtitle (if present)
                if let subtitle = parsedSong.subtitle {
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Artist
                if let artist = parsedSong.artist {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        Text(artist)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Organization pills (books/sets this song belongs to)
            OrganizationPillsView(song: song)

            // Musical Metadata Card
            if hasMusicalMetadata {
                VStack(alignment: .leading, spacing: 12) {
                    // Key and Tempo row
                    HStack(spacing: 20) {
                        if let key = effectiveKey {
                            MetadataItem(
                                icon: "music.note",
                                label: "Key",
                                value: key,
                                isOverride: setEntry?.keyOverride != nil,
                                originalValue: parsedSong.key
                            )
                        }

                        if let tempo = effectiveTempo {
                            MetadataItem(
                                icon: "metronome",
                                label: "Tempo",
                                value: "\(tempo) BPM",
                                isOverride: setEntry?.tempoOverride != nil,
                                originalValue: parsedSong.tempo.map { "\($0) BPM" }
                            )
                        }

                        Spacer()
                    }

                    // Time signature and Capo row
                    HStack(spacing: 20) {
                        if let time = parsedSong.timeSignature {
                            MetadataItem(
                                icon: "waveform",
                                label: "Time",
                                value: time
                            )
                        }

                        if let capo = effectiveCapo, capo > 0 {
                            MetadataItem(
                                icon: "guitar",
                                label: "Capo",
                                value: "\(capo)",
                                isOverride: setEntry?.capoOverride != nil,
                                originalValue: parsedSong.capo.map { "\($0)" }
                            )
                        }

                        Spacer()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }

            // Copyright info (if present)
            if let copyright = parsedSong.copyright {
                HStack(spacing: 6) {
                    Image(systemName: "c.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)

                    Text(copyright)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Check if there's any musical metadata to display
    private var hasMusicalMetadata: Bool {
        parsedSong.key != nil ||
        parsedSong.tempo != nil ||
        parsedSong.timeSignature != nil ||
        (parsedSong.capo != nil && parsedSong.capo! > 0)
    }

    // MARK: - Effective Values (with overrides)

    private var effectiveKey: String? {
        setEntry?.keyOverride ?? parsedSong.key
    }

    private var effectiveCapo: Int? {
        setEntry?.capoOverride ?? parsedSong.capo
    }

    private var effectiveTempo: Int? {
        setEntry?.tempoOverride ?? parsedSong.tempo
    }
}

// MARK: - Metadata Item

/*
 Individual metadata item with icon, label, and value
 Example: [music.note icon] Key: G
 */
struct MetadataItem: View {
    let icon: String
    let label: String
    let value: String
    var isOverride: Bool = false
    var originalValue: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isOverride ? .indigo : .blue)
                    .frame(width: 20)

                // Label and Value
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isOverride ? .indigo : .primary)

                    if isOverride {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.indigo)
                    }
                }
            }

            // Override indicator
            if isOverride, let original = originalValue {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 8))
                    Text("Original: \(original)")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.tertiary)
                .padding(.leading, 28)
            }
        }
    }
}

// MARK: - Song Section View

struct SongSectionView: View {
    let section: SongSection
    let settings: DisplaySettings

    var body: some View {
        VStack(alignment: .leading, spacing: settings.actualLineSpacing) {
            // Section Label
            Text(section.label)
                .font(settings.titleFont(size: settings.fontSize + 2))
                .foregroundStyle(settings.sectionLabelColorValue())
                .padding(.bottom, 4)

            // Section Lines
            ForEach(Array(section.lines.enumerated()), id: \.offset) { index, line in
                ChordLineView(line: line, settings: settings)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, settings.sectionSpacing)
    }
}

// MARK: - Chord Line View

/*
 Enhanced ChordLineView with pixel-perfect chord alignment

 Key improvements:
 1. Uses position-based layout with ZStack for precise chord placement
 2. Calculates exact character positions using monospaced font metrics
 3. Handles edge cases: start/end chords, multiple spaces, long chord names
 4. Customizable spacing and colors
 5. Preserves exact whitespace in lyrics

 Example rendering:

 Input: "I [C]love [Am]you [F]so [G]much"

 Before (naive approach - misaligned):
   C    Am   F    G
   I love you so much

 After (position-based - perfectly aligned):
   C   Am  F  G
   I love you so much
 */
struct ChordLineView: View {
    let line: SongLine
    let settings: DisplaySettings

    // Derived properties
    private var fontSize: CGFloat { settings.fontSize }
    private var chordFontSizeOffset: CGFloat { -2 }
    private var chordToLyricSpacing: CGFloat { settings.spacing }
    private var chordColor: Color { settings.chordColorValue() }
    private var lyricsColor: Color { settings.lyricsColorValue() }

    var body: some View {
        switch line.type {
        case .lyrics:
            renderLyricsWithChords()
        case .chordsOnly:
            renderChordsOnly()
        case .blank:
            Text(" ")
                .font(settings.lyricsFont())
        case .comment:
            Text(line.text)
                .font(settings.lyricsFont(size: fontSize - 2))
                .foregroundStyle(.tertiary)
                .italic()
        case .directive:
            // Directives are typically parsed and not displayed
            EmptyView()
        }
    }

    @ViewBuilder
    private func renderLyricsWithChords() -> some View {
        if line.hasChords {
            // Use position-based rendering for perfect alignment
            VStack(alignment: .leading, spacing: chordToLyricSpacing) {
                // Chords layer (positioned above lyrics)
                chordLayer

                // Lyrics layer (base text)
                lyricsLayer
            }
        } else {
            // No chords, just render lyrics
            Text(line.text)
                .font(settings.lyricsFont())
                .foregroundStyle(lyricsColor)
        }
    }

    /// Render chords layer with precise positioning
    @ViewBuilder
    private var chordLayer: some View {
        // Calculate character width for monospaced font
        // This is approximate but works well for monospaced fonts
        let charWidth = fontSize * 0.6 // Typical monospaced character width ratio

        ZStack(alignment: .topLeading) {
            // Invisible text to set the height and width of the chord layer
            Text(line.text)
                .font(settings.chordsFont())
                .opacity(0)

            // Position each chord precisely
            ForEach(Array(line.segments.enumerated()), id: \.offset) { _, segment in
                if let chord = segment.displayChord {
                    Text(chord)
                        .font(settings.chordsFont())
                        .foregroundStyle(chordColor)
                        .offset(x: CGFloat(segment.position) * charWidth, y: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Render lyrics layer
    @ViewBuilder
    private var lyricsLayer: some View {
        Text(line.text)
            .font(settings.lyricsFont())
            .foregroundStyle(lyricsColor)
    }

    @ViewBuilder
    private func renderChordsOnly() -> some View {
        // For chord-only lines, space them out nicely
        let charWidth = fontSize * 0.6

        ZStack(alignment: .topLeading) {
            // Create an invisible baseline using spaces
            let maxPosition = line.segments.map { $0.position + ($0.chord?.count ?? 0) }.max() ?? 0
            Text(String(repeating: " ", count: maxPosition))
                .font(settings.chordsFont())
                .opacity(0)

            // Position each chord
            ForEach(Array(line.segments.enumerated()), id: \.offset) { _, segment in
                if let chord = segment.displayChord {
                    Text(chord)
                        .font(settings.chordsFont())
                        .foregroundStyle(chordColor)
                        .offset(x: CGFloat(segment.position) * charWidth, y: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Song Display") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Amazing Grace",
                artist: "John Newton",
                content: SampleChordProSongs.amazingGrace,
                originalKey: "G"
            )
            return song
        }())
    }
}

#Preview("Simple Song") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Test Song",
                content: """
                {title: Test Song}
                {artist: Test Artist}
                {key: C}

                {verse}
                [C]Simple [F]test [G]song
                With [C]basic [F]chords
                """
            )
            return song
        }())
    }
}

#Preview("Chord Positioning Tests") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Chord Position Test Cases",
                content: """
                {title: Chord Position Test Cases}
                {subtitle: Testing all edge cases}
                {artist: Test}
                {key: C}

                {verse: Multiple chords per line}
                I [C]love [Am]you [F]so [G]much

                {verse: Chords at line start}
                [C]Hello world of music

                {verse: Chords at line end}
                Hello world of music[G]

                {verse: Chords between words (no space)}
                Hello[C]world of[G]music

                {verse: Multiple spaces}
                Hello    [C]world    of    [G]music

                {verse: Long chord names}
                [Cmaj7]Complex [Asus4]chords [Dm7b5]here [Gadd9]now

                {verse: Quick chord changes}
                [C]I [Am]love [F]you [G]so [Em]very [Am]much [Dm]today [G7]yeah

                {chorus: Mixed spacing and positions}
                [C]At the [Am]start and middle[F] and end[G]
                Some[C]times no[Am]space between[F]them[G]
                """
            )
            return song
        }())
    }
}

#Preview("Complex Song - Blest Be The Tie") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Blest Be the Tie",
                artist: "John Fawcett",
                content: SampleChordProSongs.blestBeTheTie,
                originalKey: "D"
            )
            return song
        }())
    }
}

#Preview("Complex Song - How Great Thou Art") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "How Great Thou Art",
                artist: "Carl Boberg",
                content: SampleChordProSongs.howGreatThouArt,
                originalKey: "C"
            )
            return song
        }())
    }
}

// MARK: - Set Context Banner

struct SetContextBanner: View {
    let setName: String
    let songPosition: Int
    let totalSongs: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Viewing from Set")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Text(setName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Text("Song \(songPosition) of \(totalSongs)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.8), Color.green],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

#Preview("Enhanced Metadata Header") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Complete Metadata Example",
                artist: "Test Artist",
                content: """
                {title: Complete Metadata Example}
                {subtitle: Showcasing All Metadata Fields}
                {artist: Test Artist}
                {key: G}
                {tempo: 120}
                {time: 4/4}
                {capo: 2}
                {copyright: Copyright 2026 Test Publishing}

                {verse}
                [G]This song has [C]all the [G]metadata [D]fields
                [G]Including [C]key, tempo, [G]time, and [D]capo

                {chorus}
                [C]Look at that [G]beautiful [Em]header
                [C]With icons [G]and clean [D]layout
                """
            )
            return song
        }())
    }
}

#Preview("Minimal Metadata") {
    NavigationStack {
        SongDisplayView(song: {
            let song = Song(
                title: "Simple Song",
                content: """
                {title: Simple Song}
                {artist: Unknown Artist}

                {verse}
                Just lyrics here
                No musical metadata
                """
            )
            return song
        }())
    }
}
