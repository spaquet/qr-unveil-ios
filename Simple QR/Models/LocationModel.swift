//
//  LocationModel.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/2/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class LocationModel: Codable {
    
    var id: UUID = UUID()
    
    var qrCode: QRCodeModel?
    
    var name: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    var address: String?
    var placeId: String?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
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
    
    init(qrCode: QRCodeModel, name: String, latitude: Double, longitude: Double, address: String? = nil, placeId: String? = nil) {
        self.id = UUID()
        self.qrCode = qrCode
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.placeId = placeId
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
    
    // MARK: - Helper Methods
    
    /// Calculates the distance between this location and another location
    func distance(to otherLocation: LocationModel) -> CLLocationDistance {
        let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherCLLocation = CLLocation(latitude: otherLocation.latitude, longitude: otherLocation.longitude)
        
        return thisLocation.distance(from: otherCLLocation)
    }
    
    /// Calculates the distance between this location and coordinates
    func distance(to latitude: Double, longitude: Double) -> CLLocationDistance {
        let thisLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        return thisLocation.distance(from: otherLocation)
    }
    
    /// Updates the location metadata
    func updateMetadata(name: String? = nil, address: String? = nil, placeId: String? = nil) {
        if let name = name {
            self.name = name
        }
        
        if let address = address {
            self.address = address
        }
        
        if let placeId = placeId {
            self.placeId = placeId
        }
        
        self.updatedAt = Date()
    }
    
    /// Returns a formatted address string for display
    func formattedAddress() -> String {
        if let address = self.address, !address.isEmpty {
            return address
        } else {
            return "\(latitude), \(longitude)"
        }
    }
    
    /// Performs reverse geocoding to get an address
    func reverseGeocode(completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, error == nil, let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            
            var addressComponents: [String] = []
            
            if let name = placemark.name {
                addressComponents.append(name)
            }
            
            if let street = placemark.thoroughfare {
                addressComponents.append(street)
            }
            
            if let city = placemark.locality {
                addressComponents.append(city)
            }
            
            if let state = placemark.administrativeArea {
                addressComponents.append(state)
            }
            
            if let postalCode = placemark.postalCode {
                addressComponents.append(postalCode)
            }
            
            if let country = placemark.country {
                addressComponents.append(country)
            }
            
            let addressString = addressComponents.joined(separator: ", ")
            
            self.address = addressString
            self.updatedAt = Date()
            
            completion(addressString)
        }
    }
    
    // MARK: - Static Methods
    
    /// Creates a location from a CLLocation
    static func from(clLocation: CLLocation, qrCode: QRCodeModel, name: String) -> LocationModel {
        return LocationModel(
            qrCode: qrCode,
            name: name,
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude
        )
    }
}
