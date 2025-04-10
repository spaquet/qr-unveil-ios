//
//  RequestCameraView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftUI
import AVFoundation

struct RequestCameraView: View {
    // Callback to proceed to next step
    var proceedToNextStep: () -> Void
    
    @State private var cameraAuthStatus: AVAuthorizationStatus = .notDetermined
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Use the same background as WelcomeView for consistency
            BackgroundView()
            
            VStack(spacing: 30) {
                // Camera icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                }
                .shadow(color: Color.accentColor.opacity(0.5), radius: 15, x: 0, y: 0)
                .padding(.top, 80)
                
                // Title and description
                Text("Camera Access")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Text("QR Unveil needs camera access to scan QR codes")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("We only use the camera during active scanning. Scanned images may be saved to your Photos app, under your control. We don’t store anything on our servers or with third parties. If synced with iCloud, it’s managed privately by you, with no access by us.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Button based on current authorization status
                VStack(spacing: 16) {
                    Button {
                        requestCameraAccess()
                    } label: {
                        Text(buttonTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 30)
                    
                    // Only show Skip button if status is denied (to provide a way forward)
                    if cameraAuthStatus == .denied {
                        Button {
                            // Proceed to next step even without permission
                            proceedToNextStep()
                        } label: {
                            Text("Skip (Not Recommended)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Check current authorization status when view appears
            cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        .onChange(of: cameraAuthStatus) { _, newStatus in
            // When status changes to authorized, proceed to next step
            if newStatus == .authorized {
                proceedToNextStep()
            }
        }
    }
    
    // Dynamic button title based on authorization status
    private var buttonTitle: String {
        switch cameraAuthStatus {
        case .notDetermined:
            return "Continue"
        case .denied:
            return "Open Settings"
        case .restricted:
            return "Camera Access Restricted"
        case .authorized:
            return "Continue"
        @unknown default:
            return "Allow Camera Access"
        }
    }
    
    // Request camera access or open settings if already denied
    private func requestCameraAccess() {
        switch cameraAuthStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraAuthStatus = granted ? .authorized : .denied
                    // No longer proceeding - we will use onChange handler instead
                }
            }
        case .denied, .restricted:
            // Open app settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorized:
            // Already authorized, proceed to next step when button is pressed
            proceedToNextStep()
        @unknown default:
            // Handle future cases
            break
        }
    }
}

#Preview {
    RequestCameraView(proceedToNextStep: {})
}
