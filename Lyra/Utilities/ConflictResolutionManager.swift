//
//  ConflictResolutionManager.swift
//  Lyra
//
//  Manages sync conflict detection, resolution, and user interaction
//

import Foundation
import SwiftData
import Combine

enum ConflictError: Error {
    case manualResolutionRequired
    case invalidConflictData
    case syncFailed(String)
}

@Observable
class ConflictResolutionManager {
    static let shared = ConflictResolutionManager()

    // Active conflicts requiring resolution
    var unresolvedConflicts: [SyncConflict] = []

    // Resolved conflict history
    var resolvedConflicts: [SyncConflict] = []

    // Auto-resolution settings
    var autoResolveSimpleConflicts: Bool = true
    var autoResolveStrategy: AutoResolveStrategy = .lastWriteWins

    // Statistics
    var totalConflictsDetected: Int = 0
    var totalAutoResolved: Int = 0
    var totalUserResolved: Int = 0

    enum AutoResolveStrategy: String, CaseIterable, Codable {
        case lastWriteWins = "Last Write Wins"
        case alwaysKeepLocal = "Always Keep Local"
        case alwaysKeepRemote = "Always Keep Remote"
        case neverAutoResolve = "Always Ask"
    }

    private init() {
        loadSettings()
        loadUnresolvedConflicts()
    }

    // MARK: - Conflict Detection

    /// Detects conflicts for a specific entity type
    func detectConflicts(for entityType: SyncConflict.EntityType) async throws -> [SyncConflict] {
        // Delegate to CloudKitSyncCoordinator for actual detection
        await CloudKitSyncCoordinator.shared.performConflictDetection()

        // Return conflicts that match the entity type
        return unresolvedConflicts.filter { $0.entityType == entityType }
    }

    /// Detects conflicts during sync operation
    func detectConflicts(
        localEntity: any PersistentModel,
        remoteEntity: Any,
        entityType: SyncConflict.EntityType
    ) -> SyncConflict? {
        // This is a placeholder - in production, you'd compare actual entity properties
        // and detect if both local and remote versions have been modified since last sync

        // For demonstration, we'll return nil (no conflict)
        // In real implementation, you'd:
        // 1. Compare timestamps of local and remote versions
        // 2. Check if both have been modified since last successful sync
        // 3. Identify which properties differ
        // 4. Create appropriate SyncConflict object

        return nil
    }

    /// Batch conflict detection for multiple entities
    func detectConflicts(
        localEntities: [any PersistentModel],
        remoteEntities: [Any],
        entityType: SyncConflict.EntityType
    ) -> [SyncConflict] {
        let conflicts: [SyncConflict] = []

        // Match local and remote entities by ID and detect conflicts
        // This is a placeholder implementation

        return conflicts
    }

    // MARK: - Conflict Resolution

    /// Resolves a conflict with the given resolution strategy
    func resolveConflict(
        _ conflict: SyncConflict,
        with resolution: SyncConflict.ConflictResolution,
        modelContext: ModelContext
    ) async throws {
        var resolvedConflict = conflict
        resolvedConflict.resolution = resolution
        resolvedConflict.resolvedAt = Date()

        // Apply the resolution
        switch resolution {
        case .keepLocal:
            try await applyLocalVersion(conflict, modelContext: modelContext)
        case .keepRemote:
            try await applyRemoteVersion(conflict, modelContext: modelContext)
        case .keepBoth:
            try await keepBothVersions(conflict, modelContext: modelContext)
        case .merge:
            try await mergeVersions(conflict, modelContext: modelContext)
        case .skipForNow:
            // Don't resolve, just return
            return
        }

        // Move from unresolved to resolved
        if let index = unresolvedConflicts.firstIndex(where: { $0.id == conflict.id }) {
            unresolvedConflicts.remove(at: index)
        }

        resolvedConflicts.append(resolvedConflict)
        totalUserResolved += 1
        saveResolvedConflicts()

        HapticManager.shared.success()
    }

    /// Auto-resolves simple conflicts based on strategy
    func autoResolveConflicts() {
        guard autoResolveSimpleConflicts else { return }

        let simpleConflicts = unresolvedConflicts.filter { $0.canUseLastWriteWins }

        for conflict in simpleConflicts {
            let resolution: SyncConflict.ConflictResolution

            switch autoResolveStrategy {
            case .lastWriteWins:
                resolution = conflict.autoResolve()
            case .alwaysKeepLocal:
                resolution = .keepLocal
            case .alwaysKeepRemote:
                resolution = .keepRemote
            case .neverAutoResolve:
                continue // Skip auto-resolution
            }

            var resolvedConflict = conflict
            resolvedConflict.resolution = resolution
            resolvedConflict.resolvedAt = Date()

            if let index = unresolvedConflicts.firstIndex(where: { $0.id == conflict.id }) {
                unresolvedConflicts.remove(at: index)
            }

            resolvedConflicts.append(resolvedConflict)
            totalAutoResolved += 1
        }

        saveResolvedConflicts()
    }

    /// Resolves all conflicts with a single strategy
    func resolveAllConflicts(
        with resolution: SyncConflict.ConflictResolution,
        modelContext: ModelContext
    ) async throws {
        for conflict in unresolvedConflicts {
            try await resolveConflict(conflict, with: resolution, modelContext: modelContext)
        }
    }

    // MARK: - Resolution Application

    private func applyLocalVersion(_ conflict: SyncConflict, modelContext: ModelContext) async throws {
        // Delegate to CloudKitSyncCoordinator to push local version to CloudKit
        try await CloudKitSyncCoordinator.shared.applyLocalVersion(conflict, modelContext: modelContext)
        print("✅ Applied local version for conflict: \(conflict.id)")
    }

