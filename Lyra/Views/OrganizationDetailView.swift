//
//  OrganizationDetailView.swift
//  Lyra
//
//  Comprehensive organization management view
//

import SwiftUI
import SwiftData

struct OrganizationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let organization: Organization

    @StateObject private var orgManager = OrganizationManager.shared

    @State private var showMembers = false
    @State private var showSettings = false
    @State private var showAuditLog = false
    @State private var showDeleteConfirmation = false

    // Mock current user
    private let currentUserRecordID = "user_current"

    var body: some View {
        NavigationStack {
            List {
                // Header Section
                Section {
                    VStack(spacing: 16) {
                        // Icon
                        Image(systemName: organization.displayIcon)
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .frame(width: 100, height: 100)
                            .background(
                                Circle()
                                    .fill(
                                        Color(hex: organization.displayColor) ?? .blue
                                    )
                            )

                        VStack(spacing: 4) {
                            Text(organization.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(organization.organizationType.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let description = organization.organizationDescription {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                        }

                        // Subscription Badge
                        HStack(spacing: 16) {
                            VStack {
                                Text(organization.subscriptionTier.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("Plan")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack {
                                Text("\(organization.currentSeats)/\(organization.maxSeats == 0 ? "∞" : "\(organization.maxSeats)")")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("Seats")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)

                // Quick Stats
                Section("Overview") {
                    NavigationLink {
                        OrganizationMembersView(organization: organization)
                    } label: {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading) {
                                Text("Members")
                                    .font(.subheadline)
                                Text("\(organization.memberCount) total, \(organization.adminCount) admins")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }

                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(.green)
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text("Libraries")
                                .font(.subheadline)
                            Text("\(organization.libraryCount) shared libraries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(organization.libraryCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "music.note")
                            .foregroundStyle(.purple)
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text("Total Songs")
                                .font(.subheadline)
                            Text("Across all libraries")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(organization.totalSongs)")
                            .foregroundStyle(.secondary)
                    }

                    if let lastActivity = organization.lastActivityAt {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 30)

                            VStack(alignment: .leading) {
                                Text("Last Activity")
                                    .font(.subheadline)
                                Text(lastActivity, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                }

                // Management
                if canManageOrganization {
                    Section("Management") {
                        NavigationLink {
                            OrganizationMembersView(organization: organization)
                        } label: {
                            Label("Manage Members", systemImage: "person.2.badge.gearshape")
                        }

                        NavigationLink {
                            OrganizationSettingsView(organization: organization)
                        } label: {
                            Label("Organization Settings", systemImage: "gearshape")
                        }

                        if canViewAuditLog {
                            NavigationLink {
                                AuditLogView(organization: organization)
                            } label: {
                                Label("Audit Log", systemImage: "doc.text")
                            }
                        }
                    }
                }

                // Libraries
                if let libraries = organization.libraries, !libraries.isEmpty {
                    Section("Shared Libraries") {
                        ForEach(libraries) { library in
                            LibraryRow(library: library)
                        }
                    }
                }

                // Subscription
                Section("Subscription") {
                    HStack {
                        Label("Current Plan", systemImage: "creditcard")
                        Spacer()
                        Text(organization.subscriptionTier.rawValue)
                            .foregroundStyle(.secondary)
                    }

                    if organization.subscriptionTier != .enterprise {
                        NavigationLink {
                            SubscriptionPlansView(organization: organization)
                        } label: {
                            Label("Upgrade Plan", systemImage: "arrow.up.circle")
                        }
                    }

                    if let expiresAt = organization.subscriptionExpiresAt {
                        HStack {
                            Label("Expires", systemImage: "calendar.badge.clock")
                            Spacer()
                            Text(expiresAt, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    } else if organization.subscriptionTier == .free {
                        Text("Free plan - no expiration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Danger Zone
                if isOwner {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Organization", systemImage: "trash")
                        }
                    } header: {
                        Text("Danger Zone")
                    } footer: {
                        Text("Deleting this organization will remove all members, libraries, and data. This action cannot be undone.")
                    }
                }
            }
            .navigationTitle("Organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Organization", isPresented: $showDeleteConfirmation) {
                TextField("Type '\(organization.name)' to confirm", text: .constant(""))
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteOrganization()
                }
            } message: {
                Text("This will permanently delete '\(organization.name)' and all associated data. This action cannot be undone.")
            }
        }
    }

    private var currentUserRole: OrganizationRole? {
        organization.currentUserRole(userRecordID: currentUserRecordID)
    }

    private var isOwner: Bool {
        currentUserRecordID == organization.ownerRecordID
    }

    private var canManageOrganization: Bool {
        guard let role = currentUserRole else { return false }
        return role.canManageSettings
    }

    private var canViewAuditLog: Bool {
        guard let role = currentUserRole else { return false }
        return role.canViewAuditLog
    }

    private func deleteOrganization() {
        Task {
            do {
                try await orgManager.deleteOrganization(
                    organization,
                    deletedBy: currentUserRecordID,
                    modelContext: modelContext
                )
                dismiss()
            } catch {
                print("Error deleting organization: \(error)")
            }
        }
    }
}

// MARK: - Library Row

struct LibraryRow: View {
    let library: SharedLibrary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: library.displayIcon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: library.colorHex ?? "#4A90E2") ?? .blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(library.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Label("\(library.songCount)", systemImage: "music.note")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("\(library.memberCount)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Subscription Plans View

struct SubscriptionPlansView: View {
    let organization: Organization

    @StateObject private var orgManager = OrganizationManager.shared

    var body: some View {
        List {
            ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(tier.rawValue)
                                .font(.title3)
                                .fontWeight(.bold)

                            Spacer()

                            Text("$\(String(format: "%.2f", tier.monthlyPrice))/mo")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }

                        Divider()

                        ForEach(tier.features, id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)

                                Text(feature)
                                    .font(.subheadline)
                            }
                        }

                        if tier != organization.subscriptionTier {
                            Button {
                                upgradeTo(tier)
                            } label: {
                                Text("Upgrade to \(tier.rawValue)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        } else {
                            Text("Current Plan")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Subscription Plans")
    }

    private func upgradeTo(_ tier: SubscriptionTier) {
        // TODO: Implement actual subscription upgrade
        organization.upgradeTier(to: tier)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Organization.self, SharedLibrary.self, configurations: config)

    let org = Organization(
        name: "First Baptist Church",
        description: "Main worship team organization",
        organizationType: .church,
        ownerRecordID: "owner123",
        ownerDisplayName: "John Doe"
    )
    org.memberCount = 15
    org.libraryCount = 3
    org.totalSongs = 250
    org.lastActivityAt = Date().addingTimeInterval(-3600)
    container.mainContext.insert(org)

    return OrganizationDetailView(organization: org)
        .modelContainer(container)
}
