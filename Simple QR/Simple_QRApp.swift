//
//  Simple_QRApp.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/1/25.
//

import AVFoundation
import CloudKit
import SwiftData
import SwiftUI

@main
struct Simple_QRApp: App {
    // Track the entire onboarding completion instead of just welcome screen
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // Setup SwiftData container
    let container: ModelContainer
    
    init() {
        do {
            // Define the model schema
            let schema = Schema([
                QRCodeModel.self,
                LocationModel.self,
                TagModel.self,
                SettingsModel.self,
                SecurityVerificationModel.self
            ])
            
            // Check for schema migration before configuring model container
            _ = CloudKitSchemaMigrator.shared.checkAndMigrateIfNeeded()
            
            // Configure model container with more controlled CloudKit sync
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .automatic
            )
            
            // Create container
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Check if we need to create default settings on first launch
            initializeDefaultDataIfNeeded()
            
            // Set up schema error observer
            setupSchemaErrorObserver()
            
            // Make container available to the app delegate
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.modelContainer = container
            }
        } catch {
            // Handle container creation error
            fatalError("Failed to create SwiftData container: \(error.localizedDescription)")
        }
    }
    
    private func setupSchemaErrorObserver() {
        NotificationCenter.default.addObserver(
            forName: .cloudKitSchemaError,
            object: nil,
            queue: .main
        ) { _ in
            // Show alert to user about schema change requiring restart
            // This could show a UI alert or notification
        }
    }
    
    // Initialize default data if needed (first launch)
    private func initializeDefaultDataIfNeeded() {
        let context = container.mainContext
        
        // Initialize QRDataManager with the main context
        QRDataManager.initializeShared(modelContext: context)
        
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
            print("Error checking for settings: \(error.localizedDescription)")
        }
        
        // Create some default tags if none exist
        let tagsFetchDescriptor = FetchDescriptor<TagModel>()
        do {
            let existingTags = try context.fetch(tagsFetchDescriptor)
            if existingTags.isEmpty {
                // Create default tags
                let workTag = TagModel()
                workTag.name = "Work"
                workTag.color = "#FF5733"
                
                let personalTag = TagModel()
                personalTag.name = "Personal"
                personalTag.color = "#33FF57"
                
                let favoriteTag = TagModel()
                favoriteTag.name = "Important"
                favoriteTag.color = "#3357FF"
                
                context.insert(workTag)
                context.insert(personalTag)
                context.insert(favoriteTag)
                try context.save()
                print("Created default tags")
            }
        } catch {
            print("Error checking for tags: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // First time opening the app - show onboarding flow
                    OnboardingControllerView()
                } else {
                    // User has completed onboarding - show main content
                    ContentView()
                        .onAppear {
                            // Trigger initial sync when app appears
                            CloudKitSyncManager.shared.triggerSync()
                        }
                }
            }
            // Provide the model container to the view hierarchy
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
