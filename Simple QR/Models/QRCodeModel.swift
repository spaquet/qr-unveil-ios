//
//  QRCodeModel.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/2/25.
//

import Foundation
import SwiftData

@Model
final class QRCodeModel: Codable {
    
    var id: UUID
    var label: String? // Optional text entered by the user to label a QR code
    var content: String // Content of the QR Code as a String
    var qrType: String // QR Code type: vCard, phone number, email, wifi, etc

    @Relationship(deleteRule: .cascade, inverse: \LocationModel.qrCode)
    var qrLocation: LocationModel?

    @Relationship
    var tags: [TagModel] = []
    
    
    var createdAt: Date
    var updatedAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case label
        case content
        case qrType = "qr_type"
        case qrLocation = "qr_location"
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(label: String? = nil, content: String, qrType: String, qrLocation: LocationModel? = nil, tags: [TagModel]) {
        id = UUID()
        self.label = label
        self.content = content
        self.qrType = qrType
        self.qrLocation = qrLocation
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        content = try container.decode(String.self, forKey: .content)
        qrType = try container.decode(String.self, forKey: .qrType)
        qrLocation = try container.decodeIfPresent(LocationModel.self, forKey: .qrLocation)
        tags = try container.decode([TagModel].self, forKey: .tags)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encode(content, forKey: .content)
        try container.encode(qrType, forKey: .qrType)
        try container.encodeIfPresent(qrLocation, forKey: .qrLocation)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
