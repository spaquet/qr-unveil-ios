//
//  CloudKitSyncManager.swift
//  QR Unveil
//
//  Created on 4/5/25.
//

import Foundation
import SwiftData
import CloudKit
import UIKit

/// Manager for handling CloudKit synchronization with proper retry logic
class CloudKitSyncManager {
    // MARK: - Properties
    
    /// Shared instance
    static let shared = CloudKitSyncManager()
    
    /// The queue for CloudKit operations
    private let operationQueue = OperationQueue()
    
    /// Timer for scheduled syncs
    private var syncTimer: Timer?
    
    /// Flag to indicate if a sync is in progress
    private var isSyncInProgress = false
    
    /// Dictionary to track retry attempts and backoff times for operations
    private var retryInfo: [String: (attempts: Int, nextRetryDate: Date)] = [:]
    
    /// Maximum number of retry attempts before giving up
    private let maxRetryAttempts = 5
    
    /// Base interval for exponential backoff (in seconds)
    private let baseRetryInterval: TimeInterval = 2
    
    /// Last sync time
    private(set) var lastSyncTime: Date?
    
    /// Flag to track if we've detected a schema mismatch
    private var hasDetectedSchemaMismatch = false
    
    // MARK: - Initialization
    
    private init() {
        // Set up the operation queue
        operationQueue.name = "com.qrunveil.cloudkitqueue"
        operationQueue.maxConcurrentOperationCount = 1 // Serial execution
        
        // Set up notification observers for application state changes
        setupNotificationObservers()
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObservers() {
        // Monitor app state to manage sync timing
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Monitor CloudKit account changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitAccountChanged),
            name: .CKAccountChanged,
            object: nil
        )
    }
    
    @objc private func handleApplicationWillEnterForeground() {
        // Sync when app comes to foreground
        triggerSync()
    }
    
    @objc private func handleApplicationDidEnterBackground() {
        // Cancel timer when app goes to background
        cancelSyncTimer()
    }
    
    @objc private func handleCloudKitAccountChanged() {
        // Clear retry info when account changes
        retryInfo.removeAll()
        
        // Log account change
        CloudKitDebugger.shared.logOperation(
            type: .accountStatus,
            status: .succeeded,
            details: "iCloud account changed, triggering sync"
        )
        
        // Reset schema mismatch flag
        hasDetectedSchemaMismatch = false
        
        // Trigger a sync to handle the account change
        triggerSync()
    }
    
    // MARK: - Sync Management
    
    /// Trigger a CloudKit sync if conditions allow
    func triggerSync() {
        // Don't start a new sync if one is already in progress
        guard !isSyncInProgress else {
            print("CloudKit sync already in progress, skipping...")
            CloudKitDebugger.shared.logOperation(
                type: .sync,
                status: .failed,
                details: "Sync already in progress, request ignored"
            )
            return
        }
        
        // Check if iCloud is available
        checkCloudKitAvailability { [weak self] isAvailable in
            guard let self = self, isAvailable else {
                print("CloudKit is not available, skipping sync")
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .failed,
                    details: "CloudKit is not available, sync skipped"
                )
                return
            }
            
            CloudKitDebugger.shared.logOperation(
                type: .sync,
                status: .started,
                details: "Starting CloudKit sync"
            )
            self.performSync()
        }
    }
    
    /// Schedule a sync with a delay
    func scheduleSyncWithDelay(_ delay: TimeInterval) {
        // Cancel any existing timer
        cancelSyncTimer()
        
        CloudKitDebugger.shared.logOperation(
            type: .sync,
            status: .started,
            details: "Scheduling sync with \(delay) second delay"
        )
        
        // Schedule a new timer
        syncTimer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false
        ) { [weak self] _ in
            self?.triggerSync()
        }
    }
    
    /// Cancel the sync timer
    private func cancelSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    /// Check if CloudKit is available
    private func checkCloudKitAvailability(completion: @escaping (Bool) -> Void) {
        CKContainer.default().accountStatus { status, error in
            let isAvailable = status == .available
            
            if let error = error {
                CloudKitDebugger.shared.logOperation(
                    type: .accountStatus,
                    status: .failed,
                    details: "Error checking CloudKit availability",
                    error: error
                )
            } else if isAvailable {
                CloudKitDebugger.shared.logOperation(
                    type: .accountStatus,
                    status: .succeeded,
                    details: "CloudKit is available"
                )
            } else {
                CloudKitDebugger.shared.logOperation(
                    type: .accountStatus,
                    status: .failed,
                    details: "CloudKit is not available, status: \(status.rawValue)"
                )
            }
            
            DispatchQueue.main.async {
                completion(isAvailable)
            }
        }
    }
    
    /// Perform the actual sync operation
    private func performSync() {
        isSyncInProgress = true
        
        // Log the start of sync
        CloudKitDebugger.shared.logOperation(
            type: .sync,
            status: .started,
            details: "SwiftData CloudKit sync started"
        )
        
        // Update last sync time in memory
        lastSyncTime = Date()
        
        // Update last sync attempt in UserDefaults
        UserDefaults.standard.set(Date(), forKey: "com.qrunveil.lastCloudKitSyncAttempt")
        
        // Check if we have a pending schema mismatch
        if self.hasDetectedSchemaMismatch {
            CloudKitDebugger.shared.logOperation(
                type: .sync,
                status: .failed,
                details: "Sync aborted due to schema mismatch"
            )
            
            self.isSyncInProgress = false
            
            // Post notification about schema issue
            NotificationCenter.default.post(name: .cloudKitSchemaError, object: nil)
            return
        }
        
        // Use CKContainer directly to fetch zone changes
        // This doesn't actually fetch the records but "wakes up" CloudKit
        // and can trigger SwiftData to sync shortly after
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        // First check account status
        container.accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            if status != .available {
                self.isSyncInProgress = false
                
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .failed,
                    details: "CloudKit account not available: \(status.rawValue)"
                )
                return
            }
            
            // Get zones to trigger CloudKit activity
            let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: nil)
            
            operation.fetchDatabaseChangesResultBlock = { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(_):
                    // Zone changes fetched - this activity often triggers SwiftData to sync
                    CloudKitDebugger.shared.logOperation(
                        type: .sync,
                        status: .succeeded,
                        details: "CloudKit activity triggered"
                    )
                    
                    // Notify observers that might want to perform model operations
                    NotificationCenter.default.post(
                        name: .cloudKitSyncTriggered,
                        object: nil
                    )
                    
                    // Create a small delay for SwiftData to pick up on the CloudKit activity
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                        guard let self = self else { return }
                        
                        self.isSyncInProgress = false
                        
                        CloudKitDebugger.shared.logOperation(
                            type: .sync,
                            status: .succeeded,
                            details: "CloudKit sync completed"
                        )
                        
                        // Schedule periodic syncs
                        self.scheduleSyncWithDelay(300) // 5 minutes
                    }
                    
                case .failure(let error):
                    // Handle CloudKit error
                    let operationID = "sync-\(Date().timeIntervalSince1970)"
                    
                    DispatchQueue.main.async {
                        self.isSyncInProgress = false
                        
                        // Handle using retry logic
                        self.handleCloudKitError(error, operationID: operationID) {
                            // This will be called when it's time to retry
                            self.triggerSync()
                        }
                    }
                }
            }

            // Add the operation to the queue
            database.add(operation)
            
            // Set a backup timeout in case the operation doesn't complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                guard let self = self, self.isSyncInProgress else { return }
                
                // If we're still syncing after 30 seconds, assume it completed
                self.isSyncInProgress = false
                
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .succeeded,
                    details: "CloudKit sync completed (timeout)"
                )
                
                // Schedule periodic syncs
                self.scheduleSyncWithDelay(300) // 5 minutes
            }
        }
    }
    
    
    // MARK: - Error Handling
    
    /// Handle CloudKit errors with proper retry logic
    func handleCloudKitError(_ error: Error, operationID: String, completion: @escaping () -> Void) {
        guard let ckError = error as? CKError else {
            print("Non-CloudKit error: \(error.localizedDescription)")
            CloudKitDebugger.shared.logOperation(
                type: .sync,
                status: .failed,
                details: "Non-CloudKit error encountered",
                error: error
            )
            completion()
            return
        }
        
        switch ckError.code {
        case .serverRecordChanged:
            // Handle record conflicts
            CloudKitDebugger.shared.logOperation(
                type: .sync,
                status: .failed,
                details: "Server record changed - resolving conflict",
                error: ckError
            )
            print("Server record changed - resolving conflict...")
            completion()
            
        case .networkFailure, .networkUnavailable, .serviceUnavailable:
            // Temporary network issues - retry with backoff
            CloudKitDebugger.shared.logOperation(
                type: .sync,
                status: .retrying,
                details: "Network or service issue - will retry with backoff",
                error: ckError
            )
            retryWithBackoff(operationID: operationID, error: ckError, completion: completion)
            
        case .serverRejectedRequest:
            if let retryAfter = ckError.retryAfterSeconds {
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .retrying,
                    details: "Server rejected request with retry after \(retryAfter) seconds",
                    error: ckError
                )
                print("Server rejected request with retry after \(retryAfter) seconds")
                scheduleSyncWithDelay(retryAfter)
            } else {
                // Apply our own backoff strategy
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .retrying,
                    details: "Server rejected request with no retry time - using backoff",
                    error: ckError
                )
                retryWithBackoff(operationID: operationID, error: ckError, completion: completion)
            }
            
        case .requestRateLimited:
            if let retryAfter = ckError.retryAfterSeconds {
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .retrying,
                    details: "Request rate limited with retry after \(retryAfter) seconds",
                    error: ckError
                )
                print("Request rate limited with retry after \(retryAfter) seconds")
                scheduleSyncWithDelay(retryAfter)
            } else {
                // Apply our own backoff strategy
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .retrying,
                    details: "Request rate limited with no retry time - using backoff",
                    error: ckError
                )
                retryWithBackoff(operationID: operationID, error: ckError, completion: completion)
            }
            
        case .zoneBusy:
            if let retryAfter = ckError.retryAfterSeconds {
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .retrying,
                    details: "Zone busy with retry after \(retryAfter) seconds",
                    error: ckError
                )
                print("Zone busy with retry after \(retryAfter) seconds")
                scheduleSyncWithDelay(retryAfter)
            } else {
                // Default retry after 30 seconds for zone busy
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .retrying,
                    details: "Zone busy with no retry time - using 30 second delay",
                    error: ckError
                )
                scheduleSyncWithDelay(30)
            }
            
        default:
            // Check if it's a schema mismatch error
            if isSchemaError(error) {
                // Log schema mismatch error
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .failed,
                    details: "Schema mismatch detected: \(ckError.localizedDescription)",
                    error: ckError
                )
                
                // Set flag to prevent further sync attempts
                self.hasDetectedSchemaMismatch = true
                
                // Attempt schema migration
                DispatchQueue.main.async {
                    if CloudKitSchemaMigrator.shared.checkAndMigrateIfNeeded() {
                        // Show alert to user that app needs to be restarted
                        NotificationCenter.default.post(name: .cloudKitSchemaError, object: nil)
                    }
                }
            } else {
                // Log other errors and don't retry
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .failed,
                    details: "Unhandled CloudKit error code: \(ckError.code.rawValue)",
                    error: ckError
                )
            }
            print("Unhandled CloudKit error: \(ckError.localizedDescription)")
            completion()
        }
    }
    
    /// Apply exponential backoff for retries
    private func retryWithBackoff(operationID: String, error: CKError, completion: @escaping () -> Void) {
        // Get current retry info or initialize new entry
        var retryData = retryInfo[operationID] ?? (attempts: 0, nextRetryDate: Date())
        
        // Check if we've exceeded max retry attempts
        if retryData.attempts >= maxRetryAttempts {
            CloudKitDebugger.shared.logOperation(
                type: .retry,
                status: .failed,
                details: "Exceeded maximum retry attempts (\(maxRetryAttempts)) for operation: \(operationID)",
                error: error
            )
            print("Exceeded maximum retry attempts for operation: \(operationID)")
            retryInfo.removeValue(forKey: operationID)
            completion()
            return
        }
        
        // Calculate backoff time
        var retryAfter: TimeInterval = error.retryAfterSeconds ?? 0
        
        if retryAfter <= 0 {
            // Use exponential backoff if no retry time provided
            retryAfter = pow(Double(baseRetryInterval), Double(retryData.attempts + 1))
            
            // Add some jitter (±10%)
            let jitter = Double.random(in: -0.1...0.1)
            retryAfter = retryAfter * (1 + jitter)
            
            // Cap at 5 minutes
            retryAfter = min(retryAfter, 300)
        }
        
        // Update retry info
        retryData.attempts += 1
        retryData.nextRetryDate = Date().addingTimeInterval(retryAfter)
        retryInfo[operationID] = retryData
        
        CloudKitDebugger.shared.logOperation(
            type: .retry,
            status: .started,
            details: "Retrying operation \(operationID) after \(retryAfter) seconds (attempt \(retryData.attempts)/\(maxRetryAttempts))"
        )
        print("Retrying operation \(operationID) after \(retryAfter) seconds (attempt \(retryData.attempts))")
        
        // Schedule retry
        DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter) { [weak self] in
            guard let self = self else { return }
            
            // Check if this operation is still relevant
            guard self.retryInfo[operationID] != nil else {
                completion()
                return
            }
            
            // Remove retry info
            self.retryInfo.removeValue(forKey: operationID)
            
            CloudKitDebugger.shared.logOperation(
                type: .retry,
                status: .succeeded,
                details: "Executing retry for operation \(operationID)"
            )
            
            // Execute completion to retry
            completion()
        }
    }
    
    private func isSchemaError(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        
        // Check for specific schema error conditions
        if ckError.code == .invalidArguments &&
           (ckError.localizedDescription.contains("Cannot create new type") ||
            ckError.localizedDescription.contains("schema") ||
            ckError.localizedDescription.contains("Zone Not Found")) {
            return true
        }
        
        return false
    }
    
    // MARK: - Reset
    /// Reset the CloudKit sync state to force a fresh start
    func resetCloudKitSyncState() {
        // Reset the CloudKit schema setup flag
        UserDefaults.standard.removeObject(forKey: "NSPersistentCloudKitContainerSchemaInitializationCompleted")
        
        // Clear any local CloudKit metadata
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            // Find CloudKit metadata directories
            let cloudKitMetadataURL = appSupportURL.appendingPathComponent("CloudKit")
            
            do {
                // Remove CloudKit metadata if it exists
                if fileManager.fileExists(atPath: cloudKitMetadataURL.path) {
                    try fileManager.removeItem(at: cloudKitMetadataURL)
                    
                    CloudKitDebugger.shared.logOperation(
                        type: .sync,
                        status: .succeeded,
                        details: "CloudKit metadata reset successfully"
                    )
                }
                
                // Also clear SwiftData+CloudKit specific cache
                let swiftDataCachePaths = [
                    "com.apple.swiftdata",
                    "com.apple.coredata.cloudkit.metadata"
                ]
                
                for cachePath in swiftDataCachePaths {
                    let cacheURL = appSupportURL.appendingPathComponent(cachePath)
                    if fileManager.fileExists(atPath: cacheURL.path) {
                        try fileManager.removeItem(at: cacheURL)
                    }
                }
            } catch {
                CloudKitDebugger.shared.logOperation(
                    type: .sync,
                    status: .failed,
                    details: "Failed to reset CloudKit metadata",
                    error: error
                )
            }
        }
        
        // Reset the schema mismatch flag
        hasDetectedSchemaMismatch = false
        
        // Log operation
        CloudKitDebugger.shared.logOperation(
            type: .sync,
            status: .started,
            details: "CloudKit sync state reset, app restart recommended"
        )
    }
}

// MARK: - CKError Extension

extension CKError {
    /// Get the suggested retry delay from a CloudKit error
    var retryAfterSeconds: TimeInterval? {
        if let retryAfterValue = userInfo[CKErrorRetryAfterKey] as? NSNumber {
            return retryAfterValue.doubleValue
        }
        return nil
    }
}
