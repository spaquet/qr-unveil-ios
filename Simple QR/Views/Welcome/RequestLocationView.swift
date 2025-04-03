//
//  RequestLocationView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftUI
import CoreLocation

struct RequestLocationView: View {
    // Callback to complete the onboarding process
    var completeOnboarding: () -> Void
    
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Use the same background as previous onboarding screens
            BackgroundView()
            
            VStack(spacing: 30) {
                // Location icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                }
                .shadow(color: Color.accentColor.opacity(0.5), radius: 15, x: 0, y: 0)
                .padding(.top, 80)
                
                // Title and description
                Text("Location Access")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Text("Enhance Your QR Experience")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("Location access allows QR Unveil to provide geo-based features when scanning location QR codes. This is optional but recommended for full functionality.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Buttons for location access or continue without
                VStack(spacing: 16) {
                    Button {
                        requestLocationAccess()
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
                    
                    // Secondary button to skip location access
                    Button {
                        // Complete onboarding without location access
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
            checkLocationStatus()
        }
    }
    
    // Dynamic button titles based on authorization status
    private var primaryButtonTitle: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Allow Location Access"
        case .denied, .restricted:
            return "Open Settings"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Continue to App"
        @unknown default:
            return "Allow Location Access"
        }
    }
    
    private var secondaryButtonTitle: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Skip for Now"
        case .denied, .restricted:
            return "Continue Without Location"
        case .authorizedWhenInUse, .authorizedAlways:
            return ""  // No secondary button needed when authorized
        @unknown default:
            return "Skip for Now"
        }
    }
    
    // Check current location authorization status
    private func checkLocationStatus() {
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            // If already authorized, we can automatically complete onboarding
            // However, let's give the user a moment to read the screen first
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completeOnboarding()
            }
        }
    }
    
    // Request location access or open settings if already denied
    private func requestLocationAccess() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAuthorization()
            // We'll complete onboarding when the user makes a choice via the delegate
            
            // Set up a listener to proceed when status changes
            // This is a simplification; in a real app you'd use Combine or a delegate pattern
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if locationManager.authorizationStatus != .notDetermined {
                    completeOnboarding()
                }
            }
        case .denied, .restricted:
            // Open app settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, proceed to main app
            completeOnboarding()
        @unknown default:
            break
        }
    }
}

#Preview {
    RequestLocationView(completeOnboarding: {})
}
