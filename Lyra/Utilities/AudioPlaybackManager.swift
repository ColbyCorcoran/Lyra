//
//  AudioPlaybackManager.swift
//  Lyra
//
//  Manager for backing track playback with multi-track mixing
//

import Foundation
import AVFoundation
import Observation
import Combine

@Observable
class AudioPlaybackManager {
    static let shared = AudioPlaybackManager()

    // MARK: - Properties

    /// Audio engine
    private var audioEngine: AVAudioEngine = AVAudioEngine()

    /// Player nodes for each track
    private var playerNodes: [UUID: AVAudioPlayerNode] = [:]

    /// Audio files
    private var audioFiles: [UUID: AVAudioFile] = [:]

    /// Mixer nodes per track
    private var mixerNodes: [UUID: AVAudioMixerNode] = [:]

    /// EQ nodes
    private var eqNodes: [UUID: AVAudioUnitEQ] = [:]

    /// Current tracks
    private(set) var tracks: [AudioTrack] = []

    /// Playback state
    private(set) var playbackState: PlaybackState = .stopped

    /// Current position in seconds
    private(set) var currentPosition: TimeInterval = 0

    /// Total duration (longest track)
    private(set) var totalDuration: TimeInterval = 0

    /// Mixer settings
    var mixerSettings: MixerSettings = MixerSettings()

    /// Routing configuration
    var routingConfig: AudioRoutingConfig = AudioRoutingConfig()

    /// Loop enabled
    var loopEnabled: Bool = false

    /// Loop range
    var loopStart: TimeInterval = 0
    var loopEnd: TimeInterval = 0

    /// Sync with autoscroll
    var syncWithAutoscroll: Bool = false
    var autoscrollCallback: ((TimeInterval) -> Void)?

    /// Markers
    private var reachedMarkers: Set<UUID> = []

    // MARK: - Timer

    private var positionTimer: Timer?

    // MARK: - Initialization

    private init() {
        setupAudioSession()
        setupAudioEngine()
        loadSettings()
    }

