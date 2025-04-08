import SwiftUI
import SwiftData
import AVFoundation
import CoreLocation

/// Main view controller for QR code scanning application
struct ContentView: View {
    // MARK: - Properties
    
    // Observers for settings and location manager
    @State private var settingsManager = SettingsManager.shared
    @ObservedObject private var locationManager = LocationManager.shared
    
    // Camera states
    @StateObject private var cameraManager = CameraManager()
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    
    // Modern navigation
    @State private var navigationPath = NavigationPath()
    
    // QR detection
    @State private var detectedQRCode: DetectedQRCode? = nil
    @State private var showQRBottomSheet = false
    @State private var saveLocation = SettingsManager.shared.saveLocationData
    
    // Label
    @State private var customLabel: String = ""
    
    // Tags
    @State private var selectedTags: [TagModel] = []
    @State private var showTagPicker = false
    
    // Requet access to Photo
    @State private var showPhotoPermission = false
    
    // View model access
    @Environment(\.modelContext) private var modelContext
    
    //
    @State private var shouldDirectlyScan: Bool = false
    
    var directScanFromWidget: Bool = false
    
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
                    .onAppear{
                        print("Request Camera View")
                    }
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
            .task {
                // Check if we should scan immediately
                if directScanFromWidget || UserDefaults.standard.bool(forKey: "LaunchScanQRDirectly") {
                    UserDefaults.standard.set(false, forKey: "LaunchScanQRDirectly")
                    
                    // Wait a moment for the view to fully initialize
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                    // Activate camera and scanning immediately
                    if cameraPermission == .authorized {
                        cameraManager.setupCamera()
                        cameraManager.resumeScanning()
                    } else {
                        checkCameraPermission()
                    }
                }
            }
            .onAppear {
                // Initialize saveLocation based on current settings
                saveLocation = settingsManager.saveLocationData
                
                // Check camera permission on app launch
                // This should happen before any views are shown
                checkCameraPermission()
                
                // Add this check for widget launch
                if directScanFromWidget {
                    // Ensure the camera is active immediately
                    if cameraPermission == .authorized {
                        cameraManager.setupCamera()
                        cameraManager.resumeScanning()
                    }
                }
                
                // Check CloudKit status
                SimpleCloudKitChecker.addCloudKitStatusChecks()
                
                if UserDefaults.standard.bool(forKey: "LaunchScanQRDirectly") {
                    UserDefaults.standard.set(false, forKey: "LaunchScanQRDirectly")
                    
                    // Ensure the camera is active immediately
                    if cameraPermission == .authorized {
                        cameraManager.setupCamera()
                        cameraManager.resumeScanning()
                    }
                }
            }
            .onChange(of: locationManager.authorizationStatus) { _, newStatus in
                // Update saveLocation based on current settings and authorization
                saveLocation = settingsManager.saveLocationData
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
        ScannerUIElements(
            navigationPath: $navigationPath,
            cameraManager: cameraManager
        )
    }
    
    /// Bottom sheet for QR code detection
    private var qrCodeBottomSheet: some View {
        QRBottomSheetView(
            detectedQRCode: $detectedQRCode,
            customLabel: $customLabel,
            saveLocation: $saveLocation,
            selectedTags: $selectedTags,
            showTagPicker: $showTagPicker,
            showPhotoPermission: $showPhotoPermission,
            cameraManager: cameraManager,
            modelContext: modelContext,
            safeDetectedContent: safeDetectedContent,
            safeDetectedType: safeDetectedType
        )
    }
    
    // MARK: - Helper Methods
    
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
    
    /// Checks and requests camera permission if needed
    private func checkCameraPermission() {
        // Get the current authorization status
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
}

// Navigation destinations
enum NavDestination: String, Identifiable, Hashable, CaseIterable {
    case history, tags, tagMap, settings
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .history: return NSLocalizedString("History", comment: "Menu entry title for history section")
        case .tags: return NSLocalizedString("Tags", comment: "Menu entry title for tags section")
        case .tagMap: return NSLocalizedString("Map", comment: "Menu entry title for map section")
        case .settings: return NSLocalizedString("Settings", comment: "Menu entry title for settings section")
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
