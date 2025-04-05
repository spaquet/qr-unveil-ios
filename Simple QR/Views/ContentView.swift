//
//  ContentView.swift
//  QR Unveil
//
//  Created on 4/3/25.
//

import AVFoundation
import CoreLocation
import MessageUI
import SwiftData
import SwiftUI

/// Main view controller for QR code scanning application
struct ContentView: View {
    // MARK: - Properties
    
    // Camera states
    @StateObject private var cameraManager = CameraManager()
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    
    // Modern navigation
    @State private var navigationPath = NavigationPath()
    
    // QR detection
    @State private var detectedQRCode: DetectedQRCode? = nil
    @State private var showQRBottomSheet = false
    @State private var saveLocation = true
    
    // Label
    @State private var customLabel: String = ""
    
    // Tags
    @State private var selectedTags: [TagModel] = []
    @State private var showTagPicker = false
    
    // Requet access to Photo
    @State private var showPhotoPermission = false
    
    // View model access
    @Environment(\.modelContext) private var modelContext
    
    // Navigation destinations
    enum NavDestination: String, Identifiable, Hashable, CaseIterable {
        case history, tags, tagMap, settings
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .history: return "History"
            case .tags: return "Tags"
            case .tagMap: return "Map"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .history: return "clock.arrow.circlepath"
            case .tags: return "tag"
            case .tagMap: return "map"
            case .settings: return "gear"
            }
        }
    }
    
    private var safeDetectedContent: String {
        return detectedQRCode?.content ?? cameraManager.qrCodeString ?? ""
    }

    private var safeDetectedType: String {
        if let type = detectedQRCode?.type {
            return type
        }
        if let content = cameraManager.qrCodeString {
            return QRCodeModel.determineQRType(from: content)
        }
        return "text"
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Camera layer - MUST be first in the ZStack
                if cameraPermission == .authorized {
                    // Camera preview that fills the entire screen
                    CameraPreviewRepresentable(session: cameraManager.captureSession)
                        .ignoresSafeArea()
                        .onAppear {
                            print("Camera view appeared")
                        }
                    
                    // Overlay layer with proper blending for the transparent region
                    ScannerOverlayView()
                        .ignoresSafeArea()
                    
                    // UI Elements layer
                    scannerUIElements
                } else {
                    // Camera not authorized - show permission request view
                    RequestCameraView(proceedToNextStep: {
                        checkCameraPermission()
                    })
                }
            }
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .history:
                    HistoryView()
                case .tags:
                    TagsView()
                case .tagMap:
                    MapView()
                case .settings:
                    SettingsView()
                }
            }
            .sheet(isPresented: $showQRBottomSheet, onDismiss: {
                // Make sure the scanner is reactivated on any dismissal
                detectedQRCode = nil
                customLabel = ""
                selectedTags = []
                cameraManager.resumeScanning()
            }) {
                qrCodeBottomSheet
            }
            .onAppear {
                checkCameraPermission()
            }
            .onChange(of: cameraManager.qrCodeString) { _, newValue in
                if let qrCodeString = newValue, !qrCodeString.isEmpty {
                    // Process detected QR code
                    let type = QRCodeModel.determineQRType(from: qrCodeString)
                    
                    // Create the detected QR code
                    let detected = DetectedQRCode(
                        content: qrCodeString,
                        type: type
                    )
                    
                    // Important: Set the property and THEN show the sheet
                    // This ensures the data is set before the view is rendered
                    self.detectedQRCode = detected
                    
                    // Add a small delay to ensure property is updated before sheet appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showQRBottomSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Scanner UI elements displayed on top of camera
    private var scannerUIElements: some View {
        VStack {
            // Top bar
            HStack {
                Text("QR Unveil")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                Spacer()
                
                // Menu button
                Menu {
                    ForEach(NavDestination.allCases) { destination in
                        Button {
                            navigationPath.append(destination)
                        } label: {
                            Label(destination.title, systemImage: destination.icon)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            .padding()
            
            // Instruction text above the frame
            Text("Position QR code within frame")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .padding(.top, 20)
            
            Spacer()
            
            // Bottom bar with camera controls
            HStack {
                Spacer()
                
                // Flash button
                Button {
                    cameraManager.toggleTorch()
                } label: {
                    Image(systemName: cameraManager.isTorchOn ? "bolt.fill" : "bolt.slash")
                        .font(.title2)
                        .foregroundColor(cameraManager.isTorchOn ? .yellow : .white)
                        .padding(15)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }

    /// Camera preview representable using UIViewControllerRepresentable
    struct CameraPreviewRepresentable: UIViewControllerRepresentable {
        let session: AVCaptureSession
        
        func makeUIViewController(context: Context) -> UIViewController {
            let viewController = UIViewController()
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.name = "cameraPreviewLayer" // Add a name for debugging
            
            DispatchQueue.main.async {
                // Configure the preview layer
                previewLayer.frame = viewController.view.bounds
                
                // Add as the bottom-most layer
                viewController.view.layer.insertSublayer(previewLayer, at: 0)
                
                // Add debugging info
                print("Preview layer frame: \(previewLayer.frame)")
                print("View controller bounds: \(viewController.view.bounds)")
            }
            
            return viewController
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            if let previewLayer = uiViewController.view.layer.sublayers?.first(where: { $0.name == "cameraPreviewLayer" }) {
                previewLayer.frame = uiViewController.view.bounds
            }
        }
    }
    
    // Bottom sheet for QR code detection
    private var qrCodeBottomSheet: some View {
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
                                .padding()
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
                                    showQRBottomSheet = false
                                    cameraManager.resumeScanning()
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
                debugQRData()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        
        /// View for requesting photo library access
        private var photoPermissionView: some View {
            VStack(spacing: 20) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Allow Photo Library Access")
                    .font(.headline)
                
                Text("QR Unveil would like to save the QR code image to your photo library. This allows you to view and share the QR code later.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                HStack(spacing: 20) {
                    Button("Don't Allow") {
                        // Proceed without saving image
                        saveQRCodeWithoutImage()
                        showPhotoPermission = false
                    }
                    .foregroundColor(.red)
                    
                    Button("Allow") {
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
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .padding()
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
    
    /// Checks and requests camera permission if needed
    private func checkCameraPermission() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        
        print("Current camera permission status: \(cameraPermission.rawValue)")
        
        switch cameraPermission {
        case .authorized:
            print("Camera permission already authorized, setting up camera")
            cameraManager.setupCamera()
            
        case .notDetermined:
            print("Camera permission not determined, requesting access")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermission = granted ? .authorized : .denied
                    print("Camera permission result: \(granted ? "granted" : "denied")")
                    
                    if granted {
                        self.cameraManager.setupCamera()
                    } else {
                        print("Camera permission denied by user")
                    }
                }
            }
            
        case .denied, .restricted:
            print("Camera access denied or restricted")
            // Could show an alert here explaining why camera access is needed
            
        @unknown default:
            print("Unknown camera permission status")
        }
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
        let saveLocationValue = saveLocation
        let currentLocation = cameraManager.currentLocation
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
                let location = saveLocation ? cameraManager.currentLocation : nil
                
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
            
            // Clear and dismiss
            detectedQRCode = nil
            customLabel = ""
            selectedTags = []
            showQRBottomSheet = false
            cameraManager.resumeScanning()
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

/// Separate overlay view with transparent cutout for scanning area
struct ScannerOverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent black overlay
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                
                // Transparent window in the middle
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 260, height: 260)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .blendMode(.destinationOut)
                
                // Border around the scanning area
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 260, height: 260)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Scanning animation line
                ScanningAnimationView()
                    .frame(width: 260, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .compositingGroup()
        }
    }
}

/// Animation view for the scanning line that moves up and down
struct ScanningAnimationView: View {
    @State private var offsetY: CGFloat = -130
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .green.opacity(0.7), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
            .offset(y: offsetY)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    offsetY = 130
                }
            }
    }
}

// MARK: - Camera Manager

/// Manages camera operations including QR code detection and torch control
class CameraManager: NSObject, ObservableObject {
    // Camera session
    let captureSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var deviceInput: AVCaptureDeviceInput?
    private var metadataOutput = AVCaptureMetadataOutput()
    
    // To save the Photo
    private var photoOutput = AVCapturePhotoOutput()
    @Published var capturedImage: UIImage?
    
    // Torch state
    @Published var isTorchOn = false
    
    // QR detection
    @Published var qrCodeString: String? = nil
    private var isQRDetectionPaused = false
    
    // Location
    private let locationManager = CLLocationManager()
    private(set) var currentLocation: CLLocation?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    /// Sets up the camera capture session for QR scanning
    func setupCamera() {
        // Start fresh
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        // Remove any existing inputs and outputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        // Configure session with high resolution if supported
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        captureSession.beginConfiguration()
        
        // Explicitly request the back wide-angle camera
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find a capture device")
            return
        }
        
        captureDevice = backCamera
        
        do {
            // Add camera input
            let input = try AVCaptureDeviceInput(device: backCamera)
            deviceInput = input
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("Camera input added successfully")
            } else {
                print("Failed to add camera input")
                return
            }
            
            // Configure metadata output for QR code detection
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
                    metadataOutput.metadataObjectTypes = [.qr]
                    print("QR code detection enabled")
                } else {
                    print("QR code detection not available")
                }
                
                // Set region of interest (centered square covering about 60% of view)
                let screenSize = UIScreen.main.bounds.size
                let centerX = screenSize.width / 2
                let centerY = screenSize.height / 2
                let rectSize: CGFloat = 260
                
                let scanRect = CGRect(
                    x: centerX - (rectSize / 2),
                    y: centerY - (rectSize / 2),
                    width: rectSize,
                    height: rectSize
                )
                
                // Convert to normalized coordinates (in the video orientation)
                let normalizedRect = CGRect(
                    x: scanRect.origin.y / screenSize.height,
                    y: 1.0 - (scanRect.origin.x + scanRect.size.width) / screenSize.width,
                    width: scanRect.size.height / screenSize.height,
                    height: scanRect.size.width / screenSize.width
                )
                
                metadataOutput.rectOfInterest = normalizedRect
            } else {
                print("Failed to add metadata output")
                return
            }
            
            // Add photo output for capturing images
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                print("Photo output added successfully")
            } else {
                print("Failed to add photo output")
            }
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        captureSession.commitConfiguration()
        
        // Start session on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Make sure we're not already running
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("Camera session started")
            } else {
                print("Camera session was already running")
            }
        }
    }
    
    /// Toggles the device torch (flashlight) on/off
    func toggleTorch() {
        guard let device = captureDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.torchMode == .on {
                device.torchMode = .off
                isTorchOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                isTorchOn = true
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting torch: \(error)")
        }
    }
    
    /// Pauses QR code detection temporarily
    func pauseQRDetection() {
        isQRDetectionPaused = true
    }
    
    /// Resumes QR code scanning
    func resumeScanning() {
        isQRDetectionPaused = false
        qrCodeString = nil
    }
    
    /// Captures a photo of the current camera frame when a QR code is detected
    func captureQRCodeImage() {
        let settings = AVCapturePhotoSettings()
        
        // Capture a photo
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    /// Sets up location manager for recording scan locations
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

// MARK: - Camera Manager Extensions

extension CameraManager: AVCaptureMetadataOutputObjectsDelegate {
    /// Handles QR code detection from the camera feed
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Skip if QR detection is paused
        if isQRDetectionPaused {
            return
        }
        
        // Process QR code
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue,
           metadataObject.type == .qr {
            
            // Provide haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Update QR code value and pause detection
            qrCodeString = stringValue
            pauseQRDetection()
            
            // Capture the image showing the QR code
            captureQRCodeImage()
        }
    }
}

extension CameraManager: CLLocationManagerDelegate {
    /// Updates current location when location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Error capturing photo: \(error!.localizedDescription)")
            return
        }
        
        // Get the image data and create a UIImage
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Could not create image from photo data")
            return
        }
        
        // Set the captured image property
        self.capturedImage = image
    }
}

// MARK: - Data Models

/// Model representing a detected QR code
struct DetectedQRCode {
    let content: String
    let type: String
}