    deinit {
        stop()
        audioEngine.stop()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func configureAudioSession(_ config: AudioSessionConfig) {
        let session = AVAudioSession.sharedInstance()

        do {
            var options: AVAudioSession.CategoryOptions = []

            if config.allowsBluetoothA2DP {
                options.insert(.allowBluetoothA2DP)
            }
            if config.allowsAirPlay {
                options.insert(.allowAirPlay)
            }
            if config.mixWithOthers {
                options.insert(.mixWithOthers)
            }
            if config.duckOthers {
                options.insert(.duckOthers)
            }

            try session.setCategory(config.category.avCategory, mode: .default, options: options)
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Audio Engine Setup

    private func setupAudioEngine() {
        // Main mixer is already part of the engine
        let mainMixer = audioEngine.mainMixerNode

        // Connect to output
        audioEngine.connect(mainMixer, to: audioEngine.outputNode, format: nil)

        audioEngine.prepare()
    }

    // MARK: - Track Management

    func loadTracks(_ newTracks: [AudioTrack]) {
        stop()
        clearTracks()

        tracks = newTracks
        totalDuration = tracks.map { $0.effectiveDuration }.max() ?? 0

        for track in tracks {
            loadTrack(track)
        }

        NotificationCenter.default.post(name: .audioTrackLoaded, object: self)
    }

    private func loadTrack(_ track: AudioTrack) {
        guard let url = track.fileURL else {
            print("No file URL for track: \(track.name)")
            return
        }

        do {
            // Load audio file
            let audioFile = try AVAudioFile(forReading: url)
            audioFiles[track.id] = audioFile

            // Create player node
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            playerNodes[track.id] = playerNode

            // Create mixer node for this track
            let mixerNode = AVAudioMixerNode()
            audioEngine.attach(mixerNode)
            mixerNodes[track.id] = mixerNode

            // Create EQ node
            let eqNode = AVAudioUnitEQ(numberOfBands: 3)
            eqNode.globalGain = 0
            eqNode.bands[0].frequency = 100 // Bass
            eqNode.bands[0].bandwidth = 1.0
            eqNode.bands[0].filterType = .parametric
            eqNode.bands[1].frequency = 1000 // Mid
            eqNode.bands[1].bandwidth = 1.0
            eqNode.bands[1].filterType = .parametric
            eqNode.bands[2].frequency = 10000 // Treble
            eqNode.bands[2].bandwidth = 1.0
            eqNode.bands[2].filterType = .parametric

            audioEngine.attach(eqNode)
            eqNodes[track.id] = eqNode

            // Connect: Player -> EQ -> Mixer -> Main Mixer
            let format = audioFile.processingFormat
            audioEngine.connect(playerNode, to: eqNode, format: format)
            audioEngine.connect(eqNode, to: mixerNode, format: format)
            audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: format)

            // Apply initial settings
            applyTrackSettings(track)

        } catch {
            print("Failed to load track \(track.name): \(error)")
        }
    }

    private func clearTracks() {
        // Remove all nodes
        for (_, playerNode) in playerNodes {
            audioEngine.detach(playerNode)
        }
        for (_, mixerNode) in mixerNodes {
            audioEngine.detach(mixerNode)
        }
        for (_, eqNode) in eqNodes {
            audioEngine.detach(eqNode)
        }

        playerNodes.removeAll()
        mixerNodes.removeAll()
        eqNodes.removeAll()
        audioFiles.removeAll()
        tracks.removeAll()
    }

    // MARK: - Playback Control

    func play() {
        guard playbackState != .playing else { return }

        do {
            // Start audio engine if not running
            if !audioEngine.isRunning {
                try audioEngine.start()
            }

            // Schedule all tracks
            for track in tracks {
                guard let playerNode = playerNodes[track.id],
                      let audioFile = audioFiles[track.id] else { continue }

                // Calculate start frame based on current position
                let startFrame = AVAudioFramePosition(currentPosition * audioFile.processingFormat.sampleRate)

                playerNode.stop()

                if startFrame < audioFile.length {
                    let frameCount = AVAudioFrameCount(audioFile.length - startFrame)

                    playerNode.scheduleSegment(
                        audioFile,
                        startingFrame: startFrame,
                        frameCount: frameCount,
                        at: nil
                    ) { [weak self] in
                        self?.handleTrackCompletion(trackId: track.id)
                    }

                    playerNode.play()
                }
            }

            playbackState = .playing
            startPositionTimer()

            // Sync with autoscroll
            if syncWithAutoscroll {
                autoscrollCallback?(totalDuration)
            }

            NotificationCenter.default.post(name: .audioPlaybackStateChanged, object: self)

        } catch {
            print("Failed to start playback: \(error)")
            playbackState = .error
        }
    }

    func pause() {
        guard playbackState == .playing else { return }

        for (_, playerNode) in playerNodes {
            playerNode.pause()
        }

        playbackState = .paused
        stopPositionTimer()

        NotificationCenter.default.post(name: .audioPlaybackStateChanged, object: self)
    }

    func stop() {
        for (_, playerNode) in playerNodes {
            playerNode.stop()
        }

        currentPosition = 0
        playbackState = .stopped
        stopPositionTimer()
        reachedMarkers.removeAll()

        NotificationCenter.default.post(name: .audioPlaybackStateChanged, object: self)
    }

    func togglePlayPause() {
        if playbackState == .playing {
            pause()
        } else {
            play()
        }
    }

    // MARK: - Seeking

    func seek(to position: TimeInterval) {
        let wasPlaying = playbackState == .playing

        if wasPlaying {
            pause()
        }

        currentPosition = max(0, min(position, totalDuration))

        // Clear reached markers before this position
        reachedMarkers = reachedMarkers.filter { markerId in
            tracks.flatMap { $0.markers }.first(where: { $0.id == markerId })?.position ?? 0 > currentPosition
        }

        if wasPlaying {
            play()
        }

        NotificationCenter.default.post(name: .audioPositionChanged, object: self, userInfo: ["position": currentPosition])
    }

    func skipForward(_ seconds: TimeInterval = 10) {
        seek(to: currentPosition + seconds)
    }

    func skipBackward(_ seconds: TimeInterval = 10) {
        seek(to: currentPosition - seconds)
    }

    func jumpToMarker(_ marker: AudioMarker) {
        seek(to: marker.position)
    }

    // MARK: - Playback Rate

    func setPlaybackRate(_ rate: Float) {
        let clampedRate = max(0.5, min(2.0, rate))

        for (trackId, playerNode) in playerNodes {
            playerNode.rate = clampedRate

            // Update track model
            if let index = tracks.firstIndex(where: { $0.id == trackId }) {
                tracks[index].playbackRate = clampedRate
            }
        }
    }

    // MARK: - Volume and Mixing

    func setMasterVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        audioEngine.mainMixerNode.outputVolume = clampedVolume
        mixerSettings.masterVolume = clampedVolume
        saveSettings()

        NotificationCenter.default.post(name: .audioMixerChanged, object: self)
    }

    func setTrackVolume(_ trackId: UUID, volume: Float) {
        guard let mixerNode = mixerNodes[trackId] else { return }

        let clampedVolume = max(0.0, min(1.0, volume))
        mixerNode.outputVolume = clampedVolume

        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            tracks[index].volume = clampedVolume
        }

        mixerSettings.trackSettings[trackId]?.volume = clampedVolume
        saveSettings()

        NotificationCenter.default.post(name: .audioMixerChanged, object: self)
    }

