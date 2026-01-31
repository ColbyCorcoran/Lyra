//
//  BackingTracksView.swift
//  Lyra
//
//  UI for managing backing tracks for a song
//

import SwiftUI
import AVFoundation

struct BackingTracksView: View {
    let song: Song
    @Environment(\.dismiss) private var dismiss

    @State private var tracks: [AudioTrack] = []
    @State private var showAddTrack = false
    @State private var showMixer = false
    @State private var isPlaying = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let audioManager = AudioPlaybackManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                if tracks.isEmpty {
                    emptyState
                } else {
                    tracksList
                }
            }
            .navigationTitle("Backing Tracks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTrack = true
                    } label: {
                        Label("Add Track", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTrack) {
                AddTrackView(tracks: $tracks)
            }
            .sheet(isPresented: $showMixer) {
                MixerView(tracks: $tracks, song: song)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadTracks()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Backing Tracks")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add audio files to play along with this song")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showAddTrack = true
            } label: {
                Label("Add Your First Track", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Tracks List

    private var tracksList: some View {
        List {
            Section {
                ForEach($tracks) { $track in
                    TrackRow(track: $track)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTrack(track)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onMove { from, to in
                    tracks.move(fromOffsets: from, toOffset: to)
                }
            } header: {
                HStack {
                    Text("Tracks")
                    Spacer()
                    Text("\(tracks.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    showMixer = true
                } label: {
                    Label("Open Mixer", systemImage: "slider.horizontal.3")
                }

                Button {
                    if isPlaying {
                        stopPlayback()
                    } else {
                        startPlayback()
                    }
                } label: {
                    Label(isPlaying ? "Stop Playback" : "Test Playback", systemImage: isPlaying ? "stop.fill" : "play.fill")
                }
                .foregroundStyle(isPlaying ? .red : .green)
            }
        }
    }

    // MARK: - Actions

    private func loadTracks() {
        // Load tracks from song (assuming we store them as JSON in notes for now)
        // In production, you'd want a proper relationship or dedicated field
        if let trackData = song.notes?.data(using: .utf8),
           let decodedTracks = try? JSONDecoder().decode([AudioTrack].self, from: trackData) {
            tracks = decodedTracks
        }
    }

    private func saveAndDismiss() {
        // Save tracks to song
        if let encoded = try? JSONEncoder().encode(tracks),
           let json = String(data: encoded, encoding: .utf8) {
            song.notes = json
        }
        dismiss()
    }

    private func deleteTrack(_ track: AudioTrack) {
        tracks.removeAll { $0.id == track.id }
    }

    private func startPlayback() {
        do {
            audioManager.loadTracks(tracks)
            try audioManager.play()
            isPlaying = true
        } catch {
            errorMessage = "Failed to play tracks: \(error.localizedDescription)"
            showError = true
        }
    }

    private func stopPlayback() {
        audioManager.stop()
        isPlaying = false
    }
}

// MARK: - Track Row

struct TrackRow: View {
    @Binding var track: AudioTrack

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: track.type.icon)
                .font(.title3)
                .foregroundStyle(track.isMuted ? .secondary : .blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    if track.isMuted {
                        Label("Muted", systemImage: "speaker.slash.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if track.isSolo {
                        Label("Solo", systemImage: "s.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Text(formatDuration(track.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Quick controls
            HStack(spacing: 16) {
                Button {
                    track.isMuted.toggle()
                } label: {
                    Image(systemName: track.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundStyle(track.isMuted ? .secondary : .blue)
                }
                .buttonStyle(.plain)

                VolumeIndicator(volume: track.volume)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Volume Indicator

struct VolumeIndicator: View {
    let volume: Float

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < Int(volume * 5) ? Color.blue : Color(.systemGray5))
                    .frame(width: 3, height: CGFloat(4 + index * 2))
            }
        }
    }
}

// MARK: - Add Track View

struct AddTrackView: View {
    @Binding var tracks: [AudioTrack]
    @Environment(\.dismiss) private var dismiss

    @State private var trackName = ""
    @State private var showFilePicker = false
    @State private var selectedURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Track Name", text: $trackName)
                } header: {
                    Text("Track Info")
                }

                Section {
                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Label("Choose Audio File", systemImage: "folder")
                            Spacer()
                            if let url = selectedURL {
                                Text(url.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Audio File")
                } footer: {
                    Text("Supported formats: MP3, WAV, M4A, AIFF")
                }

                Section {
                    Button {
                        addTrack()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Add Track")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(trackName.isEmpty || selectedURL == nil)
                }
            }
            .navigationTitle("Add Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, .mp3, .wav, .m4a, .aiff],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedURL = url
                if trackName.isEmpty {
                    trackName = url.deletingPathExtension().lastPathComponent
                }
            }
        case .failure(let error):
            print("Error selecting file: \(error)")
        }
    }

    private func addTrack() {
        guard let url = selectedURL else { return }

        // Get audio file duration
        let asset = AVAsset(url: url)
        let duration = asset.duration.seconds

        let track = AudioTrack(
            name: trackName,
            filename: url.lastPathComponent,
            fileURL: url,
            duration: duration
        )

        tracks.append(track)
        dismiss()
    }
}

// MARK: - Mixer View

struct MixerView: View {
    @Binding var tracks: [AudioTrack]
    let song: Song
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach($tracks) { $track in
                        MixerChannel(track: $track)
                    }
                }
                .padding()
            }
            .navigationTitle("Mixer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Mixer Channel

struct MixerChannel: View {
    @Binding var track: AudioTrack

    var body: some View {
        VStack(spacing: 12) {
            // Track name
            Text(track.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30)

            // Volume fader
            VStack {
                Text("\(Int(track.volume * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Slider(value: $track.volume, in: 0...1)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 150)
            }

            // Pan control
            VStack(spacing: 4) {
                Text("Pan")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("L")
                        .font(.caption2)
                    Slider(value: $track.pan, in: -1...1)
                    Text("R")
                        .font(.caption2)
                }
                .frame(width: 100)
            }

            Divider()

            // Controls
            VStack(spacing: 8) {
                Button {
                    track.isSolo.toggle()
                } label: {
                    Text("S")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 30, height: 30)
                        .background(track.isSolo ? Color.orange : Color(.systemGray5))
                        .foregroundStyle(track.isSolo ? .white : .primary)
                        .clipShape(Circle())
                }

                Button {
                    track.isMuted.toggle()
                } label: {
                    Text("M")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 30, height: 30)
                        .background(track.isMuted ? Color.red : Color(.systemGray5))
                        .foregroundStyle(track.isMuted ? .white : .primary)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Extensions

extension AudioTrackType {
    var icon: String {
        switch self {
        case .backing: return "waveform"
        case .clickTrack: return "metronome"
        case .guide: return "music.mic"
        case .ambient: return "wind"
        case .effect: return "sparkles"
        }
    }
}

// MARK: - Preview

#Preview {
    BackingTracksView(song: Song(title: "Test Song"))
}
