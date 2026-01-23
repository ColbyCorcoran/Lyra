//
//  AccessibilityManager.swift
//  Lyra
//
//  Centralized manager for all accessibility features
//  Makes Lyra accessible to all musicians
//

import Foundation
import SwiftUI
import UIKit
import Observation

/// Comprehensive accessibility manager coordinating all accessibility features
@Observable
class AccessibilityManager {
    static let shared = AccessibilityManager()

    // MARK: - System Accessibility States

    /// VoiceOver is active
    var isVoiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning

    /// Switch Control is active
    var isSwitchControlRunning: Bool = UIAccessibility.isSwitchControlRunning

    /// Voice Control is active
    var isVoiceControlRunning: Bool = false

    /// Guided Access is active
    var isGuidedAccessEnabled: Bool = UIAccessibility.isGuidedAccessEnabled

    /// Bold text is enabled
    var isBoldTextEnabled: Bool = UIAccessibility.isBoldTextEnabled

    /// Reduce motion is enabled
    var isReduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled

    /// Reduce transparency is enabled
    var isReduceTransparencyEnabled: Bool = UIAccessibility.isReduceTransparencyEnabled

    /// Differentiate without color is enabled
    var shouldDifferentiateWithoutColor: Bool = UIAccessibility.shouldDifferentiateWithoutColor

    /// Increase contrast is enabled
    var isDarkerSystemColorsEnabled: Bool = UIAccessibility.isDarkerSystemColorsEnabled

    /// Invert colors is enabled
    var isInvertColorsEnabled: Bool = UIAccessibility.isInvertColorsEnabled

    /// Mono audio is enabled
    var isMonoAudioEnabled: Bool = UIAccessibility.isMonoAudioEnabled

    /// Closed captions are enabled
    var isClosedCaptioningEnabled: Bool = UIAccessibility.isClosedCaptioningEnabled

    // MARK: - Lyra-Specific Accessibility Settings

    /// High contrast mode intensity (0 = off, 1 = standard, 2 = ultra)
    var highContrastMode: HighContrastMode = .off

    /// Simplified interface mode for cognitive accessibility
    var simplifiedMode: Bool = false

    /// Large buttons mode
    var largeButtonsMode: Bool = false

    /// Custom font size multiplier (on top of system Dynamic Type)
    var fontSizeMultiplier: CGFloat = 1.0

    /// Voice feedback for all actions
    var voiceFeedbackEnabled: Bool = false

    /// Haptic feedback strength
    var hapticStrength: HapticStrength = .medium

    /// Animation duration multiplier (0 = instant, 1 = normal)
    var animationSpeed: CGFloat = 1.0

    /// Braille display connected
    var brailleDisplayConnected: Bool = false

    /// Custom color scheme for vision impairments
    var customColorScheme: AccessibilityColorScheme?

    // MARK: - VoiceOver Settings

    /// Enable custom VoiceOver rotors
    var customRotorsEnabled: Bool = true

    /// Group related elements for better VoiceOver navigation
    var smartElementGrouping: Bool = true

    /// Describe chord diagrams audibly
    var describeChordDiagrams: Bool = true

    /// Announce section changes
    var announceSectionChanges: Bool = true

    // MARK: - Switch Control Settings

    /// Point scanning speed (seconds per scan)
    var pointScanningSpeed: Double = 1.0

    /// Item scanning speed
    var itemScanningSpeed: Double = 0.8

    /// Auto-scanning enabled
    var autoScanningEnabled: Bool = true

    /// Scanning highlight color
    var scanningHighlightColor: Color = .blue

    // MARK: - Initialization

    private init() {
        loadSettings()
        registerNotifications()
    }

    // MARK: - Notification Registration

    private func registerNotifications() {
        // VoiceOver
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
            self?.handleVoiceOverStatusChange()
        }

