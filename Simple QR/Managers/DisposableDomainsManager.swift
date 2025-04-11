//
//  DisposableDomainsManager.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/10/25.
//  Updated for battery optimization

import Foundation
import Sentry
import SentrySwiftUI
import UIKit

/**
 * DisposableDomainsManager
 *
 * This class manages downloading, storing, and updating the list of disposable email domains.
 * It handles caching, versioning via ETag, and smart update policies to minimize unnecessary downloads.
 * Optimized for battery usage by integrating with NetworkMonitor.
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
    
    /// Maximum background task duration (in seconds)
    private let maxBackgroundTaskDuration: TimeInterval = 30
    
    /// Flag to prevent multiple concurrent downloads
    private var isDownloading = false
    
    /// Background task identifier
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    /// Track if NetworkMonitor has been initialized
    private var isNetworkMonitorInitialized = false
    
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
     * - lastChecked: When the file was last checked for updates (even if no update was needed)
     */
    struct DomainsMetadata: Codable {
        var lastUpdated: Date
        var lastChecked: Date
        var eTag: String?
        var contentHash: String?
        
        // Add coding keys to handle the missing lastChecked field
        enum CodingKeys: String, CodingKey {
            case lastUpdated
            case lastChecked
            case eTag
            case contentHash
        }
        
        // Custom decoder initializer for backward compatibility
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Required field
            lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
            
            // Optional fields with defaults
            // If lastChecked is missing, use lastUpdated as the default value
            lastChecked = try container.decodeIfPresent(Date.self, forKey: .lastChecked) ?? lastUpdated
            eTag = try container.decodeIfPresent(String.self, forKey: .eTag)
            contentHash = try container.decodeIfPresent(String.self, forKey: .contentHash)
        }
        
        // Regular initializer
        init(lastUpdated: Date, lastChecked: Date, eTag: String? = nil, contentHash: String? = nil) {
            self.lastUpdated = lastUpdated
            self.lastChecked = lastChecked
            self.eTag = eTag
            self.contentHash = contentHash
        }
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
     * Updates the lastChecked timestamp without changing other metadata
     * This helps prevent repeated check attempts when updates aren't needed
     */
    private func updateLastCheckedTimestamp() {
        if var metadata = loadMetadata() {
            metadata.lastChecked = Date()
            saveMetadata(metadata)
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
     * - The last check was more than 24 hours ago
     *
     * @param forceCheck If true, ignores the 24-hour check interval
     * @return Boolean indicating if an update is needed
     */
    func shouldUpdateDomainsFile(forceCheck: Bool = false) -> Bool {
        // If file doesn't exist, we definitely need to update
        guard domainsFileExists(), let metadata = loadMetadata() else {
            return true
        }
        
        let now = Date()
        
        // Check if we've already checked for updates in the last 24 hours
        // Skip this check if forceCheck is true (used by the manual update in settings)
        if !forceCheck {
            let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
            if metadata.lastChecked > oneDayAgo {
                return false
            }
        }
        
        // Check if file is older than 7 days
        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        return metadata.lastUpdated < sevenDaysAgo
    }
    
    /**
     * Initiates a smart download based on network conditions and battery state
     * Only downloads when conditions are favorable for battery life
     *
     * @param forceCheck If true, will check for updates regardless of when last checked
     * @param bypassNetworkRestrictions If true, will download even on cellular (for manual updates)
     * @param completion Closure called when download completes or is deferred (success, error)
     */
    func smartDownloadDomainsFile(forceCheck: Bool = false,
                                   bypassNetworkRestrictions: Bool = false,
                                   completion: @escaping (Bool, Error?) -> Void) {
        // Prevent multiple simultaneous downloads
        guard !isDownloading else {
            completion(false, NSError(domain: "com.qrunveil.disposabledomains",
                                     code: 1003,
                                     userInfo: [NSLocalizedDescriptionKey: "Download already in progress"]))
            return
        }
        
        // Update lastChecked timestamp to prevent repeated checks
        updateLastCheckedTimestamp()
        
        // Check if we need to update at all
        guard shouldUpdateDomainsFile(forceCheck: forceCheck) else {
            completion(true, nil)
            return
        }
        
        // Get network status using our safe method
        let networkStatus = getNetworkStatus()
        
        // Only download if connected
        if !networkStatus.isConnected {
            // Not connected, defer download
            let error = NSError(domain: "com.qrunveil.disposabledomains",
                               code: 1004,
                               userInfo: [NSLocalizedDescriptionKey: "No network connection available"])
            completion(false, error)
            return
        }
        
        // Check battery state - don't download when in low power mode
        // Allow bypass only for manual updates (Settings page)
        if ProcessInfo.processInfo.isLowPowerModeEnabled && !bypassNetworkRestrictions {
            let error = NSError(domain: "com.qrunveil.disposabledomains",
                               code: 1005,
                               userInfo: [NSLocalizedDescriptionKey: "Device in low power mode, deferring download"])
            completion(false, error)
            return
        }
        
        // If on cellular, only download if the file doesn't exist at all or if bypassNetworkRestrictions is true
        if networkStatus.connectionType == .cellular && domainsFileExists() && !bypassNetworkRestrictions {
            let error = NSError(domain: "com.qrunveil.disposabledomains",
                               code: 1006,
                               userInfo: [NSLocalizedDescriptionKey: "On cellular connection, deferring non-critical update"])
            completion(false, error)
            return
        }
        
        // All checks passed, start the download with controlled background task
        downloadDomainsFileWithTimeout(completion: completion)
    }
    
    /**
     * Downloads the domains file with a timeout to prevent excessive battery drain
     *
     * @param completion Closure called when download completes (success, error)
     */
    private func downloadDomainsFileWithTimeout(completion: @escaping (Bool, Error?) -> Void) {
        isDownloading = true
        
        // Register background task with a maximum duration
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.cancelDownload(withError: "Background task timeout", code: 1007)
            self?.endBackgroundTask()
        }
        
        // Set a timeout timer for the maximum allowed duration
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: maxBackgroundTaskDuration, repeats: false) { [weak self] _ in
            self?.cancelDownload(withError: "Download timeout", code: 1008)
        }
        
        // Start the actual download
        downloadDomainsFile { [weak self] success, error in
            // Cancel the timeout timer
            timeoutTimer.invalidate()
            
            // Mark download as complete
            self?.isDownloading = false
            
            // End the background task
            self?.endBackgroundTask()
            
            // Pass result to caller
            completion(success, error)
        }
    }
    
    /**
     * Cancels an in-progress download with an error
     *
     * @param message The error message
     * @param code The error code
     */
    private func cancelDownload(withError message: String, code: Int) {
        isDownloading = false
        
        // Report a non-critical error
        let error = NSError(domain: "com.qrunveil.disposabledomains",
                           code: code,
                           userInfo: [NSLocalizedDescriptionKey: message])
        
        reportError(error: error, context: "Download cancelled: \(message)")
    }
    
    /**
     * Safely ends the background task if it's active
     */
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    /**
     * Downloads the domains file asynchronously
     *
     * This method uses URLSession's download task to fetch the file.
     * It includes ETag support to avoid downloading unchanged content.
     *
     * @param completion Closure called when download completes (success, error)
     */
    func downloadDomainsFile(completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: domainsFileURL) else {
            completion(false, NSError(domain: "com.qrunveil.disposabledomains",
                                     code: 1001,
                                     userInfo: [NSLocalizedDescriptionKey: "Invalid domains file URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        
        // Set a timeout to prevent hang
        request.timeoutInterval = 20
        
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
                let error = NSError(domain: "com.qrunveil.disposabledomains",
                                   code: 1002,
                                   userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
                self.reportError(error: error, context: "Invalid HTTP response when downloading domains file")
                completion(false, error)
                return
            }
            
            // 304 Not Modified means our file is already up to date
            if httpResponse.statusCode == 304 {
                // Update the timestamps but keep existing file
                if var metadata = self.loadMetadata() {
                    let now = Date()
                    metadata.lastChecked = now
                    // We technically didn't update, but this prevents daily rechecks
                    metadata.lastUpdated = now
                    self.saveMetadata(metadata)
                }
                completion(true, nil)
                return
            }
            
            // Handle other HTTP errors
            guard httpResponse.statusCode == 200, let tempLocalURL = tempLocalURL else {
                let error = NSError(domain: "com.qrunveil.disposabledomains",
                                   code: httpResponse.statusCode,
                                   userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])
                
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
                let now = Date()
                let metadata = DomainsMetadata(
                    lastUpdated: now,
                    lastChecked: now,
                    eTag: eTag,
                    contentHash: contentHash
                )
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
            "metadataExists": FileManager.default.fileExists(atPath: getMetadataFileURL().path),
            "networkConnected": NetworkMonitor.shared.isConnected,
            "networkType": NetworkMonitor.shared.connectionType.rawValue,
            "lowPowerMode": ProcessInfo.processInfo.isLowPowerModeEnabled
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
                // Only log non-critical network errors to Sentry if they're not just
                // connectivity issues (to avoid spamming the error logs)
                let errorDomain = (error as NSError).domain
                let errorCode = (error as NSError).code
                
                // Skip reporting for connectivity-related errors when we can detect them
                let isConnectivityError = errorDomain == NSURLErrorDomain &&
                    (errorCode == NSURLErrorNotConnectedToInternet ||
                     errorCode == NSURLErrorNetworkConnectionLost ||
                     errorCode == NSURLErrorTimedOut)
                
                // Skip reporting for our own "deferred download" errors
                let isDeferredDownload = errorDomain == "com.qrunveil.disposabledomains" &&
                    (errorCode == 1004 || // No network connection
                     errorCode == 1005 || // Low power mode
                     errorCode == 1006)   // On cellular, non-critical
                
                if !isConnectivityError && !isDeferredDownload {
                    // Standard error reporting for non-connectivity issues
                    SentrySDK.capture(error: error) { scope in
                        scope.setExtras([
                            "context": context,
                            "metadata": metadata
                        ])
                        scope.setTag(value: "disposable_domains", key: "component")
                    }
                } else {
                    // Just log locally for connectivity issues
                    print("Not reporting to Sentry - connectivity or deferred download: \(context)")
                }
        }
    }
    
    // MARK: - Network monitoring
    
    private func getNetworkStatus() -> (isConnected: Bool, connectionType: NetworkMonitor.ConnectionType) {
        let networkMonitor = NetworkMonitor.shared
        
        // Wait a short time for NetworkMonitor to initialize if needed
        if !isNetworkMonitorInitialized {
            // Try to initialize the network monitor if it's not ready
            DispatchQueue.main.async {
                // This will trigger the initialization if it hasn't happened yet
                _ = NetworkMonitor.shared.isConnected
            }
            
            // Short delay to allow NetworkMonitor to initialize
            Thread.sleep(forTimeInterval: 0.1)
            isNetworkMonitorInitialized = true
        }
        
        return (networkMonitor.isConnected, networkMonitor.connectionType)
    }
    
    
    
}

// Make ConnectionType Rawrepresentable for easier logging
extension NetworkMonitor.ConnectionType: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        switch rawValue {
        case "wifi": self = .wifi
        case "cellular": self = .cellular
        case "ethernet": self = .ethernet
        case "unknown": self = .unknown
        default: return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "cellular"
        case .ethernet: return "ethernet"
        case .unknown: return "unknown"
        }
    }
}
