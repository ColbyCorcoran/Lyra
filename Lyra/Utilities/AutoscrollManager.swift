//
//  AutoscrollManager.swift
//  Lyra
//
//  Smooth autoscroll engine for live performance
//

import SwiftUI
import Combine

@MainActor
class AutoscrollManager: ObservableObject {
    // MARK: - Published Properties

    @Published var isScrolling: Bool = false
    @Published var currentProgress: Double = 0.0 // 0.0 to 1.0
    @Published var speedMultiplier: Double = 1.0 // 0.5x to 2.0x
    @Published var isPaused: Bool = false

    // MARK: - Private Properties

    private var displayLink: CADisplayLink?
    private var startTime: TimeInterval = 0
    private var pausedTime: TimeInterval = 0
    private var pausedAt: TimeInterval = 0
    private var contentHeight: CGFloat = 0
    private var visibleHeight: CGFloat = 0
    private var duration: TimeInterval = 180 // Default 3 minutes
    private var scrollProxy: ScrollViewProxy?
    private var onScrollToPosition: ((CGFloat) -> Void)?

    // MARK: - Advanced Features

    private var sections: [SongSection] = []
    private var sectionConfigs: [UUID: SectionAutoscrollConfig] = [:]
    private var currentSectionIndex: Int? = nil
    private var timeline: AutoscrollTimeline? = nil
    private var useTimeline: Bool = false
    private var markers: [AutoscrollMarker] = []
    private var passedMarkerIds: Set<UUID> = []
    private var autoPauseTimer: Timer? = nil

    // MARK: - Computed Properties

    var scrollableHeight: CGFloat {
        max(0, contentHeight - visibleHeight)
    }

    var effectiveDuration: TimeInterval {
        duration / speedMultiplier
    }

    var elapsedTime: TimeInterval {
        guard isScrolling else { return 0 }
        if isPaused {
            return pausedTime
        }
        return CACurrentMediaTime() - startTime + pausedTime
    }

    var remainingTime: TimeInterval {
        max(0, effectiveDuration - elapsedTime)
    }

    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Configuration

    func configure(
        duration: TimeInterval,
        contentHeight: CGFloat,
        visibleHeight: CGFloat,
        onScrollToPosition: @escaping (CGFloat) -> Void
    ) {
        self.duration = duration
        self.contentHeight = contentHeight
        self.visibleHeight = visibleHeight
        self.onScrollToPosition = onScrollToPosition
    }

    /// Configure section-aware autoscroll
    func configureSections(
        _ sections: [SongSection],
        configs: [SectionAutoscrollConfig] = []
    ) {
        self.sections = sections
        self.sectionConfigs.removeAll()

        for config in configs {
            self.sectionConfigs[config.sectionId] = config
        }
    }

    /// Configure timeline playback
    func configureTimeline(_ timeline: AutoscrollTimeline?, enabled: Bool = false) {
        self.timeline = timeline
        self.useTimeline = enabled
    }

    /// Configure markers
    func configureMarkers(_ markers: [AutoscrollMarker]) {
        self.markers = markers.sorted { $0.progress < $1.progress }
    }

    /// Load configuration from song
    func loadConfiguration(from song: Song, parsedSong: ParsedSong?) {
        // Load basic settings
        self.duration = TimeInterval(song.autoscrollDuration ?? 180)

        // Load advanced configuration
        guard let config = song.autoscrollConfiguration else { return }

        // Load sections
        if let parsed = parsedSong {
            configureSections(parsed.sections, configs: config.sectionConfigs)
        }

        // Load timeline if active preset uses it
        if let preset = config.activePreset(), preset.useTimeline {
            configureTimeline(preset.timeline, enabled: true)
        }

        // Load markers
        configureMarkers(config.markers)
    }

    // MARK: - Control Methods

