//
//  SettingsModel.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import Foundation
import SwiftData

@Model
final class SettingsModel: Codable {
    
    var id: UUID = UUID()
    
    // Scan Settings
    var autoSaveScans: Bool = true
    var vibrationFeedback: Bool = true
    var playSoundOnScan: Bool = true
    var saveLocationData: Bool = true
    
    // History Settings
    var historyRetentionDays: Int = 90
    var groupScansByDate: Bool = true
    
    // Store the sort order as a string to avoid the transformable issue
    var defaultSortOrderRaw: String = "date_newest"
    
    var showFavoritesSection: Bool = true
    
    // Appearance
    var useDarkMode: Bool?
    var accentColorHex: String = "#007AFF"
    
    // Export/Import
    var lastExportDate: Date?
    var lastImportDate: Date?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Define the sort order enum outside the class
    enum SortOrder: String, Codable {
        case dateNewest = "date_newest"
        case dateOldest = "date_oldest"
        case scanCount = "scan_count"
        case alphabetical = "alphabetical"
    }
    
    // Computed property to access the sort order as an enum
    var defaultSortOrder: SortOrder {
        get {
            return SortOrder(rawValue: defaultSortOrderRaw) ?? .dateNewest
        }
        set {
            defaultSortOrderRaw = newValue.rawValue
        }
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case autoSaveScans = "auto_save_scans"
        case vibrationFeedback = "vibration_feedback"
        case playSoundOnScan = "play_sound_on_scan"
        case saveLocationData = "save_location_data"
        case historyRetentionDays = "history_retention_days"
        case groupScansByDate = "group_scans_by_date"
        case defaultSortOrder = "default_sort_order"
        case useDarkMode = "use_dark_mode"
        case accentColorHex = "accent_color_hex"
        case showFavoritesSection = "show_favorites_section"
        case lastExportDate = "last_export_date"
        case lastImportDate = "last_import_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(autoSaveScans: Bool = true,
         vibrationFeedback: Bool = true,
         playSoundOnScan: Bool = true,
         saveLocationData: Bool = true,
         historyRetentionDays: Int = 90,
         groupScansByDate: Bool = true,
         defaultSortOrder: SortOrder = .dateNewest,
         useDarkMode: Bool? = nil,
         accentColorHex: String = "#007AFF",
         showFavoritesSection: Bool = true) {
        
        self.id = UUID()
        self.autoSaveScans = autoSaveScans
        self.vibrationFeedback = vibrationFeedback
        self.playSoundOnScan = playSoundOnScan
        self.saveLocationData = saveLocationData
        self.historyRetentionDays = historyRetentionDays
        self.groupScansByDate = groupScansByDate
        self.defaultSortOrder = defaultSortOrder
        self.useDarkMode = useDarkMode
        self.accentColorHex = accentColorHex
        self.showFavoritesSection = showFavoritesSection
        self.lastExportDate = nil
        self.lastImportDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        autoSaveScans = try container.decode(Bool.self, forKey: .autoSaveScans)
        vibrationFeedback = try container.decode(Bool.self, forKey: .vibrationFeedback)
        playSoundOnScan = try container.decode(Bool.self, forKey: .playSoundOnScan)
        saveLocationData = try container.decode(Bool.self, forKey: .saveLocationData)
        historyRetentionDays = try container.decode(Int.self, forKey: .historyRetentionDays)
        groupScansByDate = try container.decode(Bool.self, forKey: .groupScansByDate)
        defaultSortOrder = try container.decode(SortOrder.self, forKey: .defaultSortOrder)
        useDarkMode = try container.decodeIfPresent(Bool.self, forKey: .useDarkMode)
        accentColorHex = try container.decode(String.self, forKey: .accentColorHex)
        showFavoritesSection = try container.decode(Bool.self, forKey: .showFavoritesSection)
        lastExportDate = try container.decodeIfPresent(Date.self, forKey: .lastExportDate)
        lastImportDate = try container.decodeIfPresent(Date.self, forKey: .lastImportDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(autoSaveScans, forKey: .autoSaveScans)
        try container.encode(vibrationFeedback, forKey: .vibrationFeedback)
        try container.encode(playSoundOnScan, forKey: .playSoundOnScan)
        try container.encode(saveLocationData, forKey: .saveLocationData)
        try container.encode(historyRetentionDays, forKey: .historyRetentionDays)
        try container.encode(groupScansByDate, forKey: .groupScansByDate)
        try container.encode(defaultSortOrder, forKey: .defaultSortOrder)
        try container.encodeIfPresent(useDarkMode, forKey: .useDarkMode)
        try container.encode(accentColorHex, forKey: .accentColorHex)
        try container.encode(showFavoritesSection, forKey: .showFavoritesSection)
        try container.encodeIfPresent(lastExportDate, forKey: .lastExportDate)
        try container.encodeIfPresent(lastImportDate, forKey: .lastImportDate)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    
    func updateSettings(autoSaveScans: Bool? = nil,
                        vibrationFeedback: Bool? = nil,
                        playSoundOnScan: Bool? = nil,
                        saveLocationData: Bool? = nil,
                        historyRetentionDays: Int? = nil,
                        groupScansByDate: Bool? = nil,
                        defaultSortOrder: SortOrder? = nil,
                        useDarkMode: Bool? = nil,
                        accentColorHex: String? = nil,
                        showFavoritesSection: Bool? = nil) {
        
        if let autoSaveScans = autoSaveScans {
            self.autoSaveScans = autoSaveScans
        }
        
        if let vibrationFeedback = vibrationFeedback {
            self.vibrationFeedback = vibrationFeedback
        }
        
        if let playSoundOnScan = playSoundOnScan {
            self.playSoundOnScan = playSoundOnScan
        }
        
        if let saveLocationData = saveLocationData {
            self.saveLocationData = saveLocationData
        }
        
        if let historyRetentionDays = historyRetentionDays {
            self.historyRetentionDays = historyRetentionDays
        }
        
        if let groupScansByDate = groupScansByDate {
            self.groupScansByDate = groupScansByDate
        }
        
        if let defaultSortOrder = defaultSortOrder {
            self.defaultSortOrderRaw = defaultSortOrder.rawValue
        }
        
        if let useDarkMode = useDarkMode {
            self.useDarkMode = useDarkMode
        }
        
        if let accentColorHex = accentColorHex {
            self.accentColorHex = accentColorHex
        }
        
        if let showFavoritesSection = showFavoritesSection {
            self.showFavoritesSection = showFavoritesSection
        }
        
        self.updatedAt = Date()
    }
    
    func recordExport() {
        self.lastExportDate = Date()
        self.updatedAt = Date()
    }
    
    func recordImport() {
        self.lastImportDate = Date()
        self.updatedAt = Date()
    }
    
    func resetToDefaults() {
        self.autoSaveScans = true
        self.vibrationFeedback = true
        self.playSoundOnScan = true
        self.saveLocationData = true
        self.historyRetentionDays = 90
        self.groupScansByDate = true
        self.defaultSortOrder = .dateNewest
        self.useDarkMode = nil
        self.accentColorHex = "#007AFF"
        self.showFavoritesSection = true
        self.updatedAt = Date()
    }
    
    // MARK: - Static Methods
    
    /// Creates default settings
    static func createDefaultSettings() -> SettingsModel {
        return SettingsModel()
    }
}
