//
//  LyraApp.swift
//  Lyra
//
//  Created by Colby Corcoran on 1/16/26.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct LyraApp: App {
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding: Bool = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Initialize DataManager with the container's main context
            DataManager.shared.initialize(with: container.mainContext)

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        handleUniversalLink(url: url)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Deep Linking

    private func handleDeepLink(url: URL) {
        Task { @MainActor in
            DeepLinkHandler.shared.handle(url: url)
        }
    }

    private func handleUniversalLink(url: URL) {
        Task { @MainActor in
            DeepLinkHandler.shared.handleUniversalLink(url: url)
        }
    }
}