    func start(fromProgress: Double = 0.0) {
        guard !isScrolling else { return }

        isScrolling = true
        isPaused = false
        currentProgress = fromProgress
        startTime = CACurrentMediaTime()
        pausedTime = fromProgress * effectiveDuration

        // Create display link for smooth 60fps scrolling
        displayLink = CADisplayLink(target: self, selector: #selector(updateScroll))
        displayLink?.add(to: .main, forMode: .common)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func pause() {
        guard isScrolling, !isPaused else { return }

        isPaused = true
        pausedAt = CACurrentMediaTime()
        pausedTime = elapsedTime

        displayLink?.isPaused = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func resume() {
        guard isScrolling, isPaused else { return }

        isPaused = false
        startTime = CACurrentMediaTime()

        displayLink?.isPaused = false

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Toggle autoscroll state
    func toggle() {
        if !isScrolling {
            start()
        } else if isPaused {
            resume()
        } else {
            pause()
        }
    }

    func stop() {
        isScrolling = false
        isPaused = false

        displayLink?.invalidate()
        displayLink = nil

        startTime = 0
        pausedTime = 0
        pausedAt = 0

        // Clean up section state
        currentSectionIndex = nil
        passedMarkerIds.removeAll()
        autoPauseTimer?.invalidate()
        autoPauseTimer = nil

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func reset() {
        stop()
        currentProgress = 0.0
        onScrollToPosition?(0)
    }

    func jumpToTop() {
        currentProgress = 0.0
        pausedTime = 0
        startTime = CACurrentMediaTime()
        onScrollToPosition?(0)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func jumpToProgress(_ progress: Double) {
        let clampedProgress = max(0, min(1, progress))
        currentProgress = clampedProgress

        if isScrolling {
            pausedTime = clampedProgress * effectiveDuration
            startTime = CACurrentMediaTime()
        }

        let scrollPosition = clampedProgress * scrollableHeight
        onScrollToPosition?(scrollPosition)
    }

    // MARK: - Speed Control

    func adjustSpeed(by delta: Double) {
        let newSpeed = max(0.5, min(2.0, speedMultiplier + delta))
        setSpeed(newSpeed)
    }

    func setSpeed(_ speed: Double) {
        let clampedSpeed = max(0.5, min(2.0, speed))

        // Calculate current position in original duration
        let currentPositionInOriginal = pausedTime / speedMultiplier

        // Update speed
        speedMultiplier = clampedSpeed

        // Recalculate start time to maintain position
        pausedTime = currentPositionInOriginal * speedMultiplier
        startTime = CACurrentMediaTime()

        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Manual Interaction

    func handleManualScroll() {
        if isScrolling && !isPaused {
            pause()
        }
    }

    func handleTap() {
        if isScrolling {
            if isPaused {
                resume()
            } else {
                pause()
            }
        }
    }

    // MARK: - Private Methods

    @objc private func updateScroll() {
        guard isScrolling, !isPaused else { return }

        let elapsed = elapsedTime

        // Use timeline if configured
        let progress: Double
        if useTimeline, let timeline = timeline {
            progress = timeline.progress(at: elapsed)
        } else {
            progress = min(1.0, elapsed / effectiveDuration)
        }

        currentProgress = progress

        // Check section boundaries
        checkSectionBoundaries(at: progress)

        // Check markers
        checkMarkers(at: progress)

        // Calculate scroll position
        let scrollPosition = progress * scrollableHeight
        onScrollToPosition?(scrollPosition)

        // Stop at bottom
        if progress >= 1.0 {
            stop()
        }
    }

    private func checkSectionBoundaries(at progress: Double) {
        guard !sections.isEmpty else { return }

        // Calculate which section we're in based on progress
        let newSectionIndex = calculateSectionIndex(for: progress)

        // Check if we entered a new section
        if let newIndex = newSectionIndex, newIndex != currentSectionIndex {
            let section = sections[newIndex]

            // Check if this section has a pause configuration
            if let config = sectionConfigs[section.id], config.isEnabled, config.pauseAtStart {
                currentSectionIndex = newIndex

                // Pause autoscroll
                pause()

                // Auto-resume if duration is set
                if let pauseDuration = config.pauseDuration {
                    autoPauseTimer?.invalidate()
                    autoPauseTimer = Timer.scheduledTimer(withTimeInterval: pauseDuration, repeats: false) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            self?.resume()
                        }
                    }
                }

                // Haptic feedback for section boundary
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            } else {
                currentSectionIndex = newIndex
            }
        }

        // Apply section speed multiplier if configured
        if let index = currentSectionIndex, index < sections.count {
            let section = sections[index]
            if let config = sectionConfigs[section.id], config.isEnabled {
                // Speed is already applied via effectiveDuration calculation
                // This is handled in the section speed computation
            }
        }
    }

    private func checkMarkers(at progress: Double) {
        for marker in markers {
            // Check if we've just passed this marker
            if progress >= marker.progress && !passedMarkerIds.contains(marker.id) {
                passedMarkerIds.insert(marker.id)

                switch marker.action {
                case .pause:
                    pause()

                    // Auto-resume if duration is set
                    if let pauseDuration = marker.pauseDuration {
                        autoPauseTimer?.invalidate()
                        autoPauseTimer = Timer.scheduledTimer(withTimeInterval: pauseDuration, repeats: false) { [weak self] _ in
                            Task { @MainActor [weak self] in
                                self?.resume()
                            }
                        }
                    }

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)

                case .speedChange:
                    // Speed change handled by marker configuration
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()

                case .notification:
                    // Visual notification
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }

    private func calculateSectionIndex(for progress: Double) -> Int? {
        guard !sections.isEmpty else { return nil }

        // For simplicity, divide progress evenly among sections
        // In a real implementation, this would use actual section heights
        let sectionCount = Double(sections.count)
        let index = Int(floor(progress * sectionCount))
        return min(index, sections.count - 1)
    }

    // MARK: - Timeline Recording

    @Published var isRecording: Bool = false
    private var recordedKeyframes: [TimelineKeyframe] = []
    private var recordingStartTime: TimeInterval = 0

    func startRecording() {
        guard !isRecording else { return }

        isRecording = true
        recordedKeyframes.removeAll()
        recordingStartTime = CACurrentMediaTime()

        // Record initial keyframe
        let keyframe = TimelineKeyframe(
            timestamp: 0,
            progress: currentProgress,
            speedMultiplier: speedMultiplier
        )
        recordedKeyframes.append(keyframe)

        // Start scrolling if not already
        if !isScrolling {
            start()
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func stopRecording(name: String) -> AutoscrollTimeline? {
        guard isRecording else { return nil }

        isRecording = false

        // Record final keyframe
        let elapsed = CACurrentMediaTime() - recordingStartTime
        let finalKeyframe = TimelineKeyframe(
            timestamp: elapsed,
            progress: currentProgress,
            speedMultiplier: speedMultiplier
        )
        recordedKeyframes.append(finalKeyframe)

        // Create timeline
        let timeline = AutoscrollTimeline(
            name: name,
            duration: elapsed,
            keyframes: recordedKeyframes
        )

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        return timeline
    }

    func cancelRecording() {
        isRecording = false
        recordedKeyframes.removeAll()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func recordKeyframe() {
        guard isRecording else { return }

        let elapsed = CACurrentMediaTime() - recordingStartTime
        let keyframe = TimelineKeyframe(
            timestamp: elapsed,
            progress: currentProgress,
            speedMultiplier: speedMultiplier
        )
        recordedKeyframes.append(keyframe)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // MARK: - Section Speed Zones

    /// Get effective speed for current section
    func currentSectionSpeed() -> Double {
        guard let index = currentSectionIndex, index < sections.count else {
            return speedMultiplier
        }

        let section = sections[index]
        if let config = sectionConfigs[section.id], config.isEnabled {
            return speedMultiplier * config.speedMultiplier
        }

        return speedMultiplier
    }

    /// Get section at progress
    func section(at progress: Double) -> SongSection? {
        guard let index = calculateSectionIndex(for: progress), index < sections.count else {
            return nil
        }
        return sections[index]
    }

    // MARK: - Cleanup

    deinit {
        displayLink?.invalidate()
        autoPauseTimer?.invalidate()
    }
}

// MARK: - Autoscroll Settings

struct AutoscrollSettings {
    var defaultDuration: TimeInterval = 180 // 3 minutes
    var defaultSpeed: Double = 1.0
    var autoStartOnOpen: Bool = false
    var loopAtEnd: Bool = false
    var hapticFeedback: Bool = true

    // Keys for UserDefaults
    private enum Keys {
        static let defaultDuration = "autoscroll_defaultDuration"
        static let defaultSpeed = "autoscroll_defaultSpeed"
        static let autoStartOnOpen = "autoscroll_autoStartOnOpen"
        static let loopAtEnd = "autoscroll_loopAtEnd"
        static let hapticFeedback = "autoscroll_hapticFeedback"
    }

    static func load() -> AutoscrollSettings {
        var settings = AutoscrollSettings()

        let defaults = UserDefaults.standard

        if let duration = defaults.object(forKey: Keys.defaultDuration) as? TimeInterval {
            settings.defaultDuration = duration
        }

        if let speed = defaults.object(forKey: Keys.defaultSpeed) as? Double {
            settings.defaultSpeed = speed
        }

        settings.autoStartOnOpen = defaults.bool(forKey: Keys.autoStartOnOpen)
        settings.loopAtEnd = defaults.bool(forKey: Keys.loopAtEnd)
        settings.hapticFeedback = defaults.bool(forKey: Keys.hapticFeedback)

        return settings
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(defaultDuration, forKey: Keys.defaultDuration)
        defaults.set(defaultSpeed, forKey: Keys.defaultSpeed)
        defaults.set(autoStartOnOpen, forKey: Keys.autoStartOnOpen)
        defaults.set(loopAtEnd, forKey: Keys.loopAtEnd)
        defaults.set(hapticFeedback, forKey: Keys.hapticFeedback)
    }
}

// MARK: - Speed Presets

extension AutoscrollManager {
    static let speedPresets: [(label: String, value: Double)] = [
        ("0.5x", 0.5),
        ("0.75x", 0.75),
        ("1x", 1.0),
        ("1.25x", 1.25),
        ("1.5x", 1.5),
        ("2x", 2.0)
    ]

    var currentSpeedLabel: String {
        if let preset = Self.speedPresets.first(where: { abs($0.value - speedMultiplier) < 0.01 }) {
            return preset.label
        }
        return String(format: "%.2fx", speedMultiplier)
    }
}
