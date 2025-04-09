//
//  URLExtension.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/8/25.
//

import Foundation

extension URL {
    /// Checks if the URL uses HTTPS protocol
    var isHttps: Bool {
        return scheme?.lowercased() == "https"
    }
    
    /// Checks if the URL uses HTTP protocol
    var isHttp: Bool {
        return scheme?.lowercased() == "http"
    }
}

// Add this extension to String for convenience
extension String {
    /// Checks if a URL string uses HTTPS
    var isHttpsUrl: Bool {
        guard let url = URL(string: self) else { return false }
        return url.isHttps
    }
    
    /// Checks if a URL string uses HTTP
    var isHttpUrl: Bool {
        guard let url = URL(string: self) else { return false }
        return url.isHttp
    }
}
