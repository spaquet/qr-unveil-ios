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
    
    var id: UUID = UUID()
    
    var name: String = ""
    var color: String?
    
    @Relationship(deleteRule: .nullify, inverse: \QRCodeModel.tags)
    var qrCodes: [QRCodeModel]? = []
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case qrCodes = "qr_codes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(name: String = "", color: String? = nil, qrCodes: [QRCodeModel] = []) {
        self.id = UUID()
        self.name = name
        self.color = color ?? TagModel.randomColor()
        self.qrCodes = qrCodes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        qrCodes = try container.decode([QRCodeModel].self, forKey: .qrCodes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encode(qrCodes, forKey: .qrCodes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    
    /// Updates the tag name
    func updateName(_ newName: String) {
        self.name = newName
        self.updatedAt = Date()
    }
    
    /// Updates the tag color
    func updateColor(_ newColor: String) {
        self.color = newColor
        self.updatedAt = Date()
    }
    
    /// Adds a QR code to this tag
    func addQRCode(_ qrCode: QRCodeModel) {
        var currentQRCodes = self.qrCodes ?? []
        
        if !currentQRCodes.contains(where: { $0.id == qrCode.id }) {
            currentQRCodes.append(qrCode)
            self.qrCodes = currentQRCodes
            
            var qrCodeTags = qrCode.tags ?? []
            qrCodeTags.append(self)
            qrCode.tags = qrCodeTags
            
            self.updatedAt = Date()
        }
    }
    
    /// Removes a QR code from this tag
    func removeQRCode(_ qrCode: QRCodeModel) {
        var currentQRCodes = self.qrCodes ?? []
        currentQRCodes.removeAll(where: { $0.id == qrCode.id })
        self.qrCodes = currentQRCodes
        
        var qrCodeTags = qrCode.tags ?? []
        qrCodeTags.removeAll(where: { $0.id == self.id })
        qrCode.tags = qrCodeTags
        
        self.updatedAt = Date()
    }
    
    /// Returns the number of QR codes with this tag
    func qrCodeCount() -> Int {
        return qrCodes?.count ?? 0
    }
    
    // MARK: - Static Methods
    
    /// Generate a random color in hex format for tag differentiation
    static func randomColor() -> String {
        let colors = [
            "#FF5733", // Red-Orange
            "#33FF57", // Green
            "#3357FF", // Blue
            "#FF33A8", // Pink
            "#33FFF0", // Cyan
            "#F033FF", // Magenta
            "#FF8333", // Orange
            "#33FF83", // Mint
            "#8333FF", // Purple
            "#FFCE33", // Yellow
            "#33B5FF", // Light Blue
            "#FF33B5"  // Rose
        ]
        
        return colors[Int.random(in: 0..<colors.count)]
    }
    
    /// Sorts tags by name
    static func sortByName(_ tags: [TagModel]) -> [TagModel] {
        return tags.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    /// Sorts tags by frequency (most used first)
    static func sortByFrequency(_ tags: [TagModel]) -> [TagModel] {
        return tags.sorted { ($0.qrCodes?.count ?? 0) > ($1.qrCodes?.count ?? 0) }
    }
}
