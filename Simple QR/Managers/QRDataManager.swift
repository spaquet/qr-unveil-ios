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
    private static var _shared: QRDataManager?
    
    static var shared: QRDataManager {
        guard let shared = _shared else {
            fatalError("QRDataManager.shared accessed before being initialized")
        }
        return shared
    }
    
    static func initializeShared(modelContext: ModelContext) {
        _shared = QRDataManager(modelContext: modelContext)
    }
    
    private init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Basic CRUD operations
    
    func saveQRCode(content: String, label: String? = nil, location: CLLocation? = nil) throws -> QRCodeModel {
        let qrType = QRCodeModel.determineQRType(from: content)
        
        let newQRCode = QRCodeModel(
            label: label,
            content: content,
            qrType: qrType,
            tags: []
        )
        
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
        
        modelContext.insert(newQRCode)
        
        try modelContext.save()
        return newQRCode
    }
    
    func fetchAllQRCodes() throws -> [QRCodeModel] {
        let descriptor = FetchDescriptor<QRCodeModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func fetchSettings() throws -> SettingsModel {
        let descriptor = FetchDescriptor<SettingsModel>()
        let settings = try modelContext.fetch(descriptor)
        
        if settings.isEmpty {
            let defaultSettings = SettingsModel.createDefaultSettings()
            modelContext.insert(defaultSettings)
            try modelContext.save()
            return defaultSettings
        }
        
        return settings[0]
    }
    
    func forceSave() throws {
        try modelContext.save()
    }
}