    private func applyRemoteVersion(_ conflict: SyncConflict, modelContext: ModelContext) async throws {
        // Delegate to CloudKitSyncCoordinator to update local with remote version
        try await CloudKitSyncCoordinator.shared.applyRemoteVersion(conflict, modelContext: modelContext)
        print("✅ Applied remote version for conflict: \(conflict.id)")
    }

    private func keepBothVersions(_ conflict: SyncConflict, modelContext: ModelContext) async throws {
        // Delegate to CloudKitSyncCoordinator to create duplicates
        try await CloudKitSyncCoordinator.shared.keepBothVersions(conflict, modelContext: modelContext)
        print("✅ Kept both versions for conflict: \(conflict.id)")
    }

    private func mergeVersions(_ conflict: SyncConflict, modelContext: ModelContext) async throws {
        // Perform intelligent merge using ConflictMergeEngine
        let mergeResult = ConflictMergeEngine.merge(
            local: conflict.localVersion.data,
            remote: conflict.remoteVersion.data,
            base: nil // Base version would come from CloudKit history if available
        )

        // If auto-merge is possible, apply it
        if mergeResult.canAutoResolve {
            try await CloudKitSyncCoordinator.shared.mergeVersions(
                conflict,
                modelContext: modelContext,
                mergedData: mergeResult.mergedData
            )
            print("✅ Auto-merged versions for conflict: \(conflict.id)")
        } else {
            // Manual resolution needed - this shouldn't happen if user already chose merge
            print("⚠️ Merge requires manual resolution for conflict: \(conflict.id)")
            throw ConflictError.manualResolutionRequired
        }
    }

    // MARK: - Conflict Management

    /// Adds a new conflict to the unresolved list
    func addConflict(_ conflict: SyncConflict) {
        guard !unresolvedConflicts.contains(where: { $0.id == conflict.id }) else { return }

        unresolvedConflicts.append(conflict)
        totalConflictsDetected += 1
        saveUnresolvedConflicts()

        // Trigger auto-resolution if enabled
        if autoResolveSimpleConflicts && conflict.canUseLastWriteWins {
            autoResolveConflicts()
        } else {
            // Notify user of new conflict
            HapticManager.shared.warning()
        }
    }

    /// Clears all resolved conflicts from history
    func clearResolvedHistory() {
        resolvedConflicts.removeAll()
        saveResolvedConflicts()
    }

    /// Gets conflicts for a specific entity
    func conflicts(for entityID: UUID) -> [SyncConflict] {
        unresolvedConflicts.filter { $0.entityID == entityID }
    }

    // MARK: - Computed Properties

    var hasUnresolvedConflicts: Bool {
        !unresolvedConflicts.isEmpty
    }

    var unresolvedCount: Int {
        unresolvedConflicts.count
    }

    var highPriorityConflicts: [SyncConflict] {
        unresolvedConflicts.filter { $0.priority == .high }
            .sorted { $0.detectedAt > $1.detectedAt }
    }

    var conflictsByPriority: [SyncConflict] {
        unresolvedConflicts.sorted { $0.priority > $1.priority }
    }

    // MARK: - Persistence

    private func saveSettings() {
        UserDefaults.standard.set(autoResolveSimpleConflicts, forKey: "conflict.autoResolve")
        UserDefaults.standard.set(autoResolveStrategy.rawValue, forKey: "conflict.strategy")
    }

    private func loadSettings() {
        autoResolveSimpleConflicts = UserDefaults.standard.bool(forKey: "conflict.autoResolve")

        if let strategyRaw = UserDefaults.standard.string(forKey: "conflict.strategy"),
           let strategy = AutoResolveStrategy(rawValue: strategyRaw) {
            autoResolveStrategy = strategy
        }
    }

    private func saveUnresolvedConflicts() {
        if let encoded = try? JSONEncoder().encode(unresolvedConflicts) {
            UserDefaults.standard.set(encoded, forKey: "conflict.unresolved")
        }
    }

    private func loadUnresolvedConflicts() {
        if let data = UserDefaults.standard.data(forKey: "conflict.unresolved"),
           let conflicts = try? JSONDecoder().decode([SyncConflict].self, from: data) {
            unresolvedConflicts = conflicts
        }
    }

    private func saveResolvedConflicts() {
        // Only save last 50 resolved conflicts to prevent bloat
        let recentResolved = resolvedConflicts.suffix(50)

        if let encoded = try? JSONEncoder().encode(Array(recentResolved)) {
            UserDefaults.standard.set(encoded, forKey: "conflict.resolved")
        }

        // Save statistics
        UserDefaults.standard.set(totalConflictsDetected, forKey: "conflict.stats.total")
        UserDefaults.standard.set(totalAutoResolved, forKey: "conflict.stats.auto")
        UserDefaults.standard.set(totalUserResolved, forKey: "conflict.stats.user")
    }

    private func loadResolvedConflicts() {
        if let data = UserDefaults.standard.data(forKey: "conflict.resolved"),
           let conflicts = try? JSONDecoder().decode([SyncConflict].self, from: data) {
            resolvedConflicts = conflicts
        }

        // Load statistics
        totalConflictsDetected = UserDefaults.standard.integer(forKey: "conflict.stats.total")
        totalAutoResolved = UserDefaults.standard.integer(forKey: "conflict.stats.auto")
        totalUserResolved = UserDefaults.standard.integer(forKey: "conflict.stats.user")
    }
}
