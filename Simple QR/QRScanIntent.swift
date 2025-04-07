//
//  QRScanIntents.swift
//  Simple QR
//
//  Created on 4/7/25.
//

import Foundation
import SwiftUI
import AppIntents

// MARK: - QR Scan Intent

@available(iOS 17.0, *)
struct QRScanIntent: AppIntent {
    static var title: LocalizedStringResource = "Scan QR Code"
    static var description: IntentDescription = IntentDescription(
        "Opens the QR code scanner",
        categoryName: "QR Scanner",
        searchKeywords: ["scan", "qr code", "camera", "scanner"]
    )
    
    @Parameter(title: "Message")
    var message: String?
    
    init() {
        self.message = nil
    }
    
    init(message: String?) {
        self.message = message
    }
    
    // Important for search integration
    static var openAppWhenRun = true
    static var isSearchable = true
    
    static var parameterSummary: some ParameterSummary {
        Summary("Scan QR Code")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Set a UserDefaults flag that ContentView will check
        UserDefaults.standard.set(true, forKey: "LaunchScanQRDirectly")
        
        return .result(value: "Opening QR scanner")
    }
}

// MARK: - Combined App Shortcuts Provider

// Single unified AppShortcutsProvider for the entire app
@available(iOS 17.0, *)
struct QRScanAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Have just one shortcut for scanning QR codes
        return [
            // Main QR scan shortcut - this is the only one we really need
            AppShortcut(
                intent: QRScanIntent(),
                phrases: [
                    "Scan a QR code with \(.applicationName)",
                    "Open QR scanner in \(.applicationName)",
                    "QR scan with \(.applicationName)"
                ],
                shortTitle: "Scan QR",
                systemImageName: "qrcode.viewfinder"
            )
        ]
    }
}
