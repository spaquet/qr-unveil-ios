//
//  Simple_QRApp.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/1/25.
//

import AVFoundation
import CloudKit
import Sentry
import SwiftData
import SwiftUI

@main
struct Simple_QRApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // Setup SwiftData container
    let container: ModelContainer
    
    init() {
        do {
            // Define the model schema - keep only what you absolutely need for now
            let schema = Schema([
                QRCodeModel.self,
                LocationModel.self,
                TagModel.self,
                SettingsModel.self,
                SecurityVerificationModel.self
            ])
            
            // Create a basic model configuration with CloudKit
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.qrunveil")
            )
            
            // Create container
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Call Sentry Initializer
            initializeSentry()
            
            // Initialize data manager
            QRDataManager.initializeShared(modelContext: container.mainContext)
            
            // Initialize default data if needed
            initializeDefaultDataIfNeeded()
        } catch {
            fatalError("Failed to create SwiftData container: \(error.localizedDescription)")
        }
    }
    
    /// Function used to initialize Sentry
    private func initializeSentry() {
        SentrySDK.start { options in
            options.dsn = "https://f9b747796283bb73df960fcdcf463fa9@o4509108609875968.ingest.us.sentry.io/4509108618985472"
            options.debug = true // Enabling debug when first installing is always helpful
            
            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true
            
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
        }
        
        // Manually call startProfiler and stopProfiler
        // to profile the code in between
        SentrySDK.startProfiler()
        // this code will be profiled
        //
        // Calls to stopProfiler are optional - if you don't stop the profiler, it will keep profiling
        // your application until the process exits or stopProfiler is called.
        SentrySDK.stopProfiler()
    }
    
    // Initialize default data if needed (first launch)
    private func initializeDefaultDataIfNeeded() {
        let context = container.mainContext
        
        // Initialize SettingsManager with the model context
        SettingsManager.shared.setup(modelContext: context)
        
        // Check if settings exist, create if not
        let settingsFetchDescriptor = FetchDescriptor<SettingsModel>()
        do {
            let existingSettings = try context.fetch(settingsFetchDescriptor)
            if existingSettings.isEmpty {
                // Create default settings
                let defaultSettings = SettingsModel()
                context.insert(defaultSettings)
                try context.save()
                print("Created default settings")
            }
        } catch {
            print("Error checking for settings: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingControllerView()
                } else {
                    ContentView()
                }
            }
            .modelContainer(container)
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
