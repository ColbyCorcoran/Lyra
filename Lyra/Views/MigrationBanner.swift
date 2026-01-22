//
//  MigrationBanner.swift
//  Lyra
//
//  Banner to alert users when data migration is available
//

import SwiftUI

struct MigrationBanner: View {
    @State private var migrationManager = DataMigrationManager.shared
    @Binding var showMigrationStatus: Bool

    var body: some View {
        if migrationManager.needsMigration() && !migrationManager.isMigrating {
            Button {
                showMigrationStatus = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.blue)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Update Available")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("Schema update to version \(DataMigrationManager.currentSchemaVersion.description)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Update")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        } else if migrationManager.isMigrating {
            // Show migration in progress banner
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Migrating Data...")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("\(Int(migrationManager.migrationProgress * 100))% complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

#Preview("Migration Needed") {
    MigrationBanner(showMigrationStatus: .constant(false))
        .onAppear {
            // Simulate older version for preview
            DataMigrationManager.shared.setSchemaVersion(SchemaVersion(major: 0, minor: 9, patch: 0))
        }
}

#Preview("Migration In Progress") {
    MigrationBanner(showMigrationStatus: .constant(false))
        .onAppear {
            let manager = DataMigrationManager.shared
            manager.isMigrating = true
            manager.migrationProgress = 0.65
        }
}
