//
//  QRCodeActionHandler.swift
//  QR Unveil
//
//  Created on 4/4/25.
//

import SwiftUI
import UIKit
import MessageUI
import ContactsUI
import SystemConfiguration.CaptiveNetwork
import Network

/// Handles actions for different QR code types
class QRCodeActionHandler {
    
    /// Enum defining different QR code types and their associated actions
    enum QRAction {
        case openURL(URL)
        case connectWiFi(ssid: String, password: String, isWPA: Bool)
        case addContact(String) // vCard data
        case sendSMS(to: String, body: String?)
        case callPhone(String)
        case sendEmail(to: String, subject: String?, body: String?)
        case none // For text or unsupported types
    }
    
    /// Determines the appropriate action for a QR code content
    /// - Parameters:
    ///   - content: The QR code content string
    ///   - type: The detected QR code type
    /// - Returns: The appropriate QRAction to take
    static func actionFor(content: String, type: String) -> QRAction {
        switch type {
        case "url":
            if let url = URL(string: content), UIApplication.shared.canOpenURL(url) {
                return .openURL(url)
            }
            
        case "wifi":
            // Parse WiFi QR code format: WIFI:S:<SSID>;T:<WPA|WEP|>;P:<password>;;
            var ssid: String = ""
            var password: String = ""
            var isWPA: Bool = true
            
            if let ssidRange = content.range(of: "S:") {
                let startIndex = content.index(ssidRange.upperBound, offsetBy: 0)
                if let endIndex = content.range(of: ";", range: startIndex..<content.endIndex)?.lowerBound {
                    ssid = String(content[startIndex..<endIndex])
                }
            }
            
            if let passwordRange = content.range(of: "P:") {
                let startIndex = content.index(passwordRange.upperBound, offsetBy: 0)
                if let endIndex = content.range(of: ";", range: startIndex..<content.endIndex)?.lowerBound {
                    password = String(content[startIndex..<endIndex])
                }
            }
            
            if let typeRange = content.range(of: "T:") {
                let startIndex = content.index(typeRange.upperBound, offsetBy: 0)
                if let endIndex = content.range(of: ";", range: startIndex..<content.endIndex)?.lowerBound {
                    let encryptionType = String(content[startIndex..<endIndex])
                    isWPA = encryptionType.uppercased() == "WPA" || encryptionType.uppercased() == "WPA2"
                }
            }
            
            if !ssid.isEmpty {
                return .connectWiFi(ssid: ssid, password: password, isWPA: isWPA)
            }
            
        case "vcard":
            return .addContact(content)
            
        case "sms":
            // Parse SMS format: SMSTO:<phone>:<message>
            var phoneNumber: String = ""
            var message: String? = nil
            
            if content.hasPrefix("SMSTO:") || content.hasPrefix("sms:") {
                let parts = content.split(separator: ":", maxSplits: 2)
                if parts.count >= 2 {
                    phoneNumber = String(parts[1])
                    if parts.count >= 3 {
                        message = String(parts[2])
                    }
                }
            }
            
            if !phoneNumber.isEmpty {
                return .sendSMS(to: phoneNumber, body: message)
            }
            
        case "phone":
            // Extract just the phone number, removing any formatting
            let phoneNumber = content.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            if !phoneNumber.isEmpty {
                return .callPhone(phoneNumber)
            }
            
        case "email":
            // Parse email format: mailto:email@example.com?subject=Subject&body=Body
            var emailAddress: String = ""
            var subject: String? = nil
            var body: String? = nil
            
            if content.hasPrefix("mailto:") {
                let contentWithoutPrefix = content.replacingOccurrences(of: "mailto:", with: "")
                
                // Split the content into address and parameters
                let components = contentWithoutPrefix.components(separatedBy: "?")
                if components.count > 0 {
                    emailAddress = components[0]
                    
                    // Parse parameters if they exist
                    if components.count > 1 {
                        let paramString = components[1]
                        let params = paramString.components(separatedBy: "&")
                        
                        for param in params {
                            let keyValue = param.components(separatedBy: "=")
                            if keyValue.count == 2 {
                                let key = keyValue[0]
                                let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                                
                                if key == "subject" {
                                    subject = value
                                } else if key == "body" {
                                    body = value
                                }
                            }
                        }
                    }
                }
            }
            
            if !emailAddress.isEmpty {
                return .sendEmail(to: emailAddress, subject: subject, body: body)
            }
            
        default:
            break
        }
        
        return .none
    }
    
