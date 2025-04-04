//
//  SecurityVerificationModel.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import Foundation
import SwiftData

@Model
final class SecurityVerificationModel: Codable {
    
    var id: UUID = UUID()
    
    var qrCode: QRCodeModel?
    
    // Verification Status
    var isVerified: Bool = false
    var verificationDate: Date?
    var securityScore: Int = 0 // 0-100 scale
    var threatLevel: ThreatLevel = SecurityVerificationModel.ThreatLevel.unknown
    
    // Common Verification Results
    var isKnownMalicious: Bool?
    var isFormattedCorrectly: Bool?
    
    // URL-specific checks
    var isHttps: Bool?
    var hasSslIssues: Bool?
    var isDomainSuspicious: Bool?
    var domainAge: Int? // Days
    var redirectsCount: Int?
    var finalDestination: String?
    
    // Phone/SMS-specific checks
    var phoneCountryCode: String?
    var isPremiumRate: Bool?
    var isKnownSpamNumber: Bool?
    
    // Email-specific checks
    var emailDomainReputation: String?
    var isDisposableEmail: Bool?
    
    // WiFi-specific checks
    var securityType: String? // WPA, WEP, Open
    var isOpenNetwork: Bool?
    
    // vCard-specific checks
    var containsSuspiciousFields: Bool?
    
    // Location-specific checks
    var isValidCoordinate: Bool?
    var isRestrictedArea: Bool?
    
