//
//  Simple_QRApp.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/1/25.
//

import SwiftUI
import AVFoundation

@main
struct Simple_QRApp: App {
    // Track the entire onboarding completion instead of just welcome screen
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // First time opening the app - show onboarding flow
                    OnboardingControllerView()
                } else {
                    // User has completed onboarding - show main content
                    ContentView()
                }
            }
        }
    }
}

// This view handles the entire onboarding flow
struct OnboardingControllerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentStep: OnboardingStep = .welcome
    
    enum OnboardingStep {
        case welcome
        case requestCamera
        case requestLocation
    }
    
    var body: some View {
        ZStack {
            // Display the appropriate view based on current step
            switch currentStep {
            case .welcome:
                WelcomeView(
                    proceedToNextStep: {
                        currentStep = .requestCamera
                    }
                )
            case .requestCamera:
                RequestCameraView(
                    proceedToNextStep: {
                        currentStep = .requestLocation
                    }
                )
            case .requestLocation:
                RequestLocationView(
                    completeOnboarding: {
                        // Mark onboarding as complete and exit to main content
                        hasCompletedOnboarding = true
                    }
                )
            }
        }
        // Disable swiping back
        .interactiveDismissDisabled()
    }
}
