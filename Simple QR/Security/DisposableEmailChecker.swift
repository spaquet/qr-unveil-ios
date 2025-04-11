//
//  DisposableEmailChecker.swift
//  Simple QR
//
//  Created on 4/10/25.
//

import Foundation

/**
 * DisposableEmailChecker
 *
 * This class provides functionality to check if an email address uses a disposable domain.
 * It utilizes the domains list downloaded and managed by DisposableDomainsManager.
 */
class DisposableEmailChecker {
    /// Singleton instance for app-wide access
    static let shared = DisposableEmailChecker()
    
    /// Set containing all disposable domains for efficient lookups
    private var disposableDomains = Set<String>()
    
    /// Flag indicating if the domains have been loaded
    private var isLoaded = false
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /**
     * Loads the disposable domains from the file into memory
     * This should be called during app initialization
     *
     * @return Boolean indicating if loading was successful
     */
    func loadDomains() -> Bool {
        guard DisposableDomainsManager.shared.domainsFileExists() else {
            print("Disposable domains file does not exist")
            return false
        }
        
        do {
            let domainsURL = DisposableDomainsManager.shared.getDomainsFileURL()
            let domainsContent = try String(contentsOf: domainsURL, encoding: .utf8)
            
            // Split the content by new lines and add to set
            let domains = domainsContent.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            disposableDomains = Set(domains)
            isLoaded = true
            
            print("Loaded \(disposableDomains.count) disposable domains")
            return true
        } catch {
            print("Error loading disposable domains: \(error.localizedDescription)")
            return false
        }
    }
    
    /**
     * Checks if an email address uses a disposable domain
     *
     * @param email The email address to check
     * @return Boolean indicating if the email uses a disposable domain
     */
    func isDisposableEmail(_ email: String) -> Bool {
        // Ensure domains are loaded
        if !isLoaded {
            _ = loadDomains()
        }
        
        // Extract domain from email
        guard let domain = extractDomain(from: email)?.lowercased() else {
            return false
        }
        
        // Check if domain exists in our set
        return disposableDomains.contains(domain)
    }
    
    /**
     * Extracts the domain part from an email address
     *
     * @param email The email address
     * @return The domain part of the email, or nil if invalid format
     */
    private func extractDomain(from email: String) -> String? {
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else {
            return nil
        }
        return components[1]
    }
    
    /**
     * Reloads domains from the file
     * Useful after an update from DisposableDomainsManager
     */
    func reloadDomains() {
        disposableDomains.removeAll()
        isLoaded = false
        _ = loadDomains()
    }
}
