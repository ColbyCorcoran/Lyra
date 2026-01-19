//
//  PreferenceKeys.swift
//  Lyra
//
//  UserDefaults extensions for app preferences
//

import Foundation
import SwiftUI

extension UserDefaults {

    // MARK: - Book Preferences

    private static let bookSortOptionKey = "bookSortOption"
    private static let bookFilterOptionKey = "bookFilterOption"
    private static let bookColorFilterKey = "bookColorFilter"

    var bookSortOption: String {
        get { string(forKey: Self.bookSortOptionKey) ?? "alphabetical" }
        set { set(newValue, forKey: Self.bookSortOptionKey) }
    }

    var bookFilterOption: String {
        get { string(forKey: Self.bookFilterOptionKey) ?? "all" }
        set { set(newValue, forKey: Self.bookFilterOptionKey) }
    }

    var bookColorFilter: String? {
        get { string(forKey: Self.bookColorFilterKey) }
        set { set(newValue, forKey: Self.bookColorFilterKey) }
    }

    // MARK: - Set Preferences

    private static let setSortOptionKey = "setSortOption"
    private static let setGroupByFolderKey = "setGroupByFolder"
    private static let showArchivedSetsKey = "showArchivedSets"
    private static let showUpcomingOnlyKey = "showUpcomingOnly"
    private static let showPastOnlyKey = "showPastOnly"

    var setSortOption: String {
        get { string(forKey: Self.setSortOptionKey) ?? "date" }
        set { set(newValue, forKey: Self.setSortOptionKey) }
    }

    var setGroupByFolder: Bool {
        get { bool(forKey: Self.setGroupByFolderKey) }
        set { set(newValue, forKey: Self.setGroupByFolderKey) }
    }

    var showArchivedSets: Bool {
        get { bool(forKey: Self.showArchivedSetsKey) }
        set { set(newValue, forKey: Self.showArchivedSetsKey) }
    }

    var showUpcomingOnly: Bool {
        get { bool(forKey: Self.showUpcomingOnlyKey) }
        set { set(newValue, forKey: Self.showUpcomingOnlyKey) }
    }

    var showPastOnly: Bool {
        get { bool(forKey: Self.showPastOnlyKey) }
        set { set(newValue, forKey: Self.showPastOnlyKey) }
    }

    // MARK: - Folder Collapse State

    private static func folderCollapseKey(_ folderName: String) -> String {
        return "folderCollapsed_\(folderName)"
    }

    func folderCollapsed(_ folderName: String) -> Bool {
        return bool(forKey: Self.folderCollapseKey(folderName))
    }

    func setFolderCollapsed(_ folderName: String, _ collapsed: Bool) {
        set(collapsed, forKey: Self.folderCollapseKey(folderName))
    }

    // MARK: - Selected Folders Filter (for Sets)

    private static let selectedFoldersFilterKey = "selectedFoldersFilter"

    var selectedFoldersFilter: Set<String> {
        get {
            if let array = array(forKey: Self.selectedFoldersFilterKey) as? [String] {
                return Set(array)
            }
            return []
        }
        set {
            set(Array(newValue), forKey: Self.selectedFoldersFilterKey)
        }
    }

    // MARK: - Helper Methods

    /// Reset all book preferences to defaults
    func resetBookPreferences() {
        removeObject(forKey: Self.bookSortOptionKey)
        removeObject(forKey: Self.bookFilterOptionKey)
        removeObject(forKey: Self.bookColorFilterKey)
    }

    /// Reset all set preferences to defaults
    func resetSetPreferences() {
        removeObject(forKey: Self.setSortOptionKey)
        removeObject(forKey: Self.setGroupByFolderKey)
        removeObject(forKey: Self.showArchivedSetsKey)
        removeObject(forKey: Self.showUpcomingOnlyKey)
        removeObject(forKey: Self.showPastOnlyKey)
        removeObject(forKey: Self.selectedFoldersFilterKey)
    }

    /// Reset all folder collapse states
    func resetFolderCollapseStates() {
        let allKeys = dictionaryRepresentation().keys
        let folderKeys = allKeys.filter { $0.hasPrefix("folderCollapsed_") }
        for key in folderKeys {
            removeObject(forKey: key)
        }
    }
}

// MARK: - AppStorage Property Wrappers

/// Convenience property wrapper for book sort option
@propertyWrapper
struct BookSortPreference: DynamicProperty {
    @AppStorage("bookSortOption") private var value: String = "alphabetical"

    var wrappedValue: String {
        get { value }
        nonmutating set { value = newValue }
    }

    var projectedValue: Binding<String> {
        Binding(
            get: { value },
            set: { value = $0 }
        )
    }
}

/// Convenience property wrapper for set sort option
@propertyWrapper
struct SetSortPreference: DynamicProperty {
    @AppStorage("setSortOption") private var value: String = "date"

    var wrappedValue: String {
        get { value }
        nonmutating set { value = newValue }
    }

    var projectedValue: Binding<String> {
        Binding(
            get: { value },
            set: { value = $0 }
        )
    }
}
