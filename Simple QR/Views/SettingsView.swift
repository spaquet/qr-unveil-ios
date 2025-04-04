//
//  SettingsView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftData
import SwiftUI
import SafariServices

struct SettingsView: View {
    @Query var settings: [SettingsModel]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showSafari = false
    @State private var currentURL: URL?
    
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
        NavigationStack {
            Form {
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
                        currentURL = URL(string: "https://qrunveil.pages.dev")
                        showSafari = true
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
                        currentURL = URL(string: "https://qrunveil.pages.dev/terms")
                        showSafari = true
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
                        currentURL = URL(string: "https://qrunveil.pages.dev/privacy")
                        showSafari = true
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
            }
            .sheet(isPresented: $showSafari) {
                if let url = currentURL {
                    SafariView(url: url)
                }
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
    }
    
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

// Safari View Controller wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}
