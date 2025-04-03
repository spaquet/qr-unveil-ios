//
//  SettingsView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//


import SwiftUI
import SafariServices

struct SettingsView: View {
    @State private var showSafari = false
    @State private var currentURL: URL?
    
    // Get app version from bundle
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            List {
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
            .sheet(isPresented: $showSafari) {
                if let url = currentURL {
                    SafariView(url: url)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
