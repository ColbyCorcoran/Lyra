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
            UserSettings.self,
            RecurrenceRule.self
        ])

        // Disable CloudKit integration - we're using local-only storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // Disable CloudKit to avoid unique constraint issues
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
                .task {
                    await generateRecurringInstances()
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

    // MARK: - Recurring Set Instance Generation

    @MainActor
    private func generateRecurringInstances() async {
        let context = sharedModelContainer.mainContext
        let monthsAhead = UserDefaults.standard.integer(forKey: "recurringInstanceGenerationMonths")
        let months = monthsAhead > 0 ? monthsAhead : 3

        let descriptor = FetchDescriptor<PerformanceSet>(
            predicate: #Predicate { set in
                set.recurrenceRule != nil && set.recurrenceStopped == false
            }
        )

        guard let templates = try? context.fetch(descriptor) else { return }

        for template in templates {
            try? RecurrenceManager.generateInstancesIfNeeded(
                for: template,
                context: context,
                monthsAhead: months
            )
        }
    }
}
