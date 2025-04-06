//
//  SettingsViewExtension.swift
//  QR Unveil
//
//  Created on 4/5/25.
//

import SwiftUI
import CloudKit

// Extension to add debugging tools to the settings view
extension SettingsView {
    
    // Debug menu implementation
    @ViewBuilder
    func debugMenuSection() -> some View {
        #if DEBUG
        Section("Developer Tools") {
            NavigationLink(destination: CloudKitDebugView()) {
                HStack {
                    Image(systemName: "icloud")
                        .foregroundColor(.blue)
                    Text("CloudKit Debug")
                }
            }
            
            Button {
                forceCloudKitSync()
            } label: {
                Label("Force CloudKit Sync", systemImage: "arrow.clockwise.icloud")
            }
            
            Button {
                simulateCloudKitError()
            } label: {
                Label("Simulate CloudKit Error", systemImage: "exclamationmark.icloud")
            }
            
            Button {
                resetCloudKitState()
            } label: {
                Label("Reset CloudKit State", systemImage: "arrow.counterclockwise.icloud")
                    .foregroundColor(.red)
            }
        }
        #else
        // Return an empty view in release builds
        EmptyView()
        #endif
    }
    
    private func resetCloudKitState() {
        // First show a confirmation alert
        let alert = UIAlertController(
            title: "Reset CloudKit State?",
            message: "This will reset the local CloudKit sync state and force a fresh setup. The app will need to restart. Use this only as a last resort for sync issues.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            // Perform the reset
            CloudKitSyncManager.shared.resetCloudKitSyncState()
            
            // Notify user to restart app
            let restartAlert = UIAlertController(
                title: "CloudKit Reset Complete",
                message: "Please close and restart the app for changes to take effect.",
                preferredStyle: .alert
            )
            
            restartAlert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Present the alert using the current window scene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let topViewController = windowScene.windows.first?.rootViewController {
                topViewController.present(restartAlert, animated: true)
            }
        })
        
        // Present the alert using the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let topViewController = windowScene.windows.first?.rootViewController {
            topViewController.present(alert, animated: true)
        }
    }
    
    // Function to force CloudKit synchronization
    private func forceCloudKitSync() {
        // First force save any pending changes
        do {
            try QRDataManager.shared.forceSave()
        } catch {
            print("Error saving before sync: \(error.localizedDescription)")
        }
        
        // Then trigger sync with logging
        CloudKitSyncManager.shared.triggerSyncWithLogging()
    }
    
    // Function to simulate a CloudKit error for testing
    private func simulateCloudKitError() {
        // Create a fake CloudKit error for testing
        let userInfo: [String: Any] = [
            CKErrorRetryAfterKey: NSNumber(value: 30.0),
            NSLocalizedDescriptionKey: "Simulated Server Rejected Request error"
        ]
        
        let error = NSError(
            domain: CKErrorDomain,
            code: CKError.serverRejectedRequest.rawValue,
            userInfo: userInfo
        )
        
        // Log the simulated error
        CloudKitDebugger.shared.logOperation(
            type: .sync,
            status: .failed,
            details: "Simulated error for testing",
            error: error
        )
        
        // Handle the simulated error
        CloudKitSyncManager.shared.handleCloudKitError(
            error as Error,
            operationID: "simulated-\(Date().timeIntervalSince1970)"
        ) {
            print("Simulated error recovery callback executed")
        }
    }
}
