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
                    VStack(alignment: .leading, spacing: 20) {
                        // QR code icon and type with better styling
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(qrTypeColor(safeDetectedType).opacity(0.2))
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: qrTypeIcon(safeDetectedType))
                                    .font(.title2)
                                    .foregroundColor(qrTypeColor(safeDetectedType))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(qrTypeTitle(safeDetectedType))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Scanned QR Code")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // QR content with better styling
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Content", systemImage: "doc.text")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ActionableQRContentView(content: safeDetectedContent, type: safeDetectedType)
                                .font(.body)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // Add custom label field
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Label", systemImage: "tag.circle")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField(
                                generateLabelFromContent(detectedQRCode?.content ?? "",
                                                       type: detectedQRCode?.type ?? "text") ?? "Custom Label",
                                text: $customLabel
                            )
                            .font(.body)
                            .padding()
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // Location toggle with better styling
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Options", systemImage: "gear")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Toggle(isOn: $saveLocation) {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.headline)
                                    Text("Save location data")
                                        .font(.subheadline)
                                }
                            }
                            .disabled(!LocationManager.shared.isAuthorized)
                            .padding()
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            
                            // Show warning if location services are disabled
                            if !LocationManager.shared.isAuthorized {
                                Text("Location services are disabled. Enable in Settings to use this feature.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Tag selection with better styling and button
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Tags", systemImage: "tag")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Button {
                                // Show tag picker
                                showTagPicker = true
                            } label: {
                                HStack {
                                    if selectedTags.isEmpty {
                                        Text("Add tags")
                                            .foregroundColor(.primary)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(selectedTags) { tag in
                                                    HStack(spacing: 4) {
                                                        Circle()
                                                            .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC"))
                                                            .frame(width: 8, height: 8)
                                                        Text(tag.name)
                                                        Image(systemName: "xmark")
                                                            .font(.system(size: 10))
                                                    }
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC").opacity(0.2))
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 30)
                        
                        // Action buttons with better styling
                        VStack(spacing: 16) {
                            Button(action: saveQRCode) {
                                HStack {
                                    Image(systemName: "qrcode")
                                    Text("Save QR Code")
                                        .fontWeight(.semibold)
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
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
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
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
        // Provide feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Clear state
        detectedQRCode = nil
        customLabel = ""
        selectedTags = []
        cameraManager.resumeScanning()
        
        // Explicitly dismiss the sheet
        DispatchQueue.main.async {
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
