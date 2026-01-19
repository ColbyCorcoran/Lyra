//
//  ColorSwatch.swift
//  Lyra
//
//  Shared color picker swatch component
//

import SwiftUI

struct ColorSwatch: View {
    let name: String
    let hex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 44, height: 44)

                    if isSelected {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }

                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
