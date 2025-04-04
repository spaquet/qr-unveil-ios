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
    
    var id: UUID = UUID()
    var label: String?
    @Attribute(.externalStorage) var content: String = ""
    var qrType: String = "text"
    
    // Tracking properties
    var scanCount: Int = 0
    var isFavorite: Bool = false
    var lastScanned: Date?
    
    @Relationship(deleteRule: .cascade)
    var securityVerification: SecurityVerificationModel?
    
    @Relationship(deleteRule: .cascade, inverse: \LocationModel.qrCode)
    var qrLocation: LocationModel?
    
    @Relationship(deleteRule: .nullify)
    var tags: [TagModel]? = []
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    public enum CodingKeys: String, CodingKey {
        case id
        case label
        case content
        case qrType = "qr_type"
        case scanCount = "scan_count"
        case isFavorite = "is_favorite"
        case lastScanned = "last_scanned"
        case qrLocation = "qr_location"
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(label: String? = nil, content: String, qrType: String? = nil, qrLocation: LocationModel? = nil, tags: [TagModel] = []) {
        self.id = UUID()
        self.label = label
        self.content = content
        self.qrType = qrType ?? Self.determineQRType(from: content)
        self.scanCount = 1
        self.isFavorite = false
        self.lastScanned = Date()
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
        scanCount = try container.decodeIfPresent(Int.self, forKey: .scanCount) ?? 1
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        lastScanned = try container.decodeIfPresent(Date.self, forKey: .lastScanned)
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
        try container.encode(scanCount, forKey: .scanCount)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encodeIfPresent(lastScanned, forKey: .lastScanned)
        try container.encodeIfPresent(qrLocation, forKey: .qrLocation)
        try container.encode(tags, forKey: .tags)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    
    /// Increments the scan count and updates the last scanned date
    func recordScan() {
        self.scanCount += 1
        self.lastScanned = Date()
        self.updatedAt = Date()
    }
    
    /// Toggles the favorite status of the QR code
    func toggleFavorite() {
        self.isFavorite.toggle()
        self.updatedAt = Date()
    }
    
    /// Updates the QR code label
    func updateLabel(_ newLabel: String?) {
        self.label = newLabel
        self.updatedAt = Date()
    }
    
    /// Adds a tag to the QR code
    func addTag(_ tag: TagModel) {
        var updatedTags = self.tags ?? []
        if !updatedTags.contains(where: { $0.id == tag.id }) {
            updatedTags.append(tag)
            self.tags = updatedTags
            
            var updatedQRCodes = tag.qrCodes ?? []
            updatedQRCodes.append(self)
            tag.qrCodes = updatedQRCodes
            
            self.updatedAt = Date()
        }
    }
    
    /// Removes a tag from the QR code
    func removeTag(_ tag: TagModel) {
        if var tags = self.tags {
            tags.removeAll(where: { $0.id == tag.id })
            self.tags = tags
        }
        
        if var qrCodes = tag.qrCodes {
            qrCodes.removeAll(where: { $0.id == self.id })
            tag.qrCodes = qrCodes
        }
        
        self.updatedAt = Date()
    }
    
    /// Formats the content based on QR type for display
    func formattedContent() -> String {
        switch qrType {
        case "url":
            return content
        case "phone":
            return content.replacingOccurrences(of: "tel:", with: "")
        case "email":
            return content.replacingOccurrences(of: "mailto:", with: "")
        case "wifi":
            // Parse WIFI:S:<SSID>;T:<WPA|WEP|>;P:<password>;H:<true|false|>;;
            if let ssidRange = content.range(of: "S:") {
                let startIndex = content.index(ssidRange.upperBound, offsetBy: 0)
                if let endIndex = content.range(of: ";", range: startIndex..<content.endIndex)?.lowerBound {
                    return String(content[startIndex..<endIndex])
                }
            }
            return content
        case "vcard":
            // Extract name from vCard
            if let nameRange = content.range(of: "FN:") {
                let startIndex = content.index(nameRange.upperBound, offsetBy: 0)
                if let endIndex = content.range(of: "\n", range: startIndex..<content.endIndex)?.lowerBound {
                    return String(content[startIndex..<endIndex])
                }
            }
            return content
        default:
            return content
        }
    }
    
    // MARK: - Static Methods
    
    /// Determines the QR code type based on content
    static func determineQRType(from content: String) -> String {
        let lowercasedContent = content.lowercased()
        
        if lowercasedContent.hasPrefix("http://") || lowercasedContent.hasPrefix("https://") {
            return "url"
        } else if lowercasedContent.hasPrefix("tel:") || isPhoneNumber(lowercasedContent){
            return "phone"
        } else if lowercasedContent.hasPrefix("mailto:") || lowercasedContent.contains("@") && lowercasedContent.contains(".") {
            return "email"
        } else if lowercasedContent.hasPrefix("wifi:") {
            return "wifi"
        } else if lowercasedContent.hasPrefix("begin:vcard") {
            return "vcard"
        } else if lowercasedContent.hasPrefix("geo:") {
            return "location"
        } else if lowercasedContent.hasPrefix("smsto:") || lowercasedContent.hasPrefix("sms:") {
            return "sms"
        } else {
            return "text"
        }
    }
    
    static func isPhoneNumber(_ string: String) -> Bool {
        // Remove any non-digit characters
        let digitsOnly = string.filter { $0.isNumber }
        
        // Check if it has 10-15 digits (standard phone number lengths)
        return digitsOnly.count >= 10 && digitsOnly.count <= 15
    }
}
