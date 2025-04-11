//
//  EmailSecurityIndicator.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/11/25.
//

import SwiftUI

struct EmailSecurityIndicator: View {
    enum SecurityStatus {
        case normal      // Regular email domain
        case disposable  // Disposable/temporary email
        case unknown     // Not verified or couldn't determine
    }
    
    let status: SecurityStatus
    let showText: Bool
    
    init(isDisposable: Bool?, showText: Bool = true) {
        if let isDisposable = isDisposable {
            self.status = isDisposable ? .disposable : .normal
        } else {
            self.status = .unknown
        }
        
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
        case .normal:
            return "envelope.fill"
        case .disposable:
            return "exclamationmark.triangle"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case .normal:
            return .green
        case .disposable:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .normal:
            return "Normal"
        case .disposable:
            return "Disposable"
        case .unknown:
            return "Unknown"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .normal:
            return Color.green.opacity(0.15)
        case .disposable:
            return Color.orange.opacity(0.15)
        case .unknown:
            return Color.gray.opacity(0.1)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EmailSecurityIndicator(isDisposable: true)
        EmailSecurityIndicator(isDisposable: false)
        EmailSecurityIndicator(isDisposable: nil)
    }
    .padding()
}
