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
                SongsTabView()
                    .tabItem {
                        Label("Songs", systemImage: "music.note")
                    }

                BooksTabView()
                    .tabItem {
                        Label("Books", systemImage: "book.fill")
                    }

                SetsTabView()
                    .tabItem {
                        Label("Sets", systemImage: "list.bullet.rectangle")
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
