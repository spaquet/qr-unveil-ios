//
//  QRDataManager.swift
//  QR Unveil
//
//  Created on 4/3/25.
//

import CloudKit
import CoreLocation
import Foundation
import SwiftData
import SwiftUI

@Observable
class QRDataManager {
    private let modelContext: ModelContext
    
    // Shared instance for app-wide access
    private static var _shared: QRDataManager?
    
    // Queue for batching operations
    private let operationQueue = DispatchQueue(label: "com.qrunveil.databatchqueue")
    
    // Pending operations that need to be saved
    private var pendingSaveOperations = 0
    
    // Timer for batched saves
    private var batchSaveTimer: Timer?
    
    // Batch save delay
    private let batchSaveDelay: TimeInterval = 2.0
    
    // Maximum pending operations before forcing a save
    private let maxPendingOperations = 10
    
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
        
        // Set up notification observers for application state changes
        setupNotificationObservers()
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleApplicationWillResignActive() {
        // Save any pending changes when the app is about to go to background
        saveBatchedChanges(force: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Batch Save Management
    
    /// Schedule a batched save operation
    private func scheduleBatchedSave() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Increment pending operations counter
            self.pendingSaveOperations += 1
            
            // If we've reached the threshold, force a save
            if self.pendingSaveOperations >= self.maxPendingOperations {
                DispatchQueue.main.async {
                    self.saveBatchedChanges(force: true)
                }
                return
            }
            
            // Otherwise, schedule a delayed save
            DispatchQueue.main.async {
                // Cancel existing timer if there is one
                self.batchSaveTimer?.invalidate()
                
                // Create a new timer
                self.batchSaveTimer = Timer.scheduledTimer(
                    withTimeInterval: self.batchSaveDelay,
                    repeats: false
                ) { [weak self] _ in
                    self?.saveBatchedChanges(force: true)
                }
            }
        }
    }
    
    /// Save all pending changes to the model context
    private func saveBatchedChanges(force: Bool = false) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only proceed if we have pending operations or force is true
            guard self.pendingSaveOperations > 0 || force else { return }
            
