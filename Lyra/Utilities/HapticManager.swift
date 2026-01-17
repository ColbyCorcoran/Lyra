//
//  HapticManager.swift
//  Lyra
//
//  Manages haptic feedback throughout the app for a premium, responsive feel
//

import UIKit

/// Centralized haptic feedback management
@MainActor
class HapticManager {
    static let shared = HapticManager()

    // Generators (reused for better performance)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Prepare generators for better responsiveness
        lightGenerator.prepare()
        mediumGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Impact Feedback

    /// Light impact - for subtle interactions like hovering or previewing
    func light() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// Medium impact - for standard button taps and selections
    func medium() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    /// Heavy impact - for significant actions like deletions
    func heavy() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    // MARK: - Selection Feedback

    /// Selection changed - for pickers, color swatches, toggles
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Notification Feedback

    /// Success - for completed actions like save, import, paste
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Warning - for non-critical issues
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Error - for failures and critical issues
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    // MARK: - Convenience Methods

    /// Haptic for button tap
    func buttonTap() {
        medium()
    }

    /// Haptic for successful save operation
    func saveSuccess() {
        success()
    }

    /// Haptic for failed operation
    func operationFailed() {
        error()
    }

    /// Haptic for color/option selection
    func optionSelected() {
        selection()
    }

    /// Haptic for swipe action (delete, etc.)
    func swipeAction() {
        heavy()
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// View modifier to add haptic feedback to button taps
struct HapticFeedback: ViewModifier {
    let style: HapticStyle

    enum HapticStyle {
        case light, medium, heavy, selection
    }

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        switch style {
                        case .light:
                            HapticManager.shared.light()
                        case .medium:
                            HapticManager.shared.medium()
                        case .heavy:
                            HapticManager.shared.heavy()
                        case .selection:
                            HapticManager.shared.selection()
                        }
                    }
            )
    }
}

extension View {
    /// Add haptic feedback to button taps
    func hapticFeedback(_ style: HapticFeedback.HapticStyle = .medium) -> some View {
        modifier(HapticFeedback(style: style))
    }
}
