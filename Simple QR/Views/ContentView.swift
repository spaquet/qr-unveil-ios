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

struct ContentView: View {
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
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Camera preview
                if cameraPermission == .authorized {
                    CameraPreviewView(session: cameraManager.captureSession)
                        .ignoresSafeArea()
                        .overlay(
                            scanningOverlay
                        )
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
                } else {
                    // Camera not authorized - show permission request view
                    RequestCameraView(proceedToNextStep: {
                        checkCameraPermission()
                    })
                }
                
                // Top bar
                VStack {
                    HStack {
                        Text("QR Unveil")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        Spacer()
                        
                        // Menu button using SwiftUI Menu
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
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
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
        }
    }
    
    // MARK: - UI Components
    
    // Scanning overlay with region of interest
    private var scanningOverlay: some View {
        ZStack {
            // Semi-transparent mask
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .mask(
                    Rectangle()
                        .overlay(
                            // Cut out a square in the middle
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: 260, height: 260)
                                .blendMode(.destinationOut)
                        )
                )
            
            // Scan region border
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 260, height: 260)
            
            // Scanning animation line
            ScanningAnimationView()
                .frame(width: 260, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20))
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
    
    private func checkCameraPermission() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        
        if cameraPermission == .authorized {
            cameraManager.setupCamera()
        } else if cameraPermission == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .authorized : .denied
                    if granted {
                        cameraManager.setupCamera()
                    }
                }
            }
        }
    }
    
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

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.frame
        }
    }
}

// MARK: - Scanning Animation
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
    
    func setupCamera() {
        captureSession.beginConfiguration()
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
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
            }
            
            // Configure metadata output for QR code detection
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
                
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
                
                // Convert to normalized coordinates
                let normalizedRect = CGRect(
                    x: scanRect.origin.y / screenSize.height,
                    y: 1.0 - (scanRect.origin.x + scanRect.size.width) / screenSize.width,
                    width: scanRect.size.height / screenSize.height,
                    height: scanRect.size.width / screenSize.width
                )
                
                metadataOutput.rectOfInterest = normalizedRect
            }
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        captureSession.commitConfiguration()
        
        // Start session on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
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
    
    func switchCamera() {
        captureSession.beginConfiguration()
        
        // Remove current input
        if let currentInput = deviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // Get new camera position
        let newPosition: AVCaptureDevice.Position = (captureDevice?.position == .back) ? .front : .back
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: newPosition
        ).devices
        
        // Add new camera input
        if let newDevice = devices.first {
            captureDevice = newDevice
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                deviceInput = newInput
                
                if captureSession.canAddInput(newInput) {
                    captureSession.addInput(newInput)
                }
                
                // Turn off torch when switching to front camera
                if newPosition == .front && isTorchOn {
                    isTorchOn = false
                }
            } catch {
                print("Error creating new input: \(error)")
            }
        }
        
        captureSession.commitConfiguration()
    }
    
    func pauseQRDetection() {
        isQRDetectionPaused = true
    }
    
    func resumeScanning() {
        isQRDetectionPaused = false
        qrCodeString = nil
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

// MARK: - Camera Manager Extensions
extension CameraManager: AVCaptureMetadataOutputObjectsDelegate {
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
        }
    }
}

// MARK: - Data Models
struct DetectedQRCode {
    let content: String
    let type: String
}
