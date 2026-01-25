//
//  LiveEditingBanner.swift
//  Lyra
//
//  Shows who is currently editing a song with live indicators
//

import SwiftUI

struct LiveEditingBanner: View {
    let editors: [UserPresence]
    let currentSongID: UUID
    var onDismiss: (() -> Void)?
    var lockEditing: Bool = false

    @State private var isExpanded: Bool = false

    var body: some View {
        if !editors.isEmpty {
            VStack(spacing: 0) {
                // Main banner
                mainBanner

                // Expanded details
                if isExpanded && editors.count > 1 {
                    expandedDetails
                }
            }
            .background(Material.thin)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: - Main Banner

    private var mainBanner: some View {
        HStack(spacing: 12) {
            // Animated editing indicator
            editingIndicator

            // Editor info
            VStack(alignment: .leading, spacing: 4) {
                Text(bannerTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(bannerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Expand/collapse button if multiple editors
            if editors.count > 1 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Dismiss button
            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Editing Indicator

    private var editingIndicator: some View {
        ZStack {
            // Pulsing circle
            Circle()
                .fill(editorColor.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay {
                    Circle()
                        .fill(editorColor.opacity(0.5))
                        .frame(width: 30, height: 30)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }

            // Icon or avatar
            if editors.count == 1 {
                Text(editors[0].displayNameOrDefault.prefix(1).uppercased())
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }

    @State private var pulseAnimation: Bool = false

    // MARK: - Expanded Details

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            ForEach(editors) { editor in
                HStack(spacing: 12) {
                    // Editor avatar
                    Circle()
                        .fill(Color(hex: editor.colorHex))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(editor.displayNameOrDefault.prefix(1).uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }

                    // Editor name and device
                    VStack(alignment: .leading, spacing: 2) {
                        Text(editor.displayNameOrDefault)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 6) {
                            Image(systemName: deviceIcon(for: editor.deviceType))
                                .font(.caption2)

                            Text(editor.deviceType)
                                .font(.caption2)

                            if let cursor = editor.cursorPosition {
                                Text("•")
                                    .font(.caption2)
                                Text("Line \(cursor)")
                                    .font(.caption2)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Active indicator
                    if editor.isActive {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Computed Properties

    private var bannerTitle: String {
        if lockEditing {
            return "Editing Locked"
        } else if editors.count == 1 {
            return "\(editors[0].displayNameOrDefault) is editing"
        } else {
            return "\(editors.count) people are editing"
        }
    }

    private var bannerSubtitle: String {
        if lockEditing {
            return "Someone else is currently editing this song"
        } else if editors.count == 1 {
            if let cursor = editors[0].cursorPosition {
                return "Currently at line \(cursor)"
            } else {
                return "Active now on \(editors[0].deviceType)"
            }
        } else {
            let devices = editors.map { $0.deviceType }.joined(separator: ", ")
            return "Active on \(devices)"
        }
    }

    private var editorColor: Color {
        if editors.count == 1 {
            return Color(hex: editors[0].colorHex)
        } else {
            return .blue
        }
    }

    // MARK: - Helper Methods

    private func deviceIcon(for deviceType: String) -> String {
        switch deviceType.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "macbook"
        default: return "desktopcomputer"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Single editor
        LiveEditingBanner(
            editors: [
                UserPresence(
                    userRecordID: "user1",
                    displayName: "John Doe",
                    deviceType: "iPhone"
                )
            ],
            currentSongID: UUID()
        )

        // Multiple editors
        LiveEditingBanner(
            editors: [
                UserPresence(userRecordID: "user1", displayName: "John Doe", deviceType: "iPhone"),
                UserPresence(userRecordID: "user2", displayName: "Jane Smith", deviceType: "iPad"),
                UserPresence(userRecordID: "user3", displayName: "Bob Wilson", deviceType: "Mac")
            ],
            currentSongID: UUID()
        )

        // Editing locked
        LiveEditingBanner(
            editors: [
                UserPresence(userRecordID: "user1", displayName: "John Doe", deviceType: "iPhone")
            ],
            currentSongID: UUID(),
            lockEditing: true
        )

        Spacer()
    }
    .padding()
}