    // Additional Information
    var securityWarnings: [String]?
    var securityRecommendations: [String]?
    var verificationServiceProvider: String?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum ThreatLevel: String, Codable {
        case safe = "safe"
        case lowRisk = "low_risk"
        case suspicious = "suspicious"
        case dangerous = "dangerous"
        case unknown = "unknown"
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case qrCode = "qr_code"
        case isVerified = "is_verified"
        case verificationDate = "verification_date"
        case securityScore = "security_score"
        case threatLevel = "threat_level"
        case isKnownMalicious = "is_known_malicious"
        case isFormattedCorrectly = "is_formatted_correctly"
        case isHttps = "is_https"
        case hasSslIssues = "has_ssl_issues"
        case isDomainSuspicious = "is_domain_suspicious"
        case domainAge = "domain_age"
        case redirectsCount = "redirects_count"
        case finalDestination = "final_destination"
        case phoneCountryCode = "phone_country_code"
        case isPremiumRate = "is_premium_rate"
        case isKnownSpamNumber = "is_known_spam_number"
        case emailDomainReputation = "email_domain_reputation"
        case isDisposableEmail = "is_disposable_email"
        case securityType = "security_type"
        case isOpenNetwork = "is_open_network"
        case containsSuspiciousFields = "contains_suspicious_fields"
        case isValidCoordinate = "is_valid_coordinate"
        case isRestrictedArea = "is_restricted_area"
        case securityWarnings = "security_warnings"
        case securityRecommendations = "security_recommendations"
        case verificationServiceProvider = "verification_service_provider"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(qrCode: QRCodeModel) {
        self.id = UUID()
        self.qrCode = qrCode
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        qrCode = try container.decodeIfPresent(QRCodeModel.self, forKey: .qrCode)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        verificationDate = try container.decodeIfPresent(Date.self, forKey: .verificationDate)
        securityScore = try container.decode(Int.self, forKey: .securityScore)
        threatLevel = try container.decode(ThreatLevel.self, forKey: .threatLevel)
        
        isKnownMalicious = try container.decodeIfPresent(Bool.self, forKey: .isKnownMalicious)
        isFormattedCorrectly = try container.decodeIfPresent(Bool.self, forKey: .isFormattedCorrectly)
        
        // URL-specific
        isHttps = try container.decodeIfPresent(Bool.self, forKey: .isHttps)
        hasSslIssues = try container.decodeIfPresent(Bool.self, forKey: .hasSslIssues)
        isDomainSuspicious = try container.decodeIfPresent(Bool.self, forKey: .isDomainSuspicious)
        domainAge = try container.decodeIfPresent(Int.self, forKey: .domainAge)
        redirectsCount = try container.decodeIfPresent(Int.self, forKey: .redirectsCount)
        finalDestination = try container.decodeIfPresent(String.self, forKey: .finalDestination)
        
        // Phone/SMS-specific
        phoneCountryCode = try container.decodeIfPresent(String.self, forKey: .phoneCountryCode)
        isPremiumRate = try container.decodeIfPresent(Bool.self, forKey: .isPremiumRate)
        isKnownSpamNumber = try container.decodeIfPresent(Bool.self, forKey: .isKnownSpamNumber)
        
        // Email-specific
        emailDomainReputation = try container.decodeIfPresent(String.self, forKey: .emailDomainReputation)
        isDisposableEmail = try container.decodeIfPresent(Bool.self, forKey: .isDisposableEmail)
        
        // WiFi-specific
        securityType = try container.decodeIfPresent(String.self, forKey: .securityType)
        isOpenNetwork = try container.decodeIfPresent(Bool.self, forKey: .isOpenNetwork)
        
        // vCard-specific
        containsSuspiciousFields = try container.decodeIfPresent(Bool.self, forKey: .containsSuspiciousFields)
        
        // Location-specific
        isValidCoordinate = try container.decodeIfPresent(Bool.self, forKey: .isValidCoordinate)
        isRestrictedArea = try container.decodeIfPresent(Bool.self, forKey: .isRestrictedArea)
        
        // Additional info
        securityWarnings = try container.decodeIfPresent([String].self, forKey: .securityWarnings)
        securityRecommendations = try container.decodeIfPresent([String].self, forKey: .securityRecommendations)
        verificationServiceProvider = try container.decodeIfPresent(String.self, forKey: .verificationServiceProvider)
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(qrCode, forKey: .qrCode)
        try container.encode(isVerified, forKey: .isVerified)
        try container.encodeIfPresent(verificationDate, forKey: .verificationDate)
        try container.encode(securityScore, forKey: .securityScore)
        try container.encode(threatLevel, forKey: .threatLevel)
        
        try container.encodeIfPresent(isKnownMalicious, forKey: .isKnownMalicious)
        try container.encodeIfPresent(isFormattedCorrectly, forKey: .isFormattedCorrectly)
        
        // URL-specific
        try container.encodeIfPresent(isHttps, forKey: .isHttps)
        try container.encodeIfPresent(hasSslIssues, forKey: .hasSslIssues)
        try container.encodeIfPresent(isDomainSuspicious, forKey: .isDomainSuspicious)
        try container.encodeIfPresent(domainAge, forKey: .domainAge)
        try container.encodeIfPresent(redirectsCount, forKey: .redirectsCount)
        try container.encodeIfPresent(finalDestination, forKey: .finalDestination)
        
        // Phone/SMS-specific
        try container.encodeIfPresent(phoneCountryCode, forKey: .phoneCountryCode)
        try container.encodeIfPresent(isPremiumRate, forKey: .isPremiumRate)
        try container.encodeIfPresent(isKnownSpamNumber, forKey: .isKnownSpamNumber)
        
        // Email-specific
        try container.encodeIfPresent(emailDomainReputation, forKey: .emailDomainReputation)
        try container.encodeIfPresent(isDisposableEmail, forKey: .isDisposableEmail)
        
        // WiFi-specific
        try container.encodeIfPresent(securityType, forKey: .securityType)
        try container.encodeIfPresent(isOpenNetwork, forKey: .isOpenNetwork)
        
        // vCard-specific
        try container.encodeIfPresent(containsSuspiciousFields, forKey: .containsSuspiciousFields)
        
        // Location-specific
        try container.encodeIfPresent(isValidCoordinate, forKey: .isValidCoordinate)
        try container.encodeIfPresent(isRestrictedArea, forKey: .isRestrictedArea)
        
        // Additional info
        try container.encodeIfPresent(securityWarnings, forKey: .securityWarnings)
        try container.encodeIfPresent(securityRecommendations, forKey: .securityRecommendations)
        try container.encodeIfPresent(verificationServiceProvider, forKey: .verificationServiceProvider)
        
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    
    /// Updates the verification results based on QR code type
    func updateVerification(results: SecurityVerificationResults) {
        self.isVerified = true
        self.verificationDate = Date()
        self.securityScore = results.securityScore
        self.threatLevel = results.threatLevel
        
        // Common fields
        self.isKnownMalicious = results.isKnownMalicious
        self.isFormattedCorrectly = results.isFormattedCorrectly
        
        // Type-specific fields
        if let urlResults = results.urlResults {
            self.isHttps = urlResults.isHttps
            self.hasSslIssues = urlResults.hasSslIssues
            self.isDomainSuspicious = urlResults.isDomainSuspicious
            self.domainAge = urlResults.domainAge
            self.redirectsCount = urlResults.redirectsCount
            self.finalDestination = urlResults.finalDestination
        }
        
        if let phoneResults = results.phoneResults {
            self.phoneCountryCode = phoneResults.countryCode
            self.isPremiumRate = phoneResults.isPremiumRate
            self.isKnownSpamNumber = phoneResults.isKnownSpamNumber
        }
        
        if let emailResults = results.emailResults {
            self.emailDomainReputation = emailResults.domainReputation
            self.isDisposableEmail = emailResults.isDisposableEmail
        }
        
        if let wifiResults = results.wifiResults {
            self.securityType = wifiResults.securityType
            self.isOpenNetwork = wifiResults.isOpenNetwork
        }
        
        if let vcardResults = results.vcardResults {
            self.containsSuspiciousFields = vcardResults.containsSuspiciousFields
        }
        
        if let locationResults = results.locationResults {
            self.isValidCoordinate = locationResults.isValidCoordinate
            self.isRestrictedArea = locationResults.isRestrictedArea
        }
        
        // Additional info
        self.securityWarnings = results.securityWarnings
        self.securityRecommendations = results.securityRecommendations
        self.verificationServiceProvider = results.verificationServiceProvider
        
        self.updatedAt = Date()
    }
    
    /// Reset verification status to unknown
    func resetVerification() {
        self.isVerified = false
        self.verificationDate = nil
        self.securityScore = 0
        self.threatLevel = .unknown
        self.updatedAt = Date()
    }
    
    /// Determines if the verification is stale (older than a certain time period)
    func isVerificationStale(staleThresholdDays: Int = 7) -> Bool {
        guard let verificationDate = verificationDate else {
            return true
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: verificationDate, to: now)
        
        return (components.day ?? 0) >= staleThresholdDays
    }
    
    /// Returns a user-friendly summary of the security verification
    func securitySummary() -> String {
        if !isVerified {
            return "Not verified yet"
        }
        
        switch threatLevel {
        case .safe:
            return "Safe to use (Score: \(securityScore)/100)"
        case .lowRisk:
            return "Low risk - Proceed with awareness (Score: \(securityScore)/100)"
        case .suspicious:
            return "Suspicious - Use with caution (Score: \(securityScore)/100)"
        case .dangerous:
            return "Dangerous - Not recommended (Score: \(securityScore)/100)"
        case .unknown:
            return "Security status unknown"
        }
    }
    
    /// Returns security warnings tailored to QR code type
    func getTypeSpecificWarnings() -> [String] {
        guard let qrType = qrCode?.qrType else {
            return []
        }
        
        var warnings: [String] = []
        
        switch qrType {
        case "url":
            if let isHttps = isHttps, !isHttps {
                warnings.append("This URL uses an unencrypted HTTP connection")
            }
            if let hasSslIssues = hasSslIssues, hasSslIssues {
                warnings.append("This website has SSL certificate issues")
            }
            if let isDomainSuspicious = isDomainSuspicious, isDomainSuspicious {
                warnings.append("This domain has been flagged as potentially suspicious")
            }
            
        case "phone", "sms":
            if let isPremiumRate = isPremiumRate, isPremiumRate {
                warnings.append("This appears to be a premium rate number which may incur charges")
            }
            if let isKnownSpamNumber = isKnownSpamNumber, isKnownSpamNumber {
                warnings.append("This number has been reported as spam or scam")
            }
            
        case "email":
            if let isDisposableEmail = isDisposableEmail, isDisposableEmail {
                warnings.append("This email uses a disposable/temporary email service")
            }
            
        case "wifi":
            if let isOpenNetwork = isOpenNetwork, isOpenNetwork {
                warnings.append("This is an open WiFi network with no encryption")
            }
            
        default:
            break
        }
        
        if let additionalWarnings = securityWarnings {
            warnings.append(contentsOf: additionalWarnings)
        }
        
        return warnings
    }
}

// MARK: - Supporting Structures

/// Results structure for security verification
struct SecurityVerificationResults {
    var securityScore: Int
    var threatLevel: SecurityVerificationModel.ThreatLevel
    var isKnownMalicious: Bool?
    var isFormattedCorrectly: Bool?
    
    var urlResults: URLVerificationResults?
    var phoneResults: PhoneVerificationResults?
    var emailResults: EmailVerificationResults?
    var wifiResults: WiFiVerificationResults?
    var vcardResults: VCardVerificationResults?
    var locationResults: LocationVerificationResults?
    
    var securityWarnings: [String]?
    var securityRecommendations: [String]?
    var verificationServiceProvider: String?
}

struct URLVerificationResults {
    var isHttps: Bool
    var hasSslIssues: Bool
    var isDomainSuspicious: Bool
    var domainAge: Int?
    var redirectsCount: Int?
    var finalDestination: String?
}

struct PhoneVerificationResults {
    var countryCode: String?
    var isPremiumRate: Bool
    var isKnownSpamNumber: Bool
}

struct EmailVerificationResults {
    var domainReputation: String?
    var isDisposableEmail: Bool
}

struct WiFiVerificationResults {
    var securityType: String
    var isOpenNetwork: Bool
}

struct VCardVerificationResults {
    var containsSuspiciousFields: Bool
}

struct LocationVerificationResults {
    var isValidCoordinate: Bool
    var isRestrictedArea: Bool
}
