//
//  DisplayPreset.swift
//  Lyra
//
//  Model for saving and managing display setting presets
//

import Foundation

// @Model removed - converted to struct (not persisted with SwiftData)
struct DisplayPreset: Codable, Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var isBuiltIn: Bool
    var settings: DisplaySettings

    init(name: String, settings: DisplaySettings, isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isBuiltIn = isBuiltIn
        self.settings = settings
    }

    // MARK: - Built-in Presets

    static let builtInPresets: [DisplayPreset] = [
        DisplayPreset(name: "Default", settings: .default, isBuiltIn: true),
        DisplayPreset(name: "Stage Performance", settings: .stagePerformance, isBuiltIn: true),
        DisplayPreset(name: "Practice", settings: .practice, isBuiltIn: true),
        DisplayPreset(name: "Large Print", settings: .largePrint, isBuiltIn: true)
    ]
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
