//
//  ContentView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/1/25.
//


import SwiftUI
import AVFoundation
import UIKit
import SafariServices

// Main View
struct ContentView: View {
    @StateObject private var viewModel = QRScannerViewModel()
    @State private var showSafari = false
    @State private var currentURL: URL?
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate center and scanner frame size
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let scannerSize: CGFloat = 260
            
            ZStack {
                // Background color
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Camera feed
                QRScannerView(viewModel: viewModel, scannerRect: CGRect(
                    x: centerX - scannerSize/2,
                    y: centerY - scannerSize/2,
                    width: scannerSize,
                    height: scannerSize
                ))
                .edgesIgnoringSafeArea(.all)
                
                // Semi-transparent overlay with properly positioned cutout
                ScannerOverlayView(
                    centerX: centerX,
                    centerY: centerY,
                    size: scannerSize,
                    viewModel: viewModel
                )
                .edgesIgnoringSafeArea(.all)
                
                // UI Elements
                VStack {
                    // Top section with title
                    Text("QR Scanner")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    // Instruction text
                    Text("Position QR code in the frame")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                    
                    Spacer()
                    
                    Spacer()
                    
                    // Bottom spacing
                    Color.clear.frame(height: viewModel.qrCodeValue != nil ? 0 : 40)
                }
                
                // Menu button in top-left
                VStack {
                    HStack {
                        // Menu Button with tap response
                        Menu {
                            // QR Unveil Website
                            Button {
                                currentURL = URL(string: "https://qrunveil.pages.dev")
                                showSafari = true
                            } label: {
                                Label("QR Unveil Website", systemImage: "globe")
                            }
                            
                            // Terms of Service
                            Button {
                                currentURL = URL(string: "https://qrunveil.pages.dev/terms")
                                showSafari = true
                            } label: {
                                Label("Terms of Service", systemImage: "doc.text")
                            }
                            
                            // Privacy Policy
                            Button {
                                currentURL = URL(string: "https://qrunveil.pages.dev/privacy")
                                showSafari = true
                            } label: {
                                Label("Privacy Policy", systemImage: "lock.shield")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.top, 55) // Safe area spacing + extra for status bar
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                
                // Results overlay
                if let result = viewModel.qrCodeValue {
                    VStack {
                        Spacer()
                    }
                    .sheet(isPresented: .constant(true), onDismiss: {
                        viewModel.resetScanner()
                    }) {
                        QRResultSheet(
                            result: result,
                            type: viewModel.qrCodeType ?? "Unknown",
                            isURL: viewModel.isURLType,
                            resetAction: {
                                viewModel.resetScanner()
                            }
                        )
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                    }
                    .zIndex(3)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.qrCodeValue != nil)
            .sheet(isPresented: $showSafari) {
                if let url = currentURL {
                    SafariView(url: url)
                }
            }
        }
    }
}

// Modern iOS 17+ result sheet
struct QRResultSheet: View {
    let result: String
    let type: String
    let isURL: Bool
    let resetAction: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: typeIcon)
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading) {
                            Text(type)
                                .font(.headline)
                            
                            Text(result)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(action: {
                        UIPasteboard.general.string = result
                        // Optional: Show a toast or haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                    
                    if isURL {
                        Button(action: {
                            showSafari = true
                        }) {
                            Label("Open in Safari", systemImage: "safari")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        dismiss()
                        resetAction()
                    }) {
                        Label("Scan Another Code", systemImage: "qrcode.viewfinder")
                    }
                    .tint(.accentColor)
                }
            }
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSafari) {
                if let url = URL(string: result) {
                    SafariView(url: url)
                }
            }
        }
    }
    
    // Get SF Symbol based on QR code type
    private var typeIcon: String {
        switch type.lowercased() {
        case "url": return "link"
        case "email": return "envelope"
        case "phone number": return "phone"
        case "sms": return "message"
        case "location": return "map"
        case "wifi network": return "wifi"
        case "contact information": return "person.crop.rectangle"
        case "calendar event": return "calendar"
        case "app store": return "apple.logo"
        case "google play store": return "play.rectangle"
        case "crypto": return "bitcoinsign.circle"
        default: return "doc.text"
        }
    }
}

// New custom overlay view for better positioning and control of scanner frame
struct ScannerOverlayView: View {
    let centerX: CGFloat
    let centerY: CGFloat
    let size: CGFloat
    @ObservedObject var viewModel: QRScannerViewModel
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay covering the entire screen
            Color.black.opacity(0.6)
            
            // Transparent cutout area
            RoundedRectangle(cornerRadius: 24)
                .frame(width: size, height: size)
                .position(x: centerX, y: centerY)
                .blendMode(.destinationOut)
        }
        .compositingGroup() // This ensures proper blending
        
        // Add border on top as a separate element (not part of the mask)
        RoundedRectangle(cornerRadius: 24)
            .stroke(Color.white, lineWidth: 4)
            .frame(width: size, height: size)
            .position(x: centerX, y: centerY)
        
        // Scanning line within the border
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.8), .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size - 40, height: 4)
            .position(x: centerX, y: centerY + viewModel.scanLinePosition)
            .onAppear {
                viewModel.startScanLineAnimation(containerHeight: size - 60) // Leave safe padding
            }
    }
}

