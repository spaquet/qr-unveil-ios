//
//  QRDetailSecuritySection.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/9/25.
//

import SwiftUI
import SwiftData

struct QRDetailSecuritySection: View {
    let qrCode: QRCodeModel
    @State private var isCopyPressed = false
    @State private var isOpenPressed = false
    
    var body: some View {
        Section("Info Sec") {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "shield")
                        .font(.title2)
                        .foregroundColor(securityColor)
                    
                    Text(NSLocalizedString("Security Information", comment: "Security section title"))
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(securityScoreText)
                        .font(.caption.weight(.semibold))  // Smaller font size
                        .padding(.horizontal, 6)           // Reduced horizontal padding
                        .padding(.vertical, 3)             // Reduced vertical padding
                        .background(securityScoreBackground)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                // Security content
                if let verification = qrCode.securityVerification {
                    switch qrCode.qrType {
                    case "url":
                        // HTTPS status
                        if let isHttps = verification.isHttps {
                            HStack(spacing: 12) {
                                Image(systemName: isHttps ? "lock.fill" : "lock.open.fill")
                                    .foregroundColor(isHttps ? .green : .orange)
                                
                                Text(isHttps ?
                                     NSLocalizedString("Secure HTTPS connection", comment: "HTTPS secure message") :
                                        NSLocalizedString("Unencrypted HTTP connection", comment: "HTTP insecure message"))
                                .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // SSL issues
                        if let hasSslIssues = verification.hasSslIssues, hasSslIssues {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.red)
                                
                                Text(NSLocalizedString("SSL certificate issues detected", comment: "SSL issues message"))
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Redirects
                        if let redirects = verification.redirectsCount, redirects > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .foregroundColor(.blue)
                                    
                                    Text(String(format: NSLocalizedString("Redirects: %d", comment: "Redirect count"), redirects))
                                        .font(.subheadline)
                                }
                                
                                if let finalDestination = verification.finalDestination {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(NSLocalizedString("Final destination:", comment: "Final URL label"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(finalDestination)
                                            .font(.callout.monospaced())
                                            .lineLimit(2)
                                            .padding(10)
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(8)
                                        
                                        // Action buttons for final URL
                                        HStack(spacing: 12) {  // Consistent spacing between buttons
                                            Button {
                                                UIPasteboard.general.string = finalDestination
                                                withAnimation {
                                                    isCopyPressed = true
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    withAnimation {
                                                        isCopyPressed = false
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 4) {  // Consistent internal spacing
                                                    Image(systemName: isCopyPressed ? "doc.on.doc.fill" : "doc.on.doc")
                                                        .font(.system(size: 10))  // Consistent icon size
                                                    Text(NSLocalizedString("Copy", comment: "Copy URL button"))
                                                        .font(.system(size: 11))  // Consistent text size
                                                }
                                                .padding(.horizontal, 8)  // Consistent horizontal padding
                                                .padding(.vertical, 4)    // Consistent vertical padding
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.secondary)
                                            .controlSize(.mini)  // Using mini for more compact appearance
                                            
                                            Button {
                                                if let url = URL(string: finalDestination) {
                                                    UIApplication.shared.open(url)
                                                    withAnimation {
                                                        isOpenPressed = true
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                        withAnimation {
                                                            isOpenPressed = false
                                                        }
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 4) {  // Consistent internal spacing
                                                    Image(systemName: isOpenPressed ? "safari.fill" : "safari")
                                                        .font(.system(size: 10))  // Consistent icon size
                                                    Text(NSLocalizedString("Open", comment: "Open URL button"))
                                                        .font(.system(size: 11))  // Consistent text size
                                                }
                                                .padding(.horizontal, 8)  // Consistent horizontal padding
                                                .padding(.vertical, 4)    // Consistent vertical padding
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.blue)
                                            .controlSize(.mini)  // Using mini for more compact appearance
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                    case "email":
                        // Disposable Email status
                        if let isDisposableEmail = verification.isDisposableEmail {
                            HStack(spacing: 12) {
                                Image(systemName: isDisposableEmail ? "exclamationmark.triangle.fill" : "envelope.fill")
                                    .foregroundColor(isDisposableEmail ? .orange : .green)
                                
                                Text(isDisposableEmail ?
                                     NSLocalizedString("Disposable email detected", comment: "Disposable email message") :
                                        NSLocalizedString("Regular email domain", comment: "Regular email message"))
                                .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Domain reputation
                        if let reputation = verification.emailDomainReputation {
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(reputation.lowercased() == "low" ? .orange : .green)
                                
                                Text(String(format: NSLocalizedString("Domain reputation: %@", comment: "Email domain reputation"), reputation))
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Extract email domain for display
                        if let emailContent = qrCode.content.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines),
                           let domain = emailContent.components(separatedBy: "@").last {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString("Domain:", comment: "Email domain label"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(domain)
                                    .font(.callout.monospaced())
                                    .padding(10)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            .padding(.vertical, 8)
                        }
                        
                    case "phone", "sms":
                        // Phone security content (future)
                        Text("Phone number security verification")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                        
                    case "wifi":
                        // WiFi security content (future)
                        Text("WiFi security verification")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                        
                    default:
                        Text(NSLocalizedString("No security information available for this type", comment: "No security info message"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    // Common sections for all types
                    // Warnings
                    if let warnings = verification.securityWarnings, !warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("Warnings:", comment: "Security warnings header"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(warnings, id: \.self) { warning in
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    
                                    Text(warning)
                                        .font(.caption2)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Recommendations
                    if let recommendations = verification.securityRecommendations, !recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("Recommendations:", comment: "Security recommendations header"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(recommendations, id: \.self) { recommendation in
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    
                                    Text(recommendation)
                                        .font(.caption2)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text(NSLocalizedString("No security information available", comment: "No security info message"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // Computed properties for styling
    private var securityScore: Int {
        qrCode.securityVerification?.securityScore ?? 0
    }
    
    private var securityScoreText: String {
        switch securityScore {
        case 80...100:
            return NSLocalizedString("Safe", comment: "Safe security rating")
        case 60..<80:
            return NSLocalizedString("Low Risk", comment: "Low risk security rating")
        case 40..<60:
            return NSLocalizedString("Moderate", comment: "Moderate security rating")
        case 20..<40:
            return NSLocalizedString("High Risk", comment: "High risk security rating")
        default:
            return NSLocalizedString("Unsafe", comment: "Unsafe security rating")
        }
    }
    
    private var securityColor: Color {
        switch securityScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
    
    private var securityScoreBackground: Color {
        switch securityScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

// Preview for QRDetailSecuritySection
#Preview {
    List {
        QRDetailSecuritySection(qrCode: createSampleQRCodeWithSecurity())
    }
    .listStyle(InsetGroupedListStyle())
}

// Helper function to create a sample QR code with security verification
private func createSampleQRCodeWithSecurity() -> QRCodeModel {
    let qrCode = QRCodeModel(
        label: "Example Website",
        content: "https://www.example.com",
        qrType: "url"
    )
    
    // Create and set up security verification
    let verification = SecurityVerificationModel(qrCode: qrCode)
    verification.isVerified = true
    verification.verificationDate = Date()
    verification.securityScore = 65
    verification.threatLevel = .lowRisk
    verification.isHttps = true
    verification.hasSslIssues = false
    verification.redirectsCount = 2
    verification.finalDestination = "https://www.example.org/landing-page"
    verification.securityWarnings = [
        "This URL redirects to a different domain",
        "Domain was registered less than 1 month ago"
    ]
    verification.securityRecommendations = [
        "Verify this is the website you intended to visit",
        "Consider using a trusted bookmark instead"
    ]
    
    qrCode.securityVerification = verification
    
    return qrCode
}
