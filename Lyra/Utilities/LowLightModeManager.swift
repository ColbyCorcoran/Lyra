//
//  LowLightModeManager.swift
//  Lyra
//
//  Manager for low light mode with brightness control and color scheme
//

import Foundation
import SwiftUI
import UIKit

@Observable
class LowLightModeManager {
    // MARK: - State Properties

    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                enableLowLightMode()
            } else {
                disableLowLightMode()
            }
        }
    }

    var intensity: Double = 0.7 // 0.0 (subtle) to 1.0 (maximum)
    var color: LowLightColor = .red
    var dimUIElements: Bool = true
    var autoEnableTime: Bool = false
    var autoEnableStartHour: Int = 20 // 8 PM
    var autoEnableEndHour: Int = 7 // 7 AM

    // MARK: - Private Properties

    private var originalBrightness: CGFloat = 0.5
    private var brightnessOverride: CGFloat?

    // MARK: - Initialization

    init() {
        loadSettings()
        checkAutoEnable()
    }

    // MARK: - Public Methods

    func toggle() {
        isEnabled.toggle()
        saveSettings()
        HapticManager.shared.selection()
    }

    func setBrightness(_ brightness: CGFloat) {
        brightnessOverride = brightness
        if isEnabled {
            applyBrightness()
        }
    }

    func checkAutoEnable() {
        guard autoEnableTime else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        // Check if current time is within low light hours
        let shouldEnable: Bool
        if autoEnableStartHour > autoEnableEndHour {
            // Crosses midnight (e.g., 20:00 - 7:00)
            shouldEnable = hour >= autoEnableStartHour || hour < autoEnableEndHour
        } else {
            // Same day (e.g., 22:00 - 23:00)
            shouldEnable = hour >= autoEnableStartHour && hour < autoEnableEndHour
        }

        if shouldEnable && !isEnabled {
            isEnabled = true
            saveSettings()
        } else if !shouldEnable && isEnabled && autoEnableTime {
            isEnabled = false
            saveSettings()
        }
    }

    // MARK: - Color Scheme

    func textColor(for originalColor: Color) -> Color {
        guard isEnabled else { return originalColor }

        // Convert to low light color
        let lowLightBase = color.color

        // Apply intensity
        return lowLightBase.opacity(intensity)
    }

    func backgroundColor(for originalColor: Color) -> Color {
        guard isEnabled else { return originalColor }

        // Pure black background for maximum contrast
        return .black
    }

    func accentColor(for originalColor: Color) -> Color {
        guard isEnabled else { return originalColor }

        // Dimmed accent color
        let lowLightBase = color.color
        return lowLightBase.opacity(intensity * 0.8)
    }

    // MARK: - PDF Color Transformation

    func transformPDFColor(_ color: UIColor) -> UIColor {
        guard isEnabled else { return color }

        // Convert to grayscale, then tint with low light color
        var white: CGFloat = 0
        color.getWhite(&white, alpha: nil)

        let tintColor = color.uiColor
        return tintColor.withAlphaComponent(white * intensity)
    }

    // MARK: - Private Methods

    private func enableLowLightMode() {
        // Save original brightness
        originalBrightness = UIScreen.main.brightness

        // Apply low light brightness
        applyBrightness()

        // Haptic feedback
        HapticManager.shared.impact(.medium)
    }

    private func disableLowLightMode() {
        // Restore original brightness
        UIScreen.main.brightness = originalBrightness
        brightnessOverride = nil

        // Haptic feedback
        HapticManager.shared.impact(.light)
    }

    private func applyBrightness() {
        let targetBrightness = brightnessOverride ?? (intensity * 0.3) // Max 30% brightness in low light

        // Animate brightness change
        UIView.animate(withDuration: 0.3) {
            UIScreen.main.brightness = targetBrightness
        }
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard

        isEnabled = defaults.bool(forKey: "lowLightMode.isEnabled")
        intensity = defaults.double(forKey: "lowLightMode.intensity")
        if intensity == 0 { intensity = 0.7 } // Default

        if let colorRaw = defaults.string(forKey: "lowLightMode.color"),
           let savedColor = LowLightColor(rawValue: colorRaw) {
            color = savedColor
        }

        dimUIElements = defaults.bool(forKey: "lowLightMode.dimUIElements")
        if !defaults.bool(forKey: "lowLightMode.dimUIElements.set") {
            dimUIElements = true // Default
            defaults.set(true, forKey: "lowLightMode.dimUIElements.set")
        }

        autoEnableTime = defaults.bool(forKey: "lowLightMode.autoEnableTime")
        autoEnableStartHour = defaults.integer(forKey: "lowLightMode.autoEnableStartHour")
        if autoEnableStartHour == 0 { autoEnableStartHour = 20 } // Default

        autoEnableEndHour = defaults.integer(forKey: "lowLightMode.autoEnableEndHour")
        if autoEnableEndHour == 0 { autoEnableEndHour = 7 } // Default
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(isEnabled, forKey: "lowLightMode.isEnabled")
        defaults.set(intensity, forKey: "lowLightMode.intensity")
        defaults.set(color.rawValue, forKey: "lowLightMode.color")
        defaults.set(dimUIElements, forKey: "lowLightMode.dimUIElements")
        defaults.set(autoEnableTime, forKey: "lowLightMode.autoEnableTime")
        defaults.set(autoEnableStartHour, forKey: "lowLightMode.autoEnableStartHour")
        defaults.set(autoEnableEndHour, forKey: "lowLightMode.autoEnableEndHour")
    }
}

// MARK: - Low Light Color

enum LowLightColor: String, CaseIterable, Identifiable, Codable {
    case red = "Red"
    case amber = "Amber"
    case orange = "Orange"
    case deepRed = "Deep Red"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red:
            return Color(red: 1.0, green: 0.1, blue: 0.1)
        case .amber:
            return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .orange:
            return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .deepRed:
            return Color(red: 0.8, green: 0.0, blue: 0.0)
        }
    }

    var uiColor: UIColor {
        switch self {
        case .red:
            return UIColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0)
        case .amber:
            return UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        case .orange:
            return UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)
        case .deepRed:
            return UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        }
    }

    var displayName: String { rawValue }
}
