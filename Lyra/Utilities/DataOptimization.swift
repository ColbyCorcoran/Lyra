//
//  DataOptimization.swift
//  Lyra
//
//  SwiftData query optimization and lazy loading
//  Target: Efficient queries for 1000+ song libraries
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Optimized Fetch Descriptors

extension FetchDescriptor {
    /// Create optimized descriptor for large libraries
    static func optimized<T: PersistentModel>(
        for type: T.Type,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        limit: Int? = nil
    ) -> FetchDescriptor<T> {
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)

        // Set fetch limit for pagination
        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        // Optimize for performance
        descriptor.includePendingChanges = false

        return descriptor
    }

    /// Create paginated fetch descriptor
    static func paginated<T: PersistentModel>(
        for type: T.Type,
        page: Int,
        pageSize: Int = 50,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) -> FetchDescriptor<T> {
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)

        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = page * pageSize
        descriptor.includePendingChanges = false

        return descriptor
    }
}

// MARK: - Pagination Manager

@Observable
class PaginationManager<T: PersistentModel> {
    var currentPage: Int = 0
    var pageSize: Int = 50
    var hasMorePages: Bool = true
    var isLoading: Bool = false

    private var loadedItems: [T] = []
    private let modelContext: ModelContext
    private let basePredicate: Predicate<T>?
    private let sortDescriptors: [SortDescriptor<T>]

    init(
        modelContext: ModelContext,
        pageSize: Int = 50,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) {
        self.modelContext = modelContext
        self.pageSize = pageSize
        self.basePredicate = predicate
        self.sortDescriptors = sortBy
    }

    func loadNextPage() async throws {
        guard !isLoading && hasMorePages else { return }

        isLoading = true
        defer { isLoading = false }

        let descriptor = FetchDescriptor<T>.paginated(
            for: T.self,
            page: currentPage,
            pageSize: pageSize,
            predicate: basePredicate,
            sortBy: sortDescriptors
        )

        let items = try modelContext.fetch(descriptor)

        if items.count < pageSize {
            hasMorePages = false
        }

        loadedItems.append(contentsOf: items)
        currentPage += 1
    }

    func reset() {
        currentPage = 0
        hasMorePages = true
        loadedItems.removeAll()
    }

    var items: [T] {
        loadedItems
    }
}

// MARK: - Lazy List View

struct LazyDataList<T: PersistentModel, Content: View>: View {
    @Environment(\.modelContext) private var modelContext

    let pageSize: Int
    let predicate: Predicate<T>?
    let sortDescriptors: [SortDescriptor<T>]
    let content: (T) -> Content

    @State private var paginationManager: PaginationManager<T>?
    @State private var items: [T] = []

    init(
        pageSize: Int = 50,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.pageSize = pageSize
        self.predicate = predicate
        self.sortDescriptors = sortBy
        self.content = content
    }

    var body: some View {
        List {
            ForEach(items, id: \.persistentModelID) { item in
                content(item)
                    .onAppear {
                        // Preload next page when near end
                        if shouldLoadMore(item: item) {
                            Task {
                                try? await paginationManager?.loadNextPage()
                                updateItems()
                            }
                        }
                    }
            }

            if paginationManager?.isLoading == true {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .task {
            if paginationManager == nil {
                paginationManager = PaginationManager(
                    modelContext: modelContext,
                    pageSize: pageSize,
                    predicate: predicate,
                    sortBy: sortDescriptors
                )

                try? await paginationManager?.loadNextPage()
                updateItems()
            }
        }
    }

    private func shouldLoadMore(item: T) -> Bool {
        guard let manager = paginationManager else { return false }

        let threshold = pageSize / 2
        guard let index = items.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) else {
            return false
        }

        return index >= items.count - threshold && manager.hasMorePages && !manager.isLoading
    }

    private func updateItems() {
        items = paginationManager?.items ?? []
    }
}

// MARK: - Query Performance Helpers

extension ModelContext {
    /// Fetch count efficiently without loading objects
    func fetchCount<T: PersistentModel>(
        for type: T.Type,
        predicate: Predicate<T>? = nil
    ) throws -> Int {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.includePendingChanges = false

        return try fetchCount(descriptor)
    }

