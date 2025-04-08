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
    @State private var selectedTags: [TagModel] = []
    @State private var showTagPicker = false
    
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
            QRDetailContentSection(content: qrCode.content, qrType: qrCode.qrType)
            
            // Location section if available
            if let location = qrCode.qrLocation {
                QRDetailLocationSection(location: location)
            }
            
            // Tags section with edit support
            if isEditing {
                Section("Tags") {
                    Button {
                        showTagPicker = true
                    } label: {
                        HStack {
                            if selectedTags.isEmpty {
                                Text("Add tags")
                                    .foregroundColor(.primary)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(selectedTags) { tag in
                                            TagChipView(tag: tag)
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                QRDetailTagsSection(tags: qrCode.tags ?? [])
            }
        }
        .navigationTitle("QR Code Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Save") {
                        saveChanges()
                        isEditing = false
                    }
                } else {
                    Button("Edit") {
                        prepareForEditing()
                        isEditing = true
                    }
                }
            }
        }
        .onAppear {
            prepareForEditing() // Load initial data
        }
        .sheet(isPresented: $showTagPicker) {
            TagPickerView(selectedTags: $selectedTags)
                .onDisappear {
                    // Ensure we always have the latest selected tags
                    if isEditing {
                        // Don't save yet, just update local state
                    }
                }
        }
    }
    
    // Prepare the editing state with current values
    private func prepareForEditing() {
        editedLabel = qrCode.label ?? ""
        selectedTags = qrCode.tags ?? []
    }
    
    // Save changes to label and tags
    private func saveChanges() {
        // Save label changes
        qrCode.updateLabel(editedLabel.isEmpty ? nil : editedLabel)
        
        // Update tags
        // First remove all existing tags
        if let existingTags = qrCode.tags {
            for tag in existingTags {
                qrCode.removeTag(tag)
            }
        }
        
        // Then add all selected tags
        for tag in selectedTags {
            qrCode.addTag(tag)
        }
        
        // Save changes to database
        do {
            try modelContext.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}

// Preview for QRDetailView
#Preview {
    NavigationView {
        QRDetailView(qrCode: createSampleQRCode())
            .modelContainer(for: [QRCodeModel.self, LocationModel.self, TagModel.self])
    }
}

// Helper function to create a sample QR code with tags and location
private func createSampleQRCode() -> QRCodeModel {
    let tag1 = TagModel(name: "Important", color: "#FF5733")
    let tag2 = TagModel(name: "Work", color: "#33FF57")
    
    let qrCode = QRCodeModel(
        label: "Company Website",
        content: "https://www.example.com",
        qrType: "url"
    )
    
    qrCode.scanCount = 5
    qrCode.isFavorite = true
    qrCode.lastScanned = Date()
    qrCode.tags = [tag1, tag2]
    
    // Create and connect location
    let location = LocationModel(
        qrCode: qrCode,
        name: "Office",
        latitude: 37.7749,
        longitude: -122.4194,
        address: "123 Main Street, San Francisco, CA 94105"
    )
    
    qrCode.qrLocation = location
    
    return qrCode
}
