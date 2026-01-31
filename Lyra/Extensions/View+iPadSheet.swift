//
//  View+iPadSheet.swift
//  Lyra
//
//  Extension for better sheet presentation on iPad
//

import SwiftUI

extension View {
    /// Applies iPad-optimized sheet presentation settings
    /// - Parameters:
    ///   - detents: Optional custom detents. If nil, uses iPad-optimized defaults.
    ///   - selection: Optional binding for selected detent
    /// - Returns: Modified view with iPad-appropriate sheet sizing
    func iPadSheetPresentation(
        detents: Set<PresentationDetent>? = nil,
        selection: Binding<PresentationDetent>? = nil
    ) -> some View {
        self.modifier(iPadSheetModifier(detents: detents, selection: selection))
    }
}

private struct iPadSheetModifier: ViewModifier {
    let detents: Set<PresentationDetent>?
    let selection: Binding<PresentationDetent>?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            // iPad - use larger detents
            if let detents = detents {
                if let selection = selection {
                    content
                        .presentationDetents(detents, selection: selection)
                        .presentationDragIndicator(.visible)
                } else {
                    content
                        .presentationDetents(detents)
                        .presentationDragIndicator(.visible)
                }
            } else {
                // Default: medium and large detents for iPad
                content
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        } else {
            // iPhone - use default behavior
            if let detents = detents {
                if let selection = selection {
                    content
                        .presentationDetents(detents, selection: selection)
                } else {
                    content
                        .presentationDetents(detents)
                }
            } else {
                content
            }
        }
    }
}
