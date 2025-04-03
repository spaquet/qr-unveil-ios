//
//  LocationModel.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/2/25.
//

import Foundation
import SwiftData

@Model
final class LocationModel: Codable {
    
    var id: UUID
    
    var qrCode: QRCodeModel
    
    var name: String
    var latitude: Double
    var longitude: Double
    
    var address: String?  // Added address string for location context
    var placeId: String?  // Added for integration with mapping services
    
    var createdAt: Date
    var updatedAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case qrCode = "qr_code"
        case name
        case latitude
        case longitude
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(qrCode: QRCodeModel, name: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.latitude = longitude
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
}
