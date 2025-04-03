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
        case address
        case placeId = "place_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(qrCode: QRCodeModel, name: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.qrCode = qrCode
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = nil
        self.placeId = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        qrCode = try container.decode(QRCodeModel.self, forKey: .qrCode)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        placeId = try container.decodeIfPresent(String.self, forKey: .placeId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(qrCode, forKey: .qrCode)
        try container.encode(name, forKey: .name)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(placeId, forKey: .placeId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
}
