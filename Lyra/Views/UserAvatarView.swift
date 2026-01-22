//
//  UserAvatarView.swift
//  Lyra
//
//  Reusable avatar component for displaying user presence
//

import SwiftUI

// MARK: - User Avatar View

struct UserAvatarView: View {
    let presence: UserPresence
    let size: AvatarSize
    var showStatus: Bool = true
    var showDevice: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar circle
            Circle()
                .fill(Color(hex: presence.colorHex))
                .frame(width: size.dimension, height: size.dimension)
                .overlay {
                    // Initials or icon
                    Text(initials)
                        .font(size.font)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            // Status indicator
            if showStatus {
                StatusIndicator(
                    status: presence.status,
                    size: size.statusSize
                )
                .offset(x: 2, y: 2)
            }

            // Device indicator
            if showDevice {
                DeviceIndicator(
                    deviceType: presence.deviceType,
                    size: size.statusSize
                )
                .offset(x: 2, y: 2)
            }
        }
    }

    private var initials: String {
        presence.displayNameOrDefault
            .components(separatedBy: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: UserPresence.PresenceStatus
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: 2)
            }
    }

    private var statusColor: Color {
        switch status {
        case .online: return .green
        case .away: return .yellow
        case .offline: return .gray
        case .doNotDisturb: return .red
        }
    }
}

// MARK: - Device Indicator

struct DeviceIndicator: View {
    let deviceType: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color(.systemGray4))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: deviceIcon)
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: 2)
            }
    }

    private var deviceIcon: String {
        switch deviceType.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "macbook"
        default: return "desktopcomputer"
        }
    }
}

// MARK: - Avatar Sizes

enum AvatarSize {
    case tiny      // 24pt
    case small     // 32pt
    case medium    // 48pt
    case large     // 64pt
    case extraLarge // 96pt

    var dimension: CGFloat {
        switch self {
        case .tiny: return 24
        case .small: return 32
        case .medium: return 48
        case .large: return 64
        case .extraLarge: return 96
        }
    }

    var font: Font {
        switch self {
        case .tiny: return .system(size: 10, design: .rounded)
        case .small: return .system(size: 12, design: .rounded)
        case .medium: return .system(size: 18, design: .rounded)
        case .large: return .system(size: 24, design: .rounded)
        case .extraLarge: return .system(size: 36, design: .rounded)
        }
    }

    var statusSize: CGFloat {
        switch self {
        case .tiny: return 8
        case .small: return 10
        case .medium: return 14
        case .large: return 18
        case .extraLarge: return 24
        }
    }
}

// MARK: - Avatar Stack

/// Displays multiple user avatars in a stacked layout
struct UserAvatarStack: View {
    let users: [UserPresence]
    let size: AvatarSize
    var maxDisplay: Int = 4
    var spacing: CGFloat = -8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(users.prefix(maxDisplay)) { user in
                UserAvatarView(
                    presence: user,
                    size: size,
                    showStatus: true
                )
                .overlay {
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                }
            }

            // Count indicator if more users
            if users.count > maxDisplay {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: size.dimension, height: size.dimension)
                    .overlay {
                        Text("+\(users.count - maxDisplay)")
                            .font(size.font)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    }
            }
        }
    }
}

// MARK: - Animated Avatar

/// Avatar with pulsing animation for active editors
struct AnimatedUserAvatarView: View {
    let presence: UserPresence
    let size: AvatarSize
    @State private var isPulsing: Bool = false

    var body: some View {
        UserAvatarView(
            presence: presence,
            size: size,
            showStatus: true
        )
        .overlay {
            if presence.isEditing {
                Circle()
                    .stroke(Color(hex: presence.colorHex), lineWidth: 3)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0.0 : 0.7)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            }
        }
        .onAppear {
            if presence.isEditing {
                isPulsing = true
            }
        }
    }
}

// MARK: - Avatar with Name

struct UserAvatarWithName: View {
    let presence: UserPresence
    let size: AvatarSize
    var layout: Layout = .horizontal

    var body: some View {
        switch layout {
        case .horizontal:
            HStack(spacing: 8) {
                avatarView
                nameView
            }
        case .vertical:
            VStack(spacing: 6) {
                avatarView
                nameView
            }
        }
    }

    private var avatarView: some View {
        UserAvatarView(
            presence: presence,
            size: size,
            showStatus: true
        )
    }

    private var nameView: some View {
        VStack(alignment: layout == .horizontal ? .leading : .center, spacing: 2) {
            Text(presence.displayNameOrDefault)
                .font(layout == .horizontal ? .subheadline : .caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(presence.activityDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    enum Layout {
        case horizontal
        case vertical
    }
}

// MARK: - Avatar Grid

/// Grid layout for displaying multiple users
struct UserAvatarGrid: View {
    let users: [UserPresence]
    let columns: Int
    let size: AvatarSize

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 12
        ) {
            ForEach(users) { user in
                UserAvatarWithName(
                    presence: user,
                    size: size,
                    layout: .vertical
                )
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("Avatar Sizes") {
    VStack(spacing: 20) {
        UserAvatarView(
            presence: UserPresence(userRecordID: "1", displayName: "John Doe"),
            size: .tiny
        )

        UserAvatarView(
            presence: UserPresence(userRecordID: "1", displayName: "John Doe"),
            size: .small
        )

        UserAvatarView(
            presence: UserPresence(userRecordID: "1", displayName: "John Doe"),
            size: .medium
        )

        UserAvatarView(
            presence: UserPresence(userRecordID: "1", displayName: "John Doe"),
            size: .large
        )

        UserAvatarView(
            presence: UserPresence(userRecordID: "1", displayName: "John Doe"),
            size: .extraLarge
        )
    }
}

#Preview("Avatar Stack") {
    UserAvatarStack(
        users: [
            UserPresence(userRecordID: "1", displayName: "John Doe"),
            UserPresence(userRecordID: "2", displayName: "Jane Smith"),
            UserPresence(userRecordID: "3", displayName: "Bob Wilson"),
            UserPresence(userRecordID: "4", displayName: "Alice Brown"),
            UserPresence(userRecordID: "5", displayName: "Charlie Davis")
        ],
        size: .medium
    )
    .padding()
}

#Preview("Animated Avatar") {
    AnimatedUserAvatarView(
        presence: {
            let user = UserPresence(userRecordID: "1", displayName: "John Doe")
            user.isEditing = true
            return user
        }(),
        size: .large
    )
    .padding()
}

#Preview("Avatar with Name") {
    VStack(spacing: 20) {
        UserAvatarWithName(
            presence: UserPresence(userRecordID: "1", displayName: "John Doe"),
            size: .medium,
            layout: .horizontal
        )

        UserAvatarWithName(
            presence: UserPresence(userRecordID: "1", displayName: "John Doe"),
            size: .medium,
            layout: .vertical
        )
    }
    .padding()
}
