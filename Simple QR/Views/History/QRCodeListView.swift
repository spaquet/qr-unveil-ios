//
//  QRCodeListView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/8/25.
//

// View to display a list of QR codes at a single location

import SwiftUI

// Main QRCodeListView
struct QRCodeListView: View {
    let locations: [LocationModel]
    @Environment(\.dismiss) private var dismiss
    @State private var qrCodeToShow: QRCodeDetailPresentation? = nil
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(locations) { location in
                    if let qrCode = location.qrCode {
                        QRCodeListItemView(
                            location: location,
                            qrCode: qrCode,
                            onTap: {
                                qrCodeToShow = QRCodeDetailPresentation(qrCode: qrCode)
                            }
                        )
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("QR Codes at Location")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $qrCodeToShow) { presentation in
            NavigationView {
                QRDetailView(qrCode: presentation.qrCode)
            }
        }
    }
}

// QR Code List Item View
struct QRCodeListItemView: View {
    let location: LocationModel
    let qrCode: QRCodeModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                // Type Icon
                QRCodeTypeIconView(qrType: qrCode.qrType)
                
                // Content
                QRCodeContentView(
                    qrCode: qrCode,
                    location: location
                )
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// QR Code Type Icon Component
struct QRCodeTypeIconView: View {
    let qrType: String
    
    var body: some View {
        Image(systemName: QRCodeHelper.qrTypeIcon(qrType))
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(QRCodeHelper.qrTypeColor(qrType))
            .cornerRadius(8)
    }
}

// QR Code Content Component
struct QRCodeContentView: View {
    let qrCode: QRCodeModel
    let location: LocationModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // QR Code Title or Content Preview
            Text(qrCode.label ?? QRCodeHelper.contentPreview(qrCode))
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // QR Code Type & Date
            HStack {
                Text(qrCode.qrType.capitalized)
                    .font(.subheadline)
                    .foregroundColor(QRCodeHelper.qrTypeColor(qrCode.qrType))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(QRCodeHelper.qrTypeColor(qrCode.qrType).opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(QRCodeHelper.formatDate(location.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Address if available
            if let address = location.address, !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// Helper struct to provide utility functions
struct QRCodeHelper {
    // Format date for display
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Get icon for QR code type
    static func qrTypeIcon(_ type: String) -> String {
        switch type {
        case "url": return "link"
        case "phone": return "phone.fill"
        case "email": return "envelope.fill"
        case "wifi": return "wifi"
        case "vcard": return "person.crop.square.fill"
        case "location": return "mappin.and.ellipse"
        case "sms": return "message.fill"
        default: return "doc.text.fill"
        }
    }
    
    // Get color for QR code type
    static func qrTypeColor(_ type: String) -> Color {
        switch type {
        case "url": return .blue
        case "phone": return .green
        case "email": return .purple
        case "wifi": return .orange
        case "vcard": return .indigo
        case "location": return .red
        case "sms": return .pink
        default: return .gray
        }
    }
    
    // Create a preview of the QR code content if no title is available
    static func contentPreview(_ qrCode: QRCodeModel) -> String {
        let content = qrCode.content
        
        switch qrCode.qrType {
        case "url":
            if let url = URL(string: content), let host = url.host {
                return host
            }
            return content
        case "phone":
            return "📞 \(content)"
        case "email":
            return content
        case "wifi":
            return "WiFi Network"
        case "vcard":
            // Extract name from vCard if possible
            if let nameRange = content.range(of: "FN:") {
                let nameStart = nameRange.upperBound
                if let nameEnd = content.range(of: "\n", range: nameStart..<content.endIndex) {
                    return String(content[nameStart..<nameEnd.lowerBound])
                }
                return String(content[nameStart..<content.endIndex])
            }
            return "Contact"
        case "sms":
            return "SMS Message"
        default:
            return content.prefix(30) + (content.count > 30 ? "..." : "")
        }
    }
}

#Preview {
    NavigationView {
        QRCodeListView(locations: [
            LocationModel(
                qrCode: QRCodeModel(
                    label: "Apple Website",
                    content: "https://www.apple.com",
                    qrType: "url"
                ),
                name: "Apple Store",
                latitude: 37.7749,
                longitude: -122.4194,
                address: "1 Infinite Loop, Cupertino, CA"
            ),
            LocationModel(
                qrCode: QRCodeModel(
                    label: nil,
                    content: "BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nTEL:+1234567890\nEMAIL:john@example.com\nEND:VCARD",
                    qrType: "vcard"
                ),
                name: "Contact",
                latitude: 37.7749,
                longitude: -122.4194,
                address: "1 Infinite Loop, Cupertino, CA"
            ),
            LocationModel(
                qrCode: QRCodeModel(
                    label: "Home WiFi",
                    content: "WIFI:S:MyNetwork;T:WPA;P:password123;;",
                    qrType: "wifi"
                ),
                name: "Home Network",
                latitude: 37.7749,
                longitude: -122.4194,
                address: "1 Infinite Loop, Cupertino, CA"
            ),
            LocationModel(
                qrCode: QRCodeModel(
                    label: "",
                    content: "tel:+14155552671",
                    qrType: "phone"
                ),
                name: "Support Number",
                latitude: 37.7749,
                longitude: -122.4194,
                address: "1 Infinite Loop, Cupertino, CA"
            ),
            LocationModel(
                qrCode: QRCodeModel(
                    label: "Contact Email",
                    content: "mailto:contact@example.com",
                    qrType: "email"
                ),
                name: "Email Contact",
                latitude: 37.7749,
                longitude: -122.4194,
                address: "1 Infinite Loop, Cupertino, CA"
            )
        ])
    }
}
