//
//  ConflictBanner.swift
//  Lyra
//
//  Banner to alert users of unresolved sync conflicts
//

import SwiftUI

struct ConflictBanner: View {
    @State private var conflictManager = ConflictResolutionManager.shared
    @State private var showConflictResolution: Bool = false

    var body: some View {
        if conflictManager.hasUnresolvedConflicts {
            Button {
                showConflictResolution = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync Conflicts Detected")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("\(conflictManager.unresolvedCount) conflict\(conflictManager.unresolvedCount == 1 ? "" : "s") need\(conflictManager.unresolvedCount == 1 ? "s" : "") your attention")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Resolve")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .sheet(isPresented: $showConflictResolution) {
                ConflictResolutionView()
            }
        }
    }
}

#Preview {
    VStack {
        ConflictBanner()
            .onAppear {
                // Add sample conflict for preview
                let conflict = SyncConflict(
                    conflictType: .contentModification,
                    entityType: .song,
                    entityID: UUID(),
                    localVersion: ConflictVersion(
                        timestamp: Date(),
                        deviceName: "iPhone",
                        data: ConflictVersion.ConflictData()
                    ),
                    remoteVersion: ConflictVersion(
                        timestamp: Date(),
                        deviceName: "iPad",
                        data: ConflictVersion.ConflictData()
                    ),
                    detectedAt: Date()
                )

                ConflictResolutionManager.shared.addConflict(conflict)
            }

        Spacer()
    }
}
