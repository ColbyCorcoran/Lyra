//
//  LyraApp.swift
//  Lyra
//
//  Created by Colby Corcoran on 1/16/26.
//

import SwiftUI
import SwiftData

@main
struct LyraApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Attachment.self,
            Annotation.self,
            UserSettings.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Can be changed to .automatic for iCloud sync
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
        }
        .modelContainer(sharedModelContainer)
    }
}
