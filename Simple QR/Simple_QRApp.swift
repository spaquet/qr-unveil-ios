//
//  Simple_QRApp.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/1/25.
//

import SwiftUI

// This is the entry point to the application

@main
struct Simple_QRApp: App {
    
    @AppStorage("hasSeenWelcomeView") private var hasSeenWelcomeView: Bool = false
    
    var body: some Scene {
        WindowGroup {
            
            // Display the welcome screen only when the app is opened for the first time on the device
            if !hasSeenWelcomeView {
                WelcomeView()
                    .onDisappear {
                        hasSeenWelcomeView = true
                    }
            } else {
                ContentView()
            }
        }
    }
}
