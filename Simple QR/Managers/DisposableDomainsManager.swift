//
//  DisposableDomainsManager.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/10/25.
//


import Foundation
import Sentry
import SentrySwiftUI

/**
 * DisposableDomainsManager
 *
 * This class manages downloading, storing, and updating the list of disposable email domains.
 * It handles caching, versioning via ETag, and smart update policies to minimize unnecessary downloads.
 * The manager also contains error reporting logic for integration with Sentry.
 */
class DisposableDomainsManager {
    /// Singleton instance for app-wide access
    static let shared = DisposableDomainsManager()
    
    /// Source URL for the disposable email domains list on GitHub
    private let domainsFileURL = "https://raw.githubusercontent.com/disposable/disposable-email-domains/refs/heads/master/domains.txt"
    
    /// Filename to use when storing the domains list locally
    private let domainsFileName = "disposable_domains.txt"
    
    /// Filename to use when storing metadata about the domains file
    private let metadataFileName = "domains_metadata.plist"
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - File Management
    
    /**
     * Returns the local URL for the domains file in the documents directory
     *
     * @return URL path to the domains file
     */
    func getDomainsFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(domainsFileName)
    }
    
    /**
     * Returns the local URL for the metadata file in the documents directory
     *
     * @return URL path to the metadata file
     */
    private func getMetadataFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(metadataFileName)
    }
    
    /**
     * Checks if the domains file exists in the local storage
     *
     * @return Boolean indicating if the file exists
     */
    func domainsFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: getDomainsFileURL().path)
    }
    
    func getMetadata() -> DomainsMetadata? {
        return loadMetadata()
    }
    
    // MARK: - Metadata Management
    
    /**
     * Metadata structure for tracking file version information
     *
     * - lastUpdated: When the file was last downloaded/updated
     * - eTag: HTTP ETag from the server for caching purposes
     * - contentHash: A hash of the file content to detect changes
     */
    struct DomainsMetadata: Codable {
        var lastUpdated: Date
        var eTag: String?
        var contentHash: String?
    }
    
    /**
     * Saves the metadata to a plist file
     *
     * @param metadata The metadata to save
     */
    private func saveMetadata(_ metadata: DomainsMetadata) {
        do {
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(metadata)
            try data.write(to: getMetadataFileURL())
        } catch {
            // Report error but don't crash
            reportError(error: error, context: "Failed to save domains metadata")
        }
    }
    
    /**
     * Loads the metadata from the plist file
     *
     * @return The metadata if available, nil otherwise
     */
    private func loadMetadata() -> DomainsMetadata? {
        guard FileManager.default.fileExists(atPath: getMetadataFileURL().path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: getMetadataFileURL())
            let decoder = PropertyListDecoder()
            return try decoder.decode(DomainsMetadata.self, from: data)
        } catch {
            // Report error but don't crash
            reportError(error: error, context: "Failed to load domains metadata")
            return nil
        }
    }
    
    /**
     * Calculates a hash for the file contents to detect changes
     *
     * @param fileURL The URL of the file to hash
     * @return A string representation of the hash, or nil if hashing fails
     */
    private func calculateFileHash(fileURL: URL) -> String? {
        do {
            let data = try Data(contentsOf: fileURL)
            var hasher = Hasher()
            hasher.combine(data)
            return String(hasher.finalize())
        } catch {
            reportError(error: error, context: "Failed to calculate file hash")
            return nil
        }
    }
    
    // MARK: - Download Management
    
    /**
     * Determines if the domains file needs to be updated
     *
     * Updates are needed if:
     * - The file doesn't exist locally
     * - The file is older than 7 days
     *
     * @return Boolean indicating if an update is needed
     */
    func shouldUpdateDomainsFile() -> Bool {
        // If file doesn't exist, we definitely need to update
        guard domainsFileExists(), let metadata = loadMetadata() else {
            return true
        }
        
        // Check if file is older than 7 days
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return metadata.lastUpdated < sevenDaysAgo
    }
    
    /**
     * Downloads the domains file asynchronously in the background
     *
     * This method uses URLSession's download task to fetch the file.
     * It includes ETag support to avoid downloading unchanged content.
     * If the server returns 304 Not Modified, it keeps the existing file.
     *
     * @param completion Closure called when download completes (success, error)
     */
    func downloadDomainsFile(completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: domainsFileURL) else {
            completion(false, NSError(domain: "com.yourdomain.disposabledomains", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid domains file URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        
        // Add ETag if we have it, to avoid downloading unchanged content
        if let metadata = loadMetadata(), let eTag = metadata.eTag {
            request.addValue(eTag, forHTTPHeaderField: "If-None-Match")
        }
        
        let task = URLSession.shared.downloadTask(with: request) { [weak self] (tempLocalURL, response, error) in
            guard let self = self else { return }
            
            // Check for network errors
            if let error = error {
                self.reportError(error: error, context: "Network error while downloading domains file")
                completion(false, error)
                return
            }
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(domain: "com.yourdomain.disposabledomains", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
                self.reportError(error: error, context: "Invalid HTTP response when downloading domains file")
                completion(false, error)
                return
            }
            
            // 304 Not Modified means our file is already up to date
            if httpResponse.statusCode == 304 {
                // Update the last checked timestamp but keep existing file
                if var metadata = self.loadMetadata() {
                    metadata.lastUpdated = Date()
                    self.saveMetadata(metadata)
                }
                completion(true, nil)
                return
            }
            
            // Handle other HTTP errors
            guard httpResponse.statusCode == 200, let tempLocalURL = tempLocalURL else {
                let error = NSError(domain: "com.yourdomain.disposabledomains", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])
                
                // Special handling for 404 error - critical alert to Sentry
                if httpResponse.statusCode == 404 {
                    self.reportError(error: error, context: "CRITICAL: Domains file not found (404)", level: .fatal)
                } else {
                    self.reportError(error: error, context: "HTTP error when downloading domains file")
                }
                
                completion(false, error)
                return
            }
            
            // Get ETag from response, if available
            let eTag = httpResponse.allHeaderFields["ETag"] as? String
            
            // Move the downloaded file to our permanent location
            do {
                let destinationURL = self.getDomainsFileURL()
                
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.copyItem(at: tempLocalURL, to: destinationURL)
                
                // Calculate content hash for future change detection
                let contentHash = self.calculateFileHash(fileURL: destinationURL)
                
                // Update metadata with new information
                let metadata = DomainsMetadata(lastUpdated: Date(), eTag: eTag, contentHash: contentHash)
                self.saveMetadata(metadata)
                
                completion(true, nil)
            } catch {
                self.reportError(error: error, context: "Failed to save downloaded domains file")
                completion(false, error)
            }
        }
        
        // Start the download task
        task.resume()
    }
    
    // MARK: - Error Handling
    
    /**
     * Error severity levels for Sentry reporting
     */
    enum ErrorLevel {
        /// Standard errors, non-critical
        case error
        
        /// Critical errors requiring immediate attention
        case fatal
    }
    
    /**
     * Reports errors to Sentry with appropriate context and severity
     *
     * For 404 errors, this sends a fatal level alert to ensure
     * immediate attention by the development team.
     *
     * @param error The error object
     * @param context Descriptive context about what was happening
     * @param level The severity level (.error or .fatal)
     */
    private func reportError(error: Error, context: String, level: ErrorLevel = .error) {
        print("ERROR: \(context) - \(error.localizedDescription)")
        
        // Additional metadata to include in Sentry events
        let metadata: [String: Any] = [
            "domainsFileURL": domainsFileURL,
            "fileExists": domainsFileExists(),
            "metadataExists": FileManager.default.fileExists(atPath: getMetadataFileURL().path)
        ]
        
        switch level {
            case .fatal:
                // For critical errors like 404s, use special handling
                SentrySDK.capture(message: "CRITICAL: \(context)") { scope in
                    // Set fatal level for highest visibility
                    scope.setLevel(.fatal)
                    
                    // Add detailed error information
                    scope.setExtras([
                        "error_description": error.localizedDescription,
                        "error_domain": (error as NSError).domain,
                        "error_code": (error as NSError).code,
                        "metadata": metadata
                    ])
                    
                    // Set tags for easier filtering/alerts
                    scope.setTag(value: "domains_file_missing", key: "error_type")
                    scope.setTag(value: "disposable_domains", key: "component")
                    scope.setTag(value: "true", key: "requires_immediate_action")
                }
                
                // You could also trigger a custom alert or notification here
                NotificationCenter.default.post(
                    name: Notification.Name("DisposableDomainsFileNotFound"),
                    object: nil
                )
                
            case .error:
                // Standard error reporting
                SentrySDK.capture(error: error) { scope in
                    scope.setExtras([
                        "context": context,
                        "metadata": metadata
                    ])
                    scope.setTag(value: "disposable_domains", key: "component")
                }
        }
        
    }
}
