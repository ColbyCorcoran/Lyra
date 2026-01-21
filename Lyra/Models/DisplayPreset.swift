//
//  DisplayPreset.swift
//  Lyra
//
//  Model for saving and managing display setting presets
//

import SwiftData
import Foundation

@Model
final class DisplayPreset {
    var id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var isBuiltIn: Bool
    var settingsData: Data

    // Computed property for settings
    var settings: DisplaySettings {
        get {
            if let decoded = try? JSONDecoder().decode(DisplaySettings.self, from: settingsData) {
                return decoded
            }
            return .default
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                settingsData = encoded
                modifiedAt = Date()
            }
        }
    }

    init(name: String, settings: DisplaySettings, isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isBuiltIn = isBuiltIn
        self.settingsData = (try? JSONEncoder().encode(settings)) ?? Data()
    }

    // MARK: - Built-in Presets

    static func createBuiltInPresets(context: ModelContext) {
        let builtInNames = ["Default", "Stage Performance", "Practice", "Large Print"]

        // Check if built-in presets already exist
        let descriptor = FetchDescriptor<DisplayPreset>(
            predicate: #Predicate { $0.isBuiltIn }
        )

        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return // Already created
        }

        // Create built-in presets
        let defaultPreset = DisplayPreset(name: "Default", settings: .default, isBuiltIn: true)
        let stagePreset = DisplayPreset(name: "Stage Performance", settings: .stagePerformance, isBuiltIn: true)
        let practicePreset = DisplayPreset(name: "Practice", settings: .practice, isBuiltIn: true)
        let largePrintPreset = DisplayPreset(name: "Large Print", settings: .largePrint, isBuiltIn: true)

        context.insert(defaultPreset)
        context.insert(stagePreset)
        context.insert(practicePreset)
        context.insert(largePrintPreset)

        try? context.save()
    }
}

// MARK: - UserDefaults Extension for Active Preset

extension UserDefaults {
    private enum PresetKeys {
        static let activePresetID = "activeDisplayPresetID"
    }

    var activeDisplayPresetID: UUID? {
        get {
            if let uuidString = string(forKey: PresetKeys.activePresetID) {
                return UUID(uuidString: uuidString)
            }
            return nil
        }
        set {
            set(newValue?.uuidString, forKey: PresetKeys.activePresetID)
        }
    }
}