            DispatchQueue.main.async {
                do {
                    try self.modelContext.save()
                    
                    // Reset pending operations counter
                    self.pendingSaveOperations = 0
                    
                    // Cancel any pending timer
                    self.batchSaveTimer?.invalidate()
                    self.batchSaveTimer = nil
                    
                    // Trigger CloudKit sync after batch save
                    CloudKitSyncManager.shared.triggerSync()
                } catch {
                    print("Error saving batched changes: \(error.localizedDescription)")
                    
                    // Check if it's a CloudKit error
                    if let ckError = error as? CKError {
                        // Generate a unique operation ID based on timestamp
                        let operationID = "batchsave-\(Date().timeIntervalSince1970)"
                        
                        // Handle with CloudKit retry logic
                        CloudKitSyncManager.shared.handleCloudKitError(ckError, operationID: operationID) {
                            // This will be called when it's appropriate to retry
                            self.saveBatchedChanges(force: true)
                        }
                    }
                }
            }
        }
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
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
        
        return newQRCode
    }
    
    /// Get all QR codes
    func fetchAllQRCodes() throws -> [QRCodeModel] {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
        let descriptor = FetchDescriptor<QRCodeModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get QR codes sorted by date
    func fetchQRCodesSortedByDate(ascending: Bool = false) throws -> [QRCodeModel] {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
        let order: SortOrder = ascending ? .forward : .reverse
        let descriptor = FetchDescriptor<QRCodeModel>(sortBy: [SortDescriptor(\.createdAt, order: order)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get QR codes sorted by scan count
    func fetchQRCodesSortedByScanCount(ascending: Bool = false) throws -> [QRCodeModel] {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
        let order: SortOrder = ascending ? .forward : .reverse
        let descriptor = FetchDescriptor<QRCodeModel>(sortBy: [SortDescriptor(\.scanCount, order: order)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get favorite QR codes
    func fetchFavoriteQRCodes() throws -> [QRCodeModel] {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
        let predicate = #Predicate<QRCodeModel> { $0.isFavorite == true }
        let descriptor = FetchDescriptor<QRCodeModel>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get QR codes by type
    func fetchQRCodesByType(_ type: String) throws -> [QRCodeModel] {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
        let predicate = #Predicate<QRCodeModel> { $0.qrType == type }
        let descriptor = FetchDescriptor<QRCodeModel>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    /// Search QR codes by content or label
    func searchQRCodes(_ searchText: String) throws -> [QRCodeModel] {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
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
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
    }
    
    /// Delete a QR code
    func deleteQRCode(_ qrCode: QRCodeModel) throws {
        modelContext.delete(qrCode)
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
    }
    
    /// Update a QR code's label
    func updateQRCodeLabel(_ qrCode: QRCodeModel, newLabel: String?) throws {
        qrCode.updateLabel(newLabel)
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
    }
    
    /// Toggle a QR code's favorite status
    func toggleFavorite(for qrCode: QRCodeModel) throws {
        qrCode.toggleFavorite()
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
    }
    
    // MARK: - Tag Methods
    
    /// Create a new tag
    func createTag(name: String, color: String? = nil) throws -> TagModel {
        let newTag = TagModel(name: name, color: color)
        modelContext.insert(newTag)
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
        
        return newTag
    }
    
    /// Get all tags
    func fetchAllTags() throws -> [TagModel] {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
        let descriptor = FetchDescriptor<TagModel>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get tags sorted by usage
    func fetchTagsSortedByUsage() throws -> [TagModel] {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
        let tags = try fetchAllTags()
        return TagModel.sortByFrequency(tags)
    }
    
    /// Add a tag to a QR code
    func addTagToQRCode(_ tag: TagModel, qrCode: QRCodeModel) throws {
        qrCode.addTag(tag)
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
    }
    
    /// Remove a tag from a QR code
    func removeTagFromQRCode(_ tag: TagModel, qrCode: QRCodeModel) throws {
        qrCode.removeTag(tag)
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
    }
    
    /// Delete a tag
    func deleteTag(_ tag: TagModel) throws {
        modelContext.delete(tag)
        
        // Schedule a batched save instead of immediate save
        scheduleBatchedSave()
    }
    
    // MARK: - Settings Methods
    
    /// Get the app settings
    func fetchSettings() throws -> SettingsModel {
        // Ensure any pending changes are saved before fetch
        saveBatchedChanges(force: true)
        
        let descriptor = FetchDescriptor<SettingsModel>()
        let settings = try modelContext.fetch(descriptor)
        
        // If no settings exist, create default settings
        if settings.isEmpty {
            let defaultSettings = SettingsModel.createDefaultSettings()
            modelContext.insert(defaultSettings)
            
            // Save immediately for settings
            try modelContext.save()
            return defaultSettings
        }
        
        return settings[0]
    }
    
    /// Update settings
    func updateSettings(with updatedSettings: SettingsModel) throws {
        // Save immediately for settings changes
        try modelContext.save()
        
        // Trigger sync after settings update
        CloudKitSyncManager.shared.triggerSync()
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
        
        // Only save if we actually deleted something
        if !oldQRCodes.isEmpty {
            try modelContext.save()
            
            // Trigger sync after bulk deletion
            CloudKitSyncManager.shared.triggerSync()
        }
    }
    
    /// Export all QR codes as JSON
    func exportQRCodesAsJSON() throws -> Data {
        // Ensure all pending changes are saved before export
        saveBatchedChanges(force: true)
        
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
        
        // Save settings change immediately
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
        
        // Save immediately for data clearing operations
        try modelContext.save()
        
        // Recreate default tags
        let workTag = TagModel(name: "Work", color: "#FF5733")
        let personalTag = TagModel(name: "Personal", color: "#33FF57")
        let favoriteTag = TagModel(name: "Important", color: "#3357FF")
        
        modelContext.insert(workTag)
        modelContext.insert(personalTag)
        modelContext.insert(favoriteTag)
        
        try modelContext.save()
        
        // Trigger CloudKit sync after major data change
        CloudKitSyncManager.shared.triggerSync()
    }
    
    /// Force save any pending changes
    func forceSave() throws {
        saveBatchedChanges(force: true)
    }
}

// MARK: - Extensions for CloudKit Error Handling

extension ModelContext {
    /// Safer save method with CloudKit error handling
    func saveWithErrorHandling() throws {
        do {
            try save()
        } catch {
            // Check if it's a CloudKit error
            if let ckError = error as? CKError {
                // Generate a unique operation ID based on timestamp
                let operationID = "modelsave-\(Date().timeIntervalSince1970)"
                
                // Handle with CloudKit retry logic
                CloudKitSyncManager.shared.handleCloudKitError(ckError, operationID: operationID) {
                    // This will be called when it's appropriate to retry
                    try? self.save()
                }
                
                // Re-throw the error so the caller can handle it as needed
                throw error
            } else {
                // Re-throw non-CloudKit errors
                throw error
            }
        }
    }
}

// MARK: - CloudKit Error Handling Extensions

extension ModelContext {
    /// Save with better CloudKit error handling
    func saveWithCloudKitErrorHandling() throws {
        do {
            try save()
        } catch {
            // Log the error
            print("CloudKit save error: \(error.localizedDescription)")
            
            // Check if it's a CloudKit error
            if let ckError = error as? CKError {
                // Handle server rejection or rate limiting
                if ckError.code == .serverRejectedRequest || ckError.code == .requestRateLimited {
                    // Check for retry-after value
                    if let retryAfter = ckError.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
                        print("CloudKit requested retry after \(retryAfter) seconds")
                        
                        // Log to the debugger
                        CloudKitDebugger.shared.logOperation(
                            type: .save,
                            status: .failed,
                            details: "Error with retry after \(retryAfter) seconds",
                            error: ckError
                        )
                        
                        // Schedule a retry after the specified delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter) {
                            print("Retrying CloudKit save after delay")
                            try? self.save()
                        }
                    }
                } else {
                    // Log other CloudKit errors
                    CloudKitDebugger.shared.logOperation(
                        type: .save,
                        status: .failed,
                        details: nil,
                        error: ckError
                    )
                }
            }
            
            // Re-throw the error so calling code can handle it if needed
            throw error
        }
    }
}

extension QRDataManager {
    /// Force save changes and respect CloudKit limits
    func forceSaveWithCloudKitHandling() {
        do {
            // Try to save with CloudKit error handling
            try modelContext.saveWithCloudKitErrorHandling()
            
            // Log successful save
            CloudKitDebugger.shared.logOperation(
                type: .save,
                status: .succeeded,
                details: "Forced save completed successfully"
            )
        } catch {
            print("Error during forced save: \(error.localizedDescription)")
        }
    }
}
