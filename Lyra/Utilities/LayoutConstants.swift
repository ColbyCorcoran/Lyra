//
//  LayoutConstants.swift
//  Lyra
//
//  Centralized layout constants for consistent spacing and sizing
//

import SwiftUI

/// Spacing constants for consistent layout throughout the app
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

/// Corner radius constants for consistent rounded corners
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

/// Icon size constants for consistent icon sizing
enum IconSize {
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 44
}

/// Shadow constants for consistent depth effects
enum ShadowStyle {
    static let light = (radius: CGFloat(4), opacity: 0.1)
    static let medium = (radius: CGFloat(8), opacity: 0.15)
    static let heavy = (radius: CGFloat(12), opacity: 0.2)
}
