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
            QRDetailContentSection(content: qrCode.content)
            
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
