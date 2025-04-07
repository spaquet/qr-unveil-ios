//
//  QRScanFromControlCenterIntent.swift
//  Simple QR
//
//  Created on 4/7/25.
//

import Foundation
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct QRScanFromControlCenterIntent: AppIntent {
    static var title: LocalizedStringResource = "Scan QR Code"
    static var description: IntentDescription = IntentDescription(
        "Opens the QR code scanner directly from Control Center",
        categoryName: "QR Scanner",
        searchKeywords: ["scan", "qr code", "camera", "scanner", "control center"]
    )
    
    // Important for Control Center integration
    static var openAppWhenRun = true
    static var isEligibleForWidgets = true
    static var isEligibleForHomeScreen = true
    static var isPersistent = true
    
    static var parameterSummary: some ParameterSummary {
        Summary("Scan QR Code")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Set a UserDefaults flag that ContentView will check
        UserDefaults.standard.set(true, forKey: "LaunchScanQRDirectly")
        
        return .result(value: "Opening QR scanner")
    }
}

// Control Center display representation
@available(iOS 17.0, *)
extension QRScanFromControlCenterIntent {
    static var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(
            title: "Scan QR Code",
            subtitle: "Open the scanner",
            image: .init(systemName: "qrcode.viewfinder")
        )
    }
}
