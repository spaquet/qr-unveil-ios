//
//  TagsView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftData
import SwiftUI

// Tags view placeholder
struct TagsView: View {
    @Query var tags: [TagModel]
    
    var body: some View {
        List {
            ForEach(tags) { tag in
                NavigationLink(destination: TagDetailView(tag: tag)) {
                    TagRowView(tag: tag)
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Add new tag action
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// Tag row for list display
struct TagRowView: View {
    let tag: TagModel
    
    var body: some View {
        HStack {
            Circle()
                .fill(colorFromHex(tag.color ?? "#CCCCCC"))
                .frame(width: 16, height: 16)
            
            Text(tag.name)
            
            Spacer()
            
            Text("\(tag.qrCodes?.count ?? 0)")
                .foregroundColor(.secondary)
        }
    }
    
    // Helper function to convert hex to Color
        private func colorFromHex(_ hex: String) -> Color {
            // Remove the # prefix if it exists
            var cleanHex = hex
            if cleanHex.hasPrefix("#") {
                cleanHex = String(cleanHex.dropFirst())
            }
            
            // Convert hex to RGB components
            var rgb: UInt64 = 0
            Scanner(string: cleanHex).scanHexInt64(&rgb)
            
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            
            return Color(red: r, green: g, blue: b)
        }
}

// Tag detail view placeholder
struct TagDetailView: View {
    let tag: TagModel
    
    var body: some View {
        Group {
            if let qrCodes = tag.qrCodes, !qrCodes.isEmpty {
                List(qrCodes) { qrCode in
                    NavigationLink(destination: QRDetailView(qrCode: qrCode)) {
                        QRCodeRowView(qrCode: qrCode)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("No QR Codes", systemImage: "qrcode")
                } description: {
                    Text("No QR codes with this tag yet.")
                } actions: {
                    Button("Scan a QR Code") {
                        // Action to scan a new QR code
                    }
                }
            }
        }
        .navigationTitle(tag.name)
    }
}
