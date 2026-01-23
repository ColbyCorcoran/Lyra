//
//  TeamDirectoryView.swift
//  Lyra
//
//  Directory view for browsing and switching between organizations
//

import SwiftUI
import SwiftData

struct TeamDirectoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allOrganizations: [Organization]

    @StateObject private var orgManager = OrganizationManager.shared

    @State private var showCreateOrganization = false
    @State private var selectedOrganization: Organization?
    @State private var searchText = ""

    // Mock current user - in production, get from authentication
    private let currentUserRecordID = "user_current"

    var body: some View {
        NavigationStack {
            List {
                // Current Organization Section
                if let current = orgManager.currentOrganization {
                    Section("Current Organization") {
                        OrganizationCard(organization: current, isCurrent: true) {
                            // Already current
                        }
                    }
                }

                // My Organizations
                let myOrgs = filteredOrganizations.filter { org in
                    org.id != orgManager.currentOrganization?.id
                }

                if !myOrgs.isEmpty {
                    Section("My Organizations") {
                        ForEach(myOrgs) { org in
                            OrganizationCard(organization: org, isCurrent: false) {
                                switchToOrganization(org)
                            }
                        }
                    }
                }

                // Personal Library
                Section("Personal") {
                    Button {
                        switchToPersonalLibrary()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Personal Library")
                                    .font(.headline)

                                Text("Your private songs and books")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if orgManager.currentOrganization == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Organizations")
            .searchable(text: $searchText, prompt: "Search organizations")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateOrganization = true
                    } label: {
                        Label("New Organization", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateOrganization) {
                CreateOrganizationView()
            }
            .sheet(item: $selectedOrganization) { org in
                OrganizationDetailView(organization: org)
            }
        }
    }

    private var filteredOrganizations: [Organization] {
        if searchText.isEmpty {
            return allOrganizations
        } else {
            return allOrganizations.filter { org in
                org.name.localizedCaseInsensitiveContains(searchText) ||
                (org.organizationDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    private func switchToOrganization(_ organization: Organization) {
        orgManager.currentOrganization = organization
        dismiss()
    }

    private func switchToPersonalLibrary() {
        orgManager.currentOrganization = nil
        dismiss()
    }
}

// MARK: - Organization Card

struct OrganizationCard: View {
    let organization: Organization
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: organization.displayIcon)
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                Color(hex: organization.displayColor) ?? .blue
                            )
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(organization.name)
                        .font(.headline)

                    HStack(spacing: 12) {
                        Label("\(organization.memberCount)", systemImage: "person.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("\(organization.libraryCount)", systemImage: "books.vertical")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let subscription = organization.subscriptionTier.rawValue, subscription != "Free" {
                        Text(subscription)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                // Status indicator
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                // View details
            } label: {
                Label("View Details", systemImage: "info.circle")
            }

            Button {
                // View members
            } label: {
                Label("View Members", systemImage: "person.3")
            }

            Divider()

            Button {
                action()
            } label: {
                Label("Switch to Organization", systemImage: "arrow.right.circle")
            }
        }
    }
}

// MARK: - Quick Team Switcher (Compact)

struct QuickTeamSwitcher: View {
    @Query private var organizations: [Organization]
    @StateObject private var orgManager = OrganizationManager.shared

    @State private var showFullDirectory = false

    var body: some View {
        Menu {
            // Current organization
            if let current = orgManager.currentOrganization {
                Label(current.name, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Personal Library", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Divider()

            // Quick switch to other organizations
            ForEach(organizations.filter { $0.id != orgManager.currentOrganization?.id }.prefix(5)) { org in
                Button {
                    orgManager.currentOrganization = org
                } label: {
                    Label(org.name, systemImage: org.displayIcon)
                }
            }

            // Personal library option
            if orgManager.currentOrganization != nil {
                Button {
                    orgManager.currentOrganization = nil
                } label: {
                    Label("Personal Library", systemImage: "person.circle")
                }
            }

            Divider()

            Button {
                showFullDirectory = true
            } label: {
                Label("All Organizations...", systemImage: "building.2")
            }
        } label: {
            HStack(spacing: 8) {
                if let current = orgManager.currentOrganization {
                    Image(systemName: current.displayIcon)
                        .foregroundStyle(Color(hex: current.displayColor) ?? .blue)
                    Text(current.name)
                        .fontWeight(.medium)
                } else {
                    Image(systemName: "person.circle")
                        .foregroundStyle(.blue)
                    Text("Personal")
                        .fontWeight(.medium)
                }

                Image(systemName: "chevron.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
        .sheet(isPresented: $showFullDirectory) {
            TeamDirectoryView()
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Organization.self, configurations: config)

    // Create sample organizations
    let church = Organization(
        name: "First Baptist Church",
        description: "Main worship team",
        organizationType: .church,
        ownerRecordID: "user1",
        ownerDisplayName: "John Doe"
    )
    church.memberCount = 12
    church.libraryCount = 3
    container.mainContext.insert(church)

    let therapy = Organization(
        name: "Harmony Therapy Practice",
        description: "Music therapy sessions",
        organizationType: .therapyPractice,
        ownerRecordID: "user1",
        ownerDisplayName: "Jane Smith"
    )
    therapy.memberCount = 5
    therapy.libraryCount = 1
    container.mainContext.insert(therapy)

    return TeamDirectoryView()
        .modelContainer(container)
}
