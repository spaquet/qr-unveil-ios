//
//  QRDetailHeaderSection.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftData
import SwiftUI

// MARK: - Header Section
struct QRDetailHeaderSection: View {
    let qrCode: QRCodeModel
    @Binding var isEditing: Bool
    @Binding var editedLabel: String
    let modelContext: ModelContext
    
    var body: some View {
        Section {
            VStack(alignment: .center, spacing: 16) {
                // QR Code image (placeholder)
                Image(systemName: "qrcode")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding()
                
                // Label/Title
                if isEditing {
                    TextField("Label", text: $editedLabel)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                } else {
                    Text(qrCode.label ?? qrCode.formattedContent())
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                HStack(spacing: 30) {
                    ActionButton(
                        icon: "doc.on.doc",
                        label: "Copy",
                        action: { UIPasteboard.general.string = qrCode.content }
                    )
                    
                    ActionButton(
                        icon: "square.and.arrow.up",
                        label: "Share",
                        action: { /* Share action would go here */ }
                    )
                    
                    ActionButton(
                        icon: qrCode.isFavorite ? "star.fill" : "star",
                        label: "Favorite",
                        iconColor: qrCode.isFavorite ? .yellow : .gray,
                        action: {
                            qrCode.toggleFavorite()
                            do {
                                try modelContext.save()
                            } catch {
                                print("Error toggling favorite: \(error)")
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Info Section
struct QRDetailInfoSection: View {
    let qrCode: QRCodeModel
    
    var body: some View {
        Section("Details") {
            LabeledContent("Type", value: qrCode.qrType.capitalized)
            LabeledContent("Created", value: formattedDate(qrCode.createdAt))
            LabeledContent("Last Scanned", value: qrCode.lastScanned != nil ? formattedDate(qrCode.lastScanned!) : "N/A")
            LabeledContent("Scan Count", value: "\(qrCode.scanCount)")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Content Section
struct QRDetailContentSection: View {
    let content: String
    
    var body: some View {
        Section("Content") {
            Text(content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

// MARK: - Location Section
struct QRDetailLocationSection: View {
    let location: LocationModel
    
    var body: some View {
        Section("Location") {
            LabeledContent("Name", value: location.name)
            LabeledContent("Coordinates", value: "\(location.latitude), \(location.longitude)")
            if let address = location.address {
                LabeledContent("Address", value: address)
            }
            
            // Map placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay(
                    Text("Map View")
                        .foregroundColor(.secondary)
                )
        }
    }
}

// MARK: - Tags Section
struct QRDetailTagsSection: View {
    let tags: [TagModel]
    
    var body: some View {
        Section("Tags") {
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                Text("No tags")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

// MARK: - Helper Components

// Action button component
struct ActionButton: View {
    let icon: String
    let label: String
    var iconColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.caption)
            }
        }
    }
}

// Tag view component
struct TagView: View {
    let tag: TagModel
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(tag.color ?? "#CCCCCC"))
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
