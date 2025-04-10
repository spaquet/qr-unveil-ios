//
//  SettingsManager.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/6/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class SettingsManager {
    var settings: SettingsModel?
    private var modelContext: ModelContext?
    
    static let shared = SettingsManager()
    
    private init() {
        // ModelContext will be set in setup method
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
    }
    
    func loadSettings() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<SettingsModel>()
        do {
            let fetchedSettings = try modelContext.fetch(descriptor)
            if let firstSettings = fetchedSettings.first {
                self.settings = firstSettings
            } else {
                // Create default settings if none exist
                let defaultSettings = SettingsModel.createDefaultSettings()
                modelContext.insert(defaultSettings)
                try modelContext.save()
                self.settings = defaultSettings
            }
        } catch {
            print("Error loading settings: \(error)")
        }
    }
    
    func updateSaveLocationDataPreference(enabled: Bool) {
        // Ensure we have valid settings
        guard let settings = self.settings else {
            print("Error: Unable to update location preference - settings not initialized")
            return
        }
        
        // Ensure we have a valid model context
        guard let modelContext = self.modelContext else {
            print("Error: Unable to update location preference - model context not initialized")
            return
        }
        
        // Update the setting
        settings.saveLocationData = enabled
        
        // Persist the change
        do {
            try modelContext.save()
            print("Location preference updated to: \(enabled)")
        } catch {
            print("Error saving location preference update: \(error)")
        }
    }
    
    // Convenience methods to access settings
    var vibrationFeedback: Bool {
        return settings?.vibrationFeedback ?? true
    }
    
    var playSoundOnScan: Bool {
        return settings?.playSoundOnScan ?? true
    }
    
    var saveLocationData: Bool {
        return (settings?.saveLocationData ?? true) && LocationManager.shared.isAuthorized
    }
}
