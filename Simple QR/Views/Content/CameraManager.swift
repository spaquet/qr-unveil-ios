//
//  CameraManager.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/7/25.
//

import AVFoundation
import CoreLocation
import AudioToolbox
import SwiftUI

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
    
    // Settings manager reference
    private let settingsManager = SettingsManager.shared
    
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
            
            // Check settings and provide haptic feedback if enabled
            if settingsManager.vibrationFeedback {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
            
            // Play sound if enabled
            if settingsManager.playSoundOnScan {
                playDetectionSound()
            }
            
            // Update QR code value and pause detection
            qrCodeString = stringValue
            pauseQRDetection()
            
            // Capture the image showing the QR code
            captureQRCodeImage()
        }
    }
    
    // Add method to play sound
    private func playDetectionSound() {
        // Simple implementation using AudioServicesPlaySystemSound
        AudioServicesPlaySystemSound(1103) // Standard system sound
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
