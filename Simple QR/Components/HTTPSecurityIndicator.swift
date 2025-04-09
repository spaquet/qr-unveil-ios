//
//  HTTPSecurityIndicator.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/8/25.
//

import SwiftUI

struct HTTPSecurityIndicator: View {
    enum SecurityStatus {
        case secure     // HTTPS
        case insecure   // HTTP
        case unknown    // Not a URL or couldn't determine
    }
    
    let status: SecurityStatus
    let showText: Bool
    
    init(url: String?, showText: Bool = true) {
        if let urlString = url, let url = URL(string: urlString) {
            if url.scheme?.lowercased() == "https" {
                self.status = .secure
            } else if url.scheme?.lowercased() == "http" {
                self.status = .insecure
            } else {
                self.status = .unknown
            }
        } else {
            self.status = .unknown
        }
        
        self.showText = showText
    }
    
    init(status: SecurityStatus, showText: Bool = true) {
        self.status = status
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 12))
            
            if showText {
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
    }
    
    private var iconName: String {
        switch status {
        case .secure:
            return "lock.fill"
        case .insecure:
            return "exclamationmark.lock.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case .secure:
            return .green
        case .insecure:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .secure:
            return "Secure"
        case .insecure:
            return "Not Secure"
        case .unknown:
            return "Unknown"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .secure:
            return Color.green.opacity(0.15)
        case .insecure:
            return Color.orange.opacity(0.15)
        case .unknown:
            return Color.gray.opacity(0.1)
        }
    }
}