    /// Batch fetch with automatic pagination
    func batchFetch<T: PersistentModel>(
        for type: T.Type,
        batchSize: Int = 100,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        process: (T) throws -> Void
    ) throws {
        var offset = 0
        var hasMore = true

        while hasMore {
            var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            descriptor.includePendingChanges = false

            let batch = try fetch(descriptor)

            if batch.isEmpty {
                hasMore = false
            } else {
                for item in batch {
                    try process(item)
                }
                offset += batch.count
                hasMore = batch.count == batchSize
            }
        }
    }
}

// MARK: - Efficient Song Queries

extension Song {
    /// Fetch songs with minimal data for lists
    static func fetchMinimalDescriptor(
        predicate: Predicate<Song>? = nil,
        sortBy: [SortDescriptor<Song>] = [SortDescriptor(\.title)]
    ) -> FetchDescriptor<Song> {
        var descriptor = FetchDescriptor<Song>(predicate: predicate, sortBy: sortBy)

        // Only fetch necessary properties
        descriptor.propertiesToFetch = [\.title, \.artist, \.currentKey]
        descriptor.includePendingChanges = false

        return descriptor
    }

    /// Efficient search query
    static func searchDescriptor(
        query: String,
        limit: Int = 50
    ) -> FetchDescriptor<Song> {
        let predicate = #Predicate<Song> { song in
            song.title.localizedStandardContains(query) ||
            (song.artist?.localizedStandardContains(query) ?? false)
        }

        var descriptor = FetchDescriptor<Song>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.title)]
        )

        descriptor.fetchLimit = limit
        descriptor.includePendingChanges = false

        return descriptor
    }
}

// MARK: - Batch Operations

class BatchOperationManager {
    static let shared = BatchOperationManager()

    /// Execute batch operation with progress tracking
    func executeBatch<T>(
        items: [T],
        batchSize: Int = 50,
        operation: @escaping (T) async throws -> Void,
        progress: @escaping (Double) -> Void
    ) async throws {
        let totalBatches = (items.count + batchSize - 1) / batchSize

        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, items.count)
            let batch = Array(items[startIndex..<endIndex])

            try await withThrowingTaskGroup(of: Void.self) { group in
                for item in batch {
                    group.addTask {
                        try await operation(item)
                    }
                }

                try await group.waitForAll()
            }

            let progressValue = Double(batchIndex + 1) / Double(totalBatches)
            await MainActor.run {
                progress(progressValue)
            }
        }
    }
}

// MARK: - Smart Preloading

@Observable
class PreloadManager {
    static let shared = PreloadManager()

    private var preloadedSongs: [UUID: ParsedSong] = [:]
    private let maxPreloaded = 5

    func preload(_ songs: [Song]) {
        let signpostID = OSSignpostID(log: PerformanceManager.shared.signpostLog)
        PerformanceManager.shared.beginSignpost("Preload Songs", id: signpostID)

        Task {
            for song in songs.prefix(maxPreloaded) {
                if preloadedSongs[song.id] == nil {
                    let parser = ChordProParser()
                    if let parsed = try? parser.parse(song.content) {
                        await MainActor.run {
                            preloadedSongs[song.id] = parsed
                        }
                    }
                }
            }

            PerformanceManager.shared.endSignpost("Preload Songs", id: signpostID)
        }
    }

    func get(_ songID: UUID) -> ParsedSong? {
        preloadedSongs[songID]
    }

    func clear() {
        preloadedSongs.removeAll()
    }

    func clearExcept(_ songIDs: Set<UUID>) {
        preloadedSongs = preloadedSongs.filter { songIDs.contains($0.key) }
    }
}

// MARK: - Data Prefetching Strategy

struct DataPrefetchStrategy {
    /// Prefetch distance (number of items ahead)
    static let prefetchDistance = 10

    /// Minimum scroll velocity to trigger prefetch
    static let minScrollVelocity: CGFloat = 100

    /// Prefetch songs in set list
    static func prefetchSetSongs(_ set: PerformanceSet, currentIndex: Int) {
        guard let entries = set.sortedSongEntries else { return }

        let startIndex = max(0, currentIndex - 1)
        let endIndex = min(entries.count, currentIndex + prefetchDistance)

        let songsToPreload = entries[startIndex..<endIndex].compactMap { $0.song }
        PreloadManager.shared.preload(songsToPreload)
    }

    /// Prefetch nearby items in list
    static func prefetchNearbyItems<T>(_ items: [T], currentIndex: Int) -> [T] {
        let startIndex = max(0, currentIndex - 2)
        let endIndex = min(items.count, currentIndex + prefetchDistance)

        return Array(items[startIndex..<endIndex])
    }
}
