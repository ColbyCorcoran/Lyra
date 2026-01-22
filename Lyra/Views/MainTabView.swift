//
//  MainTabView.swift
//  Lyra
//
//  Main tab navigation container
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding: Bool = false

    @State private var showOnboarding: Bool = false
    @State private var showMigrationStatus: Bool = false
    @State private var migrationManager = DataMigrationManager.shared
    @State private var offlineManager = OfflineManager.shared

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "book.fill")
                    }

                AnalyticsDashboardView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }

            // Status banners
            VStack(spacing: 0) {
                OfflineStatusBanner()
                ConflictBanner()
                MigrationBanner(showMigrationStatus: $showMigrationStatus)
            }
        }
        .onAppear {
            // Initialize offline monitoring
            offlineManager.startMonitoring()

            // Check onboarding
            if !hasCompletedOnboarding {
                showOnboarding = true
            }

            // Check for migrations
            if migrationManager.needsMigration() {
                // Show migration banner automatically
                print("⚠️  Migration needed: \(migrationManager.installedSchemaVersion) → \(DataMigrationManager.currentSchemaVersion)")
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showMigrationStatus) {
            MigrationStatusView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewContainer.shared.container)
}
