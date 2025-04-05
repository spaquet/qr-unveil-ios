//
//  RequestPhotoView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/4/25.
//


//
//  RequestPhotoView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/4/25.
//

import SwiftUI
import Photos

struct RequestPhotoView: View {
    // Callback to complete the onboarding process
    var completeOnboarding: () -> Void
    
    @StateObject private var photoManager = PhotoManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Use the same background as previous onboarding screens
            BackgroundView()
            
            VStack(spacing: 30) {
                // Photo library icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                }
                .shadow(color: Color.accentColor.opacity(0.5), radius: 15, x: 0, y: 0)
                .padding(.top, 80)
                
                // Title and description
                Text("Photo Library Access")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Text("Save and Share Your QR Codes")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("QR Unveil needs full access to your photo library to save QR code images and display them within the app. This allows you to easily reference and share your scanned codes.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Buttons for photo library access or continue without
                VStack(spacing: 16) {
                    Button {
                        requestPhotoAccess()
                    } label: {
                        Text(primaryButtonTitle)
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
                    
                    // Secondary button to skip photo library access
                    Button {
                        // Complete onboarding without photo library access
                        completeOnboarding()
                    } label: {
                        Text(secondaryButtonTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Check current authorization status on view appear
            photoManager.updateAuthorizationStatus()
            checkPhotoStatus()
        }
    }
    
    // Dynamic button titles based on authorization status
    private var primaryButtonTitle: String {
        switch photoManager.authorizationStatus {
        case .notDetermined:
            return "Allow Photo Library Access"
        case .denied, .restricted:
            return "Open Settings"
        case .authorized, .limited:
            return "Continue to App"
        @unknown default:
            return "Allow Photo Library Access"
        }
    }
    
    private var secondaryButtonTitle: String {
        switch photoManager.authorizationStatus {
        case .notDetermined:
            return "Skip for Now"
        case .denied, .restricted:
            return "Continue Without Photo Access"
        case .authorized, .limited:
            return ""  // No secondary button needed when authorized
        @unknown default:
            return "Skip for Now"
        }
    }
    
    // Check current photo library authorization status
    private func checkPhotoStatus() {
        if photoManager.authorizationStatus == .authorized {
            // If already authorized, we can automatically complete onboarding
            // However, let's give the user a moment to read the screen first
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completeOnboarding()
            }
        }
    }
    
    // Request photo library access or open settings if already denied
    private func requestPhotoAccess() {
        switch photoManager.authorizationStatus {
        case .notDetermined:
            photoManager.requestAuthorization {
                // We'll complete onboarding when the user makes a choice
                if photoManager.authorizationStatus != .notDetermined {
                    completeOnboarding()
                }
            }
        case .denied, .restricted:
            // Open app settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorized, .limited:
            // Already authorized, proceed to main app
            completeOnboarding()
        @unknown default:
            break
        }
    }
}

#Preview {
    RequestPhotoView(completeOnboarding: {})
}