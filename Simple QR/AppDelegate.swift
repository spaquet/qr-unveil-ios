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
        // Ensure NetworkMonitor is initialized first
        let networkMonitor = NetworkMonitor.shared
        
        // First try to load existing domains
        let loadResult = DisposableEmailChecker.shared.loadDomains()
        
        // Short delay to ensure NetworkMonitor has time to detect network status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            // Check if we need to update the domains file - only if:
            // 1. Failed to load existing domains OR
            // 2. Domains file needs updating based on age/staleness
            if !loadResult || DisposableDomainsManager.shared.shouldUpdateDomainsFile() {
                // Only update if we have network connectivity
                if networkMonitor.isConnected {
                    // Prefer WiFi over cellular for non-critical updates
                    let shouldUpdate = networkMonitor.isWiFi || !DisposableDomainsManager.shared.domainsFileExists()
                    
                    if shouldUpdate && !ProcessInfo.processInfo.isLowPowerModeEnabled {
                        self?.updateDisposableDomainsInBackground()
                    } else {
                        // We'll try again later when conditions improve
                        print("Deferring disposable domains update due to network conditions or low power mode")
                    }
                }
            }
        }
    }
    
    func updateDisposableDomainsInBackground() {
        // Use the smart download method that integrates with NetworkMonitor
        DisposableDomainsManager.shared.smartDownloadDomainsFile { success, error in
            // If download was successful, reload the domains
            if success {
                DisposableEmailChecker.shared.reloadDomains()
                print("Disposable domains updated successfully")
            } else if let error = error {
                print("Deferred or failed to update disposable domains: \(error.localizedDescription)")
                
                // Schedule a retry for non-connectivity errors when app is active
                if (error as NSError).domain != "com.qrunveil.disposabledomains" {
                    self.scheduleUpdateRetry()
                }
            }
        }
    }
    
    // Schedule a retry when the app becomes active again
    private func scheduleUpdateRetry() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(retryUpdateOnActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func retryUpdateOnActive() {
        // Remove the observer to prevent multiple retries
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Only retry if conditions are favorable
        if NetworkMonitor.shared.isConnected &&
           (NetworkMonitor.shared.isWiFi || !DisposableDomainsManager.shared.domainsFileExists()) &&
           !ProcessInfo.processInfo.isLowPowerModeEnabled {
            
            print("Retrying disposable domains update after app became active")
            updateDisposableDomainsInBackground()
        }
    }
}
