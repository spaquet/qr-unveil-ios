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
    @State private var settingsManager = SettingsManager.shared
    
    // Removed autoSaveScans since it's not implemented yet
    @State private var vibrationFeedback = true
    @State private var playSoundOnScan = true
    @State private var saveLocationData = true
    @State private var historyRetentionDays = 90
    @State private var groupScansByDate = true
    @State private var defaultSortOrder: SettingsModel.SortOrder = .dateNewest
    @State private var showFavoritesSection = true
    @State private var showDeletionAlert = false
    
    @State private var isUpdatingDomains = false
    @State private var lastUpdateDate: Date? = nil
    @State private var updateStatusMessage: String? = nil
    @State private var showingUpdateAlert = false
    
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
            Section("Scan Settings") {
                // Removed Auto-save Scans toggle since it's not implemented
                
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
            
            Section("Disposable Email Protection") {
                if let date = lastUpdateDate {
                    LabeledContent("Last Updated", value: formattedDate(date))
                } else {
                    Text("Domain list not yet downloaded")
                        .foregroundColor(.secondary)
                }
                
                if let message = updateStatusMessage {
                    Text(message)
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                
                Button(action: {
                    updateDisposableDomains()
                }) {
                    HStack {
                        Text("Update Domain List")
                        
                        if isUpdatingDomains {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isUpdatingDomains)
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
            
            // Also refresh the settings manager
            settingsManager.loadSettings()
            
            // Load the last update date
            if let metadata = DisposableDomainsManager.shared.getMetadata() {
                lastUpdateDate = metadata.lastUpdated
            }
        }
        .alert(isPresented: $showingUpdateAlert) {
            Alert(
                title: Text("Update Error"),
                message: Text(updateStatusMessage ?? "Could not update the domain list."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func updateDisposableDomains() {
        guard !isUpdatingDomains else { return }
        
        isUpdatingDomains = true
        updateStatusMessage = nil
        
        // For manual updates, bypass network restrictions (allow cellular/low power)
        DisposableDomainsManager.shared.smartDownloadDomainsFile(
            forceCheck: true,
            bypassNetworkRestrictions: true
        ) { success, error in
            DispatchQueue.main.async {
                isUpdatingDomains = false
                
                if success {
                    // Get the metadata to show the last update date
                    if let metadata = DisposableDomainsManager.shared.getMetadata() {
                        lastUpdateDate = metadata.lastUpdated
                    }
                    
                    // Reload domains in the checker
                    DisposableEmailChecker.shared.reloadDomains()
                    
                    updateStatusMessage = "Successfully updated domain list."
                } else if let error = error {
                    let nsError = error as NSError
                    
                    // Show user-friendly error message
                    if nsError.domain == "com.qrunveil.disposabledomains" {
                        switch nsError.code {
                        case 1003:
                            updateStatusMessage = "Update already in progress."
                        case 1004:
                            updateStatusMessage = "No network connection available."
                            showingUpdateAlert = true
                        default:
                            updateStatusMessage = error.localizedDescription
                            showingUpdateAlert = true
                        }
                    } else {
                        updateStatusMessage = "Failed to update: \(error.localizedDescription)"
                        showingUpdateAlert = true
                    }
                }
            }
        }
    }
    
    private func loadSettings() {
        guard let settings = currentSettings else { return }
        
        // Removed autoSaveScans assignment
        vibrationFeedback = settings.vibrationFeedback
        playSoundOnScan = settings.playSoundOnScan
        saveLocationData = settings.saveLocationData
        historyRetentionDays = settings.historyRetentionDays
        groupScansByDate = settings.groupScansByDate
        defaultSortOrder = settings.defaultSortOrder
        showFavoritesSection = settings.showFavoritesSection
    }
    
    private func updateSettings() {
        guard let settings = currentSettings else { return }
        
        settings.updateSettings(
            // Removed autoSaveScans parameter
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
        } catch {
            print("Error saving settings: \(error)")
        }
    }
}