// Safari View Controller wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// QR Scanner View
struct QRScannerView: UIViewRepresentable {
    @ObservedObject var viewModel: QRScannerViewModel
    var scannerRect: CGRect
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to get camera device")
            return view
        }
        
        do {
            // Setup camera input
            let input = try AVCaptureDeviceInput(device: captureDevice)
            viewModel.captureSession.addInput(input)
            
            // Setup metadata output
            let metadataOutput = AVCaptureMetadataOutput()
            viewModel.captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            
            // Setup preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            // Store previewLayer in viewModel for coordinate calculations
            viewModel.previewLayer = previewLayer
            
            // Start capture session
            DispatchQueue.global(qos: .background).async {
                viewModel.captureSession.startRunning()
                
                // Update ROI after session is running and previewLayer is set
                DispatchQueue.main.async {
                    setupROI(metadataOutput: metadataOutput, in: view, scannerRect: scannerRect)
                }
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update ROI if needed based on any layout changes
        if let metadataOutput = viewModel.captureSession.outputs.first as? AVCaptureMetadataOutput {
            setupROI(metadataOutput: metadataOutput, in: uiView, scannerRect: scannerRect)
        }
    }
    
    // Helper method to set up region of interest
    private func setupROI(metadataOutput: AVCaptureMetadataOutput, in view: UIView, scannerRect: CGRect) {
        guard let previewLayer = viewModel.previewLayer else { return }
        
        // Convert UIKit coordinates to AVFoundation coordinates (which are normalized)
        // In AVFoundation coordinates, (0,0) is in the top-left and (1,1) is in the bottom-right
        let topLeft = previewLayer.captureDevicePointConverted(fromLayerPoint: scannerRect.origin)
        let bottomRight = previewLayer.captureDevicePointConverted(
            fromLayerPoint: CGPoint(
                x: scannerRect.origin.x + scannerRect.width,
                y: scannerRect.origin.y + scannerRect.height
            )
        )
        
        let roi = CGRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(bottomRight.x - topLeft.x),
            height: abs(bottomRight.y - topLeft.y)
        )
        
        // Set ROI - must be within 0-1 range
        let normalizedROI = CGRect(
            x: max(0, min(roi.origin.x, 1)),
            y: max(0, min(roi.origin.y, 1)),
            width: max(0, min(roi.width, 1)),
            height: max(0, min(roi.height, 1))
        )
        
        metadataOutput.rectOfInterest = normalizedROI
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // Coordinator for handling camera delegate methods
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerView
        
        init(parent: QRScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else {
                return
            }
            
            // Play success sound and haptic feedback
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Update view model on main thread
            DispatchQueue.main.async {
                if self.parent.viewModel.captureSession.isRunning && self.parent.viewModel.qrCodeValue == nil {
                    let type = self.determineQRCodeType(value: stringValue)
                    self.parent.viewModel.qrCodeValue = stringValue
                    self.parent.viewModel.qrCodeType = type
                    self.parent.viewModel.isURLType = type.lowercased() == "url"
                    self.parent.viewModel.captureSession.stopRunning()
                }
            }
        }
        
        // QR code type detection
        func determineQRCodeType(value: String) -> String {
            if value.hasPrefix("http://") || value.hasPrefix("https://") {
                // Check for app store links first
                if value.contains("apps.apple.com") || value.contains("itunes.apple.com/app") {
                    return "App Store"
                } else if value.contains("play.google.com/store/apps") {
                    return "Google Play Store"
                }
                return "URL"
            } else if value.hasPrefix("mailto:") {
                return "Email"
            } else if value.hasPrefix("tel:") {
                return "Phone Number"
            } else if value.hasPrefix("SMSTO:") || value.hasPrefix("sms:") {
                return "SMS"
            } else if value.hasPrefix("geo:") {
                return "Location"
            } else if value.hasPrefix("WIFI:") {
                return "WiFi Network"
            } else if value.hasPrefix("BEGIN:VCARD") {
                return "Contact Information"
            } else if value.hasPrefix("BEGIN:VEVENT") {
                return "Calendar Event"
            } else if value.lowercased().hasPrefix("bitcoin:") ||
                      value.lowercased().contains("ethereum:") ||
                      (value.hasPrefix("0x") && value.count == 42 && isValidHexString(value.dropFirst(2))) || // Ethereum address
                      (value.hasPrefix("1") || value.hasPrefix("3") || value.hasPrefix("bc1")) { // Bitcoin address
                return "Crypto"
            } else {
                return "Text"
            }
        }
        
        // Helper function to validate hex strings for Ethereum addresses
        private func isValidHexString(_ string: Substring) -> Bool {
            let hexPattern = "^[0-9a-fA-F]+$"
            return string.range(of: hexPattern, options: .regularExpression) != nil
        }
    }
}

// View Model for QR Scanner
class QRScannerViewModel: ObservableObject {
    @Published var qrCodeValue: String? = nil
    @Published var qrCodeType: String? = nil
    @Published var isURLType: Bool = false
    @Published var scanLinePosition: CGFloat = 0
    
    var previewLayer: AVCaptureVideoPreviewLayer? = nil
    let captureSession = AVCaptureSession()
    
    func resetScanner() {
        qrCodeValue = nil
        qrCodeType = nil
        isURLType = false
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func startScanLineAnimation(containerHeight: CGFloat) {
        // Calculate animation bounds that strictly stay inside the container
        let padding: CGFloat = 30 // Padding from top/bottom edges
        let topPosition = -containerHeight/2 + padding
        let bottomPosition = containerHeight/2 - padding
        
        // Start at the top position (+ some padding)
        self.scanLinePosition = topPosition
        
        // Animate to the bottom position (- some padding)
        withAnimation(
            Animation
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
        ) {
            self.scanLinePosition = bottomPosition
        }
    }
}
