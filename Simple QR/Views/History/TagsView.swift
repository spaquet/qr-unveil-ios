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
    @Query(sort: \TagModel.name) var tags: [TagModel]
    @Environment(\.modelContext) private var modelContext
    @State private var showingTagEditor = false
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: TagModel? = nil
    @State private var isEditMode: EditMode = .inactive
    
    var body: some View {
        List {
            if tags.isEmpty {
                ContentUnavailableView {
                    Label("No Tags", systemImage: "tag.slash")
                } description: {
                    Text("You haven't created any tags yet.")
                } actions: {
                    Button("Create Tag") {
                        showingTagEditor = true
                    }
                }
            } else {
                ForEach(tags) { tag in
                    NavigationLink(destination: TagDetailView(tag: tag)) {
                        TagRowView(tag: tag)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            tagToDelete = tag
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            editTag(tag)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingTagEditor = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingTagEditor) {
            TagEditorView()
        }
        .alert("Delete Tag", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                tagToDelete = nil
            }
            
            Button("Delete", role: .destructive) {
                if let tag = tagToDelete {
                    deleteTag(tag)
                }
                tagToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this tag? This action cannot be undone.")
        }
    }
    
    // Opens the tag editor for an existing tag
    private func editTag(_ tag: TagModel) {
        // We need a custom approach for editing since we need to pass the tag
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(UIHostingController(rootView:
                TagEditorView(editingTag: tag)
                    .environment(\.modelContext, modelContext)
            ), animated: true)
        }
    }
    
    // Deletes a tag from the database
    private func deleteTag(_ tag: TagModel) {
        // First, remove the tag from all associated QR codes
        if let qrCodes = tag.qrCodes {
            for qrCode in qrCodes {
                tag.removeQRCode(qrCode)
            }
        }
        
        // Then delete the tag itself
        modelContext.delete(tag)
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error deleting tag: \(error.localizedDescription)")
        }
    }
}

// Tag row for list display
struct TagRowView: View {
    let tag: TagModel
    
    var body: some View {
        HStack {
            Circle()
                .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC"))
                .frame(width: 16, height: 16)
            
            Text(tag.name)
            
            Spacer()
            
            Text("\(tag.qrCodes?.count ?? 0)")
                .foregroundColor(.secondary)
        }
    }
}

struct TagChipView: View {
    let tag: TagModel
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC"))
                .frame(width: 8, height: 8)
            
            Text(tag.name)
                .font(.subheadline)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC").opacity(0.15))
        )
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

struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedTags: [TagModel]
    @Query private var availableTags: [TagModel]
    
    // State for showing tag editor
    @State private var showingTagEditor = false
    
    var body: some View {
        NavigationStack {
            List {
                if availableTags.isEmpty {
                    ContentUnavailableView {
                        Label("No Tags", systemImage: "tag.slash")
                    } description: {
                        Text("You haven't created any tags yet.")
                    } actions: {
                        Button("Create Tag") {
                            showingTagEditor = true
                        }
                    }
                } else {
                    ForEach(availableTags) { tag in
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC"))
                                    .frame(width: 16, height: 16)
                                
                                Text(tag.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingTagEditor = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingTagEditor) {
            TagEditorView()
                .environment(\.modelContext, modelContext)
        }
    }
    
    private func toggleTag(_ tag: TagModel) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}
