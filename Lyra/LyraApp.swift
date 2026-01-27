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
            Attachment.self,
            Annotation.self,
            UserSettings.self,
            Performance.self,
            SetPerformance.self,
            // Phase 7.5: Recommendation Intelligence
            SongRecommendation.self,
            UserTasteProfile.self,
            RecommendationFeedback.self,
            SmartPlaylist.self,
            PlayHistoryEntry.self,
            // Phase 7.8: Performance Insights
            PerformanceSession.self
        ])

        // Check if iCloud sync is enabled
        let iCloudEnabled = CloudSyncManager.shared.isSyncEnabled

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: iCloudEnabled ? .automatic : .none
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
