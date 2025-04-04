//
//  QRDataManager.swift
//  QR Unveil
//
//  Created on 4/3/25.
//

import Foundation
import SwiftData
import SwiftUI
import CoreLocation

@Observable
class QRDataManager {
    private let modelContext: ModelContext
    
    // Shared instance for app-wide access
    private static var _shared: QRDataManager?
    
    static var shared: QRDataManager {
        guard let shared = _shared else {
            fatalError("QRDataManager.shared accessed before being initialized with a ModelContext. Call QRDataManager.initializeShared(modelContext:) first.")
        }
        return shared
    }
    
    // Initialize the shared instance
    static func initializeShared(modelContext: ModelContext) {
        _shared = QRDataManager(modelContext: modelContext)
    }
    
    // Private init to enforce singleton pattern
    private init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - QR Code Methods
    
    /// Save a new QR code to the database
    func saveQRCode(content: String, label: String? = nil, location: CLLocation? = nil) throws -> QRCodeModel {
        // First, determine the QR code type
        let qrType = QRCodeModel.determineQRType(from: content)
        
        // Create the QR code model
        let newQRCode = QRCodeModel(
            label: label,
            content: content,
            qrType: qrType,
            tags: []
        )
        
        // Add location if available
        if let location = location {
            let locationName = label ?? "Scanned Location"
            let newLocation = LocationModel(
                qrCode: newQRCode,
                name: locationName,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            newQRCode.qrLocation = newLocation
            modelContext.insert(newLocation)
        }
        
        // Save QR code to the database
        modelContext.insert(newQRCode)
        try modelContext.save()
        
        return newQRCode
    }
    
    /// Get all QR codes
    func fetchAllQRCodes() throws -> [QRCodeModel] {
        let descriptor = FetchDescriptor<QRCodeModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get QR codes sorted by date
    func fetchQRCodesSortedByDate(ascending: Bool = false) throws -> [QRCodeModel] {
        let order: SortOrder = ascending ? .forward : .reverse
        let descriptor = FetchDescriptor<QRCodeModel>(sortBy: [SortDescriptor(\.createdAt, order: order)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get QR codes sorted by scan count
    func fetchQRCodesSortedByScanCount(ascending: Bool = false) throws -> [QRCodeModel] {
        let order: SortOrder = ascending ? .forward : .reverse
        let descriptor = FetchDescriptor<QRCodeModel>(sortBy: [SortDescriptor(\.scanCount, order: order)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get favorite QR codes
    func fetchFavoriteQRCodes() throws -> [QRCodeModel] {
        let predicate = #Predicate<QRCodeModel> { $0.isFavorite == true }
        let descriptor = FetchDescriptor<QRCodeModel>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get QR codes by type
    func fetchQRCodesByType(_ type: String) throws -> [QRCodeModel] {
        let predicate = #Predicate<QRCodeModel> { $0.qrType == type }
        let descriptor = FetchDescriptor<QRCodeModel>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    /// Search QR codes by content or label
    func searchQRCodes(_ searchText: String) throws -> [QRCodeModel] {
        let predicate = #Predicate<QRCodeModel> {
            $0.content.localizedStandardContains(searchText) ||
            ($0.label?.localizedStandardContains(searchText) ?? false)
        }
        let descriptor = FetchDescriptor<QRCodeModel>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    /// Record a scan of an existing QR code
    func recordScan(for qrCode: QRCodeModel, at location: CLLocation? = nil) throws {
        // Update scan count and last scanned date
        qrCode.recordScan()
        
        // If location is provided and the QR code doesn't have a location yet, add it
        if let location = location, qrCode.qrLocation == nil {
            let settings = try fetchSettings()
            
            if settings.saveLocationData {
                let locationName = qrCode.label ?? "Scanned Location"
                let newLocation = LocationModel(
                    qrCode: qrCode,
                    name: locationName,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                
                qrCode.qrLocation = newLocation
                modelContext.insert(newLocation)
            }
        }
        
        try modelContext.save()
    }
    
    /// Delete a QR code
    func deleteQRCode(_ qrCode: QRCodeModel) throws {
        modelContext.delete(qrCode)
        try modelContext.save()
    }
    
    /// Update a QR code's label
    func updateQRCodeLabel(_ qrCode: QRCodeModel, newLabel: String?) throws {
        qrCode.updateLabel(newLabel)
        try modelContext.save()
    }
    
    /// Toggle a QR code's favorite status
    func toggleFavorite(for qrCode: QRCodeModel) throws {
        qrCode.toggleFavorite()
        try modelContext.save()
    }
    
    // MARK: - Tag Methods
    
    /// Create a new tag
    func createTag(name: String, color: String? = nil) throws -> TagModel {
        let newTag = TagModel(name: name, color: color)
        modelContext.insert(newTag)
        try modelContext.save()
        return newTag
    }
    
    /// Get all tags
    func fetchAllTags() throws -> [TagModel] {
        let descriptor = FetchDescriptor<TagModel>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get tags sorted by usage
    func fetchTagsSortedByUsage() throws -> [TagModel] {
        let tags = try fetchAllTags()
        return TagModel.sortByFrequency(tags)
    }
    
    /// Add a tag to a QR code
    func addTagToQRCode(_ tag: TagModel, qrCode: QRCodeModel) throws {
        qrCode.addTag(tag)
        try modelContext.save()
    }
    
    /// Remove a tag from a QR code
    func removeTagFromQRCode(_ tag: TagModel, qrCode: QRCodeModel) throws {
        qrCode.removeTag(tag)
        try modelContext.save()
    }
    
    /// Delete a tag
    func deleteTag(_ tag: TagModel) throws {
        modelContext.delete(tag)
        try modelContext.save()
    }
    
    // MARK: - Settings Methods
    
    /// Get the app settings
    func fetchSettings() throws -> SettingsModel {
        let descriptor = FetchDescriptor<SettingsModel>()
        let settings = try modelContext.fetch(descriptor)
        
        // If no settings exist, create default settings
        if settings.isEmpty {
            let defaultSettings = SettingsModel.createDefaultSettings()
            modelContext.insert(defaultSettings)
            try modelContext.save()
            return defaultSettings
        }
        
        return settings[0]
    }
    
    /// Update settings
    func updateSettings(with updatedSettings: SettingsModel) throws {
        try modelContext.save()
    }
    
    // MARK: - Data Management Methods
    
    /// Purge old QR codes based on retention setting
    func purgeOldQRCodes() throws {
        let settings = try fetchSettings()
        
        // Calculate the cutoff date
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -settings.historyRetentionDays, to: Date()) else {
            return
        }
        
        // Fetch QR codes older than the cutoff date
        let predicate = #Predicate<QRCodeModel> { $0.createdAt < cutoffDate && $0.isFavorite == false }
        let descriptor = FetchDescriptor<QRCodeModel>(predicate: predicate)
        let oldQRCodes = try modelContext.fetch(descriptor)
        
        // Delete the old QR codes
        for qrCode in oldQRCodes {
            modelContext.delete(qrCode)
        }
        
        try modelContext.save()
    }
    
    /// Export all QR codes as JSON
    func exportQRCodesAsJSON() throws -> Data {
        let qrCodes = try fetchAllQRCodes()
        
        // Create a simple struct for export
        struct QRCodeExport: Codable {
            let id: UUID
            let label: String?
            let content: String
            let qrType: String
            let scanCount: Int
            let isFavorite: Bool
            let createdAt: Date
            let location: LocationExport?
            let tags: [String]
            
            struct LocationExport: Codable {
                let name: String
                let latitude: Double
                let longitude: Double
                let address: String?
            }
        }
        
        // Map QR codes to export format
        let exportData = qrCodes.map { qrCode in
            return QRCodeExport(
                id: qrCode.id,
                label: qrCode.label,
                content: qrCode.content,
                qrType: qrCode.qrType,
                scanCount: qrCode.scanCount,
                isFavorite: qrCode.isFavorite,
                createdAt: qrCode.createdAt,
                location: qrCode.qrLocation.map { loc in
                    QRCodeExport.LocationExport(
                        name: loc.name,
                        latitude: loc.latitude,
                        longitude: loc.longitude,
                        address: loc.address
                    )
                },
                tags: (qrCode.tags ?? []).map { $0.name }
            )
        }
        
        // Encode as JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(exportData)
        
        // Update last export date in settings
        let settings = try fetchSettings()
        settings.recordExport()
        try modelContext.save()
        
        return jsonData
    }
    
    /// Clear all data (except settings)
    func clearAllData() throws {
        // Delete all QR codes
        let qrCodeDescriptor = FetchDescriptor<QRCodeModel>()
        let allQRCodes = try modelContext.fetch(qrCodeDescriptor)
        
        for qrCode in allQRCodes {
            modelContext.delete(qrCode)
        }
        
        // Delete all tags (locations will be deleted by cascade)
        let tagDescriptor = FetchDescriptor<TagModel>()
        let allTags = try modelContext.fetch(tagDescriptor)
        
        for tag in allTags {
            modelContext.delete(tag)
        }
        
        try modelContext.save()
        
        // Recreate default tags
        let workTag = TagModel(name: "Work", color: "#FF5733")
        let personalTag = TagModel(name: "Personal", color: "#33FF57")
        let favoriteTag = TagModel(name: "Important", color: "#3357FF")
        
        modelContext.insert(workTag)
        modelContext.insert(personalTag)
        modelContext.insert(favoriteTag)
        
        try modelContext.save()
    }
}
