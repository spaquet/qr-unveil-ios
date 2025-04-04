//
//  QRDetailView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftData
import SwiftUI

// Main QR detail view container
struct QRDetailView: View {
    let qrCode: QRCodeModel
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editedLabel: String = ""
    
    var body: some View {
        List {
            // Header section with QR code image and actions
            QRDetailHeaderSection(
                qrCode: qrCode,
                isEditing: $isEditing,
                editedLabel: $editedLabel,
                modelContext: modelContext
            )
            
            // Details section with metadata
            QRDetailInfoSection(qrCode: qrCode)
            
            // Content section showing the raw QR content
            QRDetailContentSection(content: qrCode.content)
            
            // Location section if available
            if let location = qrCode.qrLocation {
                QRDetailLocationSection(location: location)
            }
            
            // Tags section
            QRDetailTagsSection(tags: qrCode.tags ?? [])
        }
        .navigationTitle("QR Code Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Save") {
                        qrCode.updateLabel(editedLabel.isEmpty ? nil : editedLabel)
                        do {
                            try modelContext.save()
                        } catch {
                            print("Error saving label: \(error)")
                        }
                        isEditing = false
                    }
                } else {
                    Button("Edit") {
                        editedLabel = qrCode.label ?? ""
                        isEditing = true
                    }
                }
            }
        }
        .onAppear {
            editedLabel = qrCode.label ?? ""
        }
    }
}
