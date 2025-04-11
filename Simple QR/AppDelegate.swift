//
//  AppDelegate.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/10/25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup disposable domains system
        setupDisposableDomainsSystem()
        return true
    }
    
    // MARK: - Disposable Domains
    
    func setupDisposableDomainsSystem() {
        // First try to load existing domains
        let loadResult = DisposableEmailChecker.shared.loadDomains()
        
        // Check if we need to update the domains file
        if !loadResult || DisposableDomainsManager.shared.shouldUpdateDomainsFile() {
            updateDisposableDomainsInBackground()
        }
    }
    
    func updateDisposableDomainsInBackground() {
        // Get a background task identifier
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        
        // Register the background task
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            // End the task if it expires
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        // Download the domains file
        DisposableDomainsManager.shared.downloadDomainsFile { success, error in
            // If download was successful, reload the domains
            if success {
                DisposableEmailChecker.shared.reloadDomains()
                print("Disposable domains updated successfully")
            } else if let error = error {
                print("Failed to update disposable domains: \(error.localizedDescription)")
            }
            
            // End the background task
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}
