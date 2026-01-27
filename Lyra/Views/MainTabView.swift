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

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "book.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }

            // Status banners
            VStack(spacing: 0) {
                OfflineStatusBanner()
            }
        }
        .onAppear {
            // Check onboarding
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
