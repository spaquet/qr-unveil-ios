//
//  QRCodeRowView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftData
import SwiftUI

// QR Code row for list display
struct QRCodeRowView: View {
    let qrCode: QRCodeModel
    
    var body: some View {
        HStack {
            Image(systemName: iconForQRType(qrCode.qrType))
                .font(.title2)
                .foregroundColor(colorForQRType(qrCode.qrType))
                .frame(width: 44, height: 44)
                .background(colorForQRType(qrCode.qrType).opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(qrCode.label ?? qrCode.formattedContent())
                    .font(.headline)
                    .lineLimit(1)
                
                Text(qrCode.formattedContent())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(formattedDate(qrCode.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if qrCode.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForQRType(_ type: String) -> String {
        switch type {
        case "url":
            return "link"
        case "phone":
            return "phone.fill"
        case "email":
            return "envelope.fill"
        case "wifi":
            return "wifi"
        case "vcard":
            return "person.fill"
        case "location":
            return "mappin"
        case "sms":
            return "message.fill"
        default:
            return "doc.text"
        }
    }
    
    private func colorForQRType(_ type: String) -> Color {
        switch type {
        case "url":
            return .blue
        case "phone":
            return .green
        case "email":
            return .red
        case "wifi":
            return .orange
        case "vcard":
            return .purple
        case "location":
            return .pink
        case "sms":
            return .indigo
        default:
            return .gray
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
