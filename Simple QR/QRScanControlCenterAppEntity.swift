//
//  QRScanControlCenterAppEntity.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/7/25.
//

import Foundation
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct QRScanControlCenterAppEntity: AppEntity {
    static var defaultQuery = QRScanControlCenterAppEntityQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "QR Scan"
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Scan QR Code")
    }
    
    // Unique identifier
    var id: String
    
    // Unique entity type
    static var typeDisplayName: LocalizedStringResource = "QR Scan"
}

@available(iOS 17.0, *)
struct QRScanControlCenterAppEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [QRScanControlCenterAppEntity] {
        return identifiers.map { QRScanControlCenterAppEntity(id: $0) }
    }
    
    func suggestedEntities() async throws -> [QRScanControlCenterAppEntity] {
        return [QRScanControlCenterAppEntity(id: "scan-qr")]
    }
}