    /// Performs the appropriate action for a QR code
    /// - Parameters:
    ///   - content: The QR code content
    ///   - type: The detected QR code type
    ///   - viewController: The view controller to present from
    static func performAction(for content: String, type: String, from viewController: UIViewController) {
        let action = actionFor(content: content, type: type)
        
        switch action {
        case .openURL(let url):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
        case .connectWiFi(let ssid, let password, _):
            // iOS doesn't provide a public API for connecting to WiFi networks
            // We'll show an action sheet with instructions
            let alert = UIAlertController(
                title: "Connect to WiFi",
                message: "SSID: \(ssid)\nPassword: \(password)\n\nWould you like to connect to this network?",
                preferredStyle: .actionSheet
            )
            
            alert.addAction(UIAlertAction(title: "Copy Password", style: .default) { _ in
                UIPasteboard.general.string = password
                
                // Show a confirmation toast
                let successAlert = UIAlertController(
                    title: "Password Copied",
                    message: "WiFi password has been copied to clipboard.",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                viewController.present(successAlert, animated: true)
            })
            
            // Add action to go to WiFi settings
            alert.addAction(UIAlertAction(title: "Open WiFi Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // For iPad support
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            viewController.present(alert, animated: true)
            
        case .addContact(let vCardData):
            // We'll show an action sheet with options to add contact
            let alert = UIAlertController(
                title: "Add Contact",
                message: "Would you like to add this contact to your address book?",
                preferredStyle: .actionSheet
            )
            
            alert.addAction(UIAlertAction(title: "Add Contact", style: .default) { _ in
                // Convert vCard data to a contact and present the contact view controller
                if vCardData.data(using: .utf8) != nil {
                    // Create a CNContact from vCard data
                    // This requires a more complex implementation with CNContactVCardSerialization
                    // For now, we'll just open Contacts app
                    if let contactsURL = URL(string: "contacts://") {
                        UIApplication.shared.open(contactsURL, options: [:], completionHandler: nil)
                    }
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // For iPad support
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            viewController.present(alert, animated: true)
            
        case .sendSMS(let phoneNumber, let body):
            // Show action sheet with messaging options
            let alert = UIAlertController(
                title: "Send Message",
                message: "How would you like to send a message to \(phoneNumber)?",
                preferredStyle: .actionSheet
            )
            
            // SMS option
            if MFMessageComposeViewController.canSendText() {
                alert.addAction(UIAlertAction(title: "Messages", style: .default) { _ in
                    let messageVC = MFMessageComposeViewController()
                    messageVC.body = body
                    messageVC.recipients = [phoneNumber]
                    messageVC.messageComposeDelegate = MessageDelegate.shared
                    
                    viewController.present(messageVC, animated: true)
                })
            }
            
            // WhatsApp option
            let whatsappURL = URL(string: "whatsapp://send?phone=\(phoneNumber)&text=\(body ?? "")")
            if let url = whatsappURL, UIApplication.shared.canOpenURL(url) {
                alert.addAction(UIAlertAction(title: "WhatsApp", style: .default) { _ in
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                })
            }
            
            // Copy number option
            alert.addAction(UIAlertAction(title: "Copy Number", style: .default) { _ in
                UIPasteboard.general.string = phoneNumber
                
                // Show a confirmation toast
                let successAlert = UIAlertController(
                    title: "Number Copied",
                    message: "Phone number has been copied to clipboard.",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                viewController.present(successAlert, animated: true)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // For iPad support
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            viewController.present(alert, animated: true)
            
        case .callPhone(let phoneNumber):
            // Show action sheet with calling options
            let alert = UIAlertController(
                title: "Call \(phoneNumber)",
                message: "How would you like to call this number?",
                preferredStyle: .actionSheet
            )
            
            // Phone call option
            if let phoneURL = URL(string: "tel:\(phoneNumber)") {
                alert.addAction(UIAlertAction(title: "Call", style: .default) { _ in
                    UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
                })
            }
            
            // FaceTime option
            if let facetimeURL = URL(string: "facetime:\(phoneNumber)") {
                alert.addAction(UIAlertAction(title: "FaceTime", style: .default) { _ in
                    UIApplication.shared.open(facetimeURL, options: [:], completionHandler: nil)
                })
            }
            
            // Copy number option
            alert.addAction(UIAlertAction(title: "Copy Number", style: .default) { _ in
                UIPasteboard.general.string = phoneNumber
                
                // Show a confirmation toast
                let successAlert = UIAlertController(
                    title: "Number Copied",
                    message: "Phone number has been copied to clipboard.",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                viewController.present(successAlert, animated: true)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // For iPad support
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            viewController.present(alert, animated: true)
            
        case .sendEmail(let emailAddress, let subject, let body):
            // Show action sheet with email options
            let alert = UIAlertController(
                title: "Send Email",
                message: "Send email to \(emailAddress)",
                preferredStyle: .actionSheet
            )
            
            // Mail app option
            if MFMailComposeViewController.canSendMail() {
                alert.addAction(UIAlertAction(title: "Mail App", style: .default) { _ in
                    let mailVC = MFMailComposeViewController()
                    mailVC.setToRecipients([emailAddress])
                    if let subject = subject {
                        mailVC.setSubject(subject)
                    }
                    if let body = body {
                        mailVC.setMessageBody(body, isHTML: false)
                    }
                    mailVC.mailComposeDelegate = MailDelegate.shared
                    
                    viewController.present(mailVC, animated: true)
                })
            }
            
            // Direct mailto URL option
            var mailtoURLString = "mailto:\(emailAddress)"
            var queryItems: [String] = []
            
            if let subject = subject {
                queryItems.append("subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)")
            }
            
            if let body = body {
                queryItems.append("body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body)")
            }
            
            if !queryItems.isEmpty {
                mailtoURLString += "?" + queryItems.joined(separator: "&")
            }
            
            if let mailtoURL = URL(string: mailtoURLString) {
                alert.addAction(UIAlertAction(title: "Default Mail App", style: .default) { _ in
                    UIApplication.shared.open(mailtoURL, options: [:], completionHandler: nil)
                })
            }
            
            // Copy email address option
            alert.addAction(UIAlertAction(title: "Copy Email Address", style: .default) { _ in
                UIPasteboard.general.string = emailAddress
                
                // Show a confirmation toast
                let successAlert = UIAlertController(
                    title: "Email Copied",
                    message: "Email address has been copied to clipboard.",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                viewController.present(successAlert, animated: true)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // For iPad support
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            viewController.present(alert, animated: true)
            
        case .none:
            // No action needed for text or unsupported types
            break
        }
    }
}

// MARK: - Helper Classes

/// Delegate for handling message compose view controller
class MessageDelegate: NSObject, MFMessageComposeViewControllerDelegate {
    static let shared = MessageDelegate()
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

/// Delegate for handling mail compose view controller
class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailDelegate()
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - SwiftUI Extension for UIViewController access

extension View {
    /// Get the host UIViewController from a SwiftUI View
    func getUIViewController() -> UIViewController? {
        // Get the connected scenes
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            return rootViewController
        }
        return nil
    }
}

// MARK: - ActionableQRContentView Component

/// A reusable SwiftUI view for displaying actionable QR code content
struct ActionableQRContentView: View {
    let content: String
    let type: String
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        Button(action: {
            handleTap()
        }) {
            Text(content)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle()) // Use plain style so the text styling isn't affected
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handleTap() {
        // For types that need UIKit interaction, we need to find the current UIViewController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            let action = QRCodeActionHandler.actionFor(content: content, type: type)
            
            // For some actions, we can handle in SwiftUI
            switch action {
            case .none:
                // Show a basic alert for non-actionable content
                alertTitle = "Plain Text"
                alertMessage = "This QR code contains plain text with no actionable content."
                showAlert = true
                
            default:
                // Delegate to the UIKit handler for complex actions
                QRCodeActionHandler.performAction(for: content, type: type, from: viewController)
            }
        }
    }
}
