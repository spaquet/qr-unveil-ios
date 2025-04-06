//
//  SettingsView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftData
import SwiftUI
import CloudKit

struct SettingsView: View {
    @Query var settings: [SettingsModel]
    @Environment(\.modelContext) private var modelContext
    
    @State private var isUpdatingSettings = false
    @State private var autoSaveScans = true
    @State private var vibrationFeedback = true
    @State private var playSoundOnScan = true
    @State private var saveLocationData = true
    @State private var historyRetentionDays = 90
    @State private var groupScansByDate = true
    @State private var defaultSortOrder: SettingsModel.SortOrder = .dateNewest
    @State private var showFavoritesSection = true
    @State private var showDeletionAlert = false
    
    // CloudKit sync status
    @State private var cloudSyncStatus: CloudSyncStatus = .unknown
    @State private var lastSyncTime: Date?
    @State private var isSyncing = false
    @State private var syncError: String?
    
    // Timer to check CloudKit status
    @State private var statusTimer: Timer?
    
    var currentSettings: SettingsModel? {
        settings.first
    }
    
    // Get app version from bundle
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        Form {
            // CloudKit Sync Status Section
            Section {
                HStack {
                    Text("iCloud Sync")
                    Spacer()
                    cloudStatusView
                }
                
                if cloudSyncStatus == .available {
                    Button {
                        triggerManualSync()
                    } label: {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(isSyncing)
                }
                
                if let lastSync = lastSyncTime {
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text(lastSync, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = syncError {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
            
            Section("Scan Settings") {
                Toggle("Auto-save Scans", isOn: $autoSaveScans)
                    .onChange(of: autoSaveScans) { updateSettings() }
                
                Toggle("Vibration Feedback", isOn: $vibrationFeedback)
                    .onChange(of: vibrationFeedback) { updateSettings() }
                
                Toggle("Sound on Scan", isOn: $playSoundOnScan)
                    .onChange(of: playSoundOnScan) { updateSettings() }
                
                Toggle("Save Location Data", isOn: $saveLocationData)
                    .onChange(of: saveLocationData) { updateSettings() }
            }
            
            Section("History Settings") {
                Stepper(value: $historyRetentionDays, in: 7...365, step: 30) {
                    Text("Keep History: \(historyRetentionDays) days")
                }
                .onChange(of: historyRetentionDays) { updateSettings() }
                
                Toggle("Group Scans by Date", isOn: $groupScansByDate)
                    .onChange(of: groupScansByDate) { updateSettings() }
                
                Toggle("Show Favorites Section", isOn: $showFavoritesSection)
                    .onChange(of: showFavoritesSection) { updateSettings() }
                
                Picker("Default Sort Order", selection: $defaultSortOrder) {
                    Text("Newest First").tag(SettingsModel.SortOrder.dateNewest)
                    Text("Oldest First").tag(SettingsModel.SortOrder.dateOldest)
                    Text("Most Scanned").tag(SettingsModel.SortOrder.scanCount)
                    Text("Alphabetical").tag(SettingsModel.SortOrder.alphabetical)
                }
                .onChange(of: defaultSortOrder) { updateSettings() }
            }
            
            Section("Data Management") {
                Button {
                    exportData()
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    showDeletionAlert = true
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                }
            }
            
            // Links Section
            Section("About") {
                // QR Unveil Website
                Button {
                    openURL("https://qrunveil.pages.dev")
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.accentColor)
                        Text("QR Unveil Website")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Terms of Service
                Button {
                    openURL("https://qrunveil.pages.dev/terms")
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.accentColor)
                        Text("Terms of Service")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Privacy Policy
                Button {
                    openURL("https://qrunveil.pages.dev/privacy")
                } label: {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.accentColor)
                        Text("Privacy Policy")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // App info at the bottom of the view
            Section {
                VStack(spacing: 8) {
                    Text("Made with ❤️ in SF")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text(appVersion)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadSettings()
            checkCloudKitStatus()
            startStatusTimer()
        }
        .onDisappear {
            stopStatusTimer()
        }
        .alert("Clear All Data", isPresented: $showDeletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all your saved QR codes. This action cannot be undone.")
        }
    }
    
    // CloudKit status indicator view
    private var cloudStatusView: some View {
        HStack(spacing: 4) {
            switch cloudSyncStatus {
            case .available:
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(.green)
                Text("Connected")
                    .foregroundColor(.green)
            case .unavailable:
                Image(systemName: "xmark.icloud")
                    .foregroundColor(.red)
                Text("Not Available")
                    .foregroundColor(.red)
            case .restricted:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.orange)
                Text("Restricted")
                    .foregroundColor(.orange)
            case .unknown:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.gray)
                Text("Checking...")
                    .foregroundColor(.gray)
            }
            
            if isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.leading, 4)
            }
        }
    }
    
    // Helper function to open URLs in the default browser
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // CloudKit status management
    private func checkCloudKitStatus() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.syncError = "Error: \(error.localizedDescription)"
                    self.cloudSyncStatus = .unavailable
                    return
                }
                
                switch status {
                case .available:
                    self.cloudSyncStatus = .available
                    self.syncError = nil
                case .noAccount, .couldNotDetermine:
                    self.cloudSyncStatus = .unavailable
                    self.syncError = "Please sign in to iCloud in Settings"
                case .restricted:
                    self.cloudSyncStatus = .restricted
                    self.syncError = "iCloud access restricted"
                case .temporarilyUnavailable:
                    self.cloudSyncStatus = .unavailable
                    self.syncError = "iCloud temporarily unavailable"
                @unknown default:
                    self.cloudSyncStatus = .unknown
                    self.syncError = "Unknown iCloud status"
                }
            }
        }
    }
    
    private func startStatusTimer() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            checkCloudKitStatus()
        }
    }
    
    private func stopStatusTimer() {
        statusTimer?.invalidate()
        statusTimer = nil
    }
    
    private func triggerManualSync() {
        isSyncing = true
        
        // Force save any pending changes first
        do {
            try QRDataManager.shared.forceSave()
        } catch {
            print("Error saving before sync: \(error.localizedDescription)")
        }
        
        // Trigger CloudKit sync
        CloudKitSyncManager.shared.triggerSync()
        
        // Update the last sync time and toggle off the syncing indicator after a delay
        lastSyncTime = Date()
        
        // Simulate sync completion after a reasonable delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
        }
    }
    
    // The rest of your methods
    private func loadSettings() {
        guard let settings = currentSettings else { return }
        
        autoSaveScans = settings.autoSaveScans
        vibrationFeedback = settings.vibrationFeedback
        playSoundOnScan = settings.playSoundOnScan
        saveLocationData = settings.saveLocationData
        historyRetentionDays = settings.historyRetentionDays
        groupScansByDate = settings.groupScansByDate
        defaultSortOrder = settings.defaultSortOrder
        showFavoritesSection = settings.showFavoritesSection
    }
    
    private func updateSettings() {
        guard let settings = currentSettings, !isUpdatingSettings else { return }
        
        isUpdatingSettings = true
        
        settings.updateSettings(
            autoSaveScans: autoSaveScans,
            vibrationFeedback: vibrationFeedback,
            playSoundOnScan: playSoundOnScan,
            saveLocationData: saveLocationData,
            historyRetentionDays: historyRetentionDays,
            groupScansByDate: groupScansByDate,
            defaultSortOrder: defaultSortOrder,
            showFavoritesSection: showFavoritesSection
        )
        
        do {
            try modelContext.save()
            
            // Trigger CloudKit sync after settings update
            CloudKitSyncManager.shared.triggerSync()
        } catch {
            print("Error saving settings: \(error)")
        }
        
        isUpdatingSettings = false
    }
    
    private func exportData() {
        do {
            let jsonData = try QRDataManager.shared.exportQRCodesAsJSON()
            // Here you would handle the sharing of the exported data
            // using a UIActivityViewController or similar
            print("Data exported successfully: \(jsonData.count) bytes")
        } catch {
            print("Error exporting data: \(error)")
        }
    }
    
    private func clearAllData() {
        do {
            try QRDataManager.shared.clearAllData()
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}
