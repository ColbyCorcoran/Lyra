//
//  OrganizationMembersView.swift
//  Lyra
//
//  View for managing organization members, roles, and permissions
//

import SwiftUI
import SwiftData

struct OrganizationMembersView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let organization: Organization

    @StateObject private var orgManager = OrganizationManager.shared

    @State private var searchText = ""
    @State private var selectedRole: OrganizationRole? = nil
    @State private var showInviteMember = false
    @State private var showMemberDetail: OrganizationMember?
    @State private var showError = false
    @State private var errorMessage = ""

    // Mock current user
    private let currentUserRecordID = "user_current"

    var body: some View {
        NavigationStack {
            List {
                // Owner Section
                Section("Owner") {
                    OwnerRow(organization: organization)
                }

                // Members Section
                let members = filteredMembers

                if !members.isEmpty {
                    Section("Members (\(members.count))") {
                        ForEach(members) { member in
                            MemberRow(
                                member: member,
                                currentUserRole: currentUserRole
                            ) {
                                showMemberDetail = member
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if canManageMember(member) {
                                    Button(role: .destructive) {
                                        removeMember(member)
                                    } label: {
                                        Label("Remove", systemImage: "person.badge.minus")
                                    }

                                    if member.isSuspended {
                                        Button {
                                            unsuspendMember(member)
                                        } label: {
                                            Label("Unsuspend", systemImage: "checkmark.circle")
                                        }
                                        .tint(.green)
                                    } else {
                                        Button {
                                            suspendMember(member)
                                        } label: {
                                            Label("Suspend", systemImage: "hand.raised")
                                        }
                                        .tint(.orange)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Members Yet",
                        systemImage: "person.3",
                        description: Text("Invite team members to get started")
                    )
                }

                // Statistics
                Section("Statistics") {
                    HStack {
                        Label("Total Members", systemImage: "person.2")
                        Spacer()
                        Text("\(organization.memberCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Admins", systemImage: "star")
                        Spacer()
                        Text("\(organization.adminCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Available Seats", systemImage: "chair")
                        Spacer()
                        Text("\(organization.availableSeats)")
                            .foregroundStyle(organization.availableSeats > 0 ? .green : .red)
                    }
                }
            }
            .navigationTitle("Members")
            .searchable(text: $searchText, prompt: "Search members")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showInviteMember = true
                        } label: {
                            Label("Invite Member", systemImage: "person.badge.plus")
                        }
                        .disabled(!canAddMembers)

                        Menu {
                            Button("All Roles") {
                                selectedRole = nil
                            }
                            ForEach(OrganizationRole.allCases, id: \.self) { role in
                                Button(role.rawValue) {
                                    selectedRole = role
                                }
                            }
                        } label: {
                            Label("Filter by Role", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showInviteMember) {
                InviteMemberView(organization: organization)
            }
            .sheet(item: $showMemberDetail) { member in
                MemberDetailView(member: member, organization: organization)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var filteredMembers: [OrganizationMember] {
        var members = organization.members ?? []

        // Filter by search
        if !searchText.isEmpty {
            members = members.filter { member in
                member.displayNameOrEmail.localizedCaseInsensitiveContains(searchText) ||
                (member.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by role
        if let role = selectedRole {
            members = members.filter { $0.role == role }
        }

        return members.sorted { $0.joinedAt > $1.joinedAt }
    }

    private var currentUserRole: OrganizationRole? {
        organization.currentUserRole(userRecordID: currentUserRecordID)
    }

    private var canAddMembers: Bool {
        guard let role = currentUserRole else { return false }
        return role.canManageMembers && organization.canAddMoreMembers
    }

    private func canManageMember(_ member: OrganizationMember) -> Bool {
        guard let role = currentUserRole else { return false }
        return role.canManageMembers && member.userRecordID != organization.ownerRecordID
    }

    private func removeMember(_ member: OrganizationMember) {
        Task {
            do {
                try await orgManager.removeMember(
                    member,
                    from: organization,
                    removedBy: currentUserRecordID,
                    modelContext: modelContext
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func suspendMember(_ member: OrganizationMember) {
        Task {
            do {
                try await orgManager.suspendMember(
                    member,
                    reason: "Suspended by admin",
                    suspendedBy: currentUserRecordID,
                    in: organization,
                    modelContext: modelContext
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func unsuspendMember(_ member: OrganizationMember) {
        Task {
            do {
                try await orgManager.unsuspendMember(
                    member,
                    unsuspendedBy: currentUserRecordID,
                    in: organization,
                    modelContext: modelContext
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Owner Row

struct OwnerRow: View {
    let organization: Organization

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.white)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(organization.ownerDisplayName ?? "Owner")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Owner")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Role badge
            Text("Owner")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Member Row

struct MemberRow: View {
    let member: OrganizationMember
    let currentUserRole: OrganizationRole?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(roleGradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(member.initials)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.displayNameOrEmail)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        Text(member.role.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if member.isSuspended {
                            Text("• Suspended")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else if member.invitationStatus != .accepted {
                            Text("• Pending")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer()

                // Status indicator
                if member.isSuspended {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.red)
                } else if member.invitationStatus != .accepted {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var roleGradient: LinearGradient {
        let colors: [Color]
        switch member.role {
        case .owner:
            colors = [.yellow, .orange]
        case .admin:
            colors = [.purple, .pink]
        case .editor:
            colors = [.blue, .cyan]
        case .member:
            colors = [.gray, .secondary.opacity(0.8)]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Member Detail View

struct MemberDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let member: OrganizationMember
    let organization: Organization

    @StateObject private var orgManager = OrganizationManager.shared

    @State private var selectedRole: OrganizationRole
    @State private var showRolePicker = false
    @State private var showRemoveConfirmation = false
    @State private var showSuspendDialog = false
    @State private var suspensionReason = ""

    // Mock current user
    private let currentUserRecordID = "user_current"

    init(member: OrganizationMember, organization: Organization) {
        self.member = member
        self.organization = organization
        _selectedRole = State(initialValue: member.role)
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    VStack(spacing: 16) {
                        // Avatar
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Text(member.initials)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }

                        Text(member.displayNameOrEmail)
                            .font(.title3)
                            .fontWeight(.semibold)

                        if let email = member.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Status badge
                        Text(member.statusText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)

                // Role Section
                Section("Role & Permissions") {
                    HStack {
                        Label("Role", systemImage: member.role.icon)
                        Spacer()
                        Text(member.role.rawValue)
                            .foregroundStyle(.secondary)
                    }

                    if canChangeRole {
                        Button {
                            showRolePicker = true
                        } label: {
                            Label("Change Role", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                }

                // Activity Section
                Section("Activity") {
                    if let lastLogin = member.lastLoginAt {
                        HStack {
                            Label("Last Login", systemImage: "clock")
                            Spacer()
                            Text(lastLogin, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Label("Total Edits", systemImage: "pencil")
                        Spacer()
                        Text("\(member.totalEdits)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Songs Added", systemImage: "music.note")
                        Spacer()
                        Text("\(member.totalSongsAdded)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Joined", systemImage: "calendar")
                        Spacer()
                        Text(member.joinedAt, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }

                // Actions Section
                if canManageMember {
                    Section {
                        if member.isSuspended {
                            Button {
                                unsuspendMember()
                            } label: {
                                Label("Unsuspend Member", systemImage: "checkmark.circle")
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Button {
                                showSuspendDialog = true
                            } label: {
                                Label("Suspend Member", systemImage: "hand.raised")
                                    .foregroundStyle(.orange)
                            }
                        }

                        Button(role: .destructive) {
                            showRemoveConfirmation = true
                        } label: {
                            Label("Remove from Organization", systemImage: "person.badge.minus")
                        }
                    }
                }
            }
            .navigationTitle("Member Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Change Role", isPresented: $showRolePicker) {
                ForEach(OrganizationRole.allCases.filter { $0 != .owner }, id: \.self) { role in
                    Button(role.rawValue) {
                        changeRole(to: role)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Suspend Member", isPresented: $showSuspendDialog) {
                TextField("Reason", text: $suspensionReason)
                Button("Cancel", role: .cancel) {}
                Button("Suspend", role: .destructive) {
                    suspendMember()
                }
            } message: {
                Text("Provide a reason for suspending this member")
            }
            .alert("Remove Member", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    removeMember()
                }
            } message: {
                Text("Are you sure you want to remove \(member.displayNameOrEmail) from this organization?")
            }
        }
    }

    private var statusColor: Color {
        if member.isSuspended {
            return .red
        } else if !member.isActive {
            return .gray
        } else if member.invitationStatus != .accepted {
            return .orange
        } else {
            return .green
        }
    }

    private var canChangeRole: Bool {
        guard let role = organization.currentUserRole(userRecordID: currentUserRecordID) else {
            return false
        }
        return role.canChangeRoles && member.userRecordID != organization.ownerRecordID
    }

    private var canManageMember: Bool {
        guard let role = organization.currentUserRole(userRecordID: currentUserRecordID) else {
            return false
        }
        return role.canManageMembers && member.userRecordID != organization.ownerRecordID
    }

    private func changeRole(to newRole: OrganizationRole) {
        Task {
            try? await orgManager.updateMemberRole(
                member,
                to: newRole,
                in: organization,
                changedBy: currentUserRecordID,
                modelContext: modelContext
            )
            dismiss()
        }
    }

    private func suspendMember() {
        Task {
            try? await orgManager.suspendMember(
                member,
                reason: suspensionReason.isEmpty ? "Suspended by admin" : suspensionReason,
                suspendedBy: currentUserRecordID,
                in: organization,
                modelContext: modelContext
            )
            dismiss()
        }
    }

    private func unsuspendMember() {
        Task {
            try? await orgManager.unsuspendMember(
                member,
                unsuspendedBy: currentUserRecordID,
                in: organization,
                modelContext: modelContext
            )
            dismiss()
        }
    }

    private func removeMember() {
        Task {
            try? await orgManager.removeMember(
                member,
                from: organization,
                removedBy: currentUserRecordID,
                modelContext: modelContext
            )
            dismiss()
        }
    }
}

// MARK: - Invite Member View

struct InviteMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let organization: Organization

    @StateObject private var orgManager = OrganizationManager.shared

    @State private var email = ""
    @State private var displayName = ""
    @State private var selectedRole: OrganizationRole = .member
    @State private var isInviting = false

    // Mock current user
    private let currentUserRecordID = "user_current"

    var body: some View {
        NavigationStack {
            Form {
                Section("Member Information") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Display Name (Optional)", text: $displayName)
                        .textContentType(.name)
                }

                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(availableRoles, id: \.self) { role in
                            Label(role.rawValue, systemImage: role.icon)
                                .tag(role)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(selectedRole.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("An invitation will be sent to \(email)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        inviteMember()
                    }
                    .disabled(!isFormValid || isInviting)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@")
    }

    private var availableRoles: [OrganizationRole] {
        OrganizationRole.allCases.filter { $0 != .owner }
    }

    private func inviteMember() {
        isInviting = true

        Task {
            do {
                let _ = try await orgManager.addMember(
                    to: organization,
                    userRecordID: "user_\(UUID().uuidString)", // Generate temp ID
                    displayName: displayName.isEmpty ? nil : displayName,
                    email: email,
                    role: selectedRole,
                    invitedBy: currentUserRecordID,
                    modelContext: modelContext
                )

                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error inviting member: \(error)")
            }

            isInviting = false
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Organization.self, OrganizationMember.self, configurations: config)

    let org = Organization(
        name: "Test Church",
        organizationType: .church,
        ownerRecordID: "owner123",
        ownerDisplayName: "John Doe"
    )
    container.mainContext.insert(org)

    return OrganizationMembersView(organization: org)
        .modelContainer(container)
}
