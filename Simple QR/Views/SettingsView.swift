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
    
    // Removed autoSaveScans since it's not implemented yet
    @State private var vibrationFeedback = true
    @State private var playSoundOnScan = true
    @State private var saveLocationData = true
    @State private var historyRetentionDays = 90
    @State private var groupScansByDate = true
    @State private var defaultSortOrder: SettingsModel.SortOrder = .dateNewest
    @State private var showFavoritesSection = true
    @State private var showDeletionAlert = false
    
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
