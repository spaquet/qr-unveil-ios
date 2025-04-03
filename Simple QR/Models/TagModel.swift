//
//  TagModel.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/2/25.
//

import Foundation
import SwiftData

@Model
final class TagModel: Codable {
    
    var id: UUID
    
    var name: String
    var color: String? // Optional color for tag customization
    
    var qrCodes: [QRCodeModel]
    
    var createdAt: Date
    var updatedAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case qrCodes = "qr_codes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(name: String, color: String? = nil, qrCodes: [QRCodeModel]) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.qrCodes = qrCodes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        qrCodes = try container.decode([QRCodeModel].self, forKey: .qrCodes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(qrCodes, forKey: .qrCodes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
