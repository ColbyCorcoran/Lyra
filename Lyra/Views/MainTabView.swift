//
//  MainTabView.swift
//  Lyra
//
//  Main tab navigation container
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

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

            // Offline status banner
            OfflineStatusBanner()
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewContainer.shared.container)
}
