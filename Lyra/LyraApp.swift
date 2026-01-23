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

    @State private var syncCoordinator = CloudKitSyncCoordinator.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
            SongVersion.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Attachment.self,
            Annotation.self,
            UserSettings.self,
            Performance.self,
            SetPerformance.self,
            SharedLibrary.self,
            LibraryMember.self,
            UserPresence.self,
            MemberActivity.self,
            Comment.self,
            CommentReaction.self,
            SharedPerformanceSet.self,
            SetMember.self,
            SetComment.self,
            SetMemberRole.self,
            PersonalSetSettings.self,
            SetSongReadiness.self,
            MemberReadiness.self,
            SetRehearsal.self,
            RehearsalAttendance.self,
            RehearsalSongNote.self,
            SetTemplate.self,
            TemplateSection.self,
            PublicSong.self,
            PublicSongRating.self,
            PublicSongFlag.self,
            PublicSongLike.self
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

    init() {
        // Register background tasks
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Set up CloudKit sync coordinator
                    Task {
                        await setupCloudKitSync()
                    }
                }
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
        .backgroundTask(.appRefresh("com.lyra.syncCheck")) {
            await performBackgroundSync()
        }
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

    // MARK: - CloudKit Setup

    @MainActor
    private func setupCloudKitSync() {
        // Initialize CloudKitSyncCoordinator with the model container
        syncCoordinator.setup(with: sharedModelContainer)

        // Check for pending conflicts
        Task {
            await syncCoordinator.performConflictDetection()
        }
    }

    // MARK: - Background Sync

    private func registerBackgroundTasks() {
        // Register background sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lyra.syncCheck",
            using: nil
        ) { task in
            Task {
                await self.handleBackgroundSync(task: task as! BGAppRefreshTask)
            }
        }
    }

    private func performBackgroundSync() async {
        // Perform sync
        await syncCoordinator.performBackgroundSync()

        // Schedule next background refresh
        scheduleBackgroundSync()
    }

    private func handleBackgroundSync(task: BGAppRefreshTask) async {
        // Set up task expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Perform sync
        await performBackgroundSync()

        // Mark task as completed
        task.setTaskCompleted(success: true)
    }

    private func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.lyra.syncCheck")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("❌ Could not schedule background sync: \(error)")
        }
    }
}
