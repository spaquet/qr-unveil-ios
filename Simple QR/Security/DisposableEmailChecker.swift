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
            print("Loading domains from \(domainsURL.path)")
            
            let domainsContent = try String(contentsOf: domainsURL, encoding: .utf8)
            print("Loaded \(domainsContent.count) characters")
            
            // Sample of content for debugging
            if domainsContent.count > 100 {
                print("Sample of content: \(domainsContent.prefix(100))...")
            }
            
            // Split the content by new lines and add to set
            let domains = domainsContent.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            disposableDomains = Set(domains)
            isLoaded = true
            
            print("Loaded \(disposableDomains.count) disposable domains")
            
            // Check for specific domains that should be in the list
            let testDomains = ["mailinator.com", "10minutemail.com", "guerrillamail.com"]
            for testDomain in testDomains {
                print("Test domain \(testDomain) in list: \(disposableDomains.contains(testDomain))")
            }
            
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
            let loadResult = loadDomains()
            print("Initial domain load result: \(loadResult)")
            print("Loaded \(disposableDomains.count) domains")
        }
        
        // Log some sample domains for verification
        if !disposableDomains.isEmpty {
            let sampleDomains = Array(disposableDomains.prefix(5))
            print("Sample domains: \(sampleDomains)")
        }
        
        // Extract domain from email
        guard let domain = extractDomain(from: email)?.lowercased() else {
            print("Failed to extract domain from \(email)")
            return false
        }
        
        print("Checking if \(domain) is in disposable domains list")
        let isDisposable = disposableDomains.contains(domain)
        print("Result: \(isDisposable)")
        
        return isDisposable
    }
    
    /**
     * Extracts the domain part from an email address
     *
     * @param email The email address
     * @return The domain part of the email, or nil if invalid format
     */
    private func extractDomain(from email: String) -> String? {
        // Handle "mailto:" prefix if present
        let cleanEmail = email.hasPrefix("mailto:") ?
            email.replacingOccurrences(of: "mailto:", with: "") : email
        
        // First, extract just the email part before any URL parameters
        let emailPart: String
        if let questionMarkIndex = cleanEmail.firstIndex(of: "?") {
            emailPart = String(cleanEmail[..<questionMarkIndex])
        } else {
            emailPart = cleanEmail
        }
        
        // Now extract the domain from the clean email
        let components = emailPart.components(separatedBy: "@")
        guard components.count == 2 else {
            print("Invalid email format: \(emailPart)")
            return nil
        }
        
        // Get domain part
        let domain = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        print("Extracted domain: \(domain)")
        
        return domain
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
