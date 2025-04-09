//
//  QRBottomSheetView.swift
//  QR Unveil
//
//  Created on 4/7/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import UIKit

/// Bottom sheet view displayed when a QR code is detected
struct QRBottomSheetView: View {
    // MARK: - Properties
    
    // Environment values
    @Environment(\.dismiss) private var dismiss
    
    // Bindings to parent state
    @Binding var detectedQRCode: DetectedQRCode?
    @Binding var customLabel: String
    @Binding var saveLocation: Bool
    @Binding var selectedTags: [TagModel]
    @Binding var showTagPicker: Bool
    @Binding var showPhotoPermission: Bool
    
    // References
    @ObservedObject var cameraManager: CameraManager
    let modelContext: ModelContext
    
    // Content properties
    let safeDetectedContent: String
    let safeDetectedType: String
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // QR code icon and type with better styling
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(qrTypeColor(safeDetectedType).opacity(0.15))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: qrTypeIcon(safeDetectedType))
                                    .font(.system(size: 18))
                                    .foregroundColor(qrTypeColor(safeDetectedType))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(qrTypeTitle(safeDetectedType))
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Scanned QR Code")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            if safeDetectedType == "url" {
                                // URL security indicator
                                HStack {
                                    Spacer()
                                    
                                    HTTPSecurityIndicator(url: safeDetectedContent)
                                        .padding(.trailing)
                                }
                                .padding(.top, -8) // Adjust spacing as needed
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 6)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // QR content with better styling
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("Content")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 12))
                                    .foregroundColor(qrTypeColor(safeDetectedType))
                            }
                            
                            ActionableQRContentView(content: safeDetectedContent, type: safeDetectedType)
                                .font(.system(size: 14))
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        // Add custom label field
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("Label")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "tag.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                            
                            TextField(
                                generateLabelFromContent(detectedQRCode?.content ?? "",
                                                         type: detectedQRCode?.type ?? "text") ?? "Custom Label",
                                text: $customLabel
                            )
                            .font(.system(size: 14))
                            .padding(12)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        .padding(.top, 2)
                        
                        // Location toggle with better styling
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("Options")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "gear")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Toggle(isOn: $saveLocation) {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14))
                                    Text("Save location data")
                                        .font(.system(size: 13))
                                }
                            }
                            .disabled(!LocationManager.shared.isAuthorized)
                            .padding(12)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                            
                            // Show warning if location services are disabled
                            if !LocationManager.shared.isAuthorized {
                                Text("Location services are disabled. Enable in Settings to use this feature.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 2)
                        
                        // Tag selection with better styling and button
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("Tags")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "tag")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)
                            }
                            
                            Button {
                                // Show tag picker
                                showTagPicker = true
                            } label: {
                                HStack {
                                    if selectedTags.isEmpty {
                                        Text("Add tags")
                                            .font(.system(size: 13))
                                            .foregroundColor(.primary)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(selectedTags) { tag in
                                                    HStack(spacing: 3) {
                                                        Circle()
                                                            .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC"))
                                                            .frame(width: 6, height: 6)
                                                        Text(tag.name)
                                                            .font(.system(size: 12))
                                                        Image(systemName: "xmark")
                                                            .font(.system(size: 8))
                                                    }
                                                    .padding(.vertical, 3)
                                                    .padding(.horizontal, 6)
                                                    .background(
                                                        Capsule()
                                                            .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC").opacity(0.15))
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 2)
                        
                        Spacer(minLength: 30)
                        
                        // Action buttons with better styling
                        VStack(spacing: 12) {
                            Button(action: saveQRCode) {
                                HStack {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 14))
                                    Text("Save QR Code")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                            
                            Button {
                                // Discard and scan another
                                detectedQRCode = nil
                                customLabel = ""
                                selectedTags = []
                                cameraManager.resumeScanning()
                                // Explicitly dismiss the sheet
                                DispatchQueue.main.async {
                                    dismiss()
                                }
                            } label: {
                                Text("Scan Another")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .padding(.vertical)
                }
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showPhotoPermission) {
                photoPermissionView
            }
        }
        .onAppear {
            saveLocation = SettingsManager.shared.saveLocationData
            debugQRData()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var photoPermissionView: some View {
        PhotoPermissionView(
            onAllow: {
                // Request photo library permission
                PhotoManager.shared.requestPhotoLibraryAccess { success in
                    if success {
                        // If permission granted, save the image
                        if let capturedImage = cameraManager.capturedImage {
                            saveQRCodeWithImage(capturedImage)
                        }
                    } else {
                        // User denied, proceed without image
                        saveQRCodeWithoutImage()
                    }
                    showPhotoPermission = false
                }
            },
            onDeny: {
                // Proceed without saving image
                saveQRCodeWithoutImage()
                showPhotoPermission = false
            }
        )
    }
    
    // MARK: - Helper Methods
    
    private func debugQRData() {
        print("Debug QR Data:")
        print("- detectedQRCode?.content: \(detectedQRCode?.content ?? "nil")")
        print("- detectedQRCode?.type: \(detectedQRCode?.type ?? "nil")")
        print("- cameraManager.qrCodeString: \(cameraManager.qrCodeString ?? "nil")")
        print("- safeDetectedContent: \(safeDetectedContent)")
        print("- safeDetectedType: \(safeDetectedType)")
    }
    
    /// Saves the detected QR code to database
    private func saveQRCode() {
        guard let qrCode = detectedQRCode, !qrCode.content.isEmpty else { return }
        
        // Check if we have a captured image to save
        guard let capturedImage = cameraManager.capturedImage else {
            saveQRCodeWithoutImage()
            return
        }
        
        // Check current photo library authorization status
        switch PhotoManager.shared.authorizationStatus {
        case .authorized, .limited:
            // Directly save the image
            saveQRCodeWithImage(capturedImage)
            
        case .notDetermined:
            // Request permission and show sheet
            showPhotoPermission = true
            
        case .denied, .restricted:
            // Proceed without image, optionally show a warning
            saveQRCodeWithoutImage()
            
        @unknown default:
            saveQRCodeWithoutImage()
        }
    }
    
    /// Saves QR code with image after photo library permission is granted
    private func saveQRCodeWithImage(_ image: UIImage) {
        guard let qrCode = detectedQRCode, !qrCode.content.isEmpty else { return }
        
        // Capture these values before async operations
        let saveLocationValue = saveLocation && LocationManager.shared.isAuthorized
        let currentLocation = saveLocationValue ? cameraManager.currentLocation : nil
        let customLabelValue = customLabel.isEmpty
        ? generateLabelFromContent(qrCode.content, type: qrCode.type)
        : customLabel
        let selectedTagsCopy = selectedTags
        
        do {
            // Save to database first
            let savedCode = try QRDataManager.shared.saveQRCode(
                content: qrCode.content,
                label: customLabelValue,
                location: saveLocationValue ? currentLocation : nil
            )
            
            // Add selected tags if any
            for tag in selectedTagsCopy {
                savedCode.addTag(tag)
            }
            
            // Check photo library authorization status
            switch PhotoManager.shared.authorizationStatus {
            case .authorized, .limited:
                // Proceed with saving image
                PhotoManager.shared.saveQRCodeImage(image, qrCodeId: savedCode.id) { success, error in
                    DispatchQueue.main.async {
                        if success, let assetId = PhotoManager.shared.lastSavedImageId {
                            do {
                                savedCode.updatePhotoAssetId(assetId)
                                try self.modelContext.save()
                            } catch {
                                print("Error updating QR code with photo asset ID: \(error.localizedDescription)")
                            }
                        } else if let error = error {
                            print("Error saving QR code image: \(error.localizedDescription)")
                        }
                        
                        // Always finalize
                        self.finalizeQRCodeSave()
                    }
                }
                
            case .notDetermined:
                // Request authorization
                PhotoManager.shared.requestPhotoLibraryAccess { success in
                    DispatchQueue.main.async {
                        if success {
                            // Try saving image again
                            PhotoManager.shared.saveQRCodeImage(image, qrCodeId: savedCode.id) { success, error in
                                if success, let assetId = PhotoManager.shared.lastSavedImageId {
                                    do {
                                        savedCode.updatePhotoAssetId(assetId)
                                        try self.modelContext.save()
                                    } catch {
                                        print("Error updating QR code with photo asset ID: \(error.localizedDescription)")
                                    }
                                } else if let error = error {
                                    print("Error saving QR code image: \(error.localizedDescription)")
                                }
                                
                                // Always finalize
                                self.finalizeQRCodeSave()
                            }
                        } else {
                            // Authorization denied, proceed without image
                            self.finalizeQRCodeSave()
                        }
                    }
                }
                
            case .denied, .restricted:
                // Cannot save image, just finalize
                finalizeQRCodeSave()
                
            @unknown default:
                finalizeQRCodeSave()
            }
        } catch {
            print("Error saving QR code: \(error.localizedDescription)")
            finalizeQRCodeSave()
        }
    }
    
    /// Saves QR code without an image
    private func saveQRCodeWithoutImage() {
        guard let qrCode = detectedQRCode, !qrCode.content.isEmpty else { return }
        
        do {
            // Get current location if enabled
            let location = saveLocation && LocationManager.shared.isAuthorized ? cameraManager.currentLocation : nil
            
            // Use custom label if provided, otherwise use generated label
            let finalLabel = customLabel.isEmpty
            ? generateLabelFromContent(qrCode.content, type: qrCode.type)
            : customLabel
            
            // Save to database
            let savedCode = try QRDataManager.shared.saveQRCode(
                content: qrCode.content,
                label: finalLabel,
                location: location
            )
            
            // Add selected tags if any
            for tag in selectedTags {
                savedCode.addTag(tag)
            }
            
            // Finalize and reset
            finalizeQRCodeSave()
        } catch {
            print("Error saving QR code: \(error.localizedDescription)")
        }
    }
    
    /// Common finalization steps for QR code save
    private func finalizeQRCodeSave() {
        // Add security verification before finalizing
        if let qrCode = detectedQRCode, !qrCode.content.isEmpty {
            do {
                // Get the content string directly
                let contentString = qrCode.content
                
                // Use the content string in the predicate
                let descriptor = FetchDescriptor<QRCodeModel>(
                    predicate: #Predicate<QRCodeModel> { code in
                        code.content == contentString
                    }
                )
                
                let savedCodes = try modelContext.fetch(descriptor)
                
                // Get the most recently created QR code with this content
                guard let savedCode = savedCodes.sorted(by: { $0.createdAt > $1.createdAt }).first else {
                    print("Could not find the saved QR code")
                    return
                }
                
                // Add security verification if not already present
                if savedCode.securityVerification == nil {
                    let verification = SecurityVerificationModel(qrCode: savedCode)
                    
                    // Set initial security score
                    verification.securityScore = 80 // Default good score
                    verification.isVerified = true
                    verification.verificationDate = Date()
                    
                    // For URLs, verify HTTPS
                    if qrCode.type == "url", let url = URL(string: contentString) {
                        verification.isHttps = url.scheme?.lowercased() == "https"
                        
                        // If not HTTPS, reduce security score and set as suspicious
                        if verification.isHttps == false {
                            verification.securityScore -= 30
                            verification.threatLevel = SecurityVerificationModel.ThreatLevel.suspicious
                            
                            // Add warning about HTTP
                            verification.securityWarnings = ["This URL uses unencrypted HTTP instead of HTTPS"]
                            verification.securityRecommendations = ["Consider only visiting websites that use HTTPS encryption"]
                        } else {
                            verification.threatLevel = SecurityVerificationModel.ThreatLevel.safe
                        }
                    }
                    
                    savedCode.securityVerification = verification
                    
                    // Save the updated model
                    try modelContext.save()
                }
            } catch {
                print("Error updating security verification: \(error.localizedDescription)")
            }
        }
        
        // Provide feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Clear state
        detectedQRCode = nil
        customLabel = ""
        selectedTags = []
        
        // IMPORTANT: Ensure we dismiss first, then resume scanning
        // to prevent incorrect calles
        
        // Explicitly dismiss the sheet
        DispatchQueue.main.async {
            cameraManager.resumeScanning()
            dismiss()
        }
    }
    
    /// Generates a label based on QR code content and type
    private func generateLabelFromContent(_ content: String, type: String) -> String? {
        switch type {
        case "url":
            if let url = URL(string: content), let host = url.host {
                return host
            }
            return "Website"
        case "phone":
            return "Phone Number"
        case "email":
            return "Email Address"
        case "wifi":
            if let ssidRange = content.range(of: "S:") {
                let startIndex = content.index(ssidRange.upperBound, offsetBy: 0)
                if let endIndex = content.range(of: ";", range: startIndex..<content.endIndex)?.lowerBound {
                    return "WiFi: \(content[startIndex..<endIndex])"
                }
            }
            return "WiFi Network"
        case "vcard":
            return "Contact Card"
        case "location":
            return "Location"
        case "sms":
            return "SMS Message"
        default:
            return nil
        }
    }
    
    /// Returns an icon name for the given QR code type
    private func qrTypeIcon(_ type: String) -> String {
        switch type {
        case "url": return "link"
        case "phone": return "phone.fill"
        case "email": return "envelope.fill"
        case "wifi": return "wifi"
        case "vcard": return "person.crop.square.fill"
        case "location": return "mappin.and.ellipse"
        case "sms": return "message.fill"
        default: return "doc.text.fill"
        }
    }
    
    /// Returns a color for the given QR code type
    private func qrTypeColor(_ type: String) -> Color {
        switch type {
        case "url": return .blue
        case "phone": return .green
        case "email": return .purple
        case "wifi": return .orange
        case "vcard": return .indigo
        case "location": return .red
        case "sms": return .pink
        default: return .gray
        }
    }
    
    /// Returns a title for the given QR code type
    private func qrTypeTitle(_ type: String) -> String {
        switch type {
        case "url": return "Website URL"
        case "phone": return "Phone Number"
        case "email": return "Email Address"
        case "wifi": return "WiFi Network"
        case "vcard": return "Contact Card"
        case "location": return "Geographic Location"
        case "sms": return "Text Message"
        default: return "Plain Text"
        }
    }
}
