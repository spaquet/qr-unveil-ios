//
//  URLSecurityChecker.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/9/25.
//

import Foundation
import Network

class URLSecurityChecker {
    static let shared = URLSecurityChecker()
    
    private init() {}
    
    /// Check SSL certificate validity and redirects for a URL
    /// - Parameters:
    ///   - urlString: The URL string to check
    ///   - completion: Completion handler with results
    func checkURLSecurity(urlString: String, completion: @escaping (URLSecurityResult) -> Void) {
        // Ensure we have network connectivity
        guard NetworkMonitor.shared.isConnected else {
            completion(URLSecurityResult(
                isSecure: nil,
                hasSslIssues: nil,
                redirectCount: nil,
                finalDestination: nil,
                error: "No network connection"
            ))
            return
        }
        
        guard let url = URL(string: urlString) else {
            completion(URLSecurityResult(
                isSecure: false,
                hasSslIssues: true,
                redirectCount: nil,
                finalDestination: nil,
                error: "Invalid URL"
            ))
            return
        }
        
        // Initialize result
        var result = URLSecurityResult(
            isSecure: url.isHttps,
            hasSslIssues: false,
            redirectCount: 0,
            finalDestination: urlString,
            error: nil
        )
        
        // Skip further checks for non-HTTPS URLs
        if !url.isHttps {
            completion(result)
            return
        }
        
        // Create a URLSession with strict SSL validation
        let sessionConfig = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfig)
        
        var redirectCount = 0
        var finalURL = url
        
        // Create a task that only checks headers (doesn't download content)
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0 // 5 second timeout
        
        let task = session.dataTask(with: request) { _, response, error in
            if let error = error {
                // Check if the error is related to SSL
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain &&
                   (nsError.code == NSURLErrorServerCertificateHasUnknownRoot ||
                    nsError.code == NSURLErrorServerCertificateUntrusted ||
                    nsError.code == NSURLErrorServerCertificateHasBadDate ||
                    nsError.code == NSURLErrorSecureConnectionFailed) {
                    
                    result.hasSslIssues = true
                    result.isSecure = false
                    result.error = "SSL certificate validation failed"
                } else {
                    result.error = "Connection error: \(error.localizedDescription)"
                }
                
                completion(result)
                return
            }
            
            // Check redirects
            if let httpResponse = response as? HTTPURLResponse {
                // Track final destination for redirects
                if let responseURL = response?.url, responseURL != url {
                    redirectCount += 1
                    finalURL = responseURL
                }
                
                result.redirectCount = redirectCount
                result.finalDestination = finalURL.absoluteString
                
                // Check HTTP status code
                if httpResponse.statusCode >= 400 {
                    result.error = "HTTP error \(httpResponse.statusCode)"
                }
            }
            
            completion(result)
        }
        
        // Start the task
        task.resume()
    }
}

// Result structure
struct URLSecurityResult {
    var isSecure: Bool?
    var hasSslIssues: Bool?
    var redirectCount: Int?
    var finalDestination: String?
    var error: String?
}
