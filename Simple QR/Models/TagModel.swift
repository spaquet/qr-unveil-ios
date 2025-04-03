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
}
