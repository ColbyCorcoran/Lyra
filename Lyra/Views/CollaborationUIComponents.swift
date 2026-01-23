//
//  CollaborationUIComponents.swift
//  Lyra
//
//  UI components for handling collaboration edge cases and providing user feedback
//

import SwiftUI

// MARK: - Concurrent Editing Warning

struct ConcurrentEditingWarning: View {
    let editors: [String]
    let onContinue: () -> Void
    let onViewConflicts: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Warning Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            // Title
            Text("Others Are Editing")
                .font(.title3)
                .fontWeight(.semibold)

            // Message
            VStack(spacing: 8) {
                if editors.count == 1 {
                    Text("\(editors[0]) is currently editing this song")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("\(editors.count) people are editing this song:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(editors.prefix(3), id: \.self) { editor in
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                Text(editor)
                                    .font(.caption)
                            }
                        }

                        if editors.count > 3 {
                            Text("and \(editors.count - 3) more...")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text("Your changes might conflict with theirs")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }

            // Actions
            VStack(spacing: 12) {
                Button {
                    onContinue()
                } label: {
                    Text("Continue Editing")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    onViewConflicts()
                } label: {
                    Text("View Potential Conflicts")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }
}

// MARK: - Permission Denied View

struct PermissionDeniedView: View {
    let requiredPermission: LibraryPermission
    let currentPermission: LibraryPermission?
    let onRequestAccess: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Lock Icon
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            // Title
            Text("Permission Required")
                .font(.title2)
                .fontWeight(.semibold)

            // Message
            VStack(spacing: 8) {
                if let current = currentPermission {
                    Text("You need \(requiredPermission.rawValue) permission")
                        .font(.subheadline)

                    Text("Current permission: \(current.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("You don't have access to this resource")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(requiredPermission.description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)

            // Actions
            VStack(spacing: 12) {
                Button {
                    onRequestAccess()
                } label: {
                    Text("Request Access")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }
}

// MARK: - Active Editors Indicator

struct ActiveEditorsIndicator: View {
    let editors: [String]
    let currentUserID: String

    @State private var isExpanded = false

    var body: some View {
        if !editors.isEmpty {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 8) {
                    // Avatars
                    HStack(spacing: -8) {
                        ForEach(editors.prefix(3), id: \.self) { editor in
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Text(editor.prefix(1))
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                                .overlay {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 2)
                                }
                        }
                    }

                    Text("\(editors.count) editing")
                        .font(.caption)
                        .fontWeight(.medium)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
            }
            .popover(isPresented: $isExpanded) {
                EditorsList(editors: editors, currentUserID: currentUserID)
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}

struct EditorsList: View {
    let editors: [String]
    let currentUserID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently Editing")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            Divider()

            ForEach(editors, id: \.self) { editor in
                HStack(spacing: 12) {
                    Circle()
                        .fill(editor == currentUserID ? Color.green : Color.blue)
                        .frame(width: 8, height: 8)

                    Text(editor == currentUserID ? "\(editor) (You)" : editor)
                        .font(.subheadline)

                    Spacer()
                }
                .padding(.horizontal)
            }

            Divider()

            Text("Changes are synced in real-time")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .frame(width: 250)
    }
}

// MARK: - Library Deleted Alert

struct LibraryDeletedAlert: View {
    let libraryName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text("Library Deleted")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\"\(libraryName)\" was deleted by its owner")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                onDismiss()
            } label: {
                Text("OK")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }
}

// MARK: - User Removed Alert

struct UserRemovedAlert: View {
    let libraryName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Access Removed")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You were removed from \"\(libraryName)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Your local changes have been saved")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button {
                onDismiss()
            } label: {
                Text("OK")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }
}

// MARK: - Conflict Resolution Dialog

struct ConflictResolutionDialog: View {
    let conflict: SyncConflict
    let onResolve: (ConflictResolution) -> Void
    let onDismiss: () -> Void

    @State private var selectedResolution: ResolutionOption = .useLocal

    enum ResolutionOption {
        case useLocal
        case useRemote
        case keepBoth
        case merge

        var title: String {
            switch self {
            case .useLocal: return "Use My Version"
            case .useRemote: return "Use Their Version"
            case .keepBoth: return "Keep Both Versions"
            case .merge: return "Merge Changes"
            }
        }

        var description: String {
            switch self {
            case .useLocal: return "Discard remote changes and keep your version"
            case .useRemote: return "Discard your changes and use their version"
            case .keepBoth: return "Create duplicate with both versions"
            case .merge: return "Manually merge conflicting changes"
            }
        }

        var icon: String {
            switch self {
            case .useLocal: return "arrow.left.circle"
            case .useRemote: return "arrow.right.circle"
            case .keepBoth: return "square.on.square"
            case .merge: return "arrow.triangle.merge"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)

                Text("Sync Conflict")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Changes were made on multiple devices")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Version comparison
            HStack(spacing: 12) {
                VersionCard(
                    title: "Your Version",
                    timestamp: conflict.localVersion.timestamp,
                    device: conflict.localVersion.deviceName,
                    isSelected: selectedResolution == .useLocal
                )

                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(.orange)

                VersionCard(
                    title: "Their Version",
                    timestamp: conflict.remoteVersion.timestamp,
                    device: conflict.remoteVersion.deviceName,
                    isSelected: selectedResolution == .useRemote
                )
            }

            // Resolution options
            VStack(spacing: 12) {
                ForEach([ResolutionOption.useLocal, .useRemote, .keepBoth, .merge], id: \.title) { option in
                    Button {
                        selectedResolution = option
                    } label: {
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundStyle(selectedResolution == option ? .blue : .secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)

                                Text(option.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedResolution == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(
                            selectedResolution == option ?
                            Color.blue.opacity(0.1) :
                            Color(.secondarySystemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button {
                    onDismiss()
                } label: {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    let resolution: ConflictResolution
                    switch selectedResolution {
                    case .useLocal:
                        resolution = .useLocal
                    case .useRemote:
                        resolution = .useRemote
                    case .keepBoth:
                        resolution = .keepBoth
                    case .merge:
                        // Would show merge editor
                        resolution = .useLocal // Placeholder
                    }
                    onResolve(resolution)
                } label: {
                    Text("Resolve")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }
}

struct VersionCard: View {
    let title: String
    let timestamp: Date
    let device: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(timestamp, style: .relative)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(device)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.blue, lineWidth: 2)
            }
        }
    }
}

// MARK: - Rate Limit Warning

struct RateLimitWarning: View {
    let retryAfter: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rate Limited")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Too many requests. Retry in \(Int(retryAfter))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview("Concurrent Editing") {
    ConcurrentEditingWarning(
        editors: ["Alice", "Bob", "Charlie"],
        onContinue: {},
        onViewConflicts: {}
    )
    .padding()
}

#Preview("Permission Denied") {
    PermissionDeniedView(
        requiredPermission: .admin,
        currentPermission: .viewer,
        onRequestAccess: {},
        onDismiss: {}
    )
    .padding()
}

#Preview("Conflict Resolution") {
    ConflictResolutionDialog(
        conflict: SyncConflict(
            conflictType: .contentModification,
            entityType: .song,
            entityID: UUID(),
            localVersion: SyncConflict.ConflictVersion(
                timestamp: Date(),
                deviceName: "iPhone",
                data: SyncConflict.ConflictVersion.ConflictData()
            ),
            remoteVersion: SyncConflict.ConflictVersion(
                timestamp: Date().addingTimeInterval(-300),
                deviceName: "iPad",
                data: SyncConflict.ConflictVersion.ConflictData()
            ),
            detectedAt: Date()
        ),
        onResolve: { _ in },
        onDismiss: {}
    )
    .padding()
}