        // Switch Control
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.switchControlStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
            self?.handleSwitchControlStatusChange()
        }

        // Bold text
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        }

        // Reduce motion
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            self?.updateAnimationSpeed()
        }

        // Reduce transparency
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        }

        // Differentiate without color
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.differentiateWithoutColorDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.shouldDifferentiateWithoutColor = UIAccessibility.shouldDifferentiateWithoutColor
        }

        // Darker system colors
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }

        // Invert colors
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.invertColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isInvertColorsEnabled = UIAccessibility.isInvertColorsEnabled
        }
    }

    // MARK: - Status Change Handlers

    private func handleVoiceOverStatusChange() {
        if isVoiceOverRunning {
            // VoiceOver enabled - optimize for voice navigation
            if customRotorsEnabled {
                // Custom rotors will be configured per-view
            }

            // Announce VoiceOver is active
            announce("VoiceOver is now active. Use custom rotors to navigate by section or chord.")
        }
    }

    private func handleSwitchControlStatusChange() {
        if isSwitchControlRunning {
            // Switch Control enabled - optimize for scanning
            announce("Switch Control is now active")
        }
    }

    private func updateAnimationSpeed() {
        if isReduceMotionEnabled {
            animationSpeed = 0.0 // Instant transitions
        } else {
            animationSpeed = 1.0 // Normal speed
        }
    }

    // MARK: - Accessibility Helpers

    /// Get effective animation duration
    func animationDuration(_ baseDuration: CGFloat) -> CGFloat {
        return baseDuration * animationSpeed
    }

    /// Check if any accessibility technology is active
    var isAccessibilityTechnologyActive: Bool {
        isVoiceOverRunning ||
        isSwitchControlRunning ||
        isVoiceControlRunning ||
        isGuidedAccessEnabled
    }

    /// Get recommended minimum tap target size
    var minimumTapTargetSize: CGFloat {
        if largeButtonsMode || isSwitchControlRunning {
            return 60 // Extra large for switch control
        } else if isVoiceOverRunning {
            return 44 // Apple's recommended minimum
        } else {
            return 44 // Always use accessible size
        }
    }

    /// Get effective font size for text
    func effectiveFontSize(_ baseSize: CGFloat) -> CGFloat {
        var size = baseSize

        // Apply system Dynamic Type scaling
        let category = UIApplication.shared.preferredContentSizeCategory
        let scale = UIFontMetrics.default.scaledValue(for: 1.0)
        size *= scale

        // Apply custom multiplier
        size *= fontSizeMultiplier

        // Apply bold text adjustment
        if isBoldTextEnabled {
            size *= 1.1 // Slightly larger for bold
        }

        return size
    }

    /// Get contrast ratio for current settings
    var contrastRatio: CGFloat {
        switch highContrastMode {
        case .off:
            return isDarkerSystemColorsEnabled ? 1.2 : 1.0
        case .standard:
            return 1.5
        case .ultra:
            return 2.0
        }
    }

    /// Announce text with VoiceOver or speech
    func announce(_ text: String, priority: UIAccessibility.Announcement.Priority = .default) {
        if isVoiceOverRunning {
            // Use VoiceOver announcement
            UIAccessibility.post(notification: .announcement, argument: text)
        } else if voiceFeedbackEnabled {
            // Use speech synthesizer
            speakText(text)
        }
    }

    /// Announce page change
    func announcePageChange(_ text: String) {
        if isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: text)
        }
    }

    /// Announce layout change
    func announceLayoutChange(_ text: String? = nil) {
        if isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: text)
        }
    }

    /// Speak text using AVSpeechSynthesizer
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }

    // MARK: - Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard

        // High contrast mode
        if let modeRaw = defaults.string(forKey: "accessibility.highContrastMode"),
           let mode = HighContrastMode(rawValue: modeRaw) {
            highContrastMode = mode
        }

        // Simplified mode
        simplifiedMode = defaults.bool(forKey: "accessibility.simplifiedMode")

        // Large buttons
        largeButtonsMode = defaults.bool(forKey: "accessibility.largeButtonsMode")

        // Font size multiplier
        fontSizeMultiplier = CGFloat(defaults.double(forKey: "accessibility.fontSizeMultiplier"))
        if fontSizeMultiplier == 0 {
            fontSizeMultiplier = 1.0
        }

        // Voice feedback
        voiceFeedbackEnabled = defaults.bool(forKey: "accessibility.voiceFeedbackEnabled")

        // Haptic strength
        if let strengthRaw = defaults.string(forKey: "accessibility.hapticStrength"),
           let strength = HapticStrength(rawValue: strengthRaw) {
            hapticStrength = strength
        }

        // VoiceOver settings
        customRotorsEnabled = defaults.bool(forKey: "accessibility.customRotorsEnabled")
        if !defaults.bool(forKey: "accessibility.customRotorsEnabled.set") {
            customRotorsEnabled = true
            defaults.set(true, forKey: "accessibility.customRotorsEnabled.set")
        }

        smartElementGrouping = defaults.bool(forKey: "accessibility.smartElementGrouping")
        if !defaults.bool(forKey: "accessibility.smartElementGrouping.set") {
            smartElementGrouping = true
            defaults.set(true, forKey: "accessibility.smartElementGrouping.set")
        }

        describeChordDiagrams = defaults.bool(forKey: "accessibility.describeChordDiagrams")
        if !defaults.bool(forKey: "accessibility.describeChordDiagrams.set") {
            describeChordDiagrams = true
            defaults.set(true, forKey: "accessibility.describeChordDiagrams.set")
        }

        announceSectionChanges = defaults.bool(forKey: "accessibility.announceSectionChanges")
        if !defaults.bool(forKey: "accessibility.announceSectionChanges.set") {
            announceSectionChanges = true
            defaults.set(true, forKey: "accessibility.announceSectionChanges.set")
        }

        // Switch Control settings
        pointScanningSpeed = defaults.double(forKey: "accessibility.pointScanningSpeed")
        if pointScanningSpeed == 0 {
            pointScanningSpeed = 1.0
        }

        itemScanningSpeed = defaults.double(forKey: "accessibility.itemScanningSpeed")
        if itemScanningSpeed == 0 {
            itemScanningSpeed = 0.8
        }

        autoScanningEnabled = defaults.bool(forKey: "accessibility.autoScanningEnabled")
        if !defaults.bool(forKey: "accessibility.autoScanningEnabled.set") {
            autoScanningEnabled = true
            defaults.set(true, forKey: "accessibility.autoScanningEnabled.set")
        }

        // Update animation speed based on reduce motion
        updateAnimationSpeed()
    }

    func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(highContrastMode.rawValue, forKey: "accessibility.highContrastMode")
        defaults.set(simplifiedMode, forKey: "accessibility.simplifiedMode")
        defaults.set(largeButtonsMode, forKey: "accessibility.largeButtonsMode")
        defaults.set(Double(fontSizeMultiplier), forKey: "accessibility.fontSizeMultiplier")
        defaults.set(voiceFeedbackEnabled, forKey: "accessibility.voiceFeedbackEnabled")
        defaults.set(hapticStrength.rawValue, forKey: "accessibility.hapticStrength")

        defaults.set(customRotorsEnabled, forKey: "accessibility.customRotorsEnabled")
        defaults.set(smartElementGrouping, forKey: "accessibility.smartElementGrouping")
        defaults.set(describeChordDiagrams, forKey: "accessibility.describeChordDiagrams")
        defaults.set(announceSectionChanges, forKey: "accessibility.announceSectionChanges")

        defaults.set(pointScanningSpeed, forKey: "accessibility.pointScanningSpeed")
        defaults.set(itemScanningSpeed, forKey: "accessibility.itemScanningSpeed")
        defaults.set(autoScanningEnabled, forKey: "accessibility.autoScanningEnabled")
    }
}