    func setTrackPan(_ trackId: UUID, pan: Float) {
        guard let mixerNode = mixerNodes[trackId] else { return }

        let clampedPan = max(-1.0, min(1.0, pan))
        mixerNode.pan = clampedPan

        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            tracks[index].pan = clampedPan
        }

        mixerSettings.trackSettings[trackId]?.pan = clampedPan
        saveSettings()
    }

    func muteTrack(_ trackId: UUID, mute: Bool) {
        guard let mixerNode = mixerNodes[trackId] else { return }

        mixerNode.outputVolume = mute ? 0 : (tracks.first(where: { $0.id == trackId })?.volume ?? 0.8)

        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            tracks[index].isMuted = mute
        }

        mixerSettings.trackSettings[trackId]?.mute = mute
        saveSettings()
    }

    func soloTrack(_ trackId: UUID) {
        // Unsolo all tracks first
        for track in tracks {
            if track.id != trackId {
                muteTrack(track.id, mute: true)
            }
        }

        // Unmute the solo track
        muteTrack(trackId, mute: false)

        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            tracks[index].isSolo = true
        }
    }

    func unsoloAll() {
        for track in tracks {
            muteTrack(track.id, mute: track.isMuted)
            if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                tracks[index].isSolo = false
            }
        }
    }

    // MARK: - Effects

    func applyEQ(_ trackId: UUID, settings: EQSettings) {
        guard let eqNode = eqNodes[trackId] else { return }

        eqNode.bypass = !settings.isEnabled

        if settings.isEnabled {
            eqNode.bands[0].gain = settings.bass
            eqNode.bands[1].gain = settings.mid
            eqNode.bands[1].frequency = settings.frequency
            eqNode.bands[2].gain = settings.treble
        }

        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            tracks[index].eq = settings
        }
    }

    // MARK: - Loop Control

    func setLoop(start: TimeInterval, end: TimeInterval) {
        loopStart = max(0, start)
        loopEnd = min(totalDuration, end)
        loopEnabled = true
    }

    func clearLoop() {
        loopEnabled = false
        loopStart = 0
        loopEnd = totalDuration
    }

    // MARK: - Position Timer

    private func startPositionTimer() {
        stopPositionTimer()

        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
    }

    private func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    private func updatePosition() {
        currentPosition += 0.1

        // Check for loop
        if loopEnabled && currentPosition >= loopEnd {
            seek(to: loopStart)
            if playbackState == .playing {
                play()
            }
        }

        // Check for markers
        checkMarkers()

        // Check for end
        if currentPosition >= totalDuration {
            handlePlaybackEnd()
        }

        NotificationCenter.default.post(
            name: .audioPositionChanged,
            object: self,
            userInfo: ["position": currentPosition]
        )
    }

    // MARK: - Markers

    private func checkMarkers() {
        for track in tracks {
            for marker in track.markers {
                // Check if we just passed this marker
                if currentPosition >= marker.position &&
                   currentPosition < marker.position + 0.2 && // 0.2s window
                   !reachedMarkers.contains(marker.id) {

                    reachedMarkers.insert(marker.id)
                    handleMarkerReached(marker)
                }
            }
        }
    }

    private func handleMarkerReached(_ marker: AudioMarker) {
        NotificationCenter.default.post(
            name: .audioMarkerReached,
            object: self,
            userInfo: ["marker": marker]
        )

        // Execute marker action
        if let action = marker.action {
            executeMarkerAction(action, marker: marker)
        }
    }

    private func executeMarkerAction(_ action: BackingTrackMarkerAction, marker: AudioMarker) {
        switch action {
        case .jumpToSection:
            // Handled by external listener
            break
        case .showMessage:
            // Handled by UI
            break
        case .triggerMIDI:
            // Integrate with MIDI system
            break
        case .changeDisplay:
            // Integrate with display system
            break
        case .advanceSong:
            // Integrate with performance system
            break
        case .blankScreen:
            // Integrate with display system
            break
        }
    }

    // MARK: - Completion Handling

    private func handleTrackCompletion(trackId: UUID) {
        // Check if all tracks are complete
        let allComplete = playerNodes.values.allSatisfy { !$0.isPlaying }

        if allComplete {
            handlePlaybackEnd()
        }
    }

    private func handlePlaybackEnd() {
        if loopEnabled {
            seek(to: loopStart)
            play()
        } else {
            stop()
            NotificationCenter.default.post(name: .audioTrackEnded, object: self)
        }
    }

    // MARK: - Track Settings

    private func applyTrackSettings(_ track: AudioTrack) {
        setTrackVolume(track.id, volume: track.volume)
        setTrackPan(track.id, pan: track.pan)
        muteTrack(track.id, mute: track.isMuted)
        applyEQ(track.id, settings: track.eq)
    }

    // MARK: - Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: "audioPlayback.mixerSettings"),
           let settings = try? JSONDecoder().decode(MixerSettings.self, from: data) {
            mixerSettings = settings
            audioEngine.mainMixerNode.outputVolume = settings.masterVolume
        }

        if let data = defaults.data(forKey: "audioPlayback.routingConfig"),
           let config = try? JSONDecoder().decode(AudioRoutingConfig.self, from: data) {
            routingConfig = config
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard

        if let data = try? JSONEncoder().encode(mixerSettings) {
            defaults.set(data, forKey: "audioPlayback.mixerSettings")
        }

        if let data = try? JSONEncoder().encode(routingConfig) {
            defaults.set(data, forKey: "audioPlayback.routingConfig")
        }
    }

    // MARK: - Utilities

    var isPlaying: Bool {
        playbackState == .playing
    }

    var isPaused: Bool {
        playbackState == .paused
    }

    var isStopped: Bool {
        playbackState == .stopped
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return currentPosition / totalDuration
    }

    var formattedCurrentTime: String {
        formatTime(currentPosition)
    }

    var formattedTotalTime: String {
        formatTime(totalDuration)
    }

    var formattedRemainingTime: String {
        formatTime(totalDuration - currentPosition)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Audio Routing

    func setOutputDevice(_ device: AudioOutputDevice) {
        routingConfig.mainOutput = device
        saveSettings()

        // In a real implementation, you'd configure AVAudioSession routing
        NotificationCenter.default.post(name: .audioRoutingChanged, object: self)
    }

    func getAvailableOutputDevices() -> [AudioOutputDevice] {
        var devices: [AudioOutputDevice] = [.defaultOutput, .builtInSpeaker]

        let session = AVAudioSession.sharedInstance()

        // Check for headphones
        let outputs = session.currentRoute.outputs
        for output in outputs {
            switch output.portType {
            case .headphones:
                devices.append(.headphones)
            case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                devices.append(.bluetooth(name: output.portName))
            case .airPlay:
                devices.append(.airPlay(name: output.portName))
            case .usbAudio:
                devices.append(.usb(name: output.portName))
            default:
                break
            }
        }

        return devices
    }
}
