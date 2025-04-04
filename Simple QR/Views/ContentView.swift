//
//  ContentView.swift
//  QR Unveil
//
//  Created on 4/3/25.
//

import SwiftUI
import AVFoundation
import CoreLocation
import SwiftData

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
    
    // View model access
    @Environment(\.modelContext) private var modelContext
    
    // Navigation destinations
    enum NavDestination: String, Identifiable, Hashable, CaseIterable {
        case history, tags, settings
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .history: return "History"
            case .tags: return "Tags"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .history: return "clock.arrow.circlepath"
            case .tags: return "tag"
            case .settings: return "gear"
            }
        }
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
                case .settings:
                    SettingsView()
                }
            }
            .sheet(isPresented: $showQRBottomSheet) {
                qrCodeBottomSheet
            }
            .onAppear {
                checkCameraPermission()
            }
            .onChange(of: cameraManager.qrCodeString) { _, newValue in
                if let qrCodeString = newValue, !qrCodeString.isEmpty {
                    // Process detected QR code
                    let type = QRCodeModel.determineQRType(from: qrCodeString)
                    detectedQRCode = DetectedQRCode(
                        content: qrCodeString,
                        type: type
                    )
                    showQRBottomSheet = true
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
            VStack(alignment: .leading, spacing: 16) {
                // QR code icon and type
                HStack {
                    ZStack {
                        Circle()
                            .fill(qrTypeColor(detectedQRCode?.type ?? "text").opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: qrTypeIcon(detectedQRCode?.type ?? "text"))
                            .font(.title3)
                            .foregroundColor(qrTypeColor(detectedQRCode?.type ?? "text"))
                    }
                    
                    VStack(alignment: .leading) {
                        Text(qrTypeTitle(detectedQRCode?.type ?? "text"))
                            .font(.headline)
                        
                        Text("Scanned QR Code")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                Divider()
                
                // QR content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(detectedQRCode?.content ?? "")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Location toggle
                Toggle(isOn: $saveLocation) {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                        Text("Save location data")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                // Tag selection placeholder
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(.orange)
                    
                    Text("Add tags")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: saveQRCode) {
                        Text("Save QR Code")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        // Discard and scan another
                        detectedQRCode = nil
                        showQRBottomSheet = false
                        cameraManager.resumeScanning()
                    } label: {
                        Text("Scan Another")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        detectedQRCode = nil
                        showQRBottomSheet = false
                        cameraManager.resumeScanning()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Helper Methods
    
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
        
        do {
            // Get current location if enabled
            var location: CLLocation? = nil
            if saveLocation {
                location = cameraManager.currentLocation
            }
            
            // Save to database
            let _ = try QRDataManager.shared.saveQRCode(
                content: qrCode.content,
                label: generateLabelFromContent(qrCode.content, type: qrCode.type),
                location: location
            )
            
            // Provide feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            // Clear and dismiss
            detectedQRCode = nil
            showQRBottomSheet = false
            cameraManager.resumeScanning()
        } catch {
            print("Error saving QR code: \(error.localizedDescription)")
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

// MARK: - Data Models

/// Model representing a detected QR code
struct DetectedQRCode {
    let content: String
    let type: String
}