// MARK: - Supporting Types

enum HighContrastMode: String, Codable, CaseIterable {
    case off = "off"
    case standard = "standard"
    case ultra = "ultra"

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .standard: return "High Contrast"
        case .ultra: return "Ultra High Contrast"
        }
    }

    var description: String {
        switch self {
        case .off: return "Standard contrast"
        case .standard: return "Increased contrast for better visibility"
        case .ultra: return "Maximum contrast with stark colors"
        }
    }
}

enum HapticStrength: String, Codable, CaseIterable {
    case off = "off"
    case light = "light"
    case medium = "medium"
    case strong = "strong"

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .light: return "Light"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }

    var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .off: return .light // Will not be used
        case .light: return .light
        case .medium: return .medium
        case .strong: return .heavy
        }
    }
}

struct AccessibilityColorScheme: Codable {
    var name: String
    var foregroundColor: String // Hex
    var backgroundColor: String // Hex
    var accentColor: String // Hex
    var contrastRatio: CGFloat

    static let highContrastDark = AccessibilityColorScheme(
        name: "High Contrast Dark",
        foregroundColor: "#FFFFFF",
        backgroundColor: "#000000",
        accentColor: "#FFFF00",
        contrastRatio: 21.0
    )

    static let highContrastLight = AccessibilityColorScheme(
        name: "High Contrast Light",
        foregroundColor: "#000000",
        backgroundColor: "#FFFFFF",
        accentColor: "#0000FF",
        contrastRatio: 21.0
    )

    static let yellowOnBlack = AccessibilityColorScheme(
        name: "Yellow on Black",
        foregroundColor: "#FFFF00",
        backgroundColor: "#000000",
        accentColor: "#00FFFF",
        contrastRatio: 19.5
    )

    static let greenOnBlack = AccessibilityColorScheme(
        name: "Green on Black",
        foregroundColor: "#00FF00",
        backgroundColor: "#000000",
        accentColor: "#FFFF00",
        contrastRatio: 15.0
    )
}

// MARK: - Notification Names

extension Notification.Name {
    static let accessibilitySettingsChanged = Notification.Name("accessibilitySettingsChanged")
    static let voiceFeedbackTriggered = Notification.Name("voiceFeedbackTriggered")
}

// MARK: - Import AVFoundation for Speech

import AVFoundation
