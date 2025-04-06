//
//  CloudKitSchemaMigrator.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/5/25.
//

import Foundation
import CloudKit
import SwiftUI

class CloudKitSchemaMigrator {
    static let shared = CloudKitSchemaMigrator()
    
    // Current schema version - increment this when you change your model
    private let currentSchemaVersion = 2
    
    // User defaults key for tracking schema version
    private let schemaVersionKey = "com.qrunveil.cloudkitSchemaVersion"
    
    private init() {}
    
    // Check if schema migration is needed
    func checkAndMigrateIfNeeded() -> Bool {
        let savedSchemaVersion = UserDefaults.standard.integer(forKey: schemaVersionKey)
        
        // If stored version is lower than current, migration is needed
        if savedSchemaVersion < currentSchemaVersion {
            CloudKitDebugger.shared.logOperation(
                type: .sync,
                status: .started,
                details: "Schema migration needed from v\(savedSchemaVersion) to v\(currentSchemaVersion)"
            )
            
            // Perform migration
            migrateSchema(from: savedSchemaVersion, to: currentSchemaVersion)
            return true
        }
        
        return false
    }
    
    // Perform the migration
    private func migrateSchema(from oldVersion: Int, to newVersion: Int) {
        // Reset CloudKit sync state
        CloudKitSyncManager.shared.resetCloudKitSyncState()
        
        // Update schema version in UserDefaults
        UserDefaults.standard.set(newVersion, forKey: schemaVersionKey)
        
        CloudKitDebugger.shared.logOperation(
            type: .sync,
            status: .succeeded,
            details: "Schema migrated to v\(newVersion)"
        )
    }
    
    // Reset schema version (for development/testing)
    func resetSchemaVersion() {
        UserDefaults.standard.removeObject(forKey: schemaVersionKey)
    }
}
