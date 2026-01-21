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

    func stop() {
        isScrolling = false
        isPaused = false

        displayLink?.invalidate()
        displayLink = nil

        startTime = 0
        pausedTime = 0
        pausedAt = 0

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
        let progress = min(1.0, elapsed / effectiveDuration)

        currentProgress = progress

        // Calculate scroll position
        let scrollPosition = progress * scrollableHeight
        onScrollToPosition?(scrollPosition)

        // Stop at bottom
        if progress >= 1.0 {
            stop()
        }
    }

    // MARK: - Cleanup

    deinit {
        displayLink?.invalidate()
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
